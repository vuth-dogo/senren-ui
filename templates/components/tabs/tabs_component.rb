# frozen_string_literal: true

module Senren
  class TabsComponent < BaseComponent
    VARIANTS = {
      default: 'rounded-(--senren-radius) bg-[hsl(var(--senren-muted))] p-1',
      underline: 'border-b border-[hsl(var(--senren-border))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], variant: :default, active: nil, label: 'Tabs', class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @items = normalize_items(items)
      @active = active&.to_s || @items.first&.fetch(:id, nil)
      @label = label
    end

    attr_reader :items, :active, :label

    def active_item?(item)
      item[:id].to_s == active.to_s
    end

    private

    def normalize_items(items)
      Array(items).map.with_index do |item, index|
        source = item.is_a?(Hash) ? item : { label: item.to_s }
        label = source[:label] || source['label'] || "Tab #{index + 1}"
        id = (source[:id] || source['id'] || label.to_s.parameterize).to_s
        { id: id, label: label, content: source[:content] || source['content'] }
      end
    end
  end
end
