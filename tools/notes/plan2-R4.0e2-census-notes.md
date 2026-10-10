# R4.0e2 — census re-run after R4.2l (2026-10-09)

**Status: DONE.** 151 rows in `desk/test-data/blackbox/census-r2.txt`:
158 models minus the 7 skipped as timed out, plus MCChangRoberts, recorded
by hand as `runaway`. The `--report` output is in
`plan2-R4.0e2-census-report.txt`. The runner was `tools/examples.py --run
--wall 900` (then `--rss-cap 2500` after the crash below).

It ran from 11:28 to about 15:40. That includes one ship crash and its
recovery (2 min), seven models at the wall cap (about 16 min each), and one
interrupt-recovered runaway.

## Classes

| class | n |
|---|---|
| agree | **18** (R4.0e: 3) |
| wrong answer | 2 (Moving_Cat_Puzzle ×2: liveness failure, expected success) |
| too slow (`limited time`) | 4 (ACP_SB_TLC, bosco, EWD840_anim, PaxosCommit) |
| crash-orphan | 3 (HourClock2, Barrier, MC_sums_even) |
| runaway | 1 (MCChangRoberts) |
| absent (submit rejected) | 7 (every `.toolbox/…/MC.cfg`) |
| refused | 116 |

Agreeing:
- CigaretteSmokers, DieHard, MissionariesAndCannibals, Paxos/MCConsensus
- AsynchInterface, Channel, MCInnerFIFO, HourClock, ABCorrectness
- ACP_NB_WRONG_TLC, Voucher{Cancel,LifeCycle,Redeem,Transfer}
- glowingRaccoon/clean, nbacc_ray97, TCommit, TwoPhase

**R4.2l worked:** all 28 `no definition for INVARIANT` refusals are gone.
But on the 66 models both censuses ran, 56 are still refused, now for the
NEXT reason. They were masked, not fixed.

## Refusals by cause (r8's R4.2 sizing)

| n | cause | row |
|---|---|---|
| 25 | `TLC cannot handle the temporal formula <loc>` | R4.2n (now the largest) |
| 18 | `unsupported StandardModule operator: Naturals!Nat/0` (12 in an ASSUME, 4 elsewhere) + `Integers!Int/0` ×1 + `Sequences!Seq/1` ×1 | R4.2m |
| ~23 | `undefined identifier: <X>` / `undefined operator: <X>` (Acceptor ×4, CharacterSet, MaxBallot, ClientCfg, Procs ×2 each; Jug, Goal, Value, CarsRight, R, nbrs, Peers, key, And, pState) | **new R4.2v**: likely a constant or definition of an EXTENDed/INSTANCEd module not reaching the evaluator's environment (the R4.2l family); measure first |
| 10 | `unsupported builtin operator: $UnboundedChoose` | **new R4.2u**: unbounded `CHOOSE x : P` |
| 10 | `internal: unexpected graph outcome` | R4.2q (bug by definition) |
| 7 | `no INIT in config` | R4.2k (constant-only / SPECIFICATION-less models) |
| 6 | `$OpArg` undefined identifier/operator | R4.2o |
| 4 | `TLCGet` in ASSUME: config key ×2, `-Dtlc2.tool.impl.Tool.cdot` ×2 | **new R4.2w**: TLCGet keys |
| 2+1 | VIEW / ALIAS with a temporal PROPERTY | R4.2e / R4.2i |
| 2 | set > 1,000,000 elements | R4.2i (maxSetSize parity; measure) |
| 2 + 1 + 1 + 1 | `STRING`, `$Label`, `Seq(…)` enumeration, `Rational` | R4.2b / R4.2i |
| 1 each | `module generation failed`; `Evaluating assumption module MCVoting`; a theorem/assumption not evaluable; cfg identifier `Seq` not in spec | R4.2q / R4.2i |

## The three crash-orphans (new row R4.2y)

HourClock2, Barrier and MC_sums_even each sat `running` with an idle serf
until the wall cap. The pane shows an AGENT CRASH:

```
error in %tla-lus  %arvo-response
! /lib/temporal/hoon:<[912 62].[912 64]>   tlc-live-wrong-formula-format
… /lib/job/hoon (+do-config)
```

`lib/temporal` reports tlc2's "wrong formula format" as a Hoon crash. The
job kernel does not `mule` a step. Gall rolls the agent back, the behn
wake is consumed, and the job is orphaned. Fix:
1. `mule` every step in the agent (or in `+step`) and finish the job
   `[%failed <trace>]` on a crash. Any crash then costs 10 s, not 900.
2. Make the temporal format error a typed refusal with tlc2's text.

The row says `parse` because `stage` is written at slice end.

## Ship crash at 14:05 (unplanned)

MCChangRoberts (tlc2: 1 s, 137 distinct) grew about 80 MB/s, reaching
4 GB in 50 s. The watchdog's SIGINT crashed the SERF in signal recovery:
`u3m_soft` → `_cm_signal_recover` → `_cm_stack_unwind` → `u3m_love` →
fault. The king shut down cleanly. Recovery took about 2 minutes:
- the snapshot was valid (event 0x1d14; a copy is `image-1d14.bin` in the
  evidence dir);
- boot-time cancel race; the row was recorded by hand;
- the model was added to `timed-out.json`;
- resumed with `--rss-cap 2500`.

Earlier SIGINTs at 6 GB recovered cleanly, so a fast-growing (probably
deep-recursion) runaway is the dangerous case. A runaway on a 137-state
model is an engine bug, so R4.P0b gets it first.

## `timed-out.json` now holds 15

- 7 from R4.0e
- MCChangRoberts (runaway)
- 4 slow: ACP_SB_TLC, bosco, EWD840_anim, PaxosCommit
- 3 crash-orphans, NOT slow but skipped to save 16 min each until R4.2y
