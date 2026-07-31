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

      def test_validation_rejects_unknown_component_keys
        registry = registry_with(
          'button' => component_data('button').merge('unexpected' => true)
        )

        error = assert_raises(RuntimeError) { registry.validate! }

        assert_includes error.message, 'button: unknown keys unexpected'
      end

      def test_validation_rejects_file_paths_outside_component_contract
        registry = registry_with(
          'button' => component_data('button').merge('files' => ['app/components/senren/../unsafe.rb'])
        )

        error = assert_raises(RuntimeError) { registry.validate! }

        assert_includes error.message, 'button: invalid file path "app/components/senren/../unsafe.rb"'
      end

      # The per-component file allowlist is built from the component name, so
      # an unconstrained name would validate a traversal path against itself.
      def test_validation_rejects_component_names_that_are_not_plain_identifiers
        [
          '../../../../tmp/pwn',
          'Button',
          'drop down',
          '_leading',
          'trailing-dash'
        ].each do |bad_name|
          registry = registry_with(bad_name => component_data(bad_name))

          error = assert_raises(RuntimeError) { registry.validate! }

          assert_includes error.message, 'invalid component name',
                          "#{bad_name.inspect} must be rejected"
        end
      end

      # NAME_PATTERN is only checked inside validate!, and validate! is only
      # reached through load!. A production path that built a Registry directly
      # would carry unvalidated names into ComponentCopier#source_for, which
      # interpolates the name into a filesystem path. Tests construct registries
      # directly on purpose; nothing else may.
      def test_no_production_code_builds_a_registry_without_validating_it
        root = File.expand_path('../..', __dir__)
        offenders = Dir[File.join(root, '{lib,bin,scripts}/**/*')].select do |path|
          File.file?(path) && File.read(path).match?(/Registry\.new\b/)
        end

        assert_empty offenders.map { |p| p.delete_prefix("#{root}/") },
                     'production code must go through Registry.load!, which validates'
      end

      def test_load_bang_always_validates
        source = File.read(File.expand_path('../../lib/senren/rails/registry.rb', __dir__))
        body = source[/def self\.load!.*?^      end/m]

        refute_nil body
        assert_match(/validate!/, body, 'load! must validate before returning a registry')
      end

      def test_validation_accepts_conventional_component_names
        registry = registry_with('dropdown_menu' => component_data('dropdown_menu'))

        registry.validate!
      end

      def test_validation_requires_client_controller_file
        registry = registry_with(
          'dialog' => component_data('dialog').merge(
            'client' => true,
            'can_have_client' => true,
            'controller' => 'senren--dialog',
            'files' => [
              'app/components/senren/dialog_component.rb',
              'app/components/senren/dialog_component.html.erb'
            ]
          )
        )

        error = assert_raises(RuntimeError) { registry.validate! }

        assert_includes error.message, 'dialog: client=true requires a Stimulus controller file'
      end

      private

      def registry_with(components)
        Senren::Rails::Registry.new(
          { 'components' => components },
          { 'groups' => [] },
          { 'recipes' => {} }
        )
      end

      def component_data(name)
        {
          'category' => 'actions',
          'client' => false,
          'can_have_client' => true,
          'files' => [
            "app/components/senren/#{name}_component.rb",
            "app/components/senren/#{name}_component.html.erb"
          ],
          'depends_on' => [],
          'pairs_with' => [],
          'variants' => [],
          'accessibility' => [],
          'ai' => { 'use_for' => [], 'avoid' => [] }
        }
      end
    end
  end
end
