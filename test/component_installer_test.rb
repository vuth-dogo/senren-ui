# frozen_string_literal: true

require 'test_helper'
require 'senren/rails'
require 'senren/rails/component_copier'
require 'senren/rails/component_installer'
require 'senren/rails/host_paths'
require 'senren/rails/skill_writer'
require 'senren/rails/agent_rules_writer'

module Senren
  module Rails
    class ComponentInstallerTest < Minitest::Test
      def setup
        @root = Dir.mktmpdir
        @paths = HostPaths.new(@root)
        @stdout = StringIO.new
        @installer = ComponentInstaller.new(paths: @paths, registry: Registry.load!, stdout: @stdout)
      end

      def teardown
        FileUtils.remove_entry(@root) if @root && Dir.exist?(@root)
      end

      def test_normalize_names_supports_spaces_commas_and_nested_arrays
        names = ComponentInstaller.normalize_names([['button,card'], 'badge alert', '--client', nil, 'button'])

        assert_equal %w[button card badge alert], names
      end

      def test_install_copies_components_and_syncs_generated_files
        installed = @installer.install(names: %w[button card])

        assert_equal %w[button card], installed
        assert @paths.components_dir.join('button_component.rb').exist?
        assert @paths.components_dir.join('card_component.rb').exist?
        assert @paths.skill_file.exist?
        assert @paths.agent_rules_file.exist?
        assert_includes @paths.skill_file.read, 'Component: Button'
        assert_includes @stdout.string, 'Installed: button, card'

        ledger = YAML.safe_load_file(@paths.installed_components)
        installed_names = ledger.fetch('installed').map { |entry| entry.fetch('name') }

        assert_equal %w[button card], installed_names
      end

      def test_install_raises_clear_usage_for_empty_name_list
        error = assert_raises(ArgumentError) do
          @installer.install(names: [])
        end

        assert_equal ComponentInstaller::USAGE, error.message
      end
    end
  end
end
