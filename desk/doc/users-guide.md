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
  **source bundle**, with **limits** and a write flag. Operations the
  pipeline cannot yet run faithfully are **rejected at submit by name**
  (see `doc/compatibility.md`); today that includes `%translate`, the
  `%analyze` semantic/level/lint flags, and `%clay` sources.
- **Source bundle** — either `%inline` (modules and an optional `.cfg` passed
  as nouns) or `%clay` (a root `.tla` path in a desk plus module-search
  roots; not yet loaded — rejected at submit until unit 10).
- **Job** — a submitted request identified by a `req-id` you choose. It runs
  as a chain of bounded slices — long searches persist a resumable cursor
  between events — and ends in exactly one **result**.
- **Result** — `%ok`, `%violated` (with a counterexample), `%limited` (a
  resource bound was hit), `%failed`, or `%cancelled`.
- **Artifacts** — files a terminal job produced: a `%report` with the
  TLC-style output, and on a violation a typed `%trace`.

## Workflow: inline model checking

Submit a `%check` request whose source is an inline module with a config:

```
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
=req  :*  [%check [| ~ [%exhaustive & 0]]]
          [%inline 'Counter' (malt ~[['Counter' spec]]) `cfg]
          default-limits:job-lib
          |
      ==
:tla-lus &tla-lus-action [%submit ~.counter req]
```

Then read the result:

```
.^((unit job) %gx /=tla-lus=/job/counter)
.^(artifact %gx /=tla-lus=/job/counter/artifact/report)
```

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
module-name check still validates the original case). Clay is read-only unless
you set `allow-write=&` and use the write action.

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

## Reading results and traces

- Subscribe to `/job/<id>` (mark `%tla-lus-update`) to stream ordered
  `%stage`/`%progress`/`%diagnostic`/`%result` events; a late subscriber gets a
  replayed snapshot first.
- Scry `/x/job/<id>` for the whole job, or `/x/job/<id>/artifact/report` for
  the summary.
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
