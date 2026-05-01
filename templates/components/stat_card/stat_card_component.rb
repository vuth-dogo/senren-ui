# frozen_string_literal: true

module Senren
  class StatCardComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))]',
      success: 'border-[hsl(var(--senren-success)/0.4)]',
      warning: 'border-[hsl(var(--senren-warning)/0.5)]',
      destructive: 'border-[hsl(var(--senren-destructive)/0.42)]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(label: nil, value: nil, change: nil, helper_text: nil, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @label = label
      @value = value
      @change = change
      @helper_text = helper_text
    end

    attr_reader :label, :value, :change, :helper_text

    def accent_class
      {
        success: 'text-[hsl(var(--senren-success))]',
        warning: 'text-[hsl(var(--senren-warning))]',
        destructive: 'text-[hsl(var(--senren-destructive))]'
      }.fetch(variant, 'text-[hsl(var(--senren-muted-foreground))]')
    end
  end
end
