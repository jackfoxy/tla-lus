# R1.5 — Evaluation / safety parity (unit 7) — notes

Plan: `~/FoxyLabs/tla-lus/R1.3-R1.5-plan.md`. Oracle pin unchanged:
`tlaplus@4ba7d8811`, `tlaplus-Examples@47b0e2cc`.

## R1.5.0 — kickoff (DOCS/ORACLE ONLY, 2026-08-03)

No ship change, no generator change, no `-test`, no census edit. Captures the
oracle behaviour the state-generator must match, freezes the TLC-batch baseline,
and maps each of the 12 TLC divergences to the exact `node-eval` / `check` arm
that closes it. Same pattern as C1.0 / 7.0 / 8.0.

### 1. Oracle capture — the fan-out `+solve` must reproduce

Ran `SafetyDump` (verdict/stat/trace) + `tlc2.TLC -dump` (reachable states) on
the three named specs. The current Hoon `+solve` treats `x \in S` / `x' \in S`
as a boolean **filter** (falls through `+solve` to `+solve-filter` →
`eval-bool` → the LHS var is read while unassigned → typed error). TLC instead
**enumerates `S` as candidate assignments, one successor per element**.

`AssignmentInit` — `SPECIFICATION Spec`; each disjunct is a parameterized init
op, the ones that gate through `var \in S` fan out:
```
VERDICT deadlock  EC 2114   generated 6  distinct 5  depth 1
reachable initial states:  s = 1 | 2 | 5 | 9 | 11
```
Hoon (frozen): `Error: variable is unassigned in the current state: s`.

`HourClock` — `HCini == hr \in (1 .. 12)`:
```
VERDICT ok   generated 24  distinct 12  depth 1
reachable initial states:  hr = 1 .. 12   (12 distinct)
```
Hoon (frozen): `Error: variable is unassigned in the current state: hr`.

`Continue` — `Next` contains `y' \in {1,2}`:
```
VERDICT violated-invariant  EC 2110  INV Inv1   generated 3  distinct 2  depth 2
init  (x=1,y=1)  --Next-->  {(x=2,y=1), (x=2,y=2)}   (y'=2 violates Inv1: y<2)
```
Hoon (frozen): `Error: primed variable is unassigned in the successor state: y`.

**Target rule (R1.5.1):** in `+solve`, when the head op is `\in` and the LHS is
an unbound assignable var (`+assignable-sem` already returns it — same test the
`=` arm uses at node-eval.hoon:1030), eval the RHS as a set descriptor
(`+eval-domain`), drain it in enumeration order (`+drain-sexp`), and emit one
partial state per element — the set-valued sibling of the existing single-value
`=` arm (node-eval.hoon:1030-1035), fanning out exactly like `+solve-exists`
(node-eval.hoon:1105) fans out `\E x \in S`. Init mode assigns the bare name;
next mode assigns `name'`.

### 2. TLC-batch baseline — FROZEN

The census that R1.5.x flips is already committed and drift-guarded:
`desk/test-data/tier2/divergences.txt`, generated from
`tools/gen-tier2-tests.py` (`TLC_DIVERGENCES` curated + `TLC_BATCH_DIVERGENCES`).
Verified reproducible: `python3 tools/tier2.py --check` (no ship deploy). The
frozen Hoon-vs-TLC baseline is 12 divergences = 2 curated + 10 batch:

| # | spec | TLC verdict (distinct) | Hoon frozen output |
|---|---|---|---|
| 1 | HourClock (curated) | ok (12) | `variable is unassigned: hr` |
| 2 | TCommit (curated) | ok (34) | `primed variable is unassigned: rmState` |
| 3 | AssignmentInit | deadlock (5) | `variable is unassigned: s` |
| 4 | AssignmentInitNeg | ok (1) | `variable is unassigned: s` |
| 5 | AssignmentNext | ok (2) | `Deadlock reached.` |
| 6 | Continue | violated Inv1 (2) | `primed variable is unassigned: y` |
| 7 | DistributedTrace | violated Inv (20) | `variable is unassigned: x` |
| 8 | Github725d | ok (1) | `primed variable is unassigned: a` |
| 9 | SubseteqNextState | ok (8) | `variable is unassigned: x` |
| 10 | SubsetEq | ok (1) | `SUBSET argument too large to enumerate.` |
| 11 | ConstantOperatorConfiguration | violated Inv (3) | `undefined identifier: F` |
| 12 | TraceWithLargeSetOfInitialStatesTest | (init fan-out) | `variable is unassigned: x` |

### 3. Divergence → arm map (the R1.5.0 deliverable)

The census tags most rows `x \in S (R1.5)`, but reading the sources shows the
gap is finer than one arm. Six distinct arms, mapped precisely:

**A. `+solve` new `\in`-assignment arm** (assignable LHS + set RHS → fan out) —
the R1.5.1 core, node-eval.hoon ~1030 (beside the `=` arm):
- `HourClock` — `hr \in 1..12` (init)
- `DistributedTrace` — `Init == x \in 1..10` (init)
- `Continue` — `y' \in {1,2}` (next), inside a conj/disj
- `TraceWithLargeSetOfInitialStatesTest` — init `x \in <large>` fan-out
- `AssignmentInit` — `InitIn`/`InitEq`/`InitEven` bodies use `var \in S` (also
  needs arm B for the op wrappers)

**B. `+solve` parameterized-operator expansion** — the arity-0 user-op
expansion at node-eval.hoon:1040 only fires when `?=(~ args.n)`; a
parameterized init/next/action op (`Init(s)`, `Next(s)`, `Prepare(rm)`) falls
to `+solve-filter` and fails. Extend it to bind the args and expand the body:
- `AssignmentInit` — `InitExit(s,{0,1})` etc. (arity-2 ops)
- `AssignmentInitNeg` — `Init(var) == \E val \in 0..1: var=val /\ ...`; body is
  `\E`+`=` (already works once expanded)
- `AssignmentNext` — `Next(var) == \E val \in 0..1: var'=val /\ var'>0`
- `TCommit` — `TCNext == \E rm \in RM : Prepare(rm) \/ Decide(rm)`; the
  parameterized **action** ops sit under the existing `+solve-exists` binder
  (node-eval.hoon:1105), so binder + arg-expansion compose

**C. `+solve` `\subseteq`-assignment arm** — an unbound LHS on `\subseteq`
enumerates the powerset of the RHS as candidate assignments (sibling of A):
- `SubseteqNextState` — `x \subseteq {1,2}` (init) and `x' \subseteq y'` (next)

**D. assignable-detection through LET inside ENABLED** — `+assignable-sem`
(node-eval.hoon:965) sees a bare `%variable`/`x'` apply only; a LET-wrapped
primed LHS is missed:
- `Github725d` — `Inv == ENABLED ((LET y == a' IN y) = 0)`; unwrap the LET so
  the `=` LHS resolves to `a'`

**E. lazy `SUBSET` enumeration** — R1.5.2, not R1.5.1. `SUBSET S` in an
enumeration position is forced eagerly and overflows; enumerate through the 6.3
cursor under budget (node-eval `+eval-domain` / value cursor):
- `SubsetEq` — `SUBSET (1..42) \subseteq SUBSET (1..23)`

**F. cfg `CONSTANT` operator override** — R1.5.3. A `CONSTANT F(_) ... F(0)=1`
cfg override must bind the operator so it resolves in eval (config /
`make-env`), currently `undefined identifier: F`:
- `ConstantOperatorConfiguration` — `Next == x' = F(x)`

### Scope note for R1.5.1

As literally scoped (`\in`-assignment, arm A) R1.5.1 flips only HourClock,
DistributedTrace, Continue, TraceWithLargeSetOfInitialStatesTest. To flip the
`Assignment*`/`TCommit` rows the plan attributes to it, R1.5.1 must also land
arm B (parameterized-operator expansion); SubseteqNextState needs arm C. Arms
A+B+C are one coherent state-generator increment and should ship together;
D (Github725d) is a small adjacent fix. E/F are R1.5.2/R1.5.3 as planned.

## R1.5.1 — DONE 2026-08-03 (closes 9 TLC divergences)

Landed arms A+B+C plus two supporting fixes. `desk/lib/node-eval.hoon`:
- **eenv gains `psub=(map @t sem)`** — call-by-name param substitution.
- **`+solve` `\in` arm (A)**: LHS an unbound assignable var (`+assignable-sem`),
  RHS a set descriptor (`+eval-domain`), drained in TLC order → one partial
  state per element. Any other `\in` filters. Init assigns the bare name, next
  the primed name (part is bare-keyed in both, as the `=` arm).
- **`+solve` `\subseteq` arm (C)**: same, enumerating the powerset
  (`[%subset p.rv]` sexp) of the RHS.
- **`+solve` `$BoundedForall` arm (`+solve-forall`)**: a bounded `\A x \in S : A`
  in action position is the conjunction of A over the domain (needed for
  AssignmentInit's `InitAll`, which is `\A val \in S : var = val /\ ...`).
- **parameterized-operator expansion (B)**: the arity-0 user-op arm generalized
  to any user-op; `+bind-psub` binds a bare state-variable argument as a NODE
  (`psub`, so `Init(s)`/`Next(s)`/`Prepare(rm)`'s formal stays assignable),
  operator args via `ops`, everything else evaluated once → `vals`. `+deref-sem`
  resolves a formal-param apply through `psub` in `+eval-apply` and
  `+assignable-sem`; substituted nodes are always plain variable refs so the
  chase can't self-loop.
- **`+eval-enabled` existential fix**: ENABLED A is true iff *any* (partial)
  solution exists — primed vars the action does not constrain are free
  (tlc2 `Tool.enabled`), so completeness is no longer required. Fixes
  `SubseteqNextState` (`ENABLED (x' \subseteq {1})` leaves y' free).

`desk/lib/check.hoon` **`+check-pruned`**: a CONSTRAINT-pruned state is not
counted or enqueued, but TLC still checks its invariants — a violation on the
pruned boundary is now reported (trace = predecessor behavior + the pruned
state). Retires the documented simplification at the old `+register`. Fixes
`Continue` (Inv1 violated by `(x=2,y=2)`, pruned by `Constraint == y<2 /\ x<30`).

**Verified:** all 9 flip green (verdict + distinct match TLC): HourClock ok/12,
TCommit ok/34, AssignmentInit deadlock/5, AssignmentInitNeg ok/1, AssignmentNext
ok/2, Continue violated-Inv1/2, DistributedTrace violated-Inv/20,
SubseteqNextState ok/8, TraceWithLargeSet violated-Inv/12. Census: HourClock +
TCommit → `TLC_CURATED` green arms; the 7 batch specs dropped from
`TLC_BATCH_DIVERGENCES` (now 3: `SubsetEq`=R1.5.2, `ConstantOperatorConfiguration`
=R1.5.3, `Github725d`=arm D). `tier2.hoon` byte-reproducible; full lib suite
`ok=%.y` (no regression — the two existing ENABLED tests still pass under the
non-empty check).

**Deferred:** arm D (Github725d, LET-wrapped primed `=` LHS inside ENABLED) —
niche, one spec, tracked as R1.5.x.
