# frozen_string_literal: true

module Senren
  class AlertDialogComponent < BaseComponent
    renders_one :trigger
    renders_one :title
    renders_one :description
    renders_one :cancel
    renders_one :confirm

    VARIANTS = { default: '', destructive: '' }.freeze
    SIZES    = { md: '' }.freeze

    def initialize(variant: :default, id: nil, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @dom_id = id || "senren-alert-dialog-#{SecureRandom.hex(3)}"
    end

    attr_reader :dom_id
  end
end
