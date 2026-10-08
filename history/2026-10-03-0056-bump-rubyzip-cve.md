# 2026-10-03 - Bump rubyzip past CVE-2026-85396

## Goal

`bin/ci` failed its dependency audit on `main` (4aab71e): rubyzip 3.3.1 carries CVE-2026-85396, fixed in 3.4.0.
Every open PR inherited the red gate, whatever it changed.

## Changes

- `bundle update rubyzip --conservative`: rubyzip 3.3.1 -> 3.7.0. Only `Gemfile.lock` changes (the version and its
  checksum). rubyzip is a development/test dependency, pulled in by selenium-webdriver (`>= 1.2.2, < 4.0`); the gem
  itself does not ship it, so there is no CHANGELOG entry.

## Commands run

- `bundle update rubyzip --conservative`
- `bundle exec bundle-audit check`: no vulnerabilities
- `bin/ci`

## Results

`bin/ci`: all nine gates pass, including the dependency audit.

## Decisions

- Updated rather than ignored, in line with the audit gate's own rule (no `.bundler-audit.yml`, no place for a
  suppression to hide).
- `--conservative`, so no other gem moves in a security-only change.

## Next steps

- Rebase the open fix PRs (#22-#25) on this once it merges, so their audit gate goes green.
