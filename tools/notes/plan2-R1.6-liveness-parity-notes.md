# R1.6 — Liveness parity (unit 8) — measurement notes

Parent plan: `~/FoxyLabs/tla-lus/R1.6-liveness-parity-plan.md` (.0–.7).
Oracle pin: `tlaplus@4ba7d8811`.

## R1.6.0 — kickoff (docs/oracle only)

### The five bails are ONE missing branch, not two families

The plan assumed the five `%tlc-live-wrong-formula-format` divergences split 3 + 2 — a
recursive-operator family and a negated-implication / multi-PROPERTY family — and made splitting
them `.0`'s first job. They do not split. Instrumenting `+class-default:temporal` to render the
offending conjunct (a pier-only patch, reverted) gives:

| spec | offending conjunct | source at that span |
|---|---|---|
| `Github1389` | `-<line 39, col 16-25>` | `PropIf      == ap_0(TRUE)` |
| `Github1389Violated` | `-<line 31, col 17-24>` | `PropViolated == Reach(3)` |
| `Github1389ViolatedB` | `-<line 13, col 17-24>` | `PropViolated == Reach(3)` |
| `Github710e` | `-<line 16, col 32-57>` | `neg_VisitsTwoThenStaysSmall == ~(VisitsTwoThenStaysSmall)` |
| `Test2a` | `-<line 16, col 14-21>` | `neg_Prop1 == ~(Prop1)` |

Every one is `%neg` over an **action-level leaf whose span is the whole property body**. Two of
them are a plain user-operator reference (`~(Prop1)`), three are a recursive-operator application
(`Reach(3)`) — but the failure is identical, and it happens before any of that matters.

### The cause: `+ast` has no user-defined-operator branch at all

`+ast:temporal` dispatches on the operator NAME (`$ConjList`, `[]`, `<>`, `$WF`, `~>`, `\lnot`, …).
A user-defined operator matches none of them and falls through to `(leaf s env)`, and `+leaf`
classifies purely by level:

```
?:  =(0 l)     (eval-const s env)
?:  (lte l 1)  [%& [%state s]]
[%& [%act | ~ s]]              ::  <- anything level >= 2, INCLUDING temporal
```

So **any** named reference to a temporal formula becomes an opaque `%act` leaf. Negated by the
`livespec /\ ¬livecheck` construction, it reaches `+classify`, matches neither `<>[]` nor `[]<>`,
and `+class-default` sees `contain-action` → EC 2214.

`+classify` and `+class-default` are themselves a faithful port of `Liveness.classifyExpr`
(same three cases, same `containAction` fallback, same EC). **The port is reaching a correct
fallback with a conjunct tlc2 never constructs.** The bug is upstream of classification.

### What tlc2 does there (`astToLiveAppl`, `opcode == 0`)

Upstream documents this branch unusually well (`Liveness.java:186-300`):

1. `tool.lookup(opNode, con, false)` resolves the operator. If it is an `OpDefNode`:
2. **Non-RECURSIVE operators are ALWAYS expanded** — the body is translated in place of the call,
   with formals bound *lazily* via `tool.getVal` (not `eval`: eager evaluation fails on state
   variables and turns operator arguments into `OpLambdaValue`, which the `instanceof OpDefNode`
   test at the top of the branch then cannot match).
3. **RECURSIVE operators expand only when `getLevelBound(expr) > ActionLevel`.** At temporal level
   the body *must* be expanded, because `Tool.eval` returns an `IValue` and rejects temporal
   operators outright — it cannot turn `Reach(3)` into a `LiveExprNode` subtree. At action level or
   below, do NOT expand: `Tool.eval` handles the recursion against concrete states at exploration
   time (`Fact(n) == IF n = 0 THEN 1 ELSE n * Fact(n - 1)`).
4. If the expansion's result is above `ActionLevel`, return it; otherwise fall back to the
   level-based leaf.
5. A failure while expanding is swallowed for non-recursive operators (historic fall-through) but
   **re-thrown for recursive ones** — there is no `Tool.eval` fallback for them, and swallowing it
   would let an enclosing `OPCODE_ite` retry via the disjunctive expansion and re-enter the
   recursion.
6. If the operator is still unresolved and its level is above `ActionLevel`:
   **EC 2213 `TLC_LIVE_CANNOT_HANDLE_FORMULA`** — a typed diagnostic the port does not have.
   (`Github525` and `Github742`, both excluded from the batch, are 2213 cases.)

Termination of (3) is a *separate* concern, handled by `OPCODE_ite`: if the guard evaluates to a
constant boolean against `TLCState.Empty`, translate **only the chosen branch**; otherwise fall
through to the disjunctive expansion `(g /\ e1) \/ (-g /\ e2)`. The chosen-branch call sits
*outside* the `try` so a failure is not swallowed and retried disjunctively. Upstream states
explicitly that `CASE`, `/\`, `\/` and `=>` branch selection are **not** handled and users should
write recursive operators with `IF`.

The port has no `$IfThenElse` case in `+ast` either — `IF` also falls to `+leaf`.

### Consequence for the plan: `.1` and `.4` collapse

`.1` was scoped as "recursive-operator expansion" and `.4` as "the remaining bail shapes". They are
the same increment: **the user-defined-operator branch of `astToLiveAppl`**, whose scope is

- resolve a user operator to its definition and translate the body in place of the call, binding
  formals lazily (this alone closes `Github710e` and `Test2a`);
- the RECURSIVE guard on `getLevelBound > ActionLevel`, with the re-throw asymmetry;
- `OPCODE_ite` constant-guard branch selection, which is what makes the recursive case terminate
  (this closes the three `Github1389*` specs);
- EC 2213 for the level > action case that cannot be handled, replacing today's silent `%act` leaf.

`+leaf` producing an `%act` for a level-3 expression is a bug indicator in its own right and should
become unreachable.

### Ordering decided (`.0(c)`)

**`.1` first, before the projections.** The bails are fully diagnosable without a tableau
projection — the offending conjunct plus `LivenessStruct`'s existing `TF` rendering was enough to
locate the branch and read tlc2's intent. Waiting on `.2`/`.3` would delay the increment that
clears five of the six census entries.

### The oracle target, measured

`LivenessStruct` at the pin, for the five specs (this is what `lib/temporal` must produce):

| spec | OOS | TABLEAU sizes | shape |
|---|---|---|---|
| `Github1389` | 3 | 1, 1, 1 | three `[]-<state>` — one per PROPERTY, each an expanded `<>(x = TRUE)` |
| `Github1389Violated` | 1 | 1 | `[]-<state> /\ []<>(-ENABLED <Next> \/ <Next>)` |
| `Github1389ViolatedB` | 1 | 1 | same shape; recursion sits under `<>` rather than in the ELSE |
| `Github710e` | 5 | 6, 2, 0, 1, 3 | four PROPERTYs → five OOS; the negated implication splits into three |
| `Test2a` | 1 | 0 | **one** OOS with **3 PEMs** — the three PROPERTYs become DNF disjuncts, no tableau |

`Test2a` is the sharpest structural check: three PROPERTY entries collapse into a single
`OrderOfSolution` with three PEMs, each conjoining a `<>[]` / `[]<>` with the WF fairness. Any
implementation that builds one OOS per property fails it.

### Projections designed (`.0(b)`)

Neither extension needs a new driver; both oracles already hold the data.

**TABLEAU (`.2`, `LivenessStruct`)** — `o.getTableau()` is the `TBGraph`. Stable, identity-free
fields to project, per node in index order: the node index, its `nexts` (successor indices), its
particle contents (the `TBPar` term list, rendered with the existing `LiveExprNode.toString`
padding so the leaves match what `TF` already pins), and the graph's `init-cnt`. Today's line is
just `TABLEAU <size>`.

**PRODUCT (`.3`, `ProductDump`)** — the `AbstractDiskGraph` per node. Project, per product node
`(fp, tidx)` in a deterministic order: its successor `(fp, tidx)` pairs, the checkState bit vector,
and the per-edge checkAction bit vector — plus stutter self-loops. Fingerprints must be projected
as a canonical rank (sorted index), never raw, or the golden pins nothing portable. Today's lines
are just `NODES`/`INITS`.

**Fairness (`.5`)** — `tlc-live-fairness`'s only evidence is 7 hand-built `liveness-accept` unit
tests. Once `.3` projects per-node/per-edge bit vectors, the accepting decision is checkable
against them over the whole corpus, which is most of what that row owes.

### Acceptance set frozen (`.0(d)`)

- the 6 entries in `TLC_LIVENESS_DIVERGENCES` (`tools/gen-tier2-tests.py`), asserted exactly by
  `test-tlc-liveness-batch`; R1.6 is done when the list is empty;
- the 16-case `desk/test-data/liveness` corpus (`struct.txt`, `product.txt`);
- the liveness cases in `desk/test-data/mc` (`live-box`, `live-diamond`, `wf-*`, `sf-*`,
  `leadsto-*`, `back-to-state`, the gate cases);
- `tests/lib/{temporal,temporal-struct,tableau,liveness-product,liveness-accept,liveness-verdict,liveness-lasso,liveness-message}`.

No fixtures are owed for `.1`: all five specs are already in the tier-2 batch with oracle verdicts.

### Method note

The bail label carried no information (`~|(%tlc-live-wrong-formula-format !!)`), so five specs all
looked like one opaque failure. Rendering the offending conjunct into the label — eight characters
of change — turned them into five spans pointing at one missing branch. Worth doing permanently:
a bail that names only its error class costs a full debugging cycle to re-derive.

## R1.6.1 — the user-defined-operator branch

### What landed

`+ast:temporal` gained the branch `.0` found missing (`Liveness.astToLiveAppl`, `opcode == 0`),
plus the two things it depends on:

- **`+user-op`** — resolve a user operator through `ops.env` and translate its BODY in place of the
  call. A formal bound call-by-name through `psub` is translated in place first, matching tlc2's
  single `Context` lookup.
- **`+bind-formals`** — bind formals the way `tool.getVal(args[i], con, false)` does: **in the
  caller's context**. An argument that evaluates there is bound as a VALUE, one that does not (it
  reads a state variable) as the argument NODE through `psub`. This is not a stylistic choice:
  binding the unevaluated node would rebind `n` to an expression mentioning `n`, and `Reach(n - 1)`
  would recurse forever. Each binding clears the other map so lookup order cannot matter.
- **`+ite-of`** — `OPCODE_ite`. A guard that evaluates to a constant boolean selects **one** branch;
  that is what terminates the recursive expansion. Otherwise the disjunctive expansion
  `(g /\ e1) \/ (-g /\ e2)`, kept only above action level. The chosen branch is computed outside
  the guard evaluation, as upstream comments at the same site.
- **EC 2213 `TLC_LIVE_CANNOT_HANDLE_FORMULA`** in `+user-op`'s fall-through, replacing the silent
  `%act` leaf.

### Two things the Java forced that a first reading missed

**The level is PASSED to the leaf, not recomputed from the node.** tlc2's four-argument
`astToLive(tool, expr, con, level)` is called by every branch with a level *it* computed — the
negation passes its operand's, the implication the max of both, and a user-operator expansion
passes **the expansion's**. The port's `+leaf` recomputed `(sem-lvl s)`, and that broke
`Github1389ViolatedB`: its `Reach(0)` expands to `(x = 99)`, a level-1 state predicate, while the
recursive definition it came from is temporal — so recomputing gave 3 and raised EC 2213 where tlc2
builds an `LNState`. `+leaf` now takes the level explicitly and every caller passes what it
computed.

**"Expanded to a non-temporal result" and "did not expand" are different outcomes.** A first
implementation collapsed them into a `(unit live-expr)`, which sent the first case into the 2213
fall-through. tlc2 *returns* from inside the expansion branch in both of its sub-cases; only a
failure to expand at all reaches `Specs.getLevel` and 2213.

**No `recursive` flag is needed, and that is equivalence rather than simplification.** tlc2 always
expands a non-recursive operator but discards the result unless it is above action level, falling
back to the same level-based leaf; and it expands a recursive one only when its level bound is
above action level. Gating *every* user operator on the call's own level gives the same answer in
both cases, because the level of an application is the level of its definition. Similarly the
swallow-vs-re-throw asymmetry is unnecessary here: the re-throw exists only to stop an enclosing
`OPCODE_ite` from retrying disjunctively and re-entering the recursion, and `+ite-of` computes its
chosen branch outside any recovery.

### One deliberate difference

`+expand-cap` bounds nested expansion at 1.000. tlc2 has no bound — it expands until the JVM stack
overflows and `TLC.process` turns that into `EC.SYSTEM_STACK_OVERFLOW` (`Github1389Loops`,
`Github1389StateGuard`, both excluded from the batch). A Hoon runaway is a hang, not a catchable
failure, so the port rejects with a typed diagnostic instead — the same trade `live-graph-cap`
makes for the graph build. Terminating expansions are orders of magnitude below it.

### Result: the census goes 6 → 2

| spec | before | after |
|---|---|---|
| `Github1389`, `Github1389Violated`, `Github1389ViolatedB`, `Test2a` | crash | **agree** |
| `Github710e` | crash | reaches a verdict; now the deadlock-vs-liveness precedence difference |
| `Github710d` | precedence | unchanged |

**Tier-2 liveness batch 3/9 → 7/9**, and the two remaining entries are the *same* cause on
identical state counts — `.6`'s single small increment. Green with no regressions:
`temporal`, `temporal-struct`, `tableau`, `liveness-{product,accept,verdict,lasso,message}`, `mc`,
`sim-live`, `job`, `spec-decomp`, `tier2`. No full suite (deferred to `.7` by instruction).

### EC 2213 is a guard, not a pinned behavior

It renders correctly — the intermediate `Github1389ViolatedB` failure showed
`TLC cannot handle the temporal formula line 7, col 44 to line 7, col 55 of module
Github1389ViolatedB`, location and module exact — but no corpus case reaches it now that expansion
works, so nothing pins it. `Github525` and `Github742` raise 2213 from a **different** site: the
SPEC side of `processLiveness`, not `astToLive`. That is a separate residue, and it is why both
stay excluded from the batch.
