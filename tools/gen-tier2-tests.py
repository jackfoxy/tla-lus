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

# The curated SANY comparator set (R1.1.1): self-contained specs whose Hoon
# +sany-verdict AGREES with the pinned Java SANY verdict, compared in the
# generated `desk/tests/lib/tier2.hoon` shard. (corpus, dir, module)
SANY_CURATED = [
    ("test-model", TESTMODEL, "Empty"),               # accept, minimal
    ("test-model", TESTMODEL, "DieHard"),             # accept
    ("test-model", TESTMODEL, "Calculator"),          # reject: EXTENDS a
    #                                                   missing module (CSV) —
    #                                                   resolver parity
    ("examples", EXAMPLES / "specifications/SpecifyingSystems/HourClock",
     "HourClock"),                                    # accept
    ("examples", EXAMPLES / "specifications/transaction_commit",
     "TCommit"),                                      # accept
]

# Known Hoon<->Java SANY divergences on in-scope specs, surfaced by tier 2 and
# owned by a front-end (R1.3) residue — NOT tested green (they would fail), but
# recorded (machine-checked into `divergences.txt`) so the census is explicit
# and a NEW divergence cannot appear silently. (corpus, dir, module, reason)
KNOWN_DIVERGENCES = [
    ("test-model", TESTMODEL, "IllegalOperatorTest",
     "Java rejects, Hoon accepts: `D(D)` passes a higher-order operator where a "
     "first-order 1-parameter operator is expected; the Hoon 4271 check "
     "compares arity only, not the argument operator's own parameter order "
     "(a level-higher-order edge — R1.3)"),
    ("examples", EXAMPLES / "specifications/CigaretteSmokers",
     "CigaretteSmokers",
     "Java accepts, Hoon rejects: the spec passes a `LAMBDA` to a higher-order "
     "operator; LAMBDA is not in the WU3 semantic graph (a unit-3 residue — "
     "R1.3)"),
]

TEMP_PATH = re.compile(r"/tmp/[^ )]*|(?:jar:)?file:[^ )]*|/mnt/[^ )]*\.tla")


# The curated TLC comparator set (R1.1.2): single-file safety specs whose Hoon
# `check:check` verdict + distinct-count agree with the pinned TLC run.
# (corpus, dir, module, cfg)
TLC_CURATED = [
    ("test-model", TESTMODEL, "DieHard", "DieHard.cfg"),   # safety violation
]

# Known Hoon<->TLC divergences on in-scope safety specs (R1.1.2), each an
# assignment-completeness residue owned by R1.5. (corpus, dir, module, cfg,
# reason)
TLC_DIVERGENCES = [
    ("examples", EXAMPLES / "specifications/SpecifyingSystems/HourClock",
     "HourClock", "HourClock.cfg",
     "Hoon check errors `variable is unassigned: hr`: Init is `hr \\in 1..12`, "
     "a nondeterministic `x \\in S` assignment the node-eval solver does not "
     "yet expand (the R1.5 residue)"),
    ("examples", EXAMPLES / "specifications/transaction_commit",
     "TCommit", "TCommit.cfg",
     "Hoon check errors `primed variable is unassigned: rmState`: an action "
     "leaves rmState unconstrained where TLC treats it as an `x' \\in S` / "
     "implicit assignment (the R1.5 residue)"),
]


# R1.1.3 scale-up: the flat single-file in-scope test-model batch, run through
# the Hoon SANY pipeline in one mule-isolated arm and compared en masse to the
# Java verdict. Cap keeps the single arm's runtime bounded.
BATCH_CAP = 119


def sany_batch_modules() -> list:
    """Clean flat top-level test-model specs, in scope (sany/check),
    self-contained (dependency closure is the module itself), and small."""
    local = {p.stem for p in TESTMODEL.glob("*.tla")}
    out = []
    for tla in sorted(TESTMODEL.glob("*.tla")):
        text = read(tla)
        k, _ = classify(text, local, tla.with_suffix(".cfg").exists())
        if k not in ("sany", "check"):
            continue
        if len(dep_closure(TESTMODEL, tla.stem)) != 1 or len(text) > 1800:
            continue
        out.append(tla.stem)
    return out[:BATCH_CAP]


# Modules in the batch whose Hoon +sany-verdict disagrees with Java, discovered
# by running the batch on the ship. Each entry is `<module>:<hoon-outcome>`
# where outcome is `crash` or `hoon=<accept|reject>`; the batch arm asserts the
# actual divergence list equals this frozen set. Populated from the ship run;
# grouped reasons live in `divergences.txt`.
SANY_BATCH_DIVERGENCES = ["IllegalOperatorTest:hoon=accept"]


def sany_verdict(module: str, spec: Path) -> str:
    """Just accept/reject (the comparator key; diagnostic-text parity is
    tier 1's job). Reuses norm_sany's first line."""
    return norm_sany(module, spec).splitlines()[0].split()[1]


def hcord(s: str) -> str:
    """A Hoon single-quoted-cord body (\\-escaped, control chars as \\HH)."""
    out = []
    for ch in s:
        if ch == "\\":
            out.append("\\\\")
        elif ch == "'":
            out.append("\\'")
        elif ch == "\n":
            out.append("\\0a")
        elif ch == "\t":
            out.append("\\09")
        elif ch == "\r":
            out.append("\\0d")
        else:
            out.append(ch)
    return "".join(out)


def dep_closure(spec_dir: Path, module: str) -> dict:
    """{module-name: text} for `module` and the local modules it reaches
    through EXTENDS/INSTANCE. Only the actual dependency closure — test-model
    is one flat directory, so a bare dir glob would embed the whole corpus.
    Vendored StandardModules resolve on the Hoon side and are not embedded."""
    byname = {p.stem: p for p in Path(spec_dir).glob("*.tla")}
    out, queue, seen = {}, [module], set()
    while queue:
        name = queue.pop()
        if name in seen or name not in byname:
            continue
        seen.add(name)
        text = read(byname[name])
        out[name] = text
        for r in module_refs(text):
            if r not in VENDORED and r in byname:
                queue.append(r)
    return out


def write_sany_shard():
    """Generate the Hoon comparator shard: SANY verdict (R1.1.1) + TLC
    verdict/distinct-count (R1.1.2), each vs the pinned Java oracle."""
    lines = [
        "::  GENERATED by tools/gen-tier2-tests.py -- do not edit.",
        "::  Tier-2 comparators (Release R1): each curated spec's Hoon result vs",
        "::  the pinned Java oracle -- SANY accept/reject (R1.1.1, +sany-verdict)",
        "::  and TLC verdict + distinct-count (R1.1.2, check:check).",
        "/+  *test",
        "/=  semantic  /lib/semantic",
        "/=  check  /lib/check",
        "|%",
        "++  drop-gen",
        "  ::  drop the leading `N states generated, ` — the `generated` counter",
        "  ::  has a safety-stats nuance (off-by-one on a violation); `distinct`",
        "  ::  (the state space) and the verdict are the compared at-parity signal",
        "  |=  l=@t",
        "  ^-  @t",
        "  =/  t  (trip l)",
        "  =/  ix  (fand \", \" t)",
        "  ?~  ix  l",
        "  (crip (slag (add 2 i.ix) t))",
        "++  tlc-sum",
        "  ::  verdict line + the distinct/queue counts (trace labels/depth are a",
        "  ::  safety `partial` residue, compared in a later increment)",
        "  |=  w=wain",
        "  ^-  (list @t)",
        "  :~  ?~(w '' i.w)",
        "      =/  c  (skim w |=(l=@t ?=(^ (fand \"distinct states found\" (trip l)))))",
        "      ?~(c '' (drop-gen i.c))",
        "  ==",
        "++  sany-batch-run",
        "  ::  run each batch spec through +sany-verdict under +mule (a crash",
        "  ::  becomes a recorded outcome, not a test abort) and return the sorted",
        "  ::  list of modules whose Hoon verdict disagrees with Java",
        "  |=  b=(list [name=@t jv=?(%accept %reject) src=(list [@t @t])])",
        "  ^-  (list @t)",
        "  =|  out=(list @t)",
        "  |-  ^-  (list @t)",
        "  ?~  b  (sort out lte)",
        "  =/  r  (mule |.((sany-verdict:semantic name.i.b (malt src.i.b))))",
        "  =/  e=@t",
        "    ?-  -.r",
        "      %|  (cat 3 name.i.b ':crash')",
        "      %&  ?:(=(p.r jv.i.b) '' (cat 3 name.i.b (cat 3 ':hoon=' p.r)))",
        "    ==",
        "  $(b t.b, out ?~(e out [e out]))",
    ]
    for corpus, sdir, module in SANY_CURATED:
        spec = Path(sdir) / f"{module}.tla"
        verdict = sany_verdict(module, spec)
        src = dep_closure(sdir, module)
        arm = module.lower().replace("_", "-")
        lines += [
            "::",
            f"++  test-sany-{arm}",
            "  %+  expect-eq",
            f"    !>  %{verdict}",
            "  !>",
            f"  %+  sany-verdict:semantic  '{module}'",
            "  %-  malt",
            "  ^-  (list [@t @t])",
            "  :~",
        ]
        for name, text in src.items():
            lines.append(f"      ['{name}' '{hcord(text)}']")
        lines += ["  =="]
    for corpus, sdir, module, cfg in TLC_CURATED:
        verdict, counts = tlc_summary(module, Path(sdir), cfg)
        counts = counts.split(", ", 1)[1] if ", " in counts else counts
        spec_text = read(Path(sdir) / f"{module}.tla")
        cfg_text = read(Path(sdir) / cfg)
        arm = module.lower().replace("_", "-")
        lines += [
            "::",
            f"++  test-tlc-{arm}",
            "  %+  expect-eq",
            "    !>  ^-  (list @t)",
            "    :~  '" + hcord(verdict) + "'",
            "        '" + hcord(counts) + "'",
            "    ==",
            "  !>",
            "  %-  tlc-sum",
            f"  %+  check:check  '{hcord(spec_text)}'",
            f"  '{hcord(cfg_text)}'",
        ]
    # the batch SANY runner (R1.1.3)
    batch = sany_batch_modules()
    if SANY_BATCH_DIVERGENCES:
        expect = ["    :~  " + "  ".join(f"'{d}'" for d in SANY_BATCH_DIVERGENCES),
                  "    =="]
    else:
        expect = ["    ~"]
    lines += [
        "::",
        "++  test-sany-batch",
        "  %+  expect-eq",
        "    !>  ^-  (list @t)",
        *expect,
        "  !>",
        "  %-  sany-batch-run",
        "  ^-  (list [@t ?(%accept %reject) (list [@t @t])])",
        "  :~",
    ]
    for module in batch:
        jv = sany_verdict(module, TESTMODEL / f"{module}.tla")
        text = read(TESTMODEL / f"{module}.tla")
        lines.append(f"      ['{module}' %{jv} ~[['{module}' '{hcord(text)}']]]")
    lines += ["  =="]
    lines.append("--")
    (REPO / "desk/tests/lib/tier2.hoon").write_text("\n".join(lines) + "\n")
    print(f"  sany shard: {len(SANY_CURATED)} cases -> tests/lib/tier2.hoon")
    # record the known divergence census: in-scope specs where the Hoon result
    # disagrees with the pinned Java oracle. Not tested green; listed so the
    # census is explicit and drift-guarded.
    dl = [
        "# Tier-2 known divergences (GENERATED by gen-tier2-tests.py)",
        "# In-scope specs where the Hoon result disagrees with the pinned Java",
        "# oracle. Not tested green (they would fail); census-tracked so a new",
        "# divergence cannot appear silently. columns: phase | module | reason",
        "",
    ]
    for corpus, sdir, module, reason in KNOWN_DIVERGENCES:
        jv = sany_verdict(module, Path(sdir) / f"{module}.tla")
        hoon = "accept" if jv == "reject" else "reject"
        dl.append(f"sany\t{module}\tjava={jv} hoon={hoon}: {reason}")
    for corpus, sdir, module, cfg, reason in TLC_DIVERGENCES:
        dl.append(f"tlc\t{module}\t{reason}")
    nb = len(sany_batch_modules())
    dl += [
        "",
        f"# batch (R1.1.3): {nb} flat single-file in-scope test-model specs run "
        "through +sany-verdict",
        f"# in one mule-isolated arm; {len(SANY_BATCH_DIVERGENCES)} disagree with "
        f"Java ({nb - len(SANY_BATCH_DIVERGENCES)}/{nb} agree):",
    ]
    for d in SANY_BATCH_DIVERGENCES:
        dl.append(f"batch\t{d}")
    (OUT / "divergences.txt").write_text("\n".join(dl) + "\n")
    n = len(KNOWN_DIVERGENCES) + len(TLC_DIVERGENCES)
    print(f"  divergences: {n} recorded -> tier2/divergences.txt")


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


def run_tlc(module: str, spec_dir: Path, cfg: str) -> str:
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
    return r.stdout + r.stderr


def tlc_summary(module: str, spec_dir: Path, cfg: str) -> tuple:
    """The robust at-parity TLC signal a Hoon run reproduces: the raw verdict
    line and the distinct-count line (trace-label / depth parity is a `partial`
    residue, compared later). Returns (verdict-line, counts-line) exactly as
    `check:check` renders them."""
    verdict = counts = ""
    for s in (l.rstrip() for l in run_tlc(module, spec_dir, cfg).splitlines()):
        if not verdict and (s.startswith("Model checking completed")
                            or s.startswith("Error:")):
            verdict = s
        if "distinct states found" in s:
            counts = s
    return verdict, counts


def norm_tlc(module: str, spec_dir: Path, cfg: str) -> str:
    out = run_tlc(module, spec_dir, cfg)
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
    print("sany comparator shard:")
    write_sany_shard()
    return 0


if __name__ == "__main__":
    sys.exit(main())
