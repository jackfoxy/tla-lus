# R3.3.3 — R3 ACCEPTED

```text
Sub-unit: R3.3.3 (R3 close-out, last)
Rows: none touched
Planned: the full ship suite (the user's to run), fed to
  `r3-acceptance.py --suite-log`, since omitting the clause FAILS it.
Result: 5/5 clauses hold. R3 ACCEPTED. The project's ledger is closed and
  asserted for the first time since 2026-08-23.
```

## 1. The verdict

```
  HOLDS  every ledger row terminal, none owed
           134 rows, 134 terminal, 0 owed
           (parity 99, approved-difference 10, replaced 6, excluded 19)
  HOLDS  every tier-2 census empty, no mc arm withheld
           all 7 frozen divergence lists empty and gen-mc-tests SKIPS empty
  HOLDS  docs coherent with the ledger and the tree
  HOLDS  release gate passes
           RELEASE GATE: PASS
  HOLDS  full ship suite green
           all-tests-pass.txt: ok=%.y, 2179 arms OK, 0 FAILED
  REPORT tier 3 (performance)  -- read, not gated (R2.8.1a)

5/5 clauses hold.   R3 ACCEPTED.
```

The suite log was checked for what it actually covers before it was fed in, not
just for its verdict line: **2179 arms**, including `tier2` (13 comparator arms:
the SANY curated set, `test-tlc-batch`, `test-tlc-liveness-batch`,
`test-tlc-examples-batch`) and `tier2-sub`'s six chunked SANY arms, **`mc` at
106** (105 plus `rec-fcn-eq`, unskipped by R3.2a) and **`generate-diff` at 30**
(24 plus R3.0d's `exists2` / `forall2` at three seeds each). A green verdict
over a suite that skipped this unit's own work would prove nothing.

## 2. Tier 3, reported and not gated — and a hypothesis that was wrong

The report run against the ship on 2026-09-05:

```
workload     now ms   base ms    delta  base spread
enum         2618.4    1908.7    37.2%        16.7%
eval         2626.1    1876.0    40.0%         6.1%
fp           3799.2    2677.4    41.9%         5.9%
live         1590.0    1106.0    43.8%         7.8%
queue        3175.7    2135.7    48.7%         6.3%
```

Every workload well outside its own baseline spread, so this was not left as
"noise, probably". **There was a concrete suspect**: R3.2a had put a `fcn-like`
test at the TOP of `+vlth`, so every `%seq`-vs-`%seq` comparison materialized
two pair lists through `+fcn-pairs` where it used to run a direct `+list-lth` —
and `+vlth` is called on every set sort and dedup.

**Tested, and the hypothesis was wrong.** Restoring the same-kind fast path
(cross-representation only when the kinds actually differ) and re-running moved
nothing: the deltas came back 37.2 / 40.0 / 41.9 / 43.8 / 48.7 against 37.2 /
40.0 / 44.3 / 39.7 / 38.8. The slowdown is environmental — load average 4.3
with a second pier running alongside a browser and an editor — which is exactly
what R2.8.1a measured when it decided report-only, and exactly why a threshold
here would have failed this run for being on a busy machine.

The fast path is **kept** regardless: it is strictly less work and provably
equivalent (a tuple's domain is 1..n on both sides, a record's is its keys in
`strlth` order, so same-kind pairs compare identically either way).
`value`, `fp`, `core-eval`, `bags`, `stdops-diff`, `mc` and `stream` are green
with it.

## 3. Claims retired

Per R3.3.1's rule — *a number or state in the present tense is a claim* — three
sentences stopped being true the moment the gate went green, and are corrected
here rather than left for a reader to trip over:

* `parity-manifest.md`'s header said the gate FAILS and `R1 NOT ACCEPTED` holds
  "for the whole of R2". Now: closed again 2026-09-05 by R3.0d, with the
  numbers. It also records that **R2 never wrote an `r2-acceptance.py`** —
  R2.8.2b re-opened three rows on its last unit and handed them to R3 — and
  that `r1-acceptance.py` still prints `R1 NOT ACCEPTED` **correctly**, because
  the ledger it asserts is not the one R3 closed.
* `testing.md`'s gate table said the release gate "fails by design for the whole
  of R2", and pointed acceptance at `r1-acceptance.py`. Now: PASSES as of
  2026-09-05, acceptance is `r3-acceptance.py`.
* `compatibility.md`'s ledger row now carries the assertion, not just the count.

And one paragraph added, because it is the lesson this close-out actually
taught: **a gate that fails on purpose stops being read.** `release-gate.sh` was
red from R2.0 until R3.0d, and behind the one clause everybody knew about, two
others had rotted unseen — a `TODO` token in a comment, and eleven refusals
missing from the table. R1.8.8 found that a gate nobody runs is not a gate; this
is the sibling, and the habit it asks for is to read a red gate's OTHER clauses
every time.

## 4. What the project ends with

**134 ledger rows: 99 `parity`, 10 tested `approved-difference`, 6 `replaced`,
19 `excluded`. Zero owed.** Every differential census empty, no test arm
withheld, tiers 1 and 2 reproducing byte-identically from the pinned oracle,
tier 3 reported, and 2179 suite arms green on the ship.
