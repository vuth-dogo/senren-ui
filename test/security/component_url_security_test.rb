# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/string/inflections'
require 'view_component'
require 'senren/rails/component_copier'
require_relative '../support/url_policy_fixture'

module Senren
  class ComponentUrlSecurityTest < Minitest::Test
    TEMPLATE_ROOT = File.expand_path('../../templates/components', __dir__)

    COMPONENTS = %w[
      billing_plan_card
      breadcrumb
      button
      carousel
      command
      dropdown_menu
      link
      pagination
      sidebar
      top_nav
    ].freeze

    def setup
      load_component_classes
    end

    def test_safe_url_allows_only_local_and_explicit_safe_protocols
      component = ButtonComponent.new

      assert_equal '#', component.send(:safe_url, nil)
      assert_equal '#', component.send(:safe_url, '')
      assert_equal '#section', component.send(:safe_url, '#section')
      assert_equal '/settings', component.send(:safe_url, '/settings')
      assert_equal '?page=2', component.send(:safe_url, '?page=2')
      assert_equal './settings', component.send(:safe_url, './settings')
      assert_equal 'settings', component.send(:safe_url, 'settings')
      assert_equal 'https://example.com/docs', component.send(:safe_url, 'https://example.com/docs')
      assert_equal 'mailto:support@example.com', component.send(:safe_url, 'mailto:support@example.com')
      assert_equal 'tel:+15551234567', component.send(:safe_url, 'tel:+15551234567')

      assert_equal '#', component.send(:safe_url, '//evil.example/path')
      assert_equal '#', component.send(:safe_url, 'javascript:alert(1)')
      assert_equal '#', component.send(:safe_url, 'data:text/html,<svg onload=alert(1)>')
      assert_equal '#', component.send(:safe_url, 'ftp://example.com/file')
      assert_nil component.send(:safe_url, 'javascript:alert(1)', fallback: nil)
    end

    # Every vector here was resolved in headless Chrome and confirmed to land on
    # https://evil.example/. Browsers normalize "\" to "/" for special schemes
    # and strip TAB/CR/LF before parsing, so several of these look like ordinary
    # relative paths and are not.
    def test_safe_url_rejects_protocol_relative_bypasses
      component = ButtonComponent.new

      [
        '/\\evil.example',
        '/\\/evil.example',
        "/\t/evil.example",
        "/\n/evil.example",
        "/\r/evil.example",
        '\\\\evil.example',
        '\\/evil.example',
        # The slash count matters, and the two forms failed differently: `//`
        # was caught because URI.parse reports a host, while `///` reports
        # neither scheme nor host and so fell through the scheme-less
        # allowance and was returned verbatim. Same bug class, one slash apart.
        '//evil.example',
        '///evil.example',
        '////evil.example',
        "https://ok.example\u0000.evil.example"
      ].each do |vector|
        assert_equal '#', component.send(:safe_url, vector),
                     "safe_url must reject #{vector.inspect}: the browser resolves it off-origin"
        assert_nil component.send(:safe_media_url, vector),
                   "safe_media_url must reject #{vector.inspect}"
      end
    end

    # The shared policy fixture. Its counterpart,
    # test/system/url_policy_test.rb, drives the browser helper from the same
    # file, so a change to one implementation without the other fails here.
    def test_safe_url_matches_the_shared_policy_fixture
      component = ButtonComponent.new

      UrlPolicyFixture.vectors.each do |vector|
        actual = component.send(:safe_url, vector.fetch('input'), fallback: nil)
        expected = vector.fetch('expect')

        if expected.nil?
          assert_nil actual, "must reject #{UrlPolicyFixture.describe(vector)}"
        else
          assert_equal expected, actual, "must allow unchanged: #{UrlPolicyFixture.describe(vector)}"
        end
      end
    end

    # The helper is duplicated in the install template and in the migration
    # patch applied to apps that already have a BaseComponent. They must not
    # drift, or migrated apps keep the vulnerable version.
    def test_safe_url_helper_matches_the_migration_patch
      template = File.read(
        File.expand_path('../../lib/generators/senren/install/templates/base_component.rb.tt', __dir__)
      )
      patch = Senren::Rails::ComponentCopier::BASE_URL_HELPER_PATCH

      assert_equal extract_safe_url(template), extract_safe_url(patch),
                   'base_component.rb.tt and BASE_URL_HELPER_PATCH must define the same safe_url'
    end

    def test_safe_media_url_allows_only_http_urls_and_local_paths
      component = ButtonComponent.new

      assert_equal '/images/card.png', component.send(:safe_media_url, '/images/card.png')
      assert_equal 'https://cdn.example.com/card.png', component.send(:safe_media_url, 'https://cdn.example.com/card.png')

      assert_nil component.send(:safe_media_url, 'mailto:support@example.com')
      assert_nil component.send(:safe_media_url, 'data:image/svg+xml,<svg onload=alert(1)>')
      assert_nil component.send(:safe_media_url, '//cdn.example.com/card.png')
    end

    def test_navigation_components_normalize_unsafe_urls
      assert_equal '#', TopNavComponent.new(items: [{ label: 'Bad', href: 'javascript:alert(1)' }]).items.first[:href]
      sidebar = SidebarComponent.new(items: [{ label: 'Bad', href: 'data:text/html,<script>' }])
      carousel = CarouselComponent.new(slides: [{ title: 'Bad', image_url: 'data:image/svg+xml,<svg>' }])

      assert_equal '#', sidebar.items.first[:href]
      assert_nil BreadcrumbComponent.new(items: [{ label: 'Bad', href: 'javascript:alert(1)' }]).items.first[:href]
      assert_nil CommandComponent.new(items: [{ label: 'Bad', href: 'javascript:alert(1)' }]).items.first[:href]
      assert_nil carousel.slides.first[:image_url]
      assert_equal '?page=2', PaginationComponent.new(total_pages: 5, path: '?page=:page').page_url(2)
      assert_equal '#', PaginationComponent.new(path: 'javascript:alert(:page)').page_url(2)
    end

    # A property over every component in the library, rather than a list of the
    # ones someone remembered.
    #
    # COMPONENTS above is an allowlist, so a component added later was missed by
    # construction — and two were: FormComponent#url reached form_with's action,
    # where `//evil.example` POSTs every field plus the CSRF token off-origin,
    # and AvatarComponent#src reached image_tag on user-controlled profile data.
    # Both had shipped. This scans all of them instead, so the next one cannot
    # slip through by being new.
    URL_KEYWORDS = %w[url href src].freeze
    SANITIZERS = %w[safe_url safe_media_url].freeze

    def test_every_component_taking_a_url_routes_it_through_a_sanitizer
      unguarded = Dir.children(TEMPLATE_ROOT).sort.reject do |name|
        source = component_sources(name)
        next true if source.empty?
        next true unless takes_url_argument?(source)

        SANITIZERS.any? { |helper| source.include?(helper) }
      end

      assert_empty unguarded,
                   'these components accept a URL-ish argument but never call ' \
                   "safe_url or safe_media_url: #{unguarded.join(', ')}"
    end

    def test_href_templates_use_safe_url_helper
      {
        'billing_plan_card' => 'safe_url(cta_href)',
        'button' => 'safe_url(href)',
        'link' => 'safe_url(href)'
      }.each do |component, guard|
        template = File.read(File.join(TEMPLATE_ROOT, component, "#{component}_component.html.erb"))

        assert_includes template, guard, "#{component} should sanitize href values through safe_url"
      end

      dropdown = File.read(File.join(TEMPLATE_ROOT, 'dropdown_menu', 'dropdown_menu_component.rb'))
      assert_includes dropdown, 'safe_url(@href)'
      assert_operator DropdownMenuComponent::ItemTag, :<, BaseComponent
    end

    private

    def component_sources(name)
      dir = File.join(TEMPLATE_ROOT, name)
      return '' unless File.directory?(dir)

      Dir.glob(File.join(dir, '*')).select { |f| File.file?(f) }.map { |f| File.read(f) }.join("\n")
    end

    # A keyword argument whose name is url/href/src, or a hash entry read out of
    # one — `item[:href]`, `slide[:image_url]`. Deliberately broad: a false
    # positive costs one `safe_url` call, a false negative ships an open
    # redirect.
    def takes_url_argument?(source)
      URL_KEYWORDS.any? do |word|
        source.match?(/\b\w*#{word}:\s/) || source.match?(/\[:\w*#{word}\]/)
      end
    end

    def extract_safe_url(source)
      body = source[/def safe_url.*?^\s*end\s*$/m]

      refute_nil body, 'expected a safe_url definition'
      body.lines.map(&:strip).reject(&:empty?).join("\n")
    end

    def load_component_classes
      unless defined?(BaseComponent)
        load File.expand_path('../../lib/generators/senren/install/templates/base_component.rb.tt', __dir__)
      end

      COMPONENTS.each do |name|
        class_name = "#{name.camelize}Component"
        next if Senren.const_defined?(class_name, false)

        load File.join(TEMPLATE_ROOT, name, "#{name}_component.rb")
      end
    end
  end
end
