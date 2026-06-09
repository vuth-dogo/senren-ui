# frozen_string_literal: true

module Senren
  class DropdownMenuComponent < BaseComponent
    renders_one  :trigger
    renders_many :items, 'ItemTag'

    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    def initialize(class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
    end

    class ItemTag < BaseComponent
      VARIANTS = { default: '' }.freeze
      SIZES = { md: '' }.freeze
      ITEM_ACTION = 'click->senren--dropdown-menu#close keydown->senren--dropdown-menu#onItemKey'

      def initialize(href: nil, method: nil, destructive: false, class_name: nil, **)
        super(variant: :default, size: :md, class_name: class_name, **)
        @href = href
        @method = method
        @destructive = destructive
      end

      def call
        klass = 'block w-full text-left px-3 py-2 text-sm rounded-sm hover:bg-[hsl(var(--senren-accent))] focus:bg-[hsl(var(--senren-accent))] outline-none cursor-pointer'
        klass += " #{class_name}" if class_name.present?
        klass += ' text-[hsl(var(--senren-destructive))]' if @destructive
        if @href
          link_to(content, safe_url(@href), role: 'menuitem', method: @method, class: klass, data: { action: ITEM_ACTION }, **html_attrs)
        else
          tag.button(content, type: 'button', role: 'menuitem', class: klass, data: { action: ITEM_ACTION }, **html_attrs)
        end
      end
    end
  end
end
