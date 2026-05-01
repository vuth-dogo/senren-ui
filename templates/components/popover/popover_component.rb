# frozen_string_literal: true

module Senren
  class PopoverComponent < BaseComponent
    renders_one :trigger
    renders_one :content_panel

    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze
  end
end
