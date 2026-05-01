# frozen_string_literal: true

module Senren
  class FilterBarComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(label: 'Filters', class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @label = label
    end

    attr_reader :label
  end
end
