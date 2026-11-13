#!/usr/bin/env python3
"""Time the pinned tlc2 on tlaplus-Examples models, single-threaded, for the
comparison in desk/doc/performance.md.

Each model runs as the goldens run it (tools/examples-oracle.py): CI's module
path (the jar, Apalache.tla, the spec's directory, CommunityModules, the
TLAPS library), `-workers 1 -fp 0 -seed 0 -noGenerateSpecTE -cleanup`, and
`-Dtlc2.tool.impl.Tool.cdot=true` for an "action composition" model. The wall
clock includes JVM start-up, as the port's includes its submit and polling.

  tools/tlc2-timings.py OUT MODEL-SUFFIX...    append one JSON line per model

A model is named by any suffix of its manifest path (`MCVoting.cfg`,
`ewd426/TokenRing.cfg`).
"""
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXAMPLES = Path("/mnt/mars/gitrepos/tlaplus-Examples")
DEPS = Path(os.environ.get("R4_DEPS", "/mnt/mars/gitrepos/r4-deps"))
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/"
           "tla2tools.jar")
TLAPM = Path("/mnt/mars/gitrepos/tlapm/library")
WORK = REPO / "desk/test-data/blackbox/models.json"


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    out = Path(sys.argv[1])
    models = {m["model"]: m for m in json.loads(WORK.read_text())["models"]}
    for name in sys.argv[2:]:
        hits = [m for k, m in models.items() if k.endswith(name)]
        if len(hits) != 1:
            print(f"{name}: {len(hits)} models match", file=sys.stderr)
            return 1
        m = hits[0]
        d = EXAMPLES / os.path.dirname(m["module"])
        cp = ":".join(str(p) for p in (JAR, DEPS / "apalache/lib/apalache.jar", d,
                                        DEPS / "CommunityModules-deps.jar", TLAPM))
        flags = (["-Dtlc2.tool.impl.Tool.cdot=true"]
                 if "action composition" in m.get("features", []) else [])
        cmd = (["java", "-XX:+UseParallelGC", "-cp", cp] + flags +
               ["tlc2.TLC", os.path.basename(m["module"]),
                "-config", os.path.relpath(EXAMPLES / m["model"], d),
                "-workers", "1", "-fp", "0", "-seed", "0",
                "-noGenerateSpecTE", "-cleanup"])
        t0 = time.time()
        try:
            r = subprocess.run(cmd, cwd=d, capture_output=True, text=True,
                               timeout=1800)
            text, timed_out = r.stdout + r.stderr, False
        except subprocess.TimeoutExpired:
            text, timed_out = "", True
        fin = re.search(r"Finished in (\S+)", text)
        row = {"model": m["model"], "wall_s": round(time.time() - t0, 1),
               "timeout": timed_out, "tlc_finished": fin.group(1) if fin else None}
        with out.open("a") as f:
            f.write(json.dumps(row) + "\n")
        print(row, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
