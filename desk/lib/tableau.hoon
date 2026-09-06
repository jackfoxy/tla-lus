::  tableau.hoon — particle-tableau construction (Work Unit 8.2). Port of
::  tlc2.tool.liveness.TBGraph/TBGraphNode/TBPar/TBParVec/TBTriple: the
::  particle tableau of Manna & Pnueli (PART-TAB, p.456) over the normalized
::  tableau formula (a make-binary'd `live-expr` with no actions, in positive
::  form). Consumed by the behavior-graph product (8.3).
::
::  All recursions over the recursive `live-expr` mold are hand-rolled (the wet
::  list gates fuse-loop it, the zuse-408 hazard). A particle (TBPar) is a
::  `(list live-expr)` compared as a SET by mutual containment.
/-  *tla-lus
/=  tp  /lib/temporal
=,  tp
|%
+$  par    (list live-expr)          ::  a TBPar (particle), a set of live-exprs
+$  triple  [a=live-expr b=live-expr c=live-expr]
+$  tb-node
  $:  par=par                        ::  the particle
      nexts=(list @ud)               ::  successor node indices
      index=@ud
      state-preds=(list live-expr)   ::  level<=1 members (state consistency)
  ==
+$  tb-graph
  $:  nodes=(list tb-node)
      init-cnt=@ud                   ::  the first init-cnt nodes are initial
  ==
::
::  +|  TBPar set operations (member / contains / equal / append)
::
++  par-member
  ::  TBPar.member: is `e` in the particle (by structural le-equal)
  |=  [e=live-expr p=par]
  ^-  ?
  ?~  p  |
  ?:  (le-equal e i.p)  &
  $(p t.p)
::
++  par-contains
  ::  TBPar.contains: is `sub` a subset of `p`
  |=  [p=par sub=par]
  ^-  ?
  ?~  sub  &
  ?.  (par-member i.sub p)  |
  $(sub t.sub)
::
++  par-equal
  ::  TBPar.equals: mutual containment (set equality)
  |=  [a=par b=par]
  ^-  ?
  ?&((par-contains a b) (par-contains b a))
::
++  par-append
  ::  TBPar.append: a fresh particle with `ln` at the tail
  |=  [p=par ln=live-expr]
  ^-  par
  (weld-le p ~[ln])
::
++  par-append2
  |=  [p=par a=live-expr b=live-expr]
  ^-  par
  (weld-le p ~[a b])
::
++  nxt  |=(ln=live-expr `live-expr`[%next ln])
::
::  +|  positiveClosure + alpha/beta triples
::
++  positive-closure
  ::  TBPar.positiveClosure: every positive sub-term (major operator not a
  ::  negation), adding the ()<>/()[] next particles for LNEven/LNAll. There
  ::  can be no LNActions. `tps` is a worklist (order does not affect the set).
  |=  p=par
  ^-  par
  =/  tps=par  p
  =|  res=par
  |-  ^-  par
  ?~  tps  (flop-le res)
  =/  ln  i.tps
  ?-  -.ln
      %neg   $(tps [b.ln t.tps])
      %next  $(tps [b.ln t.tps], res [ln res])
      %even  $(tps [b.ln t.tps], res [(nxt ln) ln res])
      %all   $(tps [b.ln t.tps], res [(nxt ln) ln res])
      %conj  $(tps (weld-le cs.ln t.tps), res [ln res])
      %disj  $(tps (weld-le ds.ln t.tps), res [ln res])
      %state    $(tps t.tps, res [ln res])
      %bool     $(tps t.tps, res [ln res])
      %act      ~|(%tlc-live-encountered-actions !!)
      %enabled  ~|(%tlc-live-encountered-actions !!)
  ==
::
++  alpha-triples
  ::  ([]p, p, ()[]p) and (p/\q, p, q)
  |=  p=par
  ^-  (list triple)
  ?~  p  ~
  =/  ln  i.p
  ?:  ?=(%all -.ln)
    [[ln b.ln (nxt ln)] $(p t.p)]
  ?:  ?=(%conj -.ln)
    [[ln (snag-le 0 cs.ln) (snag-le 1 cs.ln)] $(p t.p)]
  $(p t.p)
::
++  beta-triples
  ::  (<>p, p, ()<>p) and (p\/q, p, q)
  |=  p=par
  ^-  (list triple)
  ?~  p  ~
  =/  ln  i.p
  ?:  ?=(%even -.ln)
    [[ln b.ln (nxt ln)] $(p t.p)]
  ?:  ?=(%disj -.ln)
    [[ln (snag-le 0 ds.ln) (snag-le 1 ds.ln)] $(p t.p)]
  $(p t.p)
::
::  +|  local consistency
::
++  locally-consistent
  ::  TBPar.isLocallyConsistent: no state formula and its negation both present.
  ::  Positive bin = LNState/LNBool; negative bin = the body of an LNNeg (which,
  ::  in positive form, is an LNState or LNBool). A clash is inconsistency.
  |=  p=par
  ^-  ?
  =/  bins
    =|  pos=par
    =|  neg=par
    |-  ^-  [pos=par neg=par]
    ?~  p  [pos neg]
    =/  ln  i.p
    ?:  ?|(?=(%state -.ln) ?=(%bool -.ln))
      $(p t.p, pos [ln pos])
    ?:  ?=(%neg -.ln)
      ?:  ?|(?=(%state -.b.ln) ?=(%bool -.b.ln))
        $(p t.p, neg [b.ln neg])
      $(p t.p)
    $(p t.p)
  =/  pos  pos.bins
  |-  ^-  ?
  ?~  pos  &
  ?:  (par-member i.pos neg.bins)  |
  $(pos t.pos)
::
::  +|  particleClosure (the recursive tree search)
::
++  particle-closure
  ::  TBPar.particleClosure entry: positive-close, extract triples, recurse
  |=  p=par
  ^-  (list par)
  =/  pc     (positive-closure p)
  =/  alphas  (alpha-triples pc)
  =/  betas   (beta-triples pc)
  (pc-rec p alphas betas)
::
++  pc-rec
  ::  particleClosure(terms, alphas, betas): alpha-close then beta-branch
  |=  [terms=par alphas=(list triple) betas=(list triple)]
  ^-  (list par)
  ?.  (locally-consistent terms)  ~
  ::  alpha expansion (MP fig 5.1): []p -> p,()[]p ; p/\q -> p,q — to a
  ::  fixpoint. Walk the GROWING term list by index (appends land at the tail),
  ::  so an alpha child that is itself an alpha formula ([] introduced by a /\,
  ::  say) is expanded in turn; a single pass over a snapshot would drop it.
  =/  t1=par
    =/  i  0
    |-  ^-  par
    ?:  =(i (lent terms))  terms
    =/  ln  (snag-le i terms)
    =/  ks=(unit [k1=live-expr k2=live-expr])
      ?:  ?=(%all -.ln)   `[b.ln (nxt ln)]
      ?:  ?=(%conj -.ln)  `[(snag-le 0 cs.ln) (snag-le 1 cs.ln)]
      ~
    ?~  ks  $(i +(i))
    =/  m1  (par-member k1.u.ks terms)
    =/  m2  (par-member k2.u.ks terms)
    =.  terms
      ?:  &(m1 !m2)  (par-append terms k2.u.ks)
      ?:  &(m2 !m1)  (par-append terms k1.u.ks)
      ?:  |(m1 m2)   terms
      (par-append2 terms k1.u.ks k2.u.ks)
    $(i +(i))
  ::  alpha^-1 expansion: if b and c present but not a, add a — to a fixpoint
  ::  (re-sweep while the term grows)
  =/  t2=par
    |-  ^-  par
    =/  swept=par
      =/  as   alphas
      =/  cur  t1
      |-  ^-  par
      ?~  as  cur
      ?:  ?&  (par-member b.i.as cur)
              (par-member c.i.as cur)
              !(par-member a.i.as cur)
          ==
        $(as t.as, cur (par-append cur a.i.as))
      $(as t.as)
    ?:((gth (lent swept) (lent t1)) $(t1 swept) swept)
  ::  a grown-but-inconsistent term is a dead branch
  ?:  ?&((gth (lent t2) (lent terms)) !(locally-consistent t2))  ~
  (pc-beta t2 alphas betas)
::
++  pc-beta
  ::  particleClosureBeta: the first pending beta branches into two closures;
  ::  a beta^-1 recloses; otherwise `terms` is a finished particle
  |=  [terms=par alphas=(list triple) betas=(list triple)]
  ^-  (list par)
  =/  bx  (first-beta terms)
  ?^  bx
    %+  parvec-union
      (pc-rec (par-append terms k1.u.bx) alphas betas)
    (pc-rec (par-append terms k2.u.bx) alphas betas)
  =/  bi  (first-beta-inv terms betas)
  ?^  bi
    (pc-rec (par-append terms u.bi) alphas betas)
  ~[terms]
::
++  first-beta
  ::  the first term expandable by a beta rule whose kappas are both absent
  |=  terms=par
  ^-  (unit [k1=live-expr k2=live-expr])
  =/  cur  terms
  |-  ^-  (unit [k1=live-expr k2=live-expr])
  ?~  cur  ~
  =/  ln  i.cur
  =/  ks=(unit [k1=live-expr k2=live-expr])
    ?:  ?=(%even -.ln)  `[b.ln (nxt ln)]
    ?:  ?=(%disj -.ln)  `[(snag-le 0 ds.ln) (snag-le 1 ds.ln)]
    ~
  ?~  ks  $(cur t.cur)
  ?:  ?&(!(par-member k1.u.ks terms) !(par-member k2.u.ks terms))
    ks
  $(cur t.cur)
::
++  first-beta-inv
  ::  the first beta triple with b or c present but a absent
  |=  [terms=par betas=(list triple)]
  ^-  (unit live-expr)
  ?~  betas  ~
  ?:  ?&  ?|((par-member b.i.betas terms) (par-member c.i.betas terms))
          !(par-member a.i.betas terms)
      ==
    `a.i.betas
  $(betas t.betas)
::
++  parvec-contains
  |=  [ps=(list par) p=par]
  ^-  ?
  ?~  ps  |
  ?:  (par-equal p i.ps)  &
  $(ps t.ps)
::
++  parvec-union
  ::  TBParVec.union: `a`'s members not already in `b`, then all of `b`
  |=  [a=(list par) b=(list par)]
  ^-  (list par)
  ?~  a  b
  ?:  (parvec-contains b i.a)  $(a t.a)
  [i.a $(a t.a)]
::
++  implied-successors
  ::  TBPar.impliedSuccessors: the bodies of the LNNext terms
  |=  p=par
  ^-  par
  ?~  p  ~
  ?:  ?=(%next -.i.p)  [b.i.p $(p t.p)]
  $(p t.p)
::
::  +|  TBGraph construction
::
++  state-preds-of
  ::  TBGraphNode: the level<=1 members become the state predicates
  |=  p=par
  ^-  par
  ?~  p  ~
  ?:  (lte (le-level i.p) 1)  [i.p $(p t.p)]
  $(p t.p)
::
++  build-tableau
  ::  TBGraph(tf): the initial particles are particleClosure({tf}); then each
  ::  node's implied-successor particle-closure yields successor nodes
  ::  (find-or-create), growing the node list; indices are assigned in order.
  |=  tf=live-expr
  ^-  tb-graph
  =/  inits  (particle-closure ~[tf])
  =/  nodes=(list tb-node)
    =/  i  0
    |-  ^-  (list tb-node)
    ?~  inits  ~
    [[i.inits ~ i (state-preds-of i.inits)] $(inits t.inits, i +(i))]
  =/  init-cnt  (lent nodes)
  ::  worklist over a growing node list: process node i, add its successors
  =/  g=tb-graph  [nodes init-cnt]
  =/  i  0
  |-  ^-  tb-graph
  ?:  =(i (lent nodes.g))  g
  =/  src  (snag-node i nodes.g)
  =/  succs  (particle-closure (implied-successors par.src))
  =.  g
    =/  sc  succs
    |-  ^-  tb-graph
    ?~  sc  g
    =^  idx  g  (find-or-create i.sc g)
    =.  nodes.g  (add-next-to nodes.g i idx)
    $(sc t.sc)
  $(i +(i))
::
++  snag-node
  |=  [i=@ud l=(list tb-node)]
  ^-  tb-node
  ?~  l  [~ ~ 0 ~]
  ?:  =(0 i)  i.l
  $(i (dec i), l t.l)
::
++  find-or-create
  ::  the index of the node whose particle equals `p`, creating it (appended
  ::  with a fresh index and state predicates) when absent
  |=  [p=par g=tb-graph]
  ^-  [@ud tb-graph]
  =/  i  0
  |-  ^-  [@ud tb-graph]
  ?:  =(i (lent nodes.g))
    =/  nn=tb-node  [p ~ i (state-preds-of p)]
    [i g(nodes (weld-nodes nodes.g ~[nn]))]
  =/  nd  (snag-node i nodes.g)
  ?:  (par-equal p par.nd)  [i g]
  $(i +(i))
::
++  add-next-to
  ::  append successor index `idx` to node `i`'s nexts
  |=  [l=(list tb-node) i=@ud idx=@ud]
  ^-  (list tb-node)
  ?~  l  ~
  ?:  =(0 i)  [i.l(nexts (welded nexts.i.l idx)) t.l]
  [i.l $(l t.l, i (dec i))]
::
++  welded  |=([l=(list @ud) x=@ud] ^-((list @ud) (weld l ~[x])))
::
++  weld-nodes
  ::  hand-rolled weld over tb-node list (records carry the live-expr mold)
  |=  [a=(list tb-node) b=(list tb-node)]
  ^-  (list tb-node)
  ?~  a  b
  [i.a $(a t.a)]
::
++  tableau-size
  ::  the TABLEAU node count LivenessStruct projects (0 when there is no tf)
  |=  tf=(unit live-expr)
  ^-  @ud
  ?~  tf  0
  (lent nodes:(build-tableau u.tf))
::
::  +|  The TABLEAU projection (R1.6.2)
::
::  LivenessStruct projected only the node COUNT, so nothing compared the graph
::  itself — which is how the 8.2 alpha-closure fixpoint bug came to be found
::  INDIRECTLY, through a product count. These arms reproduce TLC's own
::  `TBGraph.toString` / `TBPar.toString`: per node its index, its particle, and
::  its successor indices, all identity-free.
::
++  render-par
  ::  TBPar.toString(sb, padding): `{e0,\n e1,\n e2}` with each element
  ::  rendered at padding+" " (padding is "" at the top level)
  |=  [modn=@t p=par]
  ^-  tape
  ?~  p  "\{}"
  =/  hd  (weld "\{" (render-expr:tp modn i.p " "))
  =/  rest
    =/  l  t.p
    |-  ^-  tape
    ?~  l  ""
    %+  weld
      (weld ",\0a " (render-expr:tp modn i.l " "))
    $(l t.l)
  :(weld hd rest "}")
::
++  render-tb-node
  ::  one TBGraph.toString node: `Node <i>.` then the particle, then
  ::  ` --> ` and each successor index followed by a space
  |=  [modn=@t n=tb-node]
  ^-  tape
  =/  succs
    =/  l  nexts.n
    |-  ^-  tape
    ?~  l  ""
    (weld (weld (scow %ud i.l) " ") $(l t.l))
  ;:  weld
    "Node "  (scow %ud index.n)  ".\0a"
    (render-par modn par.n)
    " --> "  succs  "\0a"
  ==
::
++  render-tableau
  ::  the per-OrderOfSolution TABLEAU block of the LivenessStruct projection:
  ::  the node count, and — when there IS a tableau — its initial-node count
  ::  and the graph. Built here rather than in temporal.hoon, which cannot
  ::  import this library (tableau.hoon imports temporal.hoon).
  |=  [modn=@t tf=(unit live-expr)]
  ^-  wain
  ?~  tf  ~['TABLEAU 0']
  =/  g  (build-tableau u.tf)
  =/  body
    =/  l  nodes.g
    |-  ^-  tape
    ?~  l  ""
    (weld (render-tb-node modn i.l) $(l t.l))
  ;:  weld
    ^-  wain
    :~  (crip "TABLEAU {(scow %ud (lent nodes.g))}")
        (crip "TBINIT {(scow %ud init-cnt.g)}")
        'TBGRAPH'
    ==
    (to-lines:tp body)
    `wain`~['ENDTBGRAPH']
  ==
--
