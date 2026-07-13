/-  *tla-lus
/=  check  /lib/tla/check
|%
  ::  Resumable Job Engine
  ::
  ::  Pure, resumable driver for the translator/SANY/TLC pipeline. One
  ::  +step call enters exactly one stage, so a single Gall event never
  ::  does unbounded work, and the emitted event stream is a pure function
  ::  of the job noun: pause/resume cannot change the output.
  ::
  ::  Unit 13 wires the real model checker (lib/tla/check) into the
  ::  %explore/%simulate stages for inline `%check` requests, bounded by
  ::  the request's max-states; the remaining stages and the PlusCal
  ::  translation path are still deterministic stand-ins.
  ::
  ::  Usage:
  ::    =/  j  (init req)
  ::    (step j)  ::  [%more events=[[%stage %parse] [%progress 1 13]] j]
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
::  deterministic per-slice stub work during exploration/simulation
++  explore-gen   25
++  explore-dis   20
++  explore-dep   3
++  simulate-gen  10
::
::  +|  Validation
::
::
++  validate
  ::  Typed-boundary request checks; ~ means acceptable
  ::
  ::  Clay bundles are size-checked at resolve time (unit 13), when the
  ::  content is first read.
  |=  req=request
  ^-  (unit @t)
  ?:  ?=(%clay -.src.req)  ~
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
  ::  Ordered stages for an operation; one bounded step each
  |=  =op
  ^-  (list stage)
  ?-    -.op
      %translate
    ~[%translate %terminal]
  ::
      %analyze
    %-  zing
    ^-  (list (list stage))
    :~  ~[%parse]
        ?:(semantic.flags.op ~[%modules %semantic] ~)
        ?:(level.flags.op ~[%level] ~)
        ?:(lint.flags.op ~[%lint] ~)
        ~[%terminal]
    ==
  ::
      %check
    %-  zing
    ^-  (list (list stage))
    :~  ?:(translate.opts.op ~[%translate] ~)
        ~[%parse %modules %semantic %level %config %init]
        ?-  -.mode.opts.op
          %exhaustive  ~[%explore %explore %explore %explore %liveness]
          %simulate    ~[%simulate %simulate]
        ==
        ~[%terminal]
    ==
  ==
::
::  +|  Engine
::
::
++  init
  ::  Start a job at %starting with its full stage plan pending
  |=  req=request
  ^-  job
  =/  stages  (plan op.req)
  :*  req
      %starting
      stages
      [0 (lent stages)]
      *run-stats
      ~
      ~
      ~
  ==
::
++  step
  ::  Enter the next pending stage; already-terminal jobs are unchanged
  ::
  ::  ?^/?~ narrow the tested wings, so the advanced job is rebuilt
  ::  wholesale rather than mutated in place.
  |=  =job
  ^-  step-result
  ?^  result.job  [%stop ~ job]
  ?~  pending.job
    =/  res=result  [%failed 'no pending work']
    =/  j
      ^-  ^job
      :*  request.job  %terminal  ~  progress.job
          stats.job  diags.job  artifacts.job  `res
      ==
    [%stop [%result res]~ j]
  =/  s  i.pending.job
  ::  shadow the narrowed sample with a wide-typed advanced job
  =/  job
    ^-  ^job
    :*  request.job  s  t.pending.job
        [+(done.progress.job) total.progress.job]
        stats.job  diags.job  artifacts.job  ~
    ==
  ?+    s
    [%more ~[[%stage s] [%progress progress.job]] job]
  ::
      %semantic
    =/  d=diagnostic
      [[%lus 100] %info %semantic 'stub semantic analysis' ~ ~]
    =.  diags.job  (snoc diags.job d)
    :+  %more
      ~[[%stage s] [%diagnostic d] [%progress progress.job]]
    job
  ::
      %explore
    ::  run the real bounded model check for inline sources, then finish;
    ::  fall back to the deterministic stub when the source is not inline
    =/  sc  (inline-spec-cfg job)
    ?~  sc
      =.  stats.job
        :*  (add generated.stats.job explore-gen)
            (add distinct.stats.job explore-dis)
            0
            (add depth.stats.job explore-dep)
        ==
      ?:  (gth generated.stats.job max-states.limits.request.job)
        (finish job(pending ~) [%limited %states stats.job] ~[[%stage s]])
      ?:  (gth depth.stats.job max-depth.limits.request.job)
        (finish job(pending ~) [%limited %depth stats.job] ~[[%stage s]])
      [%more ~[[%stage s] [%progress progress.job]] job]
    =/  rr  (run-check:check spec.u.sc cfg.u.sc max-states.limits.request.job)
    =/  res=result  -.rr
    =.  stats.job  +.rr
    =.  artifacts.job
      (~(put by artifacts.job) %report [%text (real-report res +.rr)])
    (finish job(pending ~) res ~[[%stage s] [%progress progress.job]])
  ::
      %simulate
    =.  stats.job
      :*  (add generated.stats.job simulate-gen)
          (add distinct.stats.job simulate-gen)
          0
          8
      ==
    [%more ~[[%stage s] [%progress progress.job]] job]
  ::
      %terminal
    =/  arts  (stub-artifacts job)
    =/  too-big
      %+  lien  arts
      |=  [* art=artifact]
      ?.  ?=(%text -.art)  |
      (gth (met 3 text.art) max-artifact.limits.request.job)
    ?:  too-big
      (finish job [%limited %artifact stats.job] ~[[%stage s]])
    =.  artifacts.job  (~(gas by artifacts.job) arts)
    (finish job [%ok stats.job] ~[[%stage s] [%progress progress.job]])
  ==
::
++  finish
  ::  Seal a job with its terminal result
  |=  [=job res=result pre=(list event)]
  ^-  step-result
  =.  result.job  `res
  =.  stage.job   %terminal
  [%stop (snoc pre [%result res]) job]
::
::  +|  Stub Outputs
::
::
++  wants-translation
  |=  =op
  ^-  ?
  ?-  -.op
    %translate  &
    %analyze    |
    %check      translate.opts.op
  ==
::
++  stub-artifacts
  |=  =job
  ^-  (list [artifact-name artifact])
  =/  =op  op.request.job
  %-  zing
  ^-  (list (list [artifact-name artifact]))
  :~  [[%report [%text (report-text job)]] ~]
    ::
      ?.  (wants-translation op)  ~
      [[%translation [%text stub-translation]] ~]
    ::
      ?.  ?&(?=(%translate -.op) gen-cfg.opts.op)  ~
      [[%cfg [%text stub-cfg]] ~]
  ==
::
++  inline-spec-cfg
  ::  the root module's source text and config for an inline %check
  ::  request that carries a config; ~ when the source is not inline or
  ::  has no config (those fall back to the deterministic placeholder)
  |=  =job
  ^-  (unit [spec=@t cfg=@t])
  =/  src  src.request.job
  ?.  ?=(%inline -.src)  ~
  ?~  cfg.src  ~
  =/  spec  (~(get by modules.src) root.src)
  ?~  spec  ~
  `[u.spec u.cfg.src]
::
++  real-report
  ::  a human-readable summary line for a real model-check result
  |=  [res=result stats=run-stats]
  ^-  @t
  =/  counts
    "generated {<generated.stats>} distinct {<distinct.stats>} depth {<depth.stats>}"
  %-  crip
  ?-  -.res
    %ok        "check ok: {counts}"
    %failed    "check failed: {(trip reason.res)}"
    %limited   "check limited ({<kind.res>}): {counts}"
    %cancelled  "check cancelled"
    %violated  "violation {<-.violation.res>}: {counts}"
  ==
::
++  stub-translation
  '---- MODULE Stub ----\0a(* PlusCal translation stub *)\0a===='
::
++  stub-cfg  'INIT Init\0aNEXT Next\0a'
::
++  report-text
  |=  =job
  ^-  @t
  %-  crip
  "stub run: generated {<generated.stats.job>} ".
  "distinct {<distinct.stats.job>} depth {<depth.stats.job>}"
--
