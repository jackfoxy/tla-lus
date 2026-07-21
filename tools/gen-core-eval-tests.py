#!/usr/bin/env python3
"""Capture core-evaluation goldens from the EvalDump oracle (unit 6).

Each case lives in desk/test-data/eval-core/<case>/ as A.tla plus A.txt (the
.cfg content). EvalDump builds a FastTool (SANY analyze + SpecProcessor config)
and evaluates every arity-0 root-module definition via Tool.eval, printing a
UID-free projection of each value (kind + canonical rendering) or its typed
evaluation failure. The .cfg is staged into a temp dir as A.cfg (the desk has
no %cfg Clay mark, so the corpus stores it as A.txt).

Until the semantic-node evaluator lands (subunit 6.5), this is oracle-only: it
only refreshes golden-eval.txt. The existing REPL corpus (gen-eval-tests /
tests/lib/tla/eval, 37 cases) stays the unchanged smoke suite. Once
lib/tla/tlc exposes a semantic-node evaluator this emits a differential shard.
Never edit generated files.
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
DUMP_CP = f"{JAR}:{REPO}/tools/oracle/build"
CASES = REPO / "desk/test-data/eval-core"


def golden(case: Path) -> None:
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        shutil.copy(case / "A.tla", tdp / "A.tla")
        shutil.copy(case / "A.txt", tdp / "A.cfg")
        r = subprocess.run(["java", "-cp", DUMP_CP, "EvalDump", "A"],
                           cwd=td, capture_output=True, text=True)
    (case / "golden-eval.txt").write_text(r.stdout)


def main() -> None:
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "A.tla").exists():
            golden(case)
            n += 1
    print(f"{n} eval-core cases")
    print(f"TOTAL {n}")


if __name__ == "__main__":
    main()
