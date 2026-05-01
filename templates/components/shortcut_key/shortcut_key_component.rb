# frozen_string_literal: true

module Senren
  class ShortcutKeyComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(keys: [], class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @keys = Array(keys)
    end

    attr_reader :keys
  end
end
