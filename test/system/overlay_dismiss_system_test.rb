# frozen_string_literal: true

require 'application_system_test_case'

# Clicking beside an overlay should close it -- except where it should not.
#
# None of the three did, which is only visible by clicking: the overlay element
# existed and was styled, it simply had no action bound. A markup grep found a
# `close` action in each file and reported all three as fine; the action
# belonged to the close button.
class OverlayDismissSystemTest < ApplicationSystemTestCase
  def test_a_dialog_closes_when_the_overlay_is_clicked
    visit '/components/interactive'
    open_overlay('dialog')

    assert_overlay_open 'dialog'
    click_overlay 'dialog'

    assert_overlay_closed 'dialog'
  end

  def test_a_sheet_closes_when_the_overlay_is_clicked
    visit '/components/interactive'
    open_overlay('sheet')

    assert_overlay_open 'sheet'
    click_overlay 'sheet'

    assert_overlay_closed 'sheet'
  end

  # Deliberate: an alert dialog exists to make someone choose, and dismissing
  # it by clicking beside it is indistinguishable from hitting Cancel by
  # accident. Pinned so a future "consistency" pass does not quietly add it.
  def test_an_alert_dialog_stays_open_when_the_overlay_is_clicked
    visit '/components/interactive'
    open_overlay('alert_dialog')

    assert_overlay_open 'alert_dialog'
    click_overlay 'alert_dialog'

    assert_overlay_open 'alert_dialog'
  end

  # Escape remains the way out of all three, including the modal one.
  def test_escape_closes_every_overlay
    visit '/components/interactive'

    %w[dialog sheet alert_dialog].each do |name|
      open_overlay(name)

      assert_overlay_open name
      page.driver.browser.action.send_keys(:escape).perform
      assert_overlay_closed name
    end
  end

  private

  def identifier(name) = "senren--#{name.tr('_', '-')}"

  def open_overlay(name)
    find("[data-#{identifier(name)}-target='trigger']", match: :first).click
    sleep 0.2
  end

  def click_overlay(name)
    page.execute_script("document.querySelector(\"[data-#{identifier(name)}-target='overlay']\").click()")
    sleep 0.2
  end

  def panel_hidden?(name)
    page.evaluate_script(
      "document.querySelector(\"[data-#{identifier(name)}-target='panel']\").hidden"
    )
  end

  def assert_overlay_open(name)
    refute panel_hidden?(name), "expected the #{name} panel to be open"
  end

  def assert_overlay_closed(name)
    assert panel_hidden?(name), "expected the #{name} panel to be closed"
  end
end
