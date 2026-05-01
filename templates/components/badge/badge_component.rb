# frozen_string_literal: true

module Senren
  class BadgeComponent < BaseComponent
    VARIANTS = {
      default: 'bg-[hsl(var(--senren-secondary))] text-[hsl(var(--senren-secondary-foreground))]',
      secondary: 'bg-[hsl(var(--senren-muted))] text-[hsl(var(--senren-muted-foreground))]',
      success: 'bg-[hsl(var(--senren-success))] text-[hsl(var(--senren-success-foreground))]',
      warning: 'bg-[hsl(var(--senren-warning))] text-[hsl(var(--senren-warning-foreground))]',
      destructive: 'bg-[hsl(var(--senren-destructive))] text-[hsl(var(--senren-destructive-foreground))]',
      outline: 'border border-[hsl(var(--senren-border))] text-[hsl(var(--senren-foreground))]'
    }.freeze

    SIZES = { md: '' }.freeze
  end
end
