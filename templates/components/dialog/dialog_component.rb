# frozen_string_literal: true

module Senren
  # Two ancestor traps to know about, because neither is visible in this file
  # and both look like a z-index bug from the outside:
  #
  #   * A `z-index` on any positioned ancestor creates a stacking context, and
  #     a fixed overlay cannot escape one. The panel then competes only inside
  #     that context, so a sticky header with a lower z-index still covers it.
  #     `position: relative` alone is fine; it is the z-index that traps.
  #   * `transform`, `filter`, `backdrop-filter`, `will-change` and an opacity
  #     below 1 create a stacking context too, with the same effect.
  #
  # Symptom in both cases: raising the panel's z-index changes nothing.
  class DialogComponent < BaseComponent
    renders_one :trigger
    renders_one :title
    renders_one :description
    renders_one :body
    renders_one :footer

    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    def initialize(open: false, id: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @open = open
      @dom_id = id || senren_dom_id
    end

    attr_reader :open, :dom_id
  end
end
