# 2026-07-31 13:54 - Component Source Was Servable In Production

## The question

Whether a library that deliberately copies readable source into the host app
can end up publishing that source over HTTP. Development exposure is
acceptable; production exposure is not.

## What was safe

- The gem had **no production request path** at all. `engine.rb` appended a
  rake path; everything else is `autoload`. There was nothing to reach.
- Under the shipped configuration every request for component source returns
  `404`.
- `test/dummy/app/controllers/assets_controller.rb` constrains names with
  `/\A[a-z0-9_]+\z/`, so traversal fails, and it is never packaged.

## What was not

One line, which circulates as guidance for ViewComponent sidecar assets:

```ruby
Rails.application.config.assets.paths << Rails.root.join("app/components")
```

Reproduced against Propshaft 1.3.2 in the real preview app, not reasoned about:

- all 129 component `.rb` and `.html.erb` files resolved as assets
- `RAILS_ENV=production rails assets:precompile` copied all 129 into
  `public/assets/`
- `public/assets/.manifest.json` held 142 entries, 129 of them source, each
  mapping logical name to digested filename — so the digest is not an obstacle
- `curl /assets/senren/cart_component-a2e56eaf.rb` returned `HTTP 200` with the
  full Ruby source, served by the web server without Rails involved

A host misconfiguration rather than a gem defect, but one the gem's file layout
makes unusually expensive, and the gem is the only party positioned to notice.

## The fix

`lib/senren/rails/asset_path_guard.rb`, run from an `after_initialize` block in
the engine. It raises in production and warns everywhere else: a failed boot is
recoverable, a published source tree is not. It fires only when `.rb`/`.erb`
actually sit under a configured asset path, so `app/components/assets` remains
a working place for sidecar assets — a guard that bans a legitimate pattern
gets deleted.

This is the gem's only production-boot behaviour, and the only exception to its
zero-production-footprint property.

## Three things that went wrong while fixing it

### The anchor that was inert, and the claim about it that was wrong

The initializer was first declared `after: :append_assets_path`, copied from
sprockets-rails. Propshaft names its own `"propshaft.append_assets_path"`, and
Rails resolves an unknown ordering anchor to an empty dependency set rather
than raising — `@resolve[name]` is simply empty — so the anchor was inert.

I called this an exploitable ordering bug and wrote a test to pin it. **The
test passed against the broken version.** So did a second attempt using
`config.railties_order = [:main_app, :all]`. Instrumenting the guard to print
what it actually saw settled it: both versions observed the offending path in
both orderings, because an application's own initializers run ahead of every
engine's (`all.push(self)` then `.reverse` in `ordered_railties`).

The ordering claim was wrong. `config.after_initialize` is still right, because
it does not depend on that reasoning holding — but the defect was an inert
anchor that reads like a guarantee, not a misordering. The test that could not
tell the two apart was rewritten to say only what it actually pins.

### A dependency that broke an unrelated test

Adding `gem 'propshaft'` to `gemfiles/common.rb` turned the lazy-loading system
test red: it expected eight controllers and got zero. `test/dummy` calls
`Bundler.require(*Rails.groups)`, so an auto-required propshaft installed its
railtie into the dummy app and took over asset serving. `require: false` fixes
it; the subprocess boot test requires propshaft explicitly. The comment in
`common.rb` says so, because the next person to drop `require: false` will not
otherwise connect a Gemfile line to a JavaScript assertion.

### A verification that verified nothing

The first version of the boot test asserted that the guard *says* something. It
passed with the guard disabled in three of five cases. The test that mattered
turned out to be the end-to-end one — run `assets:precompile`, then assert
`public/assets` contains no `.rb` or `.erb` — because it asserts the outcome
rather than the announcement. With the guard disabled it fails, and the
unguarded control run confirmed the disclosure it prevents: two source files
written, a marker constant readable in the output.

## Standing lesson

This is the sixth time this session that the verification was wrong rather than
the code. The pattern is consistent enough to state plainly: **a check that has
not been watched failing is not evidence.** Every guard added here was mutated
and observed going red before being trusted, and two of them did not.

## Also changed

- `bin/seed_preview` draws its `reload_token` route inside
  `if Rails.env.development?` and the action re-checks. The preview app is a
  development artifact and should be honest about it.
- `README.md` gained a "Component source in production" section stating that
  minification and source maps are the host app's decision, naming the
  configuration that publishes source, and pointing at the sidecar directory
  that does not.
