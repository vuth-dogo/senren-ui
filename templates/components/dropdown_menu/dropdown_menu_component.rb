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

    class ItemTag < ViewComponent::Base
      def initialize(href: nil, method: nil, destructive: false, **opts)
        @href = href
        @method = method
        @destructive = destructive
        @opts = opts
      end

      def call
        klass = 'block w-full text-left px-3 py-2 text-sm rounded-sm hover:bg-[hsl(var(--senren-accent))] focus:bg-[hsl(var(--senren-accent))] outline-none cursor-pointer'
        klass += ' text-[hsl(var(--senren-destructive))]' if @destructive
        if @href
          link_to(content, @href, role: 'menuitem', method: @method, class: klass,
                                  data: { action: 'click->senren--dropdown-menu#close keydown->senren--dropdown-menu#onItemKey' })
        else
          tag.button(content, type: 'button', role: 'menuitem', class: klass,
                              data: { action: 'click->senren--dropdown-menu#close keydown->senren--dropdown-menu#onItemKey' }, **@opts)
        end
      end
    end
  end
end
