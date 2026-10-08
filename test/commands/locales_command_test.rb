# frozen_string_literal: true

require 'test_helper'
require 'rails/command'
require 'commands/senren/locales/locales_command'

module Senren
  module Command
    # `bin/rails senren:locales vi` is how the README, docs/i18n.md and the
    # install generator say to copy a translation. As a rake task, Rails passed
    # `vi` to rake as a second task and failed with `Unrecognized command "vi"`.
    class LocalesCommandTest < Minitest::Test
      class FakeInstaller
        attr_reader :calls

        def initialize
          @calls = []
        end

        def install(locales:, force:)
          @calls << { locales: locales, force: force }
          locales
        end
      end

      class TestLocalesCommand < Senren::Command::LocalesCommand
        class << self
          attr_accessor :installer
        end

        private

        def require_application!
          true
        end

        def locale_installer
          self.class.installer
        end
      end

      def teardown
        TestLocalesCommand.installer = nil
      end

      def test_command_is_discoverable_by_namespace
        assert_equal Senren::Command::LocalesCommand, ::Rails::Command.find_by_namespace('senren', 'locales')
      end

      def test_space_separated_locales_reach_the_installer
        TestLocalesCommand.installer = FakeInstaller.new

        capture_io { TestLocalesCommand.perform('locales', %w[en vi], {}) }

        assert_equal [{ locales: %w[en vi], force: false }], TestLocalesCommand.installer.calls
      end

      def test_comma_separated_locales_and_force
        TestLocalesCommand.installer = FakeInstaller.new

        capture_io { TestLocalesCommand.perform('locales', %w[en,vi --force], {}) }

        assert_equal [{ locales: %w[en vi], force: true }], TestLocalesCommand.installer.calls
      end

      def test_an_unshipped_locale_prints_the_message_and_fails_without_a_backtrace
        installer = Object.new
        installer.define_singleton_method(:install) { |**| raise ArgumentError, 'Senren ships no fr translation' }
        TestLocalesCommand.installer = installer

        exit_error = nil
        _, stderr = capture_io do
          exit_error = assert_raises(SystemExit) { TestLocalesCommand.perform('locales', %w[fr], {}) }
        end

        refute exit_error.success?
        assert_equal "Senren ships no fr translation\n", stderr
      end
    end
  end
end
