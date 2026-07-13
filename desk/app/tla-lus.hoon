/-  *tla-lus
/+  default-agent, dbug
/=  job-lib  /lib/tla/job
/=  mig      /lib/tla/migrate
|%
  ::  %tla-lus: Headless TLA+ Toolchain Agent
  ::
  ::  Unit-2 surface: frozen request/update nouns from /sur/tla-lus over
  ::  the deterministic stub engine in /lib/tla/job. Jobs advance in
  ::  bounded Behn-driven steps; each step's events fan out as facts on
  ::  /jobs and /job/<id>. Later units replace the stub stage bodies with
  ::  the real translator/SANY/TLC pipeline.
  ::
::  +|  Types
::
+$  versioned-state  $%(state-0:mig state-1)
+$  state-1  [%1 jobs=(map req-id job)]
+$  card     card:agent:gall
::
::  +|  Card Helpers
::
::
++  fact
  ::  Publish one update to /jobs and /job/<id>
  |=  [id=req-id upd=update]
  ^-  card
  [%give %fact ~[/jobs [%job id ~]] %tla-lus-update !>(upd)]
::
++  efacts
  ::  Publish a step's events in order
  |=  [id=req-id events=(list event)]
  ^-  (list card)
  %+  turn  events
  |=  ev=event
  (fact id [%job id ev])
::
++  wait
  ::  Schedule the next bounded step for a job
  |=  [id=req-id now=@da]
  ^-  card
  [%pass [%job id %step ~] %arvo %b %wait now]
::
++  snapshot
  ::  Current state of a job as updates, for (re)joining watchers
  |=  [id=req-id j=job]
  ^-  (list update)
  ?^  result.j
    [%job id [%result u.result.j]]~
  :~  [%job id [%stage stage.j]]
      [%job id [%progress progress.j]]
  ==
::
++  terminal
  ::  Only terminal jobs may be deleted or expose artifacts
  |=  j=job
  ^-  ?
  ?=(^ result.j)
--
%-  agent:dbug
=|  state-1
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this     .
    default  ~(. (default-agent this %.n) bowl)
::
++  on-init
  ^-  (quip card _this)
  `this
::
++  on-save  !>(state)
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  res=(each state-1 tang)
    %-  mule  |.
    =/  old  !<(versioned-state old-vase)
    ?-  -.old
      %0  [%1 (jobs-0-to-1:mig jobs.old)]
      %1  old
    ==
  ?:  ?=(%.y -.res)  `this(state p.res)
  %-  (slog 'tla-lus: state corrupt, unable to migrate' ~)
  `this(state *state-1)
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?>  =(src.bowl our.bowl)
  ?>  ?=(%tla-lus-action mark)
  =/  act  !<(action vase)
  ?-    -.act
      %submit
    =/  cur  (~(get by jobs.state) id.act)
    ?:  &(?=(^ cur) !(terminal u.cur))
      :_  this
      [(fact id.act [%rejected id.act 'duplicate active id']) ~]
    =/  bad  (validate:job-lib request.act)
    ?^  bad
      :_  this
      [(fact id.act [%rejected id.act u.bad]) ~]
    =.  jobs.state
      (~(put by jobs.state) id.act (init:job-lib request.act))
    :_  this
    :~  (fact id.act [%ack id.act])
        (wait id.act now.bowl)
    ==
  ::
      %cancel
    ::  idempotent: unknown or already-terminal ids are no-ops
    =/  cur  (~(get by jobs.state) id.act)
    ?~  cur  `this
    ?:  (terminal u.cur)  `this
    =/  j  u.cur(result `[%cancelled ~], stage %terminal, pending ~)
    =.  jobs.state  (~(put by jobs.state) id.act j)
    :_  this
    (efacts id.act [%result [%cancelled ~]]~)
  ::
      %delete-result
    =/  cur  (~(get by jobs.state) id.act)
    ?~  cur  `this
    ?.  (terminal u.cur)
      :_  this
      [(fact id.act [%rejected id.act 'job still active']) ~]
    =.  jobs.state  (~(del by jobs.state) id.act)
    :_  this
    [(fact id.act [%deleted id.act]) ~]
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  =(src.bowl our.bowl)
  ?+    path  (on-watch:default path)
      [%jobs ~]
    `this
  ::
      [%job @ ~]
    ::  unknown job ids reject the subscription
    =/  id   `req-id`i.t.path
    =/  cur  (~(get by jobs.state) id)
    ?>  ?=(^ cur)
    :_  this
    %+  turn  (snapshot id u.cur)
    |=  upd=update
    ^-  card
    [%give %fact ~ %tla-lus-update !>(upd)]
  ==
::
++  on-leave  on-leave:default
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  [~ ~]
      [%x %jobs ~]
    :^  ~  ~  %noun
    !>  ^-  (list [req-id stage])
    %+  turn  ~(tap by jobs.state)
    |=([id=req-id j=job] [id stage.j])
  ::
      [%x %job @ ~]
    ``noun+!>((~(get by jobs.state) `req-id`i.t.t.path))
  ::
      [%x %job @ %artifact @ ~]
    =/  id    `req-id`i.t.t.path
    =/  name  `artifact-name`i.t.t.t.t.path
    =/  cur   (~(get by jobs.state) id)
    ?~  cur  [~ ~]
    ?.  (terminal u.cur)  [~ ~]
    =/  art  (~(get by artifacts.u.cur) name)
    ?~  art  [~ ~]
    ``noun+!>(u.art)
  ==
::
++  on-agent  on-agent:default
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+    wire  (on-arvo:default wire sign-arvo)
      [%job @ %step ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:default wire sign-arvo)
    ::  jobs deleted or made terminal since scheduling are no-ops
    =/  id   `req-id`i.t.wire
    =/  cur  (~(get by jobs.state) id)
    ?~  cur  `this
    ?:  (terminal u.cur)  `this
    =/  res  (step:job-lib u.cur)
    =.  jobs.state  (~(put by jobs.state) id job.res)
    ?-    -.res
        %more
      :_  this
      (snoc (efacts id events.res) (wait id now.bowl))
    ::
        %stop
      :_  this
      (efacts id events.res)
    ==
  ==
::
++  on-fail  on-fail:default
--
