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
      %builtin   %module-instance  %thm-assump
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
::
++  dump-module
  ::  the root module's normalized semantic tree (categorized:
  ::  constants, variables, definitions), operators resolved via ctx
  |=  [tree=node c=ctx]
  ^-  wain
  =/  units  (body-of-module tree)
  =/  hd
    (line 0 "MODULE {(trip (module-name tree))} {(loc-tape tree)}")
  ::  constants
  =/  consts=wain
    %-  zing
    %+  turn  units
    |=  u=node
    ^-  wain
    ?.  (is-kind u %n-paramdeclaration)  ~
    %+  turn  (decl-syms u)
    |=  [nm=@t s=sym at=node]
    (line 1 "const {(trip nm)} arity={(a-co arity.s)} L{(a-co level.s)} {(loc-tape at)}")
  ::  variables
  =/  vars=wain
    %-  zing
    %+  turn  units
    |=  u=node
    ^-  wain
    ?.  (is-kind u %n-variabledeclaration)  ~
    %+  turn  (decl-syms u)
    |=  [nm=@t s=sym at=node]
    (line 1 "var {(trip nm)} L{(a-co level.s)} {(loc-tape at)}")
  ::  definitions
  =/  defs=wain
    %-  zing
    %+  turn  units
    |=  u=node
    ^-  wain
    ?:  (is-kind u %n-operatordefinition)  (dump-opdef u c 1)
    ?:  (is-kind u %n-functiondefinition)  (dump-opdef u c 1)
    ~
  :-  hd
  :(weld consts vars defs)
::
++  a-co
  |=  n=@ud
  ^-  tape
  (dec-tape:ast n)
::
++  decl-loc
  ::  span of the identifier leaf for a declared name (const/var)
  |=  [u=node nm=@t]
  ^-  tape
  =/  hit  (find-ident (kids-of u) nm)
  ?~  hit  "~"
  (loc-tape u.hit)
::
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
::
++  dump-opdef
  ::  `def <name> arity=<n> local=<y/n> <loc>` + params + body
  |=  [u=node c=ctx d=@ud]
  ^-  wain
  =/  ds  (def-signature u)
  ?~  ds  ~
  =/  kids  (kids-of u)
  ?:  (is-kind u %n-functiondefinition)
    ::  function def: 0-ary op; body is the function-constructor expr
    :-  (line d "def {(trip name.u.ds)} arity=0 local={(yn local.u.ds)} L{(a-co (fcn-level u c))} {(loc-tape u)}")
    (dump-fcn-body u c +(d))
  ::  operator def: [lhs def body]; params come from the lhs
  ?~  kids  ~
  =/  lhs  i.kids
  =/  body  (rear-node kids)
  =/  params  (lhs-params lhs)
  =/  c2  (add-params c params)
  =/  hdr
    (line d "def {(trip name.u.ds)} arity={(a-co arity.s.u.ds)} local={(yn local.u.ds)} L{(a-co (expr-level body c2))} {(loc-tape u)}")
  :-  hdr
  %+  weld
    %+  turn  params
    |=  [pn=@t pnode=node par=@ud]
    ::  SANY leaves an unreferenced formal parameter's level uncomputed
    ::  (-1); a referenced constant parameter is level 0
    =/  lvl  ?:((subtree-names-has body pn) "L0" "L-1")
    (line +(d) "param {(trip pn)} arity={(a-co par)} {lvl} {(loc-tape pnode)}")
  (x body c2 +(d))
::
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
    (op-level (leaf-text (rear-node ids)) c ~)
  ::
      %n-opapplication
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  (max-levels c (skim kids |=(k=node ?=(%node -.k))))
    =/  gk  (kids-of (snag 0 kids))
    =/  ids  (skim gk |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
    ?~  ids  0
    =/  args  (skim (kids-of (snag 1 kids)) |=(k=node ?=(%node -.k)))
    (op-level (leaf-text (rear-node ids)) c args)
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
::
++  x
  ::  render an expression syntax node as normalized semantic lines
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  ?:  ?=(%leaf -.n)  ~
  ?+    kind.n  (x-fallback n c d)
      %n-parenexpr
    ::  [( expr )] -> inner
    =/  kids  (kids-of n)
    ?:  (gte (lent kids) 2)  (x (snag 1 kids) c d)
    ~
  ::
      %n-number
    ~[(line d "num {(trip (num-value n))} L0 {(loc-tape n)}")]
  ::
      %n-string
    ~[(line d "str {(esc-image:ast (str-value n))} L0 {(loc-tape n)}")]
  ::
      %n-real
    ~[(line d "dec {(trip (num-value n))} L0 {(loc-tape n)}")]
  ::
      %n-generalid
    (x-genid n c d)
  ::
      %n-opapplication
    (x-opappl n c d)
  ::
      %n-infixexpr
    =/  kids  (kids-of n)
    ?.  =(3 (lent kids))  (x-fallback n c d)
    =/  opn  (op-of-genop (snag 1 kids))
    :-  (apply-line opn c d n)
    %+  weld
      (x (snag 0 kids) c +(d))
    (x (snag 2 kids) c +(d))
  ::
      %n-prefixexpr
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  (x-fallback n c d)
    =/  opn  (op-of-genop (snag 0 kids))
    :-  (apply-line opn c d n)
    (x (snag 1 kids) c +(d))
  ::
      %n-postfixexpr
    =/  kids  (kids-of n)
    ?.  =(2 (lent kids))  (x-fallback n c d)
    =/  opn  (op-of-genop (snag 1 kids))
    :-  (apply-line opn c d n)
    (x (snag 0 kids) c +(d))
  ::
      %n-conjlist
    (x-builtin-list '$ConjList' n c d)
  ::
      %n-disjlist
    (x-builtin-list '$DisjList' n c d)
  ::
      %n-setenumerate
    (x-builtin-elems '$SetEnumerate' n c d)
  ::
      %n-tuple
    (x-builtin-elems '$Tuple' n c d)
  ::
      %n-ifthenelse
    =/  kids  (kids-of n)
    ?.  =(6 (lent kids))  (x-fallback n c d)
    :-  (apply-builtin-line '$IfThenElse' c d n)
    :(weld (x (snag 1 kids) c +(d)) (x (snag 3 kids) c +(d)) (x (snag 5 kids) c +(d)))
  ::
      %n-boundquant
    (x-bound-quant n c d)
  ::
      %n-unboundquant
    (x-unbound-quant n c d)
  ::
      %n-unboundorboundchoose
    (x-choose n c d)
  ::
      %n-letin
    (x-letin n c d)
  ::
      %n-subsetof
    (x-subsetof n c d)
  ::
      %n-setofall
    (x-setofall n c d)
  ::
      %n-setoffcns
    =/  kids  (kids-of n)
    =/  exprs  (skim kids |=(k=node ?=(%node -.k)))
    :-  (apply-builtin-line '$SetOfFcns' c d n)
    %-  zing
    (turn exprs |=(e=node (x e c +(d))))
  ::
      %n-rcdconstructor
    (x-rcd-constructor n c d)
  ::
      %n-setofrcds
    (x-rcd-constructor n c d)
  ::
      %n-recordcomponent
    (x-rcd-select n c d)
  ::
      %n-case
    (x-case n c d)
  ::
      ?(%n-actionexpr %n-fairnessexpr)
    =/  exprs  (skim (kids-of n) |=(k=node ?=(%node -.k)))
    :-  (apply-builtin-line (action-op n) c d n)
    %-  zing
    (turn exprs |=(e=node (x e c +(d))))
  ==
::
++  x-unbound-quant
  ::  N_UnboundQuant: [\A|\E ident.. : body]; unbounded symbols, no range
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  ?:  =(~ kids)  ~
  =/  q  (leaf-kind (snag 0 kids))
  =/  opn  ?:(=(%forall q) '$UnboundedForall' '$UnboundedExists')
  =/  vars  (idents-before-colon kids)
  =/  c2  (add-idents c vars)
  =/  body  (rear-node kids)
  :-  (apply-builtin-line opn c d n)
  %+  weld
    %+  turn  vars
    |=  [vn=@t vnode=node]
    (line +(d) "ubound {(trip vn)} L0 {(loc-tape vnode)}")
  (x body c2 +(d))
::
++  x-choose
  ::  N_UnboundOrBoundChoose: CHOOSE x (\in S)? : body
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  ?:  =(~ kids)  ~
  =/  vars  (idents-before-colon kids)
  =/  mbs  (skim kids |=(k=node (is-kind k %n-maybebound)))
  =/  rng=(unit node)
    ?~  mbs  ~
    (maybebound-range i.mbs)
  =/  bounded  ?=(^ mbs)
  =/  opn=@t  ?:(bounded '$BoundedChoose' '$UnboundedChoose')
  =/  c2  (add-idents c vars)
  =/  body  (rear-node kids)
  =/  head=wain
    %-  zing
    %+  turn  vars
    |=  [vn=@t vnode=node]
    ^-  wain
    ?.  bounded
      ~[(line +(d) "ubound {(trip vn)} L0 {(loc-tape vnode)}")]
    :-  (line +(d) "bound {(trip vn)} L0 {(loc-tape vnode)}")
    ?~(rng ~ (x u.rng c2 (add d 2)))
  :-  (apply-builtin-line opn c d n)
  (weld head (x body c2 +(d)))
::
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
::
++  x-letin
  ::  N_LetIn: [LET n-letdefinitions IN body]; let-defs extend the ctx
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  =/  defs-node  (skim kids |=(k=node (is-kind k %n-letdefinitions)))
  =/  ldefs
    ?~  defs-node  ~
    (skim (kids-of (snag 0 `(list node)`defs-node)) |=(k=node ?=(%node -.k)))
  =/  body  (rear-node kids)
  ::  each let definition is visible to later ones and to the body
  =/  c2=ctx
    =/  ds  ldefs
    =/  acc  c
    |-  ^-  ctx
    ?~  ds  acc
    =/  sig  (def-signature i.ds)
    ?~  sig  $(ds t.ds)
    $(ds t.ds, acc (~(put by acc) name.u.sig s.u.sig))
  =/  let-lines=wain
    %-  zing
    %+  turn  ldefs
    |=(ld=node (dump-opdef ld c2 +(d)))
  :-  (line d "letin lets={(a-co (lent ldefs))} L{(a-co (expr-level body c2))} {(loc-tape n)}")
  ;:  weld
    let-lines
    ~[(line +(d) "in")]
    (x body c2 (add d 2))
  ==
::
++  x-subsetof
  ::  N_SubsetOf: {x \in S : body} -> $SubsetOf, bound x over S, body
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  =/  vars  (idents-before-colon kids)
  =/  rng  (range-after-in kids)
  =/  c2  (add-idents c vars)
  =/  body  (expr-after-colon kids)
  =/  body-lines=wain  ?~(body ~ (x u.body c2 +(d)))
  =/  bound-lines=wain
    %-  zing
    %+  turn  vars
    |=  [vn=@t vnode=node]
    ^-  wain
    :-  (line +(d) "bound {(trip vn)} L0 {(loc-tape vnode)}")
    ?~(rng ~ (x u.rng c2 (add d 2)))
  :-  (apply-builtin-line '$SubsetOf' c d n)
  (weld bound-lines body-lines)
::
++  x-setofall
  ::  N_SetOfAll: {e : x \in S} -> $SetOfAll, bound x over S, operand e;
  ::  the bound is carried in an N_QuantBound child
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  c
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  e  (expr-before-colon kids)
  =/  e-lines=wain  ?~(e ~ (x u.e c2 +(d)))
  =/  bound-lines=wain
    %-  zing
    %+  turn  qbounds
    |=  qb=node
    ^-  wain
    =/  vars  (qbound-vars qb)
    =/  rng  (qbound-range qb)
    %-  zing
    %+  turn  vars
    |=  [vn=@t vnode=node]
    ^-  wain
    :-  (line +(d) "bound {(trip vn)} L0 {(loc-tape vnode)}")
    ?~(rng ~ (x u.rng c2 (add d 2)))
  :-  (apply-builtin-line '$SetOfAll' c d n)
  (weld bound-lines e-lines)
::
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
::
++  x-rcd-constructor
  ::  N_RcdConstructor / N_SetOfRcds: fields -> $RcdConstructor / $SetOfRcds
  ::  with a $Pair(field-string, value) per field
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  opn  ?:((is-kind n %n-setofrcds) '$SetOfRcds' '$RcdConstructor')
  =/  fields  (skim (kids-of n) |=(k=node ?=(%node -.k)))
  :-  (apply-builtin-line opn c d n)
  %-  zing
  %+  turn  fields
  |=  fv=node
  ^-  wain
  =/  fk  (kids-of fv)
  ?~  fk  ~
  =/  fname  (leaf-text i.fk)
  =/  val  (rear-node fk)
  :-  (apply-builtin-line '$Pair' c +(d) fv)
  %+  weld
    ~[(line (add d 2) "str {(trip fname)} L0 {(loc-tape i.fk)}")]
  (x val c (add d 2))
::
++  x-rcd-select
  ::  N_RecordComponent: [rec . field] -> $RcdSelect [rec, str field]
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  ?.  =(3 (lent kids))  (x-fallback n c d)
  =/  rec  (snag 0 kids)
  =/  fld  (snag 2 kids)
  :-  (apply-builtin-line '$RcdSelect' c d n)
  %+  weld
    (x rec c +(d))
  ~[(line +(d) "str {(trip (leaf-text fld))} L0 {(loc-tape fld)}")]
::
++  x-case
  ::  N_Case: CASE arm [] arm .. -> $Case with $Pair(cond,result) per arm
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  arms  (skim (kids-of n) |=(k=node (is-kind k %n-casearm)))
  :-  (apply-builtin-line '$Case' c d n)
  %-  zing
  %+  turn  arms
  |=  arm=node
  ^-  wain
  =/  ak  (skim (kids-of arm) |=(k=node ?=(%node -.k)))
  ?.  =(2 (lent ak))  ~
  :-  (apply-builtin-line '$Pair' c +(d) arm)
  %+  weld
    (x (snag 0 ak) c (add d 2))
  (x (snag 1 ak) c (add d 2))
::
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
::
++  lv
  ::  the `L<level>` field for a node under context `c`
  |=  [n=node c=ctx]
  ^-  tape
  "L{(a-co (expr-level n c))}"
::
++  apply-line
  ::  `apply <op> opkind=<kind> L<level> <loc>` for a resolved reference
  |=  [opn=@t c=ctx d=@ud whole=node]
  ^-  @t
  =/  s  (~(get by c) opn)
  =/  kt  ?~(s 'UnresolvedKind' (kind-tag kind.u.s))
  (line d "apply {(trip opn)} opkind={(trip kt)} {(lv whole c)} {(loc-tape whole)}")
::
++  apply-builtin-line
  |=  [opn=@t c=ctx d=@ud whole=node]
  ^-  @t
  (line d "apply {(trip opn)} opkind=BuiltInKind {(lv whole c)} {(loc-tape whole)}")
::
++  x-builtin-list
  ::  N_ConjList / N_DisjList: each item's expression is heirs[1]
  |=  [opn=@t n=node c=ctx d=@ud]
  ^-  wain
  :-  (apply-builtin-line opn c d n)
  %-  zing
  %+  turn  (kids-of n)
  |=  item=node
  ^-  wain
  =/  ik  (kids-of item)
  ?.  =(2 (lent ik))  ~
  (x (snag 1 ik) c +(d))
::
++  x-builtin-elems
  ::  N_SetEnumerate / N_Tuple: expression elements at odd child indices
  |=  [opn=@t n=node c=ctx d=@ud]
  ^-  wain
  :-  (apply-builtin-line opn c d n)
  %-  zing
  =/  kids  (kids-of n)
  =/  elems  (skim kids |=(k=node ?=(%node -.k)))
  %+  turn  elems
  |=(e=node (x e c +(d)))
::
++  x-genid
  ::  a general identifier used as a 0-ary operator reference
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~  ids  ~
  =/  nm  (leaf-text (rear-node ids))
  ~[(apply-line nm c d n)]
::
++  x-opappl
  ::  N_OpApplication: [n-generalid n-opargs]; resolve op, then args
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  ?.  =(2 (lent kids))  (x-fallback n c d)
  =/  gid  (snag 0 kids)
  =/  args-node  (snag 1 kids)
  =/  gk  (kids-of gid)
  =/  ids  (skim gk |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~  ids  ~
  =/  nm  (leaf-text (rear-node ids))
  =/  arg-exprs  (skim (kids-of args-node) |=(k=node ?=(%node -.k)))
  :-  (apply-line nm c d n)
  %-  zing
  (turn arg-exprs |=(a=node (x a c +(d))))
::
++  x-bound-quant
  ::  N_BoundQuant: [\A|\E n-quantbound.. : body]
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of n)
  ?:  =(~ kids)  ~
  =/  q  (leaf-kind (snag 0 kids))
  =/  opn  ?:(=(%forall q) '$BoundedForall' '$BoundedExists')
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  ::  extend ctx with bound variables (scope over ranges and body)
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  c
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  bound-lines=wain
    %-  zing
    %+  turn  qbounds
    |=  qb=node
    ^-  wain
    =/  vars  (qbound-vars qb)
    =/  rng  (qbound-range qb)
    %+  weld
      %+  turn  vars
      |=  [vn=@t vnode=node]
      (line +(d) "bound {(trip vn)} L0 {(loc-tape vnode)}")
    ?~(rng ~ (x u.rng c2 (add d 2)))
  =/  body  (rear-node kids)
  :-  (apply-builtin-line opn c d n)
  (weld bound-lines (x body c2 +(d)))
::
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
::
++  dump-fcn-body
  ::  N_FunctionDefinition body: a $NonRecursiveFcnSpec (or
  ::  $RecursiveFcnSpec if the body refers to the function) applied over
  ::  the declared bound variables; the operator span is the whole def
  |=  [u=node c=ctx d=@ud]
  ^-  wain
  =/  kids  (kids-of u)
  =/  ids  (skim kids |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  =/  fname  ?~(ids '' (leaf-text i.ids))
  =/  qbounds  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  body  (rear-node kids)
  =/  recursive  (subtree-names-has body fname)
  =/  opn  ?:(recursive '$RecursiveFcnSpec' '$NonRecursiveFcnSpec')
  ::  bound variables scope over the body (and the function name if recursive)
  =/  c2=ctx
    =/  qbs  qbounds
    =/  acc  ?:(recursive (~(put by c) fname [%user-op 0 | 0 ~]) c)
    |-  ^-  ctx
    ?~  qbs  acc
    $(qbs t.qbs, acc (add-idents acc (qbound-vars i.qbs)))
  =/  bound-lines=wain
    %-  zing
    %+  turn  qbounds
    |=  qb=node
    ^-  wain
    =/  vars  (qbound-vars qb)
    =/  rng  (qbound-range qb)
    %-  zing
    %+  turn  vars
    |=  [vn=@t vnode=node]
    ^-  wain
    :-  (line +(d) "bound {(trip vn)} L0 {(loc-tape vnode)}")
    ?~(rng ~ (x u.rng c2 (add d 2)))
  :-  (apply-builtin-line opn c d u)
  (weld bound-lines (x body c2 +(d)))
::
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
::
++  x-fallback
  ::  unhandled expression form: emit its node kind for visibility
  |=  [n=node c=ctx d=@ud]
  ^-  wain
  ?:  ?=(%leaf -.n)  ~
  ~[(line d "?{(trip kind.n)} {(loc-tape n)}")]
::
::  +|  Entry Point
::
::
++  dump-sem
  ::  resolve the module graph, analyze in dependency order, and dump the
  ::  root module's normalized semantic tree. Scope: well-formed modules;
  ::  SANY's semantic error recovery (nullODN sentinels, duplicate-symbol
  ::  dropping) and the separate diagnostic channel are a later increment.
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
  (dump-module tree.u.rt fc)
--
