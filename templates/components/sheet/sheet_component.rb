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
  class SheetComponent < BaseComponent
    renders_one :trigger
    renders_one :title
    renders_one :description
    renders_one :body
    renders_one :footer

    VARIANTS = {
      right: 'right-0 top-0 h-full w-full max-w-md translate-x-full data-[open=true]:translate-x-0',
      left: 'left-0  top-0 h-full w-full max-w-md -translate-x-full data-[open=true]:translate-x-0',
      top: 'left-0 top-0 w-full h-1/2 -translate-y-full data-[open=true]:translate-y-0',
      bottom: 'left-0 bottom-0 w-full h-1/2 translate-y-full data-[open=true]:translate-y-0'
    }.freeze

    SIZES = { md: '' }.freeze

    def initialize(side: :right, id: nil, class_name: nil, **html)
      super(variant: side, size: :md, class_name: class_name, **html)
      @dom_id = id || senren_dom_id(side)
    end

    attr_reader :dom_id
  end
end
