# frozen_string_literal: true

require_relative '../application_system_test_case'

class ComponentsKitchenSinkTest < ApplicationSystemTestCase
  test 'kitchen sink renders every registered component preview' do
    visit '/components/kitchen_sink'

    assert_text 'Senren Kitchen Sink'

    Senren::Rails::Registry.load!.names.each do |name|
      assert_selector %(section[data-preview-component="#{name}"])
    end

    assert_no_text 'Missing preview'
    assert_dom_node_budget :kitchen_sink_dom_nodes
    assert_no_external_ui_framework_resources
  end
end
