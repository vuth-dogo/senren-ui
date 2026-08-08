# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

# Stimulus reads `data-controller` as a space-separated list, so a caller can
# legitimately attach their own controller to a Senren component. Replacing the
# value instead of appending silently unbinds the component's own behaviour.
#
# ItemTag already learned this for data-action. The same reasoning was never
# applied to data-controller, and the passthrough test that was supposed to
# cover attributes used a key nothing collided with.
class ControllerPassthroughTest < ViewComponent::TestCase
  WRAPPERS = %w[dialog alert_dialog sheet popover dropdown_menu context_menu hover_card tooltip].freeze

  REQUIRED = { 'tooltip' => { text: 'T' } }.freeze

  def root(name, **args)
    klass = "Senren::#{name.split('_').map { |w| w[0].upcase + w[1..] }.join}Component"
    render_inline(klass.constantize.new(**REQUIRED.fetch(name, {}), **args)) { 'c' }
    Nokogiri::HTML5.fragment(page.native.to_html).at_css(%([data-senren-component="#{name}"]))
  end

  def test_a_caller_controller_is_appended_not_substituted
    broken = WRAPPERS.reject do |name|
      value = root(name, data: { controller: 'my-analytics' })&.attr('data-controller').to_s
      value.include?('my-analytics') && value.include?("senren--#{name.tr('_', '-')}")
    end

    assert_empty broken, "these lose either the caller's controller or their own: #{broken.join(', ')}"
  end

  def test_a_string_keyed_controller_is_handled_the_same_way
    value = root('popover', data: { 'controller' => 'my-analytics' })&.attr('data-controller').to_s

    assert_includes value, 'my-analytics'
    assert_includes value, 'senren--popover'
  end

  # dropdown_menu also writes data-state on its root; a caller's own state must
  # not knock it out.
  def test_component_owned_data_survives_alongside_caller_data
    root = root('dropdown_menu', data: { controller: 'my-analytics', testid: 'menu' })

    assert_equal 'closed', root.attr('data-state')
    assert_equal 'menu', root.attr('data-testid')
  end
end
