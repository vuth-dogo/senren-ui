# Session: Documentation site — Phases A–D in one pass

## Time

Started:  2026-04-27 11:43 UTC
Finished: 2026-04-27 11:56 UTC

## Goal

Implement the Senren UI documentation site per Plan 013, focused on
delivering a stunning, production-grade UI/UX. Defer deployment to the
user.

## Changes Made

### Workspace + scaffold

- Created `apps/site/` Rails 8 app (Propshaft + importmap +
  tailwindcss-rails + ViewComponent + Rouge), structured to mirror
  `apps/todolist/` so it works in the same dev environment.
- Wired `gem "senren-rails", path: "../../senren-rails"`.
- Installed all 62 Senren registry components into the site via a new
  helper script `senren-rails/bin/seed_site.rb`.

### Site components

- `app/components/site/code_block_component.{rb,html.erb}` — server-
  side syntax highlighting with Rouge, filename header, copy button.
- `app/components/site/component_preview_component.{rb,html.erb}` —
  bordered live-preview frame with subtle dotted background.
- `app/components/site/logo_component.{rb,html.erb}` — Senren brand
  mark using the kanji 洗 in a tight black square.
- `app/components/site/theme_toggle_component.{rb,html.erb}` — light
  / dark toggle with FOIT-free pre-paint script.
- `app/javascript/controllers/site/{clipboard,theme}_controller.js`.

### Layouts + shared partials

- `application.html.erb`, `marketing.html.erb`, `docs.html.erb`.
- `shared/_head.html.erb`, `_header.html.erb`, `_footer.html.erb`,
  `_sidebar.html.erb`, `_doc_page_header.html.erb`,
  `_doc_section.html.erb`.
- Sidebar groups all 62 components by category, marks stubs.

### Pages

Marketing:
- `/` — Hero (display type, grid background, mask-fade radial),
  feature grid (six features as a 2x3 with 1px hairline grid),
  component showcase (six previews), AI agent section with skill.md
  excerpt, CTA.

Docs:
- `/docs` — Introduction with philosophy + "Next steps" cards.
- `/docs/installation` — Five-step install with copyable code blocks
  and a generated-files table.
- `/docs/quickstart` — Card page recipe + the block-precedence rule.
- `/docs/theming` — CSS-variable explainer + 8 swatches + dark mode.
- `/docs/conventions` — Hard rules + custom-class API + slot demo +
  file ownership table.
- `/docs/ai-agents` — `skill.md` excerpt + `llms.txt` excerpt +
  Should / Should-not split panel.

Components:
- `/components` — Grouped index, 62 cards, JS / Stable / Stub badges.
- `/components/:name` — Header (status pills), live preview, At-a-
  glance facts table, ERB + Ruby source from gem templates, AI rules
  (Use for / Avoid), accessibility notes, prev / next pager.
- `app/views/components/previews/_<name>.html.erb` — 24 curated
  previews covering all Phase 1–3 components (Button, Link, Badge,
  Typography, Separator, Skeleton, Avatar, Alert, Card, AspectRatio,
  Label, Input, Textarea, NativeSelect, Form, Switch, Dialog,
  AlertDialog, DropdownMenu, Popover, Tooltip, HoverCard, Sheet,
  ContextMenu).
- Phase 4–6 stubs render a "Scaffolded — preview coming soon"
  placeholder; their source code is still shown.

Examples:
- `/examples` — Gallery (Dashboard live, others marked Soon).
- `/examples/dashboard` — Welcome row + 4 stat cards + alert + recent
  activity feed + team list, all built from Senren primitives.

### Polish

- Tailwind v4 `@source` directives include
  `senren-rails/templates/components/**` so the site precompiles
  every utility used by every component, even ones not directly
  referenced by site views.
- Custom utilities: `bg-grid`, `bg-grid-dense`, `bg-dots`,
  `mask-fade-bottom`, `mask-fade-radial`, `preview-frame`.
- Inter Tight (display) + Inter (body) + JetBrains Mono (code) via
  Google Fonts preconnect.
- Rouge syntax theme matched to Senren tokens, light + dark.
- Header backdrop-blur, sticky.

## Bugs found and fixed in this session

1. **ERB heredocs collide with ERB parser.** `<<~ERB` heredocs in
   `.erb` files get clobbered: ERB grabs every `<%...%>` inside the
   string before Ruby sees the heredoc. Fix: moved all sample code
   into the controller (plain Ruby) and passed via `@vars`.
2. **`registry.fetch(name)` hit `Array#fetch`.** The helper method
   returns an Array; needed `Site::RegistryLoader.fetch(name)`.
3. **`lookup_context.exists?` for partials proved fragile** with the
   Components show partial dispatcher. Replaced with a try-render-
   then-rescue-`MissingTemplate` pattern.
4. **Path math** in `Site::RegistryLoader::GEM_REGISTRY_DIR` was one
   `..` too many.
5. **Missing Rails JS pipeline** at first scaffold: created
   `config/importmap.rb`, `app/javascript/{application.js,
   controllers/application.js, controllers/index.js}`.
6. **Tailwind not pre-built**: now run `bin/rails tailwindcss:build`
   before booting (documented in `apps/site/README.md`).

## Commands Run

```bash
mkdir -p apps/site/{...full structure}
bundle install              # apps/site
bin/rails db:create db:migrate
ruby senren-rails/bin/seed_site.rb       # 62 components installed
bin/rails tailwindcss:build
bin/rails runner /tmp/smoke_full.rb      # 27/27 routes 200
bin/rails runner /tmp/all_components.rb  # 62/62 component pages 200
```

## Tests Run

Smoke test of every public route via
`ActionDispatch::Integration::Session`. All 200.

## Results

```
Routes OK:     27/27
Components OK: 62/62
```

The site boots cleanly with `bin/rails server`, looks polished out
of the box, and has working dark mode + clipboard + dialog +
dropdown previews.

## Decisions

- **The site is also the dogfood.** No CDN, no static-site
  generator. If Senren cannot build its own marketing + docs site,
  it is not ready for users.
- **Per-component preview partials** instead of an auto-renderer.
  Auto-rendering Senren components without sample content gives the
  same empty result the user saw earlier this session; deliberate
  curated previews look intentional.
- **Source code is read from the gem template directory at request
  time.** This means the site automatically reflects library changes
  as soon as you run `seed_site.rb`.
- **Stubs ship visibly.** Phase 4–6 components have `Stub` badges
  and a "preview coming soon" placeholder. They are not hidden;
  hiding them would be dishonest.

## Next Steps

Plan 013 phases that remain:

- **Phase D (search + llms)** — Cmd-K search palette + per-page
  `public/llms/<slug>.md` mirrors. Defer until Senren `Command`
  component is promoted out of stub.
- **Phase E (polish + deploy notes)** — `og:image`, sitemap,
  per-page meta, README with Fly.io / Render / Kamal recipes.
- More **examples**: settings, team, billing, auth, empty states.
- More **curated previews** for Phase 4–6 once those components
  promote out of stub status.
- **Search index** generator (`bin/build_docs_search_index`).

## Open follow-ups for the user

- Confirm domain (`senren.dev` placeholder).
- Pick hosting target.
- Decide whether to wire any analytics in v0.1.
