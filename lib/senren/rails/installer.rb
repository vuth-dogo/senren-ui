# frozen_string_literal: true

require 'fileutils'

module Senren
  module Rails
    # Idempotent installer that lays down the .senren directory, base
    # component, stylesheet, and agent instruction files. Reused by the install
    # generator and by ad-hoc rake task entry points.
    class Installer
      attr_reader :paths, :stdout

      def initialize(paths: HostPaths.new, stdout: $stdout)
        @paths  = paths
        @stdout = stdout
      end

      def run!(force: false)
        paths.ensure_dirs!
        install_static_files(force: force)
        mirror_registry
        SkillWriter.new(paths: paths).sync!
        AgentRulesWriter.new(paths: paths).sync!
        print_next_steps
        true
      end

      INSTALL_GENERATOR_TEMPLATES = File.expand_path(
        '../../generators/senren/install/templates', __dir__
      ).freeze

      STATIC_FILES = {
        'conventions.md.tt' => :conventions_file,
        'installed_components.yml.tt' => :installed_components,
        'base_component.rb.tt' => :base_component_path,
        'senren.css.tt' => :stylesheet_path
      }.freeze

      private

      def install_static_files(force:)
        STATIC_FILES.each do |template_basename, paths_method|
          src = File.join(INSTALL_GENERATOR_TEMPLATES, template_basename)
          dest = paths.public_send(paths_method)
          copy_template(src, dest, force: force)
        end
      end

      def copy_template(src, dest, force:)
        unless File.exist?(src)
          stdout.puts "  warn  template missing: #{src}"
          return
        end
        if File.exist?(dest) && !force
          stdout.puts "  skip  #{dest}"
          return
        end
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)
        stdout.puts "  copy  #{dest}"
      end

      def mirror_registry
        FileUtils.mkdir_p(paths.registry_mirror.dirname)
        FileUtils.cp(Senren::Rails.registry_path, paths.registry_mirror)
        stdout.puts "  mirror #{paths.registry_mirror}"
      end

      def print_next_steps
        stdout.puts <<~MSG

          Senren installed. Next steps:

            bin/rails senren:add button card badge alert
            bin/rails senren:add dialog dropdown_menu
            bundle exec rails senren:add form input textarea
            bin/rails senren:agents:sync
            bin/rails senren:doctor

          Read .senren/skill.md and .senren/conventions.md to get oriented.
        MSG
      end
    end
  end
end
