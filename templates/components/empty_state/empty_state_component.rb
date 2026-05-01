# frozen_string_literal: true

module Senren
  class EmptyStateComponent < BaseComponent
    renders_one :icon
    renders_one :actions

    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))] bg-[hsl(var(--senren-card))]',
      illustrated: 'border-[hsl(var(--senren-border))] bg-[hsl(var(--senren-muted)/0.35)]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(title: nil, description: nil, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @title = title
      @description = description
    end

    attr_reader :title, :description
  end
end
