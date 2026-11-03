# R4.0f: the July black-box suite, re-founded

```text
Sub-unit: R4.0f (plan r3)
Planned: regenerate the July ledger for R4 scope; the corpus half becomes
  tools/examples.py's work list; the 51 failure scenarios become real -test
  arms through a rewired adapter; nothing excluded silently; the desk builds
  with tests/ copied wholesale.
Found: July's expected values were guesses. The pin contradicts 9 of the 21
  TLC fixtures and 3 of the 7 SANY ones.
```

## 1. What changed on disk

**Deleted** (git rm; all of it generated or a mirror):
- `desk/tests/lib/corpus/**`, which held 726 corpus arms. Those were stubs:
  the adapter returned `%blocked`.
- `desk/tests/lib/failures/**`, the old failure arms. They are replaced.
- `desk/tests/check-coverage.py`. Its `.py` file inside the desk was the build
  hazard.
- `desk/tests/coverage.md`.
- `desk/tests/fixture-sha256.txt`, which checksummed 17 554 files.
- `desk/tests/fixtures/examples/`. The pinned Examples checkout replaces the
  mirror.

**Moved:** `desk/tests/fixtures/failures/` → `desk/test-data/blackbox/fixtures/`.
Its `.cfg` files can no longer reach Clay, so the old `%no-cast-between %mime
%cfg` hazard is gone too.

**New:**
- `tools/gen-blackbox.py` generates everything below and has a `--check`
  mode.
- `desk/tests/lib/blackbox/{parser,config,runtime,interface}.hoon` holds the
  44 arms. Each arm embeds its fixture's module closure inline.
- `desk/test-data/blackbox/models.json` is the work list for
  `tools/examples.py`: 158 models plus 373 parse modules.
- `desk/test-data/blackbox/coverage.md` is the ledger. Each scenario names
  its oracle and July's guess beside it.

**Rewritten:**
- `sur/tla-lus-test.hoon`, now `case` and `report` only.
- `lib/tla-lus-test-adapter.hoon`, which drives the agent in-process.
- `lib/tla-lus-test-helpers.hoon`.

## 2. Oracles

Every arm asserts exactly one named oracle.

**`pin sany` / `pin tlc`.** The generator runs the pinned jar on the same
fixture. It uses `-tool` for TLC, so EC codes are machine-read, not
scraped.
- The category follows upstream CI's exit-code rule. An action-property
  violation exits 13, so it is a **liveness** failure, not safety as July had
  it.
- The code is the first severity-1 EC.
- A fragment is kept only if the pin's own output contains it. The generator
  exits if one does not.

**`api`.** Documented agent behaviour, cited per arm.
- One citation is a gap: `+on-poke`'s `src = our` assertion is not in
  `api.md`. That is a finding against `api.md`.

**`EXCLUDED`.** Seven scenarios, each with a reason:
- `invalid-mode`: the typed wire cannot carry it.
- `invalid-flag`: there are no free-form flags.
- `invalid-worker`: the engine is single-threaded.
- `invalid-seed`: every `@ud` is a valid seed.
- `invalid-path`: Clay is unreachable in-process; the wire case is R4.0d's.
- `worker-process-failure`: there are no processes.
- `missing-request-id`: an ill-typed noun is `malformed-payload`.

## 3. Where July guessed wrong (pin measured 2026-10-08)

| scenario | July | pin |
|---|---|---|
| lexical-error (`1 @ 2`) | lexical 4000 | **parse** error (`@` is a token SANY lexes) |
| module-name-mismatch | parse 4001 | module error (file/module name) |
| missing-dependency | semantic 4002 | module error |
| missing-config | config 5001 | EC 2231, rc 151 |
| malformed-config (`INVARIANT` with no name) | config 5003 | **success** |
| duplicate-config | config 5004 | EC 1000 (unexpected exception) + 5004 |
| unknown-constant | config 5002 | **success** |
| incomplete-initial-state | 2106 | EC 2102 |
| no-initial-states | 2118 | **success**, 0 states |
| no-constraint-states | 2256 | **success** |
| invariant-evaluation | 2111 | EC 1000 then 2103 |
| action-property | safety 2112 | **liveness** 2112 (exit 13) |
| liveness-with-symmetry | config 2279 | **success**, 2279 only a WARNING |
| invalid-depth (`-simulate -depth 0`) | parameter 3107 | **success**, rc 0 |

The last row matters for R4.2d. The port REFUSES SYMMETRY together with a
temporal property, while the pin warns and runs. This arm is expected to fail
until R4.2d lands, and it is the black-box half of that row.

## 4. Corpus

The work list holds **158** models:
- by expected outcome: success 140, safety failure 16, liveness failure 2;
- by size: 127 small, 31 large.

Clause 2/3's set is **167**. The 9 extra models have manifest result
`unknown`; July excluded them for having no stable oracle, and clause 3 smoke
runs them. There are **373** parse modules. The listed exclusions are
PlusCal, Apalache `symbolic` and `unknown`.

## 5. Ship results (2026-10-08, desk rev 219)

**`-test /=tla-lus=/tests/lib/blackbox ~` → `ok=%.y`, 37/37.** Getting
there took four iterations. Each change is either an adapter normalization,
stated here, or a fix to the generator's reading of the pin. No expected value
was edited to match the port.

**Build.** The mold was renamed from `case` to `bb-case`, because `case` is
the Clay revision mold and shadowing it fails far from the cause. The
adapter's `weld`/`zing`/`turn` chain hit `fuse-loop` and was fixed with typed
intermediates, as the style guide prescribes.

**Adapter normalizations:**
- A TLC verdict's message rides in the `%report` artifact, and a `%failed`
  run's in `reason`. Both are added to `summary`.
- A verdict's EC comes from the TYPED result's `violation`, which sur
  documents (2107/2110, 2108/2116, 2112, 2114, 2104).
- The pin's `N: Stuttering` lasso is the port's `loop-start` = the last
  state.

**Generator fixes:**
- TLC codes are read from the `STARTMSG` headers in order, because EC 1000
  NESTS the specific message.
- EC 1000 (the "unexpected exception" wrapper) yields to the code that follows
  it: `Duplicate.cfg` → 5004 and `InvariantEvaluation` → 2103.

**Expectation fix:** `oversized-input` with an `%inline` bundle is
`%rejected` at submit, which compatibility.md permits.

**7 measured divergences**, all on the wire's projection of a failing run.
They are WITHHELD with their reasons printed on every generation, and owned
by the new ledger row `op-wire-failure` (R4.2j):
- (a) Runtime evaluation failures carry no EC and no `%trace`: EC 2102, 2109,
  2103 and 2179.
- (b) A false ASSUME is `%failed` and not `[%violated [%assumption …]]`.
- (c) `%analyze` module-resolution errors carry generic text, not SANY's.

## 6. Findings for the plan

1. **SYMMETRY with a temporal PROPERTY is NOT refused.** `lib/job.hoon` has
   warned and continued since R2.7.5 (EC 2279), and the black-box arm
   `liveness-with-symmetry` passes against the pin. R4.2d's premise ("the port
   refuses it") and the census's "SYMMETRY + temporal PROPERTY (refused)" row
   of 6 models are STALE. R4.2d shrinks to measuring whether those 6 models
   agree.
2. **`api.md` was wrong in two places**, now fixed:
   - re-submitting a TERMINAL id is rejected, not allowed (`op-gall-submit`
     says so, and so does the code);
   - the `src = our` poke rule was not documented anywhere a client reads.
3. **Ledger:** `op-wire-failure` was created, `absent`, owner R4.2j. Ledger
   now 135 rows, 3 owed.

## Status

DONE except the R4.0f exit item already met: `tests/` copied wholesale
builds. The pier's tree equals the repo's, and every file in it is `.hoon`.
