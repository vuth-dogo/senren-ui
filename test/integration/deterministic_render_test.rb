# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'

# Rendering the same component with the same arguments must produce the same
# HTML, every time and in every process.
#
# Eight components used to append `SecureRandom.hex` to their id, so this was
# false. That one fact disabled four things at once:
#
#   Turbo morph   — pairs old and new nodes by id, so a changing id makes every
#                   morph a replacement
#   HTTP ETags    — computed from the body, which never matched, so a client
#                   never received a 304
#   Fragment cache— a cached fragment and a fresh one referenced different ids,
#                   leaving aria-controls and label[for] pointing at nothing
#   Snapshot tests— impossible, which is why the repo had none
#
# The test walks the registry rather than a hand-written list, so a component
# added later is covered without anyone remembering to add it here.
class DeterministicRenderTest < ViewComponent::TestCase
  REQUIRED_ARGS = ComponentVariantsTest::REQUIRED_ARGS
  NEEDS_BLOCK = ComponentVariantsTest::NEEDS_BLOCK

  def registry
    @registry ||= Senren::Rails::Registry.load!
  end

  # Rails emits a fresh CSRF token per request, and a stable one would be a
  # vulnerability. It is normalised out rather than excluding the form component
  # wholesale, so the rest of its markup is still held to the rule.
  CSRF_TOKEN = /name="authenticity_token" value="[^"]*"/

  def test_every_component_renders_identically_twice
    unstable = registry.names.filter_map do |name|
      first = normalize(render_component(name))
      second = normalize(render_component(name))

      next if first == second

      "#{name}: #{diff_hint(first, second)}"
    end

    assert_empty unstable, "components whose output changes between renders:\n#{unstable.join("\n")}"
  end

  # Guards the normalisation above: if the token stops varying, that is a
  # security regression, not a determinism win.
  def test_the_csrf_token_still_varies
    first = render_component('form')
    second = render_component('form')

    assert_match CSRF_TOKEN, first, 'the form component must still emit a CSRF token'
    refute_equal first, second, 'a CSRF token that repeats across renders is a vulnerability'
  end

  def test_no_component_template_generates_a_random_id
    offenders = Dir[File.expand_path('../../templates/components/**/*.rb', __dir__)].select do |path|
      File.read(path).match?(/SecureRandom|rand\(|object_id/)
    end

    assert_empty offenders.map { |path| path[%r{templates/components/.*}] },
                 'component output must be derived from its arguments, never generated'
  end

  # The escape hatch has to keep working: an explicit id always wins.
  def test_an_explicit_id_is_used_verbatim
    html = render_inline(Senren::DialogComponent.new(id: 'checkout-confirm')).to_html

    assert_includes html, 'checkout-confirm'
  end

  # Two components with the same identifying input now collide by design, so
  # that the accessibility test reports it instead of randomness hiding it.
  def test_identical_inputs_produce_identical_ids
    one = Senren::CheckboxComponent.new(name: 'terms', value: '1')
    two = Senren::CheckboxComponent.new(name: 'terms', value: '1')

    assert_equal one.id, two.id
    refute_equal one.id, Senren::CheckboxComponent.new(name: 'terms', value: '2').id
  end

  private

  def normalize(html)
    html.gsub(CSRF_TOKEN, 'name="authenticity_token" value="NORMALIZED"')
  end

  def render_component(name)
    klass = Senren.const_get("#{name.split('_').map { |word| word[0].upcase + word[1..] }.join}Component")
    component = klass.new(**REQUIRED_ARGS.fetch(name, {}))

    if NEEDS_BLOCK.include?(name)
      render_inline(component) { 'content' }.to_html
    else
      render_inline(component).to_html
    end
  end

  def diff_hint(first, second)
    index = first.each_char.zip(second.each_char).index { |a, b| a != b }
    return 'differing length' unless index

    "diverges at #{index}: #{first[index, 40].inspect} vs #{second[index, 40].inspect}"
  end
end
