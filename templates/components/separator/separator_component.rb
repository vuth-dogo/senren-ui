module Senren
  class SeparatorComponent < BaseComponent
    VARIANTS = {
      horizontal: 'h-px w-full bg-[hsl(var(--senren-border))]',
      vertical: 'w-px h-full bg-[hsl(var(--senren-border))]'
    }.freeze

    SIZES = { md: '' }.freeze

    # BaseComponent defaults to `variant: :default`, which this component does
    # not define, so `.new` with no variant raised instead of rendering. The
    # default is :horizontal (a rule across the flow).
    def initialize(variant: :horizontal, **args)
      super
    end

    def aria_orientation = variant == :vertical ? 'vertical' : 'horizontal'
  end
end
