# frozen_string_literal: true

require 'test_helper'
require 'senren/rails'
require 'senren/rails/doctor'
require 'senren/rails/host_paths'

module Senren
  module Rails
    class DoctorTest < Minitest::Test
      def setup
        @root = Dir.mktmpdir
        @paths = HostPaths.new(@root)
        @stdout = StringIO.new
      end

      def teardown
        FileUtils.remove_entry(@root) if @root && Dir.exist?(@root)
      end

      # Regression: the checks return booleans, but the result was coerced with
      # `!yield.nil?`, and false.nil? is false. Every filesystem check reported
      # a pass on an app where nothing was installed.
      def test_reports_failure_when_nothing_is_installed
        refute Doctor.new(paths: @paths, stdout: @stdout).run!,
               'doctor must fail on an empty directory'

        output = @stdout.string

        assert_includes output, '✗ .senren directory exists'
        assert_includes output, '✗ CLAUDE.md exists'
        assert_includes output, '✗ app/components/senren exists'
        refute_includes output, 'No issues found'
      end

      def test_reports_success_for_each_artifact_that_exists
        @paths.ensure_dirs!
        @paths.skill_file.write('# skill')
        @paths.registry_mirror.write("components: {}\n")
        @paths.installed_components.write("installed: []\n")
        @paths.agent_rules_file.write('# rules')
        @paths.claude_md.write('# claude')

        Doctor.new(paths: @paths, stdout: @stdout).run!
        output = @stdout.string

        assert_includes output, '✓ .senren directory exists'
        assert_includes output, '✓ .senren/skill.md exists'
        assert_includes output, '✓ CLAUDE.md exists'
        assert_includes output, '✗ AGENTS.md exists', 'artifacts that are still missing must be reported as failures'
      end

      def test_counts_installed_components_from_the_ledger
        @paths.ensure_dirs!
        @paths.installed_components.write(
          { 'installed' => [{ 'name' => 'button' }, { 'name' => 'dialog' }] }.to_yaml
        )

        Doctor.new(paths: @paths, stdout: @stdout).run!

        assert_includes @stdout.string, '2 component(s) installed'
      end
    end
  end
end
