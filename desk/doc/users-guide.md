# `%tla-lus` User's Guide

`%tla-lus` is a native, headless [TLA+](https://lamport.azurewebsites.net/tla/tla.html)
toolchain for Urbit: PlusCal translation, SANY-compatible parsing and semantic
analysis, and TLC-compatible model checking and simulation, running as a Gall
agent with no GUI and no Java. Everything is a pure, bounded, resumable Gall
event, validated output-for-output against the Java tools at a pinned commit.

This guide is task-oriented. For the exact molds, marks, and scries see
[api.md](api.md); for what does and doesn't match Java, see
[compatibility.md](compatibility.md).

## Install and start

```
::  on a ship that has the desk installed
|install our %tla-lus            ::  or |merge from where the desk lives
|start %tla-lus
```

The agent keeps its jobs in state and survives restarts (`|nuke`/reboot); a
running check resumes from its last completed stage.

## Concepts

- **Request** — one operation (`%translate`, `%analyze`, `%check`) over a
  **source bundle**, with **limits**, an optional **write target**, and a set
  of diagnostic codes to promote to errors. Anything the pipeline cannot run
  faithfully is **rejected at submit by name** (see `doc/compatibility.md`);
  the headline case is `%translate` — PlusCal translation is out of scope and
  the ledger marks it `excluded`. `%analyze`'s semantic/level/lint flags and
  `%clay` sources are **live**.
- **Source bundle** — either `%inline` (modules and an optional `.cfg` passed
  as nouns) or `%clay` (a root module NAME in a desk, a config path, and
  module-search roots; loaded asynchronously at one pinned revision).
- **Job** — a submitted request identified by a `req-id` you choose. It runs
  as a chain of bounded slices — long searches persist a resumable cursor
  between events — and ends in exactly one **result**.
- **Result** — `%ok`, `%violated` (with a counterexample), `%limited` (a
  resource bound was hit), `%failed`, or `%cancelled`.
- **Artifacts** — files a terminal job produced: a `%report` with the
  TLC-style output, and on a violation a typed `%trace`.

## Workflow: inline model checking

Submit a `%check` request whose source is an inline module with a config.
A fresh dojo has none of `%tla-lus`'s molds or libraries in scope, so bind
the two the example uses first:

```
=tla      -build-file /=tla-lus=/sur/tla-lus/hoon
=job-lib  -build-file /=tla-lus=/lib/job/hoon
=spec '''
---- MODULE Counter ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Inv  == x < 4
====
'''
=cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::  check-opts is [translate view difftrace continue cfg coverage
::  postconditions mode]; request is [op src limits write promote env props]
=req  :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
          [%inline 'Counter' (malt ~[['Counter' spec]]) `cfg]
          default-limits:job-lib
          ~
          ~
          ~
          ~
      ==
:tla-lus &tla-lus-action [%submit ~.counter req]
```

Then read the result:

```
.^((unit job:tla) %gx /=tla-lus=/job/counter/noun)
.^(artifact:tla %gx /=tla-lus=/job/counter/artifact/report/noun)
```

The report is `Model checking completed. No error has been found.` with 5
states generated, 4 distinct, depth 4.

## Dojo generators

Three generators wrap the same actions with a demo request (the four-state
counter above, with its config). From the `%base` dojo:

```
:tla-lus +tla-lus!tla-lus/submit ~.job-1 %check     ::  or %analyze
+tla-lus!tla-lus/status ~.job-1                     ::  the (unit job)
:tla-lus +tla-lus!tla-lus/cancel ~.job-1
```

or, with the dojo on the `%tla-lus` desk (`=dir /=tla-lus=`, back with
`=dir`), the short forms `:tla-lus|submit ~.job-1 %check`,
`+tla-lus/status ~.job-1` and `:tla-lus|cancel ~.job-1`. The short poke form
names a generator in the dojo's CURRENT desk, so from `%base` it fails with
`%generator-build-fail`.

A passing model reports `%ok` with `run-stats` (states generated / distinct /
depth). A failing invariant reports `%violated [%invariant <name>]` and the
shortest counterexample trace. A temporal `PROPERTY` (e.g. `<>P`, `[]<>P`) is
liveness-checked; without a fairness constraint TLC (and `%tla-lus`) report a
stuttering lasso, so expect `%violated [%property <name>]` unless the property
holds at the relevant states.

## Workflow: Clay sources

For a spec that lives in a desk, submit a `%clay` bundle pointing at the root
`.tla` and any module-search roots. Store modules under the `%tla` mark
(lowercased file names — Clay path segments carry no case; the declared
module-name check still validates the original case). Clay is read-only unless the request carries a
`write` target (`` `[desk pax] ``), which is validated at submit and refused if
it overlaps the run's own module-search roots. Select the config with
`src.cfg` (a path); `check-opts.cfg` is the `%inline` spelling and is refused
on a `%clay` bundle.

## Model checking modes

- **Exhaustive** (`[%exhaustive deadlock=?]`) — breadth-first exploration of
  the whole reachable state space, checking the invariant at each state and
  (optionally) deadlock.
- **Simulate** (`[%simulate seed num depth generate=?]`) — bounded, **seeded**
  random behaviors. The same seed and limits always produce the same result, so
  runs are reproducible. With `generate` set this is tlc2's `-generate`: the
  successor pick becomes **probabilistic**, so each step generates one successor
  rather than all of them. Same seed, same reproducibility, a different walk —
  and different statistics, since fewer states are generated per step. It only
  changes anything when the nondeterminism sits below a conjunction (a
  top-level `\/` or `\E` is split into separate actions before the successor
  search runs, and the two modes coincide there).

## Limits and cancellation

Every request carries `limits`. The most important is `max-states`: it bounds
the model check so a single run — and a single Gall event — can never do
unbounded work. Hitting a bound yields `%limited` with the statistics gathered
so far, never a crash. Cancel any active job with `[%cancel <id>]`; it is
idempotent. Remove a finished job's stored result with `[%delete-result
<id>]`.

## Runtime envelope

For speed against TLC and which Examples models finish, see
[performance.md](performance.md).

Measured on a fake ship, vere 4.6 (R4.P8, 2026-10-12). Workloads: a
two-integer grid, and the Examples' GameOfLife, whose 16-cell states each
carry a function.

- **Loom.** Run the ship with `--loom 33` (8 GiB). The serf's resident
  memory stays far below it: a 90,000-state grid search adds about 30 MB,
  and GameOfLife (65,536 initial states) peaks at about 410 MB.
- **The persisted search is bounded.** A running check's continuation
  (visited set, queue) is bounded at 256 MB, measured as its `jam` size.
  Past it the check stops `%limited %noun` with its statistics. That is
  about 25 bytes per state for small states and 30 for GameOfLife-sized
  ones, so roughly **8 to 10 million distinct states** per check. The bound
  is checked at 16 points per doubling of the state count, so it is
  enforced within about 4%. Each check jams the continuation, about 0.16 s
  per MB (4.5 s at 28 MB), so past a few million states a measuring turn
  lasts tens of seconds. Large states reach the loom first: GameOfLife holds
  about 3.6 KB resident per state, about 2 million states in 8 GiB. Runs
  past about 1 million states have not been measured.
  (Until R4.P13 the bound was 16 MB, about 500,000 to 650,000 states.)
- **Gall turn length.** A check advances 256 units of work per Behn wake (a
  "slice"). One turn therefore lasts 256 times the per-state cost: about
  0.4 s for the grid (1.4 ms per state), and about 2–3 s for GameOfLife (9
  ms per state). The ship serves other agents between slices; a `%cancel`
  lands at the next slice boundary.
- **Front-end latency** (`%parse`/`%analyze`, and the start of every
  `%check`; R4.4, 2026-11-04, all 373 Examples parse modules through the
  agent): median about 6 s per module with its imports, 90% under 16 s,
  99% under 28 s; the slowest, `tcp_proof` (5,661 lines), about 90 s.
  Unicode spellings cost nothing measurable (same-module A/B within noise).
- **Throughput** depends on the spec. The grid reaches 90,000 states in
  about 130 s, and GameOfLife 59,000 in 300 s (R4.P5c). Temporal properties add a
  product build per property; CoffeeCan with 100 beans (5,150 states, four
  properties) takes about 13 minutes.

## Reading results and traces

- Subscribe to `/job/<id>` (mark `%tla-lus-update`) to stream ordered
  `%stage`/`%progress`/`%diagnostic`/`%result` events; a late subscriber gets a
  replayed snapshot first.
- Scry `/x/job/<id>` for the whole job, or `/x/job/<id>/artifact/report` for
  the summary. From the dojo a `%gx` scry takes the mark on the end of the
  path: `.^((unit job) %gx /=tla-lus=/job/<id>/noun)`.
- A counterexample trace lists states as `State N: <label>` with `var = value`
  bindings; a liveness lasso ends in `State M: Stuttering`.

## Troubleshooting

- **`%rejected 'duplicate active id'`** — the `req-id` already has a running
  job; pick a new id or cancel the old one.
- **`%rejected 'source exceeds limit'` / `'too many modules'`** — raise the
  corresponding `limits` field or trim the bundle.
- **`%failed 'no INIT in config'`** — a `%check` needs a `.cfg` with `INIT`,
  `NEXT`, and an `INVARIANT` or `PROPERTY`.
- **`%limited %states`** — the model is larger than `max-states`; raise the
  limit or reduce the model.
- **Unexpected output vs. Java** — check `compatibility.md`; documented
  divergences (e.g. string-set ordering) are intentional.
