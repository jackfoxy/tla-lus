# R4.P: re-run of `timed-out.json` (2026-10-12)

Approved at the R4.P close (plan r14, decision 5). The run came after
R4.P13, R4.P5c, R4.P12 and R4.P11. Each model ran alone (`--only`,
`--include-timed-out`, `--wall 900`). Rows are in
`desk/test-data/blackbox/census-r4p-timedout.txt`.

| model | before (R4.0e/e2) | now | disposition |
|---|---|---|---|
| ACP_SB_TLC | > 900 s | **success, 453 s; 54,944 / 218,352 / depth 21 = manifest** | removed |
| CoffeeCan1000Beans | timeout | typed error in 10 s (`set with too many elements`) | removed; R4.2i (maxSetSize / lazy record set) |
| CoffeeCan3000Beans | cancelled | typed error in 10 s (same) | removed; R4.2i |
| EWD840_anim | > 900 s | typed refusal in 157 s (`ALIAS in simulation mode`) | removed; R4.2 residue (ALIAS) |
| GameOfLife | 0 states | limited: all 65,536 initial states, 1,280 expanded | kept (evaluator speed, about 0.45 s/state) |
| ElevatorSafetyLarge | timeout | limited: 1,536 distinct of 390,625 generated, depth 1 | kept |
| ElevatorSafetyMedium | timeout | limited: 12,800 distinct of 19,683 generated, depth 1 | kept |
| SimplifiedFastPaxos/Paxos | timeout | limited: 901 of 1,207 distinct, depth 17 | kept (close) |
| bosco | > 900 s | limited: 2,528 distinct, depth 3 | kept |
| PaxosCommit | > 900 s | limited: **0 states at 900 s** (stuck before the first state) | kept; look first in R4.3 |
| MCChangRoberts | runaway | **crashed the ship again** (`behn: bail: %meme` in a slice) | kept; R4.2q |

`timed-out.json`: 11 → 7 entries. Each kept entry carries `rerun_r4p`.
`tools/test-examples.py` passes.

**Unplanned:** MCChangRoberts exhausted the loom inside one job slice
before the 2,500 MB RSS watchdog fired. Vere exited and the four models
after it could not connect. Recovery: reboot with `--loom 33` and a
boot-time cancel. The cancel was queued on `conn.sock` 2.2 s after launch,
ahead of behn. Then those four models were re-run. No data was lost.
Lesson: the RSS watchdog cannot stop a runaway that grows within one
event. MCChangRoberts stays skipped until R4.2q bounds it.
