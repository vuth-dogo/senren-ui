# frozen_string_literal: true

module Senren
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
