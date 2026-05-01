# 2026-04-29 14:35 - Dropdown chevron state polish

## Summary

- Updated Combobox to render a real SVG chevron instead of a static `v`
  glyph.
- Combobox now toggles `data-state="open|closed"` on its button and chevron,
  so `data-[state=open]:rotate-180` rotates the arrow while the panel is open.
- DropdownMenu now exposes `data-state="open|closed"` on the root, trigger,
  nested trigger control, and any trigger child marked with
  `data-senren-chevron`.
- Link-style DropdownMenu items now close the menu on click, matching button
  menu items.
- Updated the dropdown docs preview to include a rotating chevron.
- Added a native-select wrapper with an overlay chevron that rotates on
  focus/click while preserving the real `<select>` for form semantics.
- Updated the docs live preview wrapper to allow visible overflow, so absolute
  dropdown/combobox panels are not clipped by the preview frame.

## Verification

- `node --check` for DropdownMenu and Combobox controllers in both the gem
  templates and docs site copies.
- Ruby syntax checks for DropdownMenu, Combobox, and NativeSelect component
  classes in both the gem templates and docs site copies.
- `bin/rails tailwindcss:build` in `apps/site`
- `bundle exec rake test` in `senren-rails`
  - `15 runs, 1049 assertions, 0 failures, 0 errors, 0 skips`
- Rails smoke for `/components/dropdown_menu`, `/components/combobox`,
  `/components/select`, and `/components/native_select`
  - `interactive_dropdown_pages=4 failures=0`
- Rails smoke for dropdown-like previews confirmed the live preview wrapper no
  longer clips open panels:
  - `preview_overflow_pages=3 failures=0`
