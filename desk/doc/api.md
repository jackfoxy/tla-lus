# `%tla-lus` API

`%tla-lus` is a headless Gall agent. You drive it entirely with pokes, watches,
and scries — there is no web UI. All wire nouns live in `sur/tla-lus.hoon`.
Nothing has been released yet, so those shapes may still change; they freeze at
the first release, after which the contract is "extend, don't reshape" and every
change carries a state migration. Every operation below works from the Dojo of
the ship that hosts the agent.

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
+$  request  [=op src=source-bundle =limits write=(unit write-target) promote=(set diag-code)]
+$  write-target  [=desk pax=path]
+$  op
  $%  [%translate opts=pcal-opts]      ::  PlusCal → TLA+
      [%analyze flags=analyze-flags]   ::  lex/parse/semantic/level/lint
      [%check opts=check-opts]         ::  TLC safety / liveness / simulate
  ==
+$  source-bundle
  $%  [%inline root=module-name modules=(map module-name @t) cfg=(unit @t)]
      [%clay =ship =desk cas=case root=module-name cfg=(unit path) roots=(list path)]
  ==
+$  limits  [max-source=@ud max-modules=@ud max-states=@ud max-depth=@ud max-time=@dr max-artifact=@ud max-set-size=@ud]
+$  check-opts  [translate=? view=? difftrace=? continue=? cfg=(unit source-name) mode=check-mode]
+$  check-mode  $%([%exhaustive deadlock=?] [%simulate seed=@ud num=@ud depth=@ud generate=?] [%dfid depth=@ud deadlock=?])]
+$  analyze-flags  [syntax=? semantic=? level=? lint=?]
+$  pcal-opts  [=fairness termination=? gen-cfg=?]
```

`write` is where a terminal run's artifacts are persisted to Clay; `~` is
read-only and is the default. It is a **target**, not a flag: "may write" says
nothing about where, and an `%inline` bundle has no desk to infer one from. The
target is validated at submit — Clay's `%info` carries no ack, so a bad target
cannot be reported later — and a target overlapping the run's own module-search
roots is refused in either direction, because a run may not write over the
sources it is checking.
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
+$  run-stats  [generated=@ud distinct=@ud queued=@ud depth=@ud outdeg=out-degree]
::  state-graph out-degree: one sample per dequeued state (its newly-distinct
::  successor count), summarized as TLC reports it
+$  out-degree  [min=@ud mean=@ud p95=@ud max=@ud]
+$  violation  $%([%invariant name=@t initial=?] [%deadlock ~] [%property name=@t initial=?] [%liveness name=@t] [%assumption name=@t])
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
| `/x/job/<id>` | `(unit job)` — the public job projection (internal cursors are never exposed) |
| `/x/job/<id>/artifact/<name>` | `artifact` — a terminal job's artifact (`%report` text; `%trace` on a violation) |

## Scheduling, cancellation, restart

A job runs as a chain of **bounded slices**: each Behn wake
(`/job/<id>/step`) spends at most `default-budget:job-lib` work units via
`step:job-lib` (states registered or generated, simulation transitions, or
modules parsed), publishes that slice's events, and — if work remains —
persists an in-stage continuation inside the job and schedules the next
wake. No single event contains a full search; the per-event budget is
engine configuration, separate from the request's `limits`, which are
enforced where each resource grows (`max-states`/`max-depth` per state
registered, `max-time` per slice, `max-artifact` at artifact store). Jobs
are stored in agent state (`state-0 = [%0 jobs=(map req-id jobstate)]`), so
they survive a ship restart and resume mid-search from the persisted
cursor with an identical result; a job cancelled or deleted between
scheduling and wake-up is a no-op.

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
          write=~                  ::  or `[%base /tlaout] to persist artifacts
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

## Mold reference — every public noun, with a value

Every `+$` in `sur/tla-lus.hoon`, in declaration order, with a value a consumer
would actually see. The values are taken from green test assertions and live
runs, not invented; `tools/check-portmap.py` fails if a mold is added to the
wire and not listed here.

### Identifiers, positions, sources

| Mold | Shape | Example |
|---|---|---|
| `req-id` | `@ta` | `~.counter` — caller-chosen; a duplicate **active** id is rejected |
| `module-name` | `@t` | `'Counter'` — the TLA+ module name, not a file name |
| `source-name` | `@t` | `'Counter'`, or `'inline'` for the config |
| `pos` | `[line=@ud col=@ud]` | `[5 12]` — 1-indexed, SANY semantics |
| `span` | `[from=pos to=pos]` | `[[5 12] [5 18]]` — inclusive |
| `loc` | `[src=source-name =span]` | `['Counter' [[5 12] [5 18]]]` |
| `source-id` | `$%([%inline name=source-name] [%clay =ship =desk cas=case =path])` | `[%inline 'Counter']` / `[%clay ~zod %tla-lus da+now /counter/tla]` |
| `source-text` | `[id=source-id text=@t]` | `[[%inline 'Counter'] '---- MODULE Counter ----…']` |
| `resolver` | `$-(module-name (unit source-text))` | a gate; `inline-resolver:modules` builds one from a `(map module-name @t)` |

### Lexical and diagnostic

| Mold | Shape | Example |
|---|---|---|
| `token` | `[kind=@tas text=@t =span]` | `[%ident 'Init' [[4 1] [4 4]]]` |
| `severity` | `?(%error %warning %info)` | `%error` |
| `code-family` | `?(%sany %pcal %tlc %lus)` | `%tlc` — `%lus` is engine-specific, everything else is the pin's |
| `diag-code` | `[family=code-family num=@ud]` | `[%tlc 2.103]`, `[%sany 4.802]`, `[%lus 402]` |
| `stage` | 15 tags | `%parse`, `%config`, `%explore`, `%liveness`, `%dfid`, `%terminal` |
| `diagnostic` | `[code severity stage message at related]` | `[[%sany 4.200] %error %parse 'Encountered "==" …' `['Counter' [[4 6] [4 7]]] ~]` |

### Traces and artifacts

| Mold | Shape | Example |
|---|---|---|
| `binding` | `[var=@t val=@t]` | `['x' '1']` — the value is already **rendered**, as TLC prints it |
| `trace-state` | `[index=@ud action=(unit [name=@t at=(unit loc)]) bindings=(list binding)]` | `[2 `['Next' `['Counter' [[5 9] [5 18]]]] ~[['x' '1']]]` — `action` is `~` on the initial state |
| `trace` | `[kind=?(%safety %lasso %simulate) states=(list trace-state) loop-start=(unit @ud)]` | `[%lasso ~[…] `1]` — `loop-start` is set only for `%lasso` |
| `artifact-name` | `@ta` | `%report`, `%trace`, `%sources` |
| `artifact` | `$%([%text text=@t] [%trace =trace])` | `[%text 'Model checking completed. No error has been found.…']` |

### Request

| Mold | Shape | Example |
|---|---|---|
| `fairness` | `?(%none %wf %sf %wf-next)` | `%wf` — PlusCal only |
| `pcal-opts` | `[=fairness termination=? gen-cfg=?]` | `[%none | |]` — `%translate` is a typed rejection today |
| `analyze-flags` | `[syntax=? semantic=? level=? lint=?]` | `[& & & &]` — `semantic`/`level`/`lint` each gate whether that stage runs and reports. **`syntax` must be `&`**: parsing is mandatory (every later stage consumes the tree), so `syntax=\|` is a typed rejection rather than a flag that does nothing |
| `check-mode` | `$%([%exhaustive deadlock=?] [%simulate seed num depth generate=?] [%dfid depth deadlock=?])` | `[%exhaustive &]` / `[%simulate 42 100 20 \|]`. `generate` is tlc2's `-generate`: the same seeded run with PROBABILISTIC successor picking (`Tool.probabilistic`) — one successor per step instead of all of them. It is a field on `%simulate` rather than a mode of its own because tlc2 spells it that way too (both flags set `RunMode.SIMULATE`). A `CASE` in probabilistic position is a typed `%failed`, as tlc2 aborts there. `%dfid` is tlc2's `-dfid num`: depth-first iterative deepening, a run mode rather than a flag (`RunMode.DFID` selects `DFIDModelChecker` over `ModelChecker`). `depth` is the deepest LEVEL a sweep may reach; below 2 no sweep runs, so 0 and 1 explore the initial states and stop. A run that ends AT the bound is `[%limited %depth …]` and never `%ok` — tlc2 prints no completion line there. DFID does not support liveness and refuses a genuine temporal PROPERTY verbatim (upstream issue 548); a `[]P` box-state one runs, because it is an invariant. `-continue` with `%dfid` is a typed rejection |
| `check-opts` | `[translate=? view=? difftrace=? continue=? cfg=(unit source-name) coverage=? mode=check-mode]` | `[\| \| \| \| ~ \| [%exhaustive &]]`. `coverage` is tlc2's `-coverage` (R2.7.4.2b): it adds the per-action / per-constraint coverage block to the `%report` artifact. A **boolean**, not tlc2's interval argument — `TLCGlobals.coverageInterval` gates only *periodic* reporting and the end-of-run block is byte-identical for `-coverage 0`, `1` and `2`, so the interval is a wall-clock behaviour and has no field here. It is a typed rejection outside `%exhaustive`, alongside a temporal `PROPERTY`, and under a `SPECIFICATION`-form config |
| `op` | `$%(%translate %analyze %check)` | `[%check [\| \| \| \| ~ \| [%exhaustive &]]]` |
| `source-bundle` | `%inline` or `%clay` | see the Dojo example below; **`%clay`'s `root` is a module NAME, not a path** |
| `source-ref` | `[=ship =desk cas=case =path]` | `[~zod %tla-lus da+now /counter/tla]` — only `lib/source-path` builds one |
| `read-request` | `[tag=@ud =source-ref]` | `[1 [~zod %tla-lus da+now /counter/tla]]` |
| `read-response` | `[tag=@ud res=(each @t @t)]` | `[1 [%& '---- MODULE Counter ----…']]` |
| `limits` | six bounds | `default-limits:job-lib` = `[1.000.000 64 100.000 1.000 ~m10 1.000.000]` |
| `write-target` | `[=desk pax=path]` | `[%base /tlaout]` — no `case`: a write lands at the head. `%report` lands at `<pax>/report/txt`, a `%trace` at `<pax>/trace/noun` |
| `request` | `[=op src=source-bundle =limits write=(unit write-target) promote=(set diag-code)]` | see the Dojo example. `promote` is tlc2's `-messagesAsErrors`: diagnostic codes to raise to errors. It is on `request` rather than `check-opts` because it applies to `%analyze` and `%check` alike, and it is **not** a display concern — promotion aborts the run at the moment the diagnostic is emitted and reports the statistics reached so far, which a caller filtering severities off a finished result cannot reproduce. Only WARNINGS are promotable, which is tlc2's rule too |

### Result and job

| Mold | Shape | Example |
|---|---|---|
| `violation` | `$%(%invariant %deadlock %property %liveness %assumption)` | `[%invariant 'Inv' \|]`, `[%deadlock ~]`, `[%property 'Lead' \|]`. **`initial` splits what tlc2 reports as two error codes** (R2.7.1): `&` is a violation found while COMPUTING THE INITIAL STATES (EC 2107 for an invariant, EC 2108 for a property), `\|` one found by a behavior (EC 2110). It is not cosmetic — an initial-state violation has no behavior and tlc2 prints no state-graph statistics for it, so without the flag a caller cannot tell whether the `trace` it holds is a counterexample or a single offending state. `%deadlock`, `%liveness` and `%assumption` take no flag: the first two are properties of a behavior by construction and an ASSUME is checked before any state exists |
| `limit-kind` | `?(%source %modules %states %depth %time %artifact %noun)` | `%artifact` |
| `out-degree` | `[min mean p95 max]` | `[0 1 1 1]` — one sample per **dequeued** state, so a sink pulls `min` to 0 |
| `run-stats` | `[generated distinct queued depth outdeg]` | `[5 4 0 4 [0 1 1 1]]` |
| `result` | five arms | `[%ok [5 4 0 4 [0 1 1 1]]]`, `[%violated [%invariant 'PBad'] [3 3 0 3 [1 1 1 1]]]`, `[%failed 'unsupported: VIEW …']`, `[%limited %artifact [5 4 0 4 [0 1 1 1]]]`, `[%cancelled ~]` |
| `progress` | `[done=@ud total=@ud]` | `[3 3]` — stages, not states |
| `job` | `[request stage pending progress stats diags artifacts result]` | the public projection — **no** `id` field (the id is the map key) and **never** the internal cursors; `result` is `~` until terminal |
| `event` | `$%(%stage %progress %diagnostic %result)` | `[%stage %parse]`, `[%result [%ok …]]` |
| `action` | `$%(%submit %cancel %delete-result)` | `[%submit ~.counter req]` |
| `update` | `$%(%ack %rejected %deleted %job)` | `[%job ~.counter [%result [%ok …]]]` |

Three reading notes that save a round trip:

- **`api-version` stays 1 through this change, deliberately.**
  `compatibility.md` §10.6 records the rule: pre-release reshapes are not
  versions, because no ship held that state and no caller saw that wire.
  R2's own preamble says the same. Bumping it here would re-create exactly the
  pre-release version history §10.6 removed on purpose. It moves at release.
- **`%violated` is never collapsed into `%failed`.** A counterexample is a
  successful run that found something; `%failed` means the engine could not
  answer.
- **`run-stats` means different things per mode.** In `%simulate`, `generated`
  is transitions taken and `depth` the deepest transition index; `distinct` and
  `queued` stay 0, because simulation keeps no frontier. In `%dfid`,
  `generated` and `distinct` are tlc2's own two numbers and `queued`, `depth`
  and `outdeg` stay 0 — DFID's summary line carries no queue term, no
  `The depth of the complete state graph search is N.` line and no average
  outdegree, so the port reports nothing there rather than a number the oracle
  never produced. The per-level progress lines are in the `%report` artifact.
- **`binding.val` is already rendered text**, matching what TLC prints — the
  wire does not ship a structured value.

## Current surface

The wire contract is complete, and stable in practice — it changes only when a
parity gap needs a field the contract cannot express (most recently the
state-graph out-degree distribution in `run-stats`). It freezes at release.

The pipeline behind it is now filled in: the parity ledger
(`parity-manifest.md`) is closed — 125 rows, none owed — so `%check` runs the
real safety, liveness and simulation engines over **both** `%inline` and
`%clay` sources, and `%analyze` runs the real semantic/level/lint pipeline.
What remains unsupported is unsupported **by decision**, not by omission, and
every case is a typed rejection naming what is missing: PlusCal translation,
`VIEW`, `ALIAS`, and a cfg source override. `compatibility.md` carries the full
support matrix — every one of the thirteen approved differences with its
evidence — and its "Typed-rejected / unsupported public options" table is the
list of things a caller can ask for and not get. Nothing degrades silently.
