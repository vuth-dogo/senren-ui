# frozen_string_literal: true

module Senren
  class MaskedInputComponent < BaseComponent
    VARIANTS = InputComponent::VARIANTS
    SIZES    = InputComponent::SIZES

    def initialize(mask:, **args)
      @mask = mask
      @args = args
    end

    def input_args
      data = (@args[:data] || {}).merge(controller: 'senren--masked-input', 'senren--masked-input-mask-value': @mask)
      @args.merge(data: data)
    end
  end
end
