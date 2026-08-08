# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

# A property over every component, rather than a list of the ones someone
# remembered.
#
# The same defect has now been found and fixed three separate times -- `data:`
# in root_attrs, `data:` in DropdownMenu::ItemTag, `class:` in ItemTag -- and
# each fix was applied to one place while the identical bug sat untouched in
# others. Seven overlay components write their root element by hand and never
# call root_attrs, so a caller's `data:` and `class:` reach nothing at all.
#
# The visible consequences differ but the cause is one: an attribute the caller
# passed is silently dropped.
#
#   class:  a component that cannot be extended at its documented extension
#           point, and for dropdown items, no focus indicator for keyboard users
#   data:   no way to set a Stimulus value from the server, so
#           `data-senren--sheet-open-value` never arrives and an overlay cannot
#           be rendered already open -- which the controllers advertise in
#           their own comments
class ComponentAttributePassthroughTest < ViewComponent::TestCase
  # Components whose root is the thing under test here. Slot-only wrappers and
  # components that deliberately render into a parent are out of scope.
  OVERLAYS = %w[dialog alert_dialog sheet popover dropdown_menu context_menu hover_card].freeze

  REQUIRED = {
    'tooltip' => { text: 'T' }
  }.freeze

  def build(name)
    klass = "Senren::#{name.split('_').map { |w| w[0].upcase + w[1..] }.join}Component"
    klass.constantize.new(
      **REQUIRED.fetch(name, {}),
      class: 'probe-class',
      data: { probe: 'yes' }
    )
  end

  def root_of(name, html)
    Nokogiri::HTML5.fragment(html).at_css(%([data-senren-component="#{name}"]))
  end

  def render_root(name)
    render_inline(build(name)) { 'content' }
    root_of(name, page.native.to_html)
  end

  def test_every_overlay_passes_a_caller_data_attribute_to_its_root
    missing = OVERLAYS.reject { |name| render_root(name)&.attr('data-probe') == 'yes' }

    assert_empty missing,
                 "these drop a caller's data: entirely, so a Stimulus value cannot be set " \
                 "from the server: #{missing.join(', ')}"
  end

  # Every overlay's panel is positioned, so every one of them carries this.
  # Named rather than inferred: "the element with the most classes" looked like
  # a reasonable stand-in for "the element the component styles" and is wrong
  # for 20 of the 62 components -- composites like app_shell and calendar style
  # a root that has fewer classes than something nested inside it.
  PANEL_TOKEN = {
    'dialog' => 'max-w-lg',
    'alert_dialog' => 'max-w-md',
    'sheet' => 'fixed',
    'popover' => 'min-w-[12rem]',
    'dropdown_menu' => 'w-56',
    'context_menu' => 'w-56',
    'hover_card' => 'w-64',
    'tooltip' => 'whitespace-nowrap'
  }.freeze

  # Not "on its root" -- on the element it styles.
  #
  # An overlay's root is an empty wrapper; the panel is what has a width. A
  # class parked on the wrapper is in the DOM and does nothing, which is worse
  # to debug than being dropped, because it looks applied.
  #
  # Anchored to a class the panel is known to carry. An earlier version accepted
  # any element holding the sentinel plus one other class, which happens to
  # single out the panel for these eight and would not for a component that
  # renders, say, a <span class="sr-only"> -- it would pass on the label.
  def test_every_overlay_puts_a_caller_class_where_it_styles
    stranded = OVERLAYS.reject { |name| panel_carrying(name, 'probe-class') }

    assert_empty stranded, "these leave a caller class on an element they do not style: #{stranded.join(', ')}"
  end

  # `class_name:` is the documented styling hook and `class:` is what a Rails
  # developer types first. They must reach the same element or one of the two is
  # lying about what it does.
  def test_class_and_class_name_reach_the_same_element
    split = OVERLAYS.reject do |name|
      render_inline(
        build(name).class.new(**REQUIRED.fetch(name, {}), class_name: 'via-class-name', class: 'via-class')
      ) { 'content' }
      element = element_with(page.native.to_html, 'via-class')
      element && element['class'].to_s.split.include?('via-class-name')
    end

    assert_empty split,
                 'these send class: and class_name: to different elements, so one of them is ' \
                 "not the styling hook it claims to be: #{split.join(', ')}"
  end

  # Merging must not cost the component its own hooks.
  def test_passing_attributes_does_not_remove_the_controller_binding
    broken = OVERLAYS.reject do |name|
      root = render_root(name)
      root && root.attr('data-controller').to_s.include?("senren--#{name.tr('_', '-')}")
    end

    assert_empty broken, "these lost their data-controller when given attributes: #{broken.join(', ')}"
  end

  # The capability the fix unlocks, stated as a test so it cannot regress back
  # into a comment that promises something the API cannot do.
  def test_an_overlay_can_be_rendered_already_open_from_the_server
    render_inline(
      Senren::SheetComponent.new(data: { 'senren--sheet-open-value': true })
    ) { 'content' }

    root = root_of('sheet', page.native.to_html)

    assert_equal 'true', root.attr('data-senren--sheet-open-value')
  end

  private

  def element_with(html, token)
    Nokogiri::HTML5.fragment(html).css('[class]').find { |el| el['class'].to_s.split.include?(token) }
  end

  # The sentinel must sit on the element carrying the panel's own base class,
  # not merely somewhere in the subtree.
  def panel_carrying(name, token)
    render_inline(build(name)) { 'content' }
    element = element_with(page.native.to_html, token)
    element && element['class'].to_s.split.include?(PANEL_TOKEN.fetch(name))
  end
end
