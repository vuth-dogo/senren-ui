# frozen_string_literal: true

module Senren
  # A product tile with an add-to-cart action.
  #
  # Adding to a cart is an ordinary form submission, so this component ships no
  # Stimulus controller. That is deliberate: a listing page renders this tile
  # many times, and a controller here would download JavaScript on a page that
  # does not need any.
  #
  # Price is passed in already formatted. Currency formatting is locale- and
  # money-library-specific and belongs to the host app; a UI library that
  # guesses gets it wrong in another country.
  class ProductCardComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))]',
      featured: 'border-[hsl(var(--senren-primary))] ring-1 ring-[hsl(var(--senren-primary)/0.35)]'
    }.freeze

    SIZES = { md: '' }.freeze

    def initialize(title:, price:, url:, image_url: nil, description: nil, badge: nil,
                   action_label: 'Add to cart', available: true, method: :post,
                   variant: :default, id: nil, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @title = title
      @price = price
      @url = url
      @image_url = image_url
      @description = description
      @badge = badge
      @action_label = action_label
      @available = available
      @method = method
      @dom_id = id || senren_dom_id(title)
    end

    attr_reader :title, :price, :image_url, :description, :badge, :action_label, :method, :dom_id

    def available? = @available == true

    # Untrusted values reach href/src attributes, so both go through the shared
    # guards rather than being interpolated directly.
    def safe_action_url = safe_url(@url)
    def safe_image_url = safe_media_url(@image_url)

    def button_label = available? ? action_label : 'Out of stock'
  end
end
