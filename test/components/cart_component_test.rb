# frozen_string_literal: true

require 'test_helper'
require 'action_view'
require 'active_support/core_ext/string/inflections'
require 'view_component'

unless defined?(Senren::BaseComponent)
  load File.expand_path('../../lib/generators/senren/install/templates/base_component.rb.tt', __dir__)
end

unless defined?(Senren::CartComponent)
  load File.expand_path('../../templates/components/cart/cart_component.rb', __dir__)
end

unless defined?(Senren::ProductCardComponent)
  load File.expand_path('../../templates/components/product_card/product_card_component.rb', __dir__)
end

module Senren
  # The arithmetic is plain Ruby, so it is tested directly rather than through a
  # render harness. Rendering, variants, determinism, and the structural
  # accessibility rules are covered by the registry-driven suites in
  # test/integration, which picked both components up as soon as they had a
  # preview.
  class CartComponentTest < Minitest::Test
    ITEMS = [
      { id: 'sku-1', name: 'Mug', price_cents: 1_450, quantity: 2 },
      { id: 'sku-2', name: 'Notebook', price_cents: 890, quantity: 1 }
    ].freeze

    def cart(**overrides)
      CartComponent.new(items: ITEMS, **overrides)
    end

    def test_subtotal_multiplies_price_by_quantity
      assert_equal 3_790, cart.subtotal_cents
      assert_equal '$37.90', cart.subtotal
    end

    def test_line_total_is_per_line
      assert_equal '$29.00', cart.line_total(cart.items.first)
      assert_equal '$8.90', cart.line_total(cart.items.last)
    end

    def test_total_quantity_sums_lines
      assert_equal 3, cart.total_quantity
    end

    # Money is formatted from integer cents. Doing arithmetic on a formatted
    # string is how currency bugs start, so the component takes both.
    def test_formatting_pads_and_respects_currency
      assert_equal '$0.05', cart.format_cents(5)
      assert_equal '$10.00', cart.format_cents(1_000)
      assert_equal '€12.34', cart(currency: '€').format_cents(1_234)
    end

    def test_quantity_below_one_is_clamped
      clamped = CartComponent.new(items: [{ id: 'a', name: 'X', price_cents: 100, quantity: 0 }])

      assert_equal 1, clamped.items.first[:quantity]
      assert_equal 100, clamped.subtotal_cents
    end

    def test_string_keyed_items_are_accepted
      from_json = CartComponent.new(items: [{ 'id' => 'a', 'name' => 'X', 'price_cents' => 250, 'quantity' => 2 }])

      assert_equal 'X', from_json.items.first[:name]
      assert_equal 500, from_json.subtotal_cents
    end

    def test_empty_cart_reports_empty_and_zero
      empty = CartComponent.new(items: [])

      assert_predicate empty, :empty?
      assert_equal 0, empty.subtotal_cents
      assert_equal '$0.00', empty.subtotal
    end

    def test_checkout_url_goes_through_the_url_guard
      assert_equal '/checkout', cart(checkout_url: '/checkout').safe_checkout_url
      assert_equal '#', cart(checkout_url: 'javascript:alert(1)').safe_checkout_url
      assert_equal '#', cart(checkout_url: '///evil.example').safe_checkout_url
      assert_nil cart.safe_checkout_url, 'no checkout url means no button'
    end

    def test_ids_are_derived_and_stable
      assert_equal cart.dom_id, cart.dom_id
      assert_equal 'checkout-cart', cart(id: 'checkout-cart').dom_id
      refute_equal cart(title: 'Cart').dom_id, cart(title: 'Basket').dom_id
    end

    def test_product_card_urls_go_through_the_guards
      card = ProductCardComponent.new(title: 'Mug', price: '$1', url: 'javascript:alert(1)',
                                      image_url: '///evil.example/x.png')

      assert_equal '#', card.safe_action_url
      assert_nil card.safe_image_url
    end

    def test_product_card_label_reflects_availability
      available = ProductCardComponent.new(title: 'Mug', price: '$1', url: '/cart')
      sold_out = ProductCardComponent.new(title: 'Mug', price: '$1', url: '/cart', available: false)

      assert_equal 'Add to cart', available.button_label
      assert_equal 'Out of stock', sold_out.button_label
      refute_predicate sold_out, :available?
    end
  end
end
