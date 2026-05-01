module Senren
  class DataTableComponent < BaseComponent
    renders_one :toolbar
    renders_one :footer

    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(columns: [], rows: [], caption: nil, empty_text: 'No records found.', sortable: true,
                   variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @columns = Array(columns)
      @rows = Array(rows)
      @caption = caption
      @empty_text = empty_text
      @sortable = sortable
    end

    attr_reader :columns, :rows, :caption, :empty_text

    def sortable? = !!@sortable

    def cell_value(row, column)
      key = column_key(column)
      row.is_a?(Hash) ? (row[key] || row[key.to_s]) : row[key.to_i]
    end

    def column_label(column)
      column.is_a?(Hash) ? (column[:label] || column['label']) : column.to_s.tr('_', ' ').capitalize
    end

    def column_sort_key(column)
      column_key(column).to_s
    end

    private

    def column_key(column)
      column.is_a?(Hash) ? (column[:key] || column['key']) : column
    end
  end
end
