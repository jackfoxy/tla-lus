# R4.5.2 — `tools/r4-acceptance.py` (2026-11-05)

```text
Sub-unit: R4.5.2 (plan r16): compute R4's acceptance sentence, clause by
          clause. r1-/r3-acceptance.py are not touched.
```

## The script

`tools/r4-acceptance.py --suite-log SUITE --examples-census C1 [C2 ...]
--dojo-log DOJO [--tier3-log T3] [--skip-gate]`. Each clause is computed
from a file; a missing input FAILS its clause.

| clause | computed from |
|---|---|
| 1 parse | `desk/test-data/blackbox/parse-census.txt` (now the R4.5.1 engine's census, 373/373) against `tier2/examples/sany` |
| 2 small (127) | the runner census against the PIN (`tier2/examples/pin-vs-manifest.txt`): verdict, distinct and depth, and generated for a success (the generated count at a violation is the harness's recorded normalization); every other row must be data in `r4-fallback.json` |
| 3 large (31) | `%limited %states` at the budget, or a completed run that meets the pin's counts (or, where the pin only smoke-ran, the manifest's) |
| 4 ledger | `check-parity.py --check` |
| 5 tier 3 | REPORTED (whether it gates is a user decision) |
| 6 gates | `release-gate.sh`; the user's suite log: `ok=%.y`, 0 FAILED, and every declared `++  test-` arm under `desk/tests` present as OK; the user's runner census covers every model |
| 7 black box | `coverage.md`: selected 158 = the work list, each reports its MANIFEST outcome (counts where recorded and exhaustive), clause 2's exceptions; the 44 failure arms OK in the suite log and the 7 exclusions with reasons; a dojo-generator log with a successful run |
| 8 Unicode | `parse-census-unicode.txt`, `unicode-identity-census.txt` against `tier2/examples/sany-unicode` |

`desk/test-data/blackbox/r4-fallback.json` makes the recorded exceptions
data: the 23 time-bound rows and MCChangRoberts (plan r16 decision 2 A),
the 2 approved refusals with their ledger rows, and one order-dependent
violation count (below).

## Dry run on the evidence already measured

Inputs: `census-q9-small`, `census-q9-large`, `census-qb`, `r42au-elev`
(ElevatorSafetySmall after R4.2au), `qw-innerserial3` (MCInnerSerial at its
per-model wall), and `full-suite-r451-final.log`. Every computable clause
HOLDS: 1 (373/373), 2 (100 = pin, 27 recorded), 3 (31/31), 4 (140, 0 owed),
6b (2,457 OK arms, every declared arm run), 6c (157 rows + MCChangRoberts
not run), 7a (132 agree, 26 recorded), 7b (44/44, 7 excluded), 8 (373/373).
6a needs `release-gate.sh` (run below), 7c the user's dojo log.

## Found by the dry run: ACP_NB_WRONG_TLC's counts at its violation

Q9 called it "= pin": it compared against the MANIFEST, which records no
counts for a failure. Against the pin: safety failure at depth 13 both, but
12,645 distinct / 970 queued here against 11,852 / 1,248. A violation's
counts depend on BFS order within a level, and the spec's eight model
values (`waiting`, `notsent`, `undecided`, `commit`, `abort`, `yes`,
`timeout`, `no`) order lexicographically here and by intern (config) order
in tlc2 -- the approved `tlc-value-model` difference. Measured: renamed
`m1`..`m8` in config order (the two orders then coincide), the pin gives
11,852/1,248/13 again and the port gives **11,852 distinct, 1,248 queued,
depth 13** (generated 59,289 vs 59,286, the recorded normalization). So
it is recorded under `order_dependent`, with verdict and depth still
required to match.

## Two script bugs fixed during the dry run

- A large model the pin only smoke-ran was compared with the pin's
  `SMOKE ok` text; it is now compared with the manifest's counts.
- The inputs: later census files override earlier ones row by row.

## The release gate (clause 6a): two clauses had drifted

`release-gate.sh` FAILED on two clauses, both stale against decisions made
during R4, neither an engine regression:

- **R4 (refusals documented both ways):** the table still quoted three
  refusals the code no longer makes -- VIEW with a temporal PROPERTY
  (runs since R4.2e) and ALIAS with a temporal PROPERTY / in simulation
  (run since R4.2i; that row was already marked retired, but kept the
  messages in backticks, which the gate reads as live refusals). Rows
  marked retired, messages quoted as plain text. The matching stale
  comment in `lib/job.hoon` gained the R4.2i line.
- **R5 (upgrade/restart):** it looked for `versioned-state` and
  `;;(versioned-state`; the user's no-migrations rule replaced that with one
  tagged shape (`state-0`) coerced by on-load and reset when it no longer
  fits (scaffold gate 6). The clause now checks that contract.

Re-run: **RELEASE GATE: PASS** (every clause).

## R4.5.3 in one command

`tools/r4-examples-run.sh OUTDIR` reproduces the measured passes on the
current tree (small at 900 s; the timed-out small rows but MCChangRoberts;
the 11 rows at 3,600 s; the large smoke; MCInnerSerial at 3,800 s), then
`r4-acceptance.py` reads them in that order, later rows overriding earlier.
Every `timed-out.json` row is covered by a pass or by `r4-fallback.json`.
