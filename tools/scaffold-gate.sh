#!/usr/bin/env bash
# Scaffold gate (was "release gate", relabeled in PORT-COMPLETION-PLAN-2
# unit 0): audit the %tla-lus desk for SCAFFOLD hygiene — not Java parity.
# It proves the pin, golden reproducibility, provenance, kelvin, migration,
# fixture sizes, and that the parity ledger is well-formed. It does NOT prove
# the toolchain is at parity: the ledger still has `partial`/`absent`/
# `oracle-only` rows (see `check-parity.py`). The real release gate (unit 12)
# additionally requires the ledger to be closed to terminal statuses.
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
DESK_STATE="%3"           # agent state version (app/tla-lus.hoon)
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

echo "== gate 6: state migration =="
# R1.8.8: this gate used to require the literal chain jobs-0-to-1 / 1-to-2 /
# 2-to-3 in lib/migrate. R1.5.12b DELETED that chain on purpose — nothing has
# been released, so the pre-%3 versions were collapsed rather than carried —
# and the gate was not updated with it, so it had been failing silently since
# 2026-08-17. What the design actually guarantees is the MECHANISM, so that is
# what is checked: a version-tagged state union, an on-load that coerces the
# stored noun (`;;`) instead of requiring it to nest, a `?-` dispatch on the
# version tag, and a state tag matching DESK_STATE.
MIGOK=1
MIGWHY=""
grep -q '+\$  versioned-state' "$DESK/app/tla-lus.hoon" \
  || { MIGOK=0; MIGWHY="no versioned-state union"; }
grep -q ';;(versioned-state' "$DESK/app/tla-lus.hoon" \
  || { MIGOK=0; MIGWHY="on-load does not coerce the stored noun"; }
grep -q '?-  -.old' "$DESK/app/tla-lus.hoon" \
  || { MIGOK=0; MIGWHY="on-load has no version dispatch"; }
grep -q "^+\$  state-${DESK_STATE#%}  \[${DESK_STATE} " "$DESK/app/tla-lus.hoon" \
  || { MIGOK=0; MIGWHY="state mold is not ${DESK_STATE}"; }
[ "$MIGOK" -eq 1 ] && pass "on-load coerces + dispatches a version-tagged state ($DESK_STATE)" \
  || fail "state migration mechanism: $MIGWHY"

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

echo "== gate 10: parity ledger well-formed =="
if python3 "$REPO/tools/check-parity.py" --check >/tmp/tla-parity.log 2>&1; then
  LEDGER=$(grep -m1 'parity ledger:' /tmp/tla-parity.log)
  OWED=$(grep -m1 'still owed' /tmp/tla-parity.log)
  pass "$LEDGER — no unclassified rows"
  echo "        $OWED (scaffold gate; the real release gate requires 0)"
else
  fail "parity ledger malformed — see /tmp/tla-parity.log"; tail -6 /tmp/tla-parity.log
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
else
  echo "SCAFFOLD GATE: FAIL"
fi
exit "$FAIL"
