# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'yaml'
require 'time'
require 'senren/rails/base_component_patch'

module Senren
  module Rails
    # Copies component files from the gem's templates/ tree into the host
    # Rails app, and updates .senren/installed_components.yml.
    class ComponentCopier
      class MissingTemplate < StandardError; end

      INSTALL_GENERATOR_TEMPLATES = File.expand_path(
        '../../generators/senren/install/templates', __dir__
      ).freeze
      BASE_COMPONENT_TEMPLATE = File.join(INSTALL_GENERATOR_TEMPLATES, 'base_component.rb.tt').freeze
      BASE_URL_HELPER_PATCH = BaseComponentPatch::URL_HELPERS

      attr_reader :registry, :paths, :stdout

      def initialize(registry: Registry.load!, paths: HostPaths.new, stdout: $stdout)
        @registry = registry
        @paths    = paths
        @stdout   = stdout
      end

      # Installs a list of components (with deps), respecting the override flag.
      # Returns the ordered list of component names actually installed.
      def install(component_names, client_override: nil, force: false)
        wanted = registry.dependencies(*component_names)
        validate_client_override!(component_names, client_override)
        paths.ensure_dirs!
        ensure_base_component_url_helpers!

        wanted.each do |name|
          comp = registry.fetch(name)
          install_component(comp, client_override: client_override, force: force)
        end

        update_installed_ledger(wanted, client_override: client_override)
        wanted
      end

      private

      def ensure_base_component_url_helpers!
        dest = paths.base_component_path

        # Checked before #exist?, which follows the link. This append does not
        # go through copy_file, so without an explicit check it writes straight
        # through a symlink to its target — escaping the very app root that
        # assert_inside_host_root! exists to enforce. Path expansion does not
        # resolve symlinks, so containment alone cannot catch this.
        return if refuse_symlink?(dest, 'base_component.rb')

        if dest.exist?
          return if base_component_has_url_helpers?

          File.open(dest, 'a') { |file| file.write(BASE_URL_HELPER_PATCH) }
          stdout.puts "  update #{dest} (url helpers)"
          return
        end

        copy_file(BASE_COMPONENT_TEMPLATE, dest, force: false, label: 'base_component.rb')
      end

      def refuse_symlink?(dest, label)
        return false unless File.symlink?(dest)

        stdout.puts "  skip  #{dest} (symlink; refusing to write through it) [#{label}]"
        true
      end

      def base_component_has_url_helpers?
        source = paths.base_component_path.read

        source.include?('def safe_url') && source.include?('def safe_media_url')
      end

      def install_component(comp, client_override:, force:)
        effective_client = effective_client_for(comp, client_override)

        comp.files.each do |relative|
          next if relative.include?('javascript/controllers') && !effective_client

          src = source_for(comp, relative)
          dest = paths.root.join(relative)
          copy_file(src, dest, force: force, label: "#{comp.name}::#{File.basename(relative)}")
        end
      end

      # Only the explicitly requested components are checked: pulling in a
      # dependency that has no controller must not fail the whole install.
      def validate_client_override!(requested, override)
        return unless override

        offenders = Array(requested).map { |name| registry.fetch(name) }.reject { |comp| controller_file_for(comp) }
        return if offenders.empty?

        raise ArgumentError,
              "--client was requested for #{offenders.map(&:name).join(', ')}, but the registry lists no Stimulus " \
              'controller for them. Drop --client, or add a controller file to the registry entry.'
      end

      def controller_file_for(comp)
        comp.files.find { |relative| controller_source_path?(comp, relative) }
      end

      def effective_client_for(comp, override)
        desired = override.nil? ? comp.client? : (comp.can_have_client && override)

        # Never record client behavior in the ledger that was not installed.
        desired && !controller_file_for(comp).nil?
      end

      def source_for(comp, relative)
        # Map host path back to gem template path.
        # app/components/senren/<name>_component.rb           -> templates/components/<name>/<name>_component.rb
        # app/components/senren/<name>_component.html.erb     -> templates/components/<name>/<name>_component.html.erb
        # app/javascript/controllers/senren/<name>_controller.js -> templates/controllers/<name>_controller.js
        base = File.basename(relative)
        if component_source_path?(comp, relative)
          File.join(Senren::Rails.templates_root, 'components', comp.name, base)
        elsif controller_source_path?(comp, relative)
          File.join(Senren::Rails.templates_root, 'controllers', base)
        else
          raise "ComponentCopier: do not know how to map #{relative.inspect}"
        end
      end

      def component_source_path?(comp, relative)
        [
          "app/components/senren/#{comp.name}_component.rb",
          "app/components/senren/#{comp.name}_component.html.erb"
        ].include?(relative)
      end

      def controller_source_path?(comp, relative)
        relative == "app/javascript/controllers/senren/#{comp.name}_controller.js"
      end

      def copy_file(src, dest, force:, label:)
        raise MissingTemplate, "Missing component template: #{src} (#{label})" unless File.exist?(src)

        dest = assert_inside_host_root!(dest, label)
        return if refuse_symlink?(dest, label)

        if File.exist?(dest) && !force
          stdout.puts "  skip  #{dest} (already exists)"
          return
        end
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)
        stdout.puts "  copy  #{dest}"
      end

      # Defense in depth: destinations are registry-derived, but a copier that
      # can write anywhere is one bad registry entry away from a traversal.
      def assert_inside_host_root!(dest, label)
        expanded = Pathname.new(dest).expand_path
        root = paths.root.expand_path
        return expanded if expanded.to_s.start_with?("#{root}/")

        raise ArgumentError, "Refusing to write outside the app root: #{expanded} (#{label})"
      end

      def update_installed_ledger(names, client_override:)
        ledger_path = paths.installed_components
        ledger = ledger_path.exist? ? (YAML.safe_load_file(ledger_path) || {}) : {}
        installed = ledger['installed'] ||= []

        names.each do |name|
          existing = installed.find { |e| e['name'] == name }
          attrs = {
            'name' => name,
            'version' => Senren::Rails::VERSION,
            'installed_at' => Time.now.utc.iso8601,
            'client' => effective_client_for(registry.fetch(name), client_override)
          }
          if existing
            existing.merge!(attrs.except('installed_at'))
          else
            installed << attrs
          end
        end

        installed.sort_by! { |e| e['name'] }
        ledger_path.parent.mkpath
        File.write(ledger_path, YAML.dump(ledger))
      end
    end
  end
end
