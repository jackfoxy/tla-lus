::  temporal.hoon — temporal-property normalization to live expressions
::  (Work Unit 8.1, Phase C step C2). Port of tlc2.tool.liveness.Liveness
::  processLiveness/astToLive + LiveExprNode simplify/toDNF/pushNeg and the
::  OrderOfSolution/PossibleErrorModel decomposition, over Work Unit 3 semantic
::  nodes. The parity target is tools/oracle/LivenessStruct.java's projection
::  (desk/test-data/liveness/<case>/struct.txt).
::
::  The live-expression tree is the zuse-408 recursive-mold hazard: every node
::  is a named `+$` with a constant-head record and EVERY recursion over it is
::  hand-rolled (never turn/roll/flop/snoc — the wet gates fuse-loop the mold).
/-  *tla-lus
/=  sm      /lib/semantic
/=  ne      /lib/node-eval
/=  config  /lib/config
|%
::  a typed rejection surfaced during normalization (astToLive constant-leaf
::  evaluation): an EC code and message, matching the pin's Assert.fail
+$  aerr  [ec=@ud msg=@t]
::  +|  Live-expression tree (LN* analogue)
::
+$  live-expr
  $+  live-expr
  $%  le-conj  le-disj  le-neg  le-next  le-all  le-even
      le-act  le-state  le-enabled  le-bool
  ==
::  boolean junctions
+$  le-conj
  $+  le-conj
  $:  %conj
      cs=(list live-expr)
  ==
+$  le-disj
  $+  le-disj
  $:  %disj
      ds=(list live-expr)
  ==
::  temporal / negation unary operators
+$  le-neg
  $+  le-neg
  $:  %neg
      b=live-expr
  ==
+$  le-next
  $+  le-next
  $:  %next
      b=live-expr
  ==
+$  le-all
  $+  le-all
  $:  %all
      b=live-expr
  ==
+$  le-even
  $+  le-even
  $:  %even
      b=live-expr
  ==
::  leaves. `sub` is the subscript of an action/enabled (`<A>_e`), ~ for a bare
::  action predicate; `a`/`p` is the underlying semantic node (carried for its
::  level and span); `box` distinguishes `[A]_e` from `<A>_e`.
+$  le-act
  $+  le-act
  $:  %act
      box=?
      sub=(unit sem:sm)
      a=sem:sm
  ==
+$  le-state
  $+  le-state
  $:  %state
      p=sem:sm
  ==
+$  le-enabled
  $+  le-enabled
  $:  %enabled
      box=?
      sub=(unit sem:sm)
      p=sem:sm
  ==
+$  le-bool
  $+  le-bool
  $:  %bool
      b=?
  ==
::
::  the OrderOfSolution / PossibleErrorModel decomposition
+$  pem
  $:  ae-action=(list @ud)   ::  []<>A indices into check-action (weak fairness)
      ae-state=(list @ud)    ::  []<>S indices into check-state
      ea-action=(list @ud)   ::  <>[]A indices into check-action (strong fairness)
  ==
+$  oos
  $:  tf=(unit live-expr)         ::  the tableau formula (null when pure fairness)
      promises=(list live-expr)   ::  the <>-promises in tf's closure
      check-state=(list live-expr)
      check-action=(list live-expr)
      pems=(list pem)
  ==
::
::  +|  Node level and action-containment (LiveExprNode getLevel/containAction)
::
++  le-level
  |=  x=live-expr
  ^-  @ud
  ?-  -.x
    %bool     0
    %state    1
    %enabled  1
    %act      2
    %next     (le-level b.x)
    %neg      (le-level b.x)
    %all      3
    %even     3
    %conj     (max-level cs.x)
    %disj     (max-level ds.x)
  ==
::
++  max-level
  |=  l=(list live-expr)
  ^-  @ud
  =|  m=@ud
  |-  ^-  @ud
  ?~  l  m
  $(l t.l, m (max m (le-level i.l)))
::
++  contain-action
  |=  x=live-expr
  ^-  ?
  ?-  -.x
    %act      &
    %state    |
    %enabled  |
    %bool     |
    %neg      (contain-action b.x)
    %next     (contain-action b.x)
    %all      (contain-action b.x)
    %even     (contain-action b.x)
    %conj     (any-contain-action cs.x)
    %disj     (any-contain-action ds.x)
  ==
::
++  any-contain-action
  |=  l=(list live-expr)
  ^-  ?
  ?~  l  |
  ?:  (contain-action i.l)  &
  $(l t.l)
::
::  +|  Structural equality (leaves by span + subscript + box)
::
++  sspan-of
  |=  s=sem:sm
  ^-  (unit span)
  ?-  -.s
    %apply    at.s
    %letin    at.s
    %lit      at.s
    %atref    at.s
    %nullodn  ~
  ==
::
++  letin-at
  ::  a LET node with its span replaced by `a` (so a non-temporal LET leaf
  ::  renders at its body's span, matching TLC, while keeping its bindings)
  |=  [n=sem-letin:sm a=(unit span)]
  ^-  sem:sm
  n(at a)
::
++  le-equal
  |=  [a=live-expr b=live-expr]
  ^-  ?
  ?.  =(-.a -.b)  |
  ?-  -.a
      %bool     ?>(?=(%bool -.b) =(b.a b.b))
      %state    ?>(?=(%state -.b) =((sspan-of p.a) (sspan-of p.b)))
  ::
      %enabled
    ?>  ?=(%enabled -.b)
    ?&  =(box.a box.b)
        =((sub-span sub.a) (sub-span sub.b))
        =((sspan-of p.a) (sspan-of p.b))
    ==
  ::
      %act
    ?>  ?=(%act -.b)
    ?&  =(box.a box.b)
        =((sub-span sub.a) (sub-span sub.b))
        =((sspan-of a.a) (sspan-of a.b))
    ==
  ::
      %neg   ?>(?=(%neg -.b) (le-equal b.a b.b))
      %next  ?>(?=(%next -.b) (le-equal b.a b.b))
      %all   ?>(?=(%all -.b) (le-equal b.a b.b))
      %even  ?>(?=(%even -.b) (le-equal b.a b.b))
      %conj  ?>(?=(%conj -.b) (le-equal-list cs.a cs.b))
      %disj  ?>(?=(%disj -.b) (le-equal-list ds.a ds.b))
  ==
::
++  sub-span
  |=  u=(unit sem:sm)
  ^-  (unit (unit span))
  ?~(u ~ `(sspan-of u.u))
::
++  le-equal-list
  |=  [a=(list live-expr) b=(list live-expr)]
  ^-  ?
  ?~  a  ?=(~ b)
  ?~  b  |
  ?:  (le-equal i.a i.b)  $(a t.a, b t.b)
  |
::
::  +|  Semantic-node level and small list helpers (hand-rolled over sem)
::
++  sem-lvl
  |=  s=sem:sm
  ^-  @ud
  ?-  -.s
    %apply    lvl.s
    %letin    lvl.s
    %atref    lvl.s
    %lit      0
    %nullodn  0
  ==
::
++  hd  |=(l=(list sem:sm) ^-(sem:sm ?~(l [%nullodn ~] i.l)))
++  tl  |=(l=(list sem:sm) ^-((list sem:sm) ?~(l ~ t.l)))
::
++  flop-le
  ::  hand-rolled reverse over the recursive live-expr mold
  |=  l=(list live-expr)
  ^-  (list live-expr)
  =|  acc=(list live-expr)
  |-  ^-  (list live-expr)
  ?~  l  acc
  $(l t.l, acc [i.l acc])
::
++  weld-le
  |=  [a=(list live-expr) b=(list live-expr)]
  ^-  (list live-expr)
  ?~  a  b
  [i.a $(a t.a)]
::
::  +|  astToLive: semantic node -> live-expr (Liveness.astToLiveAppl)
::
++  ast
  ::  Liveness.astToLive / astToLiveAppl: a temporal ExprNode to a live-expr.
  ::  `env` is the constant evaluation environment, used only to fold a
  ::  constant-level leaf to LNBool (a non-boolean is a typed rejection)
  |=  [s=sem:sm env=eenv:ne]
  ^-  (each live-expr aerr)
  ?.  ?=(%apply -.s)
    ::  LetIn/Label/SubstIn unwrap to their body (INSTANCE substitution stays a
    ::  documented deferral, unit 8.1.6); a bodyless let is vacuously TRUE
    ?:  ?=(%letin -.s)
      ?~  body.s  [%& [%bool &]]
      ::  a non-temporal LET (level<=2) stays a leaf so its bindings evaluate
      ::  under node-eval (eval-letin); the leaf renders at the body's span
      ::  (matching TLC, which keeps the body node with its bindings resolved).
      ::  Only a temporal-bodied LET unwraps to its body.
      ?.  (lte (sem-lvl s) 2)  (ast u.body.s env)
      =/  bat  (sspan-of u.body.s)
      ?~  bat  (ast u.body.s env)
      (leaf (letin-at s bat) env)
    (leaf s env)
  =/  op  name.op.s
  =/  as  args.s
  ?:  |(=(op '$ConjList') =(op '\\land'))
    =/  r  (ast-list as env)
    ?:(?=(%| -.r) r [%& [%conj p.r]])
  ?:  |(=(op '$DisjList') =(op '\\lor'))
    =/  r  (ast-list as env)
    ?:(?=(%| -.r) r [%& [%disj p.r]])
  ?:  =(op '[]')
    =/  r  (ast (hd as) env)
    ?:(?=(%| -.r) r [%& [%all p.r]])
  ?:  =(op '<>')
    =/  r  (ast (hd as) env)
    ?:(?=(%| -.r) r [%& [%even p.r]])
  ?:  =(op '$Nop')  (ast (hd as) env)
  ?:  |(=(op '~>') =(op '-+->'))
    ::  P ~> Q  ==  [](-P \/ <>Q)
    =/  rp  (ast (hd as) env)
    ?:  ?=(%| -.rp)  rp
    =/  rq  (ast (hd (tl as)) env)
    ?:  ?=(%| -.rq)  rq
    [%& [%all [%disj ~[[%neg p.rp] [%even p.rq]]]]]
  ?:  =(op '$WF')
    ::  WF_e(A) == []<>(-ENABLED<A>_e \/ <A>_e); args = [e A]
    =/  e  (hd as)
    =/  a  (hd (tl as))
    [%& [%all [%even [%disj ~[[%neg [%enabled | `e a]] [%act | `e a]]]]]]
  ?:  =(op '$SF')
    ::  SF_e(A) == <>[]-ENABLED<A>_e \/ []<><A>_e
    =/  e  (hd as)
    =/  a  (hd (tl as))
    [%& [%disj ~[[%even [%all [%neg [%enabled | `e a]]]] [%all [%even [%act | `e a]]]]]]
  ?:  =(op '$AngleAct')
    ::  <A>_e ; args = [A e]
    [%& [%act | `(hd (tl as)) (hd as)]]
  ?:  =(op '$SquareAct')
    [%& [%act & `(hd (tl as)) (hd as)]]
  ?:  =(op '\'')      [%& [%act | ~ s]]
  ?:  =(op '\\lnot')  (neg-of (ast (hd as) env) s env)
  ?:  =(op '\\neg')   (neg-of (ast (hd as) env) s env)
  ?:  =(op '=>')      (implies-of as s env)
  (leaf s env)
::
++  ast-list
  |=  [l=(list sem:sm) env=eenv:ne]
  ^-  (each (list live-expr) aerr)
  ?~  l  [%& ~]
  =/  hr  (ast i.l env)
  ?:  ?=(%| -.hr)  hr
  =/  tr  $(l t.l)
  ?:  ?=(%| -.tr)  tr
  [%& [p.hr p.tr]]
::
++  leaf
  ::  a non-temporal leaf, by level: a constant (level 0) evaluates to a boolean
  ::  (LNBool) under the constant env — a non-boolean is EC 2215 (the pin's
  ::  TLC_EXPECTED_VALUE); a state (level 1) is LNState, an action LNAction
  |=  [s=sem:sm env=eenv:ne]
  ^-  (each live-expr aerr)
  =/  l  (sem-lvl s)
  ?:  =(0 l)     (eval-const s env)
  ?:  (lte l 1)  [%& [%state s]]
  [%& [%act | ~ s]]
::
++  eval-const
  ::  a constant-level leaf folded to LNBool via node-eval; an evaluation error
  ::  propagates its EC, a non-boolean value is EC 2215
  |=  [s=sem:sm env=eenv:ne]
  ^-  (each live-expr aerr)
  =/  r  (eval:ne s env)
  ?:  ?=(%| -.r)  [%| p.r]
  ?.  ?=(%bool -.p.r)
    [%| 2.215 'TLC expected a boolean value, but did not find one.']
  [%& [%bool p.p.r]]
::
++  neg-of
  |=  [lr=(each live-expr aerr) s=sem:sm env=eenv:ne]
  ^-  (each live-expr aerr)
  ?:  ?=(%| -.lr)  lr
  ?:  (gth (le-level p.lr) 2)  [%& [%neg p.lr]]
  (leaf s env)
::
++  implies-of
  |=  [as=(list sem:sm) s=sem:sm env=eenv:ne]
  ^-  (each live-expr aerr)
  =/  lr  (ast (hd as) env)
  ?:  ?=(%| -.lr)  lr
  =/  rr  (ast (hd (tl as)) env)
  ?:  ?=(%| -.rr)  rr
  ?:  (gth (max (le-level p.lr) (le-level p.rr)) 2)
    [%& [%disj ~[[%neg p.lr] p.rr]]]
  (leaf s env)
::
::  +|  parseLiveness: negate the properties, conjoin the fairness
::
++  parse-liveness
  |=  [props=(list sem:sm) fair=(list sem:sm) env=eenv:ne]
  ^-  (each (unit live-expr) aerr)
  =/  fcr  (ast-list fair env)
  ?:  ?=(%| -.fcr)  fcr
  =/  fc  p.fcr
  ?~  props
    ?~  fc  [%& ~]
    [%& `[%conj fc]]
  ?~  t.props
    =/  lr  (ast i.props env)
    ?:  ?=(%| -.lr)  lr
    ?~  fc  [%& `[%neg p.lr]]
    [%& `[%conj (weld-le fc ~[[%neg p.lr]])]]
  =/  nlr  (neg-list props env)
  ?:  ?=(%| -.nlr)  nlr
  =/  nd=live-expr  [%disj p.nlr]
  ?~  fc  [%& `nd]
  [%& `[%conj (weld-le fc ~[nd])]]
::
++  neg-list
  |=  [l=(list sem:sm) env=eenv:ne]
  ^-  (each (list live-expr) aerr)
  ?~  l  [%& ~]
  =/  hr  (ast i.l env)
  ?:  ?=(%| -.hr)  hr
  =/  tr  $(l t.l)
  ?:  ?=(%| -.tr)  tr
  [%& [[%neg p.hr] p.tr]]
::
::  +|  simplify (LiveExprNode.simplify)
::
++  simplify
  |=  x=live-expr
  ^-  live-expr
  ?-  -.x
      %conj  (conj-fold (simplify-list cs.x))
      %disj  (disj-fold (simplify-list ds.x))
      %neg
    =/  b1  (simplify b.x)
    ?:  ?=(%bool -.b1)  [%bool !b.b1]
    [%neg b1]
      %all
    =/  b1  (simplify b.x)
    ?:  ?=(%all -.b1)  [%all b.b1]
    [%all b1]
      %even
    =/  b1  (simplify b.x)
    ?:  ?=(%even -.b1)  [%even b.b1]
    [%even b1]
      %next    [%next (simplify b.x)]
      %act     x
      %state   x
      %enabled  x
      %bool    x
  ==
::
++  simplify-list
  |=  l=(list live-expr)
  ^-  (list live-expr)
  ?~  l  ~
  [(simplify i.l) $(l t.l)]
::
++  conj-fold
  ::  LNConj.simplify: drop TRUE, FALSE collapses to FALSE, flatten singleton
  |=  l=(list live-expr)
  ^-  live-expr
  =|  acc=(list live-expr)
  |-  ^-  live-expr
  ?~  l
    =/  a  (flop-le acc)
    ?~  a  [%bool &]
    ?~  t.a  i.a
    [%conj a]
  ?:  ?=(%bool -.i.l)
    ?:  b.i.l  $(l t.l)
    [%bool |]
  $(l t.l, acc [i.l acc])
::
++  disj-fold
  ::  LNDisj.simplify: drop FALSE, TRUE collapses to TRUE, flatten singleton
  |=  l=(list live-expr)
  ^-  live-expr
  =|  acc=(list live-expr)
  |-  ^-  live-expr
  ?~  l
    =/  a  (flop-le acc)
    ?~  a  [%bool |]
    ?~  t.a  i.a
    [%disj a]
  ?:  ?=(%bool -.i.l)
    ?:  b.i.l  [%bool &]
    $(l t.l)
  $(l t.l, acc [i.l acc])
::
::  +|  pushNeg (De Morgan + temporal duality)
::
++  push-neg
  |=  x=live-expr
  ^-  live-expr
  ?-  -.x
      %conj  [%disj (push-neg-list cs.x)]
      %disj  [%conj (push-neg-list ds.x)]
      %neg   b.x
      %all   [%even (push-neg b.x)]
      %even  [%all (push-neg b.x)]
      %bool  [%bool !b.x]
      %next     [%neg x]
      %act      [%neg x]
      %state    [%neg x]
      %enabled  [%neg x]
  ==
::
++  push-neg-list
  |=  l=(list live-expr)
  ^-  (list live-expr)
  ?~  l  ~
  [(push-neg i.l) $(l t.l)]
::
::  +|  toDNF (boolean-level distribution; temporal ops are atoms)
::
++  to-dnf
  |=  x=live-expr
  ^-  live-expr
  ?-  -.x
      %conj  (dnf-conj cs.x)
      %disj  (dnf-disj ds.x)
      %neg
    ?:  ?|(?=(%state -.b.x) ?=(%act -.b.x))  x
    (to-dnf (push-neg b.x))
      %all     x
      %even    x
      %next    x
      %act     x
      %state   x
      %enabled  x
      %bool    x
  ==
::
++  dnf-list
  |=  l=(list live-expr)
  ^-  (list live-expr)
  ?~  l  ~
  [(to-dnf i.l) $(l t.l)]
::
++  dnf-disj
  ::  LNDisj.toDNF: flatten nested disjuncts (getAEBody []<> collapsing is a
  ::  tableau optimization not needed for the decomposition counts)
  |=  ds=(list live-expr)
  ^-  live-expr
  =/  es  (dnf-list ds)
  =|  acc=(list live-expr)
  |-  ^-  live-expr
  ?~  es  [%disj (flop-le acc)]
  ?:  ?=(%disj -.i.es)
    $(es t.es, acc (weld-le (flop-le ds.i.es) acc))
  $(es t.es, acc [i.es acc])
::
++  dnf-conj
  ::  LNConj.toDNF: distribute over the cross-product of the disjunct factors.
  |=  cs=(list live-expr)
  ^-  live-expr
  =/  temp  (dnf-list cs)
  ::  nes: flatten nested conjuncts, keep disjuncts as factors
  =/  nes=(list live-expr)
    =|  acc=(list live-expr)
    |-  ^-  (list live-expr)
    ?~  temp  (flop-le acc)
    ?:  ?=(%conj -.i.temp)
      $(temp t.temp, acc (weld-le (flop-le cs.i.temp) acc))
    $(temp t.temp, acc [i.temp acc])
  ::  total = product of the disjunct factor widths
  =/  total=@ud
    =/  t  1
    |-  ^-  @ud
    ?~  nes  t
    ?:  ?=(%disj -.i.nes)  $(nes t.nes, t (mul t (lent ds.i.nes)))
    $(nes t.nes)
  ?:  =(1 total)  [%conj nes]
  ::  build `total` conjunct-lists by the odometer distribution
  =/  res=(list (list live-expr))  (reap total *(list live-expr))
  =/  num=@ud   1
  =/  rcount=@ud  total
  =.  res
    |-  ^-  (list (list live-expr))
    ?~  nes  res
    ?.  ?=(%disj -.i.nes)
      ::  a plain factor: append to every conjunct-list
      %=  $
        nes  t.nes
        res  (add-to-all res i.nes)
      ==
    =/  w  (lent ds.i.nes)
    =/  rc  (div rcount w)
    =.  res  (spread-disj res ds.i.nes num rc)
    %=  $
      nes     t.nes
      num     (mul num w)
      rcount  rc
    ==
  [%disj (wrap-conjs res)]
::
++  add-to-all
  ::  append `e` to each conjunct-list (order preserved via flop)
  |=  [res=(list (list live-expr)) e=live-expr]
  ^-  (list (list live-expr))
  ?~  res  ~
  [(snoc-le i.res e) $(res t.res)]
::
++  snoc-le
  |=  [l=(list live-expr) e=live-expr]
  ^-  (list live-expr)
  ?~  l  ~[e]
  [i.l $(l t.l)]
::
++  spread-disj
  ::  distribute a disjunct factor across the odometer: for each of `num`
  ::  blocks, each of the `w` disjuncts fills `rc` consecutive conjunct-lists
  |=  [res=(list (list live-expr)) ds=(list live-expr) num=@ud rc=@ud]
  ^-  (list (list live-expr))
  =/  idx  0
  =/  j    0
  |-  ^-  (list (list live-expr))
  ?:  =(j num)  res
  $(j +(j), idx (add idx (mul (lent ds) rc)), res (fill-block res ds idx rc))
::
++  fill-block
  ::  for one block starting at `idx`: disjunct k fills rows [idx+k*rc, +rc)
  |=  [res=(list (list live-expr)) ds=(list live-expr) idx=@ud rc=@ud]
  ^-  (list (list live-expr))
  =/  k  0
  |-  ^-  (list (list live-expr))
  ?~  ds  res
  =/  res2  (fill-rows res i.ds (add idx (mul k rc)) rc)
  $(ds t.ds, k +(k), res res2)
::
++  fill-rows
  ::  append `e` to rows [start, start+n)
  |=  [res=(list (list live-expr)) e=live-expr start=@ud n=@ud]
  ^-  (list (list live-expr))
  =/  i  0
  |-  ^-  (list (list live-expr))
  ?~  res  ~
  ?:  &((gte i start) (lth i (add start n)))
    [(snoc-le i.res e) $(res t.res, i +(i))]
  [i.res $(res t.res, i +(i))]
::
++  wrap-conjs
  |=  l=(list (list live-expr))
  ^-  (list live-expr)
  ?~  l  ~
  [[%conj i.l] $(l t.l)]
::
::  +|  classifyExpr + the OrderOfSolution / PossibleErrorModel decomposition
::
+$  pem-acc
  $:  ea-action=(list live-expr)   ::  <>[]A
      ae-state=(list live-expr)    ::  []<>S
      ae-action=(list live-expr)   ::  []<>A
      tfs=(list live-expr)         ::  temporal formulae with no actions
  ==
::
++  classify
  ::  route one conjunct of a DNF disjunct into the pem accumulator
  |=  [ln=live-expr p=pem-acc]
  ^-  pem-acc
  ?:  ?&(?=(%even -.ln) ?=(%all -.b.ln))
    =/  a2  b.b.ln
    ?:  (lth (le-level a2) 3)
      p(ea-action [a2 ea-action.p])
    (class-default ln p)
  ?:  ?&(?=(%all -.ln) ?=(%even -.b.ln))
    =/  a2  b.b.ln
    =/  l   (le-level a2)
    ?:  (lte l 1)  p(ae-state [a2 ae-state.p])
    ?:  =(2 l)     p(ae-action [a2 ae-action.p])
    (class-default ln p)
  (class-default ln p)
::
++  class-default
  |=  [ln=live-expr p=pem-acc]
  ^-  pem-acc
  ?:  (contain-action ln)  ~|(%tlc-live-wrong-formula-format !!)
  p(tfs [ln tfs.p])
::
++  classify-disjunct
  ::  classify all conjuncts of one DNF disjunct into a fresh pem, return the
  ::  pem accumulator and the disjunct's tf (the conjoined tfs, or ~)
  |=  d=live-expr
  ^-  [p=pem-acc tf=(unit live-expr)]
  =/  cs=(list live-expr)  ?:(?=(%conj -.d) cs.d ~[d])
  =/  p=pem-acc  *pem-acc
  =.  p
    |-  ^-  pem-acc
    ?~  cs  p
    $(cs t.cs, p (classify i.cs p))
  :-  p(ea-action (flop-le ea-action.p), ae-state (flop-le ae-state.p), ae-action (flop-le ae-action.p), tfs (flop-le tfs.p))
  =/  t  (flop-le tfs.p)
  ?~  t  ~
  ?~  t.t  `i.t
  `[%conj t]
::
::  +|  makeBinary
::
++  take-le
  ::  hand-rolled scag over the recursive live-expr mold
  |=  [n=@ud l=(list live-expr)]
  ^-  (list live-expr)
  ?:  =(0 n)  ~
  ?~  l  ~
  [i.l $(n (dec n), l t.l)]
::
++  drop-le
  ::  hand-rolled slag over the recursive live-expr mold
  |=  [n=@ud l=(list live-expr)]
  ^-  (list live-expr)
  ?:  =(0 n)  l
  ?~  l  l
  $(n (dec n), l t.l)
::
++  make-binary
  ::  LiveExprNode.makeBinary: balance every conjunction/disjunction into a
  ::  binary tree (tableau 'triple' construction needs binary junctions), the
  ::  unary operators/leaves pass through recursing their bodies. There are no
  ::  LNActions in a tf at this point (they were excluded when classifying).
  |=  x=live-expr
  ^-  live-expr
  ?-  -.x
    %bool     x
    %state    x
    %enabled  x
    %act      x
    %neg      x(b (make-binary b.x))
    %next     x(b (make-binary b.x))
    %all      x(b (make-binary b.x))
    %even     x(b (make-binary b.x))
    %conj     (binary-junction & cs.x)
    %disj     (binary-junction | ds.x)
  ==
::
++  binary-junction
  ::  balance a junction's child list into a binary tree of two-child nodes,
  ::  mirroring LNConj/LNDisj.makeBinary (split at count/2, recurse each half);
  ::  a single child collapses to its own binary form
  |=  [conj=? l=(list live-expr)]
  ^-  live-expr
  =/  n  (lent l)
  ?:  =(0 n)  ?:(conj [%bool &] [%bool |])
  ?:  =(1 n)  (make-binary ?~(l [%bool &] i.l))
  =/  mid  (div n 2)
  =/  lb  (binary-junction conj (take-le mid l))
  =/  rb  (binary-junction conj (drop-le mid l))
  ?:(conj [%conj ~[lb rb]] [%disj ~[lb rb]])
::
++  make-binary-unit
  |=  x=(unit live-expr)
  ^-  (unit live-expr)
  ?~(x ~ `(make-binary u.x))
::
::  +|  extractPromises + addToBin
::
++  extract-promises
  ::  the <>-subformulas (le-even nodes) in the closure of `x`, deduplicated.
  ::  Faithful to LiveExprNode.extractPromises: fed the make-binary'd tf, so the
  ::  child-list recursion below is the binary body(0)/body(1) traversal
  |=  x=(unit live-expr)
  ^-  (list live-expr)
  ?~  x  ~
  =|  acc=(list live-expr)
  =/  r  (collect-even u.x acc)
  (flop-le r)
::
++  collect-even
  |=  [x=live-expr acc=(list live-expr)]
  ^-  (list live-expr)
  =?  acc  ?=(%even -.x)  ?:((has-le acc x) acc [x acc])
  ?-  -.x
      %even  (collect-even b.x acc)
      %all   (collect-even b.x acc)
      %neg   (collect-even b.x acc)
      %next  (collect-even b.x acc)
      %conj  (collect-even-list cs.x acc)
      %disj  (collect-even-list ds.x acc)
      %act   acc
      %state    acc
      %enabled  acc
      %bool  acc
  ==
::
++  collect-even-list
  |=  [l=(list live-expr) acc=(list live-expr)]
  ^-  (list live-expr)
  ?~  l  acc
  $(l t.l, acc (collect-even i.l acc))
::
++  has-le
  |=  [l=(list live-expr) x=live-expr]
  ^-  ?
  ?~  l  |
  ?:  (le-equal i.l x)  &
  $(l t.l)
::
++  add-to-bin
  ::  append `x` to `bin` if not already present (by le-equal); return the
  ::  index of `x` in the bin
  |=  [x=live-expr bin=(list live-expr)]
  ^-  [idx=@ud bin=(list live-expr)]
  =/  i  0
  |-  ^-  [idx=@ud bin=(list live-expr)]
  ?~  bin  [i (snoc-le bin x)]      ::  bin exhausted -> append
  ?:  (le-equal i.bin x)  [i bin]
  =/  r  $(bin t.bin, i +(i))
  [idx.r [i.bin bin.r]]
::
++  add-list-to-bin
  |=  [xs=(list live-expr) bin=(list live-expr)]
  ^-  [idx=(list @ud) bin=(list live-expr)]
  ?~  xs  [~ bin]
  =/  r  (add-to-bin i.xs bin)
  =/  rr  $(xs t.xs, bin bin.r)
  [[idx.r idx.rr] bin.rr]
::
::  +|  normalize: property list + fairness -> OrderOfSolutions
::
++  is-box-state
  ::  a []P over a state/constant predicate: TLC routes this to an invariant
  ::  (processConfigProps), so it is not a temporal property
  |=  s=sem:sm
  ^-  ?
  ?.  ?=(%apply -.s)  |
  ?.  =('[]' name.op.s)  |
  =/  a  (hd args.s)
  (lte (sem-lvl a) 1)
::
++  drop-box-state
  |=  l=(list sem:sm)
  ^-  (list sem:sm)
  ?~  l  ~
  ?:  (is-box-state i.l)  $(l t.l)
  [i.l $(l t.l)]
::
++  box-state-inner
  ::  the P of a []P box-state property (a state/constant predicate), which TLC
  ::  checks as an invariant rather than a temporal property (unit 8.9); ~ if the
  ::  property is not a pure box-state
  |=  s=sem:sm
  ^-  (unit sem:sm)
  ?.  ?=(%apply -.s)  ~
  ?.  =('[]' name.op.s)  ~
  ?~  args.s  ~
  =/  a  (hd args.s)
  ?.  (lte (sem-lvl a) 1)  ~
  `a
::
++  normalize
  ::  the OrderOfSolutions for a spec's PROPERTY list under its fairness, or a
  ::  typed rejection (a non-boolean constant leaf). `env` folds constant leaves
  |=  [props=(list sem:sm) fair=(list sem:sm) env=eenv:ne]
  ^-  (each (list oos) aerr)
  =/  lr  (parse-liveness (drop-box-state props) fair env)
  ?:  ?=(%| -.lr)  lr
  ?~  p.lr  [%& ~]
  =/  nf  (to-dnf (simplify u.p.lr))
  ?:  ?&(?=(%bool -.nf) =(| b.nf))  [%& ~]
  =/  disjs=(list live-expr)  ?:(?=(%disj -.nf) ds.nf ~[nf])
  ::  classify each disjunct; group by equal tf into OrderOfSolutions
  ::  add-to-group appends a new tf group at the tail, so `gs` is already in
  ::  disjunct (property) order — the order TLC's OrderOfSolution[] uses
  =/  groups=(list [tf=(unit live-expr) ps=(list pem-acc)])
    =|  gs=(list [tf=(unit live-expr) ps=(list pem-acc)])
    |-  ^-  (list [tf=(unit live-expr) ps=(list pem-acc)])
    ?~  disjs  gs
    =/  cd  (classify-disjunct i.disjs)
    =.  gs  (add-to-group gs tf.cd p.cd)
    $(disjs t.disjs)
  [%& (turn-groups groups)]
::
++  tf-equal
  |=  [a=(unit live-expr) b=(unit live-expr)]
  ^-  ?
  ?~  a  ?=(~ b)
  ?~  b  |
  (le-equal u.a u.b)
::
++  add-to-group
  ::  add pem `p` under tf, lumping with an existing equal-tf group (in order)
  |=  $:  gs=(list [tf=(unit live-expr) ps=(list pem-acc)])
          tf=(unit live-expr)
          p=pem-acc
      ==
  ^-  (list [tf=(unit live-expr) ps=(list pem-acc)])
  ?~  gs  ~[[tf ~[p]]]
  ?:  (tf-equal tf.i.gs tf)
    [i.gs(ps (snoc-pem ps.i.gs p)) t.gs]
  [i.gs $(gs t.gs)]
::
++  snoc-pem
  |=  [l=(list pem-acc) p=pem-acc]
  ^-  (list pem-acc)
  ?~  l  ~[p]
  [i.l $(l t.l)]
::
++  turn-groups
  |=  gs=(list [tf=(unit live-expr) ps=(list pem-acc)])
  ^-  (list oos)
  ?~  gs  ~
  [(build-oos i.gs) $(gs t.gs)]
::
++  build-oos
  |=  g=[tf=(unit live-expr) ps=(list pem-acc)]
  ^-  oos
  ::  build the shared checkState/checkAction bins and the pem index arrays.
  ::  addToBin order mirrors Java: AEAction then EAAction into the action bin,
  ::  AEState into the state bin.
  =/  fold
    =|  acc=(list pem)
    =|  caction=(list live-expr)
    =|  cstate=(list live-expr)
    |-  ^-  [pems=(list pem) ca=(list live-expr) cs=(list live-expr)]
    ?~  ps.g  [(flop-pems acc) caction cstate]
    =/  ra  (add-list-to-bin ae-action.i.ps.g caction)
    =/  rs  (add-list-to-bin ae-state.i.ps.g cstate)
    =/  re  (add-list-to-bin ea-action.i.ps.g bin.ra)
    %=  $
      ps.g     t.ps.g
      caction  bin.re
      cstate   bin.rs
      acc      [[idx.ra idx.rs idx.re] acc]
    ==
  ::  the tableau formula is made binary (as TLC does before TBGraph and
  ::  extractPromises); promises come from that binary form
  =/  tf1  (make-binary-unit tf.g)
  :*  tf1
      (extract-promises tf1)
      cs.fold
      ca.fold
      pems.fold
  ==
::
++  flop-pems
  |=  l=(list pem)
  ^-  (list pem)
  =|  acc=(list pem)
  |-  ^-  (list pem)
  ?~  l  acc
  $(l t.l, acc [i.l acc])
::
::  +|  Structural projection for the differential (matches LivenessStruct)
::
++  render-counts
  ::  the count projection of LivenessStruct (minus the TABLEAU node count,
  ::  which is unit 8.2): OOS count then per-OOS promises/state/action/pems
  |=  oss=(list oos)
  ^-  wain
  =/  hd=@t  (crip "OOS {(scow %ud (lent oss))}")
  =/  rows
    =/  i  0
    =|  acc=(list @t)
    |-  ^-  (list @t)
    ?~  oss  (flop acc)
    =/  o  i.oss
    =/  block=(list @t)
      :~  (crip "--- {(scow %ud i)} ---")
          (crip "PROMISES {(scow %ud (lent promises.o))}")
          (crip "CHECKSTATE {(scow %ud (lent check-state.o))}")
          (crip "CHECKACTION {(scow %ud (lent check-action.o))}")
          (crip "PEMS {(scow %ud (lent pems.o))}")
      ==
    $(oss t.oss, i +(i), acc (weld (flop block) acc))
  [hd rows]
::
::  +|  Full structural projection (matches OrderOfSolution.toString)
::
++  nl  `tape`~[`@tD`10]
::
++  loc-leaf
  ::  a LNState/LNAction/LNStateEnabled leaf renders as the ExprNode's
  ::  toString = its Location span (Location.toString), the module its root
  |=  [modn=@t s=sem:sm]
  ^-  tape
  (trip (loc-str:config modn (sspan-of s)))
::
++  snag-le
  |=  [i=@ud l=(list live-expr)]
  ^-  live-expr
  ?~  l  [%bool &]
  ?:  =(0 i)  i.l
  $(i (dec i), l t.l)
::
++  snag-pem
  |=  [i=@ud l=(list pem)]
  ^-  pem
  ?~  l  [~ ~ ~]
  ?:  =(0 i)  i.l
  $(i (dec i), l t.l)
::
++  pem-empty
  |=  p=pem
  ^-  ?
  &(?=(~ ae-action.p) ?=(~ ae-state.p) ?=(~ ea-action.p))
::
++  render-expr
  ::  LiveExprNode.toString(sb, padding): the padded rendering. `pad` is the
  ::  current indentation prefix; junctions add "    ", the temporal unaries "  "
  |=  [modn=@t x=live-expr pad=tape]
  ^-  tape
  ?-  -.x
    %bool     ?:(b.x "TRUE" "FALSE")
    %state    (loc-leaf modn p.x)
    %neg      (weld "-" (render-expr modn b.x (weld pad " ")))
    %next     (weld "()" (render-expr modn b.x (weld pad "  ")))
    %all      (weld "[]" (render-expr modn b.x (weld pad "  ")))
    %even     (weld "<>" (render-expr modn b.x (weld pad "  ")))
  ::
      %act
    ?~  sub.x  (loc-leaf modn a.x)
    %-  zing
    :~  ?:(box.x "[" "<")  (loc-leaf modn a.x)
        ?:(box.x "]_" ">_")  (loc-leaf modn u.sub.x)
    ==
  ::
      %enabled
    ?~  sub.x  (weld "ENABLED " (loc-leaf modn p.x))
    %-  zing
    :~  "ENABLED "  ?:(box.x "[" "<")  (loc-leaf modn p.x)
        ?:(box.x "]_" ">_")  (loc-leaf modn u.sub.x)
    ==
  ::
    %conj     (render-junction modn "/\\ (" cs.x pad)
    %disj     (render-junction modn "\\/ (" ds.x pad)
  ==
::
++  render-junction
  ::  LNConj/LNDisj.toString: each child as `OP (body)`, children after the
  ::  first prefixed with `pad`, a newline between (not after the last); the
  ::  child body is padded `pad + "    "`
  |=  [modn=@t opn=tape l=(list live-expr) pad=tape]
  ^-  tape
  =/  pad1  (weld pad "    ")
  =/  n     (lent l)
  =/  i     0
  =|  acc=tape
  |-  ^-  tape
  ?~  l  acc
  =/  piece
    %-  zing
    :~  ?:(=(0 i) "" pad)
        opn
        (render-expr modn i.l pad1)
        ")"
        ?:(=(+(i) n) "" nl)
    ==
  $(l t.l, i +(i), acc (weld acc piece))
::
++  pem-loop
  ::  one of PEM.toString's three loops (EAAction/AEState/AEAction): each index
  ::  renders `OP <bin[idx]>` newline-terminated, the very first entry across
  ::  the whole pem omitting the leading `pad`
  |=  $:  modn=@t  opn=tape  idxs=(list @ud)
          bin=(list live-expr)  pad=tape  pad1=tape  first=?
      ==
  ^-  [tape ?]
  ?~  idxs  ["" first]
  =/  line
    %-  zing
    :~  ?:(first "" pad)  opn  (render-expr modn (snag-le i.idxs bin) pad1)  nl
    ==
  =/  rest  $(idxs t.idxs, first |)
  [(weld line -.rest) +.rest]
::
++  render-pem
  ::  PossibleErrorModel.toString: EAAction (/\ <>[]) then AEState (/\ []<>)
  ::  then AEAction (/\ []<>), each newline-terminated, over the shared bins
  |=  [modn=@t p=pem cs=(list live-expr) ca=(list live-expr) pad=tape]
  ^-  tape
  =/  pad1  (weld pad "       ")
  =/  r1  (pem-loop modn "/\\ <>[]" ea-action.p ca pad pad1 &)
  =/  r2  (pem-loop modn "/\\ []<>" ae-state.p cs pad pad1 +.r1)
  =/  r3  (pem-loop modn "/\\ []<>" ae-action.p ca pad pad1 +.r2)
  :(weld -.r1 -.r2 -.r3)
::
++  render-oos
  ::  OrderOfSolution.toString(sb): the tableau formula (if any) conjoined with
  ::  the pems; a lone empty pem under a tableau renders just the tf
  |=  [modn=@t o=oos]
  ^-  tape
  =/  plen  (lent pems.o)
  ?:  ?&(?=(^ tf.o) =(1 plen) (pem-empty (snag-pem 0 pems.o)))
    (render-expr modn u.tf.o "   ")
  =/  head=tape
    ?~  tf.o  ""
    (zing ~["/\\ " (render-expr modn u.tf.o "   ") nl "/\\ "])
  =/  pad=tape  ?~(tf.o "" "   ")
  ?:  =(1 plen)
    (weld head (render-pem modn (snag-pem 0 pems.o) check-state.o check-action.o pad))
  =/  pad1  (weld pad "   ")
  =/  acc
    ;:  weld
      head  "\\/ "
      (render-pem modn (snag-pem 0 pems.o) check-state.o check-action.o pad1)
    ==
  =/  i  1
  |-  ^-  tape
  ?:  =(i plen)  acc
  =/  piece
    %+  weld  (weld pad "\\/ ")
    (render-pem modn (snag-pem i pems.o) check-state.o check-action.o pad1)
  $(i +(i), acc (weld acc piece))
::
++  to-lines
  ::  split a rendered tape into wain lines on newline, dropping the trailing
  ::  empty produced by a final newline (hand-rolled; zuse lore is out of scope)
  |=  t=tape
  ^-  wain
  =|  cur=tape
  =|  acc=(list @t)
  |-  ^-  wain
  ?~  t
    ?~(cur (flop acc) (flop [(crip (flop cur)) acc]))
  ?:  =(10 i.t)
    $(t t.t, cur ~, acc [(crip (flop cur)) acc])
  $(t t.t, cur [i.t cur])
::
++  render-struct
  ::  the full LivenessStruct projection (unit 8.2): LIVESTRUCT / OOS n / the
  ::  per-OOS counts, the TABLEAU node count, and the TF…ENDTF rendering. The
  ::  tableau sizes are supplied by the caller (tableau.hoon imports this lib,
  ::  so temporal.hoon must not depend on it), one per OrderOfSolution in order.
  |=  [oss=(list oos) modn=@t tabs=(list @ud)]
  ^-  wain
  =/  hd=@t  (crip "OOS {(scow %ud (lent oss))}")
  =/  body
    =/  i  0
    =|  acc=(list @t)
    |-  ^-  (list @t)
    ?~  oss  (flop acc)
    =/  o  i.oss
    =/  tab  ?:((gth (lent tabs) i) (snag i tabs) 0)
    =/  block=(list @t)
      ;:  weld
        :~  (crip "--- {(scow %ud i)} ---")
            (crip "PROMISES {(scow %ud (lent promises.o))}")
            (crip "CHECKSTATE {(scow %ud (lent check-state.o))}")
            (crip "CHECKACTION {(scow %ud (lent check-action.o))}")
            (crip "PEMS {(scow %ud (lent pems.o))}")
            (crip "TABLEAU {(scow %ud tab)}")
            'TF'
        ==
        (to-lines (render-oos modn o))
        `wain`~['ENDTF']
      ==
    $(oss t.oss, i +(i), acc (weld (flop block) acc))
  `wain`['LIVESTRUCT' hd body]
--
