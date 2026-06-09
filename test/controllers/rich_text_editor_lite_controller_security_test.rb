# frozen_string_literal: true

require 'test_helper'

class RichTextEditorLiteControllerSecurityTest < Minitest::Test
  CONTROLLER_PATH = File.expand_path('../../templates/controllers/rich_text_editor_lite_controller.js', __dir__)

  def test_link_normalization_uses_protocol_allowlist
    source = File.read(CONTROLLER_PATH)

    assert_includes source, 'ALLOWED_LINK_PROTOCOLS = new Set(["http:", "https:", "mailto:", "tel:"])'
    assert_includes source, 'ALLOWED_LINK_PROTOCOLS.has(parsed.protocol)'
    assert_includes source, '!url.startsWith("//")'
    refute_includes source, 'if (/^(?:[a-z][a-z0-9+.-]*:|\/|#)/i.test(url)) return url'
  end
end
