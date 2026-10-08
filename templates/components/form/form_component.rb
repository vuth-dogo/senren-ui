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

    # ViewComponent's `content` calls the render block with the component as
    # its argument, so `|f|` would be this component, not the form builder.
    # And because a component is an ActionView::Base, `f.text_field :title,
    # class: "x"` would not raise: it would reach the template-level helper and
    # render `name="title[{class: "x"}]"`. Keep the block and call it with the
    # builder form_with yields instead.
    def render_in(view_context, **, &block)
      @form_block = block
      super
    end

    # Mirrors ViewComponent's own `content`: a block wins over with_content,
    # and it runs under the caller's virtual path so relative `t('.key')`
    # lookups inside it resolve against the caller's template.
    def form_body(builder)
      return content unless @form_block

      with_captured_virtual_path(@old_virtual_path) { view_context.capture(builder, &@form_block) }
    end

    # This one reaches form_with's `action`, which makes it the highest-value
    # URL sink in the library: `//evil.example` is a protocol-relative absolute
    # URL, so a form built from user-controlled input POSTs every field —
    # including the CSRF token — off-origin. Same policy as every other href in
    # the library; it was simply missed because the security test enumerated
    # known components rather than asserting a property over all of them.
    def url = @url && safe_url(@url)
  end
end
