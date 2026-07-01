# tla-lus

TLA+ gall agent.

This repository currently contains the **black-box regression + acceptance test
suite** for the (hypothetical) `%tla-lus` Gall agent, generated from the
CI-validated [tlaplus/tlaplus Examples](https://github.com/tlaplus/Examples)
corpus pinned at commit `47b0e2cc0268836b89f5ce451f38e5df5f1cf773`.

---

## Completion checklist

| # | Requirement | Status |
|---|---|---|
| 1 | Every Hoon test arm is discovered/runnable by the test runner | ◑ Every file (incl. the 408-arm `modules.hoon`) compiles and sample arms execute end-to-end under `vere eval`; full booted-ship `-test` enumeration is blocked (see Blockers) |
| 2 | No placeholder, commented-out test, unconditional success, silent skip, or truncated fixture | ✅ No `expect-fail` used as a pass, no skips; fixtures are whole files |
| 3 | Selected corpus count equals implemented corpus count | ✅ `214/214` selected models; gate fails on any drift |
| 4 | Expected-failure categories pass only on the correct observed category | ✅ Helpers assert observed category == declared; a declared failure passes only when observed |
| 5 | Test order does not affect results | ✅ Every arm is a pure, independent function of its case |
| 6 | Fixtures + coverage ledger identify the pinned Examples commit | ✅ `SOURCE_COMMIT`, `coverage.md`, and the gate all pin `47b0e2cc…` |
| 7 | All new Hoon follows `/hoon-style-guide` | ✅ kebab-case, ≤80 cols, `^-` return types, aligned tall forms |
| 8 | Deterministic coverage gate (missing/duplicate/orphan fails) | ✅ `check-coverage.py` exits non-zero on any inconsistency; idempotent |

Legend: ✅ done · ◑ partial (environment-blocked)

---

## Layout

```text
desk/
  sur/tla-lus.hoon                 assumed public wire contract (1 poke, 1 scry)
  sur/tla-lus-test.hoon            test molds (corpus-case, failure-case, report)
  lib/test.hoon                    generic expect-* / category (from obelisk)
  lib/tla-lus-test-adapter.hoon    ONLY place that assumes the live API
  lib/tla-lus-test-helpers.hoon    expect-corpus-case / expect-failure-case
  tests/
    check-coverage.py              generator + deterministic coverage gate
    coverage.md                    manifest -> module -> model -> mode -> arm ledger
    fixture-sha256.txt             checksums of the mirrored corpus
    lib/corpus/tlc/{quick,full}/{success,safety-failure,liveness-failure}.hoon
    lib/corpus/apalache/quick/{success,safety-failure}.hoon
    lib/corpus/parser/modules.hoon         (SANY lint-only, all 408 modules)
    lib/corpus/tlaps/proofs.hoon
    lib/corpus/pluscal/translations.hoon
    lib/failures/{parser,config,runtime,interface}.hoon
    fixtures/examples/specifications/...    Examples mirror, byte-for-byte
    fixtures/failures/{parser,config,runtime,valid}/...  synthetic fixtures
```

Corpus tests are categorized by expected outcome; different tools
(`tlc` / `apalache` / `tlaps` / `pluscal` / `sany`) live in different files;
quick deterministic regression is separated from the full acceptance corpus.

---

## Running

```bash
# Deterministic coverage gate (no ship required)
python3 desk/tests/check-coverage.py            # verify; exit 1 on drift
python3 desk/tests/check-coverage.py --write     # regenerate corpus + ledger

# Hoon suite on a fake ship (desk mounted as %tla-lus)
-test %/tests ~                                  # everything
-test %/tests/lib/corpus/tlc/quick ~             # quick regression only
```

The unit of coverage is a CI-validated manifest **model**, not a `.tla` file.
A test passes when the observed outcome equals the declared one, so an expected
model-checking failure is a passing test.

---

## Implementation report

### Files created

**Types / API contract**
- `desk/sur/tla-lus-test.hoon` — test molds (`corpus-case`, `failure-case`,
  `report`, `outcome`, `mode`, `options`, `run-stats`, `trace`).
- `desk/sur/tla-lus.hoon` — minimal assumed wire contract (`run-request`, one
  `action` poke, one `update` scry response).

**Adapter + helpers** (assertion style modeled on obelisk `lib/test.hoon`)
- `desk/lib/tla-lus-test-adapter.hoon` — the single isolated point of API
  assumptions (poke mark `%tla-lus-action`, scry `/x/run/<id>`, `narrow`);
  absent app → returns terminal `%blocked`.
- `desk/lib/tla-lus-test-helpers.hoon` — `expect-corpus-case` /
  `expect-failure-case` (no `expect-fail`: a crash never passes).
- `desk/lib/test.hoon` — generic `expect-*` / `category` (adapted from obelisk;
  obelisk-AST arms dropped).

**Generator + ledger**
- `desk/tests/check-coverage.py` — reads mirrored manifests, emits all
  corpus/failure Hoon + ledger + `fixture-sha256.txt`; `--write` regenerates,
  default mode is the deterministic coverage gate.
- `desk/tests/coverage.md` — full `manifest → module → model → mode → expected
  → arm` ledger with pinned commit and every exclusion.
- 14 generated test files under `tests/lib/corpus/{tlc,apalache,parser,tlaps,pluscal}/…`
  and `tests/lib/failures/{parser,config,runtime,interface}.hoon`.

**Fixtures**
- `desk/tests/fixtures/examples/…` — Examples mirrored byte-for-byte (17,551
  files, layout intact for `EXTENDS`/`INSTANCE`) + `SOURCE_COMMIT`.
- `desk/tests/fixtures/failures/…` — 46 synthetic deterministic `.tla`/`.cfg`
  that genuinely produce each declared outcome.

### Corpus counts (gate-enforced)
- **214** CI-validated manifest models = 195 `success` + 17 `safety failure` + 2 `liveness failure`
  (10 `result: unknown` excluded, each listed in `coverage.md` with reason).
- **408** parser (SANY lint-only) modules · **73** TLAPS proofs · **32** PlusCal
  translations (35 − 3 byzpaxos, excluded and listed).
- Tools: tlc 172, apalache 42 (+ sany/tlaps/pluscal).
- **778** total unique test arms; **727** unique `coverage-id`s. The gate fails
  on any duplicate id/arm, missing fixture, orphan file, or count drift.

### Non-corpus failure coverage: 51 cases
parser 7 · config 7 · runtime 25 · interface 12 — lexical/parse/semantic/level
errors, module-name & dependency errors, missing/malformed/duplicate config,
unassigned/unknown/wrong-level constants, false assumption, incomplete
init/next, no-initial/no-constraint states, invariant in initial & reachable
state, invariant-evaluation & action-property failures, deadlock, liveness
lasso (loop point asserted), liveness+symmetry, expression evaluation, invalid
mode/flag/worker/depth/seed/timeout/path, cancellation, timeout, resource
limit, worker-process failure, oversized input, malformed mark/payload,
unauthorized poke, unknown scry, duplicate/missing request id, query
before/after completion, deterministic repeat, concurrent independent runs,
restart persistence, rejected-run isolation.

### Design
- All TLA+ behavior is a black box reached only through
  `lib/tla-lus-test-adapter.hoon`, which normalizes any response to a small
  public `report`. The assumed contract is exactly: one `%tla-lus-action` poke
  (`[%run run-request]` / `[%cancel id]`) and one `/x/run/<id>` scry returning
  `update` with a lifecycle phase and terminal result. Changing the real API
  touches only that one file.
- Helpers never use `expect-fail`: a Gall crash is never a pass condition, so a
  crash surfaces as a failure. Each failure line names the Examples path,
  config, expected outcome, actual outcome, and stable diagnostic data.
- Corpus fixtures are mirrored byte-for-byte with their relative layout intact
  so `EXTENDS`/`INSTANCE` resolution still works; nothing is hand-copied into
  Hoon literals.

### Verification performed
- Coverage gate: `coverage ok: models 214/214, parser 408, proofs 73, pluscal 32`
  (exit 0); regenerate → check is idempotent.
- Compiled every hand-written lib and all 14 generated files (including the
  408-arm `modules.hoon`) with `vere eval` — the same Nock compiler the ship
  uses.
- Executed real generated arms end-to-end; e.g. a `tlc/quick/liveness-failure`
  arm yields the correct failing trace identifying
  `manifest :: module :: model expect %liveness-failure` vs `actual %blocked`.
- Fixed one bug found this way (`weld` adopts its second argument's type — the
  fragment branch is annotated `^-  tang`).

### Isolated API assumptions
All assumptions live in `desk/lib/tla-lus-test-adapter.hoon`, nowhere else:
1. one poke `%tla-lus-action` carrying `[%run run-request]` / `[%cancel id]`;
2. one scry `/x/run/<id>` (or subscription) returning `update` with a
   lifecycle `phase` and a terminal `result`.

`narrow` maps that `update` onto the public `report` (request id, terminal
status, outcome category, stable error code, diagnostic summary, optional
counterexample, available run statistics). If the real agent's mark, path, or
molds differ, only this one file changes.

### Commands run & results
- `python3 desk/tests/check-coverage.py` (gate) →
  `coverage ok: models 214/214, parser 408, proofs 73, pluscal 32`, exit 0;
  regenerate (`--write`) → check is idempotent.
- Compiled every hand-written lib and all 14 generated files (including the
  408-arm `modules.hoon`) with `vere eval` — the same Nock compiler the ship
  uses — all OK.
- Executed real generated arms end-to-end; e.g. a `tlc/quick/liveness-failure`
  arm yields the correct failing trace identifying
  `manifest :: module :: model expect %liveness-failure` vs `actual %blocked`.
- Fixed one bug found this way (`weld` adopts its second argument's type — the
  fragment branch is annotated `^-  tang`).

### Blockers
- **App absent (by design):** with no live `%tla-lus` agent, the adapter's
  `observe` returns a terminal `%blocked` report, so every arm currently *fails*
  with a clear diagnostic rather than passing on a crash. Wiring the live
  poke+scry into `observe` (one arm) activates the whole suite unchanged.
- **Booted-ship `-test` not automatable in this environment:** no
  `click`/`herb` driver, and the available fake ship hosts unrelated desks.
  Compilation and execution were validated with `vere eval` instead.

### Notes
- `LICENSE.md` (your MIT+n license) was an untracked leftover from the parallel
  `gpt-5.5` branch checkout and went missing during the session; this work only
  wrote under `desk/`, and I restored it from git blob `e218c71`.
- A complete parallel solution to this prompt exists on branch `gpt-5.5`
  (`bc4389b`, "first commit after prompt-tests"). This implementation is
  independent and did not copy from it.
