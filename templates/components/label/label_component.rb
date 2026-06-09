# frozen_string_literal: true

module Senren
  class LabelComponent < BaseComponent
    VARIANTS = {
      default: '',
      required: ''
    }.freeze

    SIZES = { md: '' }.freeze

    # Accept optional text: param as fallback for inline block syntax.
    # This ensures both patterns work reliably:
    #   render(Senren::LabelComponent.new(for_field: "name", text: "Name"))
    #   render(Senren::LabelComponent.new(for_field: "name")) { "Name" }
    def initialize(for_field:, text: nil, variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @for_field = for_field
      @text = text
    end

    attr_reader :for_field, :text

    # Resolve label text: content block > text param > empty string
    def label_text
      content.presence || @text || ''
    end
  end
end
