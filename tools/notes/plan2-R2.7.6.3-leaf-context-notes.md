# R2.7.6.3 — the expanded leaf had no context

```text
Sub-unit: R2.7.6.3
Claim being measured: "the expanded tree loses the inner obligation"
Measurement result: the SHAPE was right and the claim was wrong about where.
  Normalization matches the pin exactly. What was missing is the leaf's
  BINDINGS -- and the wrong answer was a wrong VERDICT, not just a wrong
  witness.
```

## Opening measurement: normalization is not the problem

The plan's opening step was to diff `live-struct-full` for the literal and the
expanded forms. They are **identical** — same OOS, promises, checkState,
checkAction, PEMs, tableau, same TF shape — differing only in source spans.

Then the same projection from `LivenessStruct` on the pinned jar: the pin's
leaf for `live-witness-rec` is `line 9, col 43 to line 9, col 54` — **the
recursive CALL `Reach(n - 1)`, not the base case**. The port's leaf is the same
node at the same span.

So both engines wrap the call opaquely and evaluate it against concrete states
later. tlc2 hands `tool.eval` the `Context` with the formals bound. **The port
handed it nothing.**

## What that produced: a wrong VERDICT

`live-rec-holds` is the probe that settles the severity — the same recursive
shape with a property that HOLDS:

```tla
R(n) == IF n = 0 THEN (x = 0) ELSE <>(R(n - 1))
Prop == R(1)          \* = <>(x = 0), and x = 0 initially
```

| | |
|---|---|
| pin | `Model checking completed. No error has been found.` |
| port, before | `Error: Temporal property Prop was violated.` with a counter-example |

The chain: the leaf `R(n - 1)` mentions a formal that exists only in the
expansion's scope → `+pred-bool` fails → and `+st-pred-bool` read that failure
as **FALSE** → `[]~leaf` then holds at every state → every cycle looks like a
counter-example. So R2.7.6.2's "unsound witness" was the visible half of a
false-positive verdict.

## The fix, in two parts

**1. The leaf carries its bindings.** `le-state` gains `ctx=(map @t value)` and
`nsub=(map @t sem)`, filled only by the new `+leaf-ctx` — every other leaf is
`~ ~`, so no other leaf's noun changes. `+le-equal` compares `%state` leaves by
SPAN and `+render-struct` prints the span, so neither the tf grouping nor the
struct projection can see the new fields; `temporal-struct` (16 cases) and
`tableau` stay green, which is the check that matters.

**The env is the CALLER's, and getting that wrong is a real trap.** The first
attempt captured `+bind-formals`' result — the callee's context, `con1` — and
`R(n - 1)` with `n` bound to the callee's `0` evaluates `R(-1)`, walks into the
ELSE branch and bails on `<>`. tlc2 falls through to the level-based handling
with `con`, not `con1`. The bail is what said so.

**2. An unevaluable leaf is no longer FALSE.** All three sites
(`+st-pred-bool`, `+cs-eval`, `+ca-eval`) coerced an evaluation failure to
`|`. That is a fallback returning a plausible answer — the completion invariant
this project has held since plan-2 — and it is what hid the missing bindings.
They now bail by name (`%tlc-live-state-leaf-unevaluable` with the underlying
message), which is the port's analogue of tlc2's `LNState.eval` letting
`tool.eval` throw.

## Result

| case | before | after |
|---|---|---|
| `live-rec-holds` (property HOLDS) | violated + counter-example | **no error** — matches the pin |
| `live-witness-rec` | `x = 9`, the promise value | `x = 8`, sound |
| `gh1389-violc` | `x = 99` | `x = 98` — inside upstream's own `s2v \in 1..98` assertion |

`live-witness-rec` and `gh1389-violc` leave `SKIPS` and are emitted as ordinary
`VARIES` arms (the witness itself is nondeterministic at the pin — R2.7.6.2).

## Cross-shard breakage, caught by running the whole liveness set

Widening `le-state` broke the **build** of three shards that construct probe
leaves as `[%state <node>]` literally: `tests/lib/temporal`,
`tests/lib/tableau` and `tests/lib/liveness-accept`. None is a shard this unit
touched, and the first two were caught by running the liveness set while the
THIRD surfaced only in the user's full suite — because my first sweep grepped
the two files I already knew about instead of the tree.

**The correct move on a mold change is an exhaustive grep for its
constructors, done once**: `grep -rn "\[%state " --include=*.hoon .` over the
whole desk lists all of them, and after the fix the only literals left are the
two in `+leaf`/`+leaf-ctx` that are supposed to be there. R1.8.8's lesson has a
sharper form here: the shards a unit runs must include everyone who
CONSTRUCTS the mold it changed, and the way to find them is the grep, not
memory.

## Evidence

15 shards — mc, five liveness, temporal, temporal-struct, tableau, sim-live,
symmetry, trace, spec-decomp, coverage, job, app — **`ok=%.y`**.

## Left on the row

`gh1389-counting` stays frozen: LASSO MINIMALITY, one state too long, the same
defect as `live-after-inv` and R2.7.11's target — not this one. The
POSTCONDITION dependency (R2.7.7.2) is unchanged.
