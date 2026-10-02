# 2026-10-03 00:28 - DataTable Pasted Cell Markup Into An Attribute

## Goal

Reported from an app whose tables have badge and link columns: those columns
did not sort, and the `<td>`s carried attributes nobody wrote.

## The bug

`data_table_component.html.erb` wrote each body cell as

```erb
<td ... data-sort-value="<%= value %>"><%= value %></td>
```

ERB escapes a plain string, so text cells were fine. A cell holding markup is
an `ActiveSupport::SafeBuffer` (`tag.span`, `link_to`, `render(...)`), and
ERB does not escape a SafeBuffer. Its markup went inside the quotes: the first
`"` closed the attribute and the rest became junk attributes. A badge
`<span class="badge" title="ok">` gave the `<td>` attributes `badge"` and
`title`, and a `data-sort-value` of `<span class=` on every row, so sorting
compared identical strings and did nothing. The visible cell looked right.

`tag.td(data: { sort_value: value })` would not have fixed it: Rails' tag
option escaping also skips `html_safe?` strings.

## Changes

- `data_table_component.rb`: `sort_value(value)`. A SafeBuffer becomes its
  decoded text via `Nokogiri::HTML5.fragment(...).text`, which is a plain
  String; anything else is `to_s` as before. ERB then escapes it exactly
  once. Nokogiri is already loaded in any Rails app through
  rails-html-sanitizer.
- `data_table_component.html.erb`: `data-sort-value="<%= sort_value(value) %>"`.
- `test/integration/data_table_sort_value_test.rb`: the `<td>` keeps exactly
  its three attributes; two HTML cells get their own text as sort values; a
  cell showing `R&D "ok"` sorts as `R&D "ok"` and the source holds
  `R&amp;D &quot;ok&quot;` with no `&amp;amp;`; plain-string and numeric
  cells are unchanged.
- `CHANGELOG.md`: Unreleased / Fixed.

## Rejected

`strip_tags` plus an explicit escape, which is what the reporting app patched
in locally. `strip_tags` returns entity-encoded text, so escaping it again
double-encodes: `R&D` became the sort key `R&amp;D`. Harmless for ordering,
but not the text the user sees. The `R&D` test fails on that version.

Also not done: a per-column `sort_value:` option for sorting dates or money by
a raw value. Useful, but a new API, not a fix.

## Validation

- New test before the fix: 5 runs, 3 failures (attributes
  `["badge", "class", "data-sort-key", "data-sort-value", "title"]`; sort
  values `["<span class=", "<a href="]`).
- After the fix: 5 runs, 12 assertions, 0 failures.
- `bin/ci`: 8 of 9 gates pass (206 unit, 68 integration, 29 system runs, 0
  failures). The dependency audit fails on rubyzip 3.3.1 (CVE-2026-85396),
  the same failure as on `origin/main`, not touched here.
