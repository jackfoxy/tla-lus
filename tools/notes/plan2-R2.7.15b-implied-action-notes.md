# R2.7.15b — the implied-action bin: two frozen cases, four defects

```text
Sub-unit: R2.7.15b
Row: tlc-safety-assume (stays `partial` on ONE item)
Planned: two frozen cases -- the square action and the queue count.
Found: those two, plus two more the fix uncovered, both of which had made the
  first two invisible.
```

## (1) The square action — and DFID had it too

`[][A]_v` is `A \/ UNCHANGED v`. The port checked `A` alone, so a STUTTERING
step reported a violation tlc2 permits. Measured at the pin on
`[][x' = x + 1]_x` over a `Next` with an `x' = x` disjunct: BFS and DFID both
complete clean, and the port reported `Action property ActOk is violated.` on
both.

`+implied-action-parts` carries the SUBSCRIPT beside the body;
`+first-bad-action` (shared with DFID since R2.5) answers FALSE only when `A`
fails **and** the subscript changed.

The subscript is OPTIONAL in the graph — `+decompose-spec` guards it the same
way — and a missing one falls back to the old behaviour. **Recorded rather
than guessed**: comparing the whole state instead would over-report whenever
`v` is a strict subset of the variables.

New `gen-dfid-tests` case `act-stutter` pins it on the DFID side.

## (2) The queue count

`+register-in` checks invariants BEFORE the enqueue, so a violating state is
counted but never queued. R2.7.15a added the implied-action check *after*
`+register-in` returned, so the successor was already on the queue and
`prop-act-viol` reported `1 states left on queue` where the pin reports 0. The
check moved inside, to sit where the invariant check does.

## (3) EVERY transition, not every NEW state

Fixing (2) exposed this. The check sat after `+register-in`'s dedup guard, so a
REVISITED successor was never checked at all — and `implied-act-viol`
(`Next == x' = (x + 1) % 4`, violating on the 3 -> 0 step into a state first
seen at depth 1) reported nothing.

tlc2's own DFID comment says it: *"We need to do it even if succState is not
new"*. A revisited successor is still not counted or enqueued; only the check
is added, and its trace runs through THIS predecessor rather than the one that
first discovered the state.

## (4) The `oss` came from the head of the property list

The last one, and the reason `prop-act-ok` stayed red after (1) was fixed.
`+search-ctx` tested the FIRST property's shape and answered `~` for anything
not genuinely temporal — so a spec declaring an implied action first and a
temporal property second built **no OrderOfSolution at all**, and the liveness
engine had nothing to report even after R2.7.15a correctly routed the run to
it. It now normalizes the TEMPORAL BIN.

R2.7.15a moved the routing and left this one behind it: the same head-of-list
assumption, one layer down.

## Still owed — the row's last item

An IMPLIED INIT is routed only by the console `+check`. `+run-check` and the
job kernel compute `iinits` and do not check it. It cannot be folded into the
invariant vector: tlc2 checks an implied init only while computing the initial
states, and an invariant is checked at every state.

## Evidence

**374 arms, `ok=%.y`, 0 FAILED** across `mc` (100 cases), `dfid` (23),
`job`, `safety-gen`, `inv-constraints`, `trace`, `liveness-lasso`,
`liveness-message`, `liveness-verdict`, `cfg-runspec`, `clay-load`.
`gen-mc-tests.py`'s `SKIPS` is EMPTY again. Ledger unchanged at
**132 terminal / 2 owed**.
