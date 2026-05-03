# frozen_string_literal: true

require 'test_helper'
require 'senren/rails/host_paths'
require 'senren/rails/agent_rules_writer'

module Senren
  module Rails
    class AgentRulesWriterTest < Minitest::Test
      def setup
        @registry = Senren::Rails::Registry.load!(
          components_path: File.expand_path('../registry/components.yml', __dir__),
          groups_path: File.expand_path('../registry/groups.yml', __dir__),
          recipes_path: File.expand_path('../registry/recipes.yml', __dir__)
        )
      end

      def test_sync_creates_source_and_all_adapter_files
        Dir.mktmpdir do |dir|
          paths = Senren::Rails::HostPaths.new(dir)
          seed_installed_components(paths, %w[button dialog])

          files = writer(paths).sync!

          expected = [
            paths.agent_rules_file,
            paths.codex_agents_md,
            paths.claude_md,
            paths.copilot_instructions,
            paths.cursor_rule_file
          ]

          assert_equal expected.map(&:to_s).sort, files.map(&:to_s).sort
          expected.each { |path| assert File.file?(path), "expected file #{path}" }
          refute File.exist?(File.join(dir, 'public', 'llms.txt'))
          refute File.exist?(File.join(dir, 'public', 'llms-full.txt'))
        end
      end

      def test_sync_preserves_existing_content_and_updates_only_marker_block
        Dir.mktmpdir do |dir|
          paths = Senren::Rails::HostPaths.new(dir)
          seed_installed_components(paths, %w[button])

          File.write(paths.codex_agents_md, <<~MD)
            # Existing rules

            Keep this section.

            #{Senren::Rails::AgentRulesWriter::START_MARKER}
            old generated content
            #{Senren::Rails::AgentRulesWriter::END_MARKER}

            Keep this footer too.
          MD

          writer(paths).sync!
          content = File.read(paths.codex_agents_md)

          assert_includes content, '# Existing rules'
          assert_includes content, 'Keep this section.'
          assert_includes content, 'Keep this footer too.'
          refute_includes content, 'old generated content'
          assert_includes content, '.senren/agent-rules.md'
          assert_equal 1, content.scan(Senren::Rails::AgentRulesWriter::START_MARKER).size
          assert_equal 1, content.scan(Senren::Rails::AgentRulesWriter::END_MARKER).size

          writer(paths).sync!
          content_again = File.read(paths.codex_agents_md)
          assert_equal 1, content_again.scan(Senren::Rails::AgentRulesWriter::START_MARKER).size
          assert_equal 1, content_again.scan(Senren::Rails::AgentRulesWriter::END_MARKER).size
        end
      end

      def test_sync_appends_marker_block_when_file_has_no_marker
        Dir.mktmpdir do |dir|
          paths = Senren::Rails::HostPaths.new(dir)
          seed_installed_components(paths, %w[button])

          paths.github_dir.mkpath
          File.write(paths.copilot_instructions, "# Existing Copilot notes\n\nKeep me.\n")

          writer(paths).sync!
          content = File.read(paths.copilot_instructions)

          assert_includes content, '# Existing Copilot notes'
          assert_includes content, 'Keep me.'
          assert_includes content, Senren::Rails::AgentRulesWriter::START_MARKER
          assert_includes content, Senren::Rails::AgentRulesWriter::END_MARKER
          assert_includes content, '.senren/agent-rules.md'
        end
      end

      private

      def writer(paths)
        Senren::Rails::AgentRulesWriter.new(registry: @registry, paths: paths)
      end

      def seed_installed_components(paths, names)
        paths.senren_dir.mkpath
        payload = { 'installed' => names.map { |name| { 'name' => name } } }
        File.write(paths.installed_components, YAML.dump(payload))
      end
    end
  end
end
