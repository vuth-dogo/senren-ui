# frozen_string_literal: true

module Senren
  # A trigger and an absolutely positioned menu.
  #
  # The menu is taller than the trigger and escapes it, so an ancestor with
  # `overflow-hidden` will clip it -- usually a card, table wrapper, or list
  # container that has the class only to make its border radius clip children.
  # Symptom: the menu opens but is cut off at the container's edge. Remove the
  # overflow, or round the first and last rows instead of the wrapper.
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
          link_to(content, safe_url(@href), role: 'menuitem', class: klass, **item_attrs)
        else
          tag.button(content, type: 'button', role: 'menuitem', class: klass, **item_attrs)
        end
      end

      private

      # Two defects lived in the old one-line version of `call`.
      #
      # It wrote `data: { action: ITEM_ACTION }` and then splatted html_attrs
      # after it, so any caller passing `data:` replaced the whole hash and
      # silently lost close-on-click and keyboard handling. This is the same
      # defect `root_attrs` had for `data:`, fixed there and never here --
      # merging is the fix in both places.
      #
      # And `method:` was passed to link_to, which was a rails-ujs option.
      # Rails 7 dropped rails-ujs, so it rendered a `method` attribute on an
      # `<a>` that does nothing at all: a documented parameter that had been
      # inert since the library targeted Rails 7.1. Turbo reads
      # data-turbo-method.
      def item_attrs
        data = (html_attrs[:data] || {}).merge(action: ITEM_ACTION)
        data = data.merge(turbo_method: @method) if @method

        html_attrs.except(:data).merge(data: data)
      end
    end
  end
end
