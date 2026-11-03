#!/usr/bin/env python3
"""The upstream license files (R5.1).

Every third-party text this repo stores, or stages onto the `%tla-ex` desk,
carries its upstream's LICENSE verbatim from the PINNED commit, under a header
naming the repo, the pin and what the file covers:

  licenses/<name>-license.txt     one per upstream (this script writes them)

`tools/examples.py --stage` copies the matching file into each directory it
stages (`tlapm/`, `community/`, `apalache/`, `specifications/`) as
`license.txt`. The tlaplus tools themselves are covered by the MIT headers the
scaffold gate already checks (`lib/stdmods.hoon`).

  tools/gen-licenses.py            (re)write licenses/
  tools/gen-licenses.py --check    the scaffold gate's provenance clause:
                                   licenses/ equals what the pins give, and
                                   every tlapm- or tlauc-derived file in the
                                   repo has a license.txt beside it

The pins are read from tools/r4-deps.sh (the single source of the R4 pins)
and, for tlaplus-Examples, from desk/doc/port-map.md's table.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GIT = Path("/mnt/mars/gitrepos")
OUT = REPO / "licenses"
DEPS_SH = REPO / "tools/r4-deps.sh"
EXAMPLES_PIN = "47b0e2cc0268836b89f5ce451f38e5df5f1cf773"


def pin(var: str) -> str:
    m = re.search(rf'^{var}="([^"]+)"', DEPS_SH.read_text(), re.M)
    if not m:
        raise SystemExit(f"{var} not found in {DEPS_SH}")
    return m.group(1)


#  name, checkout, url, pin, tag, SPDX, license files at the pin, what it covers
def upstreams():
    return [
        ("tlapm", GIT / "tlapm", "https://github.com/tlaplus/tlapm",
         pin("PIN_TLAPM_COMMIT"), "main", "BSD-2-Clause", ["LICENSE"],
         "the tlapm library modules (library/*.tla) staged onto %tla-ex "
         "under tlapm/ by tools/examples.py --stage; module resolution and "
         "parse goldens that name them"),
        ("tlauc", GIT / "tlauc", "https://github.com/tlaplus-community/tlauc",
         pin("PIN_TLAUC_COMMIT"), pin("PIN_TLAUC_TAG"), "MIT", ["LICENSE"],
         "modules converted by tlauc (R4.4, clause 8) and the goldens taken "
         "from them, stored under desk/test-data/unicode/"),
        ("communitymodules", GIT / "CommunityModules",
         "https://github.com/tlaplus/CommunityModules",
         pin("PIN_COMMUNITY_COMMIT"), pin("PIN_COMMUNITY_TAG"), "MIT", ["LICENSE"],
         "the CommunityModules release modules staged onto %tla-ex under "
         "community/, and the module texts quoted by tests/lib/cmops"),
        ("apalache", GIT / "apalache", "https://github.com/apalache-mc/apalache",
         pin("PIN_APALACHE_COMMIT"), pin("PIN_APALACHE_TAG"), "Apache-2.0",
         ["LICENSE", "NOTICE"],
         "the Apalache StandardModules (Apalache, Variants, Option, ...) "
         "staged onto %tla-ex under apalache/"),
        ("tlaplus-examples", GIT / "tlaplus-Examples",
         "https://github.com/tlaplus/Examples", EXAMPLES_PIN, "", "MIT",
         ["LICENSE.md"],
         "the Examples specifications and models staged onto %tla-ex under "
         "specifications/"),
    ]


def text_of(name, repo, url, commit, tag, spdx, files, covers) -> str:
    head = [
        f"Upstream: {url}",
        f"Pinned commit: {commit}" + (f" ({tag})" if tag else ""),
        f"License: {spdx}",
        f"Covers: {covers}",
        "",
        "The upstream license text follows verbatim, as it stands at the "
        "pinned commit.",
        "",
    ]
    body = []
    for f in files:
        t = subprocess.run(["git", "-C", str(repo), "show", f"{commit}:{f}"],
                           capture_output=True, text=True, check=True).stdout
        body += [f"===== {f} =====", "", t.rstrip("\n"), ""]
    return "\n".join(head + body) + "\n"


def wanted() -> dict:
    return {OUT / f"{u[0]}-license.txt": text_of(*u) for u in upstreams()}


def tlapm_modules() -> set:
    u = next(x for x in upstreams() if x[0] == "tlapm")
    ls = subprocess.run(["git", "-C", str(u[1]), "ls-tree", "--name-only",
                         f"{u[3]}", "library/"],
                        capture_output=True, text=True, check=True).stdout
    return {Path(p).name.lower() for p in ls.split() if p.endswith(".tla")}


def coverage_faults() -> list:
    """Files in the repo that carry tlapm or tlauc material without a
    license.txt beside them"""
    faults = []
    names = tlapm_modules()
    for f in (REPO / "desk").rglob("*.tla"):
        if f.name.lower() in names and not (f.parent / "license.txt").exists():
            faults.append(f"{f.relative_to(REPO)}: a tlapm library module "
                          "with no license.txt beside it")
    uni = REPO / "desk/test-data/unicode"
    if uni.exists() and not (uni / "license.txt").exists():
        faults.append("desk/test-data/unicode/: tlauc output with no license.txt")
    return faults


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    w = wanted()
    if not a.check:
        OUT.mkdir(exist_ok=True)
        for p, t in w.items():
            p.write_text(t)
            print(f"wrote {p.relative_to(REPO)}")
        return 0
    bad = [f"{p.relative_to(REPO)}: missing or not what the pin gives"
           for p, t in w.items() if not p.exists() or p.read_text() != t]
    extra = sorted(set(OUT.glob("*-license.txt")) - set(w))
    bad += [f"{p.relative_to(REPO)}: no upstream of that name" for p in extra]
    bad += coverage_faults()
    for b in bad:
        print(f"  FAIL {b}")
    if not bad:
        print(f"  ok   {len(w)} upstream licenses match their pins; "
              "every tlapm/tlauc-derived file is covered")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
