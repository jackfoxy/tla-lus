# R2.8.1a — the tier-3 noise measurement, and the go/no-go it decides

```text
Sub-unit: R2.8.1a
Row: none (tier 3 measures the port against itself)
Planned: measure the run-to-run spread of candidate workloads BEFORE any
  threshold is chosen, on a warm pier and a fresh boot and across a rebuild,
  and DECIDE gate-vs-report from it.
Decision: REPORT-ONLY. R2.8.1c ships the baseline store and the nightly
  report and adds NO `release-gate.sh` clause.
```

## The numbers

Five candidate workloads, one per hot path (`desk/tests/lib/perf.hoon`), five
runs per leg, on the pinned runtime (vere 4.6, `--loom 32`), driven by
`tools/tier3-noise.py`. Medians in ms; `spr` is the half-range as a percentage
of the median, which is the `+/-N%` the criterion is written in.

| workload | warm | fresh | rebuild | spr(warm) | spr(fresh) | spr(rebuild) | rebuild vs fresh |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `enum` | 1872.9 | 1926.5 | 1871.3 | 5.3% | **15.6%** | 7.3% | −2.9% |
| `eval` | 1868.5 | 1924.5 | 1876.0 | 0.9% | 3.5% | 4.4% | −2.5% |
| `fp` | 2677.4 | 2715.8 | 2675.9 | 5.9% | 3.2% | 1.7% | −1.5% |
| `live` | 1067.8 | 1109.0 | 1092.1 | 9.8% | 4.7% | 9.2% | −1.5% |
| `queue` | 2135.7 | 2141.3 | 2126.4 | 6.3% | 6.1% | 3.8% | −0.7% |

Raw samples are in `/tmp/tier3-noise-{warm,fresh,rebuild}.json` as produced;
the per-run lines are reproduced at the end of this note so the decision is
re-derivable from the file rather than from a temp directory.

## The decision, against R2.8.1a's own criterion

> if the run-to-run spread of the **median workload** exceeds **±15%**, or a
> rebuild moves it by more than **±25%**, tier 3 ships as a REPORTED NUMBER
> and .1c adds no gate clause.

* **Run-to-run: FAILS.** The median workload is `enum` on two of the three
  legs, and its fresh-boot spread is **15.6%** — over the bar. Warm (5.3%) and
  post-rebuild (7.3%) are comfortably under it.
* **Rebuild: PASSES.** Every workload moved between −0.7% and −2.9%, an order
  of magnitude inside ±25%.

**So: REPORT-ONLY.** `release-gate.sh` gets no tier-3 clause, and R2.9.2 must
assert that the nightly REPORT exists rather than assert a clause that does
not.

**The honest caveat, stated rather than buried**: the 15.6% is one outlier in
one leg (`enum` at 2226.8 ms against a 1926.5 median); two of three legs are
well under the bar. That is not a reason to round the decision down — it is
the decision's whole point. If a single ordinary run can push the median
workload past the threshold, a gate set there fires on noise, and R1.1.R3's
named failure mode is *a flaky gate is one everyone learns to ignore*. The bar
was chosen before the data and is applied to the data as written.

**Input for R2.8.1b**, since it now has evidence rather than a guess: `eval`
is the tightest candidate (≤4.4% on all three legs, 0.9% warm) and `enum` the
loosest (5.3 / 15.6 / 7.3). If a later unit wants a gateable workload, `eval`
is the shape to build on; `enum` forces a lazy-set enumeration per state and
is the one whose cost depends most on allocator behaviour.

## Two measured findings that contradict what the row assumed

**1. Pier age does NOT inflate these workloads — a fresh boot is SLIGHTLY
SLOWER.** The row added, on 2026-09-01, that the dev pier "accumulates serf
state" and that "a baseline taken only there silently encodes pier age",
citing `tier2-sub` arms observed at 270–300 s late in a session. Measured
here, the fresh pier is **0.3% to 3.9% slower** than the warm one on every
workload, not faster. So that observation does not generalize to bounded
workloads of this class, and .1b does not need to control for pier age. What
it was probably seeing is a property of the long heavy shards (the ~1.3 MB
embedded SANY corpus), not of the checker's hot paths.

**2. A rebuild is not a source of variance at all here** (−0.7% to −2.9%,
consistently slightly faster, which is within the run-to-run noise). The
rebuild was forced by a comment-only edit to `lib/value.hoon` — a deep
dependency, so the whole desk recompiled — and the probe comment was reverted
afterwards and appears in no commit.

## What this unit did NOT do

It did not build a baseline store, a threshold, or a nightly job: those are
.1b and .1c, and .1c is now constrained to the report-only shape. The workload
shard exists and passes, but it is a set of CANDIDATES — .1b owns turning it
into the workload set with measured runtime budgets.

`tools/tier3-noise.py` drives the ship through the same tmux session the dev
loop uses and reads timing off the test runner's own `took` line (the printed
digits are microseconds with Hoon's dot separators; the unit label only says
where the decimal point goes). Nothing observes a clock inside the ship, so
the arms stay reproducible (R2.6.1). Completion is detected by the COMMAND
ECHO rather than by `ok=%`, because polling for the verdict matches the
PREVIOUS run's — the stale-scrollback trap this repo has been caught by three
times.

## Raw runs

```
warm      enum  eval  fp    live  queue      (ms)
run 1     1873  1868  2835  1173  2136
run 2     1909  1875  2726  1054  2188
run 3     1972  1853  2619  1077  2069
run 4     1825  1851  2625  1068  2271
run 5     1792  1879  2677  1061  2084

fresh boot
run 1     1792  1863  2645  1109  2271
run 2     2227  1924  2761  1161  2128
run 3     1924  1991  2802  1106  2141
run 4     1926  1913  2716  1150  2109
run 5     1979  1930  2650  1109  2206

after a rebuild
run 1     1806  1793  2676  1040  2085
run 2     1871  1870  2639  1068  2108
run 3     1871  1885  2722  1092  2157
run 4     2008  1914  2704  1193  2208
run 5     1925  1876  2667  1129  2126
```
