# R2.7.7.0 — the `.cfg` keywords nothing reads

```text
Sub-unit: R2.7.7.0
Claim being measured: "POSTCONDITION, _PERIODIC, _RL_REWARD and _POSSIBLE are
  parsed into `cfg-ast` and read by nothing, while tlc2 acts on all four"
Measurement result: CONFIRMED, and sharpened three ways -- one of which
  corrects this unit's own plan row.
```

## What the port does: nothing, and it says `ok`

`lib/config.hoon` parses all four into `cfg-ast` (`postconditions`, `periodic`,
`rlreward`, `possible`) and no other file in the desk reads any of the fields.
Two `mc` cases make that concrete rather than architectural:

| case | pin | port |
|---|---|---|
| `cfg-post-false` (`Post == TLCGet("distinct") = 999`) | `Error: Postcondition Post at <loc> is false.` + counts | `Model checking completed. No error has been found.` + the same counts |
| `cfg-post-undef` (`POSTCONDITION NoSuchOp`) | counts, then a `RuntimeException`: *the post condition NoSuchOp ... is not defined* | a clean verdict |

**A run reported `ok` where tlc2 reports a failure** — R2's "no option is
accepted and ignored" in the direction that matters. Both goldens are frozen
with their arms withheld; they return with R2.7.7.2 and .3.

## Correction to this unit's own plan row

The parent row said the name check happens *"at spec-processing time, before a
single state is computed"*. **Measured, that is false.** `cfg-post-undef` shows
the pin printing `3 states generated, 2 distinct states found...` FIRST and
only then throwing: `getPostConditionSpecs` resolves the name when the
postconditions are FETCHED, after exploration. So validation and evaluation are
the same trip, and R2.7.7.2's separation from .3 buys ordering and a smaller
first increment — not an earlier failure point. The row is corrected.

## `_RL_REWARD` — the one keyword that was still unmeasured

Its only runtime consumer is `RLSimulationWorker`, and `Simulator.java:136`
selects that worker on `Boolean.getBoolean("tlc2.tool.Simulator.rl")` — a **JVM
system property**, not a CLI flag. An experimental reinforcement-learning hook
inside simulation, well outside a `-workers 1` BFS parity target: the
CAPABILITY is excludable on the same argument as `tlc-distributed`.

**Its validation is not.** `processRLReward` runs for every spec and fails with
three `TLC_CONFIG_*` rejections, so a malformed `_RL_REWARD` aborts a BFS run
at the pin and runs to completion here. The row's verdict splits accordingly —
excluding the keyword whole would have been wrong in exactly the way R1.8.0
warns about.

## `_PERIODIC` and `_RL_REWARD` are not one bucket

`_PERIODIC` is **verdict-affecting**: `ModelChecker.java:718` evaluates it
inside the search loop, between liveness checking and checkpointing, and
returns `EC.TLC_ASSUMPTION_FALSE` when false — the run ENDS. Its validation is
also *two* rejections, not three: no must-not-be-constant check, unlike
postcondition and rlreward. Precise enough to build against.

## `_POSSIBLE` — the corpus already has the case and cannot see it

`SubseteqNextState` is in the tier-2 SAFETY batch and PASSES today, carrying
`_POSSIBLE FullSet GainThree` and a `POSTCONDITION` that reads
`TLCGet("all:named")["s:_possible"][1]`. It agrees only because the
postcondition HOLDS at the pin, so an ignored keyword is invisible to a
verdict+counts comparison. The read side already exists — `all:named` is an
accepted key in `lib/stdops` — and what is missing is the sub-record.

This is why R2.7.7.4 is verified WITH .3: the only corpus case that exercises
either exercises both.

## Rows created

Three, as R2.0 created `cfg-view` and `cfg-alias` for the same reason:
**`cfg-postcondition`**, **`cfg-possible`**, **`cfg-internal-kw`**, all
`absent`. The ledger goes 131 rows / 6 owed → **134 / 9**, and
`compatibility.md`'s quoted tally says why the number went UP, so it does not
read as drift.

**One plan claim retired here**: the parent row asked for an `r2-scope` verdict
per keyword. There is no such column for `.cfg` keywords — `r2-scope` lives in
`desk/test-data/stdops/inventory.txt` and covers the 131 OPERATOR surfaces
only. The ledger row is the machine-checked record for a keyword; the drift
guard that would match `gen-stdops-tests.py`'s (fail on any keyword in
`+kw-set` that is neither consumed nor rejected) belongs with R2.7.7.1, which
is where the rejections land.

## Evidence

`-test /=tla-lus=/tests/lib/mc ~` — 68 arms of 70 cases, the two new ones
withheld with their reasons printed by the generator. `check-parity.py`
well-formed at 134 rows; `check-portmap.py` coherent after the quoted tally was
updated.
