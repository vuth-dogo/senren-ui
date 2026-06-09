# 2026-05-21 22:05 — Open source GitHub baseline

## Goal

Set up the missing GitHub-side baseline for `senren-ui` so the repo is
safer to maintain as a first public Ruby gem and open source project.

## Changes made

- Added `.github/workflows/ci.yml` for:
  - `bundle exec rake test`
  - `bundle exec rubocop`
  - `bun run controllers:check`
- Added `.github/workflows/codeql.yml` for Ruby and JavaScript analysis.
- Added `.github/dependabot.yml` for Bundler, npm, and GitHub Actions.
- Added `.github/CODEOWNERS`.
- Added PR and issue intake templates under `.github/`.
- Added `CODE_OF_CONDUCT.md` and `SECURITY.md`.
- Updated `README.md` and `CONTRIBUTING.md` so contributor and security
  workflow matches the new baseline.
- Added `plans/017_open_source_github_baseline.md`.

## Commands run

```bash
bundle exec rake test
bundle exec rubocop
bun run controllers:check
```

## Results

- Repo now contains the missing version-controlled GitHub baseline.
- `bundle exec rake test` passed with 31 runs and 1139 assertions.
- `bundle exec rubocop --cache false` inspected 93 files with no
  offenses.
- `bun run controllers:check` passed syntax and Biome checks for 25
  controller files.
- Manual GitHub settings are still required for branch protection,
  rulesets, required checks, and release permissions.

## Decisions

- Kept release automation out of scope for now. This repo is not yet set
  up for automatic RubyGems publishing.
- Used Ruby `3.4` as the CI baseline instead of introducing a broader
  support matrix without prior compatibility proof.

## Next steps

1. Push these files to GitHub.
2. Enable branch protection on `main`.
3. Mark `CI / Ruby tests` and `CI / JavaScript checks` as required
   status checks once the workflows have run at least once.
4. Enable Dependabot security updates in repo settings.
