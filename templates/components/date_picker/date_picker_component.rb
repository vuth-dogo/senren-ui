# frozen_string_literal: true

module Senren
  class DatePickerComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-input))]',
      error: 'border-[hsl(var(--senren-destructive))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(name:, value: nil, id: nil, placeholder: 'Select date', variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @name = name
      @value = value
      @id = id || name
      @placeholder = placeholder
    end

    attr_reader :name, :value, :id, :placeholder
  end
end
