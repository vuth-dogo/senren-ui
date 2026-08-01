# 2026-08-01 22:03 - Eight Defects From The Architecture Review

An external architecture review reported seven defects inside a green suite
(158 runs, 2,206 assertions, RuboCop clean). All seven reproduced. An eighth
turned up while writing a regression test for the fifth.

## The one that mattered most

`gem "senren-ui"` — the obvious Gemfile line, with no `require:` option —
loaded nothing at all. Bundler tries the gem name, then its hyphen-to-slash
fallback `senren/ui`, and **swallows the second LoadError**. There was no
`lib/senren-ui.rb`.

The failure is silent and it is worst where it hurts:

- no engine, so no `AssetPathGuard` — the production source-disclosure
  protection committed the day before was simply absent
- no rake tasks, so `senren:doctor` and `senren:agents:sync` did not exist
- but the generator and `senren:add` kept working, because they
  `require "senren/rails"` themselves

So the install looked healthy while its flagship production protection was
missing. One line of new code fixes it.

## The guard was directional

`AssetPathGuard#covers?` asked only whether the asset path was an **ancestor**
of `app/components`, with a bare `start_with?`:

| Host config | Guard | Reality |
| ----------- | ----- | ------- |
| `app/components` | raises | correct |
| `app/components/senren` | **boots clean** | publishes every component |
| `app/comp` | **raises in production** | publishes nothing |

The descendant case is the dangerous one, because it is what a developer
writes after reading the guard's own remediation text: *"Move sidecar assets
into their own directory and add that instead."* Narrowing the path to the
directory that actually holds the components evaded the check entirely.

The fix is not simply "test both directions" — that would flag the legitimate
`app/components/assets` sidecar pattern the guard deliberately allows. It now
asks, per asset path, whether the overlapping subtree contains source, scanning
the deeper of the two paths. `app/components/assets` holding only CSS passes;
`app/components/senren` holding components does not.

Separately, `Rails.env.production?` meant a conventional `RAILS_ENV=staging`
deploy printed one line of stderr and precompiled the source anyway. Now
`!Rails.env.local?` — everything except development and test is deployed.

## Containment was lexical, so a symlink walked straight through it

`assert_inside_host_root!` used `Pathname#expand_path`, which normalises `..`
but does **not** resolve symlinks, and `refuse_symlink?` tested only the leaf.
`HostPaths#ensure_dirs!` used `mkpath`, which stops at `File.directory?` — and
that follows links, so a symlinked parent was preserved rather than replaced.

Symlinking `app/components/senren` outside the app root and running
`install(['button'])` wrote three files outside it. `AgentRulesWriter` was
worse: `write_adapter_file` reads its destination before rewriting, so a
symlinked `.senren`, `.github` or `.cursor/rules` pulled outside content in and
wrote it back out — modifying pre-existing files outside the checkout.

Replaced with one `SafeWrite` module: realpath comparison for containment,
whole-chain symlink refusal, and a `mkdir_p!` that will not build through a
link. All four writers route through it.

## Three quieter ones

**`--no-client` broke transitive dependencies.** The override was applied to
the entire closure, so `senren:add context_menu --no-client` also suppressed
`dropdown_menu`'s controller — and dropdown_menu's markup emits
`data-controller` unconditionally, so the installed menu silently never opened.
Twelve registry entries have that shape. The ledger then recorded
`client: false` for a component the command was never asked about.
`validate_client_override!` already exempted dependencies in the other
direction, with a comment explaining why; the destructive direction had not
been thought through.

**`class:` erased every component's styling.** `ButtonComponent.new(variant:
:primary, class: "mt-2")` rendered `class="mt-2"` — variant and size gone.
`class:` is a legal kwarg that lands in `**html_attrs`, and the trailing splat
overwrote the computed value. The identical bug had already been found and
fixed for `data:` — the comment above it documents MaskedInput hitting it — and
the fix was never extended to `class`.

**Two URL sinks bypassed the render contract.** `FormComponent#url` reached
`form_with`'s action, where `//evil.example` POSTs every field plus the CSRF
token off-origin. `AvatarComponent#src` reached `image_tag` on user-controlled
profile data. Both slipped through because
`test/security/component_url_security_test.rb` used an **allowlist of ten known
components**, so anything added later was missed by construction. Replaced with
a property over every component directory — which is what found them.

## The eighth, found by the test for the fifth

The regression test for `class:` failed on eight components with a different
symptom: nothing lost, but the caller's class never appeared. alert_dialog,
context_menu, dialog, dropdown_menu, hover_card, popover, sheet and tooltip
write their root element by hand rather than through `root_attrs`, so a caller
`class:` — and `class_name:` — is **dropped entirely** and never reaches the
DOM.

Not fixed: it means rewriting eight templates whose roots carry
`data-controller` and Stimulus value attributes, and it is outside what the
review asked for. It is also not hidden — weakening the test to exclude them
was the tempting move and the wrong one. It is pinned as an exact list in
`test_only_the_known_hand_written_roots_ignore_a_caller_class`, so the set can
only shrink and a new component joining it fails the build.

## Also

`Installer` deleted: zero call sites, a comment claiming it was "reused by the
install generator" that was false, no containment defences, and a raw
`FileUtils.cp` of `.tt` files that would have shipped literal `<%%=` into a
host app. Nothing in README, docs or CHANGELOG referenced it.

`SkillWriter#client_summary` now reads the ledger instead of the registry
default. After `senren:add select --no-client` the skill file told agents to
use `senren--select` and named a controller file that is not on disk. The
copier computes the truth and writes it — under a comment reading *"Never
record client behavior in the ledger that was not installed"* — and nothing
read it back. The gem's flagship feature was wrong precisely for the installs
where the flag was exercised.

`humanize` no longer raises on `foo__bar`, a name `NAME_PATTERN` accepts;
`"foo__bar".split("_")` yields an empty segment and `w[0]` was nil. It fired
after files were copied and the ledger written, leaving a half-completed
install.

The registry mirror refreshes on every install; it was written once and never
again while the generated agent rules advertised it as authoritative.

The rake helpers are namespaced in `SenrenRakeArgs` — top-level `def`s become
private methods on `Object` in every host app, and `parse_options` is a
plausible collision — and argument scanning stops at the next rake target, so
`rake 'senren:add[button]' db:seed` no longer tries to install a component
called `db:seed`, and a `--force` meant for another task no longer enables
overwriting here.

## Standing lesson, restated

Every fix here was mutated and watched failing before being trusted. Two
earned it: the URL property test was confirmed to report exactly
`["avatar", "form"]` against the unfixed components, and the git-tracking
assertion caught that `lib/senren-ui.rb` had been written but never `git
add`ed — it would have been packaged from this dirty checkout and vanished
from a clean one.

Verified green afterward on all four supported Rails versions: 179 unit runs,
2,246 assertions, 32 integration runs, plus system tests, RuboCop, JS checks,
performance budgets and the dependency audit.
