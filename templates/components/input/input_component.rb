# frozen_string_literal: true

module Senren
  class InputComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-input))] focus-visible:ring-[hsl(var(--senren-ring))]',
      error: 'border-[hsl(var(--senren-destructive))] focus-visible:ring-[hsl(var(--senren-destructive))]'
    }.freeze

    SIZES = {
      sm: 'h-8  text-sm  px-2.5',
      md: 'h-10 text-sm  px-3',
      lg: 'h-12 text-base px-4'
    }.freeze

    def initialize(name:, type: 'text', value: nil, placeholder: nil, id: nil, variant: :default, size: :md,
                   class_name: nil, **html)
      super(variant: variant, size: size, class_name: class_name, **html)
      @name = name
      @type = type
      @value = value
      @placeholder = placeholder
      @id = id || name.to_s.parameterize
    end

    attr_reader :name, :type, :value, :placeholder, :id
  end
end
