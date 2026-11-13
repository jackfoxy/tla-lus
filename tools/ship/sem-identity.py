#!/usr/bin/env python3
"""R4.4 (clause 8): the structural-identity census. For every module of
parse.json, runs `+tla-lus!sem-identity` (tools/ship/sem-identity.hoon,
copied to the %tla-lus mount's gen/) in tla-zod's dojo, which compares the
SemDump projection of the %tla-ex ASCII original with that of its tlauc
conversion under `unicode/` (`tools/examples.py --stage`), columns elided.

  tools/ship/sem-identity.py [--only S] [--census FILE] [--cap-secs N]

The census is append-only JSON lines and resumable. A long run: ask first.
The dojo is driven through tmux, one command at a time, each guarded by
tla-zod-tools/guarded.sh (one C-c past the RSS or time cap).
"""
import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
PARSE = REPO / "desk/test-data/blackbox/parse.json"
GUARD = "/mnt/mars/piers/tla-zod-tools/guarded.sh"
LINE = re.compile(r"'sem-identity (\S+) a=(\w+) u=(\w+) n=(\d+)/(\d+) "
                  r"same=([yn])(.*)'")


def pane() -> str:
    return subprocess.run(["tmux", "capture-pane", "-pt", "tla-zod", "-J",
                           "-S", "-40"], capture_output=True, text=True).stdout


def one(root: str, sdir: str, cap: int) -> dict:
    #  through +stab: the dojo refuses a path literal whose segment holds a
    #  `.` (`cartalkpuzzle.toolbox`)
    cmd = f"+tla-lus!sem-identity '{root}' (stab '/{sdir}')"
    t0 = time.time()
    g = subprocess.run([GUARD, cmd, "2500", str(cap)], capture_output=True,
                       text=True)
    secs = round(time.time() - t0, 1)
    if "INTR" in g.stdout or "refusing" in g.stdout or "TOO HIGH" in g.stdout:
        return {"status": "interrupted", "guard": g.stdout.strip()[-200:],
                "secs": secs}
    time.sleep(1)
    #  only what follows this command's own echo: a module of the same name
    #  in another directory may still be on the screen
    out = pane().rsplit(f"> {cmd}", 1)[-1]
    hits = [m for m in LINE.finditer(out) if m.group(1) == root]
    if not hits:
        return {"status": "no-output", "secs": secs}
    m = hits[-1]
    return {"status": "ok", "ascii": m.group(2), "unicode": m.group(3),
            "lines": [int(m.group(4)), int(m.group(5))],
            "same": m.group(6) == "y", "diff": m.group(7).strip(),
            "secs": secs}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--census",
                    default=str(REPO / "desk/test-data/blackbox/"
                                "unicode-identity-census.txt"))
    ap.add_argument("--cap-secs", type=int, default=1800)
    a = ap.parse_args()
    work = [m["module"] for m in json.loads(PARSE.read_text())["parse"]]
    if a.only:
        work = [m for m in work if a.only in m]
    census = Path(a.census)
    done = set()
    if census.exists():
        done = {json.loads(l)["module"] for l in census.read_text().splitlines()
                if l}
    print(f"{len(work)} modules, {len(done)} done", flush=True)
    for mod in work:
        if mod in done:
            continue
        p = Path(mod)
        row = one(p.stem, str(p.parent).lower(), a.cap_secs)
        row = {"module": mod, **row}
        with census.open("a") as f:
            f.write(json.dumps(row) + "\n")
        print(f"{mod}: {row['status']} {row.get('ascii', '')}/"
              f"{row.get('unicode', '')} same={row.get('same')} "
              f"{row['secs']}s {row.get('diff', '')}"[:200], flush=True)
        if row["status"] != "ok":
            print("stopping: the dojo needs a look", flush=True)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
