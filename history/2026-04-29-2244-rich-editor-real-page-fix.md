# 2026-04-29 22:44 — Rich editor real-page controller fix

## Summary

- Fixed the real docs-page failure where RichTextEditorLite toolbar
  clicks did nothing because the Stimulus controller was not connected
  yet.
- Replaced the docs-site controller index loader with a DOM-priority
  loader that imports controllers currently present in `data-controller`
  attributes.
- Disabled RichTextEditorLite toolbar buttons until the controller
  connects, then re-enabled them from `connect`.

## Implementation notes

- The component was rendering correctly, but real-page browser
  verification showed `senren--rich-text-editor-lite` was absent from
  Stimulus modules when clicked too early.
- The new loader scans existing DOM, `DOMContentLoaded`, `turbo:load`,
  and added nodes, then imports `controllers/<identifier>_controller`
  only for controllers actually present on the page.
- Link/list editing still uses the explicit DOM transform introduced in
  the previous pass.

## Verification

- Real docs page browser check on
  `/components/rich_text_editor_lite`:
  - early state: toolbar button disabled before Stimulus is ready
  - ready state: controller connected and toolbar button enabled
  - selected text becomes `<a href="https://example.com">...`
  - selected paragraph becomes `<ul><li>...</li></ul>`
  - selected paragraph becomes `<ol><li>...</li></ol>`
- `node --check` passed for the docs controller index and
  RichTextEditorLite controllers.
- `bin/rails tailwindcss:build`
- `bundle exec rake test` in `senren-rails`

## Follow-up progress (2026-05-03)

- Work after this fix shifted to release hardening and docs-site
  metadata consistency.
- See `history/2026-05-03-2140-release-progress-catchup.md` for the
  v0.1.0 → v0.1.4 catch-up timeline.
