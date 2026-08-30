# R2.7.6.0 — RECURSIVE operators with temporal bodies: measuring the claim

Sub-unit opened by filling the handoff template's first three lines, as the
plan requires. The answer to line three ended the unit.

```text
Sub-unit: R2.7.6.0
Claim being measured (the row's residue text, verbatim):
  "R2.0 re-opens this row (R2.7.6). `Liveness.astToLive` expands RECURSIVE
   operators with temporal bodies during tableau construction and the port
   does not; upstream's `Github1389` is the regression test. Highest-risk of
   the R2.7 set"
Measurement result: STALE.
```

## Why it was stale, and how it got written

The mechanism the claim asks for is in `lib/temporal.hoon` and has been since
**R1.6.1**:

- `+user-op` — `astToLiveAppl` with `opcode == 0`, the user-defined-operator
  branch that translates the BODY in place of the call, gated on level.
- `+ite-of` — `OPCODE_ite`'s constant-guard branch selection, which is
  precisely what makes a recursive expansion terminate.
- `+bind-formals` — formals bound in the CALLER's context, a value when the
  argument evaluates there and the node through `psub` when it does not.
- `+expand-cap` — the bound that stands in for the JVM stack.

This row's own residue tail already said so: *"**R1.6.1 CLOSED the bail and
restored this row**"*, tier-2 liveness batch **3/9 → 7/9**. R2.0 re-opened the
row from the plan's prose. That is the same failure the R2 preamble enumerates
eleven instances of; this is the twelfth, and it cost the release its last
`high`-risk unit.

**The pin is the upstream commit itself.** `4ba7d8811` is *"Allow RECURSIVE
operators to define liveness properties"* — `Liveness.java` +111/-7, seven
`Github1389*` fixture pairs, seven JUnit tests. Both of its mechanisms (the
`getInRecursive()` + `getLevelBound > ActionLevel` expansion gate, and the
`OPCODE_ite` constant-guard short circuit) map onto the two arms above. The
port gates every user operator on the CALL's own level and needs no `recursive`
flag, which `+user-op`'s comment argues is observationally identical — this
unit's evidence is the first RUN-level confirmation of that argument.

## What was measured, and how

Reading is not measuring. All seven fixtures were staged as `mc` cases against
the pinned jar (module renamed to `spec`, comments trimmed to a provenance
line; the goldens are captured from the renamed file, so the line/col spans in
the action labels are the case's own).

Two are excluded upstream-side by the tier-2 inventory as
`check-excluded:TLCExt` and are **not** liveness work — `Github1389Counting`
and `Github1389ViolatedC`, the latter asserting the counter-example's shape
through a `POSTCONDITION` over `TLCExt!CounterExample`. They are R2.7.6.2, and
they depend on R2.7.7.

| case | pin | port |
|---|---|---|
| `gh1389-ok` (3 PROPERTIES: boolean guard, numeric guard 3→0, recursion in THEN) | `Model checking completed. No error has been found.` 3 generated / 2 distinct / depth 2 | **byte-exact** |
| `gh1389-viol` (`Reach(3)` → `<>(x = 99)`) | `Error: Temporal property PropViolated was violated.` + lasso `Back to state 1: <Next line 10, col 9 to line 10, col 18 of module spec>` | **byte-exact** |
| `gh1389-violb` (recursion under `<>`; `Reach(0)` is a level-1 state predicate) | same shape | **byte-exact** |
| `gh1389-loops` (guard FALSE, ELSE re-invokes unchanged) | EC **1005**, the four-line `This was a Java StackOverflowError` template | EC **2213** `TLC cannot handle the temporal formula line 9, col 9 to line 9, col 18 of module spec` |
| `gh1389-guard` (parameter bound to a state variable) | EC **1005**, same template | EC **2213** at `Prop == op(x)` |

Three byte-exact on the first attempt, with no code change in this unit.

## The two divergent cases are ONE difference

Both reach it the same way — an expansion that never reaches a base case — and
both end the same way: **no verdict is produced**. tlc2 inlines until the JVM
stack overflows and `TLC.process` translates that into EC 1005. The port bounds
at `+expand-cap` (1.000 nested expansions), falls through `+user-op`'s `fall`,
and raises EC 2213 at the property's location, because a Hoon runaway is an
uncatchable hang rather than a throwable — the same trade `live-graph-cap`
already makes for the graph build.

Worth stating precisely, because it narrows R2.7.6.1: the port does **not**
emit a dedicated cap diagnostic. The cap is invisible in the output; what a
caller sees is the ordinary "cannot handle the temporal formula" rejection at
the right location. Whether that is the right text is R2.7.6.1's question.

Both goldens are captured and FROZEN with their arms withheld through
`gen-mc-tests.py`'s `SKIPS` map, which prints the reason on every generator
run. **R2.7.6.1 deletes both entries** when it lands the differential and the
support-matrix row.

## One defect the first capture caught

`gh1389-ok` is the corpus's first multi-PROPERTY liveness case, and tlc2 prints
a different line for it: `Checking 3 branches of temporal properties for the
complete state space with 6 total distinct states at (2026-08-29 14:48:03)`.
`DROP` covered the single-property form (`^Checking temporal`) but not this
one, so the first capture froze a **wall-clock timestamp** into the golden — a
test that could never reproduce. `DROP` now covers it; the branch count it
carries is already reported by the `Implied-temporal checking` line, which was
dropped long ago. No other golden moved.

## One residue found in passing, belonging to R2.7.5

`tools/validate.py --check` reported DRIFT on `desk/doc/evidence-counts.md`
after this unit's cases landed — and the drift was **larger than this unit**:
`gen-mc-tests.py` 51 → 57 and `gen-liveness-tests.py` 17 → 18, where this unit
accounts for only +3 (five cases, two withheld; `TOTAL` counts cases minus
skips).

Traced: `evidence-counts.md` was last regenerated at **R2.7.4.6**
(`cf8d734d`), and **R2.7.5** (`df8763fc`) added four `mc` cases and the
`boximplies-viol` liveness case without re-running the generator that produces
it. Its notes list the `-test` shards as evidence and no tier-1 run. The file
is marked `GENERATED ... do not edit`, so nothing else would have caught it
until the next unit ran the gate — which is this unit.

No action beyond regenerating: the counts were understated, never overstated,
and the goldens themselves never drifted.

## Cross-shard breakage the full suite caught, belonging to R2.7.4

The user's full-suite run failed two arms in `tests/lib/stdops` — a shard this
unit did not touch, and neither did the units that broke it.

| arm | cause | fix |
|---|---|---|
| `test-unimplemented-operator-names-itself` | It asserted that `TLC!RandomElement/1` names itself as unsupported. **R2.7.4.4 implemented it**, so the arm read `1` — a drawn value — instead of the rejection. | Re-pointed at **`TLC!JavaTime/0`**, excluded on WALL-CLOCK NONDETERMINISM rather than on effort, so no later capability unit can turn it green the way one turned `RandomElement` green. |
| `test-registry-row-count` | Expected 38, got 37. **R2.7.4.3 moved `TLC!TLCSet` out of `registry` into the node-op table**, because writing the run-scoped register store needs the `rst` carrier a plain `(list value)` row cannot reach. | 37, with the comment recording that this is the counter's **first decrement** — every prior change added. |

Both are hand-written drift guards, which is exactly why they broke silently:
`gen-stdops-tests.py` regenerates `stdops-diff.hoon` and `inventory.txt`, and
both were correct throughout — `RandomElement` and `TLCSet` read `required`
there. The machine-checked record was right and the hand-written one was
stale, so tier 1, the scaffold gate and `check-portmap.py` all stayed green.

**R1.8.8's finding, a second time**: a unit runs the shards it touched, and
that discipline is structurally blind to a shard that asserts something about
code the unit changed. R2.7.4.3/.4 changed `lib/stdops.hoon`'s registry and
`tests/lib/stdops.hoon` asserts its SIZE; nothing links them but the full
suite. `tests/lib/tlcmod.hoon` was updated in the same units, so the miss was
this one shard, not a habit.

No status moves: `tlc-module-tlc` is `approved-difference` and both operators
were already `required` in the inventory. What was wrong was two test
expectations.

## A REGRESSION the full suite caught, and the third defect behind it

The suite also failed `tests/lib/tier2/test-tlc-liveness-batch`:

```text
expected: <|Github710d -> Error: Deadlock reached.|>
actual  : <|Github710e -> Error: Deadlock reached.|>
```

Read carelessly this looks like the stale census R2.7.5 already flagged. It is
not. **710d was retired as R2.7.5 intended, and 710e was newly BROKEN by the
same unit** — the frozen entry was wrong in both directions at once, and only
the full suite could see it, because the census asserts the exact list.

Measured at the pin, both ways:

| run | pin | port before this fix |
|---|---|---|
| `Github710e` as configured (deadlock checking ON) | `Error: Deadlock reached.` and **no temporal block** | deadlock report **plus** `Error: Temporal property VisitsTwoThenStaysSmall was violated.` |
| the same spec with `CHECK_DEADLOCK FALSE` | violation, `State 4: Stuttering`, and the EC 2259 fairness warning | violation, same three prefix states, **no closer and no warning** |

One predicate explains both, in opposite directions: `+box-free-tf`.

**The tf is not the whole obligation.** `VisitsTwoThenStaysSmall ==
<>(x = 1 /\ <>(x = 2)) => <>[](x < 2)` negates to `<>(A /\ <>B) /\ []<>(x >= 2)`,
and the OrderOfSolution decomposition puts the `[]<>` half into a **PEM
condition**, not into `tf`. So the tf is box-free while the witness still needs
an infinite suffix — the port therefore dropped the closer where tlc2 prints
one, and printed the second report block where tlc2 prints none.

`+box-free-tf` now asks whether **a finite prefix discharges everything**: the
tf carries no `[]`, no promise carries one, and every PEM is condition-free —
the same `isEmpty` notion `+stutter-gate`'s `quiet` already used. That flips
exactly the box-free-tf-with-a-live-PEM shape, so none of R2.7.5's six measured
properties move.

**Why one spec's worth of measurement was not enough.** R2.7.5 measured six
property shapes on a single 4-state spec, and not one of them had a box-free tf
*and* a live PEM. The case that does is in the corpus — it was `Github710e`,
inside the very census the unit chose not to regenerate. The deferral and the
defect were the same decision.

Both directions are now pinned as `mc` cases, `gh710e` and `gh710e-nodl`, so
the pair cannot regress quietly. `TLC_LIVENESS_DIVERGENCES` is **empty**: all
nine liveness-batch specs agree. **R2.8.2a's `Github710d` retirement is
therefore discharged here**, ahead of its unit.

## Evidence

`-test /=tla-lus=/tests/lib/mc ~` — **`ok=%.y`**, 57 emitted arms (59 cases,
2 withheld). The three new arms pass; the pre-SKIP run failed exactly the two
cases named above and nothing else, which is what makes the withholding a
measurement rather than a convenience.

## What is left on this row

- **R2.7.6.1** — `+expand-cap` vs EC 1005 as a *tested* approved difference
  (differential + `compatibility.md` support-matrix row), and delete the two
  `SKIPS` entries.
- **R2.7.6.2** — `Github1389Counting` / `ViolatedC`: `POSTCONDITION` +
  `TLCExt!CounterExample`, i.e. R2.7.7, not liveness.

The row stays `partial` until one of those closes it. **It is no longer
high-risk and no longer needs an expansion engine**, which is the result.
