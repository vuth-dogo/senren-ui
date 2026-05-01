module Senren
  class CodeblockComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))] bg-[hsl(var(--senren-muted)/0.35)]',
      elevated: 'border-[hsl(var(--senren-border))] bg-[hsl(var(--senren-card))] shadow-sm'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(source: nil, language: nil, filename: nil, caption: nil, wrap: false, variant: :default,
                   class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @source = source
      @language = language
      @filename = filename
      @caption = caption
      @wrap = wrap
    end

    attr_reader :source, :language, :filename, :caption

    def wrap? = !!@wrap

    def code_text
      source.presence || content.to_s
    end

    def language_label
      language.to_s.presence
    end
  end
end
