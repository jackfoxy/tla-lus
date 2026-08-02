/-  *tla-lus
/=  ast       /lib/ast
/=  syntax    /lib/syntax
/=  check     /lib/check
/=  tp        /lib/temporal
/=  lv        /lib/liveness
/=  semantic  /lib/semantic
/=  ne        /lib/node-eval
/=  config    /lib/config
/=  mod       /lib/modules
/=  stdmods   /lib/stdmods
/=  sp        /lib/source-path
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
+$  job-3
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
+$  step-result-3
  $%  [%more events=(list event) job=job-3]
      [%stop events=(list event) job=job-3]
      ::  the job is waiting on external Clay reads (unit 10): the agent
      ::  performs them and resumes the job with +deliver
      [%await events=(list event) reads=(list read-request) job=job-3]
  ==
::  the source span of the Next action, for typed trace states
+$  next-act  (unit [name=@t at=(unit loc)])
::  a fully loaded source set: what an %inline bundle carries in the
::  request, and what the %modules stage loads for a %clay bundle
+$  srcs
  $:  root=module-name
      modules=(map module-name @t)
      cfg=(unit @t)
  ==
::  one Clay read in flight: the module it stands for (the path being
::  tried and the search roots left after it) or the config file
+$  lread
  $%  [%module name=module-name from=module-name pax=path try=(list path)]
      [%cfg ~]
  ==
::  what a run consumed: where each source came from, and its content
::  hash. The id is the frozen wire typing, so inline and Clay sources
::  are recorded the same way
+$  prov   [id=source-id hash=@]
+$  provs
  $:  root=module-name
      ::  by module name, so the record is deterministic
      mods=(list [name=module-name p=prov])
      cfg=(unit prov)
  ==
::  a source-load failure: a typed diagnostic, or a limit hit at growth
+$  lerr
  $%  [%fail msg=@t]
      [%limited what=limit-kind]
  ==
::  the asynchronous source-load cursor. It never reads Clay: it names
::  the files it needs, and resumes when the agent delivers the bytes
+$  lcur
  $:  root=module-name
      =ship
      =desk
      cas=case
      ::  module-search roots, tried in order (SimpleFilenameToStream)
      roots=(list path)
      cfg-path=(unit path)
      cfg-todo=?
      ::  BFS queue of referenced names not yet requested
      queue=(list [name=module-name from=module-name])
      ::  reads in flight, by tag
      pend=(map @ud lread)
      ::  delivered but not yet absorbed responses
      inbox=(list read-response)
      mods=(map module-name @t)
      ::  the path each loaded module was actually read from
      refs=(map module-name path)
      cfg=(unit @t)
      ::  names that need no further read: loaded files, inner modules
      ::  registered from their outer file, and standard modules
      have=(set module-name)
      ::  names already loaded, queued, or in flight
      asked=(set module-name)
      bytes=@ud
      next=@ud
  ==
::  in-flight pipeline state; versioned via the [%1 k=@] wrapper above
+$  kont
  $%  ::  asynchronous Clay source load
      [%load cur=lcur]
      ::  loaded Clay sources, handed from one stage to the next; inline
      ::  runs never carry one (their bundle is already in the request)
      [%src s=srcs]
      [%parse todo=(list module-name) src=(unit srcs)]
      ::  parsed root module, consumed by the %config stage
      [%tree t=node:check src=(unit srcs)]
      ::  safety search
      [%bfs nl=@t act=next-act o=bfs-opts:check cur=bfs-cursor:check]
      ::  liveness (unit 8.8/8.9): full graph build (%build) then the 8.2–8.6
      ::  tableau/product/SCC/lasso check (%check). Pure []P box-state is a state
      ::  invariant and runs on the safety %bfs path instead (do-config), so no
      ::  first-increment recognizer remains here.
      $:  %live
          phase=?(%build %check)
          oss=(list oos:tp)
          pname=@t
          modn=@t
          act=next-act
          o=bfs-opts:check
          cur=bfs-cursor:check
          ::  %check-phase product slicing (unit 8.8.2a): the OrderOfSolutions
          ::  still to try, and the current one's bounded product-build cursor
          otodo=(list oos:tp)
          pcur=(unit pcursor:lv)
      ==
      ::  seeded simulation
      $:  %sim
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
::  Clay reads one slice may request, bounding a wide dependency fan-out
::  independently of the work budget
++  default-load-budget  8
::  the largest a persisted continuation (jammed BFS or source-load cursor)
::  may grow before a run is stopped %limited — a defense-in-depth bound on
::  the in-flight noun, above what max-states already implies, checked at
::  each slice boundary
++  max-noun-bytes  16.000.000
::  agent-wide bounds, across all jobs. A request's own `limits` bound one job;
::  these bound the ship, so one caller cannot starve it by submitting many
::  small jobs or by never collecting its results. Engine configuration, like
::  default-budget — not caller-visible
+$  gquota
  $:  max-jobs=@ud       ::  concurrent active jobs
      max-retained=@ud   ::  stored artifact bytes, all jobs
      max-inflight=@ud   ::  source bytes active jobs may hold
  ==
++  default-quota
  ^-  gquota
  [max-jobs=8 max-retained=8.000.000 max-inflight=4.000.000]
::
::  +|  Agent-Wide Quotas And Retention
::
::  Every figure below is derived from the jobs map rather than carried as a
::  counter, so the accounting cannot drift from what is actually stored and a
::  deleted job frees its quota by construction.
::
++  artifact-bytes
  ::  one job's stored artifacts, as a noun
  |=  j=job-3
  ^-  @ud
  ?:  =(~ artifacts.j)  0
  (met 3 (jam artifacts.j))
::
++  source-charge
  ::  what one request holds against the in-flight source bound: an inline
  ::  bundle is exactly its bytes; a Clay job has not read its sources yet, so
  ::  it reserves the most it is allowed to read
  |=  req=request
  ^-  @ud
  =/  s  src.req
  ?-    -.s
      %clay  max-source.limits.req
      %inline
    =/  b
      %+  roll  ~(val by modules.s)
      |=([t=@t a=@ud] (add a (met 3 t)))
    (add b ?~(cfg.s 0 (met 3 u.cfg.s)))
  ==
::
++  active-count
  |=  js=(map req-id job-3)
  ^-  @ud
  %+  roll  ~(val by js)
  |=([j=job-3 a=@ud] ?:(?=(^ result.j) a +(a)))
::
++  retained-bytes
  |=  js=(map req-id job-3)
  ^-  @ud
  %+  roll  ~(val by js)
  |=([j=job-3 a=@ud] (add a (artifact-bytes j)))
::
++  inflight-source
  |=  js=(map req-id job-3)
  ^-  @ud
  %+  roll  ~(val by js)
  |=([j=job-3 a=@ud] ?:(?=(^ result.j) a (add a (source-charge request.j))))
::
++  quota-reject
  ::  the agent-wide gate a new job must pass on top of +validate. Each bound
  ::  names the resource it protects; nothing is silently queued behind a full
  ::  store
  |=  [js=(map req-id job-3) q=gquota req=request]
  ^-  (unit @t)
  ?:  (gte (active-count js) max-jobs.q)
    `'global limit: too many active jobs'
  ?:  (gte (retained-bytes js) max-retained.q)
    `'global limit: retained artifact bytes; delete a result first'
  ?:  (gth (add (inflight-source js) (source-charge req)) max-inflight.q)
    `'global limit: in-flight source bytes'
  ~
::
++  reclaim
  ::  artifact retention: over the bound, the oldest terminal jobs give up
  ::  their artifact bodies first. The job, its result, its statistics, and its
  ::  diagnostics stay — only the bulk goes, and a warning on the job records
  ::  it, so a later artifact scry that misses is explained rather than blank.
  ::  An active job is never touched
  |=  [js=(map req-id job-3) cap=@ud]
  ^-  (map req-id job-3)
  ?:  (lte (retained-bytes js) cap)  js
  =/  cands
    ^-  (list [id=req-id j=job-3])
    %+  sort
      ^-  (list [id=req-id j=job-3])
      %+  skim  ~(tap by js)
      |=  [id=req-id j=job-3]
      &(?=(^ result.j) !=(~ artifacts.j))
    |=  [a=[id=req-id j=job-3] b=[id=req-id j=job-3]]
    ?:  =(started.j.a started.j.b)  (aor id.a id.b)
    (lth started.j.a started.j.b)
  |-  ^-  (map req-id job-3)
  ?~  cands  js
  ?:  (lte (retained-bytes js) cap)  js
  =/  dg=diagnostic
    :*  [%lus 403]  %warning  %terminal
        'artifacts reclaimed: the agent-wide retention bound was reached'
        ~  ~
    ==
  =/  jr  j.i.cands
  =.  jr  jr(artifacts ~, diags (snoc diags.jr dg))
  $(js (~(put by js) id.i.cands jr), cands t.cands)
::
++  noun-over
  ::  has a persisted continuation outgrown the in-flight noun bound?
  |=  [c=(unit [%1 k=@]) cap=@ud]
  ^-  ?
  ?~  c  |
  (gth (met 3 k.u.c) cap)
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
  ?:  ?=(%translate -.op.req)
    `'unsupported: PlusCal translation is not ported yet (unit 8)'
  ?:  ?=(%analyze -.op.req)
    (validate-src req)
  ?:  translate.opts.op.req
    `'unsupported: translate-before-check is not ported yet (unit 8)'
  ?:  ?=(^ cfg.opts.op.req)
    `'unsupported: cfg source override; put the config in the bundle'
  ?:  ?=(%clay -.src.req)
    ?~  cfg.src.req
      `'a %check request requires a config'
    (validate-src req)
  ?~  cfg.src.req
    `'a %check request requires a config'
  (validate-src req)
::
++  validate-src
  ::  what can be checked before any work is scheduled: an inline bundle
  ::  against the size limits, a Clay bundle against its reference shape
  ::  (path canonicalization and escape prevention land in unit 10.2)
  |=  req=request
  ^-  (unit @t)
  ?-  -.src.req
    %inline  (validate-bundle req)
    %clay    (validate-clay req)
  ==
::
++  validate-clay
  ::  the whole path surface is judged before a job exists: desk, root
  ::  module name, search roots, and the config path (which must itself
  ::  lie under a declared root). A bad path names its offending segment
  |=  req=request
  ^-  (unit @t)
  ?>  ?=(%clay -.src.req)
  =/  e
    %:  check-bundle:sp
      desk.src.req
      root.src.req
      cfg.src.req
      roots.src.req
    ==
  ?~(e ~ `(err-text:sp u.e))
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
  ::  ordered stages for a request; every planned stage does real work.
  ::  A %clay bundle loads its sources first; whether it also needs a
  ::  %liveness stage is unknown until its config is read, so %config
  ::  appends that stage when the loaded config names a PROPERTY
  |=  req=request
  ^-  (list stage)
  %+  weld
    ?:(?=(%clay -.src.req) `(list stage)`~[%modules] ~)
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
  ::  does the config name a temporal PROPERTY? (structural cfg parse,
  ::  no graph — the %config stage does full validation later)
  |=  req=request
  ^-  ?
  ?.  ?=(%inline -.src.req)  |
  ?~  cfg.src.req  |
  =/  pr  (parse-cfg:config u.cfg.src.req)
  ?&(?=(%& -.pr) ?=(^ properties.p.pr))
::
::  +|  Engine
::
::
++  init
  ::  start a job at %starting with its full stage plan pending
  |=  [req=request now=@da]
  ^-  job-3
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
    %load   `%modules
    %src    ~
    %parse  `%parse
    %tree   ~
    %bfs    `%explore
    %live   ?:(=(%build phase.k) `%explore `%liveness)
    %sim    `%simulate
  ==
::
++  k-srcs
  ::  the loaded Clay sources a continuation carries between stages
  |=  k=(unit kont)
  ^-  (unit srcs)
  ?~  k  ~
  ?+  -.u.k  ~
    %src    `s.u.k
    %parse  src.u.k
    %tree   src.u.k
  ==
::
++  srcs-of
  ::  the sources a stage works on: the request's inline bundle, or the
  ::  set the %modules stage loaded over Clay
  |=  [j=job-3 s=(unit srcs)]
  ^-  (unit srcs)
  ?^  s  s
  ?.  ?=(%inline -.src.request.j)  ~
  `[root.src.request.j modules.src.request.j cfg.src.request.j]
::
++  carry
  ::  loaded Clay sources travel with the continuation; an inline bundle
  ::  is already in the request and is never copied into it
  |=  [j=job-3 s=(unit srcs)]
  ^-  (unit srcs)
  ?:(?=(%inline -.src.request.j) ~ s)
::
++  time-exceeded
  |=  [j=job-3 now=@da]
  ^-  ?
  ?:  (lte now started.j)  |
  (gth `@dr`(sub now started.j) max-time.limits.request.j)
::
++  step
  ::  spend at most `budget` work units on the job's active stage;
  ::  already-terminal jobs are unchanged
  |=  [j=job-3 budget=@ud now=@da]
  ^-  step-result-3
  ?^  result.j  [%stop ~ j]
  ?:  (time-exceeded j now)
    (finish j [%limited %time stats.j] ~)
  ::  a continuation jammed by an incompatible engine version (e.g. an older
  ::  BFS-cursor shape) cannot be revived; fail the job with a restart notice
  ::  rather than crash the agent event (Work Unit 7.7 migration contract)
  =/  lr=(each (unit kont) tang)
    ?~  cont.j  [%& ~]
    =/  m  (mule |.((load-kont u.cont.j)))
    ?:(?=(%& -.m) [%& `p.m] [%| p.m])
  ?:  ?=(%| -.lr)
    (finish j [%failed 'restarted: the in-flight state is from an incompatible engine version; resubmit'] ~)
  =/  k=(unit kont)  p.lr
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
    ^-  job-3
    j(stage s, pending t.pending.j, progress prog)
  (run j k budget ~[[%stage s] [%progress prog]])
::
++  run
  ::  execute one bounded slice of the active stage
  |=  [j=job-3 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-3
  ?+    stage.j
      ~|([%tla-lus-unplanned-stage stage.j] !!)
    %modules   (do-load j k pre)
    %parse     (do-parse j k budget pre)
    %semantic  (do-semantic j k pre)
    %config    (do-config j k pre)
    %explore   (do-explore j k budget pre)
    %liveness  (do-scan j k budget pre)
    %simulate  (do-sim j k budget pre)
    %terminal  (do-terminal j pre)
  ==
::
++  more
  ::  a non-terminal slice; heartbeat progress when nothing else to say
  |=  [j=job-3 evs=(list event)]
  ^-  step-result-3
  [%more ?~(evs ~[[%progress progress.j]] evs) j]
::
++  await
  ::  pause the job on external Clay reads; the agent performs them and
  ::  resumes it with +deliver. No work is scheduled in the meantime
  |=  [j=job-3 reads=(list read-request) evs=(list event)]
  ^-  step-result-3
  [%await evs reads j]
::
++  deliver
  ::  absorb the agent's answers into the source-load cursor. Responses
  ::  for tags the cursor is not waiting on are dropped when it drains
  ::  the inbox, so a duplicate or stale delivery changes nothing
  |=  [j=job-3 rs=(list read-response)]
  ^-  job-3
  ?~  rs  j
  ?~  cont.j  j
  =/  lr  (mule |.((load-kont u.cont.j)))
  ?.  ?=(%& -.lr)  j
  ?.  ?=(%load -.p.lr)  j
  =/  c  cur.p.lr
  =.  inbox.c  (weld inbox.c rs)
  j(cont (save-kont [%load c]))
::
++  awaiting
  ::  is this job actually waiting on that read? A response for a tag it
  ::  does not hold is a duplicate, a stale delivery, or a leftover from
  ::  a superseded load; it must not be absorbed and must not advance the
  ::  job by a slice
  |=  [j=job-3 tag=@ud]
  ^-  ?
  ?~  cont.j  |
  =/  lr  (mule |.((load-kont u.cont.j)))
  ?.  ?=(%& -.lr)  |
  ?.  ?=(%load -.p.lr)  |
  (~(has by pend.cur.p.lr) tag)
::
++  finish
  ::  seal the job; a sealed job is never resumed
  |=  [j=job-3 res=result pre=(list event)]
  ^-  step-result-3
  =.  result.j   `res
  =.  stage.j    %terminal
  =.  pending.j  ~
  =.  cont.j     ~
  [%stop (snoc pre [%result res]) j]
::
++  cancel
  |=  j=job-3
  ^-  job-3
  j(result `[%cancelled ~], stage %terminal, pending ~, cont ~)
::
++  project
  ::  the public job view: results and progress, never internal cursors
  |=  j=job-3
  ^-  job
  :*  request.j  stage.j  pending.j  progress.j
      stats.j  diags.j  artifacts.j  result.j
  ==
::
::  +|  Stage: %modules (asynchronous Clay source load)
::
::
++  missing-msg
  |=  [name=module-name from=module-name]
  ^-  @t
  ?:  =('' from)
    (rap 3 ~['Cannot find source file for module ' name '.'])
  %+  rap  3
  :~  'Cannot find source file for module '  name
      ' imported in module '  from  '.'
  ==
::
++  mismatch-msg
  |=  [file=module-name declared=module-name]
  ^-  @t
  %+  rap  3
  :~  'File name \''  file  '\' does not match the name \''
      declared  '\' of the top level module it contains.'
  ==
::
++  load-init
  |=  s=source-bundle
  ^-  lcur
  ?>  ?=(%clay -.s)
  :*  root.s  ship.s  desk.s  cas.s  roots.s
      cfg-path=cfg.s
      cfg-todo=?=(^ cfg.s)
      queue=~[[root.s '']]
      pend=~
      inbox=~
      mods=~
      refs=~
      cfg=~
      have=~
      asked=(silt ~[root.s])
      bytes=0
      next=0
  ==
::
++  load-ask
  ::  put one read in flight and return its tagged request. The path is
  ::  canonicalized by lib/source-path, the only constructor of a
  ::  source-ref, so an escaping or out-of-root read cannot be issued
  |=  [c=lcur p=lread pax=path]
  ^-  (each [read-request lcur] path-err:sp)
  =/  rr  (read-ref:sp ship.c desk.c cas.c roots.c pax)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =/  tag  next.c
  =.  next.c  +(next.c)
  =.  pend.c  (~(put by pend.c) tag p)
  [%& [[tag p.rr] c]]
::
++  load-cand
  ::  the candidate file for a module under one search root, as a read.
  ::  The pending entry remembers the path so a hit can record where the
  ::  module actually came from
  |=  [c=lcur from=module-name name=module-name rot=path try=(list path)]
  ^-  (each [read-request lcur] path-err:sp)
  =/  mp  (module-path:sp rot name)
  ?:  ?=(%| -.mp)  [%| p.mp]
  (load-ask c [%module name from p.mp try] p.mp)
::
++  load-drain
  ::  absorb delivered responses. A hit registers the module (or the
  ::  config) and enqueues its references in appearance order; a miss
  ::  falls back to the next search root, then to the standard modules,
  ::  and finally fails with the text SANY reports for the same condition
  |=  [c=lcur lims=limits]
  ^-  [cur=lcur reads=(list read-request) err=(unit lerr)]
  =|  reads=(list read-request)
  |-  ^-  [lcur (list read-request) (unit lerr)]
  ::  a narrowed wing cannot be mutated in place: copy, test, then put
  ::  the widened tail back on the cursor
  =/  ibx  inbox.c
  ?~  ibx  [c (flop reads) ~]
  =/  r  i.ibx
  =.  c  c(inbox t.ibx)
  =/  p  (~(get by pend.c) tag.r)
  ::  an unknown tag is a duplicate or stale delivery: dropped
  ?~  p  $
  =.  pend.c  (~(del by pend.c) tag.r)
  ?-    -.u.p
      %cfg
    ?:  ?=(%| -.res.r)
      [c (flop reads) `[%fail 'Cannot find the config file.']]
    =.  cfg.c    `p.res.r
    =.  bytes.c  (add bytes.c (met 3 p.res.r))
    ?:  (gth bytes.c max-source.lims)
      [c (flop reads) `[%limited %source]]
    $
  ::
      %module
    ?:  ?=(%| -.res.r)
      ::  not under this search root: try the next one
      =/  tr  try.u.p
      ?^  tr
        =/  la  (load-cand c from.u.p name.u.p i.tr t.tr)
        ?:  ?=(%| -.la)
          [c (flop reads) `[%fail (err-text:sp p.la)]]
        =.  c  +.p.la
        $(reads [-.p.la reads])
      ::  a name with no user file falls back to the standard modules,
      ::  which the resolver supplies from the vendored set
      ?:  (~(has by standard-modules:stdmods) name.u.p)
        =.  have.c  (~(put in have.c) name.u.p)
        $
      [c (flop reads) `[%fail (missing-msg name.u.p from.u.p)]]
    =/  txt  p.res.r
    =.  bytes.c  (add bytes.c (met 3 txt))
    ?:  (gth bytes.c max-source.lims)
      [c (flop reads) `[%limited %source]]
    =.  mods.c  (~(put by mods.c) name.u.p txt)
    =.  refs.c  (~(put by refs.c) name.u.p pax.u.p)
    =.  have.c  (~(put in have.c) name.u.p)
    ?:  (gth ~(wyt by mods.c) max-modules.lims)
      [c (flop reads) `[%limited %modules]]
    ::  an unparsable module is registered as it arrived and contributes
    ::  no references: the %parse stage then reports SANY's own error
    ::  text, exactly as it does for an inline bundle
    =/  pr  (mule |.((parse:syntax txt)))
    ?.  ?&(?=(%& -.pr) ?=(%& -.p.pr))  $
    =/  tree  p.p.pr
    ::  SANY's file-name check: the file is named for the lowercased
    ::  module, but the declared name must match the requested one
    =/  dec  (module-name-of:mod tree)
    ?:  &(?=(^ dec) !=(u.dec name.u.p))
      [c (flop reads) `[%fail (mismatch-msg name.u.p u.dec)]]
    ::  inner modules are registered from their outer file, so a
    ::  reference to one never becomes a read
    =.  have.c
      %-  ~(gas in have.c)
      (turn (inner-modules:mod tree) |=([nm=@t *] nm))
    =.  c
      %+  roll  (refs-of:mod tree)
      |=  [nm=module-name a=_c]
      ?:  (~(has in have.a) nm)   a
      ?:  (~(has in asked.a) nm)  a
      %=  a
        queue  (snoc queue.a [nm name.u.p])
        asked  (~(put in asked.a) nm)
      ==
    $
  ==
::
++  load-ask-more
  ::  request up to `budget` new reads: the config first, then queued
  ::  module names in BFS order, each at its first search root
  |=  [c=lcur budget=@ud]
  ^-  [cur=lcur reads=(list read-request) err=(unit lerr)]
  =|  out=(list read-request)
  =/  n  0
  |-  ^-  [lcur (list read-request) (unit lerr)]
  ?:  (gte n budget)  [c (flop out) ~]
  ?:  cfg-todo.c
    ::  test a copy: narrowing the cursor's own field would freeze it
    =/  cp  cfg-path.c
    ?~  cp  $(cfg-todo.c |)
    =.  cfg-todo.c  |
    =/  la  (load-ask c [%cfg ~] u.cp)
    ?:  ?=(%| -.la)  [c (flop out) `[%fail (err-text:sp p.la)]]
    =.  c  +.p.la
    $(out [-.p.la out], n +(n))
  =/  que  queue.c
  ?~  que  [c (flop out) ~]
  ::  a bundle with no search root is rejected at +validate
  =/  rts  roots.c
  ?>  ?=(^ rts)
  =/  q  i.que
  =.  c  c(queue t.que)
  =/  la  (load-cand c from.q name.q i.rts t.rts)
  ?:  ?=(%| -.la)  [c (flop out) `[%fail (err-text:sp p.la)]]
  =.  c  +.p.la
  $(out [-.p.la out], n +(n))
::
++  id-text
  ::  a source id as text: the scry path a Clay read used, or the
  ::  inline bundle's own name for it
  |=  id=source-id
  ^-  @t
  ?-    -.id
      %inline  ?:(=('' name.id) 'inline' (rap 3 ~['inline/' name.id]))
      %clay
    (spat `path`[(scot %p ship.id) desk.id (scot cas.id) path.id])
  ==
::
++  render-sources
  ::  the provenance record: every source this run consumed, named by
  ::  where it came from and hashed by what it contained. Vendored
  ::  standard modules are not listed — they are fixed by the desk
  |=  ps=provs
  ^-  @t
  %-  wain-text
  ;:  weld
    ~[(rap 3 ~['root ' root.ps])]
  ::
    %+  turn  mods.ps
    |=  [nm=module-name p=prov]
    ^-  @t
    (rap 3 ~['module ' nm ' ' (scot %ux hash.p) ' ' (id-text id.p)])
  ::
    ?~  cfg.ps  ~
    :_  ~
    (rap 3 ~['config ' (scot %ux hash.u.cfg.ps) ' ' (id-text id.u.cfg.ps)])
  ==
::
++  put-sources
  ::  store the provenance record as soon as the sources are known, so a
  ::  run that later fails still says what it read. It is engine
  ::  metadata, not the caller's output: when it does not fit inside
  ::  max-artifact it is dropped with a warning rather than failing an
  ::  otherwise sound run — but never dropped silently
  |=  [j=job-3 ps=provs]
  ^-  [job-3 (list event)]
  =/  txt  (render-sources ps)
  ?:  (gth (met 3 txt) max-artifact.limits.request.j)
    =/  dg=diagnostic
      :*  [%lus 402]  %warning  %modules
          'source provenance omitted: it exceeds max-artifact'
          ~  ~
      ==
    [j(diags (snoc diags.j dg)) ~[[%diagnostic dg]]]
  [j(artifacts (~(put by artifacts.j) %sources [%text txt])) ~]
::
++  clay-provs
  ::  what the load cursor read, by module name
  |=  c=lcur
  ^-  provs
  :+  root.c
    %+  turn  (sort ~(tap in ~(key by mods.c)) aor)
    |=  nm=module-name
    ^-  [module-name prov]
    :-  nm
    :-  [%clay ship.c desk.c cas.c (~(gut by refs.c) nm ~)]
    (shax (~(gut by mods.c) nm ''))
  ?~  cfg.c  ~
  ?~  cfg-path.c  ~
  `[[%clay ship.c desk.c cas.c u.cfg-path.c] (shax u.cfg.c)]
::
++  inline-provs
  ::  an inline bundle records the same shape: the caller supplied the
  ::  bytes, so the id is the bundle's own name for each module
  |=  s=srcs
  ^-  provs
  :+  root.s
    %+  turn  (sort ~(tap in ~(key by modules.s)) aor)
    |=  nm=module-name
    ^-  [module-name prov]
    [nm [%inline nm] (shax (~(gut by modules.s) nm ''))]
  ?~  cfg.s  ~
  `[[%inline ''] (shax u.cfg.s)]
::
++  close-load
  ::  the module graph is closed: record what was read, then hand the
  ::  sources to %parse exactly as an inline bundle would
  |=  [j=job-3 ps=provs s=srcs pre=(list event)]
  ^-  step-result-3
  =/  po  (put-sources j ps)
  =/  jp  -.po
  =.  cont.jp  (save-kont [%src s])
  (more jp (weld pre +.po))
::
++  load-fail
  ::  a resolution failure is a typed diagnostic at the %modules stage,
  ::  carrying the text the inline resolver reports for the same condition
  |=  [j=job-3 msg=@t pre=(list event)]
  ^-  step-result-3
  =/  dg=diagnostic  [[%lus 401] %error %modules msg ~ ~]
  =.  diags.j  (snoc diags.j dg)
  (finish j [%failed msg] (snoc pre [%diagnostic dg]))
::
++  do-load
  ::  close the module graph over asynchronous reads. No stage may touch
  ::  Clay: this one names the files it needs and pauses (%await), and
  ::  the sources it hands to %parse are exactly what an inline bundle of
  ::  the same files would hand it
  |=  [j=job-3 k=(unit kont) pre=(list event)]
  ^-  step-result-3
  ?.  ?=(%clay -.src.request.j)
    (finish j [%failed 'internal: %modules on an inline bundle'] pre)
  ::  the whole run reads one revision; the agent pins it at submit, and
  ::  lib/source-path will not name a file at an unpinned case
  ?.  ?=(%ud -.cas.src.request.j)
    (load-fail j (err-text:sp [%unpinned cas.src.request.j]) pre)
  =/  c=lcur
    ?:  ?&(?=(^ k) ?=(%load -.u.k))  cur.u.k
    (load-init src.request.j)
  =/  dr  (load-drain c limits.request.j)
  =.  c  cur.dr
  ?^  err.dr
    ?-  -.u.err.dr
      %fail     (load-fail j msg.u.err.dr pre)
      %limited  (finish j [%limited what.u.err.dr stats.j] pre)
    ==
  =/  am  (load-ask-more c default-load-budget)
  =.  c  cur.am
  ?^  err.am
    ?-  -.u.err.am
      %fail     (load-fail j msg.u.err.am pre)
      %limited  (finish j [%limited what.u.err.am stats.j] pre)
    ==
  =/  reads  (weld reads.dr reads.am)
  ?^  pend.c
    =.  cont.j  (save-kont [%load c])
    ::  a pathological dependency fan-out cannot grow an unbounded jammed
    ::  resolver state, exactly as a search cursor cannot
    ?:  (noun-over cont.j max-noun-bytes)
      (finish j [%limited %noun stats.j] pre)
    (await j reads pre)
  ::  the graph is closed
  ?:  &(?=(^ cfg-path.c) ?=(~ cfg.c))
    (load-fail j 'Cannot find the config file.' pre)
  ::  `j` is narrowed to the %clay bundle here, so the hand-off happens
  ::  in a gate of its own rather than by writing back into it
  (close-load j (clay-provs c) [root.c mods.c cfg.c] pre)
::
::  +|  Stage: %parse
::
::
++  do-parse
  ::  %check parses the root module into a %tree hand-off; %analyze
  ::  parses every bundle module, one work unit each, collecting
  ::  diagnostics for %terminal's verdict
  |=  [j=job-3 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-3
  =/  so  (srcs-of j (k-srcs k))
  ?~  so
    (finish j [%failed 'internal: %parse without loaded sources'] pre)
  =/  src  u.so
  =/  cry  (carry j so)
  ::  an inline bundle's provenance is recorded here, where a Clay run
  ::  recorded its own at the close of the load
  =/  po=[job-3 (list event)]
    ?:  |(?=(%clay -.src.request.j) (~(has by artifacts.j) %sources))
      [j ~]
    (put-sources j (inline-provs src))
  =.  j    -.po
  =.  pre  (weld pre +.po)
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
    =.  cont.j  (save-kont [%tree u.tree.pt cry])
    (more j pre)
  ::  %analyze
  =/  kk=kont
    ?:  ?&(?=(^ k) ?=(%parse -.u.k))  u.k
    [%parse (sort ~(tap in ~(key by modules.src)) aor) cry]
  ?>  ?=(%parse -.kk)
  =/  evs  pre
  =/  spent  0
  |-  ^-  step-result-3
  ?~  todo.kk
    ::  Clay sources travel on to the %semantic stage
    =.  cont.j  ?~(cry ~ (save-kont [%src u.cry]))
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
  |=  [j=job-3 k=(unit kont) pre=(list event)]
  ^-  step-result-3
  ?>  ?=(%analyze -.op.request.j)
  =/  so  (srcs-of j (k-srcs k))
  ?~  so
    (finish j [%failed 'internal: %semantic without loaded sources'] pre)
  =/  src    u.so
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
++  config-fail
  ::  a config diagnostic (CFG_* 5001-5006 or TLC_CONFIG_* 2222-2281) is
  ::  a typed TLC failure: record the structured diagnostic and seal the
  ::  job %failed with its message (never a silent %ok)
  |=  [j=job-3 d=cfg-vdiag:config pre=(list event)]
  ^-  step-result-3
  =/  dg=diagnostic  [[%tlc code.d] %error %config msg.d ~ ~]
  =.  diags.j  (snoc diags.j dg)
  (finish j [%failed msg.d] (snoc pre [%diagnostic dg]))
::
++  assume-fail
  ::  a false (EC 2104) or non-boolean (EC 2105) ASSUME is a typed TLC failure
  ::  at the model-checking stage, recorded like a config diagnostic
  |=  [j=job-3 ec=@ud msg=@t pre=(list event)]
  ^-  step-result-3
  =/  dg=diagnostic  [[%tlc ec] %error %explore msg ~ ~]
  =.  diags.j  (snoc diags.j dg)
  (finish j [%failed msg] (snoc pre [%diagnostic dg]))
::
++  do-config
  ::  consume the parsed root tree and build the engine continuation.
  ::  Every config this engine cannot process faithfully is a typed
  ::  failure naming the key or form; nothing is silently ignored.
  |=  [j=job-3 k=(unit kont) pre=(list event)]
  ^-  step-result-3
  ?.  ?&(?=(^ k) ?=(%tree -.u.k))
    (finish j [%failed 'internal: %config without a parsed tree'] pre)
  =/  tree  t.u.k
  ?>  ?=(%check -.op.request.j)
  =/  so  (srcs-of j (k-srcs k))
  ?~  so
    (finish j [%failed 'internal: %config without loaded sources'] pre)
  =/  src   u.so
  ?~  cfg.src
    (finish j [%failed 'a %check request requires a config'] pre)
  =/  cfg   u.cfg.src
  =/  mode  mode.opts.op.request.j
  =/  lims  limits.request.j
  ::  real config pipeline (unit 5): parse -> validate against the WU3
  ::  graph -> assemble the typed run-spec. One bounded slice (graph
  ::  generation, like a capped run-check); a config diagnostic is a
  ::  typed TLC failure, not a silent %ok.
  ::  the semantic graph is generated once and reused by the config
  ::  assembly and the checker (it used to be built twice, reparsing
  ::  every module both times)
  =/  mo  (generate:semantic root.src modules.src)
  ?~  mo  (config-fail j [0 'internal: module generation failed'] pre)
  =/  rso  (run-spec-with:config u.mo cfg)
  ?:  ?=(%| -.rso)  (config-fail j p.rso pre)
  =/  rs  p.rso
  ?.  ?=(%init-next -.mode.rs)
    (finish j [%failed 'unsupported: SPECIFICATION form config (deep processConfigSpec, unit 5 residue)'] pre)
  =/  in  init.mode.rs
  =/  nx  next.mode.rs
  ::  all invariants are checked in declaration order (7.3); `iv` is the first
  ::  one, still used for the INVARIANT/PROPERTY-conflict guard and definition
  ::  existence checks below
  =/  iv=(unit @t)  ?~(invariants.rs ~ `i.invariants.rs)
  =/  pp=(unit @t)  ?~(properties.rs ~ `i.properties.rs)
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
  =/  order  (var-order:check tree)
  =/  modn  (module-name-of:check tree)
  =/  nl    (next-span-label:check u.nb modn)
  =/  act=next-act
    =/  sp  (span-of:ast u.nb)
    `[u.nx ?~(sp ~ `[modn u.sp])]
  ::  safety, liveness, and simulation all run on the Work Unit 3 SEMANTIC
  ::  graph via node-eval (unit 9.2 retired simulation's CST solver).
  =/  defs    (defmap-of:ne u.mo)
  =/  consts  (consts-of:check constants.rs)
  ::  TLC checks module assumptions before the search (Tool.checkAssumptions);
  ::  a false or non-boolean ASSUME is a typed TLC failure, never a silent skip
  =/  ae  (check-assumes:check assumes.u.mo (make-env:ne defs consts vars))
  ?^  ae  (assume-fail j ec.u.ae msg.u.ae pre)
  ::  symmetry group (SYMMETRY) with a temporal property: TLC warns (2279) and
  ::  continues, but the port cannot yet run liveness on the reduced graph, so it
  ::  type-rejects with the pinned 2279 warning text — keyed on the SYMMETRY
  ::  declaration, before symmetry-perms/init (which error first) (unit 8.7.2)
  ?:  &(?=(^ symmetry.rs) ?=(^ pp))
    =/  msg=@t
      %^    cat  3
          'Declaring symmetry during liveness checking is dangerous. '
        %^  cat  3
          'It might cause TLC to miss violations of the stated liveness properties. '
        'Please check liveness without symmetry defined.'
    (finish j [%failed msg] pre)
  =/  pr  (symmetry-perms:check defs consts vars symmetry.rs)
  ?:  ?=(%| -.pr)  (finish j [%failed p.pr] pre)
  =/  perms  p.pr
  =/  isb  (sem-body:check defs u.in)
  =/  nsb  (sem-body:check defs u.nx)
  ?~  isb  (finish j [%failed (rap 3 ~['no definition for INIT ' u.in])] pre)
  ?~  nsb  (finish j [%failed (rap 3 ~['no definition for NEXT ' u.nx])] pre)
  =/  invs   (resolve-invs:check defs invariants.rs)
  =/  cons   (resolve-bodies:check defs constraints.rs)
  =/  acons  (resolve-bodies:check defs action-constraints.rs)
  =/  isr  (init-states:ne u.isb (make-env:ne defs consts vars))
  ?:  ?=(%| -.isr)  (finish j [%failed msg.p.isr] pre)
  =/  is  p.isr
  ::  seeded simulation (unit 9.2): SimulationWorker over the semantic graph,
  ::  drawing with java.util.Random (lib/rng) so a run reproduces `tlc2.TLC
  ::  -simulate -workers 1`. A temporal PROPERTY is checked per behavior over its
  ::  stutter graph (unit 9.3a, LiveCheck.checkTrace via the 8.2–8.6 engine).
  ?:  ?=(%simulate -.mode)
    =/  dep
      ?:(=(0 max-depth.lims) depth.mode (min depth.mode max-depth.lims))
    =/  actions  (get-actions:check u.nsb 'Next' defs)
    ::  normalize the PROPERTY (if any) into the OrderOfSolution form; an
    ::  unsupported property is a typed rejection, never a silent %ok
    =/  osr=(each (list oos:tp) aerr:tp)
      ?~  pp  [%& ~]
      =/  psb  (sem-body:check defs u.pp)
      ?~  psb  [%| [0 (rap 3 ~['no definition for PROPERTY ' u.pp])]]
      (oss-of:check ~[u.psb] ~ (make-env:ne defs consts vars))
    ?:  ?=(%| -.osr)  (finish j [%failed msg.p.osr] pre)
    =/  o=sim-opts:check
      [actions invs p.osr ?~(pp '' u.pp) defs consts vars order num.mode dep]
    =.  cont.j  (save-kont [%sim nl act o (sim-cursor-init:check is seed.mode)])
    (more j pre)
  ?^  pp
    =/  psb  (sem-body:check defs u.pp)
    ?~  psb
      (finish j [%failed (rap 3 ~['no definition for PROPERTY ' u.pp])] pre)
    ::  a pure []P box-state property is a state invariant P, which TLC checks
    ::  via the safety search (processConfigProps) — reuse the invariant engine,
    ::  terminating in %explore before the planned %liveness stage (unit 8.9)
    =/  binner  (box-state-inner:tp u.psb)
    ?^  binner
      ::  box-state terminates in %explore, so drop the planned (never-run)
      ::  %liveness stage from the plan and its total
      =?  j  (lien pending.j |=(s=stage =(%liveness s)))
        %=  j
          pending   (skip pending.j |=(s=stage =(%liveness s)))
          progress  [done.progress.j (dec total.progress.j)]
        ==
      =/  o=bfs-opts:check
        :*  u.nsb  ~[[u.pp u.binner]]  cons  acons  vars  order  perms  defs
            consts  ?&(deadlock.mode deadlock.rs)  max-states.lims  max-depth.lims
        ==
      =.  cont.j  (save-kont [%bfs nl act o (bfs-init:check is)])
      (more j pre)
    ::  a genuine temporal property runs the 8.2–8.6 engine in the %liveness
    ::  stage; a %clay run could not know it needs that stage until its config
    ::  is read, so the plan grows here, honestly, with its total
    =?  j  !(lien pending.j |=(s=stage =(%liveness s)))
      %=  j
        pending   (snoc pending.j %liveness)
        progress  [done.progress.j +(total.progress.j)]
      ==
    ::  normalize the property into the 8.1 OrderOfSolution form (no fairness in
    ::  %init-next mode); a non-boolean/unsupported leaf is a typed rejection
    =/  osr  (oss-of:check ~[u.psb] ~ (make-env:ne defs consts vars))
    ?:  ?=(%| -.osr)  (finish j [%failed msg.p.osr] pre)
    =/  o=bfs-opts:check
      [u.nsb ~ ~ ~ vars order ~ defs consts | max-states.lims max-depth.lims]
    =.  cont.j
      %-  save-kont
      :*  %live  %build  p.osr  u.pp  modn  act
          o  (bfs-init:check is)  ~  ~
      ==
    (more j pre)
  ::  safety search: all invariants (ordered), state/action constraints, and
  ::  the effective deadlock flag (CLI flag AND the cfg CHECK_DEADLOCK flag,
  ::  matching TLC's `deadlock && getCheckDeadlock()`)
  =/  o=bfs-opts:check
    :*  u.nsb  invs  cons  acons  vars  order  perms  defs  consts
        ?&(deadlock.mode deadlock.rs)  max-states.lims  max-depth.lims
    ==
  =.  cont.j  (save-kont [%bfs nl act o (bfs-init:check is)])
  (more j pre)
::
::  +|  Stage: %explore
::
::
++  do-explore
  |=  [j=job-3 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-3
  ?:  ?&(?=(^ k) ?=(%bfs -.u.k))
    =/  kk  u.k
    =/  r  (bfs-step:check o.kk cur.kk budget)
    ?:  ?=(%more -.r)
      ::  live statistics at the slice boundary (deterministic, resumable): the
      ::  public view reflects search progress, not just the final report
      =.  stats.j  [gen.cur.r distinct.cur.r (lent queue.cur.r) depth.cur.r]
      =.  cont.j  (save-kont kk(cur cur.r))
      ::  bound the persisted noun: a search whose cursor outgrows the limit is
      ::  stopped %limited with the limiting resource, never carried unbounded
      ?:  (noun-over cont.j max-noun-bytes)
        (finish j [%limited %noun stats.j] pre)
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
    ::  the graph is built; hand off to the 8.2–8.6 %check phase (unit 8.8)
    =.  cont.j  (save-kont kk(phase %check, cur cur.r, otodo oss.kk, pcur ~))
    (more j pre)
  (finish j [%failed 'internal: %explore without a search continuation'] pre)
::
++  finish-bfs
  ::  seal a safety search: wire result, stats, report + trace artifacts
  |=  [j=job-3 out=outcome:check nl=@t act=next-act pre=(list event)]
  ^-  step-result-3
  ?:  ?=(%error -.out)  (finish j [%failed msg.out] pre)
  =/  st=run-stats
    ?-  -.out
      %ok        [gen.out distinct.out queued.out depth.out]
      %limited   [gen.out distinct.out queued.out depth.out]
      %inv       [gen.out distinct.out queued.out depth.out]
      %deadlock  [gen.out distinct.out queued.out depth.out]
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
  |=  [j=job-3 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-3
  ?.  ?&(?=(^ k) ?=(%live -.u.k) =(%check phase.u.k))
    (finish j [%failed 'internal: %liveness without a check continuation'] pre)
  =/  kk  u.k
  ::  the 8.2–8.6 temporal check on the built graph (unit 8.8.2a): try each
  ::  OrderOfSolution in turn, slicing the product build a budget at a time; on
  ::  the first violated one render tlc2.TLC's console diagnostic + typed result.
  =/  st      stats.j
  =/  states  (states-of:check seen.cur.kk)
  =/  env     (make-env:ne defs.o.kk consts.o.kk vars.o.kk)
  ::  no OrderOfSolution left to try → no temporal violation
  ?~  otodo.kk
    =/  report
      %-  wain-text
      %-  live-render:check
      :*  ~  states  next.o.kk  env  order.o.kk  modn.kk  defs.o.kk  pname.kk
          generated.st  distinct.st  depth.st
      ==
    (finish-arts j [%ok st] report ~ pre)
  =/  o  i.otodo.kk
  ::  obtain this OOS's lasso, slicing a tf product build; %more persists the
  ::  cursor and continues, %done carries the (unit lasso)
  =/  res
    ^-  $%([%more cur=pcursor:lv] [%done lasso=(unit lasso:lv)])
    ?~  tf.o
      :-  %done
      %+  lasso-of-product:lv  o
      (labeled-product:lv o states inits.cur.kk next.o.kk env order.o.kk)
    =/  pc  ?~(pcur.kk (product-init:lv o states inits.cur.kk env) u.pcur.kk)
    =/  r   (product-step:lv o states next.o.kk env order.o.kk pc budget)
    ?.  done.r  [%more cur.r]
    [%done (lasso-of-product:lv o [nodes.cur.r edges.cur.r inits.cur.r])]
  ?:  ?=(%more -.res)
    ::  bound the persisted product cursor, like the safety search
    =.  cont.j  (save-kont kk(pcur `cur.res))
    ?:  (noun-over cont.j max-noun-bytes)  (finish j [%limited %noun st] pre)
    (more j pre)
  =/  l  lasso.res
  ?~  l
    ::  this OOS has no accepting lasso → try the next one, fresh cursor
    =.  cont.j  (save-kont kk(otodo t.otodo.kk, pcur ~))
    (more j pre)
  =/  report
    %-  wain-text
    %-  live-render:check
    :*  l  states  next.o.kk  env  order.o.kk  modn.kk  defs.o.kk  pname.kk
        generated.st  distinct.st  depth.st
    ==
  =/  tr-states=(list state:check)
    (turn prefix.u.l |=(fp=@t (~(got by states) fp)))
  =/  typed=trace  [%lasso (trace-states tr-states act.kk) `loop.u.l]
  (finish-arts j [%violated [%property pname.kk] st] report `typed pre)
::
::  +|  Stage: %simulate
::
::
++  do-sim
  |=  [j=job-3 k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-result-3
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
  =/  vk     kind.u.viol.res.r
  =/  vname  name.u.viol.res.r
  =/  vpath  path.u.viol.res.r
  =/  headline=@t
    ?-  vk
      %invariant  (crip "Error: Invariant {(trip vname)} is violated.")
      %property   (crip "Error: Temporal property {(trip vname)} is violated.")
    ==
  =/  report
    %-  wain-text
    ;:  weld
      ~[headline]
      ~['Error: The behavior up to this point is:']
      (render-trace:check vpath nl.kk)
      ~[head]
    ==
  =/  typed=trace  [%simulate (trace-states vpath act.kk) ~]
  =/  vn  ?-(vk %invariant [%invariant vname], %property [%property vname])
  (finish-arts j [%violated vn st] report `typed pre)
::
::  +|  Stage: %terminal
::
::
++  do-terminal
  ::  %analyze verdict: fail iff any error-severity diagnostic was
  ::  recorded by a parse, semantic, or level stage (lint warnings do
  ::  not fail the run unless a lint-option elevated one to %error,
  ::  which flips its severity here)
  |=  [j=job-3 pre=(list event)]
  ^-  step-result-3
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
  |=  [j=job-3 res=result report=@t tr=(unit trace) pre=(list event)]
  ^-  step-result-3
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
