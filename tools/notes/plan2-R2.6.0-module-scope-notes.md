# R2.6.0 — module surfaces: which of the excluded are in R2 scope

R2.6's parent row calls its work "the in-scope slice of the 78 excluded
operator surfaces", and R2.6.1/.2/.3 name that slice by hand. This sub-unit
re-derives it against `tools/gen-stdops-tests.py`, which already classifies all
131 reachable surfaces and fails on anything unclassified.

**The hand-written split was wrong three ways, and the slice is eleven surfaces,
not "a slice of 78".**

## The measurement

The generator now emits an `r2-scope` column beside `class`, and treats a
missing verdict in EITHER column as a failure. Over all 131 surfaces:

| verdict | n | meaning |
|---|---|---|
| `in:` | 49 | already ported (`class` = required 47 / body 2) |
| `n/a:` | 20 | no TLA+ declaration binds the method — not a scope decision |
| `out:` | 48 | stays out, reason in the column |
| `R2.6.1` | 2 | `TLCExt!TLCGetOrDefault`, `TLCExt!TLCGetAndSet` |
| `R2.6.2` | 4 | `Randomization!{RandomSubset, RandomSetOfSubsets, TestRandomSetOfSubsets}`, `TLC!RandomElement` |
| `R2.6.3` | 5 | `TLCExt!{AssertEq, AssertError, TLCDefer, TLCCache, TLCNoOp}` |
| `later:` | 3 | in scope for the port, no R2 sub-unit owns them |

**The gate was tested rather than assumed.** Deleting one entry
(`("TLCExt", "TLCNoOp")`) makes the generator print
`UNCLASSIFIED[r2-scope] TLCExt!TLCNoOp/1` and return 1. Restored, and the
inventory regenerates byte-identically across consecutive runs.

## Correction 1 — `TLCGet`/`TLCSet` are not among the 78

R2.6.1 is grounded on `tlc-module-tlc` **and** `tlc-module-excluded`. The second
is wrong: both operators are `class=required` in the inventory, with
per-operator `CLASSIFY` entries written at C1.5/C1.6. They were never excluded;
what they are is *unimplemented*, which is a different row. R2.6.1 moves
`tlc-module-tlc` only.

## Correction 2 — `Randomization` is `deferred`, and its condition is discharged

Not `excluded` either. Its three surfaces plus `TLC!RandomElement` carry
`class=deferred` with the rationale **"TLC RandomGenerator parity is unit 9"**.
Unit 9 is done and `tlc-util-rng` is `parity` — `java.util.Random` is
reproduced, which the R2 plan itself calls "the hard part". So the stated
blocking condition no longer holds and these are simply owed.

The plan names two of them (`RandomSubset`, `RandomSetOfSubsets`). There are
**four**: `TestRandomSetOfSubsets` (which has no Java override — it is TLA+ over
the other two) and `TLC!RandomElement`, which lives in `TLC`, not
`Randomization`, and so falls outside a module-shaped reading of the row.

## Correction 3 — the `TLCExt` split, in both directions

This is the only one of the three sub-units that genuinely draws from the 78,
and the hand-written five-name list is wrong at both ends. The mechanism is
`MODULE_DEFAULT["TLCExt"]`: a *module-level* default that labels all fourteen
surfaces `"debugger/trace-explorer surface"`. Measured per operator against
`TLCExt.java` and `TLCExt.tla`:

- **`AssertEq` has no Java override at all.** Its `java` column is `-`; the
  vendored TLA+ body is `IF a # b THEN /\ PrintT(...) ... ELSE a = b`, over
  `PrintT` and `Assert`, both already `required`. It needs no native operator —
  it is a `body` case, the cheapest possible outcome, and the plan lists it as
  work.
- **`TLCGetOrDefault` and `TLCGetAndSet` are TLCGet-family, not debugger.**
  `tlcGetOrDefault` reads the same per-run register store as `TLCGet` — its own
  comment says *"Partially Copy&Pasted from TLCGetSet.java"* — and
  `TLCGetAndSet` has no Java override, being TLA+ over `TLCGetOrDefault` plus
  `TLCSet`. Both fall out of the per-run mutable slot **R2.6.1** builds. The
  plan leaves them in the half that stays excluded, which would have shipped
  R2.6.1's mechanism and then refused two operators it already supports.
- Genuinely debugger/trace-explorer, and staying out: `CounterExample`,
  `PickSuccessor`, `Trace`, `ToTrace` — each needs a counterexample or an
  interactive choice the evaluator does not hold.
- Recorded `later:` rather than silently dropped: `TLCEvalDefinition` (evaluates
  a definition by name in the current scope), `TLCFP` (a state fingerprint —
  `lib/fingerprint` already computes it) and `TLCModelValue` (interns a model
  value — the port has model values). None needs engine state the port lacks;
  no R2 sub-unit owns them. Saying so is the point: the previous split had no
  place to put "possible but unowned", so such surfaces silently joined the
  excluded pile.

## The "78" is not 78 decisions

**20 of the 78 carry the rationale `unreachable: no TLA+ declaration binds this
method`** — `Integers` 12, `Sequences` 3, and one each of `TransitiveClosure`,
`Strings`, `Randomization!RandomSubsetSet`, `IOUtils!Serialize`, `AnySet!ANY`.
No spec can invoke them, so there is nothing to bring into scope and nothing to
refuse. Counting them as excluded capability overstates the surface by a third.

**The honest policy-excluded count is 58.** Of those 58, R2 takes **7**
(`TLCExt`: 2 to R2.6.1, 5 to R2.6.3); the other 4 in-scope surfaces come from
the `deferred` set, not from the 78 at all.

## What this changes downstream

- R2.6.1's grounding drops `tlc-module-excluded` and gains two `TLCExt`
  surfaces. **Superseded 2026-08-25**: R2.6.1 measured that the register store
  those two share with `TLCSet` needs R2.7.4's return-carrying change, so its
  write half — and both surfaces — were folded into R2.7.4 and their `r2-scope`
  verdicts moved there. That the column had to be edited rather than argued
  with is the point of having it.
- R2.6.2's list grows from 2 named surfaces to 4, and its premise changes from
  "excluded, bring it in" to "deferred on a condition unit 9 discharged".
- R2.6.3 loses `AssertEq` as *work* (it is a `body`) and keeps four.
- The appendix's "deliberately out of R2" list should be read off the
  `r2-scope` column rather than maintained by hand — that column is now the
  machine-checked record, and the generator fails if a surface has no verdict.
