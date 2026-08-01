# Plan 022 - Lessons from jet_ui

## Purpose

Apply the applicable findings from a study of `jetrockets/jet_ui` (Rails +
ViewComponent, v0.1.0 → v0.2.8, including its CHANGELOG of mistakes made and
corrected). Same stack as Senren, so its decisions transfer almost directly.

Each item below was checked against this repo before being planned. Several of
its hardest-won lessons do not apply to us, and saying so is as useful as the
gaps: adopting them would be cargo-culting.

## Licence and attribution

Verified before writing this plan: `jetrockets/jet_ui` is **MIT licensed,
© 2026 JetRockets** (confirmed via the GitHub licence API and the repository's
`LICENSE.md`, standard unmodified MIT text). MIT permits use, modification, and
study without restriction.

No jet_ui source code is copied into Senren. What transfers here is
architectural reasoning — which decisions held up over their v0.1.0 → v0.2.8
history and which they had to reverse. Ideas and architecture are not the
subject of copyright, so the MIT notice requirement (which attaches to copies
of the software) is not triggered. Credit is given in `README.md` anyway,
because attribution is an honesty question, not only a licensing one.

If any jet_ui code is ever copied in, that changes: the MIT notice must then
ship with it, and this section must be updated to say so.

## Does not apply — and why that matters

**The Tailwind purge trap.** jet_ui's most expensive mistake (CHANGELOG v0.2.4)
was writing inline Tailwind utilities in ERB shipped *inside the gem*. Tailwind
scans the consumer's source, not gem internals, so those classes were purged in
user apps and the Accordion rendered unstyled. They had to migrate to BEM
classes plus `@apply`.

Senren is structurally immune: every component template is copied into
`app/components/senren/` in the host app before it ever renders, so the host's
Tailwind scan sees it. This is a real, load-bearing benefit of source-copy that
is worth stating explicitly in the README, because it is the single most common
failure mode for Rails UI gems.

The corollary is that we must never start rendering components *from the gem*
as a convenience path without also moving to runtime-independent CSS classes.

**The eject generator.** jet_ui bolted on `rails g jet_ui:eject` so users could
escape the gem for a component they needed to customize. For Senren, eject is
not an escape hatch — it is the only mode. We already have what they retrofitted.

## Applies — verified gaps

### 1. The compatibility claim is untested (highest priority)

`senren-ui.gemspec` declares `required_ruby_version >= 3.2` and
`rails >= 7.1`. CI (`.github/workflows/ci.yml`) runs a single job: Ruby 3.4 with
whatever Rails Bundler resolves (8.1). There is no `gemfiles/` directory.

So two supported-version claims are advertised and never exercised. This is the
same defect class plan 019 addressed in code: a guarantee asserted in metadata
but not enforced by a check. jet_ui runs Ruby 3.0–4.0 × Rails 7.0–8.1 with
`fail-fast: false` and a gemfile per Rails version.

Action: add `gemfiles/rails_7.1.gemfile` … `rails_8.1.gemfile`, drive them with
`BUNDLE_GEMFILE`, and run a matrix with `fail-fast: false`. Either the matrix
passes, or we narrow the gemspec to what we actually support. Restrict the
browser-dependent jobs to one matrix entry so system tests do not multiply.

### 2. Tailwind v4 layer order is not declared

`senren.css.tt` never declares `@layer theme, base, components, utilities`.
jet_ui recorded this as a real production break: without an explicit
declaration, layer precedence depends on import order and component styles can
lose to utilities unpredictably. We do not use `@apply` today, which is why we
have not been bitten, but the file is copied into apps that will add their own
CSS around it.

Action: declare the layer order at the top of `senren.css.tt`.

### 3. Design tokens are raw HSL channels, with no `@theme` layer

Tokens live in `:root` as bare channel triples (`--senren-primary: 151 74% 29%`)
specifically so components can write
`bg-[hsl(var(--senren-primary))]`. Two consequences:

- Tailwind generates no utilities for our tokens, so every component carries
  long arbitrary-value strings. The button root class attribute is ~300 bytes.
- Variants are hand-written. jet_ui derives `soft`/`border`/`hover` from a base
  color using relative color syntax (`oklch(from var(--primary) l c h / 40%)`),
  defining ~8 colors instead of ~40.

Action (major-version, additive first): add an `@theme` layer mapping the
existing channel variables to real utilities so `bg-primary` works, keeping the
arbitrary form valid during a deprecation window. Evaluate oklch separately —
it is what makes automatic variant derivation perceptually correct, but it is a
palette change, not just a syntax change.

This overlaps plan 021 P7; treat that as the same workstream.

### 4. No short-form API

Every call site is `render Senren::ButtonComponent.new(...)`. jet_ui invested in
a builder (`jet_ui.btn`). This is ergonomics, not correctness, but it is the
difference between a library that is usable and one that is pleasant, and it
compounds across a 62-component surface.

Action: evaluate a `senren.button(...)` helper. Note the tension with our
source-copy model: a builder is gem runtime surface, which we have deliberately
kept at zero. A generated helper copied into the host app may fit better.

### 5. CSS classes are not a first-class API

jet_ui guarantees `ui.btn "Save"` and `<button class="btn btn-default">` are
equivalent, so designers, static templates, and AI tools can all use it without
the Ruby runtime. Senren has no stable class contract — styling lives in inline
utility strings unique to each template.

Action: consider stable component classes (`senren-btn`, `senren-btn-outline`)
alongside the utilities. Lower priority for us than for jet_ui, since our users
own the copied templates and can read them directly.

### 6. No dependency vulnerability gate

jet_ui runs `bundler-audit` in CI. We run tests, RuboCop, JS checks, and
performance checks. Dependabot opens PRs but does not fail a build. Already
recorded as a follow-up in the plan 019 history; this is a second, independent
argument for it.

## Adopted as principles

1. **Stabilize conventions before scaling count.** jet_ui shipped 2 components,
   then did a breaking overhaul at v0.2.0, and only then ported the remaining 28
   in three waves (static → simple JS → overlays). We are already at 62
   components, so any convention change now costs 62×. This is the strongest
   argument for treating plan 021's Phase C and this plan's item 3 as
   major-version work with a codemod, not incremental edits.
2. **Native HTML before JavaScript.** jet_ui uses `<details>` for accordion and
   `<dialog>` for modals, and writes its own positioning rather than depending
   on Floating UI. Worth auditing our overlay controllers against: every line of
   positioning code we own is a line we maintain.
3. **Assume the consumer already has your name.** jet_ui's flash controller is
   written to be safe when the app defines a controller with the same
   identifier. Our `senren--` prefix mostly covers this, but the install
   generator writing into shared files should assume conflicts.
4. **Help text derived from the manifest.** jet_ui generates `eject --help` from
   its MANIFEST so it cannot go stale. We have `registry/components.yml` and
   should drive any component listing in help output and docs from it rather
   than maintaining a parallel list.

## Acceptance criteria

- [x] CI matrix covers the Ruby and Rails floors the gemspec claims. Ruby
      3.2-3.4 × Rails 7.1-8.1, `fail-fast: false`, driven by `gemfiles/`. The
      claim turned out to be **true**: all four Rails versions pass the full
      suite. `test/gem_packaging_test.rb` now fails if the gemspec floors drift
      out of the matrix, so the two cannot silently diverge again.
- [x] `bundler-audit` runs in CI and in `bin/ci`, and fails the build. It found
      five live advisories on first run (see the 23:24 history entry).
- [x] README credits prior art and names the Tailwind-purge failure mode that
      source-copy avoids.
- [ ] `@layer` order declared in `senren.css.tt`. Deliberately not done in this
      pass: the file is copied into host apps and the change affects cascade
      precedence, so it needs a visual check that the current test suite cannot
      provide. Scheduled with the `@theme` work rather than slipped in
      unverified.
- [ ] A decision recorded on `@theme` / oklch, short-form API, and stable CSS
      classes — each either scheduled for a major version or explicitly
      declined. All three are still open; they are major-version work because
      they touch all 62 component templates.
