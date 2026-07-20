/-  *tla-lus
/=  ast       /lib/tla/ast
/=  syntax    /lib/tla/syntax
/=  check     /lib/tla/check
/=  semantic  /lib/tla/semantic
|%
  ::  Resumable Job Kernel (unit P2-1)
  ::
  ::  Pure, resumable driver for the SANY/TLC pipeline. Every expensive
  ::  operation runs behind a persisted continuation: one +step call
  ::  spends at most `budget` work units and returns, so a single Gall
  ::  event never contains a full search or compiler stage, and the
  ::  final result is a pure function of the job noun, independent of
  ::  where the work was sliced.
  ::
  ::  Honesty contract (plan invariant 8): no stage may return a
  ::  plausible %ok without doing the named work. Everything the
  ::  pipeline cannot yet do faithfully is rejected by +validate before
  ::  a job exists, or fails with a typed reason naming the unsupported
  ::  behavior. There are no stub stages.
  ::
  ::  The in-flight continuation ($kont) holds recursive syntax/value
  ::  molds, which must never enter a vase (rendering them in a vase
  ::  type crashes in lull, e.g. the agent's on-save). It is therefore
  ::  persisted jammed inside the job and revived at each step.
  ::
::  +|  Types
::
::  the persisted job: the public $job fields plus the submit time
::  (for max-time) and the jammed in-flight continuation
+$  job-2
  $:  =request
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
+$  step-result-2
  $%  [%more events=(list event) job=job-2]
      [%stop events=(list event) job=job-2]
  ==
::  the source span of the Next action, for typed trace states
+$  next-act  (unit [name=@t at=(unit loc)])
::  in-flight pipeline state; versioned via the [%1 k=@] wrapper above
+$  kont
  $%  [%parse todo=(list module-name)]
      ::  parsed root module, consumed by the %config stage
      [%tree t=node:check]
      ::  safety search
      [%bfs nl=@t act=next-act o=bfs-opts:check cur=bfs-cursor:check]
      ::  liveness: full-graph build (%explore), then property scan
      $:  %live
          phase=?(%build %scan)
          kind=?(%diamond %boxdiamond %box)
          inner=node:check
          pname=@t
          nl=@t
          act=next-act
          o=bfs-opts:check
          cur=bfs-cursor:check
          todo=(list @t)
          best=(unit [d=@ud fp=@t])
      ==
      ::  seeded simulation
      $:  %sim
          iname=@t
          nl=@t
          act=next-act
          o=sim-opts:check
          cur=sim-cursor:check
      ==
  ==
::
::  +|  Constants
::
++  default-limits
  ^-  limits
  :*  max-source=1.000.000
      max-modules=64
      max-states=100.000
      max-depth=1.000
      max-time=~m10
      max-artifact=1.000.000
  ==
::  work units one Gall event may spend; engine configuration,
::  deliberately separate from the request's user-facing limits
++  default-budget  256
::
::  +|  Continuation Persistence
::
::
++  save-kont
  |=  k=kont
  ^-  (unit [%1 k=@])
  `[%1 (jam k)]
::
++  load-kont
  |=  c=[%1 k=@]
  ^-  kont
  ;;(kont (cue k.c))
::
::  +|  Validation
::
::
++  validate
  ::  Typed-boundary request checks; ~ means acceptable. Everything the
  ::  pipeline cannot yet do faithfully is rejected here by name, never
  ::  accepted into a stage that would fake success.
  |=  req=request
  ^-  (unit @t)
  ?:  ?=(%clay -.src.req)
    `'unsupported: %clay sources are not loaded yet (unit 10)'
  ?:  ?=(%translate -.op.req)
    `'unsupported: PlusCal translation is not ported yet (unit 8)'
  ?:  ?=(%analyze -.op.req)
    (validate-bundle req)
  ?:  translate.opts.op.req
    `'unsupported: translate-before-check is not ported yet (unit 8)'
  ?:  ?=(^ cfg.opts.op.req)
    `'unsupported: cfg source override; put the config in the bundle'
  ?~  cfg.src.req
    `'a %check request requires a config'
  (validate-bundle req)
::
++  validate-bundle
  ::  size limits are enforced here, before any work is scheduled
  |=  req=request
  ^-  (unit @t)
  ?>  ?=(%inline -.src.req)
  =/  modules  modules.src.req
  =/  count  ~(wyt by modules)
  ?:  =(0 count)
    `'empty source bundle'
  ?.  (~(has by modules) root.src.req)
    `'root module not in bundle'
  ?:  (gth count max-modules.limits.req)
    `'too many modules'
  =/  bytes
    %+  roll  ~(val by modules)
    |=  [text=@t acc=@ud]
    (add acc (met 3 text))
  =/  cfg-bytes  ?~(cfg.src.req 0 (met 3 u.cfg.src.req))
  ?:  (gth (add bytes cfg-bytes) max-source.limits.req)
    `'source exceeds limit'
  ~
::
::  +|  Planning
::
::
++  plan
  ::  ordered stages for a request; every planned stage does real work
  |=  req=request
  ^-  (list stage)
  ?-    -.op.req
      %translate  ~
      %analyze
    ?:  ?|  semantic.flags.op.req
            level.flags.op.req
            lint.flags.op.req
        ==
      `(list stage)`~[%parse %semantic %terminal]
    `(list stage)`~[%parse %terminal]
      %check
    %+  weld  `(list stage)`~[%parse %config]
    ?-    -.mode.opts.op.req
        %simulate  `(list stage)`~[%simulate]
        %exhaustive
      ?:  (has-property req)
        `(list stage)`~[%explore %liveness]
      `(list stage)`~[%explore]
    ==
  ==
::
++  has-property
  |=  req=request
  ^-  ?
  ?.  ?=(%inline -.src.req)  |
  ?~  cfg.src.req  |
  ?=(^ (cfg-value:check u.cfg.src.req 'PROPERTY'))
::
::  +|  Engine
::
::
++  init
  ::  start a job at %starting with its full stage plan pending
  |=  [req=request now=@da]
  ^-  job-2
  =/  stages  (plan req)
  :*  req  %starting  stages  [0 (lent stages)]
      *run-stats  ~  ~  ~  now  ~
  ==
::
++  kont-stage
  ::  the pipeline stage a continuation belongs to; ~ for inter-stage
  ::  data consumed by the next stage entry
  |=  k=kont
  ^-  (unit stage)
  ?-  -.k
    %parse  `%parse
    %tree   ~
    %bfs    `%explore
    %live   ?:(=(%build phase.k) `%explore `%liveness)
    %sim    `%simulate
  ==
::
++  time-exceeded
  |=  [j=job-2 now=@da]
  ^-  ?
  ?:  (lte now started.j)  |
  (gth `@dr`(sub now started.j) max-time.limits.request.j)
::
++  step
  ::  spend at most `budget` work units on the job's active stage;
  ::  already-terminal jobs are unchanged
  |=  [j=job-2 budget=@ud now=@da]
  ^-  step-result-2
  ?^  result.j  [%stop ~ j]
  ?:  (time-exceeded j now)
    (finish j [%limited %time stats.j] ~)
  =/  k=(unit kont)  ?~(cont.j ~ `(load-kont u.cont.j))
  =/  own=(unit stage)  ?~(k ~ (kont-stage u.k))
  ::  mid-stage resume: no entry events
  ?:  ?&(?=(^ own) =(u.own stage.j))
    (run j k budget ~)
  ::  stage entry
  ?~  pending.j
    (finish j [%failed 'no pending work'] ~)
  =/  s  i.pending.j
  =/  prog=progress  [+(done.progress.j) total.progress.j]
  =/  j
    ^-  job-2
    j(stage s, pending t.pending.j, progress prog)
  (run j k budget ~[[%stage s] [%progress prog]])
::
++  run
  ::  execute one bounded slice of the active stage
  |=  [j=job-2 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-2
  ?+    stage.j
      ~|([%tla-lus-unplanned-stage stage.j] !!)
    %parse     (do-parse j k budget pre)
    %semantic  (do-semantic j pre)
    %config    (do-config j k pre)
    %explore   (do-explore j k budget pre)
    %liveness  (do-scan j k budget pre)
    %simulate  (do-sim j k budget pre)
    %terminal  (do-terminal j pre)
  ==
::
++  more
  ::  a non-terminal slice; heartbeat progress when nothing else to say
  |=  [j=job-2 evs=(list event)]
  ^-  step-result-2
  [%more ?~(evs ~[[%progress progress.j]] evs) j]
::
++  finish
  ::  seal the job; a sealed job is never resumed
  |=  [j=job-2 res=result pre=(list event)]
  ^-  step-result-2
  =.  result.j   `res
  =.  stage.j    %terminal
  =.  pending.j  ~
  =.  cont.j     ~
  [%stop (snoc pre [%result res]) j]
::
++  cancel
  |=  j=job-2
  ^-  job-2
  j(result `[%cancelled ~], stage %terminal, pending ~, cont ~)
::
++  project
  ::  the public job view: results and progress, never internal cursors
  |=  j=job-2
  ^-  job
  :*  request.j  stage.j  pending.j  progress.j
      stats.j  diags.j  artifacts.j  result.j
  ==
::
::  +|  Stage: %parse
::
::
++  do-parse
  ::  %check parses the root module into a %tree hand-off; %analyze
  ::  parses every bundle module, one work unit each, collecting
  ::  diagnostics for %terminal's verdict
  |=  [j=job-2 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-2
  ?>  ?=(%inline -.src.request.j)
  =/  src  src.request.j
  ?:  ?=(%check -.op.request.j)
    =/  text  (~(get by modules.src) root.src)
    ?~  text
      (finish j [%failed 'root module not in bundle'] pre)
    =/  pr  (mule |.((parse-typed:syntax u.text)))
    ?:  ?=(%| -.pr)
      (finish j [%failed 'parse error: parser crashed'] pre)
    =/  pt  p.pr
    ?:  |(fatal.pt ?=(~ tree.pt))
      ::  SANY's exact parse-error text travels as the diagnostics
      =.  diags.j  (weld diags.j diags.pt)
      =/  evs  (turn diags.pt |=(d=diagnostic `event`[%diagnostic d]))
      %^  finish  j
        [%failed ?~(diags.pt 'parse error' message.i.diags.pt)]
      (weld pre evs)
    =.  cont.j  (save-kont [%tree u.tree.pt])
    (more j pre)
  ::  %analyze
  =/  kk=kont
    ?^  k  u.k
    [%parse (sort ~(tap in ~(key by modules.src)) aor)]
  ?>  ?=(%parse -.kk)
  =/  evs  pre
  =/  spent  0
  |-  ^-  step-result-2
  ?~  todo.kk
    =.  cont.j  ~
    (more j evs)
  ?:  (gte spent budget)
    =.  cont.j  (save-kont kk)
    (more j evs)
  =/  nm  i.todo.kk
  =/  ds=(list diagnostic)
    =/  pr  (mule |.((parse-typed:syntax (~(got by modules.src) nm))))
    ?:  ?=(%| -.pr)
      [[%lus 400] %error %parse (rap 3 ~['parser crashed in ' nm]) ~ ~]~
    diags.p.pr
  ?~  ds
    $(todo.kk t.todo.kk, spent +(spent))
  =.  diags.j  (weld diags.j ds)
  %=  $
    todo.kk  t.todo.kk
    spent    +(spent)
    evs      (weld evs (turn ds |=(d=diagnostic `event`[%diagnostic d])))
  ==
::
::  +|  Stage: %semantic (level and lint)
::
::
++  sdiag-to-diag
  ::  a semantic-library diagnostic on the wire: the code is a SANY
  ::  ErrorCode, the phase supplies the stage, and the (unit span)
  ::  becomes a loc in the root module. Cross-module instance
  ::  diagnostics carry the root name here (their true origin module is
  ::  a deferred refinement, like the parser's typed-at spans)
  |=  [d=sdiag:semantic root=module-name stg=stage]
  ^-  diagnostic
  :*  [%sany code.d]
      sev.d
      stg
      msg.d
      ?~(at.d ~ `[root u.at.d])
      ~
  ==
::
++  do-semantic
  ::  the %analyze semantic/level/lint stage: one bounded pass over the
  ::  Work Unit 3 graph (generation, level checking, linting) with the
  ::  diagnostics split by phase, emitting only the requested stages.
  ::  Level and lint diagnostics are gated exactly as SANY gates them
  ::  (a semantic error suppresses both; a level error suppresses lint),
  ::  which +analyze-graph already enforces. Runs in a single slice: a
  ::  module bundle's analysis is bounded like a capped exploration, so
  ::  no mid-stage cursor is needed (see doc/compatibility.md)
  |=  [j=job-2 pre=(list event)]
  ^-  step-result-2
  ?>  ?=(%inline -.src.request.j)
  ?>  ?=(%analyze -.op.request.j)
  =/  src    src.request.j
  =/  flags  flags.op.request.j
  =/  ag  (analyze-graph:semantic root.src modules.src)
  ?~  ag
    ::  resolution failed. If the parse stage already reported errors,
    ::  they drive the terminal verdict; otherwise surface a resolution
    ::  diagnostic (a missing EXTENDS/INSTANCE target parses per module
    ::  but fails the dependency graph)
    ?:  %+  lien  diags.j
        |=(d=diagnostic &(=(%error severity.d) ?=(?(%parse %modules) stage.d)))
      (more j pre)
    =/  d=diagnostic
      [[%lus 401] %error %modules 'module resolution failed' ~ ~]
    =.  diags.j  (snoc diags.j d)
    (more j (snoc pre [%diagnostic d]))
  =/  as-diags
    |=  [ds=(list sdiag:semantic) stg=stage]
    ^-  (list diagnostic)
    (turn ds |=(d=sdiag:semantic (sdiag-to-diag d root.src stg)))
  =/  lint-ds
    ?.  lint.flags  ~
    ::  driver-level warning controls, with default (empty) options; a
    ::  request-carried lint-options set is a future sur extension
    =/  applied  (apply-lint-options:semantic [~ ~] lint.u.ag)
    ?:  ?=(%| -.applied)  ~
    (as-diags p.applied %lint)
  =/  ds=(list diagnostic)
    ;:  weld
      ?:(semantic.flags (as-diags sem.u.ag %semantic) ~)
      ?:(level.flags (as-diags lvl.u.ag %level) ~)
      lint-ds
    ==
  =.  diags.j  (weld diags.j ds)
  =/  evs  (weld pre (turn ds |=(d=diagnostic `event`[%diagnostic d])))
  (more j evs)
::
::  +|  Stage: %config
::
::
++  cfg-known  ^-  (list @t)  ~['INIT' 'NEXT' 'INVARIANT' 'PROPERTY']
::
++  cfg-audit
  ::  the config must be key/value pairs over the supported keys, each
  ::  at most once; anything else is named in the typed rejection
  |=  cfg=@t
  ^-  (unit @t)
  =/  toks  (cfg-tokens:check cfg)
  =|  used=(set @t)
  |-  ^-  (unit @t)
  ?~  toks  ~
  =/  key  i.toks
  ?.  (lien cfg-known |=(w=@t =(w key)))
    `(rap 3 ~['unsupported config key: ' key])
  ?:  (~(has in used) key)
    `(rap 3 ~['duplicate config key: ' key])
  ?~  t.toks
    `(rap 3 ~['config key without value: ' key])
  $(toks t.t.toks, used (~(put in used) key))
::
++  do-config
  ::  consume the parsed root tree and build the engine continuation.
  ::  Every config this engine cannot process faithfully is a typed
  ::  failure naming the key or form; nothing is silently ignored.
  |=  [j=job-2 k=(unit kont) pre=(list event)]
  ^-  step-result-2
  ?.  ?&(?=(^ k) ?=(%tree -.u.k))
    (finish j [%failed 'internal: %config without a parsed tree'] pre)
  =/  tree  t.u.k
  ?>  ?=(%inline -.src.request.j)
  ?>  ?=(%check -.op.request.j)
  =/  cfg   (need cfg.src.request.j)
  =/  mode  mode.opts.op.request.j
  =/  lims  limits.request.j
  =/  bad   (cfg-audit cfg)
  ?^  bad  (finish j [%failed u.bad] pre)
  =/  in  (cfg-value:check cfg 'INIT')
  =/  nx  (cfg-value:check cfg 'NEXT')
  =/  iv  (cfg-value:check cfg 'INVARIANT')
  =/  pp  (cfg-value:check cfg 'PROPERTY')
  ?~  in  (finish j [%failed 'no INIT in config'] pre)
  ?~  nx  (finish j [%failed 'no NEXT in config'] pre)
  ?:  &(?=(^ iv) ?=(^ pp))
    %^  finish  j
      [%failed 'unsupported: INVARIANT and PROPERTY in one config (unit 7)']
    pre
  =/  ib  (body-of-def:check tree u.in)
  =/  nb  (body-of-def:check tree u.nx)
  ?~  ib  (finish j [%failed (rap 3 ~['no definition for INIT ' u.in])] pre)
  ?~  nb  (finish j [%failed (rap 3 ~['no definition for NEXT ' u.nx])] pre)
  =/  ivb=(unit node:check)  ?~(iv ~ (body-of-def:check tree u.iv))
  ?:  &(?=(^ iv) ?=(~ ivb))
    %^  finish  j
      [%failed (rap 3 ~['no definition for INVARIANT ' u.iv])]
    pre
  =/  vars  (var-names:check tree)
  =/  modn  (module-name-of:check tree)
  =/  nl    (next-span-label:check u.nb modn)
  =/  act=next-act
    =/  sp  (span-of:ast u.nb)
    `[u.nx ?~(sp ~ `[modn u.sp])]
  ?:  ?=(%simulate -.mode)
    ?:  ?=(^ pp)
      %^  finish  j
        [%failed 'unsupported: temporal property in simulation (unit 9)']
      pre
    =/  dep
      ?:  =(0 max-depth.lims)  depth.mode
      (min depth.mode max-depth.lims)
    =/  o=sim-opts:check  [u.nb ivb vars num.mode dep]
    =.  cont.j
      %-  save-kont
      [%sim ?~(iv '' u.iv) nl act o (sim-init:check u.ib vars seed.mode)]
    (more j pre)
  ?^  pp
    =/  pb  (body-of-def:check tree u.pp)
    ?~  pb
      %^  finish  j
        [%failed (rap 3 ~['no definition for PROPERTY ' u.pp])]
      pre
    =/  up  (unwrap-prop:check u.pb)
    ?:  ?=(%none kind.up)
      %^  finish  j
        [%failed 'unsupported: temporal property form (only <>P, []<>P, []P; unit 8)']
      pre
    =/  o=bfs-opts:check
      [u.nb ~ '' vars | max-states.lims max-depth.lims]
    =.  cont.j
      %-  save-kont
      :*  %live  %build  kind.up  inner.up  u.pp  nl  act
          o  (bfs-init:check u.ib vars)  ~  ~
      ==
    (more j pre)
  ::  safety search
  =/  o=bfs-opts:check
    :*  u.nb  ivb  ?~(iv '' u.iv)  vars
        deadlock.mode  max-states.lims  max-depth.lims
    ==
  =.  cont.j  (save-kont [%bfs nl act o (bfs-init:check u.ib vars)])
  (more j pre)
::
::  +|  Stage: %explore
::
::
++  do-explore
  |=  [j=job-2 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-2
  ?:  ?&(?=(^ k) ?=(%bfs -.u.k))
    =/  kk  u.k
    =/  r  (bfs-step:check o.kk cur.kk budget)
    ?:  ?=(%more -.r)
      =.  cont.j  (save-kont kk(cur cur.r))
      (more j pre)
    (finish-bfs j out.r nl.kk act.kk pre)
  ?:  ?&(?=(^ k) ?=(%live -.u.k) =(%build phase.u.k))
    =/  kk  u.k
    =/  r  (bfs-step:check o.kk cur.kk budget)
    ?:  ?=(%more -.r)
      =.  cont.j  (save-kont kk(cur cur.r))
      (more j pre)
    ?:  ?=(%limited -.out.r)
      =/  st=run-stats  [gen.out.r distinct.out.r 0 depth.out.r]
      =.  stats.j  st
      (finish j [%limited what.out.r st] pre)
    ?.  ?=(%ok -.out.r)
      (finish j [%failed 'internal: unexpected graph outcome'] pre)
    =/  st=run-stats  [gen.out.r distinct.out.r 0 depth.out.r]
    =.  stats.j  st
    =/  todo  (live-todo:check kind.kk seen.cur.r inits.cur.r)
    =.  cont.j  (save-kont kk(phase %scan, cur cur.r, todo todo))
    (more j pre)
  (finish j [%failed 'internal: %explore without a search continuation'] pre)
::
++  finish-bfs
  ::  seal a safety search: wire result, stats, report + trace artifacts
  |=  [j=job-2 out=outcome:check nl=@t act=next-act pre=(list event)]
  ^-  step-result-2
  =/  st=run-stats
    ?-  -.out
      %ok        [gen.out distinct.out 0 depth.out]
      %limited   [gen.out distinct.out 0 depth.out]
      %inv       [gen.out distinct.out 0 depth.out]
      %deadlock  [gen.out distinct.out 0 depth.out]
    ==
  =.  stats.j  st
  =/  res=result
    ?-  -.out
      %ok        [%ok st]
      %limited   [%limited what.out st]
      %inv       [%violated [%invariant name.out] st]
      %deadlock  [%violated [%deadlock ~] st]
    ==
  =/  report  (wain-text (render-outcome:check out nl))
  =/  tr=(unit trace)
    ?+  -.out  ~
      %inv       `[%safety (trace-states trace.out act) ~]
      %deadlock  `[%safety (trace-states trace.out act) ~]
    ==
  (finish-arts j res report tr pre)
::
::  +|  Stage: %liveness
::
::
++  do-scan
  |=  [j=job-2 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-2
  ?.  ?&(?=(^ k) ?=(%live -.u.k) =(%scan phase.u.k))
    (finish j [%failed 'internal: %liveness without a scan continuation'] pre)
  =/  kk  u.k
  =/  r
    (live-scan:check kind.kk inner.kk seen.cur.kk todo.kk best.kk budget)
  ?:  ?=(%more -.r)
    =.  cont.j  (save-kont kk(todo todo.r, best best.r))
    (more j pre)
  ::  stats were sealed when the graph build finished
  =/  st  stats.j
  ?~  bad.r
    =/  report
      %-  wain-text
      :-  'Model checking completed. No error has been found.'
      (counts-lines:check generated.st distinct.st depth.st)
    (finish-arts j [%ok st] report ~ pre)
  =/  tr  (trace-to:check seen.cur.kk u.bad.r)
  =/  report
    %-  wain-text
    ;:  weld
      ~[(crip "Error: Temporal property {(trip pname.kk)} was violated.")]
      ~['Error: The following behavior constitutes a counter-example:']
      (render-live-trace:check tr nl.kk)
      (counts-lines:check generated.st distinct.st depth.st)
    ==
  =/  typed=trace  [%lasso (trace-states tr act.kk) `(lent tr)]
  (finish-arts j [%violated [%property pname.kk] st] report `typed pre)
::
::  +|  Stage: %simulate
::
::
++  do-sim
  |=  [j=job-2 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-2
  ?.  ?&(?=(^ k) ?=(%sim -.u.k))
    (finish j [%failed 'internal: %simulate without a continuation'] pre)
  =/  kk  u.k
  =/  r  (sim-step:check o.kk cur.kk budget)
  ?:  ?=(%more -.r)
    =.  cont.j  (save-kont kk(cur cur.r))
    (more j pre)
  =/  st=run-stats  [steps.res.r 0 0 maxn.cur.r]
  =.  stats.j  st
  =/  head
    %-  crip
    ;:  weld
      "Simulation completed: "
      (a-tape:check traces.res.r)
      " behaviors, "
      (a-tape:check steps.res.r)
      " transitions."
    ==
  ?~  viol.res.r
    (finish-arts j [%ok st] head ~ pre)
  =/  report
    %-  wain-text
    ;:  weld
      ~[(crip "Error: Invariant {(trip iname.kk)} is violated.")]
      ~['Error: The behavior up to this point is:']
      (render-trace:check u.viol.res.r nl.kk)
      ~[head]
    ==
  =/  typed=trace  [%simulate (trace-states u.viol.res.r act.kk) ~]
  (finish-arts j [%violated [%invariant iname.kk] st] report `typed pre)
::
::  +|  Stage: %terminal
::
::
++  do-terminal
  ::  %analyze verdict: fail iff any error-severity diagnostic was
  ::  recorded by a parse, semantic, or level stage (lint warnings do
  ::  not fail the run unless a lint-option elevated one to %error,
  ::  which flips its severity here)
  |=  [j=job-2 pre=(list event)]
  ^-  step-result-2
  =/  errs
    %-  lent
    %+  skim  diags.j
    |=  d=diagnostic
    ?&  =(%error severity.d)
        ?=(?(%parse %semantic %level %lint) stage.d)
    ==
  ?:  =(0 errs)
    (finish j [%ok stats.j] pre)
  %^  finish  j
    [%failed (rap 3 ~['analysis found ' (a-co:check errs) ' error(s)'])]
  pre
::
::  +|  Artifacts
::
::
++  finish-arts
  ::  store the report (and optional typed trace) then seal; a report
  ::  exceeding max-artifact turns the run %limited at the point of
  ::  growth, keeping the true statistics
  |=  [j=job-2 res=result report=@t tr=(unit trace) pre=(list event)]
  ^-  step-result-2
  ?:  (gth (met 3 report) max-artifact.limits.request.j)
    (finish j [%limited %artifact stats.j] pre)
  =.  artifacts.j  (~(put by artifacts.j) %report [%text report])
  =.  artifacts.j
    ?~  tr  artifacts.j
    (~(put by artifacts.j) %trace [%trace u.tr])
  (finish j res pre)
::
++  trace-states
  ::  wire-typed trace states: 1-indexed, initial state has no action
  |=  [sts=(list state:check) act=next-act]
  ^-  (list trace-state)
  =/  i  1
  |-  ^-  (list trace-state)
  ?~  sts  ~
  :_  $(sts t.sts, i +(i))
  [i ?:(=(1 i) ~ act) (state-pairs:check i.sts)]
::
++  wain-text
  |=  w=wain
  ^-  @t
  (rap 3 (join '\0a' w))
--
