/-  *tla-lus
/=  job-lib  /lib/job
|%
  ::  State Migrations For %tla-lus
  ::
  ::  Owns every frozen historical state mold and the pure migration to
  ::  the current shape. The agent's on-load only dispatches; the logic
  ::  and its fixtures live here and in /tests/lib/migrate.
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
::  +|  Frozen Pre-Unit-10 Molds (%1, %2)
::
::  A historical mold must not name a live type. When unit 10 changed the
::  %clay bundle (its root became a module name, not a path), every
::  "frozen" mold that referred to /sur's $source-bundle changed silently
::  with it — and a stored state then failed to load at all. These molds
::  are copies, so history stays readable.
::
::  the %clay arm as it stood before unit 10. No %clay job can actually
::  appear in a stored state: it was typed-rejected at +validate for the
::  whole life of %1 and %2. The arm is frozen for the type, not the data
+$  source-bundle-2
  $%  [%inline root=module-name modules=(map module-name @t) cfg=(unit @t)]
      $:  %clay
          =ship
          =desk
          cas=case
          root=path
          cfg=(unit path)
          roots=(list path)
      ==
  ==
+$  request-2  [=op src=source-bundle-2 =limits allow-write=?]
::  the %1 job shape: the public $job mold as it stood, over request-2
+$  job-1
  $:  request=request-2
      =stage
      pending=(list stage)
      =progress
      stats=run-stats
      diags=(list diagnostic)
      artifacts=(map artifact-name artifact)
      result=(unit result)
  ==
+$  state-1  [%1 jobs=(map req-id job-1)]
::  the %2 job shape: the continuation kernel's job over request-2
+$  job-2
  $:  request=request-2
      =stage
      pending=(list stage)
      =progress
      stats=run-stats
      diags=(list diagnostic)
      artifacts=(map artifact-name artifact)
      result=(unit result)
      started=@da
      cont=(unit [%1 k=@])
  ==
+$  state-2  [%2 jobs=(map req-id job-2)]
::
::  +|  Migration %2 -> %3
::
::
++  jobs-2-to-3
  ::  The %2 and %3 job records carry the same fields; what changed is the
  ::  request's source bundle. Terminal jobs carry over with their source
  ::  converted, since their results are historical records. An active
  ::  job's continuation predates the %modules stage and cannot be resumed
  ::  honestly across it, so it terminates %failed with a restart
  ::  instruction — the Work Unit 7.7 contract would catch the
  ::  incompatible cursor at the next step anyway; this says so up front.
  |=  old=(map req-id job-2)
  ^-  (map req-id job-3:job-lib)
  %-  ~(run by old)
  |=  j=job-2
  ^-  job-3:job-lib
  ?^  result.j
    :*  (request-2-to-3 request.j)  stage.j  pending.j  progress.j
        stats.j  diags.j  artifacts.j  result.j  started.j  ~
    ==
  :*  (request-2-to-3 request.j)  %terminal  ~  progress.j
      stats.j  diags.j  artifacts.j
      `[%failed 'restarted: the source-load stage is new; resubmit']
      started.j  ~
  ==
::
++  request-2-to-3
  ::  an inline bundle is unchanged; a %clay bundle's root was a path and
  ::  is now the module name, so the file it pointed at becomes the name
  ::  (best effort, and unreachable in practice — %clay was rejected at
  ::  +validate before unit 10, so no such job was ever stored)
  |=  req=request-2
  ^-  request
  =/  s  src.req
  ?-    -.s
      %inline  [op.req s limits.req allow-write.req]
      %clay
    :*  op.req
        :*  %clay  ship.s  desk.s  cas.s  (root-name root.s)
            cfg.s  roots.s
        ==
        limits.req
        allow-write.req
    ==
  ==
::
++  root-name
  ::  the module name a pre-unit-10 root path pointed at: the file's own
  ::  segment, with its extension segment dropped (`/die-hard/tla` names
  ::  the module `die-hard`)
  |=  rot=path
  ^-  module-name
  =/  segs  (flop rot)
  ?~  segs  ''
  ?~  t.segs  `module-name`i.segs
  `module-name`i.t.segs
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
  |=  old=(map req-id job-1)
  ^-  (map req-id job-2)
  %-  ~(run by old)
  |=  j=job-1
  ^-  job-2
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
  ^-  (map req-id job-1)
  %-  ~(run by old)
  |=  j0=job-0
  ^-  job-1
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
  ^-  request-2
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
