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

unless defined?(Senren::PaginationComponent)
  load File.expand_path('../../templates/components/pagination/pagination_component.rb', __dir__)
end

module Senren
  class PaginationComponentTest < Minitest::Test
    TEMPLATE_ROOT = File.expand_path('../../templates/components', __dir__)

    def test_page_url_clamps_below_first_page
      component = PaginationComponent.new(current_page: 1, total_pages: 5, path: '/items?page=:page')

      assert_equal '/items?page=1', component.page_url(0)
    end

    def test_page_url_clamps_above_last_page
      component = PaginationComponent.new(current_page: 5, total_pages: 5, path: '/items?page=:page')

      assert_equal '/items?page=5', component.page_url(6)
    end

    def test_first_page_previous_link_does_not_render_page_zero
      html = render_component(PaginationComponent.new(current_page: 1, total_pages: 5, path: '/items?page=:page'))
      previous_link = fragment(html).at_css('a', text: 'Previous')

      assert_equal '/items?page=1', previous_link['href']
    end

    def test_last_page_next_link_does_not_render_past_last_page
      html = render_component(PaginationComponent.new(current_page: 5, total_pages: 5, path: '/items?page=:page'))
      next_link = fragment(html).css('a').find { |link| link.text == 'Next' }

      assert_equal '/items?page=5', next_link['href']
    end

    def test_in_range_page_url_still_uses_requested_page
      component = PaginationComponent.new(current_page: 3, total_pages: 5, path: ->(page) { "/items?page=#{page}" })

      assert_equal '/items?page=4', component.page_url(4)
    end

    def test_relative_query_page_url_remains_same_origin
      component = PaginationComponent.new(current_page: 1, total_pages: 5, path: '?page=:page')

      assert_equal '?page=2', component.page_url(2)
    end

    private

    def render_component(component)
      view = ActionView::Base.with_empty_template_cache.empty
      delegate_component_methods(view, component)
      view.define_singleton_method(:content) { '' }

      view.render(inline: File.read(File.join(TEMPLATE_ROOT, 'pagination', 'pagination_component.html.erb')))
    end

    def delegate_component_methods(view, component)
      component_methods = component.class.ancestors
                                   .take_while { |ancestor| ancestor != ViewComponent::Base }
                                   .flat_map { |ancestor| ancestor.public_instance_methods(false) }

      component_methods.each do |method_name|
        next if method_name == :render

        view.define_singleton_method(method_name) do |*args, **kwargs, &block|
          component.public_send(method_name, *args, **kwargs, &block)
        end
      end
    end

    def fragment(html)
      Nokogiri::HTML5.fragment(html)
    end
  end
end
