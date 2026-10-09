#!/usr/bin/env python3
"""R4.0f: the July black-box suite (`~/FoxyLabs/tla-lus/prompt-tests.md`,
commit a4424f42), re-founded for R4.

The July suite was written before the agent existed, against an ASSUMED wire,
and every expected value in it was a guess. This generator keeps its intent and
its structure and replaces the guesses with oracles:

  * the CORPUS half (every CI-validated manifest model) cannot run as `-test`
    arms -- a model is many Behn slices on a live agent -- so it becomes the
    work list `desk/test-data/blackbox/models.json` (models) plus
    `parse.json` (parse-only modules), which `tools/examples.py` (R4.0d)
    drives through the agent's public wire. Its oracle is the MANIFEST.
  * the FAILURE half (51 July scenarios) stays as `-test` arms under
    `desk/tests/lib/blackbox/`, driving the agent in-process through
    `lib/tla-lus-test-adapter`. Each scenario's expected value comes from ONE
    named oracle:
      - `sany` / `tlc`: the pinned jar, run here on the same fixture
        (`-tool` for TLC so the EC codes are machine-read). The outcome
        category is upstream CI's own exit-code rule
        (`tla_utils.resolve_tlc_exit_code`);
      - `api`: the documented agent behaviour, cited by section;
      - or the scenario is EXCLUDED with a reason, never skipped silently.
    Where the July guess differs from the oracle, the ledger says so.

  tools/gen-blackbox.py            regenerate arms, work list, ledger
  tools/gen-blackbox.py --check    regenerate into memory and diff (exit 1)
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from datetime import timedelta
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DESK = REPO / "desk"
EXAMPLES = Path("/mnt/mars/gitrepos/tlaplus-Examples")
TLAPLUS = Path("/mnt/mars/gitrepos/tlaplus")
JAR = TLAPLUS / "tlatools/org.lamport.tlatools/dist/tla2tools.jar"
PIN_TLAPLUS = "4ba7d8811289fb8e95dac4d5e554c05216ba3100"
PIN_EXAMPLES = "47b0e2cc0268836b89f5ce451f38e5df5f1cf773"
FIX = DESK / "test-data/blackbox/fixtures"
OUT = DESK / "test-data/blackbox"
ARMS = DESK / "tests/lib/blackbox"

SELECTED = {"success", "safety failure", "deadlock failure",
            "liveness failure", "assumption failure"}
TLC_EXIT = {0: "success", 10: "assumption-failure", 11: "deadlock-failure",
            12: "safety-failure", 13: "liveness-failure"}

CHECK = "[%check [| | | | ~ | ~ [%exhaustive & 0]]]"
ANALYZE = "[%analyze [& & & |]]"

# ------------------------------------------------------------------ cases ---
# (group, name, scenario, root, cfg, oracle, extra)
#   root   : fixture path under FIX (module name = file stem); every fixture in
#            the same directory is supplied too, so a dependency resolves
#   oracle : "sany" | "tlc" | "api" | "excluded"
#   extra  : sany/tlc -> {"fragment": substring that must appear in the PIN's
#            output; the generator fails if it does not}
#            api      -> {"expect": status, "fragment": .., "ref": doc cite,
#                         "over": limit overrides, "op": op override}
#            excluded -> {"why": reason}
#   July's original guess is kept in "july" for the ledger.
CASES = [
    # parser ---------------------------------------------------------------
    ("parser", "lexical-error", "run", "parser/Lexical.tla", None, "sany",
     {"fragment": "Encountered \"@\"", "july": "lexical-error 4000"}),
    ("parser", "parse-error", "run", "parser/Parse.tla", None, "sany",
     {"fragment": "Encountered", "july": "parse-error 4001"}),
    ("parser", "semantic-error", "run", "parser/Semantic.tla", None, "sany",
     {"fragment": "Unknown operator: `Undefined'", "july": "semantic-error 4002"}),
    ("parser", "level-error", "run", "parser/Level.tla", None, "sany",
     {"fragment": "Level error in applying operator '", "july": "level-error 4002"}),
    ("parser", "module-name-mismatch", "run", "parser/WrongName.tla", None, "sany",
     {"fragment": "does not match the name 'NotWrongName'", "july": "parse-error 4001"}),
    ("parser", "missing-dependency", "run", "parser/MissingDependency.tla", None, "sany",
     {"fragment": "Cannot find source file for module NoSuchModule",
      "july": "semantic-error 4002"}),
    ("parser", "malformed-dependency", "run", "parser/MalformedDependency.tla", None,
     "sany", {"fragment": "Encountered", "july": "parse-error 4001"}),
    # config ---------------------------------------------------------------
    ("config", "missing-config", "run", "valid/Valid.tla", "config/Missing.cfg", "tlc",
     {"fragment": "did not specify the initial state predicate",
      "july": "config-error 5001"}),
    ("config", "malformed-config", "run", "valid/Valid.tla", "config/Malformed.cfg",
     "tlc", {"july": "config-error 5003"}),
    ("config", "duplicate-config", "run", "valid/Valid.tla", "config/Duplicate.cfg",
     "tlc", {"july": "config-error 5004"}),
    ("config", "unassigned-constant", "run", "config/Unassigned.tla",
     "config/Unassigned.cfg", "tlc",
     {"fragment": "The constant parameter N is not assigned",
      "july": "config-error 5002"}),
    ("config", "unknown-constant", "run", "valid/Valid.tla", "config/UnknownConstant.cfg",
     "tlc", {"july": "config-error 5002"}),
    ("config", "wrong-level-invariant", "run", "valid/Valid.tla",
     "config/WrongInvariant.cfg", "tlc",
     {"fragment": "The invariant Next is not a state predicate",
      "july": "level-error 2146"}),
    ("config", "wrong-level-property", "run", "valid/Valid.tla",
     "config/WrongProperty.cfg", "tlc",
     {"fragment": "The property NoSuchProperty specified in the configuration file",
      "july": "config-error 5002"}),
    # runtime: pinned-oracle scenarios ------------------------------------
    ("runtime", "false-assumption", "run", "runtime/Assumption.tla",
     "runtime/Assumption.cfg", "tlc",
     {"fragment": "is false", "july": "assumption-failure 2104"}),
    ("runtime", "incomplete-initial-state", "run", "runtime/IncompleteInit.tla",
     "runtime/IncompleteInit.cfg", "tlc", {"july": "evaluation-error 2106"}),
    ("runtime", "incomplete-next-state", "run", "runtime/IncompleteNext.tla",
     "runtime/IncompleteNext.cfg", "tlc",
     {"fragment": "The following variable is not defined: y",
      "july": "evaluation-error 2109"}),
    ("runtime", "no-initial-states", "run", "runtime/NoInitialStates.tla",
     "runtime/NoInitialStates.cfg", "tlc", {"july": "evaluation-error 2118"}),
    ("runtime", "no-constraint-states", "run", "runtime/NoConstraintStates.tla",
     "runtime/NoConstraintStates.cfg", "tlc", {"july": "evaluation-error 2256"}),
    ("runtime", "invariant-in-initial-state", "run", "runtime/InvariantInitial.tla",
     "runtime/InvariantInitial.cfg", "tlc",
     {"fragment": "Invariant Inv is violated by the initial state",
      "july": "safety-failure 2107"}),
    ("runtime", "invariant-in-reachable-state", "run", "runtime/InvariantReachable.tla",
     "runtime/InvariantReachable.cfg", "tlc",
     {"fragment": "Invariant Inv is violated.", "july": "safety-failure 2110"}),
    ("runtime", "invariant-evaluation", "run", "runtime/InvariantEvaluation.tla",
     "runtime/InvariantEvaluation.cfg", "tlc",
     {"fragment": "The second argument of \\div is 0.",
      "july": "evaluation-error 2111"}),
    ("runtime", "action-property", "run", "runtime/ActionProperty.tla",
     "runtime/ActionProperty.cfg", "tlc",
     {"fragment": "Action property Increases is violated.",
      "july": "safety-failure 2112"}),
    ("runtime", "deadlock", "run", "runtime/Deadlock.tla", "runtime/Deadlock.cfg",
     "tlc", {"fragment": "Deadlock reached.", "july": "deadlock-failure 2114"}),
    ("runtime", "liveness-lasso", "run", "runtime/Liveness.tla",
     "runtime/Liveness.cfg", "tlc",
     {"fragment": "Temporal property Live was violated.",
      "july": "liveness-failure 2116"}),
    ("runtime", "liveness-with-symmetry", "run", "runtime/LivenessSymmetry.tla",
     "runtime/LivenessSymmetry.cfg", "tlc", {"july": "config-error 2279"}),
    ("runtime", "expression-evaluation", "run", "runtime/Evaluation.tla",
     "runtime/Evaluation.cfg", "tlc",
     {"fragment": "The second argument of \\div is 0.",
      "july": "evaluation-error 2179"}),
    # runtime: request-parameter scenarios --------------------------------
    ("runtime", "invalid-mode", "invalid-mode", "valid/Valid.tla", "valid/Valid.cfg",
     "excluded", {"why": "the typed wire cannot carry an unknown mode: `check-mode` is "
                  "a closed `$%`, so the noun is ill-typed and is "
                  "`malformed-payload`'s case", "july": "parameter-error 3113"}),
    ("runtime", "invalid-flag", "run", "valid/Valid.tla", "valid/Valid.cfg",
     "excluded", {"why": "the wire has no free-form flag list; every tlc2 flag the "
                  "port honours is a typed field", "july": "parameter-error 3113"}),
    ("runtime", "invalid-worker", "run", "valid/Valid.tla", "valid/Valid.cfg",
     "excluded", {"why": "the engine is single-threaded by design (one Gall agent); "
                  "there is no worker count to get wrong", "july": "parameter-error 3105"}),
    ("runtime", "invalid-depth", "run", "valid/Valid.tla", "valid/Valid.cfg",
     "tlc", {"sim": (3, 0), "july": "parameter-error 3107"}),
    ("runtime", "invalid-seed", "invalid-seed", "valid/Valid.tla", "valid/Valid.cfg",
     "excluded", {"why": "`seed` is `@ud`: every value the wire can carry is a valid "
                  "seed, as every long is at the pin", "july": "parameter-error 1102"}),
    ("runtime", "invalid-timeout", "run", "valid/Valid.tla", "valid/Valid.cfg", "api",
     {"expect": "limited-time", "over": {"max-time": "~s0"},
      "ref": "api.md *Scheduling*: `max-time` enforced per slice",
      "july": "parameter-error"}),
    ("runtime", "invalid-path", "run", "valid/Valid.tla", "valid/Valid.cfg",
     "excluded", {"why": "a path exists only in a `%clay` bundle, which an in-process "
                  "arm cannot serve (tests cannot read Clay); the `..` guard is "
                  "`tests/lib/source-path`'s, and the wire case is R4.0d's",
                  "july": "interface-error"}),
    ("runtime", "cancellation", "cancel", "runtime/Unbounded.tla",
     "runtime/Unbounded.cfg", "api",
     {"expect": "cancelled", "ref": "api.md *Actions*: `%cancel` seals an active job "
      "with `[%cancelled ~]`", "july": "cancelled"}),
    ("runtime", "timeout", "run", "runtime/Unbounded.tla", "runtime/Unbounded.cfg",
     "api", {"expect": "limited-time", "over": {"max-time": "~s1"},
             "ref": "api.md *Scheduling*: `max-time` enforced per slice",
             "july": "timeout"}),
    ("runtime", "resource-limit", "run", "runtime/Unbounded.tla",
     "runtime/Unbounded.cfg", "api",
     {"expect": "limited-states", "over": {"max-states": "10"},
      "ref": "api.md *Scheduling*: `max-states` enforced per state registered",
      "july": "resource-limit"}),
    ("runtime", "worker-process-failure", "run", "valid/Valid.tla", "valid/Valid.cfg",
     "excluded", {"why": "the engine runs no processes; there is nothing to fail",
                  "july": "process-failure"}),
    ("runtime", "oversized-input", "run", "valid/Valid.tla", "valid/Valid.cfg", "api",
     {"expect": "rejected", "over": {"max-source": "1"},
      "ref": "compatibility.md *Async source loading*: `max-source` is enforced "
      "at submit (an `%inline` bundle is all there at submit) and as `%clay` "
      "bytes arrive", "july": "resource-limit"}),
    # interface ------------------------------------------------------------
    ("interface", "malformed-mark", "malformed-mark", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "nack", "ref": "api.md *Marks*: pokes are `%tla-lus-action` only",
      "july": "interface-error"}),
    ("interface", "malformed-payload", "malformed-payload", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "nack", "ref": "api.md *Actions*: the poke vase is an `action`",
      "july": "interface-error"}),
    ("interface", "unauthorized-poke", "unauthorized", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "nack", "ref": "api.md *Actions*: only the ship itself may poke "
      "(documented by R4.0f; it was asserted in code only)",
      "july": "interface-error"}),
    ("interface", "unknown-scry", "unknown-scry", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "no-path", "ref": "api.md *Scries*: only the listed paths exist",
      "july": "interface-error 5999"}),
    ("interface", "duplicate-request-id", "duplicate-request", "runtime/Unbounded.tla",
     "runtime/Unbounded.cfg", "api",
     {"expect": "rejected", "fragment": "duplicate active id",
      "ref": "api.md *Actions*: `'duplicate active id'`", "july": "interface-error"}),
    ("interface", "missing-request-id", "missing-request-id", "valid/Valid.tla",
     "valid/Valid.cfg", "excluded",
     {"why": "`id` is a required `@ta` field: a poke without one is an ill-typed "
      "noun, which is `malformed-payload`'s case", "july": "interface-error"}),
    ("interface", "query-before-submit", "query-before-submit", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "absent", "ref": "api.md *Scries*: `/x/job/<id>` is a `(unit job)`",
      "july": "interface-error 5999"}),
    ("interface", "query-after-completion", "query-after-completion",
     "valid/Valid.tla", "valid/Valid.cfg", "api",
     {"expect": "success", "ref": "api.md *Scries*", "july": "success"}),
    ("interface", "deterministic-repeat", "repeat", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "success", "ref": "api.md *Scheduling*: identical result",
      "july": "success"}),
    ("interface", "concurrent-independent", "concurrent", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "success", "ref": "api.md *Scheduling*: jobs keyed by id",
      "july": "success"}),
    ("interface", "restart-persistence", "restart", "valid/Valid.tla",
     "valid/Valid.cfg", "api",
     {"expect": "success", "ref": "api.md *Scheduling*: resume mid-search with an "
      "identical result", "july": "success"}),
    ("interface", "rejected-run-isolation", "rejected-run-isolation",
     "valid/Valid.tla", "valid/Valid.cfg", "api",
     {"expect": "success", "ref": "api.md *Actions*: validation failures reject "
      "with a reason", "july": "success"}),
]


# Measured divergences: the arm is WITHHELD (its oracle is still captured and
# shown in the ledger), and the reason is printed on every run, so the residue
# cannot go quiet -- the `SKIPS` idiom of gen-core-eval/gen-mc. Each names its
# owner. A divergence is never "fixed" by editing the oracle.
_WIRE = "`op-wire-failure` (R4.2j): "
KNOWN = {
    "incomplete-initial-state": _WIRE + "a runtime evaluation failure is "
        "`[%failed reason]` with no diagnostic, so EC 2102 never reaches the wire",
    "incomplete-next-state": _WIRE + "no EC 2109 on the wire, no `%trace` of the "
        "behavior tlc2 prints, and the reason text differs from tlc2's",
    "invariant-evaluation": _WIRE + "no EC 2103 on the wire",
    "expression-evaluation": _WIRE + "no EC 2179 on the wire and no `%trace`",
    # false-assumption: un-withheld by R4.2j(b) -- `[%violated [%assumption loc]]`.
    # module-name-mismatch / missing-dependency: un-withheld by R4.2j(c), which
    # gave the inline %analyze path SANY's texts (the %clay loader had them).
}


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def check_pins() -> bool:
    ok = True
    for repo, pin in ((TLAPLUS, PIN_TLAPLUS), (EXAMPLES, PIN_EXAMPLES)):
        if sh(["git", "-C", str(repo), "rev-parse", "HEAD"]).stdout.strip() != pin:
            print(f"off-pin: {repo}", file=sys.stderr)
            ok = False
    return ok


# ----------------------------------------------------------------- oracle ---
def stage_fixtures(td: Path, root: str, cfg):
    d = (FIX / root).parent
    for f in d.glob("*.tla"):
        shutil.copy2(f, td / f.name)
    if cfg:
        shutil.copy2(FIX / cfg, td / Path(cfg).name)


def pin_sany(root: str) -> dict:
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        stage_fixtures(td, root, None)
        r = sh(["java", "-cp", str(JAR), "tla2sany.SANY", "-error-codes",
                Path(root).name], cwd=td)
    out = r.stdout + r.stderr
    if r.returncode == 0:
        st = "success"
    elif "Cannot find source file" in out or "does not match the name" in out:
        st = "module-error"
    elif "Parse Error" in out:
        st = "parse-error"
    elif "Level error" in out:
        st = "level-error"
    else:
        st = "semantic-error"
    return {"status": st, "code": None, "out": out, "actions": [], "loop": None}


MSG = re.compile(r"@!@!@STARTMSG (\d+):(\d+) @!@!@\n(.*?)@!@!@ENDMSG \1 @!@!@",
                 re.S)


def pin_tlc(root: str, cfg: str, sim=None) -> dict:
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        stage_fixtures(td, root, cfg)
        r = sh(["java", "-cp", str(JAR), "tlc2.TLC", "-tool", "-workers", "1",
                "-fp", "0", "-noGenerateSpecTE", "-metadir", str(td / "meta"),
                "-config", Path(cfg).name, Path(root).stem]
               + ([] if sim is None else ["-simulate", f"num={sim[0]}",
                                          "-depth", str(sim[1]), "-seed", "0"]),
               cwd=td, timeout=300)
    out = r.stdout + r.stderr
    msgs = MSG.findall(out)
    #  headers, in order: a message can NEST inside another (EC 1000 wraps
    #  the specific one), which the bodies regex cannot see
    heads = re.findall(r"@!@!@STARTMSG (\d+):(\d+) @!@!@", out)
    errs = [int(c) for c, sev in heads if sev == "1"]
    #  EC 1000 is tlc2's generic "TLC threw an unexpected exception" wrapper;
    #  the specific code that follows it is the answer
    if errs and errs[0] == 1000:
        codes = [int(c) for c, _ in heads]
        nxt = codes[codes.index(1000) + 1:]
        errs = errs[1:] or [c for c in nxt if c not in (2186,)][:1] or errs
    st = TLC_EXIT.get(r.returncode, "error")
    actions, loop = [], None
    for c, _, body in msgs:
        if c == "2217":
            m = re.match(r"\d+: <(.*?)(?: line \d+.*)?>", body.strip())
            if m:
                actions.append(m.group(1))
        elif c == "2218":
            #  `N: Stuttering` ends the lasso on a stuttering step;
            #  `N: Back to state: K` loops back to state K
            s = body.strip()
            #  a stuttering lasso loops on the LAST state; the port's typed
            #  trace says so with `loop-start` (adapter normalization: none)
            if s.endswith("Stuttering"):
                loop = len(actions)
            m = re.search(r"Back to state:? (\d+)", s)
            if m:
                loop = int(m.group(1))
    return {"status": st, "code": errs[0] if errs else None, "out": out,
            "actions": actions, "loop": loop, "rc": r.returncode}


# ------------------------------------------------------------------- hoon ---
def hcord(s: str) -> str:
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
        else:
            out.append(ch)
    return "'" + "".join(out) + "'"


def hnum(n: int) -> str:
    return f"{n:,}".replace(",", ".")


def hunit(v, f):
    return "~" if v is None else f"`{f(v)}"


def closure(tla: Path) -> list:
    """The root and the fixtures it reaches through EXTENDS/INSTANCE, so an
    arm embeds only what its run can read."""
    byname = {p.stem: p for p in tla.parent.glob("*.tla")}
    seen, q = [], [tla.stem]
    while q:
        n = q.pop(0)
        if n in seen or n not in byname:
            continue
        seen.append(n)
        txt = byname[n].read_text()
        for m in re.finditer(r"\b(?:EXTENDS|INSTANCE)\s+([\w,\s]+)", txt):
            q += re.findall(r"\w+", m.group(1).split("\n")[0])
    return [byname[n] for n in sorted(seen)]


def arm(group, name, scenario, root, cfg, exp) -> str:
    rname = Path(root).stem
    mods = closure(FIX / root)
    over = exp.get("over", {})
    ident = hashlib.sha256(f"{group}\0{name}".encode()).hexdigest()[:8]
    lines = [
        "::",
        f"::  oracle: {exp['oracle']}"
        + (f" -- {exp['ref']}" if exp.get("ref") else ""),
        "::",
        f"++  test-{group}-{name}-{ident}",
        "  %-  expect-case",
        f"  :*  {hcord(name)}",
        f"      %{scenario}",
        f"      :+  {hcord(rname)}",
        "        :~",
    ]
    for m in mods:
        lines.append(f"          :-  {hcord(m.stem)}")
        lines.append(f"          {hcord(m.read_text())}")
    lines.append("        ==")
    lines.append("      " + ("~" if not cfg else f"`{hcord((FIX / cfg).read_text())}"))
    sim = exp.get("sim")
    op = (ANALYZE if exp["op"] == "analyze" else
          CHECK if not sim else
          f"[%check [| | | | ~ | ~ [%simulate 0 {sim[0]} {sim[1]} |]]]")
    lines.append(f"      {op}")
    lines.append("      [" + " ".join(hunit(over.get(k), str) for k in
                                ("max-states", "max-time", "max-source")) + "]")
    lines.append(f"      %{exp['status']}")
    lines.append(f"      {hunit(exp.get('code'), hnum)}")
    lines.append(f"      {hunit(exp.get('fragment'), hcord)}")
    acts = exp.get("actions") or []
    lines.append("      " + ("~" if not acts else
                             "~[" + " ".join(hcord(a) for a in acts) + "]"))
    lines.append(f"      {hunit(exp.get('loop'), hnum)}")
    lines.append("  ==")
    return "\n".join(lines)


HEADER = """/-  *tla-lus-test
/+  *tla-lus-test-helpers
::  GENERATED by tools/gen-blackbox.py -- do not edit. R4.0f: the July
::  black-box failure scenarios, each asserting ONE named oracle (see
::  desk/test-data/blackbox/coverage.md).
|%"""


# ------------------------------------------------------------ the corpus ---
def timespan(s):
    if s == "unknown":
        return None
    h, m, sec = map(int, s.split(":"))
    return int(timedelta(hours=h, minutes=m, seconds=sec).total_seconds())


def corpus():
    models, parse, excluded = [], [], []
    for mf in sorted(EXAMPLES.glob("specifications/*/manifest.json")):
        man = mf.relative_to(EXAMPLES).as_posix()
        for md in json.load(open(mf))["modules"]:
            feats = md.get("features", [])
            if "pluscal" in feats:
                excluded.append((md["path"], "", "PlusCal is out of the project "
                                 "(2026-09-04)"))
                for mo in md.get("models", []):
                    excluded.append((md["path"], mo["path"], "PlusCal"))
                continue
            parse.append({"manifest": man, "module": md["path"],
                          "proof": "proof" in md})
            for mo in md.get("models", []):
                mode = mo["mode"]
                if mode == "symbolic":
                    excluded.append((md["path"], mo["path"], "Apalache `symbolic`: "
                                     "no symbolic engine; the module is parse-only"))
                    continue
                if mo["result"] not in SELECTED:
                    excluded.append((md["path"], mo["path"], f"manifest result "
                                     f"`{mo['result']}`: no stable oracle"))
                    continue
                secs = timespan(mo["runtime"])
                mid = hashlib.sha256(f"{man}\0{md['path']}\0{mo['path']}"
                                     .encode()).hexdigest()[:12]
                models.append({
                    "id": f"model-{mid}", "manifest": man, "module": md["path"],
                    "model": mo["path"],
                    "mode": (mode if isinstance(mode, str)
                             else {"simulate": mode["simulate"]["traceCount"]}),
                    "features": feats, "expected": mo["result"],
                    "runtime": mo["runtime"],
                    "size": "small" if secs is not None and secs <= 30 else "large",
                    "distinctStates": mo.get("distinctStates"),
                    "totalStates": mo.get("totalStates"),
                    "stateDepth": mo.get("stateDepth"),
                })
    return models, parse, excluded


# ------------------------------------------------------------------- main ---
def build():
    files, ledger = {}, []
    by_group = {}
    for group, name, scen, root, cfg, oracle, extra in CASES:
        july = extra.get("july", "")
        if oracle == "excluded":
            ledger.append((group, name, "EXCLUDED", extra["why"], july))
            continue
        if oracle in ("sany", "tlc"):
            p = (pin_sany(root) if oracle == "sany"
                 else pin_tlc(root, cfg, extra.get("sim")))
            frag = extra.get("fragment")
            if frag and frag not in p["out"]:
                sys.exit(f"{group}/{name}: fragment {frag!r} not in the pin's output")
            exp = {"oracle": f"pin {oracle}", "status": p["status"],
                   "code": p["code"], "fragment": frag,
                   "actions": p["actions"], "loop": p["loop"],
                   "op": "analyze" if oracle == "sany" else "check",
                   "sim": extra.get("sim")}
            got = f"{p['status']}" + (f" {p['code']}" if p["code"] else "")
        else:
            exp = {"oracle": "api", "ref": extra["ref"], "status": extra["expect"],
                   "fragment": extra.get("fragment"), "over": extra.get("over", {}),
                   "op": "check"}
            got = extra["expect"]
        differs = "" if july.split(" ")[0] == exp["status"] and (
            len(july.split()) < 2 or exp.get("code") is None
            or july.split()[1] == str(exp.get("code"))) else "  <- July guessed differently"
        if name in KNOWN:
            print(f"  WITHHELD {group}/{name}: {KNOWN[name]}")
            ledger.append((group, name, exp["oracle"], got + " -- **WITHHELD**: "
                           + KNOWN[name], july + differs))
            continue
        ledger.append((group, name, exp["oracle"], got, july + differs))
        by_group.setdefault(group, []).append(arm(group, name, scen, root, cfg, exp))
    for g, arms in by_group.items():
        files[f"tests/lib/blackbox/{g}.hoon"] = HEADER + "\n" + "\n".join(arms) + "\n--\n"

    models, parse, excl = corpus()
    #  two files, not one: together they exceed the scaffold gate's 100 KB
    #  fixture bound (gate 8), and each half has its own consumer
    files["test-data/blackbox/models.json"] = json.dumps(
        {"examples": PIN_EXAMPLES, "models": models}, indent=1) + "\n"
    files["test-data/blackbox/parse.json"] = json.dumps(
        {"examples": PIN_EXAMPLES, "parse": parse}, indent=1) + "\n"
    c = Counter(m["expected"] for m in models)
    sz = Counter(m["size"] for m in models)
    md = [
        "# Black-box coverage (GENERATED by tools/gen-blackbox.py)",
        "",
        f"Examples `{PIN_EXAMPLES}`. The July 2026 suite (`prompt-tests.md`), "
        "re-founded by R4.0f.",
        "",
        f"**Corpus (driven by `tools/examples.py`, oracle = manifest):** "
        f"{len(models)} selected models -- "
        + ", ".join(f"{k} {v}" for k, v in sorted(c.items()))
        + f"; {sz['small']} small, {sz['large']} large. "
        f"{len(parse)} modules parse-only-or-more. Selected = tested: the runner "
        "takes this file as its work list.",
        "",
        "**Failure scenarios (`-test` arms, `desk/tests/lib/blackbox/`):** "
        f"{sum(1 for l in ledger if l[2] != 'EXCLUDED' and 'WITHHELD' not in l[3])} "
        f"arms, {sum(1 for l in ledger if 'WITHHELD' in l[3])} withheld on a "
        "measured divergence, "
        f"{sum(1 for l in ledger if l[2] == 'EXCLUDED')} excluded.",
        "",
        "| group | scenario | oracle | expected | July's guess |",
        "|---|---|---|---|---|",
    ]
    md += [f"| {g} | {n} | {o} | {e} | {j} |" for g, n, o, e, j in ledger]
    md += ["", "## Corpus exclusions", "", "| module | model | reason |",
           "|---|---|---|"]
    md += [f"| `{a}` | `{b}` | {r} |" for a, b, r in excl]
    files["test-data/blackbox/coverage.md"] = "\n".join(md) + "\n"
    return files


def main() -> int:
    if not check_pins():
        return 2
    files = build()
    if "--check" in sys.argv:
        bad = [p for p, t in files.items()
               if not (DESK / p).is_file() or (DESK / p).read_text() != t]
        have = {p.relative_to(DESK).as_posix() for p in ARMS.glob("*.hoon")}
        bad += sorted(have - set(files))
        for b in bad:
            print(f"DRIFT: {b}")
        return 1 if bad else 0
    for old in ARMS.glob("*.hoon"):
        old.unlink()
    for p, t in files.items():
        (DESK / p).parent.mkdir(parents=True, exist_ok=True)
        (DESK / p).write_text(t)
    print(f"black-box: {len(files)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
