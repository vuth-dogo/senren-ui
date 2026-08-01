module Senren
  class TypographyComponent < BaseComponent
    VARIANTS = {
      h1: 'scroll-m-20 text-4xl font-bold tracking-tight',
      h2: 'scroll-m-20 text-3xl font-semibold tracking-tight',
      h3: 'scroll-m-20 text-2xl font-semibold tracking-tight',
      h4: 'scroll-m-20 text-xl font-semibold tracking-tight',
      p: 'leading-7',
      lead: 'text-xl text-[hsl(var(--senren-muted-foreground))]',
      large: 'text-lg font-semibold',
      small: 'text-sm font-medium leading-none',
      muted: 'text-sm text-[hsl(var(--senren-muted-foreground))]'
    }.freeze

    SIZES = { md: '' }.freeze

    # BaseComponent defaults to `variant: :default`, which this component does
    # not define, so `.new` with no variant raised instead of rendering. The
    # default is :p (body text).
    def initialize(variant: :p, **args)
      super
    end

    TAG_FOR = {
      h1: :h1, h2: :h2, h3: :h3, h4: :h4,
      p: :p, lead: :p, large: :p, small: :small, muted: :p
    }.freeze

    def html_tag = TAG_FOR[variant]
  end
end
