/-  *tla-lus
/+  *test
/=  job-lib  /lib/tla/job
|%
  ::  Tests For The Resumable Job Kernel (unit P2-1)
  ::
  ::  Every plan invariant the kernel owns is exercised here: typed
  ::  rejection of unsupported requests, budgeted slicing with a
  ::  persisted continuation, pause/resume identity at every slice
  ::  boundary, and limit enforcement at the point of growth.
  ::
+$  jb  job-2:job-lib
::
++  t0  ~2026.7.16
::
++  lim  default-limits:job-lib
::
++  bundle
  |=  [spec=@t cfg=(unit @t)]
  ^-  source-bundle
  [%inline 'spec' (malt ~[['spec' spec]]) cfg]
::
++  check-req
  |=  [spec=@t cfg=@t]
  ^-  request
  [[%check [| ~ [%exhaustive &]]] (bundle spec `cfg) lim |]
::
++  sim-req
  |=  [spec=@t cfg=@t seed=@ud num=@ud depth=@ud]
  ^-  request
  [[%check [| ~ [%simulate seed num depth]]] (bundle spec `cfg) lim |]
::
++  analyze-req
  |=  mods=(list [module-name @t])
  ^-  request
  =/  root  ?~(mods 'spec' -.i.mods)
  [[%analyze [& | | |]] [%inline root (malt mods) ~] lim |]
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
++  dead-spec
  ::  deadlocks at x = 2 (the conjunct filters every successor)
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x < 2 /\ x' = x + 1
  Inv == x < 9
  ====
  '''
::
++  live-spec
  ::  []P over the 4-cycle; PGood holds everywhere, PBad fails at x = 2
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  PGood == [](x < 4)
  PBad == [](x < 2)
  Lead == (x = 0) ~> (x = 1)
  ====
  '''
::
++  mc-cfg    'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
++  bare-cfg  'INIT Init\0aNEXT Next\0a'
::
++  run-all
  ::  step to termination, collecting the full event stream
  |=  [j=jb budget=@ud]
  ^-  [(list event) jb]
  =/  acc=(list event)  ~
  |-  ^-  [(list event) jb]
  =/  r  (step:job-lib j budget t0)
  ?-  -.r
    %stop  [(weld acc events.r) job.r]
    %more  $(j job.r, acc (weld acc events.r))
  ==
::
++  run-k
  ::  k bounded steps, then stop early
  |=  [j=jb budget=@ud k=@ud]
  ^-  [(list event) jb]
  =/  acc=(list event)  ~
  |-  ^-  [(list event) jb]
  ?:  =(0 k)  [acc j]
  =/  r  (step:job-lib j budget t0)
  ?-  -.r
    %stop  [(weld acc events.r) job.r]
    %more  $(j job.r, k (dec k), acc (weld acc events.r))
  ==
::
++  count-steps
  |=  [j=jb budget=@ud]
  ^-  @ud
  =/  n  0
  |-  ^-  @ud
  =/  r  (step:job-lib j budget t0)
  ?-  -.r
    %stop  +(n)
    %more  $(j job.r, n +(n))
  ==
::
++  every-boundary
  ::  interrupting after any slice must never change the event stream
  ::  or the final job noun (plan invariant 6)
  |=  [req=request budget=@ud]
  ^-  tang
  =/  j0    (init:job-lib req t0)
  =/  full  (run-all j0 budget)
  =/  n     (count-steps j0 budget)
  =/  i  1
  =|  out=tang
  |-  ^-  tang
  ?:  (gte i n)  out
  =/  pa    (run-k j0 budget i)
  =/  rest  (run-all +.pa budget)
  %=  $
    i    +(i)
    out  ;:  weld
           out
           (expect-eq !>(-.full) !>((weld -.pa -.rest)))
           (expect-eq !>(+.full) !>(+.rest))
         ==
  ==
::
::  +|  Validation: Typed Rejections
::
::
++  test-validate-ok
  (expect-eq !>(~) !>((validate:job-lib (check-req cyc-spec mc-cfg))))
::
++  test-validate-clay-rejected
  =/  req=request
    :*  [%check [| ~ [%exhaustive &]]]
        [%clay ~zod %spec da+t0 /spec ~ ~]
        lim  |
    ==
  %+  expect-eq
    !>(`'unsupported: %clay sources are not loaded yet (unit 10)')
  !>((validate:job-lib req))
::
++  test-validate-translate-rejected
  =/  req=request
    [[%translate [%none | &]] (bundle cyc-spec ~) lim |]
  %+  expect-eq
    !>(`'unsupported: PlusCal translation is not ported yet (unit 8)')
  !>((validate:job-lib req))
::
++  test-validate-analyze-flags-rejected
  =/  req=request
    [[%analyze [& & | |]] (bundle cyc-spec ~) lim |]
  %+  expect-eq
    !>(`'unsupported: %analyze semantic stage is not wired yet (unit 3)')
  !>((validate:job-lib req))
::
++  test-validate-translate-before-check-rejected
  =/  req=request
    [[%check [& ~ [%exhaustive &]]] (bundle cyc-spec `mc-cfg) lim |]
  %+  expect-eq
    !>(`'unsupported: translate-before-check is not ported yet (unit 8)')
  !>((validate:job-lib req))
::
++  test-validate-check-needs-config
  =/  req=request
    [[%check [| ~ [%exhaustive &]]] (bundle cyc-spec ~) lim |]
  %+  expect-eq
    !>(`'a %check request requires a config')
  !>((validate:job-lib req))
::
++  test-validate-empty-bundle
  =/  req=request
    [[%check [| ~ [%exhaustive &]]] [%inline 'spec' ~ `mc-cfg] lim |]
  (expect-eq !>(`'empty source bundle') !>((validate:job-lib req)))
::
++  test-validate-missing-root
  =/  req=request
    :*  [%check [| ~ [%exhaustive &]]]
        [%inline 'Nope' (malt ~[['spec' cyc-spec]]) `mc-cfg]
        lim  |
    ==
  (expect-eq !>(`'root module not in bundle') !>((validate:job-lib req)))
::
++  test-validate-oversized-source
  =/  req  (check-req cyc-spec mc-cfg)
  =.  max-source.limits.req  8
  (expect-eq !>(`'source exceeds limit') !>((validate:job-lib req)))
::
++  test-validate-too-many-modules
  =/  req=request
    :*  [%check [| ~ [%exhaustive &]]]
        [%inline 'A' (malt ~[['A' cyc-spec] ['B' cyc-spec]]) `mc-cfg]
        lim  |
    ==
  =.  max-modules.limits.req  1
  (expect-eq !>(`'too many modules') !>((validate:job-lib req)))
::
::  +|  Planning
::
::
++  test-plan-shapes
  ;:  weld
    %+  expect-eq
      !>(`(list stage)`~[%parse %config %explore])
    !>((plan:job-lib (check-req cyc-spec mc-cfg)))
  ::
    =/  live-cfg  'INIT Init\0aNEXT Next\0aPROPERTY PGood\0a'
    %+  expect-eq
      !>(`(list stage)`~[%parse %config %explore %liveness])
    !>((plan:job-lib (check-req live-spec live-cfg)))
  ::
    %+  expect-eq
      !>(`(list stage)`~[%parse %config %simulate])
    !>((plan:job-lib (sim-req cyc-spec bare-cfg 42 3 8)))
  ::
    %+  expect-eq
      !>(`(list stage)`~[%parse %terminal])
    !>((plan:job-lib (analyze-req ~[['spec' cyc-spec]])))
  ==
::
::  +|  Safety Checking Through The Kernel
::
::
++  test-check-ok
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec mc-cfg) t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.j))
    (expect-eq !>(%terminal) !>(stage.j))
    (expect-eq !>([3 3]) !>(progress.j))
    (expect-eq !>([%stage %parse]) !>((snag 0 evs)))
    (expect-eq !>([%result %ok 5 4 0 4]) !>((rear evs)))
    (expect !>((~(has by artifacts.j) %report)))
    (expect !>(!(~(has by artifacts.j) %trace)))
    (expect-eq !>(~) !>(cont.j))
  ==
::
++  test-check-budget-independent
  ::  the final job is identical whatever the per-event budget
  =/  j0  (init:job-lib (check-req cyc-spec mc-cfg) t0)
  =/  a  (run-all j0 256)
  =/  b  (run-all j0 1)
  ;:  weld
    (expect-eq !>(+.a) !>(+.b))
    ::  budget 1 slices the search across many more events
    (expect !>((gth (count-steps j0 1) (count-steps j0 256))))
  ==
::
++  test-check-violation
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req invfail-spec mc-cfg) t0) 256)
  ;:  weld
    (expect-eq !>(`[%violated [%invariant 'Inv'] [4 4 0 4]]) !>(result.j))
    (expect !>((~(has by artifacts.j) %report)))
    (expect !>((~(has by artifacts.j) %trace)))
  ==
::
++  test-check-trace-artifact
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req invfail-spec mc-cfg) t0) 256)
  =/  art  (~(got by artifacts.j) %trace)
  ?>  ?=(%trace -.art)
  =/  tr  trace.art
  ;:  weld
    (expect-eq !>(%safety) !>(kind.tr))
    (expect-eq !>(4) !>((lent states.tr)))
    (expect-eq !>(~) !>(loop-start.tr))
    (expect-eq !>([1 ~ ~[['x' '0']]]) !>((snag 0 states.tr)))
    =/  s2  (snag 1 states.tr)
    (expect-eq !>(`'Next') !>(?~(action.s2 ~ `name.u.action.s2)))
  ==
::
++  test-check-deadlock
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req dead-spec mc-cfg) t0) 256)
  (expect-eq !>(`[%violated [%deadlock ~] [3 3 0 3]]) !>(result.j))
::
++  test-check-deadlock-disabled
  =/  req=request
    [[%check [| ~ [%exhaustive |]]] (bundle dead-spec `mc-cfg) lim |]
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  (expect-eq !>(`[%ok [3 3 0 3]]) !>(result.j))
::
++  test-pause-resume-every-boundary-safety
  (every-boundary (check-req cyc-spec mc-cfg) 1)
::
::  +|  Limits At The Point Of Growth
::
::
++  test-limited-states
  =/  req  (check-req cyc-spec mc-cfg)
  =.  max-states.limits.req  2
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  ;:  weld
    (expect-eq !>(`%limited) !>(?~(result.j ~ `-.u.result.j)))
    %+  expect-eq
      !>(`%states)
    !>(?:(?&(?=(^ result.j) ?=(%limited -.u.result.j)) `kind.u.result.j ~))
  ==
::
++  test-limited-depth
  =/  req  (check-req invfail-spec bare-cfg)
  =.  max-depth.limits.req  2
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  %+  expect-eq
    !>(`%depth)
  !>(?:(?&(?=(^ result.j) ?=(%limited -.u.result.j)) `kind.u.result.j ~))
::
++  test-limited-time
  ::  max-time is checked on entry to every slice
  =/  j  (init:job-lib (check-req cyc-spec mc-cfg) t0)
  =/  r  (step:job-lib j 256 (add t0 ~m11))
  ;:  weld
    (expect-eq !>(%stop) !>(-.r))
    (expect-eq !>(`[%limited %time *run-stats]) !>(result.job.r))
  ==
::
++  test-limited-artifact
  =/  req  (check-req cyc-spec mc-cfg)
  =.  max-artifact.limits.req  4
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  ;:  weld
    (expect-eq !>(`[%limited %artifact [5 4 0 4]]) !>(result.j))
    (expect-eq !>(~) !>(artifacts.j))
  ==
::
::  +|  Config Honesty
::
::
++  test-config-unknown-key
  =/  cfg  'INIT Init\0aNEXT Next\0aCONSTANT N\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  (expect-eq !>(`[%failed 'unsupported config key: CONSTANT']) !>(result.j))
::
++  test-config-duplicate-key
  =/  cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aINVARIANT Inv\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  (expect-eq !>(`[%failed 'duplicate config key: INVARIANT']) !>(result.j))
::
++  test-config-missing-init
  =/  cfg  'NEXT Next\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  (expect-eq !>(`[%failed 'no INIT in config']) !>(result.j))
::
++  test-config-unknown-invariant
  =/  cfg  'INIT Init\0aNEXT Next\0aINVARIANT Nope\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  %+  expect-eq
    !>(`[%failed 'no definition for INVARIANT Nope'])
  !>(result.j)
::
++  test-parse-error-fails
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req 'not a module' mc-cfg) t0) 256)
  ;:  weld
    (expect-eq !>(`%failed) !>(?~(result.j ~ `-.u.result.j)))
    (expect-eq !>(1) !>((lent diags.j)))
  ==
::
::  +|  Liveness Through The Kernel
::
::
++  live-good-cfg  'INIT Init\0aNEXT Next\0aPROPERTY PGood\0a'
++  live-bad-cfg   'INIT Init\0aNEXT Next\0aPROPERTY PBad\0a'
++  lead-cfg       'INIT Init\0aNEXT Next\0aPROPERTY Lead\0a'
::
++  test-live-ok
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req live-spec live-good-cfg) t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.j))
    (expect-eq !>([4 4]) !>(progress.j))
  ==
::
++  test-live-violation
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req live-spec live-bad-cfg) t0) 256)
  =/  art  (~(got by artifacts.j) %trace)
  ?>  ?=(%trace -.art)
  ;:  weld
    (expect-eq !>(`[%violated [%property 'PBad'] [5 4 0 4]]) !>(result.j))
    (expect-eq !>(%lasso) !>(kind.trace.art))
    (expect-eq !>(`(lent states.trace.art)) !>(loop-start.trace.art))
  ==
::
++  test-live-unsupported-form
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req live-spec lead-cfg) t0) 256)
  %+  expect-eq
    !>(`[%failed 'unsupported: temporal property form (only <>P, []<>P, []P; unit 8)'])
  !>(result.j)
::
++  test-pause-resume-every-boundary-liveness
  (every-boundary (check-req live-spec live-bad-cfg) 1)
::
::  +|  Simulation Through The Kernel
::
::
++  test-sim-ok-deterministic
  =/  req  (sim-req cyc-spec bare-cfg 42 3 8)
  =/  [evs-a=(list event) ja=jb]  (run-all (init:job-lib req t0) 256)
  =/  [evs-b=(list event) jz=jb]  (run-all (init:job-lib req t0) 256)
  ;:  weld
    (expect-eq !>(ja) !>(jz))
    (expect-eq !>(`%ok) !>(?~(result.ja ~ `-.u.result.ja)))
  ==
::
++  test-sim-finds-violation
  =/  req  (sim-req invfail-spec mc-cfg 1 1 10)
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  ;:  weld
    %+  expect-eq
      !>(`[%invariant 'Inv'])
    !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~))
    (expect !>((~(has by artifacts.j) %trace)))
  ==
::
++  test-pause-resume-every-boundary-simulate
  ::  the saved RNG sample must make slicing invisible
  (every-boundary (sim-req cyc-spec bare-cfg 42 3 8) 1)
::
::  +|  Analyze Through The Kernel
::
::
++  test-analyze-ok
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (analyze-req ~[['spec' cyc-spec]]) t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok *run-stats]) !>(result.j))
    (expect-eq !>(~) !>(diags.j))
  ==
::
++  test-analyze-parse-error
  =/  req
    (analyze-req ~[['spec' cyc-spec] ['bad' 'not a module']])
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  ;:  weld
    (expect-eq !>(`[%failed 'syntax errors in 1 module(s)']) !>(result.j))
    (expect-eq !>(1) !>((lent diags.j)))
  ==
::
++  test-analyze-sliced
  ::  one module parsed per work unit; budget 1 forces one per event
  =/  req
    %-  analyze-req
    ~[['a' cyc-spec] ['b' cyc-spec] ['c' cyc-spec]]
  =/  j0  (init:job-lib req t0)
  ;:  weld
    (expect !>((gth (count-steps j0 1) (count-steps j0 256))))
    (expect-eq !>(+:(run-all j0 1)) !>(+:(run-all j0 256)))
  ==
::
++  test-pause-resume-every-boundary-analyze
  %+  every-boundary
    (analyze-req ~[['a' cyc-spec] ['b' cyc-spec] ['c' cyc-spec]])
  1
::
::  +|  Terminal Behavior
::
::
++  test-terminal-step-idempotent
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec mc-cfg) t0) 256)
  =/  r  (step:job-lib j 256 t0)
  ;:  weld
    (expect-eq !>(%stop) !>(-.r))
    (expect-eq !>(~) !>(events.r))
    (expect-eq !>(j) !>(job.r))
  ==
::
++  test-project-hides-cursor
  =/  j0  (init:job-lib (check-req cyc-spec mc-cfg) t0)
  =/  mid  +:(run-k j0 1 2)
  =/  pub  (project:job-lib mid)
  ;:  weld
    (expect-eq !>(request.mid) !>(request.pub))
    (expect-eq !>(stage.mid) !>(stage.pub))
    (expect-eq !>(progress.mid) !>(progress.pub))
  ==
--
