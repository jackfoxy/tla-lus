#!/usr/bin/env python3
"""Assert R3's acceptance sentence, clause by clause (R3.3.2).

R3 is the last phase. Its sentence, stated here because `R3-work-breakdown.md`
opens with where R2 left off rather than with an acceptance paragraph:

    Every in-scope ledger row is terminal -- `parity`, a tested
    `approved-difference`, `replaced` or `excluded` -- with none owed; every
    differential CENSUS is empty, so no divergence is being carried; the docs
    agree with the ledger and the tree; the release gate passes; and the full
    ship suite is green. Tier 3 is REPORTED, never gated.

Two things this script deliberately does NOT do.

**It does not gate on tier 3.** R2.8.1a measured the run-to-run spread of the
median workload at 15.6% on a fresh boot -- over its own +/-15% bar -- and
decided report-only. `tools/tier3-report.py` prints the numbers and
`release-gate.sh` carries them as a REPORT. Promoting that to a clause needs a
new measurement, not a new opinion: *a flaky gate is one everyone learns to
ignore* (R1.1.R3).

**It does not touch `r1-acceptance.py`.** That script is the record of what R1
proved, and it has printed `R1 NOT ACCEPTED` since R2.0 deliberately re-opened
the ledger. Editing a red gate to make it green is the exact failure mode this
whole discipline exists to prevent; a phase that wants a verdict writes its own
script, as this one is.

One clause cannot be computed from a shell: the ship suite needs a running
ship. So it is EVIDENCE THE CALLER MUST SUPPLY --

    tools/r3-acceptance.py --suite-log /path/to/captured/test/output

-- and without it the verdict is NOT ACCEPTED (evidence missing), never a
silent pass. The hand's job is to supply a measurement, not to write a
conclusion.

Exit 0 = ACCEPTED, 1 = not.
"""
import argparse
import importlib.util
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DESK = REPO / "desk"

clauses = []


def clause(name: str, held: bool, detail: str) -> None:
    clauses.append((name, held, detail))
    print(f"  {'HOLDS ' if held else 'FAILS '} {name}\n           {detail}")


def report(name: str, detail: str) -> None:
    """A measurement that is READ, not asserted. Never affects the verdict."""
    print(f"  REPORT {name}\n           {detail}")


def run(*cmd) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


def load(name: str):
    spec = importlib.util.spec_from_file_location(
        name.replace("-", "_"), REPO / "tools" / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    sys.dont_write_bytecode = True          # tools/__pycache__ is tracked
    spec.loader.exec_module(mod)
    return mod


def c_ledger() -> None:
    """Every row terminal: zero partial, zero absent, zero oracle-only."""
    r = run(sys.executable, str(REPO / "tools/check-parity.py"))
    counts = dict(re.findall(r"^\s+(\S+)\s+(\d+)$", r.stdout, re.M))
    owed = re.search(r"still owed \(partial/absent/oracle-only\): (\d+)", r.stdout)
    term = re.search(r"terminal \(parity/approved-difference/replaced/excluded\): (\d+)",
                     r.stdout)
    rows = re.search(r"parity ledger: (\d+) rows", r.stdout)
    if not (owed and term and rows):
        clause("ledger closed", False, "could not read check-parity.py output")
        return
    ok = (r.returncode == 0 and int(owed.group(1)) == 0
          and counts.get("partial") == "0" and counts.get("absent") == "0"
          and counts.get("oracle-only") == "0")
    detail = (f"{rows.group(1)} rows, {term.group(1)} terminal, {owed.group(1)} owed "
              f"(parity {counts.get('parity')}, approved-difference "
              f"{counts.get('approved-difference')}, replaced {counts.get('replaced')}, "
              f"excluded {counts.get('excluded')})")
    clause("every ledger row terminal, none owed", ok, detail)


def c_census() -> None:
    """No divergence is being CARRIED.

    R3's whole character was censused divergences -- R2.8.2b froze three in the
    examples batch and R3.0 closed them; R3.2 froze a fourth (`BagsTest`) and
    R3.2a closed that -- so "the censuses are empty" is precisely the thing a
    reader would otherwise take on faith. Every frozen list is read from the
    generators that own it, so this cannot drift from them.

    Scope, stated so the clause is not read as more than it is: the tier-2
    censuses and the withheld `mc` arms. The `SKIPS` in `gen-stdops-tests.py`
    and `gen-core-eval-tests.py` are NOT included -- what remains in those is
    documented approved differences (`Print` has no console here, tlc2's
    multi-binder function print order), which `compatibility.md` carries and
    which are terminal, not owed.
    """
    g2 = load("gen-tier2-tests")
    frozen = {
        "sany curated (KNOWN_DIVERGENCES)": g2.KNOWN_DIVERGENCES,
        "tlc curated (TLC_DIVERGENCES)": g2.TLC_DIVERGENCES,
        "sany batch": g2.SANY_BATCH_DIVERGENCES,
        "tlc safety batch": g2.TLC_BATCH_DIVERGENCES,
        "tlc liveness batch": g2.TLC_LIVENESS_DIVERGENCES,
        "tlc examples batch": g2.TLC_EXAMPLES_DIVERGENCES,
        "subdir sany batch": g2.SUB_BATCH_DIVERGENCES,
    }
    mc = load("gen-mc-tests")
    nonempty = [f"{k} ({len(v)})" for k, v in frozen.items() if v]
    if mc.SKIPS:
        nonempty.append(f"withheld mc arms ({len(mc.SKIPS)})")
    clause("every tier-2 census empty, no mc arm withheld",
           not nonempty,
           "all 7 frozen divergence lists empty and gen-mc-tests SKIPS empty"
           if not nonempty else "carrying: " + ", ".join(nonempty))


def c_coherence() -> None:
    r = run(sys.executable, str(REPO / "tools/check-portmap.py"))
    clause("docs coherent with the ledger and the tree",
           r.returncode == 0,
           "check-portmap.py: owners exist, one pin, units resolve, tallies agree, "
           "approved differences enumerated, wire molds documented")


def c_release_gate(skip: bool) -> None:
    if skip:
        clause("release gate passes", False,
               "--skip-gate given: not run, so not asserted")
        return
    r = run("bash", str(REPO / "tools/release-gate.sh"))
    tail = [l for l in r.stdout.splitlines() if l.startswith("RELEASE GATE")]
    clause("release gate passes (scaffold hygiene + ledger closed + tiers 1-2 "
           "+ no stubs + refusals documented + upgrade/restart + reproducible "
           "artifacts)",
           r.returncode == 0,
           tail[0] if tail else "release-gate.sh produced no verdict")


def c_suite(log: Path | None) -> None:
    if log is None:
        clause("full ship suite green", False,
               "no --suite-log supplied; the suite needs a running ship, so this "
               "clause is evidence the caller must provide")
        return
    if not log.exists():
        clause("full ship suite green", False, f"{log} does not exist")
        return
    text = log.read_text(errors="replace")
    verdict = re.findall(r"^ok=%\.([yn])", text, re.M)
    failed = len(re.findall(r"^FAILED\s", text, re.M))
    passed = len(re.findall(r"^OK\s", text, re.M))
    if not verdict:
        clause("full ship suite green", False,
               f"{log.name} carries no `ok=%.y`/`ok=%.n` verdict line")
        return
    ok = verdict[-1] == "y" and failed == 0
    clause("full ship suite green", ok,
           f"{log.name}: ok=%.{verdict[-1]}, {passed} arms OK, {failed} FAILED")


def r_tier3(log: Path | None) -> None:
    """Tier 3 is READ, not asserted -- R2.8.1a's decision, kept explicit here so
    a later reader has to overrule a measurement rather than an omission."""
    if log is None or not log.exists():
        report("tier 3 (performance)",
               "report-only by R2.8.1a (median workload spread 15.6% on a fresh "
               "boot, over its own +/-15% bar). Run `tools/tier3-report.py` "
               "against the ship and pass --tier3-log to have the numbers "
               "printed here. Its absence does NOT affect the verdict")
        return
    text = log.read_text(errors="replace")
    lines = [l for l in text.splitlines() if l.strip()]
    report("tier 3 (performance)",
           f"{log.name}: " + (lines[-1][:160] if lines else "empty")
           + "  -- read, not gated (R2.8.1a)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--suite-log", type=Path, default=None,
                    help="captured output of `-test /=tla-lus=/tests ~` on the ship")
    ap.add_argument("--tier3-log", type=Path, default=None,
                    help="captured output of tools/tier3-report.py (REPORTED, never gated)")
    ap.add_argument("--skip-gate", action="store_true",
                    help="do not run release-gate.sh (the clause then FAILS, by design)")
    args = ap.parse_args()

    print("R3 acceptance — each clause computed, none asserted by hand\n")
    c_ledger()
    c_census()
    c_coherence()
    c_release_gate(args.skip_gate)
    c_suite(args.suite_log)
    r_tier3(args.tier3_log)

    held = sum(1 for _, h, _ in clauses if h)
    print(f"\n{held}/{len(clauses)} clauses hold.")
    if held == len(clauses):
        print("\nR3 ACCEPTED.")
        print("  every in-scope ledger row is parity, approved-difference,")
        print("  replaced or excluded; no census carries a divergence and no mc")
        print("  arm is withheld; the docs agree with the ledger and the tree;")
        print("  the release gate passes; the ship suite is green.")
        print("  (tier 3 is REPORTED, not gated — R2.8.1a measured the noise.)")
        return 0
    print("\nR3 NOT ACCEPTED — the failing clauses above are the remaining work.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
