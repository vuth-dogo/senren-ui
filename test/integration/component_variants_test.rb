# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'
require 'nokogiri'

# Renders every variant and size the registry declares, for every component.
#
# The gap this closes: `registry_component_contract_test.rb` checks that each
# declared variant appears in a VARIANTS or SIZES constant, and the kitchen-sink
# preview renders each component exactly once in its default state. Neither ever
# rendered a non-default variant, so a variant could be listed, present as a
# constant, and still blow up or emit nothing when actually used.
#
# 122 variants are declared across 62 components.
class ComponentVariantsTest < ViewComponent::TestCase
  # Minimal arguments for the components whose constructor requires them. Kept
  # deliberately boring: the point is to reach the render path, not to exercise
  # behaviour, which the per-component tests do.
  REQUIRED_ARGS = {
    'link' => { href: '/example' },
    'label' => { for_field: 'field' },
    'input' => { name: 'field' },
    'textarea' => { name: 'field' },
    'checkbox' => { name: 'field' },
    'radio_button' => { name: 'field', value: 'one' },
    'native_select' => { name: 'field', options: [%w[one One]] },
    'switch' => { name: 'field' },
    'tooltip' => { text: 'Tooltip text' },
    'clipboard' => { value: 'copy me' },
    'combobox' => { name: 'field', options: [%w[one One]] },
    'date_picker' => { name: 'field' },
    'select' => { name: 'field', options: [%w[one One]] },
    'form' => { url: '/components/static' },
    'product_card' => { title: 'Mug', price: '$14.50', url: '/cart/items' },
    'masked_input' => { mask: '###-###', name: 'field' }
  }.freeze

  # Wrappers that exist to receive content; rendering them empty is meaningless.
  NEEDS_BLOCK = %w[form].freeze

  def registry
    @registry ||= Senren::Rails::Registry.load!
  end

  def test_every_declared_variant_renders
    failures = []
    rendered = 0

    registry.each do |component|
      klass = component_class(component.name)

      Array(component.variants).each do |variant|
        key = variant.to_sym
        option = if klass::VARIANTS.key?(key) then { variant: key }
                 elsif klass::SIZES.key?(key) then { size: key }
                 end

        next unless option

        rendered += 1
        error = render_failure(klass, component.name, option)
        failures << "#{component.name}[#{variant}]: #{error}" if error
      end
    end

    assert_empty failures, "variants that failed to render:\n#{failures.join("\n")}"
    assert_operator rendered, :>=, 100, "expected to render most of the 122 declared variants, got #{rendered}"
  end

  def test_every_declared_size_renders
    failures = []

    registry.each do |component|
      klass = component_class(component.name)

      klass::SIZES.each_key do |size|
        error = render_failure(klass, component.name, size: size)
        failures << "#{component.name}[size=#{size}]: #{error}" if error
      end
    end

    assert_empty failures, "sizes that failed to render:\n#{failures.join("\n")}"
  end

  # Every component template is required to carry the root marker, and the
  # contract test asserts that statically. This asserts it survives rendering.
  def test_every_component_emits_its_root_marker
    problems = registry.names.filter_map do |name|
      html = render_component(component_class(name), name)
      "#{name}: no data-senren-component in output" unless html.include?('data-senren-component')
    rescue StandardError => e
      "#{name}: #{e.class}: #{e.message.lines.first.to_s.strip}"
    end

    assert_empty problems, "components that did not render their root marker:\n#{problems.join("\n")}"
  end

  # Every component must be usable with only its required arguments. Three were
  # not: BaseComponent defaults to `variant: :default`, and typography,
  # separator, and aspect_ratio defined no such variant, so plain `.new` raised
  # ArgumentError. Nothing caught it because the previews always passed a
  # variant explicitly.
  def test_every_component_is_constructible_without_an_explicit_variant
    failures = registry.names.filter_map do |name|
      component_class(name).new(**REQUIRED_ARGS.fetch(name, {}))
      nil
    rescue StandardError => e
      "#{name}: #{e.class}: #{e.message.lines.first.to_s.strip}"
    end

    assert_empty failures, "components that cannot be built with defaults:\n#{failures.join("\n")}"
  end

  # `class:` is a legal kwarg on every Rails tag helper, so it is the first
  # thing a developer types — and it landed in **html_attrs, which was splatted
  # after the computed class and replaced it outright. Passing it erased the
  # component's variant and size styling with no warning. `data:` had the
  # identical defect and was fixed; `class:` was not.
  #
  # Asserted across the whole library, because the bug lived in BaseComponent,
  # and on rendered markup rather than on root_attrs, so it also covers select
  # and masked_input -- pure delegating wrappers that never call root_attrs.
  def test_a_caller_supplied_class_never_erases_component_styling
    losses = registry.names.filter_map do |name|
      baseline = root_classes(render_component(component_class(name), name))
      merged = root_classes(render_component(component_class(name), name, class: 'sentinel-class'))
      lost = baseline - merged

      "#{name}: lost #{lost.to_a.sort.inspect}" unless lost.empty?
    rescue StandardError => e
      "#{name}: #{e.class}: #{e.message.lines.first.to_s.strip}"
    end

    assert_empty losses, "components whose styling a caller `class:` erased:\n#{losses.join("\n")}"
  end

  # A separate defect from the one above, and a pre-existing one: these eight
  # write their root element by hand instead of through root_attrs, so a caller
  # `class:` (and `class_name:`) is not substituted — it is dropped entirely and
  # never reaches the DOM. Found by the test above, which is why it is recorded
  # here rather than quietly excluded from it.
  #
  # Pinned as an exact list so the set can only shrink. Fixing one means
  # deleting its name here; the assertion fails if a new component joins them.
  DROPS_CALLER_CLASS = %w[
    alert_dialog context_menu dialog dropdown_menu hover_card popover sheet tooltip
  ].freeze

  def test_only_the_known_hand_written_roots_ignore_a_caller_class
    ignoring = registry.names.reject do |name|
      root_classes(render_component(component_class(name), name, class: 'sentinel-class'))
        .include?('sentinel-class')
    rescue StandardError
      true
    end

    assert_equal DROPS_CALLER_CLASS, ignoring.sort,
                 'this list must only shrink; a new component ignoring `class:` is a regression'
  end

  # An unknown variant must be refused loudly rather than silently rendering the
  # default, or a typo ships as a styling bug.
  def test_unknown_variants_raise
    error = assert_raises(ArgumentError) { Senren::ButtonComponent.new(variant: :nope) }

    assert_match(/Unknown variant/, error.message)
  end

  def test_unknown_sizes_raise
    error = assert_raises(ArgumentError) { Senren::ButtonComponent.new(size: :enormous) }

    assert_match(/Unknown size/, error.message)
  end

  private

  # The class list on the element carrying the component marker.
  def root_classes(html)
    root = Nokogiri::HTML5.fragment(html).at_css('[data-senren-component]')
    Set.new(root ? root['class'].to_s.split : [])
  end

  def component_class(name)
    Senren.const_get("#{name.split('_').map { |word| word[0].upcase + word[1..] }.join}Component")
  end

  # Deliberately does NOT swallow the exception: an early version returned nil on
  # error, so "rendered but missing its marker" and "raised" looked identical and
  # three components that raised on `.new` were reported as a markup problem.
  def render_failure(klass, name, options)
    render_component(klass, name, options)
    nil
  rescue StandardError => e
    "#{e.class}: #{e.message.lines.first.to_s.strip}"
  end

  def render_component(klass, name, options = {})
    component = klass.new(**REQUIRED_ARGS.fetch(name, {}), **options)

    if NEEDS_BLOCK.include?(name)
      render_inline(component) { 'content' }.to_html
    else
      render_inline(component).to_html
    end
  end
end
