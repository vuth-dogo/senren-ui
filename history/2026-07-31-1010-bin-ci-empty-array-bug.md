# 2026-07-31 10:10 - `bin/ci` Failed On Success

## The bug

Reported from a real run: `bin/ci` printed six green gates, printed the summary,
and then died with

```
bin/ci: line 61: failed[@]: unbound variable
```

so a completely passing run exited non-zero.

`bin/ci` runs under `set -uo pipefail`. Bash 3.2 — which is what `/bin/bash` is
on macOS, verified as `GNU bash, version 3.2.57(1)-release` — treats
`"${arr[@]}"` on an **empty** array as an unbound variable. `${#arr[@]}` on the
same array is fine. So the failure only appeared when nothing had failed: the
`for name in "${failed[@]}"` loop had nothing to print, and that is exactly when
it aborted.

Reproduced directly before fixing:

```
$ /bin/bash -c 'set -uo pipefail; arr=(); echo "${#arr[@]}"; for x in "${arr[@]}"; do :; done'
0
/bin/bash: arr[@]: unbound variable
```

Fixed by guarding both summary loops with a length check rather than expanding
the arrays directly. `bin/matrix` was checked and is not affected: it only
expands `${failed[*]}` inside the branch reached when the array is non-empty.

## Why I did not catch it

I verified `bin/ci` several times and every run looked green, because I piped it
through `grep` to trim the output. The pipeline's exit status is grep's, so the
script's non-zero exit was invisible. The tool I used to check the work hid the
thing I was checking for.

The fix is verified the other way round: run it, capture `$?`, print it. Both
paths were exercised under `/bin/bash` explicitly —

- all gates passing: exit 0, no error, `==> CI passed`
- two gates forced to fail: exit 1, both listed, `==> CI failed: 2 of 6 steps`,
  and the run continued past the first failure, which is the behaviour the
  rewrite existed to provide

## The regression guard, and the two attempts it took

`test/bin_scripts_test.rb` now asserts that no shell script in `bin/` running
under `set -u` expands an array that can be empty without a nearby length check.
It also checks the scripts are executable and parse under `bash -n`.

The first version of the rule **did not work**, and only testing the guard
revealed it. It asked whether `${#failed[@]}` appeared *anywhere in the file*.
`bin/ci` legitimately uses that further down for its exit status, so with the
bug deliberately reintroduced the test still passed — a guard that guards
nothing, which is worse than none because it manufactures confidence.

The second version scopes the check to the five lines preceding the loop. That
caught the reintroduced bug, but also flagged `bin/matrix`, where
`RAILS_VERSIONS=("7.1" "7.2" "8.0" "8.1")` can never be empty. The final rule
only considers arrays initialised as `name=()`, which is precisely the shape
that can be empty.

Verified in both directions, three times: clean tree passes with no false
positive on `bin/matrix`; bug reintroduced is caught and only `bin/ci` is named;
restored tree passes again. The rule itself is also unit tested against a known
bad and a known good snippet, so it does not depend on the current contents of
`bin/`.

`shellcheck` would have caught the original bug and is preinstalled on GitHub
runners, but it is not available locally, so it was not added — a gate that
cannot be verified here is the same mistake in a different costume.

## Validation

`/bin/bash bin/ci`, exit code checked rather than inferred:

- exit 0
- 132 unit runs / 2080 assertions
- 16 system runs / 305 assertions
- RuboCop 137 files, no offenses
- JavaScript checks clean, performance budgets pass, no vulnerabilities
- zero `unbound variable` errors in the captured log

## Note

This is the third time in this session that a check was wrong rather than the
code: a test pinning the vulnerable `!url.startsWith("//")` shape, an
adversarial test asserting the `example.com` → `https://example.com/` rewrite
that turned out to be the bug, and now a guard that inspected the whole file
instead of the loop. Verification is code, and code has defects; the only way to
find them is to make the check fail on purpose and watch.
