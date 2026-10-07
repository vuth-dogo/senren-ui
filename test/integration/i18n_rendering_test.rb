# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'view_component/test_case'
require 'nokogiri'
require_relative '../support/i18n_render_cases'
require_relative '../../scripts/i18n_catalog'
require_relative 'component_variants_test'

# What a host sees when it translates, as opposed to what the catalogue says it
# can: the markup a component renders under a locale, compared with the markup
# it renders without one.
#
# The property that matters most is the first one. Installing Senren must not
# require a locale file, and adding the shipped English file must change nothing,
# because the English lives in the component as the `default:` and the file is a
# copy of it. If those two ever disagree the library has two sources of truth.
class I18nRenderingTest < ViewComponent::TestCase
  LOCALES = File.expand_path('../../templates/locales', __dir__)
  REQUIRED_ARGS = ComponentVariantsTest::REQUIRED_ARGS
  NEEDS_BLOCK = ComponentVariantsTest::NEEDS_BLOCK

  # Rails emits a fresh CSRF token per request, so a rendered form never repeats.
  CSRF_TOKEN = /name="authenticity_token" value="[^"]*"/

  # What a Rails app does with `config.i18n.raise_on_missing_translations = true`.
  RAISING_HANDLER = lambda do |exception, *|
    raise(exception.is_a?(I18n::MissingTranslation) ? exception.to_exception : exception)
  end

  def registry
    @registry ||= Senren::Rails::Registry.load!
  end

  def teardown
    I18n.backend.reload!
    I18n.config.clear_available_locales_set
  end

  # --- Nothing installed, or only English ------------------------------------

  def test_the_shipped_english_file_changes_nothing
    without_file = render_everything
    with_file = with_locale_file(:en) { render_everything }

    assert_equal without_file.keys, with_file.keys
    changed = without_file.keys.reject { |label| without_file[label] == with_file[label] }

    assert_empty changed, "rendering with senren.en.yml differs from rendering with none: #{changed.join(', ')}"
    assert_operator without_file.size, :>=, registry.names.size + I18nRenderCases::CASES.size
  end

  def test_a_missing_translation_never_raises_even_when_the_app_raises_on_missing_translations
    original = I18n.exception_handler
    I18n.exception_handler = RAISING_HANDLER

    assert_raises(I18n::MissingTranslationData) { I18n.t('senren.nothing.here') }
    assert_operator render_everything.size, :>, 60, 'every component must still render with the raising handler on'
  ensure
    I18n.exception_handler = original
  end

  # --- A host translation ----------------------------------------------------

  def test_one_translated_key_changes_that_word_and_nothing_else
    html = with_translations(:en, senren: { pagination: { next: 'Sau' } }) do
      render_inline(Senren::PaginationComponent.new(current_page: 2, total_pages: 3, path: '/p/:page')).to_html
    end

    assert_includes html, '>Sau<'
    refute_includes html, '>Next<'
    assert_includes html, '>Previous<', 'a key the host did not translate keeps its English'
  end

  def test_a_caller_supplied_text_is_used_verbatim_and_never_looked_up
    html = with_translations(:en, senren: { pagination: { label: 'Translated' } }) do
      render_inline(Senren::PaginationComponent.new(label: 'Mine', total_pages: 2)).to_html
    end

    assert_includes html, 'aria-label="Mine"'
    refute_includes html, 'Translated'
  end

  # nil has always meant "no text here" for an attribute, and passing it must not
  # start meaning "use the default".
  def test_an_explicit_nil_still_means_none
    html = render_inline(Senren::FilterBarComponent.new(label: nil)).to_html

    refute_includes html, 'aria-label'
  end

  def test_an_empty_translation_blanks_the_word
    html = with_translations(:en, senren: { date_picker: { clear: '' } }) do
      render_inline(Senren::DatePickerComponent.new(name: 'day')).to_html
    end

    refute_includes html, 'Clear'
  end

  # --- The Vietnamese file ---------------------------------------------------

  def test_vietnamese_translates_what_a_component_shows
    html = with_locale_file(:vi) do
      render_inline(Senren::PaginationComponent.new(current_page: 2, total_pages: 3, path: '/p/:page')).to_html
    end

    assert_includes html, '>Trước<'
    assert_includes html, '>Sau<'
    assert_includes html, 'aria-label="Phân trang"'
    refute_includes html, 'Next'
  end

  def test_vietnamese_renders_every_component_and_changes_the_ones_that_have_text
    english = render_everything
    vietnamese = with_locale_file(:vi) { render_everything }

    refute(vietnamese.values.any? { |html| html.include?('translation missing') })
    labels = I18nRenderCases::CASES.each_with_index.map { |(name, _args), index| "#{name}##{index}" }
    unchanged = labels.select { |label| english.fetch(label) == vietnamese.fetch(label) }

    assert_empty unchanged, "these rendered the same in Vietnamese as in English: #{unchanged.join(', ')}"
  end

  def test_the_calendar_names_the_month_and_the_weekdays
    html = with_locale_file(:vi) do
      render_inline(Senren::CalendarComponent.new(date: Date.new(2026, 5, 1), name: 'day')).to_html
    end

    assert_includes html, 'Tháng 5 năm 2026'
    assert_includes html, '>CN<'
    assert_includes html, '>T7<'
  end

  # A value interpolated into a translation is text. The cart name here is
  # markup, and it has to arrive as the characters it is, not as an element.
  def test_a_value_is_filled_in_and_escaped
    item = { id: 'x', name: '<b>Mug</b>', price_cents: 100, quantity: 1 }
    html = with_locale_file(:vi) { render_inline(Senren::CartComponent.new(items: [item])).to_html }
    fragment = Nokogiri::HTML5.fragment(html)
    labels = fragment.css('button[data-action$="#decrement"]').map { |node| node['aria-label'] }

    assert_equal ['Giảm số lượng <b>Mug</b>'], labels
    assert_empty fragment.css('b'), 'a name containing markup must not become an element'
  end

  def test_option_values_a_form_submits_stay_in_english
    html = with_locale_file(:vi) { render_inline(Senren::InviteMemberDialogComponent.new).to_html }
    options = Nokogiri::HTML5.fragment(html).css('option').to_h { |option| [option['value'], option.text.strip] }

    assert_equal({ 'Member' => 'Thành viên', 'Admin' => 'Quản trị viên' }, options)
  end

  # --- The strings a controller shows ----------------------------------------

  def test_controller_strings_arrive_as_stimulus_values
    html = with_locale_file(:vi) do
      [
        render_inline(Senren::CarouselComponent.new(slides: %w[One Two])).to_html,
        render_inline(Senren::ThemeToggleComponent.new).to_html,
        render_inline(Senren::ClipboardComponent.new(value: 'x')).to_html,
        render_inline(Senren::ApiKeyFieldComponent.new(value: 'x')).to_html,
        render_inline(Senren::RichTextEditorLiteComponent.new).to_html
      ].join
    end

    assert_includes html, 'data-senren--carousel-status-template-value="Slide %{current} trên %{total}"'
    assert_includes html, 'data-senren--theme-toggle-light-label-value="Giao diện sáng"'
    assert_includes html, 'data-senren--theme-toggle-dark-label-value="Giao diện tối"'
    assert_includes html, 'data-senren--clipboard-copied-status-value="Đã sao chép vào bộ nhớ tạm"'
    assert_includes html, 'data-senren--api-key-field-copied-status-value="Sao chép xong"'
    assert_includes html, 'data-senren--rich-text-editor-lite-link-prompt-value="Dán một URL"'
  end

  def test_the_carousel_announces_its_first_slide_in_the_host_language
    html = with_locale_file(:vi) { render_inline(Senren::CarouselComponent.new(slides: %w[One Two])).to_html }

    assert_includes html, '>Slide 1 trên 2<'
  end

  # --- Every key is reachable ------------------------------------------------

  # Each value becomes a marker naming its own key. If a key appears in no
  # render, nothing a translator writes for it can ever show up.
  def test_every_key_in_the_catalogue_reaches_the_markup
    tree = YAML.safe_load_file(File.join(LOCALES, 'senren.en.yml')).fetch('en').fetch('senren')
    english = I18nCatalog.flatten(tree).to_h
    keys = english.keys
    # The variables are kept in the marker, or a sentence built from another key
    # (a count followed by the item label, a month inside a title) would hide it.
    marker = lambda do |key|
      variables = I18nCatalog.variables(english.fetch(key)).map { |name| "%{#{name}}" }
      ["⟦#{key}⟧", *variables].join(' ')
    end
    markers = { senren: nest(keys.to_h { |key| [key, marker.call(key)] }) }

    output = with_translations(:en, markers) { render_everything.values.join("\n") }
    unreachable = keys.reject { |key| output.include?("⟦#{key}⟧") }

    assert_empty unreachable, "keys no component renders: #{unreachable.join(', ')}"
  end

  private

  def render_everything
    pages = registry.names.to_h { |name| [name, render_case(name, REQUIRED_ARGS.fetch(name, {}))] }

    I18nRenderCases::CASES.each_with_index do |(name, args), index|
      pages["#{name}##{index}"] = render_case(name, REQUIRED_ARGS.fetch(name, {}).merge(args))
    end
    pages
  end

  def render_case(name, args)
    component = component_class(name).new(**args)

    html = if NEEDS_BLOCK.include?(name)
             render_inline(component) { 'content' }.to_html
           else
             render_inline(component).to_html
           end
    html.gsub(CSRF_TOKEN, 'name="authenticity_token" value="NORMALIZED"')
  end

  def component_class(name)
    Senren.const_get("#{name.split('_').map { |word| word[0].upcase + word[1..] }.join}Component")
  end

  def with_locale_file(locale, &)
    tree = YAML.safe_load_file(File.join(LOCALES, "senren.#{locale}.yml")).fetch(locale.to_s)
    with_translations(locale, tree, &)
  end

  def with_translations(locale, tree, &)
    enforce = I18n.enforce_available_locales
    I18n.enforce_available_locales = false
    I18n.backend.store_translations(locale, tree)
    I18n.with_locale(locale, &)
  ensure
    I18n.enforce_available_locales = enforce
  end

  def nest(flat)
    flat.each_with_object({}) do |(key, value), tree|
      *path, leaf = key.split('.').map(&:to_sym)
      path.reduce(tree) { |branch, part| branch[part] ||= {} }[leaf] = value
    end
  end
end
