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

  # `class:` had the same defect `data:` did, and the fix for `data:` was never
  # extended to it. Losing the item's own classes costs more than looks:
  # `focus:bg-` is the only indication a keyboard user has of where they are in
  # the menu, so arrow-key navigation goes silent.
  def test_caller_classes_are_merged_with_the_item_styles
    html = render_menu(href: '/x', class: 'font-bold').native.to_html

    assert_includes html, 'font-bold'
    assert_includes html, 'hover:bg-', 'caller class must not replace the item styles'
    assert_includes html, 'focus:bg-', 'a keyboard user needs the focus indicator'
  end

  def test_class_name_and_class_both_survive
    html = render_menu(href: '/x', class_name: 'ml-2', class: 'font-bold').native.to_html

    assert_includes html, 'ml-2'
    assert_includes html, 'font-bold'
    assert_includes html, 'focus:bg-'
  end

  # A caller binding its own action must not lose the menu's -- closing on click
  # and arrow-key handling are what make it a menu.
  def test_a_caller_action_is_appended_to_the_item_action
    html = render_menu(href: '/x', data: { action: 'click->analytics#track' }).native.to_html

    assert_includes html, 'senren--dropdown-menu#close'
    assert_includes html, 'analytics#track'
  end

  # Turbo reads data-turbo-method on links. On a <button> it does nothing, so
  # emitting it there advertises behaviour that cannot happen.
  def test_method_without_href_does_not_emit_an_inert_attribute
    html = render_menu(method: :delete).native.to_html

    assert_includes html, '<button'
    refute_includes html, 'data-turbo-method',
                    'a button cannot act on data-turbo-method; Turbo only reads it on <a>'
  end

  # The append only ran for a Symbol key. `data: { "action" => ... }` skipped it
  # and the tag builder then kept the caller's value alone, so ITEM_ACTION
  # vanished -- no close-on-click, no arrow keys. Worse than the bug the append
  # was written to fix, and invisible because the original test only ever passed
  # a Symbol.
  def test_a_string_data_key_is_treated_the_same_as_a_symbol
    html = render_menu(href: '/x', data: { 'action' => 'click->analytics#track' }).native.to_html

    assert_includes html, 'senren--dropdown-menu#close'
    assert_includes html, 'senren--dropdown-menu#onItemKey'
    assert_includes html, 'analytics#track'
  end

  def test_a_string_class_key_is_merged_too
    html = render_menu(href: '/x', 'class' => 'font-bold').native.to_html

    assert_includes html, 'font-bold'
    assert_includes html, 'focus:bg-'
  end
end
