# frozen_string_literal: true

module Senren
  class TopNavComponent < BaseComponent
    renders_one :brand
    renders_one :actions

    VARIANTS = {
      default: 'bg-[hsl(var(--senren-background))/0.88]',
      solid: 'bg-[hsl(var(--senren-card))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], current_path: nil, label: 'Global', variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @items = normalize_items(items)
      @current_path = current_path
      @label = label
    end

    attr_reader :items, :current_path, :label

    def active_item?(item)
      item[:active] || (current_path && item[:href] == current_path)
    end

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
