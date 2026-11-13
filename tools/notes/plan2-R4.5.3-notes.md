# R4.5.3 — the user's runs; R4 ACCEPTED (2026-11-12)

The user ran, on tla-zod:

- `tools/r4-examples-run.sh ~/FoxyLabs/tla-lus` (2026-11-05 15:37 →
  11-06 10:53): `small.txt` 123 rows, `timed-out.txt` 3, `hour.txt` 11,
  `large.txt` 31, `innerserial.txt` 1 -- every model but MCChangRoberts
  (not run by decision).
- the full suite, `~/FoxyLabs/tla-lus/R4-census-tests-results.txt`
  (2026-11-08): `ok=%.y`, 2,458 OK.
- the documented dojo entry point (2026-11-12, after the R4.5.2 dojo
  fixes): `:tla-lus +tla-lus!tla-lus/submit ~.job-1 %check`, then
  `+tla-lus!tla-lus/status ~.job-1` -> `[%ok 5/4/4]`
  (`tla-zod-tools/logs/r453-dojo.txt`).

`tools/r4-acceptance.py` on those inputs, release gate included:
**11/11 clauses hold -- R4 ACCEPTED** (`tools/notes/r4-acceptance-output.txt`):

| clause | result |
|---|---|
| 1 parse | 373/373 agree |
| 2 small | 100 = pin; 27 recorded (23 time-bound + MCChangRoberts not run, 2 approved refusals, 1 order-dependent count) |
| 3 large | 31/31 |
| 4 ledger | 141 terminal, 0 owed |
| 5 tier 3 | REPORTED (report-only for R4, the user's decision) |
| 6 gates | release gate PASS; suite ok=%.y, 2,458 OK, 0 declared arms not run; runner census 157 rows + 1 not run |
| 7 black box | 158 selected = work list, 132 agree + 26 recorded; 44/44 failure arms, 7 exclusions with reasons; the dojo run |
| 8 Unicode | 373/373 verdicts, 373/373 identical graphs |

Run note: a side conversation suggested the suite log was the runner's
OUTDIR; it is not (`~/FoxyLabs` links to `~/Dropbox/Documents/FoxyLabs`, where
the census files sit beside the suite log), and the first acceptance run,
stopped by the user, had the right inputs.
