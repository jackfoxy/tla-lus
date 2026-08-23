# P2-R2.0 — ledger re-opening + baseline measurement

Docs and ledger only; no engine change. R2.0 does three things: measure each
claim R2 is about to schedule work against, re-status the rows R2 brings into
scope, and write down that the release gate now fails on purpose.

## The ledger is red, deliberately

| | R1 close | after R2.0 |
|---|---|---|
| rows | 125 | **127** (`cfg-view`, `cfg-alias` created) |
| terminal | 125 | 110 |
| owed | 0 | **17** |

15 rows re-statused, 2 created. `release-gate.sh` gate R1 now FAILS and
`r1-acceptance.py` prints `R1 NOT ACCEPTED`, and both will for the whole of R2.
That is recorded in three places a reader actually hits — the ledger's own
header, `testing.md`'s gate table, and `compatibility.md`'s release matrix —
each saying the same thing: **do not edit `r1-acceptance.py` to make it pass.**
It is the record of what R1 proved. R2 gets its own script at R2.9.

## Measurement corrected two of R2's own size estimates

The standing rule applies to the plan I wrote three messages ago as readily as
to a residue sentence from R1.0. Two were wrong, both **low**:

**`tlc-dfid`, M → L.** DFID is `DFIDModelChecker` (807 lines) + `DFIDWorker`
(246) + its own fingerprint-set family `FPIntSet`/`MemFPIntSet`/`MultiFPIntSet`
(683) — ~1,736 lines. Two facts scope it, and neither was in the plan:

- DFID **does not support liveness** and refuses explicitly
  (`DFIDModelChecker.java:67`, upstream issue 548). It is safety-only, so no
  liveness row is affected — which makes the unit narrower in one direction.
- It needs a **different visited set** — a fingerprint carrying a level, not the
  BFS `FPSet`. And `fp/dfid` is in-memory, so `tlc-fp-disk`'s performance-only
  exclusion does not cover it. That is the part that makes it L.

**`tlc-coverage`, M/med → L/high.** tlc2 threads `CostModel cm` through 49
signatures in `Tool.java` alone (433 references). The port looked cheaper: its
`eenv` is already threaded through `node-eval` (90 references) and already
carries a per-eval counter, `fuel`. But that similarity is a trap —

> `fuel` **decrements downward**; coverage counts **accumulate upward**.

Hoon has no mutable counter, so a coverage count cannot ride the `eenv` channel:
every eval's *return* type has to carry it. That is cross-cutting through the
evaluator, and it is the whole cost of the unit. Worth catching before the unit
was scheduled as a medium.

## VIEW and ALIAS had no ledger rows at all

Only `tlc-driver` mentioned them. That is *why* R1 could carry them as typed
rejections with nothing tracking the capability — and it is the same structural
gap R1.9.1 found for approved differences (argued in prose, indexed nowhere).
`cfg-view` and `cfg-alias` now exist, `absent`, each recording the split R1.8.6
measured:

- **`cfg-view`** — the *validation* half is already at parity (EC 2229/2233/2228
  with the role string `view function`). What is absent is the engine half:
  tlc2 fingerprints the VIEW's **value**, so a VIEW changes `distinct` counts
  and can change termination.
- **`cfg-alias`** — an *asymmetry that must be preserved*: `getAliasSpec` runs
  only when a trace prints, so tlc2 accepts an **undefined** ALIAS at config
  time. `val-alias-undef` asserts `ok` precisely so a later "make them
  symmetric" cleanup cannot over-validate it.

## Two exclusions reversed, and why that is not an admission

`tlc-util-combinatorics` and `tlc-module-excluded`'s `Randomization` slice were
excluded by R1.8.0 with a measurement that **still holds**: `Combinatorics` is
reachable only through `Randomization` and through never-constructed
`KSubsetValue`. Excluding it was correct *while `Randomization` was excluded*.
R2 brings `Randomization` in, so its only live consumer returns.

That is a scope change making a correct call obsolete — not a bad call being
undone — and the row says so, because otherwise the next reader sees a reversal
and distrusts the original measurement.

## `allow-write`, confirmed by measurement

R1.0's row said "the flag is ignored". Measured: **`allow-write` is read by no
Hoon file at all.** It is not ignored by decision; it is never consulted. The
agent has no Clay write path anywhere — no `%c %info` in `app` or `lib`. So the
last silent option on the wire is silent by omission, which is the weakest
possible form of "documented non-support".

## The support matrix kept its withdrawn rows

Seven rows moved from `approved-difference` to `partial`. Their entries stay in
`compatibility.md`'s support matrix, marked ⟶ **R2**, because *that argument is
still the best statement of what the difference is* — and R2 has to close
exactly what it describes. `check-portmap.py` check 5 still passes: it asserts
every approved-difference row appears, and all six that remain do.

## Verification

Docs and ledger only, so the required tests are the checkers, not the ship:
`check-parity.py` well-formed at 127 rows / 17 owed, and `check-portmap.py`
clean — the latter after it **caught the stale tally itself**, failing with
`compatibility.md quotes owed=0, computed 17` until the release matrix was
updated. The check R1.9.1 widened did its job on its first real test.
