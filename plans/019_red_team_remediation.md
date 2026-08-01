# Plan 019 - Red-Team Remediation

## Purpose

Fix the correctness, security, and client-lifecycle defects found by the
2026-07-30 red-team review. Every item in scope was reproduced with a
failing case before being planned; nothing here is speculative.

The unifying theme of the review was that several advertised guarantees
(`safe_url`, `senren:doctor`, marker-managed agent files, the `--client`
flag) are asserted in comments and locked in by string-matching tests,
but are not enforced by the code. This plan replaces those with
behavioral guarantees and behavioral tests.

## Scope

In scope:

- Server-side correctness: `Doctor`, `--client` override, marker sync.
- URL safety on both sides of the fence: Ruby `safe_url` and its JS twin
  `normalizeUrl`.
- Rich text editor paste/drop sanitization and link-open protocol gating.
- Stimulus listener lifecycle and `data_table` sort cost.
- Dependency hygiene: drop the unused `nokogiri` runtime dependency.

Out of scope (deferred to a later plan):

- Component upgrade lifecycle with per-file checksums (`senren:diff`).
- Registry `schema_version` and host mirror refresh.
- Deriving `files:` from the template tree (removing the 3-file cap).
- Deleting or rewiring the unused `Installer` class.

## Decisions

1. **Reproduce before repair.** Each fix lands with a test that fails
   against the current code, so the guarantee is behavioral rather than
   textual.
2. **Fix both copies of `safe_url` and pin them together.** The helper is
   duplicated in `base_component.rb.tt` and in the
   `BASE_URL_HELPER_PATCH` heredoc used to migrate existing apps. Rather
   than deduplicate now (architectural, deferred), a test asserts the two
   bodies stay byte-identical so they cannot drift again.
3. **Reject, do not rewrite, hostile URLs.** `safe_url` returns the
   fallback rather than attempting to repair an attacker-controlled URL.
   A backslash or any control character anywhere in the value is grounds
   for rejection, not stripping: browsers remove TAB/CR/LF before parsing
   and treat `\` as `/`, so a "cleaned" string would no longer be the
   string the browser acts on.
4. **Sanitize the editor on paste with the same allowlist the server
   uses.** The server-side `sanitize()` is an output filter for one
   component; it does not protect the stored value. The client allowlist
   mirrors the tags/attributes in the component template so both ends
   agree.
5. **A tampered marker block is an error, not something to preserve.**
   Malformed or duplicated markers now abort the sync with an actionable
   message instead of silently producing a block that regeneration can
   never clean up.
6. **`--client` on a component with no controller is a usage error.**
   Silently doing nothing while recording `client: true` in the ledger
   misinforms both developers and AI agents, so it raises.
7. **Keep listener fixes minimal.** Store the bound handler and remove it
   in `disconnect()` rather than restructuring templates to `data-action`,
   to keep the change reviewable and avoid touching component markup.

## Files to create

- `test/doctor_test.rb` - Doctor pass/fail behavior (currently zero tests).
- `test/marker_sync_test.rb` - tampered/duplicated/out-of-order markers
  for both `SkillWriter` and `AgentRulesWriter`.
- `test/system/red_team_remediation_system_test.rb` - browser proof for
  the batch: URL safety, paste sanitization, sort correctness, and
  listener cleanup.

## Files to modify

Ruby:

- `lib/senren/rails/doctor.rb` - `ok = !yield.nil?` treats `false` as
  success.
- `lib/senren/rails/component_copier.rb` - `--client` no-op, `safe_url`
  patch heredoc, destination containment check.
- `lib/senren/rails/skill_writer.rb` - marker validation, atomic write.
- `lib/senren/rails/agent_rules_writer.rb` - marker validation.
- `lib/senren/rails/registry.rb` - component name format validation.
- `lib/generators/senren/install/templates/base_component.rb.tt` -
  `safe_url` hardening.
- `senren-ui.gemspec` - drop `nokogiri`.

JavaScript templates:

- `templates/controllers/rich_text_editor_lite_controller.js` -
  `normalizeUrl` hardening, `openLink` protocol gate, paste/drop
  sanitizer, lazy debug payloads.
- `templates/components/rich_text_editor_lite/rich_text_editor_lite_component.html.erb`
  - route `paste` and `drop` through the sanitizer.
- `templates/controllers/data_table_controller.js` - precompute sort
  keys, batch DOM writes.
- `templates/controllers/invite_member_dialog_controller.js` - add
  `disconnect()`.
- `templates/controllers/masked_input_controller.js` - removable
  listener plus `disconnect()`.

Tests:

- `test/security/component_url_security_test.rb` - add the bypass vectors.
- `test/security/javascript_controller_security_test.rb` - widen the sink
  patterns and scan the generator's controller template.
- `test/component_copier_test.rb` - `--client` error and ledger truth.
- `test/registry/schema_test.rb` - reject malformed component names.

## Expected behavior

- `senren:doctor` reports a failure for every artifact that is genuinely
  missing, and exits non-zero on a fresh app.
- `safe_url("/\\evil.example")`, `safe_url("/\t/evil.example")` and the
  backslash and control-character variants all return the fallback.
  Legitimate relative paths, fragments, and allowed schemes are unchanged.
- `senren:add button --client` raises a clear error naming the component
  instead of silently installing nothing and writing `client: true`.
- Running `senren:agents:sync` against a file with duplicated or
  out-of-order markers aborts with a message identifying the file,
  leaving the file untouched.
- Pasting or dropping `<img src=x onerror=...>` into the editor inserts
  the image without the event handler, and the hidden textarea receives
  the sanitized markup.
- Cmd/Ctrl-clicking a `javascript:` or `data:` anchor inside the editor
  opens nothing.
- Sorting a data table reads each cell once per sort rather than once per
  comparison, and appends rows in a single batched DOM write.
- Opening the invite dialog and then disconnecting the controller leaves
  no `keydown` listener on `document`; a masked input re-connected N
  times formats its value once, not N times.

## Test strategy

Unit and contract tests (`bin/test`) carry the Ruby guarantees and the
static template scans, because they are fast and run on every push.

System tests (`bin/system`) carry the guarantees that only exist in a
real browser, since these are the ones the previous suite could not see:

- URL safety is asserted on the *resolved* `href` property, which is what
  the browser would navigate to, not on the attribute string.
- Paste sanitization is driven by dispatching a real `ClipboardEvent`
  carrying a `text/html` flavor, matching the actual attack path.
- Sort behavior is asserted on resulting row order plus an instrumented
  count of cell reads, so a regression to per-comparison DOM queries fails
  the test rather than merely being slower.
- Listener cleanup is asserted by counting `document` keydown listeners
  across an open/disconnect cycle.

## Acceptance criteria

- [x] `bin/test` passes.
- [x] `bin/system` passes.
- [x] `bundle exec rubocop --cache false` passes.
- [x] `bun run controllers:check` passes. This gate was already broken before
      the batch: `biome.json` targeted Biome 1.x while the script runs
      `bunx @biomejs/biome`, which resolves to 2.x and aborted on config
      parsing before linting anything. Migrated the config and fixed the four
      `useIterableCallbackReturn` violations that Biome 2.x newly reports.
- [x] `bin/performance` passes.
- [x] Every fix has a test that fails against the pre-fix code.
- [x] `Doctor` returns false on an empty directory.
- [x] The two `safe_url` bodies are asserted identical.
- [x] No `nokogiri` entry remains in the gemspec.
