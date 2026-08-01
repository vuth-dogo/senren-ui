# 2026-08-01 23:26 - The Fix That Carried The Bug Forward

A follow-up review of the remediation found a new Medium vulnerability. It was
introduced by one of the fixes, and it is the most instructive thing in this
whole sequence.

## What happened

Finding 04 was "a symlinked directory defeats containment". The fix added
`SafeWrite` and routed the writers through it. Containment was applied to
**directories**.

Finding 09 deleted the dead `Installer` class, whose `mirror_registry` did:

```ruby
FileUtils.mkdir_p(paths.registry_mirror.dirname)
FileUtils.cp(Senren::Rails.registry_path, paths.registry_mirror)
```

Finding 06 needed the registry mirror refreshed on every install. I wrote:

```ruby
SafeWrite.mkdir_p!(dest.dirname, paths.root, 'registry mirror')
FileUtils.cp(Senren::Rails.registry_path, dest)
```

The same shape. Guard the directory, then `cp` through whatever the
destination turns out to be. I deleted a method for a defect and then
reimplemented the defect two commits later, in a method whose commit message
was about something else entirely.

Reproduced:

| Target | Result |
| ------ | ------ |
| `.senren/registry.yml` → symlink outside | **OVERWRITTEN** |
| `.senren/installed_components.yml` → symlink outside | **OVERWRITTEN** (other keys preserved, Senren data merged in) |
| `CLAUDE.md` → symlink outside | refused |

`CLAUDE.md` was safe only because `AgentRulesWriter` happened to call
`assert_inside!` and then `File.rename`, which does not follow a symlink at the
target. Two writers were correct by construction, two by accident, and the
accident did not hold.

## Why the directory check was not enough

`assert_inside!` resolves the deepest **existing** ancestor. For a live symlink
that resolves outside, it does catch it. For a **dangling** symlink it does
not: `exist?` is false on the link, so the walk moves up to the parent
directory, finds that inside the root, and passes — and the write then creates
the file at the link's target, outside the app.

`symlinked_segment` uses `File.symlink?`, which does not follow, and walks the
whole chain including the leaf. That is the check that covers both.

## The fix

`SafeWrite.write!` and `SafeWrite.copy!`: assert the whole chain is
symlink-free and contained, write to a temporary, `rename` into place. Every
write in `lib/` now goes through one of them —
`ComponentCopier#copy_file`, `#update_installed_ledger`,
`ComponentInstaller#refresh_registry_mirror`, `SkillWriter#atomic_write`,
`AgentRulesWriter#atomic_write`.

The two that were already correct were converted as well, deliberately. Leaving
a hand-rolled `File.write` in place because it happens to be safe today is
exactly how this bug travelled from `Installer` into `ComponentInstaller`.
`grep -rn 'File\.write\|FileUtils\.cp\|mkpath' lib/` now returns only
`safe_write.rb` and two comments.

Also fixed: a ledger containing valid YAML that is not a mapping raised
`IndexError: string not matched` from `String#[]=`, which names neither the
file nor the problem. It now says which file is wrong and what to do.

## Verification

Each write path was mutated back to its unguarded form and watched failing:

- registry mirror → `FileUtils.cp`: 2 failures
- ledger → `File.write`: 1 failure

Both restored, then 183 unit runs / 2,267 assertions, 32 integration runs,
green on all four Rails versions, RuboCop clean.

The regression test pins all four destinations and the dangling-symlink case,
and asserts alongside them that an ordinary install still writes every one of
those files — a guard nobody can satisfy gets deleted rather than obeyed.

## The lesson

The previous entry ended with *"a check that has not been watched failing is
not evidence."* This one adds a second rule, and it is about fixes rather than
tests:

**Deleting the code that had a bug is not the same as eliminating the bug.**
The defect lived in a *shape* — guard the directory, then write through the
path — and the shape survived the deletion of the class that held it, because
I reached for the familiar two lines when I needed the same behaviour
elsewhere. The only durable fix was to make the unsafe shape unavailable: one
helper, every caller routed through it, and nothing left to copy.

## Still open

Finding 11, duplicated path knowledge across five sites, is untouched. It is
structural debt rather than a defect, and it is the same class of problem as
this entry — five places that must agree, with nothing forcing them to. Worth
doing before it produces its own version of this.
