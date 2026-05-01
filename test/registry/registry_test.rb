# frozen_string_literal: true

require 'test_helper'

module Senren
  module Rails
    class RegistryTest < Minitest::Test
      def setup
        @registry = Senren::Rails::Registry.load!(
          components_path: File.expand_path('../../registry/components.yml', __dir__),
          groups_path: File.expand_path('../../registry/groups.yml', __dir__),
          recipes_path: File.expand_path('../../registry/recipes.yml', __dir__)
        )
      end

      def test_loads_full_catalog
        assert_not_empty @registry.names
        assert_operator @registry.names.size, :>=, 50,
                        'expected the v0.1 registry to have at least 50 components'
      end

      def test_validation_passes
        @registry.validate! # raises on failure
      end

      def test_phase_1_components_present
        %w[button link badge typography separator skeleton avatar alert card aspect_ratio].each do |name|
          assert_not_nil @registry.find(name), "phase 1 component missing: #{name}"
        end
      end

      def test_phase_3_components_marked_client
        %w[dialog alert_dialog dropdown_menu popover tooltip hover_card sheet context_menu].each do |name|
          comp = @registry.fetch(name)
          assert comp.client?, "expected #{name} to be client by default"
          assert_not_nil comp.controller, "expected #{name} to have a Stimulus controller id"
        end
      end

      def test_rich_content_components_are_promoted
        %w[carousel codeblock command rich_text_editor_lite].each do |name|
          comp = @registry.fetch(name)
          assert_not comp.stub?, "expected #{name} to be promoted from stub"
          assert_equal 'rich', comp.category
        end
      end

      def test_dependency_closure_is_topologically_ordered
        deps = @registry.dependencies('dialog')
        assert_includes deps, 'dialog'
        assert_includes deps, 'button'
        assert deps.index('button') < deps.index('dialog'),
               'expected button to be installed before dialog'
      end

      def test_group_lookup
        forms = @registry.group('forms')
        assert_not_empty forms
        forms.each { |c| assert_equal 'forms', c.category }
      end

      def test_recipes_resolve
        assert_not_empty @registry.recipes
        @registry.recipes.each_value do |recipe|
          recipe['components'].each do |name|
            assert_not_nil @registry.find(name), "recipe references unknown component: #{name}"
          end
        end
      end

      def test_unknown_component_raises
        assert_raises(ArgumentError) { @registry.fetch('totally_made_up') }
      end
    end
  end
end
