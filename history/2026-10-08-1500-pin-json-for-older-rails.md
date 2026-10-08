# 2026-10-08 - Pin json below 3 on the Rails 7.1, 7.2 and 8.0 matrix legs

## Goal

Every PR opened on 2026-10-02 (#22-#26) went red on nine of the twelve matrix jobs: every Ruby on Rails 7.1, 7.2 and
8.0, with Rails 8.1 green. The PRs touch unrelated files (#26 changes only `Gemfile.lock`, which the matrix never
reads), so the failure came from the environment, not the diffs.

## Cause

`gemfiles/*.gemfile.lock` are gitignored, so each matrix job resolves the newest gems. json 3.0.2 resolved, and json 3
dropped the `quirks_mode:` keyword that `ActiveSupport::JSON::Encoding::JSONGemEncoder#stringify` still passes on
Rails < 8.1. Any component whose tag carries a hash-valued `data:` attribute (dialog, accordion, cart,
rich_text_editor_lite) raised `ArgumentError: unknown keyword: quirks_mode` while rendering.

Reproduced locally by re-resolving `gemfiles/rails_7.2.gemfile`: json 3.0.2, 26 errors and 4 failures in
`rake test:integration`.

## Changes

- `gem 'json', '< 3'` in `gemfiles/rails_7.1.gemfile`, `rails_7.2.gemfile` and `rails_8.0.gemfile`, each with the
  reason. Rails 8.1 is left free so the matrix still proves the newest json.

## Commands run

- `bundle lock` per matrix gemfile: json 2.21.2 on 7.1/7.2/8.0, json 3.0.2 on 8.1
- `bin/matrix`

## Results

`bin/matrix`: Rails 7.1.6, 7.2.3, 8.0.5.1 and 8.1.4 each 206 unit and 63 integration runs, 0 failures.

## Decisions

- Pinned in the matrix gemfiles, not the gemspec. senren-ui does not depend on json; the incompatibility is between
  Rails and json, and an app on Rails < 8.1 that resolves json 3 breaks on any `to_json`, ours or not.
- Committing the matrix lockfiles would also have stopped this, but it would stop the matrix noticing the next
  upstream break too. Loose resolution is the point of the matrix.

## Next steps

- Drop the pin when ActiveSupport on these lines stops passing `quirks_mode:`, or when the lines leave the matrix.
