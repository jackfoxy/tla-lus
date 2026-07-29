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
  ::  a tableau node's state predicate (level<=1: LNBool/LNState/LNNeg) at a
  ::  state, via node-eval; an evaluation failure reads as inconsistent
  |=  [x=live-expr s0=state:ne env=eenv:ne]
  ^-  ?
  ?-  -.x
    %bool   b.x
    %neg    !(st-pred-bool b.x s0 env)
  ::
      %state
    =/  r  (pred-bool:ne p.x s0 ~ env)
    ?:(?=(%& -.r) p.r |)
  ::
    %next     ~|(%tlc-live-statepred-next !!)
    %all      ~|(%tlc-live-statepred-temporal !!)
    %even     ~|(%tlc-live-statepred-temporal !!)
    %conj     ~|(%tlc-live-statepred-junction !!)
    %disj     ~|(%tlc-live-statepred-junction !!)
    %act      ~|(%tlc-live-statepred-action !!)
    %enabled  ~|(%tlc-live-statepred-enabled !!)
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
  ::  in variable-declaration order); an evaluation failure yields none
  |=  [s0=state:ne nsb=sem:sm env=eenv:ne order=(list @t)]
  ^-  (list [fp=@t st=state:ne])
  =/  r  (next-states:ne s0 nsb env)
  ?:  ?=(%| -.r)  ~
  |-  ^-  (list [fp=@t st=state:ne])
  ?~  p.r  ~
  [[(@t (state-fp:fpl order i.p.r)) i.p.r] $(p.r t.p.r)]
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
  =/  ss   (succ-fps s0 nsb env order)
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
    %act      ~|(%tlc-live-checkstate-action !!)
    %enabled  ~|(%tlc-live-checkstate-enabled !!)
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
    %all      ~|(%tlc-live-checkaction-temporal !!)
    %even     ~|(%tlc-live-checkaction-temporal !!)
    %next     ~|(%tlc-live-checkaction-next !!)
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
+$  pedge  [from=pg-key to=pg-key ca=(list ?)]
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
      %+  turn  `(list [fp=@t st=state:ne])`[[fp0 s0] (succ-fps s0 nsb env order)]
      |=  [fp1=@t s1=state:ne]
      ^-  pedge
      [[fp0 0] [fp1 0] (ca-bits check-action.o s0 s1 env)]
    [nm es ik]
  =/  tabg  (build-tableau:tb u.tf.o)
  =/  ik  (init-keys states inits tabg env)
  =/  seen=(set pg-key)  (silt ik)
  =/  q  ik
  =|  nodes=(map pg-key pnode)
  =|  edges=(list pedge)
  |-  ^-  [nodes=(map pg-key pnode) edges=(list pedge) inits=(list pg-key)]
  ?~  q  [nodes edges ik]
  =/  k   i.q
  =/  s0  (~(got by states) fp.k)
  =/  t0  (snag-node:tb tidx.k nodes.tabg)
  =.  nodes  (~(put by nodes) k [(cs-bits check-state.o s0 env) par.t0])
  =/  out  (node-edges k s0 t0 tabg check-action.o nsb env order)
  =/  fresh  (skim keys.out |=(x=pg-key !(~(has in seen) x)))
  =.  seen  (~(gas in seen) fresh)
  $(q (weld t.q fresh), edges (weld edges es.out))
::
++  node-edges
  ::  the outgoing product edges of (fp,tidx) with their checkAction labels,
  ::  and the successor product keys, over the state × tableau successor cross
  |=  $:  k=pg-key  s0=state:ne  t0=tb-node:tb  tabg=tb-graph:tb
          ca=(list live-expr)  nsb=sem:sm  env=eenv:ne  order=(list @t)
      ==
  ^-  [es=(list pedge) keys=(list pg-key)]
  ::  stuttering is always a valid liveness behaviour: a state can step to
  ::  itself (the tableau still advances), so prepend the self-successor
  =/  stutter=[fp=@t st=state:ne]  [fp.k s0]
  =/  ss  (weld ~[stutter] (succ-fps s0 nsb env order))
  |-  ^-  [es=(list pedge) keys=(list pg-key)]
  ?~  ss  [~ ~]
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
    [[[k nk bits] es.more] [nk keys.more]]
  [(weld es.here es.rest) (weld keys.here keys.rest)]
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
  ::  list of product keys), deterministic in discovery order
  |=  [verts=(list pg-key) adj=(jar pg-key pg-key)]
  ^-  (list (list pg-key))
  =|  idx=@ud
  =|  index=(map pg-key @ud)
  =|  low=(map pg-key @ud)
  =|  onstk=(set pg-key)
  =|  stk=(list pg-key)
  =|  out=(list (list pg-key))
  =<  out
  |-  ^+  [out=out idx=idx index=index low=low onstk=onstk stk=stk]
  =*  loop  $
  ?~  verts  [out idx index low onstk stk]
  ?:  (~(has by index) i.verts)  loop(verts t.verts)
  =/  r  (strong i.verts idx index low onstk stk out adj)
  %=  loop
    verts   t.verts
    idx     idx.r
    index   index.r
    low     low.r
    onstk   onstk.r
    stk     stk.r
    out     out.r
  ==
::
++  strong
  ::  the recursive Tarjan visit of one vertex
  |=  $:  v=pg-key
          idx=@ud
          index=(map pg-key @ud)
          low=(map pg-key @ud)
          onstk=(set pg-key)
          stk=(list pg-key)
          out=(list (list pg-key))
          adj=(jar pg-key pg-key)
      ==
  ^-  $:  idx=@ud  index=(map pg-key @ud)  low=(map pg-key @ud)
          onstk=(set pg-key)  stk=(list pg-key)  out=(list (list pg-key))
      ==
  =.  index  (~(put by index) v idx)
  =.  low    (~(put by low) v idx)
  =.  idx    +(idx)
  =.  stk    [v stk]
  =.  onstk  (~(put in onstk) v)
  =/  ws  (~(get ja adj) v)
  =/  r0
    |-  ^+  [idx=idx index=index low=low onstk=onstk stk=stk out=out]
    ?~  ws  [idx index low onstk stk out]
    =/  w  i.ws
    ?:  !(~(has by index) w)
      =/  r  (strong w idx index low onstk stk out adj)
      =.  low  (~(put by low.r) v (min (~(got by low.r) v) (~(got by low.r) w)))
      $(ws t.ws, idx idx.r, index index.r, low low, onstk onstk.r, stk stk.r, out out.r)
    ?:  (~(has in onstk) w)
      =.  low  (~(put by low) v (min (~(got by low) v) (~(got by index) w)))
      $(ws t.ws)
    $(ws t.ws)
  =.  idx    idx.r0
  =.  index  index.r0
  =.  low    low.r0
  =.  onstk  onstk.r0
  =.  stk    stk.r0
  =.  out    out.r0
  ::  root of an SCC: pop the stack down to v
  ?.  =((~(got by low) v) (~(got by index) v))
    [idx index low onstk stk out]
  =/  r1
    =|  comp=(list pg-key)
    |-  ^-  [comp=(list pg-key) onstk=(set pg-key) stk=(list pg-key)]
    ?~  stk  [comp onstk stk]
    =/  w  i.stk
    =.  onstk  (~(del in onstk) w)
    ?:  =(w v)  [[w comp] onstk t.stk]
    $(stk t.stk, comp [w comp])
  [idx index low onstk.r1 stk.r1 [comp.r1 out]]
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
  =/  lp        (labeled-product o states inits nsb env order)
  =/  init-set  (silt inits.lp)
  =/  verts     (turn ~(tap by nodes.lp) |=([k=pg-key *] k))
  =/  pms       pems.o
  |-  ^-  (unit lasso)
  ?~  pms  ~
  =/  adj   (adj-of edges.lp ea-action.i.pms)
  =/  sccs  (tarjan verts adj)
  =/  here
    |-  ^-  (unit lasso)
    ?~  sccs  ~
    ?.  (scc-accepting i.sccs i.pms promises.o nodes.lp edges.lp ea-action.i.pms)
      $(sccs t.sccs)
    ::  prefer the shortest accepting cycle: a self-accepting stutter self-loop
    ::  at an initial node (stuttering), else a back-to-state cycle
    =/  st  (stutter-lasso i.sccs i.pms promises.o nodes.lp edges.lp init-set ea-action.i.pms)
    ?^  st  st
    =/  bt  (bts-lasso i.sccs edges.lp init-set ea-action.i.pms)
    ?^(bt bt $(sccs t.sccs))
  ?^(here here $(pms t.pms))
::
++  stutter-lasso
  ::  a stuttering lasso: find the deepest (longest path from init) accepting
  ::  single-node component (stutter node) in the SCC. The prefix includes all
  ::  states from init through that stuttering state, and the loop target is
  ::  the 1-based index of the stuttering state within the prefix.
  |=  $:  scc=(list pg-key)  pm=pem:tp  promises=(list live-expr)
          nodes=(map pg-key pnode)  edges=(list pedge)
          init-set=(set pg-key)  eaa=(list @ud)
      ==
  ^-  (unit lasso)
  =/  members  (silt scc)
  =/  stutter-nodes
    |-  ^-  (list pg-key)
    ?~  scc  ~
    ?:  (scc-accepting ~[i.scc] pm promises nodes edges eaa)
      [i.scc $(scc t.scc)]
    $(scc t.scc)
  ?~  stutter-nodes  ~
  ::  find the deepest (longest path) to any accepting stutter
  =/  deepest-path
    (find-deepest-stutter init-set members stutter-nodes nodes edges)
  ?^  deepest-path
    =/  pf  (turn u.deepest-path |=(k=pg-key fp.k))
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
  =/  prefix  (prefix-to-bts init-set members edges)
  ?^  prefix
    =/  pf  u.prefix
    =/  last  (rear pf)
    =/  cyc  (shortest-cycle last radj)
    ?^  cyc
      =/  cycle-fps  (turn u.cyc |=(x=pg-key fp.x))
      =/  all-fps    (weld (turn (snip pf) |=(x=pg-key fp.x)) cycle-fps)
      =/  loop-fp    fp.last
      =/  loop-idx   (index-of-first loop-fp all-fps)
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
++  get-loop-target
  ::  find the 1-based index of the state that the cycle returns to. For a cycle
  ::  [k1, k2, …, kn], returns to the index of k1 in the cycle. If k1 appears
  ::  multiple times, returns the index of the first occurrence.
  |=  [target=pg-key cycle-path=(list pg-key)]
  ^-  @ud
  =/  idx  0
  |-  ^-  @ud
  ?~  cycle-path  1
  =.  idx  +(idx)
  ?:(=(i.cycle-path target) idx $(cycle-path t.cycle-path))
::
++  prefix-to-stutter
  ::  find the shortest path from any initial state to any stutter node (a state
  ::  in the SCC with a self-loop). Uses BFS. Returns the path including both
  ::  endpoints (initial state through stutter state), or ~ if no path exists.
  |=  $:  init-set=(set pg-key)  members=(set pg-key)  stutter-nodes=(list pg-key)
          nodes=(map pg-key pnode)  edges=(list pedge)
      ==
  ^-  (unit (list pg-key))
  =/  stutter-set  (silt stutter-nodes)
  =/  q=(list (list pg-key))
    (turn ~(tap in init-set) |=(k=pg-key ~[k]))
  =/  seen=(set pg-key)  init-set
  |-  ^-  (unit (list pg-key))
  ?~  q  ~
  =/  path  i.q
  =/  last  (rear path)
  ?:  (~(has in stutter-set) last)  `path
  =/  succs
    %+  turn  (skim edges |=(e=pedge =(from.e last)))
    |=(e=pedge to.e)
  =/  fresh  (skim succs |=(k=pg-key !(~(has in seen) k)))
  =.  seen  (~(gas in seen) fresh)
  =/  more  (turn fresh |=(k=pg-key (snoc path k)))
  $(q (weld t.q more))
::
++  prefix-to-bts
  ::  find the shortest path from any initial state to any state in the SCC.
  ::  Uses BFS. Returns the path or ~ if no path exists.
  |=  [init-set=(set pg-key) members=(set pg-key) edges=(list pedge)]
  ^-  (unit (list pg-key))
  =/  q=(list (list pg-key))
    (turn ~(tap in init-set) |=(k=pg-key ~[k]))
  =/  seen=(set pg-key)  init-set
  |-  ^-  (unit (list pg-key))
  ?~  q  ~
  =/  path  i.q
  =/  last  (rear path)
  ?:  (~(has in members) last)  `path
  =/  succs
    %+  turn  (skim edges |=(e=pedge =(from.e last)))
    |=(e=pedge to.e)
  =/  fresh  (skim succs |=(k=pg-key !(~(has in seen) k)))
  =.  seen  (~(gas in seen) fresh)
  =/  more  (turn fresh |=(k=pg-key (snoc path k)))
  $(q (weld t.q more))
::
++  index-of-first
  ::  find the 1-based index of the first occurrence of `target` in `lst`, or 1
  ::  if not found
  |=  [target=pg-key lst=(list pg-key)]
  ^-  @ud
  =/  idx  0
  |-  ^-  @ud
  ?~  lst  1
  =.  idx  +(idx)
  ?:(=(i.lst target) idx $(lst t.lst))
::
++  find-deepest-stutter
  ::  find the deepest (longest path from init) to any accepting stutter node
  ::  via BFS. Returns the full path from init through the stutter.
  |=  $:  init-set=(set pg-key)  members=(set pg-key)  stutter-nodes=(list pg-key)
          nodes=(map pg-key pnode)  edges=(list pedge)
      ==
  ^-  (unit (list pg-key))
  =/  stutter-set  (silt stutter-nodes)
  =/  q=(list (list pg-key))
    (turn ~(tap in init-set) |=(k=pg-key ~[k]))
  =/  seen=(set pg-key)  init-set
  =/  deepest  `~
  |-  ^-  (unit (list pg-key))
  ?~  q  deepest
  =/  path  i.q
  =/  last  (rear path)
  ?:  (~(has in stutter-set) last)
    =.  deepest  `path
    $(q t.q)
  =/  succs
    %+  turn  (skim edges |=(e=pedge =(from.e last)))
    |=(e=pedge to.e)
  =/  fresh  (skim succs |=(k=pg-key !(~(has in seen) k)))
  =.  seen  (~(gas in seen) fresh)
  =/  more  (turn fresh |=(k=pg-key (snoc path k)))
  $(q (weld t.q more))
--
