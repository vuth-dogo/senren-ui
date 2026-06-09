# frozen_string_literal: true

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

        installed = ComponentCopier.new(registry: registry, paths: paths, stdout: stdout)
                                   .install(normalized_names, client_override: client_override, force: force)

        SkillWriter.new(registry: registry, paths: paths).sync!
        AgentRulesWriter.new(registry: registry, paths: paths).sync!

        stdout.puts "Installed: #{installed.join(', ')}"
        installed
      end
    end
  end
end
