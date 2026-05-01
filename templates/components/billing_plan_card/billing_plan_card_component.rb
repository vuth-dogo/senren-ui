# frozen_string_literal: true

module Senren
  class BillingPlanCardComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))]',
      current: 'border-[hsl(var(--senren-accent))]',
      recommended: 'border-[hsl(var(--senren-primary))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(name: nil, price: nil, interval: nil, description: nil, features: [], cta_label: nil, cta_href: nil,
                   badge: nil, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @name = name
      @price = price
      @interval = interval
      @description = description
      @features = Array(features)
      @cta_label = cta_label
      @cta_href = cta_href
      @badge = badge
    end

    attr_reader :name, :price, :interval, :description, :features, :cta_label, :cta_href, :badge
  end
end
