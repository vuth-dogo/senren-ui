# Plan 003 — Registry Design

## Purpose

Define the schema, validation, and lifecycle of the Senren component
registry.

## Scope

- `registry/components.yml`
- `registry/groups.yml`
- `registry/recipes.yml`
- The host-side mirror `.senren/registry.yml` and
  `.senren/installed_components.yml`.

## Decisions

1. The canonical registry is `registry/components.yml` in the gem.
2. The schema for each component is fixed and validated:

   ```yml
   name:
     category: <string>            # primitive | form | overlay | nav | layout | data | saas
     client: <bool>                # default behavior
     can_have_client: <bool>       # whether --client is a meaningful override
     controller: <string|null>     # Stimulus identifier, e.g. senren--dialog
     files: [<path>...]            # files copied into host
     depends_on: [<name>...]
     pairs_with: [<name>...]
     variants: [<string>...]
     accessibility: [<string>...]
     ai:
       use_for: [<string>...]
       avoid: [<string>...]
   ```

3. `groups.yml` defines logical categories used by `skill.md`:
   Actions, Forms, Overlays, Navigation, Layout, Data Display,
   SaaS Blocks, Rich Content.
4. `recipes.yml` defines named multi-component installs, e.g.
   `recipe_form_basics: [form, input, textarea, native_select,
   button, label]`.
5. The registry is loaded via `Senren::Rails::Registry.load!`, which
   validates schema and dependency closure (every `depends_on` entry
   must exist).
6. `installed_components.yml` is the host-side ledger. Format:

   ```yml
   installed:
     - name: button
       version: "0.1.0"
       installed_at: "2026-04-27T11:30:00Z"
       client: false
   ```

7. Registry version is independent from gem version. Bumping the
   registry schema requires a migration note in `CHANGELOG.md`.

## Files to create

```
senren-rails/registry/components.yml
senren-rails/registry/groups.yml
senren-rails/registry/recipes.yml
senren-rails/lib/senren/rails/registry.rb
senren-rails/test/registry/registry_test.rb
senren-rails/test/registry/schema_test.rb
```

## Files to modify

- `lib/senren/rails.rb` to autoload `Registry`.

## Expected behavior

- `Registry.load!` raises a clear error on invalid YAML or schema.
- `Registry.find("button")` returns a frozen struct.
- `Registry.dependencies("dialog")` returns the closure (e.g. `[button]`).
- `Registry.group("Forms")` returns components ordered for skill.md.
- Unknown keys in YAML are rejected to catch typos.

## Test strategy

- Schema test: load every component, assert all required keys present
  and types correct.
- Dependency closure test: every `depends_on` reference resolves.
- `pairs_with` is symmetric where it makes sense (warn, not fail).
- Registry round-trip: load → serialize → load equals original.

## Acceptance criteria

- [ ] All Phase 1 components present in `components.yml`.
- [ ] Every entry passes schema validation.
- [ ] No dangling `depends_on` references.
- [ ] At least three recipes defined (form-basics, dashboard, settings).
- [ ] Tests cover happy path and at least three failure modes.
