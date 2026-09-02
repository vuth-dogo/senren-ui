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

    # native_arrow: false → custom SVG chevron that rotates while the select has
    #                       focus (appearance-none + positioned SVG). The default.
    # native_arrow: true  → the browser's own arrow (appearance-auto), which
    #                       matches the OS but cannot be styled or animated.
    #
    # The default was `true`, so out of the box a Senren select was the one
    # control in the library with no state to see: the arrow never moved, and
    # nothing distinguished an open select from a closed one. The custom arrow
    # was already written and had to be asked for by name, which meant nobody
    # got it. Pass native_arrow: true to opt back in -- worth doing on mobile,
    # where the OS renders its own picker anyway.
    def initialize(name:, options:, selected: nil, id: nil, prompt: nil, native_arrow: false,
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
