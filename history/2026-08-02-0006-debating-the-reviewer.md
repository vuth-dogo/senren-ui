# 2026-08-02 00:06 - The Severity Label Is Also A Claim

A review summary arrived listing what was fixed and what remained. Rather than
read it and act on the ranking, every assertion in it was re-run. Two things
came out of that: one finding the reviewer rated Low was a complete bypass of
the gem's central protection, and one recommendation would have reopened a hole
the same reviewer had praised a round earlier.

## The one rated Low

The summary ended its minor-notes section with:

> **Predictable temp file name** (`<dest>.<pid>.tmp`). Requires write access to
> the repo directory to exploit — and at that point they could edit the files
> directly.

Run before accepting it:

```
write! -> completed                    # no exception
victim OUTSIDE root: "senren payload"  # a file outside the root, overwritten
```

`atomically` wrote to the temporary with `File.write`, which **follows a
symlink**. Containment inspected `target` and never inspected `tmp`. So a
symlink pre-placed at the temp path walked straight out of the app root with
every `SafeWrite` check having passed — through the module that exists to make
that impossible.

The dismissal was wrong on three counts:

1. **"Requires write access to the repo" is the premise, not an extra hurdle.**
   `SafeWrite`'s own comment states the threat model: *a repository you clone
   and run `senren:install` in.* The attacker controls repo contents by
   definition.
2. **"Could edit the files directly" conflates two different things.** Editing
   files *inside* the repo is what this module tolerates. Writing *outside* it
   is what it exists to prevent. `~/.ssh/authorized_keys` is not
   `app/components/foo.rb`.
3. **Git stores symlinks**, so a cloned repo can ship
   `.senren/registry.yml.<pid>.tmp` pointing anywhere. The pid space is small
   enough to ship candidates for, and re-running costs nothing.

Fixed with two independent layers, because either alone is thin: a
`SecureRandom.hex(12)` suffix removes the guess, and
`O_CREAT|O_EXCL` refuses to open an existing path at all and does not follow a
final symlink, so a lucky guess still fails. Mutation: reverted → 2 failures.

## The one the reviewer got right, including the caveat

`resolve_existing_prefix` walked up looking for an existing ancestor without
testing `symlink?`. A dangling link is invisible to `exist?`, so the walk
stepped over an intermediate one and rebuilt the tail lexically — reporting a
contained path for a write that would land wherever the link pointed.

The reviewer rated it Low and said plainly why it was not exploitable today:
every caller runs `mkdir_p!` on the parent first, and that catches it. Verified
— true. Fixed anyway, for the reason they gave: the safety rests on an implicit
contract that callers remember to call `mkdir_p!` first, and this cycle has
already broken two implicit contracts. Their proposed patch was right in shape
and went in nearly verbatim. Mutation: reverted → 1 failure.

## The recommendation that would have regressed a fix

For the in-repo symlink regression, the advice was:

> Only refuse when the link resolves outside the root, and then
> `ln -s AGENTS.md CLAUDE.md` works normally (**rename replaces the link**,
> content stays in the repo).

Two problems. "Rename replaces the link" is the wrong behaviour: the user made
that link deliberately, and replacing it with a regular file silently destroys
their setup. Resolving to the link's target and writing there keeps it —
`test_writing_through_an_in_repo_link_preserves_it` pins that.

And the obvious way to implement "resolve" is `realpath`, which fails on a
dangling link — the exact case the same reviewer had praised one round earlier
for being handled correctly via `File.symlink?`. Implementing their round-four
advice literally would have reopened their round-three approval. Reading the
**declared** target with `File.readlink` is what works either way, and that was
not mentioned.

A recommendation can be right in principle and wrong in the most natural
implementation of it.

## Smaller corrections

The duplicated-path-knowledge count drifted across rounds: "5 sites" first,
"3 files" in the final table. Grep says four files carry the name-derived shape
— `registry.rb`, `component_copier.rb`, `skill_writer.rb:135`,
`component_generator.rb` — plus `install_generator.rb` hard-coding directories.
The final table dropped `skill_writer.rb`. Not worth a fix, worth not using the
number as an effort estimate.

The architecture score moved 7 → 8.5 → 8 → 9 across four rounds. It is the
least useful part of a review: it fluctuates and it maps to no action. The
finding list with evidence is the part that does work.

Two claims checked and confirmed: `feedbacks/` is gitignored and absent from
`spec.files`, so that document stays local as it says. And a symlink cycle
(`a → b → a`) hits `MAX_LINK_DEPTH` and returns a path inside the root, so it
does not escape; the write then fails with the OS's `ELOOP`. Message quality
only — left alone.

## The fourth rule

Three were already recorded:

1. A check that has not been watched failing is not evidence.
2. Deleting the code that had a bug is not eliminating the bug — the bug lives
   in a shape.
3. A guard needs mutation tests in both directions; proving it says "no" does
   not distinguish a correct policy from one three times too wide.

This adds:

4. **A severity label is a claim, and needs verifying like any other.** The
   finding rated Low here came with reasoning that reads as sound and was
   wrong at every step. Had the ranking been trusted, a full bypass of the
   containment layer would still be in the code.

The practical form: run a probe for the low-rated items too, at least where they
touch a security invariant. §7.1 of the feedback file took one run to invert.

## State

```
bundle exec rake test   →  191 runs, 2,292 assertions, 0 failures, 0 errors
bundle exec rubocop     →  152 files, 0 offenses
bin/ci --matrix         →  8/8 gates, green on all four Rails versions
```

Still open, and agreed with the reviewer: finding 11 (duplicated path
knowledge), `recipes.yml` as dead surface, the upgrade story
(`senren:update` / `diff` / `outdated`), and `Senren::Rails` shadowing
`::Rails` with nothing enforcing it. None is a vulnerability.
