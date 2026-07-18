/-  *tla-lus
/=  ast      /lib/tla/ast
/=  syn      /lib/tla/syntax
/=  modules  /lib/tla/modules
|%
  ::  Semantic Graph Construction
  ::
  ::  Port of tla2sany/semantic (Generator + SemanticNode kinds) at the
  ::  pinned commit: builds the semantic graph for a resolved module
  ::  graph. Modules are analyzed in dependency-first order (the
  ::  +sem-order from lib/tla/modules); each produces an export context
  ::  of its visible declarations and definitions, which EXTENDS unions
  ::  and re-exports. The root module's own declarations and definitions
  ::  are then rendered with every operator reference resolved to a
  ::  symbol (builtin, constant, variable, formal parameter, or
  ::  user-defined operator), matching the normalized SemDump oracle.
  ::  Unit 7 adds level computation: each builtin carries its OpLevel and
  ::  ArgWeights, each definition's level is computed from its body in
  ::  dependency order and threaded into the context, and every node is
  ::  dumped with its L<level> (0 constant, 1 state, 2 action, 3 temporal).
  ::  The full level-constraint machinery (level parameters, arg-level
  ::  constraints for higher-order operators) and the linter are later.
  ::
::  +|  Types
::
+$  node  syntax-node:ast
::  a resolved symbol's semantic kind (subset of ASTConstants kinds)
+$  symkind
  $?  %constant  %variable  %user-op  %formal-param
      %builtin   %module-instance  %thm-assump  %new-constant
  ==
::  a symbol's level and per-argument weights drive level computation
::  (unit 7): weights=~ means every argument contributes (all weight 1);
::  otherwise weights.i==0 marks an argument that does not raise the level
::  (e.g. the operand of prime, ENABLED, or a temporal operator)
+$  sym  [kind=symkind arity=@ud variadic=? level=@ud weights=(list @ud)]
::  visible symbols by (canonical) name
+$  ctx  (map @t sym)
::  a definition signature extracted from a definition LHS
+$  dsig  [name=@t s=sym local=?]
::  a semantic diagnostic, pre-structured for later rendering
+$  sem-err
  $%  [%undefined name=@t at=(unit span)]
      [%duplicate name=@t at=(unit span)]
      [%arity name=@t want=@ud got=@ud at=(unit span)]
  ==
::
::  +|  Built-in Operators (tla2sany BuiltInOperators.Properties)
::
::
++  builtins
  ::  name -> [arity variadic opLevel argWeights], transcribed from
  ::  tla2sany BuiltInOperators.Properties (weights ~ means all-1)
  ^-  ctx
  =/  f  |=([a=@ud lv=@ud w=(list @ud)] `sym`[%builtin a | lv w])
  =/  v  |=([lv=@ud w=(list @ud)] `sym`[%builtin 0 & lv w])
  %-  malt
  ^-  (list [@t sym])
  :~  ['STRING' (f 0 0 ~)]   ['FALSE' (f 0 0 ~)]   ['TRUE' (f 0 0 ~)]
      ['BOOLEAN' (f 0 0 ~)]  ['=' (f 2 0 ~)]       ['/=' (f 2 0 ~)]
      ['.' (f 2 0 ~)]        ['\'' (f 1 2 [0 ~])]  ['\\lnot' (f 1 0 ~)]
      ['\\neg' (f 1 0 ~)]    ['\\land' (f 2 0 ~)]  ['\\lor' (f 2 0 ~)]
      ['\\equiv' (f 2 0 ~)]  ['=>' (f 2 0 ~)]      ['SUBSET' (f 1 0 ~)]
      ['UNION' (f 1 0 ~)]    ['DOMAIN' (f 1 0 ~)]  ['\\subseteq' (f 2 0 ~)]
      ['\\in' (f 2 0 ~)]     ['\\notin' (f 2 0 ~)]  ['\\' (f 2 0 ~)]
      ['\\intersect' (f 2 0 ~)]  ['\\union' (f 2 0 ~)]  ['\\times' (f 2 0 ~)]
      ['~>' (f 2 3 [0 0 ~])]  ['[]' (f 1 3 [0 ~])]  ['<>' (f 1 3 [0 ~])]
      ['ENABLED' (f 1 1 [0 ~])]  ['UNCHANGED' (f 1 2 [0 ~])]
      ['\\cdot' (f 2 2 [0 0 ~])]  ['-+->' (f 2 3 [0 0 ~])]
      ['$AngleAct' (f 2 2 [0 0 ~])]
      ['$BoundedChoose' (v 0 ~)]   ['$BoundedExists' (v 0 ~)]
      ['$BoundedForall' (v 0 ~)]   ['$CartesianProd' (v 0 ~)]
      ['$Case' (v 0 ~)]      ['$ConjList' (v 0 ~)]  ['$DisjList' (v 0 ~)]
      ['$Except' (v 0 ~)]    ['$FcnApply' (f 2 0 ~)]
      ['$FcnConstructor' (v 0 ~)]  ['$IfThenElse' (f 3 0 ~)]
      ['$NonRecursiveFcnSpec' (f 1 0 ~)]  ['$Pair' (f 2 0 ~)]
      ['$RcdConstructor' (v 0 ~)]  ['$RcdSelect' (f 2 0 ~)]
      ['$RecursiveFcnSpec' (f 1 0 ~)]  ['$Seq' (v 0 ~)]
      ['$SetEnumerate' (v 0 ~)]    ['$SetOfAll' (v 0 ~)]
      ['$SetOfFcns' (v 0 ~)]       ['$SetOfRcds' (v 0 ~)]
      ['$SF' (f 2 3 [0 0 ~])]  ['$SquareAct' (f 2 2 [0 0 ~])]
      ['$SubsetOf' (f 1 0 ~)]
      ['$TemporalExists' (f 1 3 [0 ~])]  ['$TemporalForall' (f 1 3 [0 ~])]
      ['$TemporalWhile' (f 2 3 [0 0 ~])]   ['$Tuple' (v 0 ~)]
      ['$UnboundedChoose' (f 1 0 ~)]  ['$UnboundedExists' (f 1 0 ~)]
      ['$UnboundedForall' (f 1 0 ~)]  ['$WF' (f 2 3 [0 0 ~])]
      ['$Nop' (f 1 0 ~)]     ['$Qed' (f 0 0 ~)]    ['$Pfcase' (f 1 0 ~)]
      ['$Have' (f 1 0 ~)]    ['$Take' (f 1 0 ~)]   ['$Pick' (f 1 0 ~)]
      ['$Witness' (v 0 ~)]   ['$Suffices' (f 1 0 ~)]
  ==
::
++  syn-map
  ::  operator-synonym aliases -> canonical name (reuses the parser table)
  ^-  (map @t @t)
  (malt synonym-pairs:syn)
::
++  resolve-syn
  |=  t=@t
  ^-  @t
  (~(gut by syn-map) t t)
::
++  kind-tag
  ::  symkind -> ASTConstants printable kind name (SemDump `opkind=`)
  |=  k=symkind
  ^-  @t
  ?-  k
    %constant         'ConstantDeclKind'
    %variable         'VariableDeclKind'
    %user-op          'UserDefinedOpKind'
    %formal-param     'FormalParamKind'
    %builtin          'BuiltInKind'
    %module-instance  'ModuleInstanceKind'
    %thm-assump       'ThmOrAssumpDefKind'
    %new-constant     'NewConstantKind'
  ==
::
::  +|  Node Helpers
::
::
++  is-kind
  |=  [n=node k=@tas]
  ^-  ?
  ?&  ?=(%node -.n)
      =(kind.n k)
  ==
::
++  leaf-text
  |=  n=node
  ^-  @t
  ?>  ?=(%leaf -.n)
  text.token.n
::
++  leaf-kind
  |=  n=node
  ^-  @tas
  ?>  ?=(%leaf -.n)
  kind.token.n
::
++  loc-tape
  |=  n=node
  ^-  tape
  =/  sp  (span-of:ast n)
  ?~  sp  "~"
  (span-tape:ast u.sp)
::
++  kids-of
  |=  n=node
  ^-  (list node)
  ?:  ?=(%node -.n)  kids.n  ~
::
++  rear-node
  ::  last element; dry sample widens a ?~-narrowed list past the wet +rear
  |=  l=(list node)
  ^-  node
  (rear l)
::
++  add-decls
  ::  insert [name sym decl-node] entries into a context; unlike +gas:by
  ::  this works when the map is empty (gas infers pair types from entries)
  |=  [c=ctx dl=(list [@t sym node])]
  ^-  ctx
  |-  ^-  ctx
  ?~  dl  c
  $(dl t.dl, c (~(put by c) -.i.dl +<.i.dl))
::
++  body-of-module
  ::  the N_Body unit list of an N_Module tree
  |=  tree=node
  ^-  (list node)
  ?.  (is-kind tree %n-module)  ~
  =/  kids  (kids-of tree)
  =/  b  (skim kids |=(k=node (is-kind k %n-body)))
  ?~  b  ~
  (kids-of i.b)
::
++  module-name
  |=  tree=node
  ^-  @t
  =/  nm  (module-name-of:modules tree)
  ?~(nm '' u.nm)
::
::  +|  Definition-LHS Extraction
::
::
++  has-local
  ::  does a kid list contain a LOCAL keyword leaf
  |=  kids=(list node)
  ^-  ?
  %+  lien  kids
  |=(k=node &(?=(%leaf -.k) =(%local kind.token.k)))
::
++  count-params
  ::  N_IdentLHS parameter count (n-paramdecl / n-identdecl kids)
  |=  kids=(list node)
  ^-  @ud
  %+  roll  kids
  |=  [k=node acc=@ud]
  ?:  ?|  (is-kind k %n-identdecl)
          (is-kind k %n-paramdecl)
      ==
    +(acc)
  acc
::
++  def-signature
  ::  [name kind arity local] from an N_OperatorDefinition /
  ::  N_FunctionDefinition; ~ if not a definition we register
  |=  nd=node
  ^-  (unit dsig)
  ?:  (is-kind nd %n-operatordefinition)
    =/  kids  (kids-of nd)
    ?~  kids  ~
    =/  lhs  i.kids
    ?.  ?=(%node -.lhs)  ~
    =/  lk  (kids-of lhs)
    =/  loc  (has-local lk)
    =/  leaves  (skim lk |=(k=node ?=(%leaf -.k)))
    ?+    kind.lhs  ~
        %n-identlhs
      =/  ids  (skim lk |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
      ?~  ids  ~
      `[(leaf-text i.ids) [%user-op (count-params lk) | 0 ~] loc]
    ::
        %n-infixlhs
      ::  [ident infixop ident]: operator is the middle leaf
      ?.  (gte (lent leaves) 2)  ~
      `[(resolve-syn (leaf-text (snag 1 leaves))) [%user-op 2 | 0 ~] loc]
    ::
        %n-prefixlhs
      ::  [prefixop ident]: operator is the first leaf
      ?~  leaves  ~
      `[(resolve-syn (leaf-text i.leaves)) [%user-op 1 | 0 ~] loc]
    ::
        %n-postfixlhs
      ::  [ident postfixop]: operator is the last leaf
      ?~  leaves  ~
      `[(resolve-syn (leaf-text (rear-node leaves))) [%user-op 1 | 0 ~] loc]
    ==
  ?:  (is-kind nd %n-functiondefinition)
    =/  kids  (kids-of nd)
    =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    ?~  ids  ~
    `[(leaf-text i.ids) [%user-op 0 | 0 ~] (has-local kids)]
  ~
::
::  +|  Declaration Extraction
::
::
++  decl-syms
  ::  constant/variable declarations of one unit -> [name sym decl-node];
  ::  the decl-node's span is the source location for the header dump
  |=  nd=node
  ^-  (list [@t sym node])
  ?:  (is-kind nd %n-variabledeclaration)
    %+  murn  (kids-of nd)
    |=  k=node
    ^-  (unit [@t sym node])
    ?.  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))  ~
    `[(leaf-text k) [%variable 0 | 1 ~] k]
  ?:  (is-kind nd %n-paramdeclaration)
    ::  CONSTANT decl: n-consdecl head, then n-identdecl / operator params
    ::  (an operator constant like P(_) has nonzero arity)
    %+  murn  (kids-of nd)
    |=  k=node
    ^-  (unit [@t sym node])
    ?.  (is-kind k %n-identdecl)  ~
    =/  ik  (kids-of k)
    ?~  ik  ~
    ?.  &(?=(%leaf -.i.ik) =(%identifier (leaf-kind i.ik)))  ~
    `[(leaf-text i.ik) [%constant (us-arity k) | 0 ~] k]
  ~
::
++  recursive-syms
  ::  operators declared by a RECURSIVE unit, at placeholder level 0
  |=  nd=node
  ^-  (list [@t sym])
  ?.  (is-kind nd %n-recursive)  ~
  %+  murn  (kids-of nd)
  |=  k=node
  ^-  (unit [@t sym])
  ?.  (is-kind k %n-identdecl)  ~
  =/  ik  (kids-of k)
  ?~  ik  ~
  ?.  &(?=(%leaf -.i.ik) =(%identifier (leaf-kind i.ik)))  ~
  `[(leaf-text i.ik) [%user-op (us-arity k) | 0 ~]]
::
++  put-syms
  ::  explicit fold; +roll would discard the seeded accumulator
  |=  [c=ctx syms=(list [@t sym])]
  ^-  ctx
  ?~  syms  c
  $(c (~(put by c) -.i.syms +.i.syms), syms t.syms)
::
++  inst-syms
  ::  the ctx entries an INSTANCE unit contributes
  |=  [iu=[name=(unit @t) local=? nl=node] deps=(map @t ctx) full=ctx]
  ^-  (list [@t sym])
  =/  ip  (inst-parts nl.iu)
  =/  bctx  (~(gut by deps) mod.ip ~)
  =/  sub-lvl
    %+  roll  subs.ip
    |=  [[param=@t expr=node] acc=@ud]
    (max acc (expr-level expr full))
  %+  murn  ~(tap by bctx)
  |=  [opn=@t s=sym]
  ^-  (unit [@t sym])
  ?.  =(%user-op kind.s)  ~
  `[(inst-op-name name.iu opn) s(level (max level.s sub-lvl))]
::
::  +|  Module Export Contexts (dependency-first)
::
::
++  def-level
  ::  the level SANY assigns to a definition: the level of its body with
  ::  the definition's formal parameters in scope (constant level)
  |=  [nd=node c=ctx]
  ^-  @ud
  ?:  (is-kind nd %n-functiondefinition)  (fcn-level nd c)
  =/  kids  (kids-of nd)
  ?~  kids  0
  =/  c2  (add-params c (lhs-params i.kids))
  (expr-level (rear-node kids) c2)
::
++  build-ctx
  ::  fold the module's units in order, threading the accumulating
  ::  context so each definition's level can be computed from the names
  ::  already in scope. Returns the full internal context (builtins +
  ::  imports + own) and the exported context (re-exported imports + own
  ::  non-local symbols) with the same computed levels.
  |=  [tree=node deps=(map @t ctx)]
  ^-  [full=ctx exported=ctx]
  =/  imports=ctx
    %+  roll  (refs-of:modules tree)
    |=  [r=@t acc=ctx]
    (~(uni by acc) (~(gut by deps) r ~))
  =/  full=ctx  (~(uni by builtins) imports)
  =/  exported=ctx  imports
  =/  units  (body-of-module tree)
  |-  ^-  [ctx ctx]
  ?~  units  [full exported]
  =/  u  i.units
  =/  dsyms  (decl-syms u)
  =.  full  (add-decls full dsyms)
  =.  exported  (add-decls exported dsyms)
  ::  RECURSIVE F(_) pre-registers the operator so later (and mutually
  ::  recursive) bodies resolve it; the definition recomputes its level
  =/  rsyms  (recursive-syms u)
  =.  full  (put-syms full rsyms)
  =.  exported  (put-syms exported rsyms)
  ::  INSTANCE imports the instanced module's operators (prefixed for a
  ::  named instance); level approximated as max of the exported level
  ::  and the substitution expressions' levels
  =/  iu  (unit-instance u)
  =?  full  ?=(^ iu)  (put-syms full (inst-syms u.iu deps full))
  =?  exported  ?&(?=(^ iu) !local.u.iu)
    (put-syms exported (inst-syms u.iu deps full))
  =/  ds  (def-signature u)
  ?~  ds  $(units t.units)
  =/  s2=sym  s.u.ds
  =.  level.s2  (def-level u full)
  =.  full  (~(put by full) name.u.ds s2)
  =?  exported  !local.u.ds  (~(put by exported) name.u.ds s2)
  $(units t.units)
::
++  export-ctx
  |=  [tree=node deps=(map @t ctx)]
  ^-  ctx
  exported:(build-ctx tree deps)
::
++  analyze
  ::  export contexts for every module in dependency-first order
  |=  [order=(list @t) mods=(map @t loaded:modules) deps=(map @t (list @t))]
  ^-  (map @t ctx)
  %+  roll  order
  |=  [nm=@t acc=(map @t ctx)]
  ^-  (map @t ctx)
  =/  ld  (~(get by mods) nm)
  ?~  ld  acc
  (~(put by acc) nm (export-ctx tree.u.ld acc))
::
::  +|  Root Dump (normalized SemDump format)
::
::
++  full-ctx
  ::  everything visible inside the root, with computed definition levels
  |=  [tree=node deps=(map @t ctx)]
  ^-  ctx
  full:(build-ctx tree deps)
::
++  ind
  |=  d=@ud
  ^-  tape
  (reap (mul 2 d) ' ')
::
++  line
  |=  [d=@ud t=tape]
  ^-  @t
  (crip (weld (ind d) t))
++  a-co
  |=  n=@ud
  ^-  tape
  (dec-tape:ast n)
++  find-ident
  ::  first identifier leaf (possibly wrapped in n-identdecl) named nm
  |=  [kids=(list node) nm=@t]
  ^-  (unit node)
  |-  ^-  (unit node)
  ?~  kids  ~
  =/  k  i.kids
  ?:  &(?=(%leaf -.k) =(%identifier (leaf-kind k)) =(nm (leaf-text k)))
    `k
  ?:  ?=(%node -.k)
    =/  sub  $(kids kids.k)
    ?^  sub  sub
    $(kids t.kids)
  $(kids t.kids)
++  fcn-level
  ::  the level of a function definition's body (bound vars in scope)
  |=  [u=node c=ctx]
  ^-  @ud
  =/  kids  (kids-of u)
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  c
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  (expr-level (rear-node kids) c2)
::
++  yn
  |=  b=?
  ^-  tape
  ?:(b "y" "n")
::
++  us-arity
  ::  a parameter's arity = the number of `_` placeholders in its
  ::  declaration (e.g. op(_,_) has arity 2, a plain identifier arity 0)
  |=  n=node
  ^-  @ud
  =/  kids  (kids-of n)
  %+  roll  kids
  |=  [k=node acc=@ud]
  ?:  &(?=(%leaf -.k) =(%us (leaf-kind k)))  +(acc)  acc
::
++  lhs-params
  ::  [param-name param-node arity] list from a definition LHS
  |=  lhs=node
  ^-  (list [@t node @ud])
  ?.  ?=(%node -.lhs)  ~
  =/  lk  (kids-of lhs)
  ?+    kind.lhs  ~
      %n-identlhs
    %+  murn  lk
    |=  k=node
    ^-  (unit [@t node @ud])
    ?.  (is-kind k %n-identdecl)  ~
    =/  ik  (kids-of k)
    ?~  ik  ~
    `[(leaf-text i.ik) k (us-arity k)]
  ::
      %n-infixlhs
    ::  [ident infixop ident] -> the two identifier leaves (arity 0)
    =/  ids  (skim lk |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    (turn ids |=(k=node [(leaf-text k) k 0]))
  ::
      %n-prefixlhs
    =/  ids  (skim lk |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    (turn ids |=(k=node [(leaf-text k) k 0]))
  ::
      %n-postfixlhs
    =/  ids  (skim lk |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    (turn ids |=(k=node [(leaf-text k) k 0]))
  ==
::
++  add-params
  ::  extend a context with formal parameters (they shadow outer names)
  |=  [c=ctx params=(list [@t node @ud])]
  ^-  ctx
  |-  ^-  ctx
  ?~  params  c
  =/  pn  -.i.params
  =/  par  +>.i.params
  $(params t.params, c (~(put by c) pn [%formal-param par | 0 ~]))
::
::  +|  Expression Translation
::
::
++  op-level
  ::  the level of applying operator `opn` to operand nodes `opnds`:
  ::  max of the operator's own level and each contributing operand's
  ::  level (an operand contributes unless its arg weight is 0)
  |=  [opn=@t c=ctx opnds=(list node)]
  ^-  @ud
  =/  s  (~(get by c) opn)
  =/  oplv  ?~(s 0 level.u.s)
  =/  ws=(list @ud)  ?~(s ~ weights.u.s)
  =/  i  0
  =/  m  oplv
  |-  ^-  @ud
  ?~  opnds  m
  =/  w  (weight-at ws i)
  =/  sub  ?:(=(0 w) 0 (expr-level i.opnds c))
  $(opnds t.opnds, i +(i), m (max m sub))
::
++  weight-at
  ::  arg weight at index i; missing/past-end weights default to 1
  |=  [ws=(list @ud) i=@ud]
  ^-  @ud
  ?~  ws  1
  ?:  =(0 i)  i.ws
  $(ws t.ws, i (dec i))
::
++  max-levels
  |=  [c=ctx ns=(list node)]
  ^-  @ud
  %+  roll  ns
  |=  [k=node acc=@ud]
  (max acc (expr-level k c))
::
++  expr-level
  ::  the semantic level of an expression node under context `c`
  ::  (0 constant, 1 state, 2 action, 3 temporal)
  |=  [n=node c=ctx]
  ^-  @ud
  ?:  ?=(%leaf -.n)  0
  ?+    kind.n  (max-levels c (skim (kids-of n) |=(k=node ?=(%node -.k))))
      ?(%n-number %n-string %n-real)  0
  ::
      %n-parenexpr
    =/  kids  (kids-of n)
    ?:((gte (lent kids) 2) (expr-level (snag 1 kids) c) 0)
  ::
      %n-generalid
    =/  kids  (kids-of n)
    =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    ?~  ids  0
    =/  nm  (leaf-text (rear-node ids))
    =/  pfx  (genid-prefix n)
    (op-level ?~(pfx nm (rap 3 ~[u.pfx nm])) c ~)
  ::
      %n-opapplication
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  (max-levels c (skim kids |=(k=node ?=(%node -.k))))
    =/  gid  (snag 0 kids)
    =/  gk  (kids-of gid)
    =/  ids  (skim gk |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    ?~  ids  0
    =/  args  (skim (kids-of (snag 1 kids)) |=(k=node ?=(%node -.k)))
    =/  nm  (leaf-text (rear-node ids))
    =/  pfx  (genid-prefix gid)
    (op-level ?~(pfx nm (rap 3 ~[u.pfx nm])) c args)
  ::
      %n-infixexpr
    =/  kids  (kids-of n)
    ?.  =(3 (lent kids))  (max-levels c (skim kids |=(k=node ?=(%node -.k))))
    (op-level (op-of-genop (snag 1 kids)) c ~[(snag 0 kids) (snag 2 kids)])
  ::
      %n-prefixexpr
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  (max-levels c ~)
    (op-level (op-of-genop (snag 0 kids)) c ~[(snag 1 kids)])
  ::
      %n-postfixexpr
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  (max-levels c ~)
    (op-level (op-of-genop (snag 1 kids)) c ~[(snag 0 kids)])
  ::
      %n-conjlist
    %+  roll  (kids-of n)
    |=  [item=node acc=@ud]
    =/  ik  (kids-of item)
    ?.((gte (lent ik) 2) acc (max acc (expr-level (snag 1 ik) c)))
  ::
      %n-disjlist
    %+  roll  (kids-of n)
    |=  [item=node acc=@ud]
    =/  ik  (kids-of item)
    ?.((gte (lent ik) 2) acc (max acc (expr-level (snag 1 ik) c)))
  ::
      ?(%n-setenumerate %n-tuple %n-ifthenelse %n-setoffcns)
    (max-levels c (skim (kids-of n) |=(k=node ?=(%node -.k))))
  ::
      %n-letin
    ::  a LET expression's level is the level of its body (in the
    ::  extended context); approximate with the body node's own level
    (max-levels c ~[(rear-node (kids-of n))])
  ::
      ?(%n-boundquant %n-unboundquant %n-unboundorboundchoose %n-subsetof %n-setofall)
    (max-levels c (skim (kids-of n) |=(k=node ?=(%node -.k))))
  ::
      ?(%n-rcdconstructor %n-setofrcds %n-recordcomponent %n-case)
    (max-levels c (skim (kids-of n) |=(k=node ?=(%node -.k))))
  ::
      ?(%n-actionexpr %n-fairnessexpr)
    (op-level (action-op n) c (skim (kids-of n) |=(k=node ?=(%node -.k))))
  ==
::
++  action-op
  ::  the builtin operator for an N_ActionExpr / N_FairnessExpr, from its
  ::  delimiter: [A]_v -> $SquareAct, <<A>>_v -> $AngleAct, WF -> $WF,
  ::  SF -> $SF
  |=  n=node
  ^-  @t
  =/  kinds  (turn (skim (kids-of n) |=(k=node ?=(%leaf -.k))) leaf-kind)
  ?:  (lien kinds |=(k=@tas =(%arsb k)))  '$SquareAct'
  ?:  (lien kinds |=(k=@tas =(%arab k)))  '$AngleAct'
  ?:  (lien kinds |=(k=@tas =(%wf k)))    '$WF'
  ?:  (lien kinds |=(k=@tas =(%sf k)))    '$SF'
  '$SquareAct'
++  maybebound-range
  ::  the range expression (after \in) of an N_MaybeBound
  |=  mb=node
  ^-  (unit node)
  =/  kids  (kids-of mb)
  |-  ^-  (unit node)
  ?~  kids  ~
  ?:  &(?=(%leaf -.i.kids) =(%t-in (leaf-kind i.kids)))
    ?~(t.kids ~ `i.t.kids)
  $(kids t.kids)
::
++  idents-before-colon
  ::  identifier leaves appearing before the first `:` in a kid list
  |=  kids=(list node)
  ^-  (list [@t node])
  |-  ^-  (list [@t node])
  ?~  kids  ~
  =/  k  i.kids
  ?:  &(?=(%leaf -.k) =(%colon (leaf-kind k)))  ~
  ?:  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))
    [[(leaf-text k) k] $(kids t.kids)]
  $(kids t.kids)
::
++  add-idents
  ::  extend a context with 0-ary bound identifiers
  |=  [c=ctx vars=(list [@t node])]
  ^-  ctx
  |-  ^-  ctx
  ?~  vars  c
  $(vars t.vars, c (~(put by c) -.i.vars [%formal-param 0 | 0 ~]))
++  range-after-in
  ::  the expression following the first \in leaf
  |=  kids=(list node)
  ^-  (unit node)
  |-  ^-  (unit node)
  ?~  kids  ~
  ?:  &(?=(%leaf -.i.kids) =(%t-in (leaf-kind i.kids)))
    ?~(t.kids ~ `i.t.kids)
  $(kids t.kids)
::
++  expr-after-colon
  ::  the first node following the `:` leaf
  |=  kids=(list node)
  ^-  (unit node)
  |-  ^-  (unit node)
  ?~  kids  ~
  ?:  &(?=(%leaf -.i.kids) =(%colon (leaf-kind i.kids)))
    |-  ^-  (unit node)
    ?~  t.kids  ~
    ?:  ?=(%node -.i.t.kids)  `i.t.kids
    $(t.kids t.t.kids)
  $(kids t.kids)
::
++  expr-before-colon
  ::  the first node before the `:` leaf
  |=  kids=(list node)
  ^-  (unit node)
  |-  ^-  (unit node)
  ?~  kids  ~
  ?:  &(?=(%leaf -.i.kids) =(%colon (leaf-kind i.kids)))  ~
  ?:  ?=(%node -.i.kids)  `i.kids
  $(kids t.kids)
::
++  idents-after-colon-idents
  ::  bound identifiers appearing after the `:` in a set-of-all form
  |=  kids=(list node)
  ^-  (list [@t node])
  =/  past  |
  |-  ^-  (list [@t node])
  ?~  kids  ~
  =/  k  i.kids
  ?:  &(?=(%leaf -.k) =(%colon (leaf-kind k)))  $(kids t.kids, past &)
  ?:  &(past ?=(%leaf -.k) =(%identifier (leaf-kind k)))
    [[(leaf-text k) k] $(kids t.kids)]
  $(kids t.kids)
++  comp-level
  ::  level of one EXCEPT component: .h is 0, [e] the expr's level,
  ::  [a, b] the max over the tuple
  |=  [cn=node c=ctx]
  ^-  @ud
  =/  ck  (kids-of cn)
  ?~  ck  0
  ?:  &(?=(%leaf -.i.ck) =(%dot (leaf-kind i.ck)))  0
  (max-levels c (skim `(list node)`ck |=(k=node ?=(%node -.k))))
++  node-text
  ::  a node's textual content: a leaf's token text, or an interior
  ::  node's image (operator sub-nodes like N_InfixOp are childless
  ::  tok-nodes carrying the operator text in their image)
  |=  n=node
  ^-  @t
  ?-  -.n
    %leaf  text.token.n
    %node  image.n
  ==
::
++  op-of-genop
  ::  operator name from an N_GenInfixOp / N_GenPrefixOp / N_GenPostfixOp
  ::  (or a bare op leaf); the operator is the last child; synonym-resolved
  |=  n=node
  ^-  @t
  ?:  ?=(%leaf -.n)  (resolve-syn (leaf-text n))
  =/  kids  (kids-of n)
  ?~  kids  ''
  (resolve-syn (node-text (rear-node kids)))
++  qbound-vars
  ::  bound variable [name node] pairs before the \in in an N_QuantBound
  |=  qb=node
  ^-  (list [@t node])
  =/  ks  (kids-of qb)
  |-  ^-  (list [@t node])
  ?~  ks  ~
  =/  k  i.ks
  ?:  &(?=(%leaf -.k) =(%t-in (leaf-kind k)))  ~
  ?:  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))
    [[(leaf-text k) k] $(ks t.ks)]
  $(ks t.ks)
::
++  qbound-range
  ::  the range expression (after \in) of an N_QuantBound
  |=  qb=node
  ^-  (unit node)
  =/  kids  (kids-of qb)
  |-  ^-  (unit node)
  ?~  kids  ~
  ?:  &(?=(%leaf -.i.kids) =(%t-in (leaf-kind i.kids)))
    ?~(t.kids ~ `i.t.kids)
  $(kids t.kids)
++  subtree-names-has
  ::  does any identifier leaf in the subtree equal nm
  |=  [n=node nm=@t]
  ^-  ?
  ?:  ?=(%leaf -.n)
    &(=(%identifier kind.token.n) =(nm text.token.n))
  %+  lien  (kids-of n)
  |=(k=node (subtree-names-has k nm))
::
++  num-value
  ::  the numeric literal text under an N_Number / N_Real
  |=  n=node
  ^-  @t
  =/  kids  (kids-of n)
  =/  leaves  (skim kids |=(k=node ?=(%leaf -.k)))
  ?~  leaves  ''
  (leaf-text i.leaves)
::
++  str-value
  ::  the string content (quotes stripped) of an N_String; the text is
  ::  the node's image, e.g. `"hello"`
  |=  n=node
  ^-  @t
  ?.  ?=(%node -.n)  ''
  =/  raw  (trip image.n)
  ?:  ?&  (gte (lent raw) 2)
          =('"' (rear raw))
          =('"' (snag 0 raw))
      ==
    (crip (scag (sub (lent raw) 2) (slag 1 raw)))
  (crip raw)
++  dump-sem
  ::  resolve the module graph, analyze in dependency order, generate
  ::  the typed semantic IR for the root module (with SANY's recovery:
  ::  nullODN sentinels, duplicate-definition dropping, the Errors
  ::  channel), and render the normalized SemDump projection
  |=  [root=@t src=(map @t @t)]
  ^-  wain
  =/  r  (resolve:modules root (inline-resolver:modules src) ~)
  ?:  ?=(%| -.out.r)  ~['REJECT']
  =/  g  p.out.r
  =/  ctxs  (analyze order.g mods.g deps.g)
  =/  rt  (~(get by mods.g) root)
  ?~  rt  ~['REJECT']
  =/  fc  (full-ctx tree.u.rt ctxs)
  :-  'ACCEPT'
  (render-module (gen-module tree.u.rt fc ctxs mods.g))
::
++  generate
  ::  the typed semantic graph for later units (B5 consumes this)
  |=  [root=@t src=(map @t @t)]
  ^-  (unit sem-module)
  =/  r  (resolve:modules root (inline-resolver:modules src) ~)
  ?:  ?=(%| -.out.r)  ~
  =/  g  p.out.r
  =/  ctxs  (analyze order.g mods.g deps.g)
  =/  rt  (~(get by mods.g) root)
  ?~  rt  ~
  `(gen-module tree.u.rt (full-ctx tree.u.rt ctxs) ctxs mods.g)
::  +|  Typed Semantic IR (unit 3: the graph later units consume)
::
::  Molds follow the zuse-408 recursive recipe: every cycle member is a
::  named $+ type with $:-form records. Rendering these nouns in a vase
::  is safe (no gates), but they are internal: the public surface stays
::  the normalized dump and, later, typed projections.
::
+$  sspan   (unit span)
+$  sref    $+(sref $:(name=@t kind=symkind))
+$  sbind   $+(sbind $:(name=@t at=sspan))
+$  spar    $+(spar $:(name=@t arity=@ud used=? at=sspan))
+$  sdiag   $+(sdiag $:(code=@ud sev=?(%error %warning) at=sspan msg=@t))
+$  sem
  $+  sem
  $%  sem-apply  sem-letin  sem-lit  sem-atref  sem-nullodn
  ==
+$  sem-apply
  $+  sem-apply
  $:  %apply
      op=sref
      lvl=@ud
      at=sspan
      ubound=(list sbind)
      bound=(list sem-bound)
      args=(list sem)
  ==
+$  sem-bound   $+(sem-bound $:(vars=(list sbind) range=(unit sem)))
+$  sem-letin
  $+  sem-letin
  $:  %letin
      lets=(list sem-def)
      body=(unit sem)
      lvl=@ud
      at=sspan
  ==
+$  sem-lit     $+(sem-lit $:(%lit kind=?(%num %str %dec) val=@t at=sspan))
+$  sem-atref   $+(sem-atref $:(%atref lvl=@ud at=sspan))
+$  sem-nullodn  $+(sem-nullodn $:(%nullodn ~))
::  a substitution wrapper ($SubstIn) is encoded as a reserved %apply:
::  op ['$SubstIn' %builtin], ubound = the substituted parameter names,
::  args = the substitution expressions then the wrapped body last;
::  adding it as its own $% member loops the zuse-408 mold compiler
::  even in shapes isomorphic to sem-apply
+$  sem-thm
  $+  sem-thm
  $:  name=(unit @t)
      local=?
      lvl=@ud
      at=sspan
      body=(unit sem)
  ==
+$  sem-inst  [name=(unit @t) mod=@t local=? at=sspan]
+$  sem-def
  $+  sem-def
  $:  %sdef
      name=@t
      arity=@ud
      local=?
      lvl=@ud
      at=sspan
      params=(list spar)
      body=(unit sem)
  ==
+$  sem-module
  $:  name=@t
      at=sspan
      consts=(list [name=@t arity=@ud at=sspan])
      vars=(list [name=@t at=sspan])
      defs=(list sem-def)
      thmdefs=(list sem-thm)
      assumes=(list sem-thm)
      theorems=(list sem-thm)
      instances=(list sem-inst)
      diags=(list sdiag)
  ==
::  generator output: ~ when SANY's Generator returns null (the node
::  vanishes from the graph), plus diagnostics in report order
+$  gout  [r=(unit sem) ds=(list sdiag)]
::
::  +|  Semantic Generator (CST -> IR, with SANY error recovery)
::
::
++  inst-parts
  ::  the N_NonLocalInstance pieces: module name and WITH substitutions
  |=  nl=node
  ^-  [mod=@t subs=(list [param=@t expr=node])]
  =/  kids  (kids-of nl)
  =/  mod
    =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    ?~(ids '' (leaf-text i.ids))
  :-  mod
  %+  murn  kids
  |=  k=node
  ^-  (unit [param=@t expr=node])
  ?.  (is-kind k %n-substitution)  ~
  =/  sk  (kids-of k)
  ?.  ?=([* * * *] sk)  ~
  `[(node-text (snag 0 `(list node)`sk)) (snag 2 `(list node)`sk)]
::
++  unit-instance
  ::  a module unit's instance content: named (I == INSTANCE ..),
  ::  unnamed (INSTANCE ..), or ~
  |=  u=node
  ^-  (unit [name=(unit @t) local=? nl=node])
  ?:  (is-kind u %n-moduledefinition)
    =/  kids  (kids-of u)
    =/  local  (has-local kids)
    =/  nls  (skim kids |=(k=node (is-kind k %n-nonlocalinstance)))
    ?~  nls  ~
    =/  lhs  (skim kids |=(k=node (is-kind k %n-identlhs)))
    =/  nm=(unit @t)
      ?~  lhs  ~
      =/  ids  (skim (kids-of i.lhs) |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
      ?~(ids ~ `(leaf-text i.ids))
    `[nm local i.nls]
  ?.  (is-kind u %n-instance)  ~
  =/  kids  (kids-of u)
  =/  local  (has-local kids)
  =/  nls  (skim kids |=(k=node (is-kind k %n-nonlocalinstance)))
  ?~  nls  ~
  `[~ local i.nls]
::
++  inst-op-name
  |=  [inm=(unit @t) opn=@t]
  ^-  @t
  ?~  inm  opn
  (rap 3 ~[u.inm '!' opn])
::
++  derr
  |=  [code=@ud at=sspan msg=tape]
  ^-  sdiag
  [code %error at (crip msg)]
::
++  dwarn
  |=  [code=@ud at=sspan msg=tape]
  ^-  sdiag
  [code %warning at (crip msg)]
::
++  drop-nulls
  |=  rs=(list (unit sem))
  ^-  (list sem)
  %+  murn  rs
  |=(u=(unit sem) u)
::
++  g-list
  ::  generate a list of expressions, threading diagnostics in order
  |=  [ns=(list node) c=ctx]
  ^-  [rs=(list sem) ds=(list sdiag)]
  =|  rs=(list sem)
  =|  ds=(list sdiag)
  |-  ^-  [rs=(list sem) ds=(list sdiag)]
  ?~  ns  [(flop rs) ds]
  =/  g  (g-x i.ns c)
  %=  $
    ns  t.ns
    rs  ?~(r.g rs [u.r.g rs])
    ds  (weld ds ds.g)
  ==
::
++  builtin-apply
  ::  an $-operator application over generated children
  |=  [opn=@t n=node c=ctx kids=[ub=(list sbind) bs=(list sem-bound) as=(list sem)]]
  ^-  sem
  [%apply [opn %builtin] (expr-level n c) (span-of:ast n) ub.kids bs.kids as.kids]
::
++  g-x
  ::  generate one expression node (Generator.generateExpression)
  |=  [n=node c=ctx]
  ^-  gout
  ?:  ?=(%leaf -.n)  [~ ~]
  ?+    kind.n  [~ ~]
      %n-parenexpr
    =/  kids  (kids-of n)
    ?:  (gte (lent kids) 2)  (g-x (snag 1 kids) c)
    [~ ~]
  ::
      %n-number
    [`[%lit %num (num-value n) (span-of:ast n)] ~]
  ::
      %n-string
    [`[%lit %str (str-value n) (span-of:ast n)] ~]
  ::
      %n-real
    [`[%lit %dec (num-value n) (span-of:ast n)] ~]
  ::
      %n-generalid
    (g-genid n c)
  ::
      %n-opapplication
    (g-opappl n c)
  ::
      %n-infixexpr
    =/  kids  (kids-of n)
    ?.  =(3 (lent kids))  [~ ~]
    =/  opnode  (snag 1 kids)
    =/  opn  (op-of-genop opnode)
    =/  s  (~(get by c) opn)
    ?~  s
      :-  ~
      :~  %^  derr  4.004  (span-of:ast opnode)
          "Could not find declaration or definition of symbol '{(trip opn)}'."
          %^  derr  4.004  (span-of:ast n)
          "Couldn't resolve infix operator symbol `{(trip opn)}'."
      ==
    =/  gl  (g-x (snag 0 kids) c)
    =/  gr  (g-x (snag 2 kids) c)
    :-  :-  ~
        :*  %apply  [opn kind.u.s]  (expr-level n c)  (span-of:ast n)
            ~  ~  (drop-nulls ~[r.gl r.gr])
        ==
    (weld ds.gl ds.gr)
  ::
      %n-prefixexpr
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  [~ ~]
    =/  opnode  (snag 0 kids)
    =/  opn  (op-of-genop opnode)
    =/  s  (~(get by c) opn)
    ?~  s
      :-  ~
      :~  %^  derr  4.004  (span-of:ast opnode)
          "Could not find declaration or definition of symbol '{(trip opn)}'."
          %^  derr  4.004  (span-of:ast n)
          "Couldn't resolve prefix operator symbol `{(trip opn)}'."
      ==
    =/  ga  (g-x (snag 1 kids) c)
    :-  :-  ~
        :*  %apply  [opn kind.u.s]  (expr-level n c)  (span-of:ast n)
            ~  ~  (drop-nulls ~[r.ga])
        ==
    ds.ga
  ::
      %n-postfixexpr
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  [~ ~]
    =/  opnode  (snag 1 kids)
    =/  opn  (op-of-genop opnode)
    =/  s  (~(get by c) opn)
    ?~  s
      :-  ~
      :~  %^  derr  4.004  (span-of:ast opnode)
          "Could not find declaration or definition of symbol '{(trip opn)}'."
          %^  derr  4.004  (span-of:ast n)
          "Couldn't resolve postfix operator symbol `{(trip opn)}'."
      ==
    =/  ga  (g-x (snag 0 kids) c)
    :-  :-  ~
        :*  %apply  [opn kind.u.s]  (expr-level n c)  (span-of:ast n)
            ~  ~  (drop-nulls ~[r.ga])
        ==
    ds.ga
  ::
      %n-conjlist
    (g-junction '$ConjList' n c)
  ::
      %n-disjlist
    (g-junction '$DisjList' n c)
  ::
      %n-setenumerate
    (g-elems '$SetEnumerate' n c)
  ::
      %n-tuple
    (g-elems '$Tuple' n c)
  ::
      %n-ifthenelse
    =/  kids  (kids-of n)
    ?.  =(6 (lent kids))  [~ ~]
    =/  g  (g-list ~[(snag 1 kids) (snag 3 kids) (snag 5 kids)] c)
    [`(builtin-apply '$IfThenElse' n c [~ ~ rs.g]) ds.g]
  ::
      %n-boundquant
    (g-bound-quant n c)
  ::
      %n-unboundquant
    (g-unbound-quant n c)
  ::
      %n-unboundorboundchoose
    (g-choose n c)
  ::
      %n-letin
    (g-letin n c)
  ::
      %n-subsetof
    (g-subsetof n c)
  ::
      %n-setofall
    (g-setofall n c)
  ::
      %n-setoffcns
    =/  exprs  (skim (kids-of n) |=(k=node ?=(%node -.k)))
    =/  g  (g-list exprs c)
    [`(builtin-apply '$SetOfFcns' n c [~ ~ rs.g]) ds.g]
  ::
      ?(%n-rcdconstructor %n-setofrcds)
    (g-rcd n c)
  ::
      %n-recordcomponent
    (g-rcd-select n c)
  ::
      %n-except
    (g-except n c)
  ::
      %n-case
    (g-case n c)
  ::
      ?(%n-actionexpr %n-fairnessexpr)
    =/  exprs  (skim (kids-of n) |=(k=node ?=(%node -.k)))
    =/  g  (g-list exprs c)
    [`(builtin-apply (action-op n) n c [~ ~ rs.g]) ds.g]
  ==
::
++  genid-prefix
  ::  the ident!ident!.. prefix of a general identifier, as 'I!J!'
  |=  n=node
  ^-  (unit @t)
  =/  kids  (kids-of n)
  =/  pfxs  (skim kids |=(k=node (is-kind k %n-idprefix)))
  ?~  pfxs  ~
  =/  elems  (kids-of i.pfxs)
  ?~  elems  ~
  =/  parts
    %+  murn  `(list node)`elems
    |=  e=node
    ^-  (unit @t)
    ?.  (is-kind e %n-idprefixelement)  ~
    =/  ek  (kids-of e)
    ?~  ek  ~
    ?.  &(?=(%leaf -.i.ek) =(%identifier (leaf-kind i.ek)))  ~
    `(rap 3 ~[(leaf-text i.ek) '!'])
  ?~  parts  ~
  `(rap 3 `(list @t)`parts)
::
++  g-genid
  ::  0-ary reference; @ resolves to the innermost EXCEPT spec (level
  ::  and span travel in the ctx '@' pseudo-entry); an unknown symbol
  ::  becomes the nullODN sentinel with SANY's 4200 error
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~  ids  [~ ~]
  =/  idn  (rear-node `(list node)`ids)
  =/  nm  (leaf-text idn)
  ?:  =('@' nm)
    =/  ats  (~(get by c) '@')
    ?:  ?&(?=(^ ats) ?=([@ @ @ @ ~] weights.u.ats))
      =/  w  weights.u.ats
      [`[%atref level.u.ats `[[i.w i.t.w] [i.t.t.w i.t.t.t.w]]] ~]
    [`[%nullodn ~] ~]
  ::  an I!Op reference resolves under its instance-prefixed name
  =/  nm
    =/  pfx  (genid-prefix n)
    ?~(pfx nm (rap 3 ~[u.pfx nm]))
  =/  s  (~(get by c) nm)
  ?~  s
    :-  `[%nullodn ~]
    [(derr 4.200 (span-of:ast idn) "Unknown operator: `{(trip nm)}'.")]~
  [`[%apply [nm kind.u.s] (expr-level n c) (span-of:ast n) ~ ~ ~] ~]
::
++  g-opappl
  ::  Op(args): resolve, check arity (4204 -> nullODN, args unprocessed)
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  ?.  =(2 (lent kids))  [~ ~]
  =/  gid  (snag 0 kids)
  =/  args-node  (snag 1 kids)
  =/  ids  (skim (kids-of gid) |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~  ids  [~ ~]
  =/  idn  (rear-node `(list node)`ids)
  =/  nm  (leaf-text idn)
  =/  s  (~(get by c) nm)
  ?~  s
    :-  `[%nullodn ~]
    [(derr 4.200 (span-of:ast idn) "Unknown operator: `{(trip nm)}'.")]~
  =/  arg-exprs  (skim (kids-of args-node) |=(k=node ?=(%node -.k)))
  ?.  |(variadic.u.s =(arity.u.s (lent arg-exprs)))
    :-  `[%nullodn ~]
    :_  ~
    %^  derr  4.204  (span-of:ast args-node)
    "The operator {(trip nm)} requires {(a-co arity.u.s)} arguments."
  =/  g  (g-list arg-exprs c)
  :-  :-  ~
      :*  %apply  [nm kind.u.s]  (expr-level n c)  (span-of:ast n)
          ~  ~  rs.g
      ==
  ds.g
::
++  g-junction
  |=  [opn=@t n=node c=ctx]
  ^-  gout
  =/  items
    %+  murn  (kids-of n)
    |=  item=node
    ^-  (unit node)
    =/  ik  (kids-of item)
    ?.(=(2 (lent ik)) ~ `(snag 1 ik))
  =/  g  (g-list items c)
  [`(builtin-apply opn n c [~ ~ rs.g]) ds.g]
::
++  g-elems
  |=  [opn=@t n=node c=ctx]
  ^-  gout
  =/  elems  (skim (kids-of n) |=(k=node ?=(%node -.k)))
  =/  g  (g-list elems c)
  [`(builtin-apply opn n c [~ ~ rs.g]) ds.g]
::
++  g-qbound-groups
  ::  quantifier bound groups: vars + range per N_QuantBound
  |=  [qbounds=(list node) c2=ctx]
  ^-  [bs=(list sem-bound) ds=(list sdiag)]
  =|  bs=(list sem-bound)
  =|  ds=(list sdiag)
  |-  ^-  [bs=(list sem-bound) ds=(list sdiag)]
  ?~  qbounds  [(flop bs) ds]
  =/  vars
    %+  turn  (qbound-vars i.qbounds)
    |=([vn=@t vnode=node] `sbind`[vn (span-of:ast vnode)])
  =/  rng  (qbound-range i.qbounds)
  =/  gr=gout  ?~(rng [~ ~] (g-x u.rng c2))
  %=  $
    qbounds  t.qbounds
    bs       [[vars r.gr] bs]
    ds       (weld ds ds.gr)
  ==
::
++  g-bound-quant
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  ?:  =(~ kids)  [~ ~]
  =/  q  (leaf-kind (snag 0 kids))
  =/  opn  ?:(=(%forall q) '$BoundedForall' '$BoundedExists')
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  c
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  gb  (g-qbound-groups qbounds c2)
  =/  gx  (g-x (rear-node kids) c2)
  :-  `(builtin-apply opn n c2 [~ bs.gb (drop-nulls ~[r.gx])])
  (weld ds.gb ds.gx)
::
++  g-unbound-quant
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  ?:  =(~ kids)  [~ ~]
  =/  q  (leaf-kind (snag 0 kids))
  =/  opn  ?:(=(%forall q) '$UnboundedForall' '$UnboundedExists')
  =/  vars  (idents-before-colon kids)
  =/  c2  (add-idents c vars)
  =/  ub
    %+  turn  vars
    |=([vn=@t vnode=node] `sbind`[vn (span-of:ast vnode)])
  =/  gx  (g-x (rear-node kids) c2)
  [`(builtin-apply opn n c2 [ub ~ (drop-nulls ~[r.gx])]) ds.gx]
::
++  g-choose
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  ?:  =(~ kids)  [~ ~]
  =/  vars  (idents-before-colon kids)
  =/  mbs  (skim kids |=(k=node (is-kind k %n-maybebound)))
  =/  rng=(unit node)
    ?~  mbs  ~
    (maybebound-range i.mbs)
  =/  bounded  ?=(^ mbs)
  =/  opn=@t  ?:(bounded '$BoundedChoose' '$UnboundedChoose')
  =/  c2  (add-idents c vars)
  =/  sbinds
    %+  turn  vars
    |=([vn=@t vnode=node] `sbind`[vn (span-of:ast vnode)])
  =/  gr=gout  ?~(rng [~ ~] (g-x u.rng c2))
  =/  gx  (g-x (rear-node kids) c2)
  :-  :-  ~
      %^  builtin-apply  opn  n
        :-  c2
      ?:  bounded
        [~ [[sbinds r.gr] ~] (drop-nulls ~[r.gx])]
      [sbinds ~ (drop-nulls ~[r.gx])]
  (weld ds.gr ds.gx)
::
++  g-letin
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  =/  defs-node  (skim kids |=(k=node (is-kind k %n-letdefinitions)))
  =/  ldefs
    ?~  defs-node  ~
    (skim (kids-of (snag 0 `(list node)`defs-node)) |=(k=node ?=(%node -.k)))
  =/  body  (rear-node kids)
  =/  c2=ctx
    =/  ds  ldefs
    =/  acc  c
    |-  ^-  ctx
    ?~  ds  acc
    =/  sig  (def-signature i.ds)
    ?~  sig  $(ds t.ds)
    $(ds t.ds, acc (~(put by acc) name.u.sig s.u.sig))
  =/  glets
    =|  out=(list sem-def)
    =|  ds=(list sdiag)
    =/  lds  ldefs
    |-  ^-  [(list sem-def) (list sdiag)]
    ?~  lds  [(flop out) ds]
    =/  gd  (g-def i.lds c2)
    %=  $
      lds  t.lds
      out  ?~(r.gd out [u.r.gd out])
      ds   (weld ds ds.gd)
    ==
  =/  gx  (g-x body c2)
  :-  `[%letin -.glets r.gx (expr-level body c2) (span-of:ast n)]
  (weld +.glets ds.gx)
::
++  g-subsetof
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  =/  vars  (idents-before-colon kids)
  =/  rng  (range-after-in kids)
  =/  c2  (add-idents c vars)
  =/  body  (expr-after-colon kids)
  =/  sbinds
    %+  turn  vars
    |=([vn=@t vnode=node] `sbind`[vn (span-of:ast vnode)])
  =/  gr=gout  ?~(rng [~ ~] (g-x u.rng c2))
  =/  gx=gout  ?~(body [~ ~] (g-x u.body c2))
  :-  `(builtin-apply '$SubsetOf' n c [~ [[sbinds r.gr] ~] (drop-nulls ~[r.gx])])
  (weld ds.gr ds.gx)
::
++  g-setofall
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  c
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  e  (expr-before-colon kids)
  =/  gb  (g-qbound-groups qbounds c2)
  =/  gx=gout  ?~(e [~ ~] (g-x u.e c2))
  :-  `(builtin-apply '$SetOfAll' n c [~ bs.gb (drop-nulls ~[r.gx])])
  (weld ds.gb ds.gx)
::
++  g-rcd
  |=  [n=node c=ctx]
  ^-  gout
  =/  opn  ?:((is-kind n %n-setofrcds) '$SetOfRcds' '$RcdConstructor')
  =/  fields  (skim (kids-of n) |=(k=node ?=(%node -.k)))
  =/  parts
    =|  out=(list sem)
    =|  ds=(list sdiag)
    =/  fs  fields
    |-  ^-  [(list sem) (list sdiag)]
    ?~  fs  [(flop out) ds]
    =/  fk  (kids-of i.fs)
    ?~  fk  $(fs t.fs)
    =/  fname  (leaf-text i.fk)
    =/  gv  (g-x (rear-node fk) c)
    =/  pr=sem
      :*  %apply  ['$Pair' %builtin]  (expr-level i.fs c)  (span-of:ast i.fs)
          ~  ~
          :-  [%lit %str fname (span-of:ast i.fk)]
          (drop-nulls ~[r.gv])
      ==
    $(fs t.fs, out [pr out], ds (weld ds ds.gv))
  [`(builtin-apply opn n c [~ ~ -.parts]) +.parts]
::
++  g-rcd-select
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  ?.  =(3 (lent kids))  [~ ~]
  =/  rec  (snag 0 kids)
  =/  fld  (snag 2 kids)
  =/  gr  (g-x rec c)
  :-  :-  ~
      %^  builtin-apply  '$RcdSelect'  n
      :-  c
      :+  ~  ~
      %+  weld  (drop-nulls ~[r.gr])
      `(list sem)`[%lit %str (leaf-text fld) (span-of:ast fld)]~
  ds.gr
::
++  g-case
  |=  [n=node c=ctx]
  ^-  gout
  =/  arms  (skim (kids-of n) |=(k=node (is-kind k %n-casearm)))
  =/  parts
    =|  out=(list sem)
    =|  ds=(list sdiag)
    =/  as  arms
    |-  ^-  [(list sem) (list sdiag)]
    ?~  as  [(flop out) ds]
    =/  ak  (skim (kids-of i.as) |=(k=node ?=(%node -.k)))
    ?.  =(2 (lent ak))  $(as t.as)
    =/  g  (g-list ak c)
    =/  pr=sem
      :*  %apply  ['$Pair' %builtin]  (expr-level i.as c)  (span-of:ast i.as)
          ~  ~  rs.g
      ==
    $(as t.as, out [pr out], ds (weld ds ds.g))
  [`(builtin-apply '$Case' n c [~ ~ -.parts]) +.parts]
::
++  g-except
  ::  Generator.processExcept on the IR (see +x-except for the shape)
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  ?.  (gte (lent kids) 2)  [~ ~]
  =/  target  (snag 1 kids)
  =/  specs  (skim kids |=(k=node (is-kind k %n-exceptspec)))
  =/  tlvl  (expr-level target c)
  =/  gt  (g-x target c)
  =/  parts
    =|  out=(list sem)
    =|  ds=(list sdiag)
    =/  sps  specs
    |-  ^-  [(list sem) (list sdiag)]
    ?~  sps  [(flop out) ds]
    =/  sp  i.sps
    =/  sk  (kids-of sp)
    =/  comps  (skim sk |=(k=node (is-kind k %n-exceptcomponent)))
    =/  rhs  (rear-node sk)
    =/  clv
      %+  roll  comps
      |=  [cn=node acc=@ud]
      (max acc (comp-level cn c))
    =/  spx  (span-of:ast sp)
    =/  c2
      ?~  spx  c
      %+  ~(put by c)  '@'
      :*  %builtin  0  |  (max tlvl clv)
          ~[line.from.u.spx col.from.u.spx line.to.u.spx col.to.u.spx]
      ==
    =/  gc  (g-comps comps c)
    =/  gr  (g-x rhs c2)
    =/  seqn=sem
      [%apply ['$Seq' %builtin] clv (span-of:ast sp) ~ ~ rs.gc]
    =/  pairn=sem
      :*  %apply  ['$Pair' %builtin]
          (max clv (expr-level rhs c2))  (span-of:ast sp)
          ~  ~
          [seqn (drop-nulls ~[r.gr])]
      ==
    $(sps t.sps, out [pairn out], ds :(weld ds ds.gc ds.gr))
  =/  xlvl
    %+  roll  `(list sem)`-.parts
    |=  [s=sem acc=@ud]
    ?.(?=(%apply -.s) acc (max acc lvl.s))
  :-  :-  ~
      :*  %apply  ['$Except' %builtin]  (max tlvl xlvl)  (span-of:ast n)
          ~  ~
          (weld (drop-nulls ~[r.gt]) `(list sem)`-.parts)
      ==
  (weld ds.gt +.parts)
::
++  g-comps
  ::  EXCEPT spec components as $Seq operands
  |=  [comps=(list node) c=ctx]
  ^-  [rs=(list sem) ds=(list sdiag)]
  =|  rs=(list sem)
  =|  ds=(list sdiag)
  |-  ^-  [rs=(list sem) ds=(list sdiag)]
  ?~  comps  [(flop rs) ds]
  =/  ck  (kids-of i.comps)
  ?~  ck  $(comps t.comps)
  ?:  &(?=(%leaf -.i.ck) =(%dot (leaf-kind i.ck)))
    =/  fld  (rear-node `(list node)`ck)
    %=  $
      comps  t.comps
      rs     [[%lit %str (leaf-text fld) (span-of:ast fld)] rs]
    ==
  =/  exprs  (skim `(list node)`ck |=(k=node ?=(%node -.k)))
  ?:  =(1 (lent exprs))
    =/  g  (g-x (snag 0 exprs) c)
    %=  $
      comps  t.comps
      rs     ?~(r.g rs [u.r.g rs])
      ds     (weld ds ds.g)
    ==
  =/  g  (g-list exprs c)
  =/  tup=sem
    :*  %apply  ['$Tuple' %builtin]  (max-levels c exprs)
        (span-of:ast i.comps)  ~  ~  rs.g
    ==
  $(comps t.comps, rs [tup rs], ds (weld ds ds.g))
::
++  g-fcn-body
  ::  function-definition body: $NonRecursiveFcnSpec / $RecursiveFcnSpec
  |=  [u=node c=ctx]
  ^-  gout
  =/  kids  (kids-of u)
  =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  =/  fname  ?~(ids '' (leaf-text i.ids))
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  body  (rear-node kids)
  =/  recursive  (subtree-names-has body fname)
  =/  opn  ?:(recursive '$RecursiveFcnSpec' '$NonRecursiveFcnSpec')
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  ?:(recursive (~(put by c) fname [%user-op 0 | 0 ~]) c)
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  gb  (g-qbound-groups qbounds c2)
  =/  gx  (g-x body c2)
  :-  :-  ~
      :*  %apply  [opn %builtin]  (expr-level body c2)  (span-of:ast u)
          ~  bs.gb  (drop-nulls ~[r.gx])
      ==
  (weld ds.gb ds.gx)
::
++  g-def
  ::  one operator/function definition (Generator + OpDefNode fields)
  |=  [u=node c=ctx]
  ^-  [r=(unit sem-def) ds=(list sdiag)]
  =/  dsg  (def-signature u)
  ?~  dsg  [~ ~]
  =/  kids  (kids-of u)
  ?:  (is-kind u %n-functiondefinition)
    =/  gb  (g-fcn-body u c)
    :-  :-  ~
        :*  %sdef  name.u.dsg  0  local.u.dsg  (fcn-level u c)
            (span-of:ast u)  ~  r.gb
        ==
    ds.gb
  ?~  kids  [~ ~]
  =/  lhs  i.kids
  =/  body  (rear-node kids)
  =/  params  (lhs-params lhs)
  =/  c2  (add-params c params)
  =/  gb  (g-x body c2)
  =/  sps
    %+  turn  params
    |=  [pn=@t pnode=node par=@ud]
    `spar`[pn par (subtree-names-has body pn) (span-of:ast pnode)]
  :-  :-  ~
      :*  %sdef  name.u.dsg  arity.s.u.dsg  local.u.dsg
          (expr-level body c2)  (span-of:ast u)  sps  r.gb
      ==
  ds.gb
::
++  newsymb-name
  ::  the declared identifier of an N_NewSymb (inside its ident-decl)
  |=  u=node
  ^-  (unit [nm=@t at=sspan])
  =/  decls  (skim (kids-of u) |=(k=node (is-kind k %n-identdecl)))
  ?~  decls  ~
  =/  ik  (kids-of i.decls)
  ?~  ik  ~
  ?.  &(?=(%leaf -.i.ik) =(%identifier (leaf-kind i.ik)))  ~
  `[(leaf-text i.ik) (span-of:ast u)]
::
++  g-assumeprove
  ::  ASSUME items PROVE goal: NEW symbols scope over later items and
  ::  the goal; encoded as a reserved $AssumeProve %apply whose args are
  ::  the assumes then the goal last (NEW symbols as $NewSymb nodes)
  |=  [n=node c=ctx]
  ^-  [r=(unit sem) ds=(list sdiag) lvl=@ud]
  =/  kids  (kids-of n)
  =/  parts
    =|  out=(list sem)
    =|  ds=(list sdiag)
    =/  lvl=@ud  0
    =/  c2  c
    =/  ks  kids
    |-  ^-  [(list sem) (list sdiag) @ud ctx]
    ?~  ks  [(flop out) ds lvl c2]
    =/  k  i.ks
    ?:  ?=(%leaf -.k)  $(ks t.ks)
    ?:  (is-kind k %n-newsymb)
      =/  nn  (newsymb-name k)
      ?~  nn  $(ks t.ks)
      =/  node=sem
        :*  %apply  ['$NewSymb' %builtin]  0  (span-of:ast k)
            [[nm.u.nn ~] ~]  ~  ~
        ==
      %=  $
        ks   t.ks
        out  [node out]
        c2   (~(put by c2) nm.u.nn [%new-constant 0 | 0 ~])
      ==
    =/  g  (g-x k c2)
    %=  $
      ks   t.ks
      out  ?~(r.g out [u.r.g out])
      ds   (weld ds ds.g)
      lvl  (max lvl (expr-level k c2))
    ==
  =/  [ps=(list sem) pds=(list sdiag) plvl=@ud pc=ctx]  parts
  :*  :-  ~
      [%apply ['$AssumeProve' %builtin] plvl (span-of:ast n) ~ ~ ps]
      pds
      plvl
  ==
::
++  g-thm
  ::  ASSUME / THEOREM [name ==] body (expression or ASSUME/PROVE); a
  ::  named one also yields a thmdef
  |=  [u=node c=ctx]
  ^-  [r=sem-thm ds=(list sdiag)]
  =/  kids  (kids-of u)
  =/  nm=(unit @t)
    =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    ?~(ids ~ `(leaf-text i.ids))
  =/  body=(unit node)
    =/  bs  (skim kids |=(k=node ?=(%node -.k)))
    ?~(bs ~ `i.bs)
  ?:  &(?=(^ body) (is-kind u.body %n-assumeprove))
    =/  gap  (g-assumeprove u.body c)
    [[nm | lvl.gap (span-of:ast u) r.gap] ds.gap]
  =/  gb=gout  ?~(body [~ ~] (g-x u.body c))
  =/  lvl  ?~(body 0 (expr-level u.body c))
  [[nm | lvl (span-of:ast u) r.gb] ds.gb]
::
++  g-instance
  ::  an INSTANCE unit: one imported definition per (non-local) operator
  ::  defined in the instanced module, its body wrapped in $substin over
  ::  the WITH substitutions; plus the instance record
  |=  $:  u=node
          iu=[name=(unit @t) local=? nl=node]
          c=ctx
          ctxs=(map @t ctx)
          mods=(map @t loaded:modules)
      ==
  ^-  [defs=(list sem-def) inst=sem-inst ds=(list sdiag)]
  =/  ip  (inst-parts nl.iu)
  =/  irec=sem-inst  [name.iu mod.ip local.iu (span-of:ast u)]
  =/  bt  (~(get by mods) mod.ip)
  ?~  bt  [~ irec ~]
  =/  bctx  (full-ctx tree.u.bt ctxs)
  ::  one substitution per parameter of the instanced module, in its
  ::  declaration order: the WITH expression when given, else the
  ::  implicit same-named symbol of the instantiating module (span =
  ::  the whole INSTANCE unit)
  =/  bparams
    ^-  (list @t)
    %-  zing
    %+  turn  (body-of-module tree.u.bt)
    |=  bu=node
    ^-  (list @t)
    (turn (decl-syms bu) |=([nm=@t *] nm))
  =/  gsubs
    =|  nms=(list @t)
    =|  exs=(list sem)
    =|  ds=(list sdiag)
    =/  pl  bparams
    |-  ^-  [nms=(list @t) exs=(list sem) ds=(list sdiag)]
    ?~  pl  [(flop nms) (flop exs) ds]
    =/  pn  i.pl
    =/  ex=(unit node)
      =/  sl  subs.ip
      |-  ^-  (unit node)
      ?~  sl  ~
      ?:(=(pn param.i.sl) `expr.i.sl $(sl t.sl))
    ?^  ex
      =/  g  (g-x u.ex c)
      %=  $
        pl   t.pl
        nms  ?~(r.g nms [pn nms])
        exs  ?~(r.g exs [u.r.g exs])
        ds   (weld ds ds.g)
      ==
    ::  implicit: the instantiating module's own symbol
    =/  s  (~(get by c) pn)
    ?~  s  $(pl t.pl)
    %=  $
      pl   t.pl
      nms  [pn nms]
      exs  :_  exs
           [%apply [pn kind.u.s] level.u.s (span-of:ast u) ~ ~ ~]
    ==
  =/  sub-lvl
    %+  roll  subs.ip
    |=  [[param=@t expr=node] acc=@ud]
    (max acc (expr-level expr c))
  =/  bunits  (body-of-module tree.u.bt)
  =/  idefs
    =|  out=(list sem-def)
    =|  ds=(list sdiag)
    =/  bus  bunits
    |-  ^-  [(list sem-def) (list sdiag)]
    ?~  bus  [(flop out) ds]
    =/  bu  i.bus
    ?.  ?|  (is-kind bu %n-operatordefinition)
            (is-kind bu %n-functiondefinition)
        ==
      $(bus t.bus)
    =/  gd  (g-def bu bctx)
    ?~  r.gd  $(bus t.bus, ds (weld ds ds.gd))
    =/  base  u.r.gd
    ?:  local.base  $(bus t.bus)
    =/  ilvl  (max lvl.base sub-lvl)
    =/  subw=sem
      :*  %apply  ['$SubstIn' %builtin]  ilvl  (span-of:ast u)
          (turn nms.gsubs |=(nm=@t `sbind`[nm ~]))
          ~
          %+  weld  exs.gsubs
          ^-  (list sem)
          ?~(body.base ~ [u.body.base ~])
      ==
    =/  wrapped=sem-def
      :*  %sdef
          (inst-op-name name.iu name.base)
          arity.base
          local.iu
          ilvl
          (span-of:ast u)
          params.base
          `subw
      ==
    $(bus t.bus, out [wrapped out], ds (weld ds ds.gd))
  [-.idefs irec (weld ds.gsubs +.idefs)]
::
++  gen-module
  ::  the root module's semantic graph, with duplicate-definition
  ::  recovery (keep the first, 4201 error + 4801 warning per repeat),
  ::  INSTANCE-imported definitions ($substin bodies generated from the
  ::  instanced module's own tree), and theorem/assumption bodies
  |=  [tree=node c=ctx ctxs=(map @t ctx) mods=(map @t loaded:modules)]
  ^-  sem-module
  =/  units  (body-of-module tree)
  =/  consts
    ^-  (list [name=@t arity=@ud at=sspan])
    %-  zing
    %+  turn  units
    |=  u=node
    ^-  (list [name=@t arity=@ud at=sspan])
    ?.  (is-kind u %n-paramdeclaration)  ~
    %+  turn  (decl-syms u)
    |=  [nm=@t s=sym at=node]
    [nm arity.s (span-of:ast at)]
  =/  vars
    ^-  (list [name=@t at=sspan])
    %-  zing
    %+  turn  units
    |=  u=node
    ^-  (list [name=@t at=sspan])
    ?.  (is-kind u %n-variabledeclaration)  ~
    %+  turn  (decl-syms u)
    |=  [nm=@t s=sym at=node]
    [nm (span-of:ast at)]
  =/  seen
    =|  acc=(set @t)
    =/  cs  consts
    |-  ^-  (set @t)
    ?~  cs
      =/  vs  vars
      |-  ^-  (set @t)
      ?~  vs  acc
      $(vs t.vs, acc (~(put in acc) name.i.vs))
    $(cs t.cs, acc (~(put in acc) name.i.cs))
  =/  walk
    =|  defs=(list sem-def)
    =|  thmdefs=(list sem-thm)
    =|  assumes=(list sem-thm)
    =|  theorems=(list sem-thm)
    =|  insts=(list sem-inst)
    =|  ds=(list sdiag)
    =/  us  units
    |-  ^-  $:  (list sem-def)  (list sem-thm)  (list sem-thm)
                (list sem-thm)  (list sem-inst)  (list sdiag)
            ==
    ?~  us
      [(flop defs) (flop thmdefs) (flop assumes) (flop theorems) (flop insts) ds]
    =/  u  i.us
    ::  theorem / assumption units
    ?:  ?|  (is-kind u %n-assumption)
            (is-kind u %n-theorem)
        ==
      =/  gt  (g-thm u c)
      %=  $
        us        t.us
        ds        (weld ds ds.gt)
        thmdefs   ?~(name.r.gt thmdefs [r.gt thmdefs])
        assumes   ?.((is-kind u %n-assumption) assumes [r.gt assumes])
        theorems  ?.((is-kind u %n-theorem) theorems [r.gt theorems])
      ==
    ::  INSTANCE units import the instanced module's definitions
    =/  iu  (unit-instance u)
    ?:  ?=(^ iu)
      =/  gi  (g-instance u u.iu c ctxs mods)
      %=  $
        us     t.us
        defs   (weld (flop defs.gi) defs)
        insts  [inst.gi insts]
        ds     (weld ds ds.gi)
      ==
    ?.  ?|  (is-kind u %n-operatordefinition)
            (is-kind u %n-functiondefinition)
        ==
      $(us t.us)
    =/  dsg  (def-signature u)
    ?~  dsg  $(us t.us)
    ?:  (~(has in seen) name.u.dsg)
      %=  $
        us  t.us
        ds  %+  weld  ds
            :~  %^  derr  4.201  (span-of:ast u)
                "Operator {(trip name.u.dsg)} already defined or declared."
                %^  dwarn  4.801  (span-of:ast u)
                "Multiple declarations or definitions for symbol {(trip name.u.dsg)}.  "
            ==
      ==
    =/  gd  (g-def u c)
    %=  $
      us    t.us
      seen  (~(put in seen) name.u.dsg)
      defs  ?~(r.gd defs [u.r.gd defs])
      ds    (weld ds ds.gd)
    ==
  =/  [wdefs=(list sem-def) wthm=(list sem-thm) wass=(list sem-thm) wtheo=(list sem-thm) winst=(list sem-inst) wds=(list sdiag)]
    walk
  :*  (module-name tree)
      (span-of:ast tree)
      consts
      vars
      wdefs
      wthm
      wass
      wtheo
      winst
      wds
  ==
::
::  +|  IR Renderer (the normalized SemDump projection)
::
::
++  strip-tail
  ::  trailing-whitespace normalization applied to golden comparisons
  |=  t=tape
  ^-  tape
  (flop (skip-lead (flop t)))
::
++  skip-lead
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?:(=(' ' i.t) $(t t.t) t)
::
++  sspan-tape
  |=  sp=sspan
  ^-  tape
  ?~  sp  "~"
  "{(a-co line.from.u.sp)}.{(a-co col.from.u.sp)}-{(a-co line.to.u.sp)}.{(a-co col.to.u.sp)}"
::
++  rlvl
  ::  levels print -1 when semantic errors exist (SANY skips levelCheck)
  |=  [mask=? lvl=@ud]
  ^-  tape
  ?:(mask "L-1" "L{(a-co lvl)}")
::
++  render-sem
  |=  [s=sem d=@ud mask=?]
  ^-  wain
  ?-    -.s
      %lit
    =/  tag
      ?-  kind.s
        %num  "num"
        %str  "str"
        %dec  "dec"
      ==
    ~[(line d "{tag} {(trip val.s)} {(rlvl mask 0)} {(sspan-tape at.s)}")]
  ::
      %atref
    ~[(line d "at {(rlvl mask lvl.s)} {(sspan-tape at.s)}")]
  ::
      %nullodn
    ~[(line d "apply nullODN opkind=k0 L-1 0.0-0.0")]
  ::
      %apply
    ?:  =('$NewSymb' name.op.s)
      =/  nm  ?~(ubound.s '' name.i.ubound.s)
      ~[(line d "newsymb {(trip nm)} {(rlvl mask lvl.s)} {(sspan-tape at.s)}")]
    ?:  =('$AssumeProve' name.op.s)
      =/  n-assumes  (dec (max 1 (lent args.s)))
      :-  %+  line  d
          "assumeprove {(rlvl mask lvl.s)} {(sspan-tape at.s)}"
      ;:  weld
        ^-  wain
        %-  zing
        %+  turn  (scag n-assumes args.s)
        |=(a=sem (render-sem a +(d) mask))
      ::
        ~[(line +(d) "prove")]
      ::
        ^-  wain
        %-  zing
        %+  turn  (slag n-assumes args.s)
        |=(a=sem (render-sem a (add d 2) mask))
      ==
    ?:  =('$SubstIn' name.op.s)
      ::  the reserved substitution wrapper (see the mold note above)
      =/  nsubs  (lent ubound.s)
      :-  %+  line  d
          "substin subs={(a-co nsubs)} {(rlvl mask lvl.s)} {(sspan-tape at.s)}"
      ;:  weld
        ^-  wain
        %-  zing
        =/  nms  ubound.s
        =/  exs  (scag nsubs args.s)
        =|  out=(list wain)
        |-  ^-  (list wain)
        ?~  nms  (flop out)
        ?~  exs  (flop out)
        %=  $
          nms  t.nms
          exs  t.exs
          out  :_  out
               :-  (line +(d) "sub {(trip name.i.nms)} <-")
               (render-sem i.exs (add d 2) mask)
        ==
      ::
        ~[(line +(d) "in")]
      ::
        =/  body  (slag nsubs args.s)
        ?~(body ~ (render-sem i.body (add d 2) mask))
      ==
    :-  %+  line  d
        "apply {(trip name.op.s)} opkind={(trip (kind-tag kind.op.s))} {(rlvl mask lvl.s)} {(sspan-tape at.s)}"
    ;:  weld
      ^-  wain
      %+  turn  ubound.s
      |=  b=sbind
      (line +(d) "ubound {(trip name.b)} {(rlvl mask 0)} {(sspan-tape at.b)}")
    ::
      ^-  wain
      %-  zing
      %+  turn  bound.s
      |=  g=sem-bound
      ^-  wain
      %+  weld
        ^-  wain
        %+  turn  vars.g
        |=  b=sbind
        (line +(d) "bound {(trip name.b)} {(rlvl mask 0)} {(sspan-tape at.b)}")
      ?~(range.g ~ (render-sem u.range.g (add d 2) mask))
    ::
      ^-  wain
      %-  zing
      %+  turn  args.s
      |=(a=sem (render-sem a +(d) mask))
    ==
  ::
      %letin
    :-  %+  line  d
        "letin lets={(a-co (lent lets.s))} {(rlvl mask lvl.s)} {(sspan-tape at.s)}"
    ;:  weld
      ^-  wain
      %-  zing
      %+  turn  lets.s
      |=(df=sem-def (render-def df +(d) mask))
    ::
      ~[(line +(d) "in")]
    ::
      ?~(body.s ~ (render-sem u.body.s (add d 2) mask))
    ==
  ==
::
++  render-def
  |=  [df=sem-def d=@ud mask=?]
  ^-  wain
  :-  %+  line  d
      "def {(trip name.df)} arity={(a-co arity.df)} local={(yn local.df)} {(rlvl mask lvl.df)} {(sspan-tape at.df)}"
  %+  weld
    ^-  wain
    %+  turn  params.df
    |=  p=spar
    =/  plv  ?:(|(mask !used.p) "L-1" "L0")
    (line +(d) "param {(trip name.p)} arity={(a-co arity.p)} {plv} {(sspan-tape at.p)}")
  ?~(body.df ~ (render-sem u.body.df +(d) mask))
::
++  render-module
  |=  m=sem-module
  ^-  wain
  =/  mask  (lien diags.m |=(d=sdiag =(%error sev.d)))
  ;:  weld
    ~[(line 0 "MODULE {(trip name.m)} {(sspan-tape at.m)}")]
  ::
    ^-  wain
    %+  turn  consts.m
    |=  [nm=@t arity=@ud at=sspan]
    (line 1 "const {(trip nm)} arity={(a-co arity)} L0 {(sspan-tape at)}")
  ::
    ^-  wain
    %+  turn  vars.m
    |=  [nm=@t at=sspan]
    (line 1 "var {(trip nm)} L1 {(sspan-tape at)}")
  ::
    ^-  wain
    %-  zing
    %+  turn  defs.m
    |=(df=sem-def (render-def df 1 mask))
  ::
    ^-  wain
    %-  zing
    %+  turn  thmdefs.m
    |=  th=sem-thm
    ^-  wain
    :-  %+  line  1
        "thmdef {(trip (fall name.th ''))} local={(yn local.th)} {(rlvl mask lvl.th)} {(sspan-tape at.th)}"
    ?~(body.th ~ (render-sem u.body.th 2 mask))
  ::
    ^-  wain
    %-  zing
    %+  turn  assumes.m
    |=  th=sem-thm
    ^-  wain
    :-  %+  line  1
        %+  weld  "assume"
        "{?~(name.th "" " name={(trip u.name.th)}")} {(rlvl mask lvl.th)} {(sspan-tape at.th)}"
    ?~(body.th ~ (render-sem u.body.th 2 mask))
  ::
    ^-  wain
    %-  zing
    %+  turn  theorems.m
    |=  th=sem-thm
    ^-  wain
    :-  %+  line  1
        %+  weld  "theorem"
        "{?~(name.th "" " name={(trip u.name.th)}")} {(rlvl mask lvl.th)} {(sspan-tape at.th)}"
    ?~(body.th ~ (render-sem u.body.th 2 mask))
  ::
    ^-  wain
    %+  turn  instances.m
    |=  it=sem-inst
    %+  line  1
    %+  weld  "instance"
    "{?~(name.it "" " name={(trip u.name.it)}")} module={(trip mod.it)} local={(yn local.it)} {(rlvl mask 0)} {(sspan-tape at.it)}"
  ::
    ^-  wain
    ?~  diags.m  ~
    :-  'DIAGS'
    %+  turn  `(list sdiag)`diags.m
    |=  dg=sdiag
    %+  line  0
    %-  strip-tail
    "D {(a-co code.dg)} {?:(=(%error sev.dg) "ERROR" "WARNING")} {(sspan-tape at.dg)} {(trip msg.dg)}"
  ==
--
