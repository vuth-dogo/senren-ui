# frozen_string_literal: true

module Senren
  class TooltipComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    def initialize(text:, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @text = text
      @id = "senren-tooltip-#{SecureRandom.hex(3)}"
    end

    attr_reader :text, :id
  end
end
