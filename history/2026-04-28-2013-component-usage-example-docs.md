# Session: Component usage example docs

## Time

Started: 2026-04-28 20:10 UTC+07:00
Finished: 2026-04-28 20:13 UTC+07:00

## Goal

Add practical copyable usage examples to every component documentation page in
`apps/site`.

## Changes Made

- Updated `Site::RegistryLoader` with `read_preview_source(component)` so the
  docs site can load the curated preview ERB source for each component.
- Updated `ComponentsController#show` to expose `@usage_src`.
- Added a `Usage example` section to
  `apps/site/app/views/components/show.html.erb`.
- The usage section renders a copyable ERB code block using the same partial
  source as the live preview, keeping examples accurate for components with
  slots, required arguments, or Stimulus behavior.

## Commands Run

```bash
cd apps/site
bin/rails runner '<all 62 component pages assert usage section and add command>'
```

## Tests Run

```bash
bin/rails runner '<all 62 component pages assert usage section and add command>'
# component_pages=62 failures=0
```

## Results

All 62 component pages now render successfully and include:

- Live preview.
- Copyable usage example.
- `bin/rails senren:add <component>` install command.
- Custom component generator command.

No page contains the old live-preview fallback text.

## Decisions

- Reused curated preview partial source as the usage example instead of
  generating generic snippets. Generic snippets would be wrong for components
  with required arguments or slots.

## Next Steps

- Consider adding per-component hand-written "common recipes" later for complex
  components like Dialog, DataTable, Command, and RichTextEditorLite.
