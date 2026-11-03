# R4.0b: the classifier repaired, and proven to bite

```text
Sub-unit: R4.0b
Rows: none (tools + generated tier-2 artifacts)
Planned: fix the four classifier defects; one fixture per defect that fails
  under the old rule; re-derive every count (L2).
Found: the same `module_refs` also chooses the test-model SANY batches. The
  fix therefore ADDS 20 flat and 20 subdir specs that have never been compared,
  and DROPS one (`bcastByz`, which multi-line-EXTENDS `Functions`).
```

## 1. The four repairs (`tools/gen-tier2-tests.py`)

1. **Comments and multi-line EXTENDS.** `strip_comments` handles `(* *)` with
   nesting and `\*` to end of line, and keeps string literals verbatim. The
   EXTENDS regex now takes an identifier list across newlines. The old
   `^\s*EXTENDS\s+(.+)$` took the rest of one line, comments included.
2. **Nested modules.** Every `---- MODULE X ----` after the first one is
   inner, and inner names are removed from the refs.
3. **Transitive closure.** `ext_closure(root, byname)` follows refs through
   every local module and returns the non-local set. `classify` now judges
   that set, not the root module's own refs.
   - Examples resolve against the spec's own directory, as CI's classpath
     does.
   - test-model resolves against the spec's directory and then the flat root,
     the same order `closure_of` already used.
4. **Every manifest mode.**
   - `manifest_mode` unwraps `{"simulate": {...}}`.
   - Any mode other than `symbolic` is a TLC model.
   - A `symbolic`-only module is `sany:symbolic`.
   - A `proof` module is no longer excluded outright. It is classified like
     any other module and gets detail `proof` when it lands in `sany`. Today
     every proof module needs `TLAPS`, so it is `excluded:module` until R4.1a.
   - Only the `pluscal` feature excludes a module. `action composition` no
     longer does.

## 2. Bite fixtures (`tools/test-tier2-classify.py`)

The old rule is kept verbatim in the test file, so each fixture proves
something was broken. `tools/tier2.py` runs the fixtures before it
regenerates.

| fixture | new | old | want |
|---|---|---|---|
| 1 comments + multi-line EXTENDS | check | excluded | check |
| 1b multi-line EXTENDS alone (`Functions` on line 2) | excluded | check | excluded |
| 2 nested module | check | excluded | check |
| 3 local closure (`MCSpec` → `Spec` → `Functions`) | excluded | sany | excluded |
| 4 `simulate` is a model | check | sany | check |

All five bite.

## 3. Inventory, re-derived

**Examples (408 modules):**

| class | count |
|---|---|
| `check` | 98 (was 36) |
| `excluded:module` | 123 |
| `sany` | 110 |
| `sany:symbolic` | 40 |
| `sany:check-excluded` | 2 |
| `excluded:pluscal` | 35 |

98 and 123 reproduce the R4 census exactly.

**test-model:**

| class | count |
|---|---|
| `check` | 290 (was 211) |
| `excluded:module` | 30 |
| `sany` | 166 |
| `sany:check-excluded` | 35 |
| `excluded:pluscal` | 86 |

## 4. The batch selection moved

`sany_batch_modules` and `sany_subdir_specs` both classify through the repaired
rule.

**Flat batch: 142 → 162 (+20).** Added:
- `CyclicRedefine`, `CyclicRedefineInstance`, `CyclicRedefineVars`
- `Github1161`, `Github297`, `Github429`
- `Github687`, `Github687fifo`, `Github687spec`
- `Github702`, `Github725`, `Github725b`, `Github725c`, `Github725e`,
  `Github725f`, `Github725g`
- `Github817`, `MonolithSpec`, `NoFairnessButLiveProp`, `UndeclaredRecursion`

**Subdir batch: 310 → 329 (+20 −1).** Added:
- `EWD998/EWD998_TTrace`, `cdot/ActionCompositionDistributive`,
  `coverage/Github314`, `debug/Debug04`
- five `SpecifyingSystems` `WriteThroughCache` variants
- `examples/aba-asyn-byz`, `examples/bcastFolklore`, `examples/braf`
- `sany/Github723`
- `suite/test55`, `test56`, `test56a`, `test57`, `test57a`, `test59`,
  `test59a`

Dropped: `examples/bcastByz/bcastByz`. Its EXTENDS continues onto two more
lines and names `Functions`, which Java cannot find. The closure of every spec
already in both batches is unchanged, as measured.

**These 40 have never been compared.** The generator writes "162/162 agree"
and "329/329 agree" because the frozen census lists are empty. Those numbers
are a prediction until the ship runs `tier2` and `tier2-sub`.

Embedding cost: the subdir shard grows from 1 338 723 to 1 450 527 bytes.

## 5. Selector

`tier2-select.py` reads the inventory, so it inherits the repair. Its
Examples `check` pool is 92: the 98 minus the 6 already run through the
checker. `instance` is now an unexercised feature, because the `MC*` wrappers
have become `check`.

## Ran

- `tools/test-tier2-classify.py`: all bite.
- `tools/tier2.py`: regenerated in 3 m 40 s. The drift it reports is the
  intended one: `divergences.txt` and both shards.
- Deployed to the ship (commit 211, built clean). The pier also took
  `gen/tla-lus/{cancel,status,submit}.hoon` from `9a9fe79d`, which had never
  been deployed.

## 6. Ship run: `tests/lib/tier2`, 2026-10-08 — 18 of the 20 new flat specs diverge

`test-sany-batch` took 450 s and FAILED. All 18 diverging specs are rejected
by Hoon and accepted by Java. **Every one is a multi-module file**, which is
exactly the shape the old classifier hid: it counted the extra module names as
unresolved.
- `Github429` and `Github725e` agree.
- The rest of the shard is green: the curated sany and tlc arms, and the tlc,
  liveness and examples batches.

The 18 split into two groups:
- **15 carry a TRAILING module after the root's `====`.** At the pin, when a
  referenced module has no file, SANY extracts it from the ROOT file
  (`ParseUnit.java:401` -> `MonolithSpecExtractor.module`). The port resolves
  nested modules and separate files only.
- **3 (`Github725b`, `Github725f`, `Github687spec`) have only a NESTED
  module.** `lib/modules` registers nested modules, so their cause is
  UNMEASURED. They are R4.1c's first job.

**Ledger: `tlc-monolith` RE-OPENED, `excluded` -> `absent`.** Its R1.0
premise was that no headless input path produces a monolith. That is false: a
monolith is a source TEXT, and an `%inline` root or a `%clay` root file can
each carry one. The Examples corpus has one too:
`braf/BufferedRandomAccessFile.tla`, with a model. The ledger now stands at
**134 rows, 133 terminal, 1 owed**. Present-tense claims were updated in
`README.md`, `api.md`, `compatibility.md` and the ledger header.

The 18 are frozen in `SANY_BATCH_DIVERGENCES` with reasons, so the shard can
be green while the divergence stays explicit (L4/L7).

## 7. Ship run: `tests/lib/tier2-sub` — 5 of the 20 new subdir specs diverge

| spec | port | cause | row |
|---|---|---|---|
| `examples/braf/BufferedRandomAccessFile` | reject | trailing modules | `tlc-monolith` |
| `EWD998/EWD998_TTrace` | reject | trailing modules | `tlc-monolith` |
| `cdot/ActionCompositionDistributive` | reject | trailing modules | `tlc-monolith` |
| `suite/test59` | reject | **INSTANCE inside LET** (its comment said "INSTANCE inside LET", which is why the old classifier hid it) | `semantic-graph` |
| `sany/Github723` | **accept** (WRONG) | an implicit INSTANCE substitution of `CONSTANT C(_)` by the importer's `C(x, y)`, which has arity 2; SANY: `An operator must be substituted for symbol 'C', and it must have arity 1.` | `semantic-graph` |

Each arm took about 4–5 minutes; the whole shard took about 29 minutes.

**Ledger, after R4.0b:** `semantic-graph` was DEMOTED from `parity` to
`partial`, with `test59`, `Github723` and the 3 unmeasured nested rejects.
`tlc-monolith` was re-opened with 18 specs: 15 flat and 3 subdir. After
R4.0f's new row the ledger is 135 rows, 3 owed. Both censuses are frozen
with reasons, and `tier2.py` was regenerated.

Claims retired: `testing.md` §Subdir batch and §Tier-2 close-out, which now
read 468/491, and `tier2.py`'s summary.

**Not re-run yet:** `tier2` and `tier2-sub` against the frozen censuses. The
census entries were copied from the ship's own output, in the arms' own
order. The confirming run is the R4.0 checkpoint's full suite.

## Status

DONE: the four repairs and their bite fixtures; the inventory reports 98;
the 23 divergences are frozen; the ledger is updated.
