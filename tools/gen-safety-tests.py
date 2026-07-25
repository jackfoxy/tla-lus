#!/usr/bin/env python3
"""Capture single-worker safety goldens from the SafetyDump oracle (unit 7).

Each case lives in desk/test-data/safety/<case>/ as A.tla plus A.txt (the .cfg
content; the desk has no %cfg Clay mark, so the corpus stores it as A.txt) and
an optional opts.txt (one extra tlc2.TLC argument per line, e.g. -coverage 1).
SafetyDump drives tlc2.TLC with a single deterministic worker and an
MPRecorder, projecting the safety behaviour the Hoon checker must match:
verdict, EC category, statistics (generated/distinct/queue/depth/outdegree),
optional action coverage, and the shortest counterexample trace with per-state
action labels and FP64 fingerprints. Timings, worker ids, and disk layout are
excluded.

Until Work Unit 7.1+ grows lib/tla/tlc/{fingerprint,state,safety,trace}.hoon
and check.hoon consumes them, this is ORACLE-ONLY: it only refreshes out.txt.
The five gen-mc-tests goldens (tests/lib/tla/mc, verdict+trace+counts) stay the
green smoke suite; this corpus is the parity target those five cannot express
(fingerprints, EC categories, multiple invariants/constraints, symmetry,
coverage, outdegree, initial-state and diamond traces). Never edit generated
files; the A.tla/A.txt/opts.txt inputs are hand-authored source of truth.
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
DUMP_CP = f"{JAR}:{REPO}/tools/oracle/build"
CASES = REPO / "desk/test-data/safety"


def golden(case: Path) -> None:
    opts = []
    if (case / "opts.txt").exists():
        opts = [l for l in (case / "opts.txt").read_text().split("\n") if l.strip()]
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        shutil.copy(case / "A.tla", tdp / "A.tla")
        shutil.copy(case / "A.txt", tdp / "A.cfg")
        r = subprocess.run(["java", "-cp", DUMP_CP, "SafetyDump", "A"] + opts,
                           cwd=td, capture_output=True, text=True, timeout=180)
    (case / "out.txt").write_text(r.stdout)


def main() -> None:
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "A.tla").exists():
            golden(case)
            n += 1
    print(f"{n} safety cases")
    print(f"TOTAL {n}")


if __name__ == "__main__":
    main()
