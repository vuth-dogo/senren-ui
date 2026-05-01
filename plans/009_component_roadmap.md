# Plan 009 — Component Roadmap

## Purpose

Define the build order, scope per phase, and stub policy for v0.1
components.

## Scope

- All components from section 21 of `master_prompt.md`.
- Phase definitions from section 22.
- Stub vs. fully-implemented criteria.

## Decisions

1. Build by dependency graph, not alphabetically. Phases are:
   - **Phase 1 — Foundation**: Button, Link, Badge, Typography,
     Separator, Skeleton, Avatar, Alert, Card, AspectRatio.
   - **Phase 2 — Forms**: Form, Input, Textarea, Checkbox,
     CheckboxGroup, RadioButton, NativeSelect, Select, Switch,
     MaskedInput.
   - **Phase 3 — Overlays**: Dialog, AlertDialog, DropdownMenu,
     Popover, Tooltip, HoverCard, Sheet, ContextMenu.
   - **Phase 4 — Navigation/Layout**: Breadcrumb, Tabs, Accordion,
     Collapsible, Sidebar, ThemeToggle, ShortcutKey.
   - **Phase 5 — Data/Advanced**: Table, Pagination, Progress,
     Clipboard, Codeblock, Command, Combobox, Calendar, DatePicker,
     Carousel.
   - **Phase 6 — SaaS Blocks**: AppShell, TopNav, PageHeader,
     EmptyState, StatCard, SettingsSection, DataTable, FilterBar,
     SearchInput, BulkActionBar, TeamMemberList,
     InviteMemberDialog, BillingPlanCard, ApiKeyField, ActivityFeed,
     RichTextEditorLite.
2. v0.1 ships **fully implemented** Phases 1–3 and **scaffolded**
   Phases 4–6. Scaffolded means: registry entry, ViewComponent class
   with constructor and minimal template, test, skill block. Each
   stub carries a `# TODO: senren v0.1 stub` comment and a
   `STUB: true` flag in registry.
3. `RichTextEditorLite` ships in v0.1 as a contenteditable + tiny
   toolbar Stimulus controller. No external editor library. Section
   32 forbids over-engineering it.
4. SaaS blocks compose primitives only. They must not introduce new
   styling tokens or new Stimulus patterns.
5. Every component, including stubs, must be exercised in
   `apps/todolist` if its category appears on a Todo page (see
   sections 14–15 of `master_prompt.md`).

## Current status

- 2026-04-29: Rich Content components were promoted from stubs to
  functional components: Carousel, Codeblock, Command, and
  RichTextEditorLite.
- 2026-04-29: SaaS Blocks were promoted from stubs to functional
  composite components: AppShell, TopNav, PageHeader, EmptyState,
  StatCard, SettingsSection, DataTable, FilterBar, SearchInput,
  BulkActionBar, TeamMemberList, InviteMemberDialog,
  BillingPlanCard, ApiKeyField, and ActivityFeed.
- Rich Content components were out of scope for the earlier SaaS
  promotion pass, then completed in a dedicated pass.

## Files to create

For each component `<name>` in any phase:

```
senren-rails/templates/components/<name>/<name>_component.rb
senren-rails/templates/components/<name>/<name>_component.html.erb
senren-rails/test/components/<name>_component_test.rb
# if interactive:
senren-rails/templates/controllers/<name>_controller.js
senren-rails/test/system/<name>_test.rb
```

Plus registry entries in `registry/components.yml`.

## Files to modify

- `registry/components.yml` (one entry per component).
- `registry/groups.yml` (assign to skill-file group).
- `.senren/skill.md` (after each install).

## Expected behavior

- `senren:add <any-listed-component>` succeeds for every component
  in the list, even if the component is a stub.
- Stubs render visible "stub" badges in dev environment so developers
  notice them. Production renders the stub silently as a placeholder.
- Phase 1–3 components pass full render and (where applicable)
  system tests.

## Test strategy

- One render test per component, asserting the
  `data-senren-component` attribute.
- For stubs, an additional test asserts the stub flag is set.
- System tests for every Phase 3 interactive component.

## Acceptance criteria

- [ ] Every component in section 21 has a registry entry.
- [ ] Phase 1–3 are not stubs.
- [ ] Phase 4–6 are scaffolded or promoted from stubs with clear
  registry state.
- [ ] Build order documented and followed in history files.
- [ ] No component blocks a phase ahead of it (dependency closure).
