# Plan 021 - Runtime Optimization

## Purpose

Reduce the runtime cost Senren imposes on host apps: the ViewComponent render
path, the Stimulus client runtime, and asset delivery. The gem itself has no
production request-path footprint (`lib/senren/rails.rb` is pure `autoload`),
so every item here is about what gets *copied into* a host app.

Findings are from a 2026-07-30 research pass against current ViewComponent 4.x,
importmap/Propshaft, Turbo 8, and Tailwind v4 guidance. The three highest-impact
claims were re-verified directly against this repo before being planned.

## Scope

In scope: lazy controller loading, render-path allocations, Turbo morph and page
cache correctness, timer leaks, Tailwind token strategy, long-list rendering.

Out of scope:

- Bundling the controllers (esbuild/rollup). It would break source-copy
  editability and add a build dependency for roughly the win that lazy loading
  gives for free.
- A caching mixin in `BaseComponent`. Caching a Button costs more than
  rendering one, and it would put a cache-key contract into a library whose
  selling point is zero runtime surface. Document instead.

## Decisions

1. **Verified before planned.** Confirmed directly: the install generator never
   touches `config/importmap.rb` or `controllers/index.js` (no reference exists
   anywhere in `lib/`); `senren_component_name` runs three regex passes inside
   `root_attrs` on every render; exactly 10 component `.rb` files lack
   `# frozen_string_literal: true`.
2. **The lazy-loading budget check is currently theatre.**
   `scripts/performance_check.rb:124-133` passes when the *README* contains the
   strings `lazyLoadControllersFrom` and `preload: false`. It asserts
   documentation, not behavior — the same class of defect plan 019 fixed
   elsewhere. It must become a real check.
3. **Pin the Senren subtree, not the whole controllers tree.** The README
   currently advises `preload: false` on all controllers, which also
   de-preloads the host app's own. Scope it to
   `app/javascript/controllers/senren`.
4. **Morph support is a correctness prerequisite, not a speed feature.** Under
   Turbo 8 morph refreshes, every overlay controller loses its JS-owned DOM
   state and `disconnect()` does not fire for in-place updates. Without a
   strategy, hosts must disable morphing — losing their own performance win.
5. **`data-turbo-permanent` is not usable as-is.** It needs a stable id, but
   `dialog_component.rb` generates `SecureRandom.hex(3)` per render. Prefer a
   `turbo:before-morph-attribute` guard, and fix the non-deterministic id
   before considering the permanent-element route.
6. **Tailwind `@theme` migration is a major-version change.** Moving tokens
   from `:root` to `@theme` would let `bg-[hsl(var(--senren-primary))]` become
   `bg-primary`, but it touches all 62 templates and breaks anyone who
   customized their copied `senren.css`. Ship additively behind a deprecation
   window, not in a patch release.

## Phases

**Phase A - internal, no API change, no host impact.**

- Memoize `senren_component_name` at the class level.
- Cut allocations in `merge_classes` / `root_attrs` (currently ~6 intermediate
  objects per render).
- Add `disconnect()` timer cleanup to `hover_card` (has none at all) and
  `clipboard` (1.2s timer touching a possibly detached target).
- Add `# frozen_string_literal: true` to the 10 component files missing it, and
  hoist the large inline class strings (notably `button`, ~300 bytes per
  render) to frozen constants.

**Phase B - generator and check work.**

- Have `senren:install` pin the Senren controller subtree with
  `preload: false` and wire `lazyLoadControllersFrom`, marker-managed like the
  agent-rules blocks already are.
- Replace the README grep with a check against the host's `config/importmap.rb`,
  and add a matching `senren:doctor` check.
- Reset `document.body.style.overflow` on `turbo:before-cache` in `dialog`,
  `sheet`, and `alert_dialog`. Today the scroll lock is snapshotted into the
  Turbo page cache, so a back navigation restores an unscrollable page.
- Add a `setTimeout`-without-`clearTimeout` lint to `performance_check.rb`.

**Phase C - design work first.**

- A shared Turbo morph strategy plus a deterministic `dom_id`.
- Hoist loop-invariant work out of per-cell loops in `data_table` and `table`
  (currently one `column_sort_key` call per cell rather than per column).
- Opt-in `content-visibility` for long lists, as a named class in
  `senren.css.tt` rather than an arbitrary Tailwind value.

**Phase D - documentation only.**

- `with_collection` guidance for host apps, and an explicit note that Senren's
  own list components intentionally use inline ERB loops — that is already the
  faster choice and should not be "refactored".
- The ViewComponent fragment-caching caveat.
- State the hard Tailwind v4 requirement; `rounded-(--senren-radius)` is
  v4-only syntax and the README never says so.

## Confirmed already correct — do not change

- No `fetch`/XHR/WebSocket/framework imports in any controller, machine-enforced.
- `data_table` sort is decorate-sort-undecorate with a single
  `DocumentFragment` write (plan 019).
- Listener cleanup in 9 of 11 listener-registering controllers.
- Inline ERB loops in the list components rather than per-row sub-components.
- ERB sidecar templates: ViewComponent compiles them to methods at boot, so
  converting to `#call` would gain nothing.
- Propshaft plus importmap is the right delivery model here; content hashing
  gives per-file invalidation that a bundle would destroy.
- No passive-listener work needed: no `wheel`, `touchstart`, or `scroll`
  listeners exist.

## Test strategy

- Phase A: existing component tests must stay green; add a test asserting
  `senren_component_name` is computed once per class.
- Phase B: a generator test asserting the importmap pin is written, and a
  system test asserting the scroll lock is released after a cached back
  navigation.
- Phase C: system tests under morph, and a row-count-scaled assertion for the
  per-cell hoisting.
- Benchmark Phase A with `memory_profiler` on the kitchen-sink page to record a
  real before/after rather than an assumed one.

## Acceptance criteria

- [ ] Phase A merged with no API change and all suites green.
- [ ] `senren:install` wires lazy loading into a host app.
- [ ] The importmap check tests host configuration, not README text.
- [ ] Scroll lock does not survive into the Turbo page cache.
- [ ] Allocation reduction measured, not assumed.
