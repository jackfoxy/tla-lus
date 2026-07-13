# Testing & Compatibility Validation

`%tla-lus` is validated by **differential testing** against the Java TLA+
toolchain at a pinned commit: every Hoon component is compared, output for
output, with the corresponding Java tool. The comparison is organized into
three tiers.

## The oracle and the pin

All goldens come from `tla2tools.jar` built from the pinned commits
(`tlaplus@4ba7d8811`, `tlaplus-Examples@47b0e2cc`, `vscode-tlaplus@acc095d6`;
see `port-map.md` §0). Both `tools/validate.py` and
`test-data/oracle/regen.sh` refuse to (re)generate goldens if the checkout is
off-pin, so a golden can never silently drift to a newer tool version.

Rule: **never weaken a golden without first proving the Java behavior from the
pin.** Any intentional divergence is recorded in `compatibility.md`.

## Tier 1 — every change (fast, local)

Two halves, both required to be green:

1. **Golden reproducibility** — `python3 tools/validate.py --check`
   recompiles the oracle dumpers (`tools/oracle/*.java`), reruns every
   generator, and hashes the oracle-derived trees before/after to prove they
   reproduce byte-identically from the pinned oracle. Covered generators and
   counts: lexer (249), parser (249), BNF manifest (35 productions), module
   resolution (13), semantic graph + levels (19), constant evaluation (37),
   safety+liveness model checking (5), and the unit-0 oracle baseline (14).
2. **Hoon differential + property tests** — on the fake ship:
   `-test /=tla-lus=/tests ~`. This runs the generated differential shards
   (lexer/parser/sem/modres/eval/mc against their goldens) plus the
   hand-written property suites: `crc` (CRC-32 vectors), `sim` (seeded
   simulation reproducibility/limits), `job` (the resumable engine +
   real-pipeline integration), `bnf` (grammar-manifest drift), `diagnostics`,
   `migrate`, and the `app` agent tests.

Oracle dumpers, by stage: `TokenDump` (lexer), `AstDump` (parser CST),
`SemDump` (semantic graph + levels), `CrcVec` (PlusCal checksums), and the
REPL/TLC/SANY invocations driven directly by the generators.

## Tier 2 — CI / nightly (broader, slower)

- The relevant subset of `tlaplus/test-model`.
- A curated matrix from `tlaplus-Examples` covering imports/EXTENDS, PlusCal,
  safety, liveness, standard modules, symmetry, and simulation.
- Adapted non-UI parser fixtures from the Toolbox and the VS Code extension
  for tagged TLC messages, diagnostics, monolith modules, progress, coverage,
  checkpoints, structured values, stuttering, and lasso traces.

Each tier-2 spec is run through **both** SANY implementations (Java and the
Hoon units 4–7) and, where it has a config, through **both** TLC and the Hoon
checker (units 10–11); the comparison covers pass/fail category, diagnostic
codes/spans, semantic trees, verdict, state counts, depth, and normalized
traces. (Tier-2 automation is being built out incrementally as the ported
surface grows; see `port-map.md` for which feature rows are live.)

## Tier 3 — pre-release

Broader `tlaplus-Examples` coverage and bounded performance models
(queue/evaluator/enumeration/fingerprinting/safety/liveness hot paths).

## Fuzzing

`tests/lib/tla/fuzz.hoon` drives the lexer and parser with seeded random
inputs and asserts they never crash — they must return a clean accept/reject,
never bail. Any reduced mismatch discovered by fuzzing is saved as a
regression fixture under the appropriate `test-data/` corpus so it becomes a
permanent tier-1 case.

## Adding a case

1. Put the source fixture under the matching `test-data/<stage>/` corpus.
2. Run the stage's generator (or `tools/validate.py`) to capture its golden
   from the pinned oracle.
3. Commit the fixture, the golden, and the regenerated shard together.
4. Confirm both tier-1 halves are green.
