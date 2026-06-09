# Plan 011 — Release Checklist

## Purpose

Define the gate that determines whether Senren v0.1 can be tagged
and released.

## Scope

- v0.1 release of `senren-ui`.
- Documentation, packaging, and validation requirements.

## Progress update (2026-05-03)

- Release gate has been executed and moved to maintenance mode.
- Tagged/releases recorded in git and changelog:
  - `80221a9` (v0.1.0 release snapshot)
  - `db8ea3c` + `82862fe` (v0.1.1 prep + lockfile sync)
  - `1c56a30` (v0.1.2 progress visual fix)
  - `b7af64a` (v0.1.3)
  - `77bc014` (v0.1.4 metadata link correction)
- Post-release implementation history is tracked in
  `history/2026-05-03-2140-release-progress-catchup.md`.

## Maintenance update (2026-05-21)

- The old tracked workspace assumption has been replaced by a
  git-ignored local preview host at `.local/preview`.
- `bin/seed_preview` creates or refreshes that local host and writes a
  root component preview route.
- The full documentation/reference app is maintained separately as
  `senren-ui-page`.

## Decisions

1. v0.1 is **not** a stable API. SemVer-pre treatment: minor bumps
   may break things; patch bumps are bug fixes only.
2. v0.1 must satisfy section 29 of `master_prompt.md` in full.
3. Release artifacts: built `.gem` file plus a tagged git commit.
   No public RubyGems push for v0.1 (local path install only).
4. The local `.local/preview` preview host must be reproducible with
   `bin/seed_preview` and render Senren components with Tailwind
   styling.

## Files to create / modify

- `CHANGELOG.md` — v0.1 entry with feature list.
- `README.md` — installation, usage, examples.
- `CONTRIBUTING.md` — dev workflow, planning/history rules.
- `LICENSE` — MIT.
- `senren-ui.gemspec` — version 0.1.0, summary, deps.
- `lib/senren/rails/version.rb` — `VERSION = "0.1.0"`.

## Expected behavior

Following `bundle install` → `bin/seed_preview` → `cd .local/preview`
→ `bin/rails server` results in a local Senren component preview.

## Test strategy

- Run the full release checklist from section 29 manually and
  document results in a final history file
  (`history/<timestamp>-v0.1-release-validation.md`).
- Run gem tests: `bundle exec rake test`.
- Run `test/seed_preview_test.rb` to confirm the local preview host
  files are generated.
- Smoke test in browser: load `/` in `.local/preview`.

## Acceptance criteria — full checklist

- [x] Gem installs.
- [x] `senren:install` works.
- [x] `senren:component` works (with and without `--client`).
- [x] `senren:add` works.
- [x] `senren:skill:sync` works.
- [x] `senren:agents:sync` works.
- [x] `senren:doctor` works.
- [x] `.senren/skill.md` is centralized and grouped.
- [x] `.senren/agent-rules.md` and adapter files regenerate.
- [x] Registry validation passes.
- [x] Dummy app boots.
- [x] `.local/preview` preview host is reproducible.
- [x] Local path gem works in `.local/preview`.
- [x] Local preview renders Senren UI components.
- [x] Tailwind renders.
- [x] Stimulus controllers work.
- [x] Turbo flows work.
- [x] All tests pass.
- [x] README, CHANGELOG, CONTRIBUTING, LICENSE present.
- [x] Phase 1–3 components fully implemented.
- [x] Phase 4–6 components scaffolded with stub markers.
- [x] At least three SaaS demo pages exist in dummy app.
- [x] Final release history file written.
