# R4.0e — first Examples census: notes (2026-10-08/09)

**Status: CANCELLED by the user at 73 / 158 models** ("we have learned a lot
from it"). The partial census is frozen as
`desk/test-data/blackbox/census.txt` (73 rows, alphabetical by path,
`Bakery` … `SpanTreeRandom`). The `--report` output is in
`plan2-R4.0e-census-report.txt`. The runner is `tools/examples.py --run
--wall 900` (`max-time` = wall, RSS/time watchdog, orphan cancel). See
`plan2-R4.0d-runner-notes.md`.

## Classes (73 rows)

| class | n |
|---|---|
| agree | 3 (CigaretteSmokers, DieHard, MissionariesAndCannibals) |
| wrong answer | 2 (Moving_Cat_Puzzle CatEvenBoxes/CatOddBoxes: liveness failure, expected success) |
| too slow (wall 900 s / `%limited %time` / orphan) | 7 (CoffeeCan 100/1000/3000Beans, GameOfLife, ElevatorSafety Medium/Large, Paxos) |
| absent (submit rejected) | 4 (every `.toolbox/…/MC.cfg`: CarTalkPuzzle ×2, N-Queens ×2) |
| refused | 57 |

## Refusals grouped by cause (each group is a candidate R4.2 row)

| n | message | reading |
|---|---|---|
| 28 (+1 INIT) | `no definition for INVARIANT <name>` | **kernel bug, diagnosed**: `lib/job.hoon` `+config-run` checks targets with `body-of-def:check tree` (ROOT module only; :1370/:1372/:1450/:1482), while every other path resolves through the semantic `defs` (EXTENDS included). An L12 entry-point divergence. Likely one fix unblocks about 29 rows. |
| 7 | `TLC cannot handle the temporal formula <loc>` | temporal-formula classes the tableau refuses; measure each against the pin |
| 5 | `Evaluating assumption … failed` (EC 2105) | 4× `unsupported StandardModule operator: Naturals!Nat/0` in an ASSUME (Chameneos, Disruptor ×3: `x \in Nat`), 1× FastPaxos (theorem/assumption form) |
| 3 | `undefined identifier: $OpArg` | an operator-argument (higher-order) path |
| 2 | `no INIT in config` | constant-only models: R4.2k (SimpleMath class) |
| 2 + 1 | `variable is unassigned in the current state: msgs` / `maxBal` | Init-assignment form not recognized (HourClock2 from the smoke test is the same class) |
| 2 | `internal: unexpected graph outcome` | SpanTreeTest4Nodes and one more: internal error, so a bug |
| 1 each | VIEW+PROPERTY (R4.2e); `undefined operator: Rational`; cfg identifier `Seq` not in spec; `internal: module generation failed`; `undefined operator: pState`; set > 1,000,000 elements; ALIAS+PROPERTY (braf, from R4.0d) | individual rows |

## Ship-operation findings (also in the R4.0d notes)

- A job slice cannot be cancelled while it runs. behn re-fires the failed
  slice ahead of a cancel on any other driver; `max-time` = wall is the stop
  that works.
- An interrupted slice can ORPHAN its job (no timer left). The runner
  detects this (serf idle + `running`) and cancels.
- Killing a conn client with a request outstanding CRASHES vere's king
  (`conn: moor bail -32 broken pipe` → `loom: external fault`). That was the
  fourth crash, at 07:55 on 10-09. Never kill the runner mid-request; let a
  model finish.
- After a crash, `|commit` did not see a file deleted from the mount
  (`gen/tla-lus/probe.hoon`); `|rm /=tla-lus=/gen/tla-lus/probe/hoon`
  removed it.
