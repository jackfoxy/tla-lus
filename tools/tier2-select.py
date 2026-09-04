#!/usr/bin/env python3
"""The tier-2 spec SELECTION RULE: which specs would bring coverage the
current comparator corpus does not have.

R2.8.2a wrote the first version of this and R2.8.2b, which CONSUMES it, found
it wrong in four ways -- all of them in the direction of reporting LESS work
than there is, which is how "the answer is add nothing" survived a review:

  1. The CHECKED SET was wrong.  It credited `CigaretteSmokers` and
     `SimpleAllocator` as checker-exercised because they appear in the
     generator's `CURATED` list -- but `CURATED` is an ORACLE CAPTURE (a
     pinned `.txt` of Java's output); the specs the Hoon CHECKER actually runs
     are `TLC_CURATED`, which held only `DieHard`, `HourClock` and `TCommit`.
     It also dropped `DieHard` for the same reason.  Crediting two specs that
     never reach `check:check` hid three features.
  2. It matched features inside COMMENTS.  `SimpleAllocator.cfg` carries
     `\\** SYMMETRY Symmetry`, commented out with the warning that symmetry
     breaks its liveness properties -- and that comment was the only evidence
     of SYMMETRY coverage anywhere in the corpus.
  3. Its config fallback globbed `*.cfg` and took the FIRST, so a spec with no
     config of its own was scored on a SIBLING'S config.
  4. It never asked whether a candidate has a config at all.  A spec TLC
     cannot be pointed at is not a comparator candidate.

The rule itself, stated once and unchanged:

    Take the in-scope (`check`-class) specs that exercise a LEDGER-ROW FAMILY
    the currently-checked corpus does not, most-new-first and cheapest-first
    within that, until the nightly budget is reached.

"Currently checked" means the Hoon CHECKER, not SANY: the 452-spec SANY
batches exercise the front end and say nothing about `check:check`.  The three
checked lists are read out of `gen-tier2-tests.py` by IMPORTING it, so this
script cannot drift from them the way a regex over the source could.

A feature is a PROXY for a ledger row, not the row itself.

  tools/tier2-select.py             the rule's current answer
  tools/tier2-select.py --table     also every in-scope spec and its features
  tools/tier2-select.py --corpus X  `examples` (default, R2.8.2's scope),
                                    `test-model`, or `both`
"""
import argparse
import importlib.util
import re
import sys
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
INV = REPO / "desk/test-data/tier2/inventory.txt"
GEN = REPO / "tools/gen-tier2-tests.py"
EX = Path("/mnt/mars/gitrepos/tlaplus-Examples")
TM = Path("/mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools/test-model")

#  feature -> the ledger-row family it stands in for
FEATS = {
    "symmetry":   (r"\bSYMMETRY\b",                "tlc-safety-symmetry"),
    "view":       (r"\bVIEW\b",                    "cfg-view"),
    "alias":      (r"\bALIAS\b",                   "cfg-alias"),
    "constraint": (r"\bCONSTRAINT\b",              "tlc-safety-constraint"),
    "fairness":   (r"\b(?:WF_|SF_)",               "tlc-live-fairness"),
    "temporal":   (r"(?:<>|\[\])",                 "tlc-live-normalize"),
    "recursive":  (r"\bRECURSIVE\b",               "tlc-eval-node"),
    "choose":     (r"\bCHOOSE\b",                  "tlc-binders"),
    "subset":     (r"\bSUBSET\b",                  "tlc-enum"),
    "seq":        (r"EXTENDS[^\n]*\bSequences\b",  "tlc-module-sequences"),
    "bags":       (r"EXTENDS[^\n]*\bBags\b",       "tlc-module-bags"),
    "finitesets": (r"EXTENDS[^\n]*\bFiniteSets\b", "tlc-module-finitesets"),
    "reals":      (r"EXTENDS[^\n]*\bReals\b",      "tlc-module-excluded"),
    "instance":   (r"\bINSTANCE\b",                "semantic-graph"),
    "assume":     (r"\bASSUME\b",                  "tlc-safety-assume"),
    "except":     (r"\bEXCEPT\b",                  "tlc-value-except"),
    "tlcops":     (r"EXTENDS[^\n]*\bTLC\b",        "tlc-module-tlc"),
    "rcdset":     (r"\[\s*\w+\s*:",                "tlc-eval-node"),
    "fcnset":     (r"->\s*\w+\s*\]",               "tlc-eval-node"),
}


LEDGER = REPO / "desk/doc/parity-manifest.md"


def ledger_rows() -> dict:
    """The ledger's own row names.  `FEATS` claims to map a feature to a LEDGER
    ROW, and R2.8.2a's table named four the ledger does not have --
    `tlc-symmetry` (it is `tlc-safety-symmetry`), `tlc-module-reals` (Reals
    lives inside `tlc-module-excluded`), `semantic-instance` (a `port-map.md`
    differential, not a ledger row) and slash forms like `tlc-eval-node/rcds`.
    Adding this check found SIX MORE -- `cfg-constraint`, `tlc-eval-choose`,
    `tlc-eval-except`, `tlc-eval-lazyset`, `tlc-eval-recursive`,
    `tlc-liveness` -- so ELEVEN of nineteen entries named a row that does not
    exist.  A claim about the ledger that the ledger was never asked about.
    Checked rather than commented, so a rename fails loudly."""
    out = {}
    for ln in LEDGER.read_text().splitlines():
        if ln.startswith("| ") and ln.count("|") > 5:
            f = ln.split("|")
            n = f[1].strip()
            if n and n != "id" and not set(n) <= set("- "):
                out[n] = f[5].strip()
    return out


def gen():
    """The generator itself, imported -- the checked lists are read from the
    objects, not scraped out of the source."""
    sys.dont_write_bytecode = True        # tools/__pycache__ is tracked
    s = importlib.util.spec_from_file_location("gen_tier2", GEN)
    m = importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m


def strip_comments(t: str) -> str:
    """TLA+ comments out, both forms, `(* *)` nesting.  A commented-out
    `SYMMETRY` line is not coverage -- and in this corpus exactly one spec
    carries one, which was enough to hide the whole `tlc-symmetry` gap."""
    out, i, depth, n = [], 0, 0, len(t)
    while i < n:
        if t.startswith("(*", i):
            depth += 1
            i += 2
        elif depth and t.startswith("*)", i):
            depth -= 1
            i += 2
        elif depth:
            i += 1
        elif t.startswith("\\*", i):
            j = t.find("\n", i)
            i = n if j < 0 else j
        else:
            out.append(t[i])
            i += 1
    return "".join(out)


def cfg_of(tla: Path):
    """A spec's OWN config, or the `MC` wrapper's.  Never a sibling's: the
    first version globbed `*.cfg` and scored specs on configs belonging to
    other modules in the same directory."""
    for c in (tla.with_suffix(".cfg"), tla.parent / f"MC{tla.stem}.cfg"):
        if c.exists():
            return c
    return None


def spec_text(tla: Path) -> str:
    """Module plus its config, comments stripped.  SYMMETRY / CONSTRAINT /
    VIEW / ALIAS are CONFIG keywords and never appear in a module."""
    t = strip_comments(tla.read_text(errors="ignore"))
    c = cfg_of(tla)
    return t + "\n" + strip_comments(c.read_text(errors="ignore")) if c else t


def feats(t: str) -> set:
    return {k for k, (rx, _) in FEATS.items() if re.search(rx, t)}


def checked_specs(g) -> list:
    """Every spec that reaches `check:check`: the three batches plus the
    curated TLC comparator set.  NOT `CURATED`, which only captures Java's
    output -- crediting it is how the first version of this rule reported
    coverage the checker never had.

    A CENSUSED spec counts as exercised: the corpus reaches the row and the
    frozen divergence is the measurement.  Otherwise the rule would keep
    proposing the specs R2.8.2b already added."""
    out = [(m, TM / f"{m}.tla") for m in
           sorted(set(g.TLC_BATCH) | set(g.TLC_LIVENESS_BATCH))]
    out += [(mod, Path(sdir) / f"{mod}.tla")
            for _, sdir, mod, _ in g.TLC_CURATED]
    out += [(mod, Path(sdir) / f"{mod}.tla")
            for sdir, mod, _ in getattr(g, "TLC_EXAMPLES_BATCH", ())]
    return [(m, p) for m, p in out if p.exists()]


def censused(g) -> set:
    """Modules whose comparison is a FROZEN DIVERGENCE rather than agreement.
    They still count as exercised -- the corpus reaches the row and the
    divergence is the measurement -- but a feature reached ONLY through one is
    reported apart, because a refusal can fire BEFORE the machinery the feature
    names.  `Paxos` is the live example: it was selected for SYMMETRY and the
    port refuses it on a multi-binder action existential, so `tlc-symmetry` is
    not tested by it in any sense a reader should count."""
    out = set()
    for name in ("TLC_BATCH_DIVERGENCES", "TLC_LIVENESS_DIVERGENCES",
                 "TLC_EXAMPLES_DIVERGENCES"):
        for d in getattr(g, name, ()):
            out.add(d.split(" -> ")[0])
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--table", action="store_true")
    ap.add_argument("--corpus", default="examples",
                    choices=("examples", "test-model", "both"))
    a = ap.parse_args()
    g = gen()

    rows = ledger_rows()
    bogus = sorted({r for _, r in FEATS.values()} - set(rows))
    if bogus:
        print(f"WARNING: FEATS names {len(bogus)} row(s) the ledger does "
              f"not have: {', '.join(bogus)}\n")

    checked = checked_specs(g)
    cens = censused(g)
    have, agreed = set(), set()
    for n, p in checked:
        f = feats(spec_text(p))
        have |= f
        if n not in cens:
            agreed |= f
    missing = sorted(set(FEATS) - have)
    only_cens = sorted(have - agreed)

    print(f"specs currently run through the Hoon CHECKER: {len(checked)}"
          f"  ({len(cens & {n for n, _ in checked})} censused)")
    print(f"  {', '.join(n for n, _ in checked)}")
    print(f"  exercised, AGREEING: {', '.join(sorted(agreed))}")
    if only_cens:
        print(f"  reached ONLY by a censused divergence: {', '.join(only_cens)}"
              f"  <- the port refuses; not coverage")
    print(f"  NOT exercised: {', '.join(missing) or '(none)'}")
    #  a feature whose row is EXCLUDED is not coverage debt -- `Reals` is out
    #  of scope by argument, so "no spec supplies it" is the intended state
    mrows = sorted({FEATS[f][1] for f in missing})
    print("  -> ledger rows: " + (", ".join(
        f"{r} (**{rows[r]}**, not owed)" if rows.get(r) == "excluded" else r
        for r in mrows) or "(none)") + "\n")

    names = {n for n, _ in checked}
    want = {"examples", "test-model"} if a.corpus == "both" else {a.corpus}
    pool, cands, nocfg = [], [], 0
    for line in INV.read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        c = line.split("\t")
        if len(c) < 3 or c[2] != "check" or c[0] not in want:
            continue
        f = (EX if c[0] == "examples" else TM) / c[1]
        if not f.exists() or Path(c[1]).stem in names:
            continue
        cfg = cfg_of(f)
        fs = feats(spec_text(f))
        pool.append((c[0], c[1], fs, bool(cfg)))
        new = fs & set(missing)
        if not new:
            continue
        if cfg is None:
            nocfg += 1                    # TLC cannot be pointed at it
            continue
        live = bool(re.search(r"^\s*PROPERT(?:Y|IES)\b", strip_comments(
            cfg.read_text(errors="ignore")), re.M))
        cands.append((len(new), sorted(new), c[0], c[1],
                      f.stat().st_size, "liveness" if live else "safety"))

    print(f"in-scope (`check`-class) specs in the census "
          f"[{'+'.join(sorted(want))}]: {len(pool)}")
    if nocfg:
        print(f"  {nocfg} would bring a row but have NO config of their own "
              f"-- not comparator candidates")
    cands.sort(key=lambda r: (-r[0], r[4]))
    if not cands:
        print("candidates that bring an unexercised row: NONE\n")
        print("THE RULE'S ANSWER IS 'ADD NOTHING'. Per R2.8.2b's own terms --")
        print("*specs that exercise nothing new are corpus weight, not")
        print("coverage* -- that is the answer, and .2b closes on it.")
    else:
        print(f"candidates: {len(cands)}, in selection order\n")
        for n, new, corp, path, sz, kind in cands:
            print(f"  {n}  {path:<56}{sz // 1024:>4}KB  {kind:<8} "
                  f"{','.join(new)}")
    if a.table:
        print("\nevery in-scope spec and what it exercises:")
        for corp, path, fs, hascfg in sorted(pool):
            print(f"  {path:<62}{'cfg' if hascfg else '   '} "
                  f"{','.join(sorted(fs))}")


if __name__ == "__main__":
    main()
