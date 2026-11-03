# R4.P5c: identity key, implemented (2026-10-12)

**Status: DONE.** Approved at the R4.P close (plan r14, decision 1),
implementing R4.P5b's proposal with one correction.

## The correction: `+ekey`, not the normalized value

R4.P5b proposed `sham(jam(normalized state))`. That is unsound:
`+normalize` keeps intervals (`%intv`), set classes (`cls`) and tuples
(`%seq`) as built, so `1..3` and `{1, 2, 3}`, or `<<1, 2>>` and
`[i \in 1..2 |-> i]`, would get different keys and be counted as two
states where FP64 (and tlc2) count one. The R4.P4 equality key `+ekey` is
canonical (equal values give identical nouns, whatever the representation),
so the key is `sham` of the per-variable `+ekey` list, `~` for a missing
binding.

## What changed

- `lib/fingerprint`: `+state-key`, `+view-key`.
- `lib/check`:
  - `bfs-opts.hkey` (`_|`). When set, `+register-in` keys `seen` on the
    identity key (`+state-id`; under a VIEW, `+view-key` of the view value),
    and `+bfs-step` skips the per-state reseed.
  - `+draws`: static and conservative. A drawing operator (TLC
    `RandomElement`; Randomization `RandomSubset`, `RandomSetOfSubsets`,
    `TestRandomSetOfSubsets`) is in scope, and its name or base name appears
    as an atom in another definition's body. A false positive only keeps
    FP64.
  - `hkey` is set for the safety searches (console `+check` safety passes,
    `+explore-cursor`'s helper) as `!(draws defs)`. It is never set for a
    temporal graph build or the graph export.
  - `+dfid-fp` uses the key always: DFID has no reseed, no symmetry, no VIEW
    and no graph.
- `lib/job`: the `%bfs` safety opts take `!(draws defs)`; the `%live` build
  passes `|`.
- Ledger: new row `tlc-fp-identity` (approved-difference, the collision
  semantics); compatibility.md support matrix. 136 rows, 1 owed.

Not changed: `+edge-action-label`/`+edge-action` compare FP64 of a trace
state with its candidate successors. That is self-contained (both sides
recomputed), once per trace step.

## Tests

- `tests/lib/neval-fp` `test-key-agrees-fp`: for 19 pairs (intervals vs
  enumerations, tuples vs functions, records vs functions, `<<>>` vs `{}`,
  SUBSET, `\X`, function sets, filters, plus unequal pairs) key equality
  equals FP64-input equality.
- `tests/lib/neval-mc` `test-draws-static`: TLC with and without
  `RandomElement`, Randomization with and without `RandomSubset`.
- Regression: 51 shards green on the final code (neval-fp 13, neval-mc 9,
  fp 15, mc 107, dfid 23, symmetry 3, job 130, app 44, blackbox 40,
  safety-gen 10, perf 7, sim-diff 82, generate-diff 30, liveness-* 58,
  coverage, inv-constraints, regprop, stdops, tlcmod, rng, mp 192, …).
  `check-parity.py` and `check-portmap.py` pass.

## Measured

GameOfLife through the runner, `--wall 300`, load about 2.3: **34,048 →
59,136 distinct (×1.74)**, peak RSS 457 MB. The run is still registering
its 65,536 initial states at 300 s (depth 1), so this is the
identity-plus-invariant path, where the key matters most; expansion is
dominated by R4.P11's per-reference function rebuild.
