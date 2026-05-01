# frozen_string_literal: true

module Senren
  class BulkActionBarComponent < BaseComponent
    renders_one :actions

    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(selected_count: nil, item_label: 'items', class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @selected_count = selected_count
      @item_label = item_label
    end

    attr_reader :selected_count, :item_label

    def selection_text
      return nil if selected_count.nil?

      "#{selected_count} #{item_label} selected"
    end
  end
end
