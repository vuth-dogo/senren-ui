# frozen_string_literal: true

require 'rails/command'
require 'senren/rails'

module Senren
  module Command
    class AddCommand < ::Rails::Command::Base
      class_option :client, type: :boolean, default: nil,
                            desc: 'Override registry client behavior for installed components.'
      class_option :force, type: :boolean, default: false,
                           desc: 'Overwrite existing component files.'

      desc 'add COMPONENT [COMPONENT...]',
           'Install one or more Senren components into the current Rails app.'
      def perform(*names)
        require_application!

        component_installer.install(
          names: names,
          client_override: options[:client],
          force: options[:force]
        )
      rescue ArgumentError => e
        # The message alone, as the rake task prints it. Rails does not rescue
        # an error raised from a command, so raising printed a Thor backtrace
        # with the one line that says what to type buried at the top of it.
        abort e.message
      end

      private

      def component_installer
        Senren::Rails::ComponentInstaller.new
      end
    end
  end
end
