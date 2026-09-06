# P2-R1.9.4 — R1 close-out: the acceptance sentence, asserted

The row: *"Release close-out: full suite, `validate.py --check`,
`tier2.py --check`, `check-parity.py`, and the acceptance sentence asserted
rather than asserted-by-hand."*

The operative half is the last clause. The first four are gates that already
exist and that `release-gate.sh` (R1.9.3) already runs. What did not exist was
anything that *computes* whether R1 is accepted — that sentence lived in a
markdown file and would have been marked done by a human deciding it was true.

## The sentence

From `R1-release-work-breakdown.md`:

> Drive every in-scope ledger row to `parity` or a tested
> `approved-difference`, stand up tier-2 test automation, and replace the
> scaffold gate with the real release gate. R1's acceptance: **zero `partial`
> and zero unexplained `absent` rows**, tiers 1 and 2 green (tier 3 descoped),
> clean install/upgrade/restart.

`tools/r1-acceptance.py` computes it as four clauses:

| clause | computed by |
|---|---|
| zero `partial`, zero `absent`, zero `oracle-only` | `check-parity.py`, reading the per-status counts, not just the exit code |
| docs coherent with the ledger and the tree | `check-portmap.py` (owners exist, one pin, units resolve, tallies agree, approved differences enumerated, wire molds documented) |
| release gate passes | `release-gate.sh` — which itself carries tiers 1-2, no-stubs, refusals-documented, upgrade/restart, reproducible artifacts |
| full ship suite green | a captured suite log the caller supplies |

It prints `R1 ACCEPTED` only when all four hold, and `R1 NOT ACCEPTED` with the
failing clauses named otherwise.

## The one clause a script cannot compute

`-test /=tla-lus=/tests ~` needs a running ship. Three ways to handle that:
assume it, skip it, or require it as evidence. The first two are how a gate
quietly becomes a claim — which this release has now watched happen twice
(gate 6 red for nine units, R1.8.8; a support matrix nobody could check for
completeness, R1.9.1).

So the suite is an **input**: `--suite-log <file>`, parsed for the `ok=%.y`
verdict and the `FAILED` count, and its absence makes the clause FAIL rather
than vanish. Run with no evidence, the script says:

```
FAILS  full ship suite green
       no --suite-log supplied; the suite needs a running ship, so this
       clause is evidence the caller must provide
```

The hand's job is to supply a measurement. It is not to write the conclusion.

`--skip-gate` exists for the same reason and behaves the same way: skipping the
release gate does not omit the clause, it fails it.
