# 2026-07-30 23:37 - Attribution, CI Matrix, and Test Coverage

## Goal

Three things, in the order they had to happen: settle the licensing question
before keeping any reference to `jet_ui`, then prove the version-support claims
CI never exercised, then add the test categories the suite was missing.

## Licence check (done first, because it gates the rest)

`jetrockets/jet_ui` is **MIT, © 2026 JetRockets** — confirmed through the GitHub
licence API and the repository's `LICENSE.md`, which is standard unmodified MIT
text. MIT permits use, modification, and study without restriction.

No jet_ui code is copied into Senren. What transferred is architectural
reasoning, and ideas are not the subject of copyright, so the MIT notice
requirement — which attaches to copies of the software — is not triggered.
Credit is given anyway: attribution is an honesty question before it is a
licensing one.

- Added an **Acknowledgements** section to `README.md` crediting shadcn/ui (MIT)
  for the source-copy model and jet_ui (MIT) for the architectural lessons,
  stating plainly that no code was copied.
- Added a licence-and-attribution section to `plans/022_jet_ui_lessons.md`,
  including the condition that would change the answer: if jet_ui code is ever
  copied in, the MIT notice must ship with it.

## CI: the version matrix

The gemspec claimed `required_ruby_version >= 3.2` and `rails >= 7.1`. CI ran a
single job — Ruby 3.4 with whatever Rails resolved. Both claims were advertised
and never exercised, which is the same defect class plan 019 fixed in code.

- Added `gemfiles/rails_7.1` … `rails_8.1.gemfile`, each pinning one Rails
  minor and sharing `gemfiles/common.rb` via `eval_gemfile`. The root `Gemfile`
  now evals the same file, so a development dependency cannot be added to the
  default bundle and be silently missing from the matrix.
- Split the workflow into a `matrix` job (Ruby 3.2-3.4 × Rails 7.1-8.1,
  `fail-fast: false`, unit tests only) and a `checks` job that runs the
  version-independent gates once rather than twelve times.
- Added `bin/matrix` so the Rails axis can be run locally.

**Result: the claim is true.** All four Rails versions pass the full suite —
117 runs / 1978 assertions each, verified locally with `bin/matrix`. The Ruby
axis is exercised only in CI; locally RuboCop's `TargetRubyVersion: 3.2` passing
is the standing evidence that no newer syntax has crept in.

## `bin/ci` rewritten

It used `set -euo pipefail`, so the first failing gate aborted the run and hid
the state of everything after it — the opposite of the `fail-fast: false` the
workflow now uses. Rewritten to run every step, record pass/fail, print a
summary, and exit non-zero if anything failed. Added `--matrix` and `--help`,
and a note printed when the matrix is skipped so the gap is visible rather than
silent.

## Tests added

Two categories the suite did not have at all:

**`test/generators/install_generator_test.rb`** (8 tests). Previously the only
generator coverage asserted a Thor option's internal default — it could not
have caught a defect in generated output. Now asserts the directory layout,
every managed file, that escaped ERB in `conventions.md.tt` renders to usable
`<%=` examples, that the copied `base_component.rb` carries the hardened
`safe_url` guards, that the registry mirror matches the gem registry, and that
re-running with `--force` converges instead of duplicating marker blocks.

**`test/gem_packaging_test.rb`** (10 tests). What ships is a public contract and
nothing verified it. Asserts the gemspec validates, runtime dependencies are
exactly `rails` and `view_component`, nokogiri is not among them, required
files ship, development material (`bin/`, `scripts/`, `test/`, `gemfiles/`,
`.github/`, `history/`, `plans/`) does not, the package actually builds, and
every declared file exists.

The last two are the interesting ones: they assert that the gemspec's Ruby and
Rails floors appear in the CI matrix, and that a gemfile exists for every matrix
entry. Change a floor without updating CI and the suite fails. That closes the
loop rather than trusting a human to keep two files in sync.

Suite went from 99 runs / 1887 assertions to **117 runs / 1978 assertions**.

## Validation

- PASS `bin/ci` — all six gates, with no environment variables set
- PASS `bin/matrix` — 117 runs on each of Rails 7.1, 7.2, 8.0, 8.1
- PASS `bundle exec rubocop --cache false` — 133 files, no offenses
- PASS `bundle-audit` — no vulnerabilities

## A false positive worth recording

`test_ships_no_hot_reload_plumbing` initially failed on `docs/hot_reload.md`.
The file legitimately *documents* the reload endpoint, and its host-app section
is written for consumers, so shipping it is correct. The test was measuring the
wrong thing — string presence rather than executable plumbing — and was narrowed
to exclude documentation. Worth noting because a test that fails for the wrong
reason is only marginally better than one that passes for the wrong reason.

## Next steps

- An adversarial review of the plan 019 hardening is running separately; its
  findings will land as their own plan.
- Plan 021 (runtime optimization) Phase A is still the highest-value remaining
  code work.
- PR #7 should be re-run: it carries the `view_component` High-severity fix and
  4.12.0 now passes the full suite on all four Rails versions here.
