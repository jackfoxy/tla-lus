/-  *tla-lus
/+  *test
/=  job-lib  /lib/job
|%
  ::  Tests For The Asynchronous Clay Source-Load Stage (unit P2-10.1)
  ::
  ::  No stage may read Clay. A %clay bundle enters the %modules stage,
  ::  which names the files it needs and pauses (%await); the harness
  ::  below plays the agent, answering from an in-test file system. The
  ::  contract every case measures: a Clay run closes its dependency
  ::  graph over asynchronous reads and reaches the same module graph —
  ::  and the same verdict — an inline bundle of the same files reaches.
  ::
  ::  Texts mirror desk/test-data/clay/{multi,single}.
  ::
+$  jb  job-2:job-lib
::  an in-test Clay: full file path -> body
+$  fs  (map path @t)
::
++  t0   ~2026.7.16
++  lim  default-limits:job-lib
::
::  +|  Fixtures
::
::
++  spec-mod
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
++  helper-mod
  ^~
  '''
  ---- MODULE helper ----
  EXTENDS Naturals
  Lim == 4
  ====
  '''
::
++  single-mod
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 3
  Inv == x < 3
  ====
  '''
::
++  live-mod
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  PGood == [](x < 4)
  ====
  '''
::
++  mc-cfg    'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
++  live-cfg  'INIT Init\0aNEXT Next\0aPROPERTY PGood\0a'
::
++  mk-fs
  ::  the list is cast flat: a path literal's own type is its exact
  ::  segments, which will not nest in a (map path @t)
  |=  l=(list [path @t])
  ^-  fs
  (malt l)
::
++  multi-fs
  %-  mk-fs
  :~  [/src/spec/tla spec-mod]
      [/src/helper/tla helper-mod]
      [/src/cfg/txt mc-cfg]
  ==
::
++  single-fs
  (mk-fs ~[[/src/spec/tla single-mod] [/src/cfg/txt mc-cfg]])
::
++  wide-fs
  ::  a root with nine user references, to slice the read fan-out
  %-  mk-fs
  %+  welp
    ^-  (list [path @t])
    ~[[/src/spec/tla wide-root] [/src/cfg/txt mc-cfg]]
  %+  turn  (gulf 1 9)
  |=(n=@ud `[path @t]`[(wide-path n) (wide-mod n)])
::
++  wide-path
  |=  n=@ud
  ^-  path
  ~[%src `@ta`(cat 3 'h' (scot %ud n)) %tla]
::
++  wide-mod
  |=  n=@ud
  ^-  @t
  =/  nm  (cat 3 'h' (scot %ud n))
  (rap 3 ~['---- MODULE ' nm ' ----\0a' 'K' nm ' == ' (scot %ud n) '\0a====\0a'])
::
++  wide-root
  ^-  @t
  %+  rap  3
  :~  '---- MODULE spec ----\0a'
      'EXTENDS Naturals, h1, h2, h3, h4, h5, h6, h7, h8, h9\0a'
      'VARIABLE x\0a'
      'Init == x = 0\0a'
      'Next == x\' = (x + 1) % 4\0a'
      'Inv == x < 4\0a'
      '====\0a'
  ==
::
::  +|  Requests
::
::
++  clay-req
  |=  [root=module-name cfg=(unit path) roots=(list path)]
  ^-  request
  :*  [%check [| ~ [%exhaustive &]]]
      [%clay ~zod %spec ud+1 root cfg roots]
      lim  |
  ==
::
++  inline-req
  |=  [root=module-name mods=(list [module-name @t]) cfg=@t]
  ^-  request
  [[%check [| ~ [%exhaustive &]]] [%inline root (malt mods) `cfg] lim |]
::
::  +|  Harness
::
::
++  answer
  ::  the agent's answer for one read: the file body, or absent
  |=  [f=fs r=read-request]
  ^-  read-response
  =/  t  (~(get by f) path.source-ref.r)
  ?~  t  [tag.r %| 'no such file']
  [tag.r %& u.t]
::
++  answers
  |=  [f=fs rs=(list read-request)]
  ^-  (list read-response)
  (turn rs |=(r=read-request (answer f r)))
::
++  run-clay
  ::  drive a %clay job to termination, answering every read from `f`
  |=  [f=fs req=request budget=@ud]
  ^-  [(list event) jb]
  =/  j  (init:job-lib req t0)
  =|  acc=(list event)
  |-  ^-  [(list event) jb]
  =/  r  (step:job-lib j budget t0)
  ?-    -.r
      %stop  [(weld acc events.r) job.r]
      %more  $(j job.r, acc (weld acc events.r))
      %await
    ::  a paused job that names no read would never be resumed
    =/  rs  `(list read-request)`reads.r
    ?>  ?=(^ rs)
    %=  $
      j    (deliver:job-lib job.r (answers f rs))
      acc  (weld acc events.r)
    ==
  ==
::
++  run-clay-k
  ::  the first k slices of a %clay run, then stop where it stands
  |=  [f=fs req=request budget=@ud k=@ud]
  ^-  [(list event) jb]
  =/  j  (init:job-lib req t0)
  =|  acc=(list event)
  |-  ^-  [(list event) jb]
  ?:  =(0 k)  [acc j]
  =/  r  (step:job-lib j budget t0)
  ?-    -.r
      %stop  [(weld acc events.r) job.r]
      %more  $(j job.r, k (dec k), acc (weld acc events.r))
      %await
    =/  rs  `(list read-request)`reads.r
    ?>  ?=(^ rs)
    %=  $
      k    (dec k)
      j    (deliver:job-lib job.r (answers f rs))
      acc  (weld acc events.r)
    ==
  ==
::
++  resume-clay
  ::  finish a run already in progress
  |=  [f=fs j=jb budget=@ud]
  ^-  [(list event) jb]
  =|  acc=(list event)
  |-  ^-  [(list event) jb]
  =/  r  (step:job-lib j budget t0)
  ?-    -.r
      %stop  [(weld acc events.r) job.r]
      %more  $(j job.r, acc (weld acc events.r))
      %await
    =/  rs  `(list read-request)`reads.r
    ?>  ?=(^ rs)
    %=  $
      j    (deliver:job-lib job.r (answers f rs))
      acc  (weld acc events.r)
    ==
  ==
::
++  count-clay
  |=  [f=fs req=request budget=@ud]
  ^-  @ud
  =/  j  (init:job-lib req t0)
  =/  n  0
  |-  ^-  @ud
  =/  r  (step:job-lib j budget t0)
  ?-    -.r
      %stop  +(n)
      %more  $(j job.r, n +(n))
      %await
    =/  rs  `(list read-request)`reads.r
    ?>  ?=(^ rs)
    $(j (deliver:job-lib job.r (answers f rs)), n +(n))
  ==
::
++  read-paths
  ::  every file path a run asks for, in request order
  |=  [f=fs req=request budget=@ud]
  ^-  (list path)
  =/  j  (init:job-lib req t0)
  =|  acc=(list path)
  |-  ^-  (list path)
  =/  r  (step:job-lib j budget t0)
  ?-    -.r
      %stop  (flop acc)
      %more  $(j job.r)
      %await
    =/  rs  `(list read-request)`reads.r
    ?>  ?=(^ rs)
    %=  $
      j    (deliver:job-lib job.r (answers f rs))
      acc  (weld (flop (turn rs |=(q=read-request path.source-ref.q))) acc)
    ==
  ==
::
++  run-inline
  |=  [req=request budget=@ud]
  ^-  jb
  =/  j  (init:job-lib req t0)
  |-  ^-  jb
  =/  r  (step:job-lib j budget t0)
  ?-  -.r
    %stop   job.r
    %more   $(j job.r)
    %await  ~|(%inline-run-never-awaits !!)
  ==
::
++  clay-result
  ::  (the mold name `result` is taken in this context, so the field is
  ::  read off the job rather than cast)
  |=  [f=fs req=request]
  =/  j  +:(run-clay f req 256)
  result.j
::
++  clay-failure
  ::  the failure message and the stage its diagnostic was raised at
  |=  [f=fs req=request]
  ^-  [msg=@t stg=(unit stage)]
  =/  j  +:(run-clay f req 256)
  :-  ?:(?=([~ %failed *] result.j) reason.u.result.j '')
  ?~(diags.j ~ `stage.i.diags.j)
::
::  +|  The Differential: Clay Equals Inline
::
::
++  test-clay-multi-module
  ::  the root EXTENDS a user module: two files, loaded asynchronously,
  ::  closing to the frozen inline golden of test-multi-module-check
  %+  expect-eq
    !>(`[%ok [5 4 0 4]])
  !>((clay-result multi-fs (clay-req 'spec' `/src/cfg/txt ~[/src])))
::
++  test-clay-equals-inline
  ::  the same texts through both source representations
  =/  cr  (clay-result multi-fs (clay-req 'spec' `/src/cfg/txt ~[/src]))
  =/  ir
    %-  run-inline
    :_  256
    (inline-req 'spec' ~[['spec' spec-mod] ['helper' helper-mod]] mc-cfg)
  (expect-eq !>(cr) !>(result.ir))
::
++  test-clay-single-module
  =/  cr  (clay-result single-fs (clay-req 'spec' `/src/cfg/txt ~[/src]))
  =/  ir  (run-inline (inline-req 'spec' ~[['spec' single-mod]] mc-cfg) 256)
  ;:  weld
    (expect-eq !>(`[%ok [4 3 0 3]]) !>(cr))
    (expect-eq !>(cr) !>(result.ir))
  ==
::
++  test-clay-property-appends-liveness
  ::  a Clay run cannot plan its %liveness stage until the config is
  ::  read; %config appends it, and the progress total grows with it
  =/  f  (mk-fs ~[[/src/spec/tla live-mod] [/src/cfg/txt live-cfg]])
  =/  j  +:(run-clay f (clay-req 'spec' `/src/cfg/txt ~[/src]) 256)
  ;:  weld
    (expect-eq !>(`[%ok [5 4 0 4]]) !>(result.j))
    (expect-eq !>([5 5]) !>(progress.j))
  ==
::
::  +|  The Await Protocol
::
::
++  test-clay-first-slice-awaits
  ::  the first slice does no compiler work: it enters %modules and asks
  ::  for the config and the root module
  =/  j  (init:job-lib (clay-req 'spec' `/src/cfg/txt ~[/src]) t0)
  =/  r  (step:job-lib j 256 t0)
  ?>  ?=(%await -.r)
  =/  rs  `(list read-request)`reads.r
  ;:  weld
    %+  expect-eq
      !>(~[/src/cfg/txt /src/spec/tla])
    !>((turn rs |=(q=read-request path.source-ref.q)))
    %+  expect-eq
      !>(~[`event`[%stage %modules] [%progress 1 4]])
    !>(events.r)
    (expect-eq !>(~) !>(result.job.r))
  ==
::
++  test-clay-load-budget-slices-fan-out
  ::  a wide dependency fan-out is sliced by the load budget, not the
  ::  work budget: at most 8 reads leave in one slice
  =/  req  (clay-req 'spec' `/src/cfg/txt ~[/src])
  =/  j  (init:job-lib req t0)
  =/  r1  (step:job-lib j 256 t0)
  ?>  ?=(%await -.r1)
  =/  d1  (deliver:job-lib job.r1 (answers wide-fs `(list read-request)`reads.r1))
  =/  r2  (step:job-lib d1 256 t0)
  ?>  ?=(%await -.r2)
  ;:  weld
    (expect-eq !>(2) !>((lent `(list read-request)`reads.r1)))
    (expect-eq !>(8) !>((lent `(list read-request)`reads.r2)))
    (expect-eq !>(`[%ok [5 4 0 4]]) !>((clay-result wide-fs req)))
  ==
::
++  test-clay-stale-response-ignored
  ::  a duplicated or unknown-tag delivery changes nothing: the cursor
  ::  drops responses it is not waiting on
  =/  req  (clay-req 'spec' `/src/cfg/txt ~[/src])
  =/  clean  (run-clay multi-fs req 256)
  =/  j  (init:job-lib req t0)
  =/  r  (step:job-lib j 256 t0)
  ?>  ?=(%await -.r)
  =/  rs  `(list read-request)`reads.r
  =/  dup  (weld (answers multi-fs rs) (answers multi-fs rs))
  =/  noise  (snoc dup `read-response`[99 %& 'garbage'])
  =/  dirty  (resume-clay multi-fs (deliver:job-lib job.r noise) 256)
  (expect-eq !>(+.clean) !>(+.dirty))
::
++  test-clay-pause-resume-every-boundary
  ::  interrupting after any slice — including one taken across the Clay
  ::  boundary — must not change the event stream or the final job noun
  =/  req  (clay-req 'spec' `/src/cfg/txt ~[/src])
  =/  full  (run-clay multi-fs req 1)
  =/  n     (count-clay multi-fs req 1)
  =/  i  1
  =|  out=tang
  |-  ^-  tang
  ?:  (gte i n)  out
  =/  pa    (run-clay-k multi-fs req 1 i)
  =/  rest  (resume-clay multi-fs +.pa 1)
  %=  $
    i    +(i)
    out  ;:  weld
           out
           (expect-eq !>(-.full) !>((weld -.pa -.rest)))
           (expect-eq !>(+.full) !>(+.rest))
         ==
  ==
::
::  +|  Search Roots And Standard Modules
::
::
++  test-clay-second-search-root
  ::  roots are tried in order; a miss under the first falls through
  =/  f
    %-  mk-fs
    :~  [/src/spec/tla spec-mod]
        [/alt/helper/tla helper-mod]
        [/src/cfg/txt mc-cfg]
    ==
  %+  expect-eq
    !>(`[%ok [5 4 0 4]])
  !>((clay-result f (clay-req 'spec' `/src/cfg/txt ~[/src /alt])))
::
++  test-clay-standard-module-needs-no-file
  ::  a user file shadows a standard module, so the read is attempted;
  ::  when no root has it, the vendored module answers and the run stands
  =/  req  (clay-req 'spec' `/src/cfg/txt ~[/src])
  =/  paths  (read-paths multi-fs req 256)
  ;:  weld
    (expect !>((lien paths |=(p=path =(p /src/naturals/tla)))))
    %+  expect-eq
      !>(`[%ok [5 4 0 4]])
    !>((clay-result multi-fs req))
  ==
::
::  +|  Typed Failures At The %modules Stage
::
::
++  test-clay-missing-module
  =/  f  (mk-fs ~[[/src/spec/tla spec-mod] [/src/cfg/txt mc-cfg]])
  %+  expect-eq
    !>(['Cannot find source file for module helper imported in module spec.' `%modules])
  !>((clay-failure f (clay-req 'spec' `/src/cfg/txt ~[/src])))
::
++  test-clay-missing-root-module
  =/  f  (mk-fs ~[[/src/cfg/txt mc-cfg]])
  %+  expect-eq
    !>(['Cannot find source file for module spec.' `%modules])
  !>((clay-failure f (clay-req 'spec' `/src/cfg/txt ~[/src])))
::
++  test-clay-missing-config
  =/  f  (mk-fs ~[[/src/spec/tla single-mod]])
  %+  expect-eq
    !>(['Cannot find the config file.' `%modules])
  !>((clay-failure f (clay-req 'spec' `/src/cfg/txt ~[/src])))
::
++  test-clay-declared-name-mismatch
  ::  the file is named for one module and declares another (SANY's
  ::  file-name mismatch, checked against the case-sensitive name)
  =/  f  (mk-fs ~[[/src/spec/tla single-mod] [/src/cfg/txt mc-cfg]])
  %+  expect-eq
    !>(['File name \'Spec\' does not match the name \'spec\' of the top level module it contains.' `%modules])
  !>((clay-failure f (clay-req 'Spec' `/src/cfg/txt ~[/src])))
::
++  test-clay-unparsable-module
  =/  f  (mk-fs ~[[/src/spec/tla 'not a module'] [/src/cfg/txt mc-cfg]])
  %+  expect-eq
    !>(['Could not parse module spec.' `%modules])
  !>((clay-failure f (clay-req 'spec' `/src/cfg/txt ~[/src])))
::
::  +|  Limits During The Load
::
::
++  test-clay-limited-source
  ::  source bytes accrue as files arrive; the limit stops the load at
  ::  the point of growth, not at submit
  =/  req  (clay-req 'spec' `/src/cfg/txt ~[/src])
  =.  max-source.limits.req  40
  %+  expect-eq
    !>(`[%limited %source *run-stats])
  !>((clay-result multi-fs req))
::
++  test-clay-limited-modules
  =/  req  (clay-req 'spec' `/src/cfg/txt ~[/src])
  =.  max-modules.limits.req  1
  %+  expect-eq
    !>(`[%limited %modules *run-stats])
  !>((clay-result multi-fs req))
--
