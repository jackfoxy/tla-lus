#!/usr/bin/env python3
"""Assert R1's acceptance sentence, clause by clause (R1.9.4).

The sentence, from `R1-release-work-breakdown.md`:

    Drive every in-scope ledger row to `parity` or a tested
    `approved-difference`, stand up tier-2 test automation, and replace the
    scaffold gate with the real release gate. R1's acceptance: **zero
    `partial` and zero unexplained `absent` rows**, tiers 1 and 2 green
    (tier 3 descoped), clean install/upgrade/restart.

"Asserted rather than asserted-by-hand" means no human writes the conclusion.
Each clause below is computed, and the script prints ACCEPTED only if every
one holds.

One clause cannot be computed from a shell: the ship suite needs a running
ship. So it is EVIDENCE THE CALLER MUST SUPPLY, not an assumption --

    tools/r1-acceptance.py --suite-log /path/to/captured/test/output

-- and without it the verdict is NOT ACCEPTED (evidence missing), never a
silent pass. That is the whole point: the hand's job is to supply a
measurement, not to write a conclusion.

Exit 0 = ACCEPTED, 1 = not.
"""
import argparse
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


def run(*cmd) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


def c_ledger() -> None:
    """zero partial, zero unexplained absent; every row terminal."""
    r = run(sys.executable, str(REPO / "tools/check-parity.py"))
    counts = dict(re.findall(r"^\s+(\S+)\s+(\d+)$", r.stdout, re.M))
    owed = re.search(r"still owed \(partial/absent/oracle-only\): (\d+)", r.stdout)
    term = re.search(r"terminal \(parity/approved-difference/replaced/excluded\): (\d+)", r.stdout)
    rows = re.search(r"parity ledger: (\d+) rows", r.stdout)
    if not (owed and term and rows):
        clause("ledger closed", False, "could not read check-parity.py output")
        return
    ok = (r.returncode == 0 and int(owed.group(1)) == 0
          and counts.get("partial") == "0" and counts.get("absent") == "0"
          and counts.get("oracle-only") == "0")
    clause("zero partial, zero absent, zero oracle-only",
           ok,
           f"{rows.group(1)} rows, {term.group(1)} terminal, {owed.group(1)} owed "
           f"(parity {counts.get('parity')}, approved-difference "
           f"{counts.get('approved-difference')}, replaced {counts.get('replaced')}, "
           f"excluded {counts.get('excluded')})")


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
    clause("release gate passes (scaffold hygiene + tiers 1-2 + no stubs + "
           "refusals documented + upgrade/restart + reproducible artifacts)",
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


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--suite-log", type=Path, default=None,
                    help="captured output of `-test /=tla-lus=/tests ~` on the ship")
    ap.add_argument("--skip-gate", action="store_true",
                    help="do not run release-gate.sh (the clause then FAILS, by design)")
    args = ap.parse_args()

    print("R1 acceptance — each clause computed, none asserted by hand\n")
    c_ledger()
    c_coherence()
    c_release_gate(args.skip_gate)
    c_suite(args.suite_log)

    held = sum(1 for _, h, _ in clauses if h)
    print(f"\n{held}/{len(clauses)} clauses hold.")
    if held == len(clauses):
        print("\nR1 ACCEPTED.")
        print("  every in-scope ledger row is parity, approved-difference,")
        print("  replaced or excluded; tiers 1 and 2 reproduce byte-identically")
        print("  from the pins; the release gate passes; the ship suite is green.")
        print("  (tier 3 descoped by R1.1.R3 — a performance harness measures the")
        print("   port against itself, so it cannot feed a parity gate.)")
        return 0
    print("\nR1 NOT ACCEPTED — the failing clauses above are the remaining work.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
