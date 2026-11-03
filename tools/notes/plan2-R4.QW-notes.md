# R4.QW notes — MCInnerSerial (2026-11-01)

Plan `~/FoxyLabs/tla-lus/R4-perf-plan-r3.md`, unit QW ("lazy witnesses;
measure the memo hypothesis first"), with R4.Q1b measured first.

## Q1b (dispatch table, H12): measured, no change

A ship-only fast path moving `$BoundedExists` (≈40th in
`+eval-builtin-rs`'s chain) to first left p08 (`\E j \in {k} : TRUE` ×
20,000) at 5.34–5.61 s against 5.49–5.54 s. The cord comparisons cost less
than the noise. Arithmetic and comparison operators are not builtins: they
resolve through `+eval-user`, where Q1 already added the module precheck.

## Where an MCInnerSerial expansion went

`Serializable' == \E R \in totalOpOrder' : ...` and
`totalOpOrder == {R \in SUBSET (opId \X opId) : total /\ transitive /\
irreflexive}`. For 3 operation ids that is 2^9 subsets, for 4 it is 2^16.
Per subset the predicate costs ≈2.5 ms (totality) + ≈8 ms (transitivity),
the general per-node cost (≈110 µs per `<<oi, oj>> \in R`). A probe
(`zprobe/q4/tw`, 4 ids, the 2^16 build alone) runs past 300 s; tlc2 runs
the whole probe model in 1.3 s.

1. **The build was repeated for every candidate.** `+eval-domain` descends
   into a zero-arity definition's body to keep it lazy, and a `$SubsetOf`
   body is then materialized anyway, without the memo `+eval-user` gives.
   So `totalOpOrder'` was rebuilt for each candidate `opOrder'` of an
   expansion. Now `+eval-domain` descends only into a body that stays
   lazy (`+lazy-set`); anything else is evaluated through the reference.
   Early expansions: 11 s → ≈1 s each, with the same counts at every step.
2. **The memo key was the whole `opQ'`.** `totalOpOrder` reads the state
   only through `opId`, which depends on the queue lengths alone. The key
   is now the VALUES of the arity-0 definitions a body names, whenever
   every state read in its reach goes through them (`+dep-vals`,
   `+reach-stop`, `+top-names`; the values are bound in `vals`, which
   `+eval-user` reads first). Exact: the body sees what it would have
   computed. Not used when one of them draws or fails, or is already a
   value. The first 115 expansions took 1,175 s, now 532 s; the step run
   reaches 195 distinct (the pin) within its cap. Arm
   `test-memo-keyed-on-dependency-values` (pins 5/4/4 and a violation).

Lazy short-circuiting of `\E R \in {R \in SUBSET S : P}` (tlc2's
SetPredValue) was not needed once the build is shared: one build serves
every candidate, where a lazy witness would re-test subsets per candidate.

## Through the agent

| wall | result |
|---|---|
| 1,200 s (after 1) | `limited time`, 173 distinct / 2,054 generated |
| 1,800 s (after 2) | `limited time`, **195 distinct** / 4,443 generated, 26 queued |
| 3,800 s (after 2) | **success 2,393 s: 6,181 generated / 195 distinct / depth 5 = pin** (3.2× tlc2's 12.5 min; target ≤ 5×) |

The arm bites: with the states dropped but the values not bound it fails
(`variable is unassigned in the current state: x`).

## Gates and census

Regression 65/65 (`logs/qw-regress1.txt`); validate, scaffold-gate,
test-examples PASS. Census `logs/census-qw.txt` (16 rows) against
census-q7: every count unchanged, times within noise
(AsyncTerminationDetection 210 → 154 s, TLCSailfish2 215 → 167 s:
census-q7's slow first-after-rebuild runs).

## For Q9 (r3 decision 1)

MCInnerSerial completes in ≈40 min, so option A (a per-model wall of 5×
tlc2, ≈63 min) is enough for clause 3.
