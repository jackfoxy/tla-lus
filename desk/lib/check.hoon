/-  *tla-lus
/=  ast      /lib/ast
/=  syntax   /lib/syntax
/=  ev       /lib/eval
/=  config   /lib/config
/=  ne       /lib/node-eval
/=  fp       /lib/fingerprint
/=  sem-lib  /lib/semantic
/=  tp       /lib/temporal
/=  tb       /lib/tableau
/=  lv       /lib/liveness
/=  vl       /lib/value
/=  rng      /lib/rng
|%
  ::  TLC Safety Model Checking (deterministic single-worker BFS)
  ::
  ::  A first increment of unit 10: generate initial and next states from
  ::  the Init/Next predicates (the TLC assignment semantics for /\, \/,
  ::  =, \E, IF, and UNCHANGED), explore with deterministic breadth-first
  ::  search over fingerprinted states, check an invariant, detect
  ::  deadlock, and emit TLC's terminal summary (states generated /
  ::  distinct / depth) and, on an invariant violation, the shortest
  ::  behavior trace. Expression evaluation reuses lib/eval; a primed
  ::  variable x' reads the partial next-state binding stored under the
  ::  key "<name>'".
  ::
::  +|  Types
::
+$  node   syntax-node:ast
+$  value  value:ev
+$  state  (map @t value)   ::  variable -> value
::  a node in the reachability graph: state, its BFS depth, and the
::  fingerprint of its predecessor (for trace reconstruction)
+$  seen-entry  [depth=@ud pred=@t]
::
::  +|  Node Helpers
::
::
++  kids-of   kids-of:ev
++  is-kind   is-kind:ev
++  op-name   op-name:ev
++  genid-name  genid-name:ev
++  leaf-kind
  |=  n=node
  ^-  @tas
  ?>(?=(%leaf -.n) kind.token.n)
::
++  leaf-text
  |=  n=node
  ^-  @t
  ?>(?=(%leaf -.n) text.token.n)
::
::  +|  Fingerprinting
::
::
++  fingerprint
  ::  the canonical FP64 fingerprint of a state (Work Unit 7.1): FP64 extended
  ::  over each variable's WU6.8 fp-input bytes in `order` (TLC's declaration
  ::  order), matching TLCState.fingerPrint. The visited map is keyed by this
  ::  fingerprint — no rendered text is ever a key. Worn as `@t` only so the
  ::  existing @t-keyed seen/queue molds and the %live cursor are unchanged.
  |=  [order=(list @t) st=state]
  ^-  @t
  (@t (state-fp:fp order st))
::
::  +|  Config / Spec Extraction
::
::
++  body-of-def
  ::  the body expression of the operator definition named `nm`
  |=  [tree=node nm=@t]
  ^-  (unit node)
  ?.  (is-kind tree %n-module)  ~
  =/  b  (skim (kids-of tree) |=(k=node (is-kind k %n-body)))
  ?~  b  ~
  =/  defs
    %+  skim  (kids-of i.b)
    |=  u=node
    ?.  (is-kind u %n-operatordefinition)  |
    =(nm (def-name u))
  ?~  defs  ~
  `(rear (kids-of i.defs))
::
++  def-name
  |=  u=node
  ^-  @t
  =/  kids  (kids-of u)
  ?~  kids  ''
  =/  lhs  i.kids
  ?.  ?=(%node -.lhs)  ''
  =/  ids  (skim (kids-of lhs) |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~(ids '' (leaf-text i.ids))
::
++  var-names
  ::  the declared VARIABLE names of a module
  |=  tree=node
  ^-  (set @t)
  =/  b  (skim (kids-of tree) |=(k=node (is-kind k %n-module)))
  =/  body
    =/  bb  (skim (kids-of tree) |=(k=node (is-kind k %n-body)))
    ?~(bb ~ (kids-of i.bb))
  %-  ~(gas in *(set @t))
  %-  zing
  %+  turn  body
  |=  u=node
  ^-  (list @t)
  ?.  (is-kind u %n-variabledeclaration)  ~
  %+  murn  (kids-of u)
  |=  k=node
  ^-  (unit @t)
  ?.  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))  ~
  `(leaf-text k)
::
++  var-order
  ::  the declared VARIABLE names of a module in TLC's canonical (source
  ::  declaration) order, which fixes the FP64 state-fingerprint byte order
  |=  tree=node
  ^-  (list @t)
  =/  b  (skim (kids-of tree) |=(k=node (is-kind k %n-module)))
  =/  body
    =/  bb  (skim (kids-of tree) |=(k=node (is-kind k %n-body)))
    ?~(bb ~ (kids-of i.bb))
  %-  zing
  %+  turn  body
  |=  u=node
  ^-  (list @t)
  ?.  (is-kind u %n-variabledeclaration)  ~
  %+  murn  (kids-of u)
  |=  k=node
  ^-  (unit @t)
  ?.  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))  ~
  `(leaf-text k)
::
++  elems  elems:ev
::
++  perms-of-value
  ::  a set of functions over model values, as the name-to-name bijections
  ::  the orbit machinery uses (unit 6C.5). ~ when a function is not a
  ::  model-value permutation
  |=  v=value
  ^-  (unit (list (map @t @t)))
  ?.  ?=(%set -.v)  ~
  =|  out=(list (map @t @t))
  =/  fs  p.v
  |-  ^-  (unit (list (map @t @t)))
  ?~  fs  `(flop out)
  ?.  ?=(%fcn -.i.fs)  ~
  =/  one
    =|  m=(map @t @t)
    =/  ps  p.i.fs
    |-  ^-  (unit (map @t @t))
    ?~  ps  `m
    ?.  ?&(?=(%model -.d.i.ps) ?=(%model -.r.i.ps))  ~
    $(ps t.ps, m (~(put by m) p.d.i.ps p.r.i.ps))
  ?~  one  ~
  $(fs t.fs, out [u.one out])
::
++  symmetry-perms
  ::  the permutation group for the SYMMETRY operator. The definition is
  ::  EVALUATED (so `Permutations` is the registry override, one
  ::  implementation shared with every other caller) and its value read as
  ::  model-value bijections; a definition that does not denote such a set
  ::  is a typed rejection rather than a silent loss of reduction
  |=  [defs=(map @t sem-def:sem-lib) consts=(map @t value) vars=(set @t) sym=(unit @t)]
  ^-  (each (list (map @t @t)) @t)
  ?~  sym  [%& ~]
  =/  b  (sem-body defs u.sym)
  ?~  b  [%| (rap 3 ~['SYMMETRY operator is not defined: ' u.sym])]
  =/  r  (eval:ne u.b (make-env:ne defs consts vars))
  ?:  ?=(%| -.r)  [%| msg.p.r]
  =/  ps  (perms-of-value p.r)
  ?~  ps
    [%| (rap 3 ~['SYMMETRY ' u.sym ' is not a set of model-value permutations'])]
  [%& u.ps]
::
++  cfg-names
  ::  the INIT/NEXT/first-INVARIANT/first-PROPERTY names from a .cfg via
  ::  the real config parser (unit 5); ~ when the cfg is malformed. Full
  ::  config-vs-graph validation is the job kernel's %config stage — these
  ::  engine helpers only need the target names off a well-formed cfg.
  |=  cfg=@t
  ^-  (unit [in=(unit @t) nx=(unit @t) iv=(unit @t) pp=(unit @t)])
  =/  pr  (parse-cfg:config cfg)
  ?:  ?=(%| -.pr)  ~
  =/  a  p.pr
  :-  ~
  :*  init.a
      next.a
      ?~(invariants.a ~ `i.invariants.a)
      ?~(properties.a ~ `i.properties.a)
  ==
::
::  +|  Breadth-First Exploration (resumable cursor, unit P2-1)
::
::
+$  visit  [depth=@ud pred=@t st=state]
+$  outcome
  $%  [%ok gen=@ud distinct=@ud queued=@ud depth=@ud]
      [%inv gen=@ud distinct=@ud queued=@ud depth=@ud trace=(list state) name=@t initial=?]
      [%deadlock gen=@ud distinct=@ud queued=@ud depth=@ud trace=(list state)]
      [%limited what=?(%states %depth) gen=@ud distinct=@ud queued=@ud depth=@ud]
      ::  a typed evaluation failure during the search (WU6.9)
      [%error msg=@t]
  ==
::  fixed parameters of one search
+$  bfs-opts
  ::  WU6.9: the search runs on Work Unit 3 SEMANTIC nodes via node-eval, not
  ::  the CST. `next`/`inv` are semantic bodies; `defs`/`consts` build the
  ::  evaluation context (operator definitions + config constant assignments).
  $:  next=sem:sem-lib
      invs=(list [name=@t body=sem:sem-lib])   ::  invariants, declaration order
      cons=(list sem:sem-lib)                  ::  state constraints (CONSTRAINT)
      acons=(list sem:sem-lib)                 ::  action constraints
      vars=(set @t)
      order=(list @t)   ::  vars in TLC declaration order (FP64 byte order)
      perms=(list (map @t @t))   ::  symmetry group (empty = no symmetry)
      defs=(map @t sem-def:sem-lib)
      consts=(map @t value)
      deadlock=?     ::  report deadlocked states as violations
      cap=@ud        ::  distinct-state bound (0 = unbounded)
      maxd=@ud       ::  graph-depth bound (0 = unbounded)
  ==
::
++  env-of
  ::  the node-eval evaluation context for a search
  |=  o=bfs-opts
  ^-  eenv:ne
  (make-env:ne defs.o consts.o vars.o)
::  everything required to resume a search byte-identically
+$  bfs-cursor
  $:  init-todo=(list state)  ::  initial states not yet registered
      queue=(list @t)         ::  frontier fingerprints, BFS order
      seen=(map @t visit)
      inits=(list @t)         ::  registered initial states, in order
      gen=@ud
      distinct=@ud
      depth=@ud
      ::  out-degree samples as TLC collects them: one per DEQUEUED state, the
      ::  count of its newly-distinct successors (Worker.outDegree.addSample of
      ::  unseenSuccessorStates). A bucket histogram (sample -> count), which is
      ::  what tlc2's BucketStatistics keeps, so min/mean/95th/max all derive
      ::  from it rather than only the max (R1.5.12b)
      outdeg=(map @ud @ud)
  ==
+$  bfs-slice
  $%  [%more cur=bfs-cursor]
      [%done out=outcome cur=bfs-cursor]
  ==
::
++  bfs-init
  ::  a fresh cursor over the already-solved initial states (init solving
  ::  happens once at %config, so its typed failures surface immediately);
  ::  registration is budgeted in +bfs-step
  |=  is=(list state)
  ^-  bfs-cursor
  [is ~ ~ ~ (lent is) 0 0 ~]
::
++  con-hold
  ::  do all state constraints (CONSTRAINT) hold on `st`? (each bool / eval err)
  |=  [cs=(list sem:sem-lib) st=state e=eenv:ne]
  ^-  (each ? @t)
  ?~  cs  [%& &]
  =/  r  (pred-bool:ne i.cs st ~ e)
  ?:  ?=(%| -.r)  [%| msg.p.r]
  ?.  p.r  [%& |]
  $(cs t.cs)
::
++  acon-hold
  ::  do all action constraints (ACTION_CONSTRAINT) hold on the transition
  ::  cur -> nxt? (an action-level predicate: cur under plain names, nxt primed)
  |=  [cs=(list sem:sem-lib) cur=state nxt=state e=eenv:ne]
  ^-  (each ? @t)
  ?~  cs  [%& &]
  =/  r  (pred-bool:ne i.cs cur nxt e)
  ?:  ?=(%| -.r)  [%| msg.p.r]
  ?.  p.r  [%& |]
  $(cs t.cs)
::
++  od-stats
  ::  tlc2.util.statistics.BucketStatistics over the out-degree histogram,
  ::  reported by ModelChecker as `min, round(mean), round(p95), max`
  ::  (ModelChecker.java:890). Empty (no state dequeued) renders all zeros --
  ::  TLC only prints the line when getObservations() > 0. R1.5.12b
  |=  h=(map @ud @ud)
  ^-  [min=@ud mean=@ud p95=@ud max=@ud]
  =/  ks  (sort ~(tap in ~(key by h)) lth)
  ?~  ks  [0 0 0 0]
  =/  obs  (roll ~(val by h) add)
  ?:  =(0 obs)  [0 0 0 0]
  ::  largest observed sample (the list is ascending; walked rather than
  ::  +rear'd, which nest-fails on a ?~-narrowed list)
  =/  mx
    =/  l=(list @ud)  t.ks
    =/  m=@ud  i.ks
    |-  ^-  @ud
    ?~  l  m
    $(l t.l, m i.l)
  ::  getMean: sum(sample * count) / observations, then Math.round (half up)
  =/  sum
    %+  roll  ~(tap by h)
    |=([[k=@ud v=@ud] a=@ud] (add a (mul k v)))
  =/  mean  (div (add (mul 2 sum) obs) (mul 2 obs))
  ::  getPercentile(.95): pos = (int)(obs * .95), then the first bucket (in
  ::  ascending sample order) at which the running count EXCEEDS pos
  =/  pos  (div (mul obs 95) 100)
  =/  p95
    =/  l=(list @ud)  ks
    =/  cnt=@ud  0
    |-  ^-  @ud
    ?~  l  mx
    =.  cnt  (add cnt (~(gut by h) i.l 0))
    ?:((gth cnt pos) i.l $(l t.l))
  [i.ks mean p95 mx]
::
++  first-violated
  ::  the first invariant (declaration order) violated by `st`; ~ = all hold,
  ::  [%& name] = violated, [%| msg] = an evaluation error during the check
  |=  [ivs=(list [name=@t body=sem:sem-lib]) st=state e=eenv:ne]
  ^-  (unit (each @t @t))
  ?~  ivs  ~
  =/  r  (pred-bool:ne body.i.ivs st ~ e)
  ?:  ?=(%| -.r)  `[%| msg.p.r]
  ?.  p.r  `[%& name.i.ivs]
  $(ivs t.ivs)
::
++  register
  ::  admit one generated state at depth `d`. TLC order: a state pruned by a
  ::  CONSTRAINT (or a transition pruned by an ACTION_CONSTRAINT) is not
  ::  enqueued; a first-seen in-model state is enqueued and checked against the
  ::  invariants in declaration order. `prev` is the predecessor state (~ for an
  ::  initial state), needed to evaluate action constraints. A CONSTRAINT-pruned
  ::  state is not enqueued or counted, but TLC still checks its invariants, so a
  ::  violation on the pruned boundary is reported (R1.5.1).
  |=  [o=bfs-opts cur=bfs-cursor st=state d=@ud pred=@t prev=(unit state)]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  =/  e  (env-of o)
  =/  ch  (con-hold cons.o st e)
  ?:  ?=(%| -.ch)  [`[%error p.ch] cur]
  ?.  p.ch  (check-pruned o cur st pred e)
  ?^  prev
    =/  ah  (acon-hold acons.o u.prev st e)
    ?:  ?=(%| -.ah)  [`[%error p.ah] cur]
    ?.  p.ah  [~ cur]
    (register-in o cur st d pred e)
  (register-in o cur st d pred e)
::
++  check-pruned
  ::  a CONSTRAINT-pruned state: check its invariants (declaration order) but do
  ::  not dedup, count, or enqueue it. A violation ends the run; the trace is the
  ::  predecessor's behavior extended by this state (it is absent from `seen`).
  |=  [o=bfs-opts cur=bfs-cursor st=state pred=@t e=eenv:ne]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  =/  iv  (first-violated invs.o st e)
  ?~  iv  [~ cur]
  ?:  ?=(%| -.u.iv)  [`[%error p.u.iv] cur]
  :_  cur
  :-  ~
  :*  %inv  gen.cur  distinct.cur  (lent queue.cur)  depth.cur
      (weld (trace-to seen.cur pred) ~[st])  p.u.iv  =('' pred)
  ==
::
++  register-in
  ::  the in-model path: dedup, depth bound, enqueue, ordered invariant check
  |=  [o=bfs-opts cur=bfs-cursor st=state d=@ud pred=@t e=eenv:ne]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  ::  the state's identity is its symmetry-orbit representative (7.5); with no
  ::  symmetry group `canon` is `st` and `fp` is the plain FP64 state fingerprint
  =/  ob   (orbit-fp:fp perms.o order.o st)
  =/  fp   (@t fp.ob)   ::  worn @t for the existing @t-keyed seen/queue molds
  =/  cst  canon.ob
  ?:  (~(has by seen.cur) fp)  [~ cur]
  ?:  &(!=(0 maxd.o) (gth d maxd.o))
    [`[%limited %depth gen.cur distinct.cur (lent queue.cur) depth.cur] cur]
  ::  TLC order (doNext): the state is counted distinct and its invariants are
  ::  checked BEFORE it is enqueued, so a violating state is counted but never
  ::  enqueued (fixing the states-left-on-queue count)
  =.  distinct.cur  +(distinct.cur)
  =.  depth.cur     (max depth.cur d)
  =.  seen.cur      (~(put by seen.cur) fp [d pred cst])
  ::  the invariant is checked on the orbit representative (sound for the
  ::  symmetry-invariant predicates TLC requires; identical to `st` when there
  ::  is no symmetry group)
  =/  iv  (first-violated invs.o cst e)
  ?^  iv
    ?:  ?=(%| -.u.iv)  [`[%error p.u.iv] cur]
    :_  cur
    :-  ~
    :*  %inv  gen.cur  distinct.cur  (lent queue.cur)  depth.cur
        (trace-to seen.cur fp)  p.u.iv  =('' pred)
    ==
  =.  queue.cur  (snoc queue.cur fp)
  =?  inits.cur  =('' pred)  (snoc inits.cur fp)
  [~ cur]
::
++  register-all
  |=  [o=bfs-opts cur=bfs-cursor sts=(list state) d=@ud pred=@t prev=(unit state)]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  |-  ^-  [out=(unit outcome) cur=bfs-cursor]
  ?~  sts  [~ cur]
  =/  rr  (register o cur i.sts d pred prev)
  ?^  out.rr  rr
  $(sts t.sts, cur cur.rr)
::
++  bfs-step
  ::  spend up to `budget` work units (one per state registered or
  ::  generated), then return the cursor. The outcome and every count
  ::  are independent of how the search is sliced.
  ::  narrowing note: ?^/?~ test local copies (todo, q), never wings of
  ::  `cur`, so recursing with a fresh wide cursor never nest-fails
  |=  [o=bfs-opts cur=bfs-cursor budget=@ud]
  ^-  bfs-slice
  =/  spent  0
  |-  ^-  bfs-slice
  ?:  (gte spent budget)  [%more cur]
  ::  register pending initial states first (depth 1, no predecessor)
  =/  todo  init-todo.cur
  ?^  todo
    =/  rr  (register o cur(init-todo t.todo) i.todo 1 '' ~)
    ?^  out.rr  [%done u.out.rr cur.rr]
    $(cur cur.rr, spent +(spent))
  ?:  ?&(!=(0 cap.o) (gth distinct.cur cap.o))
    [%done [%limited %states gen.cur distinct.cur (lent queue.cur) depth.cur] cur]
  =/  q  queue.cur
  ?~  q
    [%done [%ok gen.cur distinct.cur 0 depth.cur] cur]
  =/  fp   i.q
  =/  vis  (~(got by seen.cur) fp)
  =/  nr  (next-states:ne st.vis next.o (env-of o))
  ?:  ?=(%| -.nr)  [%done [%error msg.p.nr] cur]
  =/  nexts  p.nr
  ?~  nexts
    ::  a dequeued state with NO successors still contributes a 0 out-degree
    ::  sample: TLC calls outDegree.addSample(unseenSuccessorStates) for every
    ::  state it dequeues, so a sink pulls the distribution's min to 0 (R1.5.12b)
    =.  outdeg.cur  (~(put by outdeg.cur) 0 +((~(gut by outdeg.cur) 0 0)))
    ?.  deadlock.o  $(cur cur(queue t.q), spent +(spent))
    :+  %done
      [%deadlock gen.cur distinct.cur (lent t.q) depth.cur (trace-to seen.cur fp)]
    cur(queue t.q)
  =/  cost  (lent nexts)
  =/  before  distinct.cur
  =/  rr
    (register-all o cur(queue t.q, gen (add gen.cur cost)) nexts +(depth.vis) fp `st.vis)
  ?^  out.rr  [%done u.out.rr cur.rr]
  ::  TLC out-degree sample: the number of newly-distinct successors this state
  ::  produced (Worker.outDegree.addSample of unseenSuccessorStates)
  =/  sample  (sub distinct.cur.rr before)
  =.  outdeg.cur.rr
    (~(put by outdeg.cur.rr) sample +((~(gut by outdeg.cur.rr) sample 0)))
  $(cur cur.rr, spent (add spent cost))
::
++  explore
  ::  deterministic BFS from the initial states; stops at the first
  ::  invariant violation or (unless disabled) deadlock, in BFS order.
  ::  `cap` bounds the distinct-state count (0 = unbounded); exceeding it
  ::  yields %limited with the statistics so far, so a caller can bound a
  ::  single event's work.
  |=  [is=(list state) o=bfs-opts]
  ^-  [out=outcome od=out-degree]
  =/  cur  (bfs-init is)
  |-  ^-  [out=outcome od=out-degree]
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)  [out.r (od-stats outdeg.cur.r)]
  $(cur cur.r)
::
++  explore-cursor
  ::  run the search to completion in `budget`-sized slices and return the final
  ::  cursor, exposing the statistics (max out-degree) the outcome omits. The
  ::  result is independent of `budget` (the slice-boundary resume contract)
  |=  [is=(list state) o=bfs-opts budget=@ud]
  ^-  bfs-cursor
  =/  cur  (bfs-init is)
  |-  ^-  bfs-cursor
  =/  r  (bfs-step o cur budget)
  ?:  ?=(%done -.r)  cur.r
  $(cur cur.r)
::
++  trace-to
  ::  the behavior (list of states, initial first) ending at `fp`
  |=  [seen=(map @t visit) fp=@t]
  ^-  (list state)
  =|  out=(list state)
  |-  ^-  (list state)
  =/  vis  (~(get by seen) fp)
  ?~  vis  out
  =.  out  [st.u.vis out]
  ?:  =('' pred.u.vis)  out
  $(fp pred.u.vis)
::
::  +|  Output (TLC terminal summary + trace)
::
::
++  module-name-of
  |=  tree=node
  ^-  @t
  =/  bm  (skim (kids-of tree) |=(k=node (is-kind k %n-beginmodule)))
  ?~  bm  ''
  =/  ids  (skim (kids-of i.bm) |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~(ids '' (leaf-text i.ids))
::
++  state-pairs
  ::  sorted [var rendered-value] pairs of a state
  |=  st=state
  ^-  (list [@t @t])
  %+  turn  (sort ~(tap by st) |=([a=[k=@t *] b=[k=@t *]] (aor k.a k.b)))
  |=  [k=@t v=value]
  [k (crip (render:ev v))]
::
++  render-state
  ::  variable bindings of a trace state, one `var = value` per line,
  ::  variables in sorted order
  |=  st=state
  ^-  wain
  %+  turn  (state-pairs st)
  |=  [k=@t v=@t]
  (crip "{(trip k)} = {(trip v)}")
::
++  render-trace
  ::  `State N: <label>` blocks; state 1 is the initial predicate, each later
  ::  state is labeled with the specific getActions leaf action that generated
  ::  it from its predecessor (Tool.getActions decomposition, R1.5.4). With no
  ::  action context (`actions` ~) it falls back to the whole-Next label — the
  ::  single-action case renders identically either way.
  |=  $:  trace=(list state)  next-label=@t
          actions=(list [name=@t body=sem:sem-lib])
          e=eenv:ne  order=(list @t)  modn=@t
      ==
  ^-  wain
  =/  i  1
  =/  prev=(unit state)  ~
  %-  zing
  |-  ^-  (list wain)
  ?~  trace  ~
  =/  label=@t
    ?~  prev  '<Initial predicate>'
    ?~  actions  next-label
    (edge-action-label u.prev (@t (state-fp:fp order i.trace)) actions e order modn)
  :_  $(trace t.trace, i +(i), prev `i.trace)
  ;:  weld
    ~[(crip "State {(a-tape i)}: {(trip label)}")]
    (render-state i.trace)
    ~['']
  ==
::
++  a-co
  |=(n=@ud (crip (a-tape n)))
::
++  a-tape
  |=  n=@ud
  ^-  tape
  ?:  =(0 n)  "0"
  =|  o=tape
  |-  ^-  tape
  ?:  =(0 n)  o
  $(n (div n 10), o [(add '0' (mod n 10)) o])
::
++  counts-lines
  |=  [gen=@ud distinct=@ud queued=@ud depth=@ud]
  ^-  wain
  :~  (crip "{(a-tape gen)} states generated, {(a-tape distinct)} distinct states found, {(a-tape queued)} states left on queue.")
      (crip "The depth of the complete state graph search is {(a-tape depth)}.")
  ==
::
++  next-span-label
  ::  `<Next line BL, col BC to line EL, col EC of module M>`
  |=  [next-body=node modn=@t]
  ^-  @t
  =/  sp  (span-of:ast next-body)
  ?~  sp  '<Next>'
  =*  s  u.sp
  %-  crip
  ;:  weld
    "<Next line "  (a-tape line.from.s)  ", col "  (a-tape col.from.s)
    " to line "  (a-tape line.to.s)  ", col "  (a-tape col.to.s)
    " of module "  (trip modn)  ">"
  ==
::
::  +|  Liveness (temporal properties, no fairness)
::
::
+$  graph  [seen=(map @t visit) inits=(list @t) gen=@ud distinct=@ud depth=@ud]
::
++  build-graph
  ::  the complete reachability graph via deterministic BFS (no early
  ::  stop), with per-state depth and predecessor for trace reconstruction
  |=  [is=(list state) o=bfs-opts]
  ^-  graph
  =/  cur  (bfs-init is)
  |-  ^-  graph
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)
    [seen.cur.r inits.cur.r gen.cur.r distinct.cur.r depth.cur.r]
  $(cur cur.r)
::
++  live-graph-cap
  ::  the distinct-state safety bound for a temporal graph build (R1.5.5). The
  ::  liveness path builds the WHOLE reachability graph before searching for a
  ::  lasso, so an unbounded build hangs on a large/looping state space; a build
  ::  reaching this many distinct states stops and yields %limited (TLC's own
  ::  liveness is unbounded, so a spec past the bound is a documented divergence,
  ::  not a hang). Small temporal specs are far below it and are unaffected.
  ^~  100.000
::
++  build-graph-cap
  ::  +build-graph that also reports whether the distinct-state `cap` (o.cap,
  ::  0 = unbounded) was reached (R1.5.5). A capped liveness build yields
  ::  %limited rather than a verdict on a partial graph, and never hangs.
  |=  [is=(list state) o=bfs-opts]
  ^-  [g=graph capped=?]
  =/  cur  (bfs-init is)
  |-  ^-  [g=graph capped=?]
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)
    :-  [seen.cur.r inits.cur.r gen.cur.r distinct.cur.r depth.cur.r]
    ?=(%limited -.out.r)
  $(cur cur.r)
::
::  +|  Seeded Simulation (bounded, reproducible, resumable)
::
::
+$  sim-result
  $:  traces=@ud       ::  behaviors generated (numOfGenTraces)
      steps=@ud        ::  state transitions taken
      gen=@ud          ::  states generated (|inits| + successors, 9.3b)
      mean=@ud         ::  trace-length mean over completed behaviors (Welford)
      var=@ud          ::  Var(X) = round(m2 / (traces + 1))
      sd=@ud           ::  round(sqrt(m2 / (traces + 1)))
      ::  the first violating behavior, if any: an invariant broken on a
      ::  successor, or a temporal PROPERTY broken by a completed behavior
      viol=(unit [kind=?(%invariant %property) name=@t path=(list state)])
  ==
::  fixed parameters of one simulation run (built once from search-ctx). The
::  successor generation is the unit-7 semantic path (node-eval), and the RNG is
::  java.util.Random (lib/rng), so a run reproduces `tlc2.TLC -simulate`.
::  the env is NOT stored built: eenv carries the override registry `ov`, whose
::  op-impls are gates, and a kont round-trip clams them to bunt gates (a core
::  cannot survive `;;`). Like bfs-opts, carry defs/consts/vars and rebuild the
::  env per event (sim-step), so the registry is always freshly constructed.
+$  sim-opts
  $:  actions=(list [name=@t body=sem:sem-lib])  ::  getActions, source order
      invs=(list [name=@t body=sem:sem-lib])     ::  invariants, decl order
      oss=(list oos:tp)          ::  normalized temporal PROPERTY (~ none; 9.3a)
      pname=@t                   ::  PROPERTY name (for the temporal verdict)
      defs=(map @t sem-def:sem-lib)              ::  operator definitions
      consts=(map @t value)                      ::  CONSTANT assignments
      vars=(set @t)                              ::  VARIABLE names
      order=(list @t)            ::  vars in declaration order (fingerprints)
      num=@ud     ::  behaviors to simulate
      depth=@ud   ::  transitions per behavior
  ==
::  everything required to resume a run byte-identically: the RNG is the raw
::  48-bit java.util.Random state (lib/rng), advanced only at step boundaries,
::  so slicing never changes a draw
+$  sim-cursor
  $:  s=@                    ::  localRng state
      inits=(list state)
      t=@ud                  ::  behaviors completed
      steps=@ud
      maxn=@ud               ::  deepest transition index reached
      gen=@ud                ::  states generated so far (9.3b)
      tm=@s                  ::  Welford running mean of completed trace lengths
      tm2=@s                 ::  Welford running M2
      walk=(unit [cur=state n=@ud path=(list state)])
  ==
+$  sim-slice
  $%  [%more cur=sim-cursor]
      [%done res=sim-result cur=sim-cursor]
  ==
::
++  nth-state
  ::  index into a state list; the dry sample widens a ?~-narrowed list
  ::  past the wet +snag (the recursive value mold otherwise mull-grows)
  |=  [i=@ud l=(list state)]
  ^-  state
  (snag i l)
::
++  nth-action
  ::  index into an action list (dry, same recursive-mold reason as +nth-state)
  |=  [i=@ud l=(list [name=@t body=sem:sem-lib])]
  ^-  sem:sem-lib
  body:(snag i l)
::
++  sim-nexts
  ::  SimulationWorker.getNextStates for one action: the complete successor list
  ::  in generation order. A successor that violates an invariant ends the run
  ::  (addElement throws before it is added, in generation order), so it is
  ::  returned as %viol carrying that (final) state.
  |=  $:  cur=state  body=sem:sem-lib
          invs=(list [name=@t body=sem:sem-lib])  e=eenv:ne
      ==
  ^-  $%([%viol name=@t st=state] [%ok nx=(list state)])
  =/  nr  (next-states:ne cur body e)
  ?:  ?=(%| -.nr)  [%ok ~]
  =/  gen  p.nr
  =|  keep=(list state)
  |-  ^-  $%([%viol name=@t st=state] [%ok nx=(list state)])
  ?~  gen  [%ok (flop keep)]
  =/  fv  (first-violated invs i.gen e)
  ?^  fv  [%viol ?-(-.u.fv %& p.u.fv, %| p.u.fv) i.gen]
  $(gen t.gen, keep [i.gen keep])
::
++  welford-add
  ::  fold one completed behavior of length `tl` into the running mean/m2 with
  ::  the online integer algorithm tlc2 SimulationWorkerStatistics uses; `k` is
  ::  the 1-based behavior count (numOfGenTraces at collectPostTrace).
  |=  [tm=@s tm2=@s tl=@ud k=@ud]
  ^-  [@s @s]
  =/  tls    (sun:si tl)
  =/  delta  (dif:si tls tm)
  =/  ntm    (sum:si tm (fra:si delta (sun:si k)))
  =/  ntm2   (sum:si tm2 (pro:si delta (dif:si tls ntm)))
  [ntm ntm2]
::
++  mk-result
  ::  finalize the run statistics. `gt` is the reported behavior count
  ::  (numOfGenTraces): completed behaviors, plus the current one when it
  ::  violated (a violating behavior is counted but excluded from the Welford
  ::  trace-length stats, as collectPostTrace runs only on a clean behavior).
  ::  Var(X) and SD use TLC's `genTrace + 1` div-by-zero guard.
  |=  $:  gt=@ud  cur=sim-cursor
          viol=(unit [kind=?(%invariant %property) name=@t path=(list state)])
      ==
  ^-  sim-result
  =/  m2   (abs:si tm2.cur)
  =/  d    +(gt)
  =/  var  (div (add (mul 2 m2) d) (mul 2 d))       ::  round(m2 / d)
  =/  sd
    =/  x  (div:rd (sun:rd m2) (sun:rd d))
    (abs:si (need (toi:rd (add:rd (sqt:rd x) .~0.5))))
  [gt steps.cur gen.cur (abs:si tm.cur) var sd viol]
::
++  sim-live-viol
  ::  the completed behavior (chronological) if it breaks the temporal PROPERTY,
  ::  else ~. tlc2 LiveCheck.checkTrace over the trace's stutter graph, via the
  ::  8.2–8.6 engine (+trace-lasso). `path` is newest-first (the walk order).
  |=  [o=sim-opts path=(list state) e=eenv:ne]
  ^-  (unit (list state))
  ?~  oss.o  ~
  =/  chron  (flop path)
  ?~  (trace-lasso:lv oss.o chron e order.o)  ~
  `chron
::
++  sim-step
  ::  spend up to `budget` work units (one per transition or behavior boundary).
  ::  Per step the RNG is drawn as TLC's SimulationWorker: nextDouble for the
  ::  action index, nextPrime for the retry stride, then nextDouble for the
  ::  successor pick. The draw sequence is fixed, so the run is a pure function
  ::  of [opts cursor] regardless of slicing. When a behavior completes (depth
  ::  or deadlock) its trace is checked against the temporal PROPERTY (9.3a).
  |=  [o=sim-opts cur=sim-cursor budget=@ud]
  ^-  sim-slice
  ?:  =(~ inits.cur)  [%done (mk-result 0 cur ~) cur]
  ::  build the node-eval env (with its override registry) once per event; the
  ::  kont stores defs/consts/vars, never the built env (see +$ sim-opts)
  =/  e  (make-env:ne defs.o consts.o vars.o)
  =/  spent  0
  |-  ^-  sim-slice
  ?:  (gte spent budget)  [%more cur]
  ?:  =(num.o t.cur)  [%done (mk-result t.cur cur ~) cur]
  =/  mw  walk.cur
  ?~  mw
    ::  a) start a behavior at a random initial state (TLC checks invariants
    ::  only on successors in simulation, never on the initial state)
    =^  i0  s.cur  (floor-scaled:rng s.cur (lent inits.cur))
    =/  start  (nth-state i0 inits.cur)
    $(walk.cur `[start 0 ~[start]], spent +(spent))
  =/  w  u.mw
  ?:  =(n.w depth.o)
    ::  behavior reached full depth: check the temporal property, then fold its
    ::  length into the Welford trace-length stats and start the next behavior
    =/  lv  (sim-live-viol o path.w e)
    ?^  lv
      [%done (mk-result +(t.cur) cur `[%property pname.o u.lv]) cur]
    =/  wf  (welford-add tm.cur tm2.cur (min depth.o (lent path.w)) +(t.cur))
    $(walk.cur ~, t.cur +(t.cur), tm.cur -.wf, tm2.cur +.wf, spent +(spent))
  =/  alen  (lent actions.o)
  ?:  =(0 alen)
    =/  lv  (sim-live-viol o path.w e)
    ?^  lv
      [%done (mk-result +(t.cur) cur `[%property pname.o u.lv]) cur]
    =/  wf  (welford-add tm.cur tm2.cur (min depth.o (lent path.w)) +(t.cur))
    $(walk.cur ~, t.cur +(t.cur), tm.cur -.wf, tm2.cur +.wf, spent +(spent))
  ::  b) pick an action and the retry stride prime, then walk actions from that
  ::  index until one yields successors ((index + p) % alen per retry)
  =^  index  s.cur  (floor-scaled:rng s.cur alen)
  =^  p      s.cur  (next-prime:rng s.cur)
  =/  found
    =/  tries  0
    |-  ^-  $%([%viol name=@t st=state] [%ok nx=(list state)] [%none ~])
    ?:  =(tries alen)  [%none ~]
    =/  r  (sim-nexts cur.w (nth-action index actions.o) invs.o e)
    ?:  ?=(%viol -.r)  r
    ?^  nx.r  r
    $(tries +(tries), index (mod (add index p) alen))
  ?:  ?=(%none -.found)
    ::  deadlock: no action produced a successor; check the property, fold the
    ::  behavior length, and start the next behavior
    =/  lv  (sim-live-viol o path.w e)
    ?^  lv
      [%done (mk-result +(t.cur) cur `[%property pname.o u.lv]) cur]
    =/  wf  (welford-add tm.cur tm2.cur (min depth.o (lent path.w)) +(t.cur))
    $(walk.cur ~, t.cur +(t.cur), tm.cur -.wf, tm2.cur +.wf, spent +(spent))
  ?:  ?=(%viol -.found)
    ::  an invariant violation ends the run with the offending behavior
    :+  %done
      (mk-result +(t.cur) cur `[%invariant name.found (flop [st.found path.w])])
    cur
  ::  d) pick one successor and make it the current state; every successor the
  ::  chosen action generated counts toward states-generated (collectPre)
  =^  j  s.cur  (floor-scaled:rng s.cur (lent nx.found))
  =/  s1  (nth-state j nx.found)
  %=  $
    spent      +(spent)
    gen.cur    (add gen.cur (lent nx.found))
    walk.cur   `[s1 +(n.w) [s1 path.w]]
    steps.cur  +(steps.cur)
    maxn.cur   (max maxn.cur +(n.w))
  ==
::
++  sim-cursor-init
  ::  a fresh simulation cursor. Single-worker Simulator seeds the worker RNG
  ::  from one nextLong of the user-seeded generator, then the worker scrambles
  ::  it (new RandomGenerator(workerSeed)); that scrambled value is the state.
  |=  [inits=(list state) seed=@]
  ^-  sim-cursor
  =/  wseed  -:(next-long:rng (scramble:rng seed))
  ::  states generated counts the initial states first (tlc2 getInitStates)
  [(scramble:rng wseed) inits 0 0 0 (lent inits) --0 --0 ~]
::
++  simulate
  ::  bounded seeded simulation: up to `num` random behaviors, each up to
  ::  `depth` transitions, byte-identical to `tlc2.TLC -simulate -workers 1`.
  |=  [o=sim-opts inits=(list state) seed=@]
  ^-  sim-result
  =/  cur  (sim-cursor-init inits seed)
  |-  ^-  sim-result
  =/  r  (sim-step o cur 1.024)
  ?:  ?=(%done -.r)  res.r
  $(cur cur.r)
::
++  simulate-spec
  ::  run a bounded seeded simulation from spec + config source, returning a
  ::  structured summary (traces / steps / whether a violation was found)
  |=  [spec=@t cfg=@t seed=@ traces=@ud depth=@ud]
  ^-  sim-result
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [0 0 0 0 0 0 ~]
  =*  c  p.sc
  =/  actions  (get-actions nsb.c 'Next' defs.c)
  =/  pname  ?~(pp.c '' u.pp.c)
  =/  o=sim-opts
    [actions invs.c oss.c pname defs.c consts.c vars.c order.c traces depth]
  (simulate o is.c seed)
::
++  sem-body
  ::  the semantic body of the operator definition named `nm`
  |=  [defs=(map @t sem-def:sem-lib) nm=@t]
  ^-  (unit sem:sem-lib)
  =/  d  (~(get by defs) nm)
  ?~(d ~ body.u.d)
::
++  resolve-bodies
  ::  the sem bodies of a name list (unresolvable names dropped)
  |=  [defs=(map @t sem-def:sem-lib) nms=(list @t)]
  ^-  (list sem:sem-lib)
  %+  murn  nms
  |=(nm=@t (sem-body defs nm))
::
++  resolve-invs
  ::  named invariants paired with their sem bodies, in declaration order
  |=  [defs=(map @t sem-def:sem-lib) nms=(list @t)]
  ^-  (list [name=@t body=sem:sem-lib])
  %+  murn  nms
  |=  nm=@t
  ^-  (unit [name=@t body=sem:sem-lib])
  =/  b  (sem-body defs nm)
  ?~(b ~ `[nm u.b])
::
::  the shared WU6.9 search context: everything the safety/liveness engines
::  need, resolved from the semantic graph, with the initial states solved
+$  sctx
  $:  is=(list state)                       ::  solved initial states
      defs=(map @t sem-def:sem-lib)
      consts=(map @t value)
      vars=(set @t)
      order=(list @t)                        ::  vars in declaration order
      perms=(list (map @t @t))               ::  symmetry group (SYMMETRY)
      asmz=(list sem-thm:sem-lib)            ::  module ASSUME bodies
      nsb=sem:sem-lib                        ::  Next body
      invs=(list [name=@t body=sem:sem-lib])  ::  invariants (declaration order)
      cons=(list sem:sem-lib)                 ::  state constraints
      acons=(list sem:sem-lib)                ::  action constraints
      ddl=?                                   ::  check deadlock (cfg flag)
      pp=(unit @t)                           ::  property name (liveness)
      fair=(list sem:sem-lib)                ::  fairness conjuncts (WF_/SF_/
                                             ::  []temporal) from a SPECIFICATION
                                             ::  decomposition (SpecProcessor
                                             ::  getTemporals); empty in
                                             ::  INIT/NEXT mode (unit 5.3c/8.1)
      tree=node
      nl=@t                                  ::  Next span label
      oss=(list oos:tp)                      ::  the normalized temporal
                                             ::  decomposition (unit 8.1), built
                                             ::  from the PROPERTY + fairness via
                                             ::  temporal.hoon; carried for the
                                             ::  8.2 tableau/product to consume
  ==
::
++  sem-lvl
  ::  the level of an IR node (apply/letin/atref carry it; a literal is
  ::  constant-level, nullodn has none)
  |=  s=sem:sem-lib
  ^-  @ud
  ?-  -.s
    %apply    lvl.s
    %letin    lvl.s
    %atref    lvl.s
    %lit      0
    %nullodn  0
  ==
::
++  weld-sem
  ::  hand-rolled weld over the recursive `sem` mold (wet weld fuse-loops it)
  |=  [a=(list sem:sem-lib) b=(list sem:sem-lib)]
  ^-  (list sem:sem-lib)
  ?~  a  b
  [i.a $(a t.a)]
::
++  rev-sem
  ::  hand-rolled reverse over the recursive `sem` mold (wet flop fuse-loops it)
  |=  l=(list sem:sem-lib)
  ^-  (list sem:sem-lib)
  =|  acc=(list sem:sem-lib)
  |-  ^-  (list sem:sem-lib)
  ?~  l  acc
  $(l t.l, acc [i.l acc])
::
++  max-lvl
  ::  hand-rolled max level over IR nodes (wet roll fuse-loops the mold)
  |=  l=(list sem:sem-lib)
  ^-  @ud
  =|  m=@ud
  |-  ^-  @ud
  ?~  l  m
  $(l t.l, m (max m (sem-lvl i.l)))
::
++  resolve-ref
  ::  resolve an arity-0 user-operator reference to its body; leave any other
  ::  node unchanged (TLC's nextPred wraps the `Next` reference and getNextStates
  ::  expands it — our solver takes the resolved body)
  |=  [s=sem:sem-lib defs=(map @t sem-def:sem-lib)]
  ^-  (unit sem:sem-lib)
  ?.  ?=(%apply -.s)  `s
  ?.  &(?=(%user-op kind.op.s) =(~ args.s))  `s
  =/  d  (~(get by defs) name.op.s)
  ?~  d  ~
  body.u.d
::
++  conjoin-inits
  ::  the initial predicate is the conjunction of the SPECIFICATION's
  ::  init conjuncts (TLC's initPredVec); a single conjunct passes through
  |=  [l=(list sem:sem-lib) sp=(unit span)]
  ^-  (unit sem:sem-lib)
  ?~  l  ~
  ?~  t.l  `i.l
  `[%apply ['$ConjList' %builtin] (max-lvl l) sp ~ ~ l]
::
++  decompose-spec
  ::  port of SpecProcessor.processConfigSpec: structurally decompose a
  ::  SPECIFICATION body into its init conjuncts, its next-state action, and
  ::  its fairness/temporal conjuncts. A worklist (never `turn`/`roll` over the
  ::  recursive `sem` mold) processes conjuncts depth-first in source order.
  ::  Out of scope for the corpus and deferred: INSTANCE substitution, LazyValue
  ::  parameter inlining, the subscript-variable-coverage warning.
  |=  [body=sem:sem-lib defs=(map @t sem-def:sem-lib)]
  ^-  $:  inits=(list sem:sem-lib)
          next=(unit sem:sem-lib)
          fair=(list sem:sem-lib)
          err=(unit @t)
      ==
  =/  work=(list sem:sem-lib)  ~[body]
  =|  inits=(list sem:sem-lib)
  =|  fair=(list sem:sem-lib)
  =/  next=(unit sem:sem-lib)  ~
  |-  ^-  [(list sem:sem-lib) (unit sem:sem-lib) (list sem:sem-lib) (unit @t)]
  ?~  work  [(rev-sem inits) next (rev-sem fair) ~]
  =/  p     i.work
  =/  rest  t.work
  ?.  ?=(%apply -.p)
    ?:  ?=(%letin -.p)
      ?~  body.p  $(work rest)
      $(work [u.body.p rest])
    ::  a literal/atref conjunct: route by level
    =/  l  (sem-lvl p)
    ?:  (lte l 1)  $(work rest, inits [p inits])
    ?:  =(3 l)     $(work rest, fair [p fair])
    [inits next fair `'cannot handle this conjunct in the SPECIFICATION']
  =/  op  name.op.p
  ?:  &(?=(%user-op kind.op.p) =(~ args.p))
    ::  arity-0 user operator: expand its body (init if state-level, else recurse)
    =/  d  (~(get by defs) op)
    ?~  d  $(work rest)
    ?~  body.u.d  $(work rest)
    ?:  =(1 (sem-lvl u.body.u.d))
      $(work rest, inits [u.body.u.d inits])
    $(work [u.body.u.d rest])
  ?:  |(=(op '$ConjList') =(op '\\land'))
    $(work (weld-sem args.p rest))
  ?:  =(op '$Nop')
    ?~  args.p  $(work rest)
    $(work [i.args.p rest])
  ?:  =(op '[]')
    =/  arg  ?~(args.p p i.args.p)
    ?:  &(?=(%apply -.arg) =('$SquareAct' name.op.arg))
      ::  [][A]_v: the next-state relation is A (the first SquareAct argument)
      ?^  next  [inits next fair `'the SPECIFICATION has more than one next-state relation']
      ?~  args.arg  [inits next fair `'malformed [A]_v in the SPECIFICATION']
      $(work rest, next `i.args.arg)
    ?:  (lte (sem-lvl arg) 1)
      [inits next fair `'TLC cannot handle a [] of a state predicate in the SPECIFICATION']
    $(work rest, fair [p fair])
  ::  any other conjunct: route by level
  =/  l  (sem-lvl p)
  ?:  (lte l 1)  $(work rest, inits [p inits])
  ?:  =(3 l)     $(work rest, fair [p fair])
  [inits next fair `'cannot handle this conjunct in the SPECIFICATION']
::
++  resolve-targets
  ::  resolve the Init body, Next body, fairness conjuncts, and the Next
  ::  operator name from either INIT/NEXT config keys or a SPECIFICATION
  |=  [ca=cfg-ast:config defs=(map @t sem-def:sem-lib)]
  ^-  (each [init=sem:sem-lib next=sem:sem-lib fair=(list sem:sem-lib) nname=(unit @t)] @t)
  =/  in  init.ca
  =/  nx  next.ca
  ?:  &(?=(^ in) ?=(^ nx))
    =/  isb  (sem-body defs u.in)
    =/  nsb  (sem-body defs u.nx)
    ?~  isb  [%| 'no Init definition']
    ?~  nsb  [%| 'no Next definition']
    [%& u.isb u.nsb ~ `u.nx]
  ?~  spec.ca  [%| 'no INIT/NEXT or SPECIFICATION in config']
  =/  sb  (sem-body defs u.spec.ca)
  ?~  sb  [%| 'no specification definition']
  =/  d  (decompose-spec u.sb defs)
  ?^  err.d  [%| u.err.d]
  ?~  next.d  [%| 'the SPECIFICATION has no next-state relation']
  =/  isb  (conjoin-inits inits.d (sem-span:config u.sb))
  ?~  isb  [%| 'the SPECIFICATION has no initial predicate']
  =/  nsb  (resolve-ref u.next.d defs)
  ?~  nsb  [%| 'the next-state relation is undefined']
  ::  the Next span label uses the operator name when the action is a
  ::  user-op reference (as in [][Next]_v)
  =/  nname=(unit @t)
    =/  n  u.next.d
    ?:(&(?=(%apply -.n) ?=(%user-op kind.op.n)) `name.op.n ~)
  [%& u.isb u.nsb fair.d nname]
::
++  search-ctx
  ::  parse, generate the WU3 graph, resolve config targets, solve the
  ::  initial states; a typed failure short-circuits with a message line
  |=  [spec=@t cfg=@t]
  ^-  (each sctx @t)
  =/  pr  (parse:syntax spec)
  ?:  ?=(%| -.pr)  [%| 'parse error']
  =/  tree  p.pr
  =/  vars  (var-names tree)
  =/  order  (var-order tree)
  =/  cr  (parse-cfg:config cfg)
  ?:  ?=(%| -.cr)  [%| 'config error']
  =/  ca  p.cr
  =/  pp  ?~(properties.ca ~ `i.properties.ca)
  =/  modn  (module-name-of tree)
  =/  mo  (generate:sem-lib modn (malt ~[[modn spec]]))
  ?~  mo  [%| 'semantic error']
  =/  defs  (defmap-of:ne u.mo)
  ::  resolve Init/Next (and fairness) from INIT/NEXT keys or a SPECIFICATION
  =/  rt  (resolve-targets ca defs)
  ?:  ?=(%| -.rt)  [%| p.rt]
  =/  isb   init.p.rt
  =/  nsb   next.p.rt
  =/  fair  fair.p.rt
  =/  consts  (const-map cfg)
  =/  nb  ?~(nname.p.rt ~ (body-of-def tree u.nname.p.rt))
  ::  symmetry with a temporal property: TLC warns (2279) and continues on the
  ::  symmetry-reduced graph. The port cannot yet run liveness on that spec class
  ::  (model-value \E init/actions error "variable unassigned"), so we type-reject
  ::  with the pinned 2279 warning text — a tested approved-difference (unit 8.7.2;
  ::  full warn-and-continue awaits liveness-under-model-values engine support).
  ::  Keyed on the SYMMETRY declaration (as TLC's warning is) and placed before
  ::  symmetry-perms/init-states, which error first on such a spec.
  ?:  &(?=(^ symmetry.ca) ?=(^ pp))
    :-  %|
    %^    cat  3
        'Declaring symmetry during liveness checking is dangerous. '
      %^  cat  3
        'It might cause TLC to miss violations of the stated liveness properties. '
      'Please check liveness without symmetry defined.'
  =/  pr  (symmetry-perms defs consts vars symmetry.ca)
  ?:  ?=(%| -.pr)  [%| p.pr]
  =/  perms  p.pr
  =/  ir  (init-states:ne isb (make-env:ne defs consts vars))
  ?:  ?=(%| -.ir)  [%| msg.p.ir]
  =/  invs   (resolve-invs defs invariants.ca)
  =/  cons   (resolve-bodies defs constraints.ca)
  =/  acons  (resolve-bodies defs action-constraints.ca)
  =/  ddl    !=(%false deadlock.ca)
  ::  build the normalized temporal decomposition for a liveness run (unit
  ::  8.1.4): the production setup now derives the oos via temporal.hoon rather
  ::  than the CST — the verdict still comes from the first-increment recognizer
  ::  (unit 8.5 retires that). Empty for a pure-safety run; a non-boolean
  ::  constant leaf is a typed rejection (unit 8.1.5).
  =/  or  ?~(pp `(each (list oos:tp) aerr:tp)`[%& ~] (build-live-oss ca defs consts vars fair))
  ?:  ?=(%| -.or)  [%| msg.p.or]
  :-  %&
  :*  p.ir  defs  consts  vars  order  perms  assumes.u.mo  nsb
      invs  cons  acons  ddl  pp  fair  tree
      ?~(nb '' (next-span-label u.nb modn))
      p.or
  ==
::
++  build-live-oss
  ::  the normalized OrderOfSolutions for a spec's PROPERTY list under its
  ::  fairness (unit 8.1); shared by the production setup and the differential.
  ::  A constant leaf is evaluated under the constant env, so a non-boolean is a
  ::  typed rejection (aerr).
  |=  $:  ca=cfg-ast:config
          defs=(map @t sem-def:sem-lib)
          consts=(map @t value)
          vars=(set @t)
          fair=(list sem:sem-lib)
      ==
  ^-  (each (list oos:tp) aerr:tp)
  =/  pbods=(list sem:sem-lib)
    =/  ps  properties.ca
    |-  ^-  (list sem:sem-lib)
    ?~  ps  ~
    =/  b  (sem-body defs i.ps)
    ?~  b  $(ps t.ps)
    [u.b $(ps t.ps)]
  (oss-of pbods fair (make-env:ne defs consts vars))
::
++  oss-of
  ::  normalize temporal property bodies + fairness conjuncts into the
  ::  OrderOfSolution list (exposes temporal.normalize for the job kernel's
  ::  %liveness setup and the differential's build-live-oss)
  |=  [pbods=(list sem:sem-lib) fair=(list sem:sem-lib) env=eenv:ne]
  ^-  (each (list oos:tp) aerr:tp)
  (normalize:tp pbods fair env)
::
++  consts-of
  ::  config constant assignments as an evaluation binding map (WU6.9 task 1).
  ::  An arity-0 assignment binds a value directly; `F(a,..) = v` assignments (a
  ::  constant OPERATOR, tlc2's OpRcdValue) are grouped by name into a function
  ::  value applied at the argument (arity 1) or the argument tuple (arity n) —
  ::  see +apply-const in node-eval (R1.5.3).
  |=  cs=(list cfg-const:config)
  ^-  (map @t value)
  =/  built
    =|  vals=(map @t value)
    =|  ops=(map @t (list vpair:vl))
    |-  ^-  [v=(map @t value) o=(map @t (list vpair:vl))]
    ?~  cs  [vals ops]
    ?~  args.i.cs
      $(cs t.cs, vals (~(put by vals) lhs.i.cs val.i.cs))
    =/  dp=value  ?:(=(1 (lent args.i.cs)) i.args.i.cs [%seq args.i.cs])
    =/  ex  (~(gut by ops) lhs.i.cs *(list vpair:vl))
    $(cs t.cs, ops (~(put by ops) lhs.i.cs (snoc ex [dp val.i.cs])))
  =/  vals  v.built
  =/  os  ~(tap by o.built)
  |-  ^-  (map @t value)
  ?~  os  vals
  $(os t.os, vals (~(put by vals) p.i.os [%fcn q.i.os]))
::
++  const-map
  |=  cfg=@t
  ^-  (map @t value)
  =/  pr  (parse-cfg:config cfg)
  ?:(?=(%| -.pr) ~ (consts-of constants.p.pr))
::
++  kind-name
  ::  the tlc2 value class a value corresponds to, the stable kind
  ::  discriminator the oracle projection prints (unit 6C.8)
  |=  x=value
  ^-  tape
  ?-  -.x
    %bool   "BoolValue"
    %int    "IntValue"
    %str    "StringValue"
    %model  "ModelValue"
    %intv   "IntervalValue"
    %set    "SetEnumValue"
    %seq    "TupleValue"
    %rec    "RecordValue"
    %fcn    "FcnRcdValue"
  ==
::
++  kind-of
  ::  the tlc2 value class a definition's result corresponds to. Almost always
  ::  a property of the VALUE, but a recursive function definition is the one
  ::  case where it is a property of the EXPRESSION: tlc2 keeps a
  ::  $RecursiveFcnSpec as a lazy FcnLambdaValue, while the identical function
  ::  written as a plain constructor normalizes to a FcnRcdValue. Measured at
  ::  the pin: `R1[n \in 1..3] == ...` is FcnLambdaValue and renders <<1, 2, 6>>,
  ::  `NR1 == [n \in 1..3 |-> n]` is FcnRcdValue and renders <<1, 2, 3>> — same
  ::  rendering, different class — so the class cannot be read off the value
  |=  [b=sem:sem-lib x=value]
  ^-  tape
  ?:  ?&  ?=(%apply -.b)
          =('$RecursiveFcnSpec' name.op.b)
          ?=(?(%fcn %seq) -.x)
      ==
    "FcnLambdaValue"
  (kind-name x)
::
++  project-defs
  ::  every arity-0 definition of a module, sorted by name and evaluated once
  ::  under the config's constant assignments, in the oracle's projection
  ::  form: "<name> <kind> <canonical value>" or "<name> ! EC<code> <message>".
  ::  Newlines in a diagnostic become spaces, exactly as ModuleOpDump's
  ::  projection collapses them. `skip` names the definitions this port
  ::  deliberately answers differently (unit 6C.8's differential comparator);
  ::  the graph is generated ONCE for the whole case
  |=  [spec=@t cfg=@t skip=(list @t)]
  ^-  (list tape)
  =/  mo  (generate:sem-lib 'A' (malt ~[['A' spec]]))
  ?~  mo  ~["! no semantic graph"]
  =/  defs  (defmap-of:ne u.mo)
  =/  e  (make-env:ne defs (const-map cfg) (vars-of:ne u.mo))
  =/  skipped  (silt skip)
  =/  names
    %+  sort
      %+  murn  defs.u.mo
      |=  d=sem-def:sem-lib
      ^-  (unit @t)
      ?:  |(!=(0 arity.d) (~(has in skipped) name.d))  ~
      ?~(body.d ~ `name.d)
    aor
  %+  turn  names
  |=  nm=@t
  ^-  tape
  =/  d  (~(get by defs) nm)
  ?~  d  :(weld (trip nm) " ! no definition")
  ?~  body.u.d  :(weld (trip nm) " ! no body")
  =/  r  (eval:ne u.body.u.d e)
  ?:  ?=(%& -.r)
    :(weld (trip nm) " " (kind-of u.body.u.d p.r) " " (render:vl p.r))
  ;:  weld
    (trip nm)  " ! EC"  (a-co:co code.p.r)  " "  (flat-msg msg.p.r)
  ==
::
++  flat-msg
  ::  a diagnostic on one line, as the oracle projection prints it
  |=  m=@t
  ^-  tape
  (turn (trip m) |=(c=@tD ?:(=(c 10) ' ' c)))
::
++  check-assumes
  ::  TLC Tool.checkAssumptions, run before the search: every module ASSUME
  ::  must evaluate to TRUE under the constant environment. A FALSE assumption
  ::  is EC 2104 (assumption-false); a non-boolean value or evaluation error is
  ::  EC 2105 (assumption-error). ~ when all assumptions hold.
  ::  An AXIOM-marked assumption is SKIPPED, exactly as tlc2 does
  ::  (`(!isAxiom[i]) && !isValidAssumption(...)`, Tool.java:3651): SANY sets
  ::  isAxiom only when the source keyword image is literally `AXIOM`
  ::  (AssumeNode.java:65), so `ASSUME`/`ASSUMPTION` are still checked and a
  ::  false AXIOM does not fail the run. R1.5.13
  |=  [asmz=(list sem-thm:sem-lib) e=eenv:ne]
  ^-  (unit [ec=@ud msg=@t])
  ?~  asmz  ~
  ?:  axiom.i.asmz  $(asmz t.asmz)
  ?~  body.i.asmz  $(asmz t.asmz)
  =/  r  (pred-bool:ne u.body.i.asmz ~ ~ e)
  ?:  ?=(%| -.r)  `[2.105 (cat 3 'Evaluating an assumption failed: ' msg.p.r)]
  ?.  p.r  `[2.104 'An assumption is false.']
  $(asmz t.asmz)
::
++  live-struct
  ::  the temporal-normalization count projection (unit 8.1) for a spec+cfg,
  ::  matching LivenessStruct's OOS/promises/checkState/checkAction/pems counts
  ::  (the TABLEAU node count is unit 8.2). Resolves the PROPERTY bodies and the
  ::  SPECIFICATION fairness conjuncts, then runs temporal.hoon's normalize.
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  ~[(cat 3 'Error: ' p.sc)]
  (render-counts:tp oss.p.sc)
::
++  live-tabs
  ::  the tableau node count (unit 8.2) for each OrderOfSolution, in order —
  ::  0 when the OOS has no tableau formula (hand-rolled; a wet turn over the
  ::  oos list fuse-loops the recursive live-expr it carries)
  |=  oss=(list oos:tp)
  ^-  (list @ud)
  ?~  oss  ~
  [(tableau-size:tb tf.i.oss) $(oss t.oss)]
::
++  live-struct-full
  ::  the full structural projection (unit 8.2): the LivenessStruct output
  ::  including the TABLEAU node count, the OrderOfSolution.toString rendering,
  ::  and the counts. Reads the oos the PRODUCTION search context builds (unit
  ::  8.1.4), so this differential exercises the decomposition the liveness path
  ::  carries and the tableau built from it.
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  ~[(cat 3 'Error: ' p.sc)]
  (render-struct:tp oss.p.sc (module-name-of tree.p.sc) (live-tabs oss.p.sc))
::
++  states-of
  ::  the reachable graph's fingerprint -> state map (drops depth/predecessor)
  |=  seen=(map @t visit)
  ^-  (map @t state)
  (~(run by seen) |=(w=visit st.w))
::
++  product-counts
  ::  the behavior-graph product node/init counts (unit 8.3) for each
  ::  OrderOfSolution: build the reachable graph once, then pair it with each
  ::  oos tableau via lib/liveness
  |=  c=sctx
  ^-  (list [nodes=@ud inits=@ud])
  =/  o=bfs-opts  [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | 0 0]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (make-env:ne defs.c consts.c vars.c)
  =/  oss  oss.c
  |-  ^-  (list [nodes=@ud inits=@ud])
  ?~  oss  ~
  :-  (build-product:lv i.oss states inits.g nsb.c env order.c)
  $(oss t.oss)
::
++  render-product
  ::  the PRODUCT projection (unit 8.3): the product node and initial-node
  ::  counts per OrderOfSolution, matching tools/oracle/ProductDump
  |=  counts=(list [nodes=@ud inits=@ud])
  ^-  wain
  =/  hd=@t  (crip "OOS {(scow %ud (lent counts))}")
  =/  body
    =/  i  0
    =|  acc=(list @t)
    |-  ^-  (list @t)
    ?~  counts  (flop acc)
    =/  block=(list @t)
      :~  (crip "--- {(scow %ud i)} ---")
          (crip "NODES {(scow %ud nodes.i.counts)}")
          (crip "INITS {(scow %ud inits.i.counts)}")
      ==
    $(counts t.counts, i +(i), acc (weld (flop block) acc))
  `wain`['PRODUCT' hd body]
::
++  live-product
  ::  the product projection for a spec+cfg via the production search context
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  ~[(cat 3 'Error: ' p.sc)]
  (render-product (product-counts p.sc))
::
++  live-verdict-lines
  ::  the liveness VERDICT/EC projection (unit 8.5) for a spec+cfg — the
  ::  temporal-property verdict via the SCC/acceptance search over the product
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  ~[(cat 3 'Error: ' p.sc)]
  =*  c  p.sc
  =/  o=bfs-opts  [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | 0 0]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (make-env:ne defs.c consts.c vars.c)
  ?:  (live-verdict:lv oss.c states inits.g nsb.c env order.c)
    ~['VERDICT violated-property' 'EC 2116']
  ~['VERDICT ok' 'EC 0']
::
++  live-lasso-lines
  ::  the lasso CLASS/LOOP/TRACE/STATE projection (unit 8.6) for a violated
  ::  spec: the stuttering lasso (an initial state that stutters) or a
  ::  back-to-state lasso (a real cycle returning to an earlier state), with
  ::  per-state action labels from getActions
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  ~[(cat 3 'Error: ' p.sc)]
  =*  c  p.sc
  =/  o=bfs-opts  [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | 0 0]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (make-env:ne defs.c consts.c vars.c)
  =/  l  (find-lasso:lv oss.c states inits.g nsb.c env order.c)
  ?~  l  ~['(no lasso)']
  =/  modn     (module-name-of tree.c)
  =/  actions  (get-actions nsb.c 'Next' defs.c)
  =/  np    (lent prefix.u.l)
  =/  stut  =(%stuttering class.u.l)
  =/  marker-num    ?:(stut +(np) loop.u.l)
  ::  the prefix states: state 1 is the initial predicate, each later state is
  ::  labeled with the action that generated it
  =/  prefix-lines=wain
    =/  i  1
    =/  prev=(unit @t)  ~
    =/  ps  prefix.u.l
    |-  ^-  wain
    ?~  ps  ~
    =/  st  (~(got by states) i.ps)
    =/  label=@t
      ?~  prev  'LABEL <Initial predicate>'
      %-  crip
      %+  weld  "LABEL "
      (trip (edge-action-label (~(got by states) u.prev) i.ps actions env order.c modn))
    %+  weld
      ;:  weld
        ~[(crip "STATE {(scow %ud i)} {(fp-hex i.ps)}")]
        ~[label]
        (render-state st)
        ~['ENDSTATE']
      ==
    $(ps t.ps, i +(i), prev `i.ps)
  =/  marker=wain
    :~  (crip "STATE {(scow %ud marker-num)} -1")
        ?:(stut 'LABEL Stuttering' 'LABEL Back to state')
        'ENDSTATE'
    ==
  =/  header=wain
    :~  'LIVENESS'
        'VERDICT violated-property'
        'EC 2116'
        (crip "STAT generated {(scow %ud gen.g)}")
        (crip "STAT distinct {(scow %ud distinct.g)}")
        'STAT queue 0'
        (crip "STAT depth {(scow %ud depth.g)}")
    ==
  ;:  weld
    header
    :~  (crip "CLASS {(trip class.u.l)}")
        (crip "LOOP {(scow %ud loop.u.l)}")
        (crip "TRACE {(scow %ud +(np))}")
    ==
    prefix-lines
    marker
  ==
::
++  live-report
  ::  the TLC console diagnostic for a temporal run from an ALREADY-BUILT graph
  ::  (unit 8.8.1): shared by the `live-message-lines` differential and the job
  ::  kernel's %liveness stage. Returns the lasso (for the typed result/trace)
  ::  and the console `wain`. The whole-graph find-lasso; the job kernel instead
  ::  builds the lasso via the sliced product cursor and calls +live-render.
  |=  $:  oss=(list oos:tp)  states=(map @t state:ne)  inits=(list @t)
          nsb=sem:sem-lib  env=eenv:ne  order=(list @t)  modn=@t
          defs=(map @t sem-def:sem-lib)  pname=@t
          gen=@ud  distinct=@ud  depth=@ud
      ==
  ^-  [lasso=(unit lasso:lv) report=wain]
  =/  l  (find-lasso:lv oss states inits nsb env order)
  :-  l
  %-  live-render
  :*  l  states  nsb  env  order  modn  defs  pname  gen  distinct  depth  ==
::
++  live-render
  ::  render the console diagnostic from a resolved lasso (unit 8.8.2a): shared
  ::  by +live-report and the job kernel's sliced %check phase. `Model checking
  ::  completed…` for a pass (l is ~), else the `Temporal property … was
  ::  violated.` counter-example (numbered `State N:` trace with getActions
  ::  labels, `Stuttering` / `Back to state N:` closer, and the counts).
  |=  $:  l=(unit lasso:lv)  states=(map @t state:ne)
          nsb=sem:sem-lib  env=eenv:ne  order=(list @t)  modn=@t
          defs=(map @t sem-def:sem-lib)  pname=@t
          gen=@ud  distinct=@ud  depth=@ud
      ==
  ^-  wain
  =/  footer  (counts-lines gen distinct 0 depth)
  ?~  l
    ['Model checking completed. No error has been found.' footer]
  =/  actions  (get-actions nsb 'Next' defs)
  =/  np       (lent prefix.u.l)
  =/  stut     =(%stuttering class.u.l)
  ::  the numbered prefix states: state 1 is the initial predicate, each later
  ::  state is labeled with the action that generated it (no fingerprint line)
  =/  body=wain
    =/  i  1
    =/  prev=(unit @t)  ~
    =/  ps  prefix.u.l
    |-  ^-  wain
    ?~  ps  ~
    =/  st  (~(got by states) i.ps)
    =/  label=@t
      ?~  prev  '<Initial predicate>'
      (edge-action-label (~(got by states) u.prev) i.ps actions env order modn)
    %+  weld
      ;:  weld
        ~[(crip "State {(a-tape i)}: {(trip label)}")]
        (render-state st)
      ==
    $(ps t.ps, i +(i), prev `i.ps)
  ::  the closer: a stuttering self-loop is a new numbered `State`, a
  ::  back-to-state cycle is `Back to state <loop>: <action reaching it>`
  =/  closer=wain
    ?:  stut
      ~[(crip "State {(a-tape +(np))}: Stuttering")]
    =/  last-fp   (rear prefix.u.l)
    =/  loop-fp   (snag (dec loop.u.l) prefix.u.l)
    =/  label
      (edge-action-label (~(got by states) last-fp) loop-fp actions env order modn)
    ~[(crip "Back to state {(a-tape loop.u.l)}: {(trip label)}")]
  ;:  weld
    ~[(crip "Error: Temporal property {(trip pname)} was violated.")]
    ~['Error: The following behavior constitutes a counter-example:']
    body
    closer
    footer
  ==
::
++  live-message-lines
  ::  the TLC console diagnostic for a temporal violation (unit 8.7.1), rendered
  ::  from the 8.2–8.6 liveness engine's lasso — a thin differential wrapper over
  ::  `+live-report` (which the job kernel also uses, unit 8.8.1).
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  ~[(cat 3 'Error: ' p.sc)]
  =*  c  p.sc
  =/  o=bfs-opts  [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | 0 0]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (make-env:ne defs.c consts.c vars.c)
  =/  modn    (module-name-of tree.c)
  =/  pname   ?~(pp.c '' u.pp.c)
  =/  r
    %-  live-report
    :*  oss.c  states  inits.g  nsb.c  env  order.c  modn  defs.c  pname
        gen.g  distinct.g  depth.g
    ==
  report.r
::
++  get-actions
  ::  Tool.getActions: decompose a next-state relation into named leaf actions.
  ::  A user-op reference recurses into its body (renaming the action), a
  ::  disjunction recurses each disjunct, anything else is a leaf action.
  |=  [n=sem:sem-lib nm=@t defs=(map @t sem-def:sem-lib)]
  ^-  (list [name=@t body=sem:sem-lib])
  ?:  ?=(%letin -.n)  ?~(body.n ~[[nm n]] $(n u.body.n))
  ?.  ?=(%apply -.n)  ~[[nm n]]
  =/  op  name.op.n
  ?:  ?&(?=(%user-op kind.op.n) ?=(~ args.n))
    =/  d  (~(get by defs) op)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  ~[[nm n]]
    $(n u.body.u.d, nm op)
  ?:  |(=(op '$DisjList') =(op '\\lor'))
    (get-actions-list args.n nm defs)
  ::  `\E i \in S : body` — tlc2's getActions ENUMERATES S and recurses into
  ::  args[0] once per element, carrying the binding in the element's Context
  ::  (Tool.getActionsAppl OPCODE_be), so every resulting action carries the
  ::  BODY's span, not the whole quantifier's. We keep ONE action whose BODY is
  ::  still the whole quantifier (so it stays solvable -- the bound variable has
  ::  no binding outside it) but whose SPAN is the body's, which is what the
  ::  label renders. One-vs-N is unobservable here: every per-element action
  ::  carries this same label, the successor stream is already enumerated in
  ::  element order by +solve-exists, and the coverage counts are a documented
  ::  approved difference. R1.5.12
  ?:  =(op '$BoundedExists')
    ?~  args.n  ~[[nm n]]
    ?.  ?=(%apply -.i.args.n)  ~[[nm n]]
    ~[[nm n(at at.i.args.n)]]
  ~[[nm n]]
::
++  get-actions-list
  |=  [l=(list sem:sem-lib) nm=@t defs=(map @t sem-def:sem-lib)]
  ^-  (list [name=@t body=sem:sem-lib])
  ?~  l  ~
  (weld (get-actions i.l nm defs) $(l t.l))
::
++  action-label
  ::  `<name line BL, col BC to line EL, col EC of module M>`
  |=  [nm=@t sp=(unit span) modn=@t]
  ^-  @t
  ?~  sp  (crip "<{(trip nm)}>")
  =*  s  u.sp
  %-  crip
  ;:  weld
    "<"  (trip nm)  " line "  (a-tape line.from.s)  ", col "  (a-tape col.from.s)
    " to line "  (a-tape line.to.s)  ", col "  (a-tape col.to.s)
    " of module "  (trip modn)  ">"
  ==
::
++  edge-action-label
  ::  the label of the action that generates state `s1fp` from `s0`: the first
  ::  getActions leaf whose next-state relation reaches that fingerprint
  |=  $:  s0=state  s1fp=@t
          actions=(list [name=@t body=sem:sem-lib])
          e=eenv:ne  order=(list @t)  modn=@t
      ==
  ^-  @t
  ?~  actions  '<unknown action>'
  =/  r  (next-states:ne s0 body.i.actions e)
  ?:  ?=(%| -.r)  $(actions t.actions)
  ?:  (lien p.r |=(st=state =(s1fp (@t (state-fp:fp order st)))))
    (action-label name.i.actions (sem-span:config body.i.actions) modn)
  $(actions t.actions)
::
++  edge-action
  ::  the STRUCTURED form of +edge-action-label: the action that generates
  ::  `s1fp` from `s0` as [name span], for the wire trace's per-state `action`
  ::  field (the rendered text form is what the report artifact prints).
  ::  ~ when no action matches. R1.5.12b
  |=  $:  s0=state  s1fp=@t
          actions=(list [name=@t body=sem:sem-lib])
          e=eenv:ne  order=(list @t)  modn=@t
      ==
  ^-  (unit [name=@t at=(unit loc)])
  ?~  actions  ~
  =/  r  (next-states:ne s0 body.i.actions e)
  ?:  ?=(%| -.r)  $(actions t.actions)
  ?:  (lien p.r |=(st=state =(s1fp (@t (state-fp:fp order st)))))
    =/  sp  (sem-span:config body.i.actions)
    `[name.i.actions ?~(sp ~ `[modn u.sp])]
  $(actions t.actions)
::
++  fp-hex
  ::  a state fingerprint as TLC prints it: "0x" + lowercase hex, no separators
  |=  fp=@t
  ^-  tape
  (weld "0x" (skip (slag 2 (scow %ux `@ux`fp)) |=(c=@tD =('.' c))))
::
++  raw-live-oss
  ::  the normalized oos via the raw path (parse/generate/resolve-targets/
  ::  normalize, skipping search-ctx's symmetry-with-temporal rejection so the
  ::  symmetry-live corpus case is still exercised); the module name is returned
  ::  for the structural rendering
  |=  [spec=@t cfg=@t]
  ^-  (each [modn=@t oss=(list oos:tp)] @t)
  =/  pr  (parse:syntax spec)
  ?:  ?=(%| -.pr)  [%| 'parse error']
  =/  tree  p.pr
  =/  cr  (parse-cfg:config cfg)
  ?:  ?=(%| -.cr)  [%| 'config']
  =/  ca  p.cr
  =/  modn  (module-name-of tree)
  =/  mo  (generate:sem-lib modn (malt ~[[modn spec]]))
  ?~  mo  [%| 'semantic error']
  =/  defs  (defmap-of:ne u.mo)
  =/  rt  (resolve-targets ca defs)
  ?:  ?=(%| -.rt)  [%| p.rt]
  =/  pbods=(list sem:sem-lib)
    =/  ps  properties.ca
    |-  ^-  (list sem:sem-lib)
    ?~  ps  ~
    =/  b  (sem-body defs i.ps)
    ?~  b  $(ps t.ps)
    [u.b $(ps t.ps)]
  =/  env  (make-env:ne defs (const-map cfg) (var-names tree))
  =/  or  (normalize:tp pbods fair.p.rt env)
  ?:  ?=(%| -.or)  [%| msg.p.or]
  [%& modn p.or]
::
++  live-struct-raw
  ::  the count projection via the raw path (see +raw-live-oss)
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  or  (raw-live-oss spec cfg)
  ?:  ?=(%| -.or)  ~[(cat 3 'Error: ' p.or)]
  (render-counts:tp oss.p.or)
::
++  live-struct-full-raw
  ::  the full structural projection via the raw path (see +raw-live-oss)
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  or  (raw-live-oss spec cfg)
  ?:  ?=(%| -.or)  ~[(cat 3 'Error: ' p.or)]
  (render-struct:tp oss.p.or modn.p.or (live-tabs oss.p.or))
::
++  check
  ::  model-check a spec + config, returning TLC's terminal output lines
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  ~[(cat 3 'Error: ' p.sc)]
  =*  c  p.sc
  =/  ae  (check-assumes asmz.c (make-env:ne defs.c consts.c vars.c))
  ?^  ae  ~[(cat 3 'Error: ' msg.u.ae)]
  ::  a temporal PROPERTY: a pure []P box-state is a state invariant, rendered
  ::  through the safety terminal output; every other form runs the 8.2–8.6
  ::  engine and renders tlc2.TLC's temporal console diagnostic (unit 8.9)
  ?^  pp.c
    =/  psb  (sem-body defs.c u.pp.c)
    ?~  psb  ~['No property def']
    =/  binner  (box-state-inner:tp u.psb)
    ?^  binner
      =/  o=bfs-opts
        [nsb.c ~[[u.pp.c u.binner]] cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c 0 0]
      =/  actions  (get-actions nsb.c 'Next' defs.c)
      =/  env      (make-env:ne defs.c consts.c vars.c)
      =/  modn     (module-name-of tree.c)
      (render-outcome out:(explore is.c o) nl.c actions env order.c modn)
    =/  osr  (oss-of ~[u.psb] ~ (make-env:ne defs.c consts.c vars.c))
    ?:  ?=(%| -.osr)  ~[(cat 3 'Error: ' msg.p.osr)]
    ::  the temporal graph build is bounded (R1.5.5) so `check:check` never hangs
    ::  on a large/looping state space; a capped build renders %limited
    =/  o=bfs-opts
      [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | live-graph-cap 0]
    =/  bg    (build-graph-cap is.c o)
    =/  modn  (module-name-of tree.c)
    ?:  capped.bg
      :-  'Model checking stopped: state limit reached.'
      (counts-lines gen.g.bg distinct.g.bg 0 depth.g.bg)
    =/  r
      %-  live-report
      :*  p.osr  (states-of seen.g.bg)  inits.g.bg  nsb.c
          (make-env:ne defs.c consts.c vars.c)  order.c  modn  defs.c  u.pp.c
          gen.g.bg  distinct.g.bg  depth.g.bg
      ==
    report.r
  ::  safety: an INVARIANT
  =/  o=bfs-opts  [nsb.c invs.c cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c 0 0]
  =/  actions  (get-actions nsb.c 'Next' defs.c)
  =/  env      (make-env:ne defs.c consts.c vars.c)
  =/  modn     (module-name-of tree.c)
  (render-outcome out:(explore is.c o) nl.c actions env order.c modn)
::
++  render-outcome
  ::  TLC's terminal lines for a safety outcome. `actions`/`e`/`order`/`modn`
  ::  give the getActions per-action trace labels (R1.5.4); pass ~ actions to
  ::  fall back to the single whole-Next label.
  |=  $:  res=outcome  nl=@t
          actions=(list [name=@t body=sem:sem-lib])
          e=eenv:ne  order=(list @t)  modn=@t
      ==
  ^-  wain
  ?-    -.res
      %ok
    :-  'Model checking completed. No error has been found.'
    (counts-lines gen.res distinct.res queued.res depth.res)
  ::
      %limited
    :-  ?:  =(%states what.res)
          'Model checking stopped: state limit reached.'
        'Model checking stopped: depth limit reached.'
    (counts-lines gen.res distinct.res queued.res depth.res)
  ::
      %inv
    ::  an initial-state violation (EC 2107) prints a distinct message with the
    ::  offending state inline and no statistics summary; a behavior violation
    ::  (EC 2110) prints the numbered trace and the counts (matching TLC)
    ?:  initial.res
      ::  a single offending initial state, rendered inline (a wet `turn` over
      ::  the recursive state mold fuse-loops the zuse-408 compiler)
      %+  weld
        ~[(crip "Error: Invariant {(trip name.res)} is violated by the initial state:")]
      ?~(trace.res ~ (render-state i.trace.res))
    ;:  weld
      ~[(crip "Error: Invariant {(trip name.res)} is violated.")]
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl actions e order modn)
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      %deadlock
    ;:  weld
      ~['Error: Deadlock reached.']
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl actions e order modn)
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      %error  ~[(crip "Error: {(trip msg.res)}")]
  ==
::
::  +|  Structured Result (for the Gall job engine, unit 13)
::
::
++  run-check
  ::  run the pipeline on inline source, returning the wire-typed result
  ::  and run statistics. `cap` bounds the distinct-state count so a single
  ::  invocation is bounded; a spec that exceeds it yields %limited.
  |=  [spec=@t cfg=@t cap=@ud]
  ^-  [result run-stats]
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [[%failed p.sc] *run-stats]
  =*  c  p.sc
  =/  ae  (check-assumes asmz.c (make-env:ne defs.c consts.c vars.c))
  ?^  ae  [[%failed msg.u.ae] *run-stats]
  ::  a temporal property: a pure []P box-state is a state invariant (checked by
  ::  the safety search, unit 8.9); every other form runs the 8.2–8.6 engine
  ?^  pp.c
    =/  psb  (sem-body defs.c u.pp.c)
    ?~  psb  [[%failed 'no property definition'] *run-stats]
    =/  binner  (box-state-inner:tp u.psb)
    ?~  binner
      =/  osr  (oss-of ~[u.psb] ~ (make-env:ne defs.c consts.c vars.c))
      ?:  ?=(%| -.osr)  [[%failed msg.p.osr] *run-stats]
      ::  the temporal graph build is bounded by `cap` (R1.5.5): a capped build
      ::  yields %limited rather than a lasso verdict on a partial graph
      =/  o=bfs-opts  [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | cap 0]
      =/  bg  (build-graph-cap is.c o)
      ::  the liveness graph build samples no out-degree (no BFS frontier)
      =/  st  [gen.g.bg distinct.g.bg 0 depth.g.bg [0 0 0 0]]
      ?:  capped.bg  [[%limited %states st] st]
      =/  l
        %-  find-lasso:lv
        :*  p.osr  (states-of seen.g.bg)  inits.g.bg  nsb.c
            (make-env:ne defs.c consts.c vars.c)  order.c
        ==
      ?~(l [[%ok st] st] [[%violated [%property u.pp.c] st] st])
    ::  box-state P as a safety invariant
    =/  o=bfs-opts
      [nsb.c ~[[u.pp.c u.binner]] cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c cap 0]
    =/  er  (explore is.c o)
    (explore-outcome out.er od.er)
  ::  safety (invariant)
  =/  o=bfs-opts  [nsb.c invs.c cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c cap 0]
  =/  er  (explore is.c o)
  (explore-outcome out.er od.er)
::
++  explore-outcome
  ::  a safety outcome as the wire result + run-stats (shared by run-check's
  ::  invariant and box-state paths)
  |=  [res=outcome od=out-degree]
  ^-  [result run-stats]
  ?-    -.res
      %ok        =/  st  [gen.res distinct.res queued.res depth.res od]  [[%ok st] st]
      %limited   =/  st  [gen.res distinct.res queued.res depth.res od]  [[%limited what.res st] st]
      %inv       =/  st  [gen.res distinct.res queued.res depth.res od]  [[%violated [%invariant name.res] st] st]
      %deadlock  =/  st  [gen.res distinct.res queued.res depth.res od]  [[%violated [%deadlock ~] st] st]
      %error     [[%failed msg.res] *run-stats]
  ==
::
++  run-stats-full
  ::  the final statistics of a safety search including the max out-degree that
  ::  the wire run-stats does not carry, run in `budget`-sized slices (for
  ::  statistics and pause/resume-equality differential tests)
  |=  [spec=@t cfg=@t cap=@ud budget=@ud]
  ^-  [gen=@ud distinct=@ud queued=@ud depth=@ud outdeg=[min=@ud mean=@ud p95=@ud max=@ud]]
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [0 0 0 0 [0 0 0 0]]
  =*  c  p.sc
  =/  o=bfs-opts
    [nsb.c invs.c cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c cap 0]
  =/  cur  (explore-cursor is.c o budget)
  [gen.cur distinct.cur (lent queue.cur) depth.cur (od-stats outdeg.cur)]
--

