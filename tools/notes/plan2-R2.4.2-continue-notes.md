# R2.4.2 — `-continue`: keep searching past the first violation

New ledger row `check-opt-continue` → **parity**. `result` and `violation` are
untouched.

## The row's own premise was wrong, and R2.4.0 had already proved it

R1.8.6 excluded `-continue` because *"one job yields one typed `result` on this
wire; a run that continued would have no single verdict to return."* The row
inherited that and called the decision "the unit".

There was nothing to decide. Measured at the pin, `-continue` prints EC 2110 per
violation and then **finishes**:

```
Error: Invariant Inv is violated.        <- depth 3
...
Error: Invariant Inv is violated.        <- depth 4
...
Model checking completed. No error has been found.
5 states generated, 4 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 4.
```

There is one verdict. What multiplies is the **counterexamples**. And note the
completion line prints *even though violations were reported* — it is about the
search finishing, not about the verdict, so the port renders it too.

## The measurement settled a question the row never asked

**The violating state is still enqueued.** The same spec reports at depth 3 and
again at depth 4, and depth 4 is only reachable *through* the depth-3 violator.
Without the flag the run stops at 3 generated / 3 distinct / depth 3; with it,
5 / 4 / depth 4 — the whole graph.

Had I implemented "record and skip" from the flag's description, the second
violation would never have been found and the counts would have been wrong. The
row said nothing about this; only running it did.

## Where the violations go, and why not on `result`

`result` and `violation` are **deliberately untouched**. The counterexamples
land in a new `%violations` artifact.

The reason is a budget one: `tlc-safety-invariant` records that **R2.7.1 is the
one unit meant to move `api-version`** — the EC 2107/2110 split, where a
`violation` learns whether it was an initial-state or a behaviour violation.
Putting a `(list violation)` on `result` here would have spent that budget
early, for a flag, and forced R2.7.1 to move it a second time. An additive
artifact variant costs nothing and leaves the contract where R2.7.1 wants it.

`bfs-cursor` carries **fingerprints, not traces**: the cursor is persisted and
bounded by `max-noun-bytes`, and every trace is rebuildable from `seen` at the
done boundary (`+viols-of`). Recording traces as they were found would have put
an unbounded amount of state into a persisted, size-checked noun.

## Three zuse-408 traps, all previously recorded, all still expensive

Worth re-recording because each cost a build cycle:

1. **A wet `turn` over the recursive `state` mold `fuse-loop`s the compiler.**
   Hit twice — once in `+render-outcome`'s violation blocks, once in
   `+finish-bfs`'s artifact build. Both rewritten as explicit loops, as
   `+subscript-warns` already was in R2.3.5.
2. **A `?=(^ ...)` guard narrows a list**, so a following `?~` in a loop is
   `mint-vain`. Widen with a fresh `=/ ws=(list ...)` first.
3. **A face named `trace` shadows the MOLD of that name**, so `^- [violation
   trace]` fails with `-find.$`. Renamed the loop's element face.

## Evidence

A matched pair in `tests/lib/job`: one bundle, run twice with only
`check-opts.continue` different.

| `continue` | result | counts |
|---|---|---|
| `|` | `%violated [%invariant 'Inv']` | 3 / 3 / depth 3 |
| `&` | **`%ok`** | 5 / 4 / depth 4 |

plus assertions that the artifact holds **two** violations and that their traces
are 3 and 4 states long — which is what proves the violating state stayed in the
queue rather than being skipped.

## Touched

`desk/sur/tla-lus.hoon` (`check-opts.continue`, `artifact` `%violations`),
`desk/lib/check.hoon` (`bfs-opts.cont`, `bfs-cursor.viols`, `+viols-of`,
`outcome` `%ok` viols, `+register-in`, `+bfs-init`, `+render-outcome`, 19 opts
literals), `desk/lib/job.hoon` (`+finish-bfs`, 3 opts literals),
`desk/app/tla-lus.hoon` (artifact write), `desk/tests/lib/job.hoon`,
`desk/tests/lib/clay-load.hoon`, `desk/tests/app/tla-lus.hoon`,
`desk/gen/tla-lus/submit.hoon` (check-opts literals),
`desk/doc/parity-manifest.md`, `desk/doc/compatibility.md`.
