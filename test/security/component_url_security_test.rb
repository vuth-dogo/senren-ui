# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/string/inflections'
require 'view_component'

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
