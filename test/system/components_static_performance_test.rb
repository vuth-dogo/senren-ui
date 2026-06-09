# frozen_string_literal: true

require_relative '../application_system_test_case'

class ComponentsStaticPerformanceTest < ApplicationSystemTestCase
  test 'static component preview ships no eager Senren controllers' do
    visit '/components/static'

    assert_text 'Senren Static Preview'
    assert_selector '[data-senren-component="button"]', text: 'Primary action'
    assert_equal [], loaded_senren_controllers
    assert_dom_node_budget :static_dom_nodes
    assert_no_external_ui_framework_resources
  end
end
