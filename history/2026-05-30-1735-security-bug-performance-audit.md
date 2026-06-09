# 2026-05-30 17:35 - Security, bug, and performance audit

## Goal

Audit the current gem repository for concrete bug, security, and performance
risks, validate findings with small tests or commands, and fix issues that can
be corrected safely in this checkout.

## Findings and fixes

- `bundle audit` found vulnerable dependencies:
  - `nokogiri 1.19.2` had high/medium advisories fixed in `>= 1.19.3`.
  - `view_component 4.8.0` had medium advisories fixed in `>= 4.9.0`.
- Raised the gem dependency floor to `nokogiri >= 1.19.3` and
  `view_component >= 4.9.0`, then updated the lockfile to
  `nokogiri 1.19.3` and `view_component 4.11.0`.
- Hardened registry validation so component entries reject unknown keys,
  off-contract file paths, and client components that omit their Stimulus
  controller file.
- Hardened `ComponentCopier` so a missing declared template aborts the
  install before `.senren/installed_components.yml` is written.
- Restricted the rich-text editor link normalizer to `http:`, `https:`,
  `mailto:`, `tel:`, root-relative paths, and fragment links; unsafe schemes
  such as `javascript:` and `data:` are no longer accepted.
- Removed obsolete `bin/seed_site`, which still targeted `../apps/site`
  outside this checkout after the docs app moved to `senren-ui-page`.

## Tests added

- `test/component_copier_test.rb`
  - proves missing templates abort before ledger writes.
- `test/controllers/rich_text_editor_lite_controller_security_test.rb`
  - locks the rich-text link protocol allowlist.
- Added registry tests for:
  - unknown registry keys,
  - unsafe/off-contract file paths,
  - client components missing controller files.

## Verification

- `bundle audit check --database /tmp/senren-ruby-advisory-db`
  - `No vulnerabilities found`
- `bin/ci`
  - Ruby: 42 runs, 1,636 assertions, 0 failures/errors/skips
  - RuboCop: 96 files, no offenses
  - JavaScript: 25 controller templates, syntax and Biome lint passed
- `bundle exec rake test:system`
  - passed; no system test files are currently present
- `bundle exec gem build senren-ui.gemspec`
  - built `senren-ui-0.1.5.gem`

## Residual risks

- Brakeman is not in this bundle, and this checkout is a Rails engine/gem
  rather than a full Rails application. Static Rails-app scanning should be run
  in host apps that install generated Senren components.
- Performance risk is mostly client-side payload size. The prior Importmap
  lazy-loading guidance remains the relevant mitigation for apps with many
  installed Stimulus controllers.
