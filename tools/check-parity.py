#!/usr/bin/env python3
"""Machine-check the parity ledger (PORT-COMPLETION-PLAN-2 unit 0).

Parses desk/doc/parity-manifest.md, validates that every row carries a status
from the closed set, and prints a histogram. Needs no Java oracle, so the
release gate can run it unconditionally.

  tools/check-parity.py           report the ledger histogram
  tools/check-parity.py --check   exit nonzero if any row is unclassified or
                                  malformed (used by the scaffold gate)

The ledger is a *scaffold* ledger until every in-scope row reaches a terminal
status: `parity`, `approved-difference`, `replaced`, or `excluded`. Rows that
are still `partial`, `absent`, or `oracle-only` are reported but do not fail
`--check` yet — they fail the real release gate (unit 12), not this one. What
`--check` enforces now is that nothing in scope is *unclassified*.
"""
import sys
from collections import Counter
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
MANIFEST = REPO / "desk/doc/parity-manifest.md"
VALID = {"parity", "partial", "approved-difference", "replaced",
         "absent", "excluded", "oracle-only"}
# statuses that still owe work before the real release gate can pass
OPEN = {"partial", "absent", "oracle-only"}
HEADER_CELLS = {"id", "status"}  # markers of the table header row


def rows() -> list:
    """Yield (line-no, id, status, cells) for every data row of every table."""
    out = []
    in_table = False
    for i, line in enumerate(MANIFEST.read_text().splitlines(), 1):
        s = line.strip()
        if not s.startswith("|"):
            in_table = False
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        low = {c.lower() for c in cells}
        if HEADER_CELLS <= low:          # header row: | id | ... | status | ... |
            in_table = True
            header = [c.lower() for c in cells]
            continue
        if set(cells) <= {""} or all(set(c) <= {"-", ":"} for c in cells):
            continue                     # separator row
        if not in_table:
            continue
        rid = cells[header.index("id")] if "id" in header else cells[0]
        status = cells[header.index("status")] if "status" in header else ""
        out.append((i, rid, status, cells))
    return out


def main() -> int:
    check = "--check" in sys.argv
    data = rows()
    hist = Counter()
    bad = []
    for lineno, rid, status, cells in data:
        if status not in VALID:
            bad.append(f"  line {lineno}: row '{rid}' has status "
                       f"'{status}' not in {sorted(VALID)}")
        else:
            hist[status] += 1
    print(f"parity ledger: {len(data)} rows")
    for st in sorted(VALID):
        print(f"  {st:20} {hist.get(st, 0)}")
    owed = sum(hist[s] for s in OPEN)
    terminal = len(data) - owed - len(bad)
    print(f"terminal (parity/approved-difference/replaced/excluded): {terminal}")
    print(f"still owed (partial/absent/oracle-only): {owed}")
    if bad:
        print("\nUNCLASSIFIED / malformed rows:")
        print("\n".join(bad))
        return 1
    if not data:
        print("no ledger rows parsed — manifest table shape changed")
        return 1
    print("\nledger is well-formed: every in-scope row is classified.")
    if owed and check:
        print(f"note: {owed} row(s) still owe work; this is a scaffold gate, "
              "so that is expected (fails the real release gate, not this one).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
