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
