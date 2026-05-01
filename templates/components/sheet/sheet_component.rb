# frozen_string_literal: true

module Senren
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
      @dom_id = id || "senren-sheet-#{SecureRandom.hex(3)}"
    end

    attr_reader :dom_id
  end
end
