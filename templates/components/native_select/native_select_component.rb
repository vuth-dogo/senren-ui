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

    # native_arrow: true  → keep browser/OS native arrow (appearance-auto)
    # native_arrow: false → use custom SVG arrow (appearance-none + SVG overlay)
    def initialize(name:, options:, selected: nil, id: nil, prompt: nil, native_arrow: true,
                   variant: :default, size: :md, class_name: nil, **html)
      super(variant: variant, size: size, class_name: class_name, **html)
      @name = name
      @options = options
      @selected = selected
      @id = id || name.to_s.parameterize
      @prompt = prompt
      @native_arrow = native_arrow
    end

    attr_reader :name, :options, :selected, :id, :prompt

    def native_arrow?
      @native_arrow
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

    def root_select_attrs
      attrs = select_attrs
      data = (attrs[:data] || {}).merge(senren_component: senren_component_name)

      attrs.merge(data: data)
    end

    def select_classes
      appearance = native_arrow? ? 'appearance-auto' : 'appearance-none pr-9'
      [
        'w-full cursor-pointer rounded-(--senren-radius) border bg-[hsl(var(--senren-background))] text-[hsl(var(--senren-foreground))] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-0 disabled:cursor-not-allowed disabled:opacity-50',
        appearance,
        self.class::VARIANTS[variant],
        self.class::SIZES[size],
        class_name,
        html_attrs[:class]
      ].compact.join(' ')
    end
  end
end
