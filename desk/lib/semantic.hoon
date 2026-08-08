/-  *tla-lus
/=  ast      /lib/ast
/=  syn      /lib/syntax
/=  modules  /lib/modules
|%
  ::  Semantic Graph Construction
  ::
  ::  Port of tla2sany/semantic (Generator + SemanticNode kinds) at the
  ::  pinned commit: builds the semantic graph for a resolved module
  ::  graph. Modules are analyzed in dependency-first order (the
  ::  +sem-order from lib/modules); each produces an export context
  ::  of its visible declarations and definitions, which EXTENDS unions
  ::  and re-exports. The root module's own declarations and definitions
  ::  are then rendered with every operator reference resolved to a
  ::  symbol (builtin, constant, variable, formal parameter, or
  ::  user-defined operator), matching the normalized SemDump oracle.
  ::  Levels: generation computes provisional levels (each builtin carries
  ::  its OpLevel and ArgWeights); the level-check pass (+level-module,
  ::  unit 4) then ports LevelNode/OpDefNode/OpApplNode.levelCheck: level
  ::  parameters, level constraints (min-merged), arg-level constraints
  ::  (max-merged), arg-level params, per-definition maxLevels/weights/
  ::  minMaxLevel/opLevelCond, the two-iteration recursive-section
  ::  fixpoint, node-specific temporal checks, INSTANCE substitution
  ::  checks, and the record-constructor linter. Every node is dumped
  ::  with its post-pass L<level> (L-1 when generation errors kept SANY
  ::  from level checking).
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
+$  sym  [kind=symkind arity=@ud variadic=? level=@ud weights=(list @ud) parg=(list @ud)]
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
  =/  f  |=([a=@ud lv=@ud w=(list @ud)] `sym`[%builtin a | lv w ~])
  =/  v  |=([lv=@ud w=(list @ud)] `sym`[%builtin 0 & lv w ~])
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
++  builtin-maxl
  ::  per-argument maximum levels (BuiltInOperators ArgMaxLevels);
  ::  operators absent here allow MaxLevel (3) for every argument.
  ::  Variadic operators index every argument at position 0.
  ^-  (map @t (list @ud))
  %-  malt
  ^-  (list [@t (list @ud)])
  :~  ['=' ~[2 2]]           ['/=' ~[2 2]]         ['\'' ~[1]]
      ['SUBSET' ~[2]]        ['UNION' ~[2]]        ['DOMAIN' ~[2]]
      ['\\subseteq' ~[2 2]]  ['\\in' ~[2 2]]       ['\\notin' ~[2 2]]
      ['\\' ~[2 2]]          ['\\intersect' ~[2 2]]
      ['\\union' ~[2 2]]     ['\\times' ~[2 2]]
      ['ENABLED' ~[2]]       ['UNCHANGED' ~[1]]    ['\\cdot' ~[2 2]]
      ['$AngleAct' ~[2 1]]   ['$SquareAct' ~[2 1]]
      ['$BoundedChoose' ~[2]]  ['$CartesianProd' ~[2]]
      ['$Except' ~[2]]       ['$FcnApply' ~[2 2]]  ['$RcdSelect' ~[2 0]]
      ['$Seq' ~[2]]          ['$SetEnumerate' ~[2]]
      ['$SetOfAll' ~[2]]     ['$SetOfFcns' ~[2]]   ['$SetOfRcds' ~[2]]
      ['$SF' ~[1 2]]         ['$WF' ~[1 2]]        ['$SubsetOf' ~[2]]
      ['$Tuple' ~[2]]        ['$UnboundedChoose' ~[2]]
      ['$Witness' ~[2]]
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
      `[(leaf-text i.ids) [%user-op (count-params lk) | 0 ~ (turn (lhs-params lhs) |=([@t node a=@ud] a))] loc]
    ::
        %n-infixlhs
      ::  [ident infixop ident]: operator is the middle leaf
      ?.  (gte (lent leaves) 2)  ~
      `[(resolve-syn (leaf-text (snag 1 leaves))) [%user-op 2 | 0 ~ ~] loc]
    ::
        %n-prefixlhs
      ::  [prefixop ident]: operator is the first leaf
      ?~  leaves  ~
      `[(resolve-syn (leaf-text i.leaves)) [%user-op 1 | 0 ~ ~] loc]
    ::
        %n-postfixlhs
      ::  [ident postfixop]: operator is the last leaf
      ?~  leaves  ~
      `[(resolve-syn (leaf-text (rear-node leaves))) [%user-op 1 | 0 ~ ~] loc]
    ==
  ?:  (is-kind nd %n-functiondefinition)
    =/  kids  (kids-of nd)
    =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    ?~  ids  ~
    `[(leaf-text i.ids) [%user-op 0 | 0 ~ ~] (has-local kids)]
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
    `[(leaf-text k) [%variable 0 | 1 ~ ~] k]
  ?:  (is-kind nd %n-paramdeclaration)
    ::  CONSTANT decl: n-consdecl head, then n-identdecl / operator params
    ::  (an operator constant like P(_) has nonzero arity; an operator
    ::  symbol constant `_++_`/`-._`/`_^` registers under its operator
    ::  name at arity 2/1/1, matching the name an infix/prefix/postfix
    ::  use resolves to (R1.3.2.2)
    %+  murn  (kids-of nd)
    |=  k=node
    ^-  (unit [@t sym node])
    ?:  (is-kind k %n-identdecl)
      =/  ik  (kids-of k)
      ?~  ik  ~
      ?.  &(?=(%leaf -.i.ik) =(%identifier (leaf-kind i.ik)))  ~
      `[(leaf-text i.ik) [%constant (us-arity k) | 0 ~ ~] k]
    ::  the operator symbol is a childless tok-node (its text is in the
    ::  image); position and arity depend on the fixity
    =/  oi=(unit [nm=@t ary=@ud])
      =/  ks  (kids-of k)
      ?:  (is-kind k %n-infixdecl)
        ?:  (lth (lent ks) 2)  ~
        `[(resolve-syn (node-text (snag 1 ks))) 2]
      ?:  (is-kind k %n-prefixdecl)
        ?:  (lth (lent ks) 1)  ~
        `[(resolve-syn (node-text (snag 0 ks))) 1]
      ?:  (is-kind k %n-postfixdecl)
        ?:  (lth (lent ks) 2)  ~
        `[(resolve-syn (node-text (snag 1 ks))) 1]
      ~
    ?~  oi  ~
    `[nm.u.oi [%constant ary.u.oi | 0 ~ ~] k]
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
  `[(leaf-text i.ik) [%user-op (us-arity k) | 0 ~ ~]]
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
  ::  EXTENDS re-exports the whole exported context (declarations and
  ::  definitions); INSTANCE imports only definitions, handled per unit
  ::  by +inst-syms below, so its module is NOT folded in here (its raw
  ::  VARIABLE/CONSTANT declarations must not leak into this module)
  =/  imports=ctx
    %+  roll  (extends-of tree)
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
  $(params t.params, c (~(put by c) pn [%formal-param par | 0 ~ ~]))
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
  $(vars t.vars, c (~(put by c) -.i.vars [%formal-param 0 | 0 ~ ~]))
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
  =/  ctxs  (analyze sem-order.g mods.g deps.g)
  =/  rt  (~(get by mods.g) root)
  ?~  rt  ~['REJECT']
  =/  fc  (full-ctx tree.u.rt ctxs)
  :-  'ACCEPT'
  =/  dv  (l-deps root sem-order.g ctxs mods.g)
  =/  lr
    (l-module-core (gen-module tree.u.rt fc ctxs mods.g) fc ctxs mods.g dv)
  ;:  weld
    (render-module m.lr)
    `wain`['LEVELS' ~]
    lvls.lr
  ==
::
++  sany-verdict
  ::  the tier-2 SANY accept/reject verdict (R1.1.1): a spec is accepted
  ::  iff the analyze pipeline resolves it and the semantic + level phases
  ::  raise no %error diagnostic — SANY's own console verdict (it prints
  ::  `*** Errors` and rejects on a semantic/level error, accepts with only
  ::  warnings). A parse or module-resolution failure surfaces as ~ from
  ::  +analyze-graph and is likewise a reject.
  |=  [root=@t src=(map @t @t)]
  ^-  ?(%accept %reject)
  =/  ag  (analyze-graph root src)
  ?~  ag  %reject
  =/  err  |=(ds=(list sdiag) (lien ds |=(d=sdiag =(%error sev.d))))
  ?:  ?|((err sem.u.ag) (err lvl.u.ag))  %reject
  %accept
::
++  generate
  ::  the typed semantic graph for later units (B5 consumes this)
  |=  [root=@t src=(map @t @t)]
  ^-  (unit sem-module)
  =/  r  (resolve:modules root (inline-resolver:modules src) ~)
  ?:  ?=(%| -.out.r)  ~
  =/  g  p.out.r
  =/  ctxs  (analyze sem-order.g mods.g deps.g)
  =/  rt  (~(get by mods.g) root)
  ?~  rt  ~
  =/  fc  (full-ctx tree.u.rt ctxs)
  =/  dv  (l-deps root sem-order.g ctxs mods.g)
  =/  mo  (level-module (gen-module tree.u.rt fc ctxs mods.g) fc ctxs mods.g dv)
  =.  defs.mo  (stamp-origin root defs.mo)
  `mo(imports (ext-defs root sem-order.g ctxs mods.g))
::
++  stamp-origin
  ::  record the defining module on each definition (unit 6C.1). Explicit
  ::  loop: a wet +turn over the recursive sem-def mold fuse-loops here
  |=  [mod=@t ds=(list sem-def)]
  ^-  (list sem-def)
  =|  out=(list sem-def)
  |-  ^-  (list sem-def)
  ?~  ds  (flop out)
  $(ds t.ds, out [i.ds(origin mod) out])
::
++  ext-reach
  ::  the modules the root reaches through EXTENDS, transitively, in the
  ::  graph's dependency-first order and without the root. INSTANCE-only
  ::  modules are excluded: their definitions are visible solely through
  ::  the instance's substituted (and possibly prefixed) copies, which
  ::  +gen-module already places in the root's own defs
  |=  [root=@t order=(list @t) mods=(map @t loaded:modules)]
  ^-  (list @t)
  ::  one reverse sweep suffices: in a dependency-first order every module
  ::  that extends M precedes M when the list is walked backwards
  =/  reach
    =/  rev  (flop order)
    =/  acc=(set @t)  (silt ~[root])
    |-  ^-  (set @t)
    ?~  rev  acc
    ?.  (~(has in acc) i.rev)  $(rev t.rev)
    =/  ld  (~(get by mods) i.rev)
    ?~  ld  $(rev t.rev)
    $(rev t.rev, acc (~(gas in acc) (extends-of tree.u.ld)))
  %+  skim  order
  |=(nm=@t &(!=(nm root) (~(has in reach) nm)))
::
++  body-modules
  ::  StandardModules whose vendored bodies must actually be generated,
  ::  because the pin leaves one of their operators un-overridden (see
  ::  +body-ok in lib/stdops; tests/lib/stdops guards the two against drift).
  ::  Every other standard module's bodies are the dummies TLC overrides —
  ::  the evaluator must never use them, so generating them is wasted work
  ::  and, across a corpus, wasted memory
  ^-  (set @t)
  (silt ~['Bags'])
::
++  ctx-defs
  ::  the definitions a module exports, synthesized from its export context:
  ::  names, arities, and the defining module, with no body. Enough for the
  ::  override registry (which keys on module + name + arity) and for the
  ::  typed rejection a bodyless StandardModule operator must produce
  |=  [mod=@t c=ctx]
  ^-  (list sem-def)
  %+  turn
    %+  sort  ~(tap by c)
    |=([a=[k=@t *] b=[k=@t *]] (aor k.a k.b))
  |=  [nm=@t s=sym]
  ^-  sem-def
  [%sdef nm arity.s | level.s ~ ~ ~ mod]
::
++  ext-defs
  ::  every definition the root inherits through EXTENDS, carrying the
  ::  defining module as its origin. Dependency-first, first definer wins
  ::  (Sequences re-exports Naturals' `+`, but the operator belongs to
  ::  Naturals — the module tlc2 binds its override through). A user module
  ::  is generated from its own tree so its bodies are evaluable and spans
  ::  stay in that module's coordinates; a StandardModule contributes names
  ::  and arities only, unless the pin leaves one of its operators
  ::  un-overridden. LOCAL definitions are not exported and are skipped.
  ::  These are not level-checked: evaluation consumes bodies
  |=  [root=@t order=(list @t) ctxs=(map @t ctx) mods=(map @t loaded:modules)]
  ^-  (list sem-def)
  =/  ms  (ext-reach root order mods)
  =|  seen=(set @t)
  =|  out=(list sem-def)
  |-  ^-  (list sem-def)
  ?~  ms  (flop out)
  =/  ld  (~(get by mods) i.ms)
  ?~  ld  $(ms t.ms)
  =/  std  (~(has by standard-modules:stdmods:modules) i.ms)
  =/  ds
    ?:  &(std !(~(has in body-modules) i.ms))
      (ctx-defs i.ms (~(gut by ctxs) i.ms ~))
    =/  fc  (full-ctx tree.u.ld ctxs)
    (stamp-origin i.ms defs:(gen-module tree.u.ld fc ctxs mods))
  =/  acc
    |-  ^-  [seen=(set @t) out=(list sem-def)]
    ?~  ds  [seen out]
    ?:  |(local.i.ds (~(has in seen) name.i.ds))  $(ds t.ds)
    $(ds t.ds, seen (~(put in seen) name.i.ds), out [i.ds out])
  $(ms t.ms, seen seen.acc, out out.acc)
::
++  analyze-graph
  ::  the analyze pipeline's entry (unit 4.8): resolve, generate, level
  ::  check, and lint the root module, returning the diagnostics split
  ::  by pipeline phase so %analyze can emit only the requested stages.
  ::  ~ when module resolution fails (the caller reports the modres
  ::  diagnostics from its own %parse/%modules stages)
  |=  [root=@t src=(map @t @t)]
  ^-  (unit [sem=(list sdiag) lvl=(list sdiag) lint=(list sdiag)])
  =/  r  (resolve:modules root (inline-resolver:modules src) ~)
  ?:  ?=(%| -.out.r)  ~
  =/  g  p.out.r
  =/  ctxs  (analyze sem-order.g mods.g deps.g)
  =/  rt  (~(get by mods.g) root)
  ?~  rt  ~
  =/  fc  (full-ctx tree.u.rt ctxs)
  =/  dv  (l-deps root sem-order.g ctxs mods.g)
  =/  lr
    (l-module-core (gen-module tree.u.rt fc ctxs mods.g) fc ctxs mods.g dv)
  `phase.lr
::  +|  Typed Semantic IR (unit 3: the graph later units consume)
::
::  Molds follow the zuse-408 recursive recipe: every cycle member is a
::  named $+ type with $:-form records. Rendering these nouns in a vase
::  is safe (no gates), but they are internal: the public surface stays
::  the normalized dump and, later, typed projections.
::
+$  sspan   (unit span)
+$  sref    $+(sref $:(name=@t kind=symkind))
+$  sbind   $+(sbind $:(name=@t used=? at=sspan))
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
::  op ['$SubstIn:<module>' %builtin] (the instanced module's name rides
::  in the op name; match with +substin-mod), ubound = the substituted
::  parameter names, args = the substitution expressions then the
::  wrapped body last; adding it as its own $% member loops the
::  zuse-408 mold compiler even in shapes isomorphic to sem-apply
+$  sem-thm
  $+  sem-thm
  $:  name=(unit @t)
      local=?
      lvl=@ud
      at=sspan
      body=(unit sem)
  ==
::  one INSTANCE substitution as level checking sees it: the instanced
::  module's parameter (with its declaration kind) and the substituting
::  expression (explicit WITH expr or the implicit same-named symbol)
+$  sem-isub
  $+  sem-isub
  $:  param=@t
      pkind=symkind
      expr=(unit sem)
  ==
+$  sem-inst
  $+  sem-inst
  $:  name=(unit @t)
      mod=@t
      local=?
      at=sspan
      subs=(list sem-isub)
  ==
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
      ::  the module that defines this operator (unit 6C.1). Empty for a
      ::  LET or otherwise module-less definition. The evaluator keys the
      ::  StandardModule override registry by it, exactly as tlc2 binds a
      ::  Java method to the module that declares the operator
      origin=@t
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
      ::  recursive sections (ModuleNode.opDefsInRecursiveSection): each
      ::  section lists its member definitions in creation order (a
      ::  RECURSIVE-declared operator is created at the RECURSIVE unit)
      ::  with the RECURSIVE-declared subset
      recsecs=(list [names=(list @t) recs=(list @t)])
      ::  whether the level-check pass ran (SANY skips it when semantic
      ::  generation reported errors; the dump then prints L-1)
      lchecked=?
      ::  definitions reachable through EXTENDS, each carrying the module
      ::  that defines it, dependency-first with the first definer winning
      ::  (unit 6C.1). SANY's ModuleNode.getOpDefs() exposes them the same
      ::  way; they are NOT part of the dump projection (which lists a
      ::  module's own definitions, matching SemDump), only of the
      ::  evaluation environment
      imports=(list sem-def)
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
++  g-arg-list
  ::  operator-application arguments: a bare identifier naming an
  ::  operator of nonzero arity becomes an OpArgNode, encoded as a
  ::  reserved $OpArg %apply (ubound = the operator name, single %num
  ::  literal arg = its arity); everything else generates normally
  |=  [ns=(list node) c=ctx]
  ^-  [rs=(list sem) ds=(list sdiag)]
  =|  rs=(list sem)
  =|  ds=(list sdiag)
  |-  ^-  [rs=(list sem) ds=(list sdiag)]
  ?~  ns  [(flop rs) ds]
  =/  la  (lambda-of i.ns c)
  ?^  la
    $(ns t.ns, rs [u.la rs])
  =/  oa  (oparg-of i.ns c)
  ?^  oa
    $(ns t.ns, rs [u.oa rs])
  =/  g  (g-x i.ns c)
  %=  $
    ns  t.ns
    rs  ?~(r.g rs [u.r.g rs])
    ds  (weld ds ds.g)
  ==
::
++  lam-arity
  ::  the bound-ident count of a LAMBDA node (0 for a non-LAMBDA)
  |=  n=node
  ^-  @ud
  ?.  (is-kind n %n-lambda)  0
  %-  lent
  (skim (kids-of n) |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
::
++  lambda-of
  ::  a LAMBDA in an operator-application argument position: SANY builds
  ::  an OpArgNode referencing a synthesized OpDefNode named LAMBDA. We
  ::  encode it as the reserved $OpArg %apply named LAMBDA — arity = the
  ::  bound-ident count, level = the body level under those params. The
  ::  LAMBDA is anonymous (no LEVELS row) and non-unique (sibling LAMBDAs
  ::  share the name), so it is NOT registered in the context; the $OpArg
  ::  render arm (only reads the arity head) prints just the summary line,
  ::  matching SANY's body-less projection. (R1.3.1.1)
  |=  [n=node c=ctx]
  ^-  (unit sem)
  ?.  (is-kind n %n-lambda)  ~
  =/  kids  (kids-of n)
  =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  =/  body  (rear-node kids)
  =/  params=(list [@t node @ud])
    (turn ids |=(k=node [(leaf-text k) k 0]))
  =/  c2  (add-params c params)
  =/  gb  (g-x body c2)
  =/  sp  (span-of:ast n)
  ::  the bound idents ride in `bound` and the generated body as the args
  ::  tail so level-check (+l-def, R1.3.1.2) can recompute the anonymous
  ::  OpDefNode's level data; both are invisible to the $OpArg render arm,
  ::  which reads only the ubound name and the arity head
  =/  pbinds=(list sbind)
    (turn ids |=(k=node `sbind`[(leaf-text k) & (span-of:ast k)]))
  :-  ~
  :*  %apply  ['$OpArg' %user-op]  (expr-level body c2)  sp
      [['LAMBDA' | sp] ~]
      [[pbinds ~] ~]
      :~  [%lit %num (crip (a-co (lent params))) sp]
          ?~(r.gb [%nullodn ~] u.r.gb)
      ==
  ==
::
++  oparg-of
  ::  the $OpArg encoding when a node is a bare reference to an
  ::  operator with arity > 0 (SANY builds an OpArgNode there)
  |=  [n=node c=ctx]
  ^-  (unit sem)
  ?.  (is-kind n %n-generalid)  ~
  =/  kids  (kids-of n)
  =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~  ids  ~
  =/  nm  (leaf-text (rear-node `(list node)`ids))
  ?:  =('@' nm)  ~
  =/  nm
    =/  pfx  (genid-prefix n)
    ?~(pfx nm (rap 3 ~[u.pfx nm]))
  =/  s  (~(get by c) nm)
  ?~  s  ~
  ?:  =(0 arity.u.s)  ~
  :-  ~
  :*  %apply  ['$OpArg' kind.u.s]  level.u.s  (span-of:ast n)
      [[nm | (span-of:ast n)] ~]  ~
      [[%lit %num (crip (a-co arity.u.s)) (span-of:ast n)] ~]
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
      %n-fcnappl
    ::  f[a] -> $FcnApply(f, a); several selectors tuple up
    =/  kids  (kids-of n)
    ?~  kids  [~ ~]
    =/  gf  (g-x i.kids c)
    =/  argl  (skim t.kids |=(k=node ?=(%node -.k)))
    =/  ga  (g-list argl c)
    =/  args=(list sem)
      ?:  (lte (lent rs.ga) 1)  rs.ga
      [(builtin-apply '$Tuple' n c [~ ~ rs.ga]) ~]
    :-  `(builtin-apply '$FcnApply' n c [~ ~ (weld (drop-nulls ~[r.gf]) args)])
    (weld ds.gf ds.ga)
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
      %n-fcnconst
    (g-fcnconst n c)
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
++  ref-arity
  ::  the referenced operator's arity when a node is a bare (possibly
  ::  instance-prefixed) symbol reference; ~ for any other expression
  |=  [n=node c=ctx]
  ^-  (unit @ud)
  ?.  (is-kind n %n-generalid)  ~
  =/  ids
    %+  skim  (kids-of n)
    |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k))))
  ?~  ids  ~
  =/  nm  (leaf-text (rear-node `(list node)`ids))
  ?:  =('@' nm)  ~
  =/  nm
    =/  pfx  (genid-prefix n)
    ?~(pfx nm (rap 3 ~[u.pfx nm]))
  =/  s  (~(get by c) nm)
  ?~  s  ~
  `arity.u.s
::
++  ref-first-order
  ::  whether a bare operator reference names a FIRST-ORDER operator
  ::  (every formal parameter is an individual — each `parg` entry 0).
  ::  A second-order operator (one with an operator-valued parameter,
  ::  e.g. `D(Op(_))`) cannot be passed as an operator argument: SANY's
  ::  OpDefNode.match rejects it with 4271 even when the arity matches
  ::  (`D(D)` — R1.3.2.1). ~ when the node is not a resolvable op ref.
  |=  [n=node c=ctx]
  ^-  (unit ?)
  ?.  (is-kind n %n-generalid)  ~
  =/  ids
    %+  skim  (kids-of n)
    |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k))))
  ?~  ids  ~
  =/  nm  (leaf-text (rear-node `(list node)`ids))
  ?:  =('@' nm)  ~
  =/  nm
    =/  pfx  (genid-prefix n)
    ?~(pfx nm (rap 3 ~[u.pfx nm]))
  =/  s  (~(get by c) nm)
  ?~  s  ~
  `(levy parg.u.s |=(a=@ud =(0 a)))
::
++  g-opappl
  ::  Op(args): resolve, check arity (4204 -> nullODN, args unprocessed),
  ::  then per-position operator-argument arity checks (an operator
  ::  parameter position must receive an operator of that arity:
  ::  Generator's selector 4270/4271 at the argument, then
  ::  OpDefNode.match's 4271 at the application; the argument becomes
  ::  nullODN)
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
  ::  arguments, checked against the expected per-position arity BEFORE
  ::  generation: a failing operator-argument position emits its
  ::  selector error and becomes nullODN without generating the
  ::  expression (so its own resolution errors never surface, exactly
  ::  like SANY); the match-phase 4271s follow all argument errors
  =/  garg
    =|  out=(list sem)
    =|  ds=(list sdiag)
    =|  d2=(list sdiag)
    =/  i  0
    =/  nl  arg-exprs
    |-  ^-  [out=(list sem) ds=(list sdiag) d2=(list sdiag)]
    ?~  nl  [(flop out) ds d2]
    =/  expect  (at-or parg.u.s i 0)
    ?:  =(0 expect)
      =/  oa  (oparg-of i.nl c)
      ?^  oa  $(nl t.nl, i +(i), out [u.oa out])
      =/  g  (g-x i.nl c)
      %=  $
        nl   t.nl
        i    +(i)
        out  ?~(r.g out [u.r.g out])
        ds   (weld ds ds.g)
      ==
    ::  a LAMBDA of the expected arity supplies the operator argument
    ::  directly (SANY's synthesized OpArgNode -> OpDefNode named LAMBDA)
    =/  la  ?:(=(expect (lam-arity i.nl)) (lambda-of i.nl c) ~)
    ?^  la  $(nl t.nl, i +(i), out [u.la out])
    =/  ra  (ref-arity i.nl c)
    =/  arity-ok  &(?=(^ ra) =(expect u.ra))
    ?:  arity-ok
      ::  the selector builds the OpArgNode (right arity); a FIRST-ORDER
      ::  operator is a valid argument, but a SECOND-ORDER operator (an
      ::  operator-valued parameter, `D(D)`) still fails the match phase
      ::  with 4271 while the oparg stays in the tree (R1.3.2.1)
      =/  oa  (oparg-of i.nl c)
      =/  built  ?~(oa `sem`[%nullodn ~] u.oa)
      =/  fo  (ref-first-order i.nl c)
      ?:  ?=([~ %.y] fo)
        $(nl t.nl, i +(i), out [built out])
      =/  e2
        %^  derr  4.271  (span-of:ast n)
        ;:  weld
          "Argument number {(a-co +(i))} to operator '{(trip nm)}' "
          "\0ashould be a {(a-co expect)}-parameter operator."
        ==
      %=  $
        nl   t.nl
        i    +(i)
        out  [built out]
        d2   (weld d2 [e2 ~])
      ==
    ::  not a matching-arity operator: the selector fails (4270/4271) and
    ::  the argument becomes nullODN, then the match phase's 4271 follows
    =/  e1
      ?^  ra
        %^  derr  4.271  (span-of:ast i.nl)
        "Expected arity {(a-co expect)} but found operator of arity {(a-co u.ra)}."
      %^  derr  4.270  (span-of:ast i.nl)
      ;:  weld
        "An expression appears as argument number {(a-co +(i))}"
        " (counting from 1) to operator '{(trip nm)}',"
        " in a position an operator is required."
      ==
    =/  e2
      %^  derr  4.271  (span-of:ast n)
      ;:  weld
        "Argument number {(a-co +(i))} to operator '{(trip nm)}' "
        "\0ashould be a {(a-co expect)}-parameter operator."
      ==
    %=  $
      nl   t.nl
      i    +(i)
      out  [[%nullodn ~] out]
      ds   (weld ds [e1 ~])
      d2   (weld d2 [e2 ~])
    ==
  :-  :-  ~
      :*  %apply  [nm kind.u.s]  (expr-level n c)  (span-of:ast n)
          ~  ~  out.garg
      ==
  (weld ds.garg d2.garg)
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
    |=([vn=@t vnode=node] `sbind`[vn | (span-of:ast vnode)])
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
    |=([vn=@t vnode=node] `sbind`[vn | (span-of:ast vnode)])
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
    |=([vn=@t vnode=node] `sbind`[vn | (span-of:ast vnode)])
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
    |=([vn=@t vnode=node] `sbind`[vn | (span-of:ast vnode)])
  =/  gr=gout  ?~(rng [~ ~] (g-x u.rng c2))
  =/  gx=gout  ?~(body [~ ~] (g-x u.body c2))
  :-  `(builtin-apply '$SubsetOf' n c [~ [[sbinds r.gr] ~] (drop-nulls ~[r.gx])])
  (weld ds.gr ds.gx)
::
++  g-fcnconst
  ::  the function-constructor expression [x \in S |-> e] ($FcnConstructor);
  ::  unlike a function definition body it has no name and is never recursive
  |=  [n=node c=ctx]
  ^-  gout
  =/  kids  (kids-of n)
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  ::  the body is the last node kid (after the quantbounds), skipping the
  ::  bracket/|-> tokens that a rear-of-all-kids would wrongly pick up
  =/  body  (rear-node (skim kids |=(k=node ?=(%node -.k))))
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  c
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  gb  (g-qbound-groups qbounds c2)
  =/  gx  (g-x body c2)
  :-  :-  ~
      :*  %apply  ['$FcnConstructor' %builtin]  (expr-level body c2)
          (span-of:ast n)  ~  bs.gb  (drop-nulls ~[r.gx])
      ==
  (weld ds.gb ds.gx)
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
  =/  arms
    %+  skim  (kids-of n)
    |=(k=node |((is-kind k %n-casearm) (is-kind k %n-otherarm)))
  =/  parts
    =|  out=(list sem)
    =|  ds=(list sdiag)
    =/  as  arms
    |-  ^-  [(list sem) (list sdiag)]
    ?~  as  [(flop out) ds]
    =/  ak  (skim (kids-of i.as) |=(k=node ?=(%node -.k)))
    =/  g  (g-list ak c)
    ::  an OTHER arm has just a body; give it a nullODN guard so the
    ::  evaluator (and tlc2's null first component) recognizes the default
    =/  args=(list sem)
      ?:  (is-kind i.as %n-otherarm)  [`sem`[%nullodn ~] rs.g]
      rs.g
    ?.  =(2 (lent args))  $(as t.as, ds (weld ds ds.g))
    =/  pr=sem
      :*  %apply  ['$Pair' %builtin]  (expr-level i.as c)  (span-of:ast i.as)
          ~  ~  args
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
          ~
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
  ::  a recursive function binds its own name as an unbounded formal
  ::  at the $RecursiveFcnSpec (span = the whole definition), so
  ::  self-references resolve as FormalParamKind
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  ?:(recursive (~(put by c) fname [%formal-param 0 | 0 ~ ~]) c)
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  gb  (g-qbound-groups qbounds c2)
  =/  gx  (g-x body c2)
  :-  :-  ~
      :*  %apply  [opn %builtin]  (expr-level body c2)  (span-of:ast u)
          ?:(recursive [[fname | (span-of:ast u)] ~] ~)
          bs.gb
          (drop-nulls ~[r.gx])
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
            (span-of:ast u)  ~  r.gb  ''
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
          (expr-level body c2)  (span-of:ast u)  sps  r.gb  ''
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
            [[nm.u.nn | ~] ~]  ~  ~
        ==
      %=  $
        ks   t.ks
        out  [node out]
        c2   (~(put by c2) nm.u.nn [%new-constant 0 | 0 ~ ~])
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
  ::  the WITH substitutions; one imported theorem definition per named
  ::  theorem/assumption, wrapped in $apsubstin; plus the instance
  ::  record. A substitution for an operator-valued parameter is an
  ::  $OpArg, exactly like an operator argument at an application
  |=  $:  u=node
          iu=[name=(unit @t) local=? nl=node]
          c=ctx
          ctxs=(map @t ctx)
          mods=(map @t loaded:modules)
      ==
  ^-  $:  defs=(list sem-def)
          thms=(list sem-thm)
          inst=sem-inst
          ds=(list sdiag)
      ==
  =/  ip  (inst-parts nl.iu)
  =/  irec=sem-inst  [name.iu mod.ip local.iu (span-of:ast u) ~]
  =/  bt  (~(get by mods) mod.ip)
  ?~  bt  [~ ~ irec ~]
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
  ::  substitution order per constructSubst + explicit processing: an
  ::  implicit entry per parameter resolvable in the instantiating
  ::  module, in declaration order; each explicit WITH entry replaces
  ::  its implicit in place, or appends (so an explicit substitution
  ::  for a parameter unknown to the instantiating module comes last)
  =/  ordered
    ^-  (list [pn=@t ex=(unit node)])
    =/  base
      ^-  (list [pn=@t ex=(unit node)])
      %+  murn  bparams
      |=  pn=@t
      ^-  (unit [pn=@t ex=(unit node)])
      ?~((~(get by c) pn) ~ `[pn ~])
    =/  wl  subs.ip
    |-  ^-  (list [pn=@t ex=(unit node)])
    ?~  wl  base
    =/  hit
      =/  bl  base
      |-  ^-  ?
      ?~  bl  |
      ?:(=(param.i.wl pn.i.bl) & $(bl t.bl))
    =/  base2
      ?.  hit
        %+  weld  base
        ^-  (list [pn=@t ex=(unit node)])
        [param.i.wl `expr.i.wl]~
      %+  turn  base
      |=  e=[pn=@t ex=(unit node)]
      ^-  [pn=@t ex=(unit node)]
      ?:(=(param.i.wl pn.e) [pn.e `expr.i.wl] e)
    $(wl t.wl, base base2)
  =/  gsubs
    =|  nms=(list @t)
    =|  exs=(list sem)
    =|  isubs=(list sem-isub)
    =|  ds=(list sdiag)
    =/  pl  ordered
    |-  ^-  $:  nms=(list @t)  exs=(list sem)
                isubs=(list sem-isub)  ds=(list sdiag)
            ==
    ?~  pl  [(flop nms) (flop exs) (flop isubs) ds]
    =/  pn  pn.i.pl
    =/  pkind=symkind
      =/  bs  (~(get by bctx) pn)
      ?~(bs %constant kind.u.bs)
    =/  ex=(unit node)  ex.i.pl
    ?^  ex
      =/  oa  (oparg-of u.ex c)
      ?^  oa
        %=  $
          pl     t.pl
          nms    [pn nms]
          exs    [u.oa exs]
          isubs  [[pn pkind oa] isubs]
        ==
      =/  g  (g-x u.ex c)
      %=  $
        pl     t.pl
        nms    ?~(r.g nms [pn nms])
        exs    ?~(r.g exs [u.r.g exs])
        isubs  [[pn pkind r.g] isubs]
        ds     (weld ds ds.g)
      ==
    ::  implicit: the instantiating module's own symbol (an $OpArg for
    ::  an operator-valued parameter, per constructSubst)
    =/  s  (~(get by c) pn)
    ?~  s  $(pl t.pl)
    =/  iex=sem
      ?:  (gth arity.u.s 0)
        :*  %apply  ['$OpArg' kind.u.s]  level.u.s  (span-of:ast u)
            [[pn | (span-of:ast u)] ~]  ~
            [[%lit %num (crip (a-co arity.u.s)) (span-of:ast u)] ~]
        ==
      [%apply [pn kind.u.s] level.u.s (span-of:ast u) ~ ~ ~]
    %=  $
      pl     t.pl
      nms    [pn nms]
      exs    [iex exs]
      isubs  [[pn pkind `iex] isubs]
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
      :*  %apply  [(cat 3 '$SubstIn:' mod.ip) %builtin]  ilvl  (span-of:ast u)
          (turn nms.gsubs |=(nm=@t `sbind`[nm | ~]))
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
          ''
      ==
    $(bus t.bus, out [wrapped out], ds (weld ds ds.gd))
  ::  named theorems/assumptions import as theorem definitions with the
  ::  body wrapped in $APSubstIn (APSubstInNode)
  =/  ithms
    =|  out=(list sem-thm)
    =|  ds=(list sdiag)
    =/  bus  bunits
    |-  ^-  [(list sem-thm) (list sdiag)]
    ?~  bus  [(flop out) ds]
    =/  bu  i.bus
    ?.  ?|  (is-kind bu %n-assumption)
            (is-kind bu %n-theorem)
        ==
      $(bus t.bus)
    =/  gt  (g-thm bu bctx)
    ?~  name.r.gt  $(bus t.bus, ds (weld ds ds.gt))
    ?~  body.r.gt  $(bus t.bus, ds (weld ds ds.gt))
    ?:  local.r.gt  $(bus t.bus, ds (weld ds ds.gt))
    =/  ilvl  (max lvl.r.gt sub-lvl)
    =/  wbody=sem
      :*  %apply  [(cat 3 '$APSubstIn:' mod.ip) %builtin]  ilvl
          (span-of:ast u)
          (turn nms.gsubs |=(nm=@t `sbind`[nm | ~]))
          ~
          (weld exs.gsubs `(list sem)`[u.body.r.gt ~])
      ==
    =/  wthm=sem-thm
      :*  `(inst-op-name name.iu u.name.r.gt)
          local.iu
          ilvl
          (span-of:ast u)
          `wbody
      ==
    $(bus t.bus, out [wthm out], ds (weld ds ds.gt))
  :*  -.idefs
      -.ithms
      irec(subs isubs.gsubs)
      :(weld ds.gsubs +.idefs +.ithms)
  ==
::
++  own-decls
  ::  a module tree's own CONSTANT and VARIABLE declarations (name,
  ::  arity, span), in declaration order
  |=  tree=node
  ^-  [consts=(list [name=@t arity=@ud at=sspan]) vars=(list [name=@t at=sspan])]
  =/  units  (body-of-module tree)
  :_  ^-  (list [name=@t at=sspan])
      %-  zing
      %+  turn  units
      |=  u=node
      ^-  (list [name=@t at=sspan])
      ?.  (is-kind u %n-variabledeclaration)  ~
      %+  turn  (decl-syms u)
      |=([nm=@t s=sym at=node] [nm (span-of:ast at)])
  ^-  (list [name=@t arity=@ud at=sspan])
  %-  zing
  %+  turn  units
  |=  u=node
  ^-  (list [name=@t arity=@ud at=sspan])
  ?.  (is-kind u %n-paramdeclaration)  ~
  %+  turn  (decl-syms u)
  |=([nm=@t s=sym at=node] [nm arity.s (span-of:ast at)])
::
++  ext-decls
  ::  a module's own declarations followed by those it inherits through
  ::  EXTENDS (transitively; each carrying the declaring module's span),
  ::  deduplicated by name — SANY's getConstantDecls/getVariableDecls
  ::  return own decls first, then re-exported ones
  |=  [tree=node mods=(map @t loaded:modules)]
  ^-  [consts=(list [name=@t arity=@ud at=sspan]) vars=(list [name=@t at=sspan])]
  =/  od  (own-decls tree)
  =/  cacc  consts.od
  =/  vacc  vars.od
  =/  ex  (extends-of tree)
  |-  ^-  [consts=(list [name=@t arity=@ud at=sspan]) vars=(list [name=@t at=sspan])]
  ?~  ex  [cacc vacc]
  =/  mt  (~(get by mods) i.ex)
  ?~  mt  $(ex t.ex)
  =/  sub  (ext-decls tree.u.mt mods)
  =/  cacc2
    =/  el  consts.sub
    =/  a  cacc
    |-  ^-  (list [name=@t arity=@ud at=sspan])
    ?~  el  a
    ?:  (lien a |=([nm=@t *] =(nm name.i.el)))  $(el t.el)
    $(el t.el, a (snoc a i.el))
  =/  vacc2
    =/  el  vars.sub
    =/  a  vacc
    |-  ^-  (list [name=@t at=sspan])
    ?~  el  a
    ?:  (lien a |=([nm=@t *] =(nm name.i.el)))  $(el t.el)
    $(el t.el, a (snoc a i.el))
  $(ex t.ex, cacc cacc2, vacc vacc2)
::
++  gen-module
  ::  the root module's semantic graph, with duplicate-definition
  ::  recovery (keep the first, 4201 error + 4801 warning per repeat),
  ::  INSTANCE-imported definitions ($substin bodies generated from the
  ::  instanced module's own tree), and theorem/assumption bodies
  |=  [tree=node c=ctx ctxs=(map @t ctx) mods=(map @t loaded:modules)]
  ^-  sem-module
  =/  units  (body-of-module tree)
  =/  ed  (ext-decls tree mods)
  =/  consts  consts.ed
  =/  vars  vars.ed
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
    ::  recursive-section state: a RECURSIVE unit creates placeholder
    ::  definitions at its own position (SANY creates the OpDefNode at
    ::  the declaration; the later definition fills it in place) and
    ::  opens a section that closes when every declared operator has
    ::  been defined
    =|  secs=(list [names=(list @t) recs=(list @t)])
    =/  secopen  |
    =|  snames=(list @t)
    =|  srecs=(list @t)
    =|  pending=(set @t)
    =/  us  units
    |-  ^-  $:  defs=(list sem-def)  thmdefs=(list sem-thm)
                assumes=(list sem-thm)  theorems=(list sem-thm)
                insts=(list sem-inst)  ds=(list sdiag)
                secs=(list [names=(list @t) recs=(list @t)])
            ==
    ?~  us
      :*  (flop defs)  (flop thmdefs)  (flop assumes)  (flop theorems)
          (flop insts)  ds
          %-  flop
          ?.  secopen  secs
          [[(flop snames) (flop srecs)] secs]
      ==
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
    ::  RECURSIVE F(_) creates placeholder definitions here and opens
    ::  (or extends) a recursive section
    =/  rsyms  (recursive-syms u)
    ?:  ?=(^ rsyms)
      =/  ph
        %+  turn  `(list [@t sym])`rsyms
        |=  [nm=@t s=sym]
        ^-  sem-def
        [%sdef nm arity.s | 0 (span-of:ast u) ~ ~ '']
      %=  $
        us       t.us
        secopen  &
        defs     (weld (flop ph) defs)
        snames   (weld (flop (turn `(list [@t sym])`rsyms |=([nm=@t *] nm))) snames)
        srecs    (weld (flop (turn `(list [@t sym])`rsyms |=([nm=@t *] nm))) srecs)
        pending  %+  roll  `(list [@t sym])`rsyms
                 |=([[nm=@t *] acc=_pending] (~(put in acc) nm))
      ==
    ::  INSTANCE units import the instanced module's definitions
    =/  iu  (unit-instance u)
    ?:  ?=(^ iu)
      =/  gi  (g-instance u u.iu c ctxs mods)
      %=  $
        us       t.us
        defs     (weld (flop defs.gi) defs)
        thmdefs  (weld (flop thms.gi) thmdefs)
        insts    [inst.gi insts]
        ds       (weld ds ds.gi)
      ==
    ?.  ?|  (is-kind u %n-operatordefinition)
            (is-kind u %n-functiondefinition)
        ==
      $(us t.us)
    =/  dsg  (def-signature u)
    ?~  dsg  $(us t.us)
    ?:  (~(has in pending) name.u.dsg)
      ::  fill the RECURSIVE placeholder in place
      =/  gd  (g-def u c)
      =/  p2  (~(del in pending) name.u.dsg)
      =/  closed  &(secopen =(~ p2))
      %=  $
        us       t.us
        seen     (~(put in seen) name.u.dsg)
        pending  p2
        ds       (weld ds ds.gd)
        secopen  ?:(closed | secopen)
        snames   ?:(closed ~ snames)
        srecs    ?:(closed ~ srecs)
        secs     ?.(closed secs [[(flop snames) (flop srecs)] secs])
        defs     ?~  r.gd  defs
                 =/  dl  defs
                 |-  ^-  (list sem-def)
                 ?~  dl  ~
                 ?:  =(name.i.dl name.u.dsg)  [u.r.gd t.dl]
                 [i.dl $(dl t.dl)]
      ==
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
      us      t.us
      seen    (~(put in seen) name.u.dsg)
      defs    ?~(r.gd defs [u.r.gd defs])
      ds      (weld ds ds.gd)
      snames  ?.(&(secopen ?=(^ r.gd)) snames [name.u.dsg snames])
    ==
  =/  wk  walk
  :*  (module-name tree)
      (span-of:ast tree)
      consts
      vars
      defs.wk
      thmdefs.wk
      assumes.wk
      theorems.wk
      insts.wk
      ds.wk
      secs.wk
      |
      ~
  ==
::
::  +|  Level Checking (unit 4: LevelNode/OpDefNode/OpApplNode.levelCheck)
::
::  A post-generation pass over the typed IR. Parameters are identified
::  by lkey (owner + name + kind): module declarations own '', formal
::  parameters their definition, bound identifiers 'b', NEW symbols 'n'.
::  Level constraints min-merge (SetOfLevelConstraints), arg-level
::  constraints max-merge (SetOfArgLevelConstraints). Diagnostics carry
::  SANY's full message and deduplicate on [code location message]
::  (Errors.addMessage is idempotent). Not ported (documented in
::  compatibility.md): the 4244 non-Leibniz diagnostic and the
::  4246/4247 operator-argument instance checks.
::
+$  lkey  [own=@t name=@t kind=symkind]
+$  lres
  $:  lvl=@ud
      ok=?
      lp=(set lkey)
      lc=(map lkey @ud)
      ac=(map [k=lkey i=@ud] @ud)
      ap=(set [op=lkey i=@ud par=lkey])
      all=(set lkey)
      nlp=(set lkey)
  ==
+$  oplev
  $:  lvl=@ud
      ok=?
      ary=@ud
      vdc=?
      maxl=(list @ud)
      wgts=(list @ud)
      mnmx=(list (list @ud))
      cond=(list (list (list ?)))
      pars=(list lkey)
      lp=(set lkey)
      lc=(map lkey @ud)
      ac=(map [k=lkey i=@ud] @ud)
      ap=(set [op=lkey i=@ud par=lkey])
      all=(set lkey)
      nlp=(set lkey)
      lbz=(list ?)
  ==
+$  lenv
  $:  ops=(map @t oplev)
      scope=(map @t lkey)
      pfx=@t
      c=ctx
      mlevs=(map @t mlev)
  ==
::  the instanced-module data INSTANCE checking needs (constancy plus
::  the module node's constraint collections)
+$  mlev
  $:  const=?
      lc=(map lkey @ud)
      alc=(map [k=lkey i=@ud] @ud)
      alp=(set [op=lkey i=@ud par=lkey])
  ==
::  dependency level data seeded into a module's check: definition
::  oplevs by exported name (dependency-first, user shadows std) and
::  per-module [constancy module-constraints]
+$  denv  [ops=(map @t oplev) mlevs=(map @t mlev)]
::
++  lres-nil  `lres`[0 & ~ ~ ~ ~ ~ ~]
::
++  lc-put
  ::  a level constraint: parameter must have level <= v (min-merge)
  |=  [m=(map lkey @ud) k=lkey v=@ud]
  ^-  (map lkey @ud)
  (~(put by m) k (min v (~(gut by m) k 3)))
::
++  lc-uni
  |=  [a=(map lkey @ud) b=(map lkey @ud)]
  ^-  (map lkey @ud)
  =/  bl  ~(tap by b)
  |-  ^-  (map lkey @ud)
  ?~  bl  a
  $(bl t.bl, a (lc-put a i.bl))
::
++  ac-put
  ::  an arg-level constraint: (param, position) needs level >= v
  |=  [m=(map [k=lkey i=@ud] @ud) k=[k=lkey i=@ud] v=@ud]
  ^-  (map [k=lkey i=@ud] @ud)
  (~(put by m) k (max v (~(gut by m) k 0)))
::
++  ac-uni
  |=  [a=(map [k=lkey i=@ud] @ud) b=(map [k=lkey i=@ud] @ud)]
  ^-  (map [k=lkey i=@ud] @ud)
  =/  bl  ~(tap by b)
  |-  ^-  (map [k=lkey i=@ud] @ud)
  ?~  bl  a
  $(bl t.bl, a (ac-put a i.bl))
::
++  at-or
  |=  [l=(list @ud) i=@ud d=@ud]
  ^-  @ud
  ?:((gte i (lent l)) d (snag i l))
::
++  at-or-loobean
  |=  [l=(list ?) i=@ud d=?]
  ^-  ?
  ?:((gte i (lent l)) d (snag i l))
::
++  mxl-of
  ::  the operator's maximum level for argument i (variadic index at 0)
  |=  [ol=oplev i=@ud]
  ^-  @ud
  (at-or maxl.ol ?:(vdc.ol 0 i) 3)
::
++  wgt-of
  |=  [ol=oplev i=@ud]
  ^-  @ud
  (at-or wgts.ol ?:(vdc.ol 0 i) 1)
::
++  lbz-of
  ::  whether the operator is Leibniz in argument i (builtins:
  ::  ArgWeights[i] > 0; user definitions: parameter i absent from the
  ::  body's non-Leibniz params); variadic index at 0, default Leibniz
  |=  [ol=oplev i=@ud]
  ^-  ?
  =/  i2  ?:(vdc.ol 0 i)
  ?:  (gte i2 (lent lbz.ol))  &
  (snag i2 lbz.ol)
::
++  mnmx-of
  |=  [ol=oplev i=@ud j=@ud]
  ^-  @ud
  ?:  (gte i (lent mnmx.ol))  0
  (at-or (snag i mnmx.ol) j 0)
::
++  cond-of
  |=  [ol=oplev i=@ud j=@ud k=@ud]
  ^-  ?
  ?:  (gte i (lent cond.ol))  |
  =/  ci  (snag i cond.ol)
  ?:  (gte j (lent ci))  |
  =/  cj  (snag j ci)
  ?:  (gte k (lent cj))  |
  (snag k cj)
::
++  oplev-nil
  ::  least-restrictive operator data (imported operators resolved only
  ::  through the generation context: level and weights known, no
  ::  constraint data)
  |=  [lvl=@ud ary=@ud vdc=? wgts=(list @ud)]
  ^-  oplev
  [lvl & ary vdc ~ wgts ~ ~ ~ ~ ~ ~ ~ ~ ~ (turn wgts |=(w=@ud (gth w 0)))]
::
++  l-resolve
  ::  operator data for an applied definition or builtin, trying the
  ::  instance prefix first inside instanced bodies
  |=  [nm=@t kind=symkind e=lenv]
  ^-  oplev
  ?:  =(%builtin kind)
    =/  s  (~(get by builtins) nm)
    =/  ml  (~(get by builtin-maxl) nm)
    ?~  s  (oplev-nil 0 0 | ~)
    =/  base  (oplev-nil level.u.s arity.u.s variadic.u.s weights.u.s)
    base(maxl ?~(ml ~ u.ml))
  =/  pnm  ?:(=('' pfx.e) nm (rap 3 ~[pfx.e nm]))
  =/  o1  (~(get by ops.e) pnm)
  ?^  o1  u.o1
  =/  o2  (~(get by ops.e) nm)
  ?^  o2  u.o2
  =/  s1  (~(get by c.e) pnm)
  ?^  s1  (oplev-nil level.u.s1 arity.u.s1 variadic.u.s1 weights.u.s1)
  =/  s2  (~(get by c.e) nm)
  ?^  s2  (oplev-nil level.u.s2 arity.u.s2 variadic.u.s2 weights.u.s2)
  (oplev-nil 0 0 | ~)
::
++  kind-lvl
  ::  a declared symbol's own level (OpDeclNode constructor)
  |=  k=symkind
  ^-  @ud
  ?:(=(%variable k) 1 0)
::
++  scope-key
  |=  [nm=@t kind=symkind e=lenv]
  ^-  lkey
  (~(gut by scope.e) nm ['' nm kind])
::
++  bound-key
  ::  a bound identifier's key. SANY keys constraint sets by SymbolNode
  ::  identity, so two same-named binders carry distinct entries (both
  ::  render, e.g. lc={n<=2,n<=3}); the binder span stands in for the
  ::  node identity
  |=  b=sbind
  ^-  lkey
  =/  own=@t
    ?~  at.b  'b'
    (crip "b{(a-co line.from.u.at.b)}.{(a-co col.from.u.at.b)}")
  [own name.b %formal-param]
::
++  substin-mod
  ::  a $SubstIn reserved apply's op name carries the instanced module
  ::  ('$SubstIn:B'); ~ when the name is not a substitution wrapper
  |=  nm=@t
  ^-  (unit @t)
  =/  t  (trip nm)
  ?.  =("$SubstIn:" (scag 9 t))  ~
  `(crip (slag 9 t))
::
++  apsubstin-mod
  ::  the $APSubstIn (instanced theorem/assumption) variant
  |=  nm=@t
  ^-  (unit @t)
  =/  t  (trip nm)
  ?.  =("$APSubstIn:" (scag 11 t))  ~
  `(crip (slag 11 t))
::
++  anysubstin-mod
  |=  nm=@t
  ^-  (unit @t)
  =/  s  (substin-mod nm)
  ?^(s s (apsubstin-mod nm))
::
++  oparg-def
  ::  the referenced operator of a $OpArg node, when it is a definition
  ::  (AnyDefNode); ~ when it references a formal parameter
  |=  [s=sem e=lenv]
  ^-  (unit [nm=@t ol=oplev])
  ?.  ?=(%apply -.s)  ~
  ?.  =('$OpArg' name.op.s)  ~
  =/  nm  ?~(ubound.s '' name.i.ubound.s)
  ?:  ?=(?(%constant %variable %formal-param %new-constant) kind.op.s)  ~
  `[nm (l-resolve nm kind.op.s e)]
::
++  l-x
  ::  level-check one expression: recompute its level (rewriting lvl
  ::  fields), gather level data, emit diagnostics in SANY report order
  |=  [s=sem e=lenv]
  ^-  [s=sem r=lres ds=(list sdiag)]
  ?-    -.s
      %lit      [s lres-nil ~]
      %atref    [s [lvl.s & ~ ~ ~ ~ ~ ~] ~]
      %nullodn  [s lres-nil ~]
      %letin
    =/  lets-w
      =|  out=(list sem-def)
      =|  ds=(list sdiag)
      =/  eo  e
      =/  ok  &
      =/  ll  lets.s
      =/  lcs=(map lkey @ud)  ~
      =/  acs=(map [k=lkey i=@ud] @ud)  ~
      =/  aps=(set [op=lkey i=@ud par=lkey])  ~
      |-  ^-  $:  lout=(list sem-def)  le=lenv  lok=?
                  llc=(map lkey @ud)  lac=(map [k=lkey i=@ud] @ud)
                  lap=(set [op=lkey i=@ud par=lkey])  lds=(list sdiag)
              ==
      ?~  ll  [(flop out) eo ok lcs acs aps ds]
      =/  gd  (l-def i.ll eo ~)
      =/  aps2
        ::  a let's argLevelParams pass through unless the entry
        ::  mentions one of that let's own formal parameters
        =/  pl  ~(tap in ap.ol.gd)
        =/  acc  aps
        |-  ^-  (set [op=lkey i=@ud par=lkey])
        ?~  pl  acc
        =/  hit
          =/  ql  pars.ol.gd
          |-  ^-  ?
          ?~  ql  |
          ?:  |(=(op.i.pl i.ql) =(par.i.pl i.ql))  &
          $(ql t.ql)
        $(pl t.pl, acc ?:(hit acc (~(put in acc) i.pl)))
      %=  $
        ll   t.ll
        out  [df.gd out]
        eo   eo.gd
        ok   &(ok ok.ol.gd)
        lcs  (lc-uni lcs lc.ol.gd)
        acs  (ac-uni acs ac.ol.gd)
        aps  aps2
        ds   (weld ds ds.gd)
      ==
    =/  lw  lets-w
    ?~  body.s
      [s(lets lout.lw) [0 lok.lw ~ llc.lw lac.lw lap.lw ~ ~] lds.lw]
    =/  gb  (l-x u.body.s le.lw)
    :-  s(lets lout.lw, body `s.gb, lvl lvl.r.gb)
    :_  (weld lds.lw ds.gb)
    ::  LetInNode: level/all params from the body only, constraint sets
    ::  and arg-level params merged from body and lets; SANY's
    ::  LetInNode.levelCheck never fills nonLeibnizParams
    :*  lvl.r.gb
        &(lok.lw ok.r.gb)
        lp.r.gb
        (lc-uni llc.lw lc.r.gb)
        (ac-uni lac.lw ac.r.gb)
        (~(uni in lap.lw) ap.r.gb)
        all.r.gb
        ~
    ==
  ::
      %apply
    ?:  =('$OpArg' name.op.s)
      =/  nm  ?~(ubound.s '' name.i.ubound.s)
      ?:  =('LAMBDA' nm)
        ::  an anonymous LAMBDA op-arg: level-check its body under the
        ::  bound idents (l-def, the OpDefNode path) and copy the resulting
        ::  operator level data, exactly as OpArgNode.levelCheck copies its
        ::  referenced operator's (nonLeibnizParams never filled). (R1.3.1.2)
        =/  params=(list spar)
          ?~  bound.s  ~
          (turn vars.i.bound.s |=(b=sbind `spar`[name.b 0 & at.b]))
        =/  body  ?~(args.s ~ ?~(t.args.s ~ `i.t.args.s))
        =/  df=sem-def
          [%sdef 'LAMBDA' (lent params) | lvl.s at.s params body '']
        =/  ld  (l-def df e ~)
        =/  ol  ol.ld
        :*  s(lvl lvl.ol)
            [lvl.ol ok.ol lp.ol lc.ol ac.ol ap.ol all.ol ~]
            ds.ld
        ==
      ?:  ?=(?(%constant %variable %formal-param %new-constant) kind.op.s)
        =/  key  (scope-key nm kind.op.s e)
        =/  lvl  (kind-lvl kind.op.s)
        [s(lvl lvl) [lvl & (silt ~[key]) ~ ~ ~ (silt ~[key]) ~] ~]
      ::  OpArgNode.levelCheck copies the referenced operator's level
      ::  data but never fills nonLeibnizParams
      =/  ol  (l-resolve nm kind.op.s e)
      [s(lvl lvl.ol) [lvl.ol ok.ol lp.ol lc.ol ac.ol ap.ol all.ol ~] ~]
    ?:  =('$NewSymb' name.op.s)
      =/  gs  (l-args args.s e)
      =/  lvl  (max 0 lvl.rs.gs)
      =/  ds2
        ?.  =(3 lvl)  ds.gs
        %+  weld  ds.gs
        :_  ~
        %^  derr  4.356  at.s
        "Level error:\0aTemporal formula used as set."
      :+  s(lvl lvl, args out.gs)
        [lvl ok.rs.gs lp.rs.gs lc.rs.gs ac.rs.gs ap.rs.gs all.rs.gs nlp.rs.gs]
      ds2
    ?:  =('$AssumeProve' name.op.s)
      =/  walk
        =|  out=(list sem)
        =|  ds=(list sdiag)
        =/  r  lres-nil
        =/  e2  e
        =/  as  args.s
        |-  ^-  [(list sem) lres (list sdiag)]
        ?~  as  [(flop out) r ds]
        =/  g  (l-x i.as e2)
        =?  e2  ?&(?=(%apply -.s.g) =('$NewSymb' name.op.s.g))
          =/  nn  ?~(ubound.s.g '' name.i.ubound.s.g)
          e2(scope (~(put by scope.e2) nn ['n' nn %new-constant]))
        %=  $
          as   t.as
          out  [s.g out]
          ds   (weld ds ds.g)
          r    :*  (max lvl.r lvl.r.g)
                   &(ok.r ok.r.g)
                   (~(uni in lp.r) lp.r.g)
                   (lc-uni lc.r lc.r.g)
                   (ac-uni ac.r ac.r.g)
                   (~(uni in ap.r) ap.r.g)
                   (~(uni in all.r) all.r.g)
                   (~(uni in nlp.r) nlp.r.g)
               ==
        ==
      =/  [aout=(list sem) ar=lres ads=(list sdiag)]  walk
      [s(lvl lvl.ar, args aout) ar ads]
    ?:  ?=(^ (anysubstin-mod name.op.s))
      (l-substin s e)
    ?:  ?=(?(%constant %variable %formal-param %new-constant) kind.op.s)
      ::  application of a declared symbol or formal parameter
      =/  key  (scope-key name.op.s kind.op.s e)
      =/  ga  (l-args args.s e)
      =/  lvl  (max (kind-lvl kind.op.s) lvl.rs.ga)
      =/  r=lres
        :*  lvl
            ok.rs.ga
            (~(put in lp.rs.ga) key)
            lc.rs.ga
            =/  acc  ac.rs.ga
            =/  i  0
            =/  al  rl.ga
            |-  ^-  (map [k=lkey i=@ud] @ud)
            ?~  al  acc
            $(al t.al, i +(i), acc (ac-put acc [key i] lvl.i.al))
        ::
            =/  acc  ap.rs.ga
            =/  i  0
            =/  al  rl.ga
            |-  ^-  (set [op=lkey i=@ud par=lkey])
            ?~  al  acc
            =/  acc2
              =/  ps  ~(tap in lp.i.al)
              |-  ^-  (set [op=lkey i=@ud par=lkey])
              ?~  ps  acc
              $(ps t.ps, acc (~(put in acc) [key i i.ps]))
            $(al t.al, i +(i), acc acc2)
        ::
            (~(put in all.rs.ga) key)
            nlp.rs.ga
        ==
      [s(lvl lvl, args out.ga) r ~]
    (l-apply-def s e)
  ==
::
++  l-args
  ::  level-check an argument list in order; rs = combined lres
  ::  (max level, unions), rl = per-argument lres in order
  |=  [as=(list sem) e=lenv]
  ^-  [out=(list sem) rs=lres rl=(list lres) ds=(list sdiag)]
  =|  out=(list sem)
  =|  rl=(list lres)
  =|  ds=(list sdiag)
  =/  rs  lres-nil
  |-  ^-  [out=(list sem) rs=lres rl=(list lres) ds=(list sdiag)]
  ?~  as  [(flop out) rs (flop rl) ds]
  =/  g  (l-x i.as e)
  %=  $
    as   t.as
    out  [s.g out]
    rl   [r.g rl]
    ds   (weld ds ds.g)
    rs   :*  (max lvl.rs lvl.r.g)
             &(ok.rs ok.r.g)
             (~(uni in lp.rs) lp.r.g)
             (lc-uni lc.rs lc.r.g)
             (ac-uni ac.rs ac.r.g)
             (~(uni in ap.rs) ap.r.g)
             (~(uni in all.rs) all.r.g)
             (~(uni in nlp.rs) nlp.r.g)
         ==
  ==
::
++  l-substin
  ::  $SubstIn levelCheck: level = body's, raised by the substituting
  ::  expression's level for each parameter appearing in the body's
  ::  level params; sets mapped through the substitution (getSubLCSet
  ::  with the constant-module simplification; see compatibility.md)
  |=  [s=sem e=lenv]
  ^-  [s=sem r=lres ds=(list sdiag)]
  ?>  ?=(%apply -.s)
  =/  nsubs  (lent ubound.s)
  =/  nms  (turn ubound.s |=(b=sbind name.b))
  ::  Subst.getSubLCSet: when the instanced module is not constant, a
  ::  constraint keyed by one of its CONSTANT declarations tightens to
  ::  0 and one keyed by a VARIABLE declaration to 1 before mapping
  =/  bconst
    =/  mod  (fall (anysubstin-mod name.op.s) '')
    const:(~(gut by mlevs.e) mod `mlev`[& ~ ~ ~])
  =/  sub-lvl-of
    |=  [k=lkey v=@ud]
    ^-  @ud
    ?:  bconst  v
    ?:  =(%constant kind.k)  0
    ?:  =(%variable kind.k)  1
    v
  =/  gsub  (l-args (scag nsubs args.s) e)
  =/  bl  (slag nsubs args.s)
  ?~  bl
    [s rs.gsub ds.gsub]
  =/  gb  (l-x i.bl e)
  ::  which substituted parameter (by index) a body key matches
  =/  sub-idx
    |=  k=lkey
    ^-  (unit @ud)
    ?.  =('' own.k)  ~
    =/  i  0
    =/  nl  nms
    |-  ^-  (unit @ud)
    ?~  nl  ~
    ?:(=(name.k i.nl) `i $(nl t.nl, i +(i)))
  =/  sub-r
    |=  i=@ud
    ^-  lres
    ?:((gte i (lent rl.gsub)) lres-nil (snag i rl.gsub))
  =/  lvl
    =/  acc  lvl.r.gb
    =/  i  0
    =/  nl  nms
    |-  ^-  @ud
    ?~  nl  acc
    =/  hit
      ?|  (~(has in lp.r.gb) ['' i.nl %constant])
          (~(has in lp.r.gb) ['' i.nl %variable])
      ==
    $(nl t.nl, i +(i), acc ?:(hit (max acc lvl:(sub-r i)) acc))
  =/  lp2
    =/  acc  `(set lkey)`~
    =/  ps  ~(tap in lp.r.gb)
    |-  ^-  (set lkey)
    ?~  ps  acc
    =/  si  (sub-idx i.ps)
    %=  $
      ps   t.ps
      acc  ?~(si (~(put in acc) i.ps) (~(uni in acc) lp:(sub-r u.si)))
    ==
  =/  lc2
    =/  acc  `(map lkey @ud)`~
    =/  ps  ~(tap by lc.r.gb)
    |-  ^-  (map lkey @ud)
    ?~  ps  acc
    =/  plevel  (sub-lvl-of i.ps)
    =/  si  (sub-idx -.i.ps)
    ?~  si  $(ps t.ps, acc (lc-put acc -.i.ps plevel))
    =/  acc2
      =/  qs  ~(tap in lp:(sub-r u.si))
      |-  ^-  (map lkey @ud)
      ?~  qs  acc
      $(qs t.qs, acc (lc-put acc i.qs plevel))
    $(ps t.ps, acc acc2)
  =/  ac2
    =/  acc  `(map [k=lkey i=@ud] @ud)`~
    =/  ps  ~(tap by ac.r.gb)
    |-  ^-  (map [k=lkey i=@ud] @ud)
    ?~  ps  acc
    =/  kk  `[k=lkey i=@ud]`-.i.ps
    ?^  (sub-idx k.kk)  $(ps t.ps)
    $(ps t.ps, acc (ac-put acc i.ps))
  =/  ap2
    =/  acc  `(set [op=lkey i=@ud par=lkey])`~
    =/  ps  ~(tap in ap.r.gb)
    |-  ^-  (set [op=lkey i=@ud par=lkey])
    ?~  ps  acc
    ?:  ?|(?=(^ (sub-idx op.i.ps)) ?=(^ (sub-idx par.i.ps)))
      $(ps t.ps)
    $(ps t.ps, acc (~(put in acc) i.ps))
  ::  allParams/nonLeibnizParams: start from the body's sets; each
  ::  substituted parameter present in allParams is replaced by the
  ::  substituting expression's allParams (its nonLeibnizParams join
  ::  ours); a parameter that was itself non-Leibniz additionally puts
  ::  the expression's allParams into nonLeibnizParams
  =/  anl
    =/  all2  all.r.gb
    =/  nlp2  nlp.r.gb
    =/  i  0
    =/  nl  nms
    |-  ^-  [(set lkey) (set lkey)]
    ?~  nl  [all2 nlp2]
    =/  hits
      %+  skim  ~(tap in all2)
      |=(k=lkey &(=('' own.k) =(i.nl name.k)))
    ?~  hits  $(nl t.nl, i +(i))
    =/  sr  (sub-r i)
    =/  all3
      =/  acc  all2
      =/  hl  `(list lkey)`hits
      |-  ^-  (set lkey)
      ?~  hl  acc
      $(hl t.hl, acc (~(del in acc) i.hl))
    =/  all3  (~(uni in all3) all.sr)
    =/  nlp3  (~(uni in nlp2) nlp.sr)
    =/  nhits
      %+  skim  ~(tap in nlp3)
      |=(k=lkey &(=('' own.k) =(i.nl name.k)))
    =/  nlp3
      ?~  nhits  nlp3
      =/  acc  nlp3
      =/  hl  `(list lkey)`nhits
      |-  ^-  (set lkey)
      ?~  hl  (~(uni in acc) all.sr)
      $(hl t.hl, acc (~(del in acc) i.hl))
    $(nl t.nl, i +(i), all2 all3, nlp2 nlp3)
  :*  s(lvl lvl, args (weld out.gsub ~[s.gb]))
      [lvl &(ok.rs.gsub ok.r.gb) lp2 lc2 ac2 ap2 -.anl +.anl]
      (weld ds.gsub ds.gb)
  ==
::
++  lp-constrain
  ::  constrain every parameter in ps to level <= v
  |=  [m=(map lkey @ud) ps=(set lkey) v=@ud]
  ^-  (map lkey @ud)
  =/  pl  ~(tap in ps)
  |-  ^-  (map lkey @ud)
  ?~  pl  m
  $(pl t.pl, m (lc-put m i.pl v))
::
++  sem-at
  |=  [s=sem d=sspan]
  ^-  sspan
  ?-  -.s
    %apply    at.s
    %letin    at.s
    %lit      at.s
    %atref    at.s
    %nullodn  d
  ==
::
++  oparg-param
  ::  the scope key and arity when a node is a $OpArg referencing a
  ::  formal parameter
  |=  [s=sem e=lenv]
  ^-  (unit [key=lkey ary=@ud])
  ?.  ?=(%apply -.s)  ~
  ?.  =('$OpArg' name.op.s)  ~
  ?.  ?=(%formal-param kind.op.s)  ~
  =/  nm  ?~(ubound.s '' name.i.ubound.s)
  =/  ary=@ud
    ?~  args.s  0
    ?.  ?=(%lit -.i.args.s)  0
    (rash val.i.args.s dem)
  `[(scope-key nm %formal-param e) ary]
::
++  l-apply-def
  ::  OpApplNode.levelCheck for an applied definition or builtin:
  ::  bound-variable scoping, per-argument maximum-level checks (4205),
  ::  higher-order checks (4272/4273), range checks (4315), level and
  ::  level-data computation, then the node-specific temporal checks
  ::  (4310-4314). The node's levelCorrect flag is derived from whether
  ::  any check here emitted (Java also clears it on suppressed checks;
  ::  that distinction is unobservable in the dump)
  |=  [s=sem e=lenv]
  ^-  [s=sem r=lres ds=(list sdiag)]
  ?>  ?=(%apply -.s)
  =/  opn  name.op.s
  =/  ol  (l-resolve opn kind.op.s e)
  ::  bound identifiers scope over the arguments, not the ranges
  =/  bkeys=(list [nm=@t key=lkey])
    %+  weld
      ^-  (list [nm=@t key=lkey])
      (turn ubound.s |=(b=sbind [name.b (bound-key b)]))
    ^-  (list [nm=@t key=lkey])
    %-  zing
    %+  turn  bound.s
    |=  g=sem-bound
    ^-  (list [nm=@t key=lkey])
    (turn vars.g |=(b=sbind [name.b (bound-key b)]))
  =/  bset
    =/  acc  *(set lkey)
    =/  bl  bkeys
    |-  ^-  (set lkey)
    ?~  bl  acc
    $(bl t.bl, acc (~(put in acc) key.i.bl))
  =/  e2
    %_  e
        scope
      =/  acc  scope.e
      =/  bl  bkeys
      |-  ^-  (map @t lkey)
      ?~  bl  acc
      $(bl t.bl, acc (~(put by acc) nm.i.bl key.i.bl))
    ==
  ::  ranges first (checked outside the binding scope)
  =/  granges
    =|  gout=(list sem-bound)
    =|  grl=(list (unit lres))
    =|  gds=(list sdiag)
    =/  gl  bound.s
    |-  ^-  [gout=(list sem-bound) grl=(list (unit lres)) gds=(list sdiag)]
    ?~  gl  [(flop gout) (flop grl) gds]
    ?~  range.i.gl
      $(gl t.gl, gout [i.gl gout], grl [~ grl])
    =/  g  (l-x u.range.i.gl e)
    %=  $
      gl    t.gl
      gout  [i.gl(range `s.g) gout]
      grl   [`r.g grl]
      gds   (weld gds ds.g)
    ==
  =/  ga  (l-args args.s e2)
  =/  ds0  (weld gds.granges ds.ga)
  ::  per-argument checks in order: 4205 then, for operator arguments,
  ::  4272 and the opLevelCond co-argument 4273
  =/  dsarg
    =|  acc=(list sdiag)
    =/  i  0
    =/  al  rl.ga
    =/  ao  out.ga
    |-  ^-  (list sdiag)
    ?~  al  acc
    ?~  ao  acc
    =/  d1=(list sdiag)
      ?.  ?&((gth lvl.i.al (mxl-of ol i)) ok.ol ok.i.al)  ~
      :_  ~
      %^  derr  4.205  at.s
      %+  weld  "Level error in applying operator {(trip opn)}:\0a"
      "The level of argument {(a-co +(i))} exceeds the maximum level allowed by the operator."
    =/  od  (oparg-def i.ao e)
    =/  d2=(list sdiag)
      ?~  od  ~
      =/  jn  ary.ol.u.od
      =|  dj=(list sdiag)
      =/  j  0
      |-  ^-  (list sdiag)
      ?:  (gte j jn)  dj
      ?.  ?&  (lth (mxl-of ol.u.od j) (mnmx-of ol i j))
              ok.ol  ok.i.al
          ==
        $(j +(j))
      %=  $
        j   +(j)
        dj  %+  weld  dj
            :_  ~
            %^  derr  4.272  at.s
            ;:  weld
              "Level error in applying operator {(trip opn)}:\0a"
              "The permitted level of argument {(a-co +(j))}"
              " of the operator argument {(a-co +(i))}"
              " \0amust be at least {(a-co (mnmx-of ol i j))}."
            ==
      ==
    =/  d3=(list sdiag)
      ?~  od  ~
      =/  kn  ary.ol.u.od
      =|  dj=(list sdiag)
      =/  j  0
      =/  jl  rl.ga
      |-  ^-  (list sdiag)
      ?~  jl  dj
      =/  dk=(list sdiag)
        =|  ac2=(list sdiag)
        =/  k  0
        |-  ^-  (list sdiag)
        ?:  (gte k kn)  ac2
        ?.  ?&  (cond-of ol i j k)
                (gth lvl.i.jl (mxl-of ol.u.od k))
                ok.i.al  ok.i.jl
            ==
          $(k +(k))
        %=  $
          k    +(k)
          ac2  %+  weld  ac2
               :_  ~
               %^  derr  4.273  at.s
               %+  weld  "Level error in applying operator {(trip opn)}:\0a"
               "The level of argument {(a-co +(j))} exceeds the maximum level allowed by the operator."
        ==
      $(jl t.jl, j +(j), dj (weld dj dk))
    $(al t.al, ao t.ao, i +(i), acc :(weld acc d1 d2 d3))
  ::  range checks: no range may exceed action level
  =/  dsrng
    =|  acc=(list sdiag)
    =/  gl  gout.granges
    =/  rl  grl.granges
    |-  ^-  (list sdiag)
    ?~  gl  acc
    ?~  rl  acc
    =/  d1=(list sdiag)
      ?~  i.rl  ~
      ?.  ?&((gth lvl.u.i.rl 2) ok.u.i.rl)  ~
      =/  v1  ?~(vars.i.gl '' name.i.vars.i.gl)
      :_  ~
      %^  derr  4.315  at.s
      ;:  weld
        "Level error in applying operator {(trip opn)}:\0a"
        "The level of the range for the bounded variable {(trip v1)}"
        " \0aexceeds the maximum level allowed by the operator."
      ==
    $(gl t.gl, rl t.rl, acc (weld acc d1))
  ::  level: the operator's, raised by weight-1 arguments and ranges
  =/  lvl
    =/  acc
      =/  a2  lvl.ol
      =/  i  0
      =/  al  rl.ga
      |-  ^-  @ud
      ?~  al  a2
      %=  $
        al  t.al
        i   +(i)
        a2  ?:(=(1 (wgt-of ol i)) (max a2 lvl.i.al) a2)
      ==
    =/  gl  grl.granges
    |-  ^-  @ud
    ?~  gl  acc
    $(gl t.gl, acc ?~(i.gl acc (max acc lvl.u.i.gl)))
  ::  level params: operator's, weight-1 arguments', ranges', minus the
  ::  bound identifiers
  =/  lp
    =/  acc
      =/  a2  lp.ol
      =/  i  0
      =/  al  rl.ga
      |-  ^-  (set lkey)
      ?~  al  a2
      %=  $
        al  t.al
        i   +(i)
        a2  ?:(=(1 (wgt-of ol i)) (~(uni in a2) lp.i.al) a2)
      ==
    =/  acc
      =/  gl  grl.granges
      |-  ^-  (set lkey)
      ?~  gl  acc
      $(gl t.gl, acc ?~(i.gl acc (~(uni in acc) lp.u.i.gl)))
    (~(dif in acc) bset)
  ::  which operand position substitutes a formal parameter of the
  ::  applied operator (OpApplNode.getArg)
  =/  par-idx
    |=  k=lkey
    ^-  (unit @ud)
    =/  i  0
    =/  pl  pars.ol
    |-  ^-  (unit @ud)
    ?~  pl  ~
    ?:(=(k i.pl) `i $(pl t.pl, i +(i)))
  =/  arg-lres
    |=  i=@ud
    ^-  lres
    ?:((gte i (lent rl.ga)) lres-nil (snag i rl.ga))
  =/  arg-sem
    |=  i=@ud
    ^-  (unit sem)
    ?:((gte i (lent out.ga)) ~ `(snag i out.ga))
  ::  level constraints: operator's; arguments' (excluding constraints
  ::  on our bound identifiers); ranges'; each argument's level params
  ::  bounded by the operator's per-argument maximum; opLevelCond
  ::  co-argument constraints from operator arguments; the applied
  ::  operator's argLevelParams whose op position receives a
  ::  definition-valued operator argument bound that alp's param by the
  ::  definition's per-argument maximum
  =/  lc
    =/  acc
      =/  a2  lc.ol
      =/  al  rl.ga
      |-  ^-  (map lkey @ud)
      ?~  al  a2
      =/  a3
        =/  ps  ~(tap by lc.i.al)
        =/  a4  a2
        |-  ^-  (map lkey @ud)
        ?~  ps  a4
        ?:  (~(has in bset) -.i.ps)  $(ps t.ps)
        $(ps t.ps, a4 (lc-put a4 i.ps))
      $(al t.al, a2 a3)
    =/  acc
      =/  gl  grl.granges
      |-  ^-  (map lkey @ud)
      ?~  gl  acc
      $(gl t.gl, acc ?~(i.gl acc (lc-uni acc lc.u.i.gl)))
    =/  acc
      =/  i  0
      =/  al  rl.ga
      |-  ^-  (map lkey @ud)
      ?~  al  acc
      $(al t.al, i +(i), acc (lp-constrain acc lp.i.al (mxl-of ol i)))
    =/  i  0
    =/  ao  out.ga
    |-  ^-  (map lkey @ud)
    ?~  ao  acc
    =/  od  (oparg-def i.ao e)
    ?~  od  $(ao t.ao, i +(i))
    =/  acc2
      =/  kn  ary.ol.u.od
      =/  j  0
      =/  jl  rl.ga
      =/  a3  acc
      |-  ^-  (map lkey @ud)
      ?~  jl  a3
      =/  a4
        =/  k  0
        =/  a5  a3
        |-  ^-  (map lkey @ud)
        ?:  (gte k kn)  a5
        ?.  (cond-of ol i j k)  $(k +(k))
        $(k +(k), a5 (lp-constrain a5 lp.i.jl (mxl-of ol.u.od k)))
      $(jl t.jl, j +(j), a3 a4)
    $(ao t.ao, i +(i), acc acc2)
  =/  lc
    =/  aps  ~(tap in ap.ol)
    =/  a2  lc
    |-  ^-  (map lkey @ud)
    ?~  aps  a2
    =/  si  (par-idx op.i.aps)
    ?~  si  $(aps t.aps)
    =/  as  (arg-sem u.si)
    ?~  as  $(aps t.aps)
    =/  od  (oparg-def u.as e)
    ?~  od  $(aps t.aps)
    $(aps t.aps, a2 (lc-put a2 par.i.aps (mxl-of ol.u.od i.i.aps)))
  ::  arg-level constraints: operator's, arguments', ranges'; a
  ::  formal-parameter operator argument picks up minMaxLevel and
  ::  opLevelCond constraints from this application; each alp of the
  ::  applied operator whose op position is a formal parameter is
  ::  constrained from below by the actual operand's level
  =/  ac
    =/  acc
      =/  a2  ac.ol
      =/  al  rl.ga
      |-  ^-  (map [k=lkey i=@ud] @ud)
      ?~  al  a2
      $(al t.al, a2 (ac-uni a2 ac.i.al))
    =/  acc
      =/  gl  grl.granges
      |-  ^-  (map [k=lkey i=@ud] @ud)
      ?~  gl  acc
      $(gl t.gl, acc ?~(i.gl acc (ac-uni acc ac.u.i.gl)))
    =/  i  0
    =/  ao  out.ga
    |-  ^-  (map [k=lkey i=@ud] @ud)
    ?~  ao  acc
    =/  pk  (oparg-param i.ao e)
    ?~  pk  $(ao t.ao, i +(i))
    =/  acc2
      =/  j  0
      =/  a3  acc
      |-  ^-  (map [k=lkey i=@ud] @ud)
      ?:  (gte j ary.u.pk)  a3
      $(j +(j), a3 (ac-put a3 [key.u.pk j] (mnmx-of ol i j)))
    =/  acc3
      =/  j  0
      =/  jl  rl.ga
      =/  a3  acc2
      |-  ^-  (map [k=lkey i=@ud] @ud)
      ?~  jl  a3
      =/  a4
        =/  k  0
        =/  a5  a3
        |-  ^-  (map [k=lkey i=@ud] @ud)
        ?:  (gte k ary.u.pk)  a5
        ?.  (cond-of ol i j k)  $(k +(k))
        $(k +(k), a5 (ac-put a5 [key.u.pk k] lvl.i.jl))
      $(jl t.jl, j +(j), a3 a4)
    $(ao t.ao, i +(i), acc acc3)
  =/  ac
    =/  aps  ~(tap in ap.ol)
    =/  a2  ac
    |-  ^-  (map [k=lkey i=@ud] @ud)
    ?~  aps  a2
    =/  si  (par-idx op.i.aps)
    ?~  si  $(aps t.aps)
    $(aps t.aps, a2 (ac-put a2 [op.i.aps i.i.aps] lvl:(arg-lres u.si)))
  ::  arg-level params: the applied operator's entries with both sides
  ::  remapped through the actual operands (op position substituted by
  ::  a formal-parameter operator argument; param position replaced by
  ::  the operand's level params; only entries touching no formal pass
  ::  verbatim); arguments' (entries whose param is one of our bound
  ::  identifiers dropped); ranges'; level-param appearances in
  ::  co-arguments of formal-parameter operator arguments
  =/  ap
    =/  acc
      =/  aps  ~(tap in ap.ol)
      =/  a2  *(set [op=lkey i=@ud par=lkey])
      |-  ^-  (set [op=lkey i=@ud par=lkey])
      ?~  aps  a2
      =/  si  (par-idx op.i.aps)
      ?^  si
        =/  as  (arg-sem u.si)
        ?~  as  $(aps t.aps)
        =/  pk  (oparg-param u.as e)
        ?~  pk  $(aps t.aps)
        $(aps t.aps, a2 (~(put in a2) [key.u.pk i.i.aps par.i.aps]))
      =/  sj  (par-idx par.i.aps)
      ?~  sj  $(aps t.aps, a2 (~(put in a2) i.aps))
      =/  a3
        =/  qs  ~(tap in lp:(arg-lres u.sj))
        =/  a4  a2
        |-  ^-  (set [op=lkey i=@ud par=lkey])
        ?~  qs  a4
        $(qs t.qs, a4 (~(put in a4) [op.i.aps i.i.aps i.qs]))
      $(aps t.aps, a2 a3)
    =/  acc
      =/  al  rl.ga
      |-  ^-  (set [op=lkey i=@ud par=lkey])
      ?~  al  acc
      =/  a3
        =/  ps  ~(tap in ap.i.al)
        =/  a4  acc
        |-  ^-  (set [op=lkey i=@ud par=lkey])
        ?~  ps  a4
        ?:  (~(has in bset) par.i.ps)  $(ps t.ps)
        $(ps t.ps, a4 (~(put in a4) i.ps))
      $(al t.al, acc a3)
    =/  acc
      =/  gl  grl.granges
      |-  ^-  (set [op=lkey i=@ud par=lkey])
      ?~  gl  acc
      $(gl t.gl, acc ?~(i.gl acc (~(uni in acc) ap.u.i.gl)))
    =/  i  0
    =/  ao  out.ga
    |-  ^-  (set [op=lkey i=@ud par=lkey])
    ?~  ao  acc
    =/  pk  (oparg-param i.ao e)
    ?~  pk  $(ao t.ao, i +(i))
    =/  acc2
      =/  j  0
      =/  jl  rl.ga
      =/  a3  acc
      |-  ^-  (set [op=lkey i=@ud par=lkey])
      ?~  jl  a3
      =/  a4
        =/  k  0
        =/  a5  a3
        |-  ^-  (set [op=lkey i=@ud par=lkey])
        ?:  (gte k ary.u.pk)  a5
        ?.  (cond-of ol i j k)  $(k +(k))
        =/  a6
          =/  ps  ~(tap in lp.i.jl)
          =/  a7  a5
          |-  ^-  (set [op=lkey i=@ud par=lkey])
          ?~  ps  a7
          $(ps t.ps, a7 (~(put in a7) [key.u.pk k i.ps]))
        $(k +(k), a5 a6)
      $(jl t.jl, j +(j), a3 a4)
    $(ao t.ao, i +(i), acc acc2)
  ::  all params: operator's, every argument's and range's, minus the
  ::  bound identifiers (weights are ignored here, unlike levelParams)
  =/  alx
    =/  acc
      =/  a2  all.ol
      =/  al  rl.ga
      |-  ^-  (set lkey)
      ?~  al  a2
      $(al t.al, a2 (~(uni in a2) all.i.al))
    =/  acc
      =/  gl  grl.granges
      |-  ^-  (set lkey)
      ?~  gl  acc
      $(gl t.gl, acc ?~(i.gl acc (~(uni in acc) all.u.i.gl)))
    (~(dif in acc) bset)
  ::  non-Leibniz params: operator's and components', plus every
  ::  parameter of an argument in a non-Leibniz position, minus the
  ::  bound identifiers; then (unfiltered, per Java's ordering) the
  ::  doubly-higher-order rule: a non-Leibniz definition passed as an
  ::  operator argument makes the co-argument's params non-Leibniz
  ::  wherever the opLevelCond matrix relates them
  ::  (OpApplNode.levelCheck lines 758-773)
  =/  nlx
    =/  acc
      =/  a2  nlp.ol
      =/  i  0
      =/  al  rl.ga
      |-  ^-  (set lkey)
      ?~  al  a2
      =/  a3  (~(uni in a2) nlp.i.al)
      =/  a3  ?:((lbz-of ol i) a3 (~(uni in a3) all.i.al))
      $(al t.al, i +(i), a2 a3)
    =/  acc
      =/  gl  grl.granges
      |-  ^-  (set lkey)
      ?~  gl  acc
      $(gl t.gl, acc ?~(i.gl acc (~(uni in acc) nlp.u.i.gl)))
    =/  acc  (~(dif in acc) bset)
    =/  i  0
    =/  ao  out.ga
    |-  ^-  (set lkey)
    ?~  ao  acc
    =/  od  (oparg-def i.ao e)
    ?~  od  $(ao t.ao, i +(i))
    =/  kn  ary.ol.u.od
    =/  a3
      =/  j  0
      =/  jl  rl.ga
      =/  a4  acc
      |-  ^-  (set lkey)
      ?~  jl  a4
      =/  a5
        =/  k  0
        =/  a6  a4
        |-  ^-  (set lkey)
        ?:  (gte k kn)  a6
        ?.  ?&((cond-of ol i j k) !(lbz-of ol.u.od k))  $(k +(k))
        $(k +(k), a6 (~(uni in a6) all.i.jl))
      $(jl t.jl, j +(j), a4 a5)
    $(ao t.ao, i +(i), acc a3)
  ::  node-specific temporal-operator checks
  =/  arg-lvl
    |=  i=@ud
    ^-  @ud
    ?:((gte i (lent rl.ga)) 0 lvl:(snag i rl.ga))
  =/  arg-is-not
    ::  argument i is an apply of an operator other than nm
    |=  [i=@ud nm=@t]
    ^-  ?
    ?:  (gte i (lent out.ga))  |
    =/  a  (snag i out.ga)
    ?.  ?=(%apply -.a)  |
    !=(nm name.op.a)
  =/  dstmp
    ^-  (list sdiag)
    ?:  ?&(=('[]' opn) =(2 (arg-lvl 0)) (arg-is-not 0 '$SquareAct'))
      [(derr 4.310 at.s "[] followed by action not of form [A]_v.") ~]
    ?:  ?&(=('<>' opn) =(2 (arg-lvl 0)) (arg-is-not 0 '$AngleAct'))
      [(derr 4.311 at.s "<> followed by action not of form <<A>>_v.") ~]
    ?:  ?&  |(=('~>' opn) =('-+->' opn))
            |(=(2 (arg-lvl 0)) =(2 (arg-lvl 1)))
        ==
      :_  ~
      %^  derr  4.312  at.s
      "Action used where only temporal formula or state predicate allowed."
    ?:  ?&  ?|  =('\\land' opn)  =('\\lor' opn)  =('=>' opn)
                =('\\equiv' opn)  =('$ConjList' opn)  =('$DisjList' opn)
            ==
            (lien rl.ga |=(r=lres =(3 lvl.r)))
            (lien rl.ga |=(r=lres =(2 lvl.r)))
        ==
      =/  pop
        ?:  =('$ConjList' opn)  "Conjunction list"
        ?:  =('$DisjList' opn)  "Disjunction list"
        (trip opn)
      :_  ~
      %^  derr  4.313  at.s
      "{pop} has both temporal formula and action as arguments."
    ~
  =/  dsquant
    ^-  (list sdiag)
    ?.  ?&  =(3 lvl)
            |(=('$BoundedExists' opn) =('$BoundedForall' opn))
        ==
      ~
    =|  acc=(list sdiag)
    =/  gl  gout.granges
    =/  rl  grl.granges
    |-  ^-  (list sdiag)
    ?~  gl  acc
    ?~  rl  acc
    =/  d1=(list sdiag)
      ?~  i.rl  ~
      ?.  =(2 lvl.u.i.rl)  ~
      =/  rat=sspan
        ?~(range.i.gl at.s (sem-at u.range.i.gl at.s))
      [(derr 4.314 rat "Action-level bound of quantified temporal formula.") ~]
    $(gl t.gl, rl t.rl, acc (weld acc d1))
  ::  a bound identifier is level-checked (level 0) only when some
  ::  argument references it; an unreferenced one keeps SANY's
  ::  uninitialized -1 sentinel. References live in the arguments'
  ::  allParams (ranges are outside the binding scope), with inner
  ::  shadowing already excluded because inner nodes removed their own
  ::  bound keys
  =/  argall
    =/  acc  *(set lkey)
    =/  al  rl.ga
    |-  ^-  (set lkey)
    ?~  al  acc
    $(al t.al, acc (~(uni in acc) all.i.al))
  =/  ubound2
    %+  turn  ubound.s
    |=(b=sbind b(used (~(has in argall) (bound-key b))))
  =/  bound2
    %+  turn  gout.granges
    |=  g=sem-bound
    %_  g
        vars
      %+  turn  vars.g
      |=(b=sbind b(used (~(has in argall) (bound-key b))))
    ==
  =/  dsall  :(weld ds0 dsarg dsrng dstmp dsquant)
  =/  rngok
    =/  gl  grl.granges
    |-  ^-  ?
    ?~  gl  &
    ?.  ?~(i.gl & ok.u.i.gl)  |
    $(gl t.gl)
  =/  nodeok
    ?&  ok.ol  ok.rs.ga  rngok
        =(~ dsarg)  =(~ dsrng)  =(~ dstmp)  =(~ dsquant)
    ==
  :*  s(lvl lvl, ubound ubound2, bound bound2, args out.ga)
      [lvl nodeok lp lc ac ap alx nlx]
      dsall
  ==
::
++  def-pfx
  ::  the instance prefix of an instanced definition name (I!D -> 'I!');
  ::  inherits the enclosing prefix when the name has none
  |=  [nm=@t d=@t]
  ^-  @t
  =/  raw  (trip nm)
  =/  idx
    =/  fl  (flop raw)
    =/  i  0
    |-  ^-  (unit @ud)
    ?~  fl  ~
    ?:(=('!' i.fl) `i $(fl t.fl, i +(i)))
  ?~  idx  d
  (crip (scag (sub (lent raw) u.idx) raw))
::
++  oplev-fresh
  ::  a definition's initial level data (least restrictive)
  |=  [own=@t df=sem-def]
  ^-  oplev
  :*  0  &  arity.df  |
      (reap arity.df 3)
      (reap arity.df 0)
      (turn params.df |=(p=spar (reap arity.p 0)))
      %+  turn  params.df
      |=  p=spar
      %+  turn  params.df
      |=(q=spar (reap arity.p |))
      (turn params.df |=(p=spar `lkey`[own name.p %formal-param]))
      ~  ~  ~  ~  ~  ~
      (reap arity.df &)
  ==
::
++  rec-seed
  ::  a RECURSIVE operator's seeded level data (ModuleNode: maxLevels
  ::  ActionLevel, weights 1)
  |=  [own=@t df=sem-def]
  ^-  oplev
  =/  base  (oplev-fresh own df)
  base(maxl (reap arity.df 2), wgts (reap arity.df 1))
::
++  l-def
  ::  OpDefNode.levelCheck: check the body with the formal parameters
  ::  in scope, then derive the operator's level data. Monotonic across
  ::  recursive-section iterations: level and weights never shrink,
  ::  maxLevels never grows
  |=  [df=sem-def e=lenv prev=(unit oplev)]
  ^-  [df=sem-def ol=oplev eo=lenv ds=(list sdiag)]
  =/  own  name.df
  =/  ol0  ?^(prev u.prev (oplev-fresh own df))
  ?~  body.df
    [df ol0 e(ops (~(put by ops.e) own ol0)) ~]
  =/  pkeys  (turn params.df |=(p=spar `lkey`[own name.p %formal-param]))
  =/  pset
    =/  acc  *(set lkey)
    =/  pl  pkeys
    |-  ^-  (set lkey)
    ?~  pl  acc
    $(pl t.pl, acc (~(put in acc) i.pl))
  =/  e2
    %_  e
        pfx  (def-pfx own pfx.e)
        scope
      =/  acc  scope.e
      =/  pl  params.df
      |-  ^-  (map @t lkey)
      ?~  pl  acc
      $(pl t.pl, acc (~(put by acc) name.i.pl [own name.i.pl %formal-param]))
    ==
  =/  gb  (l-x u.body.df e2)
  =/  lvl  (max lvl.ol0 lvl.r.gb)
  =/  maxl
    =/  i  0
    |-  ^-  (list @ud)
    ?:  (gte i arity.df)  ~
    :_  $(i +(i))
    %+  min  (at-or maxl.ol0 i 3)
    ?:  (gte i (lent pkeys))  3
    (~(gut by lc.r.gb) (snag i pkeys) 3)
  =/  wgts
    =/  i  0
    |-  ^-  (list @ud)
    ?:  (gte i arity.df)  ~
    :_  $(i +(i))
    %+  max  (at-or wgts.ol0 i 0)
    ?:  (gte i (lent pkeys))  0
    ?:((~(has in lp.r.gb) (snag i pkeys)) 1 0)
  =/  mnmx
    =/  i  0
    =/  pl  params.df
    |-  ^-  (list (list @ud))
    ?~  pl  ~
    :_  $(pl t.pl, i +(i))
    =/  ki  `lkey`[own name.i.pl %formal-param]
    =/  j  0
    |-  ^-  (list @ud)
    ?:  (gte j arity.i.pl)  ~
    [(~(gut by ac.r.gb) [ki j] 0) $(j +(j))]
  =/  cond
    =/  pl  params.df
    |-  ^-  (list (list (list ?)))
    ?~  pl  ~
    :_  $(pl t.pl)
    =/  ki  `lkey`[own name.i.pl %formal-param]
    =/  kn  arity.i.pl
    =/  ql  params.df
    |-  ^-  (list (list ?))
    ?~  ql  ~
    :_  $(ql t.ql)
    =/  kj  `lkey`[own name.i.ql %formal-param]
    =/  k  0
    |-  ^-  (list ?)
    ?:  (gte k kn)  ~
    [(~(has in ap.r.gb) [ki k kj]) $(k +(k))]
  =/  lp2  (~(uni in lp.ol0) (~(dif in lp.r.gb) pset))
  =/  all2  (~(uni in all.ol0) (~(dif in all.r.gb) pset))
  ::  a parameter appearing in the body's non-Leibniz params makes the
  ::  definition non-Leibniz in that argument (monotonic across
  ::  recursive-section iterations, like SANY's isLeibnizArg)
  =/  nlp2  (~(dif in nlp.r.gb) pset)
  =/  lbz2
    =/  i  0
    |-  ^-  (list ?)
    ?:  (gte i arity.df)  ~
    :_  $(i +(i))
    ?&  (at-or-loobean lbz.ol0 i &)
        ?:  (gte i (lent pkeys))  &
        !(~(has in nlp.r.gb) (snag i pkeys))
    ==
  =/  lc2
    =/  acc  *(map lkey @ud)
    =/  ps  ~(tap by lc.r.gb)
    |-  ^-  (map lkey @ud)
    ?~  ps  acc
    ?:  (~(has in pset) -.i.ps)  $(ps t.ps)
    $(ps t.ps, acc (lc-put acc i.ps))
  =/  ac2
    =/  acc  *(map [k=lkey i=@ud] @ud)
    =/  ps  ~(tap by ac.r.gb)
    |-  ^-  (map [k=lkey i=@ud] @ud)
    ?~  ps  acc
    =/  kk  `[k=lkey i=@ud]`-.i.ps
    ?:  (~(has in pset) k.kk)  $(ps t.ps)
    $(ps t.ps, acc (ac-put acc i.ps))
  =/  ap2
    %-  ~(uni in ap.ol0)
    =/  acc  *(set [op=lkey i=@ud par=lkey])
    =/  ps  ~(tap in ap.r.gb)
    |-  ^-  (set [op=lkey i=@ud par=lkey])
    ?~  ps  acc
    ?:  ?&((~(has in pset) op.i.ps) (~(has in pset) par.i.ps))
      $(ps t.ps)
    $(ps t.ps, acc (~(put in acc) i.ps))
  =/  ol=oplev
    :*  lvl  ok.r.gb  arity.df  |  maxl  wgts  mnmx  cond  pkeys
        lp2  lc2  ac2  ap2  all2  nlp2  lbz2
    ==
  :*  df(lvl lvl, body `s.gb)
      ol
      e(ops (~(put by ops.e) own ol))
      ds.gb
  ==
::
++  l-thm
  ::  a theorem/assumption/thmdef body (ThmOrAssumpDefNode levelCheck)
  |=  [th=sem-thm e=lenv]
  ^-  [th=sem-thm r=lres ds=(list sdiag)]
  ?~  body.th  [th lres-nil ~]
  =/  gb  (l-x u.body.th e)
  [th(lvl lvl.r.gb, body `s.gb) r.gb ds.gb]
::
++  l-inst
  ::  InstanceNode.levelCheck: the instanced module's constancy and
  ::  module-node constraint collections come precomputed through mlevs
  ::  (+l-deps). Three passes over the substitutions in Java's order:
  ::  per substitution the constant-module 4245 then the non-Leibniz
  ::  4244; then per substitution the module-constraint 4245 and the
  ::  operator-argument 4246; then the co-parameter 4247 over the
  ::  module's argLevelParams. Also returns the instance node's own
  ::  level-constraint contribution (Subst.getSubLCSet applied to the
  ::  module constraints), consumed by the module line
  |=  [it=sem-inst e=lenv]
  ^-  [ds=(list sdiag) lc=(map lkey @ud)]
  =/  bml  (~(gut by mlevs.e) mod.it `mlev`[& ~ ~ ~])
  ::  level-check every substitution expression once
  =/  ents
    ^-  (list [param=@t pkind=symkind sx=(unit sem) rl=lres dsx=(list sdiag)])
    %+  turn  subs.it
    |=  is=sem-isub
    ?~  expr.is  [param.is pkind.is ~ lres-nil ~]
    =/  g  (l-x u.expr.is e)
    [param.is pkind.is `s.g r.g ds.g]
  =/  d1
    =|  ds=(list sdiag)
    =/  el  ents
    |-  ^-  (list sdiag)
    ?~  el  ds
    ?~  sx.i.el  $(el t.el)
    =/  plvl  (kind-lvl pkind.i.el)
    =/  da=(list sdiag)
      ?.  ?&(!const.bml (gth lvl.rl.i.el plvl))  ~
      :_  ~
      %^  derr  4.245  at.it
      ;:  weld
        "Level error in instantiating module '{(trip mod.it)}':\0a"
        "The level of the expression or operator substituted for "
        "'{(trip param.i.el)}' \0amust be at most {(a-co plvl)}."
      ==
    =/  db=(list sdiag)
      =/  od  (oparg-def u.sx.i.el e)
      ?~  od  ~
      ?:  (levy lbz.ol.u.od |=(f=? f))  ~
      :_  ~
      %^  derr  4.244  at.it
      ;:  weld
        "Error in instantiating module '{(trip mod.it)}':\0a"
        " A non-Leibniz operator substituted for "
        "'{(trip param.i.el)}'."
      ==
    $(el t.el, ds :(weld ds dsx.i.el da db))
  =/  d2
    =|  ds=(list sdiag)
    =/  el  ents
    |-  ^-  (list sdiag)
    ?~  el  ds
    ?~  sx.i.el  $(el t.el)
    =/  key  `lkey`['' param.i.el pkind.i.el]
    =/  plevel  (~(get by lc.bml) key)
    =/  da=(list sdiag)
      ?~  plevel  ~
      ?.  (gth lvl.rl.i.el u.plevel)  ~
      :_  ~
      %^  derr  4.245  at.it
      ;:  weld
        "Level error in instantiating module '{(trip mod.it)}':\0a"
        "The level of the expression or operator substituted for "
        "'{(trip param.i.el)}' \0amust be at most {(a-co u.plevel)}."
      ==
    =/  db=(list sdiag)
      =/  od  (oparg-def u.sx.i.el e)
      ?~  od  ~
      ::  the module's arg-level constraints on this parameter, in
      ::  ascending argument position (Java iterates j < arity and
      ::  skips absent entries)
      =/  pents
        ^-  (list [pos=@ud alev=@ud])
        %+  sort
          %+  murn  ~(tap by alc.bml)
          |=  [kk=[k=lkey i=@ud] v=@ud]
          ^-  (unit [pos=@ud alev=@ud])
          ?.(=(key k.kk) ~ `[i.kk v])
        |=([a=[pos=@ud alev=@ud] b=[pos=@ud alev=@ud]] (lth pos.a pos.b))
      =/  plstr  ?~(plevel "null" (a-co u.plevel))
      =|  dj=(list sdiag)
      |-  ^-  (list sdiag)
      ?~  pents  dj
      ?.  (lth (mxl-of ol.u.od pos.i.pents) alev.i.pents)
        $(pents t.pents)
      %=  $
        pents  t.pents
        dj  %+  weld  dj
            :_  ~
            %^  derr  4.246  at.it
            ;:  weld
              "Level error in instantiating module '{(trip mod.it)}':\0a"
              "The level of the argument {(a-co pos.i.pents)} of the "
              "operator {(trip nm.u.od)} \0amust be at least {plstr}."
            ==
      ==
    $(el t.el, ds :(weld ds da db))
  =/  d3
    =|  ds=(list sdiag)
    =/  al  ~(tap in alp.bml)
    |-  ^-  (list sdiag)
    ?~  al  ds
    =/  ei
      =/  el  ents
      |-  ^-  (unit [param=@t pkind=symkind sx=(unit sem) rl=lres dsx=(list sdiag)])
      ?~  el  ~
      ?:  =(op.i.al `lkey`['' param.i.el pkind.i.el])  `i.el
      $(el t.el)
    =/  ej
      =/  el  ents
      |-  ^-  (unit [param=@t pkind=symkind sx=(unit sem) rl=lres dsx=(list sdiag)])
      ?~  el  ~
      ?:  =(par.i.al `lkey`['' param.i.el pkind.i.el])  `i.el
      $(el t.el)
    ?~  ei  $(al t.al)
    ?~  ej  $(al t.al)
    ?~  sx.u.ei  $(al t.al)
    =/  od  (oparg-def u.sx.u.ei e)
    ?~  od  $(al t.al)
    =/  mx  (mxl-of ol.u.od i.i.al)
    ?.  (gth lvl.rl.u.ej mx)  $(al t.al)
    %=  $
      al  t.al
      ds  %+  weld  ds
          :_  ~
          %^  derr  4.247  at.it
          ;:  weld
            "Level error when instantiating module '{(trip mod.it)}':\0a"
            "The level of the argument {(a-co i.i.al)} of the "
            "operator {(trip param.u.ei)}' \0amust be at most {(a-co mx)}."
          ==
    ==
  ::  the instance node's levelConstraints: the module's, with the
  ::  getSubLCSet kind overrides, mapped through the substitutions
  =/  lcc
    =/  acc  *(map lkey @ud)
    =/  ps  ~(tap by lc.bml)
    |-  ^-  (map lkey @ud)
    ?~  ps  acc
    =/  kk  `lkey`-.i.ps
    =/  plevel
      ?:  const.bml  +.i.ps
      ?:  =(%constant kind.kk)  0
      ?:  =(%variable kind.kk)  1
      +.i.ps
    =/  hit
      =/  el  ents
      |-  ^-  (unit lres)
      ?~  el  ~
      ?:  =(kk `lkey`['' param.i.el pkind.i.el])  `rl.i.el
      $(el t.el)
    ?~  hit  $(ps t.ps, acc (lc-put acc kk plevel))
    =/  acc2
      =/  qs  ~(tap in lp.u.hit)
      |-  ^-  (map lkey @ud)
      ?~  qs  acc
      $(qs t.qs, acc (lc-put acc i.qs plevel))
    $(ps t.ps, acc acc2)
  ::  getSubLCSet's arg-level-param bounds: for a module argLevelParam
  ::  whose op is substituted by a definition, bound the mapped param
  ::  (paramSet of alp.param) by that definition's per-argument maximum
  =/  lcc
    =/  al  ~(tap in alp.bml)
    |-  ^-  (map lkey @ud)
    ?~  al  lcc
    =/  sxop
      =/  el  ents
      |-  ^-  (unit (unit sem))
      ?~  el  ~
      ?:  =(op.i.al `lkey`['' param.i.el pkind.i.el])  `sx.i.el
      $(el t.el)
    ?~  sxop  $(al t.al)
    ?~  u.sxop  $(al t.al)
    =/  od  (oparg-def u.u.sxop e)
    ?~  od  $(al t.al)
    =/  mlevel  (mxl-of ol.u.od i.i.al)
    ::  paramSet(alp.param): the substituting expression's level params,
    ::  or the param itself when it is not substituted
    =/  qs
      ^-  (list lkey)
      =/  rj
        =/  el  ents
        |-  ^-  (unit lres)
        ?~  el  ~
        ?:  =(par.i.al `lkey`['' param.i.el pkind.i.el])  `rl.i.el
        $(el t.el)
      ?~(rj [par.i.al ~] ~(tap in lp.u.rj))
    =/  lcc2
      |-  ^-  (map lkey @ud)
      ?~  qs  lcc
      $(qs t.qs, lcc (lc-put lcc i.qs mlevel))
    $(al t.al, lcc lcc2)
  ::  plus each substitution expression's own level constraints
  =/  lcc
    =/  el  ents
    |-  ^-  (map lkey @ud)
    ?~  el  lcc
    $(el t.el, lcc (lc-uni lcc lc.rl.i.el))
  [:(weld d1 d2 d3) lcc]
::
++  dedup-diags
  ::  Errors.addMessage is idempotent on [code location message]
  |=  ds=(list sdiag)
  ^-  (list sdiag)
  =|  seen=(set [@ud sspan @t])
  =|  out=(list sdiag)
  |-  ^-  (list sdiag)
  ?~  ds  (flop out)
  =/  k  [code.i.ds at.i.ds msg.i.ds]
  ?:  (~(has in seen) k)  $(ds t.ds)
  $(ds t.ds, seen (~(put in seen) k), out [i.ds out])
::
++  span-key
  ::  source-order sort key for top-level statements
  |=  sp=sspan
  ^-  [@ud @ud]
  ?~(sp [0 0] [line.from.u.sp col.from.u.sp])
::
++  extends-of
  ::  the EXTENDS names of a module tree, in appearance order
  |=  tree=node
  ^-  (list @t)
  ?.  ?=(%node -.tree)  ~
  ?:  =(%n-extends kind.tree)
    %+  murn  kids.tree
    |=  k=node
    ^-  (unit @t)
    ?.  ?=(%leaf -.k)  ~
    ?.  =(%identifier kind.token.k)  ~
    `text.token.k
  (zing (turn kids.tree |=(k=node ^$(tree k))))
::
::  +|  LEVELS projection (the SemDump per-definition constraint dump)
::
++  join-sep
  |=  [sep=tape l=(list tape)]
  ^-  tape
  ?~  l  ""
  =/  acc  i.l
  =/  t  t.l
  |-  ^-  tape
  ?~  t  acc
  $(t t.t, acc :(weld acc sep i.t))
::
++  lex-lte
  ::  Java Collections.sort(List<String>) order (byte-wise on ASCII)
  |=  [a=tape b=tape]
  ^-  ?
  ?~  a  &
  ?~  b  |
  ?:  =(i.a i.b)  $(a t.a, b t.b)
  (lth `@`i.a `@`i.b)
::
++  seg-set
  ::  " tag={e1,e2,..}" with entries sorted (duplicates kept, exactly
  ::  as the oracle's sorted string list), or "" when empty
  |=  [tag=tape es=(list tape)]
  ^-  tape
  ?~  es  ""
  ;:  weld
    " "  tag  "=\{"
    (join-sep "," (sort es lex-lte))
    "}"
  ==
::
++  rn-names
  |=  s=(set lkey)
  ^-  (list tape)
  (turn ~(tap in s) |=(k=lkey (trip name.k)))
::
++  rn-lc-entries
  |=  m=(map lkey @ud)
  ^-  (list tape)
  (turn ~(tap by m) |=([k=lkey v=@ud] "{(trip name.k)}<={(a-co v)}"))
::
++  rn-alc-entries
  |=  m=(map [k=lkey i=@ud] @ud)
  ^-  (list tape)
  %+  turn  ~(tap by m)
  |=  [kk=[k=lkey i=@ud] v=@ud]
  "({(trip name.k.kk)},{(a-co i.kk)})>={(a-co v)}"
::
++  rn-alp-entries
  |=  s=(set [op=lkey i=@ud par=lkey])
  ^-  (list tape)
  %+  turn  ~(tap in s)
  |=  e=[op=lkey i=@ud par=lkey]
  "({(trip name.op.e)},{(a-co i.e)},{(trip name.par.e)})"
::
++  lvl-segs
  ::  the optional collection segments in oracle order
  |=  $:  lp=(set lkey)
          lc=(map lkey @ud)
          ac=(map [k=lkey i=@ud] @ud)
          ap=(set [op=lkey i=@ud par=lkey])
          nlp=(set lkey)
      ==
  ^-  tape
  ;:  weld
    (seg-set "lp" (rn-names lp))
    (seg-set "lc" (rn-lc-entries lc))
    (seg-set "alc" (rn-alc-entries ac))
    (seg-set "alp" (rn-alp-entries ap))
    (seg-set "nlp" (rn-names nlp))
  ==
::
++  has-op-param
  |=  df=sem-def
  ^-  ?
  (lien params.df |=(p=spar (gth arity.p 0)))
::
++  lvl-line-def
  ::  one LEVELS line for a checked definition
  |=  [df=sem-def o=oplev]
  ^-  @t
  %-  crip
  ;:  weld
    "lvl {(trip name.df)} L{(a-co lvl.o)}"
    ?:  =(0 arity.df)  ""
    ;:  weld
      " ml=["  (join-sep "," (turn maxl.o a-co))
      "] w=["  (join-sep "," (turn wgts.o a-co))  "]"
    ==
    ?.  (has-op-param df)  ""
    ;:  weld
      " mml=["
      %+  join-sep  ";"
      (turn mnmx.o |=(l=(list @ud) (join-sep "," (turn l a-co))))
      "] olc=["
      %+  join-sep  ";"
      %+  turn  cond.o
      |=  ci=(list (list ?))
      ^-  tape
      %-  zing
      (turn ci |=(cj=(list ?) `tape`(turn cj |=(f=? `@tD`?:(f 'T' 'F')))))
      "]"
    ==
    (lvl-segs lp.o lc.o ac.o ap.o nlp.o)
  ==
::
++  lvl-line-masked
  ::  when level checking never ran (semantic errors) the oracle's
  ::  collection fields are empty and the per-argument getters throw
  |=  df=sem-def
  ^-  @t
  %-  crip
  ;:  weld
    "lvl {(trip name.df)} L-1"
    ?:(=(0 arity.df) "" " ml=? w=?")
    ?.((has-op-param df) "" " mml=? olc=?")
  ==
::
++  render-levels-masked
  |=  m=sem-module
  ^-  wain
  :-  (crip "lvl MODULE {(trip name.m)} L-1")
  %+  weld
    (turn defs.m lvl-line-masked)
  %+  turn  thmdefs.m
  |=(th=sem-thm (crip "lvl {(trip (fall name.th ''))} L-1"))
::
++  validate-target
  ::  the pure validation gate for TLC-configuration targets (consumed
  ::  by the configuration unit): resolve a definition or theorem
  ::  definition by name in a level-checked module and accept it iff
  ::  its level does not exceed the required maximum. Failure is a
  ::  structured diagnostic (code 0: internal, not a SANY code)
  |=  [m=sem-module nm=@t maxlvl=@ud]
  ^-  (each @ud sdiag)
  =/  hit=(unit [lvl=@ud at=sspan])
    =/  dl  defs.m
    |-  ^-  (unit [lvl=@ud at=sspan])
    ?~  dl
      =/  tl  thmdefs.m
      |-  ^-  (unit [lvl=@ud at=sspan])
      ?~  tl  ~
      ?:  ?&(?=(^ name.i.tl) =(nm u.name.i.tl))  `[lvl.i.tl at.i.tl]
      $(tl t.tl)
    ?:  =(nm name.i.dl)  `[lvl.i.dl at.i.dl]
    $(dl t.dl)
  ?~  hit
    [%| (derr 0 ~ "Unknown target: {(trip nm)}.")]
  ?.  lchecked.m
    [%| (derr 0 at.u.hit "Target {(trip nm)} is not level-checked.")]
  ?:  (gth lvl.u.hit maxlvl)
    :-  %|
    %^  derr  0  at.u.hit
    ;:  weld
      "Level error: {(trip nm)} has level {(a-co lvl.u.hit)}, "
      "the maximum allowed is {(a-co maxlvl)}."
    ==
  [%& lvl.u.hit]
::
++  level-module
  ::  the level-checking pass over a generated module (no-op, with
  ::  L-1 masking preserved, when generation reported errors)
  |=  $:  m=sem-module
          c=ctx
          ctxs=(map @t ctx)
          mods=(map @t loaded:modules)
          dv=denv
      ==
  ^-  sem-module
  m:(l-module-core m c ctxs mods dv)
::
++  l-deps
  ::  level-check every loaded module except the root, dependency
  ::  first, accumulating definition oplevs (later modules shadow, so
  ::  user redefinitions win over std) and per-module [constancy
  ::  module-constraints] for INSTANCE/substitution checking
  |=  $:  root=@t
          order=(list @t)
          ctxs=(map @t ctx)
          mods=(map @t loaded:modules)
      ==
  ^-  denv
  =/  acc=denv  [~ ~]
  |-  ^-  denv
  ?~  order  acc
  ?:  =(root i.order)  $(order t.order)
  =/  mt  (~(get by mods) i.order)
  ?~  mt  $(order t.order)
  =/  fc  (full-ctx tree.u.mt ctxs)
  =/  r  (l-module-core (gen-module tree.u.mt fc ctxs mods) fc ctxs mods acc)
  %=  $
    order  t.order
    acc    [ops.r (~(put by mlevs.acc) i.order ml.r)]
  ==
::
++  l-module-core
  ::  ModuleNode.levelCheck: recursive sections (two-iteration
  ::  fixpoint), remaining definitions, theorem definitions, then
  ::  top-level assumptions/theorems/instances in source order;
  ::  followed by the linter when nothing errored
  |=  $:  m=sem-module
          c=ctx
          ctxs=(map @t ctx)
          mods=(map @t loaded:modules)
          dv=denv
      ==
  ^-  $:  m=sem-module
          ml=mlev
          lvls=wain
          ops=(map @t oplev)
          phase=[sem=(list sdiag) lvl=(list sdiag) lint=(list sdiag)]
      ==
  ::  a semantic (generation) error suppresses level checking and
  ::  linting entirely, so the generation diags are the whole story
  ?:  (lien diags.m |=(d=sdiag =(%error sev.d)))
    [m [& ~ ~ ~] (render-levels-masked m) ops.dv [diags.m ~ ~]]
  =/  e=lenv
    :*  ops.dv
        =/  acc  *(map @t lkey)
        =/  acc
          =/  cl  consts.m
          |-  ^-  (map @t lkey)
          ?~  cl  acc
          $(cl t.cl, acc (~(put by acc) name.i.cl ['' name.i.cl %constant]))
        =/  vl  vars.m
        |-  ^-  (map @t lkey)
        ?~  vl  acc
        $(vl t.vl, acc (~(put by acc) name.i.vl ['' name.i.vl %variable]))
        ''
        c
        mlevs.dv
    ==
  ::  definitions
  =/  dwalk
    =|  out=(list sem-def)
    =|  ds=(list sdiag)
    =/  eo  e
    =/  dl  defs.m
    =/  secs  recsecs.m
    |-  ^-  [(list sem-def) lenv (list sdiag)]
    ?~  dl  [(flop out) eo ds]
    =/  insec
      ?~  secs  |
      ?~  names.i.secs  |
      =(i.names.i.secs name.i.dl)
    ?.  insec
      =/  gd  (l-def i.dl eo ~)
      $(dl t.dl, out [df.gd out], eo eo.gd, ds (weld ds ds.gd))
    ?>  ?=(^ secs)
    =/  n  (lent names.i.secs)
    =/  members  (scag n `(list sem-def)`dl)
    =/  rest  (slag n `(list sem-def)`dl)
    =/  recset
      =/  acc  *(set @t)
      =/  rl  recs.i.secs
      |-  ^-  (set @t)
      ?~  rl  acc
      $(rl t.rl, acc (~(put in acc) i.rl))
    ::  seed the RECURSIVE members so mutual references resolve
    =/  eo2
      =/  acc  eo
      =/  ml  members
      |-  ^-  lenv
      ?~  ml  acc
      ?.  (~(has in recset) name.i.ml)  $(ml t.ml)
      %=  $
        ml   t.ml
        acc  acc(ops (~(put by ops.acc) name.i.ml (rec-seed name.i.ml i.ml)))
      ==
    ::  iteration 1, with the primed-parameter check per RECURSIVE
    ::  member right after its check
    =/  it1
      =|  o1=(list sem-def)
      =|  d1=(list sdiag)
      =/  ml  members
      =/  ei  eo2
      |-  ^-  [(list sem-def) lenv (list sdiag)]
      ?~  ml  [(flop o1) ei d1]
      =/  isrec  (~(has in recset) name.i.ml)
      =/  prev  ?:(isrec (~(get by ops.ei) name.i.ml) ~)
      =/  gd  (l-def i.ml ei prev)
      =/  d2=(list sdiag)
        ?.  isrec  ~
        =/  j  0
        |-  ^-  (list sdiag)
        ?:  (gte j arity.df.gd)  ~
        ?:  (gte (at-or maxl.ol.gd j 3) 2)  $(j +(j))
        :_  $(j +(j))
        %^  derr  4.290  at.df.gd
        %+  weld  "Argument {(a-co +(j))} of recursive operator "
        "{(trip name.df.gd)} is primed"
      $(ml t.ml, o1 [df.gd o1], ei eo.gd, d1 :(weld d1 ds.gd d2))
    =/  [m1=(list sem-def) e1=lenv dit1=(list sdiag)]  it1
    ::  fixpoint raise: every member's level and level params rise to
    ::  the section's RECURSIVE maxima
    =/  maxrec
      =/  acc  0
      =/  ml  m1
      |-  ^-  @ud
      ?~  ml  acc
      ?.  (~(has in recset) name.i.ml)  $(ml t.ml)
      =/  o  (~(get by ops.e1) name.i.ml)
      $(ml t.ml, acc ?~(o acc (max acc lvl.u.o)))
    =/  reclp
      =/  acc  *(set lkey)
      =/  ml  m1
      |-  ^-  (set lkey)
      ?~  ml  acc
      ?.  (~(has in recset) name.i.ml)  $(ml t.ml)
      =/  o  (~(get by ops.e1) name.i.ml)
      $(ml t.ml, acc ?~(o acc (~(uni in acc) lp.u.o)))
    =/  recall
      =/  acc  *(set lkey)
      =/  ml  m1
      |-  ^-  (set lkey)
      ?~  ml  acc
      ?.  (~(has in recset) name.i.ml)  $(ml t.ml)
      =/  o  (~(get by ops.e1) name.i.ml)
      $(ml t.ml, acc ?~(o acc (~(uni in acc) all.u.o)))
    =/  e2
      =/  acc  e1
      =/  ml  m1
      |-  ^-  lenv
      ?~  ml  acc
      =/  o  (~(get by ops.acc) name.i.ml)
      ?~  o  $(ml t.ml)
      =/  o2
        %=  u.o
          lvl  (max lvl.u.o maxrec)
          lp   (~(uni in lp.u.o) reclp)
          all  (~(uni in all.u.o) recall)
        ==
      $(ml t.ml, acc acc(ops (~(put by ops.acc) name.i.ml o2)))
    ::  iteration 2
    =/  it2
      =|  o1=(list sem-def)
      =|  d1=(list sdiag)
      =/  ml  m1
      =/  ei  e2
      |-  ^-  [(list sem-def) lenv (list sdiag)]
      ?~  ml  [(flop o1) ei d1]
      =/  gd  (l-def i.ml ei (~(get by ops.ei) name.i.ml))
      $(ml t.ml, o1 [df.gd o1], ei eo.gd, d1 (weld d1 ds.gd))
    =/  [m2=(list sem-def) e3=lenv dit2=(list sdiag)]  it2
    %=  $
      dl    rest
      secs  t.secs
      out   (weld (flop m2) out)
      eo    e3
      ds    :(weld ds dit1 dit2)
    ==
  =/  [wdefs=(list sem-def) ed=lenv dds=(list sdiag)]  dwalk
  ::  theorem definitions (checked before the top-level statements)
  =/  twalk
    =|  out=(list sem-thm)
    =|  ds=(list sdiag)
    =/  eo  ed
    =/  tl  thmdefs.m
    |-  ^-  [(list sem-thm) lenv (list sdiag)]
    ?~  tl  [(flop out) eo ds]
    =/  gt  (l-thm i.tl eo)
    =/  eo2
      ?~  name.th.gt  eo
      %_  eo
          ops
        %+  ~(put by ops.eo)  u.name.th.gt
        ^-  oplev
        :*  lvl.r.gt  ok.r.gt  0  |  ~  ~  ~  ~  ~
            lp.r.gt  lc.r.gt  ac.r.gt  ap.r.gt  all.r.gt  nlp.r.gt  ~
        ==
      ==
    $(tl t.tl, out [th.gt out], eo eo2, ds (weld ds ds.gt))
  =/  [wthm=(list sem-thm) et=lenv tds=(list sdiag)]  twalk
  ::  top-level statements in source order
  =/  stmts
    ^-  (list [key=[@ud @ud] tag=?(%a %t %i) idx=@ud])
    =/  raw
      ;:  weld
        =/  i  0
        =/  al  assumes.m
        |-  ^-  (list [key=[@ud @ud] tag=?(%a %t %i) idx=@ud])
        ?~  al  ~
        [[(span-key at.i.al) %a i] $(al t.al, i +(i))]
      ::
        =/  i  0
        =/  al  theorems.m
        |-  ^-  (list [key=[@ud @ud] tag=?(%a %t %i) idx=@ud])
        ?~  al  ~
        [[(span-key at.i.al) %t i] $(al t.al, i +(i))]
      ::
        =/  i  0
        =/  al  instances.m
        |-  ^-  (list [key=[@ud @ud] tag=?(%a %t %i) idx=@ud])
        ?~  al  ~
        [[(span-key at.i.al) %i i] $(al t.al, i +(i))]
      ==
    %+  sort  raw
    |=  $:  a=[key=[@ud @ud] tag=?(%a %t %i) idx=@ud]
            b=[key=[@ud @ud] tag=?(%a %t %i) idx=@ud]
        ==
    ?:  =(-.key.a -.key.b)  (lth +.key.a +.key.b)
    (lth -.key.a -.key.b)
  =/  tops
    =/  wass  assumes.m
    =/  wtheo  theorems.m
    =|  ds=(list sdiag)
    =|  arl=(list lres)
    =|  trl=(list lres)
    =|  ilc=(map lkey @ud)
    =/  sl  stmts
    |-  ^-  $:  wass=(list sem-thm)  wtheo=(list sem-thm)
                arl=(list lres)  trl=(list lres)  pds=(list sdiag)
                ilc=(map lkey @ud)
            ==
    ?~  sl  [wass wtheo (flop arl) (flop trl) ds ilc]
    ?-    tag.i.sl
        %a
      =/  th  (snag idx.i.sl wass)
      =/  gt  (l-thm th et)
      =/  d1=(list sdiag)
        ?:  =(0 lvl.r.gt)  ~
        :_  ~
        %^  derr  4.206  at.th.gt
        %+  weld  "Level error: assumptions must be level 0 (Constant), "
        "\0abut this one has level {(a-co lvl.r.gt)}."
      %=  $
        sl    t.sl
        wass  (snap wass idx.i.sl th.gt)
        arl   [r.gt arl]
        ds    :(weld ds ds.gt d1)
      ==
    ::
        %t
      =/  th  (snag idx.i.sl wtheo)
      =/  gt  (l-thm th et)
      %=  $
        sl     t.sl
        wtheo  (snap wtheo idx.i.sl th.gt)
        trl    [r.gt trl]
        ds     (weld ds ds.gt)
      ==
    ::
        %i
      =/  it  (snag idx.i.sl instances.m)
      =/  li  (l-inst it et)
      $(sl t.sl, ds (weld ds ds.li), ilc (lc-uni ilc lc.li))
    ==
  =/  tp  tops
  =/  wass  wass.tp
  =/  wtheo  wtheo.tp
  =/  arl  arl.tp
  =/  trl  trl.tp
  =/  pds  pds.tp
  =/  ilc  ilc.tp
  ::  module constancy and module-level constraints (consumed by
  ::  INSTANCE checking when this module is instanced)
  =/  const
    ?&  =(~ vars.m)
        %+  levy  wdefs
        |=(df=sem-def =(0 lvl.df))
        %+  levy  wtheo
        |=(th=sem-thm =(0 lvl.th))
    ==
  ::  EXTENDS-imported definitions contribute to the module-level
  ::  constraint sets exactly like own definitions
  ::  (ModuleNode.getOpDefs includes them). Only EXTENDS imports count:
  ::  an INSTANCE-loaded module's raw definitions are not among this
  ::  module's opDefs and must not contribute
  =/  impdefs
    ^-  (list oplev)
    =/  rootdefs
      =/  acc  *(set @t)
      =/  dl  wdefs
      |-  ^-  (set @t)
      ?~  dl  acc
      $(dl t.dl, acc (~(put in acc) name.i.dl))
    =/  exts
      =/  mt  (~(get by mods) name.m)
      ?~  mt  `(list @t)`~
      (extends-of tree.u.mt)
    %-  zing
    %+  turn  exts
    |=  en=@t
    ^-  (list oplev)
    %+  murn  ~(tap by (~(gut by ctxs) en ~))
    |=  [nm=@t s=sym]
    ^-  (unit oplev)
    ?.  =(%user-op kind.s)  ~
    ?:  (~(has in rootdefs) nm)  ~
    (~(get by ops.dv) nm)
  =/  mlc
    =/  acc  *(map lkey @ud)
    =/  acc
      ?:  const  acc
      =/  cl  consts.m
      |-  ^-  (map lkey @ud)
      ?~  cl  acc
      $(cl t.cl, acc (lc-put acc ['' name.i.cl %constant] 0))
    =/  acc
      =/  dl  wdefs
      |-  ^-  (map lkey @ud)
      ?~  dl  acc
      =/  o  (~(get by ops.ed) name.i.dl)
      $(dl t.dl, acc ?~(o acc (lc-uni acc lc.u.o)))
    =/  acc
      =/  il  impdefs
      |-  ^-  (map lkey @ud)
      ?~  il  acc
      $(il t.il, acc (lc-uni acc lc.i.il))
    ::  assumptions constrain their constants below temporal level
    ::  (addTemporalLevelConstraintToConstants) and contribute their own
    ::  constraint sets, as do theorems
    =/  acc
      =/  al  arl
      |-  ^-  (map lkey @ud)
      ?~  al  acc
      =/  acc2
        =/  ps  ~(tap in lp.i.al)
        =/  a2  (lc-uni acc lc.i.al)
        |-  ^-  (map lkey @ud)
        ?~  ps  a2
        ?.  =(%constant kind.i.ps)  $(ps t.ps)
        $(ps t.ps, a2 (lc-put a2 i.ps 2))
      $(al t.al, acc acc2)
    =/  acc
      =/  tl  trl
      |-  ^-  (map lkey @ud)
      ?~  tl  acc
      $(tl t.tl, acc (lc-uni acc lc.i.tl))
    (lc-uni acc ilc)
  =/  m2
    %_  m
      defs      wdefs
      thmdefs   wthm
      assumes   wass
      theorems  wtheo
      lchecked  &
    ==
  ::  the LEVELS projection: module line (levelParams = the constant
  ::  declarations; ModuleNode.getLevel() throws, printed L-1; the
  ::  constraint sets union the definitions' and top-level statements',
  ::  arg-level params filtered of entries mentioning a definition's
  ::  own formal parameters), then one line per definition and theorem
  ::  definition. Instance-node constraint contributions are subunit 4.6
  =/  mlp
    =/  acc  *(set lkey)
    =/  cl  consts.m
    |-  ^-  (set lkey)
    ?~  cl  acc
    $(cl t.cl, acc (~(put in acc) `lkey`['' name.i.cl %constant]))
  =/  malc
    =/  acc
      =/  a2  *(map [k=lkey i=@ud] @ud)
      =/  dl  wdefs
      |-  ^-  (map [k=lkey i=@ud] @ud)
      ?~  dl  a2
      =/  o  (~(get by ops.et) name.i.dl)
      $(dl t.dl, a2 ?~(o a2 (ac-uni a2 ac.u.o)))
    =/  acc
      =/  il  impdefs
      |-  ^-  (map [k=lkey i=@ud] @ud)
      ?~  il  acc
      $(il t.il, acc (ac-uni acc ac.i.il))
    =/  acc
      =/  al  arl
      |-  ^-  (map [k=lkey i=@ud] @ud)
      ?~  al  acc
      $(al t.al, acc (ac-uni acc ac.i.al))
    =/  tl  trl
    |-  ^-  (map [k=lkey i=@ud] @ud)
    ?~  tl  acc
    $(tl t.tl, acc (ac-uni acc ac.i.tl))
  =/  alp-of-def
    ::  a definition's argLevelParams contribution to the module node:
    ::  entries mentioning its own formal parameters stay behind
    |=  [o=oplev acc=(set [op=lkey i=@ud par=lkey])]
    ^-  (set [op=lkey i=@ud par=lkey])
    =/  pl  ~(tap in ap.o)
    |-  ^-  (set [op=lkey i=@ud par=lkey])
    ?~  pl  acc
    =/  hit
      =/  ql  pars.o
      |-  ^-  ?
      ?~  ql  |
      ?:  |(=(op.i.pl i.ql) =(par.i.pl i.ql))  &
      $(ql t.ql)
    $(pl t.pl, acc ?:(hit acc (~(put in acc) i.pl)))
  =/  malp
    =/  acc
      =/  a2  *(set [op=lkey i=@ud par=lkey])
      =/  dl  wdefs
      |-  ^-  (set [op=lkey i=@ud par=lkey])
      ?~  dl  a2
      =/  o  (~(get by ops.et) name.i.dl)
      ?~  o  $(dl t.dl)
      $(dl t.dl, a2 (alp-of-def u.o a2))
    =/  acc
      =/  il  impdefs
      |-  ^-  (set [op=lkey i=@ud par=lkey])
      ?~  il  acc
      $(il t.il, acc (alp-of-def i.il acc))
    =/  acc
      =/  al  arl
      |-  ^-  (set [op=lkey i=@ud par=lkey])
      ?~  al  acc
      $(al t.al, acc (~(uni in acc) ap.i.al))
    =/  tl  trl
    |-  ^-  (set [op=lkey i=@ud par=lkey])
    ?~  tl  acc
    $(tl t.tl, acc (~(uni in acc) ap.i.tl))
  =/  lvls=wain
    :-  %-  crip
        %+  weld  "lvl MODULE {(trip name.m)} L-1"
        (lvl-segs mlp mlc malc malp ~)
    %+  weld
      ^-  wain
      %+  turn  wdefs
      |=  df=sem-def
      =/  o  (~(get by ops.et) name.df)
      ?~(o (lvl-line-masked df) (lvl-line-def df u.o))
    ^-  wain
    %+  turn  wthm
    |=  th=sem-thm
    =/  nm  (fall name.th '')
    =/  o  (~(get by ops.et) nm)
    %-  crip
    %+  weld  "lvl {(trip nm)} L{(a-co lvl.th)}"
    ?~(o "" (lvl-segs lp.u.o lc.u.o ac.u.o ap.u.o nlp.u.o))
  =/  level-ds  :(weld dds tds pds)
  =/  allds  (weld diags.m level-ds)
  =/  lint-ds
    ?:  (lien allds |=(d=sdiag =(%error sev.d)))  ~
    (l-lint m2 c)
  :*  m2(diags (dedup-diags (weld allds lint-ds)))
      [const mlc malc malp]
      lvls
      ops.et
      [diags.m level-ds lint-ds]
  ==
::
++  collect-records
  ::  every $RcdConstructor application in the module, in generation
  ::  order (definitions, then theorem definitions, assumptions,
  ::  theorems; LET definitions inline)
  |=  m=sem-module
  ^-  (list sem)
  =/  from-sem
    |=  s=sem
    =/  acc  *(list sem)
    |-  ^-  (list sem)
    ?-    -.s
        %lit      acc
        %atref    acc
        %nullodn  acc
        %letin
      =/  acc2
        =/  dl  lets.s
        |-  ^-  (list sem)
        ?~  dl  acc
        =/  a3  ?~(body.i.dl acc ^$(s u.body.i.dl))
        $(dl t.dl, acc a3)
      ?~(body.s acc2 $(s u.body.s, acc acc2))
    ::
        %apply
      =/  acc2
        ?.  =('$RcdConstructor' name.op.s)  acc
        (weld acc `(list sem)`[s ~])
      =/  acc3
        =/  gl  bound.s
        |-  ^-  (list sem)
        ?~  gl  acc2
        =/  a4  ?~(range.i.gl acc2 ^$(s u.range.i.gl, acc acc2))
        $(gl t.gl, acc2 a4)
      =/  al  args.s
      |-  ^-  (list sem)
      ?~  al  acc3
      $(al t.al, acc3 ^$(s i.al, acc acc3))
    ==
  =/  from-body
    |=  b=(unit sem)
    ^-  (list sem)
    ?~(b ~ (from-sem u.b))
  ;:  weld
    =/  dl  defs.m
    |-  ^-  (list sem)
    ?~  dl  ~
    (weld (from-body body.i.dl) $(dl t.dl))
  ::
    =/  tl  thmdefs.m
    |-  ^-  (list sem)
    ?~  tl  ~
    (weld (from-body body.i.tl) $(tl t.tl))
  ::
    =/  tl  assumes.m
    |-  ^-  (list sem)
    ?~  tl  ~
    (weld (from-body body.i.tl) $(tl t.tl))
  ::
    =/  tl  theorems.m
    |-  ^-  (list sem)
    ?~  tl  ~
    (weld (from-body body.i.tl) $(tl t.tl))
  ==
::
++  rcd-pairs
  ::  the $Pair components of a record constructor with a string field
  ::  name: [name name-span rhs]
  |=  r=sem
  ^-  (list [fname=@t at=sspan rhs=sem])
  ?.  ?=(%apply -.r)  ~
  %+  murn  args.r
  |=  a=sem
  ^-  (unit [fname=@t at=sspan rhs=sem])
  ?.  ?=(%apply -.a)  ~
  ?.  =('$Pair' name.op.a)  ~
  ?.  ?=([* * ~] args.a)  ~
  =/  lhs  i.args.a
  ?.  ?=(%lit -.lhs)  ~
  ?.  =(%str kind.lhs)  ~
  `[val.lhs at.lhs i.t.args.a]
::
++  built-from-decls
  ::  Linter.isBuiltFromDeclarations: the expression (transitively,
  ::  through definition bodies) applies a declared symbol, formal
  ::  parameter, or one of the BOOLEAN/Int/Nat/Reals stubs
  |=  [s=sem defs=(map @t sem-def) seen=(set @t)]
  ^-  ?
  ?-    -.s
      %lit      |
      %atref    |
      %nullodn  |
      %letin
    ?~  body.s  |
    $(s u.body.s)
  ::
      %apply
    =/  hit
      ?:  ?=(?(%constant %variable %formal-param %new-constant) kind.op.s)
        &
      ?:  &(=(%builtin kind.op.s) =('BOOLEAN' name.op.s))  &
      ?.  =(%user-op kind.op.s)  |
      =/  df  (~(get by defs) name.op.s)
      ?~  df
        ?|(=('Int' name.op.s) =('Nat' name.op.s) =('Reals' name.op.s))
      ?:  (~(has in seen) name.op.s)  |
      ?~  body.u.df  |
      $(s u.body.u.df, seen (~(put in seen) name.op.s))
    ?:  hit  &
    =/  sub
      =/  gl  bound.s
      |-  ^-  ?
      ?~  gl  |
      ?:  ?~(range.i.gl | ^$(s u.range.i.gl))  &
      $(gl t.gl)
    ?:  sub  &
    =/  al  args.s
    |-  ^-  ?
    ?~  al  |
    ?:  ^$(s i.al)  &
    $(al t.al)
  ==
::
++  l-lint
  ::  the record-constructor field-name linter (tla2sany.linter.Linter):
  ::  warn when a field name shadows a visible definition or declaration
  ::  unless this record (or any record with the same field domain) has
  ::  a component built from declarations
  |=  [m=sem-module c=ctx]
  ^-  (list sdiag)
  =/  records  (collect-records m)
  =/  defsmap
    =/  acc  *(map @t sem-def)
    =/  dl  defs.m
    |-  ^-  (map @t sem-def)
    ?~  dl  acc
    $(dl t.dl, acc (~(put by acc) name.i.dl i.dl))
  =/  same-domain
    |=  [a=sem b=sem]
    ^-  ?
    =/  pa  (rcd-pairs a)
    =/  pb  (rcd-pairs b)
    ?.  =((lent pa) (lent pb))  |
    %+  levy  pa
    |=  x=[fname=@t at=sspan rhs=sem]
    (lien pb |=(y=[fname=@t at=sspan rhs=sem] =(fname.x fname.y)))
  =/  any-bfd
    |=  r=sem
    ^-  ?
    %+  lien  (rcd-pairs r)
    |=  p=[fname=@t at=sspan rhs=sem]
    (built-from-decls rhs.p defsmap ~)
  =|  out=(list sdiag)
  =/  rl  records
  |-  ^-  (list sdiag)
  ?~  rl  (flop out)
  =/  suppress
    %+  lien  records
    |=  r2=sem
    &((same-domain i.rl r2) (any-bfd r2))
  =/  warns
    ?:  suppress  ~
    %+  murn  (rcd-pairs i.rl)
    |=  p=[fname=@t at=sspan rhs=sem]
    ^-  (unit sdiag)
    ?~  (~(get by c) fname.p)  ~
    :-  ~
    %^  dwarn  4.802  at.p
    ;:  weld
      "The field name \"{(trip fname.p)}\" in the record constructor "
      "is identical to the existing definition or declaration\0a"
      "named {(trip fname.p)}.\0a"
      "The field in the record will not take the value of the "
      "{(trip fname.p)} definition or declaration.\0a"
      "In TLA+, field names in records are strings, regardless of any "
      "similarly named declarations or definitions.\0a"
      "Therefore, DOMAIN [{(trip fname.p)} |-> ...] = "
      "\{\"{(trip fname.p)}\"} holds true."
    ==
  $(rl t.rl, out (weld (flop warns) out))
::
::  driver-level warning controls (SanySettings.suppressedCodes /
::  messagesAsErrorCodes), applied at report time to linting warnings.
::  These live outside the Errors channel — SANY filters them in the
::  driver after level checking, so they never reach a SemDump golden;
::  the analyze pipeline (unit 4.8) applies them and their evidence is
::  the Hoon unit tests in tests/lib/lvl
+$  lint-options
  $:  suppressed=(set @ud)   ::  message codes to silence
      as-errors=(set @ud)    ::  message codes to elevate to errors
  ==
::
++  apply-lint-options
  ::  SANY.filterVisibleMessages then reportMessages: drop suppressed
  ::  codes, elevate as-errors codes from %warning to %error (order
  ::  preserved). A code in both sets is a configuration error (SANY
  ::  rejects before running), reported as a typed failure
  |=  [opts=lint-options ds=(list sdiag)]
  ^-  (each (list sdiag) @t)
  ?.  =(~ (~(int in suppressed.opts) as-errors.opts))
    :-  %|
    %-  crip
    %+  weld  "Options suppressed and as-errors overlap for codes: "
    (join-sep "," (turn (sort ~(tap in (~(int in suppressed.opts) as-errors.opts)) lth) a-co))
  :-  %&
  %+  murn  ds
  |=  d=sdiag
  ^-  (unit sdiag)
  ?:  (~(has in suppressed.opts) code.d)  ~
  ?:  (~(has in as-errors.opts) code.d)  `d(sev %error)
  `d
::
++  lint-warnings
  ::  a module's linting warnings only (the linter's own diagnostics),
  ::  for the analyze pipeline to filter/elevate independently of the
  ::  semantic and level diagnostics already merged into the module
  |=  [m=sem-module c=ctx]
  ^-  (list sdiag)
  (l-lint m c)
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
    ?:  =('$OpArg' name.op.s)
      =/  nm  ?~(ubound.s '' name.i.ubound.s)
      =/  ary=@t
        ?~  args.s  '0'
        ?:(?=(%lit -.i.args.s) val.i.args.s '0')
      :_  ~
      %+  line  d
      "oparg {(trip nm)} op={(trip nm)} arity={(trip ary)} {(rlvl mask lvl.s)} {(sspan-tape at.s)}"
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
    ?:  ?=(^ (anysubstin-mod name.op.s))
      ::  the reserved substitution wrapper (see the mold note above)
      =/  tag  ?:(?=(^ (substin-mod name.op.s)) "substin" "apsubstin")
      =/  nsubs  (lent ubound.s)
      :-  %+  line  d
          "{tag} subs={(a-co nsubs)} {(rlvl mask lvl.s)} {(sspan-tape at.s)}"
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
      (line +(d) "ubound {(trip name.b)} {(rlvl |(mask !used.b) 0)} {(sspan-tape at.b)}")
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
        (line +(d) "bound {(trip name.b)} {(rlvl |(mask !used.b) 0)} {(sspan-tape at.b)}")
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
++  first-line
  ::  diagnostics store SANY's full (possibly multi-line) message so
  ::  deduplication matches Errors equality; the D line shows line one
  |=  t=@t
  ^-  tape
  =/  raw  (trip t)
  |-  ^-  tape
  ?~  raw  ~
  ?:(=('\0a' i.raw) ~ [i.raw $(raw t.raw)])
::
++  esc-msg
  ::  SemDump's esc() on a D-line message: backslash and control
  ::  characters escape (the message is already cut at its first
  ::  newline, so \n never occurs here)
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?:  =('\\' i.t)  ['\\' '\\' $(t t.t)]
  ?:  =('\0d' i.t)  ['\\' 'r' $(t t.t)]
  ?:  =('\09' i.t)  ['\\' 't' $(t t.t)]
  ?:  =('\0c' i.t)  ['\\' 'f' $(t t.t)]
  [i.t $(t t.t)]
::
++  render-module
  |=  m=sem-module
  ^-  wain
  =/  mask  !lchecked.m
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
    "D {(a-co code.dg)} {?:(=(%error sev.dg) "ERROR" "WARNING")} {(sspan-tape at.dg)} {(esc-msg (first-line msg.dg))}"
  ==
--
