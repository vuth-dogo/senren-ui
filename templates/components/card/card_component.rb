# frozen_string_literal: true

module Senren
  class CardComponent < BaseComponent
    renders_one :header
    renders_one :body
    renders_one :footer

    VARIANTS = {
      default: 'bg-[hsl(var(--senren-card))] text-[hsl(var(--senren-card-foreground))] border-[hsl(var(--senren-border))]',
      muted: 'bg-[hsl(var(--senren-muted))] text-[hsl(var(--senren-muted-foreground))] border-transparent',
      outline: 'bg-transparent text-[hsl(var(--senren-foreground))] border-[hsl(var(--senren-border))]'
    }.freeze

    SIZES = { md: '' }.freeze
  end
end
