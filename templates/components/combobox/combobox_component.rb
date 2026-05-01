# frozen_string_literal: true

module Senren
  class ComboboxComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))]',
      error: 'border-[hsl(var(--senren-destructive))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(name:, options:, value: nil, placeholder: 'Search...', variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @name = name
      @options = normalize_options(options)
      @value = value
      @placeholder = placeholder
    end

    attr_reader :name, :options, :value, :placeholder

    def selected_label
      options.find { |option| option[:value].to_s == value.to_s }&.dig(:label)
    end

    private

    def normalize_options(options)
      Array(options).map do |option|
        if option.is_a?(Hash)
          { value: option[:value] || option['value'], label: option[:label] || option['label'] }
        else
          value, label = option
          { value: value, label: label || value }
        end
      end
    end
  end
end
