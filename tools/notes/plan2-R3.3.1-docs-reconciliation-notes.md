# R3.3.1 — regenerate, then grep for the sentences

```text
Sub-unit: R3.3.1 (R3 close-out, first of three)
Rows: none touched
Planned: re-run every generator, reconcile port-map / compatibility / the
  ledger / both plan files, and close the specific drift where
  `check-portmap.py`'s tally reads the repo's docs and not the plan.
Found: the regeneration is clean. FIVE prose claims were stale, and two of
  them were mine -- one is the exact half-fix this unit exists to catch.
```

**Docs and tools only. No desk change.**

## 1. The regeneration is clean

| gate | result |
|---|---|
| `tools/validate.py` (every tier-1 generator) | all goldens reproduce byte-identically; the ONLY change is `evidence-counts.md` — `gen-mc-tests` 105 → **106**, compared cases 1264 → **1265**, the expected consequence of R3.2's `rec-fcn-eq` case |
| `tools/tier2.py --check` | *tier-2 differential integrity: OK* |
| `tools/check-parity.py` | 134 rows, well-formed, 1 owed |
| `tools/check-portmap.py` | coherent with the ledger and the tree |
| `tools/scaffold-gate.sh` | **11/11 PASS** |

`api-version` does not move, and `compatibility.md` now says so in the row that
tracks it: nothing has shipped, no ship holds state worth preserving, so there
is no migration anywhere in this project.

`port-map.md` gets no R3 rows. It has none since R2.7.4.x — units stopped
logging there partway through R2 — and the coherence that matters is
`check-portmap.py`'s, which passes. Adding a row per R3 unit now would be
inventing a convention, not restoring one.

## 2. Five stale claims, and the two that are the point

**(a) `tools/tier2.py`: "a 14-spec TLC safety batch … 14/14 agree".** R3.2 added
`BagsTest`; it is 15/15. This summary prints on every `--check` run.

**(b) `tools/tier2.py`: "a 4-spec tlaplus-Examples TLC batch … closed to 3/3 by
R3.0". This one is mine, and it is exactly the failure this unit is named
after.** At R3.0 I corrected the *result* half of that sentence — `1/4 agree` →
`3/3` — and left the *count*. The batch had been 3 specs since R3.0c took
`Paxos` out on cost. **Fixing half a sentence leaves a sentence that is wrong**,
and it survived a unit whose own notes quote R2.8.2a's lesson about exactly
this.

**(c) `tools/tier2.py`: the census paragraph.** Accurate about R2.8.2b's three
entries and R3.0 closing them, silent about R3.2 freezing a fourth (`BagsTest`)
and R3.2a closing it. A census summary that stops one cycle short reads as
complete.

**(d) `doc/testing.md`, twice**: "runs 14 clean single-file test-model safety
specs" and "a curated set + a 14-spec batch" — both **current** claims, both now
15, with the historical `4/14 agree` from R1.1.5 kept and marked as the result
*as first run*. The neighbouring `back to 14/14` in the R2.3.2 narrative is
about that moment and is now tensed so it cannot be read as today's count.

**(e) `doc/testing.md`: "the three entries `divergences.txt` now carries are
R2.8.2b's examples batch".** The census is empty. Written at R3.0 when it was
true of the *liveness* census's neighbours, stale within two units.

## 3. What separates a stale claim from a historical one

Every one of the five was a sentence in the PRESENT tense about a number that
had moved. The R1.1.5 result (`4/14`), the R2.3.2 recovery (`back to 14/14`) and
`port-map.md`'s narrative rows are the same kind of number in the PAST tense,
and they stay — R2.8.2a set that precedent when it left `port-map.md`'s 8/9 rows
alone while correcting the live prose. The rule this unit applied:

> a number in a sentence that says *is*, *now* or *carries* is a claim and must
> be re-derived; a number in a sentence that says *was*, *at R‹n›* or *as first
> run* is a record and must not be touched.

Two doc additions rather than corrections: `testing.md` now carries the
R3.2/R3.2a cycle (the fourth census entry, the record-vs-function equality, the
`isName` rendering rule) and the two defects R3.2 found in the selection rule
itself — the `%1%` test-template config and the eleven invented ledger-row
names — with the consequence stated as a measurement: **`tlc-safety-symmetry`
has no viable tier-2 supplier**, because `Github432` cannot run and `Paxos` is
out on cost.

The `R2-release-work-breakdown.md` header said the ledger "stands at 134 rows,
131 terminal, 3 owed". True when R2 ended, present tense, and R3 has moved it
twice since. Now anchored to *when R2 ended*, with a pointer saying
`check-parity.py` is the current tally and this file never is.

## 4. State

Ledger **134 rows, 133 terminal, 1 owed** — `check-mode-generate` (R3.0c's
probabilistic multi-binder path). Scaffold gate 11/11. The release gate still
fails by design on that one owed row, which is R3.3.2's to assert and R3.3.3's
to close out against the full ship suite.
