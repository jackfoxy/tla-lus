/-  *tla-lus
/=  job-lib  /lib/tla/job
|%
  ::  State Migrations For %tla-lus
  ::
  ::  Owns every frozen historical state mold and the pure migration to
  ::  the current shape. The agent's on-load only dispatches; the logic
  ::  and its fixtures live here and in /tests/lib/tla/migrate.
  ::
::  +|  Frozen Unit-1 Molds (%0)
::
+$  op-0       ?(%translate %analyze %check)
+$  verdict-0  ?(%ok %failed %violated %cancelled %limited)
+$  phase-0    ?(%queued %running %done %cancelled)
+$  request-0  [op=op-0 steps=@ud]
+$  job-0
  $:  phase=phase-0
      request=request-0
      done=@ud
      result=(unit verdict-0)
  ==
+$  state-0  [%0 jobs=(map @ta job-0)]
::
::  +|  Frozen Unit-2 Molds (%1)
::
::  the %1 job shape is the public $job mold in /sur/tla-lus, which is
::  frozen; this alias records that %1 states are keyed to it
+$  state-1  [%1 jobs=(map req-id job)]
::
::  +|  Migration %1 -> %2
::
::
++  jobs-1-to-2
  ::  Terminal %1 jobs carry over verbatim: their results are
  ::  historical records. Active %1 jobs ran the unit-2 stub pipeline
  ::  and cannot be resumed honestly under the %2 continuation kernel,
  ::  so they terminate %failed with a restart instruction rather than
  ::  fake a resumable state.
  |=  old=(map req-id job)
  ^-  (map req-id job-2:job-lib)
  %-  ~(run by old)
  |=  j=job
  ^-  job-2:job-lib
  ?^  result.j
    :*  request.j  stage.j  pending.j  progress.j
        stats.j  diags.j  artifacts.j  result.j  *@da  ~
    ==
  :*  request.j  %terminal  ~  progress.j
      stats.j  diags.j  artifacts.j
      `[%failed 'restarted: the stub pipeline was superseded; resubmit']
      *@da  ~
  ==
::
::  +|  Migration %0 -> %1
::
::
++  jobs-0-to-1
  ::  Terminal stub jobs keep id and result category; jobs still active
  ::  at upgrade become %cancelled (the unit-1 stub work is meaningless
  ::  to resume under the unit-2 pipeline shapes).
  |=  old=(map @ta job-0)
  ^-  (map req-id job)
  %-  ~(run by old)
  |=  j0=job-0
  ^-  job
  :*  (synth-request op.request.j0)
      %terminal
      ~
      [done.j0 steps.request.j0]
      *run-stats
      ~
      ~
      `(migrate-result j0)
  ==
::
++  migrate-result
  |=  j0=job-0
  ^-  result
  ?.  ?=(?(%done %cancelled) phase.j0)
    [%cancelled ~]
  ?-  (fall result.j0 %cancelled)
    %ok         [%ok *run-stats]
    %failed     [%failed 'migrated from %0']
    %violated   [%violated [%invariant 'unknown'] *run-stats]
    %cancelled  [%cancelled ~]
    %limited    [%limited %states *run-stats]
  ==
::
++  synth-request
  ::  Old requests carried no source; synthesize an empty inline bundle
  |=  op0=op-0
  ^-  request
  :*  ^-  op
      ?-  op0
        %translate  [%translate [%none | &]]
        %analyze    [%analyze [& & & &]]
        %check      [%check [| ~ [%exhaustive &]]]
      ==
      [%inline '' ~ ~]
      default-limits:job-lib
      |
  ==
--
