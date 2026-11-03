# R4.0d — Examples runner: notes (session 2, 2026-10-08)

## Ship rebuilt

- The old pier was deleted by the user. A fresh fake `~zod` was booted at
  `/mnt/mars/piers/tla-zod` with `/mnt/mars/piers/vere-v4.6-linux-x86_64`
  (latest release, byte-identical to the old `.run`), the default v4.6 pill,
  and `--loom 33` (user's standing rule).
- First-time setup: `|new-desk %tla-lus`, `|mount`, copy
  `desk/{app,gen,lib,sur,tests}`, `mar/.`, `desk.bill`, `sys.kelvin`,
  `test-data/clay`; `|commit` (186 files, clean); `|install our %tla-lus`.
- Re-run shards, all `ok=%.y`, each anchored on `^> -test <path> ~`:

  | shard | OK | wall |
  |---|---|---|
  | lib/modres | 18 | 20 s |
  | lib/sem | 108 | 50 s |
  | lib/clay-load | 36 | 70 s |
  | lib/job | 121 | 5 min |
  | app | 41 | 30 s |
  | lib/blackbox | 40 | 40 s |
  | lib/safety-gen | 10 | 10 s |
  | lib/tier2 | 13 | 12 min |
  | lib/tier2-sub | 6 | 35 min |

- `%tla-ex` re-staged: `|new-desk`, `|mount`, `examples.py --stage` into
  scratch, copied minus `sys.kelvin`, `|commit` (680 files, revision 2).

## Polling made cheap

`tools/examples.py` no longer runs a `khan-eval` thread (which compiled Hoon)
per poll. It uses a conn `%peek`: `[rid %peek %| %once care desk spur]`
(arvo `+22`'s `(each path [%once vis syd tyl])`; `%|` is `1`). The reply is
`[rid %peek (unit [%omen path [mark noun]])]`. It answers in 5–20 ms with no
event and no compile. `desk_case` uses the same peek (`%cw`). The default
`--poll` is now 10 s.

Conn `%peel` exposes `/help /info /khan /live /mass /quic /port /v /who`.
`/mass` reports only road stuff. Use dojo `|mass` for loom accounting.

## Loom baseline (`|mass` after setup + all shards)

total marked 454 MB, free lists 349 MB; clay pages 281 MB; `%tla-lus` agent
27.6 MB.

## MissionariesAndCannibals retry: the loom cause, measured

- Submitted 14:45:11 via the runner (one model, census to scratch).
- **One Gall event (a behn-driven job slice) ran 12+ minutes without
  returning.** The 10 s `%peek` got no answer the whole time, because peeks
  queue behind the running event. So the polling is NOT the cause.
- Serf RSS grew linearly at about 9 MB/s: 257 MB → 4.9 GB in 9 min → 7.67 GB
  (the loom limit) at 14:57.
- `C-c` → `recover: dig: intr` (event aborted). The next behn slice started
  immediately → `recover: dig: meme`.
- A queued cancel poke plus a second `C-c` around 14:58 → **the king
  segfaulted** (`u3m_fault` in `u3_king_commence`), as in the first incident.
  The serf was orphaned (ppid 1) at 100% CPU, holding `chk/image.bin`.
- `chk/image.bin` was written at 14:58:09. Header `05 …` (version 5), event
  `0x15b` = 347; no patch file present. Copy plus `rss.log`, `mass-0.txt` and
  `pane.txt` are in `/mnt/mars/piers/tla-zod-evidence-2026-10-08-1500/`.
- The orphaned serf was frozen with SIGSTOP (so it can't write).
  Terminating it needs the user.

**ROOT CAUSE (measured, session 2 later):** an INFINITE RECURSION in
`lib/eval.hoon` `+render`. Its `%fcn` arm was `(render (fcn-view v))`, and
`+fcn-view` returns `v` UNCHANGED when the domain is not `1..n`. So rendering
any non-sequence function looped forever, the Nock stack grew about 9 MB/s,
and it ended in `meme`. `lib/check.hoon` rendered TRACE STATES with
`render:ev` (`+state-pairs` :1073, the `-view` branch :1135, `-difftrace`
:1144). MissionariesAndCannibals' `who_is_on_bank = [E |-> {..}, W |-> {..}]`
is a function over `{"E","W"}`. The run reaches its expected `Solution`
violation (expanding the 61st distinct state, depth 11), renders the
counterexample, and hangs. The polling and the loom size were bystanders.

How it was localized: a scratch `%say` generator (`gen/tla-lus/probe.hoon`,
on the ship only, not in the repo) drove `init`/`step:job` off the agent at
budget 1, answered Clay reads by scry, and printed stage, stats and kont size
per step. Step 57 ran away. One `C-c` (`dig: intr`, clean) gave a trace whose
innermost frames were `eval.hoon` render → fcn-view, repeating.

**Fix:**
- `check.hoon` :1073/:1135/:1144 now use `render:vl`, `lib/value.hoon`'s
  tlc2-faithful renderer: `+render-fcn`, tuple/record/`(d :> r @@ ..)`
  forms, string escaping, empty interval.
- `eval.hoon` `+render` renders a non-sequence `%fcn` as `(d :> r @@ ..)`
  and never recurses on it.

Afterwards the M&C probe at budget 256 gives `[%violated [%invariant
'Solution']]`, 227 generated / 61 distinct / depth 12, in 11 s at 159 MB peak.

Why the ship died rather than one job: a Gall event can't be preempted.
Pokes and `%peek`s queue behind it. A `meme` makes the serf retry, then
exit after saving. The king then hits `newt: write failed broken pipe` →
`loom: external fault`. The job's behn timer re-fires the slice at every
boot. Recovery needed the cancel poke queued at the instant conn opened
(`cancel-race.py`, retrying on connect errors), which beat behn.

## Hazard to address before the census

- The M&C job was cancelled (conn opened at boot) and its result deleted.
  The ship is clean.
- RESIDUAL: any other non-terminating or exploding slice (a still-unknown
  evaluator bug in the 158 models) does the same thing. `tools/examples.py`
  now runs a WATCHDOG thread. If the serf's RSS passes `--rss-cap` (MB,
  default 4000), it queues the job's `%cancel` poke FIRST and then sends ONE
  SIGINT to the serf (`C-c`'s effect: `dig: intr`, the event aborts with no
  state change). The cancel is then next in the queue, ahead of the behn
  re-fire. The row is recorded as `runaway`. Never send a second SIGINT:
  that was what preceded the king fault.

## Retries after the fix (runner via the agent's wire, 10 s `%peek` polls)

| model | expected | got | secs | peak RSS |
|---|---|---|---|---|
| MissionariesAndCannibals | safety failure | safety failure (`Solution`; 227 gen / 61 distinct / depth 12) | 12.4 | 140 MB |
| braf/BufferedRandomAccessFile | success | refused: `unsupported: ALIAS with a temporal PROPERTY` | 32.8 | 142 MB |
| FiniteMonotonic/MCDistributedReplicatedLog | liveness failure | refused: `unsupported: VIEW with a temporal PROPERTY` (R4.2e) | 44.6 | 149 MB |

All three finish; none threatens the loom. The two refusals are census rows
for R4.2: ALIAS+PROPERTY has no plan row yet (R4.2i placeholder), and
VIEW+PROPERTY is R4.2e.

Regression arm: `tests/lib/trace.hoon` `test-trace-renders-nonsequence-
functions`. Expected lines come from the pinned jar (`-workers 1`). It was
deliberately not run against the old code, because a bite there would run
the loom out.

Shards re-run green after the fix: trace 8, tlcmod 48, stream 48,
stdops-diff 9, sim-diff 82, safety-gen 10, neval-mc 5, neval-action 6,
mc 106, liveness-message 10, generate-diff 30, dfid 23, core-eval 21,
bags 49, job 121, blackbox 40, app 41, tier2 13.

## R4.0d exit evidence (runner, same session)

The known agreements reproduce through the agent's wire: DieHard (safety
failure), HourClock, TCommit, CigaretteSmokers and Channel (success), each
in about 11 s, which is the 10 s poll floor. SimpleMath is REFUSED by the job
kernel, `no INIT in config` (a constant-only model), although tier-2's batch,
which goes through `check:check`, counts it as agreeing. That is an
entry-point divergence (L12) and a census row for R4.2i. Paxos's cost is
left to R4.0e (wall-capped `too slow` row).

Gates: `validate.py --check` passes (the only drift is `evidence-counts.md`
modres 13→18, which is correct). `scaffold-gate.sh` fails gate 8 only:
`desk/test-data/blackbox/models.json` is 124 KB against a 100 KB bound.

## Census finding: the watchdog's SIGINT cannot cancel (2026-10-08, R4.0e)

CoffeeCan100Beans (tlc2: 5 s, 5,150 distinct) ran one slice past
`wall + 120` s at only about 82 MB, so it is CPU-bound rather than a runaway.
The time watchdog queued `%cancel` and sent SIGINT (`dig: intr`, clean).
But the job's behn timer re-fired the SAME slice before the queued cancel
ran. That happened three times, with the cancel sent over conn and over the
dojo (dill). Vere takes the next event from its drivers in a fixed order,
and behn's overdue `%wake` is always ready, so a cancel arriving on another
driver is STARVED while the slice keeps failing.

Consequences:
- Interrupting a slice cannot cancel its job. Only a boot-time race (cancel
  queued before behn's first `%wake`) or the slice finishing does.
- For a CPU-bound slice (flat memory), let it finish; the ship is not at
  risk.
- For a MEMORY runaway, SIGINT only delays the `meme`, and the ship dies as
  in session 2. The real remedy is in the kernel: a job must not re-run a
  slice that failed. For example, the agent records "slice in progress" and
  marks the job failed when a `%wake` arrives for a slice that never
  returned, or `on-fail` handles the failed `%wake`. That is R4.P2
  territory, and the user should decide it.

## Third crash and the working stop mechanism (2026-10-08 21:10 → 10-09)

- CoffeeCan100Beans' `%config` slice (one unsliced step:
  `generate:semantic` plus run-spec) ran from about 19:45. Interrupts
  re-fired it (behn starvation, above), and the runner died when its own
  synchronous cancel poke timed out. At about 21:10 the serf filled the
  loom slowly and exited (`newt: write failed broken pipe`, then king
  `loom: external fault`). The snapshot at event 2061 is valid; a copy is
  `image-2061.bin` in the evidence dir. Recovered with the boot-time cancel
  race; the job is cancelled and deleted.
- RSS DOES track loom allocation (writes land in anon mappings). The
  watchdog missed this because it fired ONCE (on time, at about 80 MB) and
  the growth came later.
- **Fix (runner only, no engine change):** the request's `max-time` is now
  the wall cap. `+step` checks `time-exceeded` before any work, so after an
  interrupt the behn re-fire ends the job `%limited %time` itself. The
  watchdog SIGINTs whenever RSS > cap or time > wall + 60 s, at most once a
  minute, and never pokes. The main loop no longer pokes a cancel; it stops
  the census at 3× wall. A `limited time` row classifies as `too slow`.
- Verified on CoffeeCan100Beans with `--wall 120`: SIGINT at 180 s and
  240 s, then `limited time` at 250 s, peak 111 MB, and the census
  continued. Stats are 0 because it never left `%config`. That is a
  front-end cost to measure in R4.P0 (likely `+subtree-names-has`, the
  known quadratic walk).

## Orphaned job after an interrupt (R4.0e, 2026-10-09)

CoffeeCan3000Beans: after the time watchdog's SIGINT, the serf went IDLE
(0% CPU, 37 MB) while the job stayed `running` at stage `parse`. No behn
timer resumed it, so the job was ORPHANED: the interrupted event consumed
the wake and nothing rescheduled a step. (CoffeeCan100Beans instead got a
re-fire and ended at `max-time`, so which case you get depends on the
interrupt's timing.) Three SIGINTs landed harmlessly on the idle serf, and
a manual `%cancel` went straight through. The runner now handles it: after
any SIGINT, if the serf is idle and the job is still `running`, it pokes
`%cancel` (which lands, since the serf is idle) and records `too slow` with
`orphaned: true`. The CoffeeCan3000Beans census row reads `cancelled`
because I cancelled it by hand; read it as too slow (stalled in `parse`
past the wall cap).

Kernel lesson for R4.P2: a job must not depend on one behn `%wake`
surviving. An aborted event loses the timer. The agent needs a liveness
re-arm, e.g. re-schedule on `on-load`, or a periodic sweep timer that steps
any `running` job with no pending wake.

## Census finding (mid-run, 2026-10-09): root-only name lookup in the job kernel

By row 67, 27 rows were refused with `no definition for INVARIANT <name>`.
Cause, read off the code: `lib/job.hoon` `+config-run` checks a config
target exists with `body-of-def:check tree <name>`. That searches only the
ROOT module's syntax tree, at :1450 (INVARIANT), :1370/:1372 (INIT/NEXT),
and :1482 (next name). Every other target (VIEW, ALIAS, the INIT/NEXT
resolution itself) goes through the semantic `defs`, which include EXTENDed
modules. So every `MC*.tla`-style model whose invariant lives in the
extended spec is FALSELY refused. This is an entry-point divergence (L12):
the console path has no such guard. It will be the first R4.2 row after the
census; fix it by resolving through `defs`, then re-run the affected rows.
Not fixed mid-census (sequencing: R4.2 after R4.0e).
