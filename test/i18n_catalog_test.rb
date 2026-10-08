# frozen_string_literal: true

require 'test_helper'
require 'action_view'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/string/inflections'
require 'i18n'
require 'nokogiri'
require 'ripper'
require 'view_component'
require 'senren/rails/base_component_patch'
require_relative '../scripts/i18n_catalog'

unless defined?(Senren::BaseComponent)
  load File.expand_path('../lib/generators/senren/install/templates/base_component.rb.tt', __dir__)
end

# Every string a component shows or announces goes through `senren_t`, with its
# English as the `default:`. These tests keep that true, and keep the two files
# the gem ships - senren.en.yml and senren.vi.yml - from drifting away from it.
#
# The English is written once, in the component. senren.en.yml is generated from
# it (bin/i18n-sync), so a second copy cannot disagree; the test below fails if
# someone edits either by hand.
class I18nCatalogTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  LOCALES = File.join(ROOT, 'templates/locales')
  EN_FILE = File.join(LOCALES, 'senren.en.yml')
  VI_FILE = File.join(LOCALES, 'senren.vi.yml')

  def catalog
    @catalog ||= I18nCatalog.new(root: ROOT)
  end

  def en
    @en ||= YAML.safe_load_file(EN_FILE).fetch('en').fetch('senren')
  end

  def vi
    @vi ||= YAML.safe_load_file(VI_FILE).fetch('vi').fetch('senren')
  end

  def flat(tree)
    I18nCatalog.flatten(tree).to_h
  end

  # --- The helper ------------------------------------------------------------

  def test_the_catalogue_is_not_empty
    assert_operator catalog.defaults.size, :>=, 100, 'the scan found almost nothing - it has drifted from the templates'
    assert_operator catalog.source_files.size, :>=, 120
  end

  def test_senren_t_returns_the_default_when_nothing_is_translated
    component = Senren::BaseComponent.new

    assert_equal 'Next', component.senren_t('pagination.next', default: 'Next')
  end

  def test_senren_t_interpolates_and_otherwise_returns_the_template_untouched
    component = Senren::BaseComponent.new

    assert_equal 'Slide 1 of 3',
                 component.senren_t('carousel.status', default: 'Slide %{current} of %{total}', current: 1, total: 3)
    assert_equal 'Slide %{current} of %{total}',
                 component.senren_t('carousel.status', default: 'Slide %{current} of %{total}'),
                 'with no values the raw template comes back, which is how a controller is handed one'
  end

  # A typo'd variable in a host's translation must cost the translation, not
  # the page.
  def test_a_translation_naming_an_unknown_variable_falls_back_to_the_english
    component = Senren::BaseComponent.new
    I18n.backend.store_translations(:en, senren: { carousel: { status: 'Bild %{curent} von %{total}' } })

    assert_equal 'Slide 1 of 3',
                 component.senren_t('carousel.status', default: 'Slide %{current} of %{total}', current: 1, total: 3)
  ensure
    I18n.reload!
  end

  def test_senren_t_is_public_so_templates_rendered_without_a_view_can_reach_it
    assert_includes Senren::BaseComponent.public_instance_methods(false), :senren_t
  end

  # The same helper reaches hosts installed before it existed, by being appended
  # to their BaseComponent. If the two bodies drift, those apps translate
  # differently from the ones installed fresh.
  def test_the_migration_patch_and_the_template_define_the_same_helper
    template = File.read(File.join(ROOT, 'lib/generators/senren/install/templates/base_component.rb.tt'))

    assert_equal helper_body(template),
                 helper_body(Senren::Rails::BaseComponentPatch::TRANSLATION_HELPER),
                 'BaseComponentPatch::TRANSLATION_HELPER must be the same code as the template'
  end

  # --- The calls -------------------------------------------------------------

  def test_every_call_has_a_literal_key_and_a_literal_default
    assert_empty catalog.problems, "senren_t calls the catalogue cannot read:\n#{catalog.problems.join("\n")}"
  end

  def test_one_key_never_has_two_defaults
    assert_empty catalog.conflicts, "keys used with different English:\n#{catalog.conflicts.join("\n")}"
  end

  def test_keys_are_dotted_snake_case
    assert_empty catalog.malformed_keys, 'keys must look like component.key or component.group.key'
  end

  def test_a_component_uses_only_its_own_namespace_and_shared
    assert_empty catalog.namespace_violations
  end

  def test_every_namespace_is_a_registered_component_or_shared
    registry = YAML.safe_load_file(File.join(ROOT, 'registry/components.yml'), aliases: false).fetch('components').keys
    namespaces = catalog.defaults.keys.map { |key| key.split('.').first }.uniq

    assert_empty namespaces - registry - [I18nCatalog::SHARED]
  end

  # `shared` is for a word that is the same word in more than one place. A key
  # with a single user belongs to that component, where it can be changed
  # without wondering who else reads it.
  def test_a_shared_key_is_used_by_at_least_two_components
    lonely = catalog.defaults.keys.grep(/\Ashared\./).select { |key| catalog.users_of(key).size < 2 }

    assert_empty lonely, "move these into their component's namespace: #{lonely.join(', ')}"
  end

  # --- senren.en.yml ---------------------------------------------------------

  def test_the_english_file_is_the_generated_catalogue
    assert_equal catalog.to_yaml, File.read(EN_FILE), 'senren.en.yml is out of date; run bin/i18n-sync'
  end

  def test_the_english_file_says_exactly_what_the_code_says
    assert_equal catalog.defaults, flat(en)
  end

  # --- senren.vi.yml ---------------------------------------------------------

  def test_vietnamese_has_exactly_the_keys_english_has
    missing = flat(en).keys - flat(vi).keys
    extra = flat(vi).keys - flat(en).keys

    assert_empty missing, "senren.vi.yml is missing: #{missing.join(', ')}"
    assert_empty extra, "senren.vi.yml has keys no component uses: #{extra.join(', ')}"
  end

  def test_vietnamese_keeps_every_interpolation_variable
    mismatched = flat(en).filter_map do |key, english|
      theirs = flat(vi)[key]
      next if I18nCatalog.variables(english) == I18nCatalog.variables(theirs)

      "#{key}: en #{I18nCatalog.variables(english)} vs vi #{I18nCatalog.variables(theirs)}"
    end

    assert_empty mismatched,
                 "a dropped or renamed %{variable} raises when the component renders:\n#{mismatched.join("\n")}"
  end

  def test_vietnamese_values_are_real_text
    blank = flat(vi).select { |_key, value| !value.is_a?(String) || value.strip.empty? }.keys

    assert_empty blank
  end

  # --- Both files ------------------------------------------------------------

  # `no`, `on`, `off` and `yes` as a bare YAML key are booleans, so a key named
  # after one loads as `false`/`true` and its translation is silently unreachable.
  def test_every_yaml_key_is_a_string
    [en, vi].each do |tree|
      keys = all_keys(tree)

      assert_empty(keys.grep_v(String), 'YAML read a key as a boolean or a number')
    end
  end

  def test_each_file_declares_the_locale_its_name_promises
    assert_equal ['en'], YAML.safe_load_file(EN_FILE).keys
    assert_equal ['vi'], YAML.safe_load_file(VI_FILE).keys
  end

  def test_the_files_load_into_i18n_and_resolve
    backend = I18n::Backend::Simple.new
    backend.load_translations(EN_FILE, VI_FILE)

    assert_equal 'Next', backend.translate(:en, 'senren.pagination.next')
    assert_equal 'Sau', backend.translate(:vi, 'senren.pagination.next')
    assert_equal 'Tháng 5', backend.translate(:vi, 'senren.calendar.months.may')
  end

  # --- No bare English -------------------------------------------------------

  # A ratchet, not a proof: it reads what a template shows and fails on a word
  # that did not go through senren_t, so the next component cannot quietly bring
  # the problem back. It is deliberately simple. What it cannot see is text built
  # from caller data, which is the caller's to translate.
  #
  # Symbols are not words. `×`, `+`, `*`, `•` and the editor's `P`, `H1`, `B`
  # contain no run of letters long enough to read as one.
  WORD = /\p{L}{2,}/

  def test_no_template_shows_a_bare_word
    offenders = erb_files.flat_map { |path| bare_text_in(path) }

    assert_empty offenders, "words that should go through senren_t:\n#{offenders.join("\n")}"
  end

  # An argument default such as `label: 'Tabs'` is exactly what this change
  # removed. Parameters that hold an identifier rather than a sentence are
  # listed by name.
  IDENTIFIER_PARAMETERS = %w[name role_name email_name content_id separator currency type value].freeze

  def test_no_constructor_default_is_a_bare_word
    offenders = ruby_files.flat_map { |path| bare_defaults_in(path) }

    assert_empty offenders, "constructor defaults that should go through senren_t:\n#{offenders.join("\n")}"
  end

  # Capitalised words in a string literal outside a senren_t call. Option values
  # that a form submits (`Member`, `Admin`) are what the host compares against,
  # so they stay as they are and are named here.
  SUBMITTED_VALUES = %w[Member Admin].freeze

  def test_no_component_class_holds_a_bare_sentence
    offenders = ruby_files.flat_map { |path| bare_literals_in(path) }

    assert_empty offenders, "string literals that read like text:\n#{offenders.join("\n")}"
  end

  private

  def erb_files
    Dir[File.join(ROOT, 'templates/components/*/*.html.erb')]
  end

  def ruby_files
    Dir[File.join(ROOT, 'templates/components/*/*_component.rb')]
  end

  def helper_body(source)
    source[/^ *def senren_t.*?^ *end$/m].to_s.lines.map(&:strip).join("\n")
  end

  def all_keys(tree)
    tree.flat_map { |key, value| [key] + (value.is_a?(Hash) ? all_keys(value) : []) }
  end

  # ERB tags become NUL so that what is left is the markup a browser would see,
  # with a hole wherever Ruby will write something.
  def bare_text_in(path)
    relative = path.delete_prefix("#{ROOT}/")
    html = File.read(path).gsub(/<%.*?%>/m, "\u0000")
    fragment = Nokogiri::HTML5.fragment(html)

    texts = fragment.xpath('.//text()').reject { |node| node.ancestors.any? { |a| %w[script style].include?(a.name) } }
    found = texts.map { |node| node.text.delete("\u0000").strip }.grep(WORD)
                 .map { |text| "#{relative}: text #{text.inspect}" }

    attributes = %w[aria-label title placeholder alt data-placeholder aria-description]
    fragment.css(attributes.map { |name| "[#{name}]" }.join(', ')).each do |element|
      attributes.each do |name|
        value = element[name].to_s.delete("\u0000")
        found << "#{relative}: #{name}=#{value.inspect}" if value.match?(WORD)
      end
    end
    found
  end

  def bare_defaults_in(path)
    relative = path.delete_prefix("#{ROOT}/")
    sexp = Ripper.sexp(File.read(path))
    found = []

    walk(sexp) do |node|
      next unless node.is_a?(Array) && node.first == :def && node[1][1] == 'initialize'

      keyword_defaults(node[2]).each do |name, default|
        next if IDENTIFIER_PARAMETERS.include?(name)
        next unless default.is_a?(Array) && default.first == :string_literal

        text = default.flatten.grep(String).join
        found << "#{relative}: #{name}: #{text.inspect}" if text.match?(WORD)
      end
    end
    found
  end

  def bare_literals_in(path)
    relative = path.delete_prefix("#{ROOT}/")
    source = File.read(path).lines.reject { |line| line.strip.start_with?('#') }.join
    source = source.gsub(/senren_t\(.*?default:\s*(?:'[^']*'|"[^"]*")/m, 'senren_t(')

    source.scan(/'([A-Z][a-z]{2,}[^']*)'|"([A-Z][a-z]{2,}[^"]*)"/).flatten.compact.filter_map do |literal|
      next if SUBMITTED_VALUES.include?(literal)
      next if literal.match?(/\A[A-Z][a-z]+[A-Z]\w*\z/) # a class name such as 'OptionTag', not a sentence

      "#{relative}: #{literal.inspect}"
    end
  end

  def keyword_defaults(params)
    return [] unless params.is_a?(Array)

    params = params[1] if params.first == :paren
    keywords = params[5] || []
    keywords.map { |(label, default)| [label[1].delete_suffix(':'), default] }
  end

  def walk(node, &block)
    return unless node.is_a?(Array)

    yield node
    node.each { |child| walk(child, &block) }
  end
end
