/-  *tla-lus
/+  *test
/=  agent    /app/tla-lus
/=  job-lib  /lib/tla/job
/=  mig      /lib/tla/migrate
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
--
