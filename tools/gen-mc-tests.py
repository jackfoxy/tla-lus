#!/usr/bin/env python3
"""Generate safety model-checking differential tests from TLC.

Each case lives in desk/test-data/mc/<case>/ as spec.tla + spec-cfg.txt.
`tlc2.TLC` is run to capture the terminal output (verdict, trace, and the
generated/distinct/depth counts) into out.txt, normalized by stripping the
progress/parsing/estimate noise. Emits tests/lib/mc.hoon comparing the
trimmed (check:check spec cfg) output against out.txt.

Only the semantically meaningful, deterministic lines are compared:
verdict, invariant/deadlock trace (state var-bindings + labels), and the
"N states generated, M distinct ..." / depth lines. Never edit generated
files.
"""
import re
import shutil
import subprocess
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
CASES = REPO / "desk/test-data/mc"
OUT = REPO / "desk/tests/lib/mc.hoon"

DROP = re.compile(
    r"WARNING|reflect|jline|^Jul |illegal|Parsing |Semantic |Linting |"
    r"^Starting|Computing |throughput|nowarning|garbage|Running break|"
    r"worker on|Estimates|because two|calculated |average outdeg|"
    r"Finished in|Finished comp|^TLC2 Version|probability|Trace exploration|"
    r"^Warning: The invariant|Progress\(|"
    #  the multi-PROPERTY form of "Checking temporal properties" carries a
    #  wall-clock timestamp exactly as the single-property form does, and
    #  its branch count is already reported by the dropped
    #  "Implied-temporal checking" line (first seen: `gh1389-ok`)
    r"^Implied-temporal|^Checking temporal|Finished checking temporal|"
    r"^Checking [0-9]+ branches of temporal")


#  Cases whose GOLDEN is captured and frozen but whose arm is not emitted,
#  each naming what has to change to turn it green --- the idiom
#  `gen-core-eval-tests.py` uses for its `SKIPS`. A frozen golden gives the
#  next increment a target; leaving the case out of the corpus entirely would
#  lose the measurement.
SKIPS: dict = {
    #  R2.7.11a emptied this map; R2.7.12 refilled it with one entry. A frozen
    #  golden with the arm withheld gives the next increment a target, and
    #  leaving the case out of the corpus entirely would lose the measurement.
    "prop-box-then-live": (
        "R2.7.12: MEASURED and NOT fixed -- a MISSED VIOLATION, not a "
        "rendering difference. `SpecProcessor.processConfigProps` routes "
        "EVERY `PROPERTY` (a `[]P` box-state to the invariant vector, a "
        "level-1 predicate to the implied inits, a `[][A]_v` to the implied "
        "actions, the rest to the liveness engine); the port decides the "
        "route from the FIRST property alone, so a box-state property "
        "followed by a genuine temporal one runs the safety engine and never "
        "checks the second. The pin reports `P2`; the port completes clean. "
        "Found while measuring R2.7.12's own clause, and it belongs to "
        "`tlc-safety-assume`, which claimed this routing at R1.8.1.1 -- that "
        "row is DEMOTED `parity` -> `partial` on this evidence."),
}


#  Cases where the port's answer differs from the pin by an APPROVED
#  DIFFERENCE (R2.7.6.1). The golden stays the PIN's -- regenerated every run,
#  so a change at the pin shows up as a diff -- and the emitted arm asserts the
#  PORT's own output instead. That tests the difference in BOTH directions: a
#  port regression fails the arm, and a port that quietly starts agreeing with
#  the pin fails it too, so the approval has to be re-decided rather than
#  lapsing into silence. A withheld arm (`SKIPS`) proves nothing; this does.
#
#  Both entries here have the same PIN outcome -- EC 1005, the four-line
#  `This was a Java StackOverflowError` template, because tlc2 has no bound on
#  tableau expansion and dies on the JVM stack -- and, measured, two DIFFERENT
#  port behaviours. Neither run produces a verdict on either side.
APPROVED = {
    "gh1389-loops": (
        ["Error: expansion bound reached (1000 nested user-operator "
         "expansions) translating the temporal formula line 7, col 37 to "
         "line 7, col 42 of module spec; the recursion reaches no base case. "
         "tlc2 has no bound here: it overflows the JVM stack and reports "
         "EC 1005"],
        "the expansion genuinely runs away (guard FALSE, ELSE re-invokes with "
        "the same argument), so `+expand-cap` stops it at 1.000 nested "
        "expansions and `+user-op` PROPAGATES that rejection rather than "
        "swallowing it -- a Hoon runaway is an uncatchable hang, not a "
        "throwable, the same trade `live-graph-cap` makes"),
    "terse-subset": (
        ["Error: Invariant Inv is violated by the initial state:",
         "x = {{}, {1}, {2}, {3}, {1, 2}, {1, 3}, {2, 3}, {1, 2, 3}}"],
        "R2.7.9: `-terse` suppresses the EXPANSION of some lazy sets when a "
        "state is printed -- measured, `SUBSET (1..3)` and `(1..4) \\X (1..2)` "
        "stay unexpanded while a set FILTER is expanded anyway, so it is "
        "per-Value-class, not a global switch. Reproducing it needs each lazy "
        "class to keep its SOURCE DESCRIPTOR (tlc2's `SubsetValue` holds its "
        "base set and prints `SUBSET <base>`); R2.7.2 gave `%set` a class TAG, "
        "which is necessary and not sufficient -- the elements are already "
        "materialized by then. The port renders the expanded form always, "
        "which is a RENDERING difference with no effect on verdict or counts, "
        "and the arm pins both sides"),
    "periodic-fast": (
        ["Error: unsupported: _PERIODIC Falsehood; tlc2 evaluates it inside "
         "the search loop and ENDS the run when it is false, which no "
         "completed run here could report"],
        "R2.7.7.5: `_PERIODIC` is evaluated by tlc2's PERIODIC-WORK THREAD on "
        "a WALL-CLOCK timer, not by the search. Measured: on this spec the "
        "timer never fires and the pin COMPLETES with an always-FALSE "
        "`_PERIODIC`; on a long-running spec the same config stops the run at "
        "wherever the timer landed -- 1 677 194 states one run, 1 740 872 the "
        "next, same jar and spec. So the keyword's observable effect is a "
        "function of machine speed, and no port can match it: this is "
        "`tlc-dfid`'s argument in its strongest form. The port REFUSES by "
        "name (R2.7.7.1), which is reproducible, and the arm asserts that "
        "refusal against the pin's completion"),
    "possible-never": (
        ["Error: Postcondition Never at line 11, col 10 to line 11, col 15 "
         "of module spec is false.",
         "4 states generated, 4 distinct states found, 0 states left on "
         "queue.",
         "The depth of the complete state graph search is 4."],
        "R2.7.7.4b: a `_POSSIBLE` predicate never witnessed fails through the "
        "generated `_CheckName` postcondition -- EC 2404 with the USER's "
        "predicate name and body location, byte-exact. What differs is one "
        "line ABOVE it: `_CheckName`'s body is `PrintT(counts) /\\ FALSE`, so "
        "the pin also prints `[Never |-> 0]`, and this engine has no Print "
        "channel. That is the standing `tlc-module-tlc` difference, not a new "
        "one -- the verdict, the location and the counts all match"),
    "gh1389-guard": (
        ["Error: TLC cannot handle the temporal formula line 12, col 9 to "
         "line 12, col 13 of module spec"],
        "NOT a cap case, measured: the recursion is guarded by a STATE "
        "variable, so the expansion fails on its first attempt and never "
        "recurses -- re-running with `+expand-cap` lowered to 3 leaves this "
        "output byte-identical. The port refuses the translation with the "
        "pin's own EC 2213 text; tlc2 attempts it and dies on the stack"),
}


#  Cases whose COUNTER-EXAMPLE WITNESS is nondeterministic AT THE PIN, so the
#  trace cannot be a golden at all. Measured (R2.7.6.2): six runs of the same
#  jar on the same unchanged spec, reading the loop state --
#
#      live-witness-many         x = 1, 2, 3, 2, 5, 6
#      live-witness-nested-many  x = 1, 8, 5, 5, 4, 8
#      live-witness-rec          x = 8, 5, 1, 4, 3, 5
#      gh1389-violc              x = 6, 64, 11, 3, 21, 11
#
#  -- against `live-witness`, whose choice is FORCED and stable at 5. This is
#  the shape `gen-dfid-tests.py` already meets: where tlc2's own answer varies
#  run to run, nothing can match it and no oracle defines what matching means,
#  so the varying part is dropped and everything else is compared. Here the
#  golden and the port's output are both projected to the verdict, the
#  counter-example header and the counts.
#
#  It is also what makes the SOUNDNESS defect precise rather than anecdotal:
#  every pin draw above is a SOUND witness (never 9, never 99), and the port's
#  is not.
VARIES = {
    "live-witness-many": "witness choice; pin drew 1/2/3/2/5/6 over six runs",
    "live-witness-nested-many": "witness choice; pin drew 1/8/5/5/4/8",
    #  R2.7.6.3 fixed the SOUNDNESS defect these two carried (the port drew
    #  the promise value itself); they are ordinary VARIES cases now, and
    #  their arms are emitted rather than withheld.
    "live-witness-rec": "witness choice; pin drew 8/5/1/4/3/5 -- all sound",
    "gh1389-violc": "witness choice; pin drew 6/64/11/3/21/11 -- all sound",
}
TRACE_LINE = re.compile(r"^(State \d+:|Back to state \d+:|[A-Za-z_][A-Za-z0-9_]* = |/\\ )")


def project(lines: list) -> list:
    """Drop the numbered trace, keeping verdict / header / counts."""
    return [l for l in lines if not TRACE_LINE.match(l)]


def wrap_note(s: str) -> str:
    """A reason wrapped as `::  ` continuation lines, for the emitted arm."""
    out, line = [], "::  "
    for w in s.split():
        if len(line) + len(w) + 1 > 76:
            out.append(line)
            line = "::  " + w
        else:
            line = (line + " " + w) if line.strip() != "::" else line + w
    out.append(line)
    return "\n".join(out)[4:]


def opts_of(case: Path) -> list:
    """Extra `tlc2.TLC` arguments for one case, one per line in opts.txt.

    R2.7.4.4 needs this: `TLC!RandomElement` draws from an RNG seeded with
    `-seed`, so a case that uses it is only reproducible when the seed is
    pinned, and the per-predecessor reseeding is `state.fingerPrint() ^ seed`
    which pins `-fp 0` too. The same shape `gen-safety-tests.py` already has.
    """
    f = case / "opts.txt"
    if not f.exists():
        return []
    return [l for l in f.read_text().split("\n") if l.strip()]


def tlc(case: Path) -> str:
    shutil.copy(case / "spec-cfg.txt", case / "spec.cfg")
    r = subprocess.run(["java", "-cp", str(JAR), "tlc2.TLC"]
                       + opts_of(case) + ["spec.tla"],
                       cwd=case, capture_output=True, text=True, timeout=120)
    (case / "spec.cfg").unlink(missing_ok=True)
    # TLC leaves trace-exploration + fingerprint artifacts (.tla/.bin/.fp,
    # a states/ dir) that have Clay marks which abort |commit; remove them
    for junk in list(case.glob("spec_TTrace_*")) + list(case.glob("*.old")):
        junk.unlink(missing_ok=True)
    st = case / "states"
    if st.is_dir():
        shutil.rmtree(st, ignore_errors=True)
    lines = [l.rstrip() for l in (r.stdout + r.stderr).split("\n")
             if l.strip() and not DROP.search(l)]
    return "\n".join(lines) + "\n"


def hnum(n):
    """A decimal integer as a Hoon literal (dot-separated in threes)."""
    d = str(int(n))
    out = ""
    while len(d) > 3:
        out = "." + d[-3:] + out
        d = d[:-3]
    return d + out


def hcord(s: str) -> str:
    return (s.replace("\\", "\\\\").replace("'", "\\'")
             .replace("\n", "\\0a").replace("\t", "\\09").replace("\r", "\\0d"))


HEADER = """::  GENERATED by tools/gen-mc-tests.py -- do not edit.
::  Expected values are normalized tlc2.TLC output at the pinned commit.
/+  *test
/=  check  /lib/check
|%
++  trim
  ::  drop blank lines; TLC's blank separators between trace states carry
  ::  no information and the captured golden has them removed
  |=  w=wain
  ^-  wain
  (skip w |=(l=@t =('' l)))
::
++  verdict-only
  ::  R2.7.6.2: the projection for a case whose counter-example WITNESS is
  ::  nondeterministic at the pin (six runs of the same jar gave six different
  ::  loop states). Keeps the verdict, the counter-example header and the
  ::  counts; drops the numbered trace -- the discipline `gen-dfid-tests.py`
  ::  already applies to a DFID counterexample, for the same reason: where
  ::  tlc2's own answer varies run to run, no port can match it and no oracle
  ::  says what matching would mean
  |=  w=wain
  ^-  wain
  %+  skim  w
  |=  l=@t
  ?|  =('Error:' (end [3 6] l))
      =('Model checking' (end [3 14] l))
      =('The depth' (end [3 9] l))
      !=(~ (find "states generated" (trip l)))
  ==
"""


def main() -> None:
    arms = []
    for case in sorted(CASES.iterdir()):
        if not (case / "spec.tla").exists():
            continue
        out = tlc(case)
        #  a nondeterministic trace is never frozen: project it away on BOTH
        #  sides so the golden reproduces and the comparison stays honest
        if case.name in VARIES:
            out = "\n".join(project(out.rstrip("\n").split("\n"))) + "\n"
        (case / "out.txt").write_text(out)
        #  the golden is captured either way; only the ARM is withheld, and
        #  the reason is printed so the residue cannot go quiet
        if case.name in SKIPS:
            print(f"  SKIP {case.name}: {SKIPS[case.name]}")
            continue
        glines = out.rstrip("\n").split("\n")
        note = ""
        if case.name in APPROVED:
            #  the arm asserts the PORT's text; the pin's golden is still
            #  captured in out.txt and quoted here so the two sit side by side
            lines_, why = APPROVED[case.name]
            print(f"  APPROVED-DIFFERENCE {case.name}: {why}")
            note = ("::  APPROVED DIFFERENCE (R2.7.6.1) -- this arm asserts "
                    "the PORT's output,\n::  not the pin's. "
                    + wrap_note(why) + "\n::  the pin (out.txt): "
                    + wrap_note(" / ".join(glines)) + "\n")
            glines = lines_
        gitems = "\n".join(f"        '{hcord(l)}'" for l in glines)
        spec = hcord((case / "spec.tla").read_text())
        cfg = hcord((case / "spec-cfg.txt").read_text())
        # A case that pins `-seed` drives the seeded entry point: a spec using
        # `TLC!RandomElement` is only reproducible with the seed supplied, and
        # the per-predecessor reseed is `fingerPrint ^ seed` (R2.7.4.4).
        proj = "  %-  verdict-only\n" if case.name in VARIES else ""
        opts = opts_of(case)
        seed = opts[opts.index("-seed") + 1] if "-seed" in opts else None
        # Hoon groups digits in threes from the right: 987654321 is
        # `987.654.321`, and a bare run of digits is a syntax error
        if seed is not None:
            seed = hnum(seed)
        call = (f"""  %^  check-seed:check
    '{spec}'
    '{cfg}'
  {seed}""" if seed else f"""  %+  check:check
    '{spec}'
  '{cfg}'""")
        arms.append(f"""::
{note}++  test-mc-{case.name}
  %+  expect-eq
    !>  ^-  wain
    :~
{gitems}
    ==
  !>
{proj}  %-  trim
{call}
""")
    OUT.write_text(HEADER + "".join(arms) + "--\n")
    print(f"{len(arms)} mc cases")
    print(f"TOTAL {len(arms)}")


if __name__ == "__main__":
    main()
