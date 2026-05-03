# frozen_string_literal: true

require 'test_helper'
require 'senren/rails/host_paths'
require 'senren/rails/llms_writer'

module Senren
  module Rails
    class LlmsWriterTest < Minitest::Test
      def setup
        @registry = Senren::Rails::Registry.load!(
          components_path: File.expand_path('../registry/components.yml', __dir__),
          groups_path: File.expand_path('../registry/groups.yml', __dir__),
          recipes_path: File.expand_path('../registry/recipes.yml', __dir__)
        )
      end

      def test_generate_delegates_to_agent_rules_sync
        Dir.mktmpdir do |dir|
          paths = Senren::Rails::HostPaths.new(dir)
          seed_installed_components(paths, %w[button])

          files = Senren::Rails::LlmsWriter.new(registry: @registry, paths: paths).generate!

          assert_includes files, paths.agent_rules_file
          assert_includes files, paths.codex_agents_md
          assert_includes files, paths.claude_md
          assert_includes files, paths.copilot_instructions
          assert_includes files, paths.cursor_rule_file
          refute File.exist?(File.join(dir, 'public', 'llms.txt'))
          refute File.exist?(File.join(dir, 'public', 'llms-full.txt'))
        end
      end

      private

      def seed_installed_components(paths, names)
        paths.senren_dir.mkpath
        payload = { 'installed' => names.map { |name| { 'name' => name } } }
        File.write(paths.installed_components, YAML.dump(payload))
      end
    end
  end
end
