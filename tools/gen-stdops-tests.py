#!/usr/bin/env python3
"""Capture the StandardModule override inventory and goldens (unit 6C, C1.0).

Three oracle-derived artifacts, all from the pinned tlaplus tree:

  desk/test-data/stdops/inventory.txt
      One row per *reachable operator surface*: every public static method of
      the tlc2.module classes (the Java override registry) joined with every
      operator the vendored StandardModules actually declare. Each row carries
      the TLC error codes its Java body can raise and a classification
      (required / body / deferred / excluded). A method with no TLA+
      declaration is unreachable — an override binds by name, so nothing can
      resolve to it — and a declaration with no Java method must evaluate its
      TLA+ body. Both facts are read off the pin, not assumed.

  desk/test-data/stdops/<case>/golden-ops.txt
      ModuleOpDump over the case: BINDINGS (what each imported definition
      resolved to — a Java override value or its TLA+ body) plus EVAL (the
      value/kind or the typed failure with its EC) for every arity-0 root
      definition.

The classification lives in CLASSIFY/MODULE_DEFAULT below; anything the pin
exposes that the rules do not cover exits nonzero, so a new upstream operator
cannot slip into the port unclassified (PORT-COMPLETION-PLAN-2 unit 0).

Oracle-only until the Hoon registry lands (subunit C1.1). Never edit
generated files.
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
TLA = Path("/mnt/mars/gitrepos/tlaplus")
SRC = TLA / "tlatools/org.lamport.tlatools/src"
JAR = TLA / "tlatools/org.lamport.tlatools/dist/tla2tools.jar"
DUMP_CP = f"{JAR}:{REPO}/tools/oracle/build"
CASES = REPO / "desk/test-data/stdops"
INVENTORY = CASES / "inventory.txt"

# tlc2/module files that carry no operator (infrastructure only). Everything
# else must appear in ModuleOpDump.MODULES.
MODULE_HELPERS = {"BuiltInModuleHelper", "TLCBuiltInOverrides"}

# StandardModules probed for their declared operators. One probe per module so
# a module that cannot stand alone does not hide the others.
PROBE_MODULES = [
    "Bags", "FiniteSets", "Integers", "Json", "Naturals", "Randomization",
    "RealTime", "Reals", "Sequences", "TLC", "TLCExt", "Toolbox",
    "_DotTrace", "_JsonTrace", "_Possible", "_TLAPlusCounterExample",
    "_TLCActionTrace", "_TLCTESpec", "_TLCTrace", "_TLCTracePlain",
]

# Classification of every reachable operator surface.
#   required  a native Hoon implementation lands in the named subunit
#   body      no Java override; the vendored TLA+ definition is evaluated
#   deferred  in scope, owned by a later named unit; typed unsupported today
#   excluded  out of scope; typed unsupported, rationale recorded
MODULE_DEFAULT = {
    "Naturals":   ("required", "arithmetic core (C1.2)"),
    "Integers":   ("required", "arithmetic core (C1.2)"),
    "Sequences":  ("required", "sequence core (C1.3)"),
    "FiniteSets": ("required", "finite-set core (C1.4)"),
    "Bags":       ("required", "bag core (C1.4)"),
    "Reals":      ("excluded", "no Real value kind; decimal literals unsupported"),
    "RealTime":   ("excluded", "real-time semantics out of scope"),
    "Randomization": ("deferred", "TLC RandomGenerator parity is unit 9"),
    "Json":       ("excluded", "filesystem/JSON IO surface, not a checking semantic"),
    "TLCExt":     ("excluded", "debugger/trace-explorer surface (plan-2 C1 scope boundary)"),
    "Toolbox":    ("excluded", "IDE trace-explorer surface"),
    "AnySet":     ("excluded", "no StandardModule declares these operators"),
    "Strings":    ("excluded", "no StandardModule declares these operators"),
    "TransitiveClosure": ("excluded", "no StandardModule declares these operators"),
    "_DotTrace":  ("excluded", "internal trace-expression spec surface"),
    "_JsonTrace": ("excluded", "internal trace-expression spec surface"),
    "_Possible":  ("excluded", "internal trace-expression spec surface"),
    "_TLAPlusCounterExample": ("excluded", "internal trace-expression spec surface"),
    "_TLCActionTrace": ("excluded", "internal trace-expression spec surface"),
    "_TLCTESpec": ("excluded", "internal trace-expression spec surface"),
    "_TLCTrace":  ("excluded", "internal trace-expression spec surface"),
    "_TLCTracePlain": ("excluded", "internal trace-expression spec surface"),
}
# per-operator overrides, keyed by the module the operator belongs to
CLASSIFY = {
    ("TLC", ":>"):           ("required", "function constructor override (C1.5)"),
    ("TLC", "@@"):           ("required", "function combination override (C1.5)"),
    ("TLC", "Assert"):       ("required", "assertion failure is a typed EC (C1.5)"),
    ("TLC", "Permutations"): ("required", "SYMMETRY consumes it; replaces check.hoon's ad hoc reader (C1.5)"),
    ("TLC", "SortSeq"):      ("required", "order-sensitive; pinned after the family-5 decision (C1.5/C1.7)"),
    ("TLC", "ToString"):     ("required", "canonical rendering already owned by value.hoon (C1.5)"),
    ("TLC", "Print"):        ("required", "typed engine output channel, never a silent no-op (C1.5)"),
    ("TLC", "PrintT"):       ("required", "typed engine output channel, never a silent no-op (C1.5)"),
    ("TLC", "TLCGet"):       ("required", "C1.5/C1.6: the key taxonomy, EC 2145, and the pin's Evaluation contract (it receives the node at minLevel 1); an engine-state read is a typed rejection naming the key"),
    ("TLC", "TLCSet"):       ("required", "C1.5 implements the rejection; it mutates engine state the evaluator does not own"),
    ("TLC", "TLCEval"):      ("required", "the pin's one plain Evaluation override; C1.6 implements the lazy argument contract with it"),
    ("TLC", "RandomElement"): ("deferred", "TLC RandomGenerator parity is unit 9"),
    ("TLC", "JavaTime"):     ("excluded", "wall-clock nondeterminism"),
    ("TLC", "Any"):          ("excluded", "universal UserValue; no canonical representation"),
    ("Bags", "SubBag"):      ("body", "not overridden by Java; evaluates its TLA+ definition"),
    ("Bags", "Sum"):         ("body", "LOCAL helper of Bags.tla"),
    ("Sequences", "Seq"):    ("required", "non-enumerable descriptor: membership yes, enumeration typed failure (C1.3)"),
    # TLCExt's non-debugger operators (R2.6.3). The module-level default calls
    # every TLCExt surface `excluded`; these five are not, and `class` has to
    # say so or it contradicts what lib/stdops actually does.
    ("TLCExt", "AssertEq"):    ("body", "no Java override; evaluates its TLA+ definition (PrintT/Assert, both implemented)"),
    ("TLCExt", "AssertError"): ("required", "catches the argument's evaluation failure and compares the message (R2.6.3)"),
    ("TLCExt", "TLCCache"):    ("required", "memoization of a pure expression is the identity; the pin returns exactly the expression's value (R2.6.3)"),
    ("TLCExt", "TLCDefer"):    ("required", "TRUE without evaluating: `execCallable` is run by the Simulation/Exploration workers, NOT by ModelChecker, so under BFS the deferred expression never runs (R2.6.3)"),
    ("TLCExt", "TLCNoOp"):     ("required", "the identity function (`return val`) (R2.6.3)"),
}

# ---------------------------------------------------------------------------
# R2 SCOPE (subunit R2.6.0). `class` above is what the port does TODAY; this is
# the orthogonal question R2.6 has to answer: of the surfaces that are not
# already `required`/`body`, which ones does R2 bring in, and who owns them?
#
# Derived here rather than by hand because the R2 plan's hand-written split was
# wrong three ways, all of them visible in the data:
#   * it grounded R2.6.1 (TLCGet/TLCSet) on the excluded set, but both are
#     already `required` -- they are not among the 78 at all;
#   * it grounded R2.6.2 (Randomization) there too, but those are `deferred`,
#     and deferred on "TLC RandomGenerator parity is unit 9", which unit 9 has
#     since DISCHARGED (`tlc-util-rng` is parity);
#   * it split TLCExt by hand into five "non-debugger" operators, which both
#     over- and under-counts (see the per-operator entries below).
#
#   R2.6.1 / R2.6.2 / R2.6.3  in scope, owned by that subunit
#   later                     in scope for the port but owned after R2
#   out:<reason>              stays out; the reason is the record
R2_MODULE_DEFAULT = {
    "Reals":      "out:no Real value kind; decimal literals unsupported",
    "RealTime":   "out:real-time semantics out of scope",
    "Json":       "out:filesystem/JSON IO surface, not a checking semantic",
    "Toolbox":    "out:IDE trace-explorer surface",
    "_DotTrace":  "out:internal trace-expression spec surface",
    "_JsonTrace": "out:internal trace-expression spec surface",
    "_Possible":  "out:internal trace-expression spec surface",
    "_TLAPlusCounterExample": "out:internal trace-expression spec surface",
    "_TLCActionTrace": "out:internal trace-expression spec surface",
    "_TLCTESpec": "out:internal trace-expression spec surface",
    "_TLCTrace":  "out:internal trace-expression spec surface",
    "_TLCTracePlain": "out:internal trace-expression spec surface",
    # R2.6.0 assigned these to R2.6.2. R2.6.2's own measurement then showed
    # the draw ADVANCES the RNG within a single evaluation (the pin designs for
    # `x' = RandomElement(..) /\ y' = RandomElement(..)` giving two values), so
    # a faithful port must carry RNG state across draws -- the same
    # return-carrying change R2.7.4 needs. Folded there too (2026-08-25); the
    # machinery underneath (`+subset-indices`, `lib/rng`, FP64) is already
    # ported, so the surgery is the whole remaining cost.
    "Randomization": "R2.7.4",
}
R2_CLASSIFY = {
    ("TLC", "RandomElement"): "R2.7.4",
    ("TLC", "JavaTime"):      "out:wall-clock nondeterminism",
    ("TLC", "Any"):           "out:universal UserValue; no canonical representation",
    # --- TLCExt, per operator. The module-level `excluded` default called all
    # fourteen "debugger/trace-explorer", which is what produced the plan's
    # wrong five-name split; measured against TLCExt.java and TLCExt.tla:
    ("TLCExt", "AssertEq"):    "R2.6.3",
    ("TLCExt", "AssertError"): "R2.6.3",
    ("TLCExt", "TLCDefer"):    "R2.6.3",
    ("TLCExt", "TLCCache"):    "R2.6.3",
    ("TLCExt", "TLCNoOp"):     "R2.6.3",
    # TLCGet-family, NOT debugger: tlcGetOrDefault reads the same per-run
    # register store as TLCGet ("Partially Copy&Pasted from TLCGetSet.java"),
    # and TLCGetAndSet is TLA+ over TLCGetOrDefault + TLCSet.
    #
    # R2.6.0 assigned these to R2.6.1. R2.6.1 then MEASURED that store: it
    # accumulates across state expansions, so it cannot ride the read-only
    # `eenv` -- every eval's RETURN type has to carry it, which is the same
    # cross-cutting change R2.7.4 (tlc-coverage) needs. Rather than perform
    # that surgery twice on the same evaluator, the WRITE half of R2.6.1 was
    # folded into R2.7.4, and these two moved with it. R2.6.1 kept and shipped
    # the READ half (TLCGet's statistic keys), which needed no such change.
    ("TLCExt", "TLCGetOrDefault"): "R2.7.4",
    ("TLCExt", "TLCGetAndSet"):    "R2.7.4",
    # the trace-explorer / debugger half, which stays out
    ("TLCExt", "CounterExample"): "out:trace-explorer surface (needs a counterexample the evaluator does not hold)",
    ("TLCExt", "PickSuccessor"):  "out:debugger surface; interactive successor choice",
    ("TLCExt", "Trace"):          "out:trace-explorer surface (needs the current behavior prefix)",
    ("TLCExt", "ToTrace"):        "out:trace-explorer surface (lasso ordinal of a liveness counterexample)",
    ("TLCExt", "TLCEvalDefinition"): "later:evaluates a definition BY NAME in the current scope; needs no engine state the port lacks, but no R2 subunit owns it",
    ("TLCExt", "TLCFP"):             "later:state fingerprint read; lib/fingerprint already computes it, but no R2 subunit owns it",
    ("TLCExt", "TLCModelValue"):     "later:interns a model value; the port has model values, but no R2 subunit owns it",
}


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def hoon_contracts() -> dict:
    """{(module, op, arity): (lazy, level)} as desk/lib/stdops.hoon records
    it — from the registry rows and from the node-op table, which carries the
    same two fields."""
    text = (REPO / "desk/lib/stdops.hoon").read_text()
    out = {}
    table = text.split("++  registry")[1].split("::  +|  Diagnostics")[0]
    for m in re.finditer(
            r"\[\['([^']+)' '((?:[^'\\]|\\.)+)' (\d+)\]\s*\[([|&]) (\d+)", table):
        key = (m.group(1), m.group(2).replace("\\\\", "\\"), int(m.group(3)))
        out[key] = (m.group(4) == "&", int(m.group(5)))
    nodes = text.split("++  node-op")[1].split("++  op-meta")[0]
    for m in re.finditer(
            r"=\(k \['([^']+)' '([^']+)' (\d+)\]\)\s*`\[%[\w-]+ ([|&]) (\d+)\]", nodes):
        out[(m.group(1), m.group(2), int(m.group(3)))] = (
            m.group(4) == "&", int(m.group(5)))
    return out


def check_contracts(rows: list) -> list:
    """tlc2 binds a plain method (all arguments evaluated) or an
    `@Evaluation` method (which receives the unevaluated node) and may pin a
    `minLevel`. Both facts are on the pinned method, so the port's own
    `lazy`/`level` must equal them."""
    want = {}
    for r in rows:
        ann = r[6]
        lazy = ann.startswith("Evaluation(")
        m = re.search(r"minLevel=(\d+)", ann)
        want[(r[0], r[1], int(r[2]))] = (lazy, int(m.group(1)) if m else 0)
    problems = []
    for key, (lazy, level) in sorted(hoon_contracts().items()):
        if key not in want:
            continue
        if (lazy, level) != want[key]:
            problems.append(
                f"{key[0]}!{key[1]}/{key[2]} declares lazy={lazy} level={level}, "
                f"but the pin has lazy={want[key][0]} minLevel={want[key][1]}")
    return problems


def hoon_registry() -> tuple:
    """The keys desk/lib/stdops.hoon claims: the override table, the
    set-denoting operators (Nat, Int — lazy descriptors rather than values),
    and the operators it allows to evaluate their vendored TLA+ body."""
    text = (REPO / "desk/lib/stdops.hoon").read_text()
    table = text.split("++  registry")[1].split("--")[0]
    reg = set()
    for m in re.finditer(r"\[\['([^']+)' '((?:[^'\\]|\\.)+)' (\d+)\]", table):
        reg.add((m.group(1), m.group(2).replace("\\\\", "\\"), int(m.group(3))))
    # the set-denoting operators (Nat, Int, Seq) and the ones the evaluator
    # runs itself (SelectSeq) are claimed by key comparison, not by a table row
    for m in re.finditer(r"=\(k \['([^']+)' '([^']+)' (\d+)\]\)", text):
        reg.add((m.group(1), m.group(2), int(m.group(3))))
    bodies = set()
    body_block = text.split("++  body-ok")[1].split("++")[0]
    for m in re.finditer(r"\['([^']+)' '([^']+)'\]", body_block):
        bodies.add((m.group(1), m.group(2)))
    return reg, bodies


def check_registry(rows: list) -> list:
    """The C1.0 inventory binds the C1.1 implementation: every override row
    must be an operator the pin really declares and classifies `required`,
    and the body-evaluable set must be exactly the pin's un-overridden
    (`body`) operators — otherwise a StandardModule dummy body could be
    evaluated as if it were the behavior."""
    reg, bodies = hoon_registry()
    known = {(r[0], r[1], int(r[2])): r[8] for r in rows}
    problems = []
    for k in sorted(reg):
        cls = known.get(k)
        if cls is None:
            # defensive fallback: accept the same module+name at another
            # arity. No registry key needs it today — unary minus was keyed
            # [Naturals '-' 1] before R1.3.5.1 canonicalized the prefix `-`
            # to `-.`; it is now the pin-exact [Integers '-.' 1] (required).
            if any(m == k[0] and n == k[1] for (m, n, _a) in known):
                continue
            problems.append(f"registry row {k[0]}!{k[1]}/{k[2]} is not a "
                            f"declared operator at the pin")
        elif cls != "required":
            problems.append(f"registry row {k[0]}!{k[1]}/{k[2]} is classified "
                            f"{cls}, not required")
    want_bodies = {(r[0], r[1]) for r in rows if r[8] == "body"}
    for k in sorted(want_bodies - bodies):
        problems.append(f"{k[0]}!{k[1]} is classified body but stdops.hoon "
                        f"does not allow its body to evaluate")
    for k in sorted(bodies - want_bodies):
        problems.append(f"stdops.hoon body-evaluates {k[0]}!{k[1]}, which the "
                        f"pin overrides (its vendored body is a dummy)")
    return problems


def check_module_classes() -> list:
    """Every operator-bearing tlc2/module class must be in the dump's list."""
    listed = set(re.findall(r'"tlc2\.module\.(\w+)"',
                            (REPO / "tools/oracle/ModuleOpDump.java").read_text()))
    onpin = {p.stem for p in (SRC / "tlc2/module").glob("*.java")} - MODULE_HELPERS
    missing = sorted(onpin - listed)
    return missing


def inventory_rows() -> list:
    r = sh(["java", "-cp", DUMP_CP, "ModuleOpDump", "--inventory"])
    rows = []
    for line in r.stdout.splitlines():
        if line == "INVENTORY" or not line:
            continue
        if line.startswith("LOAD|"):
            print(line, file=sys.stderr)
            continue
        rows.append(line.split("|"))
    return rows


def declared_ops() -> dict:
    """{(module, name, arity): visibility} for every vendored StandardModule."""
    out = {}
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        for m in PROBE_MODULES:
            (tdp / "P.tla").write_text(
                f"---- MODULE P ----\nEXTENDS {m}\n====\n")
            r = sh(["java", "-cp", DUMP_CP, "ModuleOpDump", "--declared", "P"],
                   cwd=td)
            for line in r.stdout.splitlines():
                if line in ("DECLARED", "") or line.startswith("LOAD|"):
                    continue
                mod, name, arity, vis = line.split("|")
                out[(mod, name, int(arity))] = vis
    return out


def method_ecs(cls: str, java_name: str) -> str:
    """TLC error codes reachable from a Java module method's body."""
    path = SRC / "tlc2/module" / f"{cls}.java"
    if not path.exists():
        return "-"
    text = path.read_text()
    start = None
    for m in re.finditer(r"public\s+static\s+[\w\.\[\]<>, ]+?\b" +
                         re.escape(java_name) + r"\s*\(", text):
        start = m.start()
        break
    if start is None:
        return "-"
    i = text.find("{", start)
    if i < 0:
        return "-"
    depth, j = 0, i
    while j < len(text):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                break
        j += 1
    body = text[i:j]
    ecs = sorted(set(re.findall(r"EC\.([A-Z0-9_]+)", body)))
    return ",".join(ecs) if ecs else "-"


def classify(module: str, name: str) -> tuple:
    if (module, name) in CLASSIFY:
        return CLASSIFY[(module, name)]
    if module in MODULE_DEFAULT:
        return MODULE_DEFAULT[module]
    return ("", "")


def r2_scope(module: str, name: str, cls: str, why: str) -> str:
    """R2 scope verdict for one surface (subunit R2.6.0).

    `required` and `body` surfaces are already in and need no verdict. An
    UNREACHABLE surface is not a scope decision at all -- no TLA+ declaration
    binds the method, so no spec can invoke it and there is nothing to bring
    in; saying `out:` there would misrepresent 20 of the 78 as choices.
    """
    if cls in ("required", "body"):
        return "in:already ported"
    if why.startswith("unreachable"):
        return "n/a:unreachable, not a scope decision"
    if (module, name) in R2_CLASSIFY:
        return R2_CLASSIFY[(module, name)]
    if module in R2_MODULE_DEFAULT:
        return R2_MODULE_DEFAULT[module]
    return ""


def build_inventory() -> tuple:
    """Merge the Java override table with the declared-operator table."""
    java = inventory_rows()
    declared = declared_ops()
    rows = {}
    for cls, builtin, tla, arity, jname, params, ret, ann in java:
        # an annotated override targets the module/identifier it names
        mod, name = cls, tla
        m = re.match(r"\w+\((\w+)!([\w\\]+),", ann)
        if m:
            mod, name = m.group(1), m.group(2)
        arity = int(arity)
        # Evaluation/Callable overrides take the (tool, args, ...) shape; the
        # TLA+ arity is the annotation's, read from the declaration
        vis = declared.get((mod, name, arity))
        if vis is None:
            hits = [k for k in declared if k[0] == mod and k[1] == name]
            vis = declared[hits[0]] if hits else None
            if hits:
                arity = hits[0][2]
        cl, why = classify(mod, name)
        if vis is None:
            cl, why = "excluded", "unreachable: no TLA+ declaration binds this method"
        rows[(mod, name, arity)] = [
            mod, name, str(arity), vis or "undeclared",
            f"{cls}.{jname}", params, ann, method_ecs(cls, jname), cl, why,
            r2_scope(mod, name, cl, why)]
    for (mod, name, arity), vis in declared.items():
        if (mod, name, arity) in rows:
            continue
        cl, why = classify(mod, name)
        if cl == "required":
            # in-scope module, no Java override: the TLA+ definition is the
            # behavior, so the port evaluates the vendored body
            cl, why = "body", "no Java override; evaluates its TLA+ definition"
        rows[(mod, name, arity)] = [
            mod, name, str(arity), vis, "-", "-", "-", "-", cl, why,
            r2_scope(mod, name, cl, why)]
    ordered = [rows[k] for k in sorted(rows)]
    # a surface with no `class` OR no R2 scope verdict fails the generator --
    # the same discipline for both columns, so neither can drift into silence
    unclassified = [r for r in ordered if not r[8] or not r[10]]
    return ordered, unclassified


def write_inventory(rows: list) -> None:
    head = [
        "# GENERATED by tools/gen-stdops-tests.py from the pinned tlaplus tree",
        "# (tlc2/module reflection + SANY-declared StandardModule operators).",
        "# Do not edit. One row per reachable operator surface.",
        "#",
        "# module|operator|arity|visibility|java|params|annotation|ec|class|"
        "rationale|r2-scope",
        "#",
        "# `class` is what the port does TODAY. `r2-scope` (R2.6.0) is the",
        "# orthogonal question: which surfaces R2 brings in and who owns them.",
        "#   in:...      already ported (class required/body)",
        "#   n/a:...     no TLA+ declaration binds the method; not a decision",
        "#   R2.6.N      in scope, owned by that subunit",
        "#   later:...   in scope for the port, owned after R2",
        "#   out:...     stays out, with the reason",
    ]
    body = ["|".join(r) for r in rows]
    INVENTORY.write_text("\n".join(head + body) + "\n")


def intern_evidence() -> int:
    """Family-5 evidence (subunit C1.7): what tlc2 interns, in what order,
    and what the resulting UniqueString order makes observable.

    Two drivers are run over the same fixture — a FastTool alone, and SANY
    followed by a FastTool — because the interning order, and therefore the
    rendering order of string and model-value sets (and which element CHOOSE
    picks), differs between them. Each driver is deterministic; together they
    show the order is a property of the RUN, not of the spec."""
    case = CASES / "st-string-order"
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        shutil.copy(case / "A.tla", tdp / "A.tla")
        shutil.copy(case / "A.txt", tdp / "A.cfg")
        phases = sh(["java", "-cp", DUMP_CP, "InternDump", "A"], cwd=td).stdout
        tool_only = sh(["java", "-cp", DUMP_CP, "InternDump", "--values", "A"],
                       cwd=td).stdout
    head, _, both = phases.partition("VALUES\n")
    counts = [l for l in head.splitlines() if l.startswith("== ")]
    kinds = {"node-kind": 0, "internal": 0, "other": 0}
    for line in head.splitlines():
        if line.startswith("== ") or not line:
            continue
        text = line.partition(" ")[2]
        if text.startswith("N_"):
            kinds["node-kind"] += 1
        elif text.startswith("$") or text in ("nullODN", "nullOpArg",
                                              "nullLabelNode", "LAMBDA"):
            kinds["internal"] += 1
        else:
            kinds["other"] += 1
    out = [
        "# GENERATED by tools/gen-stdops-tests.py — do not edit.",
        "# Family-5 evidence (unit 6C.1.7): tlc2's UniqueString interning order.",
        "#",
        "# Phase counts for desk/test-data/stdops/st-string-order:",
    ] + ["#   " + c for c in counts] + [
        f"#   of those, {kinds['node-kind']} are SANY syntax-tree kind names",
        f"#   (N_*) and {kinds['internal']} are internal operator names and",
        f"#   sentinels ($..., nullODN, LAMBDA); {kinds['other']} are builtin",
        "#   operators, keywords, and the module's own lexemes. Reproducing",
        "#   the order means interning all of them, at the same points.",
        "#",
        "# The same fixture under two drivers. Each is deterministic; they",
        "# disagree, so the order is a property of the run, not of the spec.",
        "",
        "== driver: FastTool alone",
        tool_only.replace("VALUES\n", "").rstrip(),
        "",
        "== driver: SANY, then FastTool",
        both.rstrip(),
        "",
    ]
    (CASES / "intern-order.txt").write_text("\n".join(out) + "\n")
    return len(counts)


# Definitions whose oracle projection this port deliberately does NOT match,
# each with the reason. Anything NOT listed here must match byte for byte, so
# a new divergence cannot appear silently.
SKIPS = {
    ("st-naturals", "NatSet"): "Nat is a lazy descriptor here, not a UserValue (C1.2)",
    ("st-integers", "IntSet"): "Int is a lazy descriptor here, not a UserValue (C1.2)",
    ("st-sequences", "SeqSet"): "Seq(S) is a lazy descriptor here, not a UserValue (C1.3)",
    ("st-sequences", "Sel"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
    ("st-sequences", "SelNone"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
    ("st-seq-errors", "SeqNotSet"): "Seq(S) is a lazy descriptor here, not a UserValue (C1.3)",
    ("st-seq-errors", "SelNotBool"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
    ("st-arith-errors", "BadArgPlus"): "the pin's message names the Java method signature; normalized (C1.2)",
    ("st-bags", "OfAll"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
    ("st-bags", "Subs"): "SubBag's body needs recursive functions and multi-binder set constructors (unit-6.5 residue)",
    ("st-tlc", "Sort"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
    ("st-tlc", "SortEmpty"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
    ("st-tlc", "Pr"): "Print writes to TLC's console; a typed rejection here (C1.5)",
    ("st-tlc", "PrT"): "PrintT writes to TLC's console; a typed rejection here (C1.5)",
    ("st-tlc-errors", "AnyV"): "TLC!Any is excluded; a typed rejection here",
    ("st-tlc-errors", "SortNotBool"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
    ("st-tlc-errors", "SortNotSeq"): "LAMBDA is not in the WU3 semantic graph (unit-3 residue)",
}
# whole cases the comparator does not drive
SKIP_CASES = {
    "st-string-order": "family 5: the approved string-order difference, "
                       "measured in intern-order.txt and fixed by tests/lib/strorder",
    "st-big-literal": "the pin fails the whole LOAD on a numeral above 2^31-1; "
                      "here the expression that contains it fails (C1.2)",
}


def hcord(s: str) -> str:
    return (s.replace("\\", "\\\\").replace("'", "\\'")
             .replace("\n", "\\0a").replace("\t", "\\09").replace("\r", "\\0d"))


def htape(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("{", "\\{") + '"'


def diff_shard() -> int:
    """Emit the differential shard: every arity-0 definition of every stdops
    case, compared against the pinned oracle's own projection. One arm per
    case — the semantic graph is generated once per case, not per
    definition."""
    arms, n = [], 0
    for case in sorted(CASES.iterdir()):
        if not case.is_dir() or not (case / "golden-ops.txt").exists():
            continue
        gold = (case / "golden-ops.txt").read_text()
        if case.name in SKIP_CASES:
            arms.append(f"::  {case.name}: not compared — {SKIP_CASES[case.name]}")
            arms.append("::")
            continue
        if "EVAL\n" not in gold:
            arms.append(f"::  {case.name}: the oracle failed to load this case")
            arms.append("::")
            continue
        slug = case.name.replace("st-", "")
        spec = hcord((case / "A.tla").read_text())
        cfg = hcord((case / "A.txt").read_text())
        skips, lines = [], []
        for line in gold.partition("EVAL\n")[2].splitlines():
            if not line.strip():
                continue
            name, _, rest = line.partition(" ")
            if (case.name, name) in SKIPS:
                skips.append((name, SKIPS[(case.name, name)]))
                continue
            # drop the Java exception class from a failure line: the class is a
            # Java identity, the code and message are the behavior
            rest = re.sub(r"^! (EC\d+ )?\w+(Exception|Error): ",
                          lambda m: "! " + (m.group(1) or ""), rest)
            lines.append(f"{name} {rest}")
            n += 1
        arms.append(f"++  test-{slug}")
        for nm, why in skips:
            arms.append(f"  ::  {nm}: {why}")
        arms.append("  %+  expect-eq")
        arms.append("    !>  ^-  (list tape)")
        arms.append("    :~  " + "\n        ".join(htape(l) for l in lines))
        arms.append("    ==")
        arms.append("  !>")
        arms.append(f"  %^  project-defs:check  '{spec}'  '{cfg}'")
        arms.append("  " + ("~[" + " ".join(f"'{nm}'" for nm, _ in skips) + "]"
                            if skips else "~"))
        arms.append("::")
    head = [
        "::  GENERATED by tools/gen-stdops-tests.py — do not edit.",
        "::",
        "::  The StandardModule override differential (unit 6C.8): every arity-0",
        "::  definition of every stdops case, evaluated through the override",
        "::  registry and compared against the pinned oracle's own projection",
        "::  (desk/test-data/stdops/*/golden-ops.txt, captured by ModuleOpDump).",
        "::  A definition this port deliberately answers differently is named in",
        "::  the arm's skip list with its reason, so a NEW divergence cannot",
        "::  appear silently — anything unlisted must match.",
        "/+  *test",
        "/=  check  /lib/check",
        "|%",
    ]
    (REPO / "desk/tests/lib/stdops-diff.hoon").write_text(
        "\n".join(head + arms + ["--"]) + "\n")
    return n


def golden(case: Path) -> None:
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        shutil.copy(case / "A.tla", tdp / "A.tla")
        shutil.copy(case / "A.txt", tdp / "A.cfg")
        r = subprocess.run(["java", "-cp", DUMP_CP, "ModuleOpDump", "A"],
                           cwd=td, capture_output=True, text=True)
    (case / "golden-ops.txt").write_text(r.stdout)


def main() -> int:
    missing = check_module_classes()
    if missing:
        print("tlc2/module classes absent from ModuleOpDump.MODULES: "
              + ", ".join(missing), file=sys.stderr)
        return 1
    rows, unclassified = build_inventory()
    write_inventory(rows)
    intern_evidence()
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "A.tla").exists():
            golden(case)
            n += 1
    compared = diff_shard()
    counts = {}
    for r in rows:
        counts[r[8]] = counts.get(r[8], 0) + 1
    print(f"{len(rows)} operator rows ("
          + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) + ")")
    # R2 scope histogram (R2.6.0), bucketed by verdict prefix
    r2 = {}
    for r in rows:
        k = r[10].split(":")[0]
        r2[k] = r2.get(k, 0) + 1
    print("R2 scope (R2.6.0): "
          + ", ".join(f"{k} {v}" for k, v in sorted(r2.items())))
    print(f"{n} stdops cases, {compared} compared definitions")
    if unclassified:
        for r in unclassified:
            miss = "class" if not r[8] else "r2-scope"
            print(f"UNCLASSIFIED[{miss}] {r[0]}!{r[1]}/{r[2]}", file=sys.stderr)
        return 1
    problems = check_registry(rows) + check_contracts(rows)
    reg, _bodies = hoon_registry()
    print(f"{len(reg)} registry rows implemented in desk/lib/stdops.hoon")
    if problems:
        for p in problems:
            print(f"REGISTRY {p}", file=sys.stderr)
        return 1
    print(f"TOTAL {n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
