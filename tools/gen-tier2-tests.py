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
    ("examples", EXAMPLES / "specifications/CigaretteSmokers",
     "CigaretteSmokers"),                             # accept (R1.3.1: LAMBDA
    #                                                   in the WU3 graph)
]

# Known Hoon<->Java SANY divergences on in-scope specs, surfaced by tier 2 and
# owned by a front-end (R1.3) residue — NOT tested green (they would fail), but
# recorded (machine-checked into `divergences.txt`) so the census is explicit
# and a NEW divergence cannot appear silently. (corpus, dir, module, reason)
KNOWN_DIVERGENCES = [
    # CigaretteSmokers closed by R1.3.1 (LAMBDA in the WU3 semantic graph) —
    # now a tested-green SANY_CURATED arm. IllegalOperatorTest closed by
    # R1.3.2.1 (deep-4271: an operator argument must be first-order) — now
    # agrees (both reject) in the flat SANY batch.
]

TEMP_PATH = re.compile(r"/tmp/[^ )]*|(?:jar:)?file:[^ )]*|/mnt/[^ )]*\.tla")


# The curated TLC comparator set (R1.1.2): single-file safety specs whose Hoon
# `check:check` verdict + distinct-count agree with the pinned TLC run.
# (corpus, dir, module, cfg)
TLC_CURATED = [
    ("test-model", TESTMODEL, "DieHard", "DieHard.cfg"),   # safety violation
    # R1.5.1: `x \in S` nondeterministic init assignment now enumerated by the
    # node-eval solver, so these agree (ok / 12 and 34 distinct)
    ("examples", EXAMPLES / "specifications/SpecifyingSystems/HourClock",
     "HourClock", "HourClock.cfg"),                        # safety ok, 12 states
    ("examples", EXAMPLES / "specifications/transaction_commit",
     "TCommit", "TCommit.cfg"),                            # safety ok, 34 states
]

# Known Hoon<->TLC divergences on in-scope safety specs (R1.1.2). HourClock and
# TCommit were closed by R1.5.1 (nondeterministic `x \in S` / `x' \in S`
# assignment + parameterized-action-operator expansion in the node-eval solver)
# and moved to TLC_CURATED as tested-green arms. (corpus, dir, module, cfg,
# reason)
TLC_DIVERGENCES = []


def sany_batch_modules() -> list:
    """The full flat top-level test-model in-scope batch (sany/check) whose
    dependency closure resolves entirely within the flat directory (R1.1.4:
    all sizes and multi-file closures, not just the single-file < 1.8 KB seed
    of R1.1.3). Subdir specs are a later step. Run through the Hoon SANY
    pipeline in one mule-isolated arm and compared en masse to Java."""
    local = {p.stem for p in TESTMODEL.glob("*.tla")}
    out = []
    for tla in sorted(TESTMODEL.glob("*.tla")):
        text = read(tla)
        k, _ = classify(text, local, tla.with_suffix(".cfg").exists())
        if k not in ("sany", "check"):
            continue
        if any(m not in local for m in dep_closure(TESTMODEL, tla.stem)):
            continue                          # closure must be flat-resolvable
        out.append(tla.stem)
    return out


# Modules in the batch whose Hoon +sany-verdict disagrees with Java, discovered
# by running the batch on the ship. Each entry is `<module>:<hoon-outcome>`
# where outcome is `crash` or `hoon=<accept|reject>`; the batch arm asserts the
# actual divergence list equals this frozen set. Populated from the ship run;
# grouped reasons live in `divergences.txt`.
SANY_BATCH_DIVERGENCES = []
BATCH_REASONS = {
    # BagsTest closed by R1.3.1 (LAMBDA in the WU3 graph). IllegalOperatorTest
    # closed by R1.3.2.1 (deep-4271, first-order op-arg check). Both now agree.
}


# R1.1.5: a bounded TLC batch — clean single-file test-model SAFETY specs
# (ok / invariant-violated / deadlock, small state space) run through
# `check:check` in one mule-isolated arm, comparing the verdict + distinct-count
# to the pinned TLC run. Edge specs whose oracle is a TLC exception / config
# error / temporal-handling message are out of this verdict-comparison scope.
TLC_BATCH = [
    "AssignmentInit", "AssignmentInitNeg", "AssignmentNext",
    "ConstantOperatorConfiguration", "Continue", "DepthFirstErrorTrace",
    "DistributedTrace", "Github1145b", "Github725d", "Github743", "Github746",
    "SubsetEq", "SubseteqNextState", "TraceWithLargeSetOfInitialStatesTest",
]

# NB (R1.1.8 -> R1.5.5): a TLC LIVENESS batch was DEFERRED because the raw
# `check:check` entry had no state cap, so a liveness spec with a large / looping
# Hoon state graph hung the arm (mule catches a bail, not an infinite loop).
# R1.5.5 threaded a distinct-state cap through the temporal `build-graph` path of
# `run-check`/`check` (`build-graph-cap` + `live-graph-cap`): a capped build now
# yields %limited instead of hanging, so the graph-SIZE hang is fixed. R1.5.7 then
# wired and ship-ran a curated liveness batch and hit a SECOND, orthogonal blocker
# (see the NB after TLC_BATCH_REASONS): a per-state value-core EVAL blowup hard-bails
# `check:check` (uncatchable by `mule`) on some SPECIFICATION-form / multi-PROPERTY
# specs, aborting the arm. The batch stays deferred on that value-core hardening.

# TLC safety batch modules whose Hoon check disagrees with TLC.
# Frozen from the ship run, in TLC_BATCH order (the arm returns processing
# order via +flop). Each entry is `<module> -> <Hoon verdict>`.
# R1.5.1 closed the 7 `x \in S` / `x' \in S` / parameterized-action-operator
# assignment specs; R1.5.2 closed SubsetEq (lazy `SUBSET A \subseteq SUBSET B`
# reduction); R1.5.3 closed ConstantOperatorConfiguration (cfg constant-operator
# `F(a) = v` enumeration bound as a function value). The one remaining residue is
# a LET-wrapped primed ENABLED LHS (R1.5.x).
_P = "Error: primed variable is unassigned in the successor state"
TLC_BATCH_DIVERGENCES = [
    f"Github725d -> {_P}: a",
]
# grouped cause, keyed by module
TLC_BATCH_REASONS = {
    "Github725d": "a LET-wrapped primed variable as the `=` LHS inside ENABLED "
                  "is not recognized as assignable (R1.5.x)",
}

# NB (R1.5.7): a tier-2 TLC LIVENESS batch (clean single-file test-model specs
# with a temporal PROPERTY) was wired and ship-run, and surfaced a SECOND, deeper
# blocker beyond R1.1.8's unbounded graph (which R1.5.5 fixed with `live-graph-cap`):
# some SPECIFICATION-form / multi-PROPERTY liveness specs (from the small clean set
# Github1037/1389ViolatedB/710d/710e/715/725b/725f/LivenessConstraintWarning/Test2a)
# HARD-bail inside the value core during `check:check` — a bail `mule` does not
# catch, which aborts the whole test arm and floods the dojo. R1.5.5 bounds the
# GRAPH SIZE (distinct-state count); this is a per-state EVALUATION blowup, an
# orthogonal value-core hardening task. The batch is therefore not yet wired; the
# unblock condition is that value-core hardening, not the graph bound.


# R1.1.6: subdir SANY specs. Tests cannot scry Clay (the framework passes no
# our/now) and the full 310-spec / 1.2 MB closure set is past the embedding
# limit, so this covers the small-closure subset (< 1.5 KB) via chunked embedded
# arms in a separate shard (`tests/lib/tier2-sub.hoon`). Larger-closure subdir
# specs are a follow-on. Root module names collide across subdirs (`MC` ×3), so
# a spec's identity is its relative PATH, not its module name.
SUBDIR_CLOSURE_MAX = 16000
SUBDIR_CHUNK = 55

# Frozen from the ship run, one `<path> -> <outcome>` per divergent spec, in
# processing (chunk) order. Reasons grouped in `divergences.txt`.
# Frozen from the ship run, in sorted (processing) order. Every divergence is a
# front-end (R1.3) residue — these are SANY's own adversarial conformance specs
# (`suite/`, `coverage/`). `hoon=reject` = Java accepts / Hoon rejects (a feature
# gap); `hoon=accept` = Java rejects / Hoon too lenient.
SUB_BATCH_DIVERGENCES = [
    # examples/SingleLaneBridge/SingleLaneBridge closed by R1.3.3.2 (tuple-
    # pattern binder `\A <<r,l>> \in CarsRight \X CarsLeft`) — an R1.3.3.4
    # target closed early by the tuple-binder fix.
    # gh1134/MultiUser + gh1134/SingleUser closed by R1.3.3.1: MultiUser via
    # parametrized-instance parameter scope, both via nested-instance member
    # `StateMachine!Init(..)` resolution. (SingleUser's R1.3.0 `_CONF`
    # classification was wrong — its cause is the nested-member gap.)
    # suite/etest15 + suite/test10 closed by R1.3.3.2 (tuple-pattern binders
    # in function definitions `[<<k,l>> \in Int \X Int |-> ..]`).
    # R1.3.4 conformance triage closed five: etest16 (duplicate record fields,
    # EC 4262), test16/test7/test9 (tuple binders in subset-of/set-of-all/
    # CHOOSE), test23 (LOCAL operator definitions in scope). The measured
    # cause of each differed from its R1.3.0 `_CONF` label.
    # test52 CLOSED by R1.3.5.1 (prefix/postfix op-args + unary-minus `-`→`-.`
    # reconciliation, `prefixop`): the port's SANY verdict now AGREES with Java
    # (accept). De-censused in R1.3.6 (2026-08-15) after the tier2-sub arm
    # measured hoon==java (sub-5 actual empty). [was: "suite/test52 -> hoon=reject"]
    # etest5 `IF M!Init ...` references a member of a NONEXISTENT module M;
    # SANY rejects (EC 4200 `Unknown operator: Init` at the selector), the port
    # under-rejects (`M!Init` resolves to the local `Init` def, ignoring the
    # unknown instance prefix) and accepts. PRE-EXISTING (accepts on 624cae35,
    # before R1.3.5.4) — a nonexistent-module member-ref gap surfaced by the
    # R1.3.5.4 tier2-sub run, NOT introduced by it; not `!`-nav/proof. → R1.3.6.
    "suite/etest5 -> hoon=accept",
    # suite/test203 closed by R1.3.3.1: `foo(n) == INSTANCE M WITH A <- g,
    # b <- n` is a parametrized instance (Gap A) — an R1.3.3.4 target closed
    # early by the parametrized-parameter fix.
    # test30/test999 closed by R1.3.2.2 (infix operator constants).
    "suite/test206 -> hoon=reject",
    # test214 + test216 CLOSED by R1.3.5.4 (theorem-name scoping + USE/HIDE
    # EC 4357 fact validation): test216 now accepts (bare `Thm1`/`Thm2` refs
    # resolve as ThmOrAssumpDefKind, .4.1); test214 now rejects with exactly
    # EC 4357 on `HIDE bar, TRUE` (.4.3). Proofs walk clean without projection
    # (.4.2, SemDump renders getTheorem() only).
    # test217 is the OTHER direction (hoon=accept / java=reject): a
    # parametrized-instance MEMBER APPLICATION `I(x')!Foo` — the instance-element
    # arg `x'` (action level) must be APPLIED to the member `I!Foo` (SANY: a
    # level error, EC 2xxx); the port drops the arg (`apply I!Foo`, no args,
    # L0) so it under-checks and accepts. Same instance-member gap as test206/
    # test219 (this is its level-error variant), R1.3.3 follow-up — NOT `!`-nav.
    "suite/test217 -> hoon=accept",
    "suite/test219 -> hoon=reject",
    # test219a CLOSED by R1.3.5.3 (`!`-subexpression navigation): label refs,
    # structural/@/op-symbol selectors, and the unbounded-CHOOSE fix (.3.7).
    # test51 + test42 closed by R1.3.3.3 (operator-symbol parameter in a def).
    # test216 CLOSED by R1.3.5.4.1 (bare THEOREM-name refs `Thm1`/`Thm2` now
    # resolve as ThmOrAssumpDefKind). test206/test219 STILL diverge, but NOT on
    # `!`-nav (that mechanism is complete — test219a accepts): the residuals are
    # separate gaps ->
    #   test206: parametrized-instance member application arity
    #            `Inst2(COp!@!++)!Foo(1,2,3,4,5)` (the instance-param arg is not
    #            counted; EC 4204) — R1.3.3 instance-member follow-up.
    #   test219: same class, x18 (`I(x)!OOp2`, `L!Inst2!Foo`, ... EC 4204) —
    #            parametrized/nested-instance member arity, R1.3.3 follow-up.
]
_LAM = "LAMBDA not in the WU3 graph (unit-3 residue, R1.3)"
_HO = "higher-order operator parameters (`_++_`/`Plus(_,_)`/`PLen(_)`) — R1.3"
_CONF = "SANY conformance edge (front-end semantic/level residue, R1.3)"
_INST = "INSTANCE ... WITH substitution edge (R1.3)"
SUB_BATCH_REASONS = {
    # R1.3.1 closed the LAMBDA specs (ModuleOverwrites, coverage/F,K,L,
    # EWD840/Error02,Error03,MC02,MC02Sim, suite/test201).
    # test203 closed by R1.3.3.1 (parametrized instance `foo(n)`, Gap A).
    # test30/test999 closed by R1.3.2.2 (infix operator constants).
    # gh1134/MultiUser + gh1134/SingleUser closed by R1.3.3.1 (parametrized-
    # instance parameter scope + nested-instance member `M!Op(..)`).
    # test216 closed by R1.3.5.4.1 (theorem-name scoping).
    "suite/test217": "parametrized-instance member application `I(x')!Foo` — the instance-element arg is dropped, so the level error is under-checked (hoon=accept vs java=reject) — R1.3.3 follow-up (`!`-nav done, R1.3.5.3)",
    # test43 closed by R1.3.2.3 (SortSeq with built-in `<`/`>`/`\leq` op-args).
    # test51 + test42 closed by R1.3.3.3 (operator-symbol parameter in a def).
    # R1.3.4 closed test7/test9/test16 (tuple binders in subset-of/set-of-all/
    # CHOOSE), test23 (LOCAL defs), etest16 (dup record fields, EC 4262).
    # test214 closed by R1.3.5.4.3 (USE/HIDE EC 4357). test52 closed by
    # R1.3.5.1 (prefixop), de-censused R1.3.6.
    "suite/etest5": "`M!Init` member of a nonexistent module M — port resolves to the local `Init` def and under-rejects (SANY: EC 4200 Unknown operator); pre-existing (before R1.3.5.4), not `!`-nav/proof → R1.3.6",
    # test206/test219a are NOT the "\E/SUBSET under substitution" gap the plan
    # expected — that already works; both fail on labels / `!`-subexpression
    # selectors (test206 at PARSE, test219a on `Op!lab`), the R1.3.5 residue.
    "suite/test206": "parametrized-instance member application arity `Inst2(COp!@!++)!Foo(..)` (EC 4204) — R1.3.3 follow-up (`!`-nav done, R1.3.5.3)",
    # EWD998/EWD998 closed by R1.3.2.3 (built-in operator `+`/`\cup` as an
    # operator argument to TLCGetAndSet).
    # test219 is NOT an INSTANCE-substitution gap: R1.3.3.1 landed the
    # parametrized/nested instance edges (MultiUser accepts), but test219
    # still fails at PARSE — it is dominated by labels (`lab(x,y,z) ::`) and
    # `!`-subexpression selectors (`!:!++`, `!>>`, `!2!1`), the unit-3
    # subexpression-navigation residue tracked under R1.3.5.
    "suite/test219": "parametrized/nested-instance member application arity `I(x)!OOp2`/`L!Inst2!Foo` (EC 4204, x18) — R1.3.3 follow-up (`!`-nav done, R1.3.5.3)",
}


def closure_of(tla: Path):
    """(closure {module: text}, byname) for a spec file, resolving modules in
    the spec's own directory then the flat test-model root, skipping vendored
    StandardModules."""
    byname = {p.stem: p for p in tla.parent.glob("*.tla")}
    for p in TESTMODEL.glob("*.tla"):
        byname.setdefault(p.stem, p)
    out, q, seen = {}, [tla.stem], set()
    while q:
        n = q.pop()
        if n in seen or n not in byname:
            continue
        seen.add(n)
        t = read(byname[n])
        out[n] = t
        for r in sorted(module_refs(t)):
            if r not in VENDORED and r in byname:
                q.append(r)
    return out, byname


def sany_subdir_specs() -> list:
    """(path-id, root-module, {module: text}) for small-closure in-scope subdir
    specs whose closure resolves entirely (no missing module)."""
    flat = {p.stem for p in TESTMODEL.glob("*.tla")}
    out = []
    for tla in sorted(TESTMODEL.rglob("*.tla")):
        if tla.parent == TESTMODEL:
            continue
        loc = {p.stem for p in tla.parent.glob("*.tla")} | flat
        k, _ = classify(read(tla), loc, tla.with_suffix(".cfg").exists())
        if k not in ("sany", "check"):
            continue
        cl, byname = closure_of(tla)
        if any(r not in VENDORED and r not in byname
               for m in cl for r in module_refs(cl[m])):
            continue
        if sum(len(t) for t in cl.values()) >= SUBDIR_CLOSURE_MAX:
            continue
        rid = str(tla.relative_to(TESTMODEL))[:-4]      # drop ".tla"
        out.append((rid, tla.stem, cl))
    return out


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
        for r in sorted(module_refs(text)):
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
        "++  tlc-batch-run",
        "  ::  run each batch spec through check:check under +mule and return the",
        "  ::  sorted modules whose [verdict distinct] disagrees with TLC",
        "  |=  b=(list [name=@t exp=(list @t) spec=@t cfg=@t])",
        "  ^-  (list @t)",
        "  =|  out=(list @t)",
        "  |-  ^-  (list @t)",
        "  ?~  b  (flop out)",
        "  =/  r  (mule |.((tlc-sum (check:check spec.i.b cfg.i.b))))",
        "  =/  e=@t",
        "    ?-  -.r",
        "      %|  (cat 3 name.i.b ' -> crash')",
        "      %&  ?:  =(p.r exp.i.b)  ''",
        "          (cat 3 name.i.b (cat 3 ' -> ' ?~(p.r '' i.p.r)))",
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
        src = dep_closure(TESTMODEL, module)
        srclist = " ".join(f"['{n}' '{hcord(t)}']" for n, t in src.items())
        lines.append(f"      ['{module}' %{jv} ~[{srclist}]]")
    lines += ["  =="]
    # the batch TLC runner (R1.1.5)
    if TLC_BATCH_DIVERGENCES:
        texpect = ["    :~  " + "  ".join(f"'{d}'" for d in TLC_BATCH_DIVERGENCES),
                   "    =="]
    else:
        texpect = ["    ~"]
    lines += [
        "::",
        "++  test-tlc-batch",
        "  %+  expect-eq",
        "    !>  ^-  (list @t)",
        *texpect,
        "  !>",
        "  %-  tlc-batch-run",
        "  ^-  (list [@t (list @t) @t @t])",
        "  :~",
    ]
    for module in TLC_BATCH:
        verdict, counts = tlc_summary(module, TESTMODEL, f"{module}.cfg")
        dist = counts.split(", ", 1)[1] if ", " in counts else counts
        spec_text = read(TESTMODEL / f"{module}.tla")
        cfg_text = read(TESTMODEL / f"{module}.cfg")
        exp = f"~['{hcord(verdict)}' '{hcord(dist)}']"
        lines.append(f"      ['{module}' {exp} '{hcord(spec_text)}' "
                     f"'{hcord(cfg_text)}']")
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
        mod = d.split(":")[0]
        dl.append(f"batch\t{d}\t{BATCH_REASONS.get(mod, '')}")
    dl += [
        "",
        f"# tlc-batch (R1.1.5): {len(TLC_BATCH)} clean single-file test-model "
        "safety specs run through check:check;",
        f"# {len(TLC_BATCH_DIVERGENCES)} disagree with TLC "
        f"({len(TLC_BATCH) - len(TLC_BATCH_DIVERGENCES)}/{len(TLC_BATCH)} agree):",
    ]
    for d in TLC_BATCH_DIVERGENCES:
        mod = d.split(" -> ")[0]
        dl.append(f"tlc-batch\t{d}\t{TLC_BATCH_REASONS.get(mod, '')}")
    nsub = len(sany_subdir_specs())
    dl += [
        "",
        f"# subdir-batch (R1.1.6): {nsub} small-closure in-scope test-model "
        "subdir specs through +sany-verdict;",
        f"# {len(SUB_BATCH_DIVERGENCES)} disagree with Java "
        f"({nsub - len(SUB_BATCH_DIVERGENCES)}/{nsub} agree):",
    ]
    for d in SUB_BATCH_DIVERGENCES:
        rid = d.split(" -> ")[0]
        dl.append(f"subdir-batch\t{d}\t{SUB_BATCH_REASONS.get(rid, '')}")
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


def write_subdir_shard():
    """Generate the chunked subdir SANY comparator shard (R1.1.6)."""
    specs = sany_subdir_specs()
    lines = [
        "::  GENERATED by tools/gen-tier2-tests.py -- do not edit.",
        "::  Tier-2 subdir SANY comparator (Release R1, R1.1.6): small-closure",
        "::  in-scope test-model subdir specs, run through +sany-verdict in",
        "::  chunked mule-isolated arms and compared to the pinned Java verdict.",
        "::  A spec's identity is its relative path (root names collide).",
        "/+  *test",
        "/=  semantic  /lib/semantic",
        "|%",
        "++  sub-batch-run",
        "  |=  b=(list [id=@t root=@t jv=?(%accept %reject) src=(list [@t @t])])",
        "  ^-  (list @t)",
        "  =|  out=(list @t)",
        "  |-  ^-  (list @t)",
        "  ?~  b  (flop out)",
        "  =/  r  (mule |.((sany-verdict:semantic root.i.b (malt src.i.b))))",
        "  =/  e=@t",
        "    ?-  -.r",
        "      %|  (cat 3 id.i.b ' -> crash')",
        "      %&  ?:  =(p.r jv.i.b)  ''",
        "          (cat 3 id.i.b (cat 3 ' -> hoon=' p.r))",
        "    ==",
        "  $(b t.b, out ?~(e out [e out]))",
    ]
    chunks = [specs[i:i + SUBDIR_CHUNK]
              for i in range(0, len(specs), SUBDIR_CHUNK)]
    for ci, chunk in enumerate(chunks, 1):
        ids = {rid for rid, _, _ in chunk}
        exp = [d for d in SUB_BATCH_DIVERGENCES
               if d.split(" -> ")[0] in ids]
        if exp:
            eblock = ["    :~  " + "  ".join(f"'{d}'" for d in exp), "    =="]
        else:
            eblock = ["    ~"]
        lines += [
            "::",
            f"++  test-sany-sub-{ci}",
            "  %+  expect-eq",
            "    !>  ^-  (list @t)",
            *eblock,
            "  !>",
            "  %-  sub-batch-run",
            "  ^-  (list [@t @t ?(%accept %reject) (list [@t @t])])",
            "  :~",
        ]
        for rid, root, cl in chunk:
            jv = sany_verdict(root, TESTMODEL / (rid + ".tla"))
            src = " ".join(f"['{n}' '{hcord(t)}']" for n, t in cl.items())
            lines.append(f"      ['{rid}' '{root}' %{jv} ~[{src}]]")
        lines += ["  =="]
    lines.append("--")
    (REPO / "desk/tests/lib/tier2-sub.hoon").write_text("\n".join(lines) + "\n")
    print(f"  subdir shard: {len(specs)} specs in {len(chunks)} arms "
          "-> tests/lib/tier2-sub.hoon")


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
    print("subdir sany shard:")
    write_subdir_shard()
    return 0


if __name__ == "__main__":
    sys.exit(main())
