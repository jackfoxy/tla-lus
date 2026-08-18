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
