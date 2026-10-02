# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'
require 'active_model'

# FormComponent is documented to yield the Rails form builder, so a caller can
# write `f.text_field :title`. It yielded the component instead: ViewComponent's
# `content` always calls the render block with the component as its argument.
#
# That failed silently. A component is an ActionView::Base, so it answers the
# template-level `text_field(object_name, method, options)`, and
# `f.text_field :title, class: "x"` rendered `name="title[{class: "x"}]"` --
# the options hash serialised into the field name. The page looked right, the
# form submitted, and the controller received nothing under `title`.
class FormBuilderYieldTest < ViewComponent::TestCase
  def form_html(**, &)
    render_inline(Senren::FormComponent.new(url: '/import', method: :post, **), &)
    Nokogiri::HTML5.fragment(page.native.to_html)
  end

  def test_the_block_receives_the_form_builder
    klass = nil
    form_html { |f| klass = f.class.name }

    assert_equal 'ActionView::Helpers::FormBuilder', klass
  end

  def test_a_builder_field_posts_under_its_own_name
    input = form_html { |f| f.text_field(:title, placeholder: 'T', class: 'x') }.at_css('input[type=text]')

    assert_equal 'title', input['name']
    assert_equal 'T', input['placeholder']
    assert_equal 'x', input['class']
  end

  def test_a_file_field_keeps_its_options_as_attributes
    doc = form_html(multipart: true) { |f| f.file_field(:file, accept: 'application/json') }
    input = doc.at_css('input[type=file]')

    assert_equal 'file', input['name']
    assert_equal 'application/json', input['accept']
    assert_equal 'multipart/form-data', doc.at_css('form')['enctype']
  end

  # The documented create-form example: with a model, the builder scopes the
  # field under the model's param key.
  class Post
    include ActiveModel::Model

    attr_accessor :title

    def persisted? = false
  end

  def test_a_model_form_scopes_builder_fields_under_the_model
    render_inline(Senren::FormComponent.new(model: Post.new(title: 'Hello'), url: '/posts')) { |f| f.text_field(:title) }
    input = Nokogiri::HTML5.fragment(page.native.to_html).at_css('input[type=text]')

    assert_equal 'form_builder_yield_test_post[title]', input['name']
    assert_equal 'Hello', input['value']
  end

  # The fields land inside the form, not beside it.
  def test_builder_fields_render_inside_the_form_element
    doc = form_html { |f| f.text_field(:title) }

    assert_equal 1, doc.css('form input[name=title]').size
  end

  # Callers that never touch the builder must keep working: a block with no
  # parameter, and with_content.
  def test_a_block_without_a_builder_parameter_still_renders
    doc = form_html { ActionController::Base.helpers.tag.input(name: 'q') }

    assert_equal 1, doc.css('form input[name=q]').size
  end

  def test_with_content_still_renders
    render_inline(Senren::FormComponent.new(url: '/import').with_content('static'))

    assert_includes page.native.at_css('form').text, 'static'
  end
end
