# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

# CartComponent documented `remove_url:` per item, normalised it in
# normalize_item, and then wrote it nowhere. Removal is client-side -- the
# controller drops the line, recalculates, and dispatches `senren--cart:removed`
# for the application to act on -- so the URL was the one piece of information
# the listener needed and the only one it could not get.
#
# An input that is accepted, validated and discarded is worse than one that is
# rejected: the caller has no signal that nothing happened.
class CartRemoveUrlTest < ViewComponent::TestCase
  def item(**over)
    { id: 'sku-1', name: 'Mug', price_cents: 1450, quantity: 1 }.merge(over)
  end

  def line_for(**over)
    render_inline(Senren::CartComponent.new(checkout_url: '/checkout', items: [item(**over)]))
    Nokogiri::HTML5.fragment(page.native.to_html).at_css("[data-senren--cart-target='line']")
  end

  def test_a_remove_url_reaches_the_line_element
    assert_equal '/cart/items/sku-1', line_for(remove_url: '/cart/items/sku-1')['data-remove-url']
  end

  def test_a_string_keyed_remove_url_works_the_same
    render_inline(
      Senren::CartComponent.new(checkout_url: '/checkout',
                                items: [{ 'id' => 'sku-1', 'name' => 'Mug', 'price_cents' => 1450,
                                          'remove_url' => '/cart/items/sku-1' }])
    )
    line = Nokogiri::HTML5.fragment(page.native.to_html).at_css("[data-senren--cart-target='line']")

    assert_equal '/cart/items/sku-1', line['data-remove-url']
  end

  # Omitted rather than emitted empty, so `dataset.removeUrl` is undefined and
  # the listener can tell "no URL configured" from "URL is the empty string".
  def test_no_attribute_when_no_remove_url_was_given
    assert_nil line_for['data-remove-url']
  end

  # Same sink discipline as every other URL the library renders. A cart is fed
  # from application data, and an item name or URL that came from a supplier
  # feed is not trusted input.
  def test_a_javascript_url_is_not_rendered
    refute_includes line_for(remove_url: 'javascript:alert(1)')['data-remove-url'].to_s, 'javascript'
  end
end
