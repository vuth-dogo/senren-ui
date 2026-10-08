# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

# DataTableComponent wrote each body cell as `data-sort-value="<%= value %>"`.
# ERB escapes a plain string there, but a cell holding markup -- a badge, a
# link, anything built with `tag` or `render` -- is a SafeBuffer, and ERB does
# not escape a SafeBuffer. Its markup landed inside the attribute: the first
# `"` closed it, the rest became junk attributes on the <td>, and every row's
# sort value was the same fragment (`<span class=`), so sorting did nothing.
#
# The sort value is the cell's text, decoded, and escaped exactly once by ERB.
class DataTableSortValueTest < ViewComponent::TestCase
  def helpers = ActionController::Base.helpers

  def cells_for(values)
    render_inline(Senren::DataTableComponent.new(columns: [:status], rows: values.map { |v| { status: v } }))
    Nokogiri::HTML5.fragment(page.native.to_html).css('tbody td')
  end

  def test_an_html_cell_does_not_break_out_of_the_attribute
    td = cells_for([helpers.tag.span('Active', class: 'badge', title: 'ok')]).first

    assert_equal %w[class data-sort-key data-sort-value], td.attributes.keys.sort
    assert_equal 'Active', td['data-sort-value']
    assert_equal 1, td.css('span.badge[title=ok]').size, 'the cell itself still renders the markup'
  end

  def test_html_cells_sort_by_their_text
    cells = cells_for([helpers.tag.span('Paused', class: 'badge'), helpers.link_to('Active', '/a')])

    assert_equal(%w[Paused Active], cells.map { |td| td['data-sort-value'] })
  end

  # Entities are decoded once and escaped once: a cell showing "R&D" sorts as
  # "R&D", not "R&amp;D".
  def test_an_entity_in_an_html_cell_is_escaped_exactly_once
    td = cells_for([helpers.tag.span('R&D "ok"', class: 'x')]).first

    assert_equal 'R&D "ok"', td['data-sort-value']
    assert_includes rendered_content, 'data-sort-value="R&amp;D &quot;ok&quot;"'
    refute_includes rendered_content, '&amp;amp;'
  end

  # ERB checks `to_s.html_safe?`, not the value's class, so an object that
  # renders itself as markup reaches the attribute the same way a SafeBuffer
  # does.
  def test_an_object_whose_to_s_is_markup_is_reduced_to_its_text
    badge = Struct.new(:label) do
      def to_s = ActionController::Base.helpers.tag.b(label, class: 'x')
    end
    td = cells_for([badge.new('Active')]).first

    assert_equal %w[class data-sort-key data-sort-value], td.attributes.keys.sort
    assert_equal 'Active', td['data-sort-value']
  end

  def test_a_plain_string_cell_is_unchanged
    td = cells_for(['R&D <b>not markup</b>']).first

    assert_equal 'R&D <b>not markup</b>', td['data-sort-value']
    assert_equal 'R&D <b>not markup</b>', td.text
  end

  def test_a_numeric_cell_keeps_its_number
    assert_equal '42', cells_for([42]).first['data-sort-value']
  end
end
