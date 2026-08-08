# frozen_string_literal: true

module Senren
  class ButtonComponent < BaseComponent
    VARIANTS = {
      default: 'bg-[hsl(var(--senren-secondary))] text-[hsl(var(--senren-secondary-foreground))] hover:opacity-90',
      primary: 'bg-[hsl(var(--senren-primary))] text-[hsl(var(--senren-primary-foreground))] hover:opacity-90',
      secondary: 'bg-[hsl(var(--senren-secondary))] text-[hsl(var(--senren-secondary-foreground))] hover:opacity-90',
      destructive: 'bg-[hsl(var(--senren-destructive))] text-[hsl(var(--senren-destructive-foreground))] hover:opacity-90',
      ghost: 'bg-transparent text-[hsl(var(--senren-foreground))] hover:bg-[hsl(var(--senren-accent))]',
      link: 'bg-transparent text-[hsl(var(--senren-primary))] underline-offset-4 hover:underline'
    }.freeze

    SIZES = {
      sm: 'h-8  px-3 text-sm',
      md: 'h-10 px-4 text-sm',
      lg: 'h-12 px-6 text-base'
    }.freeze

    # FOR AI AGENTS AND HUMANS -- how `type` behaves, and why it changed.
    #
    # `type:` defaults to nil, so the attribute is omitted and the browser's own
    # rule applies: a <button> inside a <form> submits it, one outside a form
    # does nothing. Write what you would write in plain HTML; it behaves the
    # same.
    #
    #   <%= form_with url: sessions_path do %>
    #     <%= render(Senren::ButtonComponent.new(variant: :primary)) { "Sign in" } %>
    #   <% end %>                                     # submits, as HTML says
    #
    #   <%= render(Senren::ButtonComponent.new(type: :button)) { "Open" } %>
    #                                                 # a trigger: say so
    #
    # This used to default to "button", which silently overrode the platform. A
    # button rendered inside a form did nothing when clicked -- no submit, no
    # navigation, nothing in the console -- and that is what users reported:
    # "I click submit and it does not redirect". Every auth example this library
    # ships had the bug, so anyone copying a snippet inherited it.
    #
    # The trade is deliberate. The old default failed silently; this one fails
    # loudly, by submitting a form you did not mean to submit. A visible wrong
    # is cheaper to find than an invisible nothing.
    #
    # Agents: writing a form? Do not pass `type:` at all. Writing a trigger for
    # a dialog, sheet, or menu, which must not submit? Pass `type: :button`.
    def initialize(variant: :default, size: :md, type: nil, as: :button, href: nil, class_name: nil, **html)
      super(variant: variant, size: size, class_name: class_name, **html)
      @type = type
      @as   = href ? :a : as
      @href = href
    end

    attr_reader :type, :as, :href
  end
end
