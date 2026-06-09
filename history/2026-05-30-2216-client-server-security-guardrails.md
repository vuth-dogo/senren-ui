# 2026-05-30 22:16 — Client and Server Security Guardrails

## Goal

Add practical guardrails for render-time security in Senren components and
Stimulus controllers without adding runtime weight to the gem.

## Changes

- Added shared `safe_url` and `safe_media_url` helpers to the generated
  `Senren::BaseComponent`.
- Routed component URL props through the shared helpers for links,
  buttons, navigation, command items, dropdown items, pagination, billing
  CTAs, and carousel images.
- Added security contract tests for URL protocols, unsafe Stimulus DOM
  sinks, server-side escaping bypasses, and direct SQL escape hatches.
- Added the new security tests to `bin/test`.
- Updated contributing and plan docs with the enforced guardrails.

## Decisions

- Client-side code can reduce DOM XSS risk but cannot prevent SQL
  injection. SQL injection stays a server-side/query-construction
  concern.
- No new runtime JS sanitizer dependency was added in this pass. The
  current rich text editor is kept isolated and server-sanitized; if it
  grows into user-generated rich content, DOMPurify should be evaluated as
  an explicit optional dependency.
- No profiler gem was bundled into `senren-ui`; render profiling belongs
  in host apps via Rack Mini Profiler, Active Support instrumentation, or
  production APM.

## Validation

- `bundle exec ruby -Itest test/security/component_url_security_test.rb`
  passed.
- `bundle exec ruby -Itest test/security/javascript_controller_security_test.rb`
  passed.
- `bundle exec ruby -Itest test/security/server_side_security_test.rb`
  passed.
- `bin/ci` passed: focused tests, full Ruby suite, RuboCop, and
  JavaScript syntax/lint checks.
- `git diff --check` passed.

## Next Steps

- Run `bin/ci`.
- Consider a host-app security/performance guide covering Brakeman,
  bundler-audit, Rack Mini Profiler, CSP, DOMPurify, and Web Vitals.
