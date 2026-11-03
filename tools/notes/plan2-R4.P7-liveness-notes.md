# R4.P7: liveness at scale (H9) (2026-10-12)

**Status: DONE as measured and scoped below. CoffeeCan100Beans completes.
CoffeeCan1000Beans does not, and why is recorded below.**

## 1. First measurement: what reaches the liveness engine at all

86 census models have a PROPERTY. Almost all are blocked BEFORE the engine,
by correctness rows (census r2):
- the tableau refusing a temporal formula (R4.2n);
- ASSUME evaluation;
- `Nat`/`Seq` (R4.2m), `$UnboundedChoose` (R4.2u), undefined identifiers
  (R4.2v).

Of the few that reach it, two "too slow" rows were not performance at all:
- **HourClock2** (12 states) and **Barrier** (64 states) now end in 10 s
  with "Temporal formulas containing actions must be of forms <>[]A or
  []<>A". Their PROPERTY is a CONJUNCTION (`HCini /\ [][HCnxt2]_hr`; a
  one-item `/\ [][…]_vars`). tlc2's `SpecProcessor.processConfigProps`
  recurses through `/\` (infix and bulleted), zero-arity definitions,
  SUBST-IN, LET, parametrized instances and `\A` over a constant set before
  binning each conjunct; the port bins each PROPERTY NAME whole. This is
  likely much of R4.2n's 25 "cannot handle the temporal formula" rows: an
  R4.2 correctness row, recorded there.

## 2. The kernel's liveness graph was not the console's

`lib/job` built the temporal graph with no CONSTRAINTs, no action
constraints, no SYMMETRY group, and deadlock checking OFF, where the console
path (`check.hoon`) uses all four. A search ending other than `%ok`,
`%inv` or `%limited` (a deadlock, an implied-action violation, an evaluation
error) became `internal: unexpected graph outcome`.
- **Fixed:** the same options as the console path, and every non-`%ok`
  outcome goes through `+finish-bfs`, as `ModelChecker.doNext` aborts before
  the liveness check.
- **Arm** `tests/lib/job` `test-live-deadlock-preempts`: a deadlocking spec
  with `Lead == (x = 0) ~> (x = 1)`. tlc2 reports `Deadlock reached` (3/3,
  depth 3). The kernel reported `Lead` violated. It bit.
- **Census effect:** the 10 "unexpected graph outcome" rows now show their
  real causes:
  - incomplete next state (R4.2p) ×5: aba_asyn_byz, bcastByz, bcastByzNoBcast,
    cf1s_folklore, nbacg_guer01;
  - `Nat` (R4.2m) ×3: SpanTree, SpanTreeRandom, SpanTreeTest4Nodes;
  - `$SquareAct` ×1: MCRealTimeHourClock;
  - `Seq(S)` enumeration ×1: MCReachable.

  R4.2q's bulk is gone.

## 3. The engine's cost (CoffeeCan, TerminationHypothesis)

The liveness cost grows about n^1.2: 37 → 58 ms per state for N = 10 → 40
(65 → 860 states). The per-phase profile at N = 40 (4 OOS):

| | before | after |
|---|---|---|
| product, OOS 2 / 3 / 4 | 8.0 / 8.4 / 16.7 s | 1.2 / 1.3 / 0.5 s (cache warm) |
| lasso (Tarjan + acceptance), OOS 4 | 7.9 s | (component edges in one pass) |
| whole console run, TerminationHypothesis | 53.7 s | **18.7 s** |

### Changes (`lib/liveness`), all byte-identical

- `+product-step`: the worklist is a FIFO (front + reversed back), and the
  edges accumulate reversed and are flopped once at completion. Both were
  `+weld`ed per step: quadratic, the H10 pattern.
- Per-state caches on the cursor: successor fingerprints and checkState
  bits. They are shared by every tableau node a state pairs with.
- `~+` on `+succ-fps`, `+cs-bits`, `+ca-bits` and `+consistent-at`. These are
  pure questions every OOS and tableau node re-asked. tlc2's LiveCheck
  answers them once per state or edge during the BFS.
- `+scc-internal`: each component's internal EAAction edges in ONE pass.
  `+scc-accepting` filtered the whole edge list per component, O(components
  × edges), which was the lasso time. `+scc-accepting-in` takes them
  pre-split.

### End to end

**CoffeeCan100Beans** through the runner: `limited time` at 900 s → **success
in 786 s**, 20,002 generated and 5,150 distinct, matching the manifest. The
graph build is about 300 s of that (all 5,150 states are initial); the rest
is the four OOS.

## 4. Not done, and why

- **CoffeeCan1000Beans** (r13's exit evidence) has 501,500 states. At the
  measured 30–60 ms per state of evaluation, that is hours. It is also
  R4.2z's maxSetSize divergence. The remaining cost is evaluator speed (Next
  at about 2.6 ms per state, an action predicate at about 1.5 ms per edge),
  which is R4.P5b's and the evaluator's.
- **`live-graph-cap`** stays: it bounds only the console path (tests). The
  job path already takes the request's `max-states`.
- **On-the-fly recording during the BFS** (LiveCheck's full design) would
  also share Next with the safety search. The caches above capture most of
  the gain without changing the order of edges, which decides the lasso.
  Not worth the risk now.
