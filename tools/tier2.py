#!/usr/bin/env python3
"""Tier-2 runner (Release R1, sub-unit R1.1).

Tier 2 is the broad, nightly differential layer (see `doc/testing.md`): the
`tlaplus/test-model` corpus and the curated `tlaplus-Examples` matrix, run
through the Java oracle and — from R1.1.1 on — through the Hoon units 4-11.

It is deliberately a SEPARATE runner from `tools/validate.py` (tier 1): tier 1
stays fast enough for every change, tier 2 runs TLC over many specs and belongs
in CI/nightly. This script owns the tier-2 goldens the same way `validate.py`
owns tier 1's.

  tools/tier2.py            regenerate the tier-2 inventory + curated oracle
  tools/tier2.py --check    regenerate, then fail if anything drifted from the
                            committed tier-2 goldens (the reproducibility gate)

R1.1.0 (this increment) is oracle-only: it proves the classified scope map and
the curated Java projection reproduce byte-identically from the pins. The Hoon
comparison (each in-scope spec through the ship pipeline, compared to the
oracle projection) lands in R1.1.1+.
"""
import hashlib
import subprocess
import sys
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
TIER2 = REPO / "desk/test-data/tier2"
GEN = REPO / "tools/gen-tier2-tests.py"


SHARD = REPO / "desk/tests/lib/tier2.hoon"


def snapshot() -> dict:
    h = {}
    for f in sorted(TIER2.rglob("*")):
        if f.is_file():
            h[str(f.relative_to(TIER2))] = hashlib.md5(f.read_bytes()).hexdigest()
    for s in (SHARD, REPO / "desk/tests/lib/tier2-sub.hoon"):
        if s.is_file():                      # the generated Hoon comparators
            h["tests/lib/" + s.name] = hashlib.md5(s.read_bytes()).hexdigest()
    return h


def main() -> int:
    check = "--check" in sys.argv
    before = snapshot()
    print("regenerating tier-2 goldens from the pins...")
    r = subprocess.run([sys.executable, str(GEN)], text=True)
    if r.returncode != 0:
        print("generator failed (off-pin or oracle error)", file=sys.stderr)
        return 2
    after = snapshot()
    keys = sorted(set(before) | set(after))
    drift = []
    for k in keys:
        if before.get(k) != after.get(k):
            tag = ("changed" if k in before and k in after
                   else "added" if k in after else "removed")
            drift.append(f"{tag}: {k}")
    if drift:
        print(f"\nDRIFT: {len(drift)} tier-2 golden(s) changed after regeneration:")
        for d in drift[:40]:
            print("  " + d)
        print("\nA change here means the pinned oracle (or an upstream corpus "
              "spec) no longer produces the committed tier-2 projection. "
              "Investigate before committing; never weaken a golden without "
              "proving the Java behavior from the pin.")
        return 1 if check else 0
    print("\ntier-2 differential integrity: OK — inventory + curated oracle + "
          "comparator shard reproduce byte-identically from the pins.")
    print("Hoon comparators: desk/tests/lib/tier2.hoon — SANY accept/reject "
          "(R1.1.1), TLC verdict/distinct-count (R1.1.2), a 142-spec "
          "mule-isolated SANY batch (R1.1.3/4 + R1.3.1/R1.3.2, 142/142 agree), a 14-spec "
          "TLC safety batch (R1.1.5 + R1.5.1/R1.5.2/R1.5.3/R1.5.9, 14/14 agree), and a "
          "295-spec subdir SANY batch (R1.1.6-9 + R1.3.1/R1.3.2/R1.3.3/R1.3.5/R1.3.7, "
          "tier2-sub.hoon, 295/295 agree), plus a 9-spec TLC LIVENESS batch "
          "(R1.8.1.4, 9/9 agree). "
          "The census is EMPTY in every batch: SANY closed by R1.3.7, the last TLC safety "
          "one by R1.5.9, and the liveness ones by R1.6 (R1.6.1's user-defined-operator "
          "branch and R1.6.6's deadlock precedence). Each arm asserts its census exactly, "
          "so a NEW divergence fails the test. "
          "Run on the ship: "
          "-test /=tla-lus=/tests/lib/tier2 ~ (and .../tier2-sub ~). "
          "Known divergences: desk/test-data/tier2/divergences.txt.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
