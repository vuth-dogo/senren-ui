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
bundle exec rake test
bin/system
bin/performance
bundle exec rubocop
bun run controllers:check
```

To exercise the gem against a local host app inside this repo:

```bash
cd /path/to/senren-ui
bin/seed_preview
cd .local/preview
bin/rails server
# optional custom path:
# SENREN_PREVIEW_ROOT=/abs/path/to/your/preview-app bin/seed_preview
```

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
- Registry entry in `registry/components.yml` (full schema).
- Skill block produced by `SkillWriter`.
- Demo usage in `.local/preview` if relevant to the local preview UI.

## Commit hygiene

- One logical change per commit.
- Mention the affected plan and history files in the commit body.
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
