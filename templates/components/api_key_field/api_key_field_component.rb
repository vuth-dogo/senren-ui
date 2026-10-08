# frozen_string_literal: true

module Senren
  class ApiKeyFieldComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(value: nil, label: senren_t('api_key_field.label', default: 'API key'),
                   reveal_label: senren_t('api_key_field.reveal', default: 'Reveal'),
                   hide_label: senren_t('api_key_field.hide', default: 'Hide'),
                   copy_label: senren_t('api_key_field.copy', default: 'Copy'),
                   class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @value = value
      @label = label
      @reveal_label = reveal_label
      @hide_label = hide_label
      @copy_label = copy_label
    end

    attr_reader :value, :label, :reveal_label, :hide_label, :copy_label

    # Announced after a copy. The controller reads it from a Stimulus value, so
    # the sentence is built here, in the host's language, not in JavaScript.
    def copied_status = senren_t('api_key_field.copied_status', default: '%{label} complete', label: copy_label)
  end
end
