# 2026-07-31 10:36 - Render Coverage Audit

## The question

"The matrix finishes very fast — is it really running system tests?"

It was not, and the suspicion was well placed.

## What the matrix actually proved

`bin/matrix` ran `bundle exec rake test`. The Rakefile's `test` task excludes
`test/system/**`. So every matrix leg reported *132 runs* — exactly the unit
count — and no browser test ran on any Rails version but the newest.

Auditing what covered component **rendering** at all:

| Coverage | Reality before |
|---|---|
| Components with a dedicated test in `test/components/` | 3 of 62 |
| `registry_component_contract_test.rb` | checks constants and inheritance; never calls render |
| Kitchen-sink test rendering all 62 | a **system** test, so Rails 8.1 only |
| Declared variants ever rendered | 0 of 122 |
| Declared sizes ever rendered | 0 of 74 |

So a green matrix said the library code worked on Rails 7.1-8.1 while proving
nothing about whether a single component rendered on any of them — for a
ViewComponent library, rendering is precisely the part that depends on the Rails
version.

## What was added

**`test/integration/`, a new suite that the matrix runs.** It boots the dummy
app and renders server-side, no browser, about a second per leg. It lives in its
own rake task and process because the unit suite `load`s component classes
directly; booting the dummy app in the same process loads them again and
ViewComponent 4 raises `RedefinedSlotError`. That is the same reason Rails keeps
system tests separate, discovered the same way — by trying it.

- `component_rendering_test.rb` — all 62 components render through the real
  routes; the static, interactive, and red-team previews render; no inline event
  handlers reach the output.
- `component_variants_test.rb` — **258 render calls**: 122 declared variants, 74
  declared sizes, and each component's default state. Also asserts unknown
  variants and sizes raise rather than silently falling back.

`bin/matrix` now runs `test` and `test:integration` per Rails version, and the
GitHub workflow runs both in the matrix job. Verified: 18 integration runs on
each of Rails 7.1, 7.2, 8.0, 8.1.

## Three defects the new coverage found immediately

### 1. Three components raised on plain `.new`

`typography`, `separator`, and `aspect_ratio` inherit `variant: :default` from
`BaseComponent` but define no `:default` in their `VARIANTS`, so

```ruby
Senren::SeparatorComponent.new
# => ArgumentError: Unknown variant: :default. Allowed: horizontal, vertical
```

Invisible until now because every preview passes a variant explicitly. Given
sensible defaults — `:p`, `:horizontal`, `:square`. This can only fix code that
was already broken: the previous behaviour was an exception.

### 2. Any component given `data:` silently lost its root marker

`MaskedInputComponent` rendered without `data-senren-component`, while the
`InputComponent` it delegates to emitted it. The cause is in `root_attrs`, so it
affected every component, not just this one:

```ruby
data = (extra.delete(:data) || {}).merge(senren_component: senren_component_name)
{ class: tag_class, data: data, **html_attrs, **extra }
```

`html_attrs` is splatted *after* the computed `data:`, so a caller-supplied
`data:` hash overwrote it wholesale and took the marker with it. Fixed by
merging both sources and applying the marker last.

The static contract test could not have caught this: it checks the marker is in
the *template*, and it was. Only rendering shows it being dropped.

### 3. `MaskedInputComponent#initialize` never calls `super`

Found while diagnosing the above. It inherits `BaseComponent` but skips its
constructor, so `@variant`, `@size`, `@class_name`, and `@html_attrs` are unset.
It works today because it forwards everything to `InputComponent`, but
`root_attrs` on it would operate on nil state. Left as-is and recorded rather
than changed, since it is not currently reachable and the fix belongs with a
wider look at delegating components.

## A flaky gate, fixed

`bin/ci`'s dependency audit ran `bundle-audit check --update` and failed when
GitHub was unreachable — a network timeout reported identically to a real
advisory. Split: refresh the database when possible, warn and continue on a
local copy when not, fail hard if there is no database at all. The GitHub
workflow keeps the strict `--update`, where missing network genuinely is a
failure.

## Validation

`/bin/bash bin/ci --matrix`, exit code checked:

- exit 0
- unit 132 runs / 2080 assertions
- integration 18 runs / 123 assertions
- system 16 runs / 305 assertions
- RuboCop 141 files, no offenses
- matrix: `test` and `test:integration` green on Rails 7.1, 7.2, 8.0, 8.1

## Accessibility, the gap this entry first only named

`test/integration/accessibility_test.rb` asserts the structural invariants that
can be proved from rendered markup and that break silently: unique ids, valid
ARIA roles, `aria-controls`/`labelledby`/`describedby` resolving to elements
that exist, anchors being focusable, every control having an accessible name,
and nothing focusable inside an `aria-hidden` subtree. It is not a replacement
for axe or manual testing — it is the subset a renderer can prove.

It found four problems on first run:

- **Duplicate ids on the kitchen sink** (`details-panel`, `q`). The preview
  helper passed `id: 'details'` to both the accordion and the tabs, and rendered
  two search inputs both defaulting to `name: 'q'`. Fixture bugs, not component
  bugs — but duplicate ids silently detach every `aria-controls` and
  `label[for]` pointing at them, and the kitchen sink is what the system tests
  render too.
- **Readonly inputs with no accessible name** in `clipboard` and
  `api_key_field`. These are focusable display fields whose `label:` names the
  button, not the input. A genuine component gap; both now carry `aria-label`.
- **Unlabelled inputs in three previews**, now named.

And a fourth that was **my test being wrong**: it reported the checkbox, radio,
and switch components as unnamed because it only looked for `label[for]`. Those
components wrap the input inside the `<label>`, which is the implicit form and
perfectly valid. The components were right; the check was not. That is the
fourth time this session that verification, rather than code, was the defect —
so the rule holds: make the check fail on purpose and read what it says before
believing it.

## What is still not covered

Stated plainly, because the point of this entry is that a green suite was
hiding gaps:

- **Browser behaviour across versions.** System tests still run on one Rails
  version only. That is a deliberate call, not an oversight: Stimulus behaviour
  does not depend on the Rails version, and the server-rendered markup it acts
  on is now covered by the matrix. Running Chrome four times would cost minutes
  to re-prove the same thing.
- **Ruby versions locally.** Only 3.4 is installed here; 3.2 and 3.3 are
  exercised in CI. `TargetRubyVersion: 3.2` in RuboCop is the local proxy.
- **Accessibility beyond structure.** Colour contrast, focus order, keyboard
  traps, and screen-reader announcements are not asserted; the prose
  `accessibility` notes in the registry are still not machine-checked. An axe
  run against the system tests is the natural next step.
- **Visual regression.** No screenshot baselines. Out of scope for now.
- **Slot and block coverage.** Components are rendered with default content;
  their slots are exercised only where a preview happens to use them.
