/-  *tla-lus
/+  default-agent, dbug
/=  job-lib  /lib/tla/job
/=  mig      /lib/tla/migrate
|%
  ::  %tla-lus: Headless TLA+ Toolchain Agent
  ::
  ::  Frozen request/update nouns from /sur/tla-lus over the resumable
  ::  continuation kernel in /lib/tla/job (unit P2-1). Jobs advance in
  ::  Behn-driven steps of at most default-budget work units; each
  ::  step's events fan out as facts on /jobs and /job/<id>. Scries
  ::  expose the public $job projection, never internal cursors.
  ::
::  +|  Types
::
+$  versioned-state  $%(state-0:mig state-1:mig state-2)
+$  state-2  [%2 jobs=(map req-id job-2:job-lib)]
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
  |=  [id=req-id j=job-2:job-lib]
  ^-  (list update)
  ?^  result.j
    [%job id [%result u.result.j]]~
  :~  [%job id [%stage stage.j]]
      [%job id [%progress progress.j]]
  ==
::
++  terminal
  ::  Only terminal jobs may be deleted or expose artifacts
  |=  j=job-2:job-lib
  ^-  ?
  ?=(^ result.j)
--
%-  agent:dbug
=|  state-2
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
  =/  res=(each state-2 tang)
    %-  mule  |.
    =/  old  !<(versioned-state old-vase)
    ?-  -.old
      %0  [%2 (jobs-1-to-2:mig (jobs-0-to-1:mig jobs.old))]
      %1  [%2 (jobs-1-to-2:mig jobs.old)]
      %2  old
    ==
  ?:  ?=(%.y -.res)  `this(state p.res)
  %-  (slog 'tla-lus: state corrupt, unable to migrate' ~)
  `this(state *state-2)
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
      (~(put by jobs.state) id.act (init:job-lib request.act now.bowl))
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
    =.  jobs.state  (~(put by jobs.state) id.act (cancel:job-lib u.cur))
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
    |=([id=req-id j=job-2:job-lib] [id stage.j])
  ::
      [%x %job @ ~]
    =/  cur  (~(get by jobs.state) `req-id`i.t.t.path)
    ``noun+!>(`(unit job)`(bind cur project:job-lib))
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
    =/  res  (step:job-lib u.cur default-budget:job-lib now.bowl)
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
