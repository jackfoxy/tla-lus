#!/bin/bash
# R4.5.3: the Examples runner pass r4-acceptance.py reads (clauses 2, 3, 6c, 7a),
# on a live ship (tla-zod, %tla-ex staged by `tools/examples.py --stage`).
# Long: roughly a day. Each census is append-only JSON lines, so a re-run of
# this script resumes where it stopped.
#
#   tools/r4-examples-run.sh OUTDIR
#   tools/r4-acceptance.py --suite-log SUITE --dojo-log DOJO \
#     --examples-census OUTDIR/{small,timed-out,hour,large,innerserial}.txt
#
# The passes, as R4 measured them (plan r16 decision 2, r3 decision 1):
#   small       the 127 small models at a 900 s wall (the runner skips the
#               rows in timed-out.json)
#   timed-out   the timed-out small rows at 900 s, except MCChangRoberts
#               (a known runaway, listed in r4-fallback.json)
#   hour        the 11 rows that need up to an hour, at 3,600 s
#   large       the 31 large models' smoke run (1,000 states) at 900 s
#   innerserial MCInnerSerial at its per-model wall (about 63 minutes)
set -u
OUT=${1:?usage: tools/r4-examples-run.sh OUTDIR}
mkdir -p "$OUT"
cd "$(dirname "$0")/.."
LOG="$OUT/run.log"
ex() { python3 -B tools/examples.py --run "$@" >> "$LOG" 2>&1; }

echo "small $(date -Is)" >> "$LOG"
ex --size small --wall 900 --census "$OUT/small.txt"
echo "timed-out $(date -Is)" >> "$LOG"
for o in GameOfLife/GameOfLife.cfg SimplifiedFastPaxos/Paxos.cfg btree/btree.cfg; do
  ex --include-timed-out --wall 900 --only "$o" --census "$OUT/timed-out.txt"
done
echo "hour $(date -Is)" >> "$LOG"
for o in PaxosHowToWinATuringAward/MCPaxosTiny PaxosHowToWinATuringAward/MCVoting \
         bcastByz/bcastByz.cfg SimplifiedFastPaxos/Paxos.cfg allocator/AllocatorImplementation \
         CoffeeCan/CoffeeCan1000Beans Disruptor/Disruptor_MPMC_liveliness GameOfLife/GameOfLife.cfg \
         MultiCarElevator/ElevatorLivenessMedium ewd426/TokenRing nbacg_guer01/nbacg_guer01; do
  ex --include-timed-out --wall 3600 --only "$o" --census "$OUT/hour.txt"
done
echo "large $(date -Is)" >> "$LOG"
ex --size large --include-timed-out --budget 1000 --wall 900 --census "$OUT/large.txt"
echo "innerserial $(date -Is)" >> "$LOG"
ex --size large --include-timed-out --budget 1000 --wall 3800 \
   --only AdvancedExamples/MCInnerSerial --census "$OUT/innerserial.txt"
echo "done $(date -Is)" >> "$LOG"
