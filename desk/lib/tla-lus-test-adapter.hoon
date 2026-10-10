/-  *tla-lus-test, api=tla-lus
/=  agent    /app/tla-lus
/=  job-lib  /lib/job
|%
  ::  tla-lus-test-adapter: the ONE place the black-box suite meets the agent
  ::
  ::  R4.0f rewired the July 2026 adapter, whose +observe was a stub returning
  ::  %blocked against an assumed wire, to the real one: it drives the agent
  ::  in-process exactly as tests/app/tla-lus.hoon does -- `%tla-lus-action`
  ::  pokes, Behn wakes on `/job/<id>/step`, `/x/job/<id>` peeks -- and
  ::  normalizes what it sees into a +report.
  ::
  ::  Status vocabulary (what +report.status can be):
  ::    TLC runs     upstream CI's exit-code categories (%success,
  ::                 %safety-failure, %deadlock-failure, %liveness-failure,
  ::                 %assumption-failure) or %error for any other failure
  ::    analyze runs %success, %parse-error, %module-error, %semantic-error,
  ::                 %level-error, from the first %error diagnostic's stage
  ::    the agent    %cancelled, %limited-<kind>, %rejected, %nack, %absent,
  ::                 %no-path, %unfinished, and the scenario-specific
  ::                 %nondeterministic / %interference / %diverged
  ::
::  +|  Types
::
+$  card  card:agent:gall
::  +|  Constants
::
::  a run still going after this many wakes is reported %unfinished
::
++  max-wakes  2.000
++  epoch  ~2026.7.12
::  +|  Public API
::
++  observe
  ::  drive one case through the agent and normalize what it shows
  |=  c=bb-case
  ^-  report
  =/  ag   `agent:gall`agent
  =/  req  (to-request c)
  =/  sub  !>(`action:api`[%submit ~.j1 req])
  ?-  scenario.c
      %run
    =/  r  (run ag 0 ~.j1 req)
    ?:  ?=(%| -.r)  [%rejected ~ p.r ~ ~]
    (narrow -.p.r +.p.r ~.j1)
  ::
      %cancel
    =/  s  (submit ag 0 ~.j1 req)
    ?:  ?=(%| -.s)  [%rejected ~ p.s ~ ~]
    =/  ag1  (fall (wake p.s 1 ~.j1) p.s)
    =/  res  (poke ag1 2 ~zod %tla-lus-action !>(`action:api`[%cancel ~.j1]))
    ?~  res  [%nack ~ '' ~ ~]
    (narrow +.u.res 3 ~.j1)
  ::
      %malformed-mark
    ?~  (poke ag 0 ~zod %tla-lus-nonsense sub)  [%nack ~ '' ~ ~]
    [%accepted ~ '' ~ ~]
  ::
      %malformed-payload
    ?~  (poke ag 0 ~zod %tla-lus-action !>(42))  [%nack ~ '' ~ ~]
    [%accepted ~ '' ~ ~]
  ::
      %unauthorized
    ?~  (poke ag 0 ~nec %tla-lus-action sub)  [%nack ~ '' ~ ~]
    [%accepted ~ '' ~ ~]
  ::
      %unknown-scry
    =/  res  (~(on-peek ag (bowl-at 0 ~zod)) /x/no-such-path)
    ?:  |(?=(~ res) ?=([~ ~] res))  [%no-path ~ '' ~ ~]
    [%served ~ '' ~ ~]
  ::
      %duplicate-request
    =/  s  (submit ag 0 ~.j1 req)
    ?:  ?=(%| -.s)  [%rejected ~ p.s ~ ~]
    =/  again  (submit p.s 1 ~.j1 req)
    ?:  ?=(%| -.again)  [%rejected ~ p.again ~ ~]
    [%accepted ~ '' ~ ~]
  ::
      %query-before-submit
    (narrow ag 0 ~.never)
  ::
      %query-after-completion
    =/  r  (run ag 0 ~.j1 req)
    ?:  ?=(%| -.r)  [%rejected ~ p.r ~ ~]
    ::  well after the result: a later peek must see the same job
    (narrow -.p.r (add 100 +.p.r) ~.j1)
  ::
      %repeat
    =/  r1  (run ag 0 ~.j1 req)
    ?:  ?=(%| -.r1)  [%rejected ~ p.r1 ~ ~]
    =/  r2  (run -.p.r1 +.p.r1 ~.j2 req)
    ?:  ?=(%| -.r2)  [%rejected ~ p.r2 ~ ~]
    =/  one  (narrow -.p.r2 +.p.r2 ~.j1)
    ?.  =(one (narrow -.p.r2 +.p.r2 ~.j2))  [%nondeterministic ~ '' ~ ~]
    one
  ::
      %concurrent
    =/  s1  (submit ag 0 ~.j1 req)
    ?:  ?=(%| -.s1)  [%rejected ~ p.s1 ~ ~]
    =/  s2  (submit p.s1 1 ~.j2 req)
    ?:  ?=(%| -.s2)  [%rejected ~ p.s2 ~ ~]
    ::  alternate one wake each until both are terminal
    =/  ag2  p.s2
    =/  n  2
    =/  k  0
    |-  ^-  report
    ?:  ?|  (gte k max-wakes)
            ?&((done ag2 n ~.j1) (done ag2 n ~.j2))
        ==
      =/  one  (narrow ag2 n ~.j1)
      ?.  =(one (narrow ag2 n ~.j2))  [%interference ~ '' ~ ~]
      one
    =/  ag3  (fall (wake ag2 n ~.j1) ag2)
    =/  ag4  (fall (wake ag3 +(n) ~.j2) ag3)
    $(ag2 ag4, n (add 2 n), k +(k))
  ::
      %restart
    =/  r  (run ag 0 ~.j1 req)
    ?:  ?=(%| -.r)  [%rejected ~ p.r ~ ~]
    =/  straight  (narrow -.p.r +.p.r ~.j1)
    =/  s  (submit ag 0 ~.j2 req)
    ?:  ?=(%| -.s)  [%rejected ~ p.s ~ ~]
    =/  ag1  (fall (wake p.s 1 ~.j2) p.s)
    ::  a Gall restart: the whole state through on-save/on-load
    =/  ag2
      `agent:gall`+:(~(on-load agent (bowl-at 2 ~zod)) ~(on-save ag1 (bowl-at 2 ~zod)))
    =/  fin  (finish ag2 3 ~.j2)
    =/  resumed  (narrow -.fin +.fin ~.j2)
    ?.  =(straight resumed)  [%diverged ~ '' ~ ~]
    resumed
  ::
      %rejected-run-isolation
    ::  `syntax=|` is a typed rejection (api.md, `analyze-flags`)
    =/  bad  req(op [%analyze [| & & |]])
    =/  s  (submit ag 0 ~.j0 bad)
    ?:  ?=(%& -.s)  [%accepted ~ 'the bad request was not rejected' ~ ~]
    =/  r  (run ag 1 ~.j1 req)
    ?:  ?=(%| -.r)  [%rejected ~ p.r ~ ~]
    (narrow -.p.r +.p.r ~.j1)
  ==
::  +|  Internal Helpers
::
++  bowl-at
  ::  a bowl whose clock moves one second per tick, so a %time limit bites
  |=  [n=@ud src=ship]
  ^-  bowl:gall
  :*  [~zod src %tla-lus `path`/test-agent]
      [~ ~ ~]
      [n `@uvJ`(shax n) (add epoch (mul n ~s1)) [~zod %tla-lus ud+n]]
  ==
::
++  to-request
  ::  an inline request with the case's limit overrides
  |=  c=bb-case
  ^-  request:api
  =/  lim=limits:api  default-limits:job-lib
  =?  max-states.lim  ?=(^ max-states.over.c)  u.max-states.over.c
  =?  max-time.lim  ?=(^ max-time.over.c)  u.max-time.over.c
  =?  max-source.lim  ?=(^ max-source.over.c)  u.max-source.over.c
  [op.c [%inline root.src.c (malt modules.src.c) cfg.src.c] lim ~ ~]
::
++  poke
  ::  one poke; ~ when the agent crashes, which Gall turns into a nack
  |=  [ag=agent:gall n=@ud src=ship =cage]
  ^-  (unit [(list card) agent:gall])
  =/  res  (mule |.((~(on-poke ag (bowl-at n src)) cage)))
  ?:  ?=(%| -.res)  ~
  `p.res
::
++  submit
  ::  %submit; the reason when the agent nacks or answers %rejected
  |=  [ag=agent:gall n=@ud id=@ta req=request:api]
  ^-  (each agent:gall @t)
  =/  res  (poke ag n ~zod %tla-lus-action !>(`action:api`[%submit id req]))
  ?~  res  [%| 'nack']
  =/  caz=(list card)  -.u.res
  |-  ^-  (each agent:gall @t)
  ?~  caz  [%& +.u.res]
  =/  cd=card  i.caz
  ?.  ?=([%give %fact *] cd)  $(caz t.caz)
  =/  up  !<(update:api q.cage.p.cd)
  ?:  ?=(%rejected -.up)  [%| reason.up]
  $(caz t.caz)
::
++  wake
  ::  one Behn wake on the job's step wire, under its CURRENT wake number
  ::  (read from the agent's state; R4.P2); ~ if the agent crashes
  |=  [ag=agent:gall n=@ud id=@ta]
  ^-  (unit agent:gall)
  =/  sav  ;;([%0 jobs=* arms=(map @ta @ud) *] q:~(on-save ag (bowl-at n ~zod)))
  =/  seq  (~(gut by arms.sav) id 0)
  =/  res
    %-  mule
    |.((~(on-arvo ag (bowl-at n ~zod)) [%job id %step (scot %ud seq) ~] [%behn %wake ~]))
  ?:  ?=(%| -.res)  ~
  `+.p.res
::
++  job-of
  |=  [ag=agent:gall n=@ud id=@ta]
  ^-  (unit job:api)
  =/  res  (~(on-peek ag (bowl-at n ~zod)) [%x %job id ~])
  ?~  res  ~
  ?~  u.res  ~
  !<((unit job:api) q.u.u.res)
::
++  done
  |=  [ag=agent:gall n=@ud id=@ta]
  ^-  ?
  =/  j  (job-of ag n id)
  |(?=(~ j) ?=(^ result.u.j))
::
++  finish
  ::  wake `id` until its result is set, at most +max-wakes times
  |=  [ag=agent:gall n=@ud id=@ta]
  ^-  [agent:gall @ud]
  =/  k  0
  |-  ^-  [agent:gall @ud]
  ?:  |((done ag n id) (gte k max-wakes))  [ag n]
  =/  next  (wake ag n id)
  ?~  next  [ag n]
  $(ag u.next, n +(n), k +(k))
::
++  run
  ::  submit `id` and wake it to a result
  |=  [ag=agent:gall n=@ud id=@ta req=request:api]
  ^-  (each [agent:gall @ud] @t)
  =/  s  (submit ag n id req)
  ?:  ?=(%| -.s)  [%| p.s]
  [%& (finish p.s +(n) id)]
::
++  narrow
  ::  the public +report for job `id`
  |=  [ag=agent:gall n=@ud id=@ta]
  ^-  report
  =/  j  (job-of ag n id)
  ?~  j  [%absent ~ '' ~ ~]
  =/  jb=job:api  u.j
  =/  res=(unit result:api)  result.jb
  ?~  res  [%unfinished ~ '' ~ ~]
  =/  errs=(list diagnostic:api)
    (skim diags.jb |=(d=diagnostic:api =(%error severity.d)))
  ::  the console report rides as the `%report` artifact; a TLC verdict's
  ::  message is there, not among the diagnostics
  =/  rep=tape
    =/  art  (~(get by artifacts.jb) %report)
    ?.  ?=([~ %text *] art)  ~
    (trip text.u.art)
  =/  lines=(list tape)
    (turn diags.jb |=(d=diagnostic:api `tape`"{(trip message.d)}\0a"))
  =/  dmsg=tape  (zing lines)
  ::  a run that fails says why in the result itself
  =/  why=tape  ?.(?=(%failed -.u.res) ~ "{(trip reason.u.res)}\0a")
  =/  summary=@t  (crip :(weld why rep dmsg))
  =/  tr=(unit trace:api)
    =/  arts=(list artifact:api)  ~(val by artifacts.jb)
    |-  ^-  (unit trace:api)
    ?~  arts  ~
    ?:  ?=(%trace -.i.arts)  `trace.i.arts
    $(arts t.arts)
  =/  acts=(list @t)
    ?~  tr  ~
    %+  turn  states.u.tr
    |=  s=trace-state:api
    ?~(action.s 'Initial predicate' name.u.action.s)
  ::  a verdict's EC is carried by the typed result (sur/tla-lus,
  ::  +violation, R2.7.1 / R2.7.13), not by a diagnostic
  =/  code=(unit @ud)
    ?^  errs  `num.code.i.errs
    ?.  ?=(%violated -.u.res)  ~
    =/  v  violation.u.res
    ?-  -.v
      %invariant   `?:(initial.v 2.107 2.110)
      %property    `?:(initial.v 2.108 2.116)
      %action      `2.112
      %liveness    `2.116
      %deadlock    `2.114
      %assumption  `2.104
    ==
  :*  (status-of op.request.jb u.res errs)
      code
      summary
      acts
      ?~(tr ~ loop-start.u.tr)
  ==
::
++  status-of
  ::  a result's category: CI's exit-code rule for TLC, a stage for SANY
  |=  [=op:api r=result:api errs=(list diagnostic:api)]
  ^-  @tas
  ?:  ?=(%analyze -.op)
    ?~  errs  %success
    ?+  stage.i.errs  %semantic-error
      %parse    %parse-error
      %modules  %module-error
      %level    %level-error
    ==
  ?-  -.r
    %ok         %success
    %cancelled  %cancelled
    %failed     %error
    %limited    `@tas`(cat 3 'limited-' kind.r)
  ::
      %violated
    ?-  -.violation.r
      %invariant   %safety-failure
      %deadlock    %deadlock-failure
      %assumption  %assumption-failure
      %property    %liveness-failure
      %action      %liveness-failure
      %liveness    %liveness-failure
    ==
  ==
--
