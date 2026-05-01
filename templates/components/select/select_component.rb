# frozen_string_literal: true

module Senren
  # Stimulus-driven styled select. v0.1 ships as a thin wrapper around the
  # native_select with a Stimulus controller hook for future styling work.
  class SelectComponent < BaseComponent
    VARIANTS = NativeSelectComponent::VARIANTS
    SIZES    = NativeSelectComponent::SIZES

    def initialize(**args)
      @args = args
    end

    def native_select_args
      data = (@args[:data] || {}).merge(controller: 'senren--select')
      @args.merge(data: data)
    end
  end
end
