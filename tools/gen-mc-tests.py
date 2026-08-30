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
SKIPS = {
    "live-after-inv": (
        "R2.7.5: the post-error temporal block is CORRECT here (right "
        "property, right shape, appended in the right place) but its "
        "counter-example runs one state too long --- the pin stops at State 3, "
        "where `[](x = 0 => [](x # 2))`'s promise is fulfilled, and the port "
        "continues to State 4 because the graph has that state. That is LASSO "
        "MINIMALITY in `+oos-lasso` (`tlc-live-lasso`, currently `parity`), "
        "not the post-error rule: `live-after-deadlock` passes because there "
        "the witness ends at the last state anyway, and no existing liveness "
        "case has a graph that extends PAST its witness. Frozen so the fix "
        "has a target."),
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
    "gh1389-guard": (
        ["Error: TLC cannot handle the temporal formula line 12, col 9 to "
         "line 12, col 13 of module spec"],
        "NOT a cap case, measured: the recursion is guarded by a STATE "
        "variable, so the expansion fails on its first attempt and never "
        "recurses -- re-running with `+expand-cap` lowered to 3 leaves this "
        "output byte-identical. The port refuses the translation with the "
        "pin's own EC 2213 text; tlc2 attempts it and dies on the stack"),
}


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
"""


def main() -> None:
    arms = []
    for case in sorted(CASES.iterdir()):
        if not (case / "spec.tla").exists():
            continue
        out = tlc(case)
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
  %-  trim
{call}
""")
    OUT.write_text(HEADER + "".join(arms) + "--\n")
    print(f"{len(arms)} mc cases")
    print(f"TOTAL {len(arms)}")


if __name__ == "__main__":
    main()
