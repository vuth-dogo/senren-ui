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

    # Base classes shared by all input types.
    # NOTE: `flex` is intentionally omitted — it breaks browser-native
    #       date/datetime-local/time picker UI on some engines.
    BASE_CLASSES = 'w-full rounded-(--senren-radius) border bg-[hsl(var(--senren-background))] text-[hsl(var(--senren-foreground))] placeholder:text-[hsl(var(--senren-muted-foreground))] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-0 disabled:cursor-not-allowed disabled:opacity-50'

    # File-type inputs get a styled button instead of unstyled browser defaults.
    FILE_CLASSES = 'file:mr-3 file:h-full file:cursor-pointer file:border-0 file:border-r file:border-solid file:border-[hsl(var(--senren-border))] file:bg-[hsl(var(--senren-muted))] file:px-3 file:text-sm file:font-medium file:text-[hsl(var(--senren-foreground))]'

    # Non-file inputs get standard font styling for the placeholder.
    TEXT_FILE_CLASSES = 'file:border-0 file:bg-transparent file:text-sm file:font-medium'

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

    def input_classes
      file_type? ? "#{BASE_CLASSES} #{FILE_CLASSES}" : "#{BASE_CLASSES} #{TEXT_FILE_CLASSES}"
    end

    def file_type?
      type.to_s == 'file'
    end
  end
end
