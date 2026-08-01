# Plan 020 - Hot Reload

## Purpose

Remove the edit-to-see-it loop friction when developing Senren components.
Today, changing a file in `templates/` has no effect until the developer
re-runs `bin/seed_preview`, which reinstalls all ~75 components and rewrites
the preview app. The feedback loop is measured in tens of seconds for a
one-line CSS change.

## Scope

Two scopes were requested. They need different treatments, because only one
of them has a real gap:

**Phase A - gem development (code).** `templates/` is the source of truth, and
the preview app holds *copies*. Nothing syncs them. This is a genuine missing
capability and is where the work is.

**Phase B - host apps (documentation).** After `senren add`, components belong
to the host app, and Rails already reloads `app/components/**` on every request
in development. Building a reload mechanism here would duplicate the framework.
The actual gap is narrower and worth documenting rather than automating:
Stimulus controllers served through importmap are cached by the browser, so a
controller edit needs a page reload even though the Ruby side hot-reloads.

Out of scope:

- Watching `lib/` (changing gem internals needs a process restart anyway).
- Any watcher shipped into host apps.
- Replacing `bin/seed_preview`; the watcher complements it.

## Decisions

1. **No new dependency.** A polling mtime scan over `templates/` and
   `registry/` costs a few milliseconds per tick and avoids adding `listen`
   (with its platform-specific native notifiers) to a gem whose whole selling
   point is a thin dependency surface. The scan set is ~160 files.
2. **Targeted copy, not reseed.** Map each changed template to its single
   destination and copy only that file. A registry change is the exception: it
   can add or remove components, so it triggers a full install.
3. **Browser reload via a version file, not a socket.** The watcher bumps
   `tmp/senren-reload.txt`; the preview layout polls a tiny endpoint and calls
   `location.reload()` when the value changes. No SSE, no ActionCable, no gem.
   This matters because Ruby and ERB edits are picked up by Rails on the next
   request, but Stimulus controller edits are not visible until the page
   reloads — so the reload signal is what makes JS edits feel hot.
4. **The reload plumbing lives in the generated preview app**, emitted by
   `bin/seed_preview`, not in `templates/` or `lib/`. It must never reach a
   published gem or a host app. `.local/` is gitignored, so it stays local.
5. **Phase B ships as documentation.** Writing a host-app watcher would compete
   with Rails' own reloader and with whatever bundler the host chose.

## Files to create

- `bin/watch` - polling watcher; targeted sync; bumps the reload token.
- `docs/hot_reload.md` - how the loop works for gem development, and what does
  and does not reload in a host app (Phase B).

## Files to modify

- `bin/seed_preview` - emit the reload endpoint, route, and the polling snippet
  in the preview layout.
- `CONTRIBUTING.md` - document `bin/watch` in the local setup section.
- `README.md` - short note for host-app developers on what reloads after
  `senren add` and what needs a refresh.

## Expected behavior

- `bin/watch` running alongside `bin/rails server` in `.local/preview`:
  editing `templates/components/button/button_component.html.erb` copies that
  one file and the browser reloads within about a second.
- Editing `templates/controllers/dialog_controller.js` syncs the controller and
  reloads the page, so the new controller code is actually evaluated.
- Editing `registry/components.yml` triggers a full reinstall, because entries
  may have been added or removed.
- Deleting a watched file is reported and skipped rather than crashing.
- `bin/watch` exits cleanly on Ctrl-C and refuses to start with a clear message
  if the preview app has not been seeded.

## Test strategy

The watcher is developer tooling that talks to a gitignored directory, so the
tests cover the pure logic rather than the loop:

- `test/template_sync_test.rb` - the template-to-destination mapping, including
  the controller path, the component path, the registry trigger, and rejection
  of paths outside `templates/`.
- The polling loop, the terminal output, and the browser reload are verified
  manually; a test that sleeps on the filesystem would be slow and flaky for
  little value. `docs/hot_reload.md` records the manual check.

## Acceptance criteria

- [x] `bin/watch` syncs a component template edit to the preview app.
- [x] `bin/watch` syncs a Stimulus controller edit and the browser reloads.
- [x] A registry edit triggers a full reinstall.
- [x] Mapping logic is unit tested.
- [x] No new runtime or development gem dependency.
- [x] Reload plumbing is absent from `templates/`, `lib/`, and the built gem.
- [x] `bin/test`, `bundle exec rubocop`, and `bin/performance` pass.
