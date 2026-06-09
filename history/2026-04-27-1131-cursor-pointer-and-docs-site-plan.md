# Session: Button cursor polish + Docs Site plan

## Time

Started:  2026-04-27 11:25 UTC
Finished: 2026-04-27 11:31 UTC

## Goal

1. Fix the missing `cursor: pointer` on the Senren `Button` component
   when used as the trigger inside `Senren::DialogComponent` (and
   anywhere else a `<button>` element is rendered).
2. Decide and document the next major milestone: the Senren
   documentation + landing site.

## Changes Made

### Button cursor polish (library level)

- `senren-rails/templates/components/button/button_component.html.erb`
  — added `cursor-pointer` to the base classes and
  `disabled:cursor-not-allowed` so disabled buttons show the correct
  affordance. Native `<button>` elements default to the arrow cursor
  in most browsers; this restores expected web UI behavior. Anchors
  rendered with `as: :a` already inherit pointer from `href`, so the
  fix is harmless there.
- Re-ran `senren-rails/bin/seed_preview` to refresh the installed
  copy in `apps/todolist`. The seed now uses `force: true` so library
  updates propagate cleanly.

### Documentation & landing site plan

- New plan file: `senren-rails/plans/013_documentation_site.md`.
  Decisions of note:
  1. Build the site as **`apps/site`**, mirroring the
     `apps/todolist` workspace pattern. No static-site generator —
     the site itself dogfoods Senren.
  2. Component preview pages render the **live component** plus the
     **gem template source** read from
     `senren-rails/templates/components/<name>/`.
  3. Per-page markdown mirrors served at `public/llms/<slug>.md` so
     AI agents can fetch a clean source view via HTTP.
  4. Search v0.1 = client-side `search-index.json` consumed by
     Senren `Command` palette.
  5. Phased implementation: Skeleton → Docs prose → Component
     reference → Examples + search + llms → Polish + deploy notes.

## Commands Run

```bash
ruby /home/vudogo/senren/senren-rails/bin/seed_preview
bin/rails test               # in apps/todolist
bin/rails runner /tmp/check_imports.rb  # smoke check
```

## Tests Run

```bash
cd apps/todolist
bin/rails test
# 12 runs, 54 assertions, 0 failures, 0 errors, 0 skips
```

## Results

- Buttons now show `cursor: pointer` on hover everywhere they appear,
  including the dialog trigger in `apps/todolist/app/views/todos/index.html.erb`.
- Plan 013 is committed and ready to drive the next 5–6 sessions.

## Decisions

- **Documentation site lives in `apps/site`**, not as a static
  generator. The Senren thesis is "Rails is enough"; the site must
  prove it.
- **No external editor library** for code blocks. Use a Senren
  `Codeblock` component (Phase 5 — currently scaffolded; promote
  to fully implemented during Phase C of the docs site build).
- **Search via Senren `Command`** (Phase 5). If the `Command` stub
  has not been promoted by the time we hit Phase D of the docs
  build, ship a minimal client-side fuzzy search as a temporary
  fallback and create a follow-up history entry to upgrade later.
- **Domain placeholder**: `senren.dev`. Confirm with user before
  v0.1 launch.

## Next Steps

In priority order:

1. (User confirmation) approve Plan 013 and the `senren.dev`
   domain placeholder.
2. Execute Phase A of Plan 013: scaffold `apps/site` (Rails 8 +
   Propshaft + importmap + tailwindcss-rails + ViewComponent +
   `gem "senren-rails", path: "../../senren-rails"`), wire Senren
   install + Phase 1 components, build the layout + landing page.
3. Phase B: docs prose pages (installation, quickstart, theming,
   conventions, AI agents).
4. Phase C: component reference pages with live preview + source.
5. Phase D: examples, recipes, search, llms.txt.
6. Phase E: polish + Fly.io deploy notes.

## Open questions for the user

- Domain confirmation (`senren.dev` or another).
- Should the site host a public **playground** in v0.2 (not v0.1)?
  Plan 013 currently defers this.
- Analytics: skip in v0.1, or wire Plausible / Fathom from day one?
- Hosting target: Fly.io is assumed in Plan 013; user may prefer
  Render, Hatchbox, or Kamal-on-VPS.
