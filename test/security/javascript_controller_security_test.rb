# frozen_string_literal: true

require 'test_helper'

class JavaScriptControllerSecurityTest < Minitest::Test
  CONTROLLER_ROOT = File.expand_path('../../templates/controllers', __dir__)
  GENERATOR_TEMPLATE_ROOT = File.expand_path('../../lib/generators/senren/component/templates', __dir__)
  RICH_TEXT_CONTROLLER = File.join(CONTROLLER_ROOT, 'rich_text_editor_lite_controller.js')

  # `\s*=` did not match `innerHTML +=`, so the compound-assignment form of the
  # same sink slipped through. The patterns below cover both, plus the sinks
  # the original list omitted entirely.
  UNSAFE_DOM_SINKS = {
    /\.innerHTML\s*\+?=[^=]/ => 'innerHTML assignment',
    /\.outerHTML\s*\+?=[^=]/ => 'outerHTML assignment',
    /\.insertAdjacentHTML\s*\(/ => 'insertAdjacentHTML',
    /\.srcdoc\s*\+?=[^=]/ => 'srcdoc assignment',
    /createContextualFragment\s*\(/ => 'Range.createContextualFragment',
    /\bdocument\.write\s*\(/ => 'document.write',
    /\beval\s*\(/ => 'eval',
    /\bnew Function\s*\(/ => 'new Function',
    /\bwindow\.location\s*\+?=[^=]/ => 'window.location assignment',
    /\blocation\.href\s*\+?=[^=]/ => 'location.href assignment'
  }.freeze

  def test_stimulus_controllers_do_not_write_unsanitized_html_or_eval_code
    offenses = controller_files.flat_map do |path|
      File.readlines(path).flat_map.with_index(1) do |line, line_number|
        UNSAFE_DOM_SINKS.filter_map do |pattern, label|
          "#{relative(path)}:#{line_number} uses #{label}" if line.match?(pattern)
        end
      end
    end

    assert_empty offenses, "Unsafe client-side sinks found:\n#{offenses.join("\n")}"
  end

  def test_inner_html_reads_are_confined_to_rich_text_controller
    files = controller_files.select { |path| File.read(path).include?('innerHTML') }

    assert_equal [RICH_TEXT_CONTROLLER], files
  end

  def test_window_open_uses_noopener_and_noreferrer
    offenses = controller_files.filter_map do |path|
      source = File.read(path)
      next unless source.include?('window.open(')

      relative(path) unless source.include?('noopener,noreferrer')
    end

    assert_empty offenses, "window.open must use noopener,noreferrer in: #{offenses.join(', ')}"
  end

  # Pasted markup is rebuilt against an allowlist rather than assigned as HTML,
  # and every href it carries is re-checked before it lands in the document.
  def test_rich_text_editor_sanitizes_pasted_markup
    source = File.read(RICH_TEXT_CONTROLLER)

    assert_includes source, 'sanitizeToFragment', 'pasted HTML must be rebuilt, not inserted verbatim'
    assert_includes source, 'ALLOWED_PASTE_TAGS'
    assert_includes source, 'ALLOWED_PASTE_ATTRIBUTES'
    assert_match(/const href = this\.normalizeHref\(attr\.value\)/, source,
                 'pasted hrefs go through normalizeHref, which never promotes a relative reference')
  end

  def test_rich_text_editor_gates_the_protocol_before_opening_a_link
    source = File.read(RICH_TEXT_CONTROLLER)
    open_call = source[/openLink\(event\).*?\n  \}/m]

    refute_nil open_call
    assert_match(/normalizeHref\(link\.getAttribute\("href"\)\)/, open_call,
                 'openLink reads existing markup, so it uses the markup policy')
  end

  def test_url_normalizer_rejects_backslash_and_control_character_bypasses
    source = File.read(RICH_TEXT_CONTROLLER)

    assert_includes source, 'url.includes("\\\\")',
                    'normalizeUrl must reject backslashes: browsers treat them as "/"'
    assert_match(/charCodeAt\(0\)\s*<=\s*0x1f/, source,
                 'normalizeUrl must reject control characters: browsers strip TAB/CR/LF before parsing')
    # Confirmed in Chrome: without this, "///evil.example" reached the bare-host
    # branch as "https:////evil.example" and was rewritten to
    # https://evil.example/ — a relative-looking value turned into an
    # off-origin absolute URL. safe_url rejects the same shape server-side.
    assert_match(%r{return url\.startsWith\("//"\)}, source,
                 'any leading "//" must be rejected, not just the two-slash form')
    refute_includes source, '!url.startsWith("//")',
                    'the two-slash-only guard let "///evil.example" through'
  end

  # The two helpers exist because a bare word means different things in the two
  # places a URL enters: relative markup versus something a person typed. While
  # one function served both, a pasted href="settings" became https://settings/.
  def test_markup_and_typed_url_policies_are_separate
    source = File.read(RICH_TEXT_CONTROLLER)

    assert_match(/^\s*normalizeHref\(rawUrl\) \{/, source, 'markup policy must exist')
    assert_match(/^\s*normalizeUrl\(rawUrl\) \{/, source, 'typed-input policy must exist')
    assert_match(/^\s*rejectedUrlShape\(url\) \{/, source, 'both must share the unsafe-shape guard')

    # Only insertLink handles typed input; every markup path uses normalizeHref.
    typed_callers = source.scan('this.normalizeUrl(').size

    assert_equal 1, typed_callers,
                 'normalizeUrl may only be called from insertLink; markup must use normalizeHref'
  end

  private

  # The generator template is the starting point for every host-authored
  # controller, so it must be held to the same rules as the shipped ones.
  def controller_files
    Dir[File.join(CONTROLLER_ROOT, '*.js')] + Dir[File.join(GENERATOR_TEMPLATE_ROOT, '*.js.tt')]
  end

  def relative(path)
    path.delete_prefix("#{Dir.pwd}/")
  end
end
