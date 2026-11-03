# R4.0c: the pinned oracle over the whole R4 Examples corpus

```text
Sub-unit: R4.0c
Tool: tools/examples-oracle.py (--check for byte-reproducibility)
Goldens: desk/test-data/tier2/examples/{sany,sany-unicode,tlc}/<path>.txt,
         pin-vs-manifest.txt, lncheck.txt, tlauc-failures.txt
Planned: 1.5-2 h of JVM. Measured: 25 min for the full capture with 4 jobs.
```

## 1. Method (and where it departs from upstream CI)

**SANY.** CI's exact command (`parse_modules.py`): the classpath
`tla2tools : apalache.jar : <spec dir> : CommunityModules-deps.jar :
tlapm/library`, run from the Examples root with `-error-codes`.

**Unicode.** A copy of `specifications/` converted with pinned `tlauc
--skip numsets` (CI's flags), then SANY the same way.

**TLC.** CI's classpath, mode flags and the `cdot` feature flag. It departs
from CI in four places, all for determinism:
- `-workers 1` (CI uses the manifest's setting, default `auto`);
- `-fp 0` (CI picks a random polynomial);
- `-seed 0` in EVERY mode (see §3);
- `-noGenerateSpecTE`.

CI also runs `-lncheck final`. The golden is taken without it; every
liveness model then runs a second time with it, and `lncheck.txt` records
whether the output changes.

**Size split.** Small models (recorded runtime ≤ 30 s, CI's split) run to
completion. Large models (> 30 s or `unknown`) get a 60 s smoke run (CI
gives them 5 s).

## 2. Results (first capture)

- **SANY: 373/373 exit 0**, in ASCII and in Unicode. CI's claim that every
  module parses holds at the pin. `tlauc` converted every module.
- **TLC (167 models):**

  | result | models |
  |---|---|
  | success | 112 |
  | safety failure | 16 |
  | liveness failure | 2 |
  | smoke ok (large) | 35 |
  | exit 255 | 2 |

  The two exit-255 models are `ewd998/EWD998ChanID_export` and `_shiviz`,
  both with manifest result `unknown`: `Error: current state is not a legal
  state`.

**Pin against manifest.** Every recorded result agrees, and so does every
recorded `distinctStates` / `totalStates`. **`stateDepth` differs by 1–2 in 7
models**, always lower at the pin:
- `ElevatorSafetySmall`, `PrisonerLightUnknown`, `SpanTree`, `braf`, `btree`,
  `kvstore`, `EWD840`.

The manifest was recorded with `-workers auto`, and the pin with `-workers 1`.
This is a recording difference. **The pin wins** (R4 plan, risk 3): clause 2's
depth check compares against the pin's projection, never against the
manifest's `stateDepth`.

## 3. Finding: unseeded `RandomElement` in a BFS

`SpanTreeRandom` was the one model whose `-lncheck final` run DIFFERED. The
flag is not the cause. The spec draws `RandomElement(...)` inside a constant
definition, and an exhaustive run without `-seed` gets a fresh random seed
on every run (tlc2 never prints it). Two runs, two state spaces. Every TLC
run now passes `-seed 0`, the port's default, and the TLC part was
re-captured.

This is the R4.P3 trap in miniature: a constant definition that is random.
It is also a reproducibility hole that `tier2.py`'s curated runs share. They
pass no `-seed`; that is harmless today only because no curated spec draws.

## 4. After seeding (2026-10-08 09:47)

The re-captured results are identical in shape: 112 success, 16 safety, 2
liveness, 35 smoke ok, 2 exit 255.

**`lncheck.txt`: 88/88 liveness models are byte-identical with and without
`-lncheck final`.** The flag moves nothing at the pin on this corpus, so the
goldens need not mirror it.

**Reproducibility:** `--check --part tlc` (a second full run) reproduced all
167 TLC goldens, `pin-vs-manifest.txt` and `lncheck.txt` byte-for-byte. Its
only "drift" was the three parts it did not regenerate; the tool's `--check`
now restricts the comparison to the parts a run produced.

## Status

DONE. Exit evidence met:
- the goldens reproduce;
- the pin-vs-manifest table is written. Its disagreements are 7 depth-only,
  explained by worker count, plus 2 results that are manifest `unknown`.
