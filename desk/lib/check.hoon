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
      outdeg=@ud   ::  max newly-distinct successors of any state (TLC max out-degree)
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
  [is ~ ~ ~ (lent is) 0 0 0]
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
  ::  initial state), needed to evaluate action constraints.
  ::  (Simplification vs TLC: TLC still checks invariants on constraint-pruned
  ::  states; we skip them. No corpus case combines a constraint with an
  ::  invariant on the pruned boundary — documented in the parity ledger.)
  |=  [o=bfs-opts cur=bfs-cursor st=state d=@ud pred=@t prev=(unit state)]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  =/  e  (env-of o)
  =/  ch  (con-hold cons.o st e)
  ?:  ?=(%| -.ch)  [`[%error p.ch] cur]
  ?.  p.ch  [~ cur]
  ?^  prev
    =/  ah  (acon-hold acons.o u.prev st e)
    ?:  ?=(%| -.ah)  [`[%error p.ah] cur]
    ?.  p.ah  [~ cur]
    (register-in o cur st d pred e)
  (register-in o cur st d pred e)
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
  =.  outdeg.cur.rr  (max outdeg.cur.rr (sub distinct.cur.rr before))
  $(cur cur.rr, spent (add spent cost))
::
++  explore
  ::  deterministic BFS from the initial states; stops at the first
  ::  invariant violation or (unless disabled) deadlock, in BFS order.
  ::  `cap` bounds the distinct-state count (0 = unbounded); exceeding it
  ::  yields %limited with the statistics so far, so a caller can bound a
  ::  single event's work.
  |=  [is=(list state) o=bfs-opts]
  ^-  outcome
  =/  cur  (bfs-init is)
  |-  ^-  outcome
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)  out.r
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
::  +|  Resumable Liveness Scan (unit P2-1)
::
+$  scan-slice
  $%  [%more todo=(list @t) best=(unit [d=@ud fp=@t])]
      [%done bad=(unit @t)]
  ==
::
++  live-todo
  ::  the ordered scan worklist for a property kind over a built graph
  |=  [kind=?(%diamond %boxdiamond %box) seen=(map @t visit) inits=(list @t)]
  ^-  (list @t)
  ?:  ?=(%diamond kind)  inits
  (turn ~(tap by seen) |=([fp=@t *] fp))
::
++  live-scan
  ::  process up to `budget` fingerprints of the worklist, replicating
  ::  +check-live's selection: the first violating initial state for
  ::  <>P; the shallowest reachable violator (first seen wins ties, in
  ::  worklist order) for []P and []<>P
  |=  $:  kind=?(%diamond %boxdiamond %box)
          inner=node
          seen=(map @t visit)
          todo=(list @t)
          best=(unit [d=@ud fp=@t])
          budget=@ud
      ==
  ^-  scan-slice
  =/  spent  0
  |-  ^-  scan-slice
  ?~  todo
    [%done ?~(best ~ `fp.u.best)]
  ?:  (gte spent budget)  [%more todo best]
  =/  v   (~(got by seen) i.todo)
  =/  ok  (ev-bool %init inner st.v ~)
  ?:  ?=(%diamond kind)
    ?.  ok  [%done `i.todo]
    $(todo t.todo, spent +(spent))
  =?  best  ?&(!ok |(?=(~ best) (gth d.u.best depth.v)))
    `[depth.v i.todo]
  $(todo t.todo, spent +(spent))
::
::  +|  Seeded Simulation (bounded, reproducible, resumable)
::
::
+$  sim-result
  $:  traces=@ud       ::  behaviors simulated
      steps=@ud        ::  state transitions taken
      viol=(unit (list state))  ::  an invariant-violating behavior, if hit
  ==
::  fixed parameters of one simulation run
+$  sim-opts
  $:  next=node
      inv=(unit node)
      vars=(set @t)
      num=@ud     ::  behaviors to simulate
      depth=@ud   ::  transitions per behavior
  ==
::  everything required to resume a run byte-identically; the RNG is
::  saved as its raw sample, so slicing cannot change the choices
+$  sim-cursor
  $:  seed=@
      inits=(list state)
      t=@ud               ::  behaviors completed
      steps=@ud
      maxn=@ud            ::  deepest transition index reached
      walk=(unit [cur=state path=(list state) n=@ud])
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
++  sim-init
  |=  [init=node vars=(set @t) seed=@]
  ^-  sim-cursor
  [seed (gen init vars %init ~ ~) 0 0 0 ~]
::
++  sim-step
  ::  spend up to `budget` work units (one per transition or behavior
  ::  boundary). The RNG call sequence is identical for every slicing,
  ::  so the run is a pure function of [opts cursor].
  ::  narrowing note: the walk option is tested via a local copy so the
  ::  recursion can always assign a fresh wide cursor
  |=  [o=sim-opts cur=sim-cursor budget=@ud]
  ^-  sim-slice
  ?:  =(~ inits.cur)  [%done [0 0 ~] cur]
  =/  rng  ~(. og seed.cur)
  =/  spent  0
  |-  ^-  sim-slice
  ?:  (gte spent budget)  [%more cur(seed +<.rng)]
  ?:  =(num.o t.cur)  [%done [t.cur steps.cur ~] cur(seed +<.rng)]
  =/  mw  walk.cur
  ?~  mw
    ::  begin a new behavior at a random initial state
    =^  i0  rng  (rads:rng (lent inits.cur))
    =/  start  (nth-state i0 inits.cur)
    $(cur cur(walk `[start ~[start] 0]), spent +(spent))
  =/  w  u.mw
  ?:  ?&(?=(^ inv.o) !(ev-bool %init u.inv.o cur.w ~))
    :+  %done
      [+(t.cur) steps.cur `(flop path.w)]
    cur(seed +<.rng)
  ?:  =(n.w depth.o)
    $(cur cur(walk ~, t +(t.cur)), spent +(spent))
  =/  nexts  (gen next.o vars.o %next cur.w ~)
  ?:  =(~ nexts)
    $(cur cur(walk ~, t +(t.cur)), spent +(spent))
  =^  idx  rng  (rads:rng (lent nexts))
  =/  pick  (nth-state idx nexts)
  %=  $
    spent  +(spent)
    cur
    %=  cur
      walk   `[pick [pick path.w] +(n.w)]
      steps  +(steps.cur)
      maxn   (max maxn.cur +(n.w))
    ==
  ==
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
  =/  o=sim-opts  [next inv vars traces depth]
  =/  cur  (sim-init init vars seed)
  |-  ^-  sim-result
  =/  r  (sim-step o cur 1.024)
  ?:  ?=(%done -.r)  res.r
  $(cur cur.r)
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
  =/  nm  (cfg-names cfg)
  ?~  nm  [0 0 ~]
  =/  in  in.u.nm
  =/  nx  nx.u.nm
  =/  iv  iv.u.nm
  ?~  in  [0 0 ~]
  ?~  nx  [0 0 ~]
  =/  ib  (body-of-def tree u.in)
  =/  nb  (body-of-def tree u.nx)
  ?~  ib  [0 0 ~]
  ?~  nb  [0 0 ~]
  =/  inv  ?~(iv ~ (body-of-def tree u.iv))
  (simulate u.ib u.nb inv vars seed traces depth)
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
  ::  arity-0 config constant assignments as an evaluation binding map (WU6.9
  ::  task 1); operator-valued constants are a later increment
  |=  cs=(list cfg-const:config)
  ^-  (map @t value)
  (malt (murn cs |=(c=cfg-const:config ?~(args.c `[lhs.c val.c] ~))))
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
    :(weld (trip nm) " " (kind-name p.r) " " (render:vl p.r))
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
  ::  EC 2105 (assumption-error). ~ when all assumptions hold. (TLC skips
  ::  axioms; we check every assumption — axiom marking is a documented residue.)
  |=  [asmz=(list sem-thm:sem-lib) e=eenv:ne]
  ^-  (unit [ec=@ud msg=@t])
  ?~  asmz  ~
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
  ::  and the console `wain` — `Model checking completed…` for a pass, else the
  ::  `Temporal property … was violated.` counter-example (numbered `State N:`
  ::  trace with getActions labels, `Stuttering` / `Back to state N:` closer,
  ::  and the reachability counts).
  |=  $:  oss=(list oos:tp)  states=(map @t state:ne)  inits=(list @t)
          nsb=sem:sem-lib  env=eenv:ne  order=(list @t)  modn=@t
          defs=(map @t sem-def:sem-lib)  pname=@t
          gen=@ud  distinct=@ud  depth=@ud
      ==
  ^-  [lasso=(unit lasso:lv) report=wain]
  =/  l       (find-lasso:lv oss states inits nsb env order)
  =/  footer  (counts-lines gen distinct 0 depth)
  ?~  l
    [~ ['Model checking completed. No error has been found.' footer]]
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
  :-  l
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
  ::  liveness: a temporal PROPERTY (built via node-eval; the property's
  ::  state-predicate scan still runs on the CST body — a WU6.9 residue)
  ?^  pp.c
    =/  prop-body  (body-of-def tree.c u.pp.c)
    ?~  prop-body  ~['No property def']
    =/  o=bfs-opts  [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | 0 0]
    =/  g  (build-graph is.c o)
    =/  lr  (check-live u.prop-body u.pp.c g)
    ?:  ok.lr
      :-  'Model checking completed. No error has been found.'
      (counts-lines gen.g distinct.g 0 depth.g)
    ;:  weld
      ~[(crip "Error: Temporal property {(trip u.pp.c)} was violated.")]
      ~['Error: The following behavior constitutes a counter-example:']
      (render-live-trace trace.lr nl.c)
      (counts-lines gen.g distinct.g 0 depth.g)
    ==
  ::  safety: an INVARIANT
  =/  o=bfs-opts  [nsb.c invs.c cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c 0 0]
  (render-outcome (explore is.c o) nl.c)
::
++  render-outcome
  ::  TLC's terminal lines for a safety outcome
  |=  [res=outcome nl=@t]
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
      (render-trace trace.res nl)
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      %deadlock
    ;:  weld
      ~['Error: Deadlock reached.']
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl)
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
  ::  liveness (temporal property)
  ?^  pp.c
    =/  prop  (body-of-def tree.c u.pp.c)
    ?~  prop  [[%failed 'no property definition'] *run-stats]
    =/  o=bfs-opts  [nsb.c ~ ~ ~ vars.c order.c perms.c defs.c consts.c | 0 0]
    =/  g   (build-graph is.c o)
    =/  st  [gen.g distinct.g 0 depth.g]
    =/  lr  (check-live u.prop u.pp.c g)
    ?:  ok.lr  [[%ok st] st]
    [[%violated [%property u.pp.c] st] st]
  ::  safety (invariant)
  =/  o=bfs-opts  [nsb.c invs.c cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c cap 0]
  =/  res  (explore is.c o)
  ?-    -.res
      %ok        =/  st  [gen.res distinct.res queued.res depth.res]  [[%ok st] st]
      %limited   =/  st  [gen.res distinct.res queued.res depth.res]  [[%limited what.res st] st]
      %inv       =/  st  [gen.res distinct.res queued.res depth.res]  [[%violated [%invariant name.res] st] st]
      %deadlock  =/  st  [gen.res distinct.res queued.res depth.res]  [[%violated [%deadlock ~] st] st]
      %error     [[%failed msg.res] *run-stats]
  ==
::
++  run-stats-full
  ::  the final statistics of a safety search including the max out-degree that
  ::  the wire run-stats does not carry, run in `budget`-sized slices (for
  ::  statistics and pause/resume-equality differential tests)
  |=  [spec=@t cfg=@t cap=@ud budget=@ud]
  ^-  [gen=@ud distinct=@ud queued=@ud depth=@ud outdeg=@ud]
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [0 0 0 0 0]
  =*  c  p.sc
  =/  o=bfs-opts
    [nsb.c invs.c cons.c acons.c vars.c order.c perms.c defs.c consts.c ddl.c cap 0]
  =/  cur  (explore-cursor is.c o budget)
  [gen.cur distinct.cur (lent queue.cur) depth.cur outdeg.cur]
--

