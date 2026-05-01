# frozen_string_literal: true

module Senren
  class AppShellComponent < BaseComponent
    renders_one :top_nav
    renders_one :sidebar
    renders_one :header
    renders_one :footer

    VARIANTS = {
      default: 'bg-[hsl(var(--senren-background))]',
      compact: 'bg-[hsl(var(--senren-muted)/0.25)]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(content_id: 'senren-main', skip_label: 'Skip to content', variant: :default, class_name: nil, **html)
      super(variant: variant, size: :md, class_name: class_name, **html)
      @content_id = content_id
      @skip_label = skip_label
    end

    attr_reader :content_id, :skip_label
  end
end
