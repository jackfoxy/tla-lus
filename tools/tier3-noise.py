#!/usr/bin/env python3
"""R2.8.1a — measure the RUN-TO-RUN SPREAD of the tier-3 candidate workloads.

This is a measurement, not a harness and not a gate. R1.1.R3's warning is the
reason it exists before anything else in tier 3: *a flaky gate is one everyone
learns to ignore*, so the variance is measured BEFORE a threshold is chosen,
and R2.8.1a's criterion is applied to what comes out:

    run-to-run spread of the MEDIAN workload  > +/-15%  -> report-only
    a REBUILD moves it by                     > +/-25%  -> report-only

Either way the numbers are recorded, so the decision is re-derivable rather
than remembered.

Usage:
    tools/tier3-noise.py --runs 5 [--label warm]      drive the ship, collect
    tools/tier3-noise.py --report FILE...             summarize collected JSON

The ship is driven through the same tmux session the dev loop uses. Timing is
read off the test runner's own `took` line: the printed digits are MICROSECONDS
with Hoon's dot separators, and the unit label only says where the decimal
point would go (`ms/874.042` and `s/2.347.507` are 874042 and 2347507 us).
Nothing here observes a clock inside the ship, so the arms stay reproducible.
"""
import argparse
import json
import re
import statistics
import subprocess
import time
from pathlib import Path

SESSION = "tla-zod"
SHARD = "/=tla-lus=/tests/lib/perf"
CMD = f"-test {SHARD} ~"
TOOK = re.compile(r"^>\s+(test-perf-[a-z-]+):\s+took\s+\S+?/([\d.]+)\s*$")


def pane(lines: int = 4000) -> str:
    return subprocess.run(
        ["tmux", "capture-pane", "-pt", SESSION, "-S", f"-{lines}"],
        capture_output=True, text=True).stdout


def send(text: str) -> None:
    #  `-l --` so a leading `-` is not read as an option
    subprocess.run(["tmux", "send-keys", "-t", SESSION, "-l", "--", text],
                   check=True)
    subprocess.run(["tmux", "send-keys", "-t", SESSION, "Enter"], check=True)


def one_run(timeout_s: int = 3600) -> dict:
    """Run the shard once; return {arm: microseconds}.

    Completion is detected by the COMMAND ECHO, which the dojo prints only
    when the run finishes -- polling for `ok=%` matches the PREVIOUS run's
    verdict, a trap this repo has been caught by three times.
    """
    subprocess.run(["tmux", "clear-history", "-t", SESSION], check=True)
    send(CMD)
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        time.sleep(10)
        if f"> {CMD}" in pane(200):
            break
    else:
        raise SystemExit("timed out waiting for the run to finish")
    text = pane()
    if "\nok=%.y" not in text:
        raise SystemExit("the workload shard did not pass; refusing to time it")
    out = {}
    for line in text.splitlines():
        m = TOOK.match(line)
        if m:
            out[m.group(1)] = int(m.group(2).replace(".", ""))
    return out


def spread(xs: list) -> dict:
    """Half-range as a percentage of the median: the +/-N% the criterion uses."""
    med = statistics.median(xs)
    lo, hi = min(xs), max(xs)
    pct = (max(hi - med, med - lo) / med * 100) if med else 0.0
    return {"n": len(xs), "min": lo, "median": med, "max": hi,
            "spread_pct": round(pct, 1)}


def report(samples: dict) -> None:
    print(f"{'workload':<20}{'n':>3}{'min ms':>10}{'median ms':>12}"
          f"{'max ms':>10}{'spread':>9}")
    rows = {}
    for arm, xs in sorted(samples.items()):
        s = spread(xs)
        rows[arm] = s
        print(f"{arm:<20}{s['n']:>3}{s['min']/1000:>10.1f}"
              f"{s['median']/1000:>12.1f}{s['max']/1000:>10.1f}"
              f"{s['spread_pct']:>8.1f}%")
    if not rows:
        return
    #  the criterion names THE MEDIAN WORKLOAD -- the one whose median runtime
    #  is the middle of the set -- not the worst or the average
    by_med = sorted(rows.items(), key=lambda kv: kv[1]["median"])
    name, mid = by_med[len(by_med) // 2]
    print(f"\nmedian workload: {name} at {mid['median']/1000:.1f} ms, "
          f"spread +/-{mid['spread_pct']:.1f}%")
    print("R2.8.1a criterion: "
          + ("FAIL -> tier 3 ships REPORT-ONLY, .1c adds no gate clause"
             if mid["spread_pct"] > 15 else
             "run-to-run PASSES (a rebuild delta is still owed)"))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=5)
    ap.add_argument("--label", default="warm")
    ap.add_argument("--out", default=None)
    ap.add_argument("--report", nargs="*", default=None)
    a = ap.parse_args()

    if a.report is not None:
        merged: dict = {}
        for f in a.report:
            for arm, xs in json.loads(Path(f).read_text())["samples"].items():
                merged.setdefault(arm, []).extend(xs)
        report(merged)
        return

    samples: dict = {}
    for i in range(a.runs):
        got = one_run()
        print(f"run {i+1}/{a.runs}: "
              + " ".join(f"{k.split('-')[-1]}={v/1000:.0f}ms"
                         for k, v in sorted(got.items())), flush=True)
        for arm, us in got.items():
            samples.setdefault(arm, []).append(us)
    out = Path(a.out or f"/tmp/tier3-noise-{a.label}.json")
    out.write_text(json.dumps({"label": a.label, "samples": samples}, indent=1))
    print(f"\nwrote {out}")
    report(samples)


if __name__ == "__main__":
    main()
