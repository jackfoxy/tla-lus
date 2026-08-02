/-  *tla-lus
/+  *test
/=  agent    /app/tla-lus
/=  job-lib  /lib/job
/=  mig      /lib/migrate
|%
  ::  Agent-Level Tests For %tla-lus
  ::
  ::  Drives the agent arms directly with a hand-built bowl. Fake-ship
  ::  install/restart behavior is exercised separately in the dojo.
  ::
+$  card  card:agent:gall
::
++  mk-bowl
  |=  [run=@ud now=@da src=ship]
  ^-  bowl:gall
  :*  [~zod src %tla-lus `path`/test-agent]
      [~ ~ ~]
      [run `@uvJ`(shax run) now [~zod %tla-lus ud+run]]
  ==
::
++  bol  (mk-bowl 0 ~2026.7.12 ~zod)
::
++  cyc-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  Inv == x < 4
  ====
  '''
::
++  demo-req
  ::  a real inline %check request the %2 kernel runs end to end
  ^-  request
  :*  [%check [| ~ [%exhaustive &]]]
      :*  %inline  'spec'
          (malt ~[['spec' cyc-spec]])
          `'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
      ==
      default-limits:job-lib
      |
  ==
::  (plan:job-lib demo-req) is ~[%parse %config %explore]
++  total  3
::
++  sim-demo-req
  ::  a seeded simulation over cyc-spec (Inv holds, so it completes num behaviors)
  ^-  request
  :*  [%check [| ~ [%simulate 1 2 6]]]
      :*  %inline  'spec'  (malt ~[['spec' cyc-spec]])
          `'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
      ==
      default-limits:job-lib  |
  ==
::
++  live-src
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  A == x' = 1 - x
  B == x' = x
  Next == A \/ B
  Live == <>[](x = 1)
  ====
  '''
++  live-demo-req
  ::  a temporal-property run (exercises the %live build/check kont end to end)
  ^-  request
  :*  [%check [| ~ [%exhaustive &]]]
      :*  %inline  'spec'  (malt ~[['spec' live-src]])
          `'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
      ==
      default-limits:job-lib  |
  ==
::
++  do-poke
  |=  [ag=agent:gall act=action]
  ^-  [(list card) agent:gall]
  (~(on-poke ag bol) %tla-lus-action !>(`action`act))
::
++  do-arvo
  |=  [ag=agent:gall id=@ta]
  ^-  [(list card) agent:gall]
  (~(on-arvo ag bol) [%job id %step ~] [%behn %wake ~])
::
++  do-writ
  ::  a Clay answer arriving on a job's load wire
  |=  [ag=agent:gall id=@ta gen=@da tag=@ud]
  ^-  [(list card) agent:gall]
  %-  ~(on-arvo ag bol)
  :-  `wire`[%job id %load (scot %da gen) (scot %ud tag) ~]
  [%clay %writ ~]
::
++  gen0  ~2026.7.12
::
++  wake-n
  ::  n wakes; returns the cards of the last one
  |=  [ag=agent:gall id=@ta n=@ud]
  ^-  [(list card) agent:gall]
  =/  caz  *(list card)
  |-
  ?:  =(0 n)  [caz ag]
  =^  caz2  ag  (do-arvo ag id)
  $(n (dec n), caz caz2)
::
++  scry-job
  |=  [ag=agent:gall id=@ta]
  ^-  (unit job)
  =/  res  (~(on-peek ag bol) [%x %job id ~])
  !<((unit job) q:(need (need res)))
::
++  run-to-result
  ::  submit and wake to completion (12 wakes covers any of these plans)
  |=  req=request
  ^-  (unit job)
  =/  ag  `agent:gall`agent
  =^  c0  ag  (do-poke ag [%submit ~.j1 req])
  =^  c1  ag  (wake-n ag ~.j1 12)
  (scry-job ag ~.j1)
::
++  reload-at
  ::  submit, wake `k` times (leaving a mid-run jammed kont in state), then
  ::  round-trip the whole agent state through on-save/on-load (a Gall restart)
  ::  and wake to completion — the resumed job must match an uninterrupted run
  |=  [req=request k=@ud]
  ^-  (unit job)
  =/  ag  `agent:gall`agent
  =^  c0  ag  (do-poke ag [%submit ~.j1 req])
  =^  c1  ag  (wake-n ag ~.j1 k)
  =/  ag2  `agent:gall`+:(~(on-load agent bol) ~(on-save ag bol))
  =^  c2  ag2  (wake-n ag2 ~.j1 12)
  (scry-job ag2 ~.j1)
::
++  fact-update
  ::  extract the update payload from a %fact card
  |=  c=card
  ^-  update
  ?>  ?=([%give %fact *] c)
  !<(update q.cage.p.c)
::
::  +|  Lifecycle And Migration
::
::
++  test-on-init-quiet
  =/  res  ~(on-init agent bol)
  (expect-eq !>(~) !>(-.res))
::
++  test-save-load-roundtrip
  =/  ag  `agent:gall`agent
  =^  caz  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  saved  ~(on-save ag bol)
  =/  ag2  `agent:gall`+:(~(on-load agent bol) saved)
  (expect-eq !>(q:~(on-save ag bol)) !>(q:~(on-save ag2 bol)))
::
++  test-inflight-resume-across-reload
  ::  unit 9.4: a mid-run job's checkpointed cursor (the jammed %bfs/%sim/%live
  ::  kont in agent state) survives a Gall restart (on-save -> on-load) and
  ::  resumes to the byte-identical uninterrupted result, at any slice boundary.
  =/  reqs=(list request)  ~[demo-req sim-demo-req live-demo-req]
  |-  ^-  tang
  ?~  reqs  ~
  =/  base  (need (run-to-result i.reqs))
  %+  weld
    ;:  weld
      (expect-eq !>(result.base) !>(result:(need (reload-at i.reqs 1))))
      (expect-eq !>(result.base) !>(result:(need (reload-at i.reqs 2))))
      (expect-eq !>(progress.base) !>(progress:(need (reload-at i.reqs 2))))
    ==
  $(reqs t.reqs)
::
++  test-on-load-migrates-v0
  =/  old
    ^-  state-0:mig
    :-  %0
    %-  malt
    ^-  (list [@ta job-0:mig])
    :~  [~.old-done [%done [%check 60] 60 `%ok]]
        [~.old-run [%running [%analyze 40] 25 ~]]
    ==
  =/  ag  `agent:gall`+:(~(on-load agent bol) !>(old))
  =/  done  (need (scry-job ag ~.old-done))
  =/  run   (need (scry-job ag ~.old-run))
  ;:  weld
    (expect-eq !>(`[%ok *run-stats]) !>(result.done))
    (expect-eq !>([60 60]) !>(progress.done))
    (expect-eq !>(`[%cancelled ~]) !>(result.run))
    (expect-eq !>(%terminal) !>(stage.run))
  ==
::
::  +|  Authorization And Marks
::
::
++  test-unauthorized-poke
  =/  foreign  (mk-bowl 0 ~2026.7.12 ~nec)
  %-  expect-fail
  |.((~(on-poke agent foreign) %tla-lus-action !>(`action`[%cancel ~.j1])))
::
++  test-bad-mark
  %-  expect-fail
  |.((~(on-poke agent bol) %noun !>(0)))
::
::  +|  Submit
::
::
++  test-submit-ack-and-timer
  =/  ag  `agent:gall`agent
  =^  caz  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  j  (need (scry-job ag ~.j1))
  ;:  weld
    (expect-eq !>(2) !>((lent caz)))
    (expect-eq !>([%ack ~.j1]) !>((fact-update (snag 0 caz))))
    %-  expect
    !>(?=([%pass [%job @ %step ~] %arvo %b %wait *] (snag 1 caz)))
    (expect-eq !>(%starting) !>(stage.j))
    (expect-eq !>([0 total]) !>(progress.j))
    (expect-eq !>(~) !>(result.j))
  ==
::
++  test-duplicate-active-rejected
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz   ag  (do-poke ag [%submit ~.j1 demo-req])
  ;:  weld
    (expect-eq !>(1) !>((lent caz)))
    %+  expect-eq
      !>([%rejected ~.j1 'duplicate active id'])
    !>((fact-update (snag 0 caz)))
  ==
::
++  test-invalid-request-rejected
  =/  ag  `agent:gall`agent
  =/  req  demo-req
  =.  max-source.limits.req  8
  =^  caz  ag  (do-poke ag [%submit ~.big req])
  ;:  weld
    (expect-eq !>(1) !>((lent caz)))
    %+  expect-eq
      !>([%rejected ~.big 'source exceeds limit'])
    !>((fact-update (snag 0 caz)))
    (expect-eq !>(*(unit job)) !>((scry-job ag ~.big)))
  ==
::
++  test-unsupported-op-rejected
  ::  the honesty contract: unsupported operations never become jobs
  =/  ag  `agent:gall`agent
  =/  req  demo-req
  =.  op.req  [%translate [%none | &]]
  =^  caz  ag  (do-poke ag [%submit ~.tr req])
  ;:  weld
    %+  expect-eq
      !>([%rejected ~.tr 'unsupported: PlusCal translation is not ported yet (unit 8)'])
    !>((fact-update (snag 0 caz)))
    (expect-eq !>(*(unit job)) !>((scry-job ag ~.tr)))
  ==
::
::  +|  Bounded Execution
::
::
++  test-first-step-events
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz   ag  (do-arvo ag ~.j1)
  ;:  weld
    ::  stage fact, progress fact, next timer
    (expect-eq !>(3) !>((lent caz)))
    %+  expect-eq
      !>([%job ~.j1 [%stage %parse]])
    !>((fact-update (snag 0 caz)))
    %+  expect-eq
      !>([%job ~.j1 [%progress 1 total]])
    !>((fact-update (snag 1 caz)))
    %-  expect
    !>(?=([%pass [%job @ %step ~] %arvo %b %wait *] (snag 2 caz)))
  ==
::
++  test-run-to-done
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz   ag  (wake-n ag ~.j1 total)
  =/  j  (need (scry-job ag ~.j1))
  ;:  weld
    ::  final wake: stage, progress, result facts and no timer
    (expect-eq !>(3) !>((lent caz)))
    %+  expect-eq
      !>([%job ~.j1 [%result [%ok [5 4 0 4]]]])
    !>((fact-update (snag 2 caz)))
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.j))
    (expect-eq !>([total total]) !>(progress.j))
    (expect-eq !>(~) !>(diags.j))
  ==
::
++  test-wake-unknown-job-is-noop
  =/  ag  `agent:gall`agent
  =^  caz  ag  (do-arvo ag ~.ghost)
  (expect-eq !>(~) !>(caz))
::
::  +|  Cancellation
::
::
++  test-cancel-idempotent
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (do-poke ag [%cancel ~.j1])
  =^  caz2  ag  (do-poke ag [%cancel ~.j1])
  =^  caz3  ag  (do-poke ag [%cancel ~.unknown])
  =/  j  (need (scry-job ag ~.j1))
  ;:  weld
    %+  expect-eq
      !>([%job ~.j1 [%result [%cancelled ~]]])
    !>((fact-update (snag 0 caz1)))
    (expect-eq !>(~) !>(caz2))
    (expect-eq !>(~) !>(caz3))
    (expect-eq !>(`[%cancelled ~]) !>(result.j))
    (expect-eq !>(%terminal) !>(stage.j))
  ==
::
++  test-wake-after-cancel-is-noop
  ::  the pending timer for a cancelled job must not advance it
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (do-poke ag [%cancel ~.j1])
  =^  caz   ag  (do-arvo ag ~.j1)
  ;:  weld
    (expect-eq !>(~) !>(caz))
    (expect-eq !>(`[%cancelled ~]) !>(result:(need (scry-job ag ~.j1))))
  ==
::
::  +|  Deletion
::
::
++  test-delete-active-rejected
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz   ag  (do-poke ag [%delete-result ~.j1])
  ;:  weld
    %+  expect-eq
      !>([%rejected ~.j1 'job still active'])
    !>((fact-update (snag 0 caz)))
    (expect !>(?=(^ (scry-job ag ~.j1))))
  ==
::
++  test-delete-terminal
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (do-poke ag [%cancel ~.j1])
  =^  caz   ag  (do-poke ag [%delete-result ~.j1])
  ;:  weld
    (expect-eq !>([%deleted ~.j1]) !>((fact-update (snag 0 caz))))
    (expect-eq !>(*(unit job)) !>((scry-job ag ~.j1)))
  ==
::
::  +|  Subscriptions And Scries
::
::
++  test-watch-jobs
  =/  res  (~(on-watch agent bol) /jobs)
  (expect-eq !>(~) !>(-.res))
::
++  test-watch-active-job-snapshot
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz   ag  (~(on-watch ag bol) /job/j1)
  ;:  weld
    (expect-eq !>(2) !>((lent caz)))
    %+  expect-eq
      !>([%job ~.j1 [%stage %starting]])
    !>((fact-update (snag 0 caz)))
    %+  expect-eq
      !>([%job ~.j1 [%progress 0 total]])
    !>((fact-update (snag 1 caz)))
  ==
::
++  test-watch-terminal-job-snapshot
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (do-poke ag [%cancel ~.j1])
  =^  caz   ag  (~(on-watch ag bol) /job/j1)
  ;:  weld
    (expect-eq !>(1) !>((lent caz)))
    %+  expect-eq
      !>([%job ~.j1 [%result [%cancelled ~]]])
    !>((fact-update (snag 0 caz)))
  ==
::
++  test-watch-unknown-job-rejected
  %-  expect-fail
  |.((~(on-watch agent bol) /job/ghost))
::
++  test-watch-foreign-rejected
  =/  foreign  (mk-bowl 0 ~2026.7.12 ~nec)
  %-  expect-fail
  |.((~(on-watch agent foreign) /jobs))
::
++  test-scry-jobs-list
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  res  (~(on-peek ag bol) /x/jobs)
  %+  expect-eq
    !>(~[[~.j1 %starting]])
  !>(!<((list [req-id stage]) q:(need (need res))))
::
++  test-scry-artifacts
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  active  (~(on-peek ag bol) /x/job/j1/artifact/report)
  =^  caz1  ag  (wake-n ag ~.j1 total)
  =/  report   (~(on-peek ag bol) /x/job/j1/artifact/report)
  =/  missing  (~(on-peek ag bol) /x/job/j1/artifact/translation)
  ;:  weld
    (expect-eq !>([~ ~]) !>(active))
    (expect-eq !>([~ ~]) !>(missing))
    %-  expect
    !>(?=([~ ~ %noun *] report))
  ==
::
++  test-scry-unknown-path
  (expect-eq !>([~ ~]) !>((~(on-peek agent bol) /x/nonsense)))
::
::  +|  Agent-Wide Quotas (unit 10.4)
::
::
++  submit-n
  ::  n distinct submits, returning the cards of the last one
  |=  [ag=agent:gall n=@ud]
  ^-  [(list card) agent:gall]
  =/  caz  *(list card)
  =/  i  0
  |-  ^-  [(list card) agent:gall]
  ?:  =(i n)  [caz ag]
  =^  caz2  ag  (do-poke ag [%submit (scot %ud i) demo-req])
  $(i +(i), caz caz2, ag ag)
::
++  test-submit-past-active-bound-rejected
  ::  the concurrency bound is enforced at submit, naming the resource,
  ::  and no job is created for the refused request
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (submit-n ag max-jobs:default-quota:job-lib)
  =^  caz   ag  (do-poke ag [%submit ~.over demo-req])
  ;:  weld
    (expect-eq !>(1) !>((lent caz)))
    %+  expect-eq
      !>([%rejected ~.over 'global limit: too many active jobs'])
    !>((fact-update (snag 0 caz)))
    (expect-eq !>(*(unit job)) !>((scry-job ag ~.over)))
  ==
::
++  test-finished-job-frees-the-bound
  ::  a job that reaches a result stops counting against concurrency
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (submit-n ag max-jobs:default-quota:job-lib)
  =^  caz1  ag  (do-poke ag [%cancel ~.0])
  =^  caz   ag  (do-poke ag [%submit ~.next demo-req])
  ;:  weld
    (expect-eq !>(2) !>((lent caz)))
    (expect-eq !>([%ack ~.next]) !>((fact-update (snag 0 caz))))
  ==
::
++  test-delete-frees-the-bound
  ::  deleting a terminal job frees its quota with no counter to update
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (submit-n ag max-jobs:default-quota:job-lib)
  =^  caz1  ag  (do-poke ag [%cancel ~.0])
  =^  caz2  ag  (do-poke ag [%delete-result ~.0])
  =^  caz   ag  (do-poke ag [%submit ~.next demo-req])
  ;:  weld
    (expect-eq !>([%deleted ~.0]) !>((fact-update (snag 0 caz2))))
    (expect-eq !>([%ack ~.next]) !>((fact-update (snag 0 caz))))
  ==
::
::  +|  Idempotency And Delivery Robustness (unit 10.5)
::
::  Repeated or reordered delivery must leave both the state and the
::  emitted event stream exactly as the single-delivery case left them.
::
++  test-resubmit-terminal-rejected
  ::  an id names one run: a result is never silently replaced
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (do-poke ag [%cancel ~.j1])
  =/  before  (need (scry-job ag ~.j1))
  =^  caz   ag  (do-poke ag [%submit ~.j1 demo-req])
  ;:  weld
    (expect-eq !>(1) !>((lent caz)))
    %+  expect-eq
      !>([%rejected ~.j1 'a result for this id already exists; delete it first'])
    !>((fact-update (snag 0 caz)))
    (expect-eq !>(before) !>((need (scry-job ag ~.j1))))
  ==
::
++  test-wake-after-completion-is-noop
  ::  a late or duplicated timer never resumes a sealed job or re-emits
  ::  its result
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (wake-n ag ~.j1 total)
  =/  done  (need (scry-job ag ~.j1))
  =^  caz2  ag  (do-arvo ag ~.j1)
  =^  caz3  ag  (do-arvo ag ~.j1)
  ;:  weld
    (expect-eq !>(~) !>(caz2))
    (expect-eq !>(~) !>(caz3))
    (expect-eq !>(done) !>((need (scry-job ag ~.j1))))
  ==
::
++  test-writ-stale-generation-dropped
  ::  a response left over from an earlier job that held this id carries
  ::  that job's generation, and is not absorbed by this one
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  before  (need (scry-job ag ~.j1))
  =^  caz   ag  (do-writ ag ~.j1 (sub gen0 ~h1) 0)
  ;:  weld
    (expect-eq !>(~) !>(caz))
    (expect-eq !>(before) !>((need (scry-job ag ~.j1))))
  ==
::
++  test-writ-unheld-tag-dropped
  ::  right job, right generation, but a read it is not holding — a
  ::  duplicate, or one for a superseded load. No cards, no slice spent
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  before  (need (scry-job ag ~.j1))
  =^  caz   ag  (do-writ ag ~.j1 gen0 7)
  ;:  weld
    (expect-eq !>(~) !>(caz))
    (expect-eq !>(before) !>((need (scry-job ag ~.j1))))
  ==
::
++  test-writ-unknown-job-dropped
  =/  ag  `agent:gall`agent
  =^  caz  ag  (do-writ ag ~.ghost gen0 0)
  (expect-eq !>(~) !>(caz))
::
++  test-writ-terminal-job-dropped
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (do-poke ag [%cancel ~.j1])
  =/  done  (need (scry-job ag ~.j1))
  =^  caz   ag  (do-writ ag ~.j1 gen0 0)
  ;:  weld
    (expect-eq !>(~) !>(caz))
    (expect-eq !>(done) !>((need (scry-job ag ~.j1))))
  ==
::
++  test-stale-load-wire-dropped
  ::  an in-flight read from an older engine shape is ignored rather
  ::  than crashing the event
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  res  (~(on-arvo ag bol) `wire`/job/j1/load/0 [%clay %writ ~])
  (expect-eq !>(~) !>(-.res))
::
++  test-delete-twice-is-noop
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (do-poke ag [%cancel ~.j1])
  =^  caz2  ag  (do-poke ag [%delete-result ~.j1])
  =^  caz   ag  (do-poke ag [%delete-result ~.j1])
  ;:  weld
    (expect-eq !>([%deleted ~.j1]) !>((fact-update (snag 0 caz2))))
    (expect-eq !>(~) !>(caz))
    (expect-eq !>(*(unit job)) !>((scry-job ag ~.j1)))
  ==
::
++  test-watch-midrun-reconnect
  ::  a watcher rejoining mid-run gets the stage and progress it is at,
  ::  never a replay of what it already saw
  =/  ag  `agent:gall`agent
  =^  caz0  ag  (do-poke ag [%submit ~.j1 demo-req])
  =^  caz1  ag  (wake-n ag ~.j1 2)
  =^  caz   ag  (~(on-watch ag bol) /job/j1)
  ;:  weld
    (expect-eq !>(2) !>((lent caz)))
    %+  expect-eq
      !>([%job ~.j1 [%stage %config]])
    !>((fact-update (snag 0 caz)))
    %+  expect-eq
      !>([%job ~.j1 [%progress 2 total]])
    !>((fact-update (snag 1 caz)))
  ==
::
::  +|  API Version And State Migration (unit 10.6)
::
::
++  req-2
  ::  a pre-unit-10 request, over the frozen mold
  ^-  request-2:mig
  :*  [%check [| ~ [%exhaustive &]]]
      [%inline 'Demo' (malt ~[['Demo' cyc-spec]]) `'INIT Init\0aNEXT Next\0a']
      default-limits:job-lib
      |
  ==
::
++  state-2-fixture
  ^-  state-2:mig
  :-  %2
  %-  malt
  ^-  (list [req-id job-2:mig])
  :~  :-  ~.done
      :*  req-2  %terminal  ~  [3 3]  [5 4 0 4]  ~
          (malt ~[[`artifact-name`%report `artifact`[%text 'kept']]])
          `[%ok [5 4 0 4]]
          ~2026.7.20
          ~
      ==
    ::
      :-  ~.live
      [req-2 %explore ~[%liveness] [2 4] [9 8 1 2] ~ ~ ~ ~2026.7.21 `[%1 42]]
  ==
::
++  test-scry-version
  ::  a caller can ask what it is talking to
  =/  res  (~(on-peek agent bol) /x/version)
  %+  expect-eq
    !>([api-version 3])
  !>(!<([api=@ud state=@ud] q:(need (need res))))
::
++  test-on-load-migrates-v2
  ::  %2 -> %3: a completed run survives whole; an in-flight one is
  ::  sealed with a restart instruction rather than resumed across the
  ::  new source-load stage
  =/  ag  `agent:gall`+:(~(on-load agent bol) !>(state-2-fixture))
  =/  done  (need (scry-job ag ~.done))
  =/  live  (need (scry-job ag ~.live))
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.done))
    (expect-eq !>([3 3]) !>(progress.done))
    (expect-eq !>(`[%text 'kept']) !>((~(get by artifacts.done) %report)))
    %+  expect-eq
      !>(`[%failed 'restarted: the source-load stage is new; resubmit'])
    !>(result.live)
    (expect-eq !>(%terminal) !>(stage.live))
    (expect-eq !>([9 8 1 2]) !>(stats.live))
  ==
::
++  test-on-load-coerces-a-stale-type
  ::  the stored *type* names molds that have since changed, so on-load
  ::  coerces the noun instead of requiring it to nest as stored — a
  ::  shape change anywhere in the request must not throw away results
  =/  ag  `agent:gall`+:(~(on-load agent bol) !>(`*`state-2-fixture))
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result:(need (scry-job ag ~.done))))
    (expect-eq !>(2) !>((lent !<((list [req-id stage]) q:(need (need (~(on-peek ag bol) /x/jobs)))))))
  ==
::
++  test-on-load-keeps-v3
  ::  a current state loads unchanged
  =/  ag   `agent:gall`agent
  =^  caz  ag  (do-poke ag [%submit ~.j1 demo-req])
  =/  ag2  `agent:gall`+:(~(on-load agent bol) ~(on-save ag bol))
  (expect-eq !>(q:~(on-save ag bol)) !>(q:~(on-save ag2 bol)))

--
