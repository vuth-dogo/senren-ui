# frozen_string_literal: true

module Senren
  class SidebarComponent < BaseComponent
    VARIANTS = {
      default: 'w-64',
      compact: 'w-20'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], brand: 'Senren', variant: :default, label: 'Primary', class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @items = normalize_items(items)
      @brand = brand
      @label = label
    end

    attr_reader :items, :brand, :label

    private

    def normalize_items(items)
      Array(items).map do |item|
        if item.is_a?(Hash)
          {
            label: item[:label] || item['label'],
            href: safe_url(item[:href] || item['href']),
            active: item[:active] || item['active']
          }
        else
          label, href = item
          { label: label, href: safe_url(href), active: false }
        end
      end
    end
  end
end
