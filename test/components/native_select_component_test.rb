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

unless defined?(Senren::NativeSelectComponent)
  load File.expand_path('../../templates/components/native_select/native_select_component.rb', __dir__)
end

unless defined?(Senren::SelectComponent)
  load File.expand_path('../../templates/components/select/select_component.rb', __dir__)
end

module Senren
  class NativeSelectComponentTest < Minitest::Test
    TEMPLATE_ROOT = File.expand_path('../../templates/components', __dir__)

    def test_native_arrow_output_preserves_component_marker_on_select_root
      html = render_component(
        NativeSelectComponent.new(
          name: :status,
          options: [%w[draft Draft], %w[published Published]],
          selected: 'published',
          prompt: 'Choose status',
          data: { controller: 'custom-select' }
        ),
        'native_select'
      )
      root = fragment(html).at_css('select')

      assert_equal 'select', root.name
      assert_equal 'native_select', root['data-senren-component']
      assert_equal 'custom-select', root['data-controller']
      assert_includes root['class'], 'appearance-auto'
      assert_equal 'Choose status', root.at_css('option[value=""]').text
      assert root.at_css('option[value="published"]').has_attribute?('selected')
      assert_nil root.previous_element
      assert_nil root.next_element
    end

    def test_custom_arrow_output_keeps_marker_on_wrapper_root
      html = render_component(
        NativeSelectComponent.new(
          name: :status,
          options: [%w[draft Draft]],
          native_arrow: false
        ),
        'native_select'
      )
      root = fragment(html).element_children.first

      assert_equal 'div', root.name
      assert_equal 'native_select', root['data-senren-component']
      assert_nil root.at_css('select')['data-senren-component']
      assert_includes root.at_css('select')['class'], 'appearance-none'
      assert root.at_css('svg[aria-hidden="true"]')
    end

    def test_select_component_default_delegation_renders_marked_native_select
      html = render_component(
        SelectComponent.new(
          name: :role,
          options: [%w[admin Admin]],
          selected: 'admin'
        ),
        'select'
      )
      root = fragment(html).at_css('select')

      assert_equal 'native_select', root['data-senren-component']
      assert_equal 'senren--select', root['data-controller']
      assert_equal 'role', root['name']
      assert root.at_css('option[value="admin"]').has_attribute?('selected')
    end

    private

    def render_component(component, template_name)
      view = ActionView::Base.with_empty_template_cache.empty
      default_render = view.method(:render)
      nested_render = method(:render_component)

      delegate_component_methods(view, component)
      view.define_singleton_method(:content) { '' }
      view.define_singleton_method(:render) do |renderable = nil, *args, **kwargs, &block|
        if renderable.is_a?(NativeSelectComponent)
          nested_render.call(renderable, 'native_select')
        elsif renderable.nil?
          default_render.call(*args, **kwargs, &block)
        else
          default_render.call(renderable, *args, **kwargs, &block)
        end
      end

      view.render(inline: File.read(File.join(TEMPLATE_ROOT, template_name, "#{template_name}_component.html.erb")))
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
