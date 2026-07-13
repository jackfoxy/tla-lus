#!/usr/bin/env bash
# Regenerate (default) or verify (--check) golden oracle outputs for the
# %tla-lus unit-0 baseline cases. Oracle: tla2tools.jar built from the pinned
# tlaplus commit; pin, invocation forms, and normalization rules are
# documented in desk/doc/port-map.md and must stay in sync with this script.
set -euo pipefail

TLA_REPO="${TLA_REPO:-/mnt/mars/gitrepos/tlaplus}"
TOOLS="$TLA_REPO/tlatools/org.lamport.tlatools"
JAR="$TOOLS/dist/tla2tools.jar"
PIN="4ba7d8811289fb8e95dac4d5e554c05216ba3100"
HERE="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-regen}"
FAIL=0

if [ ! -f "$JAR" ]; then
  echo "missing $JAR — build it: (cd $TOOLS && ant -f customBuild.xml info compile compile-test dist)" >&2
  exit 1
fi
ACTUAL="$(git -C "$TLA_REPO" rev-parse HEAD)"
if [ "$ACTUAL" != "$PIN" ]; then
  echo "tlaplus checkout is $ACTUAL, not pinned $PIN — refusing to generate goldens" >&2
  exit 1
fi

# Normalization rules (port-map.md section 3). $1 = per-case work dir.
normalize() {
  sed -E \
    -e 's/\r$//' \
    -e "s#$1#<WORK>#g" \
    -e "s#$TLA_REPO#<REPO>#g" \
    -e 's/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/<DATETIME>/g' \
    -e 's#[^ ]*/tlc-[0-9]+#<TLCTMP>#g' \
    -e 's/TLC2 Version [0-9][0-9.]* \(rev: ([0-9a-f]+)\)/TLC2 Version <BUILD> (rev: \1)/' \
    -e 's/Finished in [0-9]+(min *)?[0-9]*s at/Finished in <D> at/' \
    -e 's/ in [0-9]+(min *)?[0-9]*s\.?$/ in <D>./' \
    -e 's/\(([0-9.,]+) s\/min\)/(<RATE>)/g' \
    -e 's/ and [0-9]+ cores/ and <N> cores/' \
    -e 's/with [0-9]+MB heap and [0-9]+MB offheap/with <N>MB heap and <N>MB offheap/' \
    -e 's/\[pid: [0-9]+\]/[pid: <N>]/' \
    -e 's/seed -?[0-9]{6,}/seed <SEED>/' \
    -e 's/_TTrace_[0-9]+/_TTrace_<T>/g' \
    -e 's#states/[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9.\-]+#<METADIR>#g' \
    -e 's/[ \t]+$//'
}

# finish <case> <normalized-file>
finish() {
  local golden="$HERE/golden/$1.txt"
  if [ "$MODE" = "--check" ]; then
    if diff -u "$golden" "$2" >/dev/null 2>&1; then
      echo "ok   $1"
    else
      echo "FAIL $1"; diff -u "$golden" "$2" | head -40 || true; FAIL=1
    fi
  else
    cp "$2" "$golden"; echo "wrote $1"
  fi
}

# run <case> [append-file] -- <cmd...>   (cmd runs inside a temp copy)
run() {
  local name="$1"; shift
  local append=""
  if [ "$1" != "--" ]; then append="$1"; shift; fi
  shift  # the --
  local work; work="$(mktemp -d)"
  cp "$HERE/cases/$name/"* "$work/"
  rm -f "$work/SOURCE"
  local code=0
  ( cd "$work" && "$@" ) >"$work/.out" 2>&1 || code=$?
  {
    normalize "$work" <"$work/.out"
    echo "exit-code: $code"
    if [ -n "$append" ]; then
      echo "--- rewritten: $append ---"
      normalize "$work" <"$work/$append"
    fi
  } >"$work/.norm"
  finish "$name" "$work/.norm"
  rm -rf "$work"
}

SANY=(java -cp "$JAR" tla2sany.SANY -error-codes)
TLC=(java -cp "$JAR" tlc2.TLC -workers 1 -fp 0)

run lex-bad-string    -- "${SANY[@]}" LexBadString.tla
run syntax-accept     -- "${SANY[@]}" SyntaxAccept.tla
run syntax-reject     -- "${SANY[@]}" SyntaxReject.tla
run semantic-undef    -- "${SANY[@]}" SemanticUndef.tla
run semantic-instance -- "${SANY[@]}" SemanticInstance.tla
run level-prime       -- "${SANY[@]}" LevelPrime.tla
run lint-record-clash -- "${SANY[@]}" LintRecordClash.tla
run pcal-evenodd EvenOdd.tla -- java -cp "$JAR" pcal.trans -nocfg EvenOdd.tla
run cfg-bad           -- "${TLC[@]}" -config CfgBad.cfg CfgBad.tla
run values-eval       -- "${TLC[@]}" -config ValuesEval.cfg ValuesEval.tla
run safety-diehard    -- "${TLC[@]}" -config DieHard.cfg DieHard.tla
run deadlock-counter  -- "${TLC[@]}" -config DeadlockCounter.cfg DeadlockCounter.tla
run liveness-lasso    -- "${TLC[@]}" -config LivenessLasso.cfg LivenessLasso.tla
run simulate-seeded   -- "${TLC[@]}" -config DeadlockCounter.cfg \
                         -simulate num=3 -depth 8 -seed 1 -aril 0 -deadlock \
                         DeadlockCounter.tla

if [ "$MODE" = "--check" ] && [ "$FAIL" = 1 ]; then exit 1; fi
echo "done ($MODE)"
