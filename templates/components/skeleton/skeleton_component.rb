# frozen_string_literal: true

module Senren
  class SkeletonComponent < BaseComponent
    VARIANTS = {
      default: 'rounded-(--senren-radius)',
      circle: 'rounded-full',
      text: 'rounded-md h-4'
    }.freeze

    SIZES = { md: '' }.freeze
  end
end
