require 'pathname'

module Senren
  module Rails
    # Resolves canonical paths inside a host Rails application.
    # Accepts an explicit root for tests; defaults to Rails.root when present.
    class HostPaths
      attr_reader :root

      def initialize(root = nil)
        @root = Pathname.new(root || ::Rails.root).expand_path
      end

      def senren_dir            = root.join('.senren')
      def skill_file            = senren_dir.join('skill.md')
      def registry_mirror       = senren_dir.join('registry.yml')
      def installed_components  = senren_dir.join('installed_components.yml')
      def conventions_file      = senren_dir.join('conventions.md')

      def components_dir        = root.join('app', 'components', 'senren')
      def base_component_path   = components_dir.join('base_component.rb')

      def stylesheet_path       = root.join('app', 'assets', 'stylesheets', 'senren.css')

      def stimulus_dir          = root.join('app', 'javascript', 'controllers', 'senren')

      def llms_short            = root.join('public', 'llms.txt')
      def llms_full             = root.join('public', 'llms-full.txt')

      def ensure_dirs!
        [senren_dir, components_dir, stimulus_dir,
         stylesheet_path.dirname, llms_short.dirname].each(&:mkpath)
      end
    end
  end
end
