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

      def create_public_dir
        empty_directory 'public'
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

      def write_skill_file
        say_status :senren, 'writing .senren/skill.md'
        Senren::Rails::SkillWriter.new(paths: host_paths).sync!
      end

      def write_llms_files
        say_status :senren, 'writing public/llms.txt and public/llms-full.txt'
        Senren::Rails::LlmsWriter.new(paths: host_paths).generate!
      end

      def print_next_steps
        say "\nSenren installed."
        say 'Next: bin/rails senren:add button card badge alert dialog'
      end

      private

      def host_paths
        @host_paths ||= Senren::Rails::HostPaths.new(destination_root)
      end
    end
  end
end
