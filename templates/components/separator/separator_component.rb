module Senren
  class SeparatorComponent < BaseComponent
    VARIANTS = {
      horizontal: 'h-px w-full bg-[hsl(var(--senren-border))]',
      vertical: 'w-px h-full bg-[hsl(var(--senren-border))]'
    }.freeze

    SIZES = { md: '' }.freeze

    def aria_orientation = variant == :vertical ? 'vertical' : 'horizontal'
  end
end
