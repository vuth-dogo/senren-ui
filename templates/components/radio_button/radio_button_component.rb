# frozen_string_literal: true

module Senren
  class RadioButtonComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    def initialize(name:, value:, checked: false, id: nil, label: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @name = name
      @value = value
      @checked = checked
      @id = id || "#{name.to_s.parameterize}-#{value.to_s.parameterize}"
      @label = label
    end

    attr_reader :name, :value, :checked, :id, :label
  end
end
