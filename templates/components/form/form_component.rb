# frozen_string_literal: true

module Senren
  class FormComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    def initialize(model: nil, url: nil, method: :post, multipart: false, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @model = model
      @url   = url
      @method = method
      @multipart = multipart
    end

    attr_reader :model, :url, :method, :multipart
  end
end
