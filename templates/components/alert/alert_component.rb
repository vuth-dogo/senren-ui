module Senren
  class AlertComponent < BaseComponent
    renders_one :title
    renders_one :description

    VARIANTS = {
      default: 'bg-[hsl(var(--senren-background))] text-[hsl(var(--senren-foreground))] border-[hsl(var(--senren-border))]',
      info: 'bg-[hsl(var(--senren-secondary))] text-[hsl(var(--senren-secondary-foreground))] border-transparent',
      success: 'bg-[hsl(var(--senren-success))] text-[hsl(var(--senren-success-foreground))] border-transparent',
      warning: 'bg-[hsl(var(--senren-warning))] text-[hsl(var(--senren-warning-foreground))] border-transparent',
      destructive: 'bg-[hsl(var(--senren-destructive))] text-[hsl(var(--senren-destructive-foreground))] border-transparent'
    }.freeze

    SIZES = { md: '' }.freeze

    def aria_role = variant == :destructive ? 'alert' : 'status'
  end
end
