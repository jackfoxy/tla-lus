# R2.8.2a — the census refresh, and the selection rule it owes .2b

```text
Sub-unit: R2.8.2a
Row: tlc-live-diagnostics (already `parity`; its clause is discharged here)
Planned: regenerate the whole tier-2 census, retire the stale `Github710d`
  divergence, add the drift guard, and OUTPUT .2b's selection rule.
Found: the stale claim was NOT in the constant the row named -- that was
  already empty -- but in the PROSE, in two live places. And the selection
  rule's answer is "add nothing", which is an answer .2b's own row provides
  for.
```

## 1. The regeneration is a NO-OP, and that is now measured

`tools/tier2.py --check` regenerates the inventory, the curated oracle capture
and both comparator shards from the pins and fails on any drift:

```
tier-2 differential integrity: OK — inventory + curated oracle + comparator
shard reproduce byte-identically from the pins.
```

`git status` over `desk/test-data/tier2/`, `tests/lib/tier2.hoon` and
`tests/lib/tier2-sub.hoon` is empty afterwards. 1015 modules inventoried
(607 test-model, 408 examples), 452/452 SANY, 14/14 TLC safety, 9/9 TLC
liveness, census empty.

That is what the row asked for: the liveness half being a no-op *was* an
inference from a passing frozen assertion, and it is a measured fact now.

## 2. The stale claim was in the prose, not the constant

The row says `TLC_LIVENESS_DIVERGENCES` "still reads `Github710d -> Error:
Deadlock reached.`". **It does not** — R2.7.6.0 emptied it, exactly as the same
row's opening sentence says. The row contradicts itself, and the half that is
right is the opening.

But the claim it describes is real and survived in **prose that R2.7.6.0 did
not touch**:

* `tools/tier2.py` printed *"a 9-spec TLC LIVENESS batch … **8/9 agree**"* and
  *"The census is EMPTY **except one liveness entry**"* — a summary emitted on
  every run, contradicting the `divergences.txt` it had just regenerated
  (`0 disagree with TLC (9/9 agree)`).
* `desk/doc/testing.md` said the same in two places: the `Github710d` bullet
  ending *"leaving the liveness batch **8/9**"*, and the deferral list's
  *"(8/9, one censused entry)"*.

All three now say 9/9 and name R2.7.5 as what closed it and R2.7.6.0 as what
regenerated it. `port-map.md`'s R1.1.R1/R1.1.R4 rows still say 8/9 and are
deliberately left alone — they are a historical narrative log of what those
units found, the precedent R1.1.R4's own row set.

**The generalizable bit**: R2.7.6.0 fixed the DATA and left the SENTENCES that
assert things about the data. A regenerated artifact does not regenerate the
prose describing it, and the prose is what a reader believes.

## 3. The selection rule for R2.8.2b — and its answer is "add nothing"

Shipped as `tools/tier2-select.py`, so the rule is executable rather than
described. Stated once:

> Take the in-scope (`check`-class) `tlaplus-Examples` specs that exercise a
> LEDGER-ROW FAMILY the currently-checked corpus does not, most-new-first and
> cheapest-first within that, until the nightly budget is reached.

Its current answer:

```
specs currently run through the Hoon CHECKER: 27
  exercised: alias, assume, choose, constraint, except, fairness, fcnset,
             finitesets, rcdset, recursive, seq, subset, symmetry, temporal,
             tlcops
  NOT exercised: bags, instance, reals, view
  -> ledger rows: cfg-view, semantic-instance, tlc-module-bags,
                  tlc-module-reals

in-scope (`check`-class) examples specs in the census: 36
candidates that bring an unexercised row: NONE
```

**36** — not 408. The census inventories 408 examples modules, but 197 are
excluded and 175 are SANY-only; only 36 are in scope for the checker, and every
one of them exercises a row the 27 already-checked specs cover. Per .2b's own
terms — *specs that exercise nothing new are corpus weight, not coverage* —
that is the answer, and .2b can close on it rather than adding specs for the
sake of a bigger number.

The four unexercised rows are worth naming because they are what a future
coverage unit would have to go and *build* rather than find: `cfg-view`,
`semantic-instance`, `tlc-module-bags`, `tlc-module-reals`. No in-scope
`tlaplus-Examples` spec supplies them.

## Two mistakes in the rule, both caught before it shipped

* **It conflated SANY coverage with CHECKER coverage.** The first version
  derived "already covered" from every quoted identifier in
  `gen-tier2-tests.py`, which swept in all 452 SANY-batch modules. Those
  exercise the front end and say nothing about `check:check`. The rule now
  reads `TLC_BATCH` + `TLC_LIVENESS_BATCH` + the curated examples out of the
  generator, so it cannot drift from them.
* **It scanned only the `.tla`.** `SYMMETRY`, `CONSTRAINT`, `VIEW` and `ALIAS`
  are CONFIG keywords and never appear in a module, so a module-only scan
  reported all four as unexercised when three of them are covered. The rule
  now reads each spec's sibling `.cfg` too. Had this shipped uncorrected it
  would have sent .2b hunting for coverage that already exists.

## What this unit did not change

No spec was added to any batch — that is .2b's call, and the rule's answer is
that there is nothing to add. No generator logic changed; the only code is the
new selection tool and the corrected prose.
