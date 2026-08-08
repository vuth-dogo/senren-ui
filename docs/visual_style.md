# Senren Visual Style

Senren's default visual direction is **Spring Garden SaaS**: modern Rails UI
components with the color warmth of Japanese garden illustration, the tactile
quality of risograph print, and the restraint needed for real product screens.

## Vocabulary

- **Spring**: fresh, bright, optimistic color without candy-like saturation.
- **Japanese garden**: pond blue, sakura pink, young leaf green, iris violet,
  warm paper, and deep pine ink.
- **Risograph-adjacent**: flat color fields, gentle grain when used in
  marketing surfaces, and clear shape boundaries.
- **SaaS-practical**: readable tables, forms, dialogs, and dashboards. Color
  supports hierarchy; it does not replace hierarchy.
- **Elegant**: small radius, calm borders, controlled shadows, generous but
  not decorative spacing.

## Core Palette

Use the semantic `--senren-*` tokens in component templates. The named palette
tokens are available for documentation, examples, and branded surfaces.

| Token | Role |
| --- | --- |
| `--senren-background` | warm paper app background |
| `--senren-foreground` | deep pine ink text |
| `--senren-primary` | main action green |
| `--senren-secondary` | sakura surface |
| `--senren-accent` | pond blue hover and highlight |
| `--senren-muted` | soft young leaf surface |
| `--senren-border` | pale waterline borders |
| `--senren-palette-sky` | illustration and brand accent |
| `--senren-palette-sakura` | illustration and secondary surfaces |
| `--senren-palette-pond` | panels, previews, and selected surfaces |
| `--senren-palette-leaf` | success and growth accents |
| `--senren-palette-iris` | secondary visual accent |
| `--senren-palette-paper` | warm neutral surface |

## Palette Presets

`senren.css` declares Spring Garden in `:root`. That is the default and needs no
attribute. `senren_themes.css` adds five alternates, each one a re-declaration
of the same token table:

| `data-senren-theme` | Reads as |
| --- | --- |
| *(omitted)* | Spring Garden — warm paper, pine ink, garden green |
| `rose` | warm pink, low contrast |
| `slate` | neutral grey, high contrast |
| `indigo` | cool blue-violet |
| `emerald` | cool green |
| `amber` | warm gold |

```erb
<%= stylesheet_link_tag "senren" %>
<%= stylesheet_link_tag "senren_themes" %>
```

```erb
<html data-senren-theme="rose">
```

**Load `senren_themes.css` after `senren.css`.** `:root` and
`[data-senren-theme="rose"]` are equal specificity, so the later rule wins and
source order is the whole mechanism. Reversed, both files load, the attribute is
on `<html>`, nothing errors, and the page renders in the default palette — the
one failure mode of this feature, and it looks like the theme file was never
installed.

The attribute goes on `<html>`, not on `<body>` or a wrapper, so it composes
with the existing `.dark` class instead of replacing it. Light/dark stays
orthogonal to palette: each preset ships both blocks.

No component knows themes exist. They read `hsl(var(--senren-*))` and inherit
whatever is in scope, which is why a sixth palette is a copied CSS block and
nothing else — no component to touch, no build step, no configuration.

Switching at runtime is one attribute write:

```js
document.documentElement.dataset.senrenTheme = "slate"
```

## Overriding a Component's Classes

`class_name:` and `class:` are both merged into the element the component
styles. Merged, not resolved — the component's own class stays in the list:

```erb
<%= render Senren::DialogComponent.new(class_name: "max-w-sm") %>
<!-- panel renders class="… max-w-lg max-w-sm …" -->
```

Two `max-w-*` declarations with identical specificity, so the winner is whichever
Tailwind emits later in the stylesheet. The order of the HTML attribute is not an
input to that. Tailwind emits the named scale alphabetically, which measured
against a real build means:

| You pass | Against dialog's `max-w-lg` | Result |
| --- | --- | --- |
| `max-w-sm` | `sm` emitted after `lg` | applies |
| `max-w-2xl` | `2xl` emitted before `lg` | **silently ignored** |

Nothing about either class tells you which you are getting. For an override that
does not depend on emit order, use Tailwind's important modifier:

```erb
<%= render Senren::DialogComponent.new(class_name: "max-w-2xl!") %>
```

This applies to any pair from one utility family — `w-`, `h-`, `p-`, `z-`,
`text-`, `bg-`. It is not specific to widths. Senren does not ship a
class-conflict resolver; adding one means a `tailwind_merge` dependency, which
the library has so far chosen not to take.

Classes from families the component does not use need no modifier — there is
nothing to conflict with.

## Component Rules

- Prefer semantic tokens over raw color utilities.
- Keep primitives quiet: buttons, inputs, cards, tables, menus, and dialogs
  must stay usable in dense SaaS screens.
- Use colorful surfaces mostly for state, focus, hover, badges, empty states,
  callouts, and documentation previews.
- Avoid black-and-white defaults unless contrast requires it.
- Avoid one-hue themes; every screen should have a warm neutral, green, blue,
  and one soft floral accent available.
- Do not use noisy grain inside core form controls, tables, or menus. Grain is
  for marketing areas, illustrations, and preview frames only.
