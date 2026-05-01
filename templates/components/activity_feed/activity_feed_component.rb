# frozen_string_literal: true

module Senren
  class ActivityFeedComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @items = Array(items)
    end

    attr_reader :items

    def item_value(item, key)
      item.is_a?(Hash) ? (item[key] || item[key.to_s]) : nil
    end
  end
end
