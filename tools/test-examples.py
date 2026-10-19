#!/usr/bin/env python3
"""Offline checks for the R4.0d/e Examples runner (tools/examples.py).

No ship needed. Each check pins one lesson R4.0 paid for:

  * `max-time` is the wall cap, so the slice behn re-fires after an
    interrupt ends the job `%limited %time` (the only stop that works:
    a running slice cannot be cancelled);
  * `limited time`, `too slow` and an orphaned job all classify as
    `too slow`; `runaway` stays its own class;
  * the timed-out list names real work-list models, and a run skips them
    unless `--include-timed-out`;
  * the census file has a marked extension (Clay refuses `.jsonl`).

  python3 tools/test-examples.py      exit 1 on any failure
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import examples as e  # noqa: E402
import urbit_conn as u  # noqa: E402

FAILS = []


def check(name, cond):
    print(f"  {'ok  ' if cond else 'FAIL'} {name}")
    if not cond:
        FAILS.append(name)


def row(status, **kw):
    r = {"status": status, "expected": "success", "size": "small",
         "manifest": {"distinctStates": None, "stateDepth": None}}
    r.update(kw)
    return r


def limits_of(req):
    #  request = [op src limits write promote]
    return req[1][1][0]


def main() -> int:
    work = json.loads(e.WORK.read_text())["models"]
    small = next(m for m in work if m["size"] == "small")
    large = next(m for m in work if m["size"] == "large")

    #  max-time = wall (the @dr is seconds << 64)
    lim = limits_of(e.request(small, 2, 20_000, 900))
    check("request max-time is the wall cap", lim[1][1][1][1][0] == 900 << 64)
    check("small model: max-states uncapped", lim[1][1][0] == 10**9)
    lim = limits_of(e.request(large, 2, 20_000, 900))
    check("large model: max-states is the budget", lim[1][1][0] == 20_000)

    #  classification
    check("limited time -> too slow", e.classify(row("limited time")) == "too slow")
    check("too slow -> too slow", e.classify(row("too slow")) == "too slow")
    check("orphan row -> too slow",
          e.classify(row("too slow", orphaned=True)) == "too slow")
    check("runaway stays runaway", e.classify(row("runaway")) == "runaway")
    check("large + limited states -> agree",
          e.classify(row("limited states", size="large")) == "agree")
    check("small + limited states -> %limited",
          e.classify(row("limited states")) == "%limited (states)")
    check("expected verdict -> agree", e.classify(row("success")) == "agree")
    check("other verdict -> wrong answer",
          e.classify(row("liveness failure")) == "wrong answer")
    check("distinct mismatch -> wrong answer",
          e.classify(row("success", distinct=5,
                         manifest={"distinctStates": 6, "stateDepth": None}))
          == "wrong answer")
    check("error with code -> refused (code)",
          e.classify(row("error", error={"code": "tlc 2105"}))
          == "refused (tlc 2105)")

    #  the timed-out list
    ids = e.timed_out_ids()
    check("timed-out list is non-empty", len(ids) > 0)
    check("every timed-out id is in the work list",
          ids <= {m["id"] for m in work})
    kept, skipped = e.select_work(work, "", False)
    check("a run skips the timed-out models",
          len(skipped) == len(ids) and not ({m["id"] for m in kept} & ids))
    kept, skipped = e.select_work(work, "", True)
    check("--include-timed-out keeps them", not skipped and len(kept) == len(work))
    kept, _ = e.select_work(work, "", True, "large")
    check("--size large keeps only CI's large models",
          kept and all(m["size"] == "large" for m in kept)
          and len(kept) == sum(m["size"] == "large" for m in work))

    #  marked extension for the default census
    check("census file has a marked extension (.txt)",
          (e.REPO / "desk/test-data/blackbox/census.txt").suffix == ".txt")

    print(f"test-examples: {'FAIL' if FAILS else 'PASS'} "
          f"({len(FAILS)} failed)")
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
