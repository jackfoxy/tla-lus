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
--
