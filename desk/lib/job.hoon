/-  *tla-lus
/=  ast       /lib/ast
/=  syntax    /lib/syntax
/=  check     /lib/check
/=  fp        /lib/fingerprint
/=  tp        /lib/temporal
/=  lv        /lib/liveness
/=  semantic  /lib/semantic
/=  ne        /lib/node-eval
/=  config    /lib/config
/=  mod       /lib/modules
/=  stdmods   /lib/stdmods
/=  sp        /lib/source-path
/=  rng       /lib/rng
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
+$  jobstate
  $:  =request
      =stage
      pending=(list stage)
      =progress
      stats=run-stats
      diags=(list diagnostic)
      ::  SPECIFICATION-decomposition warnings (R2.3.5), prepended to whatever
      ::  report the run ends up producing. On the jobstate rather than a kont
      ::  because EVERY terminal path renders a report and they do not share a
      ::  continuation shape -- `+finish-arts` is the one place they all meet
      swarn=(list @t)
      artifacts=(map artifact-name artifact)
      result=(unit result)
      started=@da
      ::  R4.P2: `k` is `[kont-tag kont]`, stored as is (no jam)
      cont=(unit [%1 k=*])
  ==
+$  step-out
  $%  [%more events=(list event) job=jobstate]
      [%stop events=(list event) job=jobstate]
      ::  the job is waiting on external Clay reads (unit 10): the agent
      ::  performs them and resumes the job with +deliver
      [%await events=(list event) reads=(list read-request) job=jobstate]
  ==
::  the source span of the Next action, for typed trace states
+$  next-act  (unit [name=@t at=(unit loc)])
::  a fully loaded source set: what an %inline bundle carries in the
::  request, and what the %modules stage loads for a %clay bundle
+$  srcs
  $:  root=module-name
      modules=(map module-name @t)
      cfg=(unit @t)
      ::  R4.P12: the trees the %clay loader already parsed, by text hash,
      ::  so no later stage parses a module again (`~` for an inline bundle)
      pc=pcache:mod
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
::  what an emission chokepoint returns: the updated job, the events to fan
::  out, and -- if a diagnostic was PROMOTED to an error -- the message the
::  caller must seal the run %failed with (R2.4.5)
+$  demit  [j=jobstate evs=(list event) halt=(unit @t)]
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
      ::  R4.P12: every module parsed so far, by text hash (`+parse-cached`)
      pc=pcache:mod
  ==
::  in-flight pipeline state; versioned by the `kont-tag` in its `cont` wrapper
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
      ::  `aname` is the ROOT ACTION NAME the trace's action attribution falls
      ::  back to -- `Action` under a SPECIFICATION, the NEXT operator's name
      ::  otherwise. Carried since R1.8.3, when a SPECIFICATION first reached
      ::  this path at all
      ::  `al` is the resolved ALIAS body (R2.3.2), what `+finish-bfs` renders
      ::  the report and the typed wire trace through
      $:  %bfs
          nl=@t
          act=next-act
          aname=@t
          o=bfs-opts:check
          cur=bfs-cursor:check
          al=(unit sem:semantic)
          ::  R2.7.7.3: the POSTCONDITION names, carried across the slices so
          ::  `+finish-bfs` can evaluate them after the search -- the config
          ::  itself is not retained
          pcs=(list @t)
          ::  `-view` render body (R2.4.3); ~ unless the flag is set
          vr=(unit sem:semantic)
      ==
      ::  liveness (unit 8.8/8.9): full graph build (%build) then the 8.2–8.6
      ::  tableau/product/SCC/lasso check (%check). Pure []P box-state is a state
      ::  invariant and runs on the safety %bfs path instead (do-config), so no
      ::  first-increment recognizer remains here.
      $:  %live
          phase=?(%build %check)
          oss=(list oos:tp)
          pname=@t
          ::  R2.7.14: the POSTCONDITION names. The comment at the `%inv`
          ::  branch below used to say the liveness path "keeps them on its own
          ::  kont" -- it did not; the `%live` kont had no such field and the
          ::  temporal report evaluated no postcondition at all, which is the
          ::  defect R2.7.14 measured at the pin
          pcs=(list @t)
          ::  R2.7.12: the IMPLIED TEMPORALS, carried so the sliced report can
          ::  do the same POST-HOC ATTRIBUTION the console path does -- which
          ::  property a counter-example violates is decided against the lasso,
          ::  not by taking the first `PROPERTY`. `pname` stays as the fallback
          props=(list [name=@t body=sem:semantic])
          modn=@t
          act=next-act
          ::  the whole-Next label, carried since R2.3.4: an INVARIANT
          ::  violation during the graph build is reported by `+finish-bfs`,
          ::  which renders a safety trace and needs it
          nl=@t
          o=bfs-opts:check
          cur=bfs-cursor:check
          ::  %check-phase product slicing (unit 8.8.2a): the OrderOfSolutions
          ::  still to try, and the current one's bounded product-build cursor
          otodo=(list oos:tp)
          pcur=(unit pcursor:lv)
          ::  what the sliced report needs and used to lack (R1.8.3): the
          ::  SPECIFICATION's name and definition span and its fairness
          ::  conjuncts, for the EC 2257/2259 stuttering hint, plus the ROOT
          ::  ACTION NAME (`Action` under a SPECIFICATION, the NEXT operator's
          ::  name otherwise). Without these the kernel's report differed from
          ::  the console path's on exactly these three things
          sname=(unit @t)
          sloc=sspan:semantic
          fair=(list sem:semantic)
          aname=@t
      ==
      ::  seeded simulation
      $:  %sim
          nl=@t
          act=next-act
          o=sim-opts:check
          cur=sim-cursor:check
          ::  `-difftrace` (R2.4.3): tlc2 honours it in SIMULATION only, so it
          ::  rides on this kont and nowhere else
          df=?
      ==
      ::  depth-first iterative deepening (R2.5). Its own kont because its
      ::  visited set is not the BFS one: each fingerprint carries a status
      ::  word, not a `[depth pred]`. `ngen`/`ndis` are `doInit`'s two numbers,
      ::  which the EC 2208 line needs and the cursor stops being able to
      ::  supply the moment the first sweep runs
      $:  %dfid
          act=next-act
          o=dfid-opts:check
          cur=dfid-cursor:check
          al=(unit sem:semantic)
          vr=(unit sem:semantic)
          ngen=@ud
          ndis=@ud
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
      ::  tlc2's own `-maxSetSize` default (R2.4.1)
      max-set-size=1.000.000
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
::  each slice boundary. R4.P13: 256 MB, since the continuation is no longer
::  jammed per slice (R4.P2, R4.P8) and so bounds only loom growth
++  max-noun-bytes  256.000.000
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
  |=  j=jobstate
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
  |=  js=(map req-id jobstate)
  ^-  @ud
  %+  roll  ~(val by js)
  |=([j=jobstate a=@ud] ?:(?=(^ result.j) a +(a)))
::
++  retained-bytes
  |=  js=(map req-id jobstate)
  ^-  @ud
  %+  roll  ~(val by js)
  |=([j=jobstate a=@ud] (add a (artifact-bytes j)))
::
++  inflight-source
  |=  js=(map req-id jobstate)
  ^-  @ud
  %+  roll  ~(val by js)
  |=([j=jobstate a=@ud] ?:(?=(^ result.j) a (add a (source-charge request.j))))
::
++  quota-reject
  ::  the agent-wide gate a new job must pass on top of +validate. Each bound
  ::  names the resource it protects; nothing is silently queued behind a full
  ::  store
  |=  [js=(map req-id jobstate) q=gquota req=request]
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
  |=  [js=(map req-id jobstate) cap=@ud]
  ^-  (map req-id jobstate)
  ?:  (lte (retained-bytes js) cap)  js
  =/  cands
    ^-  (list [id=req-id j=jobstate])
    %+  sort
      ^-  (list [id=req-id j=jobstate])
      %+  skim  ~(tap by js)
      |=  [id=req-id j=jobstate]
      &(?=(^ result.j) !=(~ artifacts.j))
    |=  [a=[id=req-id j=jobstate] b=[id=req-id j=jobstate]]
    ?:  =(started.j.a started.j.b)  (aor id.a id.b)
    (lth started.j.a started.j.b)
  |-  ^-  (map req-id jobstate)
  ?~  cands  js
  ?:  (lte (retained-bytes js) cap)  js
  =/  dg=diagnostic
    :*  [%lus 403]  %warning  %terminal
        'artifacts reclaimed: the agent-wide retention bound was reached'
        ~  ~
    ==
  =/  jr  j.i.cands
  ::  NOT routed through `+add-diags`: this is agent-side retention reclaim on
  ::  an already-TERMINAL job, not an emission during a run, so there is
  ::  nothing left to abort and tlc2 has no analogue to promote (R2.4.5)
  =.  jr  jr(artifacts ~, diags (snoc diags.jr dg))
  $(js (~(put by js) id.i.cands jr), cands t.cands)
::
++  noun-over
  ::  has a persisted continuation outgrown the in-flight noun bound? The
  ::  measure is its jam size, as before R4.P2, so the bound is unchanged
  |=  [c=(unit [%1 k=*]) cap=@ud]
  ^-  ?
  ?~  c  |
  (gth (met 3 (jam k.u.c)) cap)
::
++  noun-due
  ::  R4.P8: should this slice measure? A jam of the whole continuation is
  ::  O(state space) -- 0.4-0.5 s per slice at 90k states, more than the
  ::  slice's own work -- so a growing search measures only when its count
  ::  (`a` before the slice, `b` after) crosses one of 16 log-spaced
  ::  checkpoints per doubling: below 32 at every change, then about every
  ::  4.4% of growth. The bound is still enforced, at most one checkpoint
  ::  late
  |=  [a=@ud b=@ud]
  ^-  ?
  =/  bucket
    |=  d=@ud
    ^-  [@ud @ud]
    =/  m  (met 0 d)
    [m (rsh [0 (sub m (min m 5))] d)]
  !=((bucket a) (bucket b))
::
::  +|  Continuation Persistence
::
::
::  R4.P2 (H3): a continuation is stored as the noun itself, tagged with a
::  hash of the `kont` TYPE. Jamming it every slice, and `cue`-ing and then
::  CLAMMING it (`;;` over a recursive mold) on the next, cost O(state space)
::  per slice -- measured at 8k states: cue 15 ms, clam 140 ms, jam 16 ms. A
::  matching tag means this build wrote it, so it is loaded through `!<`
::  (one type check, no walk of the value). Anything else -- a kont from
::  another build, or hostile input -- crashes, which every caller already
::  turns into the restart notice; nothing is converted
++  kont-tag  ^~(`@uvH`(sham -:!>(*kont)))
++  save-kont
  |=  k=kont
  ^-  (unit [%1 k=*])
  `[%1 [kont-tag k]]
::
++  load-kont
  |=  c=[%1 k=*]
  ^-  kont
  ?>  ?=(^ k.c)
  ?>  =(kont-tag -.k.c)
  !<(kont [-:!>(*kont) +.k.c])
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
  ::  a write target is validated at SUBMIT, before a job exists, because
  ::  Clay's `%info` is fire-and-forget: it carries no ack gift, so a bad
  ::  target cannot be reported back through the job's result. Everything
  ::  knowable must therefore be known now (R2.2)
  =/  we  (write-err req)
  ?^  we  we
  ?:  ?=(%translate -.op.req)
    `'unsupported: PlusCal translation is not ported yet (unit 8)'
  ::  `analyze-flags.syntax` cannot mean anything here and must not pretend
  ::  to. Parsing is mandatory (every later stage consumes the tree), a parse
  ::  ERROR is fatal (`parse-typed` reports every one as fatal, so it can never
  ::  be suppressed), and a SUCCESSFUL parse emits no diagnostics at all --
  ::  measured, `parse-typed` returns `diags=~`. So `syntax=|` has no possible
  ::  behaviour, and R2.1 refuses it rather than accepting it and doing
  ::  nothing, which is what it did before
  ?:  ?=(%analyze -.op.req)
    ?.  syntax.flags.op.req
      `'unsupported: syntactic analysis cannot be skipped; every later stage consumes the tree'
    (validate-src req)
  ?:  translate.opts.op.req
    `'unsupported: translate-before-check is not ported yet (unit 8)'
  ::  the cfg source override (R2.3.3) -- tlc2's `-config`, which replaces the
  ::  default `<spec>.cfg` with a NAMED file. The port's analogue names one of
  ::  the bundle's own sources to use as the config instead of the bundle's
  ::  `cfg` field. An unknown name is refused HERE, at submit, so nothing
  ::  downstream can silently fall back to the bundle's cfg and check a
  ::  different config than the caller asked for
  ::  `-difftrace` is honoured by tlc2 in SIMULATION only -- measured at the
  ::  pin, an exhaustive run's output is byte-identical with and without it.
  ::  Accepting it on an exhaustive request would be accepting an option that
  ::  does nothing, which R2.1 forbids (R2.4.3)
  ?:  ?&(difftrace.opts.op.req !?=(%simulate -.mode.opts.op.req))
    `'unsupported: -difftrace outside simulation (tlc2 honours it only in -simulate)'
  ::  `-continue` under DFID is a real tlc2 capability (`TLCGlobals.continuation`
  ::  is read in `DFIDModelChecker.doNext` too) that this port has not built:
  ::  the DFID engine stops at its first violation and carries ONE hit.
  ::  Refused by name rather than accepted and ignored (R2.1)
  ?:  ?&(continue.opts.op.req ?=(%dfid -.mode.opts.op.req))
    `'unsupported: -continue with -dfid (the DFID engine records one violation; use exhaustive mode)'
  ::  `-coverage` (R2.7.4.2b) is collected on the EXHAUSTIVE safety search's
  ::  BFS cursor -- `Worker.addElement` / `Tool.isInModel` / `Tool.getInitStates`
  ::  are its three counting sites, and the simulation and DFID engines pass
  ::  through none of them. tlc2 does report coverage under `-simulate` and
  ::  `-dfid`; this port does not, and refuses by name rather than reporting a
  ::  block of zeroes (R2.1)
  ?:  ?&(coverage.opts.op.req !?=(%exhaustive -.mode.opts.op.req))
    `'unsupported: -coverage outside exhaustive mode (the counters live on the safety search)'
  ?:  ?=(%clay -.src.req)
    ::  a %clay bundle selects its config by PATH, not by name: a Clay path
    ::  ends in its mark (`/spec/cfg`, or `/spec-cfg/txt`), so the reference
    ::  needs it and a bare name cannot supply it. The capability is
    ::  present on this bundle, spelled `src.cfg` -- refused, not missing
    ?:  ?=(^ cfg.opts.op.req)
      `'unsupported: cfg source override on a %clay bundle; select the config with src.cfg (a path)'
    ?~  cfg.src.req
      `'a %check request requires a config'
    (validate-src req)
  ?:  ?=(^ cfg.opts.op.req)
    ?.  (~(has by modules.src.req) u.cfg.opts.op.req)
      `(rap 3 ~['unknown cfg source: ' u.cfg.opts.op.req])
    (validate-src req)
  ?~  cfg.src.req
    `'a %check request requires a config'
  (validate-src req)
::
++  write-err
  ::  validate the write target against the request that carries it. An
  ::  %inline bundle declares no search roots, so nothing of its own can be
  ::  written over; a %clay bundle's roots are exactly what the target must
  ::  avoid (+write-ref refuses overlap in either direction)
  |=  req=request
  ^-  (unit @t)
  ?~  write.req  ~
  =/  roots  ?:(?=(%clay -.src.req) roots.src.req ~)
  =/  r  (write-ref:sp desk.u.write.req roots pax.u.write.req)
  ?:(?=(%& -.r) ~ `(err-text:sp p.r))
::
++  validate-src
  ::  what can be checked before any work is scheduled: an inline bundle
  ::  against the size limits, a Clay bundle against its reference shape
  ::  (path canonicalization and escape prevention run inside +validate-clay,
  ::  through lib/source-path, the only constructor of a source-ref)
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
        %dfid      `(list stage)`~[%dfid]
        %exhaustive
      ?:  (has-property req)
        `(list stage)`~[%explore %liveness]
      `(list stage)`~[%explore]
    ==
  ==
::
++  cfg-of
  ::  the EFFECTIVE config text for a source set. `check-opts.cfg` names a
  ::  source in the bundle to use INSTEAD of the bundle's own `cfg` -- tlc2's
  ::  `-config`, which replaces the default `<spec>.cfg` with a named file
  ::  (R2.3.3). `+validate` refuses an unknown name at submit, so a miss here
  ::  cannot mean "silently use the bundle's cfg"; it means the name resolved
  ::  to nothing, which the caller is told about rather than run around
  |=  [req=request s=srcs]
  ^-  (unit @t)
  ?.  ?=(%check -.op.req)  cfg.s
  ?~  cfg.opts.op.req  cfg.s
  (~(get by modules.s) u.cfg.opts.op.req)
::
++  has-property
  ::  does the config name a temporal PROPERTY? (structural cfg parse,
  ::  no graph — the %config stage does full validation later). Reads the
  ::  EFFECTIVE config, so an overridden one plans the same stages it runs
  |=  req=request
  ^-  ?
  ?.  ?=(%inline -.src.req)  |
  =/  ct  (cfg-of req [root.src.req modules.src.req cfg.src.req ~])
  ?~  ct  |
  =/  pr  (parse-cfg:config u.ct)
  ?&(?=(%& -.pr) ?=(^ properties.p.pr))
::
::  +|  Engine
::
::
++  init
  ::  start a job at %starting with its full stage plan pending
  |=  [req=request now=@da]
  ^-  jobstate
  =/  stages  (plan req)
  :*  req  %starting  stages  [0 (lent stages)]
      *run-stats  ~  ~  ~  ~  now  ~
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
    %dfid   `%dfid
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
  |=  [j=jobstate s=(unit srcs)]
  ^-  (unit srcs)
  ?^  s  s
  ?.  ?=(%inline -.src.request.j)  ~
  `[root.src.request.j modules.src.request.j cfg.src.request.j ~]
::
++  parse-typed-cached
  ::  R4.P12: `+parse-typed` answered from the loader's parse cache when it
  ::  holds the text; a cached tree parsed cleanly, so it has no diagnostics
  |=  [text=@t pc=pcache:mod]
  ^-  [tree=(unit node:check) diags=(list diagnostic) fatal=?]
  =/  hit  (~(get by pc) (shax text))
  ?^  hit  [hit ~ |]
  (parse-typed:syntax text)
::
++  carry
  ::  loaded Clay sources travel with the continuation; an inline bundle
  ::  is already in the request and is never copied into it
  |=  [j=jobstate s=(unit srcs)]
  ^-  (unit srcs)
  ?:(?=(%inline -.src.request.j) ~ s)
::
++  time-exceeded
  |=  [j=jobstate now=@da]
  ^-  ?
  ?:  (lte now started.j)  |
  (gth `@dr`(sub now started.j) max-time.limits.request.j)
::
++  step
  ::  spend at most `budget` work units on the job's active stage;
  ::  already-terminal jobs are unchanged
  |=  [j=jobstate budget=@ud now=@da]
  ^-  step-out
  ?^  result.j  [%stop ~ j]
  ?:  (time-exceeded j now)
    (finish j [%limited %time stats.j] ~)
  ::  a continuation jammed by an incompatible engine version (e.g. an older
  ::  BFS-cursor shape) cannot be revived; fail the job with a restart notice
  ::  rather than crash the agent event (a kont from another build is refused, never converted)
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
    (run-safe j k budget ~)
  ::  stage entry
  ?~  pending.j
    (finish j [%failed 'no pending work'] ~)
  =/  s  i.pending.j
  =/  prog=progress  [+(done.progress.j) total.progress.j]
  =/  j
    ^-  jobstate
    j(stage s, pending t.pending.j, progress prog)
  (run-safe j k budget ~[[%stage s] [%progress prog]])
::
++  run-safe
  ::  R4.2y: a crash in a slice seals the job %failed. Uncaught, Gall rolls
  ::  the whole event back, the behn wake that drove it is gone, and the job
  ::  sits `running` forever (three census models, 16 min each)
  |=  [j=jobstate k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-out
  =/  m  (mule |.((run j k budget pre)))
  ?:  ?=(%& -.m)  p.m
  (crash-fail j p.m pre)
::
++  crash-fail
  ::  the crash tags with a tlc2 error behind them become that typed error;
  ::  any other crash is an internal failure naming the stage
  |=  [j=jobstate tan=tang pre=(list event)]
  ^-  step-out
  =/  txt=tape  (zing (turn tan |=(t=tank ~(ram re t))))
  ?^  (find "tlc-live-wrong-formula-format" txt)
    =/  msg=@t  'Temporal formulas containing actions must be of forms <>[]A or []<>A.'
    =/  r  (add-diags j ~[[[%tlc 2.214] %error %liveness msg ~ ~]])
    (finish j.r [%failed msg] (weld pre evs.r))
  =/  top=tape  ?~(tan "" ~(ram re i.tan))
  %^  finish  j
    [%failed (crip "internal: crashed in %{(trip stage.j)}: {top}")]
  pre
::
++  run
  ::  execute one bounded slice of the active stage
  |=  [j=jobstate k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-out
  ?+    stage.j
      ~|([%tla-lus-unplanned-stage stage.j] !!)
    %modules   (do-load j k pre)
    %parse     (do-parse j k budget pre)
    %semantic  (do-semantic j k pre)
    %config    (do-config j k pre)
    %explore   (do-explore j k budget pre)
    %liveness  (do-scan j k budget pre)
    %simulate  (do-sim j k budget pre)
    %dfid      (do-dfid j k budget pre)
    %terminal  (do-terminal j pre)
  ==
::
++  more
  ::  a non-terminal slice; heartbeat progress when nothing else to say
  |=  [j=jobstate evs=(list event)]
  ^-  step-out
  [%more ?~(evs ~[[%progress progress.j]] evs) j]
::
++  await
  ::  pause the job on external Clay reads; the agent performs them and
  ::  resumes it with +deliver. No work is scheduled in the meantime
  |=  [j=jobstate reads=(list read-request) evs=(list event)]
  ^-  step-out
  [%await evs reads j]
::
++  deliver
  ::  absorb the agent's answers into the source-load cursor. Responses
  ::  for tags the cursor is not waiting on are dropped when it drains
  ::  the inbox, so a duplicate or stale delivery changes nothing
  |=  [j=jobstate rs=(list read-response)]
  ^-  jobstate
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
  |=  [j=jobstate tag=@ud]
  ^-  ?
  ?~  cont.j  |
  =/  lr  (mule |.((load-kont u.cont.j)))
  ?.  ?=(%& -.lr)  |
  ?.  ?=(%load -.p.lr)  |
  (~(has by pend.cur.p.lr) tag)
::
++  add-diags
  ::  the single emission chokepoint for a run's diagnostics (R2.4.5).
  ::
  ::  Promotion (`request.promote`, tlc2's `-messagesAsErrors`) has to happen
  ::  HERE and not at the terminal verdict. `MP.printWarning` calls
  ::  `Assert.fail` BEFORE `recorder.record`, so a promoted warning aborts the
  ::  run at the moment it is emitted and never lands as a warning at all --
  ::  it BECOMES the error. Measured mid-run at the pin (EC 2143 promoted):
  ::  2 states generated / 2 distinct / 1 left on queue, against 5/5/0
  ::  unpromoted. Promoting at the end instead would let the run continue past
  ::  the point tlc2 stops and report a completed search where tlc2 reported a
  ::  partial one -- which is exactly the difference a caller filtering
  ::  severities off a finished result cannot reproduce.
  ::
  ::  `halt` is the promoted diagnostic's message; the caller seals %failed.
  ::  Nothing after a promoted diagnostic is emitted, because in tlc2 nothing
  ::  after it runs.
  |=  [j=jobstate ds=(list diagnostic)]
  ^-  demit
  ?~  ds  [j ~ ~]
  ?.  (promoted j i.ds)
    =.  diags.j  (snoc diags.j i.ds)
    =/  r  $(ds t.ds)
    [j.r [[%diagnostic i.ds] evs.r] halt.r]
  =/  dg  i.ds(severity %error)
  =.  diags.j  (snoc diags.j dg)
  [j ~[[%diagnostic dg]] `message.dg]
::
++  promoted
  ::  is this diagnostic promoted to an error by the request's set? Only a
  ::  WARNING can be, and that is tlc2's rule rather than a port choice:
  ::  `isTlcMessageAsError` is consulted in `MP.printWarning` and nowhere
  ::  else, so an error or an info code in the set is inert there too --
  ::  measured, `-messagesAsErrors 2110` (an error) leaves a run byte-identical
  |=  [j=jobstate dg=diagnostic]
  ^-  ?
  ?.  =(%warning severity.dg)  |
  (~(has in promote.request.j) code.dg)
::
++  finish
  ::  seal the job; a sealed job is never resumed
  |=  [j=jobstate res=result pre=(list event)]
  ^-  step-out
  =.  result.j   `res
  =.  stage.j    %terminal
  =.  pending.j  ~
  =.  cont.j     ~
  [%stop (snoc pre [%result res]) j]
::
++  cancel
  |=  j=jobstate
  ^-  jobstate
  j(result `[%cancelled ~], stage %terminal, pending ~, cont ~)
::
++  project
  ::  the public job view: results and progress, never internal cursors
  |=  j=jobstate
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
      pc=~
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
      ::  R4.1a: SANY's order is the SPEC directory (the first root), then
      ::  the StandardModules, then the library roots (`SimpleFilenameToStream`
      ::  over CI's classpath; measured in R4.0a). So a standard name missing
      ::  from the spec directory is the vendored module, and never a library
      ::  root's copy (tlapm's `FiniteSets`/`Bags`, CommunityModules' `Json`)
      ?:  ?&  (~(has by standard-modules:stdmods) name.u.p)
              =(try.u.p (slag 1 roots.c))
          ==
        =.  have.c  (~(put in have.c) name.u.p)
        $
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
      ::  last, a block in the root file itself (R4.1c, `tlc-monolith`):
      ::  delivered back to this loop as if it had been read, so it is
      ::  registered, size-checked and parsed exactly as a file is
      =/  rtxt  (~(get by mods.c) root.c)
      =/  mono=(unit @t)
        ?~(rtxt ~ (monolith-module:mod u.rtxt name.u.p))
      ?~  mono
        [c (flop reads) `[%fail (missing-msg name.u.p from.u.p)]]
      =/  tag  next.c
      =.  next.c  +(next.c)
      =/  at=path  (~(gut by refs.c) root.c /)
      =.  pend.c  (~(put by pend.c) tag [%module name.u.p from.u.p at ~])
      =.  inbox.c  [[tag [%& u.mono]] inbox.c]
      $
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
    =/  pr  (mule |.((parse-cached:mod txt pc.c)))
    ?.  ?&(?=(%& -.pr) ?=(%& -.res.p.pr))  $
    =.  pc.c  cache.p.pr
    =/  tree  p.res.p.pr
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
  |=  [j=jobstate ps=provs]
  ^-  demit
  =/  txt  (render-sources ps)
  ?:  (gth (met 3 txt) max-artifact.limits.request.j)
    =/  dg=diagnostic
      :*  [%lus 402]  %warning  %modules
          'source provenance omitted: it exceeds max-artifact'
          ~  ~
      ==
    (add-diags j ~[dg])
  [j(artifacts (~(put by artifacts.j) %sources [%text txt])) ~ ~]
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
  |=  [req=request s=srcs]
  ^-  provs
  :+  root.s
    %+  turn  (sort ~(tap in ~(key by modules.s)) aor)
    |=  nm=module-name
    ^-  [module-name prov]
    [nm [%inline nm] (shax (~(gut by modules.s) nm ''))]
  ::  under a cfg source override the config's bytes are the NAMED source's,
  ::  so record THAT id -- provenance must name what was read as the config,
  ::  not the bundle `cfg` the override displaced (R2.3.3)
  =/  nm  ?:(?=(%check -.op.req) cfg.opts.op.req ~)
  ?^  nm
    `[[%inline u.nm] (shax (~(gut by modules.s) u.nm ''))]
  ?~  cfg.s  ~
  `[[%inline ''] (shax u.cfg.s)]
::
++  close-load
  ::  the module graph is closed: record what was read, then hand the
  ::  sources to %parse exactly as an inline bundle would
  |=  [j=jobstate ps=provs s=srcs pre=(list event)]
  ^-  step-out
  =/  po  (put-sources j ps)
  ?^  halt.po  (finish j.po [%failed u.halt.po] (weld pre evs.po))
  =/  jp  j.po
  =.  cont.jp  (save-kont [%src s])
  (more jp (weld pre evs.po))
::
++  load-fail
  ::  a resolution failure is a typed diagnostic at the %modules stage,
  ::  carrying the text the inline resolver reports for the same condition
  |=  [j=jobstate msg=@t pre=(list event)]
  ^-  step-out
  =/  dg=diagnostic  [[%lus 401] %error %modules msg ~ ~]
  =/  r  (add-diags j ~[dg])
  (finish j.r [%failed msg] (weld pre evs.r))
::
++  do-load
  ::  close the module graph over asynchronous reads. No stage may touch
  ::  Clay: this one names the files it needs and pauses (%await), and
  ::  the sources it hands to %parse are exactly what an inline bundle of
  ::  the same files would hand it
  |=  [j=jobstate k=(unit kont) pre=(list event)]
  ^-  step-out
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
  (close-load j (clay-provs c) [root.c mods.c cfg.c pc.c] pre)
::
::  +|  Stage: %parse
::
::
++  do-parse
  ::  %check parses the root module into a %tree hand-off; %analyze
  ::  parses every bundle module, one work unit each, collecting
  ::  diagnostics for %terminal's verdict
  |=  [j=jobstate k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-out
  =/  so  (srcs-of j (k-srcs k))
  ?~  so
    (finish j [%failed 'internal: %parse without loaded sources'] pre)
  =/  src  u.so
  =/  cry  (carry j so)
  ::  an inline bundle's provenance is recorded here, where a Clay run
  ::  recorded its own at the close of the load
  =/  po=demit
    ?:  |(?=(%clay -.src.request.j) (~(has by artifacts.j) %sources))
      [j ~ ~]
    (put-sources j (inline-provs request.j src))
  ?^  halt.po  (finish j.po [%failed u.halt.po] (weld pre evs.po))
  =.  j    j.po
  =.  pre  (weld pre evs.po)
  ?:  ?=(%check -.op.request.j)
    =/  text  (~(get by modules.src) root.src)
    ?~  text
      (finish j [%failed 'root module not in bundle'] pre)
    =/  pr  (mule |.((parse-typed-cached u.text pc.src)))
    ?:  ?=(%| -.pr)
      (finish j [%failed 'parse error: parser crashed'] pre)
    =/  pt  p.pr
    ?:  |(fatal.pt ?=(~ tree.pt))
      ::  SANY's exact parse-error text travels as the diagnostics
      =/  r  (add-diags j diags.pt)
      %^  finish  j.r
        :-  %failed
        ?^  halt.r  u.halt.r
        ?~(diags.pt 'parse error' message.i.diags.pt)
      (weld pre evs.r)
    =.  cont.j  (save-kont [%tree u.tree.pt cry])
    (more j pre)
  ::  %analyze
  =/  kk=kont
    ?:  ?&(?=(^ k) ?=(%parse -.u.k))  u.k
    [%parse (sort ~(tap in ~(key by modules.src)) aor) cry]
  ?>  ?=(%parse -.kk)
  =/  evs  pre
  =/  spent  0
  |-  ^-  step-out
  ?~  todo.kk
    ::  Clay sources travel on to the %semantic stage
    =.  cont.j  ?~(cry ~ (save-kont [%src u.cry]))
    (more j evs)
  ?:  (gte spent budget)
    =.  cont.j  (save-kont kk)
    (more j evs)
  =/  nm  i.todo.kk
  =/  ds=(list diagnostic)
    =/  pr  (mule |.((parse-typed-cached (~(got by modules.src) nm) pc.src)))
    ?:  ?=(%| -.pr)
      [[%lus 400] %error %parse (rap 3 ~['parser crashed in ' nm]) ~ ~]~
    diags.p.pr
  ?~  ds
    $(todo.kk t.todo.kk, spent +(spent))
  =/  r  (add-diags j ds)
  ?^  halt.r  (finish j.r [%failed u.halt.r] (weld evs evs.r))
  ::  copy the DIAGS leg rather than the whole jobstate: `op.request.j` is
  ::  narrowed by the `?=(%check ...)` guard above, so a `%=` on `j` itself
  ::  nest-fails against the unnarrowed one `+add-diags` returns. `+add-diags`
  ::  touches no other leg, so this is the same assignment
  =.  diags.j  diags.j.r
  %=  $
    todo.kk  t.todo.kk
    spent    +(spent)
    evs      (weld evs evs.r)
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
  |=  [j=jobstate k=(unit kont) pre=(list event)]
  ^-  step-out
  ?>  ?=(%analyze -.op.request.j)
  =/  so  (srcs-of j (k-srcs k))
  ?~  so
    (finish j [%failed 'internal: %semantic without loaded sources'] pre)
  =/  src    u.so
  =/  flags  flags.op.request.j
  =/  ag  (analyze-graph-with:semantic root.src modules.src pc.src)
  ?~  ag
    ::  resolution failed. If the parse stage already reported errors,
    ::  they drive the terminal verdict; otherwise surface a resolution
    ::  diagnostic (a missing EXTENDS/INSTANCE target parses per module
    ::  but fails the dependency graph)
    ?:  %+  lien  diags.j
        |=(d=diagnostic &(=(%error severity.d) ?=(?(%parse %modules) stage.d)))
      (more j pre)
    ::  R4.2j: name the failure in SANY's words, as the %clay loader does
    ::  (`+missing-msg`, `+mismatch-msg`); only a cycle or an unparsable
    ::  module keeps the generic text, the parse stage having reported
    ::  the latter already
    =/  why=@t
      =/  rr  (resolve:mod root.src (inline-resolver:mod modules.src) pc.src)
      ?.  ?=(%| -.out.rr)  'module resolution failed'
      =/  e  p.out.rr
      ?+  -.e  'module resolution failed'
        %missing   (missing-msg what.e in.e)
        %mismatch  (mismatch-msg file.e module.e)
      ==
    =/  d=diagnostic  [[%lus 401] %error %modules why ~ ~]
    =/  r  (add-diags j ~[d])
    (more j.r (weld pre evs.r))
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
  ::  the lint and level stages are where WARNINGS actually appear, so this is
  ::  the site a promotion set is most likely to fire at (R2.4.5)
  =/  r  (add-diags j ds)
  ?^  halt.r  (finish j.r [%failed u.halt.r] (weld pre evs.r))
  (more j.r (weld pre evs.r))
::
::  +|  Stage: %config
::
::
++  config-fail
  ::  a config diagnostic (CFG_* 5001-5006 or TLC_CONFIG_* 2222-2281) is
  ::  a typed TLC failure: record the structured diagnostic and seal the
  ::  job %failed with its message (never a silent %ok)
  |=  [j=jobstate d=cfg-vdiag:config pre=(list event)]
  ^-  step-out
  =/  dg=diagnostic  [[%tlc code.d] %error %config msg.d ~ ~]
  =/  r  (add-diags j ~[dg])
  (finish j.r [%failed msg.d] (weld pre evs.r))
::
++  assume-fail
  ::  a non-boolean ASSUME (EC 2105) is a typed TLC failure at the
  ::  model-checking stage, recorded like a config diagnostic. A FALSE one
  ::  (EC 2104) is a VERDICT: tlc2 exits 10, CI calls it `assumption
  ::  failure`, and the wire has `[%assumption name]` for exactly this -- it
  ::  had never been produced (R4.2j). Its name is the assumption's location
  |=  [j=jobstate ae=[ec=@ud msg=@t at=@t] pre=(list event)]
  ^-  step-out
  =/  dg=diagnostic  [[%tlc ec.ae] %error %explore msg.ae ~ ~]
  =/  r  (add-diags j ~[dg])
  ?.  =(2.104 ec.ae)
    (finish j.r [%failed msg.ae] (weld pre evs.r))
  (finish j.r [%violated [%assumption at.ae] *run-stats] (weld pre evs.r))
::
++  do-config
  ::  consume the parsed root tree and build the engine continuation.
  ::  Every config this engine cannot process faithfully is a typed
  ::  failure naming the key or form; nothing is silently ignored.
  |=  [j=jobstate k=(unit kont) pre=(list event)]
  ^-  step-out
  ?.  ?&(?=(^ k) ?=(%tree -.u.k))
    (finish j [%failed 'internal: %config without a parsed tree'] pre)
  =/  tree  t.u.k
  ::  R2.7.3: the same spec-processing rejection the console path applies --
  ::  a decimal anywhere in the module aborts before any state is computed
  =/  dec  (first-decimal:check tree)
  ?^  dec  (finish j [%failed (decimal-error:check u.dec)] pre)
  ?>  ?=(%check -.op.request.j)
  =/  so  (srcs-of j (k-srcs k))
  ?~  so
    (finish j [%failed 'internal: %config without loaded sources'] pre)
  =/  src   u.so
  =/  cfo   (cfg-of request.j src)
  ?~  cfo
    (finish j [%failed 'a %check request requires a config'] pre)
  =/  cfg   u.cfo
  =/  mode  mode.opts.op.request.j
  =/  lims  limits.request.j
  ::  real config pipeline (unit 5): parse -> validate against the WU3
  ::  graph -> assemble the typed run-spec. One bounded slice (graph
  ::  generation, like a capped run-check); a config diagnostic is a
  ::  typed TLC failure, not a silent %ok.
  ::  the semantic graph is generated once and reused by the config
  ::  assembly and the checker (it used to be built twice, reparsing
  ::  every module both times)
  =/  mo  (generate-with:semantic root.src modules.src pc.src)
  ?~  mo  (config-fail j [0 'internal: module generation failed'] pre)
  =/  rso  (run-spec-with:config u.mo cfg)
  ?:  ?=(%| -.rso)  (config-fail j p.rso pre)
  =/  rs  p.rso
  ::  R2.7.7.1: refuse a parsed-but-unacted `.cfg` keyword BY NAME, before the
  ::  run starts. `run-spec` does not carry these four fields, so the check
  ::  takes the parsed AST directly -- and it is a `config-fail` with code 0,
  ::  the port-local code, because the pin SUPPORTS these keywords and has no
  ::  EC for refusing them
  =/  pca  (parse-cfg:config cfg)
  =/  ukw  ?:(?=(%| -.pca) ~ (unsupported-kw:config p.pca))
  ?^  ukw  (config-fail j [0 u.ukw] pre)
  ::  all invariants are checked in declaration order (7.3); `iv` is the first
  ::  one, still used for the INVARIANT/PROPERTY-conflict guard and definition
  ::  existence checks below
  =/  iv=(unit @t)  ?~(invariants.rs ~ `i.invariants.rs)
  =/  pp=(unit @t)  ?~(properties.rs ~ `i.properties.rs)
  ::  INIT/NEXT mode keeps its own name-level diagnostics; both modes then
  ::  resolve through the SAME +resolve-targets the console path uses, so a
  ::  SPECIFICATION decomposes here exactly as it does there (R1.8.3 --
  ::  this branch used to be a flat typed rejection)
  ?:  ?&(?=(%init-next -.mode.rs) ?=(~ init.mode.rs))
    (finish j [%failed 'no INIT in config'] pre)
  ?:  ?&(?=(%init-next -.mode.rs) ?=(~ next.mode.rs))
    (finish j [%failed 'no NEXT in config'] pre)
  ?:  ?=(%init-next -.mode.rs)
    =/  in  init.mode.rs
    =/  nx  next.mode.rs
    ?~  in  (finish j [%failed 'no INIT in config'] pre)
    ?~  nx  (finish j [%failed 'no NEXT in config'] pre)
    ::  R4.2l: resolved through the semantic graph, which holds what EXTENDS
    ::  imports; the root's syntax tree alone refused every MC-style model
    ::  whose Init/Next live in the module it extends
    =/  dm  (defmap-of:ne u.mo)
    ?.  (~(has by dm) u.in)
      (finish j [%failed (rap 3 ~['no definition for INIT ' u.in])] pre)
    ?.  (~(has by dm) u.nx)
      (finish j [%failed (rap 3 ~['no definition for NEXT ' u.nx])] pre)
    (config-run j tree src rs iv pp u.mo pre)
  (config-run j tree src rs iv pp u.mo pre)
::
++  def-node
  ::  the syntax node of definition `nm` and the module that holds it: the
  ::  root's own, else the module the semantic graph says defines it (an
  ::  EXTENDS import), parsed from the bundle (R4.2l)
  |=  [tree=node:check modn=@t defs=(map @t sem-def:semantic) src=srcs nm=@t]
  ^-  (unit [nod=node:check mod=@t])
  =/  own  (body-of-def:check tree nm)
  ?^  own  `[u.own modn]
  =/  d  (~(get by defs) nm)
  ?~  d  ~
  =/  text  (~(get by modules.src) origin.u.d)
  ?~  text  ~
  =/  pr  (mule |.((parse-typed-cached u.text pc.src)))
  ?:  ?=(%| -.pr)  ~
  ?~  tree.p.pr  ~
  =/  b  (body-of-def:check u.tree.p.pr nm)
  ?~  b  ~
  `[u.b origin.u.d]
::
++  config-run
  ::  the mode-independent half of +do-config: everything from the resolved
  ::  Init/Next bodies down to the engine continuation. Both INIT/NEXT and
  ::  SPECIFICATION reach it, which is what makes a SPECIFICATION run in the
  ::  job kernel at all (R1.8.3)
  |=  $:  j=jobstate
          tree=node:check
          src=srcs
          rs=run-spec:config
          iv=(unit @t)
          pp=(unit @t)
          mo=sem-module:semantic
          pre=(list event)
      ==
  ^-  step-out
  ?>  ?=(%check -.op.request.j)
  =/  mode  mode.opts.op.request.j
  =/  lims  limits.request.j
  ::  VIEW and ALIAS are parsed, validated (2229/2233/2228, R1.8.6) and carried
  ::  in the run-spec, but NO engine path applies them: a VIEW changes what TLC
  ::  fingerprints, so ignoring one would silently report more distinct states
  ::  than tlc2 and could even change termination. Refuse instead of degrading
  ::  -- the release doctrine for every unsupported option (R1.8.6)
  ::  VIEW is live as of R2.3.1 — resolved below and carried on `bfs-opts` —
  ::  except alongside a temporal PROPERTY, where the liveness module
  ::  recomputes plain state fingerprints that a view-keyed graph would not
  ::  match. Narrowed, not ignored (see check.hoon's matching guard)
  ::  ALIAS is live as of R2.3.2 — resolved below and carried on the `%bfs`
  ::  kont, which is what `+finish-bfs` renders the report and the typed wire
  ::  trace from. Refused on the two paths whose trace renderers take no alias
  ::  (simulation and the genuine temporal lasso), each at its own branch below
  ::  rather than here, because a `[]P` box-state PROPERTY runs on the SAFETY
  ::  path and does render the alias — a `?=(^ pp)` guard here would over-refuse
  ?:  &(?=(^ view.rs) ?=(^ pp))
    %^  finish  j
      [%failed 'unsupported: VIEW with a temporal PROPERTY (the liveness graph is not view-keyed; unit 8)']
    pre
  ::  R4.2l: the VARIABLEs of the whole EXTENDS closure, from the semantic
  ::  graph (the root's own first, in declaration order, then the imported
  ::  ones); the root tree alone dropped an extended module's variables
  =/  order  (turn vars.mo head)
  =/  vars   (silt order)
  =/  modn  (module-name-of:check tree)
  =/  defs    (defmap-of:ne mo)
  ::  R2.7.7.4b: `_POSSIBLE`'s predicates with their levels, resolved the same
  ::  way the console resolves them
  =/  poss
    %+  murn  possible.rs
    |=  nm=@t
    ^-  (unit [@t sem:semantic @ud])
    =/  d  (~(get by defs) nm)
    ?~  d  ~
    ?~  body.u.d  ~
    `[nm u.body.u.d lvl.u.d]

  ::  the VIEW body, resolved like any other config target (R2.3.1)
  =/  vwb=(unit sem:semantic)  ?~(view.rs ~ (sem-body:check defs u.view.rs))
  ::  the ALIAS body, resolved like any other config target (R2.3.2)
  =/  alb=(unit sem:semantic)  ?~(alias.rs ~ (sem-body:check defs u.alias.rs))
  ::  `-view` (R2.4.3) renders through the VIEW body. With the flag set but no
  ::  VIEW in the config there is nothing to render, so it is refused rather
  ::  than silently ignored
  ?:  ?&(view.opts.op.request.j ?=(~ vwb))
    %^  finish  j
      [%failed 'unsupported: -view without a VIEW in the config (nothing to render)']
    pre
  =/  vrb=(unit sem:semantic)  ?:(view.opts.op.request.j vwb ~)
  ::  R2.7.14b: `-postCondition mod!op` appends to the config's POSTCONDITION
  ::  list, in the order given, exactly as tlc2 appends both to one
  ::  `POST_CONDITIONS`. A module half naming somewhere other than where the
  ::  operator lives is refused at CONFIG time -- honouring it would run the
  ::  root module's operator instead, which is accepting an option and doing
  ::  something else
  =/  xpc  (cli-postconditions:check postconditions.opts.op.request.j defs)
  ?:  ?=(%| -.xpc)  (finish j [%failed p.xpc] pre)
  =/  pcs=(list @t)  (weld postconditions.rs p.xpc)
  ?:  ?&(?=(^ iv) !(~(has by defs) u.iv))
    %^  finish  j
      [%failed (rap 3 ~['no definition for INVARIANT ' u.iv])]
    pre
  ::  the SAME resolver the console path uses: INIT/NEXT keys or a
  ::  SPECIFICATION decomposition (init conjuncts, the [A]_v action, the
  ::  WF_/SF_/[]temporal fairness conjuncts)
  =/  tg
    ?-  -.mode.rs
      %init-next  [init.mode.rs next.mode.rs `(unit @t)`~]
      %spec       [`(unit @t)`~ `(unit @t)`~ `name.mode.rs]
    ==
  ::  `order` goes in so the SPECIFICATION decomposition can raise the EC 2145
  ::  subscript-coverage warning here too (R2.3.5) -- the kernel's report is
  ::  compared to the console's, so a warning on one path must appear on both
  =/  rt  (resolve-targets:check tg defs order)
  ?:  ?=(%| -.rt)  (finish j [%failed p.rt] pre)
  =.  swarn.j  warn.p.rt
  =/  isb=sem:semantic  init.p.rt
  =/  nsb=sem:semantic  next.p.rt
  =/  fair  fair.p.rt
  =/  nname  nname.p.rt
  ::  ROOT ACTION NAME: `Action` when the relation came from a SPECIFICATION
  ::  (tlc2 builds that action with a null opDef, so Action.getLocation prints
  ::  the generic "Action"), else the NEXT operator's name
  =/  aname=@t  ?~(nname 'Action' u.nname)
  =/  sname=(unit @t)  ?:(?=(%spec -.mode.rs) `name.mode.rs ~)
  =/  sloc=sspan:semantic
    ?~  sname  ~
    =/  d  (~(get by defs) u.sname)
    ?~(d ~ at.u.d)
  ::  the NEXT body's syntax node and the module that holds it, so the
  ::  action label names an imported Next's own module (R4.2l)
  =/  nd=(unit [nod=node:check mod=@t])
    ?~(nname ~ (def-node tree modn defs src u.nname))
  =/  nl  ?~(nd '' (next-span-label:check aname nod.u.nd mod.u.nd))
  =/  act=next-act
    ?~  nd  ~
    =/  sp  (span-of:ast nod.u.nd)
    `[?~(nname '' u.nname) ?~(sp ~ `[mod.u.nd u.sp])]
  ::  safety, liveness, and simulation all run on the Work Unit 3 SEMANTIC
  ::  graph via node-eval (unit 9.2 retired simulation's CST solver).
  =/  consts  (consts-of:check constants.rs)
  ::  TLC checks module assumptions before the search (Tool.checkAssumptions);
  ::  a false or non-boolean ASSUME is a typed TLC failure, never a silent skip
  =/  ae  (check-assumes:check assumes.mo (make-env:ne defs consts vars) modn)
  ?^  ae  (assume-fail j u.ae pre)
  ::  R2.7.5: SYMMETRY with a temporal PROPERTY WARNS AND CONTINUES (EC 2279),
  ::  matching tlc2 and the console path. Unit 8.7.2's engine blocker was
  ::  re-measured and is stale -- see `+search-ctx-seed`'s note. The warning
  ::  rides `swarn`, the channel R2.3.5's EC 2145 warning already uses
  ::  FIRST in the list, matching the console path's `(weld symwarn warn)` --
  ::  tlc2 prints it before the search, ahead of any decomposition warning
  ::  a `[]P` box-state PROPERTY is folded into the invariants and never
  ::  reaches the liveness checker, so it draws no warning -- same test the
  ::  console path uses (`+search-ctx-seed`'s `genuine-temporal`)
  =/  genuine-temporal
    ?.  ?=(^ pp)  |
    =/  psb  (sem-body:check defs u.pp)
    ?.  ?=(^ psb)  |
    ?=(~ (box-state-inner:tp u.psb))
  =?  swarn.j  &(?=(^ symmetry.rs) genuine-temporal)
    :_  swarn.j
    %^    cat  3
        'Warning: Declaring symmetry during liveness checking is dangerous. '
      %^  cat  3
        'It might cause TLC to miss violations of the stated liveness properties. '
      'Please check liveness without symmetry defined.'
  =/  pr  (symmetry-perms:check defs consts vars symmetry.rs)
  ?:  ?=(%| -.pr)  (finish j [%failed p.pr] pre)
  =/  perms  p.pr
  =/  invs   (resolve-invs:check defs invariants.rs)
  ::  R2.7.15a: EVERY declared PROPERTY binned on its own shape
  ::  (`SpecProcessor.processConfigProps`), so the kernel routes the whole list
  ::  rather than testing the head. The box-state ones join the INVARIANT
  ::  vector AFTER the config's own -- `processConfigInvariants()` fills it
  ::  first (R2.3.4) -- and the implied actions ride the search
  =/  bins   (bin-properties:check properties.rs defs)
  =/  iacts  iacts.bins
  =/  cons   (resolve-bodies:check defs constraints.rs)
  =/  acons  (resolve-bodies:check defs action-constraints.rs)
  ::  R2.7.4.2b: the carrier-keeping variant, for the INIT coverage counts --
  ::  `irej` is the candidates the initial predicate rejected once they were
  ::  already fully assigned, which is the `secondary` half of the INIT line
  ::  R2.7.4.4: `RandomEnumerableValues.setSeed(seed)` runs for EVERY run mode,
  ::  and the INITIAL-state solve draws from that seed alone -- off a worker
  ::  `IdThread.getCurrentState()` is null, so `TLCStateRandom` never reseeds
  ::  and the whole init phase runs from `new Random(randomSeed)`. `%dfid`
  ::  carries no seed on this wire, so it runs from the 0 default
  =/  eseed=@ud
    ?-  -.mode
      %exhaustive  seed.mode
      %simulate    seed.mode
      %dfid        0
    ==
  =/  rs0=rst:ne  empty-rst:ne
  =/  isc
    %^  init-states-rs:ne  isb  (make-env:ne defs consts vars)
    rs0(es (scramble:rng eseed))
  =/  isr  -.isc
  ?:  ?=(%| -.isr)  (finish j [%failed msg.p.isr] pre)
  =/  is  p.isr
  ::  R2.7.4.2b: everything the coverage block needs and the search does not
  ::  otherwise carry. `irej` is the R2.7.4.1a carrier's INIT rejection count
  =/  cvo=cov-opts:check
    :*  coverage.opts.op.request.j  modn
        ?:(?=(%init-next -.mode.rs) ?~(init.mode.rs '' u.init.mode.rs) '')
        [(lent is) irej.+.isc]
        (resolve-names:check defs constraints.rs)
        (resolve-names:check defs action-constraints.rs)
    ==
  ::  seeded simulation (unit 9.2): SimulationWorker over the semantic graph,
  ::  drawing with java.util.Random (lib/rng) so a run reproduces `tlc2.TLC
  ::  -simulate -workers 1`. A temporal PROPERTY is checked per behavior on its
  ::  stutter graph (unit 9.3a, LiveCheck.checkTrace via the 8.2–8.6 engine).
  ::  DFID (R2.5): a SECOND search engine, not a mode of the BFS. Its PROPERTY
  ::  routing is `+dfid-setup`'s -- box-state onto the invariant vector, a
  ::  level-1 predicate as an implied init, `[][A]_v` as an implied action, and
  ::  a genuine temporal one REFUSED, which is `DFIDModelChecker`'s own rule
  ?:  ?=(%dfid -.mode)
    =/  psb  ?~(pp ~ (sem-body:check defs u.pp))
    ?:  ?&(?=(^ pp) ?=(~ psb))
      (finish j [%failed (rap 3 ~['no definition for PROPERTY ' u.pp])] pre)
    =/  su
      %-  dfid-opts-of:check
      :*  (get-actions:check nsb aname defs (make-env:ne defs consts vars))
          invs  cons  acons  vars  order  defs  consts
          properties.rs  ?&(deadlock.mode deadlock.rs)
          max-set-size.lims  depth.mode
      ==
    ?:  ?=(%| -.su)  (finish j [%failed p.su] pre)
    ::  the planned %liveness stage never runs under DFID: either the property
    ::  routed to a safety check above, or `+dfid-opts-of` refused
    =?  j  (lien pending.j |=(s=stage =(%liveness s)))
      %=  j
        pending   (skip pending.j |=(s=stage =(%liveness s)))
        progress  [done.progress.j (dec total.progress.j)]
      ==
    =/  o   o.p.su
    =/  ci  (dfid-cursor-init:check o is (dfid-env:check o))
    ?^  err.ci  (finish j [%failed u.err.ci] pre)
    ::  the EC 2255 state-level warning prints BEFORE the verdict, which is
    ::  what `swarn` is for (R2.3.5's EC 2145 uses the same channel)
    =.  swarn.j  (weld swarn.j warn.p.su)
    =.  cont.j
      %-  save-kont
      :*  %dfid  act  o  cur.ci  alb  vrb
          (lent is)  ~(wyt by fps.cur.ci)
      ==
    (more j pre)
  ?:  ?=(%simulate -.mode)
    ::  `+trace-states` renders the simulated behavior with no alias, and
    ::  tlc2 does apply one there (`SimulationWorker.java:163`), so an ALIAS
    ::  here would print a wrong trace. Refused, narrowly (R2.3.2)
    ?^  alias.rs
      %^  finish  j
        [%failed 'unsupported: ALIAS in simulation mode (the simulated trace is not aliased; unit 9)']
      pre
    =/  dep
      ?:(=(0 max-depth.lims) depth.mode (min depth.mode max-depth.lims))
    =/  actions  (get-actions:check nsb aname defs (make-env:ne defs consts vars))
    ::  normalize the PROPERTY (if any) into the OrderOfSolution form; an
    ::  unsupported property is a typed rejection, never a silent %ok
    =/  osr=(each (list oos:tp) aerr:tp)
      ?~  pp  [%& ~]
      =/  psb  (sem-body:check defs u.pp)
      ?~  psb  [%| [0 (rap 3 ~['no definition for PROPERTY ' u.pp])]]
      (oss-of:check ~[u.psb] modn ~ (make-env:ne defs consts vars))
    ?:  ?=(%| -.osr)  (finish j [%failed msg.p.osr] pre)
    =/  o=sim-opts:check
      ::  the effective deadlock flag. The exhaustive mode ANDs a request-side
      ::  toggle with the cfg's (`?&(deadlock.mode deadlock.rs)`, TLC's
      ::  `deadlock && getCheckDeadlock()`), but `[%simulate ...]` carries no
      ::  such toggle on this wire -- only `[%exhaustive deadlock=?]` does --
      ::  so here the cfg's CHECK_DEADLOCK is the whole story.
      :*  actions  invs  cons  acons  deadlock.rs
          p.osr  ?~(pp '' u.pp)
          defs  consts  vars  order  num.mode  dep  generate.mode
      ==
    ::  `-difftrace` rides on the SIM kont, the only path tlc2 honours it on
    =.  cont.j
      (save-kont [%sim nl act o (sim-cursor-init:check is seed.mode) difftrace.opts.op.request.j])
    (more j pre)
  ::  R2.7.15c: the IMPLIED INITS, which this kernel used to compute and drop.
  ::  tlc2 checks a level<=1 PROPERTY only while computing the INITIAL STATES
  ::  (`Tool.getImpliedInits`), so it cannot join the invariant vector -- an
  ::  invariant is checked at every state, and folding would report violations
  ::  at states tlc2 never tests. The EC 2255 state-level warning is emitted
  ::  for EVERY one, in config order, whether or not it holds, and it rides
  ::  `swarn` because it prints BEFORE the verdict (the DFID branch above
  ::  already does this, through `+dfid-opts-of`'s `warn`)
  ::
  ::  This sits AFTER the %dfid and %simulate branches on purpose: DFID checks
  ::  its own implied inits state-major in `+dfid-cursor-init`, so reaching it
  ::  from here would check them twice
  =.  swarn.j
    (weld swarn.j (turn iinits.bins |=([n=@t *] (state-level-warn:check n))))
  =/  ib=(unit (each [kind=?(%inv %prop) name=@t st=state:check] @t))
    ?~  iinits.bins  ~
    %-  first-bad-init:check
    [is invs iinits.bins (make-env:ne defs consts vars)]
  ::  an `%inv` answer is left to the search: it reaches the same initial state
  ::  and reports EC 2107 with the counters it actually accumulated. An
  ::  evaluation error (`%|`) is likewise the search's own typed failure
  ?:  ?=([~ %& %prop *] ib)
    =/  env   (make-env:ne defs consts vars)
    =/  acts  (get-actions:check nsb aname defs env)
    =/  mn    ?~(act '' ?~(at.u.act '' src.u.at.u.act))
    ::  no state-graph statistics: the run aborts during initial-state
    ::  computation and tlc2 prints none, which is what the console shows too
    %:  finish-arts
      j
      [%violated [%property name.p.u.ib &] *run-stats]
      %-  wain-text
      %:  init-viol-lines:check
        p.u.ib  order  alb  vrb  env
      ==
      `[%safety (trace-states ~[st.p.u.ib] act acts env order mn alb) ~]
      pre
    ==
  ::  R2.7.15a: routed over EVERY property by `+bin-properties`, not on the
  ::  head of the list. The box-state ones ride the safety search's INVARIANT
  ::  vector and the implied actions ride it as a per-transition check (both
  ::  wired below, where the opts are built); the LIVENESS stage is planned
  ::  only when a genuine temporal property was declared.
  ?^  temps.bins
    ::  the lasso trace is rendered by the %liveness stage, which takes no
    ::  alias, and tlc2 does alias it (`LiveWorker.java:876-972`). Refused
    ::  narrowly, matching the console path's guard (R2.3.2)
    ?^  alias.rs
      %^  finish  j
        [%failed 'unsupported: ALIAS with a temporal PROPERTY (the lasso trace is not aliased; unit 8)']
      pre
    ::  a genuine temporal property runs the 8.2-8.6 engine in the %liveness
    ::  stage; a %clay run could not know it needs that stage until its config
    ::  is read, so the plan grows here, honestly, with its total
    =?  j  !(lien pending.j |=(s=stage =(%liveness s)))
      %=  j
        pending   (snoc pending.j %liveness)
        progress  [done.progress.j +(total.progress.j)]
      ==
    ::  R2.7.15a: normalize EVERY temporal property, not just the head --
    ::  `+oss-of` has always taken a list and the caller passed a singleton
    =/  osr
      %:  oss-of:check
        (turn temps.bins |=([* b=sem:semantic] b))
        modn  fair  (make-env:ne defs consts vars)
      ==
    ?:  ?=(%| -.osr)  (finish j [%failed msg.p.osr] pre)
    ::  R2.3.4: the temporal graph build carries the config's INVARIANTs, so an
    ::  INVARIANT alongside a PROPERTY is CHECKED rather than refused. R2.7.15a
    ::  adds the box-state properties and the implied actions to the same
    ::  build, so a spec declaring both kinds gets both checked in ONE run
    ::  R4.P7: the console path's graph (`check.hoon` +search-ctx users):
    ::  the CONSTRAINTs, action constraints and SYMMETRY group, and the
    ::  safety path's deadlock flag (`deadlock && getCheckDeadlock()`). All
    ::  four were off here, so a deadlocking spec reported its PROPERTY
    ::  violated where tlc2 stops at `Deadlock reached`
    =/  o=bfs-opts:check
      :*  nsb  (weld invs binvs.bins)  cons  acons  ~  vars  order  perms
          defs  consts
          ?&(deadlock.mode deadlock.rs)
          max-states.lims  max-depth.lims  vwb  max-set-size.lims  |  ~
          *cov-opts:check  0  iacts
          ::  R4.P5c: a temporal graph keeps FP64 (lasso choice reads map order)
          |
      ==
    =.  cont.j
      %-  save-kont
      :*  %live  %build  p.osr  ?~(pp '' u.pp)  pcs
          temps.bins
          modn  act  nl
          o  (bfs-init:check is)  ~  ~
          sname  sloc  fair  aname
      ==
    (more j pre)
  ::  no temporal property: a safety run, and the box-state properties are part
  ::  of it. Drop the planned (never-run) %liveness stage from the plan
  =?  j  (lien pending.j |=(s=stage =(%liveness s)))
    %=  j
      pending   (skip pending.j |=(s=stage =(%liveness s)))
      progress  [done.progress.j (dec total.progress.j)]
    ==

  ::  safety search: all invariants (ordered), state/action constraints, and
  ::  the effective deadlock flag (CLI flag AND the cfg CHECK_DEADLOCK flag,
  ::  matching TLC's `deadlock && getCheckDeadlock()`)
  ::  the getActions decomposition is built ONCE here and carried on the opts
  ::  (R2.7.4.2b): `+finish-bfs` needs the same list for the trace labels, and
  ::  passing it in removes the per-slice rebuild R2.7.4.2a's timing measured
  =/  acts  (get-actions:check nsb aname defs (make-env:ne defs consts vars))
  =/  o=bfs-opts:check
    :*  nsb  (weld invs binvs.bins)  cons  acons  poss  vars  order  perms  defs  consts
        ?&(deadlock.mode deadlock.rs)  max-states.lims  max-depth.lims
        vwb  max-set-size.lims  continue.opts.op.request.j  acts  cvo
        ::  R2.7.4.4: tlc2's `-seed`, which seeds `RandomEnumerableValues` for
        ::  BFS as well as simulation. `mode` is already narrowed to
        ::  `%exhaustive` here -- the dfid and simulate branches returned above
        seed.mode
        ::  R2.7.15a: the IMPLIED ACTIONS, checked on every transition
        iacts
        ::  R4.P5c: the identity key, unless the spec can draw
        !(draws:check defs)
    ==
  ::  R2.7.4.3: the cursor inherits the register store the initial-state solve
  ::  wrote, so an `Init` conjunct's `TLCSet` is visible to the first `Next`
  =.  cont.j
    (save-kont [%bfs nl act aname o (bfs-init-regs:check is +.isc) alb pcs vrb])
  (more j pre)
::
::  +|  Stage: %explore
::
::
++  do-explore
  |=  [j=jobstate k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-out
  ?:  ?&(?=(^ k) ?=(%bfs -.u.k))
    =/  kk  u.k
    =/  r  (bfs-step:check o.kk cur.kk budget)
    ?:  ?=(%more -.r)
      =/  d0  distinct.stats.j
      ::  live statistics at the slice boundary (deterministic, resumable): the
      ::  public view reflects search progress, not just the final report
      =.  stats.j
        :*  gen.cur.r  distinct.cur.r  len.queue.cur.r  depth.cur.r
            (od-stats:check outdeg.cur.r)
        ==
      =.  cont.j  (save-kont kk(cur cur.r))
      ::  bound the persisted noun: a search whose cursor outgrows the limit is
      ::  stopped %limited with the limiting resource, never carried unbounded
      ?:  ?&  (noun-due d0 distinct.cur.r)
              (noun-over cont.j max-noun-bytes)
          ==
        (finish j [%limited %noun stats.j] pre)
      (more j pre)
    %:  finish-bfs
      j  out.r  (od-stats:check outdeg.cur.r)  o.kk  cur.r
      nl.kk  act.kk  aname.kk  al.kk  vr.kk  pcs.kk  pre
    ==
  ?:  ?&(?=(^ k) ?=(%live -.u.k) =(%build phase.u.k))
    =/  kk  u.k
    =/  r  (bfs-step:check o.kk cur.kk budget)
    ?:  ?=(%more -.r)
      ::  partial statistics at the slice boundary (as in do-explore), so a
      ::  max-time interruption of the graph build reports progress (9.5)
      =.  stats.j
        :*  gen.cur.r  distinct.cur.r  len.queue.cur.r  depth.cur.r
            (od-stats:check outdeg.cur.r)
        ==
      =.  cont.j  (save-kont kk(cur cur.r))
      (more j pre)
    ?:  ?=(%limited -.out.r)
      =/  st=run-stats  [gen.out.r distinct.out.r 0 depth.out.r (od-stats:check outdeg.cur.r)]
      =.  stats.j  st
      (finish j [%limited what.out.r st] pre)
    ::  R2.3.4: with INVARIANTs carried here, `%inv` is now reachable and is a
    ::  real verdict -- the safety violation pre-empts the temporal check, as
    ::  `ModelChecker.doNext` returning pre-empts tlc2's. `+finish-bfs` renders
    ::  it exactly as the plain safety path does. ALIAS is refused alongside a
    ::  temporal PROPERTY (R2.3.2), so `~` is the whole story for the alias
    ::  R4.P7: and so does every other end of the search -- a deadlock, an
    ::  implied-action violation, an evaluation error -- exactly as
    ::  `ModelChecker.doNext` aborts the run before the final liveness check.
    ::  Only `%inv` reached here before; the rest reported "unexpected graph
    ::  outcome" (10 census models, R4.2q)
    ?.  ?=(%ok -.out.r)
      %:  finish-bfs
        j  out.r  (od-stats:check outdeg.cur.r)  o.kk  cur.r
        ::  the %live kont carries no postcondition names: the liveness path
        ::  keeps them on its own kont, and this branch is the search outcome
        ::  that pre-empts it (R2.3.4)
        nl.kk  act.kk  aname.kk  ~  ~  ~  pre
      ==
    =/  st=run-stats  [gen.out.r distinct.out.r 0 depth.out.r (od-stats:check outdeg.cur.r)]
    =.  stats.j  st
    ::  the graph is built; hand off to the 8.2–8.6 %check phase (unit 8.8)
    =.  cont.j  (save-kont kk(phase %check, cur cur.r, otodo oss.kk, pcur ~))
    (more j pre)
  (finish j [%failed 'internal: %explore without a search continuation'] pre)
::
++  finish-bfs
  ::  seal a safety search: wire result, stats, report + trace artifacts
  |=  $:  j=jobstate  out=outcome:check  od=out-degree  o=bfs-opts:check
          ::  the final cursor, which carries the coverage counters
          ::  (R2.7.4.2b); everything else reads `out`
          cur=bfs-cursor:check
          nl=@t  act=next-act  aname=@t  al=(unit sem:semantic)
          vr=(unit sem:semantic)
          ::  R2.7.7.3: the POSTCONDITION names, from the kont
          pcs=(list @t)
          pre=(list event)
      ==
  ^-  step-out
  ?:  ?=(%error -.out)  (finish j [%failed msg.out] pre)
  =/  st=run-stats
    ?-  -.out
      %ok        [gen.out distinct.out queued.out depth.out od]
      %limited   [gen.out distinct.out queued.out depth.out od]
      %inv       [gen.out distinct.out queued.out depth.out od]
      %action    [gen.out distinct.out queued.out depth.out od]
      %deadlock  [gen.out distinct.out queued.out depth.out od]
    ==
  =.  stats.j  st
  =/  res=result
    ?-  -.out
      %ok        [%ok st]
      %limited   [%limited what.out st]
      %inv       [%violated [%invariant name.out initial.out] st]
      ::  R2.7.15a: EC 2112, the wire variant R2.7.13 added
      %action    [%violated [%action name.out] st]
      %deadlock  [%violated [%deadlock ~] st]
    ==
  ::  per-action attribution for the wire trace: the getActions leaves plus the
  ::  evaluation env they are re-solved against (R1.5.12b). The report artifact
  ::  keeps the whole-Next label it has always rendered.
  =/  env   (make-env:ne defs.o consts.o vars.o)
  ::  R2.7.4.2b: `+do-config` built this list once and put it on the opts, so
  ::  the trace labels and the coverage counters index the SAME decomposition
  =/  acts  ?^(acts.o acts.o (get-actions:check next.o aname defs.o env))
  =/  modn  ?~(act '' ?~(at.u.act '' src.u.at.u.act))
  ::  the ALIAS reaches BOTH artifacts (R2.3.2): the report through
  ::  `+render-outcome` and the typed trace through `+trace-states`. `env` is
  ::  passed where `*eenv:ne` used to be because evaluating the alias needs it;
  ::  it changes nothing else, since `actions` stays `~` and the only other
  ::  reader of `e` is the per-action label that `~` disables
  =/  report
    %-  wain-text
    ::  R2.7.7.3: the kernel evaluates the postconditions on the same terms as
    ::  the console -- after the search, with the run's final statistics, and
    ::  in the same slot. The NAMES ride on the kont (`pcs`) because the config
    ::  is long gone by the time this renders
    ::  (no `%error` guard: `out` is already narrowed here, and the test
    ::  mint-vains)
    =/  pst  (out-stats:check out)
    =/  pcl=wain
      %:  post-cond-lines:check
        pcs
        defs.o
        %+  with-run:ne  env
        [| 0 `[depth.pst distinct.pst queued.pst gen.pst]]
        modn
        rs.cur
        poss.o
      ==
    %:  render-outcome:check
      out  nl  ~  env  ~  ''  al  vr  |
      (cov-report:check o cur acts)  ~  pcl
    ==
  =/  tr=(unit trace)
    ?+  -.out  ~
      %inv       `[%safety (trace-states trace.out act acts env order.o modn al) ~]
      %action    `[%safety (trace-states trace.out act acts env order.o modn al) ~]
      %deadlock  `[%safety (trace-states trace.out act acts env order.o modn al) ~]
    ==
  ::  `-continue` (R2.4.2): a completed run that passed violations carries them
  ::  all. They go to their OWN artifact rather than into `result` -- `result`
  ::  and `violation` are R2.7.1's to reshape, and that is the unit meant to
  ::  reshape `violation` (R2.7.1 has since done so, splitting EC 2107/2110
  ::  with an `initial` flag; `api-version` stayed 1 -- see sur/tla-lus)
  =.  j
    ?.  ?&(?=(%ok -.out) ?=(^ viols.out))  j
    ::  EXPLICIT loop, and the element face is NOT called `trace`: a wet `turn`
    ::  over the recursive `state` mold fuse-loops zuse-408, and a face named
    ::  `trace` shadows the MOLD of that name, which `-find.$`s the cast
    =/  vs=(list [=violation =trace])
      ::  WIDENED: the `?=(^ viols.out)` guard above narrows the list, which
      ::  makes this loop's `?~` branch `mint-vain` (the zuse-408 narrowing
      ::  trap the dev notes record for wet gates)
      =/  ws=(list [name=@t trace=(list state:check)])  viols.out
      =|  acc=(list [=violation =trace])
      |-  ^-  (list [=violation =trace])
      ?~  ws  (flop acc)
      =/  one=[=violation =trace]
        ::  `-continue` records only BEHAVIOR violations: an initial-state
        ::  one returns from `doInit` before the search starts (R2.7.1)
        :-  [%invariant name.i.ws %.n]
        [%safety (trace-states trace.i.ws act acts env order.o modn al) ~]
      $(ws t.ws, acc [one acc])
    j(artifacts (~(put by artifacts.j) %violations [%violations vs]))
  (finish-arts j res report tr pre)
::
::  +|  Stage: %liveness
::
::
++  do-scan
  |=  [j=jobstate k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-out
  ?.  ?&(?=(^ k) ?=(%live -.u.k) =(%check phase.u.k))
    (finish j [%failed 'internal: %liveness without a check continuation'] pre)
  =/  kk  u.k
  ::  the 8.2–8.6 temporal check on the built graph (unit 8.8.2a): try each
  ::  OrderOfSolution in turn, slicing the product build a budget at a time; on
  ::  the first violated one render tlc2.TLC's console diagnostic + typed result.
  =/  st      stats.j
  =/  states  (states-of:check seen.cur.kk)
  =/  env     (make-env:ne defs.o.kk consts.o.kk vars.o.kk)
  ::  R2.7.14a/b: the POSTCONDITION lines, in tlc2's slot (between the EC
  ::  2257/2259 hint and the counts). The run's FINAL carrier and statistics,
  ::  for the same reason R2.7.7.4a threaded them on the safety path -- a
  ::  postcondition typically reads `TLCGet("distinct")`.
  ::
  ::  A gate rather than a value, because `TLCExt!CounterExample` binds to the
  ::  LASSO and the lasso is not known until the product search finishes: the
  ::  pass branch calls it with `~`, the violation branch with the counter-
  ::  example it just built. The console path does the same inside
  ::  `+live-report`, and `test-kernel-report-equals-console-*` is what keeps
  ::  the two honest
  =/  pcl-of
    |=  cev=(unit value:check)
    ^-  wain
    %:  post-cond-lines:check
      pcs.kk
      defs.o.kk
      %-  ?~(cev same |=(x=eenv:ne (with-ce:ne x u.cev)))
      %+  with-run:ne  env
      [| 0 `[depth.st distinct.st queued.st generated.st]]
      modn.kk
      rs.cur.kk
      poss.o.kk
    ==
  ::  no OrderOfSolution left to try → no temporal violation
  ?~  otodo.kk
    =/  report
      %-  wain-text
      %-  live-render:check
      ::  a pass renders only `Model checking completed.` + counts, so the gate
      ::  is empty by construction; `aname` is carried anyway so the two call
      ::  sites cannot drift (R1.8.3)
      :*  ~  states  next.o.kk  env  order.o.kk  modn.kk  defs.o.kk  pname.kk
          props.kk
          generated.st  distinct.st  depth.st  ~  aname.kk  |  (pcl-of ~)
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
      (labeled-product:lv o states (flop inits.cur.kk) next.o.kk env order.o.kk)
    =/  pc  ?~(pcur.kk (product-init:lv o states (flop inits.cur.kk) env) u.pcur.kk)
    =/  r   (product-step:lv o states next.o.kk env order.o.kk pc budget)
    ?.  done.r  [%more cur.r]
    [%done (lasso-of-product:lv o [nodes.cur.r edges.cur.r inits.cur.r])]
  ?:  ?=(%more -.res)
    ::  bound the persisted product cursor, like the safety search, as its
    ::  product node count grows
    =/  n0  ?~(pcur.kk 0 ~(wyt by nodes.u.pcur.kk))
    =.  cont.j  (save-kont kk(pcur `cur.res))
    ?:  ?&  (noun-due n0 ~(wyt by nodes.cur.res))
            (noun-over cont.j max-noun-bytes)
        ==
      (finish j [%limited %noun st] pre)
    (more j pre)
  =/  l  lasso.res
  ?~  l
    ::  this OOS has no accepting lasso → try the next one, fresh cursor
    =.  cont.j  (save-kont kk(otodo t.otodo.kk, pcur ~))
    (more j pre)
  =/  report
    %-  wain-text
    %-  live-render:check
    ::  R1.8.3: the continuation now carries the SPEC name/span, the fairness
    ::  conjuncts and the root action name, so the sliced report is the console
    ::  path's. The gate is tested against the OOS BEING REPORTED (`~[o]`), not
    ::  the whole list -- tlc2 tests `this.oos`, so a spec whose first violated
    ::  property has empty PEMs prints no hint even when a later one would
    :*  l  states  next.o.kk  env  order.o.kk  modn.kk  defs.o.kk  pname.kk
        props.kk
        generated.st  distinct.st  depth.st
        (stutter-gate:check ~[o] sname.kk sloc.kk fair.kk modn.kk)
        aname.kk
        ::  R2.7.5: same OOS, same test as the console path
        (box-free-tf:check ~[o])
        ::  R2.7.14b: the counter-example as a VALUE, `loop` 0 when the report
        ::  carries no closer -- the LiveCheck call site, which appends no
        ::  closing edge
        %-  pcl-of
        :-  ~
        %:  counter-example-value:check
          (turn prefix.u.l |=(fp=@t (~(got by states) fp)))
          order.o.kk
          (get-actions:check next.o.kk aname.kk defs.o.kk env)
          env
          modn.kk
          ?:((box-free-tf:check ~[o]) 0 loop.u.l)
        ==
    ==
  =/  tr-states=(list state:check)
    (turn prefix.u.l |=(fp=@t (~(got by states) fp)))
  =/  typed=trace  [%lasso (trace-states tr-states act.kk ~ *eenv:ne ~ '' ~) `loop.u.l]
  ::  R2.7.12: the TYPED result names the same property the report does. The
  ::  wire carries ONE name where the console can now print several, so it
  ::  takes the first attributed one; `pname` remains the fallback
  =/  vps  (violated-props:check props.kk u.l states env modn.kk)
  =/  vnm  ?~(vps pname.kk i.vps)
  (finish-arts j [%violated [%property vnm %.n] st] report `typed pre)
::
::  +|  Stage: %simulate
::
::
++  do-sim
  |=  [j=jobstate k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-out
  ?.  ?&(?=(^ k) ?=(%sim -.u.k))
    (finish j [%failed 'internal: %simulate without a continuation'] pre)
  =/  kk  u.k
  =/  r  (sim-step:check o.kk cur.kk budget)
  ?:  ?=(%more -.r)
    ::  commit partial statistics at the slice boundary so an interruption
    ::  (max-time / noun bound) reports the run so far, not empty stats (9.5)
    =.  stats.j  [gen.cur.r 0 0 maxn.cur.r [0 0 0 0]]
    =.  cont.j  (save-kont kk(cur cur.r))
    (more j pre)
  ::  states-generated / behaviors / trace-length in TLC's simulation stat slots
  ::  (generated = states generated; depth = deepest transition reached)
  ::  simulation samples no state-graph out-degree (no BFS frontier)
  =/  st=run-stats  [gen.res.r 0 0 maxn.cur.r [0 0 0 0]]
  =.  stats.j  st
  =/  head
    %-  crip
    ;:  weld
      "Simulation completed: "
      (a-tape:check traces.res.r)
      " behaviors, "
      (a-tape:check steps.res.r)
      " transitions, "
      (a-tape:check gen.res.r)
      " states generated (trace length: mean="
      (a-tape:check mean.res.r)
      ", var="
      (a-tape:check var.res.r)
      ", sd="
      (a-tape:check sd.res.r)
      ")."
    ==
  ::  a `-generate` engine REFUSAL ends the run with no verdict, as tlc2 aborts
  ::  on the shapes `Tool.probabilistic` does not implement (R2.4.6). It is a
  ::  typed failure rather than an `%ok` with empty statistics: tlc2 performs no
  ::  model checking at all in that case, and a caller must not read the partial
  ::  counts as a completed run
  ?^  err.res.r
    (finish j [%failed u.err.res.r] pre)
  ?~  viol.res.r
    (finish-arts j [%ok st] head ~ pre)
  =/  vk     kind.u.viol.res.r
  =/  vname  name.u.viol.res.r
  =/  vpath  path.u.viol.res.r
  =/  headline=@t
    ?-  vk
      %invariant  (crip "Error: Invariant {(trip vname)} is violated.")
      %property   (crip "Error: Temporal property {(trip vname)} is violated.")
      %deadlock   'Error: Deadlock reached.'
    ==
  =/  report
    %-  wain-text
    ;:  weld
      ~[headline]
      ~['Error: The behavior up to this point is:']
      (render-trace:check vpath nl.kk ~ *eenv:ne ~ '' ~ ~ df.kk)
      ~[head]
    ==
  =/  typed=trace  [%simulate (trace-states vpath act.kk ~ *eenv:ne ~ '' ~) ~]
  =/  vn
    ?-  vk
      ::  simulation reports what a BEHAVIOR violated; it has no
      ::  initial-predicate phase of its own (R2.7.1)
      %invariant  [%invariant vname %.n]
      %property   [%property vname %.n]
      %deadlock   [%deadlock ~]
    ==
  (finish-arts j [%violated vn st] report `typed pre)
::
::  +|  Stage: %dfid
::
::
++  do-dfid
  ::  depth-first iterative deepening (R2.5). Sliced like every other engine;
  ::  every count is independent of how the run is sliced
  |=  [j=jobstate k=(unit kont) budget=@ud pre=(list event)]
  ^-  step-out
  ?.  ?&(?=(^ k) ?=(%dfid -.u.k))
    (finish j [%failed 'internal: %dfid without a continuation'] pre)
  =/  kk  u.k
  ::  an initial-state violation is found by `+dfid-cursor-init`, before any
  ::  sweep: the cursor arrives already stopped and there is nothing to step
  ?:  stop.cur.kk
    (finish-dfid j (dfid-verdict:check cur.kk %ok) kk pre)
  =/  r  (dfid-step:check o.kk cur.kk budget)
  ?:  ?=(%more -.r)
    ::  live statistics at the slice boundary. DFID reports no queue, no graph
    ::  depth and no out-degree -- its summary line carries two numbers -- so
    ::  those slots stay zero rather than holding something tlc2 never produced
    =/  d0  distinct.stats.j
    =.  stats.j  [gen.cur.r ~(wyt by fps.cur.r) 0 0 [0 0 0 0]]
    =.  cont.j   (save-kont kk(cur cur.r))
    ?:  ?&  (noun-due d0 distinct.stats.j)
            (noun-over cont.j max-noun-bytes)
        ==
      (finish j [%limited %noun stats.j] pre)
    (more j pre)
  (finish-dfid j out.r kk pre)
::
++  finish-dfid
  ::  seal a DFID search: wire result, stats, report + trace artifacts
  |=  [j=jobstate out=dfid-out:check kk=kont pre=(list event)]
  ^-  step-out
  ?>  ?=(%dfid -.kk)
  ?:  ?=(%error -.out)  (finish j [%failed msg.out] pre)
  =/  gd  (dfid-gen-dis out)
  =/  st=run-stats  [gen.gd dis.gd 0 0 [0 0 0 0]]
  =.  stats.j  st
  =/  res=result
    ?-  -.out
      %ok        [%ok st]
      ::  the bound was reached and tlc2 printed no completion line, so this is
      ::  NOT %ok: the search did not finish
      %limited   [%limited %depth st]
      %inv       [%violated [%invariant name.out initial.out] st]
      ::  an implied INIT can only fail on an initial state, by construction
      %prop      [%violated [%property name.out %.y] st]
      ::  R2.7.13: an implied ACTION violation is tlc2's EC 2112 and now has
      ::  its own wire variant. It used to be `[%property name %.n]`, which
      ::  ALSO carries EC 2116 (a temporal property violated by a behavior),
      ::  so the two were indistinguishable on the wire. DFID is the only
      ::  engine that reaches this: `+check`'s console path renders the
      ::  diagnostic without a typed result, and neither `+run-check` nor the
      ::  job kernel routes an implied action at all (`tlc-safety-assume`)
      %action    [%violated [%action name.out] st]
      %deadlock  [%violated [%deadlock ~] st]
    ==
  =/  env  (make-env:ne defs.o.kk consts.o.kk vars.o.kk)
  =/  report
    %-  wain-text
    %:  render-dfid-outcome:check
      out  order.o.kk  env  al.kk  vr.kk  ngen.kk  ndis.kk
    ==
  ::  the wire trace carries NO action attribution, because the DFID printers
  ::  carry none: `printInvariantTrace` prints the ordinal and nothing else
  ::  where the BFS trace names the getActions leaf. Passing `~` for both the
  ::  leaves and the fallback label is what makes every state's `action` ~
  =/  tr=(unit trace)
    ?+  -.out  ~
        ?(%inv %action %deadlock)
      `[%safety (trace-states (dfid-trace-of out) ~ ~ env order.o.kk '' al.kk) ~]
    ==
  (finish-arts j res report tr pre)
::
++  dfid-gen-dis
  ::  an outcome's two counts. Every arm but %error has them, at differing
  ::  axes, so a bare `gen.out` over the union forks
  |=  out=dfid-out:check
  ^-  [gen=@ud dis=@ud]
  ?-  -.out
    %error     [0 0]
    %ok        [gen.out distinct.out]
    %limited   [gen.out distinct.out]
    %inv       [gen.out distinct.out]
    %prop      [gen.out distinct.out]
    %action    [gen.out distinct.out]
    %deadlock  [gen.out distinct.out]
  ==
::
++  dfid-trace-of
  ::  the counterexample an outcome carries, ~ when it carries none
  |=  out=dfid-out:check
  ^-  (list state:check)
  ?+  -.out  ~
    %inv       trace.out
    %prop      trace.out
    %action    trace.out
    %deadlock  trace.out
  ==
::
::  +|  Stage: %terminal
::
::
++  do-terminal
  ::  %analyze verdict: fail iff any error-severity diagnostic was
  ::  recorded by a parse, semantic, or level stage (lint warnings do
  ::  not fail the run unless a lint-option elevated one to %error,
  ::  which flips its severity here)
  |=  [j=jobstate pre=(list event)]
  ^-  step-out
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
  |=  [j=jobstate res=result report=@t tr=(unit trace) pre=(list event)]
  ^-  step-out
  ::  R2.3.5: the decomposition's warnings lead the report, as they lead tlc2's
  ::  console output -- they are emitted while the config is processed, before
  ::  any run line. Counted against `max-artifact` like the rest of it
  =/  report=@t
    ?~  swarn.j  report
    (rap 3 (join '\0a' (snoc swarn.j report)))
  ?:  (gth (met 3 report) max-artifact.limits.request.j)
    (finish j [%limited %artifact stats.j] pre)
  =.  artifacts.j  (~(put by artifacts.j) %report [%text report])
  =.  artifacts.j
    ?~  tr  artifacts.j
    (~(put by artifacts.j) %trace [%trace u.tr])
  (finish j res pre)
::
++  trace-states
  ::  wire-typed trace states: 1-indexed, initial state has no action. Each
  ::  later state names the getActions leaf that GENERATED it (R1.5.12b) --
  ::  the same per-action attribution the console trace renders; `act` (the
  ::  whole-Next label) is the fallback when no leaf matches or no action
  ::  context is available.
  |=  $:  sts=(list state:check)  act=next-act
          acts=(list act:check)
          e=eenv:ne  order=(list @t)  modn=@t
          al=(unit sem:semantic)
      ==
  ^-  (list trace-state)
  =/  i  1
  =/  prev=(unit state:check)  ~
  |-  ^-  (list trace-state)
  ?~  sts  ~
  =/  a=next-act
    ?:  =(1 i)  ~
    ?~  prev  act
    ?:  ?=(~ acts)  act
    =/  hit
      ::  R2.6.1: the same re-solve as `+render-trace`, and it needs the same
      ::  thing -- a trace position IS its level, so the predecessor's level is
      ::  `i - 1`; without it a spec reading `TLCGet("level")` matches no
      ::  action and every wire trace state loses its attribution
      %:  edge-action:check
        u.prev  (@t (state-fp:fp order i.sts))  acts
        (with-run:ne e [| (dec i) ~])  order  modn
      ==
    ?~(hit act hit)
  ::  ALIAS (R2.3.2): the record BECOMES the state, its successor is the next
  ::  trace state, and the LAST state pairs with ITSELF -- the same pairing
  ::  `+render-trace` uses, so report and wire trace never disagree
  =/  shown=[order=(list @t) st=state:check]
    ?~  al  [order i.sts]
    (alias-state:check u.al e i.sts ?~(t.sts i.sts i.t.sts))
  :_  $(sts t.sts, i +(i), prev `i.sts)
  [i a (state-pairs:check order.shown st.shown)]
::
++  wain-text
  |=  w=wain
  ^-  @t
  (rap 3 (join '\0a' w))
--
