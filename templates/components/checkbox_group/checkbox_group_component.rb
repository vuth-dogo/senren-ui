module Senren
  class CheckboxGroupComponent < BaseComponent
    renders_one  :legend
    renders_many :options, 'OptionTag'

    VARIANTS = { default: '' }.freeze
    SIZES    = { md: '' }.freeze

    class OptionTag < ViewComponent::Base
      def initialize(name:, value:, label:, checked: false)
        @name = name
        @value = value
        @label = label
        @checked = checked
      end

      def call
        content_tag(:label, class: 'inline-flex items-center gap-2 cursor-pointer') do
          tag.input(type: 'checkbox', name: name, value: @value, checked: @checked,
                    class: 'h-4 w-4 rounded border border-[hsl(var(--senren-input))] text-[hsl(var(--senren-primary))] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--senren-ring))]') +
            content_tag(:span, @label, class: 'text-sm text-[hsl(var(--senren-foreground))]')
        end
      end

      private

      attr_reader :name
    end
  end
end
