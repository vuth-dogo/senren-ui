# 2026-04-29 21:12 — Rich Content components promoted

## Summary

- Promoted Carousel, Codeblock, Command, and RichTextEditorLite from
  stub registry entries to functional components.
- Added matching docs-site preview examples for all four Rich Content
  components.
- Added a registry regression test to keep these four entries promoted.
- Synced the app registry and regenerated `.senren/skill.md`,
  `llms.txt`, and `llms-full.txt`.

## Implementation notes

- `CodeblockComponent` renders optional filename/language/caption
  metadata and preserves source whitespace in `pre/code`.
- `CommandComponent` adds a small Stimulus-powered command list with
  query filtering, roving active state, enter selection, and an empty
  state.
- `CarouselComponent` adds accessible previous/next controls, dot
  navigation, keyboard navigation, and live status text.
- `RichTextEditorLiteComponent` uses a lightweight contenteditable
  editor with hidden textarea sync and a minimal toolbar for bold,
  italic, links, and lists.

## Verification

- `ruby -c` passed for all four Rich Content component classes in the
  gem templates and docs-site copies.
- `node --check` passed for the Carousel, Command, and
  RichTextEditorLite Stimulus controllers in both locations.
- Smoke checked `/components/carousel`, `/components/codeblock`,
  `/components/command`, and `/components/rich_text_editor_lite` on
  the docs server: all returned 200 with no fallback or stub text.
- `bin/rails tailwindcss:build`
- `bundle exec rake test` in `senren-rails`
- Registry check confirmed all four Rich Content entries have
  `stub: false` in both source and app registries.
