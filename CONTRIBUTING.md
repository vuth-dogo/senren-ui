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
cd senren-rails
bundle install
bun install
bundle exec rake test
bun run controllers:check
```

To exercise the gem against a real Rails app, use the bundled workspace:

```bash
cd ../apps/todolist
bundle install
bin/rails db:setup
bin/rails generate senren:install
bin/rails senren:add button card badge alert
bin/rails server
```

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
- Demo usage in `apps/todolist` if relevant to the Todo UI.

## Commit hygiene

- One logical change per commit.
- Mention the affected plan and history files in the commit body.
- Run `bundle exec rake test` before pushing.
- Run `bun run controllers:check` before pushing if you touched
  `templates/controllers/*.js`.
