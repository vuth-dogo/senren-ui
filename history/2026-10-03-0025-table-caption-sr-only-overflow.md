# 2026-10-03 00:25 - The Table Caption Was Positioned Against The Page

## Goal

Reported from an app with a fixed-height shell (`h-screen overflow-hidden`
root, `overflow-y-auto` `<main>`): on pages with a captioned table below the
fold, the window scrolled past the shell into a blank strip.

## The bug

`TableComponent` and `DataTableComponent` render `<caption class="sr-only">`
when given `caption:`. `sr-only` is `position: absolute`. Neither component,
nor the `overflow-x-auto` wrapper inside DataTable, is positioned, so the
caption's containing block is the nearest positioned ancestor on the page,
usually the initial containing block.

- An overflow clip only applies to descendants whose containing block is the
  clipping element or inside it, so the components' own `overflow-hidden`
  did not clip the caption.
- In a shell where `<main>` scrolls, the caption's static position is far
  below the viewport relative to the document, and the document grows by that
  much. Measured by the reporter with this DataTable template below 1500px of
  content, Tailwind v4.3.3, headless Chrome at 1280x970: document scroll
  height 1545px; 970px with `relative` added to the root.

The library's own AppShell lets the document scroll, which hides this: the
caption's static position is then inside the normal flow.

## Changes

- `table_component.html.erb`, `data_table_component.html.erb`: `relative` on
  the root, which already has `overflow-hidden`. The caption is now placed
  and clipped inside the component.
- `test/integration/caption_containing_block_test.rb`: renders both with a
  caption and asserts the CSS rule itself: the caption's nearest positioned
  ancestor is inside the component, at or below an element that clips
  overflow.
- `CHANGELOG.md`: Unreleased / Fixed.

Asserted on markup because the dummy app has no Tailwind stylesheet, so a
browser test there cannot see `relative` or `overflow-hidden` at all.

## Not changed, for a separate decision

A probe of every `.sr-only` in the kitchen sink found three more with no
positioned ancestor inside their component but an overflow container above
them: the sidebar's collapsed-label span (also inside AppShell), the command
palette's input label, and the rich text editor's label. They have the same
property; whether each one can actually leak depends on its layout, and none
was reported. Left for a follow-up rather than widened into this fix.

## Validation

- New test before the fix: 2 runs, 2 failures ("no positioned ancestor inside
  table", "... inside data_table").
- After the fix: 2 runs, 6 assertions, 0 failures.
- `bin/ci`: 8 of 9 gates pass (206 unit, 65 integration, 29 system runs, 0
  failures). The dependency audit fails on rubyzip 3.3.1 (CVE-2026-85396),
  the same failure as on `origin/main`, not touched here.
