# frozen_string_literal: true

module Senren
  class ClipboardComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(value:, label: 'Copy', copied_label: 'Copied', class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @label = label
      @value = value
      @copied_label = copied_label
    end

    attr_reader :label, :value, :copied_label
  end
end
