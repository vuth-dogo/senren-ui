# Plan 023 - Deterministic IDs and Value-Driven State

## Purpose

Make component output byte-stable across renders, then move interactive state
out of imperative DOM writes and into Stimulus values.

These are one plan, not two, because the second does not work without the
first: Turbo morph pairs old and new nodes **by id**, so a randomly generated id
makes morph replace an element rather than morph it. Converting controllers to
value-driven state while ids still churn would produce no observable
improvement.

## The problem, measured

Eight components mint a random id on every render:

```
render 1 id: "terms-8720"
render 2 id: "terms-a82e"
```

Same component, same arguments, different HTML. That single fact disables four
things at once:

- **Turbo morph** cannot pair nodes, so every morph is a replacement.
- **HTTP ETags** never match, so a client never receives a 304 even when nothing
  changed.
- **Fragment caching** is unsound: a cached fragment and a fresh one reference
  different ids, so `aria-controls` and `label[for]` point at nothing.
- **Snapshot and visual regression testing** are impossible, which is why the
  repo has none.

Randomness also does not actually prevent duplicate ids — it trades a
deterministic collision for a probabilistic one. The accessibility test added in
the previous session found real duplicates on the kitchen-sink page anyway.

Separately, the six overlay controllers keep their state in imperative DOM
writes (`hidden`, `classList`, `body.style.overflow`). `dialog_controller`
declares `static values = { open: Boolean }` and then ignores it: `_show()`
writes `openValue` *and* manipulates the DOM, so the value is a redundant copy
rather than the source of truth, and there is no `openValueChanged` callback.

Current Stimulus API usage across 25 controllers: `static values` 6, and
`static outlets`, `static classes`, `this.dispatch()`, and `ValueChanged`
callbacks **zero**.

## Decisions

1. **Derive ids, never generate them.** A `senren_dom_id` helper on
   `BaseComponent` builds an id from the arguments that identify the component.
   Same inputs always produce the same id.
2. **Collisions should be loud, not improbable.** Two components with identical
   identifying inputs on one page will now produce the same id, and the
   accessibility test fails. That is the correct signal: the caller should pass
   an explicit `id:`. A random suffix hid this rather than solving it.
3. **`id:` stays the first-class escape hatch.** Every affected component
   already accepts `id:`; that continues to win.
4. **The value is the state; the callback does the DOM.** Actions only assign
   values. All DOM work moves into `xxxValueChanged`. This is what makes the
   state server-renderable, morph-survivable, and controllable from a Turbo
   Stream that changes one attribute.
5. **No global store.** State that belongs to the server stays on the server and
   arrives as a value attribute. State that is purely local to the browser
   (theme, sidebar collapsed) stays in `localStorage`, which `theme_toggle`
   already does. A JavaScript store would create a second source of truth.
6. **Use `this.dispatch`, not hand-rolled events.** `command_controller` emits
   `new CustomEvent("senren:command-select")` by hand. Stimulus namespaces
   `this.dispatch("select")` to `senren--command:select` automatically.
7. **Write the pattern down.** This library is also instruction material for AI
   agents, so the rule goes into `.senren/conventions.md` and the skill file, not
   only into the code.

## Files to modify

Phase A — deterministic ids:

- `lib/generators/senren/install/templates/base_component.rb.tt` — add
  `senren_dom_id`.
- `templates/components/{alert_dialog,checkbox,command,dialog,invite_member_dialog,sheet,rich_text_editor_lite,tooltip}/*_component.rb`
  — replace `SecureRandom` with derived ids.

Phase B — value-driven state:

- `templates/controllers/{dialog,alert_dialog,sheet,popover,dropdown_menu,context_menu}_controller.js`
- `templates/controllers/command_controller.js` — `this.dispatch`.
- `lib/generators/senren/install/templates/conventions.md.tt` and
  `lib/senren/rails/skill_writer.rb` — document the pattern.

## Files to create

- `test/integration/deterministic_render_test.rb` — the same component rendered
  twice produces identical HTML, for every registered component.
- `test/system/value_driven_state_system_test.rb` — opening an overlay sets its
  value attribute; setting the attribute from outside opens it; state survives a
  simulated morph.

## Expected behavior

- Rendering any component twice with the same arguments produces byte-identical
  HTML.
- `Senren::DialogComponent.new(title: "Confirm")` produces the same id on every
  render and in every process.
- Setting `data-senren--dialog-open-value="true"` from the server renders an
  open dialog with no JavaScript initialisation.
- Clicking the trigger sets the value; the DOM changes because the value
  changed, not because the action touched the DOM.
- A morph that preserves the value attribute leaves the overlay open.

## Test strategy

- Determinism is asserted by rendering every component twice and comparing, so
  the guarantee covers components added later.
- The value contract is asserted in the browser from both directions: action
  changes value, and externally-set value changes DOM. Asserting only the first
  would pass on the current imperative code.
- Existing system tests for dialog, dropdown, and combobox must keep passing
  unchanged; they exercise the behaviour through the UI and are the regression
  net for the refactor.

## Acceptance criteria

- [ ] No `SecureRandom` remains under `templates/components/`.
- [ ] Every component renders byte-identically across two renders.
- [ ] The six overlay controllers drive their DOM from a value callback.
- [ ] `command_controller` uses `this.dispatch`.
- [ ] The pattern is documented in conventions and the skill file.
- [ ] `bin/ci --matrix` passes.
