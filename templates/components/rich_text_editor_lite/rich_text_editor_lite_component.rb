module Senren
  class RichTextEditorLiteComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))] bg-[hsl(var(--senren-card))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(name: 'content', value: nil, label: 'Content', placeholder: 'Write something...', id: nil,
                   toolbar: true, debug: ::Rails.env.development?, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @name = name
      @value = value
      @label = label
      @placeholder = placeholder
      @dom_id = id || senren_dom_id(name)
      @toolbar = toolbar
      @debug = debug
    end

    attr_reader :name, :value, :label, :placeholder, :dom_id

    def toolbar? = !!@toolbar

    def debug? = !!@debug

    def initial_content
      value.presence || content.to_s.presence || "<p>#{ERB::Util.html_escape(placeholder)}</p>"
    end
  end
end
