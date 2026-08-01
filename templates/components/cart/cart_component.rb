# frozen_string_literal: true

module Senren
  # A shopping cart: line items with quantity steppers, a live subtotal, and
  # removal.
  #
  # The server owns the cart. This component owns the widget. The Stimulus
  # controller only does what does not round-trip pleasantly — stepping a
  # quantity and recomputing the displayed subtotal while the user clicks — and
  # announces the result with senren--cart:changed so a host app can update a
  # header badge without reaching inside.
  #
  # Money arrives twice, and on purpose: `price` already formatted for display,
  # and `price_cents` as an integer for arithmetic. Formatting is locale- and
  # money-library-specific and belongs to the host app. Doing arithmetic on a
  # formatted string is how currency bugs start.
  class CartComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))]',
      flush: 'border-transparent shadow-none'
    }.freeze

    SIZES = { md: '' }.freeze

    def initialize(items: [], currency: '$', title: 'Cart', empty_text: 'Your cart is empty.',
                   checkout_url: nil, checkout_label: 'Checkout', variant: :default,
                   id: nil, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @items = Array(items).map { |item| normalize_item(item) }
      @currency = currency
      @title = title
      @empty_text = empty_text
      @checkout_url = checkout_url
      @checkout_label = checkout_label
      @dom_id = id || senren_dom_id(title)
    end

    attr_reader :items, :currency, :title, :empty_text, :checkout_label, :dom_id

    def empty? = items.empty?
    def total_quantity = items.sum { |item| item[:quantity] }
    def subtotal_cents = items.sum { |item| item[:price_cents] * item[:quantity] }
    def subtotal = format_cents(subtotal_cents)
    def line_total(item) = format_cents(item[:price_cents] * item[:quantity])
    def safe_checkout_url = @checkout_url && safe_url(@checkout_url)

    # Kept public so the same rendering is available to a host app updating a
    # line through a Turbo Stream.
    # Kernel.format explicitly: ViewComponent::Base defines its own `format`
    # (the current template format, taking no arguments), which shadows
    # Kernel#format inside a component. On Rails 8.x this happened to resolve;
    # on 7.1 it raised "wrong number of arguments (given 2, expected 0)" as soon
    # as the call ran inside a tag block. Caught by the version matrix.
    def format_cents(cents)
      "#{currency}#{Kernel.format('%.2f', cents.to_i / 100.0)}"
    end

    private

    def normalize_item(item)
      {
        id: item[:id] || item['id'],
        name: item[:name] || item['name'],
        price_cents: (item[:price_cents] || item['price_cents']).to_i,
        quantity: [(item[:quantity] || item['quantity'] || 1).to_i, 1].max,
        image_url: item[:image_url] || item['image_url'],
        remove_url: item[:remove_url] || item['remove_url']
      }
    end
  end
end
