# frozen_string_literal: true

require_relative '../application_system_test_case'
require_relative '../support/url_policy_fixture'

# The browser half of the shared URL policy.
#
# Senren implements the same policy twice, in Ruby (`safe_url`) and in
# JavaScript (`normalizeHref`), and the two drifted once: a fix landed on the
# server while the client still rewrote "///evil.example" into
# https://evil.example/. Both are now driven from
# test/fixtures/url_policy.yml, so a change to one without the other fails.
#
# The client is exercised through its real path — pasting an anchor into the
# editor — rather than by calling the function directly, because that is how a
# hostile href actually arrives.
class UrlPolicyTest < ApplicationSystemTestCase
  PAGE_CONTROLLERS = %w[
    senren--data-table
    senren--invite-member-dialog
    senren--masked-input
    senren--rich-text-editor-lite
  ].freeze

  test 'the pasted-href policy matches the shared fixture' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    UrlPolicyFixture.vectors.each do |vector|
      actual = paste_anchor_href(vector.fetch('input'))
      expected = vector.fetch('expect')

      if expected.nil?
        assert_nil actual, "must drop the href for #{UrlPolicyFixture.describe(vector)}"
      else
        assert_equal expected, actual, "must keep unchanged: #{UrlPolicyFixture.describe(vector)}"
      end
    end
  end

  # Guards the reason the two client helpers exist separately: a bare word is a
  # relative reference in markup, but a host when a person types it into the link
  # prompt. While one function served both, pasting `href="settings"` produced
  # https://settings/ — a same-origin link rewritten off-origin.
  test 'a pasted relative href is never promoted to an absolute URL' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    {
      'settings' => 'settings',
      'example.com' => 'example.com',
      './rel' => './rel',
      '?page=2' => '?page=2'
    }.each do |input, expected|
      assert_equal expected, paste_anchor_href(input),
                   "#{input.inspect} is a relative reference in markup and must stay one"
    end

    resolved = page.evaluate_script(<<~JS)
      (function () {
        const a = document.querySelector('[role="textbox"] a');
        return a ? a.href : null;
      })()
    JS

    origin = page.evaluate_script('window.location.origin')

    assert resolved.start_with?(origin),
           "a relative href must still resolve to this origin, got #{resolved.inspect}"
  end

  private

  def paste_anchor_href(input)
    page.execute_script(<<~JS, input)
      const editor = document.querySelector('[role="textbox"]')
      editor.innerHTML = ""
      editor.focus()
      const escaped = arguments[0].replace(/&/g, "&amp;").replace(/"/g, "&quot;")
      const transfer = new DataTransfer()
      transfer.setData("text/html", '<a href="' + escaped + '">x</a>')
      editor.dispatchEvent(new ClipboardEvent("paste", {
        clipboardData: transfer, bubbles: true, cancelable: true
      }))
    JS

    page.evaluate_script(<<~JS)
      (function () {
        const a = document.querySelector('[role="textbox"] a');
        return a ? a.getAttribute('href') : null;
      })()
    JS
  end
end
