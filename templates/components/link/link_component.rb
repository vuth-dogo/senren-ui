# frozen_string_literal: true

module Senren
  class LinkComponent < BaseComponent
    VARIANTS = {
      default: 'text-[hsl(var(--senren-primary))] hover:underline underline-offset-4',
      muted: 'text-[hsl(var(--senren-muted-foreground))] hover:underline underline-offset-4',
      destructive: 'text-[hsl(var(--senren-destructive))] hover:underline underline-offset-4'
    }.freeze

    SIZES = { md: '' }.freeze

    def initialize(href:, variant: :default, external: false, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @href = href
      @external = external
    end

    attr_reader :href, :external

    def external_attrs
      external ? { rel: 'noopener noreferrer', target: '_blank' } : {}
    end
  end
end
