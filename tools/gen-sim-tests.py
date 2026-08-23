#!/usr/bin/env python3
"""Generate exact seeded-trace tests for simulation (unit 9.2).

lib/check's simulate ports tlc2 SimulationWorker over the semantic state graph,
drawing with lib/rng (java.util.Random). This runs `tlc2.TLC -simulate num=1
-workers 1 -seed S` for a corpus of specs (in the node-eval supported fragment:
`x' = e` actions and disjunctions, with an invariant that eventually trips),
parses the counterexample trace, and emits desk/tests/lib/sim-diff.hoon asserting
that `simulate-spec` reproduces the exact same behavior (its violating state path
rendered by render-states) for each seed. Never edit generated files.
"""
import re
import subprocess
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
JAR = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/dist/tla2tools.jar")
OUT = REPO / "desk/tests/lib/sim-diff.hoon"
WORK = Path("/tmp/gen-sim-work")

# each case: name, TLA source, cfg, per-behavior depth cap, seed list. Every
# spec stays in the supported fragment and its invariant is reached, so TLC
# prints the trace (and simulate-spec returns a violating path).
CASES = [
    ("two", """---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
A == x' = x + 1
B == x' = x + 10
Next == A \\/ B
Inv == x < 25
====
""", "INIT Init\nNEXT Next\nINVARIANT Inv\n", 40, [1, 2, 3, 4, 5]),
    ("three", """---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
A == x' = x + 1
B == x' = x + 3
C == x' = x + 7
Next == A \\/ B \\/ C
Inv == x < 30
====
""", "INIT Init\nNEXT Next\nINVARIANT Inv\n", 60, [1, 2, 3, 7, 42]),
    ("twovar", """---- MODULE spec ----
EXTENDS Naturals
VARIABLE x, y
Init == x = 0 /\\ y = 0
A == x' = x + 1 /\\ y' = y
B == x' = x /\\ y' = y + 1
Next == A \\/ B
Inv == x + y < 6
====
""", "INIT Init\nNEXT Next\nINVARIANT Inv\n", 40, [1, 2, 3, 7, 42]),
    # R1.7: `x' \in S` in simulation -- one action yielding TWO successors, so
    # the successor-pick draw actually branches (the old residue claimed this
    # was unsupported; R1.5.1 closed it in the node-eval solver).
    ("nondet", """---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
A == x' \\in {x + 1, x + 2}
B == x' = x + 5
Next == A \\/ B
Inv == x < 25
====
""", "INIT Init\nNEXT Next\nINVARIANT Inv\n", 40, [1, 2, 3, 7, 42]),
    # R1.7: a state CONSTRAINT. Successors above the bound are DROPPED from the
    # successor set (SimulationWorker's functor: `isInModel(t) && isInActions`),
    # so once x >= 11 action B yields nothing and the retry stride must fall
    # through to A -- a different RNG consumption and a different path than an
    # engine that ignores the constraint.
    ("constraint", """---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
A == x' = x + 1
B == x' = x + 10
Next == A \\/ B
Constr == x =< 20
Inv == x # 13
====
""", "INIT Init\nNEXT Next\nCONSTRAINT Constr\nINVARIANT Inv\n", 40,
     [1, 2, 3, 7, 42]),
    # R1.7: an ACTION_CONSTRAINT -- forbids the +10 step on every transition, so
    # only A ever contributes a successor.
    ("actconstraint", """---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
A == x' = x + 1
B == x' = x + 10
Next == A \\/ B
ActConstr == x' =< x + 5
Inv == x # 7
====
""", "INIT Init\nNEXT Next\nACTION_CONSTRAINT ActConstr\nINVARIANT Inv\n", 40,
     [1, 2, 3, 7, 42]),
    # R1.7c: DEADLOCK in simulation. The constraint dead-ends the walk at x = 3
    # (the only action's successor is pruned), and with deadlock checking on --
    # the default -- tlc2 reports `Error: Deadlock reached.` and STOPS the whole
    # simulation, printing the behavior up to and including the deadlocked
    # state (`SimulationWorker.java:692-698`). One action, so the path is
    # deterministic and every seed must produce it.
    ("deadlock", """---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
Constr == x =< 3
====
""", "INIT Init\nNEXT Next\nCONSTRAINT Constr\n", 40, [1, 2, 42]),
]


def hcord(s: str) -> str:
    o = []
    for ch in s:
        if ch == "\\":
            o.append("\\\\")
        elif ch == "'":
            o.append("\\'")
        elif ch == "\n":
            o.append("\\0a")
        else:
            o.append(ch)
    return "".join(o)


def tlc_trace(src: str, cfg: str, seed: int, depth: int):
    """The state path TLC's -simulate produces before the invariant trips,
    each state as render-states' "var=val,..." (vars sorted)."""
    WORK.mkdir(exist_ok=True)
    (WORK / "spec.tla").write_text(src)
    (WORK / "spec.cfg").write_text(cfg)
    r = subprocess.run(
        ["java", "-cp", str(JAR), "tlc2.TLC", "-simulate", "num=1",
         "-depth", str(depth), "-seed", str(seed), "-workers", "1", "spec.tla"],
        cwd=WORK, capture_output=True, text=True)
    lines = r.stdout.splitlines()
    try:
        start = next(i for i, l in enumerate(lines) if "behavior up to this point" in l)
    except StopIteration:
        raise SystemExit(f"no trace for seed {seed}:\n{r.stdout}\n{r.stderr}")
    states, cur = [], None
    for l in lines[start + 1:]:
        if l.startswith("State "):
            if cur is not None:
                states.append(cur)
            cur = {}
        elif cur is not None:
            m = re.match(r"\s*(?:/\\ )?(\w+) = (.+)$", l)
            if m:
                cur[m.group(1)] = m.group(2).strip()
            elif l.strip() == "" and cur:
                pass
            elif not l.startswith(" ") and l.strip():
                break
    if cur:
        states.append(cur)
    return [",".join(f"{k}={v}" for k, v in sorted(s.items())) for s in states]


HEADER = """::  GENERATED by tools/gen-sim-tests.py -- do not edit.
::  Exact seeded-trace parity (unit 9.2): lib/check's simulate (SimulationWorker
::  over the semantic graph, drawing java.util.Random via lib/rng) reproduces
::  `tlc2.TLC -simulate -workers 1 -seed S` behavior for behavior. Each golden
::  is the violating state path TLC printed, rendered as render-states does.
/+  *test
/=  check  /lib/check
/=  ne     /lib/node-eval
|%
"""


def main() -> None:
    arms = []
    n = 0
    for name, src, cfg, depth, seeds in CASES:
        arms.append(f"++  src-{name}  '{hcord(src)}'\n")
        arms.append(f"++  cfg-{name}  '{hcord(cfg)}'\n")
        for seed in seeds:
            path = tlc_trace(src, cfg, seed, depth)
            golden = "~[" + " ".join(f'"{p}"' for p in path) + "]"
            arms.append(f"""++  test-sim-{name}-{seed}
  %+  expect-eq
    !>  `(list tape)`{golden}
  !>  %-  render-states:ne
      path:(need viol:(simulate-spec:check src-{name} cfg-{name} {seed} 1 {depth}))
""")
            n += 1
    OUT.write_text(HEADER + "".join(arms) + "--\n")
    print(f"{n} sim exact-trace cases")
    print(f"TOTAL {n}")


if __name__ == "__main__":
    main()
