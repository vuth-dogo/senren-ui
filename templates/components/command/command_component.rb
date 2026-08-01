# frozen_string_literal: true

module Senren
  class CommandComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(items: [], placeholder: 'Type a command...', label: 'Command menu', empty_text: 'No results found.',
                   id: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @placeholder = placeholder
      @label = label
      @empty_text = empty_text
      @dom_id = id || senren_dom_id(label)
      @items = normalize_items(items)
    end

    attr_reader :items, :placeholder, :label, :empty_text, :dom_id

    private

    def normalize_items(items)
      Array(items).map.with_index do |item, index|
        data = item.is_a?(Hash) ? item : { label: item.to_s }
        label = data[:label] || data['label']
        description = data[:description] || data['description']
        keywords = data[:keywords] || data['keywords']
        {
          id: data[:id] || data['id'] || "#{dom_id}-option-#{index}",
          label: label,
          description: description,
          href: safe_url(data[:href] || data['href'], fallback: nil),
          keywords: [label, description, keywords].flatten.compact.join(' ')
        }
      end
    end
  end
end
