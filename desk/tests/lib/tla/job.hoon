/-  *tla-lus
/+  *test
/=  job-lib  /lib/tla/job
|%
  ::  Tests For The Deterministic Stub Job Engine
  ::
++  demo-bundle
  ^-  source-bundle
  [%inline 'Demo' (malt ~[['Demo' '---- MODULE Demo ----\0a====\0a']]) ~]
::
++  demo-req
  |=  =op
  ^-  request
  [op demo-bundle default-limits:job-lib |]
::
++  check-op   ^-  op  [%check [& ~ [%exhaustive &]]]
++  sim-op     ^-  op  [%check [& ~ [%simulate 1 3 8]]]
::
++  run-all
  ::  step to termination, collecting the full event stream
  |=  j=job
  ^-  [(list event) job]
  =/  acc=(list event)  ~
  |-
  =/  r  (step:job-lib j)
  ?-  -.r
    %stop  [(weld acc events.r) job.r]
    %more  $(j job.r, acc (weld acc events.r))
  ==
::
::  +|  Validation
::
::
++  test-validate-ok
  (expect-eq !>(~) !>((validate:job-lib (demo-req check-op))))
::
++  test-validate-empty-bundle
  =/  req  `request`[check-op [%inline 'Demo' ~ ~] default-limits:job-lib |]
  (expect-eq !>(`'empty source bundle') !>((validate:job-lib req)))
::
++  test-validate-missing-root
  =/  bundle
    `source-bundle`[%inline 'Nope' (malt ~[['Demo' '====']]) ~]
  =/  req  `request`[check-op bundle default-limits:job-lib |]
  (expect-eq !>(`'root module not in bundle') !>((validate:job-lib req)))
::
++  test-validate-oversized-source
  =/  req  (demo-req check-op)
  =.  max-source.limits.req  8
  (expect-eq !>(`'source exceeds limit') !>((validate:job-lib req)))
::
++  test-validate-too-many-modules
  =/  bundle
    ^-  source-bundle
    [%inline 'A' (malt ~[['A' '===='] ['B' '====']]) ~]
  =/  req  `request`[check-op bundle default-limits:job-lib |]
  =.  max-modules.limits.req  1
  (expect-eq !>(`'too many modules') !>((validate:job-lib req)))
::
::  +|  Planning
::
::
++  test-plan-lengths
  ;:  weld
    (expect-eq !>(2) !>((lent (plan:job-lib [%translate [%none | &]]))))
    (expect-eq !>(6) !>((lent (plan:job-lib [%analyze [& & & &]]))))
    (expect-eq !>(2) !>((lent (plan:job-lib [%analyze [& | | |]]))))
    (expect-eq !>(13) !>((lent (plan:job-lib check-op))))
    (expect-eq !>(10) !>((lent (plan:job-lib sim-op))))
  ==
::
::  +|  Execution
::
::
++  test-run-check-ok
  =/  [events=(list event) j=job]  (run-all (init:job-lib (demo-req check-op)))
  ;:  weld
    (expect-eq !>(`[%ok [100 80 0 12]]) !>(result.j))
    (expect-eq !>(%terminal) !>(stage.j))
    (expect-eq !>([13 13]) !>(progress.j))
    (expect-eq !>([%stage %translate]) !>((snag 0 events)))
    (expect-eq !>([%progress 1 13]) !>((snag 1 events)))
    (expect-eq !>([%result %ok 100 80 0 12]) !>((rear events)))
    (expect-eq !>(1) !>((lent diags.j)))
    (expect !>((~(has by artifacts.j) %report)))
    (expect !>((~(has by artifacts.j) %translation)))
    (expect !>(!(~(has by artifacts.j) %cfg)))
  ==
::
++  test-translate-artifacts
  =/  [evs=(list event) j=job]  (run-all (init:job-lib (demo-req [%translate [%none | &]])))
  ;:  weld
    (expect !>((~(has by artifacts.j) %report)))
    (expect !>((~(has by artifacts.j) %translation)))
    (expect !>((~(has by artifacts.j) %cfg)))
  ==
::
++  test-pause-resume-identical
  ::  interrupting after any step never changes the stream or final job
  =/  j0  (init:job-lib (demo-req check-op))
  =/  full  (run-all j0)
  =/  r1  (step:job-lib j0)
  ?>  ?=(%more -.r1)
  =/  resumed  (run-all job.r1)
  ;:  weld
    (expect-eq !>(-.full) !>((weld events.r1 -.resumed)))
    (expect-eq !>(+.full) !>(+.resumed))
  ==
::
++  test-limited-states
  =/  req  (demo-req check-op)
  =.  max-states.limits.req  50
  =/  [events=(list event) j=job]  (run-all (init:job-lib req))
  ;:  weld
    (expect-eq !>(`[%limited %states [75 60 0 9]]) !>(result.j))
    (expect-eq !>(%terminal) !>(stage.j))
    (expect-eq !>([%result %limited %states 75 60 0 9]) !>((rear events)))
    (expect-eq !>(~) !>(pending.j))
  ==
::
++  test-limited-depth
  =/  req  (demo-req check-op)
  =.  max-depth.limits.req  5
  =/  [evs=(list event) j=job]  (run-all (init:job-lib req))
  (expect-eq !>(`[%limited %depth [50 40 0 6]]) !>(result.j))
::
++  test-limited-artifact
  =/  req  (demo-req check-op)
  =.  max-artifact.limits.req  4
  =/  [evs=(list event) j=job]  (run-all (init:job-lib req))
  ;:  weld
    (expect-eq !>(`[%limited %artifact [100 80 0 12]]) !>(result.j))
    (expect-eq !>(~) !>(artifacts.j))
  ==
::
++  test-simulate-run
  =/  [evs=(list event) j=job]  (run-all (init:job-lib (demo-req sim-op)))
  ;:  weld
    (expect-eq !>(`[%ok [20 20 0 8]]) !>(result.j))
    (expect-eq !>([10 10]) !>(progress.j))
  ==
::
++  test-terminal-step-idempotent
  =/  [evs=(list event) j=job]  (run-all (init:job-lib (demo-req check-op)))
  =/  r  (step:job-lib j)
  ;:  weld
    (expect-eq !>(%stop) !>(-.r))
    (expect-eq !>(~) !>(events.r))
    (expect-eq !>(j) !>(job.r))
  ==
::
::  +|  Real Pipeline Integration (unit 13)
::
::
++  real-bundle
  ::  an inline single-module bundle with a config, so the job engine
  ::  runs the real model checker (lib/tla/check) end to end
  |=  [spec=@t cfg=@t]
  ^-  source-bundle
  [%inline 'spec' (malt ~[['spec' spec]]) `cfg]
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
++  invfail-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = x + 1
  Inv == x < 3
  ====
  '''
::
++  mc-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::
::  a passing spec model-checks to %ok with the real state counts
++  test-real-check-ok
  =/  req  `request`[check-op (real-bundle cyc-spec mc-cfg) default-limits:job-lib |]
  =/  [evs=(list event) j=job]  (run-all (init:job-lib req))
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.j))
    (expect !>((~(has by artifacts.j) %report)))
  ==
::
::  a failing invariant yields a real %violated result
++  test-real-check-violation
  =/  req  `request`[check-op (real-bundle invfail-spec mc-cfg) default-limits:job-lib |]
  =/  [evs=(list event) j=job]  (run-all (init:job-lib req))
  (expect-eq !>(`[%violated [%invariant 'Inv'] [4 4 0 4]]) !>(result.j))
::
::  the real check is bounded by max-states and yields %limited
++  test-real-check-limited
  =/  req  `request`[check-op (real-bundle cyc-spec mc-cfg) default-limits:job-lib |]
  =.  max-states.limits.req  2
  =/  [evs=(list event) j=job]  (run-all (init:job-lib req))
  (expect-eq !>(%limited) !>(?~(result.j %none -.u.result.j)))
::
::  pause/resume stays identical on the real pipeline too
++  test-real-pause-resume-identical
  =/  req  `request`[check-op (real-bundle cyc-spec mc-cfg) default-limits:job-lib |]
  =/  j0  (init:job-lib req)
  =/  full  (run-all j0)
  =/  r1  (step:job-lib j0)
  ?>  ?=(%more -.r1)
  =/  resumed  (run-all job.r1)
  (expect-eq !>(+.full) !>(+.resumed))
--
