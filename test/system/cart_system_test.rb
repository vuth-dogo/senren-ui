# frozen_string_literal: true

require_relative '../application_system_test_case'

# The cart in a real browser: stepping quantities, removing lines, and the
# events a host app listens for.
#
# The arithmetic is unit tested in test/components/cart_component_test.rb, and
# rendering is covered by the registry-driven integration suites. What only a
# browser can show is asserted here.
class CartSystemTest < ApplicationSystemTestCase
  def visit_cart
    visit '/components/interactive'
    assert_selector "[data-controller~='senren--cart']"
  end

  def subtotal
    find("[data-senren--cart-target~='subtotal']").text
  end

  def quantities
    all("[data-senren--cart-target~='quantity']").map { |node| node.text.strip }
  end

  test 'the server-rendered subtotal is what paints first' do
    visit_cart

    # 2 x $14.50 + 1 x $8.90
    assert_equal '$37.90', subtotal
    assert_equal %w[2 1], quantities
  end

  test 'stepping a quantity updates that line and the subtotal' do
    visit_cart

    all("[aria-label^='Increase']").first.click

    assert_equal %w[3 1], quantities
    assert_equal '$52.40', subtotal

    all("[aria-label^='Decrease']").first.click

    assert_equal %w[2 1], quantities
    assert_equal '$37.90', subtotal
  end

  # Removing is a separate, explicit action, so a stepper that reached zero
  # would leave a line whose price the user cannot see.
  test 'a quantity never steps below one' do
    visit_cart

    3.times { all("[aria-label^='Decrease']").last.click }

    assert_equal %w[2 1], quantities
    assert_equal '$37.90', subtotal
  end

  test 'removing a line drops it from the subtotal and the count' do
    visit_cart

    all("[aria-label^='Remove']").first.click

    assert_equal %w[1], quantities
    assert_equal '$8.90', subtotal
    assert_equal '1', find("[data-senren--cart-target~='count']").text
  end

  # A host app updates a header badge by listening, not by reaching into the
  # component's internals.
  test 'changes are announced with the new subtotal' do
    visit_cart

    page.execute_script(<<~JS)
      window.__cartEvents = []
      document.addEventListener("senren--cart:changed", (event) => {
        window.__cartEvents.push(event.detail)
      })
      document.addEventListener("senren--cart:removed", (event) => {
        window.__cartEvents.push({ removed: event.detail.id, subtotalCents: event.detail.subtotalCents })
      })
    JS

    all("[aria-label^='Increase']").first.click
    all("[aria-label^='Remove']").last.click

    events = page.evaluate_script('window.__cartEvents')

    assert_equal 2, events.size, 'one change event and one removal event'
    assert_equal 5_240, events.first['subtotalCents']
    assert_equal 'sku-2', events.last['removed']
    assert_equal 4_350, events.last['subtotalCents']
  end

  # The value is the state: setting it from outside, as a Turbo Stream would,
  # must repaint the subtotal without any action being clicked.
  test 'the subtotal value is authoritative' do
    visit_cart

    page.execute_script(<<~JS)
      document
        .querySelector("[data-controller~='senren--cart']")
        .setAttribute("data-senren--cart-subtotal-cents-value", "999")
    JS

    assert_equal '$9.99', subtotal
  end
end
