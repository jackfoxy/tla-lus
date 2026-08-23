# P2-R1.9.0 — port-map ↔ ledger coherence

The row said: *"Regenerate `port-map.md` from the ledger. It is currently
hand-appended per increment; the release gate wants it derived, so the two
cannot drift."*

**Measured, the premise is wrong, and this is the eleventh time in R1.** The two
documents are not two views of one table; they are orthogonal projections, and
neither can generate the other:

| | keyed by | answers |
|---|---|---|
| `parity-manifest.md` | Java cluster (125 rows) | *is this at parity, and on what evidence* |
| `port-map.md` §7 | unit / increment (~190 rows) | *what happened, when, and why* |

Nothing in the ledger records that a residue statement was false, that a
measurement cancelled four planned units, or that a gate had been red for nine
increments. Nothing in the progress log tells you whether `tlc-enum` is at
parity. Deriving either from the other would delete the thing that makes it
worth keeping.

So the deliverable is not a generator. It is: **find what actually drifts, fix
it, and make it machine-checked.**

## What was drifting

Thirteen dead file references, on both sides.

**port-map §4–§5 — eleven planned owners that no file ever took.** The section's
own preamble admitted it: *"Hoon owner names refer to the **planned**
`lib/*.hoon` split."* That was true at unit 0 and never corrected. Named but
nonexistent: `levels`, `lint`, `stdlib`, `cfg`, `safety`, `state`, `trace`,
`simulate`, and the three `pcal-*`. Each is now the file that actually owns the
behavior, measured against the tree — e.g. level checking and linting both live
in `semantic.hoon`, the BFS queue in `check.hoon`, the fingerprint set in
`fingerprint.hoon`, and the three `pcal-*` become `—` because PlusCal is
excluded.

**The ledger — two rows naming files that do not exist.**

- `tlc-safety-stategen` named `lib/state`; the `state` mold is
  `node-eval.hoon:34`, a file the same cell already named.
- `op-gall-version` named *"`lib/migrate` frozen molds"* — and `lib/migrate` was
  **deleted by R1.5.12b**, the same deletion that left `scaffold-gate.sh` gate 6
  red for nine units (R1.8.8). One removal, three documents left stale, found by
  two different close-outs. The frozen molds are now `app/tla-lus`'s
  `versioned-state`.

## What the checker enforces

`tools/check-portmap.py`, wired in as **scaffold-gate gate 10** (the ledger
well-formedness check becomes gate 11):

1. every `*.hoon` either document names as an owner exists;
2. the pinned oracle commit is identical across port-map §1, `scaffold-gate.sh`
   and `validate.py`;
3. every `unit` the ledger cites is findable in port-map;
4. any tally quoted in prose equals what `check-parity.py` computes.

The progress log is deliberately **out** of check 1: it quotes historical names
on purpose, because a deleted file is part of what happened.

## It found one on its first run

Check 3 failed immediately: the ledger attributes ten rows to unit **`6C`**,
which port-map never mentions — it records that work as `P2-C1.0` … `P2-C1.8`.
Both names are right (PLAN-2 Phase C step C1 *is* Work Unit 6 family 4), but
nothing connected them, so a reader holding `tlc-module-naturals` and its
`unit: 6C` had no way to find the increment that did it. port-map §4 now carries
the mapping table, and the check makes a new unmapped name impossible.

That is the argument for the whole unit in one line: the drift that matters is
never the drift you set out to fix.
