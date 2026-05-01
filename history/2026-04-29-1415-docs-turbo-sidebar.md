# 2026-04-29 14:15 - Docs sidebar Turbo navigation

## Summary

- Wrapped the docs layout body content in a `docs_content` Turbo frame.
- Targeted docs sidebar links at that frame with `data-turbo-action="advance"`
  so sidebar clicks update the content and URL without rebuilding the whole
  page shell.
- Added `site--docs-nav` Stimulus behavior to keep the active sidebar link and
  component group synchronized after clicks, frame loads, and browser history
  navigation.
- Updated site search navigation to use the docs Turbo frame when the current
  page has it.
- Moved sidebar active/inactive visual state into CSS so JavaScript only needs
  to toggle `is-active`.

## Verification

- `node --check apps/site/app/javascript/controllers/site/docs_nav_controller.js`
- `node --check apps/site/app/javascript/controllers/site/search_controller.js`
- `bin/rails tailwindcss:build` in `apps/site`
- Rails smoke for `/docs`, `/docs/installation`, `/components/button`, and
  `/components/data_table`:
  - `docs_turbo_pages=4 failures=0`
- Local HTTP check against `http://127.0.0.1:3124/components/button` confirmed
  `docs_content`, `site--docs-nav`, and sidebar `data-turbo-frame` attributes
  render on the live server.
