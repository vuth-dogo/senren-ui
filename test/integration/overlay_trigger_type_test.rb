# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'nokogiri'

# `ButtonComponent` no longer emits `type="button"` by default, so a button in a
# form submits like plain HTML does. That is the right default -- the old one
# silently swallowed submits -- but it inverts the burden for one specific use:
# an overlay trigger must never submit, and now has to say so.
#
# The library's own examples are what people copy. Every one of them opened an
# overlay from a bare `ButtonComponent.new`, which works only because none of
# those examples sit inside a form. Copied into a form -- an "Edit" button in a
# settings form opening a confirm dialog -- the same code posts the form and
# navigates away instead of opening the dialog.
#
# So this asserts the property on rendered markup rather than trusting that
# whoever adds the next example remembers.
class OverlayTriggerTypeTest < ActionDispatch::IntegrationTest
  PAGES = %w[/components/interactive /components/kitchen_sink].freeze

  def test_every_overlay_trigger_button_declares_it_does_not_submit
    offenders = PAGES.flat_map { |path| submitting_triggers_on(path) }

    assert_empty offenders,
                 'these overlay triggers submit the form they are placed in, instead of ' \
                 "opening their overlay: #{offenders.join(', ')}"
  end

  # A trigger that opens an overlay is not the only button that must not submit;
  # a dialog's Cancel is the same case. Kept separate because the failure reads
  # differently: Cancel posts the form it was meant to abandon.
  def test_alert_dialog_cancel_does_not_submit
    get '/components/kitchen_sink'

    cancels = Nokogiri::HTML5(response.body)
                      .css('[data-senren-component="alert_dialog"] button')
                      .select { |b| b.text.strip.casecmp('cancel').zero? }

    refute_empty cancels, 'the alert dialog preview no longer renders a Cancel button'
    cancels.each { |b| assert_equal 'button', b['type'], "Cancel submits: #{b.to_html}" }
  end

  private

  # Triggers are marked by the Stimulus target their controller reads, which is
  # what the components themselves emit -- not a convention this test invents.
  def submitting_triggers_on(path)
    get path

    assert_response :success

    Nokogiri::HTML5(response.body).css('[data-senren-component]').flat_map do |root|
      component = root['data-senren-component']
      root.css('[data-action*="#toggle"], [data-action*="#open"]').flat_map do |trigger|
        buttons = trigger.name == 'button' ? [trigger] : trigger.css('button')
        buttons.reject { |b| b['type'] == 'button' }
               .map { |b| "#{component}: #{b.text.strip.presence || b['id']}" }
      end
    end
  end
end
