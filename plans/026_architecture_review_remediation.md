# Plan 026 - Architecture Review Remediation

## Purpose

Act on the 2026-08-01 architecture review. Seven defects were reported; all
seven were reproduced by execution before any code was changed, and an eighth
was found while writing the regression test for the fifth.

## Verification first

Every claim was re-run independently rather than taken on trust, because a
report that says VERIFIED is still someone else's verification:

| # | Claim | Reproduced |
| - | ----- | ---------- |
| 1 | `gem "senren-ui"` loads nothing | `require "senren-ui"` and `require "senren/ui"` both `LoadError` |
| 2 | Guard misses descendant asset paths | `app/components/senren` → 0 offenders; `app/comp` → 1 offender |
| 3 | `--no-client` breaks dependencies | `context_menu --no-client` installed 0 controllers; dropdown_menu markup needs one |
| 4 | Symlink defeats containment | 3 files written outside the app root |
| 5 | `class:` erases styling | `class: "mt-2"` → `"mt-2"`, variant and size gone |
| 6 | Two unguarded URL sinks | property scan returned exactly `["avatar", "form"]` |
| 7 | `Installer` is dead | zero call sites; `conventions.md.tt` holds 3 raw `<%%` |

## Decisions

1. **`lib/senren-ui.rb` is the highest-value change in the repo.** Bundler
   swallows the fallback `LoadError`, so the omission produced an app with no
   engine, no rake tasks and no `AssetPathGuard`, while the generator kept
   working — an install that looks healthy with the production
   source-disclosure guard absent.
2. **Overlap is bidirectional, and per-path.** The guard now asks whether each
   asset path publishes source, scanning the deeper of (asset path,
   app/components). A naive both-directions test would have flagged the
   legitimate `app/components/assets` sidecar directory; scanning per path
   keeps that working while catching `app/components/senren`.
3. **Fail closed on environment.** `Rails.env.production?` let staging, review
   apps and any custom environment warn once and precompile anyway.
   `!Rails.env.local?` treats everything except development and test as
   deployed.
4. **An override describes what was asked for.** `--client`/`--no-client` now
   applies only to explicitly requested names; dependencies use their registry
   default. `validate_client_override!` already exempted dependencies in the
   other direction, for the same reason.
5. **Containment must be real, not lexical.** One `SafeWrite` module doing
   realpath comparison and whole-chain symlink refusal, with all four writers
   routed through it. `expand_path` normalises dots but does not resolve
   symlinks, and `mkpath` stops at `File.directory?`, which follows them.
6. **Delete `Installer` rather than repair it.** Zero call sites, a comment
   claiming it was "reused by the install generator" that was false, no
   containment defences, and a raw `FileUtils.cp` of `.tt` files that would
   ship literal `<%%=` into a host app. Nothing in README, docs or CHANGELOG
   references it. Keeping broken dead code with an inviting comment is the
   actual risk.
7. **Replace the allowlist security test with a property.** The old test
   enumerated ten known components, so anything added later was missed by
   construction — and two were. The property scans every component directory.

## The eighth defect

Writing the regression test for #5 surfaced a different bug with the same
symptom. Eight overlay components — alert_dialog, context_menu, dialog,
dropdown_menu, hover_card, popover, sheet, tooltip — write their root element
by hand instead of through `root_attrs`, so a caller `class:` is not
substituted, it is **dropped entirely** and never reaches the DOM. `class_name:`
has the same fate.

Not fixed here: it means rewriting eight templates whose roots carry
`data-controller` and Stimulus value attributes, and it is outside what the
review asked for. Recorded instead as an exact pinned list in
`test_only_the_known_hand_written_roots_ignore_a_caller_class`, so the set can
only shrink and a new component joining it fails the build.

## Out of scope

- Rewriting the eight hand-written overlay roots (above).
- The upgrade story — `senren:update` / `senren:diff` / `senren:outdated`. The
  ledger records `version` and `installed_at` that nothing reads, and
  `recipes.yml` ships seven curated recipes with no consumer. Both are real
  gaps and both are features, not defects.
