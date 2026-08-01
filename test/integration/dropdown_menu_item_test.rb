# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

# A dropdown item has to survive being given attributes.
#
# Both of these shipped broken: passing `data:` replaced the item's own action
# binding, and `method:` produced a `method` attribute on an anchor, which has
# done nothing since Rails dropped rails-ujs. Found while building a role menu
# that needed a PATCH.
class DropdownMenuItemTest < ViewComponent::TestCase
  def render_menu(**item_args)
    render_inline(Senren::DropdownMenuComponent.new) do |menu|
      menu.with_trigger { 'Open' }
      menu.with_item(**item_args) { 'Admin' }
    end
    page
  end

  def test_an_item_keeps_its_own_action_when_given_no_data
    html = render_menu(href: '/roles/admin').native.to_html

    assert_includes html, 'senren--dropdown-menu#close'
    assert_includes html, 'senren--dropdown-menu#onItemKey'
  end

  # The regression: caller data used to overwrite the action hash wholesale.
  def test_caller_data_is_merged_with_the_item_action_not_substituted_for_it
    html = render_menu(href: '/roles/admin', data: { turbo_method: :patch }).native.to_html

    assert_includes html, 'senren--dropdown-menu#close',
                    'caller data must not remove close-on-click'
    assert_includes html, 'data-turbo-method="patch"'
  end

  def test_method_is_translated_to_a_turbo_method_attribute
    html = render_menu(href: '/roles/admin', method: :patch).native.to_html

    assert_includes html, 'data-turbo-method="patch"',
                    'method: must reach Turbo, not render an inert anchor attribute'
    assert_includes html, 'senren--dropdown-menu#close'
  end

  def test_method_and_caller_data_coexist
    html = render_menu(href: '/roles/admin', method: :delete, data: { confirm: 'Sure?' }).native.to_html

    assert_includes html, 'data-turbo-method="delete"'
    assert_includes html, 'data-confirm="Sure?"'
    assert_includes html, 'senren--dropdown-menu#close'
  end

  def test_a_button_item_also_keeps_its_action_alongside_caller_data
    html = render_menu(data: { testid: 'role-admin' }).native.to_html

    assert_includes html, '<button'
    assert_includes html, 'data-testid="role-admin"'
    assert_includes html, 'senren--dropdown-menu#onItemKey'
  end

  # The URL policy still applies to an item's href.
  def test_an_unsafe_href_is_still_neutralised
    html = render_menu(href: 'javascript:alert(1)').native.to_html

    refute_includes html, 'javascript:'
  end
end
