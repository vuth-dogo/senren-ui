module Senren
  class AccordionComponent < BaseComponent
    VARIANTS = { single: '', multiple: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], variant: :single, open: nil, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @items = normalize_items(items)
      @open = Array(open).map(&:to_s)
    end

    attr_reader :items, :open

    def multiple? = variant == :multiple

    def open_item?(item, index)
      open.include?(item[:id]) || (open.empty? && index.zero?)
    end

    private

    def normalize_items(items)
      Array(items).map.with_index do |item, index|
        source = item.is_a?(Hash) ? item : { title: item.to_s }
        title = source[:title] || source['title'] || "Section #{index + 1}"
        id = (source[:id] || source['id'] || title.to_s.parameterize).to_s
        { id: id, title: title, content: source[:content] || source['content'] }
      end
    end
  end
end
