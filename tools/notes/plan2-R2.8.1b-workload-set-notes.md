# R2.8.1b — the tier-3 workload set

```text
Sub-unit: R2.8.1b
Row: none (tier 3 measures the port against itself)
Planned: one workload per hot path, each with a measured runtime budget,
  stored per pinned runtime, byte-reproducible in what it reports.
Found: "byte-reproducible in what it reports" and "a performance workload"
  are in tension, and resolving it is the whole design -- a wall-clock number
  is never byte-reproducible, so the set reports the WORK and measures the
  time separately.
```

## The tension, and how the set resolves it

R2.8.1b asks for a workload set that is *byte-reproducible in what it
reports*. R2.8.1a had just measured the same unchanged code varying 0.9% to
15.6% run to run. A time is therefore not a fact a test can hold, and a set
that asserted one would be the flaky gate R1.1.R3 warned about, wearing a
different hat.

What IS byte-reproducible is the **work**: the states a workload generates,
how many are distinct, how deep the search goes, the out-degree distribution.
So the set splits the two:

* `desk/tests/lib/perf.hoon` (generated) asserts each workload's **work
  profile**. A diff of that file is the report, and it is byte-exact.
* `tools/tier3-noise.py` reads the **timing** off the runner's own `took`
  line, outside the ship. Nothing inside observes a clock (R2.6.1).
* Each workload carries its **measured median** as a comment, from R2.8.1a's
  15 runs, so a later reader can tell a workload that GOT slower from one
  that was always slow — the cap discipline R1.1.R2 established, *a measured
  runtime budget, not a wall*.

The profile has a second job that is less obvious and turned out to matter:
it stops a workload from silently ceasing to do its work. A spec that started
erroring early would keep reporting a fast, meaningless time.

## The set

Corpus at `desk/test-data/perf/<workload>/` — `spec.tla`, `spec-cfg.txt`,
`path.txt` (the hot path it covers), `engine.txt`, `profile.txt`,
`budget.txt` — generated into the shard by `tools/gen-perf-tests.py`.
Runtime pinned in the generator: **vere 4.6, `--loom 32`**.

| workload | hot path | engine | work profile | measured median |
| --- | --- | --- | --- | --- |
| `queue` | BFS queue / dedup / fp-set | safety | 1153 gen, 576 distinct, depth 47, outdeg 0/1/1/2 | 2136 ms |
| `eval` | evaluator | safety | 41 / 41 / depth 41 | 1876 ms |
| `enum` | enumeration (`+force`, cursors) | safety | 13 / 13 / depth 13 | 1909 ms |
| `fp` | fingerprinting (structural) | safety | 61 / 61 / depth 61 | 2677 ms |
| `live` | liveness (8.2–8.6) | **liveness** | verdict %ok, 13 / 12 / depth 12 | 1106 ms |

## The defect the set's own capture found

The first generator ran every workload through `+run-stats-full`. That arm
builds `bfs-opts` **with no liveness at all**, so the liveness workload was
timing a 12-state safety search and reporting a fast, meaningless number —
exactly the failure the profile exists to catch, caught by the profile on its
first capture (`live` came back as its safety graph).

The set now carries an `engine` per workload. `+lprof` drives the liveness
workload through `+run-check`, which is the entry point that reaches the
tableau build and `+find-lasso`, and its profile leads with the VERDICT
(1 = `%ok`) so a workload that starts *failing* rather than merely getting
slower shows up in the profile too.

**A limitation recorded rather than smoothed over**: the liveness workload is
small enough that its ~1.1 s is dominated by parse and semantic setup rather
than by the liveness engine. It exercises the engine and pins its verdict, but
it is not yet a sensitive liveness *benchmark*. Growing it is a candidate for
whatever unit next touches this set; it was left alone here because R2.8.1a's
budgets were measured against these exact specs, and changing a spec
invalidates its budget.

## Two Hoon/ship facts worth carrying

* **A bare `1153` is a syntax error in Hoon** — numerals past three digits
  must be dot-grouped (`1.153`), and Clay reports it as `syntax error` against
  the column of the literal with `FAILED /tests/lib/perf/hoon (build)`. The
  generator now emits through `hnum()`. Only the `queue` workload is large
  enough to have hit it.
* A `|commit` of a single generated test file took **hours** on this box
  during this unit, and the serf's uptime kept resetting under an hour while
  one was outstanding. I read that as a restart loop and was wrong — the
  commit did land (rev 169). The uptime resets are unexplained and are NOT
  evidence of a failed commit; check for the `: /~zod/<desk>/<rev>/` line
  before concluding anything.

## Status

All five workloads verified green against their stored profiles on the ship
(`-test /=tla-lus=/tests/lib/perf ~`, `ok=%.y`, 0 FAILED, rev 170). The set is
regenerable: `tools/gen-perf-tests.py` rebuilds the shard from the corpus, and
`--capture` re-emits it in capture form when a profile has to be re-taken.
