# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

class RichTextInitialContentSecurityTest < ViewComponent::TestCase
  def test_initial_content_removes_active_markup_and_script_urls
    value = <<~HTML
      <script>alert(1)</script><img src="x" onerror="alert(1)">
      <svg onload="alert(1)"></svg><iframe src="https://evil.example"></iframe>
      <a href="javascript:alert(1)" onclick="alert(1)">script link</a>
      <a href="data:text/html,unsafe">data link</a>
      <a href="java&#x73;cript:alert(1)">encoded link</a>
      <p data-align="left"><strong>Preserved formatting</strong></p>
      <a href="/safe?page=2&amp;sort=name">Safe link</a>
    HTML

    render_inline(Senren::RichTextEditorLiteComponent.new(value: value, debug: false))
    editor = page.native.at_css('[contenteditable]')

    assert_empty editor.css('script, img, svg, iframe, object, embed')
    event_attributes = editor.css('*').flat_map do |node|
      node.attribute_nodes.select { |attribute| attribute.name.start_with?('on') }
    end
    assert_empty event_attributes
    editor.css('a').first(3).each { |link| assert_nil link['href'] }
    assert_equal 'left', editor.at_css('p')['data-align']
    assert_equal 'Preserved formatting', editor.at_css('strong').text
    assert_equal '/safe?page=2&sort=name', editor.css('a').last['href']
  end
end
