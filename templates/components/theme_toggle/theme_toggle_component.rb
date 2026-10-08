# frozen_string_literal: true

module Senren
  class ThemeToggleComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(label: senren_t('theme_toggle.label', default: 'Toggle theme'), class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @label = label
    end

    attr_reader :label

    # What the label reads once the theme has switched. The controller swaps
    # between the two, so both reach it as Stimulus values.
    def light_label = senren_t('theme_toggle.light', default: 'Light theme')
    def dark_label = senren_t('theme_toggle.dark', default: 'Dark theme')
  end
end
