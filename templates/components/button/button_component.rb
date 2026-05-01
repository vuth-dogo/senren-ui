# frozen_string_literal: true

module Senren
  class ButtonComponent < BaseComponent
    VARIANTS = {
      default: 'bg-[hsl(var(--senren-secondary))] text-[hsl(var(--senren-secondary-foreground))] hover:opacity-90',
      primary: 'bg-[hsl(var(--senren-primary))] text-[hsl(var(--senren-primary-foreground))] hover:opacity-90',
      secondary: 'bg-[hsl(var(--senren-secondary))] text-[hsl(var(--senren-secondary-foreground))] hover:opacity-90',
      destructive: 'bg-[hsl(var(--senren-destructive))] text-[hsl(var(--senren-destructive-foreground))] hover:opacity-90',
      ghost: 'bg-transparent text-[hsl(var(--senren-foreground))] hover:bg-[hsl(var(--senren-accent))]',
      link: 'bg-transparent text-[hsl(var(--senren-primary))] underline-offset-4 hover:underline'
    }.freeze

    SIZES = {
      sm: 'h-8  px-3 text-sm',
      md: 'h-10 px-4 text-sm',
      lg: 'h-12 px-6 text-base'
    }.freeze

    def initialize(variant: :default, size: :md, type: 'button', as: :button, href: nil, class_name: nil, **html)
      super(variant: variant, size: size, class_name: class_name, **html)
      @type = type
      @as   = href ? :a : as
      @href = href
    end

    attr_reader :type, :as, :href
  end
end
