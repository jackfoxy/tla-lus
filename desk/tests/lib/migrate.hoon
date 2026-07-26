/-  *tla-lus
/+  *test
/=  mig      /lib/migrate
/=  job-lib  /lib/job
|%
  ::  Migration Fixtures: %0 -> %1 -> %2
  ::
++  old-jobs
  ^-  (map @ta job-0:mig)
  %-  malt
  ^-  (list [@ta job-0:mig])
  :~  [~.done-ok [%done [%check 60] 60 `%ok]]
      [~.mid-run [%running [%analyze 40] 25 ~]]
      [~.was-cancelled [%cancelled [%translate 10] 0 `%cancelled]]
      [~.saw-violation [%done [%check 80] 80 `%violated]]
  ==
::
++  migrated  (jobs-0-to-1:mig old-jobs)
::
++  test-all-jobs-survive
  (expect-eq !>(4) !>(~(wyt by migrated)))
::
++  test-all-terminal
  %-  expect
  !>  %+  levy  ~(tap by migrated)
      |=  [* j=job]
      ?&  ?=(^ result.j)
          ?=(%terminal stage.j)
          ?=(~ pending.j)
      ==
::
++  test-ok-preserved
  =/  j  (~(got by migrated) ~.done-ok)
  ;:  weld
    (expect-eq !>(`[%ok *run-stats]) !>(result.j))
    (expect-eq !>([60 60]) !>(progress.j))
    (expect-eq !>([%check [| ~ [%exhaustive &]]]) !>(op.request.j))
  ==
::
++  test-active-becomes-cancelled
  =/  j  (~(got by migrated) ~.mid-run)
  ;:  weld
    (expect-eq !>(`[%cancelled ~]) !>(result.j))
    (expect-eq !>([25 40]) !>(progress.j))
  ==
::
++  test-cancelled-preserved
  =/  j  (~(got by migrated) ~.was-cancelled)
  (expect-eq !>(`[%cancelled ~]) !>(result.j))
::
++  test-violated-category-preserved
  =/  j  (~(got by migrated) ~.saw-violation)
  (expect-eq !>(`[%violated [%invariant 'unknown'] *run-stats]) !>(result.j))
::
::  +|  Migration %1 -> %2
::
::
++  demo-req-1
  ^-  request
  :*  [%check [| ~ [%exhaustive &]]]
      [%inline 'Demo' (malt ~[['Demo' '---- MODULE Demo ----\0a====\0a']]) ~]
      default-limits:job-lib
      |
  ==
::
++  old-jobs-1
  ^-  (map req-id job)
  %-  malt
  ^-  (list [req-id job])
  :~  :-  ~.finished
      :*  demo-req-1  %terminal  ~  [3 3]  [5 4 0 4]  ~
          (malt ~[[`artifact-name`%report `artifact`[%text 'old report']]])
          `[%ok [5 4 0 4]]
      ==
    ::
      :-  ~.mid-flight
      [demo-req-1 %explore ~[%explore %terminal] [2 4] [25 20 0 3] ~ ~ ~]
  ==
::
++  migrated-2  (jobs-1-to-2:mig old-jobs-1)
::
++  test-1-to-2-terminal-preserved
  =/  j  (~(got by migrated-2) ~.finished)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.j))
    (expect-eq !>([3 3]) !>(progress.j))
    (expect-eq !>(`[%text 'old report']) !>((~(get by artifacts.j) %report)))
    (expect-eq !>(~) !>(cont.j))
  ==
::
++  test-1-to-2-active-fails-honestly
  ::  a mid-flight %1 stub job cannot resume under the %2 kernel
  =/  j  (~(got by migrated-2) ~.mid-flight)
  ;:  weld
    %+  expect-eq
      !>(`[%failed 'restarted: the stub pipeline was superseded; resubmit'])
    !>(result.j)
    (expect-eq !>(%terminal) !>(stage.j))
    (expect-eq !>(~) !>(pending.j))
    (expect-eq !>(~) !>(cont.j))
  ==
--
