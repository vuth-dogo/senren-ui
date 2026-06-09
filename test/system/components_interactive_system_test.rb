# frozen_string_literal: true

require_relative '../application_system_test_case'

class ComponentsInteractiveSystemTest < ApplicationSystemTestCase
  EXPECTED_CONTROLLERS = %w[
    senren--accordion
    senren--collapsible
    senren--combobox
    senren--dialog
    senren--dropdown-menu
    senren--rich-text-editor-lite
    senren--tabs
  ].freeze

  test 'interactive components lazy-load only the controllers present on the page' do
    visit '/components/interactive'

    assert_text 'Senren Interactive Preview'
    assert_loaded_senren_controllers EXPECTED_CONTROLLERS
    assert_operator loaded_senren_controllers.size, :<, 25
    assert_dom_node_budget :interactive_dom_nodes
    assert_no_external_ui_framework_resources
  end

  test 'representative interactive components respond in the browser' do
    visit '/components/interactive'
    assert_loaded_senren_controllers EXPECTED_CONTROLLERS
    install_performance_observers

    assert_interaction_budget('dialog-open', 'document.getElementById("dialog-open").click()')
    assert_selector '[role="dialog"]', text: 'Dialog title', visible: true
    find('[role="dialog"]').send_keys(:escape)
    assert_no_selector '[role="dialog"]', visible: true

    click_button 'Menu actions'
    assert_selector '[role="menu"]', text: 'Second action', visible: true

    click_button 'Details'
    assert_selector '#details-panel', text: 'Details panel', visible: true

    click_button 'Advanced'
    assert_text 'Advanced content'

    click_button 'More options'
    assert_text 'Hidden options'

    click_button 'Choose status'
    fill_in 'Choose status', with: 'Pub'
    click_button 'Published'
    assert_equal 'published', page.evaluate_script('document.querySelector("input[name=status]").value')

    find('[role="textbox"]').send_keys(' extra')
    assert_includes page.evaluate_script('document.querySelector("textarea[name=body]").value'), 'extra'
    assert_no_long_tasks_over_budget
  end
end
