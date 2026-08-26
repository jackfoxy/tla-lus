# R2.7.4 — handoff

Written at the close of R2.7.3 for a fresh session. R2.7.4 is the largest
remaining unit and it absorbed two others, so its scope is no longer what the
plan row alone says.

## Where the project stands

Committed through **R2.7.3** (`fd9ad1b9`), working tree clean. Ledger: **131
rows, 124 terminal, 7 owed** (`tools/check-parity.py`). Scaffold gate PASS,
tier-1 `validate.py --check` green.

R2 sub-units done: R2.0–R2.2, R2.3.0–.5, R2.4.0–.6, R2.5.0, R2.5, R2.6 (all),
R2.7.1, R2.7.2, R2.7.3. Remaining: **R2.7.4**, R2.7.5, R2.7.6, R2.8.1, R2.8.2,
R2.9.

## The dev ship — read before doing anything

The pier was rebuilt on 2026-08-25 (the old one was on an obsolete vere and had
become unstable).

```
/mnt/mars/piers/tla-zod/.run --loom 32 /mnt/mars/piers/tla-zod
```

- **vere 4.6**, `--loom 32` = 4096MB. **The loom flag is not persisted** — a
  plain `.run <pier>` maps 2048MB and the desk will not rebuild cold
  (`recover: dig: meme`). Check `du -sh .urb/chk` against the mapped loom
  whenever anything memes.
- tmux session `tla-zod`; drive with `send-keys` (use `-l --` for lines starting
  with `-`) and `capture-pane`.
- Deploy loop: `cp` changed files from repo `desk/` into
  `/mnt/mars/piers/tla-zod/tla-lus/`, then `|commit %tla-lus`.
- **On a FRESH pier only**: after the first commit you must
  `|install our %tla-lus`, or no agent exists and nothing runs.
- **Do not run the full suite.** The user runs it; ask. Run the touched shards
  plus `validate.py --check` and `scaffold-gate.sh`.
- Two traps that cost real time: `tmux clear-history` does NOT clear the visible
  screen, so polling the pane for `^ok=%` matches the PREVIOUS run's verdict —
  poll for the run's own command echo and confirm it sits above the verdict. And
  never send a command while output is still streaming; the dojo concatenates
  keystrokes and wedges (recover with `C-c`, `C-a`, `C-k`).

## What R2.7.4 now owns

The plan row is `tlc-coverage` only. **Two more units folded in** because all
three need the same evaluator change:

| consumer | folded from | what it needs |
|---|---|---|
| `tlc-coverage` cost model | its own row | a counter that accumulates UPWARD through evaluation |
| `TLC!TLCSet` + `TLCExt!TLCGetOrDefault`/`TLCGetAndSet` | **R2.6.1** | a run-scoped mutable register store |
| `Randomization!*` + `TLC!RandomElement` | **R2.6.2** | RNG state that advances across draws inside one evaluation |

It also owns closing `tlc-module-tlc` and `tlc-util-combinatorics`. The
`r2-scope` column in `desk/test-data/stdops/inventory.txt` already says
`R2.7.4` for all six surfaces — that column is machine-checked and
`gen-stdops-tests.py` fails on anything unclassified, so keep it in step.

## The one change all three need

`eenv` is read-only and `eres` is `(each value eval-err)`. There is no channel
for mutable run state to escape an evaluation. **Every eval's RETURN type has to
carry it.** `node-eval` has ~90 `eenv` references; this is cross-cutting.

R2.0 sized `tlc-coverage` L/high for exactly this and recorded the reason:
*"`fuel` decrements DOWNWARD while coverage accumulates UPWARD, and Hoon has no
mutable counter."*

**Design once, against all three.** The shapes differ:

- coverage: a monotone counter, write-only during evaluation, read at the end.
- register store: a `(map @ud value)` read AND written mid-evaluation, and the
  write is visible to a later conjunct of the same evaluation.
- RNG: a seed that advances per draw, reseeded per predecessor state.

## Measured facts to build against (do not re-measure)

**`TLCSet`** (`tools/notes/plan2-R2.6.1-tlcget-notes.md`)
- The register accumulates ACROSS state expansions: measured 100 → 101 → 102 →
  103 with `TLCSet(0, TLCGet(0) + 1)` in a next-state relation.
- The write is visible to a later conjunct of the SAME evaluation.
- It is worker-local side-channel state, NOT part of the checked state.
- `TLCGet`'s READ half is already done (statistics keys), so only the write and
  the integer-key reads remain.

**`Randomization`** (`tools/notes/plan2-R2.6.2-randomization-measurement-notes.md`)
- The machinery is ALREADY PORTED: `+subset-indices`, `+optimal-m-a`,
  `+prime-factors`, `+next-int-bound` in `lib/rng` (built by R2.4.6), and FP64
  at polynomial index 0 (`tlc-util-fp64` is `parity`).
- The draw is keyed on `state.fingerPrint() ^ randomSeed`, reseeded per
  PREDECESSOR state in BFS; during initial-state generation it is `randomSeed`
  alone.
- Parity is against **`-fp 0` runs only**, because the port's FP64 is pinned at
  index 0.
- The RNG ADVANCES within one evaluation — the pin designs for
  `x' = RandomElement(0..2) /\ y' = RandomElement(0..2)` giving two values.
- **There is no honest partial**: a fresh RNG per evaluation is right for one
  draw and SILENTLY WRONG for two.
- Trap on record: `-fp 0 -seed 7` and `-fp 0 -seed 8` gave identical picks and
  looked like proof `-seed` was inert. It was a collision on `nextInt(100)`.
  Widen the seed before concluding.

**`tlc-coverage`**
- `TLC_COVERAGE_INIT/NEXT` are `getEvalCount()` (`ActionWrapper.java:147/155`).
- tlc2 threads `CostModel cm` through 49 signatures in `Tool.java` (433 refs).
- The `Tool.getActions` decomposition that KEYS them is already ported and
  verified (`+get-actions`, per-action trace labels).

## A constraint R2.7.2 proved, which will bite

**The `value` mold cannot take another recursive arm.** Isolation-probed:

| shape | result |
|---|---|
| 10th arm carrying a second named recursive mold | `[skipped 620.067 frames]` |
| 10th arm carrying `(list value)` | `recover: dig: over` |
| 10th arm carrying no `value` | compiles |
| widening an EXISTING arm | compiles |

The limit is adding a **cycle member**, not arm count. If R2.7.4 wants to put
anything value-shaped into the mold, widen an existing arm. Probe in isolation
with `-build-file` on a scratch lib BEFORE touching real code — dojo-typed
molds do not reproduce the bug.

## How to verify it

**The register store and the RNG can change a spec's state graph; coverage
counts cannot.** That asymmetry decides the test shape:

- For coverage, comparing statistics is enough.
- For `TLCSet` and `Randomization`, use the shape `tlcget-level` established in
  R2.6.1: **build the state graph out of the value** (`Next == x' = x +
  TLCGet("level")`), so a wrong value yields a different graph and the
  differential cannot pass by accident.

Corpus locations: `desk/test-data/mc/<case>/{spec.tla,spec-cfg.txt}` regenerated
by `tools/gen-mc-tests.py`; `desk/test-data/eval-core/` by
`gen-core-eval-tests.py` (which carries a `SKIPS` table — `tlc-coverage` is
listed in `gen-safety-tests`'s coverage case).

## Sequencing suggestion

Do it as separately verifiable steps, the way R2.7.2's two-step split worked:

1. Thread the carrier through `eval`'s return with every consumer defaulted to
   "no change" — all shards green, no behavior difference. This is the risky
   mechanical step and it should be provable on its own.
2. Land coverage on it.
3. Land the register store (`TLCSet`, `TLCGetOrDefault`, `TLCGetAndSet`), with
   the graph-shaped differential.
4. Land `Randomization`/`RandomElement`, same differential shape, `-fp 0`.

Each step closes something and can be abandoned without leaving the tree broken.

## Standing rules that keep paying

- **Open by measuring the row's own claim.** In this session R2.5, R2.6.0,
  R2.6.1, R2.6.2, R2.7.1 and R2.7.3 each found their row's stated premise wrong
  or incomplete. R2.7.4's row is the one that has already been re-sized twice.
- **A plausible wrong answer is worse than a refusal**, and unlike a refusal a
  caller cannot detect it. This is why R2.6.2 shipped nothing.
- **Write the corpus case and run it.** Every defect this session that reading
  missed was caught that way — the invariant-path statistics, the `body-modules`
  gate, `+num-value` truncation, the two-line 2244 template, the `SetCupValue`
  over-report.
