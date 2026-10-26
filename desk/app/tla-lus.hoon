/-  *tla-lus
/+  default-agent, dbug
/=  job-lib  /lib/job
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
::  ONE state shape and no migrations: the project is in development, so a
::  shape change is made in place and `on-load` resets a state that no
::  longer fits.
::
::  `arms` is each job's CURRENT wake number (R4.P2). A step wake carries it
::  in its wire, and a wake with any other number is stale and ignored, so
::  re-arming a job (at `on-load`, or by the sweep) can never fork a second
::  step chain. `sweep` is the pending sweep timer, if any: once a minute it
::  re-arms every running job, so a job whose wake was lost (an event
::  aborted by an interrupt consumes it) resumes within a minute instead of
::  sitting `running` forever
::  `pace` (R4.QS): per job, when its last step began and the budget it
::  ran with, from which the next budget is sized (`+pace-budget`)
+$  state-0
  $:  %0
      jobs=(map req-id jobstate:job-lib)
      arms=(map req-id @ud)
      sweep=(unit @da)
      pace=(map req-id [at=@da bud=@ud])
  ==
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
  ::  Schedule the next bounded step for a job, under wake number `seq`
  |=  [id=req-id seq=@ud now=@da]
  ^-  card
  [%pass [%job id %step (scot %ud seq) ~] %arvo %b %wait now]
::
++  sweep-gap  ~m1
++  sweep-card
  |=  at=@da
  ^-  card
  [%pass [%sweep (scot %da at) ~] %arvo %b %wait at]
::
++  rearmable
  ::  a job the sweep may re-arm: running, and not paused on Clay reads (a
  ::  `%modules` job is resumed by its `%writ`s, not by a wake)
  |=  j=jobstate:job-lib
  ^-  ?
  &(?=(~ result.j) !=(%modules stage.j))
::
::  +|  Wake Numbering (R4.P2)
::
++  next-arm
  ::  a fresh wake number for `id`, recorded as its current one
  |=  [st=state-0 id=req-id]
  ^-  [@ud state-0]
  =/  n  +((~(gut by arms.st) id 0))
  [n st(arms (~(put by arms.st) id n))]
::
++  rearm-all
  ::  a fresh wake, now, for every job the sweep may re-arm
  |=  [st=state-0 now=@da]
  ^-  [(list card) state-0]
  =/  js  ~(tap by jobs.st)
  =|  caz=(list card)
  |-  ^-  [(list card) state-0]
  ?~  js  [(flop caz) st]
  ?.  (rearmable q.i.js)  $(js t.js)
  =^  seq  st  (next-arm st p.i.js)
  $(js t.js, caz [(wait p.i.js seq now) caz])
::
++  start-sweep
  ::  (re)start the sweep timer, superseding any pending one
  |=  [st=state-0 now=@da]
  ^-  [(list card) state-0]
  ?.  (lien ~(val by jobs.st) rearmable)  [~ st(sweep ~)]
  =/  at  (add now sweep-gap)
  [~[(sweep-card at)] st(sweep `at)]
::
++  ensure-sweep
  ::  start the sweep timer unless one is pending
  |=  [st=state-0 now=@da]
  ^-  [(list card) state-0]
  ?^  sweep.st  [~ st]
  (start-sweep st now)
::
++  read-card
  ::  One asynchronous Clay read for a paused job, tagged on its load
  ::  wire; the %writ comes back to on-arvo and resumes the job. The
  ::  wire carries the job's generation (its submit time) as well as the
  ::  read's tag, so a response left over from an earlier job that held
  ::  the same id cannot be absorbed by this one
  |=  [id=req-id gen=@da r=read-request]
  ^-  card
  :*  %pass  [%job id %load (scot %da gen) (scot %ud tag.r) ~]  %arvo  %c
      %warp  ship.source-ref.r  desk.source-ref.r
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
  |=  [id=req-id gen=@da reads=(list read-request)]
  ^-  [caz=(list card) miss=(list read-response)]
  =|  caz=(list card)
  =|  miss=(list read-response)
  |-  ^-  [(list card) (list read-response)]
  ?~  reads  [(flop caz) (flop miss)]
  ?:  (file-exists source-ref.i.reads)
    $(reads t.reads, caz [(read-card id gen i.reads) caz])
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
  |=  [id=req-id j=jobstate:job-lib]
  ^-  (list update)
  ?^  result.j
    [%job id [%result u.result.j]]~
  :~  [%job id [%stage stage.j]]
      [%job id [%progress progress.j]]
  ==
::
++  terminal
  ::  Only terminal jobs may be deleted or expose artifacts
  |=  j=jobstate:job-lib
  ^-  ?
  ?=(^ result.j)
::
++  retain
  ::  a job that just finished may have pushed the artifact store over
  ::  its bound; reclaim only then, so the scan is not paid every slice
  |=  [j=jobstate:job-lib js=(map req-id jobstate:job-lib)]
  ^-  (map req-id jobstate:job-lib)
  ?.  (terminal j)  js
  (reclaim:job-lib js max-retained:default-quota:job-lib)
::
++  write-cards
  ::  R2.2: a terminal job with a write target persists its artifacts to Clay.
  ::
  ::  This lives in the AGENT, not the kernel: `+step` is pure and returns
  ::  `[%stop events job]` with no cards, which is what lets the scaffold
  ::  gate assert no `desk/lib` file touches Clay. The kernel decides WHAT a
  ::  run produced; the agent decides where it goes.
  ::
  ::  Clay's `%info` is an internal edit and carries NO ack gift (`lull`:
  ::  `[%info des=desk dit=nori]`, and the gift set is `%writ`/`%wris` only).
  ::  There is therefore no round trip to await and no failure to report back
  ::  through the job's result — which is exactly why `+write-err` validates
  ::  the target at SUBMIT, before a job exists. By the time a card is emitted
  ::  the desk and path are known good, so a refusal here would be a Clay bug,
  ::  the same argument compatibility.md 10.7 makes for the absent `%writ`
  ::  watchdog.
  |=  j=jobstate:job-lib
  ^-  (list card)
  =/  w  write.request.j
  ?~  w  ~
  =/  as  ~(tap by artifacts.j)
  |-  ^-  (list card)
  ?~  as  ~
  =/  nom  p.i.as
  =/  art  q.i.as
  ::  a text artifact is written as `%txt` (a `wain`, the desk's own mark);
  ::  a typed trace is a noun and is written as `%noun`. The artifact NAME
  ::  becomes the final path segment, so `%report` lands at <pax>/report/txt
  =/  =cage
    ?-  -.art
      %text   [%txt !>(`wain`(to-wain:format text.art))]
      %trace  [%noun !>(`trace`trace.art)]
      ::  a `-continue` run's counterexample list (R2.4.2): a noun, like a
      ::  single trace
      %violations  [%noun !>(`(list [=violation =trace])`viols.art)]
    ==
  =/  ext  ?-(-.art %text %txt, %trace %noun, %violations %noun)
  =/  pax  `path`(weld pax.u.w ~[nom ext])
  :_  $(as t.as)
  [%pass [%job %write nom ~] %arvo %c %info desk.u.w %& ~[[pax %ins cage]]]
::
++  advance
  ::  Fan out a step's events and schedule what comes next: another
  ::  bounded step, nothing (terminal), or the Clay reads the job is
  ::  waiting on. Reads that cannot exist are answered immediately and a
  ::  step is scheduled, so a paused job always makes progress
  |=  [id=req-id r=step-out:job-lib now=@da seq=@ud]
  ^-  [(list card) jobstate:job-lib]
  ?-    -.r
      %more  [(snoc (efacts id events.r) (wait id seq now)) job.r]
      %stop  [(weld (efacts id events.r) (write-cards job.r)) job.r]
      %await
    =/  dr  (do-reads id started.job.r reads.r)
    :_  (deliver:job-lib job.r miss.dr)
    ;:  weld
      (efacts id events.r)
      caz.dr
      ?~(miss.dr ~ ~[(wait id seq now)])
    ==
  ==
--
%-  agent:dbug
=|  state-0
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
  ::  the stored noun is coerced to the one state shape; one that no longer
  ::  fits (a shape changed during development) resets the agent to empty
  =/  res  (mule |.(;;(state-0 q.old-vase)))
  =.  state
    ?:  ?=(%& -.res)  p.res
    ((slog 'tla-lus: stored state does not fit this build; reset' ~) *state-0)
  ::  re-arm every running job and restart the sweep. A wake that was pending
  ::  is superseded by its new number, so nothing steps twice
  =^  caz  state  (rearm-all state now.bowl)
  =^  sw   state  (start-sweep state now.bowl)
  [(weld caz sw) this]
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
    ?^  cur
      ::  an id names one run: an active one is not disturbed, and a
      ::  result is never silently replaced by a resubmit (delete it
      ::  first — the explicit path)
      :_  this
      :_  ~
      %+  fact  id.act
      :+  %rejected  id.act
      ?:  (terminal u.cur)
        'a result for this id already exists; delete it first'
      'duplicate active id'
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
    =.  pace.state  (~(del by pace.state) id.act)
    =^  seq  state  (next-arm state id.act)
    =^  sw   state  (ensure-sweep state now.bowl)
    :_  this
    :*  (fact id.act [%ack id.act])
        (wait id.act seq now.bowl)
        sw
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
    =.  arms.state  (~(del by arms.state) id.act)
    =.  pace.state  (~(del by pace.state) id.act)
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
      [%x %version ~]
    ::  what a caller is talking to: the public API revision and the
    ::  agent's state version
    :^  ~  ~  %noun
    !>  ^-  [api=@ud state=@ud]
    [api-version 0]
  ::
      [%x %jobs ~]
    :^  ~  ~  %noun
    !>  ^-  (list [req-id stage])
    %+  turn  ~(tap by jobs.state)
    |=([id=req-id j=jobstate:job-lib] [id stage.j])
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
      [%job @ %step *]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:default wire sign-arvo)
    ::  jobs deleted or made terminal since scheduling are no-ops
    =/  id   `req-id`i.t.wire
    =/  cur  (~(get by jobs.state) id)
    ?~  cur  `this
    ?:  (terminal u.cur)  `this
    ::  only the job's CURRENT wake steps it (R4.P2)
    ?.  ?&  ?=([%job @ %step @ ~] wire)
            =(`(slav %ud i.t.t.t.wire) (~(get by arms.state) id))
        ==
      `this
    =/  bud  (pace-budget:job-lib (~(get by pace.state) id) now.bowl)
    =.  pace.state  (~(put by pace.state) id [now.bowl bud])
    =/  res  (step:job-lib u.cur bud now.bowl)
    =^  seq  state  (next-arm state id)
    =/  adv  (advance id res now.bowl seq)
    =.  jobs.state  (~(put by jobs.state) id +.adv)
    =.  jobs.state  (retain +.adv jobs.state)
    [-.adv this]
  ::
      [%job @ %load @ @ ~]
    ::  a Clay read for a paused job: deliver the body and resume it.
    ::  Everything that is not a live answer to a read this job is
    ::  actually holding — an unknown or deleted job, a sealed one, a
    ::  response from an earlier job that held this id, a duplicate, or
    ::  one for a superseded load — is dropped without a step, so a
    ::  repeated or reordered delivery changes neither state nor events
    ?.  ?=([%clay %writ *] sign-arvo)
      (on-arvo:default wire sign-arvo)
    =/  id   `req-id`i.t.wire
    =/  gen  (slav %da i.t.t.t.wire)
    =/  tag  (slav %ud i.t.t.t.t.wire)
    =/  cur  (~(get by jobs.state) id)
    ?~  cur  `this
    ?:  (terminal u.cur)  `this
    ?.  =(gen started.u.cur)  `this
    ?.  (awaiting:job-lib u.cur tag)  `this
    =/  j    (deliver:job-lib u.cur ~[[tag (writ-text p.sign-arvo)]])
    =/  res  (step:job-lib j default-budget:job-lib now.bowl)
    =^  seq  state  (next-arm state id)
    =/  adv  (advance id res now.bowl seq)
    =.  jobs.state  (~(put by jobs.state) id +.adv)
    =.  jobs.state  (retain +.adv jobs.state)
    [-.adv this]
  ::
      [%job @ %load *]
    ::  a malformed load wire is dropped, never a crashed event
    `this
  ::
      [%sweep @ ~]
    ::  R4.P2: re-arm every running job, then reschedule while any remain.
    ::  A superseded sweep timer (its time is not the pending one) is a no-op
    ?.  ?=([%behn %wake *] sign-arvo)  `this
    ?.  =(`(slav %da i.t.wire) sweep.state)  `this
    =.  sweep.state  ~
    =^  caz  state  (rearm-all state now.bowl)
    =^  sw   state  (ensure-sweep state now.bowl)
    [(weld caz sw) this]
  ==
::
++  on-fail  on-fail:default
--
