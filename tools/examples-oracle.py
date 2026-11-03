#!/usr/bin/env python3
"""R4.0c: the pinned Java oracle over the whole R4 Examples corpus.

Mirrors upstream Examples CI (`.github/scripts/*` at `47b0e2cc0`) wherever
that does not cost determinism, and records every place it departs:

  * SANY: CI's exact command -- `java -cp <tools:apalache:dir:community:tlapm>
    tla2sany.SANY -error-codes <path>` run from the Examples root -- on all 373
    non-PlusCal modules. Clause 1's golden.
  * Unicode (clause 8): a copy of the corpus converted with CI's own
    `tlauc <module> --skip numsets`, then SANY the same way.
  * TLC: every non-PlusCal, non-`symbolic` model (167). CI's classpath, mode
    flags (`-simulate num=N`, `-generate`) and feature flags (`cdot`).
    DEPARTURES, for determinism: `-workers 1` (CI: the manifest's, default
    `auto`), `-fp 0` (CI: a random polynomial), `-seed 0` in every mode
    (CI: random), and `-noGenerateSpecTE`. CI also passes `-lncheck final`;
    the golden is taken WITHOUT it and every liveness model is run a second
    time WITH it, so whether that flag moves anything is a measured table, not
    an assumption.
  * Small models (recorded runtime <= 30 s, CI's own split) run to completion
    under a hard timeout. Large ones (> 30 s or `unknown`) get the smoke
    projection: CI gives them 5 s; we give SMOKE_SECS, and the golden records
    only "no error before the timeout" or what the run ended with.

Goldens: `desk/test-data/tier2/examples/{sany,sany-unicode,tlc}/<path>.txt`,
plus `pin-vs-manifest.txt` and `lncheck.txt`. A golden is a NORMALIZED
projection (temp paths, timing, versions stripped), so `--check` can demand
byte-identity.

  tools/examples-oracle.py [--jobs N] [--only SUBSTR] [--part sany|unicode|tlc]
  tools/examples-oracle.py --check     regenerate into a temp tree and diff

Long run: ask before starting it (R4 rule). Never run beside a ship `-test`.
"""
import argparse
import concurrent.futures as cf
import filecmp
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import timedelta
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXAMPLES = Path("/mnt/mars/gitrepos/tlaplus-Examples")
TLAPLUS = Path("/mnt/mars/gitrepos/tlaplus")
DEPS = Path(os.environ.get("R4_DEPS", "/mnt/mars/gitrepos/r4-deps"))
JAR = TLAPLUS / "tlatools/org.lamport.tlatools/dist/tla2tools.jar"
APALACHE = DEPS / "apalache/lib/apalache.jar"
COMMUNITY = DEPS / "CommunityModules-deps.jar"
TLAPM = Path("/mnt/mars/gitrepos/tlapm/library")
TLAUC = DEPS / "tlauc"
OUT = REPO / "desk/test-data/tier2/examples"

PIN_TLAPLUS = "4ba7d8811289fb8e95dac4d5e554c05216ba3100"
PIN_EXAMPLES = "47b0e2cc0268836b89f5ce451f38e5df5f1cf773"

SMALL = timedelta(seconds=30)
SMALL_TIMEOUT = 1800          # -workers 1 on this box; CI's 60 s is for auto
SMOKE_SECS = 60
TLC_EXIT = {0: "success", 10: "assumption failure", 11: "deadlock failure",
            12: "safety failure", 13: "liveness failure"}
TEMP = re.compile(r"/tmp/[^ )'\"]*|(?:jar:)?file:[^ )'\"]*|"
                  + re.escape(str(EXAMPLES)) + r"[^ )'\"]*")


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def check_pins() -> bool:
    ok = True
    for repo, pin in ((TLAPLUS, PIN_TLAPLUS), (EXAMPLES, PIN_EXAMPLES)):
        h = sh(["git", "-C", str(repo), "rev-parse", "HEAD"]).stdout.strip()
        if h != pin:
            print(f"off-pin: {repo} at {h[:9]}", file=sys.stderr)
            ok = False
    r = sh([str(REPO / "tools/r4-deps.sh")])
    if r.returncode:
        print(r.stdout, file=sys.stderr)
        ok = False
    return ok


def timespan(s: str) -> timedelta:
    if s == "unknown":
        return timedelta.max
    h, m, sec = map(int, s.split(":"))
    return timedelta(hours=h, minutes=m, seconds=sec)


def mode_of(mo) -> str:
    m = mo["mode"]
    return next(iter(m)) if isinstance(m, dict) else m


def corpus():
    """(modules, models): the R4 corpus, PlusCal out."""
    mods, models = [], []
    for mf in sorted(EXAMPLES.glob("specifications/*/manifest.json")):
        for md in json.load(open(mf))["modules"]:
            if "pluscal" in md.get("features", []):
                continue
            mods.append(md)
            for mo in md.get("models", []):
                if mode_of(mo) != "symbolic":
                    models.append((md, mo))
    return mods, models


def cp(*dirs) -> str:
    return ":".join(str(d) for d in (JAR, APALACHE, *dirs, COMMUNITY, TLAPM))


def norm(text: str, root: Path) -> str:
    t = text.replace(str(root), "<root>")
    return TEMP.sub("<path>", t)


# -------------------------------------------------------------------- SANY ---
def sany(root: Path, path: str) -> str:
    """CI's parse_modules.py command, from the corpus root."""
    r = sh(["java", "-cp", cp(root / os.path.dirname(path)), "tla2sany.SANY",
            "-error-codes", path], cwd=root, timeout=600)
    keep = []
    for ln in (r.stdout + r.stderr).splitlines():
        s = ln.rstrip()
        if (s.startswith("****** SANY") or s.startswith("Parsing file")
                or s.startswith("Semantic processing") or s.startswith("Linting")
                or not s):
            continue
        keep.append(norm(s, root))
    return f"SANY exit {r.returncode}\n" + "".join(l + "\n" for l in keep)


def unicode_root(tmp: Path, mods) -> Path:
    """A converted copy of the corpus, as CI's Unicode leg makes it."""
    root = tmp / "examples-unicode"
    shutil.copytree(EXAMPLES / "specifications", root / "specifications",
                    symlinks=True)
    bad = []
    for md in mods:
        r = sh([str(TLAUC), str(root / md["path"]), "--skip", "numsets"])
        if r.returncode:
            bad.append(f"{md['path']}: tlauc rc={r.returncode}")
    (tmp / "tlauc-failures.txt").write_text("".join(b + "\n" for b in bad))
    return root


# --------------------------------------------------------------------- TLC ---
def tlc_cmd(md, mo, lncheck: bool) -> list:
    flags = ["-Dtlc2.tool.impl.Tool.cdot=true"] \
        if "action composition" in md.get("features", []) else []
    mode = mo["mode"]
    #  `-seed 0` in EVERY mode: tlc2 seeds RandomElement for the BFS too, and
    #  unseeded it draws a seed it never prints (SpanTreeRandom measured it:
    #  two runs, two answers). 0 is the port's default seed.
    run = (["-simulate", f"num={mode['simulate']['traceCount']}"]
           if isinstance(mode, dict) else
           ["-generate"] if mode == "generate" else []) + ["-seed", "0"]
    return (["java", "-XX:+UseParallelGC", "-cp", cp()] + flags +
            ["tlc2.TLC", md["path"], "-config", mo["path"], "-workers", "1",
             "-fp", "0", "-noGenerateSpecTE", "-cleanup"] +
            (["-lncheck", "final"] if lncheck else []) + run)


def sort_bindings(trace: list) -> list:
    """Bindings within each state block sorted: tlc2's print order is a Java
    hash order (approved difference, see gen-tier2-tests.sort_bindings)."""
    out, blk = [], []
    for l in trace:
        if l.startswith("State ") or l.startswith("Back to state "):
            out += sorted(blk) + [l]
            blk = []
        else:
            blk.append(l)
    return out + sorted(blk)


def project(out: str, root: Path) -> list:
    """The tier-2 projection (gen-tier2-tests.tlc_projection's shape): first
    verdict/error line, the full counts line (a comparator drops `generated`
    where the port is known to differ), depth, further `Error:` lines, and the
    sorted-binding trace."""
    verdict = counts = depth = ""
    err, trace, in_trace = [], [], False
    for ln in out.splitlines():
        s = ln.rstrip()
        if s.startswith("Error:") and not in_trace:
            err.append(norm(s, root))
        if not verdict and (s.startswith("Model checking completed")
                            or s.startswith("Error:")):
            verdict = norm(s, root)
        if "distinct states found" in s:
            counts = s          # generated kept: the manifest table needs it
        if s.startswith("The depth of the complete state graph"):
            depth = s
        if (s.startswith("Error: The behavior up to this point is")
                or s.startswith("Error: The following behavior "
                                "constitutes a counter-example")):
            in_trace = True
            continue
        if in_trace:
            if "states generated" in s or s.startswith("Finished"):
                in_trace = False
            elif s:
                trace.append(norm(s, root))
    return [verdict, counts, depth] + err[1:] + sort_bindings(trace)


def tlc(md, mo, lncheck=False) -> str:
    small = timespan(mo["runtime"]) <= SMALL
    with tempfile.TemporaryDirectory(prefix="r4-oracle-") as td:
        root = Path(td)
        sdir = os.path.dirname(md["path"])
        shutil.copytree(EXAMPLES / sdir, root / sdir, symlinks=True)
        cmd = tlc_cmd(md, mo, lncheck)
        try:
            r = sh(cmd + ["-metadir", str(root / "meta")], cwd=root,
                   timeout=SMALL_TIMEOUT if small else SMOKE_SECS)
        except subprocess.TimeoutExpired as e:
            out = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
            errs = [norm(l.rstrip(), root) for l in out.splitlines()
                    if l.startswith("Error:")]
            head = (f"TIMEOUT small {SMALL_TIMEOUT}s" if small
                    else f"SMOKE ok: no error in {SMOKE_SECS}s")
            return "\n".join([head] + errs) + "\n"
        res = TLC_EXIT.get(r.returncode, f"exit {r.returncode}")
        body = project(r.stdout + r.stderr, root)
        return "\n".join([f"RESULT {res}"] + body).rstrip() + "\n"


# -------------------------------------------------------------- the tables ---
COUNTS = re.compile(r"(\d+) distinct states found")
TOTAL = re.compile(r"^(\d+) states generated", re.M)
DEPTHN = re.compile(r"search is (\d+)")


def pin_vs_manifest(models, gold: Path) -> str:
    rows = ["# model | manifest result | pin result | manifest distinct/total/depth"
            " | pin distinct/total/depth | agree",
            "# pin counts are -workers 1 -fp 0; the manifest's were recorded by"
            " upstream CI (workers per manifest, its own tool versions)"]
    for md, mo in models:
        g = (gold / "tlc" / (mo["path"] + ".txt")).read_text()
        first = g.splitlines()[0]
        pres = first[7:] if first.startswith("RESULT ") else first
        d = COUNTS.search(g)
        dp = DEPTHN.search(g)
        man = (mo.get("distinctStates", "-"), mo.get("totalStates", "-"),
               mo.get("stateDepth", "-"))
        tot = TOTAL.search(g)
        pc = (d.group(1) if d else "-", tot.group(1) if tot else "-",
              dp.group(1) if dp else "-")
        agree = pres == mo["result"] or pres.startswith("SMOKE ok")
        for want, got in zip(man, pc):
            if want != "-" and got != "-":
                agree = agree and str(want) == got
        rows.append(f"{mo['path']} | {mo['result']} | {pres} | "
                    f"{man[0]}/{man[1]}/{man[2]} | {pc[0]}/{pc[1]}/{pc[2]} | "
                    f"{'yes' if agree else 'NO'}")
    return "\n".join(rows) + "\n"


def is_liveness(mo) -> bool:
    t = (EXAMPLES / mo["path"]).read_text(errors="ignore")
    t = re.sub(r"\(\*.*?\*\)", "", t, flags=re.S)
    t = re.sub(r"\\\*.*", "", t)
    return bool(re.search(r"^\s*PROPERT(?:Y|IES)\b", t, re.M))


# ------------------------------------------------------------------- main ---
def write(dst: Path, text: str):
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(text)


def generate(out: Path, jobs: int, only: str, parts: set):
    mods, models = corpus()
    if only:
        mods = [m for m in mods if only in m["path"]]
        models = [(m, o) for m, o in models if only in o["path"]]
    print(f"corpus: {len(mods)} modules, {len(models)} TLC models")
    with cf.ThreadPoolExecutor(jobs) as ex, \
            tempfile.TemporaryDirectory(prefix="r4-uc-") as utd:
        if "sany" in parts:
            futs = {ex.submit(sany, EXAMPLES, m["path"]): m for m in mods}
            for f in cf.as_completed(futs):
                write(out / "sany" / (futs[f]["path"] + ".txt"), f.result())
            print("  sany done")
        if "unicode" in parts:
            uroot = unicode_root(Path(utd), mods)
            write(out / "tlauc-failures.txt",
                  (Path(utd) / "tlauc-failures.txt").read_text())
            futs = {ex.submit(sany, uroot, m["path"]): m for m in mods}
            for f in cf.as_completed(futs):
                write(out / "sany-unicode" / (futs[f]["path"] + ".txt"), f.result())
            print("  unicode done")
        if "tlc" in parts:
            futs = {ex.submit(tlc, md, mo): mo for md, mo in models}
            live = [(md, mo) for md, mo in models if is_liveness(mo)]
            lfuts = {ex.submit(tlc, md, mo, True): mo for md, mo in live}
            for f in cf.as_completed(futs):
                write(out / "tlc" / (futs[f]["path"] + ".txt"), f.result())
            rows = ["# liveness models: golden (no -lncheck) vs CI's -lncheck final"]
            for f in cf.as_completed(lfuts):
                mo = lfuts[f]
                same = f.result() == (out / "tlc" / (mo["path"] + ".txt")).read_text()
                rows.append(f"{mo['path']} | {'same' if same else 'DIFFERS'}")
            write(out / "lncheck.txt", "\n".join([rows[0]] + sorted(rows[1:])) + "\n")
            if not only:
                write(out / "pin-vs-manifest.txt", pin_vs_manifest(models, out))
            print("  tlc done")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--only", default="")
    ap.add_argument("--part", action="append",
                    choices=("sany", "unicode", "tlc"))
    a = ap.parse_args()
    if not check_pins():
        return 2
    parts = set(a.part or ("sany", "unicode", "tlc"))
    if not a.check:
        generate(OUT, a.jobs, a.only, parts)
        return 0
    with tempfile.TemporaryDirectory(prefix="r4-check-") as td:
        generate(Path(td), a.jobs, a.only, parts)
        cmp = filecmp.dircmp(OUT, td)
        drift = []

        def walk(c, pre=""):
            drift.extend(pre + f for f in c.diff_files + c.left_only + c.right_only)
            for n, sub in c.subdirs.items():
                walk(sub, pre + n + "/")
        walk(cmp)
        #  a partial regeneration only answers for the parts it produced
        own = {"sany": ("sany/",), "unicode": ("sany-unicode/", "tlauc-failures"),
               "tlc": ("tlc/", "lncheck", "pin-vs-manifest")}
        keep = tuple(x for pt in parts for x in own[pt])
        drift = [d for d in drift if d.startswith(keep)]
        if drift:
            print(f"DRIFT: {len(drift)}")
            for d in drift[:40]:
                print("  " + d)
            return 1
    print("examples oracle reproduces byte-identically")
    return 0


if __name__ == "__main__":
    sys.exit(main())
