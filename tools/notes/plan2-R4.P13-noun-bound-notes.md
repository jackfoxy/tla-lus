# R4.P13: `max-noun-bytes` 16 → 256 MB (2026-10-12)

**Status: DONE.** Approved at the R4.P close (plan r14, decision 2).

- `lib/job.hoon` `max-noun-bytes` 16.000.000 → 256.000.000. The bound now
  limits only loom growth (R4.P2 removed the per-slice jam, R4.P8 amortized
  the measurement with `+noun-due`).
- `users-guide.md` §Runtime envelope: about 8–10 M small states per check;
  measuring cost; large states reach the loom first.

## Measured: the cost of one measurement near the bound

Scratch dojo probe, a `(map @ [@ @ud])` of `sham` keys, `~>(%bout (met 3
(jam m)))`, load about 1:

| entries | jam size | jam time |
|---|---|---|
| 100,000 | 2.7 MB | 0.27 s |
| 1,000,000 | 28.3 MB | 4.5 s |

About 0.1–0.16 s per MB, slightly superlinear. At the 256 MB bound one
measuring turn would last about 45–60 s. Measurements come at 16
checkpoints per doubling, so this is roughly 10% overhead at that scale
plus long single turns: acceptable for a multi-hour run, documented. If it
bites (R4.3), the fix is to extrapolate bytes/state from the last
measurement and skip checkpoints far below the cap.

GameOfLife's resident cost (R4.P8: about 3.6 KB/state) puts its loom limit
near 2 M states, below this bound; small states (grid, about 0.33 KB/state
resident) reach the bound first.

job 130, app 44 green.
