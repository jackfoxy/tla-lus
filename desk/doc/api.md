# `%tla-lus` API

`%tla-lus` is a headless Gall agent. You drive it entirely with pokes, watches,
and scries — there is no web UI. All wire nouns are frozen in `sur/tla-lus.hoon`
(the contract is "extend, don't reshape"). Every operation below works from the
Dojo of the ship that hosts the agent.

Only the host ship may drive the agent: `on-poke`, `on-watch`, and `on-arvo`
all assert `=(src.bowl our.bowl)`.

## Marks

| Mark | Direction | Mold |
|---|---|---|
| `%tla-lus-action` | poke in | `action` |
| `%tla-lus-update` | fact out | `update` |
| `%tla` | Clay | raw `.tla` module text |

Both agent marks are `%noun` marks (`mar/tla-lus/action.hoon`,
`mar/tla-lus/update.hoon`).

## Actions (poke `%tla-lus-action`)

```hoon
+$  action
  $%  [%submit id=req-id =request]
      [%cancel id=req-id]
      [%delete-result id=req-id]
  ==
```

- **`%submit`** — validate `request` and start a job under `id`. Re-submitting
  an `id` whose job is still active is rejected (`%rejected … 'duplicate active
  id'`); re-submitting a terminal id is allowed. Validation failures reject with
  a reason. On success the agent emits `%ack` and schedules the first bounded
  slice.
- **`%cancel`** — idempotent. An unknown or already-terminal id is a no-op; an
  active job is sealed with `[%cancelled ~]` and emits a `%result` update.
- **`%delete-result`** — remove a **terminal** job's stored result and
  artifacts. Deleting an active job is rejected (`'job still active'`).

### `request`

```hoon
+$  request  [=op src=source-bundle =limits allow-write=?]
+$  op
  $%  [%translate opts=pcal-opts]      ::  PlusCal → TLA+
      [%analyze flags=analyze-flags]   ::  lex/parse/semantic/level/lint
      [%check opts=check-opts]         ::  TLC safety / liveness / simulate
  ==
+$  source-bundle
  $%  [%inline root=module-name modules=(map module-name @t) cfg=(unit @t)]
      [%clay =ship =desk cas=case root=path cfg=(unit path) roots=(list path)]
  ==
+$  limits  [max-source=@ud max-modules=@ud max-states=@ud max-depth=@ud max-time=@dr max-artifact=@ud]
+$  check-opts  [translate=? cfg=(unit source-name) mode=check-mode]
+$  check-mode  $%([%exhaustive deadlock=?] [%simulate seed=@ud num=@ud depth=@ud])]
+$  analyze-flags  [syntax=? semantic=? level=? lint=?]
+$  pcal-opts  [=fairness termination=? gen-cfg=?]
```

`allow-write` gates Clay write-back; Clay is read-only otherwise.
`default-limits:job-lib` is a sane starting point.

## Updates (fact `%tla-lus-update`, path `/job/<id>`)

```hoon
+$  update
  $%  [%ack id=req-id]                  ::  submit accepted
      [%rejected id=req-id reason=@t]   ::  submit/validation refused
      [%deleted id=req-id]              ::  result deleted
      [%job id=req-id =event]           ::  one step's event
  ==
+$  event
  $%  [%stage =stage]                   ::  entered a pipeline stage
      [%progress =progress]             ::  done/total stages
      [%diagnostic =diagnostic]         ::  a finding (code/severity/stage/span)
      [%result =result]                 ::  terminal outcome (exactly once)
  ==
+$  result
  $%  [%ok stats=run-stats]
      [%failed reason=@t]
      [%violated =violation stats=run-stats]  ::  counterexample, never collapsed to %failed
      [%cancelled ~]
      [%limited kind=limit-kind stats=run-stats]
  ==
+$  run-stats  [generated=@ud distinct=@ud queued=@ud depth=@ud]
+$  violation  $%([%invariant name=@t] [%deadlock ~] [%property name=@t] [%liveness name=@t] [%assumption name=@t])
```

Events arrive **in order**; `%result` fires exactly once and is terminal.
Subscribing to `/job/<id>` first **replays a snapshot** of the job so far
(so a late subscriber catches up), then streams live events — terminal replay
is idempotent. Subscribing to an unknown id fails the watch.

## Subscriptions (watch)

- `/job/<id>` — snapshot + live updates for one job.
- `/jobs` — a marker subscription (no snapshot).

## Scries (peek, `%x` care)

| Path | Returns |
|---|---|
| `/x/jobs` | `(list [req-id stage])` — all jobs and their current stage |
| `/x/job/<id>` | `(unit job)` — the full job noun |
| `/x/job/<id>/artifact/<name>` | `artifact` — a terminal job's artifact (`%report`, `%translation`, `%cfg`, or a `%trace`) |

## Scheduling, cancellation, restart

A job runs as a chain of **bounded slices**: each Behn wake
(`/job/<id>/step`) enters exactly one pipeline stage via `step:job-lib`,
publishes that slice's events, and — if work remains — schedules the next
wake. No single event does unbounded work; the model checker is bounded by
`max-states`. Jobs are stored in agent state (`state-1 = [%1 jobs=(map req-id
job)]`), so they survive a ship restart and resume from the persisted stage;
a job cancelled or deleted between scheduling and wake-up is a no-op.

## Dojo example

```
::  submit a safety check of an inline spec
=spec '''
---- MODULE Counter ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Inv  == x < 4
====
'''
=req  :*  op=[%check [translate=| cfg=~ mode=[%exhaustive deadlock=&]]]
          src=[%inline 'Counter' (malt ~[['Counter' spec]]) `'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a']
          limits=*limits          ::  or default-limits:job-lib
          allow-write=|
      ==
::  the request id is a @ta of your choosing
:tla-lus &tla-lus-action [%submit ~.counter req]

::  peek results (the %gx care supplies the %x head of the on-peek path)
.^((list [req-id stage]) %gx /=tla-lus=/jobs)
.^((unit job) %gx /=tla-lus=/job/counter)
.^(artifact %gx /=tla-lus=/job/counter/artifact/report)

::  cancel / clean up
:tla-lus &tla-lus-action [%cancel ~.counter]
:tla-lus &tla-lus-action [%delete-result ~.counter]
```

## Current surface

The wire contract is complete and frozen. The pipeline behind it is being
filled in unit by unit (see `port-map.md`): `%check` runs the real safety and
liveness model checker for inline sources that carry a config; the PlusCal
translation, semantic/level diagnostics, and Clay-source paths are documented
in `compatibility.md` as they land. Deferred behaviors reject or fall back
rather than crash.
