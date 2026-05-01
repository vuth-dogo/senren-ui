# frozen_string_literal: true

module Senren
  class TableComponent < BaseComponent
    VARIANTS = {
      default: '',
      compact: 'text-xs'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(columns: [], rows: [], caption: nil, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @columns = Array(columns)
      @rows = Array(rows)
      @caption = caption
    end

    attr_reader :columns, :rows, :caption

    def cell_value(row, column)
      key = column_key(column)
      row.is_a?(Hash) ? (row[key] || row[key.to_s]) : row[key.to_i]
    end

    def column_label(column)
      column.is_a?(Hash) ? (column[:label] || column['label']) : column.to_s.titleize
    end

    private

    def column_key(column)
      column.is_a?(Hash) ? (column[:key] || column['key']) : column
    end
  end
end
