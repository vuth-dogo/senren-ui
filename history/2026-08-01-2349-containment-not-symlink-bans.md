# 2026-08-01 23:49 - The Guard Was Right, The Policy Was Too Wide

The symlinked-destination hole is closed. Closing it introduced a regression
that broke `senren:add` outright.

## The regression

`symlinked_segment` refused **any** symlink on the path, regardless of where it
pointed. But an in-repo symlink is ordinary:

```
ln -s AGENTS.md CLAUDE.md    # one set of agent instructions, two names
```

On a host with that, `senren:add button` did this:

```
senren:add            -> SafeWrite::Escape ... CLAUDE.md is a symlink
files copied first    -> ["base_component.rb", "button_component.html.erb", "button_component.rb"]
ledger written        -> true
```

Three things made it worse than it looks. It broke the **install** command, not
just `agents:sync`, because `ComponentInstaller#install` calls
`AgentRulesWriter`. It failed **midway**, leaving components on disk and the
ledger updated. And the message said *"is a symlink"* — security-flavoured
wording for a completely benign setup, with no hint what to do.

The evidence that this was an oversight rather than a decision is in the tests:
every symlink case in `safe_write_test.rb` used a link pointing outside
(`@outside`, `ghost`, `victim`). The in-repo direction had never been
exercised. The policy was written against escapes and the other direction was
never considered.

## The property was always containment

Nothing may escape the app root. That is the security property. "No symlinks
anywhere" is a much wider policy that happens to imply it, and the extra width
was all cost.

`real_target` now resolves a path to where a write would actually land, and the
only question asked is whether that is inside the root. It reads the
**declared** target with `File.readlink` rather than asking the filesystem to
resolve it, which is what keeps the dangling case decidable — `exist?` is false
on a broken link, so resolving only existing ancestors would clear the parent
directory and let the write land wherever the link pointed.

A consequence worth stating: writes go to what the link points at, so
`ln -s AGENTS.md CLAUDE.md` **survives** the install instead of being replaced
by a regular file. Respecting the user's setup, not just tolerating it.

## The conflict that is real, reported as itself

Once in-repo links are allowed, `AGENTS.md` and `CLAUDE.md` being one file
reaches `AgentRulesWriter` — which writes *different* content to each adapter,
so the last write silently wins.

That is a genuine conflict and it is refused. But it is refused as what it is:

```
Senren writes different instructions to each agent adapter, so these cannot
share a file: AGENTS.md and CLAUDE.md both resolve to /path/AGENTS.md. Replace
the link with a real file, or have one adapter reference the other by path
instead of linking to it.
```

And it runs as a **preflight** in `ComponentInstaller#install`, before the
copier. The first version of this check lived inside `sync!`, which runs after
the copier — so it still failed with components already written. Now:

```
files copied first    -> []
ledger written        -> false
```

## The last non-atomic write

`ensure_base_component_url_helpers!` used `File.open(dest, 'a')`. Containment
was fine — `refuse_symlink?` guards it — but it was the one write in the gem
that could be interrupted, leaving `base_component.rb` holding half a method
and an app that will not boot. It is the migration path onto the hardened URL
helpers, so it runs on apps that already have code worth not corrupting. Now a
read-modify-write through `SafeWrite.write!`.

`grep -rn 'File\.open\|File\.write\|FileUtils\.cp\|mkpath' lib/` returns
nothing outside `safe_write.rb`.

## Verification

Mutated in three directions and watched failing each time:

| Mutation | Result |
| -------- | ------ |
| refuse any symlink again (too strict) | 2 errors |
| stop following declared targets (too loose on dangling) | 1 failure |
| remove the preflight (fail mid-install again) | 1 failure |

Both directions matter. A test suite that only proves the guard refuses things
cannot tell an over-tight policy from a correct one — which is exactly how this
regression shipped.

One existing test had to change: it asserted the skip message contained the
word `"symlink"`. It now asserts the outcome and the path named, because the
policy is containment and the message should say where the write would have
gone, not that a link exists.

188 unit runs / 2,286 assertions, 32 integration runs, green on all four Rails
versions.

## The lesson, third instalment

Previously: *a check that has not been watched failing is not evidence*, then
*deleting the code that had a bug is not eliminating the bug*. This one:

**A guard needs mutation tests in both directions.** Every test here proved the
guard said no. None proved it said yes when it should. So a policy three times
wider than the property it protected looked exactly like a correct one — green
suite, clean lint, and a broken install command for anyone with an ordinary
symlink in their repo.

## Still open

Finding 11, duplicated path knowledge across three files with no
`ComponentPaths`. `recipes.yml` remains a dead surface. `Senren::Rails`
shadowing `::Rails` is still handled by discipline with nothing enforcing it.
The temp-file name is still predictable (`<dest>.<pid>.tmp`), which needs write
access to the repo directory to matter.
