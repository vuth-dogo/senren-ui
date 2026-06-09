# 2026-05-21 22:55 — Local preview workflow

## Goal

Make the local `.local/preview` preview app reproducible from this gem
checkout and document it as the lightweight visual smoke-test host.

## Changes made

- Updated docs to use `bin/seed_preview` instead of the older
  Ruby script path.
- Documented `.local/preview` as the git-ignored local preview host.
- Clarified that the full docs/reference app lives separately in
  `senren-ui-page`.
- Updated Plan 012 from the old `apps/todolist` workspace assumption to
  the current `.local/preview` workflow.
- Added `test/seed_preview_test.rb` to verify the seed script writes:
  routes, controller, preview view, Tailwind browser runtime, and
  `senren.css` import.
- Added `test/components/registry_component_contract_test.rb` to cover
  every registered component class, public registry options, root marker
  wiring, and client controller templates.
- Fixed `SwitchComponent` so its root label uses `root_attrs`.

## Commands run

```bash
bin/seed_preview
bin/test
bundle exec ruby -Itest test/components/registry_component_contract_test.rb
bundle exec ruby -Itest test/seed_preview_test.rb
bundle exec rubocop --cache false bin/seed_preview lib/generators/senren/install/templates/base_component.rb.tt
```

## Results

- Local preview at `.local/preview` renders the component preview route.
- Registry component contract test covers all registered components.
- `bin/test` passed.
- RuboCop passed for the touched seed/template files.

## Decisions

- Keep `.local/preview` as the local visual smoke-test app.
- Treat `senren-ui-page` as the real docs/reference app rather than
  maintaining a second docs host inside this checkout.
