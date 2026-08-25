# R2.6.3 — TLCExt, non-debugger operators

Five surfaces: `AssertEq`, `AssertError`, `TLCCache`, `TLCDefer`, `TLCNoOp`.
R2.6.0 had already cut this list down (it removed `AssertEq` as work and moved
`TLCGetOrDefault`/`TLCGetAndSet` out); this unit built the rest.

## What each one turned out to be

| operator | shape | why |
|---|---|---|
| `TLCNoOp(v)` | `v` | the pin is literally `return val;` — it exists to defeat constant folding, which this evaluator does not do |
| `AssertError(err, exp)` | evaluate `exp`, branch on failure | a `try/catch` in the pin; here `eres` already returns a failure as a VALUE, so "catching" is branching on `%|` |
| `TLCCache(expr, closure)` | evaluate `closure`, then `expr` | memoization of a pure expression is the identity: the pin caches on the expr node (constant level) or on `s0` (variable level) and returns exactly `expr`'s value either way |
| `TLCDefer(exp)` | TRUE, without evaluating `exp` | see below — this is what tlc2 does under BFS |
| `AssertEq(a, b)` | its vendored TLA+ body | no Java override at all |

`AssertError` checks `err` **syntactically**, as `assertError` does with
`Assert.check(args[0] instanceof StringNode, ...)` — a computed string is
rejected even though it would evaluate to one.

`TLCCache` still evaluates `closure`, because the pin evaluates it to build the
cache key before it decides anything. A `closure` that fails must fail the
operator here too, rather than being skipped on a cache hit this engine has not
got.

## `TLCDefer` — measured, not assumed

`TLCDefer` sets a callable on the state via `TLCState.setCallable`. **Who runs
that callable decides the whole behavior**, and only two classes do:
`SimulationWorker` and `ExplorationWorker`. `ModelChecker` does not.

Measured at the pin with `TLCDefer(PrintT(<<"deferred", x>>))`:

```
BFS:        (nothing printed; 3 states, deadlock, otherwise unchanged)
-simulate:  <<"deferred", 0>>  <<"deferred", 1>>  ...
```

So **TRUE-without-evaluating is not an approximation under BFS — it is tlc2's
behavior**. Under simulation the callable does run, and this engine has no
post-step hook to run it in, so that case is refused BY NAME. `tlc-run` gained a
`sim` flag for the purpose, set by the simulation path.

## Two things the corpus caught that reading had not

Both were found by writing `desk/test-data/mc/tlcext-ops` — one spec whose
invariant exercises all five operators — and running it.

1. **The invariant check had no run statistics.** R2.6.1 wired `TLCGet`'s
   statistics into the *next-state* evaluation and stopped there. An invariant
   is evaluated on a different path (`+register-in`), so
   `TLCGet("distinct")` inside an INVARIANT raised EC 2145. Fixed by building
   the env there too, with the counters read *after* the state is entered —
   which is where tlc2 reads them, since it checks the invariant immediately
   after `setStatus`. `+check-pruned` got the same treatment, with the
   statistics standing *before* the pruned state, since a pruned state is
   never counted.

2. **`AssertEq` needed a second allow-list, and R2.6.0's claim was half right.**
   R2.6.0 said `AssertEq` needs no native operator because it is a `body`. True
   of the pin — but the port has *two* gates, and R2.6.0's analysis only implied
   the first:
   - `+body-ok` in `lib/stdops` — the operators whose vendored definition is
     the behavior. Adding `AssertEq` here got past the "unsupported operator"
     refusal.
   - `+body-modules` in `lib/semantic` — the modules whose vendored bodies are
     **generated at all**. Every other standard module's bodies are the dummies
     TLC overrides, so generating them is wasted work. `TLCExt` was not in it,
     so the definition existed with no body and every use failed
     `operator has no evaluable body: AssertEq`.

   The second gate is the one worth remembering: a `body` classification is not
   self-executing, and the two lists are guarded against drift by
   `tests/lib/stdops` precisely because they can disagree.

## `class` moved, not just `r2-scope`

R2.6.0 set the `r2-scope` column for these five but left `class` at the
module-level `excluded` default. That default is what produced the wrong split
in the first place, and leaving it would have meant `inventory.txt` saying
`excluded` about operators `lib/stdops` implements. `CLASSIFY` now carries a
per-operator entry for each: `AssertEq` → `body`, the other four → `required`.
The counts moved `body 2 → 3`, `required 47 → 51`, `excluded 78 → 73`, and the
`R2.6.3` scope bucket is now empty because all five read `in:already ported`.

## Evidence

- `desk/test-data/mc/tlcext-ops` — one spec, all five operators in its
  invariant, including **both** `AssertError` paths (a non-matching message
  returning FALSE, and the pin's exact `The second argument of \div is 0.`
  returning TRUE). Byte-exact against the pin.
- `tests/lib/stdops` row-count guard updated 37 → 38 (`TLCNoOp` is the only
  plain registry row; its three siblings are `@Evaluation` node-ops and
  `AssertEq` is a body).
- Shards green: mc (32), stdops, stdops-diff, tlcmod, core-eval, sem,
  node-eval, stream, safety-gen, modres, cfg-val, job, trace, inv-constraints,
  sim-diff.

## A note on the ship, not the code

This unit could not be built at all for a while: `|commit` died
`recover: dig: meme` even on a freshly restarted pier. It was not the change —
reverting R2.6.3 entirely reproduced it. The dev pier's snapshot had grown to
**2.0 GB against a 2 GB loom**. `|meld` in-dojo crashed the serf. The fix was
`--loom 33` (8 GB) at boot, after which everything built first time. Recorded in
[[tla-lus-dev-environment]].


## An unrelated gate failure, fixed in passing

The scaffold gate went red on `regen.sh --check`, and it was **nothing to do
with this unit**: the host JDK moved `11.0.31` → `11.0.32`, and TLC prints the
JVM version in its startup banner, which 6 of the 14 baseline goldens pinned
verbatim. The oracle is unchanged; only the machine is.

`regen.sh`'s normalizer already elides the build, seed, pid, heap sizes, cores,
timings, temp paths and metadir. It now elides the JVM version too
(`, <Word> <version> 64bit` → `, <JVM> 64bit`). The regenerated diff is exactly
six lines, `Ubuntu 11.0.31` → `<JVM>`, and nothing else — a normalization, not a
weakened golden.

Worth noting because the first attempt got it wrong in an instructive way: the
pattern required a closing paren after `64bit`, which only one of the six banner
lines has (the others continue `, MSBDiskFPSet, DiskStateQueue)`). That wrote
the *new literal version* into five goldens instead of the placeholder —
silently swapping one pinned environment string for another. Caught by diffing
the regeneration rather than trusting it, reverted, and redone.
