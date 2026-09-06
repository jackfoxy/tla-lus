# R2.7.7.4 — measured, and it is not the sub-unit the plan described

```text
Sub-unit: R2.7.7.4
Claim being measured: "the READ side already exists (`all:named` is an accepted
  key in `lib/stdops`); what is missing is the `s:_possible` sub-record"
Measurement result: WRONG, and by a wide margin. `all:named` is an accepted
  KEY NAME that is refused BY NAME at evaluation, the sub-record does not exist
  because NAMED REGISTERS do not exist, and `_POSSIBLE` is a CONSUMER of that
  surface rather than a feature of its own.
```

## What `_POSSIBLE` actually is

`SpecProcessor.processConfigPossible` generates a synthetic module —
`_PossibleModule_nnn`, extending the root spec and `_Possible` — containing, per
named predicate:

```tla
_PossibleAC_P_nnn == _Track(P, "P")
_PossiblePC_P_nnn == _CheckName("P")
```

and wires each `_PossibleAC` into the **model constraints** when the predicate
is state-level and into the **action constraints** when it is action-level, so
`_Track` runs for every discovered state / every transition. Each
`_PossiblePC` becomes a POSTCONDITION.

`_Track` is not native. Its vendored body is:

```tla
_Update(Op(_,_), val) == TLCSet("s:_possible", Op(TLCGetOrDefault("s:_possible", <<>>), val))
```

— that is, **the register store, under a STRING key**, incrementing a record
of name → count. `_Counts` merges the per-worker records (a Java override for
speed; the TLA+ body is equivalent), and `_CheckName(name)` is the postcondition
that fails when a count is zero or absent.

So `_POSSIBLE` is built entirely out of pieces this port either has or lacks —
and the piece it lacks is the big one.

## The port's actual starting point

| surface | pin | port today |
|---|---|---|
| `TLCSet("s:...", v)` | writes a NAMED register | EC 2169 positional argument error — "nonnegative integer" |
| `TLCGet("s:...")` | reads it | EC 2145 undefined |
| `TLCGetOrDefault("s:...", d)` | reads it | returns `d` |
| `TLCGet("all:named")` | the per-worker sequence of named records | in `tlc-get-keys` but NOT in `tlc-stat-keys`, so: *"unsupported StandardModule operator: TLC!TLCGet; the key all:named reports engine state the evaluator cannot reach"* |

The port's register store is `regs=(map @ud value)` on the R2.7.4 carrier —
**integer keys only**. `lib/stdops` says so itself, at the `TLCGetOrDefault`
arm: *"The named-register form (`"s:..."`) is a separate surface this does not
claim."* That sentence was written by R2.7.4.3 and is exactly right; the plan
row simply did not read it.

Every one of those behaviours is a refusal or a default rather than a wrong
answer, so nothing here is unsound — but the capability is absent, not partial.

## Re-scope

`.4` splits, and the sizing moves S–M → **M + M**:

- **R2.7.7.4a — named registers.** `rst` gains `named=(map @t value)`; the
  three surfaces above start acting on string keys; `TLCGet("all:named")`
  answers the single-worker sequence. This is `tlc-module-tlc`'s territory,
  independently testable with a spec that writes and reads one, and it is a
  prerequisite for anything else here. The carrier itself is cheap — `rst` has
  one construction site (`+empty-rst`) and field-wise mutation elsewhere.
- **R2.7.7.4b — `_POSSIBLE` on top.** The two constraint positions keyed on the
  predicate's LEVEL (state → model constraints, action → action constraints),
  the counting semantics, the extra validation the pin has here and nowhere
  else (a TEMPORAL-level predicate is `EC.TLC_CONFIG_ID_HAS_VALUE`, *"a
  temporal formula; only state- and action-level predicates are supported"*),
  and the generated `_CheckName` postconditions — which are reachable only
  because R2.7.7.3 now evaluates postconditions at all.

`SubseteqNextState` closes on **.4b**, not before: its postcondition asserts
`FullSet = 8` and `GainThree = 16`, which needs the counting, not just the
plumbing.

## Not started

No code was written for this unit. The measurement is the deliverable, and it
says the plan's estimate was wrong about both the size and the shape.
