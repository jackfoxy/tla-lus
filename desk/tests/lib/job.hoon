/-  *tla-lus
/+  *test
/=  job-lib  /lib/job
/=  check     /lib/check
|%
  ::  Tests For The Resumable Job Kernel (unit P2-1)
  ::
  ::  Every plan invariant the kernel owns is exercised here: typed
  ::  rejection of unsupported requests, budgeted slicing with a
  ::  persisted continuation, pause/resume identity at every slice
  ::  boundary, and limit enforcement at the point of growth.
  ::
+$  jb  job-3:job-lib
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
++  clay-req
  ::  a %clay %check request over ~zod/%spec at a pinned revision
  |=  [root=module-name cfg=(unit path) roots=(list path)]
  ^-  request
  :*  [%check [| ~ [%exhaustive &]]]
      [%clay ~zod %spec ud+1 root cfg roots]
      lim  |
  ==
::
++  analyze-req
  |=  mods=(list [module-name @t])
  ^-  request
  =/  root  ?~(mods 'spec' -.i.mods)
  [[%analyze [& | | |]] [%inline root (malt mods) ~] lim |]
::
++  analyze-req-f
  ::  an %analyze request with explicit flags [syntax semantic level lint]
  |=  [mods=(list [module-name @t]) flags=analyze-flags]
  ^-  request
  =/  root  ?~(mods 'spec' -.i.mods)
  [[%analyze flags] [%inline root (malt mods) ~] lim |]
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
::  a spec with a state constraint (exercises the cursor's constraint pruning)
++  con-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = x + 1
  Bound == x =< 4
  ====
  '''
++  con-cfg  'INIT Init\0aNEXT Next\0aCONSTRAINT Bound\0a'
::  a symmetric spec (exercises the cursor's permutation group; cfg cord is
::  single-quoted so the model-value set braces are literal)
++  sym-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals, TLC
  CONSTANT P
  VARIABLE x
  Init == \E p \in P : x = p
  Next == \E p \in P : x' = p
  Perms == Permutations(P)
  Inv == TRUE
  ====
  '''
++  sym-cfg  'CONSTANT P = {a, b}\0aSYMMETRY Perms\0aINIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::  a helper module imported by the root spec (multi-module MVP acceptance)
++  helper-mod
  ^~
  '''
  ---- MODULE helper ----
  EXTENDS Naturals
  Lim == 4
  ====
  '''
++  multi-spec
  ::  the root EXTENDS a user helper module (a two-module bundle); the checked
  ::  predicates are root-local — evaluating an operator imported from another
  ::  *user* module is a documented unit-6 residue (only own + INSTANCE defs are
  ::  in the evaluation defmap)
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals, helper
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  Inv == x < 4
  ====
  '''
::
++  undef-spec
  ::  Bar is undefined -> semantic error 4200 (generation phase)
  ^~
  '''
  ---- MODULE spec ----
  Foo == Bar
  ====
  '''
::
++  asm-spec
  ::  a non-constant ASSUME -> level error 4206 (level phase)
  ^~
  '''
  ---- MODULE spec ----
  VARIABLE x
  ASSUME x = x
  ====
  '''
::
++  lint-spec
  ::  a record field shadowing a definition -> lint warning 4802
  ^~
  '''
  ---- MODULE spec ----
  bar == 23
  R == [bar |-> 42]
  ====
  '''
::
++  analyze-run
  ::  drive an analyze request to termination, returning whether the
  ::  verdict failed and the error/warning diagnostics it emitted
  |=  req=request
  ^-  [failed=? errs=(list diagnostic) warns=(list diagnostic)]
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  =/  ds  diags.j
  :+  ?=([~ %failed *] result.j)
    (skim ds |=(d=diagnostic =(%error severity.d)))
  (skim ds |=(d=diagnostic =(%warning severity.d)))
::
++  run-all
  ::  step to termination, collecting the full event stream
  |=  [j=jb budget=@ud]
  ^-  [(list event) jb]
  =/  acc=(list event)  ~
  |-  ^-  [(list event) jb]
  =/  r  (step:job-lib j budget t0)
  ?-  -.r
    %stop   [(weld acc events.r) job.r]
    %more   $(j job.r, acc (weld acc events.r))
    %await  ~|(%inline-run-never-awaits !!)
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
    %stop   [(weld acc events.r) job.r]
    %more   $(j job.r, k (dec k), acc (weld acc events.r))
    %await  ~|(%inline-run-never-awaits !!)
  ==
::
++  count-steps
  |=  [j=jb budget=@ud]
  ^-  @ud
  =/  n  0
  |-  ^-  @ud
  =/  r  (step:job-lib j budget t0)
  ?-  -.r
    %stop   +(n)
    %more   $(j job.r, n +(n))
    %await  ~|(%inline-run-never-awaits !!)
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
::  a %clay bundle is accepted (unit 10.1); what it can be rejected for
::  before any read is its reference shape and the missing config
++  test-validate-clay
  ;:  weld
    %+  expect-eq
      !>(~)
    !>((validate:job-lib (clay-req 'spec' `/src/cfg/txt ~[/src])))
  ::
    %+  expect-eq
      !>(`'a %check request requires a config')
    !>((validate:job-lib (clay-req 'spec' ~ ~[/src])))
  ::
    %+  expect-eq
      !>(`'a %clay bundle needs at least one module-search root')
    !>((validate:job-lib (clay-req 'spec' `/src/cfg/txt ~)))
  ::
    %+  expect-eq
      !>(`'empty root module name')
    !>((validate:job-lib (clay-req '' `/src/cfg/txt ~[/src])))
  ==
::
++  test-validate-translate-rejected
  =/  req=request
    [[%translate [%none | &]] (bundle cyc-spec ~) lim |]
  %+  expect-eq
    !>(`'unsupported: PlusCal translation is not ported yet (unit 8)')
  !>((validate:job-lib req))
::
++  test-validate-analyze-accepted
  ::  the semantic/level/lint flags are wired (unit 4.8); a well-formed
  ::  bundle validates
  =/  req=request
    [[%analyze [& & & &]] (bundle cyc-spec ~) lim |]
  (expect-eq !>(~) !>((validate:job-lib req)))
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
  ::
    ::  any deeper flag adds the %semantic stage
    %+  expect-eq
      !>(`(list stage)`~[%parse %semantic %terminal])
    !>((plan:job-lib (analyze-req-f ~[['spec' cyc-spec]] [& & & &])))
  ::
    ::  a Clay bundle loads its sources first (unit 10.1)
    %+  expect-eq
      !>(`(list stage)`~[%modules %parse %config %explore])
    !>((plan:job-lib (clay-req 'spec' `/src/cfg/txt ~[/src])))
  ==
::
::  +|  Analyze Pipeline (unit 4.8)
::
::
++  test-analyze-clean-ok
  ::  a well-formed module analyzed at every flag: %ok, no diagnostics
  =/  r  (analyze-run (analyze-req-f ~[['spec' cyc-spec]] [& & & &]))
  ;:  weld
    (expect !>(!failed.r))
    (expect-eq !>(~) !>(errs.r))
    (expect-eq !>(~) !>(warns.r))
  ==
::
++  test-analyze-semantic-error
  ::  an undefined operator fails the run with a 4200 at the %semantic
  ::  stage; level and lint do not run (SANY gating, via analyze-graph)
  =/  r  (analyze-run (analyze-req-f ~[['spec' undef-spec]] [& & & &]))
  =/  es  errs.r
  ?>  ?=(^ es)
  ;:  weld
    (expect !>(failed.r))
    (expect-eq !>([%sany 4.200]) !>(code.i.es))
    (expect-eq !>(%semantic) !>(stage.i.es))
  ==
::
++  test-analyze-level-error
  ::  a non-constant ASSUME fails the run with a 4206 at the %level stage
  =/  r  (analyze-run (analyze-req-f ~[['spec' asm-spec]] [& & & &]))
  =/  es  errs.r
  ?>  ?=(^ es)
  ;:  weld
    (expect !>(failed.r))
    (expect-eq !>([%sany 4.206]) !>(code.i.es))
    (expect-eq !>(%level) !>(stage.i.es))
  ==
::
++  test-analyze-level-flag-off
  ::  with the level flag off, the 4206 level error is not emitted and
  ::  the run is %ok
  =/  r  (analyze-run (analyze-req-f ~[['spec' asm-spec]] [& & | |]))
  ;:  weld
    (expect !>(!failed.r))
    (expect-eq !>(~) !>(errs.r))
  ==
::
++  test-analyze-lint-warning
  ::  a record-field collision is a %lint warning: emitted but does not
  ::  fail the run
  =/  r  (analyze-run (analyze-req-f ~[['spec' lint-spec]] [& & & &]))
  =/  ws  warns.r
  ?>  ?=(^ ws)
  ;:  weld
    (expect !>(!failed.r))
    (expect-eq !>(~) !>(errs.r))
    (expect-eq !>([%sany 4.802]) !>(code.i.ws))
    (expect-eq !>(%lint) !>(stage.i.ws))
  ==
::
++  test-analyze-lint-flag-off
  ::  with the lint flag off, no 4802 warning is emitted
  =/  r  (analyze-run (analyze-req-f ~[['spec' lint-spec]] [& & & |]))
  (expect-eq !>(~) !>(warns.r))
::
++  test-analyze-budget-independent
  ::  the analyze pipeline is pause/resume identical at every slice
  ;:  weld
    (every-boundary (analyze-req-f ~[['spec' cyc-spec]] [& & & &]) 1)
    (every-boundary (analyze-req-f ~[['spec' lint-spec]] [& & & &]) 1)
    (every-boundary (analyze-req-f ~[['spec' undef-spec]] [& & & &]) 1)
  ==
::
::  +|  Safety Checking Through The Kernel
::
::
++  test-check-ok
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec mc-cfg) t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
    (expect-eq !>(%terminal) !>(stage.j))
    (expect-eq !>([3 3]) !>(progress.j))
    (expect-eq !>([%stage %parse]) !>((snag 0 evs)))
    (expect-eq !>([%result %ok 5 4 0 4 [0 1 1 1]]) !>((rear evs)))
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
    (expect-eq !>(`[%violated [%invariant 'Inv'] [4 4 0 4 [1 1 1 1]]]) !>(result.j))
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
  (expect-eq !>(`[%violated [%deadlock ~] [3 3 0 3 [0 1 1 1]]]) !>(result.j))
::
++  test-check-deadlock-disabled
  =/  req=request
    [[%check [| ~ [%exhaustive |]]] (bundle dead-spec `mc-cfg) lim |]
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  (expect-eq !>(`[%ok [3 3 0 3 [0 1 1 1]]]) !>(result.j))
::
++  test-pause-resume-every-boundary-safety
  (every-boundary (check-req cyc-spec mc-cfg) 1)
::  the extended BFS cursor (Work Unit 7: state/action constraints, symmetry
::  group, out-degree) must resume byte-identically at every slice boundary
++  test-pause-resume-every-boundary-constraint
  (every-boundary (check-req con-spec con-cfg) 1)
++  test-pause-resume-every-boundary-symmetry
  (every-boundary (check-req sym-spec sym-cfg) 1)
::  MVP acceptance: a multi-module inline %check (the root spec EXTENDS a user
::  helper module) is parsed, resolved, and generated as a two-module bundle and
::  runs end to end to a safety verdict matching tlc2.TLC
++  test-multi-module-check
  =/  req=request
    :*  [%check [| ~ [%exhaustive &]]]
        [%inline 'spec' (malt ~[['spec' multi-spec] ['helper' helper-mod]]) `mc-cfg]
        lim  |
    ==
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
::
::  a search whose persisted cursor is under the noun-size bound completes
::  normally (the limit is a defense-in-depth ceiling above max-states)
++  test-noun-size-under-limit
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (check-req cyc-spec mc-cfg) t0) 1)
  (expect-eq !>(%.y) !>(?=([%ok *] (need result.j))))
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
  ?>  ?=(%stop -.r)
  ;:  weld
    (expect-eq !>(%stop) !>(-.r))
    (expect-eq !>(`[%limited %time *run-stats]) !>(result.job.r))
  ==
::
++  test-limited-time-simulation-partial-stats
  ::  a simulation interrupted by max-time reports the PARTIAL statistics
  ::  accumulated so far (states generated > 0), not empty stats (unit 9.5).
  ::  A big run + a small budget guarantees the sim is mid-flight after k slices.
  =/  j0  (init:job-lib (sim-req cyc-spec bare-cfg 42 20 30) t0)
  =/  jp  +:(run-k j0 4 12)
  =/  r   (step:job-lib jp 4 (add t0 ~m11))
  ?>  ?=(%stop -.r)
  ?>  ?=(^ result.job.r)
  ?>  ?=(%limited -.u.result.job.r)
  ;:  weld
    (expect-eq !>(%time) !>(kind.u.result.job.r))
    (expect !>((gth generated.stats.job.r 0)))
  ==
::
++  test-limited-artifact
  =/  req  (check-req cyc-spec mc-cfg)
  =.  max-artifact.limits.req  4
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  ;:  weld
    (expect-eq !>(`[%limited %artifact [5 4 0 4 [0 1 1 1]]]) !>(result.j))
    (expect-eq !>(~) !>(artifacts.j))
  ==
::  the state cap applies to a temporal (~>) run's graph build too, so the
::  8.2-8.6 %check path is reached only within the limit (unit 8.8.3)
++  test-limited-liveness-states
  =/  req  (check-req live-spec lead-cfg)
  =.  max-states.limits.req  2
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  %+  expect-eq
    !>(`%states)
  !>(?:(?&(?=(^ result.j) ?=(%limited -.u.result.j)) `kind.u.result.j ~))
::
::  +|  Config Honesty
::
::
::  a malformed CONSTANT line (bare `CONSTANT N`, no `=`/`<-`) is the
::  real ModelConfig CFG_EXPECTED_SYMBOL (5006), not a made-up rejection
++  test-config-constant-no-value
  =/  cfg  'INIT Init\0aNEXT Next\0aCONSTANT N\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  %+  expect-eq
    !>  `[%failed 'TLC found an error in the configuration file at line 3\0aIt was expecting = or <-, but did not find it.']
  !>  result.j
::
::  a repeated INVARIANT is valid in TLC (a list key accumulates), so the
::  run proceeds; the engine checks the first invariant -> %ok on cyc
++  test-config-repeated-invariant
  =/  cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aINVARIANT Inv\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
::
::  no INIT and no SPECIFICATION with state variables -> TLC_CONFIG 2231
++  test-config-missing-init
  =/  cfg  'NEXT Next\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  %+  expect-eq
    !>  `[%failed 'The configuration file did not specify the initial state predicate.']
  !>  result.j
::
::  an invariant not defined in the spec -> TLC_CONFIG 2229 (validation
::  against the WU3 graph, replacing the old CST body-lookup message)
++  test-config-unknown-invariant
  =/  cfg  'INIT Init\0aNEXT Next\0aINVARIANT Nope\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req cyc-spec cfg) t0) 256)
  %+  expect-eq
    !>  `[%failed 'The invariant Nope specified in the configuration file\0ais not defined in the specification.']
  !>  result.j
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
::  a pure []P property is a state invariant: TLC (and now the port, unit 8.9)
::  checks it via the safety search, not the temporal engine. PGood holds
::  everywhere -> %ok; PBad ([](x<2)) fails at x=2 -> an invariant violation with
::  a safety trace. Box-state runs %parse/%config/%explore (3 stages, no %liveness).
++  test-live-ok
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req live-spec live-good-cfg) t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
    (expect-eq !>([3 3]) !>(progress.j))
  ==
::
++  test-live-violation
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req live-spec live-bad-cfg) t0) 256)
  =/  art  (~(got by artifacts.j) %trace)
  ?>  ?=(%trace -.art)
  ;:  weld
    (expect-eq !>(`[%violated [%invariant 'PBad'] [3 3 0 3 [1 1 1 1]]]) !>(result.j))
    (expect-eq !>(%safety) !>(kind.trace.art))
  ==
::
++  test-live-leadsto
  ::  a leads-to property (unit 8.8.1): (x=0) ~> (x=1) is now handled by the
  ::  8.2–8.6 engine (was an "unsupported form" reject under the first-increment
  ::  recognizer). With no fairness TLC permits stuttering at x=0, so it never
  ::  reaches x=1 — the property is violated.
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req live-spec lead-cfg) t0) 256)
  %+  expect-eq
    !>(`[%violated [%property 'Lead'] [5 4 0 4 [0 1 1 1]]])
  !>(result.j)
::
++  test-pause-resume-every-boundary-liveness
  (every-boundary (check-req live-spec live-bad-cfg) 1)
::  the sliced 8.2-8.6 %check path (unit 8.8.2a): the leads-to property runs the
::  tableau/product build a slice at a time, so budget 1 pauses at every
::  product-step boundary — the verdict, lasso, and job noun must be identical
++  test-pause-resume-every-boundary-leadsto
  (every-boundary (check-req live-spec lead-cfg) 1)
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
++  live-viol-spec
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
++  live-prop-cfg  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
::  a temporal PROPERTY is checked per behavior during simulation (9.3a); the
::  %sim kont round-trips the normalized `oss` across the config->sim events
++  test-sim-finds-property
  =/  req  (sim-req live-viol-spec live-prop-cfg 1 3 8)
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  ;:  weld
    %+  expect-eq
      !>(`[%property 'Live'])
    !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~))
    (expect !>((~(has by artifacts.j) %trace)))
  ==
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
    (expect-eq !>(`[%failed 'analysis found 1 error(s)']) !>(result.j))
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
  ?>  ?=(%stop -.r)
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
::
::  +|  Agent-Wide Quotas And Retention (unit 10.4)
::
::  Every figure is derived from the jobs map, so a deleted job frees its
::  quota by construction and the accounting cannot drift from the store.
::
++  small-quota
  ^-  gquota:job-lib
  [max-jobs=2 max-retained=400 max-inflight=1.000]
::
++  active-job
  |=  start=@da
  ^-  jb
  (init:job-lib (check-req cyc-spec mc-cfg) start)
::
++  done-job
  ::  a terminal job holding `n` bytes of report artifact
  |=  [start=@da n=@ud]
  ^-  jb
  =/  j  (active-job start)
  =.  result.j     `[%ok *run-stats]
  =.  stage.j      %terminal
  =.  artifacts.j  (~(put by artifacts.j) %report [%text (fil 3 n 'x')])
  j
::
++  jmap
  |=  l=(list [req-id jb])
  ^-  (map req-id jb)
  (malt l)
::
++  test-quota-active-jobs
  ::  a job past the concurrency bound is refused, naming the bound;
  ::  terminal jobs do not count against it
  =/  js  (jmap ~[[~.a (active-job t0)] [~.b (active-job t0)]])
  =/  fin  (jmap ~[[~.a (done-job t0 0)] [~.b (done-job t0 0)]])
  ;:  weld
    (expect-eq !>(2) !>((active-count:job-lib js)))
    (expect-eq !>(0) !>((active-count:job-lib fin)))
    %+  expect-eq
      !>(`'global limit: too many active jobs')
    !>((quota-reject:job-lib js small-quota (check-req cyc-spec mc-cfg)))
    %+  expect-eq
      !>(~)
    !>((quota-reject:job-lib fin small-quota (check-req cyc-spec mc-cfg)))
  ==
::
++  test-quota-retained-bytes
  ::  a full artifact store refuses new work rather than growing
  =/  js  (jmap ~[[~.a (done-job t0 500)]])
  ;:  weld
    (expect !>((gth (retained-bytes:job-lib js) 400)))
    %+  expect-eq
      !>(`'global limit: retained artifact bytes; delete a result first')
    !>((quota-reject:job-lib js small-quota (check-req cyc-spec mc-cfg)))
    ::  deleting the job frees the quota, with no counter to update
    %+  expect-eq
      !>(~)
    !>((quota-reject:job-lib (~(del by js) ~.a) small-quota (check-req cyc-spec mc-cfg)))
  ==
::
++  test-quota-inflight-source
  ::  an active job holds source bytes: an inline bundle exactly what it
  ::  carries, a Clay job the most it is allowed to read (it has not read
  ::  anything yet). A terminal job holds none
  =/  cr  (clay-req 'spec' `/src/cfg/txt ~[/src])
  =.  max-source.limits.cr  1.000
  =/  clay-js  (jmap ~[[~.a (init:job-lib cr t0)]])
  =/  inline-js  (jmap ~[[~.a (active-job t0)]])
  =/  bundle-bytes  (source-charge:job-lib (check-req cyc-spec mc-cfg))
  ;:  weld
    (expect-eq !>(1.000) !>((inflight-source:job-lib clay-js)))
    (expect-eq !>(bundle-bytes) !>((inflight-source:job-lib inline-js)))
    (expect-eq !>(0) !>((inflight-source:job-lib (jmap ~[[~.a (done-job t0 0)]]))))
    %+  expect-eq
      !>(`'global limit: in-flight source bytes')
    !>((quota-reject:job-lib clay-js small-quota (check-req cyc-spec mc-cfg)))
  ==
::
++  test-reclaim-oldest-first
  ::  over the bound, the oldest terminal job gives up its artifacts and
  ::  says so; the result and statistics stay
  =/  js
    %-  jmap
    :~  [~.old (done-job t0 300)]
        [~.new (done-job (add t0 ~h1) 300)]
    ==
  =/  out  (reclaim:job-lib js 400)
  =/  old  (~(got by out) ~.old)
  =/  new  (~(got by out) ~.new)
  ;:  weld
    (expect-eq !>(~) !>(artifacts.old))
    (expect !>((~(has by artifacts.new) %report)))
    (expect-eq !>(`[%ok *run-stats]) !>(result.old))
    (expect-eq !>(`[%lus 403]) !>(?~(diags.old ~ `code.i.diags.old)))
    (expect-eq !>(`%warning) !>(?~(diags.old ~ `severity.i.diags.old)))
  ==
::
++  test-reclaim-spares-active-jobs
  ::  an in-flight job's artifacts are never reclaimed under it
  =/  live  (active-job t0)
  =.  artifacts.live  (~(put by artifacts.live) %report [%text (fil 3 500 'x')])
  =/  out  (reclaim:job-lib (jmap ~[[~.a live]]) 100)
  ;:  weld
    (expect !>((~(has by artifacts:(~(got by out) ~.a)) %report)))
    (expect-eq !>(~) !>(diags:(~(got by out) ~.a)))
  ==
::
++  test-reclaim-under-bound-is-identity
  =/  js  (jmap ~[[~.a (done-job t0 10)]])
  (expect-eq !>(js) !>((reclaim:job-lib js 400)))
::
++  test-noun-bound
  ::  the in-flight noun bound the search and load cursors share
  =/  small  (save-kont:job-lib [%parse ~['a'] ~])
  ;:  weld
    (expect-eq !>(%.n) !>((noun-over:job-lib ~ 10)))
    (expect-eq !>(%.n) !>((noun-over:job-lib small 1.000)))
    (expect-eq !>(%.y) !>((noun-over:job-lib small 1)))
  ==

::
::  +|  Kernel Report == Console Report (R1.8.3)
::
::  The job kernel's sliced %liveness path and `check:check` used to render
::  DIFFERENT reports for the same spec: the kernel passed `~` for the EC
::  2257/2259 stuttering gate (its continuation carried no SPEC name, span or
::  fairness) and `'Next'` for the root action name where the console path
::  passes `sctx`'s `aname` (`Action` under a SPECIFICATION). Both are now on
::  the %live continuation, so the two paths are asserted EQUAL rather than
::  each being spot-checked against its own frozen golden.
++  kernel-report
  ::  run a %check to completion through the kernel and return its %report
  |=  [spec=@t cfg=@t]
  ^-  @t
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req spec cfg) t0) 256)
  =/  a  (~(get by artifacts.j) %report)
  ?~  a  ''
  ?.  ?=(%text -.u.a)  ''
  text.u.a
::
++  console-report
  |=  [spec=@t cfg=@t]
  ^-  @t
  (rap 3 (join '\0a' (check:check spec cfg)))
::
++  same-report
  |=  [spec=@t cfg=@t]
  ^-  tang
  %+  expect-eq
    !>((console-report spec cfg))
  !>((kernel-report spec cfg))
::
::  a STUTTERING counterexample under INIT/NEXT: the console path appends the
::  EC 2257 hint, and the kernel used to drop it
++  test-kernel-report-equals-console-2257
  %+  same-report  live-spec  lead-cfg
::
::  the same property under a SPECIFICATION that carries NO fairness: EC 2259,
::  which names the spec and its source location -- unreachable from the kernel
::  before this unit, because a SPECIFICATION-form config was typed-rejected
++  spec-nofair
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == \/ x' = x
          \/ (x = 0 /\ x' = 1)
  Spec == Init /\ [][Next]_x
  Lead == (x = 0) ~> (x = 1)
  ====
  '''
++  test-kernel-report-equals-console-2259
  %+  same-report  spec-nofair  'SPECIFICATION Spec\0aPROPERTY Lead\0a'
::
::  a SPECIFICATION WITH fairness: no hint at all, and the trace labels come
::  from the decomposed action
++  spec-fair
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = 1 - x
  Spec == Init /\ [][Next]_x /\ WF_x(Next)
  Live == <>[](x = 1)
  ====
  '''
++  test-kernel-report-equals-console-fair
  %+  same-report  spec-fair  'SPECIFICATION Spec\0aPROPERTY Live\0a'
::
::  and a plain safety run under a SPECIFICATION: the verdict the console path
::  reaches, through the kernel
++  spec-safety
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x < 3 /\ x' = x + 1
  Inv == x < 9
  Spec == Init /\ [][Next]_x
  ====
  '''
++  test-kernel-report-equals-console-safety-spec
  %+  same-report  spec-safety  'SPECIFICATION Spec\0aINVARIANT Inv\0a'
::
::  +|  Unsupported Options Are Refused, Never Ignored (R1.8.6)
::
::  VIEW and ALIAS are parsed, carried in the run-spec, and — until R1.8.6 —
::  silently dropped by every engine path. A dropped VIEW is not cosmetic: tlc2
::  fingerprints the VIEW's value, so ignoring one reports MORE distinct states
::  than tlc2 and can change whether a run terminates. Both are now refused.
++  view-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  Inv == x < 9
  V == x % 2
  ====
  '''
++  test-view-refused-not-ignored
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req view-spec 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aVIEW V\0a') t0) 256)
  %+  expect-eq
    !>(`[%failed 'unsupported: VIEW (state fingerprinting through a view function; unit 7)'])
  !>(result.j)
::
++  test-alias-refused-not-ignored
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req view-spec 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aALIAS V\0a') t0) 256)
  %+  expect-eq
    !>(`[%failed 'unsupported: ALIAS (trace rendering through an alias; unit 7)'])
  !>(result.j)
::
::  the same spec WITHOUT the VIEW line still runs: the refusal is keyed on the
::  option, not on the definition being present in the module
++  test-view-definition-alone-is-fine
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req view-spec 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a') t0) 256)
  (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
--
