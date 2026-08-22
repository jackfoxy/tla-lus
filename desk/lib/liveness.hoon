::  liveness.hoon — behavior-graph product (Work Unit 8.3). Pairs the Work
::  Unit 7 reachable state graph with an OrderOfSolution tableau (unit 8.2):
::  a product node is a (state-fp, tableau-node-index) pair whose tableau node
::  is consistent with the state, reachable from the consistent initial pairs.
::  Port of the LiveCheck node-combination contract (addInitState/addNextState).
::  For a no-tableau OrderOfSolution the product is the reachable state graph.
/-  *tla-lus
/=  tp  /lib/temporal
/=  tb  /lib/tableau
/=  ne  /lib/node-eval
/=  fpl  /lib/fingerprint
/=  vl  /lib/value
=,  tp
|%
+$  pg-key  [fp=@t tidx=@ud]        ::  a product node (state fingerprint, node)
::
++  st-pred-bool
  ::  a tableau node's state predicate (level<=1) at a state, via node-eval; an
  ::  evaluation failure reads as inconsistent.
  ::
  ::  JUNCTIONS ARE EVALUATED, NOT REFUSED. `+state-preds-of:tableau` keeps a
  ::  particle member whose `le-level` is <= 1, and the level of a `%conj` is
  ::  the MAX of its children — so a conjunction of two state predicates is a
  ::  state predicate and arrives here. It used to bail
  ::  `%tlc-live-statepred-junction` on `<>(x = 1 /\ y = 0)`, an ordinary
  ::  liveness property TLC runs to a verdict (R1.2.0 found it by reading this
  ::  arm against `+cs-eval`, which handles both cases; corpus case
  ::  `conj-statepred`). tlc2 has no case analysis here at all —
  ::  `TBGraphNode.isConsistent` calls `tool.isValid` on the expression
  ::  whatever its shape.
  |=  [x=live-expr s0=state:ne env=eenv:ne]
  ^-  ?
  ?-  -.x
    %bool   b.x
    %neg    !(st-pred-bool b.x s0 env)
    %conj   (levy cs.x |=(y=live-expr (st-pred-bool y s0 env)))
    %disj   (lien ds.x |=(y=live-expr (st-pred-bool y s0 env)))
  ::
      %state
    =/  r  (pred-bool:ne p.x s0 ~ env)
    ?:(?=(%& -.r) p.r |)
  ::
  ::  ENABLED is `LNStateEnabled extends LNState`, so its level is VARIABLE and
  ::  `+state-preds-of` keeps it -- tlc2 evaluates it here through
  ::  `LNStateEnabled.eval` -> `tool.enabled`, and so must the port (R1.2.7)
    %enabled  (enabled-eval box.x sub.x p.x s0 env)
  ::
  ::  the rest are above state level -- `%act` and `%next` are ActionLevel,
  ::  `%all`/`%even` TemporalLevel -- so `+state-preds-of`'s `le-level <= 1`
  ::  filter removes them before they can arrive, exactly as
  ::  `TBGraphNode`'s constructor does. Reaching one is an invariant violation,
  ::  not an input shape
    %next     ~|(%tlc-live-statepred-next !!)
    %all      ~|(%tlc-live-statepred-temporal !!)
    %even     ~|(%tlc-live-statepred-temporal !!)
    %act      ~|(%tlc-live-statepred-action !!)
  ==
::
++  consistent-at
  ::  TBGraphNode.isConsistent: every state predicate of the node holds
  |=  [nd=tb-node:tb s0=state:ne env=eenv:ne]
  ^-  ?
  =/  ps  state-preds.nd
  |-  ^-  ?
  ?~  ps  &
  ?.  (st-pred-bool i.ps s0 env)  |
  $(ps t.ps)
::
++  succ-fps
  ::  the fingerprints of a state's successors (the next-state relation, keyed
  ::  in variable-declaration order); an evaluation failure yields none.
  ::
  ::  Successors ABSENT from the reachable graph are dropped. Without a model
  ::  CONSTRAINT the graph is closed under this relation, so that is a no-op;
  ::  with one, tlc2 never enqueues the constrained state, so the edge does not
  ::  exist for liveness either. The product build used to take the raw relation
  ::  and then `~(got by states)` the successor, which crashes on a constrained
  ::  spec (test-model's `LivenessConstraintWarning`). R1.8.1.4
  ::  DEDUPLICATED by fingerprint, in first-occurrence order: tlc2 collects the
  ::  successors into a `SetOfStates` keyed by fingerprint before handing them to
  ::  `addNextState`, and `GraphNode.transExists` refuses a repeat, so a state
  ::  reachable by two actions contributes ONE product edge. The port emitted one
  ::  per occurrence -- again invisible to a node-count projection (R1.6.3).
  |=  [s0=state:ne nsb=sem:sm env=eenv:ne order=(list @t) states=(map @t state:ne)]
  ^-  (list [fp=@t st=state:ne])
  =/  r  (next-states:ne s0 nsb env)
  ?:  ?=(%| -.r)  ~
  =|  seen=(set @t)
  |-  ^-  (list [fp=@t st=state:ne])
  ?~  p.r  ~
  =/  fp  `@t`(state-fp:fpl order i.p.r)
  ?.  (~(has by states) fp)  $(p.r t.p.r)
  ?:  (~(has in seen) fp)  $(p.r t.p.r)
  [[fp i.p.r] $(p.r t.p.r, seen (~(put in seen) fp))]
::
++  build-product
  ::  the product node count and initial-node count for one OrderOfSolution.
  ::  No tableau: the product is the reachable state graph. With a tableau:
  ::  BFS from the consistent initial (state, init-tableau-node) pairs, adding
  ::  a successor (fp1, t1) whenever a state successor s1 is consistent with a
  ::  tableau successor t1 of the current node.
  |=  $:  o=oos:tp
          states=(map @t state:ne)
          inits=(list @t)
          nsb=sem:sm
          env=eenv:ne
          order=(list @t)
      ==
  ^-  [nodes=@ud inits=@ud]
  ?~  tf.o
    [~(wyt by states) (lent inits)]
  =/  tabg   (build-tableau:tb u.tf.o)
  =/  init-keys  (init-keys states inits tabg env)
  =/  seen=(set pg-key)  (silt init-keys)
  =/  q  init-keys
  |-  ^-  [nodes=@ud inits=@ud]
  ?~  q  [~(wyt in seen) (lent init-keys)]
  =/  s0   (~(got by states) fp.i.q)
  =/  t0   (snag-node:tb tidx.i.q nodes.tabg)
  =/  ss   (succ-fps s0 nsb env order states)
  =/  new  (succ-keys ss t0 tabg seen env)
  =.  seen  (~(gas in seen) new)
  $(q (weld t.q new))
::
++  init-keys
  ::  the consistent initial product nodes: an initial tableau node (index <
  ::  init-cnt) that is consistent with an initial state
  |=  [states=(map @t state:ne) inits=(list @t) tabg=tb-graph:tb env=eenv:ne]
  ^-  (list pg-key)
  ?~  inits  ~
  =/  s0  (~(got by states) i.inits)
  =/  here
    =/  t  0
    |-  ^-  (list pg-key)
    ?:  =(t init-cnt.tabg)  ~
    ?:  (consistent-at (snag-node:tb t nodes.tabg) s0 env)
      [[i.inits t] $(t +(t))]
    $(t +(t))
  (weld here $(inits t.inits))
::
++  succ-keys
  ::  the newly-seen product nodes from a node's successors: each state
  ::  successor s1 paired with each tableau successor t1 of the current node,
  ::  kept when s1 is consistent with t1 and (s1,t1) is not already seen
  |=  $:  ss=(list [fp=@t st=state:ne])
          t0=tb-node:tb
          tabg=tb-graph:tb
          seen=(set pg-key)
          env=eenv:ne
      ==
  ^-  (list pg-key)
  ?~  ss  ~
  =/  here
    =/  ns  nexts.t0
    |-  ^-  (list pg-key)
    ?~  ns  ~
    =/  t1  (snag-node:tb i.ns nodes.tabg)
    ?.  (consistent-at t1 st.i.ss env)  $(ns t.ns)
    =/  key=pg-key  [fp.i.ss i.ns]
    ?:  (~(has in seen) key)  $(ns t.ns)
    [key $(ns t.ns)]
  (weld here $(ss t.ss))
::
::  +|  The PossibleErrorModel accepting condition (Work Unit 8.4)
::
::  A candidate component (a cycle / strongly-connected component in the product
::  graph) satisfies a `pem` — is an accepting counterexample — iff, over the
::  component (LiveWorker.checkComponent):
::    - EAAction (<>[]E): every edge satisfies each E (E holds always, so on
::      every transition of the infinitely-repeated cycle);
::    - AEState  ([]<>S): some node satisfies each S (S holds infinitely often);
::    - AEAction ([]<>A): some edge satisfies each A (A fires infinitely often);
::    - promises (<>p): each tableau promise is fulfilled at some node.
::  WF_/SF_ fairness is *encoded* in the pem (an unfair cycle simply fails the
::  AEAction/EAAction it contributes), so no separate fairness logic is needed.
::  The component is presented as per-node checkState bit-lists and particles
::  and per-edge checkAction bit-lists (the labels the product carries).
++  comp
  $:  node-cs=(list (list ?))    ::  per-node checkState results
      node-par=(list par:tb)     ::  per-node tableau particle (for promises)
      edge-ca=(list (list ?))    ::  per-edge checkAction results
  ==
::
++  bit-at
  ::  the i-th boolean of a result vector (missing reads false)
  |=  [i=@ud v=(list ?)]
  ^-  ?
  ?~  v  |
  ?:(=(0 i) i.v $(i (dec i), v t.v))
::
++  all-edges-set
  ::  every edge has bit `idx` set (the EAAction "holds on every transition")
  |=  [idx=@ud edges=(list (list ?))]
  ^-  ?
  ?~  edges  &
  ?.  (bit-at idx i.edges)  |
  $(edges t.edges)
::
++  some-set
  ::  some element of `rows` has bit `idx` set (AEState/AEAction "some node/edge")
  |=  [idx=@ud rows=(list (list ?))]
  ^-  ?
  ?~  rows  |
  ?:  (bit-at idx i.rows)  &
  $(rows t.rows)
::
++  every-ea
  ::  each EAAction index holds on every edge
  |=  [idxs=(list @ud) edges=(list (list ?))]
  ^-  ?
  ?~  idxs  &
  ?.  (all-edges-set i.idxs edges)  |
  $(idxs t.idxs)
::
++  every-some
  ::  each index (AEState/AEAction) holds on some row (node/edge)
  |=  [idxs=(list @ud) rows=(list (list ?))]
  ^-  ?
  ?~  idxs  &
  ?.  (some-set i.idxs rows)  |
  $(idxs t.idxs)
::
++  is-fulfilling
  ::  TBPar.isFulfilling: a particle fulfils promise <>p iff <>p is absent from
  ::  it, or its body p is present
  |=  [promise=live-expr p=par:tb]
  ^-  ?
  ?.  (par-member:tb promise p)  &
  ?:  ?=(%even -.promise)  (par-member:tb b.promise p)
  |
::
++  promise-met
  ::  a promise is fulfilled at some node of the component
  |=  [promise=live-expr nodes=(list par:tb)]
  ^-  ?
  ?~  nodes  |
  ?:  (is-fulfilling promise i.nodes)  &
  $(nodes t.nodes)
::
++  all-promises
  |=  [promises=(list live-expr) nodes=(list par:tb)]
  ^-  ?
  ?~  promises  &
  ?.  (promise-met i.promises nodes)  |
  $(promises t.promises)
::
++  pem-accepting
  ::  whether a candidate component is an accepting counterexample for `p`
  |=  [p=pem:tp promises=(list live-expr) c=comp]
  ^-  ?
  ?&  (every-ea ea-action.p edge-ca.c)
      (every-some ae-state.p node-cs.c)
      (every-some ae-action.p edge-ca.c)
      (all-promises promises node-par.c)
  ==
::
::  +|  checkState / checkAction evaluation (the product edge/node labels)
::
++  cs-eval
  ::  a checkState live-expr (a state predicate, level<=1) at a state
  |=  [x=live-expr s0=state:ne env=eenv:ne]
  ^-  ?
  ?-  -.x
    %bool   b.x
    %neg    !(cs-eval b.x s0 env)
    %conj   (levy cs.x |=(y=live-expr (cs-eval y s0 env)))
    %disj   (lien ds.x |=(y=live-expr (cs-eval y s0 env)))
  ::
      %state
    =/  r  (pred-bool:ne p.x s0 ~ env)
    ?:(?=(%& -.r) p.r |)
  ::
  ::  ENABLED is state-level (`LNStateEnabled extends LNState`), so it can be a
  ::  checkState entry and tlc2 evaluates it (R1.2.7)
    %enabled  (enabled-eval box.x sub.x p.x s0 env)
  ::
  ::  the rest are above state level, and a checkState entry is level <= 1 by
  ::  construction (`+classify` bins `[]<>S` with `le-level <= 1` here and
  ::  everything else into checkAction), so these cannot arrive
    %act      ~|(%tlc-live-checkstate-action !!)
    %all      ~|(%tlc-live-checkstate-temporal !!)
    %even     ~|(%tlc-live-checkstate-temporal !!)
    %next     ~|(%tlc-live-checkstate-next !!)
  ==
::
++  ca-eval
  ::  a checkAction live-expr (an action predicate, level<=2) on a transition
  ::  s0 -> s1; LNAction/LNStateEnabled leaves carry action/ENABLED semantics
  |=  [x=live-expr s0=state:ne s1=state:ne env=eenv:ne]
  ^-  ?
  ?-  -.x
    %bool   b.x
    %neg    !(ca-eval b.x s0 s1 env)
    %conj   (levy cs.x |=(y=live-expr (ca-eval y s0 s1 env)))
    %disj   (lien ds.x |=(y=live-expr (ca-eval y s0 s1 env)))
  ::
      %state
    =/  r  (pred-bool:ne p.x s0 ~ env)
    ?:(?=(%& -.r) p.r |)
  ::
    %act      (act-eval box.x sub.x a.x s0 s1 env)
    %enabled  (enabled-eval box.x sub.x p.x s0 env)
  ::  `LNNext.eval(tool, s1, s2)` is `body.eval(tool, s2, Empty)` -- the body at
  ::  the SUCCESSOR state. `()P` is ActionLevel, so it can be a checkAction
  ::  entry and must be evaluated rather than refused (R1.2.7)
    %next     (cs-eval b.x s1 env)
  ::
  ::  `[]`/`<>` cannot be evaluated at a transition at all: tlc2 raises
  ::  EC 2251 TLC_LIVE_CANNOT_EVAL_FORMULA (`LNAll.eval`/`LNEven.eval`). These
  ::  arms return a bare `?`, so the port renders that as a bail rather than a
  ::  diagnostic -- an approved difference, see compatibility.md
    %all      ~|(%tlc-live-cannot-eval-formula !!)
    %even     ~|(%tlc-live-cannot-eval-formula !!)
  ==
::
++  sub-val
  ::  a subscript state-expression evaluated at a state (its value, or ~ on
  ::  an evaluation error)
  |=  [e=sem:sm st=state:ne env=eenv:ne]
  ^-  (unit value:vl)
  =/  r  (eval:ne e env(s0 st))
  ?:(?=(%& -.r) `p.r ~)
::
++  act-eval
  ::  LNAction.eval: <A>_e is A /\ e' != e ; [A]_e is A \/ e' = e (a subscript
  ::  stutter makes [A]_e true and <A>_e false without evaluating A)
  |=  [box=? sub=(unit sem:sm) a=sem:sm s0=state:ne s1=state:ne env=eenv:ne]
  ^-  ?
  =/  stut
    ?~  sub  |
    =/  v0  (sub-val u.sub s0 env)
    =/  v1  (sub-val u.sub s1 env)
    ?&(?=(^ v0) ?=(^ v1) (equal:vl u.v0 u.v1))
  ?:  &(?=(^ sub) box stut)  &
  ?:  &(?=(^ sub) !box stut)  |
  =/  r  (pred-bool:ne a s0 s1 env)
  ?:(?=(%& -.r) p.r |)
::
++  enabled-eval
  ::  LNStateEnabled.eval: ENABLED <A>_e holds at s0 iff some successor via A
  ::  changes the subscript e; ENABLED [A]_e is always true
  |=  [box=? sub=(unit sem:sm) a=sem:sm s0=state:ne env=eenv:ne]
  ^-  ?
  ?:  &(box ?=(^ sub))  &
  =/  r  (solve:ne a %next s0 ~ env(enabled &))
  ?:  ?=(%| -.r)  |
  ?~  sub
    (lien p.r |=(st=state:ne (complete:ne st vars.env)))
  =/  v0  (sub-val u.sub s0 env)
  ?~  v0  |
  %+  lien  p.r
  |=  st=state:ne
  ?.  (complete:ne st vars.env)  |
  =/  v1  (sub-val u.sub st env)
  ?&(?=(^ v1) !(equal:vl u.v0 u.v1))
::
::  +|  Labeled product graph, SCC search, and verdict (Work Unit 8.5)
::
+$  pnode  [cs=(list ?) par=par:tb]           ::  a product node's labels
::  `stut` marks the self-edge the port adds so a behavior can stutter forever.
::  tlc2's EXHAUSTIVE product has no such edge (`LiveChecker.addNextState`
::  records the real successors only) -- it grants stuttering in the acceptance
::  search instead. The port grants it in the GRAPH, which is verdict-equivalent
::  (every liveness fixture agrees) but is a different representation, so the
::  PRODUCT projection excludes exactly these edges rather than filtering
::  self-loops by shape -- a genuine `x' = x` transition is still compared.
::  R1.6.3; recorded as an approved difference in compatibility.md.
+$  pedge  [from=pg-key to=pg-key ca=(list ?) stut=?]
::  the bounded/resumable product-build cursor (unit 8.8.2a): the tableau, the
::  BFS worklist over product keys, the visited set, and the product built so
::  far. The static inputs (oos, states, nsb, env, order) are supplied fresh at
::  each step from the kont, so the persisted cursor stays small.
+$  pcursor
  $:  tabg=tb-graph:tb
      q=(list pg-key)
      seen=(set pg-key)
      nodes=(map pg-key pnode)
      edges=(list pedge)
      inits=(list pg-key)
  ==
::  the bounded/resumable Tarjan SCC cursor (unit 8.8.2b): the roots still to
::  start, the index/lowlink/on-stack/SCC-stack state, an EXPLICIT DFS frame
::  stack (replacing recursion — so a deep product cannot overflow the Hoon
::  stack and the search pauses/resumes), and the components found so far. The
::  adjacency is supplied fresh at each step, so the persisted cursor stays small.
+$  scursor
  $:  verts=(list pg-key)
      idx=@ud
      index=(map pg-key @ud)
      low=(map pg-key @ud)
      onstk=(set pg-key)
      stk=(list pg-key)
      work=(list [v=pg-key ws=(list pg-key)])
      out=(list (list pg-key))
  ==
::
++  product-init
  ::  seed a product-build cursor for a tableau OOS from the reachable state
  ::  graph: the tableau, the consistent initial product keys, and an empty
  ::  product. (A no-tf OOS is handled whole by the caller.)
  |=  $:  o=oos:tp  states=(map @t state:ne)  inits=(list @t)
          env=eenv:ne
      ==
  ^-  pcursor
  ?~  tf.o  [*tb-graph:tb ~ ~ ~ ~ ~]
  =/  tabg  (build-tableau:tb u.tf.o)
  =/  ik    (init-keys states inits tabg env)
  [tabg ik (silt ik) ~ ~ ik]
::
++  product-step
  ::  advance a product-build cursor by at most `budget` worklist keys; `done`
  ::  is true when the worklist is empty (the product is complete). Mirrors the
  ::  tableau branch of +labeled-product exactly, one slice at a time.
  |=  $:  o=oos:tp  states=(map @t state:ne)  nsb=sem:sm  env=eenv:ne
          order=(list @t)  pc=pcursor  budget=@ud
      ==
  ^-  [done=? cur=pcursor]
  =/  spent  0
  |-  ^-  [done=? cur=pcursor]
  ?~  q.pc  [& pc]
  ?:  =(spent budget)  [| pc]
  =/  k   i.q.pc
  =/  s0  (~(got by states) fp.k)
  =/  t0  (snag-node:tb tidx.k nodes.tabg.pc)
  =.  nodes.pc  (~(put by nodes.pc) k [(cs-bits check-state.o s0 env) par.t0])
  =/  succs  (succ-fps s0 nsb env order states)
  =/  out  (node-edges k s0 t0 tabg.pc check-action.o succs env)
  =/  fresh  (skim keys.out |=(x=pg-key !(~(has in seen.pc) x)))
  =.  seen.pc  (~(gas in seen.pc) fresh)
  =.  edges.pc  (weld edges.pc es.out)
  $(q.pc (weld t.q.pc fresh), spent +(spent))
::
++  cs-bits
  |=  [xs=(list live-expr) s0=state:ne env=eenv:ne]
  ^-  (list ?)
  ?~  xs  ~
  [(cs-eval i.xs s0 env) $(xs t.xs)]
::
++  ca-bits
  |=  [xs=(list live-expr) s0=state:ne s1=state:ne env=eenv:ne]
  ^-  (list ?)
  ?~  xs  ~
  [(ca-eval i.xs s0 s1 env) $(xs t.xs)]
::
++  labeled-product
  ::  the product graph with per-node checkState bits + particle and per-edge
  ::  checkAction bits. A no-tableau OOS's product is the reachable state graph
  ::  (a single implicit tableau node, index 0).
  |=  $:  o=oos:tp
          states=(map @t state:ne)
          inits=(list @t)
          nsb=sem:sm
          env=eenv:ne
          order=(list @t)
      ==
  ^-  [nodes=(map pg-key pnode) edges=(list pedge) inits=(list pg-key)]
  ?~  tf.o
    =/  ik=(list pg-key)  (turn inits |=(fp=@t `pg-key`[fp 0]))
    =/  nm=(map pg-key pnode)
      %-  malt
      %+  turn  ~(tap by states)
      |=  [fp=@t st=state:ne]
      ^-  [pg-key pnode]
      [[fp 0] [(cs-bits check-state.o st env) ~]]
    =/  es=(list pedge)
      %-  zing
      %+  turn  ~(tap by states)
      |=  [fp0=@t s0=state:ne]
      ^-  (list pedge)
      ::  the tagged stutter self-edge, then the real successors (see +$ pedge)
      :-  ^-  pedge
          [[fp0 0] [fp0 0] (ca-bits check-action.o s0 s0 env) &]
      %+  turn  (succ-fps s0 nsb env order states)
      |=  [fp1=@t s1=state:ne]
      ^-  pedge
      [[fp0 0] [fp1 0] (ca-bits check-action.o s0 s1 env) |]
    [nm es ik]
  ::  drain the bounded product-build cursor in one unbounded pass (the job
  ::  kernel steps the same cursor a slice at a time — unit 8.8.2a)
  =/  pc  (product-init o states inits env)
  =/  r   (product-step o states nsb env order pc (bex 62))
  [nodes.cur.r edges.cur.r inits.cur.r]
::
++  bit-tape
  ::  a checkState/checkAction bit vector as `1`/`0`, or `-` when empty
  ::  `=(~ bs)` rather than `?~`: the latter NARROWS bs, which makes the inner
  ::  loop's own `?~` vacuous (mint-vain)
  |=  bs=(list ?)
  ^-  tape
  ?:  =(~ bs)  "-"
  |-  ^-  tape
  ?~  bs  ""
  [`@tD`?:(i.bs '1' '0') $(bs t.bs)]
::
++  render-product-graph
  ::  the PNODE/PEDGE half of the PRODUCT projection (R1.6.3): each product
  ::  node with its checkState bits, then its outgoing edges with their
  ::  checkAction bits, in (fingerprint-rank, tableau-index) order so the
  ::  projection is a SET rather than a traversal artifact. `ranks` maps a state
  ::  fingerprint to its index in the ascending fingerprint ordering; the
  ::  oracle ranks the same way, so the two agree without exposing raw FP64s.
  ::
  ::  Only KEYS and EDGES go through `sort` -- a `pnode` carries a particle,
  ::  which is the recursive `live-expr` mold, and the wet list gates fuse-loop
  ::  on it (the zuse-408 hazard this library is written around).
  |=  $:  o=oos:tp
          states=(map @t state:ne)
          inits=(list @t)
          nsb=sem:sm
          env=eenv:ne
          order=(list @t)
          ranks=(map @t @ud)
      ==
  ^-  wain
  =/  lp  (labeled-product o states inits nsb env order)
  =/  rk  |=(fp=@t ^-(@ud (~(gut by ranks) fp 0)))
  =/  ks=(list pg-key)
    %+  sort  ~(tap in ~(key by nodes.lp))
    |=  [a=pg-key b=pg-key]
    ^-  ?
    =/  ra  (rk fp.a)
    =/  rb  (rk fp.b)
    ?:(=(ra rb) (lte tidx.a tidx.b) (lth ra rb))
  =/  es=(list pedge)
    %+  sort  edges.lp
    |=  [a=pedge b=pedge]
    ^-  ?
    =/  ra  (rk fp.to.a)
    =/  rb  (rk fp.to.b)
    ?:(=(ra rb) (lte tidx.to.a tidx.to.b) (lth ra rb))
  =|  acc=(list @t)
  |-  ^-  wain
  ?~  ks  (flop acc)
  =/  k  i.ks
  =/  nd  (~(got by nodes.lp) k)
  =/  hd=@t
    %-  crip
    "PNODE {(scow %ud (rk fp.k))} {(scow %ud tidx.k)} CS {(bit-tape cs.nd)}"
  =/  rows=(list @t)
    =/  l  (skim es |=(e=pedge &(=(from.e k) !stut.e)))
    |-  ^-  (list @t)
    ?~  l  ~
    :_  $(l t.l)
    %-  crip
    ;:  weld
      "PEDGE {(scow %ud (rk fp.k))} {(scow %ud tidx.k)} -> "
      "{(scow %ud (rk fp.to.i.l))} {(scow %ud tidx.to.i.l)} "
      "CA {(bit-tape ca.i.l)}"
    ==
  $(ks t.ks, acc (weld (flop rows) [hd acc]))
::
++  node-edges
  ::  the outgoing product edges of (fp,tidx) with their checkAction labels,
  ::  and the successor product keys, over the state × tableau successor cross.
  ::  `succs` are the state's non-stutter successors (from the reachable graph in
  ::  the whole search, or a trace's own next states in +trace-product).
  ::  stuttering is always a valid liveness behaviour: a state can step to
  ::  itself (the tableau still advances), so prepend the self-successor. The
  ::  edge is TAGGED `stut`, because tlc2's exhaustive product does not have it
  ::  (see `+$ pedge`); on the TRACE product it is what tlc2 does too
  ::  (`LiveCheck.checkTrace`: `successors.put(tlcState)`, "Add state itself to
  ::  allow stuttering").
  |=  $:  k=pg-key  s0=state:ne  t0=tb-node:tb  tabg=tb-graph:tb
          ca=(list live-expr)  succs=(list [fp=@t st=state:ne])  env=eenv:ne
      ==
  ^-  [es=(list pedge) keys=(list pg-key)]
  ::  the stutter edge is a pure SELF-loop on (fp,tidx): it must not cross with
  ::  the tableau successors, or stuttering would DISCOVER product nodes tlc2
  ::  never has -- measured on the `~>` fixtures, where crossing added a
  ::  (state, tidx 2) node that neither tlc2 nor the port's own `+build-product`
  ::  count path has (R1.6.3).
  =/  stut-edge=pedge  [k k (ca-bits ca s0 s0 env) &]
  =/  ss  succs
  |-  ^-  [es=(list pedge) keys=(list pg-key)]
  ?~  ss  [~[stut-edge] ~]
  =/  rest  $(ss t.ss)
  =/  here
    =/  bits  (ca-bits ca s0 st.i.ss env)
    =/  ns  nexts.t0
    |-  ^-  [es=(list pedge) keys=(list pg-key)]
    ?~  ns  [~ ~]
    =/  t1  (snag-node:tb i.ns nodes.tabg)
    =/  more  $(ns t.ns)
    ?.  (consistent-at t1 st.i.ss env)  more
    =/  nk=pg-key  [fp.i.ss i.ns]
    [[[k nk bits |] es.more] [nk keys.more]]
  [(weld es.here es.rest) (weld keys.here keys.rest)]
::
::  +|  Liveness over a simulation trace (Work Unit 9.3a)
::
++  trace-graph
  ::  the fingerprint-keyed behavior graph of a simulation trace: each state by
  ::  its fingerprint, the initial fp, and each fp's trace successors (those
  ::  that follow its occurrences — accumulated by fingerprint, matching
  ::  addNextState). The product build adds the stutter self-loop. This is the
  ::  graph tlc2 LiveCheck.checkTrace feeds the liveness checker per behavior.
  |=  [trace=(list state:ne) order=(list @t)]
  ^-  [states=(map @t state:ne) init=@t succ=(jar @t [fp=@t st=state:ne])]
  ?~  trace  [~ *@t ~]
  =/  ini  `@t`(state-fp:fpl order i.trace)
  =|  states=(map @t state:ne)
  =|  succ=(jar @t [fp=@t st=state:ne])
  =.  states  (~(put by states) ini i.trace)
  =/  prev=[fp=@t st=state:ne]  [ini i.trace]
  =/  rest  t.trace
  |-  ^-  [states=(map @t state:ne) init=@t succ=_succ]
  ?~  rest  [states ini succ]
  =/  fp1  `@t`(state-fp:fpl order i.rest)
  =.  states  (~(put by states) fp1 i.rest)
  =.  succ    (~(add ja succ) fp.prev [fp1 i.rest])
  $(rest t.rest, prev [fp1 i.rest])
::
++  trace-product
  ::  the tableau product over a trace's behavior graph (+trace-graph). Mirrors
  ::  +labeled-product but the state successors are the trace's own, not a
  ::  next-states search, so it needs no reachable-graph exploration.
  |=  [o=oos:tp trace=(list state:ne) env=eenv:ne order=(list @t)]
  ^-  [nodes=(map pg-key pnode) edges=(list pedge) inits=(list pg-key)]
  =/  g  (trace-graph trace order)
  ?~  tf.o
    =/  ik=(list pg-key)  ~[[init.g 0]]
    =/  nm=(map pg-key pnode)
      %-  malt
      %+  turn  ~(tap by states.g)
      |=  [fp=@t st=state:ne]
      ^-  [pg-key pnode]
      [[fp 0] [(cs-bits check-state.o st env) ~]]
    =/  es=(list pedge)
      %-  zing
      %+  turn  ~(tap by states.g)
      |=  [fp0=@t s0=state:ne]
      ^-  (list pedge)
      :-  ^-  pedge
          [[fp0 0] [fp0 0] (ca-bits check-action.o s0 s0 env) &]
      %+  turn  (~(get ja succ.g) fp0)
      |=  [fp1=@t s1=state:ne]
      ^-  pedge
      [[fp0 0] [fp1 0] (ca-bits check-action.o s0 s1 env) |]
    [nm es ik]
  =/  tabg  (build-tableau:tb u.tf.o)
  =/  ik    (init-keys states.g ~[init.g] tabg env)
  =|  nodes=(map pg-key pnode)
  =|  edges=(list pedge)
  =/  seen=(set pg-key)  (silt ik)
  =/  q  ik
  |-  ^-  [nodes=(map pg-key pnode) edges=(list pedge) inits=(list pg-key)]
  ?~  q  [nodes edges ik]
  =/  k   i.q
  =/  s0  (~(got by states.g) fp.k)
  =/  t0  (snag-node:tb tidx.k nodes.tabg)
  =.  nodes  (~(put by nodes) k [(cs-bits check-state.o s0 env) par.t0])
  =/  out  (node-edges k s0 t0 tabg check-action.o (~(get ja succ.g) fp.k) env)
  =/  fresh  (skim keys.out |=(x=pg-key !(~(has in seen) x)))
  =.  seen   (~(gas in seen) fresh)
  =.  edges  (weld edges es.out)
  $(q (weld t.q fresh))
::
++  trace-lasso
  ::  a temporal counterexample lasso for the first violated OrderOfSolution
  ::  over a trace's behavior graph (tlc2 LiveCheck.checkTrace). Reuses the
  ::  8.2–8.6 tableau product + SCC/acceptance (+lasso-of-product) — the only
  ::  difference from the whole-graph check is the trace-fixed successors.
  |=  [oss=(list oos:tp) trace=(list state:ne) env=eenv:ne order=(list @t)]
  ^-  (unit lasso)
  ?~  oss  ~
  =/  here  (lasso-of-product i.oss (trace-product i.oss trace env order))
  ?^(here here $(oss t.oss))
::
++  adj-of
  ::  adjacency map from an edge list, keeping only edges whose EAAction bits
  ::  all hold (the <>[]E restriction; a cycle in this subgraph satisfies EAAction)
  |=  [edges=(list pedge) eaa=(list @ud)]
  ^-  (jar pg-key pg-key)
  %+  roll  edges
  |=  [e=pedge acc=(jar pg-key pg-key)]
  ?.  (levy eaa |=(i=@ud (bit-at i ca.e)))  acc
  (~(add ja acc) from.e to.e)
::
++  tarjan
  ::  Tarjan's SCC over the product subgraph; returns the components (each a
  ::  list of product keys), deterministic in discovery order. An explicit DFS
  ::  frame stack (`work`) replaces the recursion; the post-recursion lowlink
  ::  update happens when a frame is popped, bubbling its low to the parent
  ::  frame. Byte-identical to the former recursive +strong.
  |=  [verts=(list pg-key) adj=(jar pg-key pg-key)]
  ^-  (list (list pg-key))
  =/  sc=scursor  [verts 0 ~ ~ ~ ~ ~ ~]
  |-  ^-  (list (list pg-key))
  ::  bind the frame stack to a LOCAL and narrow that, so the sc.work / sc.verts
  ::  wings stay list-typed for the =. assignments below (narrowing an sc wing
  ::  with ?~ would make a later =. onto it need a lest)
  =/  wk  work.sc
  ?~  wk
    ::  no active DFS: advance to the next unvisited root
    =/  vs  verts.sc
    ?~  vs  out.sc
    =/  v0    i.vs
    =/  rest  t.vs
    ?:  (~(has by index.sc) v0)
      $(verts.sc rest)
    =.  verts.sc  rest
    =.  index.sc  (~(put by index.sc) v0 idx.sc)
    =.  low.sc    (~(put by low.sc) v0 idx.sc)
    =.  idx.sc    +(idx.sc)
    =.  stk.sc    [v0 stk.sc]
    =.  onstk.sc  (~(put in onstk.sc) v0)
    =.  work.sc   ~[[v0 (~(get ja adj) v0)]]
    $(sc sc)
  =/  fr     i.wk
  =/  wrest  t.wk
  ?~  ws.fr
    ::  v.fr has no more successors: emit its SCC if it is a root, pop the frame,
    ::  and bubble its lowlink to the parent frame
    =/  v  v.fr
    =.  sc
      ?.  =((~(got by low.sc) v) (~(got by index.sc) v))  sc
      =/  r
        =/  os  onstk.sc
        =/  sk  stk.sc
        =|  comp=(list pg-key)
        |-  ^-  [comp=(list pg-key) os=_os sk=_sk]
        ?~  sk  [comp os sk]
        =/  w  i.sk
        =.  os  (~(del in os) w)
        ?:  =(w v)  [[w comp] os t.sk]
        $(sk t.sk, comp [w comp])
      sc(onstk os.r, stk sk.r, out [comp.r out.sc])
    =.  work.sc  wrest
    =?  low.sc  ?=(^ wrest)
      =/  p  v.i.wrest
      (~(put by low.sc) p (min (~(got by low.sc) p) (~(got by low.sc) v)))
    $(sc sc)
  ::  process v.fr's next successor edge; the advanced top frame + the rest
  =/  v    v.fr
  =/  w    i.ws.fr
  =/  wk2  ^-((list [v=pg-key ws=(list pg-key)]) [[v t.ws.fr] wrest])
  ?:  (~(has by index.sc) w)
    =.  work.sc  wk2
    =?  low.sc  (~(has in onstk.sc) w)
      (~(put by low.sc) v (min (~(got by low.sc) v) (~(got by index.sc) w)))
    $(sc sc)
  ::  w unvisited: enter it and push its frame
  =.  index.sc  (~(put by index.sc) w idx.sc)
  =.  low.sc    (~(put by low.sc) w idx.sc)
  =.  idx.sc    +(idx.sc)
  =.  stk.sc    [w stk.sc]
  =.  onstk.sc  (~(put in onstk.sc) w)
  =.  work.sc   [[w (~(get ja adj) w)] wk2]
  $(sc sc)
::
++  scc-accepting
  ::  a strongly-connected component is an accepting counterexample for `pm`
  ::  iff it contains a cycle (size>1 or a self-loop) and satisfies the pem
  ::  over its internal EAAction-holding edges and its nodes
  |=  $:  scc=(list pg-key)  pm=pem:tp  promises=(list live-expr)
          nodes=(map pg-key pnode)  edges=(list pedge)  eaa=(list @ud)
      ==
  ^-  ?
  =/  members  (silt scc)
  =/  internal
    %+  skim  edges
    |=  e=pedge
    ?&  (~(has in members) from.e)
        (~(has in members) to.e)
        (levy eaa |=(i=@ud (bit-at i ca.e)))
    ==
  ?.  ?|((gth (lent scc) 1) (lien internal |=(e=pedge =(from.e to.e))))  |
  =/  node-cs   (turn scc |=(k=pg-key cs:(~(got by nodes) k)))
  =/  node-par  (turn scc |=(k=pg-key par:(~(got by nodes) k)))
  =/  edge-ca   (turn internal |=(e=pedge ca.e))
  (pem-accepting pm promises [node-cs node-par edge-ca])
::
++  oos-violated
  ::  whether any pem of an OrderOfSolution has an accepting SCC in the product
  |=  $:  o=oos:tp  states=(map @t state:ne)  inits=(list @t)
          nsb=sem:sm  env=eenv:ne  order=(list @t)
      ==
  ^-  ?
  =/  lp     (labeled-product o states inits nsb env order)
  =/  verts  (turn ~(tap by nodes.lp) |=([k=pg-key *] k))
  =/  pms    pems.o
  |-  ^-  ?
  ?~  pms  |
  =/  adj   (adj-of edges.lp ea-action.i.pms)
  =/  sccs  (tarjan verts adj)
  =/  hit
    |-  ^-  ?
    ?~  sccs  |
    ?:  (scc-accepting i.sccs i.pms promises.o nodes.lp edges.lp ea-action.i.pms)  &
    $(sccs t.sccs)
  ?:(hit & $(pms t.pms))
::
++  live-verdict
  ::  whether any OrderOfSolution is violated (an accepting counterexample
  ::  exists) — a temporal-property violation
  |=  $:  oss=(list oos:tp)  states=(map @t state:ne)  inits=(list @t)
          nsb=sem:sm  env=eenv:ne  order=(list @t)
      ==
  ^-  ?
  ?~  oss  |
  ?:  (oos-violated i.oss states inits nsb env order)  &
  $(oss t.oss)
::
::  +|  Lasso counterexample construction (Work Unit 8.6)
::
+$  lasso  [prefix=(list @t) class=?(%stuttering %back-to-state) loop=@ud]
::
++  find-lasso
  ::  a counterexample lasso for the first violated OrderOfSolution. This
  ::  increment builds the stuttering lasso — an accepting single-node SCC that
  ::  is an initial product node with a stutter self-loop (the prefix is that
  ::  one state); back-to-state lassos (a non-trivial cycle, needing the prefix
  ::  walk and per-action labels) are a follow-on.
  |=  $:  oss=(list oos:tp)  states=(map @t state:ne)  inits=(list @t)
          nsb=sem:sm  env=eenv:ne  order=(list @t)
      ==
  ^-  (unit lasso)
  ?~  oss  ~
  =/  here  (oos-lasso i.oss states inits nsb env order)
  ?^(here here $(oss t.oss))
::
++  oos-lasso
  |=  $:  o=oos:tp  states=(map @t state:ne)  inits=(list @t)
          nsb=sem:sm  env=eenv:ne  order=(list @t)
      ==
  ^-  (unit lasso)
  =/  lp  (labeled-product o states inits nsb env order)
  (lasso-of-product o lp)
::
++  lasso-of-product
  ::  the lasso (if any) for one OrderOfSolution over an ALREADY-BUILT product
  ::  (unit 8.8.2a): the bounded SCC/acceptance/lasso post-step the job kernel
  ::  runs after slicing the product build. Separated from +oos-lasso, which
  ::  builds the product whole for the differential.
  |=  $:  o=oos:tp
          lp=[nodes=(map pg-key pnode) edges=(list pedge) inits=(list pg-key)]
      ==
  ^-  (unit lasso)
  =/  init-set  (silt inits.lp)
  =/  verts     (turn ~(tap by nodes.lp) |=([k=pg-key *] k))
  =/  pms       pems.o
  |-  ^-  (unit lasso)
  ?~  pms  ~
  =/  adj   (adj-of edges.lp ea-action.i.pms)
  =/  sccs  (tarjan verts adj)
  ::  a stuttering counterexample is preferred over a back-to-state one; among
  ::  the accepting stutter SCCs TLC reports the one its DFS finishes first (the
  ::  deepest reachable stutter), so collect every stutter lasso and keep the
  ::  one with the longest prefix, falling back to the first back-to-state cycle.
  =/  here
    =|  stutters=(list lasso)
    =/  bt=(unit lasso)  ~
    |-  ^-  (unit lasso)
    ?~  sccs
      ::  keep the accepting stutter with the longest prefix (the deepest
      ::  reachable stutter, which TLC's DFS finishes first); else back-to-state
      ?~  stutters  bt
      :-  ~
      =/  best  i.stutters
      =/  more  t.stutters
      |-  ^-  lasso
      ?~  more  best
      =?  best  (gth (lent prefix.i.more) (lent prefix.best))  i.more
      $(more t.more)
    ?.  (scc-accepting i.sccs i.pms promises.o nodes.lp edges.lp ea-action.i.pms)
      $(sccs t.sccs)
    =/  st  (stutter-lasso i.sccs i.pms promises.o nodes.lp edges.lp init-set ea-action.i.pms)
    =?  stutters  ?=(^ st)  [u.st stutters]
    =?  bt  &(?=(~ bt) ?=(~ st))  (bts-lasso i.sccs edges.lp init-set ea-action.i.pms)
    $(sccs t.sccs)
  ?^(here here $(pms t.pms))
::
++  stutter-lasso
  ::  a stuttering lasso: find the shortest path from init to any accepting
  ::  single-node component (stutter node). This becomes the lasso prefix.
  |=  $:  scc=(list pg-key)  pm=pem:tp  promises=(list live-expr)
          nodes=(map pg-key pnode)  edges=(list pedge)
          init-set=(set pg-key)  eaa=(list @ud)
      ==
  ^-  (unit lasso)
  =/  stutter-nodes
    |-  ^-  (list pg-key)
    ?~  scc  ~
    ?:  (scc-accepting ~[i.scc] pm promises nodes edges eaa)
      [i.scc $(scc t.scc)]
    $(scc t.scc)
  ?~  stutter-nodes  ~
  =/  prefix  (bfs-to init-set (silt stutter-nodes) edges)
  ?^  prefix
    ::  the lasso trace is over distinct STATES: consecutive product nodes with
    ::  the same state fingerprint are a stutter step (the tableau advances while
    ::  the state holds), so they collapse to one trace state — matching TLC,
    ::  which reports the state path, not the product path.
    =/  fps  (turn u.prefix |=(k=pg-key fp.k))
    =/  pf
      |-  ^-  (list @t)
      ?~  fps  ~
      ?~  t.fps  fps
      ?:  =(i.fps i.t.fps)  $(fps t.fps)
      [i.fps $(fps t.fps)]
    `[pf %stuttering (lent pf)]
  ~
::
++  bts-lasso
  ::  a back-to-state lasso: the shortest path from an initial state to the SCC,
  ::  followed by the shortest cycle within the SCC back to some state in that path.
  ::  The prefix is the combined path, and the loop returns to the appropriate index.
  |=  $:  scc=(list pg-key)  edges=(list pedge)
          init-set=(set pg-key)  eaa=(list @ud)
      ==
  ^-  (unit lasso)
  =/  members  (silt scc)
  =/  radj
    ::  real (non-self-loop) EAAction-holding adjacency inside the SCC
    %+  roll  edges
    |=  [e=pedge acc=(jar pg-key pg-key)]
    ?.  ?&  !=(from.e to.e)
            (~(has in members) from.e)
            (~(has in members) to.e)
            (levy eaa |=(i=@ud (bit-at i ca.e)))
        ==
      acc
    (~(add ja acc) from.e to.e)
  =/  prefix  (bfs-to init-set members edges)
  ?^  prefix
    =/  pf  u.prefix
    =/  last  (rear pf)
    =/  cyc  (shortest-cycle last radj)
    ?^  cyc
      =/  cycle-fps  (turn u.cyc |=(x=pg-key fp.x))
      =/  all-fps    (weld (turn (snip pf) |=(x=pg-key fp.x)) cycle-fps)
      =/  loop-fp    fp.last
      ::  1-based index of the first product state whose fingerprint is loop-fp
      =/  loop-idx
        =/  idx  0
        =/  fps  all-fps
        |-  ^-  @ud
        ?~  fps  1
        =.  idx  +(idx)
        ?:(=(i.fps loop-fp) idx $(fps t.fps))
      `[all-fps %back-to-state loop-idx]
    ~
  ~
::
++  shortest-cycle
  ::  the shortest cycle from `k` back to `k` in `radj` as a node path
  ::  [k, …] (excluding the returning step); BFS carrying the path so far
  |=  [k=pg-key radj=(jar pg-key pg-key)]
  ^-  (unit (list pg-key))
  =/  q=(list (list pg-key))  ~[~[k]]
  =/  seen=(set pg-key)  (silt ~[k])
  |-  ^-  (unit (list pg-key))
  ?~  q  ~
  =/  path  i.q
  =/  last  (rear path)
  =/  ws  (~(get ja radj) last)
  =/  ret  (lien ws |=(w=pg-key =(w k)))
  ?:  &(ret (gth (lent path) 0))  `path
  =/  fresh  (skim ws |=(w=pg-key !(~(has in seen) w)))
  =.  seen  (~(gas in seen) fresh)
  =/  more  (turn fresh |=(w=pg-key (snoc path w)))
  $(q (weld t.q more))
::
++  bfs-to
  ::  the shortest path from any initial state to the first node found in
  ::  `target`, by BFS over `edges`. Returns the path including both endpoints
  ::  (initial state through target state), or ~ if no path exists.
  |=  [init-set=(set pg-key) target=(set pg-key) edges=(list pedge)]
  ^-  (unit (list pg-key))
  =/  q=(list (list pg-key))
    (turn ~(tap in init-set) |=(k=pg-key ~[k]))
  =/  seen=(set pg-key)  init-set
  |-  ^-  (unit (list pg-key))
  ?~  q  ~
  =/  path  i.q
  =/  last  (rear path)
  ?:  (~(has in target) last)  `path
  =/  succs
    %+  turn  (skim edges |=(e=pedge =(from.e last)))
    |=(e=pedge to.e)
  =/  fresh  (skim succs |=(k=pg-key !(~(has in seen) k)))
  =.  seen  (~(gas in seen) fresh)
  =/  more  (turn fresh |=(k=pg-key (snoc path k)))
  $(q (weld t.q more))
--
