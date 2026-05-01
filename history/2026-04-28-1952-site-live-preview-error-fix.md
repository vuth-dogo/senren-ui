# Session: Site live preview error fix

## Time

Started: 2026-04-28 19:45 UTC+07:00
Finished: 2026-04-28 19:52 UTC+07:00

## Goal

Fix `apps/site` component pages that still showed the live-preview fallback or
raised preview errors in development.

## Changes Made

- Fixed `apps/site/app/views/components/show.html.erb` to render preview
  partials from the correct path:
  `components/previews/<component>`.
- Added missing preview partials for all remaining registry components, so all
  62 component pages have live preview content.
- Updated stale preview calls:
  - `AspectRatioComponent` uses `variant: :video`.
  - `LabelComponent` no longer uses unsupported `variant: :optional`.
  - `FormComponent` uses `model: false, url: "#"` instead of unsupported
    `action:`.
  - DropdownMenu and ContextMenu previews no longer call missing
    `with_separator`.
  - Popover and HoverCard previews use `with_content_panel`.
  - Tooltip preview uses `text:`.
- Fixed `SelectComponent` and `MaskedInputComponent` in both gem templates and
  the installed `apps/site` copy. They no longer define `#call` while also
  shipping a sidecar template, and the templates now reference
  `Senren::NativeSelectComponent` / `Senren::InputComponent` explicitly.

## Commands Run

```bash
bin/rails runner '<all 62 component pages smoke>' # in apps/site
bin/rails tailwindcss:build                       # in apps/site
ruby -Itest -Ilib test/registry/template_files_test.rb # in senren-rails
```

## Tests Run

```bash
cd apps/site
bin/rails runner '<all 62 component pages smoke>'
# component_pages=62 failures=0 fallback=0

bin/rails tailwindcss:build
# Done in 173ms

cd ../../senren-rails
ruby -Itest -Ilib test/registry/template_files_test.rb
# 3 runs, 151 assertions, 0 failures, 0 errors, 0 skips
```

## Results

All component pages in `apps/site` now return HTTP 200 and none contains the
fallback text:

```txt
Live preview coming soon
View the source below to see the component implementation.
```

## Decisions

- Fixed the previews directly instead of restoring the broad fallback. Preview
  errors should fail loudly during development so component API drift is caught.
- Left SaaS and Rich Content component implementations as stubs, but their site
  pages now have explicit preview content instead of the generic fallback.

## Next Steps

- Add a permanent integration test for `apps/site` that asserts all component
  pages return 200 and do not include the fallback text.
