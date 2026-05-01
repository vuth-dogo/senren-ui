# Plan 007 — ViewComponent Conventions

## Purpose

Standardize the Ruby-side shape of every Senren component so humans
and AI agents can edit any component without learning a new pattern
for each one.

## Scope

- Module namespace.
- Base class.
- Constructor signature.
- Slot conventions.
- Variant handling.
- Class-merging utility.

## Decisions

1. Namespace: `Senren::`. Every component is `Senren::<Name>Component`.
2. Base class: `Senren::BaseComponent < ViewComponent::Base`. Provides
   shared helpers (class merging, variant resolution, attribute
   sanitization).
3. Constructor signature is keyword-only:

   ```ruby
   def initialize(variant: :default, size: :md, class: nil, **html)
   ```

   `class:` is renamed to `class_name` internally because `class` is
   a Ruby keyword. The base helper merges `class_name` with computed
   variant classes.
4. Variants are declared as class-level constants:

   ```ruby
   VARIANTS = { default: "...", primary: "...", destructive: "..." }
   SIZES    = { sm: "...", md: "...", lg: "..." }
   ```

5. Slots use ViewComponent's `renders_one` / `renders_many` only.
   Names are `with_header`, `with_body`, `with_footer`, `with_title`,
   `with_actions` — fixed vocabulary across all components.
6. Components must not access global state, the controller, or the
   request. Pass everything in via the constructor.
7. Components emit `data-senren-component="<name>"` on their root
   element so QA, tests, and AI agents can locate them in DOM.
8. Class merging uses a small internal helper, not a third-party
   `tailwind_merge` gem in v0.1, to keep deps minimal.

## Files to create

```
senren-rails/lib/generators/senren/install/templates/base_component.rb.tt
senren-rails/templates/components/<each>/<name>_component.rb
senren-rails/templates/components/<each>/<name>_component.html.erb
senren-rails/docs/viewcomponent_conventions.md
senren-rails/test/components/base_component_test.rb
```

## Files to modify

- All component templates conform to this plan.
- Component generator emits this shape by default.

## Expected behavior

- Every component responds to `.new(variant:, size:, class_name:)`
  with sensible defaults.
- Invalid variant raises `ArgumentError` with the list of valid
  options.
- Slots render in a consistent order; missing slots render nothing.
- DOM root carries `data-senren-component="<name>"`.

## Test strategy

- Base component unit test for class merging and variant resolution.
- One render test per component (default render, each variant, each
  size, slot presence/absence).
- Lint test asserts every component template's root element includes
  the `data-senren-component` attribute.

## Acceptance criteria

- [ ] All Phase 1 components share the same constructor shape.
- [ ] All slots use the fixed vocabulary.
- [ ] Invalid variants fail loudly.
- [ ] No component reaches outside its constructor inputs.
- [ ] `data-senren-component` present on every root.
