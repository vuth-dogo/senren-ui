# frozen_string_literal: true

module Senren
  # Unlike Dialog and Sheet, this does not close when the overlay is clicked.
  # An alert dialog exists to make someone choose, and dismissing it by
  # clicking beside it is indistinguishable from choosing Cancel by accident.
  # Escape still closes it, because a keyboard user needs a way out.
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
      @dom_id = id || senren_dom_id
    end

    attr_reader :dom_id
  end
end
