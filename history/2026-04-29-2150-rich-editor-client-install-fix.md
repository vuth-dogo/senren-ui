# 2026-04-29 21:50 — Rich editor and client install docs fix

## Summary

- Fixed RichTextEditorLite toolbar behavior for selected text, links,
  bulleted lists, and numbered lists.
- Updated component install docs so interactive components show
  `--client` explicitly and describe Stimulus as required.
- Kept static components on the no-client path in docs examples.

## Implementation notes

- Toolbar buttons now preserve the editor selection on pointer,
  mouse, and touch start before the click action runs.
- Link insertion uses an explicit DOM anchor transform with URL
  normalization instead of relying on fragile browser command state.
- Bulleted and numbered lists use explicit block-to-list DOM
  transforms and can unwrap or convert existing lists.
- The docs component page now renders client-aware install commands:
  `senren:add <name> --client` and
  `generate senren:component <name> --client` for interactive
  components.

## Verification

- Headless Chromium DOM smoke passed for RichTextEditorLite link,
  bulleted list, and numbered list behavior.
- `node --check` passed for the app and template RichTextEditorLite
  controllers.
- `bin/rails tailwindcss:build`
- `bundle exec rake test` in `senren-rails`
- Page smoke confirmed RichTextEditorLite renders `--client` commands
  and Button renders the static/no-client path.
