# frozen_string_literal: true

require 'test_helper'
require 'action_view'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/string/inflections'
require 'nokogiri'
require 'view_component'

unless defined?(Senren::BaseComponent)
  load File.expand_path('../../lib/generators/senren/install/templates/base_component.rb.tt', __dir__)
end

unless defined?(Senren::DropdownMenuComponent)
  load File.expand_path('../../templates/components/dropdown_menu/dropdown_menu_component.rb', __dir__)
end

module Senren
  class DropdownMenuComponentTest < Minitest::Test
    TEMPLATE_ROOT = File.expand_path('../../templates/components', __dir__)

    def test_item_tag_button_preserves_html_attributes
      html = render_item(DropdownMenuComponent::ItemTag.new(
                           id: 'delete-btn',
                           class_name: 'custom-item',
                           data: { turbo_method: 'delete' }
                         ))

      root = fragment(html)
      assert_equal 'button', root.name
      assert_equal 'delete-btn', root['id']
      assert_includes root['class'], 'custom-item'
      assert_equal 'delete', root['data-turbo-method']
    end

    def test_item_tag_link_preserves_html_attributes
      html = render_item(DropdownMenuComponent::ItemTag.new(
                           href: '/settings',
                           id: 'settings-link',
                           class_name: 'custom-item',
                           data: { turbo_frame: 'main' }
                         ))

      root = fragment(html)
      assert_equal 'a', root.name
      assert_equal 'settings-link', root['id']
      assert_includes root['class'], 'custom-item'
      assert_equal 'main', root['data-turbo-frame']
      assert_equal '/settings', root['href']
    end

    def test_item_tag_link_applies_default_item_class
      html = render_item(DropdownMenuComponent::ItemTag.new(href: '/home'))

      root = fragment(html)
      assert_equal 'a', root.name
      assert_includes root['class'], 'block'
      assert_includes root['class'], 'cursor-pointer'
    end

    def test_item_tag_button_applies_default_item_class
      html = render_item(DropdownMenuComponent::ItemTag.new)

      root = fragment(html)
      assert_equal 'button', root.name
      assert_includes root['class'], 'block'
      assert_includes root['class'], 'cursor-pointer'
    end

    def test_item_tag_destructive_adds_destructive_class
      html = render_item(DropdownMenuComponent::ItemTag.new(destructive: true))

      root = fragment(html)
      assert_includes root['class'], 'text-[hsl(var(--senren-destructive))]'
    end

    def test_item_tag_button_has_menu_role
      html = render_item(DropdownMenuComponent::ItemTag.new)

      root = fragment(html)
      assert_equal 'menuitem', root['role']
      assert_equal 'button', root['type']
    end

    def test_item_tag_link_has_menu_role
      html = render_item(DropdownMenuComponent::ItemTag.new(href: '/page'))

      root = fragment(html)
      assert_equal 'menuitem', root['role']
    end

    def test_item_tag_sanitizes_url
      html = render_item(DropdownMenuComponent::ItemTag.new(href: 'javascript:alert(1)'))

      root = fragment(html)
      assert_equal '#', root['href']
    end

    private

    def render_item(component)
      view = ActionView::Base.with_empty_template_cache.empty
      component.define_singleton_method(:content) { 'Item' }
      component.render_in(view)
    end

    def fragment(html)
      Nokogiri::HTML5.fragment(html).element_children.first
    end
  end
end
