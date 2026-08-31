# R2.7.7.4b — `_POSSIBLE`

The consumer .4a's measurement predicted: predicates tracked at the two
constraint positions, counted into the named register, and checked by generated
postconditions.

## Pinned first

| case | pin |
|---|---|
| temporal-level predicate | `Error: The possible of Temporal is equal to a temporal formula; only state- and action-level predicates are supported` — EC 2230, before any state |
| witnessed | ordinary completion |
| never witnessed | `[Never |-> 0]` (the counts, via `PrintT`) then `Error: Postcondition Never at line 11, col 10 to line 11, col 15 of module spec is false.` |

The last one is the important shape: `_POSSIBLE`'s failure arrives through the
POSTCONDITION machinery R2.7.7.3 built, reporting the **user's** predicate name
and its **body** location — the pin wraps each generated check in a
`PossibleAction` for exactly that.

## What shipped

- `+track-possible` implements `_Possible!_Track` natively rather than through
  the synthetic module `processConfigPossible` generates. It counts the
  predicate's truth and **never prunes** — `_Track` answers TRUE whatever the
  predicate does, which is why the predicates are not simply appended to
  `cons`/`acons`.
- Wired at both positions, keyed on the predicate's LEVEL: state-level into the
  MODEL-constraint position (every discovered state, including a terminal one —
  the pin's stated reason for not routing everything through action
  constraints), action-level into the ACTION-constraint position (every
  transition). Tracked BEFORE the constraint check, since a constraint-pruned
  state was still discovered.
- The counter follows the vendored body: increment when TRUE, and otherwise
  ensure the name is PRESENT at 0 (`old @@ (name :> 0)` keeps an existing
  count), so a never-witnessed predicate ends at 0 rather than absent — which
  is what `_CheckName` tests.
- `+possible-lines` is the generated `_CheckName` postcondition, run after the
  config's own.
- EC **2230** for a temporal-level predicate, in `+ck-keyword-names` — the one
  rejection `_POSSIBLE` has and the other keywords do not.
- `_POSSIBLE` moves `+kw-refused` → `+kw-handled`; the R2.7.7.1 drift guard
  forces the move, and `test-cfg-possible-refused-by-name` became
  `test-cfg-possible-is-handled-not-refused`.

## Evidence

`possible-ok` and `possible-temporal` are **byte-exact**. `possible-never` is
an APPROVED-DIFFERENCE arm: verdict, EC 2404 text, name, location and counts
all match, and the pin prints one extra line above it — `_CheckName`'s body is
`PrintT(counts) /\ FALSE` and this engine has no Print channel. That is the
standing `tlc-module-tlc` difference, not a new one.

**And the corpus target closes.** `SubseteqNextState` — in the tier-2 safety
batch, refused since R2.7.7.1 — now agrees, and for the right reason: its own
postcondition asserts `FullSet = 8` and `GainThree = 16` against counters the
port produces, so the counting semantics are pinned by the pin's own
expectations rather than by a golden I chose. `TLC_BATCH_DIVERGENCES` is empty
again.

## A recovery worth recording

A scripted edit to `lib/config.hoon` spliced the wrong region and destroyed the
`.cfg` PARSER — the text I meant to delete (`?^ possible.a`, in
`+unsupported-kw`) had a near-identical neighbour in the parser
(`?: =(kw '_POSSIBLE')`). The file was restored from `HEAD` — which the user
had committed through R2.7.7.4a, so the loss was exactly this unit's own config
edits — and all six were re-applied deliberately with asserted anchors.

The lesson is narrow and worth keeping: **a positional splice keyed on a
pattern that repeats in the same file is not a safe edit**. Anchor on unique
text, assert it, and check the parser still parses.
