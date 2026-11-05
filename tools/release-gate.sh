#!/usr/bin/env bash
# RELEASE GATE (R1.9.3; tier-3 REPORT added by R3.3.2) — the real one.
#
# `scaffold-gate.sh` proves scaffold HYGIENE and says so in its own banner: pin,
# golden reproducibility, no Java/GUI, provenance, kelvin, a migration
# mechanism, bounded fixtures, a desk manifest, port-map/ledger coherence, and
# a well-formed ledger. It deliberately does NOT prove the port is done — it
# reports the owed count and passes anyway.
#
# This gate adds what a release additionally requires:
#
#   R1  ledger CLOSED           zero partial/absent/oracle-only (not just well-formed)
#   R2  tier 2 green            tier2.py --check, not only tier 1
#   R3  no stubs or TODOs       in port code (vendored upstream text exempted)
#   R4  refusals are documented BOTH ways: every `unsupported:` message in the
#                               desk is in compatibility.md's table, and every
#                               message that table lists exists in the desk
#   R5  upgrade / restart       one tagged state shape, a coercing on-load, and
#                               a test that resumes an in-flight job across a
#                               Gall reload
#   R6  reproducible artifacts  the oracle baseline regenerates byte-identically
#
# and one thing it deliberately does NOT gate:
#
#   T3  tier-3 performance      REPORTED, never asserted. R2.8.1a measured the
#                               run-to-run spread of the median workload at
#                               15.6% on a fresh boot -- over its own +/-15%
#                               bar -- so a threshold here would fail runs for
#                               being on a busy machine. `a flaky gate is one
#                               everyone learns to ignore` (R1.1.R3). The
#                               numbers are printed, and reading them is the
#                               point; promoting this to a clause needs a NEW
#                               MEASUREMENT, not a new opinion.
#
#   tools/release-gate.sh              the gates
#   tools/release-gate.sh --tier3      the gates, plus the tier-3 report (needs
#                                      a running ship; still never fails)
#
# Passes when the scaffold gate passes, every R-gate below passes, and on the
# ship  -test /=tla-lus=/tests ~  reports  ok=%.y  (which no shell can check —
# it is named as the remaining gate, exactly as the scaffold gate does).
set -uo pipefail

TIER3=0
for a in "$@"; do [ "$a" = "--tier3" ] && TIER3=1; done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESK="$REPO/desk"
FAIL=0
pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAIL=1; }

echo "===== scaffold hygiene ====="
if bash "$REPO/tools/scaffold-gate.sh" >/tmp/tla-scaffold.log 2>&1; then
  pass "scaffold-gate.sh: all gates"
else
  fail "scaffold-gate.sh failed"; sed -n '/FAIL/p' /tmp/tla-scaffold.log | head -6
fi

echo "===== release-only gates ====="

echo "== R1: parity ledger CLOSED =="
OWED=$(python3 "$REPO/tools/check-parity.py" 2>/dev/null \
        | sed -n 's/^still owed (partial\/absent\/oracle-only): //p')
if [ "${OWED:-x}" = "0" ]; then
  pass "ledger closed — 0 partial/absent/oracle-only"
else
  fail "ledger not closed — ${OWED:-unknown} row(s) still owed"
fi

echo "== R2: tier-2 differential green =="
if python3 "$REPO/tools/tier2.py" --check >/tmp/tla-tier2.log 2>&1; then
  pass "tier2.py --check — inventory, oracle and comparator shards reproduce"
else
  fail "tier-2 drift — see /tmp/tla-tier2.log"; tail -6 /tmp/tla-tier2.log
fi

echo "== R3: no stubs or TODOs in port code =="
# Vendored upstream text is exempt and must stay verbatim: lib/stdmods.hoon is
# the MIT StandardModules (whose own TLA+ carries TODOs), and default-agent,
# dbug and skeleton are stock Urbit libraries.
VENDORED='stdmods.hoon|default-agent.hoon|dbug.hoon|skeleton.hoon'
HITS=$(grep -rnE 'TODO|FIXME|XXX' "$DESK/lib" "$DESK/app" "$DESK/sur" 2>/dev/null \
        | grep -vE "/($VENDORED):" | wc -l)
if [ "$HITS" -eq 0 ]; then
  pass "no TODO/FIXME/XXX in port code (vendored text exempt)"
else
  fail "$HITS TODO/FIXME/XXX in port code"
  grep -rnE 'TODO|FIXME|XXX' "$DESK/lib" "$DESK/app" "$DESK/sur" 2>/dev/null \
    | grep -vE "/($VENDORED):" | head -5
fi

echo "== R4: every refusal is documented, both ways =="
if python3 - "$DESK" <<'PYEOF'
import glob, re, sys
desk = sys.argv[1]
compat = open(f"{desk}/doc/compatibility.md").read()
i = compat.index("## Typed-rejected / unsupported public options")
table = compat[i:]
src = "".join(open(f).read()
              for f in glob.glob(f"{desk}/lib/*.hoon") + glob.glob(f"{desk}/app/*.hoon"))
code = set(re.findall(r"'(unsupported: [^']*)'", src))
doc = set(re.findall(r"`(unsupported: [^`]*)`", table))
undocumented, stale = sorted(code - doc), sorted(doc - code)
for m in undocumented:
    print(f"    refusal in code, not in the table: {m}")
for m in stale:
    print(f"    refusal in the table, not in code: {m}")
sys.exit(1 if (undocumented or stale) else 0)
PYEOF
then
  pass "compatibility.md's refusal table matches the desk exactly"
else
  fail "refusal table and code disagree"
fi

echo "== R5: upgrade and restart =="
#  R4 (the user's no-migrations rule, 2026-10): ONE tagged state shape,
#  which on-load coerces (`;;`) and resets to empty when it no longer fits;
#  no version union, no conversion arms (scaffold gate 6 forbids them)
R5=1; WHY=""
grep -q '+\$  state-0' "$DESK/app/tla-lus.hoon" || { R5=0; WHY="no tagged state-0"; }
grep -q ';;(state-0'    "$DESK/app/tla-lus.hoon" || { R5=0; WHY="on-load does not coerce"; }
grep -q 'test-inflight-resume-across-reload' "$DESK/tests/app/tla-lus.hoon" \
  || { R5=0; WHY="no in-flight resume-across-reload test"; }
[ "$R5" -eq 1 ] && pass "one tagged state shape, coercing on-load, resume-across-reload test" \
  || fail "upgrade/restart: $WHY"

echo "== R6: reproducible artifacts =="
if bash "$DESK/test-data/oracle/regen.sh" --check >/tmp/tla-regen.log 2>&1; then
  pass "oracle baseline regenerates byte-identically"
else
  fail "oracle baseline drift — see /tmp/tla-regen.log"; tail -6 /tmp/tla-regen.log
fi

echo "===== tier 3: REPORT, not a gate ====="
# R2.8.1a's decision, kept here rather than in a comment nobody runs: the
# spread is wider than any bar worth setting, so this section prints numbers
# and never touches FAIL. It needs a running ship, so it runs only on request.
if [ "$TIER3" -eq 1 ]; then
  if python3 "$REPO/tools/tier3-report.py" >/tmp/tla-tier3.log 2>&1; then
    echo "  REPORT  tier-3 workloads (read, not gated):"
    sed -n '1,20p' /tmp/tla-tier3.log | sed 's/^/          /'
  else
    # nonzero here means the WORKLOAD SHARD failed -- a deterministic work
    # profile changed, which is an ordinary test failure, not a slow run.
    # It is still not this gate's clause; the shard is the suite's job.
    echo "  REPORT  tier-3 report could not run cleanly — see /tmp/tla-tier3.log"
    tail -4 /tmp/tla-tier3.log | sed 's/^/          /'
  fi
else
  echo "  REPORT  not run (pass --tier3; it needs a running ship)."
  echo "          Report-only. R2.8.1a measured 15.6% on a fresh boot (over"
  echo "          its +/-15% bar); R4.5.1 re-measured 4.5% warm, 3.0% fresh"
  echo "          boot, 3.4% across a rebuild; the user kept it report-only"
  echo "          for R4 (2026-11-05)."
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "RELEASE GATE: PASS"
  echo "  scaffold hygiene + ledger closed + tiers 1-2 green + no stubs"
  echo "  + refusals documented + upgrade/restart + reproducible artifacts."
  echo "  tier 3 is reported above, never gated (R2.8.1a)."
  echo "  remaining ship gate:  -test /=tla-lus=/tests ~   must report ok=%.y"
  echo "  then:                 tools/r3-acceptance.py --suite-log <captured>"
else
  echo "RELEASE GATE: FAIL"
fi
exit "$FAIL"
