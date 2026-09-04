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

# R1.8.1.4: the TLC LIVENESS batch, deferred since R1.1.8 and re-deferred by
# R1.5.7, is now WIRED. Its two historical blockers are both discharged:
# R1.5.5 threaded a distinct-state cap through the temporal `build-graph` path of
# `run-check`/`check` (`build-graph-cap` + `live-graph-cap`), so a looping graph
# yields %limited instead of hanging; and the uncatchable value-core bail R1.5.7
# recorded does NOT reproduce (measured in R1.8.1.0 — every SPECIFICATION-form
# case returns a verdict; R1.3.8's `$CartesianProd` fix is the likely cause).
# R1.8.1.1 then supplied what the batch was really waiting on: fairness extraction
# from a SPECIFICATION, without which every liveness property has a stuttering
# counterexample and the port reports `violated` for all of them.
#
# Membership is derived the same way TLC_BATCH's is, one axis over: a flat
# single-file test-model spec, `check`-class (its EXTENDS closure stays inside
# the ported StandardModules), with a `PROPERTY`/`PROPERTIES` in its .cfg, whose
# oracle verdict is an ordinary run outcome with state counts. Specs whose oracle
# is a TLC exception or a temporal-handling message stay out of a verdict+count
# comparison, exactly as they do for the safety batch:
#   EmptyOrderOfSolutions (tautology), Github1389Loops / Github1389StateGuard
#   (Java StackOverflowError), Github525 / Github742 ("TLC cannot handle the
#   temporal formula"), Github607 (nested-evaluation error), testinvalidinvariant
#   (EC 2146 config rejection), Test2 (postcondition failure), TLCGetLevel /
#   TLCGetNonDeterminism (TLCGet-driven), and UserModuleOverride[Annotation]
#   (a user-supplied Java override class, which has no port analogue).
TLC_LIVENESS_BATCH = [
    "Github1037", "Github1389", "Github1389Violated", "Github1389ViolatedB",
    "Github710d", "Github710e", "Github715", "LivenessConstraintWarning",
    "Test2a",
]

# TLC safety batch modules whose Hoon check disagrees with TLC.
# Frozen from the ship run, in TLC_BATCH order (the arm returns processing
# order via +flop). Each entry is `<module> -> <Hoon verdict>`.
# R1.5.1 closed the 7 `x \in S` / `x' \in S` / parameterized-action-operator
# assignment specs; R1.5.2 closed SubsetEq (lazy `SUBSET A \subseteq SUBSET B`
# reduction); R1.5.3 closed ConstantOperatorConfiguration (cfg constant-operator
# `F(a) = v` enumeration bound as a function value); R1.5.9 closed Github725d --
# `+deref-letin` unwraps a LET whose body names one of its own 0-ary definitions
# before the `=`-LHS assignability test, so `(LET y == a' IN y) = 0` inside
# ENABLED assigns `a'` exactly as tlc2's Tool does (it pushes a LetInNode's
# definitions into the context and recurses on the body in action position).
# The TLC batch now agrees on every spec.
# R1.8.6 REOPENED one: `Github746` declares `ALIAS Alias`, and the port
# type-rejected ALIAS instead of silently ignoring it. The silent ignore had
# been WRONG and this projection could not see it -- TLC renders the violating
# state THROUGH the alias (`/\ i = 1 /\ foo = "bar" /\ j = TRUE`) where the
# port printed the raw binding `i = 1`, and it went unnoticed because an
# initial-state violation is announced by `Error: Invariant Inv is violated by
# the initial state:`, which is neither trace marker `tlc_projection` keys on.
# The spec agreed on [verdict, counts, depth] while disagreeing on every state
# line: a pre-existing divergence made VISIBLE, which is what refusing an
# unsupported option buys.
#
# R2.3.2 CLOSED it by porting alias rendering rather than restoring the ignore
# (`+alias-state`, plus the EC 2107 initial-state branch of `+render-outcome`,
# which `ModelChecker.java:1187` builds from `evalAlias(curState, curState)`).
# The TLC safety batch agrees on every spec again.
# R2.7.7.1 adds exactly one, and it is a REFUSAL rather than a wrong answer.
# `SubseteqNextState` carries `_POSSIBLE FullSet GainThree` and a
# `POSTCONDITION` reading `TLCGet("all:named")["s:_possible"][1]`. Both were
# parsed and IGNORED here, and the spec passed the batch anyway -- because the
# postcondition HOLDS at the pin, so a verdict+counts comparison could not see
# it. R2.7.7.1 refuses both keywords by name, which is the honest state and
# makes the gap visible in the census instead of invisible in a green batch.
# It closes with R2.7.7.3 + R2.7.7.4, which land together for this reason.
# CLOSED by R2.7.7.4b. The entry existed for two units: R2.7.7.1 refused
# `SubseteqNextState` by name because `_POSSIBLE` and its POSTCONDITION were
# parsed and ignored (it had been PASSING the batch with both ignored, since
# the postcondition happens to hold at the pin, so a verdict+counts comparison
# could not see it); R2.7.7.3 moved the refusal one keyword later; R2.7.7.4b
# tracks `_POSSIBLE` and the spec agrees again -- this time for the right
# reason, its postcondition asserting `FullSet = 8` and `GainThree = 16`
# against counters the port now produces.
TLC_BATCH_DIVERGENCES = []
# grouped cause, keyed by module
TLC_BATCH_REASONS = {
}

# Liveness batch modules whose Hoon check disagrees with TLC, frozen from the
# ship run in TLC_LIVENESS_BATCH order (the arm returns processing order via
# +flop). Same census discipline as the safety batch: listed, not silenced --
# and the arm ASSERTS this exact list, so a new divergence (or a fixed one)
# fails the test rather than passing unnoticed.
#
# 8 of 9 agree on the WHOLE projection (verdict + counts + depth + labelled
# trace, R1.1.R1). R1.6 closed the batch on verdict+counts: R1.6.1 built the
# user-defined-operator branch of `astToLiveAppl` (five
# `%tlc-live-wrong-formula-format` bails), and R1.6.6 turned deadlock checking
# ON for the liveness graph build, so a deadlock reached in the state search
# pre-empts the final liveness report.
#
# R1.1.R1's trace comparison reopened exactly one of those: `Github710d`. Its
# VERDICT is right (`Error: Deadlock reached.` on both sides) — what R1.6.6 got
# wrong is the claim that tlc2's final liveness check "never runs". It does:
# tlc2 prints the deadlock trace, THEN `Error: Temporal property NeverThree was
# violated.` with its own counter-example, and only then the statistics. The
# port emitted the deadlock report alone.
#
# R2.7.5 built that second block and R2.7.6.0 RETIRED THE ENTRY — the batch now
# agrees on all 9. The retirement was not free, and how it was caught is the
# point: R2.7.5 deferred regenerating this census, so its `Github710d` entry
# went stale in BOTH directions at once. The full ship suite reported
# `Github710e` in 710d's place, and that was a REGRESSION R2.7.5 introduced,
# not a second missing block — the port emitted a temporal block for 710e where
# tlc2 emits none.
#
# Cause (R2.7.6.0, measured): `+box-free-tf` tested only the tableau formula.
# `VisitsTwoThenStaysSmall` negates to `<>(A /\ <>B) /\ []<>(x >= 2)`, whose
# `[]<>` half lands in a PEM CONDITION rather than in `tf` — box-free tf, live
# obligation. The predicate now also requires box-free promises and
# condition-free PEMs. Confirmed on the pin both ways: with `CHECK_DEADLOCK
# FALSE` 710e prints `State 4: Stuttering` plus the fairness warning, and with
# deadlock checking ON it prints no second block at all. Both are `mc` cases
# (`gh710e`, `gh710e-nodl`) so the pair is pinned rather than argued.
TLC_LIVENESS_DIVERGENCES = []
# grouped cause, keyed by module
TLC_LIVENESS_REASONS = {}
# R2.8.2b: the `tlaplus-Examples` TLC batch. R2.8.2 owed "more examples specs
# in the comparator shards" and R2.8.2a owed it a SELECTION RULE
# (`tools/tier2-select.py`); this is the rule applied. Membership is the rule's
# answer under the nightly budget: an in-scope (`check`-class) examples spec
# with a config of its own that exercises a LEDGER-ROW FAMILY the 26
# checker-exercised specs do not, cheapest-first. Same comparator and same
# census discipline as the two test-model batches -- one mule-isolated arm, the
# whole projection compared, divergences FROZEN by name so a new one cannot
# appear silently.
#
# R3.0 CLOSED ALL THREE of the divergences this batch froze at R2.8.2b, and
# the batch is now 3/3 agreeing:
#   `Channel`          record sets -- agreed from the start
#   `SimpleMath`       a config with NO behaviour spec (cfg-runspec, R3.0a)
#   `CigaretteSmokers` a LAMBDA operator argument (tlc-eval-node, R3.0b)
#
# TWO specs are deliberately NOT here, and both were measured rather than
# assumed:
#
# `SimplifiedFastPaxos/Paxos` -- the multi-binder action existential
# (tlc-eval-action, R3.0c) -- is out on COST, not capability. The port no
# longer refuses it: it explores. But where tlc2 answers in 4.2 s the port had
# not finished in ~50 min, which is more than the whole tier-2 shard costs
# today, so it cannot sit in a nightly batch. R3.0c's evidence is the `mc` case
# `multibind` instead, which pins the same construct AND its enumeration ORDER
# (the odometer runs the LEADING binder fastest, so the trace, the queue count
# and which violation is reported first all depend on getting it right).
#
# `AsynchronousInterface/PrintValues` was expected to join `SimpleMath` as the
# second no-behaviour-spec supplier once R3.0a landed. Measured, it brings a
# DIFFERENT row: its assumptions are `Print(...)` calls, so it fails on
# `TLC!Print`, which is `tlc-module-tlc`'s standing approved difference (this
# engine has no output channel). Adding it would census an approved difference
# under another row's name.
TLC_EXAMPLES_BATCH = [
    (EXAMPLES / "specifications/SpecifyingSystems/AsynchronousInterface",
     "Channel", "Channel.cfg"),                        # safety ok, 12 states
    (EXAMPLES / "specifications/SpecifyingSystems/SimpleMath",
     "SimpleMath", "SimpleMath.cfg"),                  # ASSUME-only, 0 states
    (EXAMPLES / "specifications/CigaretteSmokers",
     "CigaretteSmokers", "CigaretteSmokers.cfg"),      # safety ok, 6 states
]

# Emptied by R3.0. Each entry named a REFUSAL -- the port answered a typed
# error where tlc2 answered a verdict -- and each was charged to a ledger row
# that then closed it. The mechanism stays: this batch is where an
# `tlaplus-Examples` spec's divergence gets frozen by name.
TLC_EXAMPLES_DIVERGENCES = []
TLC_EXAMPLES_REASONS = {}


# `LivenessConstraintWarning` was the tenth candidate and did not TERMINATE
# (no verdict in 480 s where TLC answers in 1.8 s over 5 distinct states). Root
# cause found and fixed in R1.8.1.4 rather than censused: every liveness graph
# build in `lib/check` passed `~` for the model CONSTRAINT / ACTION_CONSTRAINT,
# so a spec finite only under its constraint (`history' = history \o <<pc>>`
# bounded by `Len(history) < 3`) grew without bound; and `+succ-fps:liveness`
# took the raw next-state relation, so once the graph WAS pruned the product
# build crashed `~(got by states)` on a constrained successor. It now agrees.


# R1.1.6: subdir SANY specs, embedded in chunked `mule`-isolated arms in their
# own shard (`tests/lib/tier2-sub.hoon`). Root module names collide across
# subdirs (`MC` ×3), so a spec's identity is its relative PATH, not its module
# name.
#
# THE CAP IS A RUNTIME BUDGET, NOT AN EMBEDDING LIMIT (R1.1.R0 measured it;
# R1.1.R2 raised it). R1.1.6-.9 raised it 1.5 KB → 4 → 8 → 16 KB and stopped,
# and the NB here, `doc/testing.md` and the R1.1.9 row all then claimed the 15
# specs above 16 KB were "past the embedding limit" and "would need Clay-read,
# which the ship's test framework cannot do". That was never measured and is
# false: the 15 alone embed as a 476 598-byte single-arm shard that BUILDS and
# runs OK in 365 s, and all 310 in-scope subdir specs embed as a 1 338 467-byte
# 6-arm shard that builds and comes back `ok=%.y` in 1 683 s. The largest single
# closure, `suite/test211`, is 63 594 raw bytes in ONE module (66 390 escaped).
# Nothing failed per-file, per-arm or per-build.
#
# What the 15 actually cost is TIME: ~24 s/spec against ~4 s/spec averaged over
# the 310. So the cap now sits above every in-scope spec at the pin (largest
# 63 594) and exists to bound what a future upstream spec can add to a nightly
# arm — a number to raise deliberately, not a wall.
SUBDIR_CLOSURE_MAX = 70000
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
    # etest5 CLOSED by R1.3.7.2: `IF M!Init ...` for a NONEXISTENT module M —
    # +g-genid now rejects a `M!x` whose prefix base names neither a symbol in
    # scope nor an instance (no `M!<member>` in ctx) instead of falling through
    # to the $Sel resolver (which silently resolved to the local `Init`), so the
    # reference is nullODN with SANY's EC 4200 `Unknown operator: `Init'.` at the
    # FINAL identifier's span.
    # suite/test203 closed by R1.3.3.1: `foo(n) == INSTANCE M WITH A <- g,
    # b <- n` is a parametrized instance (Gap A) — an R1.3.3.4 target closed
    # early by the parametrized-parameter fix.
    # test30/test999 closed by R1.3.2.2 (infix operator constants).
    # test214 + test216 CLOSED by R1.3.5.4 (theorem-name scoping + USE/HIDE
    # EC 4357 fact validation): test216 now accepts (bare `Thm1`/`Thm2` refs
    # resolve as ThmOrAssumpDefKind, .4.1); test214 now rejects with exactly
    # EC 4357 on `HIDE bar, TRUE` (.4.3). Proofs walk clean without projection
    # (.4.2, SemDump renders getTheorem() only).
    # test217 CLOSED by R1.3.7.1b: a parametrized-instance member reference
    # `I(x')!Foo` with no trailing arg list APPLIES the instance arguments to
    # the member (+g-genid now generates them via +genid-prefix-args), and an
    # imported THEOREM carries the instance formals (sem-thm `params`), so its
    # oplev gets arity + maxLevels from the body's constraints (`z<=1`, a
    # VARIABLE substitution) — the action-level argument `x'` now draws SANY's
    # two EC 4205 level errors.
    # test219a CLOSED by R1.3.5.3 (`!`-subexpression navigation): label refs,
    # structural/@/op-symbol selectors, and the unbounded-CHOOSE fix (.3.7).
    # test51 + test42 closed by R1.3.3.3 (operator-symbol parameter in a def).
    # test216 CLOSED by R1.3.5.4.1 (bare THEOREM-name refs resolve as
    # ThmOrAssumpDefKind). test206 + test219 CLOSED by R1.3.7.1a: a
    # parametrized-instance member application `Inst2(COp!@!++)!Foo(1..5)` /
    # `I(x)!OOp2` / `L!Inst2!Foo` supplies the INSTANCE arguments in the leading
    # positions the import prepended (+g-instance adds |iparams| to the member
    # arity), so +genid-prefix-args now welds the `M(args)!` prefix arguments
    # onto the application's own — retiring the spurious EC 4204.
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
        "++  sort-bindings",
        "  ::  the bindings of each state block SORTED. tlc2 prints them in",
        "  ::  `getVariableDecls()` order -- `java.util.Hashtable` bucket order",
        "  ::  at the module context's final capacity, reversed by ModuleNode --",
        "  ::  which is neither source nor sorted order (`DieHard`'s four",
        "  ::  variables reproduce TLC's printed order only at capacity 191) and",
        "  ::  which a different implementation cannot produce without emulating",
        "  ::  the Java table. An APPROVED DIFFERENCE: same bindings, same",
        "  ::  values, a line order that carries no meaning -- so both sides are",
        "  ::  sorted before compare. See `doc/compatibility.md`.",
        "  |=  t=(list @t)",
        "  ^-  (list @t)",
        "  =|  acc=(list @t)",
        "  =|  blk=(list @t)",
        "  |-  ^-  (list @t)",
        "  ?~  t  (weld acc (sort blk aor))",
        "  =/  s  (trip i.t)",
        "  ?:  ?|(=(\"State \" (scag 6 s)) =(\"Back to state \" (scag 14 s)))",
        "    $(t t.t, acc (weld acc (snoc (sort blk aor) i.t)), blk ~)",
        "  $(t t.t, blk (snoc blk i.t))",
        "++  trace-of",
        "  ::  the labelled behavior trace: every non-blank line between tlc2's",
        "  ::  `Error: The behavior up to this point is:` marker and the counts",
        "  ::  line. Kept whole, bindings included -- a single-variable state",
        "  ::  renders its binding bare (`x = 0`), so a `/\\\\ `-only filter would",
        "  ::  compare labels over a trace whose values nothing checked.",
        "  |=  w=wain",
        "  ^-  (list @t)",
        "  =|  out=(list @t)",
        "  =/  in=?  |",
        "  |-  ^-  (list @t)",
        "  ?~  w  (flop out)",
        "  =/  t  (trip i.w)",
        "  ?:  ?|  =(\"Error: The behavior up to this point is:\" t)",
        "      =(\"Error: The following behavior constitutes a counter-example:\" t)",
        "      ==",
        "    $(w t.w, in &)",
        "  ?.  in  $(w t.w)",
        "  ?:  ?=(^ (fand \"states generated\" t))  (flop out)",
        "  ?:  =(~ t)  $(w t.w)",
        "  $(w t.w, out [i.w out])",
        "++  tlc-sum",
        "  ::  the WHOLE projection the tier-2 goldens carry (R1.1.R1): verdict",
        "  ::  line, the distinct/queue counts, the search-depth line, and the",
        "  ::  labelled behavior trace. The generated count stays dropped --",
        "  ::  R1.1.R0 measured it still diverging on `DieHard` (253 vs 252) and",
        "  ::  `Continue` (4 vs 3), a named two-spec residue. The verdict is",
        "  ::  SELECTED, not taken as the first line: tlc2 prints warnings (EC",
        "  ::  2255 state-level PROPERTY, 2279 symmetry) BEFORE it, and the Java",
        "  ::  side of this comparator already skips them (`tlc_projection`).",
        "  ::  Taking `i.w` compared a warning against a verdict and read as a",
        "  ::  port divergence -- surfaced by R1.8.1.4's liveness batch, the",
        "  ::  first specs here that warn.",
        "  |=  w=wain",
        "  ^-  (list @t)",
        "  =/  v",
        "    %+  skim  w",
        "    |=  l=@t",
        "    =/  t  (trip l)",
        "    ?|  =(\"Model checking completed\" (scag 24 t))",
        "        =(\"Error:\" (scag 6 t))",
        "    ==",
        "  =/  c  (skim w |=(l=@t ?=(^ (fand \"distinct states found\" (trip l)))))",
        "  =/  d",
        "    %+  skim  w",
        "    |=(l=@t ?=(^ (fand \"depth of the complete state graph\" (trip l))))",
        "  %+  weld",
        "    :~  ?~(v '' i.v)",
        "        ?~(c '' (drop-gen i.c))",
        "        ?~(d '' i.d)",
        "    ==",
        "  (sort-bindings (trace-of w))",
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
        proj = tlc_projection(module, Path(sdir), cfg)
        spec_text = read(Path(sdir) / f"{module}.tla")
        cfg_text = read(Path(sdir) / cfg)
        arm = module.lower().replace("_", "-")
        lines += [
            "::",
            f"++  test-tlc-{arm}",
            "  %+  expect-eq",
            "    !>  ^-  (list @t)",
            "    :~  " + "\n        ".join(f"'{hcord(l)}'" for l in proj),
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
        proj = tlc_projection(module, TESTMODEL, f"{module}.cfg")
        spec_text = read(TESTMODEL / f"{module}.tla")
        cfg_text = read(TESTMODEL / f"{module}.cfg")
        exp = "~[" + " ".join(f"'{hcord(l)}'" for l in proj) + "]"
        lines.append(f"      ['{module}' {exp} '{hcord(spec_text)}' "
                     f"'{hcord(cfg_text)}']")
    lines += ["  =="]
    # the batch TLC LIVENESS runner (R1.8.1.4) — same comparator, one axis over
    if TLC_LIVENESS_DIVERGENCES:
        lexpect = ["    :~  " + "  ".join(f"'{d}'"
                                          for d in TLC_LIVENESS_DIVERGENCES),
                   "    =="]
    else:
        lexpect = ["    ~"]
    lines += [
        "::",
        "++  test-tlc-liveness-batch",
        "  %+  expect-eq",
        "    !>  ^-  (list @t)",
        *lexpect,
        "  !>",
        "  %-  tlc-batch-run",
        "  ^-  (list [@t (list @t) @t @t])",
        "  :~",
    ]
    for module in TLC_LIVENESS_BATCH:
        proj = tlc_projection(module, TESTMODEL, f"{module}.cfg")
        spec_text = read(TESTMODEL / f"{module}.tla")
        cfg_text = read(TESTMODEL / f"{module}.cfg")
        exp = "~[" + " ".join(f"'{hcord(l)}'" for l in proj) + "]"
        lines.append(f"      ['{module}' {exp} '{hcord(spec_text)}' "
                     f"'{hcord(cfg_text)}']")
    lines += ["  =="]
    # the EXAMPLES TLC batch (R2.8.2b) — same comparator, other corpus
    if TLC_EXAMPLES_DIVERGENCES:
        eexpect = ["    :~  " + "  ".join(f"'{d}'"
                                          for d in TLC_EXAMPLES_DIVERGENCES),
                   "    =="]
    else:
        eexpect = ["    ~"]
    lines += [
        "::",
        "++  test-tlc-examples-batch",
        "  %+  expect-eq",
        "    !>  ^-  (list @t)",
        *eexpect,
        "  !>",
        "  %-  tlc-batch-run",
        "  ^-  (list [@t (list @t) @t @t])",
        "  :~",
    ]
    for sdir, module, cfg in TLC_EXAMPLES_BATCH:
        proj = tlc_projection(module, Path(sdir), cfg)
        spec_text = read(Path(sdir) / f"{module}.tla")
        cfg_text = read(Path(sdir) / cfg)
        exp = "~[" + " ".join(f"'{hcord(l)}'" for l in proj) + "]"
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
    nlive = len(TLC_LIVENESS_BATCH)
    dl += [
        "",
        f"# tlc-liveness-batch (R1.8.1.4): {nlive} clean single-file test-model "
        "specs with a temporal PROPERTY through check:check;",
        f"# {len(TLC_LIVENESS_DIVERGENCES)} disagree with TLC "
        f"({nlive - len(TLC_LIVENESS_DIVERGENCES)}/{nlive} agree):",
    ]
    for d in TLC_LIVENESS_DIVERGENCES:
        mod = d.split(" -> ")[0]
        dl.append(f"tlc-liveness-batch\t{d}\t{TLC_LIVENESS_REASONS.get(mod, '')}")
    nex = len(TLC_EXAMPLES_BATCH)
    dl += [
        "",
        f"# tlc-examples-batch (R2.8.2b): {nex} in-scope tlaplus-Examples specs "
        "through check:check, picked by tools/tier2-select.py;",
        f"# {len(TLC_EXAMPLES_DIVERGENCES)} disagree with TLC "
        f"({nex - len(TLC_EXAMPLES_DIVERGENCES)}/{nex} agree):",
    ]
    for d in TLC_EXAMPLES_DIVERGENCES:
        mod = d.split(" -> ")[0]
        dl.append(f"tlc-examples-batch\t{d}\t{TLC_EXAMPLES_REASONS.get(mod, '')}")
    nsub = len(sany_subdir_specs())
    dl += [
        "",
        f"# subdir-batch (R1.1.6-.9, completed R1.1.R2): {nsub} in-scope "
        "test-model subdir specs -- EVERY one whose closure resolves -- "
        "through +sany-verdict;",
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


def tlc_projection(module: str, spec_dir: Path, cfg: str) -> list:
    """The WHOLE projection the tier-2 goldens carry (R1.1.R1), as `check:check`
    renders it: the verdict line, the counts line MINUS the generated count, the
    search-depth line, and the labelled behavior trace.

    The generated count stays dropped: R1.1.R0 measured it still diverging on
    `DieHard` (253 vs 252) and `Continue` (4 vs 3), so `+drop-gen` is a named
    two-spec residue, not a stale workaround.

    Unlike `norm_tlc`'s golden projection this keeps EVERY non-blank trace line,
    not just the `/\\ ` ones: a single-variable state renders its binding bare
    (`x = 0`, `TLCStateMut.toString`'s `vlen == 1` branch), and dropping those
    would compare the labels of a trace whose bindings nothing checked."""
    verdict = counts = depth = ""
    trace, in_trace = [], False
    for ln in run_tlc(module, spec_dir, cfg).splitlines():
        s = ln.rstrip()
        if not verdict and (s.startswith("Model checking completed")
                            or s.startswith("Error:")):
            verdict = s
        if "distinct states found" in s:
            counts = s
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
                trace.append(TEMP_PATH.sub("<path>", s))
    if ", " in counts:
        counts = counts.split(", ", 1)[1]
    return [verdict, counts, depth] + sort_bindings(trace)


def sort_bindings(trace: list) -> list:
    """A trace with the bindings of each state block SORTED.

    tlc2 prints them in `TLCStateMut.toString`'s `vars[i]` order, which is
    SpecProcessor's `rootModule.getVariableDecls()` — and that is
    `Context.getVariableDecls()` walking a `java.util.Hashtable`'s buckets,
    reversed by `ModuleNode`. So the printed order is a HASH order over the
    variable names at whatever capacity the module context's table happens to
    have grown to: `DieHard`'s four variables reproduce TLC's printed order
    (`action, smallBucket, bigBucket, water_to_pour`) at capacity 191 and at no
    other capacity in the 11/23/47/95/191/383 growth sequence, and match
    neither source order nor sorted order.

    Reproducing it means emulating a Java hash table whose capacity depends on
    the total symbol count of the module context (every operator EXTENDS drags
    in), so it is an APPROVED DIFFERENCE — same bindings, same values, one line
    order that carries no meaning — and both sides are sorted before compare.
    See `doc/compatibility.md`."""
    out, blk = [], []
    for l in trace:
        if l.startswith("State ") or l.startswith("Back to state "):
            out += sorted(blk) + [l]
            blk = []
        else:
            blk.append(l)
    return out + sorted(blk)


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
