# R2.8.1c — the baseline store and the report, and the gate that is not there

```text
Sub-unit: R2.8.1c
Row: none (tier 3 measures the port against itself)
Planned: "the gate, and it lands with the unit that runs it -- IF .1a says
  gate", CONDITIONAL on R2.8.1a.
Decided: .1a said NO. This unit ships the baseline store and the report and
  adds NO `release-gate.sh` clause at all.
```

## What shipped

* **`desk/test-data/perf/baseline.json`** — the store, keyed by the runtime it
  was measured on (`vere 4.6, --loom 32`) and carrying, per workload, the
  median / min / max / spread over R2.8.1a's 15 pooled runs. Timings only: the
  deterministic WORK profile lives beside each spec and is asserted by the
  generated shard, so a change there is an ordinary test failure and never
  reaches this file.
* **`tools/tier3-report.py`** — the report. Runs the workload set, prints each
  workload against its baseline with the delta and the baseline's own spread
  beside it, and **exits nonzero for exactly one reason**: the shard did not
  pass. That is a changed work profile, not a slow run, and reporting it as
  "slow" would be a lie. It imports the ship driver from `tier3-noise.py`
  rather than copying it, so there is one definition of how a run is started
  and how `took` is parsed.
* **No `release-gate.sh` clause.** Deliberate, and it is the unit's main
  decision rather than an omission.

## Why no gate — and the number that shows it

R2.8.1a measured the median workload at **15.6%** run-to-run on a fresh boot,
against its own ±15% bar. The bar was fixed before the data and applied to it.

The first run of the report is itself the argument:

```
workload     now ms   base ms    delta  base spread
enum         1856.2    1908.7    -2.8%        16.7%
eval         1952.9    1876.0     4.1%         6.1%
fp           2859.9    2677.4     6.8%         5.9%
live         1089.5    1106.0    -1.5%         7.8%
queue        2185.4    2135.7     2.3%         6.3%
```

`fp` came in **+6.8% against a baseline spread of 5.9%** — marginally outside,
on a run where nothing changed. A gate set at any threshold this data could
justify would have fired there. That is R1.1.R3's *flaky gate everyone learns
to ignore*, caught before it was built rather than after.

The report is printed with both columns for the same reason: a delta means
nothing without the spread it should be read against, and a single number
invites exactly the threshold thinking .1a ruled out.

## The report is RUN, not merely shipped

R2's second invariant — *a gate that is not run is not a gate* — killed
scaffold gate 6 for nine units. A report that is shipped and never run fails
the same way, so this unit ran it end to end against the committed workload
set (rev 170) and the output above is that run, not a mock-up.

## Docs reconciled, because .1c would otherwise contradict them

`doc/testing.md` and `validate.py` both said tier 3 was **DESCOPED by
R1.1.R3**. Shipping a tier-3 report while the docs say it does not exist is a
contradiction this unit creates, so it fixes it here rather than leaving it to
R2.9.1:

* `testing.md`'s Tier-3 section now leads with what R2 built (.1a's numbers,
  .1b's set, .1c's store and report), states plainly that `release-gate.sh`
  has no clause and why, and **keeps R1.1.R3's reasoning below it as the
  record** — struck through nowhere, because it is still the correct account
  of why tier 3 was not in R1. It also records the two R1-era assumptions
  R2.8.1a measured and contradicted: pier age does not inflate these
  workloads, and a rebuild is not a variance source.
* `validate.py`'s tier list says REPORT-ONLY with the reason. No golden reads
  that docstring (R1.1.R3 established this), so tier-1 reproducibility is
  unaffected — `check-portmap.py` still clean.

## What R2.9.2 must now assert

The nightly **report**, not a gate clause. R2.8.1a's row and R2.9.2's row both
already carry that resolution; this note is where the artifact it points at
is described.
