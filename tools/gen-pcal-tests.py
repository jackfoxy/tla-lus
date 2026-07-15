#!/usr/bin/env python3
"""Capture PlusCal-translation goldens from the Java oracle (pcal.trans).

Each case lives in desk/test-data/pcal/<case>/in.tla with a PlusCal
--algorithm block. `pcal.trans` rewrites a copy in place, inserting the
generated TLA+ between BEGIN/END TRANSLATION (with chksum(pcal)/chksum(tla)
CRC-32 markers) and writing a .cfg. This captures the rewritten .tla as
golden.tla and the .cfg as golden-cfg.txt, and records the two checksums.

The Hoon translator is not yet ported (unit 8 is multi-increment; see
tools/notes/unit8-pluscal-notes.md), so this only refreshes goldens. Once
lib/tla/pcal/* exists this will also emit a differential shard comparing the
Hoon translation + checksums against these goldens. Never edit generated files.
"""
import re
import shutil
import subprocess
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
CASES = REPO / "desk/test-data/pcal"

MARKER = re.compile(
    r'BEGIN TRANSLATION \(chksum\(pcal\) = "([0-9a-f]+)" '
    r'/\\ chksum\(tla\) = "([0-9a-f]+)"\)')


def golden(case: Path) -> None:
    work = case / "work.tla"
    shutil.copy(case / "in.tla", work)
    subprocess.run(["java", "-cp", str(JAR), "pcal.trans", "work.tla"],
                   cwd=case, capture_output=True, text=True)
    if work.exists():
        text = work.read_text()
        (case / "golden.tla").write_text(text)
        m = MARKER.search(text)
        if m:
            (case / "checksums.txt").write_text(
                f"pcal {m.group(1)}\ntla {m.group(2)}\n")
    cfg = case / "work.cfg"
    if cfg.exists():
        (case / "golden-cfg.txt").write_text(cfg.read_text())
    for junk in ("work.tla", "work.cfg", "work.old"):
        (case / junk).unlink(missing_ok=True)


def main() -> None:
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "in.tla").exists():
            golden(case)
            n += 1
    print(f"{n} pcal cases")
    print(f"TOTAL {n}")


if __name__ == "__main__":
    main()
