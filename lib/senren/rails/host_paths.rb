require 'pathname'
require 'senren/rails/safe_write'

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
      def agent_rules_file      = senren_dir.join('agent-rules.md')

      def components_dir        = root.join('app', 'components', 'senren')
      def base_component_path   = components_dir.join('base_component.rb')

      def stylesheet_path       = root.join('app', 'assets', 'stylesheets', 'senren.css')

      def stimulus_dir          = root.join('app', 'javascript', 'controllers', 'senren')

      def github_dir            = root.join('.github')
      def copilot_instructions  = github_dir.join('copilot-instructions.md')
      def cursor_rules_dir      = root.join('.cursor', 'rules')
      def cursor_rule_file      = cursor_rules_dir.join('senren.mdc')
      def claude_md             = root.join('CLAUDE.md')
      def codex_agents_md       = root.join('AGENTS.md')

      # Pathname#mkpath stops at File.directory?, which follows symlinks, so a
      # checkout shipping app/components/senren as a link to somewhere outside
      # the project had that link preserved and every later write redirected
      # through it. SafeWrite refuses instead of silently accepting it.
      def ensure_dirs!
        [senren_dir, components_dir, stimulus_dir,
         stylesheet_path.dirname, github_dir, cursor_rules_dir].each do |dir|
          SafeWrite.mkdir_p!(dir, root, 'ensure_dirs!')
        end
      end

      def ensure_agent_dirs!
        [senren_dir, github_dir, cursor_rules_dir].each do |dir|
          SafeWrite.mkdir_p!(dir, root, 'ensure_agent_dirs!')
        end
      end
    end
  end
end
