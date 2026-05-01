# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'time'

module Senren
  module Rails
    # Copies component files from the gem's templates/ tree into the host
    # Rails app, and updates .senren/installed_components.yml.
    class ComponentCopier
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
        paths.ensure_dirs!

        wanted.each do |name|
          comp = registry.fetch(name)
          install_component(comp, client_override: client_override, force: force)
        end

        update_installed_ledger(wanted, client_override: client_override)
        wanted
      end

      private

      def install_component(comp, client_override:, force:)
        effective_client = effective_client_for(comp, client_override)

        comp.files.each do |relative|
          next if relative.include?('javascript/controllers') && !effective_client

          src = source_for(comp, relative)
          dest = paths.root.join(relative)
          copy_file(src, dest, force: force, label: "#{comp.name}::#{File.basename(relative)}")
        end
      end

      def effective_client_for(comp, override)
        return comp.client? if override.nil?
        return false unless comp.can_have_client

        override
      end

      def source_for(comp, relative)
        # Map host path back to gem template path.
        # app/components/senren/<name>_component.rb           -> templates/components/<name>/<name>_component.rb
        # app/components/senren/<name>_component.html.erb     -> templates/components/<name>/<name>_component.html.erb
        # app/javascript/controllers/senren/<name>_controller.js -> templates/controllers/<name>_controller.js
        base = File.basename(relative)
        if relative.include?('app/components/senren/')
          File.join(Senren::Rails.templates_root, 'components', comp.name, base)
        elsif relative.include?('app/javascript/controllers/senren/')
          File.join(Senren::Rails.templates_root, 'controllers', base)
        else
          raise "ComponentCopier: do not know how to map #{relative.inspect}"
        end
      end

      def copy_file(src, dest, force:, label:)
        unless File.exist?(src)
          stdout.puts "  warn  missing template: #{src} (#{label})"
          return
        end
        if File.exist?(dest) && !force
          stdout.puts "  skip  #{dest} (already exists)"
          return
        end
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)
        stdout.puts "  copy  #{dest}"
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
