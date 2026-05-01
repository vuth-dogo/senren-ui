# frozen_string_literal: true

module Senren
  class ContextMenuComponent < BaseComponent
    renders_one  :trigger
    renders_many :items, DropdownMenuComponent::ItemTag

    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze
  end
end
