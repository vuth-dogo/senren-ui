# Contributing to Senren UI

Thanks for your interest. Senren is small and opinionated; please read
this file before opening a PR.

## Two non-negotiable rules

1. **Plans before code.** Architectural changes start with a new or
   updated file in `plans/` describing Purpose, Scope, Decisions, Files
   to create, Files to modify, Expected behavior, Test strategy, and
   Acceptance criteria.
2. **History after work.** Every meaningful implementation session ends
   with a new file in `history/YYYY-MM-DD-HHMM-<title>.md` recording
   goal, changes, commands run, results, decisions, and next steps.

## Local setup

```bash
git clone <repo>
cd senren-ui
bundle install
bun install
bin/ci             # every gate, reports all failures rather than the first
bin/ci --matrix    # additionally run the Rails 7.1-8.1 matrix (slow)
```

Individual gates, if you want to run one in isolation:

```bash
bin/test                              # unit tests (no Rails app booted)
bundle exec rake test:integration     # renders all 62 components via test/dummy
bin/system                            # headless browser tests
bin/performance                       # payload and runtime budgets
bin/matrix                            # unit tests on every supported Rails
bundle exec rubocop
bundle exec bundle-audit check --update
bun run controllers:check
bin/lint-fix                          # auto-fix RuboCop, ERB lint, controller JS
```

`bin/system` needs no setup: it uses a system Chrome and
`/usr/bin/chromedriver` when present, and otherwise lets Selenium Manager
fetch a matching driver.

Supported versions are proved, not asserted. `gemfiles/rails_*.gemfile` drive
the matrix via `BUNDLE_GEMFILE`, CI runs Ruby 3.2-3.4 × Rails 7.1-8.1 with
`fail-fast: false`, and `test/gem_packaging_test.rb` fails if the gemspec's
floors drift out of that matrix.

To exercise the gem against a local host app inside this repo:

```bash
cd /path/to/senren-ui
bin/seed_preview
cd .local/preview
bin/rails server
# optional custom path:
# SENREN_PREVIEW_ROOT=/abs/path/to/your/preview-app bin/seed_preview
```

While the server runs, start the watcher from the gem root in another
terminal so template edits appear without re-seeding:

```bash
bin/watch
```

It copies changed files from `templates/` and `registry/` into the preview
app and reloads the browser. See `docs/hot_reload.md` for what does and does
not reload.

The local preview uses Tailwind's browser runtime for convenience. The
real documentation/reference app is maintained separately in
`senren-ui-page`.

## What to forbid in PRs

- React, Vue, Alpine, lit, or any other JS framework dependency.
- Network calls from Stimulus controllers (Turbo handles server state).
- Hard-coded color utilities (`gray-*`, `slate-*`, etc.) in component
  templates — use semantic tokens (`bg-background`, `text-foreground`).
- New per-component markdown files for AI agents — Senren uses one
  centralized `.senren/skill.md`.

## Component checklist (Definition of Done)

- ViewComponent Ruby class under `Senren::` namespace.
- ERB template with `data-senren-component="<name>"` on root.
- Tailwind classes use semantic tokens only.
- Variants/sizes declared as class-level constants.
- Stimulus controller iff client behavior is needed
  (`app/javascript/controllers/senren/<name>_controller.js`).
- Component test in `test/components/`.
- System test in `test/system/` if interactive.
- Nothing extra is needed for render coverage: `test/integration/` renders
  every registered component in every declared variant and size, driven
  from the registry, so a new component is covered as soon as it has a
  preview in `ComponentPreviewHelper`.
- Registry entry in `registry/components.yml` (full schema).
- Skill block produced by `SkillWriter`.
- Demo usage in `.local/preview` if relevant to the local preview UI.

## Commit hygiene

- One logical change per commit.
- Mention the affected plan and history files in the commit body.
- Run `bin/ci` before pushing.
- Run `bin/ci --matrix` if you touched the gemspec, the Gemfile, or anything
  version sensitive.
- Run `bundle exec rake test` before pushing.
- Run `bin/system` before pushing if you touched component templates,
  Stimulus controllers, or the dummy preview app.
- Run `bundle exec rubocop` before pushing.
- Run `bin/performance` before pushing if you touched component
  templates, Stimulus controllers, or Importmap loading guidance.
- Run `bun run controllers:check` before pushing if you touched
  `templates/controllers/*.js`.

## Pull request workflow

1. Fork the repo and branch from `main`.
2. Keep each PR scoped to one logical change.
3. If the change is architectural, add or update a matching `plans/`
   entry first.
4. Before opening the PR, add or update the matching `history/` file.
5. Fill in the PR template with exact validation commands and results.

## Security workflow

- Do not report vulnerabilities in public issues.
- Use GitHub Security Advisories or the contact in `SECURITY.md`.
- Do not commit API keys, credentials, or private tokens, even in tests
  or screenshots.
- Do not pass untrusted URLs directly to component `href`/`src`
  attributes. Use the shared `safe_url` / `safe_media_url` helpers.
- Do not use `raw`, `html_safe`, `innerHTML =`,
  `insertAdjacentHTML`, `eval`, direct SQL APIs, or string-built SQL.
  The security tests intentionally fail on these escape hatches.
