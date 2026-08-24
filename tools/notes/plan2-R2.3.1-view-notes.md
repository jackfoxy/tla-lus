# P2-R2.3.1 — VIEW: fingerprinting through a view function

`cfg-view` reaches `parity`. Ledger **16 → 15 owed**.

## R2.3.0's measurement held

The engine work was one insertion point, as measured. `+orbit-fp` already
returned `[fp canon]` — and `canon` is Java's `minVals`, the symmetry
representative the view is evaluated on — so the composition needed no new
ordering logic:

```
canonicalize under the symmetry group   →   evaluate the view on that   →   fingerprint the value
```

`+view-fp` is `+fp-value` under a name that says why it exists. The identity
site in `+register-in` picks one or the other, and a view that fails to evaluate
falls back to the plain fingerprint rather than silently conflating states.

## The differential is a matched pair, and that matters

`view` and `view-off` are the *same module and config*, differing only in the
`VIEW Vw` line. The pin answers **3 distinct** with the view and **6** without.

That pairing is the point: a single fixture asserting "3 distinct" would pass if
the view were ignored *and* the state space happened to be 3. The pair proves
the view is what collapses the states. Both reproduce byte-for-byte on the first
run.

## One combination stays refused, and the reason is load-bearing

VIEW with a temporal `PROPERTY` is still a typed rejection. Measured:

- `build-graph` keys the reachability graph through `+orbit-fp` (now
  view-aware, since it reuses `+bfs-step`);
- but `liveness.hoon` recomputes **plain** `state-fp`s in `+succ-fps` (line 91)
  and `+trace-graph` (600) and looks them up in that graph.

Under a view those disagree, and `+succ-fps` would silently drop every successor
— an empty edge set, not an error.

**That mismatch already exists for symmetry**, and has never fired only because
symmetry+liveness is itself refused (`tlc-live-diagnostics`, the pinned 2279
text). So an existing approved difference is quietly holding up the correctness
of an unrelated arm. Worth stating plainly, because the next person to lift the
symmetry rejection needs to know it, and R2.7.5 is exactly that unit.

R2.3.1 therefore *narrows* the VIEW rejection rather than dropping it. The
honest cost is one refusal replaced by a smaller one.

## What R2.2's lesson cost here

Four `bfs-opts` literals were missed by my first pattern sweep, and the failures
were invisible for several cycles because **a failing `|commit` lands nothing**
— Clay keeps the last good revision, so the desk kept serving an 11,163-byte
`mc.hoon` while the pier had 12,247, and every "green" shard I read was the old
build. The tell was Clay's own file size, not the test output.

Two habits to keep: after changing a widely-constructed mold, sweep for
constructions by *shape* (`grep -c` the field, compare to the literal count)
rather than by pattern-matching known forms; and when a result looks
inexplicable, ask Clay what it actually holds before trusting a shard verdict.

## Verification

- `gen-mc-tests` 14 → 16 cases; `mc` shard green with both new arms.
- `tests/lib/job`: `test-view-refused-not-ignored` is **superseded** — VIEW now
  works — and replaced by `test-view-collapses-states`, which asserts the
  collapse through the kernel (`[%ok [3 2 0 2 …]]` for a 4-state cycle under
  `x % 2`). Same supersession R2.2 did to R2.1's `allow-write` refusal test.
- Shards green: `mc`, `job`, `liveness-verdict`, `sim`.
- The refusal table matches the code in both directions (release-gate R4).
