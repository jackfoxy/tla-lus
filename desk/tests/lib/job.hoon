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
+$  jb  jobstate:job-lib
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
  [[%check [| | | | ~ | ~ [%exhaustive & 0]]] (bundle spec `cfg) lim ~ ~ ~ ~]
::
++  sim-req
  |=  [spec=@t cfg=@t seed=@ud num=@ud depth=@ud]
  ^-  request
  [[%check [| | | | ~ | ~ [%simulate seed num depth |]]] (bundle spec `cfg) lim ~ ~ ~ ~]
::
++  dfid-req
  ::  `tlc2.TLC -workers 1 -dfid <depth>` (R2.5)
  |=  [spec=@t cfg=@t depth=@ud]
  ^-  request
  [[%check [| | | | ~ | ~ [%dfid depth &]]] (bundle spec `cfg) lim ~ ~ ~ ~]
::
++  gen-req
  ::  the same run under `-generate` (R2.4.6): probabilistic successor picking
  |=  [spec=@t cfg=@t seed=@ud num=@ud depth=@ud]
  ^-  request
  [[%check [| | | | ~ | ~ [%simulate seed num depth &]]] (bundle spec `cfg) lim ~ ~ ~ ~]
::
++  clay-req
  ::  a %clay %check request over ~zod/%spec at a pinned revision
  |=  [root=module-name cfg=(unit path) roots=(list path)]
  ^-  request
  :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
      [%clay ~zod %spec ud+1 root cfg roots]
      lim  ~  ~  ~  ~
  ==
::
++  analyze-req
  |=  mods=(list [module-name @t])
  ^-  request
  =/  root  ?~(mods 'spec' -.i.mods)
  [[%analyze [& | | |]] [%inline root (malt mods) ~] lim ~ ~ ~ ~]
::
++  analyze-req-f
  ::  an %analyze request with explicit flags [syntax semantic level lint]
  |=  [mods=(list [module-name @t]) flags=analyze-flags]
  ^-  request
  =/  root  ?~(mods 'spec' -.i.mods)
  [[%analyze flags] [%inline root (malt mods) ~] lim ~ ~ ~ ~]
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
  ::  predicates are root-local here. Imported definitions are in the
  ::  evaluation defmap since unit 6C.1, and since R4.2l the kernel's config
  ::  targets and VARIABLEs follow EXTENDS too (`test-extends-*`)
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
++  test-validate-write-over-source-rejected
  ::  R2.2: a run must not be able to write over the sources it is checking.
  ::  `+write-ref` refuses overlap in EITHER direction, so a target under a
  ::  read root and a read root under the target are both refused.
  =/  req=request
    :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
        [%clay ~zod %base ud+1 'spec' `/spec-cfg/txt ~[/]]
        lim
        `[%base /spec]
        ~  ~  ~
    ==
  %+  expect-eq
    !>  `'write target /spec overlaps a module-search root; a run may not write over its own sources'
  !>((validate:job-lib req))
::
++  test-validate-write-outside-roots-accepted
  ::  the same request with a target that shares no prefix with the roots
  =/  req=request
    :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
        [%clay ~zod %base ud+1 'spec' `/src/spec-cfg/txt ~[/src]]
        lim
        `[%base /out]
        ~  ~  ~
    ==
  (expect-eq !>(~) !>((validate:job-lib req)))
::
++  test-validate-write-inline-accepted
  ::  an %inline bundle declares no search roots, so nothing of its own can
  ::  be written over
  =/  req=request
    [[%check [| | | | ~ | ~ [%exhaustive & 0]]] (bundle cyc-spec `mc-cfg) lim `[%base /out] ~ ~ ~]
  (expect-eq !>(~) !>((validate:job-lib req)))
::
++  test-validate-write-bad-desk-rejected
  =/  req=request
    [[%check [| | | | ~ | ~ [%exhaustive & 0]]] (bundle cyc-spec `mc-cfg) lim `[%'Bad Desk' /out] ~ ~ ~]
  %+  expect-eq
    !>(`'invalid desk name \'Bad Desk\'')
  !>((validate:job-lib req))
::
++  test-validate-syntax-off-rejected
  ::  R2.1: `analyze-flags.syntax` could never mean anything — parsing is
  ::  mandatory, a parse error is fatal (never suppressible), and a SUCCESSFUL
  ::  parse emits no diagnostics (`parse-typed` returns `diags=~`). It was
  ::  accepted and ignored; it is now refused rather than given an invented
  ::  meaning.
  %+  expect-eq
    !>  `'unsupported: syntactic analysis cannot be skipped; every later stage consumes the tree'
  !>((validate:job-lib (analyze-req-f ~[['spec' cyc-spec]] [| & & &])))
::
++  test-validate-syntax-on-accepted
  (expect-eq !>(~) !>((validate:job-lib (analyze-req-f ~[['spec' cyc-spec]] [& & & &]))))
::
++  test-validate-translate-rejected
  =/  req=request
    [[%translate [%none | &]] (bundle cyc-spec ~) lim ~ ~ ~ ~]
  %+  expect-eq
    !>(`'unsupported: PlusCal translation is not ported yet (unit 8)')
  !>((validate:job-lib req))
::
++  test-validate-analyze-accepted
  ::  the semantic/level/lint flags are wired (unit 4.8); a well-formed
  ::  bundle validates
  =/  req=request
    [[%analyze [& & & &]] (bundle cyc-spec ~) lim ~ ~ ~ ~]
  (expect-eq !>(~) !>((validate:job-lib req)))
::
++  test-validate-translate-before-check-rejected
  =/  req=request
    [[%check [& | | | ~ | ~ [%exhaustive & 0]]] (bundle cyc-spec `mc-cfg) lim ~ ~ ~ ~]
  %+  expect-eq
    !>(`'unsupported: translate-before-check is not ported yet (unit 8)')
  !>((validate:job-lib req))
::
++  test-validate-check-needs-config
  =/  req=request
    [[%check [| | | | ~ | ~ [%exhaustive & 0]]] (bundle cyc-spec ~) lim ~ ~ ~ ~]
  %+  expect-eq
    !>(`'a %check request requires a config')
  !>((validate:job-lib req))
::
++  test-validate-empty-bundle
  =/  req=request
    [[%check [| | | | ~ | ~ [%exhaustive & 0]]] [%inline 'spec' ~ `mc-cfg] lim ~ ~ ~ ~]
  (expect-eq !>(`'empty source bundle') !>((validate:job-lib req)))
::
++  test-validate-missing-root
  =/  req=request
    :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
        [%inline 'Nope' (malt ~[['spec' cyc-spec]]) `mc-cfg]
        lim  ~  ~  ~  ~
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
    :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
        [%inline 'A' (malt ~[['A' cyc-spec] ['B' cyc-spec]]) `mc-cfg]
        lim  ~  ~  ~  ~
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
::  +|  -messagesAsErrors (R2.4.5)
::
::  A MATCHED PAIR on the lint warning above: one request, one field different.
::  tlc2 promotes at the moment `MP.printWarning` runs (`Assert.fail` BEFORE
::  `recorder.record`), so the promoted diagnostic never lands as a warning and
::  the run stops there.
++  promote-req
  ::  the lint-warning analyze request, with `codes` promoted to errors
  |=  codes=(set diag-code)
  ^-  request
  [[%analyze [& & & &]] [%inline 'spec' (malt ~[['spec' lint-spec]]) ~] lim ~ codes ~ ~]
::
++  test-promote-warning-fails-the-run
  =/  req  (promote-req (silt ~[`diag-code`[%sany 4.802]]))
  =/  r  (run-all (init:job-lib req t0) 256)
  =/  j  +.r
  =/  as-warn
    (lien diags.j |=(d=diagnostic &(=([%sany 4.802] code.d) =(%warning severity.d))))
  =/  as-err
    (lien diags.j |=(d=diagnostic &(=([%sany 4.802] code.d) =(%error severity.d))))
  ;:  weld
    ::  the verdict is %failed, carrying the warning's own message
    (expect-eq !>(`%failed) !>(?~(result.j ~ `-.u.result.j)))
    ::  and 4802 is recorded as an ERROR, never as a warning: in tlc2 the
    ::  promoted code never reaches `recorder.record` as a warning at all
    (expect-eq !>([| &]) !>([as-warn as-err]))
  ==
::
++  test-promote-off-keeps-the-warning
  ::  the matched half: the same request with an empty set completes, and the
  ::  4802 diagnostic is still a WARNING
  =/  r  (run-all (init:job-lib (promote-req ~) t0) 256)
  =/  j  +.r
  =/  as-warn
    (lien diags.j |=(d=diagnostic &(=([%sany 4.802] code.d) =(%warning severity.d))))
  ;:  weld
    (expect-eq !>(`%ok) !>(?~(result.j ~ `-.u.result.j)))
    (expect-eq !>(&) !>(as-warn))
  ==
::
++  test-promote-unrelated-code-is-inert
  ::  a code the run never emits changes nothing, exactly as tlc2 does with
  ::  `-messagesAsErrors 2143` on a spec that never triggers 2143
  =/  r  (run-all (init:job-lib (promote-req (silt ~[`diag-code`[%tlc 2.143]])) t0) 256)
  =/  j  +.r
  (expect-eq !>(`%ok) !>(?~(result.j ~ `-.u.result.j)))
::
++  test-promote-error-code-is-inert
  ::  promoting a code that is emitted as an ERROR is inert too, and that is
  ::  tlc2's rule and not a port choice: `isTlcMessageAsError` is consulted in
  ::  `MP.printWarning` and nowhere else. Measured, `-messagesAsErrors 2110`
  ::  (an error) leaves a run byte-identical
  =/  base  (check-req invfail-spec mc-cfg)
  =/  req  base(promote (silt ~[`diag-code`[%tlc 2.110]]))
  =/  r  (run-all (init:job-lib req t0) 256)
  =/  j  +.r
  (expect-eq !>(`%violated) !>(?~(result.j ~ `-.u.result.j)))
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
++  print-spec
  ::  R4.2a: every print site tlc2 has -- a constant definition, an ASSUME
  ::  (with a `\E` that prints per witness tried), Init, Next and an invariant
  ^-  @t
  %-  of-wain:format
  :~  '---- MODULE spec ----'
      'EXTENDS Naturals, TLC'
      'K == IF PrintT("const K") THEN 7 ELSE 0'
      'VARIABLE x'
      'Init == x = 0 /\\ PrintT(<<"init", x>>)'
      'Next == x < 2 /\\ x\' = x + 1 /\\ PrintT(<<"next", x, x\'>>)'
      'Inv == PrintT(<<"inv", x>>)'
      'ASSUME Print("assume", K = K)'
      'ASSUME \\E i \\in 1..3 : PrintT(<<"ex", i>>) /\\ i = 2'
      '===='
  ==
::
++  print-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-print-output-artifact
  ::  R4.2a: the `%output` artifact holds the pin's console lines, in the
  ::  pin's order (measured with tla2tools.jar on this spec), whatever the
  ::  slicing
  =/  want=@t
    %-  of-wain:format
    :~  '"const K"'  '"assume"  TRUE'  '<<"ex", 1>>'  '<<"ex", 2>>'
        '<<"init", 0>>'  '<<"inv", 0>>'  '<<"next", 0, 1>>'  '<<"inv", 1>>'
        '<<"next", 1, 2>>'  '<<"inv", 2>>'
    ==
  =/  j0  (init:job-lib (check-req print-spec print-cfg) t0)
  =/  a  (run-all j0 256)
  =/  b  (run-all j0 1)
  ;:  weld
    (expect-eq !>(`[%ok [3 3 0 3 [0 1 1 1]]]) !>(result.+.a))
    (expect-eq !>(`[%text want]) !>((~(get by artifacts.+.a) %output)))
    (expect-eq !>((~(get by artifacts.+.a) %output)) !>((~(get by artifacts.+.b) %output)))
  ==
::
++  test-json-file-artifacts
  ::  R4.2f: `JsonSerialize` / `ndJsonSerialize` are TRUE and their files are
  ::  artifacts named for the path (`+file-art`); the text is what
  ::  tla2tools.jar writes for the same calls (measured)
  =/  spec=@t
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals, Json'
        'VARIABLE x'
        'Init == x = 0 /\\ JsonSerialize("out/Trace.json", <<[a |-> 1]>>)'
        '             /\\ ndJsonSerialize("log.ndjson", <<1, "two">>)'
        'Next == UNCHANGED x'
        '===='
    ==
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req spec 'INIT Init\0aNEXT Next\0a') t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok [2 1 0 1 [0 0 0 0]]]) !>(result.j))
    %+  expect-eq  !>(`[%text '[{"a":1}]'])
    !>((~(get by artifacts.j) ~.file-out-trace.json))
    %+  expect-eq  !>(`[%text '1\0a"two"\0a'])
    !>((~(get by artifacts.j) ~.file-log.ndjson))
  ==
::
++  env-req
  ::  R4.2c/g: a check request carrying an environment and Java properties
  |=  [spec=@t cfg=@t env=(map @t @t) props=(map @t @t)]
  ^-  request
  =/  r  (check-req spec cfg)
  r(env env, props props)
::
++  ioutils-mini
  ::  the one IOUtils operator under test, as a module of that name (the
  ::  override is keyed [IOUtils IOEnv 0], as tlc2 binds it)
  '---- MODULE IOUtils ----\0aIOEnv == CHOOSE r : TRUE\0a====\0a'
::
++  test-ioenv-from-request
  ::  R4.2c: `IOEnv` is the request's environment as a record; an absent
  ::  variable is not in its DOMAIN (the corpus's guarded reads)
  =/  spec=@t
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals, IOUtils'
        'VARIABLE x'
        'Init == x = 0'
        'Next == UNCHANGED x'
        'ASSUME IOEnv.K = "7" /\\ "J" \\notin DOMAIN IOEnv'
        '===='
    ==
  =/  b  [%inline 'spec' (malt ~[['spec' spec] ['IOUtils' ioutils-mini]]) `'INIT Init\0aNEXT Next\0a']
  =/  r0  (check-req spec '')
  =/  r1  r0(src b, env (malt ~[['K' '7']]))
  =/  r2  r0(src b)
  =/  a  (run-all (init:job-lib r1 t0) 256)
  =/  z  (run-all (init:job-lib r2 t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok [2 1 0 1 [0 0 0 0]]]) !>(result.+.a))
    ::  no K: the record has no such field, so the ASSUME fails to evaluate
    (expect !>(?=([~ %failed *] result.+.z)))
  ==
::
++  cdot-spec
  %-  of-wain:format
  :~  '---- MODULE spec ----'
      'EXTENDS Naturals, TLC'
      'VARIABLE x'
      'Init == x = 1'
      'Inc == x\' = x + 1'
      'Dbl == x\' = x * 2'
      'Next == x < 20 /\\ (Inc \\cdot Dbl \\/ Inc)'
      'ASSUME TLCGet("-Dfoo") = "-Dfoo"'
      '===='
  ==
::
++  test-cdot-with-property
  ::  R4.2g: with `tlc2.tool.impl.Tool.cdot=true` the composition runs; the
  ::  pin (`java -Dtlc2.tool.impl.Tool.cdot=true`) reports 58 generated
  ::  (the intermediate states of `Inc \cdot Dbl` included), 30 distinct,
  ::  depth 7. An unset `-D` key reads back as itself
  =/  props  (malt ~[['tlc2.tool.impl.Tool.cdot' 'true']])
  =/  a  (run-all (init:job-lib (env-req cdot-spec 'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a' ~ props) t0) 256)
  =/  st  ?.(?=([~ %ok *] result.+.a) *run-stats stats.u.result.+.a)
  (expect-eq !>([58 30 7]) !>([generated.st distinct.st depth.st]))
::
++  test-cdot-refused-without-property
  ::  R4.2g: without the property, the pin's own refusal
  =/  a  (run-all (init:job-lib (env-req cdot-spec 'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a' ~ ~) t0) 256)
  %+  expect-eq
    !>(`[%failed 'The current version of TLC does not support action composition.  An incomplete implementation can be enabled via the tlc2.tool.impl.Tool.cdot=true java property.'])
  !>(?.(?=([~ %failed *] result.+.a) ~ `[%failed reason.u.result.+.a]))
::
++  test-tlcget-d-property
  ::  R4.2g: `TLCGet("-D<key>")` reads the request's property
  =/  spec=@t
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals, TLC'
        'VARIABLE x'
        'Init == x = 0'
        'Next == UNCHANGED x'
        'ASSUME TLCGet("-Dfoo") = "bar"'
        '===='
    ==
  =/  a  (run-all (init:job-lib (env-req spec 'INIT Init\0aNEXT Next\0a' ~ (malt ~[['foo' 'bar']])) t0) 256)
  (expect-eq !>(`[%ok [2 1 0 1 [0 0 0 0]]]) !>(result.+.a))
::
++  test-json-deserialize-refused
  ::  R4.2f: the JSON readers are refused by name (approved difference)
  =/  spec=@t
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals, Json'
        'VARIABLE x'
        'Init == x = 0'
        'Next == UNCHANGED x'
        'ASSUME ndJsonDeserialize("trace.ndjson") = <<>>'
        '===='
    ==
  =/  a  (run-all (init:job-lib (check-req spec 'INIT Init\0aNEXT Next\0a') t0) 256)
  =/  why=@t  ?.(?=([~ %failed *] result.+.a) '' reason.u.result.+.a)
  %-  expect
  !>  ?=(^ (find "Json!ndJsonDeserialize; it reads a file" (trip why)))
::
++  config-spec
  |=  want=@t
  ^-  @t
  %-  of-wain:format
  :~  '---- MODULE spec ----'
      'EXTENDS Naturals, TLC'
      'VARIABLE x'
      'Init == x = 0'
      'Next == x < 1 /\\ x\' = x + 1'
      (cat 3 'ASSUME ' want)
      '===='
  ==
::
++  test-tlcget-config-bfs
  ::  R4.2w: the exhaustive run's record, as tla2tools.jar prints it
  ::  (`mode |-> "bfs", worker |-> 1, seed |-> "0", fingerprint |->
  ::  "-7992595565342442794", deadlock |-> FALSE`); install names this engine
  =/  sp  %-  config-spec
    %+  rap  3
    :~  'LET c == TLCGet("config") IN c.mode = "bfs" /\\ c.worker = 1 /\\ '
        'c.seed = "0" /\\ c.fingerprint = "-7992595565342442794" /\\ '
        'c.deadlock = FALSE /\\ DOMAIN c = {"mode", "deadlock", "worker", '
        '"seed", "fingerprint", "install"}'
    ==
  =/  a  (run-all (init:job-lib (check-req sp 'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a') t0) 256)
  (expect !>(?=([~ %ok *] result.+.a)))
::
++  test-tlcget-config-generate
  ::  R4.2w: a `-generate` run's record (SimTokenRing, EWD998_opts assume
  ::  `mode = "generate"`); traces and depth are the request's
  =/  sp  %-  config-spec
    %+  rap  3
    :~  'LET c == TLCGet("config") IN c.mode = "generate" /\\ c.traces = 3 /\\ '
        'c.depth = 4 /\\ c.aril = "0" /\\ c.sched = "random"'
    ==
  =/  r  (sim-req sp 'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a' 0 3 4)
  =/  r2  r(op [%check [| | | | ~ | ~ [%simulate 0 3 4 &]]])
  =/  a  (run-all (init:job-lib r2 t0) 256)
  (expect !>(?=([~ %ok *] result.+.a)))
::
++  test-ioexec-refused
  ::  R4.2h: a CommunityModules process operator is refused by name
  =/  spec=@t
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals, IOUtils'
        'VARIABLE x'
        'Init == x = 0'
        'Next == UNCHANGED x'
        'ASSUME IOExec(<<"ls">>).exitValue = 0'
        '===='
    ==
  =/  iou  '---- MODULE IOUtils ----\0aIOExec(c) == CHOOSE r : TRUE\0a====\0a'
  =/  b  [%inline 'spec' (malt ~[['spec' spec] ['IOUtils' iou]]) `'INIT Init\0aNEXT Next\0a']
  =/  r0  (check-req spec '')
  =/  a  (run-all (init:job-lib r0(src b) t0) 256)
  =/  why=@t  ?.(?=([~ %failed *] result.+.a) '' reason.u.result.+.a)
  %-  expect
  !>  ?=(^ (find "IOUtils!IOExec; it runs a process" (trip why)))
::
++  ec2213-why
  ::  the failure reason of a two-module PROPERTY run (R4.2ad)
  |=  [mods=(list [@t @t]) cfg=@t]
  ^-  tape
  =/  b  [%inline 'r' (malt mods) `cfg]
  =/  r0  (check-req '' '')
  =/  a  (run-all (init:job-lib r0(src b) t0) 256)
  ?.  ?=([~ %failed *] result.+.a)  ""
  (trip reason.u.result.+.a)
::
++  ec2213-a
  %-  of-wain:format
  :~  '---- MODULE A ----'
      'EXTENDS Naturals'
      'VARIABLE x'
      'Init == x = 0'
      'Next == x\' = (x + 1) % 3'
      'Bad == \\A i \\in {x} : <>(x = i)'
      '===='
  ==
::
++  test-ec2213-module-extends
  ::  R4.2ad: EC 2213's location names the module the formula is IN (pin:
  ::  `... line 6, col 8 to line 6, col 31 of module A:`), not the root
  =/  r
    '---- MODULE r ----\0aEXTENDS A\0aSpec == Init /\\ [][Next]_x\0a====\0a'
  =/  why  (ec2213-why ~[['r' r] ['A' ec2213-a]] 'SPECIFICATION Spec\0aPROPERTY Bad\0a')
  %+  expect-eq
    !>("TLC cannot handle the temporal formula line 6, col 8 to line 6, col 31 of module A")
  !>((scag 82 why))
::
++  test-ec2213-module-instance
  ::  through an INSTANCE: the instanced module's text (pin: `of module A`)
  =/  r
    %-  of-wain:format
    :~  '---- MODULE r ----'
        'EXTENDS Naturals'
        'VARIABLE y'
        'I == INSTANCE A WITH x <- y'
        'Spec == y = 0 /\\ [][(y\' = (y + 1) % 3)]_y'
        'Prop == I!Bad'
        '===='
    ==
  =/  why  (ec2213-why ~[['r' r] ['A' ec2213-a]] 'SPECIFICATION Spec\0aPROPERTY Prop\0a')
  %+  expect-eq
    !>("TLC cannot handle the temporal formula line 6, col 8 to line 6, col 31 of module A")
  !>((scag 82 why))
::
++  bundle-stats
  ::  [generated distinct depth] of an inline multi-module %check, or the
  ::  failure reason (R4.2 census fixes)
  |=  [root=@t mods=(list [@t @t]) cfg=@t]
  ^-  (each [@ud @ud @ud] @t)
  =/  bun  [%inline root (malt mods) `cfg]
  =/  r0  (check-req '' '')
  =/  a  (run-all (init:job-lib r0(src bun) t0) 256)
  =/  res  result.+.a
  ?~  res  [%| 'no result']
  ?.  ?=(%ok -.u.res)
    [%| ?:(?=(%failed -.u.res) reason.u.res 'not ok')]
  [%& [generated distinct depth]:stats.u.res]
::
++  test-instance-extends-chain
  ::  an unnamed INSTANCE imports what the instanced module itself imports
  ::  through ITS unnamed INSTANCE and EXTENDS (Sailfish: `INSTANCE Sailfish`
  ::  -> `INSTANCE BlockDag` -> `EXTENDS Utils` gives `Max`). Pin: 2/1/1
  =/  u  '---- MODULE U ----\0aEXTENDS Integers\0aMax(S) == CHOOSE x \\in S : \\A y \\in S : y <= x\0a====\0a'
  =/  b  '---- MODULE B ----\0aEXTENDS Integers, U\0aTop == Max({1, 5, 3})\0a====\0a'
  =/  sm
    '---- MODULE S ----\0aEXTENDS Integers\0aINSTANCE B\0aVARIABLE x\0aInit == x = Top\0aNext == UNCHANGED x\0a====\0a'
  =/  r
    '---- MODULE R ----\0aEXTENDS Integers\0aVARIABLE x\0aINSTANCE S\0aInv == x = Max({2, 5})\0a====\0a'
  %+  expect-eq  !>([%& [2 1 1]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['S' sm] ['B' b] ['U' u]]
      'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::
++  test-mod-override-through-instance
  ::  `B <-[V] MB` overrides V's `B` under every instance qualification
  ::  (MCPaxos: `Ballot <-[Voting] MCBallot` with `V == INSTANCE Voting`);
  ::  else `\E b \in Nat` is enumerated. Pin: 4/3/2
  =/  v
    '---- MODULE V ----\0aEXTENDS Naturals\0aB == Nat\0aVARIABLE y\0aVI == y = 0\0aVN == \\E b \\in B : b > y /\\ y\' = b\0a====\0a'
  =/  p
    '---- MODULE P ----\0aEXTENDS Naturals\0aVARIABLE y\0aMB == 0..2\0aW == INSTANCE V\0aInit == W!VI\0aNext == W!VN\0a====\0a'
  %+  expect-eq  !>([%& [4 3 2]])
  !>  %^  bundle-stats  'P'
        ~[['P' p] ['V' v]]
      'CONSTANT B <-[V] MB\0aINIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-mod-override-inherited
  ::  `Nat <- [M]MNat` where M INHERITS Nat (LeastCircularSubstring:
  ::  `Nat <- [ZSequences]ZSeqNat`): tlc2 overrides Nat's one shared
  ::  definition. Pin: 6/3/1
  =/  m  '---- MODULE M ----\0aEXTENDS Naturals\0aSmall == {n \\in Nat : n < 3}\0a====\0a'
  =/  r
    '---- MODULE R ----\0aEXTENDS Naturals, M\0aMNat == 0..5\0aVARIABLE x\0aInit == x \\in Small\0aNext == x\' = (x + 1) % 3\0a====\0a'
  %+  expect-eq  !>([%& [6 3 1]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['M' m]]
      'CONSTANT Nat <- [M]MNat\0aINIT Init\0aNEXT Next\0a'
::
++  test-subst-names-own-var
  ::  `I == INSTANCE A WITH x <- Lx`, where the ROOT's `Lx == x + 1` names
  ::  the root's own `x`: the substitution expression is read outside the
  ::  inner binding of `x` (braf: `file_content <- LogicalFileContent`
  ::  looped). Pin: 5/5/5
  =/  a  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aAN == x\' = x + 1\0aASpec == x = 1 /\\ [][AN]_x\0a====\0a'
  =/  r
    %-  of-wain:format
    :~  '---- MODULE R ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'Lx == x + 1'
        'I == INSTANCE A WITH x <- Lx'
        'Init == x = 0'
        'Next == x < 4 /\\ x\' = x + 1'
        'Prop == I!ASpec'
        '===='
    ==
  %+  expect-eq  !>([%& [5 5 5]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['A' a]]
      'INIT Init\0aNEXT Next\0aPROPERTY Prop\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-live-instance-self-subst
  ::  an unnamed INSTANCE substitutes `d <- d`; a bare `d` in the instanced
  ::  module's temporal PROPERTY must translate as the variable, not chase
  ::  that binding forever (TestMCReachability's `Termination`: one slice
  ::  exhausted the loom). Pin: 3/3/3
  =/  i
    %-  of-wain:format
    :~  '---- MODULE I ----'
        'EXTENDS Naturals'
        'VARIABLES x, d'
        'Init == x = 0 /\\ d = FALSE'
        'Next == x < 2 /\\ x\' = x + 1 /\\ d\' = (x + 1 = 2)'
        'Spec == Init /\\ [][Next]_<<x, d>> /\\ WF_<<x, d>>(Next)'
        'Done == <>(d \\/ x = 5)'
        '===='
    ==
  =/  r  '---- MODULE R ----\0aEXTENDS Naturals\0aVARIABLES x, d\0aINSTANCE I\0a====\0a'
  %+  expect-eq  !>([%& [3 3 3]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['I' i]]
      'SPECIFICATION Spec\0aPROPERTY Done\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-subst-reads-instancer-scope
  ::  `b <- a` names the INSTANTIATING module's `a`, although the instance
  ::  also substitutes its own `a <- x`: a call-by-name substitution is read
  ::  in the scope it was written in (TestGraphs' `Refinement`: `T <- ... \cup
  ::  {.. : succ \in successors}` captured the sibling `successors`, a wrong
  ::  implied-action failure). Pin: 3/3/3
  =/  m  '---- MODULE M ----\0aEXTENDS Naturals\0aVARIABLES a, b\0aStep == b\' = b /\\ a\' = a + 1\0a====\0a'
  =/  r
    %-  of-wain:format
    :~  '---- MODULE R ----'
        'EXTENDS Naturals'
        'VARIABLES x, a'
        'I == INSTANCE M WITH a <- x, b <- a'
        'Init == x = 0 /\\ a = 10'
        'Next == x < 2 /\\ x\' = x + 1 /\\ a\' = a'
        'Prop == [][I!Step]_<<x, a>>'
        '===='
    ==
  %+  expect-eq  !>([%& [3 3 3]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['M' m]]
      'INIT Init\0aNEXT Next\0aPROPERTY Prop\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-subst-state-expr-lazy
  ::  a state-reading `WITH` expression carries level 0 in the graph; it is
  ::  bound by name all the same, so `x'` through the instance reads the
  ::  successor (it read the current-state value: a wrong implied-action
  ::  failure). Pin: 4/4/4
  =/  m  '---- MODULE M ----\0aEXTENDS Naturals\0aVARIABLE x\0aInc == x\' = x + 2\0aNext == Inc\0a====\0a'
  =/  r
    %-  of-wain:format
    :~  '---- MODULE R ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'I == INSTANCE M WITH x <- x * 2'
        'Init == x = 0'
        'RNext == x < 3 /\\ x\' = x + 1'
        'Prop == [][I!Inc]_x'
        '===='
    ==
  %+  expect-eq  !>([%& [4 4 4]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['M' m]]
      'INIT Init\0aNEXT RNext\0aPROPERTY Prop\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-subst-state-op-lazy
  ::  as above through an operator, `y <- Dbl(x)` ("primed variable is
  ::  unassigned in the successor state: y"). Pin: 4/4/4
  =/  n  '---- MODULE N ----\0aEXTENDS Naturals\0aVARIABLE y\0aInc == y\' = y + 2\0a====\0a'
  =/  r
    %-  of-wain:format
    :~  '---- MODULE R ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'Dbl(v) == v * 2'
        'I == INSTANCE N WITH y <- Dbl(x)'
        'Init == x = 0'
        'RNext == x < 3 /\\ x\' = x + 1'
        'Prop == [][I!Inc]_x'
        '===='
    ==
  %+  expect-eq  !>([%& [4 4 4]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['N' n]]
      'INIT Init\0aNEXT RNext\0aPROPERTY Prop\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-subst-sibling-member
  ::  `I!Next` calls its sibling `Inc`, whose `WITH` wrapper binds `x <-
  ::  Dbl(x)` again from inside the instance: the binding in force is kept,
  ::  so `Dbl` is applied once (EWD998ChanID's `active <- Node2Nat(active)`
  ::  was applied twice). Pin: 4/4/4
  =/  m  '---- MODULE M ----\0aEXTENDS Naturals\0aVARIABLE x\0aInc == x\' = x + 2\0aNext == Inc\0a====\0a'
  =/  r
    %-  of-wain:format
    :~  '---- MODULE R ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'Dbl(v) == v * 2'
        'I == INSTANCE M WITH x <- Dbl(x)'
        'Init == x = 0'
        'RNext == x < 3 /\\ x\' = x + 1'
        'Prop == [][I!Next]_x'
        '===='
    ==
  %+  expect-eq  !>([%& [4 4 4]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['M' m]]
      'INIT Init\0aNEXT RNext\0aPROPERTY Prop\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-memo-key-keeps-free-names
  ::  an operator application is memoized with its environment cut to the
  ::  names FREE in its reach: `F` reads the constant `N` freely, and `N` is
  ::  only BOUND in `L`'s `Lib(N)` -- a cut by every name bound anywhere in
  ::  the reach dropped it ("undefined identifier: N", EWD998Chan). Pin: 3/3/3
  =/  l  '---- MODULE L ----\0aEXTENDS Naturals\0aLib(N) == N + 1\0a====\0a'
  =/  r
    %-  of-wain:format
    :~  '---- MODULE R ----'
        'EXTENDS Naturals, L'
        'CONSTANT N'
        'F(x) == x + N + Lib(0)'
        'VARIABLE v'
        'Init == v = F(1)'
        'Next == v < 9 /\\ v\' = v + 1'
        'Inv == v >= 7'
        '===='
    ==
  %+  expect-eq  !>([%& [3 3 3]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['L' l]]
      'CONSTANT N = 5\0aINIT Init\0aNEXT Next\0aINVARIANT Inv\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-memo-const-def-reads-state
  ::  `F` is constant-level in its module, but `c <- x` makes it read the
  ::  state, here through its sibling `G`: the memo keys it with the variables its reach names, never by
  ::  the graph's level (cleared states read "unassigned", TLCSailfish2's
  ::  BlockDag over `vs`). Pin: 4/4/4
  =/  m  '---- MODULE M ----\0aEXTENDS Naturals\0aCONSTANT c\0aF == c + 1\0aG == F * 2\0a====\0a'
  =/  r
    %-  of-wain:format
    :~  '---- MODULE R ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'I == INSTANCE M WITH c <- x'
        'Init == x = 0'
        'Next == x < 3 /\\ x\' = x + 1'
        'Inv == I!G = 2 * (x + 1)'
        '===='
    ==
  %+  expect-eq  !>([%& [4 4 4]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['M' m]]
      'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-subset-assign-supersets
  ::  R4.Q5: `x' \in SUBSET T /\ x \subseteq x'` produces only the
  ::  supersets of x (`+subset-sup`); the counts are the full path's. Pin:
  ::  10/4/2
  =/  sp
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'Init == x = {1}'
        'Next == /\\ x\' \\in SUBSET {1, 2, 3, 4}'
        '        /\\ x \\subseteq x\''
        '        /\\ 3 \\notin x\''
        '===='
    ==
  %+  expect-eq  !>([%& [10 4 2]])
  !>  %^  bundle-stats  'spec'
        ~[['spec' sp]]
      'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-subset-assign-outside
  ::  R4.Q5: A not within T leaves no candidate. Pin: 1/1/1
  =/  sp
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'Init == x = {5}'
        'Next == /\\ x\' \\in SUBSET {1, 2, 3, 4}'
        '        /\\ x \\subseteq x\''
        '===='
    ==
  %+  expect-eq  !>([%& [1 1 1]])
  !>  %^  bundle-stats  'spec'
        ~[['spec' sp]]
      'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-action-argument-solved
  ::  an ACTION passed as an operator argument is bound by name and solved
  ::  where the body uses it (LockHS's `NoStutter(NoHistoryChange(l0(self)))`
  ::  was evaluated eagerly: "primed variable is unassigned"). Pin: 4/4/4
  =/  sp
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals'
        'VARIABLES x, s'
        'Keep(A) == A /\\ UNCHANGED s'
        'Wrap(A) == s = 0 /\\ A'
        'Init == x = 0 /\\ s = 0'
        'Next == Wrap(Keep(x < 3 /\\ x\' = x + 1))'
        '===='
    ==
  %+  expect-eq  !>([%& [4 4 4]])
  !>  %^  bundle-stats  'spec'
        ~[['spec' sp]]
      'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-oparg-sibling-through-instance
  ::  an operator ARGUMENT naming a sibling inside a named instance resolves
  ::  to the instance's copy (MCKVsnap: `satisfyIsolationLevel(s, t, CT_SI)`
  ::  in `CC == INSTANCE ClientCentric`). Pin: 3/3/3
  =/  c
    '---- MODULE C ----\0aEXTENDS Naturals\0aTwice(f(_), a) == f(f(a))\0aInc(a) == a + 1\0aT(a) == Twice(Inc, a)\0a====\0a'
  =/  r
    '---- MODULE R ----\0aEXTENDS Naturals\0aCC == INSTANCE C\0aVARIABLE x\0aInit == x = CC!T(0)\0aNext == x < 6 /\\ x\' = CC!T(x)\0a====\0a'
  %+  expect-eq  !>([%& [3 3 3]])
  !>  %^  bundle-stats  'R'
        ~[['R' r] ['C' c]]
      'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-memb-through-substin
  ::  membership in an instanced definition is decided on the structure
  ::  under its `$SubstIn` wrapper (MCNano's `N!Ledger`): `[D -> SUBSET
  ::  (1..12)]` has 4096^3 elements and must not be built. Pin: 385/64/7
  =/  m
    %-  of-wain:format
    :~  '---- MODULE M ----'
        'EXTENDS Naturals'
        'CONSTANT D'
        'VARIABLE l'
        'Big == [D -> SUBSET (1..12)]'
        'TypeOk == l \\in [{1, 2} -> Big]'
        'MI == l = [i \\in {1, 2} |-> [d \\in D |-> {}]]'
        'MN == \\E i \\in {1, 2}, d \\in D : l\' = [l EXCEPT ![i][d] = {1}]'
        '===='
    ==
  =/  q
    %-  of-wain:format
    :~  '---- MODULE Q ----'
        'EXTENDS Naturals'
        'VARIABLE l'
        'N == INSTANCE M WITH D <- {1, 2, 3}'
        'Init == N!MI'
        'Next == N!MN'
        'Inv == N!TypeOk'
        '===='
    ==
  %+  expect-eq  !>([%& [385 64 7]])
  !>  %^  bundle-stats  'Q'
        ~[['Q' q] ['M' m]]
      'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aCHECK_DEADLOCK FALSE\0a'
::
++  test-sim-alias
  ::  R4.2i: a simulated behavior renders through the ALIAS, each state
  ::  paired with its successor and the last with itself (pin, -simulate:
  ::  `x = 3` / `nx = 3` last)
  =/  spec=@t
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'Init == x = 0'
        'Next == x\' = x + 1'
        'Inv == x < 3'
        'Alias == [x |-> x, nx |-> x\']'
        '===='
    ==
  =/  a  (run-all (init:job-lib (sim-req spec 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aALIAS Alias\0a' 7 1 10) t0) 256)
  =/  rep  (~(get by artifacts.+.a) %report)
  =/  txt=tape  ?.(?=([~ %text *] rep) "" (trip +.u.rep))
  ;:  weld
    (expect !>(?=(^ (find "/\\ x = 2\0a/\\ nx = 3" txt))))
    (expect !>(?=(^ (find "/\\ x = 3\0a/\\ nx = 3" txt))))
    ::  R4.2as: the simulator's labels (pin: `<Init line 4, col 9 to line 4,
    ::  col 13 of module S1>`, then the generating action)
    (expect !>(?=(^ (find "State 1: <Init line 4, col 9 to line 4, col 13 of module spec>" txt))))
    (expect !>(?=(^ (find "State 2: <Next line 5, col 9 to line 5, col 18 of module spec>" txt))))
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
    (expect-eq !>(`[%violated [%invariant 'Inv' %.n] [4 4 0 4 [1 1 1 1]]]) !>(result.j))
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
    [[%check [| | | | ~ | ~ [%exhaustive | 0]]] (bundle dead-spec `mc-cfg) lim ~ ~ ~ ~]
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
    :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
        [%inline 'spec' (malt ~[['spec' multi-spec] ['helper' helper-mod]]) `mc-cfg]
        lim  ~  ~  ~  ~
    ==
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
::
::  R4.2l: an MC-style root that only EXTENDS the module holding the
::  variable, Init, Next and the invariant. The job kernel used to look the
::  config targets up in the ROOT syntax tree and refused it (`no definition
::  for INIT Init`), the cause of about 29 R4.0e census refusals. Expected
::  values: tlc2 at the pin (`-workers 1`), 2026-10-09
++  ext-spec
  ^~
  '''
  ---- MODULE Spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = x + 1
  Inv == x < 2
  ====
  '''
++  ext-mc
  ^~
  '''
  ---- MODULE MC ----
  EXTENDS Spec
  ====
  '''
++  ext-req
  |=  cfg=@t
  ^-  request
  :*  [%check [| | | | ~ | ~ [%exhaustive & 0]]]
      [%inline 'MC' (malt ~[['MC' ext-mc] ['Spec' ext-spec]]) `cfg]
      lim  ~  ~  ~  ~
  ==
++  ext-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::
++  test-extends-config-targets
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (ext-req ext-cfg) t0) 256)
  %+  expect-eq
    !>  `*`[[%invariant 'Inv' %.n] 3 3 0 3]
  !>  ^-  *
      ?.  ?=([~ %violated *] result.j)  result.j
      =*  r  u.result.j
      :*  violation.r
          generated.stats.r  distinct.stats.r  queued.stats.r  depth.stats.r
      ==
::
::  the action label names the module that DEFINES the imported Next, as
::  tlc2 prints it, not the root
++  test-extends-next-label
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (ext-req ext-cfg) t0) 256)
  =/  ra  (~(get by artifacts.j) %report)
  =/  lines=wain
    ?.  ?&(?=(^ ra) ?=(%text -.u.ra))  ~
    (to-wain:format text.u.ra)
  %+  expect-eq
    !>  ^-  wain
    :~  'State 1: <Initial predicate>'
        'State 2: <Next line 5, col 9 to line 5, col 18 of module Spec>'
        'State 3: <Next line 5, col 9 to line 5, col 18 of module Spec>'
    ==
  !>((skim lines |=(l=@t =('State ' (end [3 6] l)))))
::
::  a name NO module defines is still refused, by the config validator and
::  with tlc2's own text, before the kernel's guard: so that guard only ever
::  fired on names an EXTENDed module defines, which is the R4.2l bug
++  test-extends-undefined-invariant
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (ext-req 'INIT Init\0aNEXT Next\0aINVARIANT Nope\0a') t0) 256)
  %+  expect-eq
    !>  `[%failed 'The invariant Nope specified in the configuration file\0ais not defined in the specification.']
  !>(result.j)
::
::  R4.2y: a crash inside a slice seals the job %failed. Before, Gall rolled
::  the event back with the behn wake that drove it, and the job sat
::  `running` until the runner's wall cap (three R4.0e2 census models)
++  test-crash-seals-job
  ::  a stage `+run` has no arm for crashes it (`%tla-lus-unplanned-stage`)
  =/  j0  (init:job-lib (check-req cyc-spec mc-cfg) t0)
  =/  r   (step:job-lib j0(pending ~[%lint], cont ~) 256 t0)
  =/  res  ?:(?=(%stop -.r) result.job.r ~)
  %+  expect-eq
    !>  [%stop %.y 'internal: crashed in %lint']
  !>  :+  -.r
        ?=([~ %failed *] res)
      ?.  ?=([~ %failed *] res)  ''
      (end [3 26] reason.u.res)
::
::  the crash that ports tlc2's `Assert.fail(TLC_LIVE_WRONG_FORMULA_FORMAT)`
::  (`Liveness.classifyExpr`) is that typed error, with tlc2's text and code.
::  Expected: tlc2 at the pin (`-workers 1`), 2026-10-09 -- exit 255,
::  `Error: Temporal formulas containing actions must be of forms <>[]A or []<>A.`
++  wff-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLES i
  Init == i = 0
  Next == i < 5 /\ i' = i + 1
  Spec == Init /\ [][Next]_i
  Live == (<><<Next>>_i) ~> (i = 5)
  ====
  '''
++  test-wrong-formula-format-typed
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req wff-spec 'SPECIFICATION Spec\0aPROPERTY Live\0a') t0) 256)
  %+  expect-eq
    !>  :-  `[%failed 'Temporal formulas containing actions must be of forms <>[]A or []<>A.']
        `[%tlc 2.214]
  !>  :-  result.j
      =/  ds  (skim diags.j |=(d=diagnostic =(%error severity.d)))
      ?~(ds ~ `code.i.ds)
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
::  R4.3: the state bound is checked before each INITIAL state is
::  registered (it was checked only after all of them: LeastCircularSubstring-
::  Medium's 6,400 ran out of time first), so it stops at bound + 1
++  test-limited-states-in-inits
  =/  sp  '---- MODULE spec ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x \\in 0..50\0aNext == UNCHANGED x\0a====\0a'
  =/  req  (check-req sp 'INIT Init\0aNEXT Next\0a')
  =.  max-states.limits.req  10
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  %+  expect-eq  !>(`[%states 11])
  !>  ?.  ?&(?=(^ result.j) ?=(%limited -.u.result.j))  ~
      `[kind distinct.stats]:u.result.j
::
::  R4.3: under a bound an init `x \in {y \in S : P}` takes bound + 1
::  elements, not the whole filter (CoffeeCan3000Beans' ~4.5 million)
++  test-init-filter-bounded
  =/  sp  '---- MODULE spec ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x \\in {y \\in 0..50 : y % 2 = 0}\0aNext == UNCHANGED x\0a====\0a'
  =/  req  (check-req sp 'INIT Init\0aNEXT Next\0a')
  =.  max-states.limits.req  5
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  %+  expect-eq  !>(`[%states 6 6])
  !>  ?.  ?&(?=(^ result.j) ?=(%limited -.u.result.j))  ~
      `[kind generated.stats distinct.stats]:u.result.j
::
::  R4.3: a bounded init that a later conjunct thins below the bound is
::  solved again unbounded, so a truncated init set is never explored:
::  the 5 states x > 40 complete (the bounded pass alone found none)
++  test-init-filter-bound-resolved
  =/  sp  '---- MODULE spec ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x \\in {y \\in 0..50 : y % 2 = 0} /\\ x > 40\0aNext == UNCHANGED x\0a====\0a'
  =/  req  (check-req sp 'INIT Init\0aNEXT Next\0a')
  =.  max-states.limits.req  5
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  %+  expect-eq  !>(`[%ok 5])
  !>  ?.  ?&(?=(^ result.j) ?=(%ok -.u.result.j))  ~
      `[%ok distinct.stats.u.result.j]
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
    (expect-eq !>(`[%violated [%invariant 'PBad' %.n] [3 3 0 3 [1 1 1 1]]]) !>(result.j))
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
    !>(`[%violated [%property 'Lead' %.n] [5 4 0 4 [0 1 1 1]]])
  !>(result.j)
::
::  R4.P7: an end of the search other than an invariant violation pre-empts
::  the temporal check on the kernel path too. tlc2 reports `Deadlock
::  reached` (3 generated, 3 distinct, depth 3) and never runs the liveness
::  check; the kernel reported `internal: unexpected graph outcome`
++  live-deadlock-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x < 2 /\ x' = x + 1
  Lead == (x = 0) ~> (x = 1)
  ====
  '''
::
++  test-live-deadlock-preempts
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req live-deadlock-spec lead-cfg) t0) 256)
  ?>  ?=([~ %violated *] result.j)
  =/  r  u.result.j
  =/  s  stats.r
  %+  expect-eq
    !>([[%deadlock ~] 3 3 0 3])
  !>([violation.r generated.s distinct.s queued.s depth.s])
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
      !>(`[%invariant 'Inv' %.n])
    !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~))
    (expect !>((~(has by artifacts.j) %trace)))
  ==
::
::  +|  DFID Through The Kernel (R2.5)
::
::  Every expectation here is `tlc2.TLC -workers 1 -dfid N` at the pin. The
::  COUNTS are compared, not the trace: the DFS order is drawn from a
::  clock-seeded generator `-seed` does not reach, so two runs of the same jar
::  can report different counterexamples while agreeing on every number.
::
::  +|  EC 2107 / 2110 On The Wire (R2.7.1)
::
::  The two used to arrive as the same `[%invariant name]`. These arms are the
::  point of the split: same operator, same name, different `initial`.
::
++  test-invariant-violated-by-behavior
  ::  EC 2110: found by a behavior, so the result carries a counterexample and
  ::  the full state-graph statistics
  =/  r  (run-all (init:job-lib (check-req invfail-spec mc-cfg) t0) 1.024)
  =/  j  +.r
  ;:  weld
    %+  expect-eq
      !>(`violation`[%invariant 'Inv' %.n])
    !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) violation.u.result.j *violation))
    (expect !>((~(has by artifacts.j) %trace)))
  ==
::
++  test-invariant-violated-by-initial-state
  ::  EC 2107: `Inv == x > 0` is false at `x = 0`, so tlc2 reports it while
  ::  COMPUTING the initial states — no behavior, and no statistics
  =/  spec
    '''
    ---- MODULE spec ----
    EXTENDS Naturals
    VARIABLE x
    Init == x = 0
    Next == x' = x + 1
    Inv == x > 0
    ====
    '''
  =/  r  (run-all (init:job-lib (check-req spec mc-cfg) t0) 1.024)
  =/  j  +.r
  %+  expect-eq
    !>(`violation`[%invariant 'Inv' %.y])
  !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) violation.u.result.j *violation))
::
::  R2.7.15c: an IMPLIED INIT on the KERNEL. The kernel used to compute the
::  bin and drop it, so this spec completed `%ok` where the console reported
::  EC 2108. `finish-arts` prepends `swarn` to the report, and the EC 2255
::  state-level warning rides that channel, so the artifact is the console's
::  output byte for byte -- the same discipline
::  `test-dfid-kernel-report-matches-console` applies to DFID
++  imp-init-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x \in {0, 3}
  Next == x' = x
  Spec == Init /\ [][Next]_x
  ImpInit == x = 0
  ====
  '''
++  imp-init-cfg  'SPECIFICATION Spec\0aPROPERTY ImpInit\0a'
::
++  test-implied-init-kernel
  =/  r  (run-all (init:job-lib (check-req imp-init-spec imp-init-cfg) t0) 1.024)
  =/  j  +.r
  ;:  weld
    ::  no state-graph statistics: the run aborts while computing the initial
    ::  states, and tlc2 prints none
    %+  expect-eq
      !>(`[%violated [%property 'ImpInit' %.y] *run-stats])
    !>(result.j)
    ::  the offending initial state, as the wire trace
    %+  expect-eq  !>(1)
    !>  ^-  @ud
    =/  ta  (~(get by artifacts.j) %trace)
    ?.  ?&(?=(^ ta) ?=(%trace -.u.ta))  0
    ?.  ?=(%safety -.trace.u.ta)  0
    (lent states.trace.u.ta)
  ==
::
++  test-implied-init-kernel-report-matches-console
  =/  r  (run-all (init:job-lib (check-req imp-init-spec imp-init-cfg) t0) 1.024)
  =/  j  +.r
  =/  ra  (~(get by artifacts.j) %report)
  %+  expect-eq
    !>(`@t`(rap 3 (join '\0a' (check:check imp-init-spec imp-init-cfg))))
  !>(?:(?&(?=(^ ra) ?=(%text -.u.ra)) text.u.ra ''))
::
++  test-dfid-plan
  %+  expect-eq
    !>(`(list stage)`~[%parse %config %dfid])
  !>((plan:job-lib (dfid-req cyc-spec bare-cfg 10)))
::
++  test-dfid-ok
  ::  `-dfid 10` on the 4-cycle: the graph is exhausted inside the bound, so
  ::  the completion line prints and the run is %ok at 11/4
  =/  r  (run-all (init:job-lib (dfid-req cyc-spec bare-cfg 10) t0) 1.024)
  =/  j  +.r
  ;:  weld
    (expect-eq !>(`%ok) !>(?~(result.j ~ `-.u.result.j)))
    (expect-eq !>([11 4]) !>([generated.stats.j distinct.stats.j]))
  ==
::
++  test-dfid-bound-is-limited-not-ok
  ::  `-dfid 2` stops AT the bound. tlc2 prints no completion line there, so
  ::  reporting %ok would claim a search it did not perform
  =/  r  (run-all (init:job-lib (dfid-req cyc-spec bare-cfg 2) t0) 1.024)
  =/  j  +.r
  ;:  weld
    %+  expect-eq
      !>(`[%limited %depth])
    !>(?:(?&(?=(^ result.j) ?=(%limited -.u.result.j)) `[%limited kind.u.result.j] ~))
    (expect-eq !>([2 2]) !>([generated.stats.j distinct.stats.j]))
  ==
::
++  test-dfid-finds-violation
  ::  7 generated / 4 distinct, and the counts are the run's FINAL ones: the
  ::  worker keeps walking after `setErrState` because its DFS loop never tests
  ::  `stopCode`, so stopping at the violation would report fewer
  =/  r  (run-all (init:job-lib (dfid-req invfail-spec mc-cfg 10) t0) 1.024)
  =/  j  +.r
  ;:  weld
    %+  expect-eq
      !>(`[%invariant 'Inv' %.n])
    !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~))
    (expect-eq !>([7 4]) !>([generated.stats.j distinct.stats.j]))
    (expect !>((~(has by artifacts.j) %trace)))
  ==
::
++  test-dfid-trace-has-no-action-labels
  ::  DFID's printers carry no action attribution -- `printInvariantTrace`
  ::  prints the ordinal and nothing else -- so no trace state names one
  =/  r  (run-all (init:job-lib (dfid-req invfail-spec mc-cfg 10) t0) 1.024)
  =/  j  +.r
  =/  ta  (~(get by artifacts.j) %trace)
  %+  expect-eq  !>(&)
  !>  ^-  ?
  ?.  ?&(?=(^ ta) ?=(%trace -.u.ta))  |
  ?.  ?=(%safety -.trace.u.ta)  |
  (levy states.trace.u.ta |=(ts=trace-state ?=(~ action.ts)))
::
++  test-dfid-deadlock
  =/  r  (run-all (init:job-lib (dfid-req dead-spec mc-cfg 10) t0) 1.024)
  =/  j  +.r
  %+  expect-eq
    !>(`[%deadlock ~])
  !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~))
::
++  test-dfid-box-state-property-runs
  ::  `[]P` over a state-level P is appended to the config's INVARIANT vector
  ::  by `processConfigProps`, so DFID checks it like any invariant and does
  ::  NOT refuse -- measured at the pin, PBad reports at 4/3
  =/  r  (run-all (init:job-lib (dfid-req live-spec live-bad-cfg 6) t0) 1.024)
  =/  j  +.r
  ;:  weld
    %+  expect-eq
      !>(`[%invariant 'PBad' %.n])
    !>(?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~))
    (expect-eq !>([4 3]) !>([generated.stats.j distinct.stats.j]))
  ==
::
++  test-dfid-box-state-property-holds
  =/  r  (run-all (init:job-lib (dfid-req live-spec live-good-cfg 6) t0) 1.024)
  =/  j  +.r
  ;:  weld
    (expect-eq !>(`%ok) !>(?~(result.j ~ `-.u.result.j)))
    (expect-eq !>([11 4]) !>([generated.stats.j distinct.stats.j]))
  ==
::
++  test-dfid-refuses-genuine-liveness
  ::  `DFIDModelChecker.java:67`, verbatim including the DOUBLE space before
  ::  `Please`. It keys on a genuine temporal property, which is why the two
  ::  box-state cases above run instead of hitting this
  =/  r  (run-all (init:job-lib (dfid-req live-spec lead-cfg 6) t0) 1.024)
  =/  j  +.r
  %+  expect-eq
    !>  :-  ~
    :-  %failed
    %^  cat  3
      'Depth-First Iterative Deepening mode does not support checking liveness '
    %^  cat  3
      'properties (https://github.com/tlaplus/tlaplus/issues/548).  Please check '
    'liveness properties in Breadth-First-Search mode.'
  !>(result.j)
::
++  test-dfid-refuses-continue
  ::  `-continue` under DFID is a tlc2 capability this engine has not built,
  ::  so it is refused BY NAME rather than accepted and ignored (R2.1)
  %+  expect-eq
    !>  `'unsupported: -continue with -dfid (the DFID engine records one violation; use exhaustive mode)'
  !>  %-  validate:job-lib
  [[%check [| | | & ~ | ~ [%dfid 10 &]]] (bundle cyc-spec `bare-cfg) lim ~ ~ ~ ~]
::
++  test-dfid-refuses-difftrace
  ::  measured at the pin, `-difftrace` changes nothing outside `-simulate`
  %+  expect-eq
    !>(`'unsupported: -difftrace outside simulation (tlc2 honours it only in -simulate)')
  !>  %-  validate:job-lib
  [[%check [| | & | ~ | ~ [%dfid 10 &]]] (bundle cyc-spec `bare-cfg) lim ~ ~ ~ ~]
::
++  test-dfid-kernel-report-matches-console
  ::  the kernel's `%report` artifact is the CONSOLE renderer's output, so the
  ::  22-case `tests/lib/dfid` differential covers this path too. Both go
  ::  through `+render-dfid-outcome`; this arm is what keeps them from drifting
  =/  r  (run-all (init:job-lib (dfid-req invfail-spec mc-cfg 10) t0) 1.024)
  =/  j  +.r
  =/  ra  (~(get by artifacts.j) %report)
  %+  expect-eq
    !>  ^-  @t
    %+  rap  3
    %+  join  '\0a'
    (dfid-check:check invfail-spec mc-cfg 10)
  !>(?:(?&(?=(^ ra) ?=(%text -.u.ra)) text.u.ra ''))
::
++  test-pause-resume-every-boundary-dfid
  ::  the DFID cursor is resumable like every other: interrupting after any
  ::  slice changes neither the event stream nor the final job noun
  (every-boundary (dfid-req cyc-spec bare-cfg 6) 1)
::
::  +|  -generate (R2.4.6)
::
::  A MATCHED PAIR: one bundle, one seed, one field different. The nondeterminism
::  sits BELOW the action-decomposition boundary, which is the only place
::  `Tool.probabilistic` is observable -- a top-level `\/` or `\E` is consumed by
::  `Tool.getActions` and the two modes are byte-identical there.
++  gen-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x, y
  Init == x = 0 /\ y = 0
  Next == /\ y' = y + 1
          /\ \E n \in 1..5 : x' = (x + n) % 100
  Inv == x < 30
  ====
  '''
++  gen-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::  `tlc2.TLC -simulate num=1 -workers 1 -seed 1 -depth 20`: 43 states generated,
::  because the exhaustive walk takes every successor of the chosen action
++  test-gen-off-matches-tlc
  =/  r  (run-all (init:job-lib (sim-req gen-spec gen-cfg 1 1 20) t0) 1.024)
  =/  j  +.r
  %+  expect-eq
    !>  [`[%invariant 'Inv' %.n] `43]
  !>  :-  ?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~)
      ?~(result.j ~ `generated.stats.j)
::  the same run with `-generate`: 13, because the probabilistic walk returns at
::  the FIRST successor the functor accepts instead of taking all five. Same
::  verdict KIND, different arithmetic -- so the field reaches the engine rather
::  than being read and ignored
++  test-gen-on-matches-tlc
  =/  r  (run-all (init:job-lib (gen-req gen-spec gen-cfg 1 1 20) t0) 1.024)
  =/  j  +.r
  %+  expect-eq
    !>  [`[%invariant 'Inv' %.n] `13]
  !>  :-  ?:(?&(?=(^ result.j) ?=(%violated -.u.result.j)) `violation.u.result.j ~)
      ?~(result.j ~ `generated.stats.j)
::  a CASE below the decomposition boundary. tlc2 ABORTS there -- exit 255, no
::  model checking at all -- so the port fails the run rather than dropping the
::  action and reporting a completed simulation over whatever actions remain
++  gen-case-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x, y
  Init == x = 0 /\ y = 0
  Next == /\ y' = y + 1
          /\ CASE x < 5 -> x' = x + 1
               [] OTHER -> x' = 0
  Inv == y < 8
  ====
  '''
++  test-gen-case-refused
  =/  r  (run-all (init:job-lib (gen-req gen-case-spec gen-cfg 1 1 20) t0) 1.024)
  =/  j  +.r
  %+  expect-eq
    !>  `%failed
  !>  ?~(result.j ~ `-.u.result.j)
::  the SAME spec under plain `-simulate` runs to a verdict, which is what makes
::  the refusal a property of the probabilistic engine and not of the spec
++  test-gen-case-runs-without-generate
  =/  r  (run-all (init:job-lib (sim-req gen-case-spec gen-cfg 1 1 20) t0) 1.024)
  =/  j  +.r
  %+  expect-eq
    !>  `%violated
  !>  ?~(result.j ~ `-.u.result.j)
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
      !>(`[%property 'Live' %.n])
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
++  test-noun-due-checkpoints
  ::  R4.P8: every change below 32; above it, 16 checkpoints per doubling
  ::  (a crossing measures, a slice inside one bucket does not); no growth
  ::  never measures
  ;:  weld
    (expect-eq !>(%.y) !>((noun-due:job-lib 3 4)))
    (expect-eq !>(%.n) !>((noun-due:job-lib 7 7)))
    (expect-eq !>(%.n) !>((noun-due:job-lib 1.024 1.055)))
    (expect-eq !>(%.y) !>((noun-due:job-lib 1.024 1.088)))
    (expect-eq !>(%.y) !>((noun-due:job-lib 1.000 2.000)))
    (expect-eq !>(%.n) !>((noun-due:job-lib 90.000 90.100)))
  ==

::
::  R4.P2 (H3): a continuation is stored as itself, tagged with its type's
::  hash, so a slice no longer jams, cues and clams the whole search state
++  test-kont-round-trip
  =/  k=kont:job-lib  [%parse ~['a'] ~]
  =/  c  (save-kont:job-lib k)
  ?>  ?=(^ c)
  (expect-eq !>(k) !>((load-kont:job-lib u.c)))
::
::  a continuation written by another build (its tag differs) fails the JOB
::  with the restart notice, never the event
++  test-kont-foreign-tag-restarts
  =/  j0  (init:job-lib (check-req cyc-spec mc-cfg) t0)
  =/  j   j0(stage %parse, cont `[%1 [0v0 [%parse ~['a'] ~]]])
  =/  r   (step:job-lib j 256 t0)
  %+  expect-eq
    !>  `[%failed 'restarted: the in-flight state is from an incompatible engine version; resubmit']
  !>(?:(?=(%stop -.r) result.job.r ~))

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
++  test-view-collapses-states
  ::  R2.3.1: VIEW is live. `view-spec` cycles x over 0..3 and the view is
  ::  `x % 2`, so the four states collapse to two — the identity is the
  ::  fingerprint of the VIEW'S VALUE, not of the bindings. This is the
  ::  behaviour R1.8.6 refused rather than fake, and R2.3.1 implements.
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req view-spec 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aVIEW V\0a') t0) 256)
  (expect-eq !>(`[%ok [3 2 0 2 [0 1 1 1]]]) !>(result.j))
::
++  alias-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x < 3 /\ x' = x + 1
  Inv == x < 2
  Alias == [ v |-> x, doubled |-> x * 2, moved |-> x' # x ]
  Spec == Init /\ [][Next]_x
  Lead == (x = 0) ~> (x = 1)
  ====
  '''
::
++  test-alias-renders-wire-trace
  ::  R2.3.2: ALIAS is live, and it reaches the TYPED WIRE TRACE, not only the
  ::  console report. The record BECOMES the state, in the RECORD'S constructor
  ::  order (`v, doubled, moved`, not alphabetical) -- and `moved` is `x' # x`,
  ::  which reads TRUE on every state but the LAST, because the last state has
  ::  no successor and is paired with ITSELF. That final FALSE is what proves
  ::  the successor pairing rather than a coincidence of values
  =/  cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aALIAS Alias\0a'
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req alias-spec cfg) t0) 256)
  =/  art  (~(got by artifacts.j) %trace)
  ?>  ?=(%trace -.art)
  =/  sts  states.trace.art
  ;:  weld
    (expect-eq !>(3) !>((lent sts)))
    (expect-eq !>(~[['v' '0'] ['doubled' '0'] ['moved' 'TRUE']]) !>(bindings:(snag 0 sts)))
    (expect-eq !>(~[['v' '1'] ['doubled' '2'] ['moved' 'TRUE']]) !>(bindings:(snag 1 sts)))
    (expect-eq !>(~[['v' '2'] ['doubled' '4'] ['moved' 'FALSE']]) !>(bindings:(snag 2 sts)))
  ==
::
++  test-view-definition-alone-is-fine
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req view-spec 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a') t0) 256)
  (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
::
::  +|  Cfg Source Override (R2.3.3)
::
::  `check-opts.cfg` is tlc2's `-config`: it names one of the bundle's own
::  sources to use as the config INSTEAD of the bundle's `cfg` field. The pair
::  below is matched -- one bundle, carrying BOTH configs, run twice with only
::  that field different -- so a passing test proves the override SELECTS
::  rather than that a number happens to match.
++  twocfg-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  Loose == x < 4
  Strict == x < 2
  ====
  '''
::
++  loose-cfg   'INIT Init\0aNEXT Next\0aINVARIANT Loose\0a'
++  strict-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Strict\0a'
::
++  ovr-bundle
  ::  carries its own `cfg` (loose, holds) AND a named source `strict` the
  ::  override can select (strict, is violated)
  ^-  source-bundle
  :*  %inline  'spec'
      (malt ~[['spec' twocfg-spec] ['strict' strict-cfg]])
      `loose-cfg
  ==
::
++  ovr-req
  |=  nm=(unit source-name)
  ^-  request
  [[%check [| | | | nm | ~ [%exhaustive & 0]]] ovr-bundle lim ~ ~ ~ ~]
::
++  test-cfg-override-absent-uses-bundle-cfg
  ::  no override: the bundle's own cfg runs, Loose holds, the run completes
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (ovr-req ~) t0) 256)
  (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
::
++  test-cfg-override-selects-named-source
  ::  same bundle, override set: the NAMED source is the config, so Strict is
  ::  the invariant and it is violated. A different verdict KIND, not just a
  ::  different count -- the bundle's own cfg could not produce this
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (ovr-req `'strict') t0) 256)
  ?>  ?=(^ result.j)
  ?>  ?=(%violated -.u.result.j)
  (expect-eq !>(`violation`[%invariant 'Strict' %.n]) !>(violation.u.result.j))
::
++  test-cfg-override-unknown-source-rejected
  ::  refused at SUBMIT, so nothing downstream can quietly fall back to the
  ::  bundle's cfg and check a config the caller did not ask for
  %+  expect-eq
    !>(`'unknown cfg source: nope')
  !>((validate:job-lib (ovr-req `'nope')))
::
++  test-cfg-override-clay-rejected
  ::  a %clay bundle selects its config by PATH: the file's mark is part of
  ::  the reference, so a bare name cannot supply it
  =/  req=request
    :*  [%check [| | | | `'some-cfg' | ~ [%exhaustive & 0]]]
        [%clay ~zod %spec ud+1 'spec' `/spec-cfg/txt ~[/lib]]
        lim  ~  ~  ~  ~
    ==
  %+  expect-eq
    !>(`'unsupported: cfg source override on a %clay bundle; select the config with src.cfg (a path)')
  !>((validate:job-lib req))
::
::  +|  INVARIANT And PROPERTY In One Config (R2.3.4)
::
::  The kernel refused this combination because NEITHER path could do it: the
::  liveness branch built its graph with `~` for invariants and the box-state
::  branch substituted the property for them. Both now carry the config's
::  invariant list, so the combination RUNS -- and a safety violation
::  pre-empts the temporal check, exactly as `ModelChecker.doNext` returning
::  pre-empts tlc2's final pass.
++  ip-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  Spec == Init /\ [][Next]_x
  Inv == x < 9
  Tight == x < 2
  BoxSmall == [](x < 9)
  BoxTight == [](x < 2)
  Live == <>(x = 3)
  ====
  '''
::
++  ip-inv-wins   'SPECIFICATION Spec\0aINVARIANT Tight\0aPROPERTY Live\0a'
++  ip-prop-runs  'SPECIFICATION Spec\0aINVARIANT Inv\0aPROPERTY Live\0a'
++  ip-box-order  'SPECIFICATION Spec\0aINVARIANT Tight\0aPROPERTY BoxTight\0a'
++  ip-both-ok    'SPECIFICATION Spec\0aINVARIANT Inv\0aPROPERTY BoxSmall\0a'
::
++  test-inv-prop-accepted-not-refused
  ::  the submit-time refusal is gone: the combination validates
  (expect-eq !>(~) !>((validate:job-lib (check-req ip-spec ip-prop-runs))))
::
++  test-inv-prop-invariant-preempts-liveness
  ::  the INVARIANT is violated at x = 2, so the run stops there with a SAFETY
  ::  verdict and the temporal property is never reported -- the kernel used to
  ::  refuse this config outright, and before that would not have checked `Tight`
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req ip-spec ip-inv-wins) t0) 256)
  ?>  ?=(^ result.j)
  ?>  ?=(%violated -.u.result.j)
  (expect-eq !>(`violation`[%invariant 'Tight' %.n]) !>(violation.u.result.j))
::
++  test-inv-prop-liveness-runs-when-invariant-holds
  ::  the matched half: same spec, an invariant that HOLDS, so the run reaches
  ::  the temporal check and reports the PROPERTY. A different verdict from the
  ::  arm above, off one word of config
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req ip-spec ip-prop-runs) t0) 256)
  ?>  ?=(^ result.j)
  ?>  ?=(%violated -.u.result.j)
  (expect-eq !>(`violation`[%property 'Live' %.n]) !>(violation.u.result.j))
::
++  test-inv-prop-box-state-invariant-order
  ::  a `[]P` box-state PROPERTY is checked as an INVARIANT, and the config's
  ::  own invariants come FIRST: `processConfigInvariants()` fills `invVec`
  ::  before `processConfigProps` appends to it. Both are false at x = 2 and
  ::  tlc2 names `Tight`, so the port must too
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req ip-spec ip-box-order) t0) 256)
  ?>  ?=(^ result.j)
  ?>  ?=(%violated -.u.result.j)
  (expect-eq !>(`violation`[%invariant 'Tight' %.n]) !>(violation.u.result.j))
::
++  test-inv-prop-both-hold
  ::  both hold: the run completes
  =/  [evs=(list event) j=jb]
    (run-all (init:job-lib (check-req ip-spec ip-both-ok) t0) 256)
  ?>  ?=(^ result.j)
  (expect-eq !>(%ok) !>(-.u.result.j))
::
++  test-kernel-report-equals-console-inv-prop
  ::  the kernel's rendered report is the console's, for the pre-empting case
  %+  same-report  ip-spec  ip-inv-wins
::
++  test-kernel-report-equals-console-inv-prop-box
  %+  same-report  ip-spec  ip-box-order
::
::  +|  Max Set Size (R2.4.1)
::
::  tlc2's `-maxSetSize` (`TLCGlobals.setBound`, default 1,000,000). R2.4.0
::  measured which of its two guarded sites is actually reachable: NOT
::  `StateVec.grow`/EC 2172 (`-maxSetSize 5` on a spec with 21 successors ran
::  clean, 442 states) but `ValueVec.ensureCapacity`, whose message names the
::  BOUND rather than the actual size. The port's `+force` is the same
::  boundary -- where a lazy set must become a value.
++  bigset-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals, FiniteSets
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 3
  Inv == Cardinality({i \in 0..30 : TRUE}) = 31
  ====
  '''
::
++  bigset-req
  |=  n=@ud
  ^-  request
  =/  l  lim
  =.  max-set-size.l  n
  [[%check [| | | | ~ | ~ [%exhaustive & 0]]] (bundle bigset-spec `mc-cfg) l ~ ~ ~ ~]
::
++  test-max-set-size-default-runs
  ::  the matched half: the same spec under the default bound completes
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (bigset-req 0) t0) 256)
  ?>  ?=(^ result.j)
  (expect-eq !>(%ok) !>(-.u.result.j))
::
++  test-max-set-size-bound-bites
  ::  one field different, and the run FAILS with tlc2's own wording -- the
  ::  bound names itself, as `ValueVec` does
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (bigset-req 5) t0) 256)
  %+  expect-eq
    !>(`[%failed 'Attempted to construct a set with too many elements (>5).'])
  !>(result.j)
::
::  +|  Continue Past The First Violation (R2.4.2)
::
::  tlc2's `-continue`. R2.4.0 measured what the row could not decide: the run
::  COMPLETES -- two EC 2110 blocks and then `Model checking completed. No
::  error has been found.` with the WHOLE graph's counts. So `result` stays one
::  (`%ok`), and the counterexamples become a list in their own artifact;
::  `result`/`violation` are left alone for R2.7.1, the unit that owns the
::  api-version bump.
++  cont-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLES x, y
  Init == x = 0 /\ y = 0
  Next == x' = (x + 1) % 4 /\ y' = y
  Inv == x < 2
  ====
  '''
::
++  cont-req
  |=  c=?
  ^-  request
  [[%check [| | | c ~ | ~ [%exhaustive & 0]]] (bundle cont-spec `mc-cfg) lim ~ ~ ~ ~]
::
++  test-continue-off-stops-at-first
  ::  the matched half: without the flag the run STOPS at the first violation
  ::  and reports the prefix's counts -- 3 states, depth 3
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (cont-req |) t0) 256)
  %+  expect-eq
    !>(`[%violated [%invariant 'Inv' %.n] [3 3 0 3 [1 1 1 1]]])
  !>(result.j)
::
++  test-continue-completes-with-all-violations
  ::  one field different: the search runs to completion, so the VERDICT is
  ::  `%ok` and the counts are the WHOLE graph's (5 generated / 4 distinct /
  ::  depth 4, against 3/3/3 above). Both violations are on the wire
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (cont-req &) t0) 256)
  =/  a  (~(get by artifacts.j) %violations)
  ?>  ?=(^ a)
  ?>  ?=(%violations -.u.a)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4 [0 1 1 1]]]) !>(result.j))
    (expect-eq !>(2) !>((lent viols.u.a)))
    (expect-eq !>(`violation`[%invariant 'Inv' %.n]) !>(violation:(snag 0 viols.u.a)))
    ::  discovery order: the depth-3 violator first, then the depth-4 one that
    ::  is only reachable THROUGH it -- which is what proves the violating
    ::  state is still enqueued
    (expect-eq !>(3) !>((lent states.trace:(snag 0 viols.u.a))))
    (expect-eq !>(4) !>((lent states.trace:(snag 1 viols.u.a))))
  ==
::
::  +|  Render Options (R2.4.3)
::
::  `-view` and `-difftrace`. R2.4.0 left `-difftrace` open; R2.4.3 measured it
::  by BYTE-DIFFING both modes: an exhaustive run is IDENTICAL with and without
::  the flag, while a simulation omits unchanged bindings. So it is honoured on
::  the sim path only, and refused elsewhere rather than accepted and ignored.
++  vw-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLES x, y
  Init == x = 0 /\ y = 0
  Next == x' = (x + 1) % 4 /\ y' = y
  Inv == x < 2
  Vw == x
  ====
  '''
::
++  vw-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aVIEW Vw\0a'
::
++  vw-req
  |=  v=?
  ^-  request
  [[%check [| v | | ~ | ~ [%exhaustive & 0]]] (bundle vw-spec `vw-cfg) lim ~ ~ ~ ~]
::
++  test-view-render-off-shows-bindings
  ::  the matched half: without the flag the trace prints the BINDINGS
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (vw-req |) t0) 256)
  =/  a  (~(got by artifacts.j) %report)
  ?>  ?=(%text -.a)
  =/  ls  (to-wain:format text.a)
  (expect !>((lien ls |=(l=@t =(l '/\\ x = 0')))))
::
++  test-view-render-on-shows-view-value
  ::  one field different: every state renders as the VIEW'S VALUE -- a bare
  ::  `0`, no `/\`, no names. Measured at the pin
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib (vw-req &) t0) 256)
  =/  a  (~(got by artifacts.j) %report)
  ?>  ?=(%text -.a)
  =/  ls  (to-wain:format text.a)
  ;:  weld
    (expect !>(!(lien ls |=(l=@t =(l '/\\ x = 0')))))
    (expect !>((lien ls |=(l=@t =(l '0')))))
  ==
::
++  test-view-render-without-view-refused
  ::  the flag with no VIEW in the config has nothing to render
  =/  req=request
    [[%check [| & | | ~ | ~ [%exhaustive & 0]]] (bundle vw-spec `mc-cfg) lim ~ ~ ~ ~]
  =/  [evs=(list event) j=jb]  (run-all (init:job-lib req t0) 256)
  %+  expect-eq
    !>(`[%failed 'unsupported: -view without a VIEW in the config (nothing to render)'])
  !>(result.j)
::
++  test-difftrace-outside-simulation-refused
  ::  measured: an exhaustive run is byte-identical with and without the flag,
  ::  so accepting it there would be accepting an option that does nothing
  =/  req=request
    [[%check [| | & | ~ | ~ [%exhaustive & 0]]] (bundle vw-spec `mc-cfg) lim ~ ~ ~ ~]
  %+  expect-eq
    !>(`'unsupported: -difftrace outside simulation (tlc2 honours it only in -simulate)')
  !>((validate:job-lib req))
::
::  R4.2k: a module of ASSUMEs with NO behaviour spec (SimpleMath's shape)
::  completes over zero initial states through the kernel, as the console
::  path has since R3.0a; a false ASSUME is still the assumption verdict
++  asm-only
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE spec ----\0a"  "EXTENDS Naturals\0a"
    "ASSUME 1 + 1 = 2\0a"  "====\0a"
  ==
++  asm-false
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE spec ----\0a"  "EXTENDS Naturals\0a"
    "ASSUME 1 + 1 = 3\0a"  "====\0a"
  ==
++  test-no-behaviour-spec
  =/  ok  +:(run-all (init:job-lib (check-req asm-only '') t0) 256)
  =/  bad  +:(run-all (init:job-lib (check-req asm-false '') t0) 256)
  ;:  weld
    (expect-eq !>(`[%ok [0 0 0 0 [0 0 0 0]]]) !>(result.ok))
    (expect-eq !>(%.y) !>(?=([~ %violated [%assumption *] *] result.bad)))
  ==
--
