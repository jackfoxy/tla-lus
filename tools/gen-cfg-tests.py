#!/usr/bin/env python3
"""Capture TLC .cfg parse goldens from the ConfigDump oracle (unit 5).

Each case lives in desk/test-data/cfg/<case>/in.txt. Goldens come from
`ConfigDump in.txt` (a normalized, UID-free projection of the ModelConfig
config AST + rawConstants, or a CONFIG-ERROR section with the exact
ConfigFileException message). This captures each case's golden.txt.

Until the Hoon config parser (lib/tla/config or check.hoon cfg stage,
subunits 5.1/5.2) lands, this is oracle-only: it only refreshes goldens.
Once the parser exposes a dump-cfg entrypoint this will also emit a
differential shard (desk/tests/lib/tla/cfg.hoon) comparing the Hoon
projection against these goldens. Never edit generated files.
"""
import subprocess
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
DUMP_CP = f"{JAR}:{REPO}/tools/oracle/build"
CASES = REPO / "desk/test-data/cfg"


def golden(case: Path) -> None:
    r = subprocess.run(["java", "-cp", DUMP_CP, "ConfigDump", "in.txt"],
                       cwd=case, capture_output=True, text=True)
    (case / "golden.txt").write_text(r.stdout)


def main() -> None:
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "in.txt").exists():
            golden(case)
            n += 1
    print(f"{n} cfg cases")
    print(f"TOTAL {n}")


if __name__ == "__main__":
    main()
