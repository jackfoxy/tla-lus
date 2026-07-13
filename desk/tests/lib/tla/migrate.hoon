/-  *tla-lus
/+  *test
/=  mig  /lib/tla/migrate
|%
  ::  Migration Fixtures: Unit-1 %0 State -> %1
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
    (expect-eq !>([%check [& ~ [%exhaustive &]]]) !>(op.request.j))
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
--
