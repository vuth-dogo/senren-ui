# frozen_string_literal: true

module Senren
  class ThemeToggleComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(label: 'Toggle theme', class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @label = label
    end

    attr_reader :label
  end
end
