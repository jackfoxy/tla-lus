#!/usr/bin/env bash
# Release gate (unit 16): audit the %tla-lus desk for release. Runs the
# differential reproducibility check and a set of provenance/hygiene gates,
# then prints the compatibility-matrix tag. The Hoon test suite runs on the
# fake ship and is checked separately (see below).
#
#   tools/release-gate.sh
#
# Done when every gate below is PASS and, on the ship,
#   -test /=tla-lus=/tests ~   ==>  ok=%.y
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESK="$REPO/desk"
TLA_REPO="${TLA_REPO:-/mnt/mars/gitrepos/tlaplus}"
PIN="4ba7d8811289fb8e95dac4d5e554c05216ba3100"
DESK_STATE="%1"           # agent state version (app/tla-lus.hoon)
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
# only vendored StandardModule *text* (lib/tla/stdmods.hoon) and docs may
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
grep -qiE 'MIT' "$DESK/lib/tla/stdmods.hoon" && pass "StandardModules carry MIT provenance" \
  || fail "stdmods.hoon missing MIT provenance header"
grep -qiE 'MIT' "$DESK/doc/compatibility.md" "$DESK/../README.md" 2>/dev/null \
  && pass "license noted in docs" || fail "license not noted in docs"

echo "== gate 5: kelvin compatibility =="
[ -f "$DESK/sys.kelvin" ] && pass "sys.kelvin present: $(head -1 "$DESK/sys.kelvin")" \
  || fail "no sys.kelvin"

echo "== gate 6: state migration =="
grep -q 'jobs-0-to-1' "$DESK/app/tla-lus.hoon" \
  && pass "on-load migrates %0 -> %1 (lib/tla/migrate)" || fail "no %0->%1 migration in on-load"

echo "== gate 7: fixture size bound =="
BIG=$(find "$DESK/test-data" -type f -size +100k 2>/dev/null | wc -l)
[ "$BIG" -eq 0 ] && pass "no fixture over 100 KB" || { fail "$BIG oversized fixture(s):"; \
  find "$DESK/test-data" -type f -size +100k -printf '    %s %p\n'; }

echo "== gate 8: desk manifest =="
[ -f "$DESK/desk.bill" ] && pass "desk.bill present" || fail "no desk.bill"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "RELEASE GATE: PASS"
  echo "  compatibility matrix tag:"
  echo "    oracle pin  : tlaplus@${PIN:0:9}"
  echo "    desk state  : $DESK_STATE"
  echo "  remaining ship gate:  -test /=tla-lus=/tests ~   must report ok=%.y"
else
  echo "RELEASE GATE: FAIL"
fi
exit "$FAIL"
