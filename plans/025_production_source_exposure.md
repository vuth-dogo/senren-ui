# Plan 025 - Production Source Exposure

## Purpose

Senren copies readable source into the host app on purpose. Establish where
that readable source is allowed to be readable, and make the boundary
enforceable rather than documented.

The rule this exists to serve: source visible in development is acceptable;
source visible in production is not.

## Findings

Investigated before any code was written.

1. **The gem has no production request path.** `lib/senren/rails/engine.rb`
   only appended a rake path. Everything else is `autoload`. There was nothing
   to attack.
2. **The default preview configuration is safe.** Every request for component
   source under the shipped configuration returns `404`.
3. **`test/dummy/app/controllers/assets_controller.rb` is sound** — it
   constrains names with `/\A[a-z0-9_]+\z/`, so path traversal fails — and it
   is never packaged into the gem.
4. **One host configuration publishes everything.** This line, which circulates
   as guidance for ViewComponent sidecar assets:

   ```ruby
   Rails.application.config.assets.paths << Rails.root.join("app/components")
   ```

   Reproduced against Propshaft 1.3.2 in the real preview app:

   - all 129 component `.rb` and `.html.erb` files resolved as assets
   - `RAILS_ENV=production rails assets:precompile` copied all 129 into
     `public/assets/`
   - `public/assets/.manifest.json` held 142 entries, 129 of them source, each
     mapping logical name to digested filename — the digest is not a secret
   - `curl /assets/senren/cart_component-a2e56eaf.rb` returned `HTTP 200` and
     the full Ruby source, served by the web server with Rails uninvolved

   This is not a gem defect. It is a host misconfiguration that the gem's own
   file layout makes unusually costly, and the gem is the only party positioned
   to notice it.

## Decisions

1. **Refuse at boot, not at request time.** By the time a request arrives the
   files are already on disk and the web server may answer without Rails. The
   only effective moment is before `assets:precompile` writes anything.
2. **Raise in production, warn elsewhere.** A failed boot is recoverable; a
   published source tree is not. Development keeps working, with a warning,
   because that is the stated risk calculation.
3. **Object to source on the asset path, not to sidecar assets.** A guard that
   bans a legitimate ViewComponent pattern gets deleted. It fires only when
   `.rb`/`.erb` actually sit under a configured asset path, so
   `app/components/assets` stays available.
4. **Accept one production initializer.** The gem's zero-production-footprint
   property is worth keeping, and this is the single justified exception.

## Verification

The unit test drives the guard with a Struct standing in for a Rails app. That
is not sufficient on its own — this session has repeatedly found the
verification wrong rather than the code — so the guard is also exercised
through a real boot:

- `test/asset_path_guard_test.rb` — the decision logic
- `test/integration/asset_path_guard_boot_test.rb` — a real Rails application
  with a real Propshaft, booted in a subprocess, including one test that runs
  `assets:precompile` and asserts no source reaches `public/assets`

Both were confirmed to fail when the guard is disabled.

## Correction

The initializer was first declared `after: :append_assets_path`, copied from
sprockets-rails. Propshaft names its own `"propshaft.append_assets_path"`, and
Rails resolves an unknown ordering anchor to an empty dependency set instead of
raising, so the anchor was inert.

Measured rather than assumed: it made no difference. An application's own
initializers run ahead of every engine's, so the guard saw a fully configured
app either way, under default ordering and under
`config.railties_order = [:main_app, :all]`. The initial claim that this was an
exploitable ordering bug was wrong.

`config.after_initialize` is still correct, because it does not depend on that
reasoning holding. An inert anchor that reads like a guarantee is the actual
defect.

## Out of scope

- Minifying or obfuscating the copied source. Senren ships editable source by
  design; minification and source maps are the host app's decision.
- Anything about `app/javascript`. Controllers are meant to be served.
