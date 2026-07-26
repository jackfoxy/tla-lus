/-  *tla-lus
/+  *test
/=  mig      /lib/migrate
/=  job-lib  /lib/job
|%
  ::  Migration Fixtures: %0 -> %1 -> %2 -> %3
  ::
  ::  The historical molds are frozen copies in /lib/migrate, not the live
  ::  /sur types: unit 10 reshaped the %clay bundle, and a mold that names
  ::  a live type stops describing what was actually stored.
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
      |=  [* j=job-1:mig]
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
  ^-  request-2:mig
  :*  [%check [| ~ [%exhaustive &]]]
      [%inline 'Demo' (malt ~[['Demo' '---- MODULE Demo ----\0a====\0a']]) ~]
      default-limits:job-lib
      |
  ==
::
++  old-jobs-1
  ^-  (map req-id job-1:mig)
  %-  malt
  ^-  (list [req-id job-1:mig])
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
::
::  +|  Migration %2 -> %3
::
::
++  clay-req-2
  ::  a pre-unit-10 %clay request. No such job could be stored (%clay was
  ::  typed-rejected at +validate), but the mold and its conversion are
  ::  frozen so history stays readable either way
  ^-  request-2:mig
  :*  [%check [| ~ [%exhaustive &]]]
      [%clay ~zod %spec da+~2026.7.12 /die-hard/tla `/die-hard/txt ~[/lib]]
      default-limits:job-lib
      |
  ==
::
++  old-jobs-2
  ^-  (map req-id job-2:mig)
  %-  malt
  ^-  (list [req-id job-2:mig])
  :~  :-  ~.finished
      :*  demo-req-1  %terminal  ~  [3 3]  [5 4 0 4]  ~
          (malt ~[[`artifact-name`%report `artifact`[%text 'old report']]])
          `[%ok [5 4 0 4]]
          ~2026.7.20
          ~
      ==
    ::
      :-  ~.mid-flight
      :*  demo-req-1  %explore  ~[%liveness]  [2 4]  [25 20 0 3]  ~  ~  ~
          ~2026.7.21
          `[%1 42]
      ==
    ::
      :-  ~.old-clay
      :*  clay-req-2  %terminal  ~  [1 1]  *run-stats  ~  ~
          `[%failed 'unsupported: %clay sources are not loaded yet (unit 10)']
          ~2026.7.19
          ~
      ==
  ==
::
++  migrated-3  (jobs-2-to-3:mig old-jobs-2)
::
++  test-2-to-3-terminal-preserved
  ::  a completed run is a historical record: it survives the upgrade
  ::  whole, submit time and artifacts included
  =/  j  (~(got by migrated-3) ~.finished)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.j))
    (expect-eq !>([3 3]) !>(progress.j))
    (expect-eq !>([5 4 0 4]) !>(stats.j))
    (expect-eq !>(`[%text 'old report']) !>((~(get by artifacts.j) %report)))
    (expect-eq !>(~2026.7.20) !>(started.j))
    (expect-eq !>(~) !>(cont.j))
  ==
::
++  test-2-to-3-active-fails-honestly
  ::  an in-flight continuation predates the %modules stage; it is sealed
  ::  with a restart instruction rather than resumed into a shape it was
  ::  never built for
  =/  j  (~(got by migrated-3) ~.mid-flight)
  ;:  weld
    %+  expect-eq
      !>(`[%failed 'restarted: the source-load stage is new; resubmit'])
    !>(result.j)
    (expect-eq !>(%terminal) !>(stage.j))
    (expect-eq !>(~) !>(pending.j))
    (expect-eq !>(~) !>(cont.j))
    ::  its statistics and progress are kept, not zeroed
    (expect-eq !>([25 20 0 3]) !>(stats.j))
    (expect-eq !>([2 4]) !>(progress.j))
  ==
::
++  test-2-to-3-clay-root-converted
  ::  the one shape change: a root path becomes the module name it named
  =/  j  (~(got by migrated-3) ~.old-clay)
  =/  s  src.request.j
  ?>  ?=(%clay -.s)
  ;:  weld
    (expect-eq !>('die-hard') !>(root.s))
    (expect-eq !>(`/die-hard/txt) !>(cfg.s))
    (expect-eq !>(~[/lib]) !>(roots.s))
    (expect-eq !>(~zod) !>(ship.s))
  ==
::
++  test-2-to-3-count-preserved
  (expect-eq !>(3) !>(~(wyt by migrated-3)))
::
++  test-root-name-conversion
  ;:  weld
    (expect-eq !>('die-hard') !>((root-name:mig /die-hard/tla)))
    (expect-eq !>('spec') !>((root-name:mig /a/b/spec/tla)))
    (expect-eq !>('spec') !>((root-name:mig /spec)))
    (expect-eq !>('') !>((root-name:mig /)))
  ==

--
