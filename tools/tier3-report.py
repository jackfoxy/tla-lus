#!/usr/bin/env python3
"""The tier-3 NIGHTLY REPORT (R2.8.1c).

R2.8.1c was written as "the gate, and it lands with the unit that runs it --
IF .1a says gate". **R2.8.1a said no.** The measured run-to-run spread of the
median workload reached 15.6% on a fresh boot, over its own +/-15% bar, so
this unit ships the baseline store and this report and adds NO clause to
`release-gate.sh` at all. A threshold nobody trusts is worse than a number
everybody reads, and R1.1.R3 already named the failure mode: *a flaky gate is
one everyone learns to ignore*.

So: **this script never fails a run for being slow.** It exits nonzero for
exactly one reason -- the workload shard did not pass, which means a
workload's deterministic WORK PROFILE changed (or it stopped running at all).
That is not a performance signal; it is an ordinary test failure that happens
to be noticed here, and reporting it as "slow" would be a lie.

  tools/tier3-report.py                 run the set, print the report
  tools/tier3-report.py --runs 3        average over N runs (default 1)
  tools/tier3-report.py --json OUT      also write the raw numbers

The baseline is `desk/test-data/perf/baseline.json`, keyed by the runtime it
was measured on. A baseline measured on another machine says nothing here, so
the report says whose it is rather than pretending it is universal.
"""
import argparse
import json
import statistics
from pathlib import Path

import importlib.util

REPO = Path("/mnt/mars/gitrepos/tla-lus")
BASELINE = REPO / "desk/test-data/perf/baseline.json"

#  the ship driver lives in tier3-noise.py; importing it keeps ONE definition
#  of how a run is started and how `took` is parsed. A second copy would be a
#  second thing to keep in step with the dojo's quirks
_spec = importlib.util.spec_from_file_location(
    "tier3_noise", REPO / "tools/tier3-noise.py")
noise = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(noise)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=1)
    ap.add_argument("--json", default=None)
    a = ap.parse_args()

    base = json.loads(BASELINE.read_text())
    samples: dict = {}
    for _ in range(a.runs):
        #  one_run raises if the shard did not report ok=%.y -- the one
        #  condition this report treats as a failure
        for arm, us in noise.one_run().items():
            samples.setdefault(arm.replace("test-perf-", ""), []).append(us)

    print(f"tier-3 report  ({a.runs} run(s))")
    print(f"baseline: {base['runtime']}, measured {base['measured']}")
    print(f"          {base['source']}")
    print()
    print(f"{'workload':<10}{'now ms':>9}{'base ms':>10}{'delta':>9}"
          f"{'base spread':>13}")
    rows = {}
    for w in sorted(samples):
        now = statistics.median(samples[w])
        b = base["workloads"].get(w)
        if b is None:
            print(f"{w:<10}{now/1000:>9.1f}{'--':>10}{'new':>9}{'--':>13}")
            rows[w] = {"now_ms": round(now / 1000, 1)}
            continue
        d = (now / 1000 - b["median_ms"]) / b["median_ms"] * 100
        print(f"{w:<10}{now/1000:>9.1f}{b['median_ms']:>10.1f}{d:>8.1f}%"
              f"{b['spread_pct']:>12.1f}%")
        rows[w] = {"now_ms": round(now / 1000, 1),
                   "baseline_ms": b["median_ms"],
                   "delta_pct": round(d, 1)}
    missing = sorted(set(base["workloads"]) - set(samples))
    if missing:
        print("\nMISSING from this run (in the baseline, not measured): "
              + ", ".join(missing))
    print("\nREPORT ONLY -- no threshold, no gate (R2.8.1a). A delta inside "
          "the baseline's own")
    print("spread is noise; read the two columns together rather than the "
          "delta alone.")
    if a.json:
        Path(a.json).write_text(json.dumps(
            {"baseline_runtime": base["runtime"], "runs": a.runs,
             "workloads": rows}, indent=1) + "\n")
        print(f"\nwrote {a.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
