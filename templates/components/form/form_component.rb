# frozen_string_literal: true

module Senren
  class FormComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    # method: defaults to nil so Rails can infer PATCH for persisted models.
    # Pass method: :post / :patch / :delete explicitly only when needed.
    def initialize(model: nil, url: nil, method: nil, multipart: false, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @model = model
      @url   = url
      @method = method
      @multipart = multipart
    end

    attr_reader :model, :method, :multipart

    # This one reaches form_with's `action`, which makes it the highest-value
    # URL sink in the library: `//evil.example` is a protocol-relative absolute
    # URL, so a form built from user-controlled input POSTs every field —
    # including the CSRF token — off-origin. Same policy as every other href in
    # the library; it was simply missed because the security test enumerated
    # known components rather than asserting a property over all of them.
    def url = @url && safe_url(@url)
  end
end
