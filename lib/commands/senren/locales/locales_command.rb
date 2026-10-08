# frozen_string_literal: true

require 'rails/command'
require 'senren/rails'
require 'senren/rails/locale_installer'

module Senren
  module Command
    # `bin/rails senren:locales vi` as the docs write it. As a rake task only,
    # Rails handed `vi` to rake as a second task name and failed with
    # `Unrecognized command "vi"`; the only spelling that worked was
    # `bin/rails 'senren:locales[vi]'`. A Rails command receives the words after
    # it as arguments, the same way senren:add does.
    class LocalesCommand < ::Rails::Command::Base
      class_option :force, type: :boolean, default: false,
                           desc: 'Replace a locale file that already exists with the shipped one.'

      desc 'locales LOCALE [LOCALE...]',
           'Copy shipped Senren translations into config/locales.'
      def perform(*names)
        require_application!

        locale_installer.install(locales: names.flat_map { |name| name.split(',') }, force: options[:force])
      rescue ArgumentError => e
        # The message alone, as the rake task prints it. Rails does not rescue
        # an error raised from a command, so raising printed a Thor backtrace
        # with the one line that says what to type buried at the top of it.
        abort e.message
      end

      private

      def locale_installer
        Senren::Rails::LocaleInstaller.new
      end
    end
  end
end
