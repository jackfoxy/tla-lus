# R4.2y — a crash never orphans a job (2026-10-09)

**Status: DONE.**

## The bug

A Hoon crash inside a job slice was not caught. Gall rolled the event back,
including the behn wake that drove it, so the job sat `running` with nothing
to step it again. R4.0e2 lost about 50 minutes to three such models
(HourClock2, Barrier, MC_sums_even), each held to the 900 s wall cap.

## Fix (`lib/job.hoon`)

- `+run-safe` wraps every slice (`+run`) in `mule`, at both call sites in
  `+step`.
- `+crash-fail` turns a crash into a terminal result:
  - The `%tlc-live-wrong-formula-format` crash (`lib/temporal.hoon:912`,
    the port of `Liveness.classifyExpr`'s
    `Assert.fail(TLC_LIVE_WRONG_FORMULA_FORMAT)`) becomes tlc2's typed error:
    diagnostic `[%tlc 2.214]` and `[%failed 'Temporal formulas containing
    actions must be of forms <>[]A or []<>A.']`.
  - Any other crash is `[%failed 'internal: crashed in %<stage>: <first
    trace line>']`.

## Found by it: cfg integers of 1000 or more crashed the config parser

MC_sums_even's crash was `lib/config.hoon:114`, in `+read-dec`, which used
`(slav %ud t)`. That wants Hoon's dotted form (`1.000`), so `MaxNat =
1000000` crashed. Fixed with `(rash t dem)`. New oracle case
`desk/test-data/cfg/pos-const-bigint` (`N = 1000000`, `M = 1000`; golden
from the pinned `ConfigDump`); its arm crashed before the fix and passes
after. No other `slav %ud` reads user input.

## Evidence

- `tests/lib/job.hoon`:
  - `test-crash-seals-job`: a slice in a stage `+run` has no arm for ends
    `[%stop …]` with `[%failed 'internal: crashed in %lint…']`.
  - `test-wrong-formula-format-typed`: `Live == (<><<Next>>_i) ~> (i = 5)`;
    expected from tlc2 at the pin (exit 255, the line above), plus code
    2214.
  - Both crashed the agent before the fix.
- Shards green on `tla-zod`: job 126, cfg (incl. `pos-const-bigint`), app
  41, clay-load 36, blackbox 40, cfg-val 39, cfg-runspec 16, safety-gen 10,
  liveness-message 10, mc 106.
- Through the runner, the three former orphans now finish in about 11 s:
  - HourClock2, Barrier: EC 2214. tlc2 SUCCEEDS on both, so the port's
    temporal classifier misreads their properties (`HC2 == HCini /\
    [][HCnxt2]_hr`, an implied-action property). That is R4.2n.
  - MC_sums_even: after the read-dec fix, `no INIT in config` (R4.2k).
- All three are off `timed-out.json` (12 left).
