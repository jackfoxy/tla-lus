# R1.8.1 — SPECIFICATION-form decomposition — measurement notes

Parent plan: `~/FoxyLabs/tla-lus/R1.8.1-spec-decomposition-plan.md` (.0–.4, plus .3b).
Oracle pin: `tlaplus@4ba7d8811`.

## R1.8.1.0 — kickoff (docs/oracle only)

### The recorded uncatchable crash does NOT reproduce

`tools/gen-tier2-tests.py:296` records why the tier-2 **liveness batch** stayed deferred:

> a per-state value-core EVAL blowup hard-bails `check:check` (uncatchable by `mule`) on some
> SPECIFICATION-form / multi-PROPERTY specs, aborting the arm.

The plan made reproducing this `.0`'s first job, on the grounds that a crash must not be
mistaken for a parity bug later. **It is gone.** A scratch probe ran all seven SPECIFICATION-form
liveness cases through `check:check` on the ship: **0 CRASHED, all seven returned a verdict.**

Attribution is likely but not proven. R1.3.8 fixed a hard bail of exactly this class — a dropped
`$CartesianProd` node left `+bi-in` doing `(snag 1 as)` on a shortened argument list, an uncaught
bail `mule` cannot catch. R1.5.5's `build-graph-cap` / `live-graph-cap` is the other candidate.
Distinguishing them would mean reverting one, which is not worth the cycle; what matters for the
plan is that **`.4`'s "re-enable the liveness batch" is no longer blocked on a crash**, only on
the decomposition itself.

### The decomposition table, frozen

Every SPECIFICATION-form liveness case, oracle verdict vs the port today:

| case | SPEC's fairness conjunct | oracle | port | agrees |
|---|---|---|---|---|
| `back-to-state` | — | `violated-property` | violated | ✅ |
| `sf-absent-viol` | — | `violated-property` | violated | ✅ |
| `wf-viol` | `WF_x(A)` | `violated-property` | violated | ✅ |
| `wf-pass` | `WF_x(Inc)` | **ok** | violated | ❌ |
| `sf-pass` | `WF_x(Ay) /\ WF_x(By) /\ SF_x(Cy)` | **ok** | violated | ❌ |
| `spec-fairness-pass` | `Fairness` → `WF_x(Inc)` | **ok** | violated | ❌ |
| `leadsto-pass` | `WF_x(Go)` | **ok** | violated | ❌ |

**4 of 7 diverge, all in one direction**: the port reports a temporal violation for every case
whose SPEC carries fairness. That is the exact signature of fairness never being extracted —
without it, every liveness property has a stuttering counterexample, so "violated" is what you
always get. The three agreements are agreements *by luck*: those cases are violations anyway.

The port's message is identical in all seven (`Error: Temporal property Live was violated.`), so
the verdict is not being computed from the fairness at all.

### One requirement the plan did not state

`spec-fairness-pass` puts the fairness behind a **named definition**:

```
Fairness == WF_x(Inc)
Spec == Init /\ [][Next]_x /\ Fairness
```

So `processConfigSpec` extraction must **resolve definitions**, not pattern-match `WF_`/`SF_` at
the conjunct level. `sf-pass` adds the other axis — several fairness conjuncts in one SPEC,
mixing `WF_` and `SF_`. Between them these two cases pin the shape `.1` has to handle.

### Consequences for the plan

- `.0`'s crash-reproduction task is **discharged**: nothing to characterize, and `.4` loses its
  stated blocker.
- `.1`'s fairness extraction must resolve through definitions; add that to its scope.
- The four `-pass` cases are `.3`'s acceptance set — they are already in the corpus with oracle
  verdicts, so no new fixtures are needed for the fairness half.

## R1.8.1.1 — the decomposition

### The fairness half was a DISCARD, not a missing feature

`.0` concluded the port "never extracts fairness". That was the right reading of the symptom and
the wrong reading of the cause. Tracing it:

- `+decompose-spec` (`check.hoon`) already ports `processConfigSpec` — it walks the SPECIFICATION
  conjuncts depth-first, expands arity-0 user operators (so `Fairness == WF_x(Inc)` is resolved,
  the requirement `.0` flagged), and routes level-3 conjuncts to `fair`.
- `+resolve-targets` returns that `fair`, and `+search-ctx` feeds it to `+build-live-oss`, which
  calls `normalize:temporal`. The resulting OrderOfSolutions is carried in `sctx.oss`.

So the fairness reached the engine. Then `check:check` **rebuilt the OrderOfSolutions from
scratch**:

```
=/  osr  (oss-of ~[u.psb] ~ (make-env:ne defs.c consts.c vars.c))
                          ^ fairness passed as ~
```

and rendered from `p.osr`, discarding `sctx.oss` entirely. Every `WF_`/`SF_` the SPEC declared
was dropped at that one call, so a fair spec still had a stuttering counterexample and **every**
liveness property came back violated.

`+live-verdict-lines` — the differential entry — used `oss.c` and got the same specs right.
That is precisely why the `liveness-verdict` shard was green while production was wrong, and why
`leadsto-pass` was recorded as "matches in the differential but production-deferred on
SPECIFICATION-form config". The deferral was this line.

### Result

The fix is to use the `oss` `search-ctx` already built. All seven SPECIFICATION-form cases now
match the pin:

| case | oracle | port before | port after |
|---|---|---|---|
| `back-to-state` | violated | violated | violated ✅ |
| `sf-absent-viol` | violated | violated | violated ✅ |
| `wf-viol` | violated | violated | violated ✅ |
| `wf-pass` | ok | **violated** | ok ✅ |
| `sf-pass` | ok | **violated** | ok ✅ |
| `spec-fairness-pass` | ok | **violated** | ok ✅ |
| `leadsto-pass` | ok | **violated** | ok ✅ |

**4 divergences → 0.** Worth noting for the remaining increments: no new decomposition machinery
was needed for fairness. `.1`'s remaining scope is the PROPERTY routing — implied-init and
implied-action — which is genuinely absent, not merely disconnected.

### PROPERTY routing — the other half of `.1`

`.0` and the fairness fix left the four-way routing of `processConfigProps` still to build. Two
of the four destinations were absent; measured at the pin first:

| shape | pin | port before |
|---|---|---|
| `[]P`, P state-level | box invariant | already routed (8.9) |
| level-1 predicate | `Error: Property X is violated by the initial state:` + the state, **no counts** | `Temporal property X was violated.` + a stuttering trace |
| `[][A]_v` | `Error: Action property X is violated.` + the behavior + counts | **CRASHED** (uncaught bail) |
| anything else | temporal | already routed |

**The `[][A]_v` crash was in `search-ctx`, not in the checker.** Such a property was being handed
to `normalize:temporal`, which bails on it — so the routing had to happen at **oss-build time**,
not merely where the result is rendered. That is the second uncatchable bail this unit has
cleared (the first being `.0`'s, already gone).

**The plan's trace shape was wrong.** It says the implied-action diagnostic carries "the two-state
trace" (from `ModelChecker.java:533-545`). Measured, the console prints the **whole behavior** up
to and including the offending step, then the ordinary counts. Whatever the internal
representation, the output is a full numbered trace with per-action labels.

**An implied init that HOLDS falls through to the ordinary safety run** — tlc2 checks it while
computing initial states and, if it passes, carries on with the model check. `+safety-run` was
factored out of `check:check` so both entries share one implementation instead of duplicating it.

New arms: `+implied-action-inner` (the shape test), `+implied-init-run`, `+implied-action-run`,
and `+first-bad-step`, which scans the built graph for the first transition breaking A and
reconstructs the behavior from `+trace-to` plus the offending successor — reusing `build-graph`,
`trace-to` and `render-trace` rather than adding a parallel search.

All three shapes are byte-exact against the pin, including the `State 1..5` numbering, the
`<Next line 5, col 9 to line 5, col 24 of module A>` action labels, and the counts.

Because the checks landed with the routing, `.2`'s scope is now largely *verification* — the
EC 2112/2113 diagnostics it describes are implemented; what it still owes is the corpus fixtures
and the `SafetyDump` differential that pin them.

## R1.8.1.2 — checking implied inits + actions

`.1` landed the checks together with the routing, so this increment's job was to **pin them**
and to close the gap the fixtures exposed.

### The fixtures found a diagnostic the port did not emit

Four cases added to the `mc` corpus — `implied-init-viol`, `implied-init-pass`,
`implied-act-viol`, `implied-act-pass` — which compares `check:check`'s console output against
tlc2's byte for byte. Capturing the goldens surfaced something my hand-run measurements had
filtered away: tlc2 emits a **warning before the verdict** whenever a PROPERTY is state-level:

```
Warning: The formula ImpInit is a state-level formula, but it was used as a PROPERTY (or
PROPERTIES), where a temporal formula is typically expected. …
See https://explain.tlapl.us/invariants-and-properties for additional details.
```

That is **EC 2255** `TLC_LIVE_FORMULA_STATE_LEVEL` (`MP.java:1035`), and it appears whether the
property holds or is violated. The port had no coverage of it — my earlier probes had grepped
it out of the oracle output, which is exactly the sort of thing a committed golden catches and
an ad-hoc measurement does not. Now emitted inline, following the same pattern as the existing
2279 symmetry warning.

### Result

**11/11 `mc` cases green**, including all four new ones, byte-exact:

| case | shape |
|---|---|
| `implied-init-viol` | 2255 warning, then `Property X is violated by the initial state:` + state, **no counts** |
| `implied-init-pass` | 2255 warning, then the ordinary safety completion + counts |
| `implied-act-viol` | `Action property X is violated.` + full numbered behavior + counts |
| `implied-act-pass` | ordinary safety completion + counts |

### On EC 2112/2113

The plan names these as the implied-action codes to carry. Measured, tlc2's **console** output
carries no `EC` prefix on these lines — the codes are internal, the same way EC 2110 is for an
invariant violation, which the port already renders as bare text. The mc differential pins the
rendered text, which is what a user sees; wiring the numeric codes matters only where the port
exposes them (the MP layer), and `gen-mp-tests` does not currently reach 2112/2113/2255.
Extending the MP corpus to cover them belongs with `.3b`'s diagnostic sweep, not here.

### Note for the close-out

`gen-mc-tests.py` went 7 → **11** cases, so `evidence-counts.md` needs regenerating at `.4`
(`validate.py` will flag the drift).

## R1.8.1.3 — fairness + property gates

### The differential had been hiding two of them

`gen-mc-tests.py`'s DROP filter contained `^Warning: The stuttering`, so the mc goldens had
never carried EC 2257/2259 at all. Removing that filter did two things: it let the new fixtures
pin the gates, and it revealed that **`live-box` — an existing case — had been silently missing
the 2257 warning all along**. A filter added to make a differential pass is a differential that
stops measuring; this one hid a real divergence in a case that read as green.

### The gates, measured

| EC | fires when | text |
|---|---|---|
| **2257** | stuttering counterexample, config is INIT/NEXT (no SPECIFICATION) | `…may be caused by the absence of a behavior specification (SPECIFICATION). Only INIT and NEXT have been provided…` |
| **2259** | stuttering counterexample, SPECIFICATION present but carries no fairness | `…absence of a fairness constraint in the behavior specification Spec defined at line 6, col 1 to line 6, col 26 of module spec…` |
| **2237** | a SPECIFICATION conjunct is constantly FALSE | `The spec is trivially false because Falsy is false.` |

Two details a naive reading would miss:

**The stuttering hint is conditional on the PEM, not just on stuttering.** tlc2 guards it with
`!oos.hasEmptyPEMAndBoxFreePromises()` (`LiveWorker.java:997`). My first probe used
`Live == <>(x = 1)`, whose PEMs are empty, and printed no hint — which is why the gates looked
like they did not exist. `[]<>(x = 1)` shows them. My first implementation then tested whether
the PEM *list* was empty rather than whether *each PEM* is empty
(`PossibleErrorModel.isEmpty` = no `<>[]A`, no `[]<>S`, no `[]<>A`), which over-fired on
`live-diamond`. New `+has-box:temporal` supplies the box-in-promise half of the predicate.

**2259 names the SPEC's source location**, so `sctx` gained `sname`/`sloc` and a `+locn-tape`
renderer for the bare `line L, col C to line L, col C of module M` form.

2237 is detected during decomposition, naming the conjunct **as written** — the operator name
for `Falsy == FALSE`, the literal for an inline `FALSE`.

### Result

**14/14 mc cases green**, including `gate-no-spec`, `gate-no-fair`, `gate-trivial` and the
corrected `live-box`.

### Known gap, stated rather than hidden

The **job kernel's** liveness path (`job.hoon`, sliced continuation) passes `~` for the gate: it
does not carry the SPEC name/fairness needed to compute it, so its report omits the 2257/2259
hint that the console path emits. Recorded here and in the code rather than papered over.

## R1.8.1.3b — `cfg-validate`'s remaining diagnostic codes

### The blocker the plan named was real, and one line wide

EC 2146's two message variants are selected by `!def.getBody().levelParams.isEmpty()`
(`SpecProcessor.java:1021`), and `sem-def` carries `lvl` but not `lp`. The `lp` set is
computed — `oplev.lp`, already oracle-verified through the `LEVELS` projection's `lp` segment —
and then **thrown away**: `+level-module` returns `m:(l-module-core …)` and drops the `ops` map
the core also returns. `sem-module` gained `lpe=(map @t ?)` (per-definition levelParams
emptiness) filled from exactly that map. `OpDefNode.levelCheck` adds the body's levelParams and
then removes the formals (`OpDefNode.java:1123`), so for the arity-0 operator an INVARIANT must
be, the definition's set *is* the body's.

### What the codes actually needed was not a check, it was a table

Six of the seven codes turned out to be one missing structure rather than six missing tests.
`SpecProcessor.processConfig` never looks at the semantic graph: it looks up `this.defns`, the
name→Object table `processSpec` assembled beforehand, and dispatches on `instanceof OpDefNode` /
`== null` / a value. The port's `+validate-config` had been reading `defs.m`/`consts.m` directly,
which cannot express the states that produce these diagnostics — a config `CONSTANT Inv = 42`
**replaces** the operator `Inv` in the table (2230), and a declared CONSTANT covered only by an
override resolves to *null* until the override loop runs (2229 vs 2224). New `+build-defns`
reproduces the table in the Java's order, emitting on the way: 2242 (`makeConstantTable`),
2222, 2242 again for the per-module tables, 2223/2224/2225 (the `<-` loops, constants before
operator definitions), 2226, then `processConstantDefns`' 2225/2281. `+validate-config` is now
just `processConfig` over that table.

### Two pre-existing divergences the corpus had never touched

`TLC_CONFIG_ID_REQUIRES_NO_ARG` (2228) has a **one-parameter** variant and a two-parameter one,
and `MP` picks between them by `parameters.length`. INVARIANT/INIT/NEXT pass a role and get
`TLC requires invariant not to take any argument, but one was given: Op`; **SPECIFICATION and
PROPERTY pass only the name** (`SpecProcessor.java:799/823`) and get `TLC requires Op not to
take any argument.` The port emitted the two-parameter form for all four. Also measured: an
INVARIANT resolving to the boolean **TRUE** is not 2230 at all — it is warning 2149 and the run
proceeds. Both were invisible because no corpus case covered them; both now have one
(`val-spec-arg`, `val-prop-arg`, `val-inv-const-true`).

### EC 2281 is a message about an exception, not about a level

`Assert.fail(TLC_CONFIG_SUBSTITUTION_NON_CONSTANT, …)` fires only when *evaluating* the
substituting definition throws **and** the body's level bound is above constant, and its third
parameter is that exception's own message. Probing five body shapes at the pin, the throw is
always EC 2280 `TLC_CONFIG_UNDEFINED_OR_NO_OPERATOR` naming the first state variable the body
reads, with the identifier's `Location.toString()` on the next line — so `+nonconst-ref` walks
the body in evaluation order (a bound range before the body it binds, descending into an applied
user operator) and names that reference. One asymmetry had to be measured rather than assumed:
under `ENABLED` a **primed** variable is assignable and does not fail, so `V == ENABLED (x' = x)`
reports the *unprimed* `x` at col 20, not the primed one at col 15.

### Result

**27/27 cfg-val cases green** (13 → 27), covering 2242, 2223, 2224, 2225 on both of its paths
(the operator-override loop and `processConstantDefns`' constant-arity check), 2226, 2281, 2146 in
both variants, the 2230 body for a SPECIFICATION and an INVARIANT, the two 2228 variants, and
the accepted constant TRUE. `cfg-runspec`, `sem`, `lvl`, `mc`, `job`, `spec-decomp`,
`safety-gen`, `cfg`, `inv-constraints` and `trace` stay green after the `sem-module` mold change.

### Residues, stated (compatibility.md)

Per-module `mod!lhs <- rhs` substitution checks (they need each non-root module's operator list,
where the graph exposes the root plus its `EXTENDS` imports); `OpRcdValue.toString()` in a 2230
body; and 2281's addendum when the body is non-constant because it is **temporal** (EC 2261
there, with tlc2's abbreviated expression rendering).

## R1.8.1.4 — close-out: the tier-2 liveness batch

### The deferral was hiding more than it said

The batch had been deferred twice (R1.1.8 on an unbounded graph, R1.5.7 on an "uncatchable
value-core bail"), and `.0` discharged the second by measuring that the bail no longer reproduces
— on the **mc corpus**. Wiring the real thing showed that measurement did not generalize: of the
nine test-model liveness specs, **five bail, one diverges, one did not terminate**, and only two
agreed at first contact.

Membership is derived, not listed: a flat single-file test-model spec, `check`-class, with a
`PROPERTY`/`PROPERTIES` in its `.cfg`, whose oracle verdict is an ordinary run outcome with state
counts. Eleven further candidates are excluded on the same rule the safety batch uses (a TLC
exception or a temporal-handling message is not a verdict+count comparison) and each is named in
the generator.

### The comparator was measuring the wrong line

Two of the "divergences" were not divergences. `+tlc-sum` took `i.w` — the wain's **first** line —
as the verdict, while the Java side of the same comparator (`tlc_summary`) *selects* the line
starting `Model checking completed` or `Error:`. No safety spec prints anything before its
verdict, so the two had never disagreed; R1.8.1.2's new EC 2255 warning ("a state-level PROPERTY
is only checked in the initial state") is the first thing that does, and it made `Github715` read
as a port divergence when the port's own verdict was right underneath. `+tlc-sum` now selects the
verdict the same way the Java side does.

### Two real bugs, found by one non-terminating spec

`LivenessConstraintWarning` builds an unbounded `history` sequence bounded **only** by its
`CONSTRAINT Len(history) < 3`. TLC answers in 1.8 s over 5 distinct states; the port produced no
verdict in 480 s. Two independent holes, both closed here:

1. **Every liveness graph build dropped the model constraint.** All six sites in `lib/check`
   passed `~ ~ ~` for `invs`/`cons`/`acons` (the safety and implied-action paths pass them). tlc2
   never enqueues a constrained state, so liveness runs over the constrained graph. Without it the
   state space is infinite and `live-graph-cap` only converts the hang into a very slow `%limited`.
2. **The product build then crashed on the pruned graph.** `+succ-fps:liveness` returned the raw
   next-state relation and the caller did `~(got by states)` on each successor — fine while the
   graph was closed under that relation, fatal once it is not. `+succ-fps` now takes `states` and
   drops successors absent from it, which is what a constrained edge *is*.

Neither is reachable without a CONSTRAINT, and no mc or liveness corpus case has one — which is
why a 9-spec batch found what 16 liveness fixtures could not.

### What the batch measures now: 3 of 9

| spec | outcome |
|---|---|
| `Github1037`, `Github715`, `LivenessConstraintWarning` | agree |
| `Github1389`, `Github1389Violated`, `Github1389ViolatedB`, `Github710e`, `Test2a` | bail `%tlc-live-wrong-formula-format` |
| `Github710d` | port reports the temporal violation, TLC reports `Deadlock reached` (same 4 distinct states) |

The six are **frozen and asserted** by the arm, not silenced: a new divergence — or a fixed one —
fails the test. They are liveness-engine behavior, not decomposition: R1.8.1.1 supplied the
SPECIFICATION fairness every one of these specs needs (without it they would all report a
stuttering violation), and it is what lets three of them match at all.

`+class-default:temporal` bails where tlc2 has a case. `Github1389` is upstream's own regression
test for **recursive operators with temporal bodies**, which tlc2's `Liveness.astToLive` expands
during tableau construction; the port has no such expansion, so the formula reaches the PEM
fallback. That demotes `tlc-live-normalize` from `approved-difference` to `partial` — a terminal
row that bails on in-scope specs was overstated, and the batch is what surfaced it.

### Gates

Full ship suite `-test /=tla-lus=/tests ~` **`ok=%.y`, 1732 OK, 0 FAILED / 0 CRASHED, 0 build
errors**; `tier2.py --check` byte-reproducible from the pins; `check-parity.py --check` well-formed
(70 parity / 11 approved-difference / 13 partial / 108 terminal).

### Ledger

Only one of the unit's four rows closes. `tlc-safety-assume` reaches `parity`. `cfg-validate`,
`cfg-runspec` and `check-opt-cfg` stay `partial` on residues that are now small and precisely
named — the per-module `<-` substitution checks, `OpRcdValue.toString()` in a 2230 body, EC 2281's
temporal addendum, and the job kernel's sliced liveness report omitting the 2257/2259 hint. The
plan's definition of done expected all four; the evidence supports one, and the honest ledger is
worth more than the flip.
