# frozen_string_literal: true

require_relative '../application_integration_test_case'

# Renders every registered component on whatever Rails version is loaded.
#
# The audit that produced this file: `bin/matrix` runs `rake test`, the Rakefile
# excludes `test/system/**`, and the only test that rendered all 62 components
# was the kitchen-sink *system* test. So a green matrix proved the library code
# worked on Rails 7.1-8.1 while proving nothing about whether a single component
# rendered on any version but the newest.
#
# `test/components/` covers three components in depth;
# `registry_component_contract_test.rb` checks constants and inheritance but
# never calls render. This closes the gap without a browser, so it costs about a
# second per matrix leg.
class ComponentRenderingTest < ApplicationIntegrationTestCase
  def registry
    @registry ||= Senren::Rails::Registry.load!
  end

  def test_every_registered_component_renders
    get '/components/kitchen_sink'

    assert_response :success

    missing = registry.names.reject { |name| response.body.include?(%(data-preview-component="#{name}")) }

    assert_empty missing, "components absent from the rendered page: #{missing.join(', ')}"
    assert_operator registry.names.size, :>=, 60, 'sanity: the registry should be fully loaded'
  end

  # The preview helper raises rather than rendering a placeholder when a
  # component has no representative usage, so this catches a component added to
  # the registry without one.
  def test_no_component_falls_back_to_a_missing_preview
    get '/components/kitchen_sink'

    refute_includes response.body, 'Missing preview'
  end

  def test_static_preview_renders
    get '/components/static'

    assert_response :success
    assert_includes response.body, 'data-senren-component'
  end

  def test_interactive_preview_renders_and_declares_its_controllers
    get '/components/interactive'

    assert_response :success

    %w[senren--dialog senren--dropdown-menu senren--tabs senren--accordion].each do |identifier|
      assert_includes response.body, identifier, "#{identifier} must be declared in the markup"
    end
  end

  # The red-team page carries the components whose markup the security tests
  # depend on; if it stops rendering, those tests would pass against an empty
  # page.
  def test_red_team_preview_renders_its_components
    get '/components/red_team'

    assert_response :success
    assert_includes response.body, 'senren--rich-text-editor-lite'
    assert_includes response.body, 'senren--data-table'
    assert_includes response.body, 'data-sort-key'
  end

  def test_rendered_markup_carries_no_unescaped_event_handlers
    %w[/components/static /components/interactive /components/kitchen_sink].each do |path|
      get path

      assert_response :success
      refute_match(/\son(?:error|load|click)\s*=/i, response.body,
                   "#{path} must not emit inline event handlers")
    end
  end
end
