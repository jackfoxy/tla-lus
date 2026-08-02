#!/usr/bin/env python3
"""Tier-2 matrix generator (Release R1, sub-unit R1.1).

Tier-2 is the broad, nightly differential layer described in `doc/testing.md`:
the `tlaplus/test-model` corpus plus the curated `tlaplus-Examples` matrix, run
through the Java oracle (SANY, and TLC where a spec has a model) and — from
R1.1.1 on — through the Hoon units 4-11 for comparison.

This generator does two things, both byte-reproducible from the pins:

  1. CLASSIFY every spec in both corpora into the ported scope map
     (`desk/test-data/tier2/inventory.txt`): `sany`, `check-safety`,
     `check-liveness`, or `excluded:<reason>`. The classification rules are
     total, so a spec added upstream lands in some bucket; the frozen file then
     drifts, which `tools/tier2.py --check` catches (the drift guard).

  2. Capture the Java oracle projection for a small, self-contained CURATED set
     (`desk/test-data/tier2/oracle/<name>.txt`) — a normalized SANY verdict and,
     where the spec has a model, a normalized TLC verdict + state counts + trace.
     Nondeterministic header/footer noise (version, seed, pid, timestamps, temp
     paths, GC warning, runtime) is stripped so the projection is stable.

R1.1.0 stops here (oracle-only, no Hoon comparator yet), mirroring every prior
unit's `.0` kickoff. The Hoon side and the full-corpus run set are R1.1.1+.

  tools/gen-tier2-tests.py            regenerate inventory + curated oracle
  tools/gen-tier2-tests.py --list     print the classification histogram only
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
TLAPLUS = Path("/mnt/mars/gitrepos/tlaplus")
EXAMPLES = Path("/mnt/mars/gitrepos/tlaplus-Examples")
JAR = TLAPLUS / "tlatools/org.lamport.tlatools/dist/tla2tools.jar"
TESTMODEL = TLAPLUS / "tlatools/org.lamport.tlatools/test-model"

PIN_TLAPLUS = "4ba7d8811289fb8e95dac4d5e554c05216ba3100"
PIN_EXAMPLES = "47b0e2cc0268836b89f5ce451f38e5df5f1cf773"

OUT = REPO / "desk/test-data/tier2"

# The 20 vendored StandardModules (public + internal `_*`); a spec whose
# EXTENDS/INSTANCE closure stays inside these + repo-local modules parses.
VENDORED = {
    "Bags", "FiniteSets", "Integers", "Json", "Naturals", "Randomization",
    "Reals", "RealTime", "Sequences", "TLC", "TLCExt", "Toolbox",
    "_DotTrace", "_JsonTrace", "_Possible", "_TLAPlusCounterExample",
    "_TLCActionTrace", "_TLCTESpec", "_TLCTrace", "_TLCTracePlain",
}
# Operator overrides at parity (tlc-module-* rows). A spec that EXTENDS only
# these can be model-checked; extending TLCExt/Json/Randomization/Reals/Toolbox
# pulls in operators the ledger marks excluded (typed reject), so the check is
# out of scope even though SANY parses it.
CHECK_MODS = {"Naturals", "Integers", "Sequences", "FiniteSets", "Bags", "TLC"}

PLUSCAL = re.compile(r"^\s*\(\*.*\b(--algorithm|--fair\s+algorithm)\b", re.M)
PLUSCAL2 = re.compile(r"^\s*--(fair\s+)?algorithm\b", re.M)


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def check_pin() -> bool:
    ok = True
    for repo, pin in ((TLAPLUS, PIN_TLAPLUS), (EXAMPLES, PIN_EXAMPLES)):
        h = sh(["git", "-C", str(repo), "rev-parse", "HEAD"]).stdout.strip()
        if h != pin:
            print(f"off-pin: {repo} at {h[:9]}, expected {pin[:9]}",
                  file=sys.stderr)
            ok = False
    return ok


# ---------------------------------------------------------------- classify ---
def module_refs(text: str) -> set:
    """EXTENDS names + INSTANCE targets referenced by a module's text."""
    refs = set()
    for m in re.findall(r"^\s*EXTENDS\s+(.+)$", text, re.M):
        refs |= {s.strip() for s in m.split(",") if s.strip()}
    refs |= set(re.findall(r"\bINSTANCE\s+([A-Za-z_][A-Za-z0-9_]*)", text))
    return refs


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def is_pluscal(text: str) -> bool:
    return bool(PLUSCAL.search(text) or PLUSCAL2.search(text))


def classify(text: str, local: set, has_cfg: bool):
    """Return (klass, detail). `local` = module names resolvable in the same
    corpus dir. Rules are total."""
    if is_pluscal(text):
        return "excluded", "pluscal"
    refs = module_refs(text)
    unresolved = {r for r in refs if r not in VENDORED and r not in local}
    if unresolved:
        return "excluded", "module:" + ",".join(sorted(unresolved))
    if has_cfg and refs <= CHECK_MODS:
        return "check", ""          # safety/liveness decided by the cfg/run
    if has_cfg:
        # parses + has a model, but pulls in an excluded-operator module
        return "sany", "check-excluded:" + ",".join(
            sorted(refs - CHECK_MODS - {""}))
    return "sany", ""


def testmodel_rows():
    local = {p.stem for p in TESTMODEL.rglob("*.tla")}
    rows = []
    for tla in sorted(TESTMODEL.rglob("*.tla")):
        cfg = tla.with_suffix(".cfg")
        k, d = classify(read(tla), local, cfg.exists())
        rel = tla.relative_to(TESTMODEL)
        rows.append(("test-model", str(rel), k, d))
    return rows


def examples_rows():
    import json
    rows = []
    for mf in sorted(EXAMPLES.glob("specifications/**/manifest.json")):
        m = json.load(open(mf))
        base = EXAMPLES
        for md in m.get("modules", []):
            path = md["path"]
            tla = base / path
            local = {p.stem for p in (base / os.path.dirname(path)).glob("*.tla")}
            feats = md.get("features", [])
            if feats:
                rows.append(("examples", path, "excluded",
                             "feature:" + ",".join(sorted(feats))))
                continue
            if "proof" in md:
                rows.append(("examples", path, "excluded", "proof"))
                continue
            has_model = any(mo.get("mode") == "exhaustive search"
                            for mo in md.get("models", []))
            k, d = classify(read(tla) if tla.exists() else "", local, has_model)
            rows.append(("examples", path, k, d))
    return rows


def write_inventory(rows):
    from collections import Counter
    hist = Counter(f"{k}:{d.split(':')[0]}" if d else k for _, _, k, d in rows)
    lines = [
        "# Tier-2 scope inventory (GENERATED by tools/gen-tier2-tests.py)",
        f"# oracle pins: tlaplus@{PIN_TLAPLUS[:9]} tlaplus-Examples@{PIN_EXAMPLES[:9]}",
        "# columns: corpus | path | class | detail",
        "# class: sany | check | excluded  (check = SANY + TLC, ported ops only)",
        "#",
        "# histogram:",
    ]
    for k in sorted(hist):
        lines.append(f"#   {k:28s} {hist[k]}")
    lines += ["#", f"# total: {len(rows)} modules", ""]
    for corpus, path, k, d in rows:
        lines.append(f"{corpus}\t{path}\t{k}\t{d}")
    (OUT / "inventory.txt").write_text("\n".join(lines) + "\n")
    return hist


# ------------------------------------------------------------- oracle run ---
# The curated R1.1.0 run set: small, self-contained specs proven to run clean,
# spanning every verdict class. (corpus, dir, module, cfg-or-None, note)
CURATED = [
    # SANY-only rejects / accepts from test-model
    ("test-model", TESTMODEL, "Empty", None, "sany accept, minimal module"),
    # safety / liveness / deadlock from test-model (self-contained, tiny)
    ("test-model", TESTMODEL, "DieHard", "DieHard.cfg", "safety violation"),
    # Examples: small ported-only success models
    ("examples", EXAMPLES / "specifications/SpecifyingSystems/HourClock",
     "HourClock", "HourClock.cfg", "safety ok, 12 states"),
    ("examples", EXAMPLES / "specifications/transaction_commit",
     "TCommit", "TCommit.cfg", "safety ok, 34 states"),
    ("examples", EXAMPLES / "specifications/CigaretteSmokers",
     "CigaretteSmokers", "CigaretteSmokers.cfg", "safety ok, 6 states"),
    ("examples", EXAMPLES / "specifications/allocator",
     "SimpleAllocator", "SimpleAllocator.cfg", "safety ok, 400 states"),
]

TEMP_PATH = re.compile(r"/tmp/[^ )]*|(?:jar:)?file:[^ )]*|/mnt/[^ )]*\.tla")


def norm_sany(module: str, spec: Path) -> str:
    r = sh(["java", "-cp", str(JAR), "tla2sany.SANY", spec.name], cwd=spec.parent)
    out = r.stdout + r.stderr
    err = []
    capture = False
    for ln in out.splitlines():
        s = ln.rstrip()
        if s.startswith("*** Errors") or "Parse Error" in s or "Abort" in s \
                or s.startswith("Fatal errors") or s.startswith("Unrecoverable"):
            capture = True
        if not capture:
            continue
        if s.startswith("Parsing file") or s.startswith("Semantic processing") \
                or s.startswith("Linting"):
            continue
        err.append(TEMP_PATH.sub("<path>", s))
    verdict = "accept" if r.returncode == 0 and not err else "reject"
    lines = [f"SANY {verdict}"]
    if err:
        lines += [e for e in err if e]
    return "\n".join(lines).rstrip() + "\n"


STATE_HDR = re.compile(r"^State \d+: ")
STATS = re.compile(r"^(\d+) states generated, (\d+) distinct states found, "
                   r"(\d+) states left on queue")
DEPTH = re.compile(r"^The depth of the complete state graph search is (\d+)")


def norm_tlc(module: str, spec_dir: Path, cfg: str) -> str:
    # Run in an isolated temp dir so TLC's state metadata and any trace-
    # exploration spec (`<Spec>_TTrace_*.tla/.bin`) never pollute the pinned
    # oracle checkout. Copy the spec's siblings (multi-file specs INSTANCE
    # local modules) + the config in; `-noGenerateSpecTE` suppresses the TE
    # spec, `-metadir` keeps states/fp out of even the temp spec dir.
    with tempfile.TemporaryDirectory(prefix="tier2-") as td:
        td = Path(td)
        for f in Path(spec_dir).glob("*.tla"):
            shutil.copy2(f, td / f.name)
        shutil.copy2(Path(spec_dir) / cfg, td / cfg)
        meta = td / "meta"
        r = sh(["java", "-cp", str(JAR), "tlc2.TLC", "-workers", "1",
                "-noGenerateSpecTE", "-metadir", str(meta),
                "-config", cfg, module], cwd=td, timeout=180)
    out = r.stdout + r.stderr
    verdict = None
    stats = depth = None
    trace = []
    in_trace = False
    for ln in out.splitlines():
        s = ln.rstrip()
        if s.startswith("Error: Invariant") and "violated" in s:
            verdict = "violated:" + s.split("Invariant", 1)[1].split(
                "is violated")[0].strip()
        elif s.startswith("Error: Temporal property") and "violated" in s:
            verdict = "violated-property"
        elif s.startswith("Error: Deadlock"):
            verdict = "deadlock"
        elif s.startswith("Error: Assumption") or "Assumption" in s and "false" in s:
            verdict = verdict or "assumption-false"
        elif s.startswith("Model checking completed"):
            verdict = verdict or "ok"
        elif s.startswith("Error:") and verdict is None:
            verdict = "error:" + TEMP_PATH.sub("<path>", s[6:].strip())[:80]
        m = STATS.match(s)
        if m:
            stats = m.groups()
        m = DEPTH.match(s)
        if m:
            depth = m.group(1)
        if s.startswith("Error: The behavior up to this point is"):
            in_trace = True
            continue
        if in_trace:
            if STATE_HDR.match(s):
                trace.append(TEMP_PATH.sub("<path>", s))
            elif s.startswith("/\\") or s.startswith("|"):
                trace.append(s)
            elif s == "" or s.startswith("Error:") or s.startswith(str(module)):
                pass
            elif re.match(r"^\d+ states generated", s):
                in_trace = False
    lines = [f"TLC {verdict or 'unknown'}"]
    if stats:
        lines.append(f"STATES {stats[0]} {stats[1]} {stats[2]}")
    if depth:
        lines.append(f"DEPTH {depth}")
    if trace:
        lines.append("TRACE")
        lines += trace
    return "\n".join(lines).rstrip() + "\n"


def run_curated():
    odir = OUT / "oracle"
    odir.mkdir(parents=True, exist_ok=True)
    for corpus, sdir, module, cfg, note in CURATED:
        spec = Path(sdir) / f"{module}.tla"
        body = [f"# {corpus}: {module}  ({note})"]
        body.append(norm_sany(module, spec).rstrip())
        if cfg:
            body.append(norm_tlc(module, Path(sdir), cfg).rstrip())
        (odir / f"{module}.txt").write_text("\n".join(body) + "\n")
        print(f"  oracle {module}: "
              f"{'sany+tlc' if cfg else 'sany'}")


def main() -> int:
    if "--list" not in sys.argv and not check_pin():
        return 2
    OUT.mkdir(parents=True, exist_ok=True)
    rows = testmodel_rows() + examples_rows()
    hist = write_inventory(rows)
    print("tier-2 inventory:")
    for k in sorted(hist):
        print(f"  {k:28s} {hist[k]}")
    print(f"  {'TOTAL':28s} {len(rows)}")
    if "--list" in sys.argv:
        return 0
    print("curated oracle capture:")
    run_curated()
    return 0


if __name__ == "__main__":
    sys.exit(main())
