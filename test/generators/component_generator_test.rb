# frozen_string_literal: true

require 'test_helper'
require 'rails/generators'
require 'generators/senren/component/component_generator'

module Senren
  module Generators
    class ComponentGeneratorTest < Minitest::Test
      def test_client_option_is_enabled_by_default
        option = Senren::Generators::ComponentGenerator.class_options.fetch(:client)

        assert_equal true, option.instance_variable_get(:@default)
      end
    end
  end
end
