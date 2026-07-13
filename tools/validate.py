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

# each generator regenerates its goldens + Hoon shard from the oracle
GENERATORS = [
    "gen-lexer-tests.py",
    "gen-parser-tests.py",
    "gen-bnf-manifest.py",
    "gen-modres-tests.py",
    "gen-sem-tests.py",
    "gen-eval-tests.py",
    "gen-mc-tests.py",
]
# paths whose contents are oracle-derived and must reproduce byte-identically
TRACKED = ["desk/test-data", "desk/tests", "desk/doc/tla-bnf.md"]


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


def run_generators() -> None:
    for g in GENERATORS:
        r = sh(["python3", str(REPO / "tools" / g)])
        tag = "ok  " if r.returncode == 0 else "FAIL"
        print(f"  {tag} {g}: {r.stdout.strip().splitlines()[-1] if r.stdout.strip() else ''}")
        if r.returncode != 0:
            print(r.stderr)


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
    run_generators()
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
