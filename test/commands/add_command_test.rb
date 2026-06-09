# frozen_string_literal: true

require 'test_helper'
require 'rails/command'
require 'commands/senren/add/add_command'
require 'senren/rails/component_installer'

module Senren
  module Command
    class AddCommandTest < Minitest::Test
      FakeCall = Struct.new(:names, :client_override, :force, keyword_init: true)

      class FakeInstaller
        attr_reader :calls

        def initialize
          @calls = []
        end

        def install(names:, client_override:, force:)
          @calls << FakeCall.new(names: names, client_override: client_override, force: force)
        end
      end

      class TestAddCommand < Senren::Command::AddCommand
        class << self
          attr_accessor :installer
        end

        private

        def require_application!
          true
        end

        def component_installer
          self.class.installer
        end
      end

      def test_command_is_discoverable_by_namespace
        command = ::Rails::Command.find_by_namespace('senren', 'add')

        assert_equal Senren::Command::AddCommand, command
      end

      def test_command_parses_space_separated_names_and_no_client_flag
        installer = FakeInstaller.new
        TestAddCommand.installer = installer

        capture_io do
          TestAddCommand.perform('add', %w[button input --no-client], {})
        end

        assert_equal [
          FakeCall.new(names: %w[button input], client_override: false, force: false)
        ], installer.calls
      ensure
        TestAddCommand.installer = nil
      end

      def test_command_parses_comma_separated_names_and_force_flag
        installer = FakeInstaller.new
        TestAddCommand.installer = installer

        capture_io do
          TestAddCommand.perform('add', %w[button,card --client --force], {})
        end

        assert_equal [
          FakeCall.new(names: ['button,card'], client_override: true, force: true)
        ], installer.calls
      ensure
        TestAddCommand.installer = nil
      end

      def test_command_raises_clear_error_without_component_names
        installer = Object.new
        installer.define_singleton_method(:install) do |**|
          raise ArgumentError, Senren::Rails::ComponentInstaller::USAGE
        end

        TestAddCommand.installer = installer

        error = assert_raises(::Rails::Command::Base::Error) do
          capture_io do
            TestAddCommand.perform('add', [], {})
          end
        end

        assert_equal Senren::Rails::ComponentInstaller::USAGE, error.message
      ensure
        TestAddCommand.installer = nil
      end
    end
  end
end
