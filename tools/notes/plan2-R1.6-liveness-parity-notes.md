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

## R1.6.2 — the TABLEAU projection

### The projection

`LivenessStruct` emitted `TABLEAU <node-count>` and nothing else, so the tableau graph itself was
never compared. It now emits, per OrderOfSolution that has one:

```
TABLEAU <n>
TBINIT <init-node-count>
TBGRAPH
<TBGraph.toString()>
ENDTBGRAPH
```

`TBGraph.toString` is TLC's own rendering — per node, `Node i.`, its particle via
`TBPar.toString`, then ` --> ` and the successor indices — so it carries no object identities and
needs no normalization. It also reuses the padded `LiveExprNode` printer the `TF` block already
pins, which means the particle's leaves are compared against a renderer the corpus had already
proven. `getInitCnt()` is the count of leading nodes that are initial.

The port side is `+render-par` / `+render-tb-node` / `+render-tableau` in `lib/tableau`, and
`+render-struct` now takes the rendered BLOCK per OrderOfSolution instead of a bare count — the
same device the count used, since `tableau.hoon` imports `temporal.hoon` and not the other way
round. **11 of 16 goldens grew a graph**; all 16 compare green on the first ship run, including
the three-node `~>` tableaux (`leadsto-pass` / `leadsto-viol`), whose particle contents are exactly
what the 8.2 alpha-closure fixpoint bug got wrong and what no projection could see at the time.

### The shard claimed to be generated and was not

`tests/lib/temporal-struct.hoon` carried the header *"GENERATED from
desk/test-data/liveness/<case>/{A.tla,A.txt,struct.txt} — do not edit"*, and no tool wrote it. It
was hand-maintained with 16 inline goldens. Extending the projection meant either hand-editing all
of them or making the claim true; `gen-liveness-tests.py` now emits the shard, which also puts it
under `validate.py`'s drift guard for the first time.

One case needs a different entry point and now says so in the generator rather than by hand:
`symmetry-live` declares SYMMETRY with a liveness PROPERTY, which tlc2 warns about and continues
while the port refuses (an 8.7 approved-difference). Only `+live-struct-full-raw` reaches the
decomposition this shard compares, so `STRUCT_RAW` names it with the reason.

### Hoon note

`{` opens string interpolation inside a `"..."` tape, so `"{"` and `"{}"` are syntax errors, not
literals — they must be written `"\{"` and `"\{}"`. Rendering a set-braced particle is the first
place in this port that needed a literal brace.

### Result

`temporal-struct` 16/16 green; `tableau`, `temporal`, `liveness-{product,accept,verdict,lasso,message}`,
`mc`, `sim-live` and `job` unchanged and green. No full suite (deferred to `.7`).

## R1.6.3 — the product edge/label projection

### The projection

`ProductDump` emitted `NODES`/`INITS` and nothing else. It now emits, per product node in
fingerprint-rank order:

```
PNODE <fp-rank> <tidx> CS <checkState bits>
PEDGE <fp-rank> <tidx> -> <fp-rank> <tidx> CA <checkAction bits>
```

State fingerprints project as a **rank** — the index in the ascending ordering of the reachable
state fingerprints — not raw. Both sides compute the same FP64 (`tlc-fp` is parity), so the rank
agrees, and no 64-bit blob lands in a golden. Successors sort numerically by (rank, tidx); a
lexicographic sort of the rendered lines would put rank 10 before rank 2. tlc2 keys the single
implicit node of a no-tableau product at `-1`; the projection normalizes it to `0`, which is how
the port indexes it.

`tests/lib/liveness-product.hoon` is generated now, for the same reason `temporal-struct` was in
`.2`. Its coverage went **14 → 15**: the old hand-written shard excluded `leadsto-pass` as a
"fairness residue", which R1.8.1.1 closed.

### Three real divergences, none of which a count could see

**1. Duplicate edges.** `Next == \/ x' = x \/ x' = 1` reaches the same successor by two disjuncts,
and the port emitted one product edge per occurrence. tlc2 collects successors into a
`SetOfStates` keyed by fingerprint before `addNextState`, and `GraphNode.transExists` refuses a
repeat, so a state reachable two ways contributes ONE edge. `+succ-fps` now deduplicates by
fingerprint in first-occurrence order.

**2. A stutter self-loop on every node.** The port prepended a self-successor to every state so a
behavior could stutter forever. tlc2's EXHAUSTIVE product has no such edge —
`LiveChecker.addNextState` records the real successors only — and grants stuttering in the
acceptance search instead. (Its TRACE path is different and *does* add it:
`LiveCheck.checkTrace` does `successors.put(tlcState)`, "Add state itself to allow stuttering".)
Removing it outright turned `wf-absent-viol` and `diamond-const-false` from
`violated-property`/`CLASS stuttering` into `ok`, so it is load-bearing: the port grants stuttering
in the GRAPH where tlc2 grants it in the SEARCH. That is verdict-equivalent across all 16 fixtures
and is now an **approved difference**, with `pedge` carrying a `stut` tag so the projection excludes
exactly those edges — a genuine `x' = x` transition is still compared, which a "skip self-loops"
filter would have hidden.

**3. The stutter successor was discovering product NODES.** This is the one that could not be
waved through. `+node-edges` crossed the stutter successor with the tableau successors, so on the
`~>` fixtures it reached a `(state, tidx 2)` product node that neither tlc2 **nor the port's own
`+build-product` count path** has — which means the `NODES` count the differential had compared
since 8.3 came from a graph the verdict was not computed on. The stutter edge is now a pure
self-loop on `(fp, tidx)`, discovering nothing. Verdict and lasso stay green, so nothing depended
on the crossing.

### Result

`liveness-product` **15/15**, `liveness-{verdict,lasso,message,accept}`, `temporal-struct`,
`tableau`, `mc`, `sim-live`, `sim`, `sim-stats`, `job`, `stream`, `spec-decomp`, `trace` and
`tier2` all green. No full suite (deferred to `.7`).

## R1.6.5 — the fairness differential is not reachable, and here is what pins the row instead

### What the increment was scoped as, and why it cannot be built

`.0` scoped `.5` as "project the accepting decision per candidate component from
`LiveWorker.checkComponent`, and compare `+pem-accepting` against it over the corpus instead of
over 7 hand-built cases". Against the pinned jar that projection does not exist:

- `LiveWorker.checkComponent` is **private**, and its only externally visible effect is a
  counterexample — it reports nothing about components it checked and rejected.
- The single public signal is `LiveWorker.STATS`, a `BucketStatistics` histogram fed by one
  `addSample(com.size())` at `LiveWorker.java:587`. It carries component **sizes**, not decisions,
  and only in aggregate across the whole run.

A harness was built anyway to measure how much that histogram is worth. Over the 16-case corpus,
**11 cases record exactly one checked component (size 1 or 2) and 5 record none**. Two things
follow, and both argue against shipping it:

1. `wf-absent-viol` is a stuttering **violation** that records **no checked component at all** —
   independent confirmation, from a completely different signal, of the difference `.3` recorded:
   tlc2 detects stuttering **outside** `checkComponent` (`LiveWorker.isStuttering`), where the port
   grants stuttering in the graph and lets the ordinary SCC search find it.
2. Because of that same approved difference, the port's `+scc-accepting` sees a self-loop on every
   singleton and so calls `+pem-accepting` on components tlc2 never examines. The two histograms
   differ by design, broadly, and a differential over them would have to be filtered on most of
   the corpus — which is the thing this unit's plan warns against.

The harness was therefore reverted rather than committed. What it measured is recorded here.

### What actually pins `tlc-live-fairness`

The acceptance decision is differentially pinned, just not per candidate component:

- **Its inputs**, completely, as of `.2` and `.3`: the per-node `checkState` bits and per-edge
  `checkAction` bits (`PNODE`/`PEDGE`), the tableau particles and promises (`TBGRAPH`), and the
  PEM decomposition itself (`PEMS`/`CHECKSTATE`/`CHECKACTION` and the `OrderOfSolution.toString`
  rendering). Every operand `+pem-accepting` reads is compared byte-for-byte against the pin.
- **Its output**, on every corpus case: `liveness-verdict` (does any PEM accept) and
  `liveness-lasso` (which component did, and its `CLASS`). A wrong accepting decision changes one
  of those.

So the row is at parity for everything the oracle exposes. The residue is precise and, against
this pin, unobservable: **the decision on candidate components that were checked and rejected**.
Closing it would need a patched tlc2, which is out of scope — the pin is the contract.

`tests/lib/liveness-accept`'s 7 hand-built cases stay as the direct structural test of
`+pem-accepting` (fair/unfair, EAAction-every-edge, AEState/AEAction-some, promise discharge,
multi-conjunct), now sitting on top of oracle-pinned inputs rather than hand-built ones.

## R1.6.6 — deadlock-vs-liveness precedence

### The cause was one flag

`check:check`'s liveness path built its state graph with the deadlock flag hard-wired to `|`:

```
[nsb.c ~ cons.c acons.c vars.c order.c perms.c defs.c consts.c | live-graph-cap 0]
                                                              ^ deadlock off
```

and then went straight to `+live-report`. tlc2 reaches a deadlock in the state search
(`ModelChecker.doNext`) and **aborts the run there**, so its final liveness check never runs. On
`Github710d` and `Github710e` — both `Step == x < 3 /\ x' = x + 1`, so `x = 3` has no successor —
TLC reports `Error: Deadlock reached.` where the port reported a temporal violation over the
identical state count.

### The fix, and why it is one pass and not two

The flag now comes from the config (`ddl.c`), and a new `+build-graph-out` returns the search
**outcome** alongside the graph. A `%deadlock` (or a typed `%error`) is rendered through
`+render-outcome`, the same terminal renderer `+safety-run` uses, and pre-empts the liveness report.

`+bfs-step` stops at the first deadlock, so the graph is complete exactly when the outcome is *not*
one — which means the deadlock check costs nothing extra: no second exploration pass is needed, and
the liveness build is unchanged whenever there is no deadlock. `+build-graph-cap` is now a thin
wrapper over `+build-graph-out`, so the other five liveness graph builds are untouched.

### Result: the census is empty

**The tier-2 liveness batch is 9/9** and `TLC_LIVENESS_DIVERGENCES` is `[]`, which the
`test-tlc-liveness-batch` arm now asserts. That is R1.6's stated definition of done: a test flip,
not a judgment call.

Green: `liveness-{verdict,lasso,message,product}`, `mc`, `sim-live`, `job`, `spec-decomp`, `tier2`.
No full suite (deferred to `.7` by instruction).

### Note on the environment

The `tla-zod` tmux session was gone at the start of this increment (a harness teardown kills it, as
`[[tla-lus-dev-environment]]` records). Restarted with `tmux new-session -d -s tla-zod -x 220 -y 50`
then `/mnt/mars/piers/tla-zod/.run /mnt/mars/piers/tla-zod`; no stale `.vere.lock`, ~60 s to a
prompt including replay. The scratchpad helper scripts are session-scoped and had to be rewritten.
