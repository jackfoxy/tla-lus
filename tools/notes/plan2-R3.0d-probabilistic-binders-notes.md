# R3.0d — the probabilistic half, and the one line that decided it

```text
Sub-unit: R3.0d (the row R3.0c deliberately left)
Row: check-mode-generate -> `parity`. THE LEDGER IS CLOSED: 134/134, 0 owed.
Planned: measure whether `SubsetEnumerator` reseeds on `reset()`, because the
  answer decides the RNG call sequence; then reuse the exhaustive odometer.
Found: it does not reseed -- `reset()` is `i = 0` and nothing else -- which
  turns the whole problem from a stream into a walk over fixed permutations.
  And the universal is not randomized at all.
```

## 1. The measurement

```java
@Override
public void reset() {
    i = 0;
}
```

`EnumerableValue.SubsetEnumerator.reset()`. It rewinds the counter and touches
nothing else: the seed `index`, the multiplier `a`, the modulus `m` and the
increment `c` are all drawn in the CONSTRUCTOR and survive.

Three consequences follow, and together they are the unit:

* **Every RNG draw happens up front.** Two per enumerator — `nextInt(n)` for
  the seed and `nextPrime(random)` for the increment — which is exactly what
  `+subset-indices` already reproduced for one group.
* **They happen in GROUP ORDER.** `Tool.contexts(Ordering.RANDOMIZED, …)`
  walks the bound groups and constructs one enumerator each. (It interleaves
  domain evaluation with construction, but evaluating a domain consumes no
  randomness, so drawing after all domains are evaluated is the same
  sequence.)
* **Enumeration consumes nothing.** An inner group REPLAYS its permutation on
  every carry of the odometer.

So the port does not need a lazily-reseeding stream. It draws every group's
permutation once and walks a fixed table — which is why this unit is small,
and why guessing would have made it neither small nor right.

## 2. What was built

* `+draw-orders` — one permutation per group, drawn in group order, threading
  the enumeration generator's state.
* `+order-rows` — `+bind-rows` with each group walked in its drawn order
  instead of its enumeration order. Index 0 still advances first, so the
  LEADING binder varies fastest, exactly as in the exhaustive path.
* `+prow-items` — the deferred-conjunct builder over ROWS of a product rather
  than elements of one group.

Both quantifier sites reuse `+bound-domains` from R3.0c, so the two facts that
unit measured — every domain evaluated in the OUTER context, leading binder
fastest — are stated once and used by both engines.

**`$BoundedForall` is not randomized, and that is measured too.** tlc2 calls
the plain `contexts(pred, …)` — `Ordering.NORMALIZED` — takes the FIRST context
now and defers the rest onto the ActionItemList. So the universal reuses
`+bind-rows` with no draw at all, consuming no randomness. Had it been given
`+order-rows` "for symmetry", every seeded trace in the corpus would have
shifted.

## 3. Why the evidence is a seeded differential and nothing else would do

An ordering bug does not change WHICH successors exist, only which one a
`-generate` run reaches first. A verdict comparison cannot see it; a state
count cannot see it. `gen-generate-tests` compares the **exact seeded
behaviour** against `tlc2.TLC -generate num=1 -workers 1 -seed S`, so a wrong
draw order, a reversed odometer or one extra RNG draw all show up as a
different trace.

Two cases added, three seeds each — **24 → 30 exact-trace cases**:

* `exists2` — `\E n \in 1..3, m \in 1..4 : x' = (x + n * m) % 100` under a
  conjunction, so `getActions` leaves the quantifier for `getNextStates`.
* `forall2` — a multi-binder `\A` filtering beside a randomized `\E`, which is
  the shape that catches a universal that wrongly consumes randomness.

All 30 byte-identical. `sim-diff` (82), `sim`, `sim-live` and `sim-stats` are
green as well, because `-simulate` shares the site — the second trap R3.0d's
row named, and the reason the evidence is both engines rather than the one the
refusal message happened to list first.

## 4. The trap the row named, and it was real

`release-gate.sh` R4 checks refusals **both ways**. R3.3.2 had just added the
two probabilistic multi-binder messages to `compatibility.md`'s table; deleting
them from the code without deleting the table rows would have failed the gate
in the opposite direction from the one that motivated documenting them. Both
rows retired here, and the check reports **0 undocumented, 0 stale**.

## 5. State

**The ledger is closed: 134 rows, 134 terminal, 0 owed.** Every in-scope row is
`parity`, a tested `approved-difference`, `replaced` or `excluded`, for the
first time since R2.0 re-opened it on 2026-08-23.

Remaining: **R3.3.3** — the full ship suite, and `r3-acceptance.py --suite-log`
fed the captured output.
