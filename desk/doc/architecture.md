# `%tla-lus` Architecture

`%tla-lus` is split into a **pure pipeline** (a stack of libraries with no
Arvo effects) and a thin **Gall shell** that schedules, persists, authorizes,
and publishes. Every heavy computation is a pure function of a noun; the shell
only decides *when* to run a bounded slice and *what* to do with its output.

## Pure pipeline (`lib/`)

The libraries form a dependency stack, each a port of a Java stage validated
against it (see `port-map.md` for the Java-to-Hoon traceability and tests):

```
source.hoon    UTF-8 codec + SimpleCharStream position model
   │
lexer.hoon     TLA+ token manager  (vs TokenDump)          ── unit 3
   │
ast.hoon       concrete syntax-tree mold + AstDump renderer
syntax.hoon    SANY parser: operator stack, junctions, …   ── unit 4
   │
modules.hoon   EXTENDS/INSTANCE resolution, std modules,   ── unit 5
stdmods.hoon   dependency-first sem-order, parse cache
source-path.hoon  the only constructor of a source-ref:   ── unit 10.2
               canonical, escape-free, pinned-revision paths
   │
semantic.hoon  semantic graph: name resolution, arities,   ── units 6–7
               builtin table, per-def levels (0/1/2/3)
   │
config.hoon    TLC .cfg parse + config-vs-graph validation  ── unit 5 (B4)
               + typed run-spec (vs ConfigDump/FastTool)
   │
tlc/value.hoon      canonical TLC values (equality, order,  ── unit 6 (B5)
                    render, FP64 input bytes, lazy sets)
tlc/stdops.hoon     StandardModule override registry keyed  ── unit 6C (C1)
                    [module operator arity]; argument
                    contract (lazy/minLevel) per operator
tlc/node-eval.hoon  semantic-node evaluator + action solver ── unit 6
                    (init/next-states, pred-bool)
tlc/fingerprint.hoon  FP64 fingerprints, FPSet, symmetry     ── unit 7.1/7.5
                      orbit canonicalization
   │
eval.hoon      canonical TLC values + constant evaluation   ── unit 9  (vs REPL;
               (value mold aliased by tlc/value)               retired on the
                                                                safety path)
   │
check.hoon     safety BFS on semantic nodes: ordered         ── unit 7 (B6)
               invariants, constraints, deadlock, symmetry,
               FP64 identity, shortest traces, out-degree;
crc.hoon       liveness (stuttering lasso), seeded simulation
   │
temporal.hoon  temporal-PROPERTY normalization: the LN*        ── unit 8.1
               live-expression tree, astToLive/simplify/
               toDNF/pushNeg/makeBinary/extractPromises, and
               the OrderOfSolution / PossibleErrorModel oos
   │
job.hoon       resumable stage engine: init → step → …,      ── units 1, 7, 10
               jammed continuation, typed %limited limits,
               asynchronous %modules source load, quotas
```

**StandardModule operators resolve through `lib/stdops`**, the Hoon
equivalent of tlc2's override binding: the key is `[module operator arity]`,
never a bare name, and an override beats the operator's vendored TLA+ body
(those bodies are deliberate dummies TLC overrides). An operator with neither
an override nor an explicit body classification is a typed rejection naming
itself. Three properties are machine-checked against the pinned tree by
`tools/gen-stdops-tests.py`: every registry key is an operator the pin
declares and classifies required; the body-evaluable set equals the pin's
un-overridden operators; and each operator's laziness and `minLevel` equal
its pinned annotation. Operators needing more than evaluated values — an
operator argument, a lazy set, or the unevaluated node of an `@Evaluation`
override — are dispatched to `node-eval`, which owns the environment and the
recursion budget.

The Work Unit 6–7 core lives under `lib/`. Safety state generation runs
on the Work Unit 3 semantic graph through `tlc/node-eval` (the retired CST
solver in `eval.hoon`/`check.hoon` survives only for simulation and the liveness
state-predicate scan); state identity is the `tlc/fingerprint` FP64 orbit
representative, never rendered text.

**Temporal-property normalization lives in `lib/temporal`** (unit 8.1), the
Hoon port of `Liveness.processLiveness` / `astToLive` and the `LiveExprNode`
normal form. It consumes Work Unit 3 semantic nodes and a `SPECIFICATION`'s
fairness conjuncts and produces the `oos` — the `OrderOfSolution` /
`PossibleErrorModel` decomposition (tableau formula, promises, and the shared
check-state/check-action bins with per-pem index arrays). The `live-expr` tree
is the recursive-mold hazard handled the obelisk way (a named `$+` union of
constant-head records, every recursion hand-rolled). `search-ctx:check` builds
the `oos` for a liveness run and carries it on `sctx`; the molds and the
`normalize` / `render-struct` interfaces are **frozen** for the tableau (8.2)
and product/SCC (8.3) layers to build on. Constant-level leaves are folded to
`LNBool` through `node-eval`, so a non-boolean liveness leaf is a typed
rejection rather than a silent pass.

**The tableau → product → verdict → lasso stack** (units 8.2–8.6) builds on that
frozen `oos`. `lib/tableau` (8.2) constructs the Manna–Pnueli particle tableau:
`particleClosure` is an alpha/beta expansion under local consistency run to a
**fixpoint** (the forward alpha sweep walks the growing term list, so a `[]`
introduced by expanding a `/\` is itself expanded and its level≤1 body enters the
particle's state predicates). `lib/liveness` `+build-product` (8.3) pairs each
reachable state with the tableau nodes consistent with it (`isConsistent`,
evaluated by `node-eval` — a non-temporal `LET` leaf keeps its bindings so
`x = y` resolves); `+pem-accepting` (8.4) and `+labeled-product`/`+tarjan`/
`+live-verdict` (8.5) give the `ok` / `violated-property` verdict over the SCCs.

**The lasso layer** (8.6) turns a violated `oos` into the counterexample trace.
`+find-lasso` selects the first violated `oos`; `+stutter-lasso` takes the
shortest prefix (`+prefix-to-stutter` BFS) from an initial product node to an
accepting stutter node, `+bts-lasso` the shortest real-edge cycle
(`+shortest-cycle`) back to a prefix state (`+prefix-to-bts`), generalized to a
loop target > 1. The **trace contract** is `lib/check` `+live-lasso-lines`, which
renders the whole `LivenessDump` `out.txt`: `LIVENESS` / `VERDICT
violated-property` / `EC 2116` / the four `STAT` lines (`generated`/`distinct`/
`queue 0`/`depth`, from `+build-graph`) / `CLASS` (`stuttering` | `back-to-state`)
/ `LOOP` (1-based loop target) / `TRACE` / the numbered `STATE` blocks (state 1 =
`<Initial predicate>`, the fingerprint as `0x`+separatorless hex via `+fp-hex`,
the `var = value` bindings, per-transition `getActions` labels) closed by the
`STATE n -1` marker. Stutter-node selection matches TLC's DFS (unit 8.6.2): the
trace is over distinct **states**, so a same-fingerprint stutter step collapses
(`+dedup-consec`), and among the accepting stutter SCCs `+oos-lasso` reports the
deepest (`+deepest-lasso`, the one TLC finishes first). As of unit 8.8 the job
kernel's %liveness stage runs this engine in production (`do-config`→`do-explore`
→`do-scan`, via `live-report`/`live-render`) with the product build sliced through
a bounded resumable `+pcursor` and the SCC search an explicit-stack `+scursor`
(no recursion-depth bail); pause/resume at every product-step boundary is
byte-identical, and time/state/depth/noun/artifact limits each return a typed
`%limited`. The first-increment `check-live` recognizer now serves only pure
`[]P` (box-state) until unit 8.9 routes it to the invariant engine and retires it.

Purity is the load-bearing property: because `+step:job` is a pure function of
the job noun, pausing and resuming a job cannot change its output (tested as
`test-pause-resume-identical`), and a job persisted across a restart resumes to
the identical result.

### Asynchronous source load (unit 10)

Purity is what forces sources to arrive asynchronously: a stage that read
Clay would be a function of the event it ran in, not of the job noun. So
no library reads Clay at all — the scaffold gate checks that `desk/lib`
and `desk/sur` contain no scry — and a `%clay` bundle instead plans a
`%modules` stage that *names* the files it needs:

```
   %modules ──▶ %await [read-request …]        the kernel names files
       ▲                    │
       │                    ▼
       │            app/tla-lus: %warp ─▶ Clay
       │                    │
       └──── +deliver ◀── %writ                the agent brings bytes back
                  │
                  ▼
   graph closed ──▶ %src ──▶ %parse ──▶ %config ──▶ %explore
```

The `%load` cursor holds the BFS queue, the reads in flight (by tag), the
delivered-but-unabsorbed inbox, and the byte/module accounting; it jams
and revives like any other continuation, so a run paused waiting on Clay
resumes byte-identically. Resolution mirrors the inline resolver exactly,
so a Clay run reaches the module graph — and the verdict, report, and
counterexample — an inline bundle of the same files reaches.

Three invariants hold it together:

- **Escape-free by construction.** A `source-ref` exists only if
  `source-path` built it, which requires canonical segments, a path under
  a declared search root, and a revision already pinned to a number.
- **One revision per run.** The agent resolves the requested case at
  submit, so a commit mid-run cannot split the source set.
- **Bounded everywhere.** Source bytes and module count accrue as reads
  arrive; the load cursor shares the search cursor's noun bound; reads per
  slice have their own budget.

### Quota model (unit 10.4)

A request's `limits` bound one job. A `gquota` bounds the ship: concurrent
active jobs, retained artifact bytes, and in-flight source bytes, checked
at submit with each rejection naming its resource. Every figure is derived
from the jobs map rather than carried as a counter, so the accounting
cannot drift and deleting a job frees its quota by construction. Over the
retention bound, the oldest terminal jobs give up their artifact bodies —
never their results — and say so in their own diagnostics.

## Gall shell (`app/tla-lus.hoon`)

The agent is deliberately small. It:

- **Authorizes** — every `on-poke`/`on-watch`/`on-arvo` asserts
  `=(src.bowl our.bowl)`; only the host ship drives it.
- **Validates and starts** — `%submit` runs `validate:job` (typed-boundary
  checks: bundle non-empty, root present, size/module limits, and a typed
  rejection naming every operation the pipeline cannot yet do faithfully)
  then `init:job`, storing the job under its `req-id`.
- **Schedules bounded slices** — a Behn timer on wire `/job/<id>/step`; each
  `%behn %wake` runs one `step:job` with a fixed work budget
  (`default-budget:job`), fans its events out as `%tla-lus-update` facts,
  and reschedules while the step returns `%more`. The search itself is
  resumable: the BFS/liveness/simulation cursor persists inside the job as
  a versioned jammed continuation, so a large model check yields between
  events instead of blocking the ship (unit P2-1). The continuation is
  jammed because its recursive syntax/value molds must not enter the
  `on-save` vase type.
- **Publishes** — subscribers to `/job/<id>` get a replayed snapshot then live
  ordered events; `%result` is terminal and fires once.
- **Persists** — all jobs live in `state-2 = [%2 jobs=(map req-id job-2)]`.
  `on-save`/`on-load` carry them across upgrades; `migrate.hoon` owns the
  frozen `%0`/`%1` molds and the `%0 → %1 → %2` chain (active `%1` stub
  jobs terminate `%failed` rather than fake a resumable state). Scries
  expose the public `$job` projection, never the internal continuation.

## Dependency graph (units)

```
0 → 1 → 2 → 3 → 4 → 5 → 6 → 7
                    \→ 8
7 + 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15
```

The parser (4) rests on the lexer (3); the semantic graph (6) and levels (7)
rest on module resolution (5); the evaluator (9) and both checkers (10–11) rest
on the semantic layer; simulation and recovery (12) and the Gall integration
(13) sit on top. PlusCal (8) is an independent front-end whose generated TLA+
is validated back through units 4–7.

## Persistence and recovery

State is a versioned tagged union (`versioned-state = $%(state-0 state-1
state-2)`), so upgrades are explicit migrations, never in-place reshaping. A
job's noun contains everything needed to resume byte-identically: the
request, the current stage, the remaining `pending` stages, accumulated
stats/diags/artifacts, the submit time (for `max-time`), the jammed in-stage
continuation (search queue, visited set, scan worklist, or RNG sample), and
(once set) the terminal result. Recovery is therefore "reload state, keep
stepping": interrupting after any slice — including mid-search — never
changes the event stream or the final job, and scheduled wakes for deleted
or already-terminal jobs are no-ops.

## Trust boundaries and data ownership

- **Input** arrives only as pokes from the host ship; nouns are clammed at the
  mark boundary, so a malformed action crashes the grab, not the agent.
- **Clay** is read-only unless a request opts in with `allow-write` *and* uses
  the explicit write action; module-search roots are (to be) canonicalized so a
  relative path cannot escape the request's allowed desk/roots.
- **Resources** are bounded per request (`limits`): source bytes, module count,
  states, depth, wall-clock, and stored-artifact bytes. Exceeding any bound
  yields a structured `%limited` result rather than exhausting the ship.
- **Output** the agent owns: jobs and artifacts live in agent state and are
  removed only by `%delete-result` (terminal jobs) or `%cancel`.

## What is external

The only external dependency is the **oracle** used to *build the tests*: the
Java `tla2tools.jar` at a pinned commit. It is never shipped or called at
runtime — it only produces the differential goldens under `test-data/`. The
desk contains no GUI, no Toolbox, and no `tla2tex` code.
