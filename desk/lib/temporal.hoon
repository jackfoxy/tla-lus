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
/=  sm  /lib/semantic
|%
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
  |=  s=sem:sm
  ^-  live-expr
  ?.  ?=(%apply -.s)
    ?:  ?=(%letin -.s)
      ?~  body.s  [%bool &]
      (ast u.body.s)
    (leaf s)
  =/  op  name.op.s
  =/  as  args.s
  ?:  |(=(op '$ConjList') =(op '\\land'))  [%conj (ast-list as)]
  ?:  |(=(op '$DisjList') =(op '\\lor'))   [%disj (ast-list as)]
  ?:  =(op '[]')    [%all (ast (hd as))]
  ?:  =(op '<>')    [%even (ast (hd as))]
  ?:  =(op '$Nop')  (ast (hd as))
  ?:  |(=(op '~>') =(op '-+->'))
    ::  P ~> Q  ==  [](-P \/ <>Q)
    =/  p  (ast (hd as))
    =/  q  (ast (hd (tl as)))
    [%all [%disj ~[[%neg p] [%even q]]]]
  ?:  =(op '$WF')
    ::  WF_e(A) == []<>(-ENABLED<A>_e \/ <A>_e); args = [e A]
    =/  e  (hd as)
    =/  a  (hd (tl as))
    [%all [%even [%disj ~[[%neg [%enabled | `e a]] [%act | `e a]]]]]
  ?:  =(op '$SF')
    ::  SF_e(A) == <>[]-ENABLED<A>_e \/ []<><A>_e
    =/  e  (hd as)
    =/  a  (hd (tl as))
    [%disj ~[[%even [%all [%neg [%enabled | `e a]]]] [%all [%even [%act | `e a]]]]]
  ?:  =(op '$AngleAct')
    ::  <A>_e ; args = [A e]
    [%act | `(hd (tl as)) (hd as)]
  ?:  =(op '$SquareAct')
    [%act & `(hd (tl as)) (hd as)]
  ?:  =(op '\'')      [%act | ~ s]
  ?:  =(op '\\lnot')  (neg-of (ast (hd as)) s)
  ?:  =(op '\\neg')   (neg-of (ast (hd as)) s)
  ?:  =(op '=>')      (implies-of as s)
  (leaf s)
::
++  ast-list
  |=  l=(list sem:sm)
  ^-  (list live-expr)
  ?~  l  ~
  [(ast i.l) $(l t.l)]
::
++  leaf
  ::  a non-temporal leaf, by level (const -> LNBool, state -> LNState,
  ::  action -> LNAction). Constant folding to a boolean is deferred (no corpus
  ::  case); a constant leaf is treated as TRUE.
  |=  s=sem:sm
  ^-  live-expr
  =/  l  (sem-lvl s)
  ?:  =(0 l)     [%bool &]
  ?:  (lte l 1)  [%state s]
  [%act | ~ s]
::
++  neg-of
  |=  [ln=live-expr s=sem:sm]
  ^-  live-expr
  ?:  (gth (le-level ln) 2)  [%neg ln]
  (leaf s)
::
++  implies-of
  |=  [as=(list sem:sm) s=sem:sm]
  ^-  live-expr
  =/  l  (ast (hd as))
  =/  r  (ast (hd (tl as)))
  ?:  (gth (max (le-level l) (le-level r)) 2)  [%disj ~[[%neg l] r]]
  (leaf s)
::
::  +|  parseLiveness: negate the properties, conjoin the fairness
::
++  parse-liveness
  |=  [props=(list sem:sm) fair=(list sem:sm)]
  ^-  (unit live-expr)
  =/  fc  (ast-list fair)
  ?~  props
    ?~  fc  ~
    `[%conj fc]
  ?~  t.props
    =/  ln  (ast i.props)
    ?~  fc  `[%neg ln]
    `[%conj (weld-le fc ~[[%neg ln]])]
  =/  nd=live-expr  [%disj (neg-list props)]
  ?~  fc  `nd
  `[%conj (weld-le fc ~[nd])]
::
++  neg-list
  |=  l=(list sem:sm)
  ^-  (list live-expr)
  ?~  l  ~
  [[%neg (ast i.l)] $(l t.l)]
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
::  +|  extractPromises + addToBin
::
++  extract-promises
  ::  the <>-subformulas (le-even nodes) in the closure of `x`, deduplicated
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
++  normalize
  |=  [props=(list sem:sm) fair=(list sem:sm)]
  ^-  (list oos)
  =/  lx  (parse-liveness (drop-box-state props) fair)
  ?~  lx  ~
  =/  nf  (to-dnf (simplify u.lx))
  ?:  ?&(?=(%bool -.nf) =(| b.nf))  ~
  =/  disjs=(list live-expr)  ?:(?=(%disj -.nf) ds.nf ~[nf])
  ::  classify each disjunct; group by equal tf into OrderOfSolutions
  =/  groups=(list [tf=(unit live-expr) ps=(list pem-acc)])
    =|  gs=(list [tf=(unit live-expr) ps=(list pem-acc)])
    |-  ^-  (list [tf=(unit live-expr) ps=(list pem-acc)])
    ?~  disjs  (flop-groups gs)
    =/  cd  (classify-disjunct i.disjs)
    =.  gs  (add-to-group gs tf.cd p.cd)
    $(disjs t.disjs)
  (turn-groups groups)
::
++  flop-groups
  |=  gs=(list [tf=(unit live-expr) ps=(list pem-acc)])
  ^-  (list [tf=(unit live-expr) ps=(list pem-acc)])
  =|  acc=(list [tf=(unit live-expr) ps=(list pem-acc)])
  |-  ^-  (list [tf=(unit live-expr) ps=(list pem-acc)])
  ?~  gs  acc
  $(gs t.gs, acc [i.gs acc])
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
  :*  tf.g
      (extract-promises tf.g)
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
--
