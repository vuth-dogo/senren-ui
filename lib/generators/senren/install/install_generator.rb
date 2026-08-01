# frozen_string_literal: true

require 'rails/generators/base'
require 'senren/rails'

module Senren
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :force, type: :boolean, default: false,
                           desc: 'Overwrite existing Senren-managed files.'

      def create_senren_dir
        empty_directory '.senren'
      end

      def create_components_dir
        empty_directory 'app/components/senren'
      end

      def create_stimulus_dir
        empty_directory 'app/javascript/controllers/senren'
      end

      def create_assets_dir
        empty_directory 'app/assets/stylesheets'
      end

      def copy_base_files
        template 'base_component.rb.tt', 'app/components/senren/base_component.rb'
        template 'senren.css.tt',                'app/assets/stylesheets/senren.css'
        template 'conventions.md.tt',            '.senren/conventions.md'
        template 'installed_components.yml.tt',  '.senren/installed_components.yml'
      end

      def mirror_registry
        copy_file Senren::Rails.registry_path, '.senren/registry.yml'
      end

      # Switches Stimulus to on-demand loading instead of documenting it.
      #
      # Rails' default is `eagerLoadControllersFrom("controllers", application)`,
      # which imports every controller in the importmap on every page. Because
      # `pin_all_from "app/javascript/controllers"` is recursive it also covers
      # app/javascript/controllers/senren, so a static page paid for every
      # interactive component the app had installed.
      #
      # This was a README instruction the developer had to follow by hand, and a
      # "PASS" in bin/performance that only grepped that README. An instruction
      # nobody runs is not a feature.
      #
      # It uses the official stimulus-loading helper rather than a Senren-specific
      # loader, and therefore changes loading for the app's own controllers too.
      # That is the trade the README already asked for; the generator only acts
      # when the file still carries the untouched Rails default, and says so.
      def configure_stimulus_loading
        enable_lazy_controller_loading
        disable_controller_preloading
      end

      def write_skill_file
        say_status :senren, 'writing .senren/skill.md'
        Senren::Rails::SkillWriter.new(paths: host_paths).sync!
      end

      def write_agent_files
        say_status :senren, 'syncing Codex/Cursor/Claude/Copilot instruction files'
        Senren::Rails::AgentRulesWriter.new(paths: host_paths).sync!
      end

      def print_next_steps
        say "\nSenren installed."
        say 'Next: bin/rails senren:add button card badge alert dialog'
        say 'Then: bin/rails senren:agents:sync'
      end

      private

      def enable_lazy_controller_loading
        index = 'app/javascript/controllers/index.js'
        unless host_file?(index)
          return say_status(:skip,
                            "#{index} not found; switch to lazyLoadControllersFrom by hand")
        end

        source = File.read(File.join(destination_root, index))
        if source.include?('lazyLoadControllersFrom')
          return say_status(:senren,
                            'controllers already load on demand')
        end

        unless source.include?('eagerLoadControllersFrom')
          return say_status(:skip, "#{index} has a custom loader; left alone")
        end

        gsub_file index, 'eagerLoadControllersFrom', 'lazyLoadControllersFrom'
        say_status :senren, 'Stimulus controllers now load when their data-controller appears'
      end

      # Only strips the modulepreload tags. On its own it does not stop eager
      # importing, which is why it is paired with the change above.
      def disable_controller_preloading
        importmap = 'config/importmap.rb'
        unless host_file?(importmap)
          return say_status(:skip,
                            "#{importmap} not found; add preload: false by hand")
        end

        source = File.read(File.join(destination_root, importmap))
        if source.match?(/under:\s*["']controllers["'].*preload:\s*false/)
          return say_status(:senren,
                            'controller preloading already disabled')
        end

        if source.match?(%r{pin_all_from\s+["']app/javascript/controllers["']})
          # A backreference rather than a block: Thor forwards the block to
          # String#gsub across several frames, where $~ is no longer the match.
          # The lookahead makes a second run a no-op.
          gsub_file importmap,
                    %r{(pin_all_from\s+["']app/javascript/controllers["'](?![^\n]*preload:)[^\n]*)},
                    '\1, preload: false'
        else
          append_to_file importmap,
                         %(\npin_all_from "app/javascript/controllers", under: "controllers", preload: false\n)
        end
      end

      def host_file?(relative)
        File.exist?(File.join(destination_root, relative))
      end

      def host_paths
        @host_paths ||= Senren::Rails::HostPaths.new(destination_root)
      end
    end
  end
end
