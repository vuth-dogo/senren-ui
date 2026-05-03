require 'yaml'

module Senren
  module Rails
    # Runs a series of checks against the host Rails app and prints a
    # human-readable status report.
    class Doctor
      Result = Struct.new(:label, :ok, :detail) do
        def icon = ok ? '✓' : '✗'
      end

      attr_reader :paths, :stdout

      def initialize(paths: HostPaths.new, stdout: $stdout)
        @paths  = paths
        @stdout = stdout
      end

      def run!
        results = runtime_checks + installation_checks
        installed = installed_count
        results << Result.new("#{installed} component(s) installed", installed >= 0, nil)

        report(results)
        results.all?(&:ok)
      end

      private

      def check(label)
        ok = false
        detail = nil
        begin
          ok = !yield.nil?
        rescue StandardError => e
          detail = e.message
        end
        Result.new(label, ok, detail)
      end

      def gem_loadable?(name)
        Gem::Specification.find_by_name(name)
        true
      rescue Gem::LoadError
        false
      end

      def runtime_checks
        [
          check('ViewComponent gem available')    { defined?(::ViewComponent) },
          check('TailwindCSS stylesheet present') { paths.stylesheet_path.exist? },
          check('Stimulus directory present')     { paths.stimulus_dir.directory? },
          check('Turbo gem available')            { defined?(::Turbo) || gem_loadable?('turbo-rails') }
        ]
      end

      def installation_checks
        [
          check('.senren directory exists')               { paths.senren_dir.directory? },
          check('.senren/skill.md exists')                { paths.skill_file.file? },
          check('.senren/registry.yml exists')            { paths.registry_mirror.file? },
          check('.senren/installed_components.yml exists') { paths.installed_components.file? },
          check('.senren/agent-rules.md exists')          { paths.agent_rules_file.file? },
          check('AGENTS.md exists')                       { paths.codex_agents_md.file? },
          check('CLAUDE.md exists')                       { paths.claude_md.file? },
          check('.github/copilot-instructions.md exists') { paths.copilot_instructions.file? },
          check('.cursor/rules/senren.mdc exists')        { paths.cursor_rule_file.file? },
          check('app/components/senren exists')           { paths.components_dir.directory? },
          check('app/javascript/controllers/senren exists') { paths.stimulus_dir.directory? }
        ]
      end

      def installed_count
        return 0 unless paths.installed_components.file?

        ledger = YAML.safe_load_file(paths.installed_components) || {}
        Array(ledger['installed']).size
      rescue StandardError
        -1
      end

      def report(results)
        stdout.puts 'Senren Doctor'
        stdout.puts ''
        results.each do |r|
          line = "#{r.icon} #{r.label}"
          line += "  -- #{r.detail}" if r.detail
          stdout.puts line
        end
        stdout.puts ''
        if results.all?(&:ok)
          stdout.puts 'No issues found.'
        else
          stdout.puts 'Issues found. Resolve the items marked with ✗.'
        end
      end
    end
  end
end
