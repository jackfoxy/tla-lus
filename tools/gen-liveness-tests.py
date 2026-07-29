#!/usr/bin/env python3
"""Capture single-worker liveness goldens from the LivenessDump oracle (unit 8).

Each case lives in desk/test-data/liveness/<case>/ as A.tla plus A.txt (the .cfg
content; the desk has no %cfg Clay mark, so the corpus stores it as A.txt) and
an optional opts.txt (one extra tlc2.TLC argument per line). LivenessDump drives
tlc2.TLC single-worker with an MPRecorder, projecting the temporal behaviour the
Hoon liveness engine (lib/{temporal,tableau,liveness}.hoon, unit 8) must match:
the verdict, EC category, the violated property name(s), run statistics, and the
lasso — its per-state FP64 fingerprints and action labels, its loop-target state
number, and its stuttering / back-to-state classification. Timings, worker ids,
thread order, and the on-disk graph layout are excluded.

Until unit 8 grows the temporal/tableau/liveness libs and check.hoon consumes
them, this is ORACLE-ONLY: it only refreshes out.txt. The five gen-mc-tests
liveness goldens (tests/lib/mc: <>P/[]<>P stutter lassos, no fairness) stay the
green smoke suite; this corpus is the parity target those cannot express
(fairness WF_/SF_, ~>, spec-form fairness, non-stuttering and back-to-state
lassos, loop targets, and the symmetry+liveness diagnostic). Never edit
generated files; the A.tla/A.txt/opts.txt inputs are the hand-authored source of
truth.
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
DUMP_CP = f"{JAR}:{REPO}/tools/oracle/build"
CASES = REPO / "desk/test-data/liveness"


def golden(case: Path) -> None:
    opts = []
    if (case / "opts.txt").exists():
        opts = [l for l in (case / "opts.txt").read_text().split("\n") if l.strip()]
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        shutil.copy(case / "A.tla", tdp / "A.tla")
        shutil.copy(case / "A.txt", tdp / "A.cfg")
        # out.txt: the run projection (verdict, lasso, loop target, class)
        r = subprocess.run(["java", "-cp", DUMP_CP, "LivenessDump", "A"] + opts,
                           cwd=td, capture_output=True, text=True, timeout=180)
        (case / "out.txt").write_text(r.stdout)
        # struct.txt: the normalization projection (OrderOfSolution decomposition
        # — the live-expression / oos / pem parity target for lib/temporal.hoon,
        # unit 8.1). Independent of the extra tlc args (options do not affect the
        # temporal normalization), so LivenessStruct takes no opts.
        s = subprocess.run(["java", "-cp", DUMP_CP, "LivenessStruct", "A"],
                           cwd=td, capture_output=True, text=True, timeout=180)
        (case / "struct.txt").write_text(s.stdout)
        # product.txt: the behavior-graph PRODUCT projection (per OrderOfSolution
        # product node + initial-node counts) — the unit 8.3 parity target for
        # lib/liveness. Drives a standalone LiveCheck over the reachable graph;
        # deterministic per fixture (FP64 index 0, a set not a run order).
        p = subprocess.run(["java", "-cp", DUMP_CP, "ProductDump", "A"],
                           cwd=td, capture_output=True, text=True, timeout=180)
        (case / "product.txt").write_text(p.stdout)


def main() -> None:
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "A.tla").exists():
            golden(case)
            n += 1
    print(f"{n} liveness cases")
    print(f"TOTAL {n}")


if __name__ == "__main__":
    main()
