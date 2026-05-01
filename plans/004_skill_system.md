# Plan 004 — AI Agent Skill System

## Purpose

Define the structure, generation, and update lifecycle of the
centralized AI-agent skill file `.senren/skill.md`.

## Scope

- `.senren/skill.md`
- `.senren/conventions.md`
- `Senren::Rails::SkillWriter`
- `senren:skill:sync` rake task
- The skill template under `docs/skill_template.md`.

## Decisions

1. **One** centralized skill file. No per-component markdown by
   default. This is non-negotiable.
2. The skill file is grouped by logical category, not alphabetical:
   Actions → Forms → Overlays → Navigation → Layout → Data Display →
   SaaS Blocks → Rich Content.
3. Each component block in the skill file uses the fixed schema:

   ```
   ## Component: <Name>
   Category: <Category>
   Depends on: ...
   Pairs with: ...
   Use for: ...
   Avoid: ...
   Rails usage: <ERB example>
   Client behavior: <Stimulus controller, file path; or "None">
   Agent rules: ...
   ```

4. The skill file has a generated region delimited by HTML comments:

   ```
   <!-- senren:skill:start -->
   ...generated content...
   <!-- senren:skill:end -->
   ```

   Anything outside that region is preserved across regeneration so
   users can add app-specific notes.
5. `SkillWriter` is the **only** writer for the generated region. It
   reads from `installed_components.yml` and the gem registry; it
   never invents content.
6. `senren:skill:sync` regenerates the file without installing any
   components. Useful after manual registry edits.

## Files to create

```
senren-rails/lib/senren/rails/skill_writer.rb
senren-rails/docs/skill_template.md
senren-rails/lib/generators/senren/install/templates/skill.md.tt
senren-rails/lib/generators/senren/install/templates/conventions.md.tt
senren-rails/test/components/skill_writer_test.rb
```

## Files to modify

- `.senren/skill.md` in host app (writer target).
- `lib/tasks/senren.rake` (add `senren:skill:sync`).

## Expected behavior

- Running `senren:install` writes a skill.md with the fixed header
  and an empty generated region.
- Running `senren:add button` adds a "Component: Button" block
  inside the generated region, under the "Actions" group.
- Running `senren:skill:sync` rebuilds the generated region only.
- User content outside the markers is preserved byte-for-byte.

## Test strategy

- Snapshot tests for skill.md output for representative installs:
  `[]`, `[button]`, `[button, dialog]`, full Phase 1.
- Preservation test: write user notes outside markers, run sync,
  assert notes intact.
- Group ordering test: install in random order, assert the file
  groups in the canonical order.

## Acceptance criteria

- [ ] One skill file, not per-component files.
- [ ] Fixed group ordering.
- [ ] User content preserved across regeneration.
- [ ] Every component block contains all required sub-sections.
- [ ] AI agent rules and anti-patterns present for every component.
