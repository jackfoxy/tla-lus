#!/usr/bin/env python3
"""The core-evaluation differential (unit 6 / R1.4.1) against the EvalDump oracle.

Each case lives in desk/test-data/eval-core/<case>/ as A.tla plus A.txt (the
.cfg content). EvalDump builds a FastTool (SANY analyze + SpecProcessor config)
and evaluates every arity-0 root-module definition via Tool.eval, printing a
UID-free projection of each value (kind + canonical rendering) or its typed
evaluation failure. The .cfg is staged into a temp dir as A.cfg (the desk has
no %cfg Clay mark, so the corpus stores it as A.txt).

This refreshes golden-eval.txt AND emits desk/tests/lib/core-eval.hoon, which
runs every arity-0 definition of every case through +project-defs:check --- the
same comparator gen-stdops-tests.py uses --- and compares it against the
oracle's own projection, line for line. +project-defs evaluates through
lib/node-eval under an environment built from the case's .cfg CONSTANT
assignments, so the model-value and constant cases are compared rather than
skipped (R1.4.0 measured 6 of the 61 goldens behind that).

A definition this port deliberately answers differently is named in its arm's
skip list with the reason, so a NEW divergence cannot appear silently ---
anything unlisted must match. The existing REPL corpus (gen-eval-tests /
tests/lib/eval, 37 cases) stays the unchanged CST smoke suite.
Never edit generated files.
"""
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
TLA = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools")
JAR = TLA / "dist/tla2tools.jar"
PIN = "4ba7d8811289fb8e95dac4d5e554c05216ba3100"
DUMP_CP = f"{JAR}:{REPO}/tools/oracle/build"
CASES = REPO / "desk/test-data/eval-core"
TEST = REPO / "desk/tests/lib/core-eval.hoon"

#  (case, defname) -> why this port deliberately answers differently.
#  Each entry is a ledger residue with a named owner; nothing lands here
#  without one.
_LAZYSET = ("tlc2 has a class per LAZY set form -- SubsetValue for `SUBSET S`, "
            "SetOfTuplesValue for `A \\X B`, SetPredValue for a filter whose base "
            "set is itself lazy -- and the port normalizes all of them to one "
            "eager `%set`, so only the class column differs; the elements and "
            "their rendering agree exactly. The class is NOT a property of the "
            "operator either: `{x \\in 1..6 : P}` is a SetEnumValue at the pin "
            "while `{x \\in (A \\X B) : P}` is a SetPredValue, so reproducing it "
            "would mean modelling tlc2's lazy-value class hierarchy, which this "
            "port deliberately does not. Enumeration here IS lazy (`sexp`/`ecur`) "
            "-- it is the representation class that is absent. Laziness also "
            "PROPAGATES from the base set, which is why `[<<i, j>> \\in (A \\X B) "
            "|-> e]` is a FcnLambdaValue at the pin while `[i \\in 1..3 |-> e]` is "
            "a FcnRcdValue: same constructor, but the first is built over a lazy "
            "domain. R1.3.8")

#  R2.7.13 MEASURED the residue R2.7.2 left on `tlc-eval-node`; R2.7.16 CLOSED
#  it, so the thirteen entries that stood here are gone and `ev-lazyclass`
#  compares in full. The rule, for the record, is one predicate --- tlc2's
#  `Reducible`, which has exactly TWO implementors in the whole tree
#  (IntervalValue, SetEnumValue) --- applied per operator, and the operators do
#  NOT share one rule:
#
#      [d1 |-> e]  FcnRcdValue iff EVERY domain is Reducible; a RECURSIVE
#                  spec forces FcnLambdaValue outright
#      \cup        eager iff BOTH operands are Reducible; an EMPTY Reducible
#                  operand returns the OTHER OPERAND ITSELF, class and all
#      \cap        eager iff EITHER is
#      \           eager iff the LEFT is
#      UNION       eager iff a SetEnumValue OF SetEnumValues --- strictly
#                  narrower than Reducible, so an INTERVAL element does not
#                  combine
#      {x \in S:P} eager iff S is Reducible
#      SUBSET \X [D -> R] [a: S]   never; their class is unconditional
#
SKIPS: dict = {}

#  R1.4.1b added four cases that exist to REACH the sites lib/node-eval names
#  as unsupported --- the nine original cases reached none of them. Every
#  definition below is red on purpose and names the increment that turns it
#  green; the goldens are frozen now so those increments have a target.
_PRINT = ("TLC!Print/PrintT write to tlc2's console. Gall owns effects here "
          "and the evaluator is a pure function with no output channel, so "
          "the port gives a typed rejection naming what is missing rather "
          "than a silent no-op returning the value (plan-2 invariant 8). "
          "Approved difference decided in R1.4.6 --- routing the output to a "
          "job artifact would mean threading an accumulator through every "
          "+eval return, which is not this unit's change")
_ORDER = ("tlc2 prints a multi-binder function in CONSTRUCTION order (first "
          "index fastest: <<1,1>>, <<2,1>>, <<1,2>>, <<2,2>>); the port "
          "normalizes function pairs into its storage order, sorted by domain "
          "point --- the same function, the same pairs, a different print "
          "order. DOMAIN of it agrees (GDom), and applying it agrees (GAt). "
          "Approved difference, the tlc-value-order family")
#  R3.0b RETIRED the three `ev-oparg` LAMBDA skips (`A3`, `A4`, `Sel`). Their
#  reason -- "LAMBDA is not in the WU3 semantic graph (unit-3 residue)" -- had
#  been false since R1.3.1 put it there; what was actually missing was the
#  EVALUATOR half, which resolved an operator argument by NAME only. `+lambda-def`
#  builds the definition instead, so all three compare.
SKIPS.update({("ev-multibind", d): _ORDER for d in ("G", "H")})
SKIPS.update({
    ("ev-multibind", "ExTup"):
        "tuple-pattern bounded quantifier at constant level; the port reports "
        "'unbounded quantifier is not enumerable', which misdescribes a bound "
        "quantifier --- a site R1.4.0 did not name; R1.4.3",
    ("ev-tlc", "Pr"): _PRINT,
    ("ev-tlc", "PrT"): _PRINT,
    ("ev-tlc", "PrNest"): _PRINT,
})

HEAD = """::  GENERATED by tools/gen-core-eval-tests.py -- do not edit.
::
::  The core-evaluation differential (unit 6 / R1.4.1): every arity-0
::  definition of every eval-core case, evaluated through lib/node-eval
::  under the case's .cfg constant assignments, and compared against the
::  pinned oracle's own projection (desk/test-data/eval-core/*/
::  golden-eval.txt, captured by EvalDump). A definition this port
::  deliberately answers differently is named in the arm's skip list with
::  its reason, so a NEW divergence cannot appear silently -- anything
::  unlisted must match.
/+  *test
/=  check  /lib/check
|%
"""


def check_pin() -> None:
    h = subprocess.run(["git", "-C", str(TLA.parent.parent), "rev-parse", "HEAD"],
                       capture_output=True, text=True).stdout.strip()
    if h != PIN:
        raise SystemExit(f"tlaplus is {h}, not pinned {PIN}")


def hcord(t: str) -> str:
    return (t.replace("\\", "\\\\").replace("'", "\\'")
             .replace("\n", "\\0a").replace("\t", "\\09"))


def htape(t: str) -> str:
    return ('"' + t.replace("\\", "\\\\").replace('"', '\\"')
                .replace("{", "\\{") + '"')


def golden(case: Path) -> None:
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        shutil.copy(case / "A.tla", tdp / "A.tla")
        shutil.copy(case / "A.txt", tdp / "A.cfg")
        r = subprocess.run(["java", "-cp", DUMP_CP, "EvalDump", "A"],
                           cwd=td, capture_output=True, text=True)
    (case / "golden-eval.txt").write_text(r.stdout)


def emit() -> int:
    arms, n = [], 0
    for case in sorted(CASES.iterdir()):
        if not case.is_dir() or not (case / "golden-eval.txt").exists():
            continue
        gold = (case / "golden-eval.txt").read_text()
        if "EVAL\n" not in gold:
            arms.append(f"::  {case.name}: the oracle failed to load this case")
            arms.append("::")
            continue
        slug = case.name.replace("ev-", "")
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
            #  drop the Java exception class from a failure line: the class is
            #  a Java identity, the code and message are the behavior (C1.2)
            rest = re.sub(r"^! (EC\d+ )?\w+(Exception|Error): ",
                          lambda m: "! " + (m.group(1) or ""), rest)
            lines.append(f"{name} {rest}")
            n += 1
        arms.append(f"++  test-{slug}")
        for nm, why in skips:
            arms.append(f"  ::  {nm}: {why}")
        arms.append("  %+  expect-eq")
        arms.append("    !>  ^-  (list tape)")
        if lines:
            arms.append("    :~  " + "\n        ".join(htape(l) for l in lines))
            arms.append("    ==")
        else:
            arms.append("    ~")
        arms.append("  !>")
        arms.append(f"  %^  project-defs:check  '{spec}'  '{cfg}'")
        arms.append("  " + ("~[" + " ".join(f"'{nm}'" for nm, _ in skips) + "]"
                            if skips else "~"))
        arms.append("::")
    TEST.write_text(HEAD + "\n".join(arms) + "\n--\n")
    return n


def main() -> None:
    check_pin()
    c = 0
    for case in sorted(CASES.iterdir()):
        if case.is_dir() and (case / "A.tla").exists():
            golden(case)
            c += 1
    n = emit()
    print(f"{c} eval-core cases, {n} compared definitions")
    print(f"TOTAL {c}")


if __name__ == "__main__":
    main()
