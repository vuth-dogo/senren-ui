# frozen_string_literal: true

require_relative '../application_system_test_case'

# Browser-level proof for the plans/019 batch.
#
# These guarantees live here rather than in unit tests because the defects they
# cover were invisible to string-matching tests: the URL bypasses only appear
# once a browser resolves the attribute, and the paste sink only exists once a
# real ClipboardEvent carries a text/html flavor.
class RedTeamRemediationSystemTest < ApplicationSystemTestCase
  # Every controller the preview page lazy-loads. The helper asserts the exact
  # set, so each test states the whole page rather than the one it exercises.
  PAGE_CONTROLLERS = %w[
    senren--data-table
    senren--invite-member-dialog
    senren--masked-input
    senren--rich-text-editor-lite
  ].freeze

  BYPASS_LINK_IDS = %w[
    link-backslash
    link-backslash-slash
    link-tab
    link-newline
    link-protocol-relative
    link-javascript
  ].freeze

  test 'safe_url keeps every protocol-relative bypass on this origin' do
    visit '/components/red_team'
    assert_text 'Senren Red Team Preview'

    origin = page.evaluate_script('window.location.origin')

    BYPASS_LINK_IDS.each do |id|
      # `href` (the IDL property) is what the browser would navigate to. The
      # attribute string alone hides the bypass, which is why the old test
      # could not see it.
      resolved = page.evaluate_script("document.getElementById('#{id}').href")

      assert resolved.start_with?(origin),
             "#{id} resolved off-origin to #{resolved.inspect}; safe_url failed to neutralize it"
      refute_includes resolved, 'evil.example'
    end

    assert_equal "#{origin}/components/static",
                 page.evaluate_script("document.getElementById('link-safe').href"),
                 'legitimate relative links must still work'
  end

  test 'pasted markup is rebuilt against the allowlist before it reaches the document' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    page.execute_script(<<~JS)
      window.__senrenXss = false
      const editor = document.querySelector('[role="textbox"]')
      editor.focus()
      const transfer = new DataTransfer()
      transfer.setData('text/html', [
        '<img src=x onerror="window.__senrenXss = true">',
        '<a href="javascript:alert(1)">bad link</a>',
        '<scr' + 'ipt>window.__senrenXss = true</scr' + 'ipt>',
        '<p>clean paragraph</p>'
      ].join(''))
      editor.dispatchEvent(new ClipboardEvent('paste', {
        clipboardData: transfer, bubbles: true, cancelable: true
      }))
    JS

    refute page.evaluate_script('window.__senrenXss'), 'pasted script or event handler executed'

    html = page.evaluate_script(%(document.querySelector('[role="textbox"]').innerHTML))

    refute_includes html, 'onerror', 'event handler attributes must be stripped'
    refute_includes html, '<img', 'disallowed elements must not survive'
    refute_includes html, 'javascript:', 'javascript: hrefs must be dropped'
    assert_includes html, 'clean paragraph', 'allowed markup must be preserved'
    assert_includes html, 'bad link', 'the text of a rejected anchor is kept; only its href is dropped'

    stored = page.evaluate_script('document.querySelector("textarea[name=body]").value')

    refute_includes stored, 'onerror', 'the value posted to the server must be sanitized too'
    assert_includes stored, 'clean paragraph'
  end

  test 'ctrl-clicking a hostile anchor inside the editor opens nothing' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    opened = page.evaluate_script(<<~JS)
      window.__senrenOpened = null
      window.open = (url) => { window.__senrenOpened = url; return null }

      const editor = document.querySelector('[role="textbox"]')
      const anchor = document.createElement("a")
      anchor.setAttribute("href", "javascript:alert(1)")
      anchor.textContent = "trap"
      editor.appendChild(anchor)
      anchor.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, ctrlKey: true }))

      window.__senrenOpened
    JS

    assert_nil opened, 'openLink must gate the protocol before calling window.open'
  end

  test 'sorting a data table reads each cell once per sort, not once per comparison' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    row_count = page.evaluate_script(
      %(document.querySelectorAll('[data-senren--data-table-target="row"]').length)
    )

    assert_operator row_count, :>, 1, 'the fixture needs enough rows for the distinction to matter'

    page.execute_script(<<~JS)
      window.__senrenCellReads = 0
      const original = Element.prototype.querySelector
      Element.prototype.querySelector = function (...args) {
        if (typeof args[0] === "string" && args[0].includes("data-sort-key")) {
          window.__senrenCellReads++
        }
        return original.apply(this, args)
      }
    JS

    find('th button[data-sort-key="name"]').click

    # Read the counter before anything else queries cells, or the assertion
    # measures the test harness instead of the controller.
    reads = page.evaluate_script('window.__senrenCellReads')

    # Decorate-sort-undecorate reads n cells. The previous implementation read
    # one per comparison (~n log n), which grew without bound.
    assert_equal row_count, reads,
                 "expected #{row_count} cell reads (one per row), got #{reads}"

    assert_equal %w[alpha bravo charlie delta], sorted_names, 'ascending sort order'

    find('th button[data-sort-key="name"]').click

    assert_equal %w[delta charlie bravo alpha], sorted_names, 'clicking again reverses the order'
  end

  test 'the invite dialog unregisters its document listener on disconnect' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    # There is no DOM API to enumerate listeners, so count the registrations.
    page.execute_script(<<~JS)
      window.__senrenKeydownAdded = 0
      window.__senrenKeydownRemoved = 0
      const add = document.addEventListener.bind(document)
      const remove = document.removeEventListener.bind(document)
      document.addEventListener = (type, fn, opts) => {
        if (type === "keydown") window.__senrenKeydownAdded++
        return add(type, fn, opts)
      }
      document.removeEventListener = (type, fn, opts) => {
        if (type === "keydown") window.__senrenKeydownRemoved++
        return remove(type, fn, opts)
      }
    JS

    find('[data-senren--invite-member-dialog-target="trigger"]', match: :first).click

    assert_equal 1, page.evaluate_script('window.__senrenKeydownAdded'),
                 'opening the dialog registers exactly one document keydown listener'

    # Remove the element while the dialog is still open. Stimulus processes the
    # mutation asynchronously, so this must be its own browser round-trip.
    page.execute_script(
      %(document.querySelector('[data-controller~="senren--invite-member-dialog"]').remove())
    )

    assert_equal 1, eventually { page.evaluate_script('window.__senrenKeydownRemoved') },
                 'disconnect() must remove the listener the dialog registered'
  end

  test 'a masked input formats once after repeated reconnects' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    # Each detach/attach is its own round-trip so Stimulus can run
    # disconnect()/connect() between them.
    3.times do
      page.execute_script(<<~JS)
        const input = document.getElementById("masked-code")
        const parent = input.parentNode
        const next = input.nextSibling
        parent.removeChild(input)
        parent.insertBefore(input, next)
      JS
    end

    page.execute_script(<<~JS)
      const input = document.getElementById("masked-code")
      input.value = "123456"
      input.dispatchEvent(new Event("input", { bubbles: true }))
    JS

    formatted = page.evaluate_script('document.getElementById("masked-code").value')

    assert_equal '123-456', formatted,
                 'stacked listeners would re-run the mask over its own output'
  end

  private

  def sorted_names
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('[data-senren--data-table-target="row"]'))
        .map((row) => row.querySelector('[data-sort-key="name"]').textContent.trim())
    JS
  end

  # Stimulus lifecycle callbacks run on a MutationObserver turn, so a value can
  # lag one round-trip behind the DOM change that triggers it.
  def eventually(attempts: 20)
    result = nil
    attempts.times do
      result = yield
      break if result.to_i.positive?

      sleep 0.05
    end
    result
  end
end
