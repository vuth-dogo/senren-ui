# frozen_string_literal: true

module Senren
  class SearchInputComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(name: 'q', value: nil, placeholder: senren_t('search_input.placeholder', default: 'Search...'),
                   label: senren_t('search_input.label', default: 'Search'), class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @name = name
      @value = value
      @placeholder = placeholder
      @label = label
    end

    attr_reader :name, :value, :placeholder, :label
  end
end
