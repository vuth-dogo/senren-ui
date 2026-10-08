# frozen_string_literal: true

require 'test_helper'

# TopNavComponent's default variant was `bg-[hsl(var(--senren-background))/0.88]`.
# The `/0.88` sits inside the brackets, so it is not Tailwind's opacity
# modifier: Tailwind copies the bracket content into the declaration verbatim,
# `background-color: hsl(var(--senren-background))/0.88`, which is not a valid
# colour. The browser drops it and the sticky header has no background at all.
#
# Tailwind does not warn -- it is a valid arbitrary value that yields invalid
# CSS -- and no browser test here can see it, because the dummy app ships no
# Tailwind stylesheet (see focus_ring_room_test.rb). So the shape is banned at
# the source. The library's alpha syntax is inside the colour function:
# `bg-[hsl(var(--senren-background)/0.88)]`.
class ArbitraryValueAlphaTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  SOURCES = Dir[File.join(ROOT, '{templates,lib}/**/*.{rb,erb,tt}')]

  # A closing paren, then `/<number>`, then the closing bracket.
  ALPHA_OUTSIDE_FUNCTION = %r{[\w:-]+-\[[^\]\s"']*\)/[\d.]+\]}

  def offenders_in(text)
    text.scan(ALPHA_OUTSIDE_FUNCTION)
  end

  def test_the_rule_catches_the_broken_shape_and_passes_the_working_ones
    assert_equal ['bg-[hsl(var(--senren-background))/0.88]'],
                 offenders_in(%(class="sticky bg-[hsl(var(--senren-background))/0.88]"))
    assert_empty offenders_in(%(class="bg-[hsl(var(--senren-background)/0.88)]"))
    assert_empty offenders_in(%(class="bg-[hsl(var(--senren-background))]/88"))
    assert_empty offenders_in(%(class="hover:bg-[hsl(var(--senren-muted)/0.6)]"))
  end

  def test_there_are_sources_to_check
    refute_empty SOURCES
  end

  def test_no_arbitrary_value_puts_its_alpha_outside_the_colour_function
    offenders = SOURCES.flat_map do |path|
      offenders_in(File.read(path)).map { |match| "#{path.delete_prefix("#{ROOT}/")}: #{match}" }
    end

    assert_empty offenders, "alpha must go inside hsl(), e.g. bg-[hsl(var(--token)/0.88)]:\n#{offenders.join("\n")}"
  end
end
