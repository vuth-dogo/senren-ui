# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

# TableComponent and DataTableComponent render `<caption class="sr-only">`.
# `sr-only` is `position: absolute`, and nothing in either component was
# positioned, so the caption's containing block was whatever positioned
# ancestor the page happened to have -- usually the initial containing block.
#
# Two effects. The components' own `overflow-hidden` / `overflow-x-auto`
# wrappers did not clip the caption, because an overflow clip only applies to
# descendants whose containing block is inside it. And in the common
# "document never scrolls, <main> scrolls" shell, the caption sat at its static
# position relative to the document, so a table below the fold made the
# document taller and the window scrolled into blank space under an
# `h-screen overflow-hidden` shell.
#
# Asserted on markup, not geometry: the dummy app ships no Tailwind stylesheet,
# so `relative` and `overflow-hidden` have no effect in a browser here (see
# focus_ring_room_test.rb). The property checked is the CSS rule itself: the
# caption's containing block must be inside the component, at or below an
# element that clips overflow.
class CaptionContainingBlockTest < ViewComponent::TestCase
  POSITIONED = /(?:\A|\s)(?:relative|absolute|fixed|sticky)(?:\s|\z)/
  CLIPS = /(?:\A|\s)overflow-(?:hidden|clip|auto|scroll|x-auto|y-auto|x-hidden|y-hidden)(?:\s|\z)/

  def columns = [{ key: :name, label: 'Name' }]
  def rows = [{ name: 'a' }, { name: 'b' }]

  def caption_and_root(component)
    render_inline(component)
    doc = Nokogiri::HTML5.fragment(page.native.to_html)
    root = doc.at_css('[data-senren-component]')
    [root.at_css('caption.sr-only'), root]
  end

  # Ancestors of `node` up to and including `root`, nearest first.
  def ancestors_within(node, root)
    node.ancestors.take_while { |a| a != root.parent }.grep(Nokogiri::XML::Element)
  end

  def assert_caption_contained(component)
    caption, root = caption_and_root(component)
    refute_nil caption, 'expected an sr-only caption to assert about'

    containing_block = ancestors_within(caption, root).find { |a| a['class'].to_s.match?(POSITIONED) }
    refute_nil containing_block,
               "no positioned ancestor inside #{root['data-senren-component']}: the sr-only caption is positioned " \
               'against the page and escapes every overflow container'

    clipped = [containing_block, *ancestors_within(containing_block, root)].any? { |a| a['class'].to_s.match?(CLIPS) }
    assert clipped, "the caption's containing block is not inside an element that clips overflow"
  end

  def test_table_caption_is_contained_by_the_component
    assert_caption_contained(Senren::TableComponent.new(columns:, rows:, caption: 'Models'))
  end

  def test_data_table_caption_is_contained_by_the_component
    assert_caption_contained(Senren::DataTableComponent.new(columns:, rows:, caption: 'Models'))
  end
end
