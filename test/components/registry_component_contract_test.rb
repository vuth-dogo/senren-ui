# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/string/inflections'
require 'view_component'

module Senren
  class RegistryComponentContractTest < Minitest::Test
    TEMPLATE_ROOT = File.expand_path('../../templates/components', __dir__)
    CONTROLLER_ROOT = File.expand_path('../../templates/controllers', __dir__)

    def setup
      @registry = Rails::Registry.load!(
        components_path: File.expand_path('../../registry/components.yml', __dir__),
        groups_path: File.expand_path('../../registry/groups.yml', __dir__),
        recipes_path: File.expand_path('../../registry/recipes.yml', __dir__)
      )
      load_component_classes
    end

    def test_registered_components_expose_registry_public_options
      @registry.find_each do |component|
        component_class = self.class.component_class_for(component.name)
        expected_options = component.variants.map(&:to_sym)
        exposed_options = self.class.exposed_options_for(component_class)

        assert_empty expected_options - exposed_options,
                     "#{component.name} registry variants must be exposed by VARIANTS or SIZES"
      end
    end

    def test_registered_components_define_size_constants
      @registry.find_each do |component|
        component_class = self.class.component_class_for(component.name)

        assert component_class.const_defined?(:SIZES), "#{component.name} missing SIZES"
        assert component_class::SIZES.is_a?(Hash), "#{component.name} SIZES must be a hash"
      end
    end

    def test_registered_component_classes_inherit_from_base_component
      @registry.find_each do |component|
        component_class = self.class.component_class_for(component.name)

        assert_operator component_class, :<, BaseComponent, "#{component.name} must inherit from BaseComponent"
      end
    end

    def test_client_components_have_controller_template
      @registry.all.select(&:client?).each do |component|
        controller_path = File.join(CONTROLLER_ROOT, "#{component.name}_controller.js")

        assert File.file?(controller_path), "#{component.name} missing controller template"
      end
    end

    def test_component_templates_use_registered_root_marker
      @registry.find_each do |component|
        template_path = File.join(TEMPLATE_ROOT, component.name, "#{component.name}_component.html.erb")

        template = File.read(template_path)
        uses_root_marker = template.include?('root_attrs') ||
                           template.include?('senren_component') ||
                           template.include?('data-senren-component') ||
                           template.include?('NativeSelectComponent') ||
                           template.include?('InputComponent')

        assert uses_root_marker, "#{component.name} template should emit a Senren root marker"
      end
    end

    def self.component_class_for(component_name)
      Senren.const_get("#{component_name.camelize}Component")
    end

    def self.exposed_options_for(component_class)
      variants = component_class.const_defined?(:VARIANTS) ? component_class::VARIANTS.keys : []
      sizes = component_class.const_defined?(:SIZES) ? component_class::SIZES.keys : []

      (variants + sizes).uniq
    end

    private

    def load_component_classes
      return if self.class.component_classes_loaded?

      unless defined?(BaseComponent)
        load File.expand_path('../../lib/generators/senren/install/templates/base_component.rb.tt', __dir__)
      end

      @registry.dependencies(@registry.names).each do |name|
        next if Senren.const_defined?("#{name.camelize}Component", false)

        load File.join(TEMPLATE_ROOT, name, "#{name}_component.rb")
      end

      self.class.component_classes_loaded = true
    end

    class << self
      attr_accessor :component_classes_loaded

      alias component_classes_loaded? component_classes_loaded
    end
  end
end
