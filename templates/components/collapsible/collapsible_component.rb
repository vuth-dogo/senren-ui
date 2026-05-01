module Senren
  class CollapsibleComponent < BaseComponent
    renders_one :trigger
    renders_one :body

    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(title: 'Details', open: false, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @title = title
      @open = open
    end

    attr_reader :title

    def open? = @open
  end
end
