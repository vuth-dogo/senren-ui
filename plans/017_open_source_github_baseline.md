# Plan 017 — Open Source GitHub Baseline

## Purpose

Add the minimum GitHub-side project files and workflows needed to make
`senren-ui` safer to maintain as a public Ruby gem and open source
repository.

## Scope

- Repository-level GitHub automation and policy files.
- Contributor and security guidance for first-time external users.
- CI coverage for Ruby tests, performance budgets, RuboCop, and JS
  controller checks.

## Decisions

1. Start with a narrow baseline instead of a full release pipeline:
   verify pull requests and `main`, but do not automate gem publishing
   yet.
2. Use repo-committed files for what can be versioned:
   workflows, Dependabot, CODEOWNERS, templates, code of conduct, and
   security policy.
3. Keep privileged repository controls outside the repo and document
   them separately: branch protection, rulesets, release permissions,
   and environment secrets still need manual GitHub setup.
4. Run CI on Ruby `3.4` as the maintained baseline while the gemspec
   declares `>= 3.2.0` to match ViewComponent 4.x.

## Files to create

- `.github/workflows/ci.yml`
- `.github/workflows/codeql.yml`
- `.github/dependabot.yml`
- `.github/CODEOWNERS`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`

## Files to modify

- `README.md`
- `CONTRIBUTING.md`

## Expected behavior

- Pull requests and pushes to `main` run the same core checks that
  maintainers run locally.
- Dependency and workflow updates can be proposed automatically.
- Contributors get structured issue and PR intake instead of ad-hoc
  free text.
- Security reports are routed privately instead of leaking in public
  issues.

## Test strategy

- Run `bundle exec rake test`.
- Run `bin/performance`.
- Run `bundle exec rubocop`.
- Run `bun run controllers:check`.
- Review workflow YAML for syntax and repo-path correctness.

## Acceptance criteria

- [x] CI workflow exists and reflects real repo commands.
- [x] CodeQL workflow exists for Ruby and JS.
- [x] Dependabot configuration exists for Bundler, npm, and GitHub Actions.
- [x] CODEOWNERS and PR/issue templates exist.
- [x] `CODE_OF_CONDUCT.md` and `SECURITY.md` exist.
- [x] Contributor docs explain the PR and security flow.
- [x] Local validation commands pass after the changes.
