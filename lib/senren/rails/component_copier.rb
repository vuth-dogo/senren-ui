# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'yaml'
require 'time'
require 'senren/rails/base_component_patch'
require 'senren/rails/safe_write'

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

        requested = Array(component_names).map(&:to_s)
        wanted.each do |name|
          comp = registry.fetch(name)
          install_component(comp, client_override: override_for(name, requested, client_override), force: force)
        end

        update_installed_ledger(wanted, requested: requested, client_override: client_override)
        wanted
      end

      private

      # --client / --no-client describes what the user asked for, not what its
      # dependencies are. Applying it to the whole closure meant
      # `senren:add context_menu --no-client` also suppressed the controller for
      # dropdown_menu, whose markup emits data-controller unconditionally — so
      # the installed menu silently never opened, and the ledger then recorded
      # client: false for a component this command was never asked about.
      #
      # validate_client_override! already exempts dependencies in the other
      # direction, for the same reason.
      def override_for(name, requested, client_override)
        requested.include?(name) ? client_override : nil
      end

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

      # Delegates to SafeWrite so an intermediate symlinked directory is caught,
      # not just a symlinked leaf. `app/components/senren -> /elsewhere` used to
      # pass every check here.
      def refuse_symlink?(dest, label)
        SafeWrite.resolve(dest, paths.root, label, io: stdout).nil?
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
        SafeWrite.mkdir_p!(File.dirname(dest), paths.root, label)
        SafeWrite.copy!(src, dest, paths.root, label)
        stdout.puts "  copy  #{dest}"
      end

      # Defense in depth: destinations are registry-derived, but a copier that
      # can write anywhere is one bad registry entry away from a traversal.
      #
      # This used to compare expand_path, which normalises lexically and does
      # not resolve symlinks, so a symlinked ancestor escaped it entirely.
      def assert_inside_host_root!(dest, label)
        SafeWrite.assert_inside!(dest, paths.root, label)
      rescue SafeWrite::Escape => e
        raise ArgumentError, e.message
      end

      # A ledger holding anything but a mapping used to reach `ledger['installed']
      # ||= []` and raise `IndexError: string not matched` from String#[]=, which
      # tells the user nothing about which file is wrong or why.
      def load_ledger(path)
        return {} unless path.exist?

        content = YAML.safe_load_file(path) || {}
        return content if content.is_a?(Hash)

        raise ArgumentError,
              "#{path} is not a Senren ledger: expected a YAML mapping, got #{content.class}. " \
              'Fix or delete the file and run the command again.'
      end

      def update_installed_ledger(names, requested:, client_override:)
        ledger_path = paths.installed_components
        ledger = load_ledger(ledger_path)
        installed = ledger['installed'] ||= []

        names.each do |name|
          existing = installed.find { |e| e['name'] == name }
          attrs = {
            'name' => name,
            'version' => Senren::Rails::VERSION,
            'installed_at' => Time.now.utc.iso8601,
            'client' => effective_client_for(
              registry.fetch(name), override_for(name, requested, client_override)
            )
          }
          if existing
            existing.merge!(attrs.except('installed_at'))
          else
            installed << attrs
          end
        end

        installed.sort_by! { |e| e['name'] }
        SafeWrite.mkdir_p!(ledger_path.parent, paths.root, 'ledger')
        SafeWrite.write!(ledger_path, YAML.dump(ledger), paths.root, 'ledger')
      end
    end
  end
end
