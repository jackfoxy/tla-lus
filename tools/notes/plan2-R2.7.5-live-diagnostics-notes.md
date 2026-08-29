# R2.7.5 — `tlc-live-diagnostics` — DONE 2026-08-29

Both named gaps shipped, plus a **third defect found while chasing the first**
that turned out to be the reason the first was hard. Measured against the pin
(`tlaplus@4ba7d8811`, `-fp 0`), repeatedly and at scale.

## The defect that gated everything: a closer tlc2 does not print

The port emitted `State N: Stuttering` where tlc2 ends the counter-example at
its last prefix state — in the **ordinary, no-error** temporal report, nothing
to do with the post-error block:

| | end of the counter-example for `[](x = 1 => [](x # 3))` |
|---|---|
| pin | `State 4: <Step …>` / `x = 3` → straight to the statistics |
| port (before) | … / **`State 5: Stuttering`** |

### The discriminator, and the one that looked right and wasn't

Measured across shapes on one 4-state spec, every property violated, running
`LivenessStruct` beside `tlc2.TLC`:

| property | tableau formula | box? | closer? |
|---|---|---|---|
| `[](x=1 => [](x#3))` | `<>(A /\ <>~B)` | no | **NO** |
| `<>(x=9)` | `[]~P` | yes | yes |
| `(x=1) ~> (x=9)` | `<>(A /\ []~B)` | yes | yes |
| `[]<>(x=9)` | `<>[]~P` | yes | yes |
| `<>[](x=9)` | `[]<>~P` | yes | yes |
| `[](x=1 => <>(x=9))` | `<>(A /\ []~B)` | yes | yes |

Clean separation on **`has-box` of the TABLEAU FORMULA**: when the negated
property carries no `[]`, the witness is pure reachability — a finite path,
nothing left to discharge in the limit — so no cycle is doing work and there is
nothing to close. `+box-free-tf`.

The near-miss worth recording: `+stutter-gate`'s `quiet` predicate does NOT
work here, and an earlier attempt at this unit used it and mis-classified every
`<>` property. `quiet` asks `has-box` of the **PROMISES** (tlc2's
`containsBoxInPromise`), and `<>(x = 9)` has **zero** promises — so a
promise-keyed test says nothing about it. Verified directly: the port prints no
2257/2259 hint for `<>(x = 9)` either. Same arm, same helper, different operand,
opposite answer.

### The corpus could not have caught it

Every **violated** case in `desk/test-data/liveness/` was a `<>`, `~>`, `[]<>`
or `<>[]`; the closer-free rows were all PASSING runs plus `box-state`, which
routes to the invariant engine. Eight byte-exact violation cases in
`liveness-message`, all of the shape that *does* take a closer. Same failure
mode as R1.3.8's `\X` and R2.4.6's two simulation defects: a construct with no
case at all, held at parity without ever being measured. New fixture
`boximplies-viol` (LivenessDump + struct + product goldens) and a tenth
`liveness-message` arm now pin it.

## Gap (a) — the second report block

The row said "after a deadlock". Measured, it is **not deadlock-specific**: an
INVARIANT violation gets it too. That also corrects the note R2.3.4 left at the
temporal console path ("an INVARIANT alongside a temporal PROPERTY prints … NO
temporal verdict") — true for the `<>` property that unit measured, false in
general.

Two conditions, both necessary:

1. **the state queue is empty at the error** — `Github710d` (deadlock, 0
   queued) and an invariant violation with 0 queued both print the block; the
   same specs with one state left on the queue do not. Stable from 4 states to
   20 001.
2. **the property's tableau formula is box-free** — the same `+box-free-tf`.
   Equivalently: tlc2 appends this block exactly for the counter-examples it
   would render *without* a closer, which is why the block has none.

Shipped as `+post-error-live` plus a `post` slot on `+render-outcome`, welded
before the counts in the `%inv` and `%deadlock` branches, with the numbered
prefix factored out of `+live-render` as `+live-prefix-lines`. Corpus:
`live-after-deadlock` (block), `live-after-deadlock-lasso` (no block — box
property fails condition 2), `live-after-deadlock-queued` (no block — fails
condition 1).

### One case is frozen, not passing, and says why

`live-after-inv` produces the **right block in the right place with the right
property name**, and a counter-example one state too long: the pin stops at
State 3, where `[](x = 0 => [](x # 2))`'s promise is fulfilled, and the port
runs to State 4 because the graph contains it. That is **lasso minimality** in
`+oos-lasso` (`tlc-live-lasso`, currently `parity`), not the post-error rule —
`live-after-deadlock` passes because there the witness ends at the last state
anyway. `gen-mc-tests.py` gained a `SKIPS` map (the idiom
`gen-core-eval-tests.py` already uses): the golden is captured and frozen, the
arm withheld, and the reason printed on every generator run so the residue
cannot go quiet. **No existing liveness case has a graph that extends past its
witness**, which is why this has never shown before.

## Gap (b) — warn-and-continue under model-value symmetry

**The engine blocker was stale.** Unit 8.7.2 recorded that "the port cannot yet
run liveness on that spec class (a model-value `\E` init/action — empirically
errors when the guard is relaxed)". Re-measured by relaxing the guard: the port
runs the `symmetry-live` fixture to

```
Model checking completed. No error has been found.
4 states generated, 1 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 1.
```

— the pin's verdict and the pin's counts exactly. Only the warning LINE was
owed. The claim predated R1.5.1's solver work and R2.4.6's `+get-actions`
rebuild, the two constructs it named.

Shipped: both rejections (`check.hoon` `+search-ctx-seed`, `job.hoon`
`+config-run`) become the EC 2279 warning on the existing `swarn` channel — the
one R2.3.5's EC 2145 subscript warning already uses, printed before the verdict
on both paths. `+live-message-lines` carries `swarn` too, or the shard could not
see it.

**The guard is keyed on a GENUINE temporal property, not on `pp`.** A `[]P`
box-state PROPERTY is folded into the invariant vector by `processConfigProps`
and never reaches the liveness checker, so tlc2 prints no warning for it —
measured on `Prop == []Inv` under `SYMMETRY Perms`: no warning, `ok`, 1
distinct. `tests/lib/symmetry`'s `test-symmetry-property-rejected` became
`test-symmetry-box-property-runs` and now asserts that.

## Hoon traps hit

- `=/ pp ?~(properties.ca ~ \`i.properties.ca)` infers a union with **no `u`
  face**, so `u.pp` is `-find.u.pp` however you narrow it. The mold annotation
  `(unit @t)` is what names the field; `job.hoon` already had it, `check.hoon`
  did not.
- A `|commit` can fail with `crud: %into event failed` and bury the real
  compile error hundreds of lines below the changed-file listing. Filter the
  clay frames out before reading.

## Owed, and deliberately not done here

The **`Github710d` census entry retirement**. `TLC_LIVENESS_DIVERGENCES` in
`tools/gen-tier2-tests.py` still reads `"Github710d -> Error: Deadlock
reached."` with the reason "the port's R1.6.6 pre-emption emits the deadlock
report alone" — which this unit made false. Retiring it means regenerating the
tier-2 comparator over the whole `tlaplus` test-model corpus, a long JVM run
that is its own operation; flagged rather than half-done. Until then the census
overstates a divergence that no longer exists.

## Evidence

`-test` over `liveness-message`, `liveness-verdict`, `liveness-lasso`,
`liveness-product`, `temporal-struct`, `mc`, `job`, `app`, `sim-live`, `trace`,
`spec-decomp`, `symmetry`, `coverage` — **314 arms, `ok=%.y`, 0 FAILED.**
