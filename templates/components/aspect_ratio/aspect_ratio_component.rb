# frozen_string_literal: true

module Senren
  class AspectRatioComponent < BaseComponent
    VARIANTS = {
      square: 'aspect-square',
      video: 'aspect-video',
      portrait: 'aspect-[3/4]',
      ultrawide: 'aspect-[21/9]'
    }.freeze

    SIZES = { md: '' }.freeze

    # BaseComponent defaults to `variant: :default`, which this component does
    # not define, so `.new` with no variant raised instead of rendering. The
    # default is :square (the neutral ratio).
    def initialize(variant: :square, **args)
      super
    end
  end
end
