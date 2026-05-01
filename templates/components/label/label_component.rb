# frozen_string_literal: true

module Senren
  class LabelComponent < BaseComponent
    VARIANTS = {
      default: '',
      required: ''
    }.freeze

    SIZES = { md: '' }.freeze

    def initialize(for_field:, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @for_field = for_field
    end

    attr_reader :for_field
  end
end
