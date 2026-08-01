# 2026-07-30 23:24 - Dependency Audit Gate

## Goal

Close the dependency-vulnerability gap flagged independently by the red-team
review, the runtime research pass, and the `jet_ui` comparison (plans 019, 021,
022). Dependabot was opening PRs but nothing failed a build, so a known CVE
could sit in the lockfile indefinitely.

## Changes

- Added `bundler-audit` to the `development, test` group.
- Added an audit step to `.github/workflows/ci.yml` and to `bin/ci`, so the
  build fails on a known advisory rather than relying on someone reading a
  Dependabot PR.

## Vulnerabilities found and fixed

The gate paid for itself on first run — five advisories were live in the
lockfile:

| Gem | Was | Now | Advisory |
|---|---|---|---|
| websocket-driver | 0.8.0 | 0.8.2 | CVE-2026-54465 memory exhaustion in header parser |
| websocket-driver | 0.8.0 | 0.8.2 | CVE-2026-61666 **High** — DoS via malformed Host header |
| view_component | 4.11.0 | 4.12.0 | CVE-2026-54498 **High** — `around_render` HTML-safety bypass |
| net-imap | 0.6.4 | 0.6.6 | CVE-2026-47242 command injection via ID argument |
| rails / activestorage | 8.1.3 | 8.1.3.1 | CVE-2026-66066 arbitrary file read / RCE in variant processing |

`bundle-audit check --update` now reports no vulnerabilities.

The `view_component` one is notable: it is exactly what Dependabot PR #7
proposes, and #7 is the only open PR failing for a substantive reason. So the
one PR that looked like a routine version bump is a **High-severity security
fix that has been blocked since 2026-06-09**. Locally, `view_component` 4.12.0
passes all 99 unit tests and all 10 system tests, so whatever fails in #7's CI
is either stale or environmental rather than a real incompatibility. Worth
re-running that PR's checks against current `main` before assuming otherwise.

## Validation

`env -u SENREN_CHROMEDRIVER -u SENREN_CHROME_BIN bin/ci` — all six steps pass:

- 99 runs, 1887 assertions
- 10 system runs, 139 assertions
- RuboCop: 126 files, no offenses
- JavaScript: 25 files, no lint errors
- Performance: all four budgets pass
- Dependency audit: no vulnerabilities

## Decisions

1. `bundle-audit check --update` refreshes the advisory database on every run.
   That makes the build depend on network access and means a newly published
   advisory can fail an unchanged commit. This is intended: for a security
   gate, a build that fails because the world changed is the correct behavior.
2. Fixed the advisories by updating rather than adding ignore entries. No
   `.bundler-audit.yml` was created, so there is no place for a suppression to
   hide.

## Next steps

- Re-run CI on PR #7; it may now be mergeable, and it carries a High-severity
  fix.
- PR #12 (nokogiri) will conflict: nokogiri moved out of the gemspec into the
  development group earlier in this session.
- The CI matrix gap recorded in plan 022 is still open: the gemspec claims
  `ruby >= 3.2` and `rails >= 7.1`, but CI tests only Ruby 3.4 with Rails 8.1.
  A CVE gate on one untested combination is weaker than it looks.
