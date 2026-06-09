# Plan 012 — Workspace and Preview App

## Purpose

Define the local `.local/preview` Rails preview host that acts as the
day-to-day visual smoke test for Senren components in this checkout.

## Scope

- The git-ignored `.local/preview` host app.
- Local-path gem wiring.
- The generated preview route and component render surface.

## Decisions

1. `.local/preview` is intentionally ignored by git and can be
   recreated with `bin/seed_preview`.
2. The local host app uses the gem via local path:

   ```ruby
   # .local/preview/Gemfile
   gem "senren-ui", path: "../..", require: "senren/rails"
   ```

3. The local preview route is `root "components#index"`.
4. The preview page renders the full registered component set through a
   kitchen-sink preview helper.
5. The preview host imports `senren.css` and uses Tailwind's browser
   runtime for local visual checks. Production/docs builds should use a
   real Tailwind build pipeline.
6. The full documentation/reference app is maintained separately as
   `senren-ui-page`, not as `apps/site` inside this checkout.

## Files to create

```
bin/seed_preview
test/seed_preview_test.rb
.local/preview/Gemfile          # generated, ignored by git
.local/preview/config/routes.rb # generated, ignored by git
.local/preview/app/views/components/index.html.erb # generated, ignored by git
```

## Files to modify

- `README.md` and `CONTRIBUTING.md` for the local preview workflow.
- History files whenever the local preview workflow changes.

## Expected behavior

- From a clean checkout, the following sequence creates a local preview:

  ```bash
  bundle install
  bin/seed_preview
  cd .local/preview
  bundle install
  bin/rails server
  ```

- Visiting `/` shows the Senren component preview with Tailwind styles.

## Test strategy

- `test/seed_preview_test.rb` runs `bin/seed_preview` against a temp
  host skeleton and asserts routes, preview view, Tailwind runtime, and
  `senren.css` import are written.
- `bin/test` runs the seed test as part of the full gem test suite.

## Acceptance criteria

- [x] `.local/preview` is ignored by git.
- [x] `bin/seed_preview` can create or refresh the local preview host.
- [x] Preview route renders the full registered component set.
- [x] Preview host loads `senren.css` and Tailwind browser runtime.
- [x] Tests cover the seed script output.
