# frozen_string_literal: true

module Senren
  class NativeSelectComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-input))] focus-visible:ring-[hsl(var(--senren-ring))]',
      error: 'border-[hsl(var(--senren-destructive))] focus-visible:ring-[hsl(var(--senren-destructive))]'
    }.freeze

    SIZES = {
      sm: 'h-8  text-sm  px-2.5',
      md: 'h-10 text-sm  px-3',
      lg: 'h-12 text-base px-4'
    }.freeze

    def initialize(name:, options:, selected: nil, id: nil, prompt: nil, variant: :default, size: :md, class_name: nil,
                   **html)
      super(variant: variant, size: size, class_name: class_name, **html)
      @name = name
      @options = options
      @selected = selected
      @id = id || name.to_s.parameterize
      @prompt = prompt
    end

    attr_reader :name, :options, :selected, :id, :prompt

    def wrapper_attrs
      { class: 'group relative w-full', data: { senren_component: senren_component_name } }
    end

    def select_attrs
      attrs = html_attrs.except(:class)
      attrs.merge(
        id: id,
        name: name,
        class: select_classes,
        'aria-invalid': variant == :error
      )
    end

    def select_classes
      [
        'flex w-full cursor-pointer appearance-none rounded-(--senren-radius) border bg-[hsl(var(--senren-background))] pr-9 text-[hsl(var(--senren-foreground))] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-0 disabled:cursor-not-allowed disabled:opacity-50',
        self.class::VARIANTS[variant],
        self.class::SIZES[size],
        class_name,
        html_attrs[:class]
      ].compact.join(' ')
    end
  end
end
