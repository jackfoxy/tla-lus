/-  *tla-lus-test, api=tla-lus
::  tla-lus-test-adapter: the ONE place the suite assumes anything about the
::  live %tla-lus Gall API.
::
::  The whole black-box suite treats TLA+ behavior as opaque and reaches it
::  only through this door.  If the agent's real mark, scry path or wire
::  molds differ from what is assumed here, only this file changes; every
::  corpus and failure arm keeps compiling and asserting against the
::  normalized +report shape.
::
::  Assumed minimal contract (and nothing more):
::    1. one poke `%tla-lus-action` carrying [%run run-request] / [%cancel id];
::    2. one scry `/x/run/<id>` (or subscription) returning +update:api with
::       lifecycle +phase and a terminal +result.
::
|%
::  +poke-mark: assumed submit/cancel poke mark
::
++  poke-mark  `mark`%tla-lus-action
::  +scry-path: assumed result scry path for a request id
::
++  scry-path
  |=  id=@t
  ^-  path
  /x/run/[id]
::  +corpus-to-request: narrow a corpus case to a submit payload
::
::    module is the root .tla; model is its .cfg (empty for parse/prove/
::    translate cases, which carry no config).
::
++  corpus-to-request
  |=  c=corpus-case
  ^-  run-request:api
  :*  id=id.c
      source=[%path root=module.c]
      config=?:(=('' model.c) ~ `model.c)
      mode=`mode:api`mode.c
      options=`options:api`options.c
  ==
::  +failure-to-request: narrow a failure case to a submit payload
::
++  failure-to-request
  |=  c=failure-case
  ^-  run-request:api
  :*  id=name.c
      source=[%path root=root.c]
      config=config.c
      mode=`mode:api`mode.c
      options=`options:api`options.c
  ==
::  +narrow: normalize a live +update into the public +report shape
::
::    Documents the crossing contract; used the moment +observe is wired to a
::    real agent.  Maps the app's terminal +result onto outcome / code /
::    summary / trace / stats without leaking any internal structure.
::
++  narrow
  |=  =update:api
  ^-  report
  ?~  result.update
    [id.update %.n %pending ~ ~ '' ~ ~]
  =/  r  u.result.update
  =/  =status  status.r
  =/  out=(unit outcome)
    ?+  status  ~
      %success            `%success
      %safety-failure     `%safety-failure
      %liveness-failure   `%liveness-failure
      %assumption-failure  `%assumption-failure
      %deadlock-failure   `%deadlock-failure
    ==
  =/  =trace  [states.r loop.r]
  =/  stats=run-stats
    ?:  ?&(?=(~ distinct.r) ?=(~ total.r) ?=(~ depth.r))
      ~
    `[distinct.r total.r depth.r]
  :*  id=id.update
      terminal=?=(?(%done %failed %cancelled) phase.r)
      status=status
      outcome=out
      code=code.r
      summary=summary.r
      trace=?:(=(~ states.r) ~ `trace)
      stats=stats
  ==
::  +observe: submit a request and return the normalized terminal report
::
++  observe
  |=  req=run-request:api
  ^-  report
  ::  ISOLATED ASSUMPTION / KNOWN BLOCKER
  ::
  ::  A live desk would here poke `(poke-mark !>([%run req]))` at %tla-lus and
  ::  scry `(scry-path id.req)` for the terminal +update:api, then hand it to
  ::  +narrow.  The %tla-lus agent is hypothetical and absent from this desk,
  ::  so no run can be observed.  We return a terminal %blocked report: every
  ::  corpus/failure arm then FAILS with a clear diagnostic instead of passing
  ::  on a crash.  Wiring the live poke+scry here activates the entire suite
  ::  with no other change.
  :*  id=id.req
      terminal=%.n
      status=%blocked
      outcome=`(unit outcome)`~
      code=~
      summary='tla-lus agent absent: no run observed'
      trace=~
      stats=~
  ==
::  +run-corpus: observe a corpus case
::
++  run-corpus
  |=  c=corpus-case
  ^-  report
  (observe (corpus-to-request c))
::  +run-failure: observe a failure case
::
++  run-failure
  |=  c=failure-case
  ^-  report
  (observe (failure-to-request c))
--
