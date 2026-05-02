# frozen_string_literal: true

module Senren
  class ProgressComponent < BaseComponent
    VARIANTS = {
      default: '',
      success: '',
      warning: '',
      destructive: ''
    }.freeze
    INDICATOR_VARIANTS = {
      default: 'bg-[hsl(var(--senren-primary))]',
      success: 'bg-[hsl(var(--senren-success))]',
      warning: 'bg-[hsl(var(--senren-warning))]',
      destructive: 'bg-[hsl(var(--senren-destructive))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(value: 0, max: 100, label: nil, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @value = value.to_f
      @max = max.to_f.positive? ? max.to_f : 100.0
      @label = label
    end

    attr_reader :value, :max, :label

    def percent
      ((value / max) * 100).clamp(0, 100).round
    end

    def indicator_class
      INDICATOR_VARIANTS.fetch(variant)
    end
  end
end
