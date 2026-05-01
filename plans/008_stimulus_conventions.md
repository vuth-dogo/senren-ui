# Plan 008 — Stimulus Conventions

## Purpose

Standardize the JavaScript surface of Senren so client behavior
remains small, local, and predictable.

## Scope

- Controller naming.
- File location.
- Allowed responsibilities.
- Forbidden responsibilities.
- Registration with Stimulus.

## Decisions

1. Controllers live under `app/javascript/controllers/senren/` in the
   host app, copied from `templates/controllers/` in the gem.
2. Controller identifiers use double-dash namespace:
   `senren--dialog`, `senren--dropdown-menu`, `senren--tabs`,
   `senren--combobox`, `senren--theme-toggle`, `senren--clipboard`.
3. Controllers are auto-registered by the host app's existing
   `controllers/index.js` if it uses `eagerLoadControllersFrom`.
   For Importmap apps that pin individually, the install generator
   prints exact pin lines.
4. Controllers handle **only** local UI behavior:
   open/close, focus management, keyboard navigation, copy to
   clipboard, theme toggle, tabs activation, accordion toggle,
   combobox interaction, rich-text toolbar.
5. Controllers must **not**:
   - Render large UI from JS.
   - Manage application state.
   - Make XHR/Fetch requests (Turbo handles server state).
   - Import any framework (React, Vue, Alpine, lit).
6. Every controller exposes its `static targets`, `static values`,
   and `static classes` near the top of the file as a self-documenting
   contract.
7. Controllers must include accessibility behavior by default
   (Escape to close dialog, focus trap, aria-expanded toggling).

## Files to create

```
senren-rails/templates/controllers/dialog_controller.js
senren-rails/templates/controllers/dropdown_menu_controller.js
senren-rails/templates/controllers/tabs_controller.js
senren-rails/templates/controllers/combobox_controller.js
senren-rails/templates/controllers/theme_toggle_controller.js
senren-rails/templates/controllers/clipboard_controller.js
senren-rails/docs/stimulus_conventions.md
senren-rails/test/system/<each>_test.rb
```

## Files to modify

- Component generator writes a controller skeleton matching this plan
  by default. `--no-client` skips it for static-only custom
  components.

## Expected behavior

- Controller file starts with imports from `@hotwired/stimulus`, then
  declares `static` contract, then methods.
- Components reference controllers via
  `data-controller="senren--<name>"` and `data-action`/`data-target`
  attributes, never via inline event handlers.
- Removing a controller from the host app degrades gracefully: the
  component still renders; the interactive feature is the only loss.

## Test strategy

- System tests using Rails system test harness (Capybara + headless
  browser) for every interactive component:
  Dialog open/close, DropdownMenu keyboard nav, Tabs activation,
  Combobox filter, Clipboard copy, ThemeToggle.
- Lint test asserting no controller imports forbidden libraries.

## Acceptance criteria

- [ ] All controllers under `app/javascript/controllers/senren/`.
- [ ] All identifiers use `senren--` prefix.
- [ ] No controller does fetch/XHR or imports React/Vue/Alpine.
- [ ] Every interactive component has a system test.
- [ ] Accessibility behavior (Escape, focus trap, aria) covered.
