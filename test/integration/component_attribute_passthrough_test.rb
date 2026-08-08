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

  def test_every_overlay_merges_a_caller_class_into_its_root
    missing = OVERLAYS.reject { |name| render_root(name)&.attr('class').to_s.include?('probe-class') }

    assert_empty missing, "these drop a caller's class: #{missing.join(', ')}"
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
end
