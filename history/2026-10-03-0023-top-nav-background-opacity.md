# 2026-10-03 00:23 - TopNav's Translucent Background Was No Background

## Goal

The default `TopNavComponent` is `sticky top-0` with `backdrop-blur-md`, and
was reported transparent: page content showed through it while scrolling.

## The bug

`templates/components/top_nav/top_nav_component.rb`, default variant:

```ruby
default: 'bg-[hsl(var(--senren-background))/0.88]'
```

The `/0.88` is inside the brackets, so it is not Tailwind's opacity modifier.
Tailwind v4 copies bracket content verbatim, giving
`background-color: hsl(var(--senren-background))/0.88`. That is not a valid
`<color>`, so the browser drops the declaration and computes
`rgba(0, 0, 0, 0)`. Tailwind does not warn: the arbitrary value is valid, the
CSS it produces is not.

It is the only class of this shape in the library. Every other translucent
class already puts the alpha inside `hsl()`:
`bg-[hsl(var(--senren-background)/0.88)]` appears twice in other templates.

## Changes

- `top_nav_component.rb`: `bg-[hsl(var(--senren-background)/0.88)]`, which
  keeps the intended 88% translucency.
- `test/arbitrary_value_alpha_test.rb`: scans every `.rb`, `.erb` and `.tt`
  under `templates/` and `lib/` for an arbitrary value ending in `)/<n>]`.
  The rule is itself tested against the broken shape and three working ones,
  so it does not pass merely because nothing matches.
- `CHANGELOG.md`: Unreleased / Fixed.

## Why not a browser test

The dummy app ships no Tailwind stylesheet, so a computed-style check there
reads the browser default whatever the class says. `focus_ring_room_test.rb`
records the same trap. The bug is a source shape, so the test is a source scan.

## Validation

- New test before the fix: 3 runs, 1 failure, naming
  `templates/components/top_nav/top_nav_component.rb: bg-[hsl(var(--senren-background))/0.88]`.
- After the fix: 3 runs, 11 assertions, 0 failures.
- `bin/ci`: 8 of 9 gates pass (209 unit, 63 integration, 29 system runs, 0
  failures). The dependency audit fails on rubyzip 3.3.1 (CVE-2026-85396),
  the same failure as on `origin/main`, not touched here.
