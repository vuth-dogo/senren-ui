# frozen_string_literal: true

require 'test_helper'

class RichTextEditorLiteControllerSecurityTest < Minitest::Test
  CONTROLLER_PATH = File.expand_path('../../templates/controllers/rich_text_editor_lite_controller.js', __dir__)

  def test_link_normalization_uses_protocol_allowlist
    source = File.read(CONTROLLER_PATH)

    assert_includes source, 'ALLOWED_LINK_PROTOCOLS = new Set(["http:", "https:", "mailto:", "tel:"])'
    assert_includes source, 'ALLOWED_LINK_PROTOCOLS.has(parsed.protocol)'
    refute_includes source, 'if (/^(?:[a-z][a-z0-9+.-]*:|\/|#)/i.test(url)) return url'
  end
end

# Slash-count, backslash, and control-character handling used to be asserted
# here as well. Those assertions pinned the exact shape later proved vulnerable
# — `!url.startsWith("//")`, which `///evil.example` walks straight past — so a
# string-matching test was actively defending the bug.
#
# They now live in one place each, at the right level:
#   test/security/javascript_controller_security_test.rb  - the shape is gone
#   test/fixtures/url_policy.yml                          - the policy itself,
#     driven against Ruby in test/security/component_url_security_test.rb and
#     against the browser in test/system/url_policy_test.rb
