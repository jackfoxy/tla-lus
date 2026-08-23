#!/usr/bin/env python3
"""Assert `port-map.md` and `parity-manifest.md` cannot drift apart, or away
from the tree (R1.9.0).

R1.9.0 was written as "regenerate port-map.md from the ledger". Measured, that
is not possible and would not be the right thing: the two documents are
ORTHOGONAL projections, not two views of one table.

  * `parity-manifest.md` is keyed by JAVA CLUSTER and answers "is this at
    parity, and on what evidence" — 125 rows, statuses, rationale.
  * `port-map.md` §7 is keyed by UNIT and answers "what happened, when, and
    why" — an append-only progress log. Nothing in the ledger records that a
    residue text was wrong, or that a measurement cancelled a planned unit.

Neither generates the other. What CAN drift, and did, is the small set of facts
they share with each other and with the tree. That is what this checks:

  1. every `*.hoon` file either document names as an owner exists;
  2. the pinned oracle commit in port-map §1 is the one the tooling uses;
  3. every ledger `unit` value appears in port-map's inventory unit column
     (i.e. no ledger row is attributed to a unit port-map never heard of);
  4. the ledger tally the docs quote is the one `check-parity.py` computes
     (port-map's §7 progress log is exempt: it quotes each increment's figure
     on purpose, as it does superseded file names);
  5. every `approved-difference` ledger row appears in compatibility.md's
     support matrix (R1.9.1) — a deliberate divergence cannot be added to the
     ledger and left out of the document that is supposed to enumerate them;
  6. every `+$` on the public wire (`sur/tla-lus.hoon`) appears in api.md
     (R1.9.2) — a noun a consumer can receive cannot ship undocumented.

Exit 0 clean, 1 on any drift, with the offending reference named.
"""
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DESK = REPO / "desk"
PORTMAP = DESK / "doc/port-map.md"
LEDGER = DESK / "doc/parity-manifest.md"
GATE = REPO / "tools/scaffold-gate.sh"
VALIDATE = REPO / "tools/validate.py"

fails = []


def bad(msg: str) -> None:
    fails.append(msg)
    print(f"  FAIL  {msg}")


def ok(msg: str) -> None:
    print(f"  ok    {msg}")


def hoon_files() -> set:
    return {p.name for p in (DESK / "lib").glob("*.hoon")} | \
           {p.name for p in (DESK / "app").glob("*.hoon")} | \
           {p.name for p in (DESK / "sur").glob("*.hoon")}


def check_owners() -> None:
    """(1) Every .hoon an owner column names must exist."""
    have = hoon_files()
    pm = PORTMAP.read_text()
    # only the inventory sections: the progress log quotes historical names on
    # purpose (a deleted file is part of what happened)
    i, j = pm.index("## 4. Primary Inventory"), pm.index("## 6. Selected Oracle Cases")
    stale = sorted({m for m in re.findall(r"`([a-z0-9-]+\.hoon)`", pm[i:j])
                    if m not in have})
    if stale:
        bad(f"port-map §4-§5 names Hoon files that do not exist: {', '.join(stale)}")
    else:
        ok("port-map §4-§5 owner columns all resolve to real files")

    missing = set()
    for line in LEDGER.read_text().split("\n"):
        if not line.startswith("| ") or line.count("|") < 7:
            continue
        cells = line.split("|")
        if cells[1].strip() in ("id", ""):
            continue
        for m in re.findall(r"\b(?:lib|app|sur)/([a-z0-9-]+)", cells[3]):
            if f"{m}.hoon" not in have:
                missing.add(m)
    if missing:
        bad(f"ledger hoon-owner names files that do not exist: {', '.join(sorted(missing))}")
    else:
        ok("ledger hoon-owner column resolves to real files")


def check_pin() -> None:
    """(2) One pin, quoted identically wherever it is quoted."""
    pins = {}
    m = re.search(r"`([0-9a-f]{40})`", PORTMAP.read_text())
    if m:
        pins["port-map §1"] = m.group(1)
    m = re.search(r'PIN="([0-9a-f]{40})"', GATE.read_text())
    if m:
        pins["scaffold-gate.sh"] = m.group(1)
    m = re.search(r'PIN\s*=\s*"([0-9a-f]{40})"', VALIDATE.read_text())
    if m:
        pins["validate.py"] = m.group(1)
    if len(pins) < 2:
        bad(f"could not find the pin in at least two places (found {list(pins)})")
        return
    if len(set(pins.values())) != 1:
        bad(f"pin disagreement: {pins}")
    else:
        ok(f"one pinned oracle commit across {len(pins)} places ({next(iter(pins.values()))[:9]})")


def check_units() -> None:
    """(3) No ledger row attributed to a unit port-map never mentions."""
    pm = PORTMAP.read_text()
    units = set()
    for line in LEDGER.read_text().split("\n"):
        if not line.startswith("| ") or line.count("|") < 7:
            continue
        cells = line.split("|")
        if cells[1].strip() in ("id", ""):
            continue
        for tok in re.findall(r"\d+[A-Za-z]?(?:\.\d+)*", cells[6]):
            units.add(tok.split(".")[0])
    unknown = sorted(u for u in units if not re.search(rf"\b{re.escape(u)}\b", pm))
    if unknown:
        bad(f"ledger cites units port-map never mentions: {', '.join(unknown)}")
    else:
        ok(f"every ledger unit ({len(units)}) appears in port-map")


def check_tally() -> None:
    """(4) A tally quoted in prose must be the computed one."""
    r = subprocess.run([sys.executable, str(REPO / "tools/check-parity.py")],
                       capture_output=True, text=True)
    m = re.search(r"still owed \(partial/absent/oracle-only\): (\d+)", r.stdout)
    if not m:
        bad("could not read the owed count from check-parity.py")
        return
    owed = int(m.group(1))
    m2 = re.search(r"terminal \(parity/approved-difference/replaced/excluded\): (\d+)", r.stdout)
    terminal = int(m2.group(1)) if m2 else -1
    stale = []
    pats = [
        # "still owed (...): N"  and  "N still owed"  and  "N rows"
        (r"still owed[^)\n]*?\)?:\s*(\d+)", owed),
        (r"\*\*(\d+) still owed", owed),
        (r"(\d+) still owed", owed),
        (r"\*\*(\d+) rows, (?:\d+) still owed", None),
    ]
    for doc in (PORTMAP, LEDGER, DESK / "doc/compatibility.md"):
        text = doc.read_text()
        # port-map's §7 progress log quotes the tally AS IT WAS at each
        # increment -- the same reason check (1) exempts it from the
        # file-existence sweep. A log that could not cite a superseded figure
        # would not be a log.
        if doc is PORTMAP and "## 7. Progress Log" in text:
            text = text[:text.index("## 7. Progress Log")]
        for pat, want in pats[:3]:
            for q in re.findall(pat, text):
                if int(q) != want:
                    stale.append(f"{doc.name} quotes owed={q}, computed {want}")
        # a bare "(N rows, M still owed)" phrasing
        for rows, om in re.findall(r"\((\d+) rows, (\d+) still owed\)", text):
            if int(om) != owed:
                stale.append(f"{doc.name} quotes owed={om}, computed {owed}")
            if int(rows) != terminal + owed:
                stale.append(f"{doc.name} quotes rows={rows}, computed {terminal + owed}")
    if stale:
        for s in stale:
            bad(s)
    else:
        ok(f"quoted tallies agree with check-parity.py ({terminal} terminal, {owed} owed)")


def check_approved_differences() -> None:
    """(5) Every approved-difference row must appear in the support matrix."""
    compat = (DESK / "doc/compatibility.md").read_text()
    try:
        i = compat.index("## Support matrix")
        j = compat.index("\n## ", i + 1)
    except ValueError:
        bad("compatibility.md has no '## Support matrix' section")
        return
    matrix = compat[i:j]
    rows = []
    for line in LEDGER.read_text().split("\n"):
        if not line.startswith("| ") or line.count("|") < 7:
            continue
        cells = line.split("|")
        if cells[5].strip() == "approved-difference":
            rows.append(cells[1].strip())
    absent = [r for r in rows if f"`{r}`" not in matrix]
    if absent:
        bad("approved-difference rows missing from the support matrix: "
            + ", ".join(absent))
    else:
        ok(f"all {len(rows)} approved-difference rows appear in the support matrix")


def check_wire_documented() -> None:
    """(6) Every public mold must appear in api.md."""
    sur = (DESK / "sur/tla-lus.hoon").read_text()
    api = (DESK / "doc/api.md").read_text()
    molds = re.findall(r"^\+\$\s+([a-z0-9-]+)", sur, re.M)
    absent = [m for m in molds if f"`{m}`" not in api]
    if absent:
        bad("public molds missing from api.md: " + ", ".join(absent))
    else:
        ok(f"all {len(molds)} public wire molds appear in api.md")


def main() -> int:
    print("== port-map / ledger coherence ==")
    check_owners()
    check_pin()
    check_units()
    check_tally()
    check_approved_differences()
    check_wire_documented()
    if fails:
        print(f"\nDRIFT: {len(fails)} problem(s).")
        return 1
    print("\nport-map and the ledger are coherent with each other and the tree.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
