# frozen_string_literal: true

module Senren
  class SidebarComponent < BaseComponent
    VARIANTS = {
      default: 'w-64',
      compact: 'w-20'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], brand: senren_t('sidebar.brand', default: 'Senren'), variant: :default,
                   label: senren_t('sidebar.label', default: 'Primary'), class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @items = normalize_items(items)
      @brand = brand
      @label = label
    end

    attr_reader :items, :brand, :label

    def toggle_label = senren_t('sidebar.toggle', default: 'Toggle sidebar')

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
