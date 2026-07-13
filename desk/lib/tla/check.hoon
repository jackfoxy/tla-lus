/-  *tla-lus
/=  ast     /lib/tla/ast
/=  syntax  /lib/tla/syntax
/=  ev      /lib/tla/eval
|%
  ::  TLC Safety Model Checking (deterministic single-worker BFS)
  ::
  ::  A first increment of unit 10: generate initial and next states from
  ::  the Init/Next predicates (the TLC assignment semantics for /\, \/,
  ::  =, \E, IF, and UNCHANGED), explore with deterministic breadth-first
  ::  search over fingerprinted states, check an invariant, detect
  ::  deadlock, and emit TLC's terminal summary (states generated /
  ::  distinct / depth) and, on an invariant violation, the shortest
  ::  behavior trace. Expression evaluation reuses lib/tla/eval; a primed
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
++  op-key  op-key:ev
::
::  +|  Environment Assembly
::
::
++  combine
  ::  the evaluation environment. In %next mode current variables are
  ::  visible under their name and partial next-state bindings under
  ::  "<name>'"; in %init mode the state being built is visible under
  ::  the plain names (there is no priming in an initial predicate).
  |=  [mode=?(%init %next) cur=state nxt=state]
  ^-  env:ev
  ?:  =(%init mode)  (~(uni by cur) nxt)
  =/  e  cur
  =/  ps  ~(tap by nxt)
  |-  ^-  env:ev
  ?~  ps  e
  $(ps t.ps, e (~(put by e) (cat 3 p.i.ps '\'') q.i.ps))
::
++  ev-bool
  |=  [mode=?(%init %next) n=node cur=state nxt=state]
  ^-  ?
  =/  v  (eval:ev n (combine mode cur nxt))
  ?>(?=(%bool -.v) p.v)
::
++  ev-val
  |=  [mode=?(%init %next) n=node cur=state nxt=state]
  ^-  value
  (eval:ev n (combine mode cur nxt))
::
::  +|  State Generation
::
::
++  assignable
  ::  if `lhs` is an assignable state variable in this mode (unprimed
  ::  identifier for %init, primed identifier for %next) that is not yet
  ::  bound in nxt, return its name
  |=  [lhs=node vars=(set @t) mode=?(%init %next) nxt=state]
  ^-  (unit @t)
  =/  nm=(unit @t)
    ?:  &(=(%next mode) (is-kind lhs %n-postfixexpr))
      =/  kids  (kids-of lhs)
      ?.  =(2 (lent kids))  ~
      ?.  =('\'' (op-name (snag 1 kids)))  ~
      `(genid-name (snag 0 kids))
    ?:  &(=(%init mode) (is-kind lhs %n-generalid))
      `(genid-name lhs)
    ~
  ?~  nm  ~
  ?.  (~(has in vars) u.nm)  ~
  ?:  (~(has by nxt) u.nm)  ~
  nm
::
++  gen
  ::  all completed states satisfying `pred`, extending the partial
  ::  next-state `nxt` (keyed by plain variable name)
  |=  [pred=node vars=(set @t) mode=?(%init %next) cur=state nxt=state]
  ^-  (list state)
  ?:  ?=(%leaf -.pred)  (filter pred vars mode cur nxt)
  ?+    kind.pred  (filter pred vars mode cur nxt)
      %n-parenexpr
    =/  kids  (kids-of pred)
    ?:((gte (lent kids) 2) (gen (snag 1 kids) vars mode cur nxt) ~)
  ::
      %n-conjlist
    %+  gen-conj  vars
    :*  mode  cur  nxt
        %+  turn  (kids-of pred)
        |=(item=node ?:((gte (lent (kids-of item)) 2) (snag 1 (kids-of item)) item))
    ==
  ::
      %n-disjlist
    %-  zing
    %+  turn  (kids-of pred)
    |=  item=node
    =/  ik  (kids-of item)
    (gen ?:((gte (lent ik) 2) (snag 1 ik) item) vars mode cur nxt)
  ::
      %n-ifthenelse
    =/  kids  (kids-of pred)
    ?:  (ev-bool mode (snag 1 kids) cur nxt)
      (gen (snag 3 kids) vars mode cur nxt)
    (gen (snag 5 kids) vars mode cur nxt)
  ::
      %n-boundquant
    (gen-exists pred vars mode cur nxt)
  ::
      %n-prefixexpr
    =/  kids  (kids-of pred)
    ?.  =(%unchanged (op-key (op-name (snag 0 kids))))
      (filter pred vars mode cur nxt)
    (gen-unchanged (snag 1 kids) vars cur nxt)
  ::
      %n-infixexpr
    =/  kids  (kids-of pred)
    ?.  =(3 (lent kids))  (filter pred vars mode cur nxt)
    =/  key  (op-key (op-name (snag 1 kids)))
    ?:  =(%and key)
      (gen-conj vars mode cur nxt ~[(snag 0 kids) (snag 2 kids)])
    ?:  =(%or key)
      %-  zing
      %+  turn  ~[(snag 0 kids) (snag 2 kids)]
      |=(d=node (gen d vars mode cur nxt))
    ?:  =(%eq key)
      =/  as  (assignable (snag 0 kids) vars mode nxt)
      ?~  as  (filter pred vars mode cur nxt)
      ~[(~(put by nxt) u.as (ev-val mode (snag 2 kids) cur nxt))]
    (filter pred vars mode cur nxt)
  ==
::
++  gen-conj
  ::  thread the partial next-state across a conjunction of predicates
  |=  [vars=(set @t) mode=?(%init %next) cur=state nxt=state conjs=(list node)]
  ^-  (list state)
  =/  acc=(list state)  ~[nxt]
  |-  ^-  (list state)
  ?~  conjs  acc
  =/  next-acc
    %-  zing
    %+  turn  acc
    |=(pn=state (gen i.conjs vars mode cur pn))
  $(conjs t.conjs, acc next-acc)
::
++  gen-exists
  ::  \E v \in S : P -- branch over each value in S (v is a constant)
  |=  [pred=node vars=(set @t) mode=?(%init %next) cur=state nxt=state]
  ^-  (list state)
  =/  kids  (kids-of pred)
  =/  qb  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  parts  (qb-parts ?~(qb ~ (kids-of i.qb)))
  =/  dom  (as-set:ev (ev-val mode range.parts cur nxt))
  =/  body  (rear kids)
  =/  vn  ?~(vars.parts '' i.vars.parts)
  %-  zing
  %+  turn  dom
  |=  x=value
  (gen body vars mode (~(put by cur) vn x) nxt)
::
++  qb-parts
  |=  kids=(list node)
  ^-  [vars=(list @t) range=node]
  =/  vars=(list @t)
    %+  murn  kids
    |=  k=node
    ^-  (unit @t)
    ?.  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))  ~
    `(leaf-text k)
  =/  range
    =/  ks  kids
    |-  ^-  node
    ?~  ks  !!
    ?:  &(?=(%leaf -.i.ks) =(%t-in (leaf-kind i.ks)))
      ?~(t.ks !! i.t.ks)
    $(ks t.ks)
  [vars range]
::
++  gen-unchanged
  ::  UNCHANGED v / UNCHANGED <<a, b>> -- bind each named variable to its
  ::  current value
  |=  [arg=node vars=(set @t) cur=state nxt=state]
  ^-  (list state)
  =/  names=(list @t)
    ?:  (is-kind arg %n-generalid)  ~[(genid-name arg)]
    %+  murn  (kids-of arg)
    |=  k=node
    ^-  (unit @t)
    ?.  (is-kind k %n-generalid)  ~
    `(genid-name k)
  =/  out=state  nxt
  =.  out
    |-  ^-  state
    ?~  names  out
    =/  cv  (~(get by cur) i.names)
    ?~  cv  $(names t.names)
    $(names t.names, out (~(put by out) i.names u.cv))
  ~[out]
::
++  filter
  ::  a boolean constraint: keep the partial state iff it evaluates true
  |=  [pred=node vars=(set @t) mode=?(%init %next) cur=state nxt=state]
  ^-  (list state)
  ?:  (ev-bool mode pred cur nxt)  ~[nxt]  ~
::
::  +|  Fingerprinting
::
::
++  fingerprint
  ::  a canonical key for a state: sorted "var=<rendered value>" pairs
  |=  st=state
  ^-  @t
  %+  roll  (sort ~(tap by st) |=([a=[k=@t *] b=[k=@t *]] (aor k.a k.b)))
  |=  [[k=@t v=value] acc=@t]
  (cat 3 acc (crip "{(trip k)}={(render:ev v)};"))
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
++  cfg-value
  ::  the identifier following a config keyword (INIT/NEXT/INVARIANT)
  |=  [cfg=@t key=@t]
  ^-  (unit @t)
  =/  toks  (cfg-tokens cfg)
  |-  ^-  (unit @t)
  ?~  toks  ~
  ?:  =(key i.toks)  ?~(t.toks ~ `i.t.toks)
  $(toks t.toks)
::
++  cfg-tokens
  ::  whitespace-separated words of a .cfg, comments stripped
  |=  cfg=@t
  ^-  (list @t)
  %+  murn  `(list @t)`(sto (crip (sub-comments (trip cfg))))
  |=(w=@t ?:(=('' w) ~ `w))
::
++  sto
  ::  split on whitespace
  |=  t=@t
  ^-  (list @t)
  =/  words  (fell (trip t))
  (turn words crip)
::
++  fell
  |=  t=tape
  ^-  (list tape)
  =/  ws  |=(c=@tD |(=(' ' c) =('\0a' c) =('\09' c) =('\0d' c)))
  =|  cur=tape
  =|  out=(list tape)
  |-  ^-  (list tape)
  ?~  t
    ?~(cur (flop out) (flop [(flop cur) out]))
  ?:  (ws i.t)
    ?~(cur $(t t.t) $(t t.t, cur ~, out [(flop cur) out]))
  $(t t.t, cur [i.t cur])
::
++  sub-comments
  ::  drop `\*` line comments (cfg uses TLA-style comments)
  |=  t=tape
  ^-  tape
  |-  ^-  tape
  ?~  t  ~
  ?:  ?&(=('\\' i.t) ?=(^ t.t) =('*' i.t.t))
    $(t (skip-line t.t))
  [i.t $(t t.t)]
::
++  skip-line
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?:(=('\0a' i.t) t $(t t.t))
::
::  +|  Breadth-First Exploration
::
::
+$  visit  [depth=@ud pred=@t st=state]
+$  outcome
  $%  [%ok gen=@ud distinct=@ud depth=@ud]
      [%inv gen=@ud distinct=@ud depth=@ud trace=(list state) name=@t]
      [%deadlock gen=@ud distinct=@ud depth=@ud trace=(list state)]
      [%limited gen=@ud distinct=@ud depth=@ud]
  ==
::
++  explore
  ::  deterministic BFS from the initial states; stops at the first
  ::  invariant violation or (unless disabled) deadlock, in BFS order.
  ::  `cap` bounds the distinct-state count (0 = unbounded); exceeding it
  ::  yields %limited with the statistics so far, so a caller can bound a
  ::  single event's work.
  |=  $:  init=node
          next=node
          inv=(unit node)
          inv-name=@t
          vars=(set @t)
          cap=@ud
      ==
  ^-  outcome
  =/  inits  (gen init vars %init ~ ~)
  =|  seen=(map @t visit)
  =/  gen-count  (lent inits)
  =|  distinct=@ud
  =|  max-depth=@ud
  =|  queue=(list @t)   ::  fingerprints, in BFS order
  ::  register the initial states, checking the invariant on each
  =/  reg
    |=  [sts=(list state) d=@ud pred=@t s=_seen q=_queue di=@ud md=@ud]
    ^-  [inv=(unit [trace=(list state) st=state]) s=_seen q=_queue di=@ud md=@ud]
    |-  ^-  [inv=(unit [trace=(list state) st=state]) s=_seen q=_queue di=@ud md=@ud]
    ?~  sts  [~ s q di md]
    =/  fp  (fingerprint i.sts)
    ?:  (~(has by s) fp)  $(sts t.sts)
    =.  s   (~(put by s) fp [d pred i.sts])
    =.  q   (snoc q fp)
    =.  di  +(di)
    =.  md  (max md d)
    ?:  ?&(?=(^ inv) !(ev-bool %init u.inv i.sts ~))
      [`[(trace-to s fp) i.sts] s q di md]
    $(sts t.sts)
  =/  ir  (reg inits 1 '' seen queue distinct max-depth)
  =.  seen  s.ir
  =.  queue  q.ir
  =.  distinct  di.ir
  =.  max-depth  md.ir
  ?^  inv.ir
    [%inv gen-count distinct max-depth trace.u.inv.ir inv-name]
  ::  breadth-first loop
  |-  ^-  outcome
  ?:  ?&(!=(0 cap) (gth distinct cap))
    [%limited gen-count distinct max-depth]
  ?~  queue  [%ok gen-count distinct max-depth]
  =/  fp  i.queue
  =/  vis  (~(got by seen) fp)
  =/  nexts  (gen next vars %next st.vis ~)
  ?~  nexts
    [%deadlock gen-count distinct max-depth (trace-to seen fp)]
  =.  gen-count  (add gen-count (lent nexts))
  =/  rr  (reg nexts +(depth.vis) fp seen t.queue distinct max-depth)
  =.  seen  s.rr
  =.  distinct  di.rr
  =.  max-depth  md.rr
  ?^  inv.rr
    [%inv gen-count distinct max-depth trace.u.inv.rr name=inv-name]
  ::  q.rr is t.queue with the new frontier appended (reg snoc'd onto it)
  $(queue q.rr)
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
++  render-state
  ::  variable bindings of a trace state, one `var = value` per line,
  ::  variables in sorted order
  |=  st=state
  ^-  wain
  %+  turn  (sort ~(tap by st) |=([a=[k=@t *] b=[k=@t *]] (aor k.a k.b)))
  |=  [k=@t v=value]
  (crip "{(trip k)} = {(render:ev v)}")
::
++  render-trace
  ::  `State N: <label>` blocks; state 1 is the initial predicate, later
  ::  states are labeled with the Next action's source span
  |=  [trace=(list state) next-label=@t]
  ^-  wain
  =/  i  1
  %-  zing
  |-  ^-  (list wain)
  ?~  trace  ~
  =/  label  ?:(=(1 i) '<Initial predicate>' next-label)
  :_  $(trace t.trace, i +(i))
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
  |=  [gen=@ud distinct=@ud depth=@ud]
  ^-  wain
  :~  (crip "{(a-tape gen)} states generated, {(a-tape distinct)} distinct states found, 0 states left on queue.")
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
  |=  [init=node next=node vars=(set @t)]
  ^-  graph
  =/  is  (gen init vars %init ~ ~)
  =/  gen-count  (lent is)
  ::  register the initial states (depth 1, no predecessor)
  =/  reg=[seen=(map @t visit) inits=(list @t) distinct=@ud depth=@ud queue=(list @t)]
    =|  seen=(map @t visit)
    =|  inits=(list @t)
    =/  distinct=@ud  0
    =/  depth=@ud  0
    =|  queue=(list @t)
    |-  ^-  [(map @t visit) (list @t) @ud @ud (list @t)]
    ?~  is  [seen inits distinct depth queue]
    =/  fp  (fingerprint i.is)
    ?:  (~(has by seen) fp)  $(is t.is)
    %=  $
      is        t.is
      seen      (~(put by seen) fp [1 '' i.is])
      inits     (snoc inits fp)
      queue     (snoc queue fp)
      distinct  +(distinct)
      depth     (max depth 1)
    ==
  =/  seen  seen.reg
  =/  inits  inits.reg
  =/  distinct  distinct.reg
  =/  depth  depth.reg
  =/  queue  queue.reg
  ::  breadth-first over the queue
  |-  ^-  graph
  ?~  queue  [seen inits gen-count distinct depth]
  =/  fp   i.queue
  =/  vis  (~(got by seen) fp)
  =/  nexts  (gen next vars %next st.vis ~)
  =.  gen-count  (add gen-count (lent nexts))
  =/  nd  +(depth.vis)
  =^  add-fps  seen
    =|  new=(list @t)
    |-  ^-  [(list @t) (map @t visit)]
    ?~  nexts  [new seen]
    =/  nfp  (fingerprint i.nexts)
    ?:  (~(has by seen) nfp)  $(nexts t.nexts)
    %=  $
      nexts     t.nexts
      new       (snoc new nfp)
      seen      (~(put by seen) nfp [nd fp i.nexts])
    ==
  =.  distinct  (add distinct (lent add-fps))
  =.  depth  ?~(add-fps depth (max depth nd))
  $(queue (weld t.queue add-fps))
::
++  unwrap-prop
  ::  classify a temporal property: <>P (%diamond), []<>P (%boxdiamond),
  ::  []P (%box), or unsupported (%none); `inner` is the state predicate P
  |=  n=node
  ^-  [kind=?(%diamond %boxdiamond %box %none) inner=node]
  =/  m  (unparen n)
  ?.  (is-kind m %n-prefixexpr)  [%none m]
  =/  kids  (kids-of m)
  ?.  =(2 (lent kids))  [%none m]
  =/  op  (op-name (snag 0 kids))
  =/  arg  (unparen (snag 1 kids))
  ?:  =('<>' op)  [%diamond arg]
  ?.  =('[]' op)  [%none m]
  ?.  (is-kind arg %n-prefixexpr)  [%box arg]
  =/  ak  (kids-of arg)
  ?.  =(2 (lent ak))  [%box arg]
  ?.  =('<>' (op-name (snag 0 ak)))  [%box arg]
  [%boxdiamond (unparen (snag 1 ak))]
::
++  unparen
  |=  n=node
  ^-  node
  ?.  (is-kind n %n-parenexpr)  n
  =/  kids  (kids-of n)
  ?:((gte (lent kids) 2) (unparen (snag 1 kids)) n)
::
++  check-live
  ::  a first-increment liveness check under no fairness: every reachable
  ::  state may stutter forever, so <>P fails when an initial state has
  ::  ~P and []<>P fails when any reachable state has ~P (stutter there)
  |=  [prop=node name=@t g=graph]
  ^-  [ok=? trace=(list state)]
  =/  up  (unwrap-prop prop)
  ?:  ?=(%none kind.up)  [& ~]
  =/  holds  |=(st=state (ev-bool %init inner.up st ~))
  ?:  ?=(%diamond kind.up)
    ::  the first initial state (in generation order) violating P
    =/  bad
      |-  ^-  (unit @t)
      ?~  inits.g  ~
      ?.  (holds st:(~(got by seen.g) i.inits.g))  `i.inits.g
      $(inits.g t.inits.g)
    ?~  bad  [& ~]
    [| (trace-to seen.g u.bad)]
  ::  %boxdiamond / %box: the shallowest reachable state violating P
  =/  entries  ~(tap by seen.g)
  =/  bad
    %+  roll  entries
    |=  [[fp=@t v=visit] best=(unit [d=@ud fp=@t])]
    ?:  (holds st.v)  best
    ?:  ?&(?=(^ best) (lte d.u.best depth.v))  best
    `[depth.v fp]
  ?~  bad  [& ~]
  [| (trace-to seen.g fp.u.bad)]
::
++  render-live-trace
  ::  a lasso counterexample: the prefix states then a `Stuttering` step
  |=  [trace=(list state) next-label=@t]
  ^-  wain
  =/  base  (render-trace trace next-label)
  (snoc base (crip "State {(a-tape +((lent trace)))}: Stuttering"))
::
::  +|  Seeded Simulation (bounded, reproducible)
::
::
+$  sim-result
  $:  traces=@ud       ::  behaviors simulated
      steps=@ud        ::  state transitions taken
      viol=(unit (list state))  ::  an invariant-violating behavior, if hit
  ==
::
++  nth-state
  ::  index into a state list; the dry sample widens a ?~-narrowed list
  ::  past the wet +snag (the recursive value mold otherwise mull-grows)
  |=  [i=@ud l=(list state)]
  ^-  state
  (snag i l)
::
++  walk
  ::  a single random behavior from `start`: at each step pick a uniformly
  ::  random next state (reproducibly, from the RNG core), up to `depth`
  ::  transitions, stopping early on a deadlock or invariant violation
  |=  $:  start=state
          next=node
          inv=(unit node)
          vars=(set @t)
          rng=_og
          depth=@ud
      ==
  ^-  [trace=(list state) viol=(unit (list state)) steps=@ud rng=_og]
  =/  cur=state       start
  =/  path=(list state)  ~[start]
  =/  n     0
  |-  ^-  [(list state) (unit (list state)) @ud _og]
  ?:  ?&(?=(^ inv) !(ev-bool %init u.inv cur ~))
    [(flop path) `(flop path) n rng]
  ?:  =(n depth)  [(flop path) ~ n rng]
  =/  nexts  (gen next vars %next cur ~)
  ?:  =(~ nexts)  [(flop path) ~ n rng]
  =^  idx  rng  (rads:rng (lent nexts))
  =/  pick  (nth-state idx nexts)
  $(cur pick, path [pick path], n +(n), rng rng)
::
++  simulate
  ::  bounded seeded simulation: up to `traces` random behaviors, each up
  ::  to `depth` transitions. Deterministic in `seed`, so two runs with the
  ::  same seed and limits produce the same result (reproducibility) and
  ::  the limits always terminate with partial statistics
  |=  $:  init=node
          next=node
          inv=(unit node)
          vars=(set @t)
          seed=@
          traces=@ud
          depth=@ud
      ==
  ^-  sim-result
  =/  inits  (gen init vars %init ~ ~)
  ?:  =(~ inits)  [0 0 ~]
  =/  rng  ~(. og seed)
  =/  t     0
  =/  steps=@ud  0
  |-  ^-  sim-result
  ?:  =(t traces)  [t steps ~]
  =^  i0  rng  (rads:rng (lent inits))
  =/  start  (nth-state i0 inits)
  =/  wr  (walk start next inv vars rng depth)
  =.  steps  (add steps steps.wr)
  =.  rng    rng.wr
  ?^  viol.wr  [+(t) steps viol.wr]
  $(t +(t))
::
++  simulate-spec
  ::  run a bounded seeded simulation from spec + config source, returning
  ::  a structured summary (traces / steps / whether a violation was found)
  |=  [spec=@t cfg=@t seed=@ traces=@ud depth=@ud]
  ^-  sim-result
  =/  pr  (parse:syntax spec)
  ?:  ?=(%| -.pr)  [0 0 ~]
  =/  tree  p.pr
  =/  vars  (var-names tree)
  =/  in  (cfg-value cfg 'INIT')
  =/  nx  (cfg-value cfg 'NEXT')
  =/  iv  (cfg-value cfg 'INVARIANT')
  ?~  in  [0 0 ~]
  ?~  nx  [0 0 ~]
  =/  ib  (body-of-def tree u.in)
  =/  nb  (body-of-def tree u.nx)
  ?~  ib  [0 0 ~]
  ?~  nb  [0 0 ~]
  =/  inv  ?~(iv ~ (body-of-def tree u.iv))
  (simulate u.ib u.nb inv vars seed traces depth)
::
++  check
  ::  model-check a spec + config, returning TLC's terminal output lines
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  pr  (parse:syntax spec)
  ?:  ?=(%| -.pr)  ~['Parse error']
  =/  tree  p.pr
  =/  vars  (var-names tree)
  =/  in  (cfg-value cfg 'INIT')
  =/  nx  (cfg-value cfg 'NEXT')
  =/  iv  (cfg-value cfg 'INVARIANT')
  =/  pp  (cfg-value cfg 'PROPERTY')
  ?~  in  ~['No INIT']
  ?~  nx  ~['No NEXT']
  =/  init-body  (body-of-def tree u.in)
  =/  next-body  (body-of-def tree u.nx)
  ?~  init-body  ~['No Init def']
  ?~  next-body  ~['No Next def']
  =/  nl  (next-span-label u.next-body (module-name-of tree))
  ::  liveness: a temporal PROPERTY
  ?^  pp
    =/  prop-body  (body-of-def tree u.pp)
    ?~  prop-body  ~['No property def']
    =/  g  (build-graph u.init-body u.next-body vars)
    =/  lr  (check-live u.prop-body u.pp g)
    ?:  ok.lr
      :-  'Model checking completed. No error has been found.'
      (counts-lines gen.g distinct.g depth.g)
    ;:  weld
      ~[(crip "Error: Temporal property {(trip u.pp)} was violated.")]
      ~['Error: The following behavior constitutes a counter-example:']
      (render-live-trace trace.lr nl)
      (counts-lines gen.g distinct.g depth.g)
    ==
  ::  safety: an INVARIANT
  =/  inv-body  ?~(iv ~ (body-of-def tree u.iv))
  =/  res  (explore u.init-body u.next-body inv-body ?~(iv '' u.iv) vars 0)
  ?-    -.res
      %ok
    :-  'Model checking completed. No error has been found.'
    (counts-lines gen.res distinct.res depth.res)
  ::
      %limited
    :-  'Model checking stopped: state limit reached.'
    (counts-lines gen.res distinct.res depth.res)
  ::
      %inv
    ;:  weld
      ~[(crip "Error: Invariant {(trip name.res)} is violated.")]
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl)
      (counts-lines gen.res distinct.res depth.res)
    ==
  ::
      %deadlock
    ;:  weld
      ~['Error: Deadlock reached.']
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl)
      (counts-lines gen.res distinct.res depth.res)
    ==
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
  =/  pr  (parse:syntax spec)
  ?:  ?=(%| -.pr)  [[%failed 'parse error'] *run-stats]
  =/  tree  p.pr
  =/  vars  (var-names tree)
  =/  in  (cfg-value cfg 'INIT')
  =/  nx  (cfg-value cfg 'NEXT')
  =/  iv  (cfg-value cfg 'INVARIANT')
  =/  pp  (cfg-value cfg 'PROPERTY')
  ?~  in  [[%failed 'no INIT in config'] *run-stats]
  ?~  nx  [[%failed 'no NEXT in config'] *run-stats]
  =/  ib  (body-of-def tree u.in)
  =/  nb  (body-of-def tree u.nx)
  ?~  ib  [[%failed 'no Init definition'] *run-stats]
  ?~  nb  [[%failed 'no Next definition'] *run-stats]
  ::  liveness (temporal property)
  ?^  pp
    =/  prop  (body-of-def tree u.pp)
    ?~  prop  [[%failed 'no property definition'] *run-stats]
    =/  g   (build-graph u.ib u.nb vars)
    =/  st  [gen.g distinct.g 0 depth.g]
    =/  lr  (check-live u.prop u.pp g)
    ?:  ok.lr  [[%ok st] st]
    [[%violated [%property u.pp] st] st]
  ::  safety (invariant)
  =/  inv-body  ?~(iv ~ (body-of-def tree u.iv))
  =/  o  (explore u.ib u.nb inv-body ?~(iv '' u.iv) vars cap)
  ?-    -.o
      %ok        =/  st  [gen.o distinct.o 0 depth.o]  [[%ok st] st]
      %limited   =/  st  [gen.o distinct.o 0 depth.o]  [[%limited %states st] st]
      %inv       =/  st  [gen.o distinct.o 0 depth.o]  [[%violated [%invariant name.o] st] st]
      %deadlock  =/  st  [gen.o distinct.o 0 depth.o]  [[%violated [%deadlock ~] st] st]
  ==
--

