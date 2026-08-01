# frozen_string_literal: true

require_relative '../application_system_test_case'

# Attacks the real paste sanitizer in a real browser.
#
# The sanitizer rebuilds nodes rather than assigning a string, which removes the
# usual mutation-XSS surface. That is a claim, not a proof, so each payload here
# is dispatched as a genuine ClipboardEvent and the page is then asked whether
# anything executed.
#
# `sync()` writes `editorTarget.innerHTML` into the textarea, so sanitized DOM
# makes a round trip through serialization on its way to the server. Several
# payloads below exist purely to test that round trip.
class RichTextPasteAdversarialTest < ApplicationSystemTestCase
  PAGE_CONTROLLERS = %w[
    senren--data-table
    senren--invite-member-dialog
    senren--masked-input
    senren--rich-text-editor-lite
  ].freeze

  # Each payload sets window.__pwned if it executes.
  PAYLOADS = {
    'plain img onerror' => '<img src=x onerror="window.__pwned=1">',
    'svg wrapping style+img' => '<svg><style><img src=x onerror="window.__pwned=1"></style></svg>',
    'math mtext mglyph style' =>
      '<math><mtext><table><mglyph><style><img src=x onerror="window.__pwned=1">',
    'noscript title breakout' =>
      '<noscript><p title="</noscript><img src=x onerror=window.__pwned=1>">',
    'svg p style anchor id' =>
      '<svg></p><style><a id="</style><img src=1 onerror=window.__pwned=1>">',
    'svg anchor xlink href' =>
      '<svg><a xlink:href="javascript:window.__pwned=1">click</a></svg>',
    'svg uppercase anchor' =>
      '<svg><A href="javascript:window.__pwned=1">x</A></svg>',
    'uppercase href attribute' => '<a HREF="javascript:window.__pwned=1">x</a>',
    'uppercase event attribute' => '<p ONCLICK="window.__pwned=1">x</p>',
    'iframe srcdoc' => '<iframe srcdoc="<img src=x onerror=parent.__pwned=1>"></iframe>',
    'object data' => '<object data="javascript:window.__pwned=1"></object>',
    'form action breakout' => '<form action="javascript:window.__pwned=1"><input></form>',
    'template content' => '<template><img src=x onerror="window.__pwned=1"></template>',
    'style import' => '<style>@import "javascript:window.__pwned=1";</style>',
    'anchor data url' => '<a href="data:text/html,<script>window.__pwned=1</script>">x</a>',
    'anchor protocol-relative' => '<a href="///evil.example">x</a>'
  }.freeze

  test 'no pasted payload executes or leaves a dangerous attribute behind' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    survivors = {}

    PAYLOADS.each do |name, payload|
      html = paste_and_read(payload)
      survivors[name] = html

      refute page.evaluate_script('window.__pwned === 1'), "#{name}: payload executed"
      refute_match(/onerror|onclick|onload/i, html, "#{name}: event handler survived")
      refute_match(/javascript:/i, html, "#{name}: javascript: URL survived")
      refute_match(/<(script|iframe|object|embed|style|svg|math|form|input|template)\b/i, html,
                   "#{name}: disallowed element survived")
    end

    # Reported so a regression shows what changed, not just that it changed.
    puts "\n--- what each payload reduced to ---"
    survivors.each { |name, html| puts "  #{name.ljust(28)} #{html[0, 70]}" }
  end

  # Anchor href policy is asserted from the shared fixture in
  # test/system/url_policy_test.rb, against the same file the Ruby suite uses.
  # It lived here as a hand-written table until the table itself encoded the
  # bug: it expected "example.com" to become https://example.com/, which is the
  # same-origin-to-off-origin rewrite that motivated splitting normalizeHref
  # from normalizeUrl.

  # The textarea is what reaches the server. Sanitizing the DOM but posting
  # something else would defeat the whole exercise.
  test 'the value posted to the server matches the sanitized editor content' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    PAYLOADS.each_value { |payload| paste_and_read(payload) }

    editor = page.evaluate_script(%(document.querySelector('[role="textbox"]').innerHTML))
    stored = page.evaluate_script('document.querySelector("textarea[name=body]").value')

    assert_equal editor, stored, 'the textarea must carry exactly the sanitized DOM'
    refute_match(/onerror|javascript:/i, stored)
  end

  # Classic mutation XSS: sanitized DOM serializes to markup that re-parses into
  # something different. sync() performs exactly that serialization.
  test 'sanitized content survives a serialize and re-parse round trip unchanged' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    PAYLOADS.each do |name, payload|
      first = paste_and_read(payload)

      page.execute_script(<<~JS, first)
        const doc = new DOMParser().parseFromString(arguments[0], "text/html")
        window.__reparsed = doc.body.innerHTML
      JS
      reparsed = page.evaluate_script('window.__reparsed')

      assert_equal first, reparsed,
                   "#{name}: serialized output re-parses differently, which is the mutation-XSS shape"
    end
  end

  test 'deeply nested markup does not throw and silently discard the paste' do
    visit '/components/red_team'
    assert_loaded_senren_controllers PAGE_CONTROLLERS

    page.execute_script(<<~JS)
      window.__pasteError = null
      window.addEventListener("error", (e) => { window.__pasteError = String(e.message) })

      const depth = 15000
      const payload = "<b>".repeat(depth) + "deep" + "</b>".repeat(depth)
      const editor = document.querySelector('[role="textbox"]')
      editor.innerHTML = ""
      editor.focus()

      const transfer = new DataTransfer()
      transfer.setData("text/html", payload)
      try {
        editor.dispatchEvent(new ClipboardEvent("paste", {
          clipboardData: transfer, bubbles: true, cancelable: true
        }))
      } catch (e) {
        window.__pasteError = String(e.message)
      }
    JS

    error = page.evaluate_script('window.__pasteError')
    text = page.evaluate_script(%(document.querySelector('[role="textbox"]').textContent))

    assert_nil error,
               "deep nesting threw (#{error}). paste() calls preventDefault() before sanitizing, " \
               'so a throw means the content is silently discarded.'
    assert_includes text, 'deep', 'content must survive rather than vanish'
  end

  private

  def paste_and_read(payload)
    page.execute_script(<<~JS, payload)
      window.__pwned = 0
      const editor = document.querySelector('[role="textbox"]')
      editor.innerHTML = ""
      editor.focus()
      const transfer = new DataTransfer()
      transfer.setData("text/html", arguments[0])
      editor.dispatchEvent(new ClipboardEvent("paste", {
        clipboardData: transfer, bubbles: true, cancelable: true
      }))
    JS

    page.evaluate_script(%(document.querySelector('[role="textbox"]').innerHTML))
  end
end
