# frozen_string_literal: true

module Senren
  class TextareaComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-input))] focus-visible:ring-[hsl(var(--senren-ring))]',
      error: 'border-[hsl(var(--senren-destructive))] focus-visible:ring-[hsl(var(--senren-destructive))]'
    }.freeze

    SIZES = { md: 'min-h-[80px] text-sm px-3 py-2' }.freeze

    def initialize(name:, value: nil, placeholder: nil, id: nil, rows: 4, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @name = name
      @value = value
      @placeholder = placeholder
      @id = id || name.to_s.parameterize
      @rows = rows
    end

    attr_reader :name, :value, :placeholder, :id, :rows
  end
end
