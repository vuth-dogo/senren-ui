# frozen_string_literal: true

module Senren
  class SwitchComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    def initialize(name:, checked: false, value: '1', id: nil, label: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @name = name
      @checked = checked
      @value = value
      @id = id || name.to_s.parameterize
      @label = label
    end

    attr_reader :name, :checked, :value, :id, :label
  end
end
