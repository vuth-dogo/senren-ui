# Hot reload

What reloads automatically, what does not, and why — for both people working
on the gem and people using it in an app.

## Working on the gem

`templates/` is the source of truth, and the preview app under `.local/preview`
holds *copies* made by `bin/seed_preview`. Editing a template therefore has no
effect on the running preview until the copy is refreshed. `bin/watch` closes
that gap.

```bash
bin/seed_preview                       # once
cd .local/preview && bin/rails server  # terminal 1
bin/watch                              # terminal 2, from the gem root
```

With both running, editing `templates/components/button/button_component.html.erb`
copies that one file into the preview app and the browser reloads within about
a second.

What each kind of edit does:

| You edit | `bin/watch` does | Result |
|---|---|---|
| `templates/components/<name>/*` | copies the one file | page reloads |
| `templates/controllers/*.js` | copies the one controller | page reloads |
| `registry/*.yml` | full reinstall of every component | page reloads |
| `lib/generators/senren/install/templates/*.tt` | copies to its host path | page reloads |
| `lib/**/*.rb` | nothing | restart `bin/watch` and the server |

`lib/` is deliberately not watched: changing gem internals requires restarting
the Ruby process, which a file copy cannot do.

`installed_components.yml.tt` is never synced. That file is a *template* for a
ledger, and the ledger in the preview app is state — copying over it would
erase the install history.

Options:

- `SENREN_PREVIEW_ROOT` — watch a preview app somewhere else. Matches
  `bin/seed_preview`.
- `SENREN_WATCH_INTERVAL` — poll interval in seconds, default `0.5`.

### How the browser reload works

`bin/watch` writes a timestamp to `tmp/senren-reload.txt` after every sync. The
preview layout polls `/senren/reload_token` twice a second and calls
`location.reload()` when the value changes.

This exists because Rails only reloads *Ruby and ERB*. A Stimulus controller is
JavaScript already delivered to the browser: syncing the file changes nothing
until the page is reloaded and the module is fetched again. The token is what
makes controller edits feel hot.

There is no websocket, no ActionCable, and no extra gem — deliberately, since
the whole plumbing exists only in the gitignored `.local/preview` app and must
never reach a published gem or a host app.

### Manual check

Automated tests cover the path-mapping logic (`test/template_sync_test.rb`).
The polling loop itself is verified by hand:

1. Start the server and `bin/watch`.
2. Change a colour class in a component template — the page reloads with the
   new style.
3. Add a `console.log` to a controller — the page reloads and the log appears.
4. Add a component to `registry/components.yml` — the watcher reports a full
   reinstall and the new component renders.

## Using the gem in your app

After `bin/rails senren:add`, the components are yours. Rails handles most of
the reloading, so there is little for Senren to add:

| You edit | Reloads? |
|---|---|
| `app/components/senren/*.rb` | Yes — Rails reloads on the next request |
| `app/components/senren/*.html.erb` | Yes — same |
| `app/assets/stylesheets/senren.css` | Yes, once Tailwind rebuilds |
| `app/javascript/controllers/senren/*.js` | **No** — needs a page reload |

The Stimulus row is the one to know about. With importmap the controller is a
module the browser has already fetched, so editing it does nothing until you
reload the page. In development Propshaft serves the new file immediately, so
an ordinary refresh is enough — you do not need to restart the server or clear
a cache.

If you want that refresh automated, the usual choice is the `hotwire-livereload`
gem in your own `Gemfile`. Senren does not ship one, because doing so would put
a development dependency and a websocket into every app that installs a
component library.

### Turbo morphing

If your app uses Turbo 8 page morphing, a morph can move or replace the element
a controller is attached to, which triggers `disconnect()` and `connect()`.
Senren controllers clean up their document-level listeners in `disconnect()`,
so they survive repeated morphs. If you write your own controller, do the same:
anything you add to `document` or `window` in `connect()` or on open must be
removed in `disconnect()`, or it will accumulate on every navigation.
