# frozen_string_literal: true

require 'test_helper'

module Senren
  # The palette presets are only useful if every one of them is complete.
  #
  # A theme is a re-declaration of the token set, and a missing variable does
  # not fail loudly — it silently falls back to whatever :root declared, so a
  # slate page renders one stray Spring Garden green and nobody notices until a
  # screenshot. These assertions are what make adding a seventh palette safe.
  class ThemesTest < Minitest::Test
    TOKENS_PATH = File.expand_path('../lib/generators/senren/install/templates/senren.css.tt', __dir__)
    THEMES_PATH = File.expand_path('../lib/generators/senren/install/templates/senren_themes.css.tt', __dir__)

    def setup
      @tokens = File.read(TOKENS_PATH)
      @themes = File.read(THEMES_PATH)
    end

    # The contract: whatever :root declares is what a theme must redeclare.
    def base_tokens
      root = @tokens[/:root\s*\{(.*?)\}/m, 1].to_s
      root.scan(/(--senren-[a-z-]+)\s*:/).flatten.uniq
    end

    # Anchored to the start of a line on purpose. Without the anchor this also
    # matched `.dark[data-senren-theme="X"]`, so the two blocks were grouped
    # together and a token missing from the light block was masked by the dark
    # one -- which is exactly the failure this file exists to catch. Found by
    # deleting a token and watching the suite stay green.
    def theme_blocks
      @themes.scan(/^\[data-senren-theme="([a-z]+)"\]\s*\{(.*?)\}/m).to_h
    end

    def dark_blocks
      @themes.scan(/\.dark\[data-senren-theme="([a-z]+)"\]\s*\{(.*?)\}/m).to_h
    end

    def test_the_base_declares_the_token_set_this_suite_checks_against
      assert_operator base_tokens.size, :>=, 25,
                      'expected senren.css to declare the full token set in :root'
    end

    def test_every_light_theme_declares_every_token
      missing = theme_blocks.filter_map do |name, body|
        gaps = base_tokens.reject { |t| body.include?("#{t}:") }
        "#{name}: #{gaps.join(', ')}" if gaps.any?
      end

      assert_empty missing, "themes missing tokens that :root declares:\n#{missing.join("\n")}"
    end

    # Dark blocks deliberately omit --senren-radius and the palette swatches:
    # a palette does not change shape or brand colour between light and dark.
    # Everything that carries contrast must be present.
    def test_every_dark_theme_redeclares_every_contrast_token
      contrast = base_tokens.grep_v(/radius|palette/)

      missing = dark_blocks.filter_map do |name, body|
        gaps = contrast.reject { |t| body.include?("#{t}:") }
        "#{name}: #{gaps.join(', ')}" if gaps.any?
      end

      assert_empty missing, "dark themes missing contrast tokens:\n#{missing.join("\n")}"
    end

    def test_every_theme_has_both_a_light_and_a_dark_block
      assert_equal theme_blocks.keys.sort, dark_blocks.keys.sort,
                   'a palette without a dark block silently inherits the default dark scheme'
    end

    # HSL channels, unwrapped, so Tailwind can compose them with opacity
    # modifiers. A stray hsl(...) or hex would render as nothing.
    def test_every_theme_value_is_a_bare_hsl_triplet
      bad = []
      # Iterated as pairs rather than merged: both hashes key on the palette
      # name, so merging silently dropped every light block from the check.
      (theme_blocks.to_a + dark_blocks.to_a).each do |name, body|
        body.scan(/(--senren-[a-z-]+)\s*:\s*([^;]+);/) do |token, value|
          next if token.include?('radius')
          next if value.strip.match?(/\A\d+(\.\d+)?\s+\d+(\.\d+)?%\s+\d+(\.\d+)?%\z/)

          bad << "#{name} #{token}: #{value.strip}"
        end
      end

      assert_empty bad, "values must be bare HSL channels:\n#{bad.join("\n")}"
    end

    def test_the_documented_palettes_are_all_present
      assert_equal %w[amber emerald indigo rose slate], theme_blocks.keys.sort
    end
  end
end
