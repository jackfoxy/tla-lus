#!/usr/bin/env bash
# Scaffold gate (was "release gate", relabeled in PORT-COMPLETION-PLAN-2
# unit 0): audit the %tla-lus desk for SCAFFOLD hygiene — not Java parity.
# It proves the pin, golden reproducibility, provenance, kelvin, migration,
# fixture sizes, and that the parity ledger is well-formed. It does NOT prove
# the toolchain is at parity, and it passes whatever the ledger's owed count
# is — it only reports it.
#
# The REAL release gate is `tools/release-gate.sh` (R1.9.3). It runs this
# script and then adds what a release requires: the ledger CLOSED (zero
# partial/absent/oracle-only), tier 2 as well as tier 1, no stubs or TODOs in
# port code, every `unsupported:` refusal documented in both directions,
# upgrade/restart, and reproducible oracle artifacts.
#
#   tools/scaffold-gate.sh
#
# Passes when every gate below is PASS and, on the ship,
#   -test /=tla-lus=/tests ~   ==>  ok=%.y
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESK="$REPO/desk"
TLA_REPO="${TLA_REPO:-/mnt/mars/gitrepos/tlaplus}"
PIN="4ba7d8811289fb8e95dac4d5e554c05216ba3100"
DESK_STATE="%0"           # the agent state tag (app/tla-lus.hoon)
FAIL=0
pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAIL=1; }

echo "== gate 1: pinned oracle =="
HEAD="$(git -C "$TLA_REPO" rev-parse HEAD 2>/dev/null || echo none)"
[ "$HEAD" = "$PIN" ] && pass "tlaplus at pinned $PIN" || fail "tlaplus is $HEAD, not $PIN"

echo "== gate 2: differential reproducibility =="
if python3 "$REPO/tools/validate.py" --check >/tmp/tla-validate.log 2>&1; then
  pass "all goldens reproduce byte-identically from the pin"
else
  fail "golden drift — see /tmp/tla-validate.log"; tail -8 /tmp/tla-validate.log
fi

echo "== gate 3: no GUI / tla2tex / Java code or deps =="
# only vendored StandardModule *text* (lib/stdmods.hoon) and docs may
# mention these names; no Java sources or build deps may live in the desk
if find "$DESK" -name '*.java' -o -name '*.jar' -o -name '*.class' | grep -q .; then
  fail "Java artifacts present in desk"
else
  pass "no .java/.jar/.class in desk"
fi
CODE_HITS=$(grep -rilE 'tla2tex|import java|javax\.' "$DESK" --include='*.hoon' 2>/dev/null \
  | grep -vE 'stdmods\.hoon$' | wc -l)
[ "$CODE_HITS" -eq 0 ] && pass "no GUI/tla2tex references in Hoon code (outside vendored module text)" \
  || fail "$CODE_HITS Hoon file(s) reference GUI/tla2tex"

echo "== gate 4: license / provenance =="
grep -qiE 'MIT' "$DESK/lib/stdmods.hoon" && pass "StandardModules carry MIT provenance" \
  || fail "stdmods.hoon missing MIT provenance header"
grep -qiE 'MIT' "$DESK/doc/compatibility.md" "$DESK/../README.md" 2>/dev/null \
  && pass "license noted in docs" || fail "license not noted in docs"

echo "== gate 5: kelvin compatibility =="
[ -f "$DESK/sys.kelvin" ] && pass "sys.kelvin present: $(head -1 "$DESK/sys.kelvin")" \
  || fail "no sys.kelvin"

echo "== gate 6: state loading =="
# ONE state shape and no migrations (the project is in development): on-load
# COERCES the stored noun (`;;`) to that shape instead of requiring it to nest,
# and resets to empty if it does not fit. No version union, no conversion arms
MIGOK=1
MIGWHY=""
grep -q ';;(state-0 q.old-vase)' "$DESK/app/tla-lus.hoon" \
  || { MIGOK=0; MIGWHY="on-load does not coerce the stored noun to state-0"; }
grep -q '=|  state-0' "$DESK/app/tla-lus.hoon" \
  || { MIGOK=0; MIGWHY="the agent does not run state-0"; }
! grep -qE 'versioned-state|state-[1-9]' "$DESK/app/tla-lus.hoon" \
  || { MIGOK=0; MIGWHY="a migration (versioned state) is present"; }
[ "$MIGOK" -eq 1 ] && pass "on-load coerces the one state shape; no migrations" \
  || fail "state loading: $MIGWHY"

echo "== gate 7: no synchronous Clay read in a stage =="
# the pure pipeline may not touch Clay: every external read is a
# read-request the agent performs (unit 10.1). Only app/ (and the
# caller-side generators) may scry.
# (comment lines are not code: a `::` line may name the rune it forbids)
sync_reads() {
  grep -rn '\.\^' "$DESK/lib" "$DESK/sur" --include='*.hoon' 2>/dev/null \
    | grep -vE ':[0-9]+: *::'
}
SYNC_HITS=$(sync_reads | wc -l)
[ "$SYNC_HITS" -eq 0 ] && pass "no scry in desk/lib or desk/sur (all source access is async)" \
  || { fail "$SYNC_HITS synchronous read(s) in a library:"; sync_reads | sed 's/^/    /'; }

echo "== gate 8: fixture size bound =="
BIG=$(find "$DESK/test-data" -type f -size +100k 2>/dev/null | wc -l)
[ "$BIG" -eq 0 ] && pass "no fixture over 100 KB" || { fail "$BIG oversized fixture(s):"; \
  find "$DESK/test-data" -type f -size +100k -printf '    %s %p\n'; }

echo "== gate 9: desk manifest =="
[ -f "$DESK/desk.bill" ] && pass "desk.bill present" || fail "no desk.bill"

echo "== gate 10: port-map / ledger coherence =="
# R1.9.0: the two documents are orthogonal projections and neither can be
# generated from the other, so what is enforced is the facts they SHARE —
# owner files that exist, one pin, units that resolve, quoted tallies.
if python3 "$REPO/tools/check-portmap.py" >/tmp/tla-portmap.log 2>&1; then
  pass "port-map and the ledger are coherent with each other and the tree"
else
  fail "port-map/ledger drift — see /tmp/tla-portmap.log"; tail -8 /tmp/tla-portmap.log
fi

echo "== gate 11: parity ledger well-formed =="
if python3 "$REPO/tools/check-parity.py" --check >/tmp/tla-parity.log 2>&1; then
  LEDGER=$(grep -m1 'parity ledger:' /tmp/tla-parity.log)
  OWED=$(grep -m1 'still owed' /tmp/tla-parity.log)
  pass "$LEDGER — no unclassified rows"
  echo "        $OWED (scaffold gate; release-gate.sh requires 0)"
else
  fail "parity ledger malformed — see /tmp/tla-parity.log"; tail -6 /tmp/tla-parity.log
fi

echo "== gate 12: every desk file has a mark =="
# Clay validates EVERY file of a commit through the mark its extension names;
# one file with no mark (`%no-cast-between %mime %py` / `%jsonl`) fails the
# whole |commit. The desk is deployed by copying desk/ wholesale (R4.0e), so
# every file under it must name a mark in desk/mar, or one `|new-desk`
# supplies (hoon, noun).
MARKS=$( { ls "$DESK/mar" | sed -n 's/\.hoon$//p'; echo hoon; echo noun; } | sort -u)
UNMARKED=$(find "$DESK" -type f | while read -r f; do
  b=$(basename "$f")
  case "$b" in *.*) e="${b##*.}" ;; *) e="" ;; esac
  printf '%s\n' "$MARKS" | grep -qx -- "$e" || echo "$f"
done)
[ -z "$UNMARKED" ] && pass "every file under desk/ names a mark" \
  || { fail "$(printf '%s\n' "$UNMARKED" | wc -l) file(s) with no mark:"; \
       printf '%s\n' "$UNMARKED" | sed "s|$DESK/|    |" | head -20; }

echo "== gate 13: Examples runner logic =="
# R4.0d/e: the stop that works (max-time = wall), the census classes, the
# timed-out skip list. Offline -- no ship
if python3 "$REPO/tools/test-examples.py" >/tmp/tla-examples.log 2>&1; then
  pass "$(tail -1 /tmp/tla-examples.log)"
else
  fail "runner checks failed — see /tmp/tla-examples.log"; grep FAIL /tmp/tla-examples.log | head
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "SCAFFOLD GATE: PASS"
  echo "  this proves scaffold hygiene, NOT Java parity."
  echo "  compatibility matrix tag:"
  echo "    oracle pin  : tlaplus@${PIN:0:9}"
  echo "    desk state  : $DESK_STATE"
  echo "    evidence    : desk/doc/evidence-counts.md (generated)"
  echo "    parity      : desk/doc/parity-manifest.md ($(grep -m1 'still owed' /tmp/tla-parity.log 2>/dev/null || echo 'see check-parity.py'))"
  echo "  remaining ship gate:  -test /=tla-lus=/tests ~   must report ok=%.y"
  echo "  for release:          tools/release-gate.sh"
else
  echo "SCAFFOLD GATE: FAIL"
fi
exit "$FAIL"
