/-  *tla-lus
/+  default-agent, dbug
/=  job-lib  /lib/job
/=  mig      /lib/migrate
|%
  ::  %tla-lus: Headless TLA+ Toolchain Agent
  ::
  ::  Frozen request/update nouns from /sur/tla-lus over the resumable
  ::  continuation kernel in /lib/job (unit P2-1). Jobs advance in
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
++  read-card
  ::  One asynchronous Clay read for a paused job, tagged on its load
  ::  wire; the %writ comes back to on-arvo and resumes the job
  |=  [id=req-id r=read-request]
  ^-  card
  :*  %pass  [%job id %load (scot %ud tag.r) ~]  %arvo  %c  %warp
      ship.source-ref.r  desk.source-ref.r
      `[%sing %x cas.source-ref.r path.source-ref.r]
  ==
::
++  file-exists
  ::  Does the file exist at the pinned revision? A %sing read of a path
  ::  that was never born has no settled answer, so an absent file is
  ::  answered synchronously rather than warped for
  |=  r=source-ref
  ^-  ?
  =/  pax  (weld ~[(scot %p ship.r) desk.r (scot cas.r)] path.r)
  =/  m  (mule |.(.^(? %cu pax)))
  ?:(?=(%| -.m) | p.m)
::
++  writ-text
  ::  A %writ body, mark-agnostically: a marked text file is stored as
  ::  either an atom (%tla) or a wain (%txt)
  |=  rit=riot:clay
  ^-  (each @t @t)
  ?~  rit  [%| 'no such file']
  =/  nun  q.q.r.u.rit
  ?@  nun  [%& `@t`nun]
  =/  m  (mule |.((of-wain:format ;;(wain nun))))
  ?:(?=(%| -.m) [%| 'unreadable file body'] [%& p.m])
::
++  do-reads
  ::  Route a paused job's read-requests: existing files become Clay
  ::  cards, absent ones become responses the caller delivers at once
  |=  [id=req-id reads=(list read-request)]
  ^-  [caz=(list card) miss=(list read-response)]
  =|  caz=(list card)
  =|  miss=(list read-response)
  |-  ^-  [(list card) (list read-response)]
  ?~  reads  [(flop caz) (flop miss)]
  ?:  (file-exists source-ref.i.reads)
    $(reads t.reads, caz [(read-card id i.reads) caz])
  $(reads t.reads, miss [[tag.i.reads %| 'no such file'] miss])
::
++  pin-case
  ::  Pin a Clay bundle's revision for the whole run: a %da/%tas case is
  ::  resolved to a concrete aeon at submit, so a commit mid-run cannot
  ::  split the source set and no read can block on an unsettled case
  |=  req=request
  ^-  (each request @t)
  ?.  ?=(%clay -.src.req)  [%& req]
  =/  s  src.req
  =/  pax  /(scot %p ship.s)/[desk.s]/(scot cas.s)
  =/  m  (mule |.(.^(cass:clay %cw pax)))
  ?:  ?=(%| -.m)
    [%| 'cannot resolve the Clay revision: unknown desk or unsettled case']
  =.  cas.s  [%ud ud.p.m]
  [%& req(src s)]
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
::
++  retain
  ::  a job that just finished may have pushed the artifact store over
  ::  its bound; reclaim only then, so the scan is not paid every slice
  |=  [j=job-2:job-lib js=(map req-id job-2:job-lib)]
  ^-  (map req-id job-2:job-lib)
  ?.  (terminal j)  js
  (reclaim:job-lib js max-retained:default-quota:job-lib)
::
++  advance
  ::  Fan out a step's events and schedule what comes next: another
  ::  bounded step, nothing (terminal), or the Clay reads the job is
  ::  waiting on. Reads that cannot exist are answered immediately and a
  ::  step is scheduled, so a paused job always makes progress
  |=  [id=req-id r=step-result-2:job-lib now=@da]
  ^-  [(list card) job-2:job-lib]
  ?-    -.r
      %more  [(snoc (efacts id events.r) (wait id now)) job.r]
      %stop  [(efacts id events.r) job.r]
      %await
    =/  dr  (do-reads id reads.r)
    :_  (deliver:job-lib job.r miss.dr)
    ;:  weld
      (efacts id events.r)
      caz.dr
      ?~(miss.dr ~ ~[(wait id now)])
    ==
  ==
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
    ::  the agent-wide bounds, on top of the request's own limits
    =/  full
      %^  quota-reject:job-lib  jobs.state
        default-quota:job-lib
      request.act
    ?^  full
      :_  this
      [(fact id.act [%rejected id.act u.full]) ~]
    =/  pin  (pin-case request.act)
    ?:  ?=(%| -.pin)
      :_  this
      [(fact id.act [%rejected id.act p.pin]) ~]
    =.  jobs.state
      (~(put by jobs.state) id.act (init:job-lib p.pin now.bowl))
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
    =/  adv  (advance id res now.bowl)
    =.  jobs.state  (~(put by jobs.state) id +.adv)
    =.  jobs.state  (retain +.adv jobs.state)
    [-.adv this]
  ::
      [%job @ %load @ ~]
    ::  a Clay read for a paused job: deliver the body and resume it.
    ::  Responses for deleted, terminal, or no-longer-pending reads are
    ::  dropped by the job (the load cursor ignores unknown tags)
    ?.  ?=([%clay %writ *] sign-arvo)
      (on-arvo:default wire sign-arvo)
    =/  id   `req-id`i.t.wire
    =/  tag  (slav %ud i.t.t.t.wire)
    =/  cur  (~(get by jobs.state) id)
    ?~  cur  `this
    ?:  (terminal u.cur)  `this
    =/  j    (deliver:job-lib u.cur ~[[tag (writ-text p.sign-arvo)]])
    =/  res  (step:job-lib j default-budget:job-lib now.bowl)
    =/  adv  (advance id res now.bowl)
    =.  jobs.state  (~(put by jobs.state) id +.adv)
    =.  jobs.state  (retain +.adv jobs.state)
    [-.adv this]
  ==
::
++  on-fail  on-fail:default
--
