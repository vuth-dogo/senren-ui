# frozen_string_literal: true

require 'test_helper'

# A focus ring is drawn outside a control's border box, so a scroll container
# has to leave room for it. The sheet's body did not: a focused input flush
# against the edge had its ring shaved off on both sides, which reads as a
# broken border rather than as a clipped ring.
#
# Asserted on markup rather than on rendered geometry, deliberately. The dummy
# app ships no stylesheet at all, so Tailwind utilities have no effect there --
# the first version of this was a system test that measured the gap in a
# browser, found `overflow: visible` because `overflow-auto` never applied, and
# passed just as happily with the fix removed. Anything in this repo that
# asserts on visual geometry has the same problem.
class FocusRingRoomTest < Minitest::Test
  TEMPLATES = Dir[File.expand_path('../templates/components/*/*_component.html.erb', __dir__)]
  RING_ROOM = /-mx-(\d+)/
  RING_PAD  = /(?:\s|")px-(\d+)/

  # Tailwind's scale is 0.25rem per unit; a 2px ring needs at least one.
  MIN_UNITS = 1

  def scrolling_containers
    TEMPLATES.flat_map do |path|
      File.read(path).scan(/class="([^"]*overflow-(?:auto|scroll|y-auto)[^"]*)"/).flatten
          .map { |classes| [File.basename(path), classes] }
    end
  end

  def test_the_library_still_has_scrolling_containers_to_check
    refute_empty scrolling_containers, 'expected at least one scrolling container to assert about'
  end

  # Only containers that can hold a focusable control need the room. The
  # combobox and command lists hold options rendered by the component itself,
  # which sit inside their own padding.
  def test_the_sheet_body_leaves_room_for_a_focus_ring
    _, classes = scrolling_containers.find { |file, _| file.start_with?('sheet') }

    refute_nil classes, 'expected the sheet to have a scrolling body'

    pad = classes[RING_PAD, 1]&.to_i
    refute_nil pad, "sheet body has no horizontal padding to hold a ring: #{classes}"
    assert_operator pad, :>=, MIN_UNITS, "sheet body padding of #{pad} is too small for a focus ring"
  end

  # The room is bought with a negative margin cancelling the padding, so it
  # costs no layout. Padding without the margin would indent the content.
  def test_that_room_is_cancelled_by_a_matching_negative_margin
    _, classes = scrolling_containers.find { |file, _| file.start_with?('sheet') }
    pad = classes[RING_PAD, 1]&.to_i
    margin = classes[RING_ROOM, 1]&.to_i

    refute_nil margin, "sheet body pads by #{pad} without a matching -mx, which indents its content: #{classes}"
    assert_equal pad, margin, 'the negative margin must cancel the padding exactly'
  end
end
