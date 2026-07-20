#!/usr/bin/env python3
"""Differential / compatibility validation harness (unit 14).

Regenerates every differential golden and generated test shard from the
pinned Java oracle, then reports whether anything changed. A clean run
proves tier-1 reproducibility: the committed goldens are exactly what the
pinned tlaplus commit produces, so `-test /=tla-lus=/tests` on the fake
ship is validating against the real oracle rather than a stale snapshot.

  tools/validate.py            regenerate goldens/shards, then report drift
  tools/validate.py --check    same, but exit nonzero if anything drifted

Tiers (see desk/doc/testing.md):
  tier 1  this script + `-test /=tla-lus=/tests ~`  (every change)
  tier 2  tlaplus/test-model + a tlaplus-Examples matrix   (CI/nightly)
  tier 3  broader examples + bounded performance models    (pre-release)

The oracle jar must be built from the pinned commit; each generator and
tools/oracle/*.java refuse to run off-pin (or are guarded here).
"""
import hashlib
import subprocess
import sys
from pathlib import Path

REPO = Path("/mnt/mars/gitrepos/tla-lus")
TLA = Path("/mnt/mars/gitrepos/tlaplus")
TOOLS = TLA / "tlatools/org.lamport.tlatools"
JAR = TOOLS / "dist/tla2tools.jar"
PIN = "4ba7d8811289fb8e95dac4d5e554c05216ba3100"
ORACLE = REPO / "tools/oracle"

# every in-scope generator regenerates its oracle-derived output. Each one
# prints a final `TOTAL <n>` line: the count of cases it actually ran, so the
# docs cite a generated number rather than a hand-written one (unit 0).
# `comparator`:
#   pass         a Hoon test/shard differentially checks this oracle output
#   oracle-only  goldens are captured from the pin but nothing in Hoon
#                compares against them yet (the Hoon owner is still absent)
GENERATORS = [
    ("gen-lexer-tests.py",  "pass",        "Lexer (boundary + syntax corpus)",   "desk/tests/lib/tla/lexer/*.hoon"),
    ("gen-parser-tests.py", "pass",        "Parser (syntax corpus accept/reject)", "desk/tests/lib/tla/corpus-*.hoon"),
    ("gen-parse-err-tests.py", "pass",     "Parse-error diagnostics (PErrors text)", "desk/tests/lib/tla/parse-err.hoon"),
    ("gen-bnf-manifest.py", "pass",        "BNF grammar productions",            "desk/tests/lib/tla/bnf.hoon"),
    ("gen-modres-tests.py", "pass",        "Module resolution graphs",           "desk/tests/lib/tla/modres.hoon"),
    ("gen-sem-tests.py",    "pass",        "Semantic graph + levels",            "desk/tests/lib/tla/sem.hoon"),
    ("gen-eval-tests.py",   "pass",        "Constant evaluation (TLC REPL)",     "desk/tests/lib/tla/eval.hoon"),
    ("gen-mc-tests.py",     "pass",        "Safety + liveness model checking",   "desk/tests/lib/tla/mc.hoon"),
    ("gen-stdmods.py",      "pass",        "Vendored StandardModules",           "desk/lib/tla/stdmods.hoon"),
    ("gen-pcal-tests.py",   "oracle-only", "PlusCal translation goldens",        "(no Hoon translator yet — unit 8)"),
    ("gen-cfg-tests.py",    "oracle-only", "TLC .cfg parse goldens (ModelConfig)", "(no Hoon config parser yet — unit 5.1)"),
]
EVIDENCE = "desk/doc/evidence-counts.md"
# paths whose contents are oracle-derived and must reproduce byte-identically
TRACKED = ["desk/test-data", "desk/tests", "desk/doc/tla-bnf.md",
           "desk/lib/tla/stdmods.hoon", EVIDENCE]


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def check_pin() -> bool:
    if not JAR.exists():
        print(f"missing {JAR} — build it: "
              f"(cd {TOOLS} && ant -f customBuild.xml info compile compile-test dist)")
        return False
    head = sh(["git", "-C", str(TLA), "rev-parse", "HEAD"]).stdout.strip()
    if head != PIN:
        print(f"tlaplus checkout is {head}, not pinned {PIN} — refusing to validate")
        return False
    return True


def compile_oracle() -> bool:
    build = ORACLE / "build"
    build.mkdir(exist_ok=True)
    srcs = [str(p) for p in ORACLE.glob("*.java")]
    r = sh(["java", "-m", "jdk.compiler/com.sun.tools.javac.Main",
            "-cp", str(JAR), "-d", str(build)] + srcs)
    if r.returncode != 0:
        print("oracle compile failed:\n" + r.stdout + r.stderr)
        return False
    return True


def run_generators() -> dict:
    """Run every generator; return {generator: case-count} parsed from the
    `TOTAL <n>` line each one prints. A generator whose output has no Hoon
    comparator is tagged `orac` (oracle-only), never a plain pass."""
    counts = {}
    for g, comp, _area, _owner in GENERATORS:
        r = sh(["python3", str(REPO / "tools" / g)])
        total = None
        for line in r.stdout.splitlines():
            if line.startswith("TOTAL "):
                total = int(line.split()[1])
        counts[g] = total
        if r.returncode != 0:
            tag = "FAIL"
        elif comp == "oracle-only":
            tag = "orac"
        else:
            tag = "ok  "
        print(f"  {tag} {g}: {total} cases ({comp})")
        if r.returncode != 0:
            print(r.stderr)
    return counts


def write_evidence(counts: dict) -> None:
    """Regenerate desk/doc/evidence-counts.md from the live generator runs so
    the status docs cite a machine-produced count, not a hand-written one."""
    lines = [
        "# Evidence Counts",
        "",
        "GENERATED by `tools/validate.py` — do not edit. Each row is the case",
        f"count a generator actually ran against the pinned oracle (`tlaplus@{PIN[:9]}`).",
        "`oracle-only` means goldens are captured but no Hoon code compares against",
        "them yet; those cases prove nothing about parity until a comparator lands.",
        "",
        "| Generator | Cases | Comparator | Area | Hoon owner |",
        "|---|---|---|---|---|",
    ]
    passed = orac = 0
    for g, comp, area, owner in GENERATORS:
        n = counts.get(g)
        lines.append(f"| `{g}` | {n} | {comp} | {area} | `{owner}` |")
        if comp == "oracle-only":
            orac += n or 0
        else:
            passed += n or 0
    lines += [
        "",
        f"Compared cases: **{passed}**.  Oracle-only cases: **{orac}**.",
        "",
        "The oracle-baseline suite (`desk/test-data/oracle/regen.sh`) adds 14 "
        "end-to-end golden cases outside this table.",
        "",
    ]
    (REPO / EVIDENCE).write_text("\n".join(lines))


def snapshot() -> dict:
    """content hash of every oracle-derived file (git-independent: this
    repo intentionally stays uncommitted, so we validate idempotency by
    hashing rather than by diffing against a git index)."""
    h = {}
    for t in TRACKED:
        p = REPO / t
        files = [p] if p.is_file() else sorted(p.rglob("*"))
        for f in files:
            if f.is_file():
                h[str(f.relative_to(REPO))] = hashlib.md5(f.read_bytes()).hexdigest()
    return h


def drift(before: dict, after: dict) -> list:
    keys = sorted(set(before) | set(after))
    out = []
    for k in keys:
        if before.get(k) != after.get(k):
            tag = "changed" if k in before and k in after else ("added" if k in after else "removed")
            out.append(f"{tag}: {k}")
    return out


def main() -> int:
    check = "--check" in sys.argv
    if not check_pin():
        return 2
    print("compiling oracle dumpers...")
    if not compile_oracle():
        return 2
    before = snapshot()
    print("regenerating goldens from the pinned oracle...")
    counts = run_generators()
    write_evidence(counts)
    # oracle baseline cases (unit-0 regen.sh) validate separately
    rc = sh(["bash", str(REPO / "desk/test-data/oracle/regen.sh"), "--check"])
    ok = rc.returncode == 0
    print(f"  {'ok  ' if ok else 'FAIL'} regen.sh --check "
          f"({sum(1 for l in rc.stdout.splitlines() if l.startswith('ok'))} baseline cases)")
    d = drift(before, snapshot())
    if d or not ok:
        print(f"\nDRIFT: {len(d)} oracle-derived file(s) changed after regeneration:")
        for l in d[:40]:
            print("  " + l)
        print("\nInvestigate before committing: a change here means the pinned "
              "oracle no longer produces the committed goldens (or a generator "
              "is nondeterministic). Never weaken a golden without proving the "
              "Java behavior from the pin.")
        return 1 if check else 0
    print("\ntier-1 differential integrity: OK — all goldens reproduce "
          "byte-identically from the pinned oracle.")
    print("Now run the Hoon side:  -test /=tla-lus=/tests ~   (on the fake ship)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
