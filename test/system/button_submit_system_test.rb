# frozen_string_literal: true

require 'application_system_test_case'

# Users reported clicking a submit button and nothing happening -- no redirect,
# no error. ButtonComponent defaulted `type` to "button", so every button
# rendered inside a form was inert. The library's own auth examples all had it.
#
# Asserted by navigating, not by reading an attribute: a `type="submit"` in the
# markup proves nothing if something else swallows the click, and the symptom
# users described was about the page not changing.
class ButtonSubmitSystemTest < ApplicationSystemTestCase
  def test_a_button_in_a_form_submits_it
    visit '/components/interactive'
    assert_no_current_path(/submitted=yes/)

    find('#probe-submit').click

    # A waiting matcher, not page.current_url: reading the URL straight after
    # the click races the navigation, and the first version of this passed once
    # by luck and failed on every run after.
    # `message:` is not a Capybara option -- passing it raises ArgumentError,
    # which is an error rather than a failure, and a grep for "failures" reads
    # that as green. The explanation belongs in a comment, not in a kwarg.
    assert_current_path(/submitted=yes/, url: true)
  end

  # The other half. A trigger for a dialog or menu says type: :button, and must
  # keep doing nothing to the form around it.
  def test_an_explicit_type_button_does_not_submit
    visit '/components/interactive'

    find('#probe-trigger').click
    sleep 0.5

    assert_no_current_path(/submitted=yes/, url: true)
  end

  # The components that render their own trigger buttons set type="button"
  # themselves, so they never depended on the default and must stay inert.
  def test_a_component_rendered_trigger_still_does_not_submit
    visit '/components/interactive'

    find("[data-senren--sheet-target='trigger']", match: :first).click
    sleep 0.5

    assert_no_current_path(/submitted=yes/, url: true)
    refute page.evaluate_script("document.querySelector(\"[data-senren--sheet-target='panel']\").hidden"),
           'the sheet trigger should still open the sheet'
  end
end
