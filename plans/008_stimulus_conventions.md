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
3. Controllers are registered by the host app's existing
   `controllers/index.js`. For small apps, the Stimulus default
   `eagerLoadControllersFrom` behavior is acceptable. For apps with many
   interactive components, use `lazyLoadControllersFrom` and set
   `preload: false` on the Importmap controller pins so unused Senren
   controllers are not downloaded during initial page load.
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
8. Controllers must not write unsanitized HTML or evaluate dynamic
   code. `innerHTML =`, `outerHTML =`, `insertAdjacentHTML`,
   `document.write`, `eval`, and `new Function` are blocked by
   `test/security/javascript_controller_security_test.rb`. If a
   controller must handle rich text, keep it isolated, sanitize on the
   server, and add a dedicated regression test.

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
- `README.md` documents the optional lazy Stimulus / Importmap
  configuration for host apps that need to keep initial JavaScript
  small.

## Expected behavior

- Controller file starts with imports from `@hotwired/stimulus`, then
  declares `static` contract, then methods.
- Components reference controllers via
  `data-controller="senren--<name>"` and `data-action`/`data-target`
  attributes, never via inline event handlers.
- Removing a controller from the host app degrades gracefully: the
  component still renders; the interactive feature is the only loss.
- A host app using lazy registration can render static pages without
  fetching unrelated Senren controller modules.

## Test strategy

- System tests using Rails system test harness (Capybara + headless
  browser) for every interactive component:
  Dialog open/close, DropdownMenu keyboard nav, Tabs activation,
  Combobox filter, Clipboard copy, ThemeToggle.
- Lint test asserting no controller imports forbidden libraries.
- Static security tests asserting no unsafe DOM sinks or dynamic code
  evaluation are introduced.
- `bin/performance` asserts Stimulus controllers stay below payload
  budgets and do not introduce network calls or external UI framework
  imports.

## Acceptance criteria

- [ ] All controllers under `app/javascript/controllers/senren/`.
- [ ] All identifiers use `senren--` prefix.
- [ ] No controller does fetch/XHR or imports React/Vue/Alpine.
- [ ] Every interactive component has a system test.
- [ ] Accessibility behavior (Escape, focus trap, aria) covered.
- [x] Host-app guidance documents on-demand controller loading for
      Importmap applications with many interactive components.
- [x] Unsafe DOM sinks are covered by a local security test.
- [x] Stimulus payload and runtime boundaries are covered by
      `bin/performance`.
