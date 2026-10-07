# frozen_string_literal: true

require_relative '../application_system_test_case'

# The five controllers that write a sentence into the page after it loads.
#
# They used to hard-code it ("Copied", "Slide 2 of 3", "Light theme", a
# `window.prompt`), so no translation of the markup could reach them. They now
# read the sentence from a Stimulus value the server filled in. Rendering the
# value is tested elsewhere; this proves each controller *reads* it - that the
# value name in the markup, the declaration in the controller and the lookup
# agree - which only a browser can show.
#
# Run twice, in English and in Vietnamese. The English pass matters as much: it
# is what an app with no locale file gets, and it has to say what it always did.
class I18nSystemTest < ApplicationSystemTestCase
  CONTROLLERS = %w[
    senren--api-key-field senren--carousel senren--clipboard senren--rich-text-editor-lite senren--theme-toggle
  ].freeze

  ENGLISH = {
    query: '',
    carousel_next: 'Next slide', carousel_status: 'Slide 2 of 2',
    theme_in_light_mode: 'Dark theme', theme_in_dark_mode: 'Light theme',
    clipboard_label: 'Copied', clipboard_status: 'Copied to clipboard',
    hide: 'Hide', copy: 'Copy', api_key_status: 'Copy complete',
    link_button: 'Create link', link_prompt: 'Paste a URL'
  }.freeze

  VIETNAMESE = {
    query: '?locale=vi',
    carousel_next: 'Slide sau', carousel_status: 'Slide 2 trên 2',
    theme_in_light_mode: 'Giao diện tối', theme_in_dark_mode: 'Giao diện sáng',
    clipboard_label: 'Đã sao chép', clipboard_status: 'Đã sao chép vào bộ nhớ tạm',
    hide: 'Ẩn', copy: 'Sao chép', api_key_status: 'Sao chép xong',
    link_button: 'Tạo liên kết', link_prompt: 'Dán một URL'
  }.freeze

  test 'the controllers say their sentences in English when nothing is translated' do
    open_kitchen_sink ENGLISH

    assert_carousel ENGLISH
    assert_theme_toggle ENGLISH
    assert_clipboard ENGLISH
    assert_api_key_field ENGLISH
    assert_link_prompt ENGLISH
  end

  test 'the controllers say their sentences in the language the server rendered' do
    open_kitchen_sink VIETNAMESE

    assert_carousel VIETNAMESE
    assert_theme_toggle VIETNAMESE
    assert_clipboard VIETNAMESE
    assert_api_key_field VIETNAMESE
    assert_link_prompt VIETNAMESE
  end

  private

  def open_kitchen_sink(words)
    visit "/components/kitchen_sink#{words.fetch(:query)}"

    assert_text 'Senren Kitchen Sink'
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until (CONTROLLERS - loaded_senren_controllers).empty?
    end
  end

  def preview(name, &)
    within(%(section[data-preview-component="#{name}"]), &)
  end

  def assert_carousel(words)
    preview('carousel') do
      find(%(button[aria-label="#{words.fetch(:carousel_next)}"])).click

      assert_selector '[data-senren--carousel-target="status"]', text: words.fetch(:carousel_status), visible: :all
    end
  end

  # Light mode shows the theme a click switches *to*, so the label says "Dark"
  # first. The class and the stored preference are put back afterwards, or the
  # next test would start in the dark.
  #
  # The controller is called rather than clicked. This button carries its own
  # data-action on the controller element, which real Stimulus binds and the
  # preview app's stimulus_lite does not (it only looks at descendants), so a
  # click here would do nothing in the harness whatever the controller does.
  def assert_theme_toggle(words)
    preview('theme_toggle') do
      assert_selector '[data-senren--theme-toggle-target="label"]', text: words.fetch(:theme_in_light_mode)

      page.execute_script(
        'document.querySelector(\'[data-controller="senren--theme-toggle"]\')' \
        '.__senrenControllers["senren--theme-toggle"].toggle()'
      )

      assert_selector '[data-senren--theme-toggle-target="label"]', text: words.fetch(:theme_in_dark_mode)
    end
  ensure
    page.execute_script('localStorage.removeItem("senren-theme"); document.documentElement.classList.remove("dark")')
  end

  def assert_clipboard(words)
    stub_clipboard
    preview('clipboard') do
      find('[data-senren--clipboard-target="button"]').click

      assert_selector '[data-senren--clipboard-target="button"]', text: words.fetch(:clipboard_label)
      assert_selector '[data-senren--clipboard-target="status"]', text: words.fetch(:clipboard_status), visible: :all
    end
  end

  def assert_api_key_field(words)
    stub_clipboard
    preview('api_key_field') do
      find('[data-senren--api-key-field-target="revealButton"]').click

      assert_selector '[data-senren--api-key-field-target="revealButton"]', text: words.fetch(:hide)

      find('button', text: words.fetch(:copy), exact_text: true).click

      assert_selector '[data-senren--api-key-field-target="status"]', text: words.fetch(:api_key_status), visible: :all
    end
  end

  def assert_link_prompt(words)
    page.execute_script(
      'window.__senrenPrompt = null; ' \
      'window.prompt = (message) => { window.__senrenPrompt = message; return null }'
    )
    preview('rich_text_editor_lite') do
      find(%(button[aria-label="#{words.fetch(:link_button)}"])).click
    end

    assert_equal words.fetch(:link_prompt), page.evaluate_script('window.__senrenPrompt')
  end

  # Copying needs a permission a headless browser has not been granted. The
  # controller's job here is to announce the result, which is what is under test.
  def stub_clipboard
    page.execute_script(
      "Object.defineProperty(navigator, 'clipboard', { value: { writeText: async () => {} }, configurable: true })"
    )
  end
end
