#!/usr/bin/env python3
"""R2.8.2a's OUTPUT: the spec SELECTION RULE that R2.8.2b consumes.

R2.8.2b used to say "more `tlaplus-Examples` specs", with no count and no
rule, which made it the only unbounded row left in the plan. R2.8.2a owes it a
rule instead, and the rule has to be derived from the CENSUS -- the regenerated
inventory is the only thing that knows which specs the current corpus already
runs through the Hoon CHECKER.

The rule, stated once:

    Take the in-scope (`check`-class) `tlaplus-Examples` specs that exercise a
    LEDGER-ROW FAMILY the currently-checked corpus does not, most-new-first and
    cheapest-first within that, until the nightly budget is reached.

"Currently checked" means the Hoon CHECKER, not SANY: the 452-spec SANY batches
exercise the front end and say nothing about `check:check`. The checked set is
`TLC_BATCH` + `TLC_LIVENESS_BATCH` + the curated examples, read out of
`gen-tier2-tests.py` so this script cannot drift from it.

A feature is a PROXY for a ledger row, not the row itself, and the config
keywords (SYMMETRY / CONSTRAINT / VIEW / ALIAS) live in the `.cfg` rather than
the module -- scanning only the `.tla` silently reports them as unexercised,
which this script got wrong on its first pass.

  tools/tier2-select.py            print the rule's current answer
  tools/tier2-select.py --table    also print every candidate's features
"""
import argparse
import re
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
INV = REPO / "desk/test-data/tier2/inventory.txt"
GEN = REPO / "tools/gen-tier2-tests.py"
EX = Path("/mnt/mars/gitrepos/tlaplus-Examples")
TM = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/test-model")

#  feature -> the ledger-row family it stands in for
FEATS = {
    "symmetry":   (r"\bSYMMETRY\b",                "tlc-symmetry"),
    "view":       (r"\bVIEW\b",                    "cfg-view"),
    "alias":      (r"\bALIAS\b",                   "cfg-alias"),
    "constraint": (r"\bCONSTRAINT\b",              "cfg-constraint"),
    "fairness":   (r"\b(?:WF_|SF_)",               "tlc-live-fairness"),
    "temporal":   (r"(?:<>|\[\])",                 "tlc-liveness"),
    "recursive":  (r"\bRECURSIVE\b",               "tlc-eval-recursive"),
    "choose":     (r"\bCHOOSE\b",                  "tlc-eval-choose"),
    "subset":     (r"\bSUBSET\b",                  "tlc-eval-lazyset"),
    "seq":        (r"EXTENDS[^\n]*\bSequences\b",  "tlc-module-sequences"),
    "bags":       (r"EXTENDS[^\n]*\bBags\b",       "tlc-module-bags"),
    "finitesets": (r"EXTENDS[^\n]*\bFiniteSets\b", "tlc-module-finitesets"),
    "reals":      (r"EXTENDS[^\n]*\bReals\b",      "tlc-module-reals"),
    "instance":   (r"\bINSTANCE\b",                "semantic-instance"),
    "assume":     (r"\bASSUME\b",                  "tlc-safety-assume"),
    "except":     (r"\bEXCEPT\b",                  "tlc-eval-except"),
    "tlcops":     (r"EXTENDS[^\n]*\bTLC\b",        "tlc-module-tlc"),
    "rcdset":     (r"\[\s*\w+\s*:",                "tlc-eval-node/rcds"),
    "fcnset":     (r"->\s*\w+\s*\]",               "tlc-eval-node/fcns"),
}

CURATED_EXAMPLES = (("HourClock", "SpecifyingSystems/HourClock"),
                    ("TCommit", "transaction_commit"),
                    ("CigaretteSmokers", "CigaretteSmokers"),
                    ("SimpleAllocator", "allocator"))


def feats(t: str) -> set:
    return {k for k, (rx, _) in FEATS.items() if re.search(rx, t)}


def spec_text(tla: Path) -> str:
    """The module PLUS its config. SYMMETRY / CONSTRAINT / VIEW / ALIAS are
    CONFIG keywords and never appear in the module, so a `.tla`-only scan
    reports them unexercised when they are not."""
    t = tla.read_text(errors="ignore")
    for pat in (tla.stem + ".cfg", "MC*.cfg", "*.cfg"):
        got = sorted(tla.parent.glob(pat))
        if got:
            return t + "\n" + got[0].read_text(errors="ignore")
    return t


def batch(name: str) -> list:
    m = re.search(rf"^{name} = \[(.*?)\]", GEN.read_text(), re.S | re.M)
    return re.findall(r'"([A-Za-z0-9_]+)"', m.group(1)) if m else []


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--table", action="store_true")
    a = ap.parse_args()

    checked, have = [], set()
    for m in sorted(set(batch("TLC_BATCH")) | set(batch("TLC_LIVENESS_BATCH"))):
        p = TM / f"{m}.tla"
        if p.exists():
            have |= feats(spec_text(p))
            checked.append(m)
    for mod, sub in CURATED_EXAMPLES:
        p = EX / "specifications" / sub / f"{mod}.tla"
        if p.exists():
            have |= feats(spec_text(p))
            checked.append(mod)

    missing = sorted(set(FEATS) - have)
    print(f"specs currently run through the Hoon CHECKER: {len(checked)}")
    print(f"  exercised: {', '.join(sorted(have))}")
    print(f"  NOT exercised: {', '.join(missing) or '(none)'}")
    print(f"  -> ledger rows: "
          f"{', '.join(sorted({FEATS[f][1] for f in missing})) or '(none)'}\n")

    pool, cands = [], []
    for line in INV.read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        c = line.split("\t")
        if len(c) < 3 or c[0] != "examples" or c[2] != "check":
            continue
        f = EX / c[1]
        if not f.exists():
            continue
        fs = feats(spec_text(f))
        pool.append((c[1], fs))
        new = fs & set(missing)
        if new:
            cands.append((len(new), sorted(new), c[1], f.stat().st_size))

    print(f"in-scope (`check`-class) examples specs in the census: {len(pool)}")
    cands.sort(key=lambda r: (-r[0], r[3]))
    if not cands:
        print("candidates that bring an unexercised row: NONE\n")
        print("THE RULE'S ANSWER IS 'ADD NOTHING'. Per R2.8.2b's own terms --")
        print("*specs that exercise nothing new are corpus weight, not")
        print("coverage* -- that is the answer, and .2b closes on it.")
    else:
        print(f"candidates: {len(cands)}, in selection order\n")
        for n, new, path, sz in cands:
            print(f"  {n}  {path:<58}{sz//1024:>4}KB  {','.join(new)}")
    if a.table:
        print("\nevery in-scope examples spec and what it exercises:")
        for path, fs in sorted(pool):
            print(f"  {path:<62}{','.join(sorted(fs))}")


if __name__ == "__main__":
    main()
