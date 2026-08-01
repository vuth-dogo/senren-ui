# frozen_string_literal: true

require 'fileutils'
require 'senren/rails/agent_rules_writer'
require 'senren/rails/component_copier'
require 'senren/rails/host_paths'
require 'senren/rails/registry'
require 'senren/rails/skill_writer'

module Senren
  module Rails
    # Installs one or more registered Senren components into the host app and
    # refreshes the generated guidance files afterward.
    class ComponentInstaller
      USAGE = 'Usage: bin/rails senren:add NAME [NAME...] [--client | --no-client]'

      attr_reader :registry, :paths, :stdout

      def self.normalize_names(names)
        Array(names)
          .flatten
          .flat_map { |entry| entry.to_s.split(/[,\s]+/) }
          .reject { |entry| entry.empty? || entry.start_with?('-') }
          .uniq
      end

      def initialize(registry: Registry.load!, paths: HostPaths.new, stdout: $stdout)
        @registry = registry
        @paths    = paths
        @stdout   = stdout
      end

      def install(names:, client_override: nil, force: false)
        normalized_names = self.class.normalize_names(names)
        raise ArgumentError, USAGE if normalized_names.empty?

        # Preflight. Everything below writes to disk, and a failure partway
        # through leaves components copied, the ledger updated and the guidance
        # files stale -- which is exactly what the first version of the adapter
        # collision check did.
        AgentRulesWriter.new(registry: registry, paths: paths).assert_distinct_adapters!

        installed = ComponentCopier.new(registry: registry, paths: paths, stdout: stdout)
                                   .install(normalized_names, client_override: client_override, force: force)

        refresh_registry_mirror
        SkillWriter.new(registry: registry, paths: paths).sync!
        AgentRulesWriter.new(registry: registry, paths: paths).sync!

        stdout.puts "Installed: #{installed.join(', ')}"
        installed
      end

      private

      # The mirror was written once at install time and never again, so it drifted
      # from the gem on every upgrade while the generated agent rules kept
      # advertising it as the authoritative "component registry mirror". Agents
      # read stale component metadata and had no way to tell.
      # The FileUtils.cp here was lifted from the Installer#mirror_registry that
      # this same review deleted, and it carried that method's defect with it:
      # containment was applied to the directory, so a symlinked
      # .senren/registry.yml was followed and a file outside the app root was
      # overwritten. Moving a bug is not fixing it. SafeWrite.copy! checks the
      # destination file itself.
      def refresh_registry_mirror
        dest = paths.registry_mirror
        SafeWrite.mkdir_p!(dest.dirname, paths.root, 'registry mirror')
        SafeWrite.copy!(Senren::Rails.registry_path, dest, paths.root, 'registry mirror')
      end
    end
  end
end
