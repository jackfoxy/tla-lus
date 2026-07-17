# `%tla-lus` Architecture

`%tla-lus` is split into a **pure pipeline** (a stack of libraries with no
Arvo effects) and a thin **Gall shell** that schedules, persists, authorizes,
and publishes. Every heavy computation is a pure function of a noun; the shell
only decides *when* to run a bounded slice and *what* to do with its output.

## Pure pipeline (`lib/tla/`)

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
   │
semantic.hoon  semantic graph: name resolution, arities,   ── units 6–7
               builtin table, per-def levels (0/1/2/3)
   │
eval.hoon      canonical TLC values + constant evaluation   ── unit 9  (vs REPL)
   │
check.hoon     state generation, BFS safety + fingerprints, ── units 10–12
crc.hoon       liveness (stuttering lasso), seeded simulation
   │
job.hoon       resumable stage engine: init → step → …      ── units 2, 13
```

Purity is the load-bearing property: because `+step:job` is a pure function of
the job noun, pausing and resuming a job cannot change its output (tested as
`test-pause-resume-identical`), and a job persisted across a restart resumes to
the identical result.

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
