# Session: Component install command docs

## Time

Started: 2026-04-28 19:55 UTC+07:00
Finished: 2026-04-28 19:57 UTC+07:00

## Goal

Add command-line guidance to every component documentation page so users can
copy the official component into their app or generate a custom component with
the same Senren conventions.

## Changes Made

- Updated `apps/site/app/views/components/show.html.erb`.
- Added an `Install this component` section below the live preview on every
  component detail page.
- The section includes:
  - Official source-copy command:

    ```bash
    bin/rails senren:add <component_name>
    ```

  - Custom generator command:

    ```bash
    bin/rails generate senren:component <component_name>
    ```

  - `--client` is included automatically for components with Stimulus behavior.
  - Dependency notes are shown when the registry declares dependencies.

## Commands Run

```bash
cd apps/site
bin/rails runner '<all 62 component pages assert install section and add command>'
```

## Tests Run

```bash
bin/rails runner '<all 62 component pages assert install section and add command>'
# component_pages=62 failures=0
```

## Results

All 62 component pages render successfully, include the new install section,
include the component-specific `senren:add` command, and still have no live
preview fallback text.

## Decisions

- The docs distinguish official component installation (`senren:add`) from
  custom component scaffolding (`generate senren:component`).
- `--client` is derived from registry metadata so users get the correct
  Stimulus scaffold command for interactive components.

## Next Steps

- Consider adding a right-side in-page table of contents entry for
  `#install` if the docs layout gains one later.
