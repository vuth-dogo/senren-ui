# Plan 011 — Release Checklist

## Purpose

Define the gate that determines whether Senren v0.1 can be tagged
and released.

## Scope

- v0.1 release of `senren-ui`.
- Documentation, packaging, and validation requirements.

## Decisions

1. v0.1 is **not** a stable API. SemVer-pre treatment: minor bumps
   may break things; patch bumps are bug fixes only.
2. v0.1 must satisfy section 29 of `master_prompt.md` in full.
3. Release artifacts: built `.gem` file plus a tagged git commit.
   No public RubyGems push for v0.1 (local path install only).
4. The `apps/todolist` app must boot, render the Todo index using
   Senren components, and pass its tests on a clean machine using
   only `bundle install` and `bin/rails db:setup`.

## Files to create / modify

- `CHANGELOG.md` — v0.1 entry with feature list.
- `README.md` — installation, usage, examples.
- `CONTRIBUTING.md` — dev workflow, planning/history rules.
- `LICENSE` — MIT.
- `senren-ui.gemspec` — version 0.1.0, summary, deps.
- `lib/senren/rails/version.rb` — `VERSION = "0.1.0"`.

## Expected behavior

Following the `bundle install` → `bin/rails db:setup` →
`bin/rails server` flow inside `apps/todolist` on a clean machine
results in a working Todo SaaS-style UI built on Senren.

## Test strategy

- Run the full release checklist from section 29 manually and
  document results in a final history file
  (`history/<timestamp>-v0.1-release-validation.md`).
- Run gem tests: `bundle exec rake test`.
- Run todolist tests: from `apps/todolist`, `bin/rails test` and
  `bin/rails test:system`.
- Smoke test in browser: load `/todos`, create, edit, delete a todo.

## Acceptance criteria — full checklist

- [ ] Gem installs.
- [ ] `senren:install` works.
- [ ] `senren:component` works (with and without `--client`).
- [ ] `senren:add` works.
- [ ] `senren:skill:sync` works.
- [ ] `senren:llms:generate` works.
- [ ] `senren:doctor` works.
- [ ] `.senren/skill.md` is centralized and grouped.
- [ ] `public/llms.txt` and `public/llms-full.txt` regenerate.
- [ ] Registry validation passes.
- [ ] Dummy app boots.
- [ ] `apps/todolist` boots and works end-to-end.
- [ ] Local path gem works in `apps/todolist`.
- [ ] Todo CRUD works with Senren UI.
- [ ] Tailwind renders.
- [ ] Stimulus controllers work.
- [ ] Turbo flows work.
- [ ] All tests pass.
- [ ] README, CHANGELOG, CONTRIBUTING, LICENSE present.
- [ ] Phase 1–3 components fully implemented.
- [ ] Phase 4–6 components scaffolded with stub markers.
- [ ] At least three SaaS demo pages exist in dummy app.
- [ ] Final release history file written.
