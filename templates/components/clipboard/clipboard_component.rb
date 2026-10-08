# frozen_string_literal: true

module Senren
  class ClipboardComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(value:, label: senren_t('clipboard.copy', default: 'Copy'),
                   copied_label: senren_t('clipboard.copied', default: 'Copied'), class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @label = label
      @value = value
      @copied_label = copied_label
    end

    attr_reader :label, :value, :copied_label

    # What a screen reader is told once the copy has happened. Passed to the
    # controller as a Stimulus value so no sentence lives in JavaScript.
    def copied_status = senren_t('clipboard.copied_status', default: 'Copied to clipboard')
  end
end
