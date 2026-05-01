# frozen_string_literal: true

module Senren
  class PageHeaderComponent < BaseComponent
    renders_one :actions
    renders_one :eyebrow

    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(title: nil, description: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @title = title
      @description = description
    end

    attr_reader :title, :description
  end
end
