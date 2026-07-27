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
    ("TLC", "TLCGet"):       ("deferred", "engine run statistics; supported keys decided in C1.5"),
    ("TLC", "TLCSet"):       ("deferred", "engine run statistics; supported keys decided in C1.5"),
    ("TLC", "TLCEval"):      ("deferred", "needs the Evaluation/laziness contract (C1.6)"),
    ("TLC", "RandomElement"): ("deferred", "TLC RandomGenerator parity is unit 9"),
    ("TLC", "JavaTime"):     ("excluded", "wall-clock nondeterminism"),
    ("TLC", "Any"):          ("excluded", "universal UserValue; no canonical representation"),
    ("Bags", "SubBag"):      ("body", "not overridden by Java; evaluates its TLA+ definition"),
    ("Bags", "Sum"):         ("body", "LOCAL helper of Bags.tla"),
    ("Sequences", "Seq"):    ("required", "non-enumerable descriptor: membership yes, enumeration typed failure (C1.3)"),
}


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def hoon_registry() -> tuple:
    """The keys desk/lib/stdops.hoon claims: the override table, the
    set-denoting operators (Nat, Int — lazy descriptors rather than values),
    and the operators it allows to evaluate their vendored TLA+ body."""
    text = (REPO / "desk/lib/stdops.hoon").read_text()
    table = text.split("++  registry")[1].split("--")[0]
    reg = set()
    for m in re.finditer(r"\[\['([^']+)' '((?:[^'\\]|\\.)+)' (\d+)\]", table):
        reg.add((m.group(1), m.group(2).replace("\\\\", "\\"), int(m.group(3))))
    descriptors = text.split("++  set-descriptor")[1].split("--")[0]
    for m in re.finditer(r"=\(k \['([^']+)' '([^']+)' (\d+)\]\)", descriptors):
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
            # unary minus: the pin declares `-.` in Integers, the generator
            # names the node `-`; accept the same name at another arity
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
            f"{cls}.{jname}", params, ann, method_ecs(cls, jname), cl, why]
    for (mod, name, arity), vis in declared.items():
        if (mod, name, arity) in rows:
            continue
        cl, why = classify(mod, name)
        if cl == "required":
            # in-scope module, no Java override: the TLA+ definition is the
            # behavior, so the port evaluates the vendored body
            cl, why = "body", "no Java override; evaluates its TLA+ definition"
        rows[(mod, name, arity)] = [
            mod, name, str(arity), vis, "-", "-", "-", "-", cl, why]
    ordered = [rows[k] for k in sorted(rows)]
    unclassified = [r for r in ordered if not r[8]]
    return ordered, unclassified


def write_inventory(rows: list) -> None:
    head = [
        "# GENERATED by tools/gen-stdops-tests.py from the pinned tlaplus tree",
        "# (tlc2/module reflection + SANY-declared StandardModule operators).",
        "# Do not edit. One row per reachable operator surface.",
        "#",
        "# module|operator|arity|visibility|java|params|annotation|ec|class|rationale",
    ]
    body = ["|".join(r) for r in rows]
    INVENTORY.write_text("\n".join(head + body) + "\n")


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
    n = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "A.tla").exists():
            golden(case)
            n += 1
    counts = {}
    for r in rows:
        counts[r[8]] = counts.get(r[8], 0) + 1
    print(f"{len(rows)} operator rows ("
          + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) + ")")
    print(f"{n} stdops cases")
    if unclassified:
        for r in unclassified:
            print(f"UNCLASSIFIED {r[0]}!{r[1]}/{r[2]}", file=sys.stderr)
        return 1
    problems = check_registry(rows)
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
