# Session: Docs sidebar hover depth

## Time

Started: 2026-04-28 22:02 UTC+07:00
Finished: 2026-04-28 22:05 UTC+07:00

## Goal

Add a more tactile, shadowed, slightly 3D hover effect to the `apps/site`
documentation sidebar.

## Changes Made

- Added `docs-sidebar-link` styling in `apps/site/app/assets/stylesheets/site.css`.
- Applied the class to both top-level docs links and component links in
  `apps/site/app/views/shared/_sidebar.html.erb`.
- Kept active states visually raised with a lighter shadow.
- Added reduced-motion handling so hover still changes color/shadow without
  transform movement for users who prefer less motion.

## Commands Run

```bash
cd apps/site && bin/rails tailwindcss:build
curl -s http://127.0.0.1:3000/docs/installation | rg -n "docs-sidebar-link|Installation|Components"
```

## Results

- Tailwind build completed successfully.
- The running docs site rendered `docs-sidebar-link` on sidebar navigation
  entries for `/docs/installation`.

## Decisions

- Kept the effect site-specific rather than changing the reusable
  `Senren::SidebarComponent`, because the request targeted `apps/site`.
- Used a small translate plus layered pond/leaf shadows to match the new
  Spring Garden palette without making the dense sidebar feel jumpy.
