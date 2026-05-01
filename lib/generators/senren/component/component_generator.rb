# frozen_string_literal: true

require 'rails/generators/named_base'
require 'senren/rails'

module Senren
  module Generators
    # Low-level generator for creating a custom component in the host app.
    #
    #   bin/rails generate senren:component picker
    #   bin/rails generate senren:component picker --no-client
    class ComponentGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      class_option :client, type: :boolean, default: true,
                            desc: 'Generate a Stimulus controller alongside the component.'

      def create_component_class
        template 'component.rb.tt',
                 "app/components/senren/#{file_name}_component.rb"
      end

      def create_component_template
        template 'component.html.erb.tt',
                 "app/components/senren/#{file_name}_component.html.erb"
      end

      def create_component_test
        template 'component_test.rb.tt',
                 "test/components/senren/#{file_name}_component_test.rb"
      end

      def create_stimulus_controller
        return unless options[:client]

        template 'controller.js.tt',
                 "app/javascript/controllers/senren/#{file_name}_controller.js"
      end

      def create_system_test
        return unless options[:client]

        template 'system_test.rb.tt',
                 "test/system/senren/#{file_name}_test.rb"
      end

      private

      def file_name
        super.underscore
      end

      def class_name
        file_name.camelize
      end

      def stimulus_identifier
        "senren--#{file_name.dasherize}"
      end
    end
  end
end
