# Plan 013 — Documentation & Landing Site

## Purpose

Ship the official Senren UI website. It must serve three audiences:

1. **Developers** evaluating Senren — landing page that explains what
   Senren is, why it exists, and how it differs from React-based UI
   libraries.
2. **Users actively building** — full component reference with live
   previews, copy-pasteable code, accessibility notes, AI agent rules.
3. **AI coding agents** — `llms.txt`, `llms-full.txt`, and per-page
   structured data so an agent can ground itself before writing code.

The site itself must be the **strongest possible dogfood**: built with
Senren components on a real Rails stack. If Senren cannot build its
own marketing + docs site, it is not ready for users.

## Scope

In scope (v0.1 of the site):

- Landing page (hero, value props, code sample, CTA, feature grid, footer)
- Docs section (installation, quickstart, theming, conventions, AI agents)
- Component reference (one page per Phase 1–3 component, scaffolded
  pages for Phase 4–6 stubs)
- Examples gallery (Dashboard, Settings, Team, Billing — reuses the
  recipes already in `registry/recipes.yml`)
- Recipes section (named multi-component patterns)
- Changelog page (rendered from `senren-rails/CHANGELOG.md`)
- Search via Senren `Command` palette (Phase 5 — fall back to client-
  side fuzzy search if `Command` is still scaffolded)
- Dark mode via Senren `ThemeToggle`
- Sidebar nav via Senren `Sidebar`
- Syntax-highlighted code blocks with a Senren `Clipboard` copy button

Out of scope for v0.1 of the site:

- Live in-browser editor / playground (defer to v0.2)
- Authentication or user accounts
- A package marketplace
- Comments / discussions (link to GitHub Discussions)
- Internationalization (English only for v0.1)

## Decisions

1. **Build inside the workspace as `apps/site`**, mirroring the
   `apps/todolist` pattern. Same Rails 8 + Propshaft + importmap +
   tailwindcss-rails + ViewComponent stack, same `gem "senren-ui",
   path: "../../senren-rails", require: "senren/rails"` install. This guarantees Senren is
   exercised the same way an end user would exercise it.
2. **Do not introduce a static-site generator** (Bridgetown / Jekyll /
   Astro). The thesis is "Rails is enough"; the site must prove it.
3. Component preview pages use a `Site::ComponentPreviewComponent`
   that renders both the live component and its source code side-by-
   side. The source code is read from the **gem template files**
   (`senren-rails/templates/components/<name>/<name>_component.html.erb`)
   at request time in development, and at build time in production.
4. Docs prose lives in `apps/site/app/views/docs/*.html.erb`. Markdown
   bodies live in `apps/site/app/content/docs/**/*.md` and are rendered
   via `Commonmarker` (already a transitive dep of `actiontext`); fall
   back to a tiny in-house renderer if Commonmarker is not available.
5. Each docs page is also rendered to `public/llms/<slug>.md` as plain
   markdown so AI agents can fetch a clean source view via HTTP.
6. The site reuses Senren's own design tokens. No bespoke CSS.
7. Production hosting is **Fly.io** (cheap, supports SQLite +
   Litestream, single-region is fine). Document the deploy in
   `apps/site/README.md` but do not deploy in this plan.
8. The site domain is `senren-ui.dev`. All links in `llms.txt` point
   to that domain.
9. Search v0.1: client-side index served as `public/search-index.json`,
   built by a `bin/build_search_index.rb` script that walks the docs
   tree and the registry. Senren `Command` UI consumes it.

## Files to create

### Rails app skeleton

```text
apps/site/
  Gemfile
  Gemfile.lock
  Rakefile
  config.ru
  bin/{rails,setup,seed}
  config/
    application.rb
    boot.rb
    database.yml
    environment.rb
    environments/{development,production,test}.rb
    initializers/{assets,filter_parameter_logging,inflections,
                  content_security_policy,cors}.rb
    routes.rb
    puma.rb
    importmap.rb
  db/
    seeds.rb
  app/
    assets/
      builds/.keep
      tailwind/application.css
      stylesheets/{application.css,senren.css,site.css}
    javascript/
      application.js
      controllers/{application.js,index.js,senren/.keep,site/.keep}
    components/
      senren/   # populated by `bin/rails senren:add ...`
      site/
        component_preview_component.{rb,html.erb}
        code_block_component.{rb,html.erb}
        nav_link_component.{rb,html.erb}
        marketing_hero_component.{rb,html.erb}
        feature_grid_component.{rb,html.erb}
        prop_table_component.{rb,html.erb}
    controllers/
      application_controller.rb
      home_controller.rb
      docs_controller.rb
      components_controller.rb
      examples_controller.rb
      recipes_controller.rb
      changelog_controller.rb
    views/
      layouts/{application,docs}.html.erb
      home/show.html.erb
      docs/{index,installation,quickstart,theming,conventions,
            ai_agents,llms_txt}.html.erb
      components/{index,show}.html.erb
      examples/{index,dashboard,settings,team,billing}.html.erb
      recipes/{index,show}.html.erb
      changelog/show.html.erb
    content/
      docs/**/*.md
  public/
    llms.txt
    llms-full.txt
    llms/<slug>.md       # one per docs page
    search-index.json
  test/
    integration/site_smoke_test.rb
    components/site/component_preview_component_test.rb
```

### Workspace plumbing

- `senren-rails/bin/site_dev` — convenience: `cd apps/site && bin/rails server`.
- `senren-rails/bin/build_docs_search_index` — generator for the
  `search-index.json` consumed by Senren `Command`.

## Files to modify

- `senren-rails/registry/recipes.yml` — add `marketing_hero`,
  `feature_grid`, `docs_layout`, `component_preview` recipes used
  by the site.
- `senren-rails/README.md` — link to `https://www.senren-ui.dev` once live.
- `senren-rails/CHANGELOG.md` — record v0.1.0 site launch.

## Expected behavior

- `cd apps/site && bin/rails server` boots the site at
  `http://localhost:3000`.
- `/` renders the landing hero + feature grid + code sample + CTA.
- `/docs/installation` renders the install steps with copy buttons
  on every code block.
- `/components` lists all 62 registry components grouped by category
  (Phase 1–3 fully documented, Phase 4–6 marked as `Stub`).
- `/components/dialog` renders a working live `Senren::DialogComponent`
  preview, the ERB source from the gem template, the props/slots
  table, accessibility notes, AI agent rules pulled from the registry.
- `/examples/dashboard` renders the dashboard recipe end-to-end.
- `public/llms.txt` and `public/llms-full.txt` exist and link to
  per-page markdown mirrors under `public/llms/*.md`.
- Dark mode toggle works via Senren `ThemeToggle`.
- Cmd/Ctrl-K opens the Senren `Command` palette and jumps between
  pages.

## Test strategy

- Smoke test: `bin/rails test test/integration/site_smoke_test.rb`
  asserts every top-level route returns 200 and contains the
  expected `data-senren-component` attribute, proving each page
  actually composes Senren primitives.
- Component preview test: assert that for at least one Phase 1–3
  component the preview page renders the source code AND a working
  live instance with the right `data-senren-component` attribute.
- llms.txt test: assert that `public/llms.txt` lists every published
  doc slug.

## Acceptance criteria

- [ ] `apps/site` boots with `bin/rails server` after a clean clone.
- [ ] Landing page renders without console errors.
- [ ] At least 10 component pages (Phase 1) render with live preview
      + source code + props table + AI agent rules.
- [ ] Phase 2 + Phase 3 component pages render at minimum: live
      preview + AI agent rules. Source code may be loaded lazily.
- [ ] At least one full example page (`/examples/dashboard`) renders.
- [ ] Dark mode toggle works.
- [ ] `Cmd/Ctrl-K` palette opens (or graceful fallback if Command
      component is still a stub).
- [ ] `public/llms.txt` and `public/llms-full.txt` exist and pass the
      llms.txt test.
- [ ] Smoke test green.
- [ ] History file recorded for the implementation session.

## Implementation phases

The site is built incrementally so the user can review and steer:

1. **Phase A — Skeleton** (~1 session)
   - Create `apps/site` with the same scaffold pattern used for
     `apps/todolist`. Wire local-path gem, Tailwind, importmap,
     Senren install + Phase 1 components.
   - Layouts + landing page only.
   - Acceptance: boots, landing page renders.

2. **Phase B — Docs prose** (~1 session)
   - Installation, quickstart, theming, conventions, ai_agents pages.
   - Markdown rendering pipeline.
   - Sidebar nav with `Senren::Sidebar` (or stub fallback).
   - Acceptance: `/docs/*` routes render, dark mode works.

3. **Phase C — Component reference** (~2 sessions)
   - `Site::ComponentPreviewComponent` reads gem templates.
   - Auto-generated index from `registry/components.yml`.
   - Per-component pages for Phase 1–3, stub pages for Phase 4–6.
   - Acceptance: every registry component has a page; Phase 1–3
     pages have a working live preview.

4. **Phase D — Examples + recipes + search + llms** (~1 session)
   - Dashboard / Settings / Team / Billing example pages.
   - Recipes index.
   - Search index + `Command`-driven palette.
   - `public/llms.txt`, `public/llms-full.txt`, `public/llms/*.md`.
   - Acceptance: smoke test green, llms test green.

5. **Phase E — Polish + deploy notes** (~0.5 session)
   - Footer, social cards (`og:image`), analytics hook (no real
     analytics in v0.1).
   - `apps/site/README.md` with Fly.io deploy instructions.
   - History entry.

Total: ~5–6 implementation sessions.

## Risks

- **Phase 4–6 stubs** may render visibly broken in component pages.
  Mitigation: site renders a clear `Stub` badge and links to the
  component's roadmap entry.
- **Live preview vs. asset pipeline** — Tailwind needs to scan the
  gem template files, which live outside `apps/site`. Mitigation: add
  the gem's `templates/components/**/*.html.erb` directory to the
  Tailwind `@source` list in `apps/site/app/assets/tailwind/application.css`.
- **Search index size** — full-text index of all docs + components
  can grow. Mitigation: cap to titles + headings + first paragraph in
  v0.1; full-text deferred to v0.2.
