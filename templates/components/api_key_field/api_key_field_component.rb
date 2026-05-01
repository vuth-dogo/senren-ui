# frozen_string_literal: true

module Senren
  class ApiKeyFieldComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(value: nil, label: 'API key', reveal_label: 'Reveal', hide_label: 'Hide', copy_label: 'Copy',
                   class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @value = value
      @label = label
      @reveal_label = reveal_label
      @hide_label = hide_label
      @copy_label = copy_label
    end

    attr_reader :value, :label, :reveal_label, :hide_label, :copy_label
  end
end
