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
  end
end
