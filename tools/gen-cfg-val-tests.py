#!/usr/bin/env python3
"""Capture config-vs-graph validation goldens from the ConfigValidate oracle
(unit 5.3).

Each case lives in desk/test-data/cfg-val/<case>/ as A.tla plus in.txt (the
.cfg content). ConfigValidate drives tlc2.tool.impl.FastTool (SANY parse ->
SpecProcessor.processConfig) and reports the config-semantic verdict: `ok`,
or a `<code> <span>` line plus the rendered TLC_CONFIG_* message (processConfig
fails fast, so at most one). The .cfg is staged into a temp dir as A.cfg
because FastTool/getConfig requires the .cfg extension (the desk has no %cfg
Clay mark, so the corpus stores it as in.txt).

Until the Hoon config validator lands (subunit 5.3b), this is oracle-only: it
only refreshes golden-val.txt. Once lib/tla/config exposes validate-config
against the WU3 graph this will emit a differential shard. Never edit
generated files.
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
DUMP_CP = f"{JAR}:{REPO}/tools/oracle/build"
CASES = REPO / "desk/test-data/cfg-val"


def golden(case: Path) -> None:
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        shutil.copy(case / "A.tla", tdp / "A.tla")
        shutil.copy(case / "in.txt", tdp / "A.cfg")
        r = subprocess.run(["java", "-cp", DUMP_CP, "ConfigValidate", "A"],
                           cwd=td, capture_output=True, text=True)
    (case / "golden-val.txt").write_text(r.stdout)


def main() -> None:
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "A.tla").exists():
            golden(case)
            n += 1
    print(f"{n} cfg-val cases")
    print(f"TOTAL {n}")


if __name__ == "__main__":
    main()
