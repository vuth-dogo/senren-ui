# frozen_string_literal: true

module Senren
  class BreadcrumbComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], label: 'Breadcrumb', separator: '/', class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @items = normalize_items(items)
      @label = label
      @separator = separator
    end

    attr_reader :items, :label, :separator

    private

    def normalize_items(items)
      Array(items).map do |item|
        if item.is_a?(Hash)
          { label: item.fetch(:label) { item.fetch('label') }, href: safe_url(item[:href] || item['href'], fallback: nil) }
        else
          label, href = item
          { label: label, href: safe_url(href, fallback: nil) }
        end
      end
    end
  end
end
