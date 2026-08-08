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

  # Appending is only half of it: the result has to be a valid identifier list.
  #
  # A caller who names the component's own controller alongside theirs -- which
  # is what you write if you are not sure whether the component sets it, and what
  # copying an existing data-controller produces -- got it twice. The merge did
  # dedupe, but on the two whole strings, so "a senren--popover" and
  # "senren--popover" compared unequal and both went through.
  #
  # Stimulus takes that list literally. The same controller connects twice on one
  # element and every action fires twice, so a toggle opens and immediately
  # closes: an intermittent-looking bug with no error attached to it.
  def test_a_repeated_controller_token_appears_once
    duplicated = WRAPPERS.reject do |name|
      own = "senren--#{name.tr('_', '-')}"
      value = root(name, data: { controller: "my-analytics #{own}" })&.attr('data-controller').to_s
      value.split.count(own) == 1 && value.include?('my-analytics')
    end

    assert_empty duplicated,
                 'these emit their own controller twice, so Stimulus connects it twice and every ' \
                 "action fires twice: #{duplicated.join(', ')}"
  end

  # data-action is the same list, and the case that actually reaches users:
  # a dropdown item that tracks clicks is written by copying the existing action.
  def test_a_repeated_action_token_appears_once
    render_inline(Senren::DropdownMenuComponent.new) do |menu|
      menu.with_trigger { 'Open' }
      menu.with_item(href: '/x', data: { action: 'click->analytics#track click->senren--dropdown-menu#close' }) { 'A' }
    end
    value = Nokogiri::HTML5.fragment(page.native.to_html).at_css('a[role="menuitem"]')['data-action'].to_s

    assert_equal 1, value.split.count('click->senren--dropdown-menu#close'), value
    assert_includes value, 'click->analytics#track'
  end

  # dropdown_menu also writes data-state on its root; a caller's own state must
  # not knock it out.
  def test_component_owned_data_survives_alongside_caller_data
    root = root('dropdown_menu', data: { controller: 'my-analytics', testid: 'menu' })

    assert_equal 'closed', root.attr('data-state')
    assert_equal 'menu', root.attr('data-testid')
  end
end
