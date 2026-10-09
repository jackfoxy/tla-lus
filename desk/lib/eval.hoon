/-  *tla-lus
/=  ast     /lib/ast
/=  syntax  /lib/syntax
|%
  ::  Constant-Expression Evaluation And Canonical TLC Values
  ::
  ::  SCOPE (R1.2.4): the CST EVALUATOR below (`+eval` over a `node`, and
  ::  `+eval-text`) is TEST-ONLY. It is reached from `tests/lib/eval` alone --
  ::  the 37-case `tlc2.REPL` differential -- and from no production path;
  ::  R1.4.4 retired it when `lib/node-eval` became the production evaluator.
  ::  What production imports from this library is its TYPES (`value`,
  ::  `vfield`, `vpair`) and four CST helpers (`kids-of`, `is-kind`, `op-name`,
  ::  `genid-name`).
  ::
  ::  That is why its `!!` sites are exempt from R1.2's no-bail invariant: no
  ::  user input can reach them. R1.2.4 weighed DELETING the driver to remove
  ::  them and decided against it -- the 37 REPL expressions are bare
  ::  expressions with no module context, and `gen-core-eval-tests`'s 20 cases
  ::  are arity-0 DEFINITIONS inside modules, so the coverage is not duplicated
  ::  without authoring 37 new fixtures and goldens. Removing 19 unreachable
  ::  assertions is not worth losing a differential. Every `!!` here is now
  ::  LABELLED, though: an unlabelled bail costs a debugging cycle to re-derive
  ::  even in test-only code (R1.6.0 paid exactly that).
  ::
  ::  A first increment of unit 9: evaluate a constant-level TLA+
  ::  expression (as parsed by lib/syntax) to a canonical TLC value
  ::  and render it exactly as the `tlc2.REPL` oracle does. Values are
  ::  normalized the way TLC normalizes them: set elements are sorted and
  ::  deduplicated, records are keyed, and a function whose domain is
  ::  1..n renders as a tuple. Integer arithmetic is signed.
  ::
  ::  Deviation (compatibility.md): TLC orders strings by their internal
  ::  UniqueString id (interning order), which is not reproducible without
  ::  replicating interning; strings are ordered lexicographically here,
  ::  which agrees with the oracle on non-adversarial string sets.
  ::
::  +|  Types
::
+$  node  syntax-node:ast
::  a canonical TLC value; recursion is only ever through +list, so no
::  $+ fixpoint annotation is needed
::  obelisk-style recursion: the type and its record arms are named,
::  $+-annotated molds; inline tagged tuples in the cycle overflow the
::  zuse-408 mold compiler / loop at runtime
+$  value
  $+  value
  $%  vbool  vint  vstr  vmodel  vset  vseq  vrec  vfcn  vintv
  ==
+$  vbool   $+(vbool $:(%bool p=?))
+$  vint    $+(vint $:(%int p=@sd))
+$  vstr    $+(vstr $:(%str p=@t))
+$  vmodel  $+(vmodel $:(%model p=@t))
::  R2.7.2: `cls` is the tlc2 VALUE CLASS this set was built as -- `%set-enum`
::  for an ordinary one, `%subset`/`%prod`/`%fcns`/`%rcds`/... for a lazy
::  construction. It rides the EXISTING arm rather than a new one because a
::  tenth arm carrying `value` overflows the zuse-408 mold compiler
::  (`recover: dig: over`), while widening an arm adds no cycle member and
::  compiles -- measured by isolation probe before any of this was written
+$  vset    $+(vset $:(%set cls=@tas p=(list value)))
+$  vseq    $+(vseq $:(%seq p=(list value)))
+$  vrec    $+(vrec $:(%rec p=(list vfield)))
+$  vfcn    $+(vfcn $:(%fcn p=(list vpair)))
+$  vintv   $+(vintv $:(%intv lo=@sd hi=@sd))
+$  vfield  $+(vfield $:(k=@t v=value))
+$  vpair   $+(vpair $:(d=value r=value))
+$  env  (map @t value)
::  evaluation can fail (TLC "Error evaluating expression")
+$  eval-result  (each value @t)
::
::  +|  Integer Helpers (signed)
::
::
++  in
  ::  a non-negative integer literal as a value
  |=  n=@ud
  ^-  value
  [%int (sun:si n)]
::
++  int-of
  |=  v=value
  ^-  @sd
  ?>  ?=(%int -.v)
  p.v
::
::  +|  Canonical Ordering
::
::
++  kind-rank
  |=  v=value
  ^-  @ud
  ?-  -.v
    %bool   0
    %int    1
    %intv   1
    %str    2
    %model  3
    %seq    4
    %set    5
    %rec    6
    %fcn    7
  ==
::
++  val-lth
  ::  strict canonical order used to normalize sets
  |=  [a=value b=value]
  ^-  ?
  =/  ra  (kind-rank a)
  =/  rb  (kind-rank b)
  ?.  =(ra rb)  (lth ra rb)
  ?-    -.a
      %bool   ?>(?=(%bool -.b) &(!p.a p.b))
  ::
      %int
    ?:  ?=(%int -.b)   (lth-si p.a p.b)
    ?>  ?=(%intv -.b)  (lth-si p.a lo.b)
  ::
      %intv
    ?:  ?=(%int -.b)   (lth-si lo.a p.b)
    ?>  ?=(%intv -.b)  (lth-si lo.a lo.b)
  ::
      %str    ?>(?=(%str -.b) (lth-str p.a p.b))
      %model  ?>(?=(%model -.b) (lth-str p.a p.b))
      %seq    ?>(?=(%seq -.b) (list-lth p.a p.b))
      %set    ?>(?=(%set -.b) (list-lth p.a p.b))
      %rec    ?>(?=(%rec -.b) |)
      %fcn    ?>(?=(%fcn -.b) |)
  ==
::
++  lth-si
  |=  [a=@sd b=@sd]
  ^-  ?
  =(%.y (dif-neg a b))
::
++  dif-neg
  ::  is a < b, for signed integers
  |=  [a=@sd b=@sd]
  ^-  ?
  =/  da  (old:si a)
  =/  db  (old:si b)
  ?:  &(-.da !-.db)  |            ::  a>=0, b<0  -> a not < b
  ?:  &(!-.da -.db)  &            ::  a<0, b>=0  -> a < b
  ?:  &(-.da -.db)   (lth +.da +.db)   ::  both >=0
  (gth +.da +.db)                 ::  both <0: more-negative is smaller
::
++  lth-str
  |=  [a=@t b=@t]
  ^-  ?
  =/  la  (trip a)
  =/  lb  (trip b)
  |-  ^-  ?
  ?~  la  ?~(lb | &)
  ?~  lb  |
  ?:  =(i.la i.lb)  $(la t.la, lb t.lb)
  (lth i.la i.lb)
::
++  list-lth
  ::  shorter first, then elementwise (matches TLC set/tuple order)
  |=  [a=(list value) b=(list value)]
  ^-  ?
  ?.  =((lent a) (lent b))  (lth (lent a) (lent b))
  |-  ^-  ?
  ?~  a  |
  ?~  b  |
  ?:  (val-equal i.a i.b)  $(a t.a, b t.b)
  (val-lth i.a i.b)
::
++  val-equal
  |=  [a=value b=value]
  ^-  ?
  &(!(val-lth a b) !(val-lth b a))
::
::  +|  Set Normalization
::
::
++  norm-set
  ::  sort by canonical order and remove duplicates
  |=  vs=(list value)
  ^-  (list value)
  =/  sorted  (sort vs val-lth)
  |-  ^-  (list value)
  ?~  sorted  ~
  ?~  t.sorted  sorted
  ?:  (val-equal i.sorted i.t.sorted)  $(sorted t.sorted)
  [i.sorted $(sorted t.sorted)]
::
++  expand
  ::  an interval or set as a plain element list (sets already normalized)
  |=  v=value
  ^-  (list value)
  ?-    -.v
      %set   p.v
      %intv
    =/  lo  lo.v
    |-  ^-  (list value)
    ?:  (lth-si hi.v lo)  ~
    [[%int lo] $(lo (sum:si lo (sun:si 1)))]
  ::
      *  ~
  ==
::
++  as-set
  ::  coerce a value to a normalized element list (set or interval)
  |=  v=value
  ^-  (list value)
  ?:  ?=(%set -.v)  p.v
  (norm-set (expand v))
::
::  +|  Rendering (matches tlc2.REPL toString)
::
::
++  render
  |=  v=value
  ^-  tape
  ?-    -.v
      %bool   ?:(p.v "TRUE" "FALSE")
      %int    (render-int p.v)
      %str    (weld "\"" (weld (trip p.v) "\""))
      %model  (trip p.v)
      %intv   "{(render-int lo.v)}..{(render-int hi.v)}"
  ::
      %set
    =/  es  (turn (norm-set p.v) render)
    "\{{(join-commas es)}}"
  ::
      %seq
    "<<{(join-commas (turn p.v render))}>>"
  ::
      %rec
    =/  es
      %+  turn  (sort p.v |=([x=[k=@t *] y=[k=@t *]] (lth-str k.x k.y)))
      |=  [k=@t val=value]
      "{(trip k)} |-> {(render val)}"
    "[{(join-commas es)}]"
  ::
      %fcn
    ::  a non-sequence function stays %fcn under +fcn-view, so render its
    ::  pairs here; recursing on it would never terminate (R4.0d: a trace
    ::  state holding [b \in {"E","W"} |-> ...] ran the loom out)
    =/  fv  (fcn-view v)
    ?.  ?=(%fcn -.fv)  (render fv)
    =/  ps  %+  turn  p.fv
            |=([d=value r=value] "{(render d)} :> {(render r)}")
    =/  body
      |-  ^-  tape
      ?~  ps  ~
      ?~  t.ps  i.ps
      :(weld i.ps " @@ " $(ps t.ps))
    "({body})"
  ==
::
++  render-int
  |=  n=@sd
  ^-  tape
  =/  o  (old:si n)
  ?:  -.o  (scow %ud +.o)
  ['-' (scow %ud +.o)]
::
++  join-commas
  |=  ts=(list tape)
  ^-  tape
  ?~  ts  ~
  ?~  t.ts  i.ts
  (weld i.ts (weld ", " $(ts t.ts)))
::
++  fcn-view
  ::  a function whose domain is exactly 1..n renders as a sequence
  |=  v=value
  ^-  value
  ?.  ?=(%fcn -.v)  v
  =/  n  (lent p.v)
  ?:  =(0 n)  [%seq ~]
  =/  contiguous
    =/  i  1
    =/  ps  p.v
    |-  ^-  ?
    ?~  ps  &
    ?.  (val-equal d.i.ps (in i))  |
    $(ps t.ps, i +(i))
  ?.  contiguous  v
  [%seq (turn p.v |=([d=value r=value] r))]
::
::  +|  Node Helpers
::
::
++  kids-of
  |=  n=node
  ^-  (list node)
  ?:(?=(%node -.n) kids.n ~)
::
++  leaf-text
  |=  n=node
  ^-  @t
  ?>(?=(%leaf -.n) text.token.n)
::
++  is-kind
  |=  [n=node k=@tas]
  ^-  ?
  &(?=(%node -.n) =(kind.n k))
::
++  node-text
  |=  n=node
  ^-  @t
  ?-  -.n
    %leaf  text.token.n
    %node  image.n
  ==
::
++  genid-name
  ::  the identifier of an N_GeneralId
  |=  n=node
  ^-  @t
  =/  ids  (skim (kids-of n) |=(k=node &(?=(%leaf -.k) =(%identifier kind.token.k))))
  ?~(ids '' (leaf-text (rear ids)))
::
++  op-name
  ::  operator name from an N_GenInfixOp / prefix / postfix (last child)
  |=  n=node
  ^-  @t
  ?:  ?=(%leaf -.n)  (leaf-text n)
  =/  kids  (kids-of n)
  ?~(kids '' (node-text (rear kids)))
::
++  elems
  ::  the expression children (nodes) of a set/tuple/args form
  |=  n=node
  ^-  (list node)
  (skim (kids-of n) |=(k=node ?=(%node -.k)))
::
++  num-lit
  |=  n=node
  ^-  @t
  =/  ls  (skim (kids-of n) |=(k=node ?=(%leaf -.k)))
  ?~(ls '0' (leaf-text i.ls))
::
++  str-lit
  ::  string content of an N_String (image is `"..."`)
  |=  n=node
  ^-  @t
  ?.  ?=(%node -.n)  ''
  =/  c  image.n
  =/  n  (met 3 c)
  ?:  (lth n 2)  c
  (cut 3 [1 (sub n 2)] c)
::
++  op-key
  ::  map an operator's (synonym-resolved) name cord to a clean @tas
  ::  dispatch key -- operator names contain characters (\, %, +) that
  ::  cannot appear in a @tas term literal
  |=  op=@t
  ^-  @tas
  ?:  =(op '+')  %add
  ?:  =(op '-')  %sub
  ?:  =(op '*')  %mul
  ?:  =(op '^')  %pow
  ?:  =(op '\\div')  %fdiv
  ?:  =(op '%')  %fmod
  ?:  =(op '=')  %eq
  ?:  =(op '/=')  %ne
  ?:  =(op '<')  %lt
  ?:  =(op '>')  %gt
  ?:  =(op '\\leq')  %le
  ?:  =(op '\\geq')  %ge
  ?:  =(op '/\\')  %and
  ?:  =(op '\\land')  %and
  ?:  =(op '\\/')  %or
  ?:  =(op '\\lor')  %or
  ?:  =(op '=>')  %imply
  ?:  =(op '\\equiv')  %iff
  ?:  =(op '\\in')  %in
  ?:  =(op '\\notin')  %notin
  ?:  =(op '\\subseteq')  %subseteq
  ?:  =(op '\\cup')  %union
  ?:  =(op '\\union')  %union
  ?:  =(op '\\cap')  %inter
  ?:  =(op '\\intersect')  %inter
  ?:  =(op '\\')  %diff
  ?:  =(op '..')  %range
  ?:  =(op '\\o')  %concat
  ?:  =(op '~')  %not
  ?:  =(op '\\lnot')  %not
  ?:  =(op 'SUBSET')  %powerset
  ?:  =(op 'UNION')  %bigunion
  ?:  =(op 'DOMAIN')  %domain
  %unknown
::
++  int-bin
  |=  [key=@tas a=@sd b=@sd]
  ^-  value
  ?+  key  ~|([%int-op key] !!)
    %add   [%int (sum:si a b)]
    %sub   [%int (dif:si a b)]
    %mul   [%int (pro:si a b)]
    %pow   (in (pow (abs:si a) (abs:si b)))
    %fdiv  (in (div (abs:si a) (abs:si b)))
    %fmod  (in (mod (abs:si a) (abs:si b)))
  ==
::
++  bool-of
  |=  v=value
  ^-  ?
  ?>(?=(%bool -.v) p.v)
::
++  eval-genid
  |=  [n=node e=env]
  ^-  value
  =/  nm  (genid-name n)
  ?:  =('TRUE' nm)   [%bool &]
  ?:  =('FALSE' nm)  [%bool |]
  ?:  =('BOOLEAN' nm)  [%set %set-enum ~[[%bool |] [%bool &]]]
  =/  hit  (~(get by e) nm)
  ?~  hit  ~|([%unbound nm] !!)
  u.hit
::
++  eval-infix
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  key  (op-key (op-name (snag 1 kids)))
  =/  a  (eval (snag 0 kids) e)
  =/  b  (eval (snag 2 kids) e)
  ?+    key  ~|([%infix key] !!)
      ?(%add %sub %mul %pow %fdiv %fmod)
    (int-bin key (int-of a) (int-of b))
  ::
      %eq   [%bool (val-equal a b)]
      %ne   [%bool !(val-equal a b)]
      %lt   [%bool (lth-si (int-of a) (int-of b))]
      %gt   [%bool (lth-si (int-of b) (int-of a))]
      %le   [%bool !(lth-si (int-of b) (int-of a))]
      %ge   [%bool !(lth-si (int-of a) (int-of b))]
      %and  [%bool &((bool-of a) (bool-of b))]
      %or   [%bool |((bool-of a) (bool-of b))]
      %imply  [%bool |(!(bool-of a) (bool-of b))]
      %iff  [%bool =((bool-of a) (bool-of b))]
      %in   [%bool (has-elem b a)]
      %notin  [%bool !(has-elem b a)]
      %subseteq  [%bool (subseteq a b)]
      %union  (set-union a b)
      %inter  (set-inter a b)
      %diff  (set-diff a b)
      %range  [%intv (int-of a) (int-of b)]
      %concat  [%seq (weld (seq-of a) (seq-of b))]
  ==
::
++  seq-of
  |=  v=value
  ^-  (list value)
  ?>(?=(?(%seq) -.v) p.v)
::
++  has-elem
  |=  [s=value x=value]
  ^-  ?
  (lien (as-set s) |=(y=value (val-equal x y)))
::
++  subseteq
  |=  [a=value b=value]
  ^-  ?
  =/  bs  (as-set b)
  (levy (as-set a) |=(x=value (lien bs |=(y=value (val-equal x y)))))
::
++  set-union
  |=  [a=value b=value]
  ^-  value
  [%set %set-enum (norm-set (weld (as-set a) (as-set b)))]
::
++  set-inter
  |=  [a=value b=value]
  ^-  value
  =/  bs  (as-set b)
  [%set %set-enum (norm-set (skim (as-set a) |=(x=value (lien bs |=(y=value (val-equal x y))))))]
::
++  set-diff
  |=  [a=value b=value]
  ^-  value
  =/  bs  (as-set b)
  [%set %set-enum (norm-set (skip (as-set a) |=(x=value (lien bs |=(y=value (val-equal x y))))))]
::
++  eval-prefix
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  key  (op-key (op-name (snag 0 kids)))
  =/  a  (eval (snag 1 kids) e)
  ?+    key  ~|([%prefix key] !!)
      %not  [%bool !(bool-of a)]
      %sub  [%int (dif:si (sun:si 0) (int-of a))]
      %powerset  (powerset a)
      %bigunion  (big-union a)
      %domain  (domain-of a)
  ==
::
++  powerset
  |=  s=value
  ^-  value
  =/  es  (as-set s)
  ::  build all subsets, seeding the accumulator with the empty subset
  =/  subs=(list (list value))  ~[~]
  =.  subs
    |-  ^-  (list (list value))
    ?~  es  subs
    =/  x  i.es
    =.  subs  (weld subs (turn subs |=(sub=(list value) (snoc sub x))))
    $(es t.es)
  [%set %set-enum (norm-set (turn subs |=(sub=(list value) `value`[%set %set-enum (norm-set sub)])))]
::
++  big-union
  |=  s=value
  ^-  value
  =/  inner  (as-set s)
  [%set %set-enum (norm-set (zing (turn inner as-set)))]
::
++  domain-of
  |=  v=value
  ^-  value
  ?-    -.v
      %rec   [%set %set-enum (norm-set (turn p.v |=([k=@t *] `value`[%str k])))]
      %fcn   [%set %set-enum (norm-set (turn p.v |=([d=value *] d)))]
      %seq   [%intv (sun:si 1) (sun:si (lent p.v))]
      *      ~|(%domain !!)
  ==
::
++  eval-record
  |=  [n=node e=env]
  ^-  value
  :-  %rec
  %+  turn  (skim (kids-of n) |=(k=node (is-kind k %n-fieldval)))
  |=  fv=node
  ^-  [@t value]
  =/  fk  (kids-of fv)
  [(leaf-text (snag 0 fk)) (eval (rear fk) e)]
::
++  eval-rcd-select
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  rec  (eval (snag 0 kids) e)
  =/  fld  (leaf-text (snag 2 kids))
  ?>  ?=(%rec -.rec)
  =/  hit  (skim p.rec |=([k=@t *] =(k fld)))
  ?~(hit ~|([%no-field fld] !!) v.i.hit)
::
++  eval-ite
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  ?:  (bool-of (eval (snag 1 kids) e))
    (eval (snag 3 kids) e)
  (eval (snag 5 kids) e)
::
++  qbound-parts
  ::  [vars range] from an N_QuantBound or a flat {x \in S ...} form:
  ::  identifier(s) before \in and the range expr after it
  |=  kids=(list node)
  ^-  [vars=(list @t) range=node]
  =/  vars=(list @t)
    %+  murn  kids
    |=  k=node
    ^-  (unit @t)
    ?.  &(?=(%leaf -.k) =(%identifier kind.token.k))  ~
    `(leaf-text k)
  =/  range
    =/  ks  kids
    |-  ^-  node
    ?~  ks  ~|(%eval-qbound-no-in !!)
    ?:  &(?=(%leaf -.i.ks) =(%t-in kind.token.i.ks))
      ?~(t.ks ~|(%eval-qbound-no-range !!) i.t.ks)
    $(ks t.ks)
  [vars range]
::
++  eval-subsetof
  ::  {x \in S : P}
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  parts  (qbound-parts kids)
  =/  dom  (as-set (eval range.parts e))
  =/  body  (expr-after-colon kids)
  =/  vn  ?~(vars.parts '' i.vars.parts)
  :+  %set  %set-enum
  %-  norm-set
  %+  skim  dom
  |=  x=value
  (bool-of (eval body (~(put by e) vn x)))
::
++  eval-setofall
  ::  {e : x \in S}
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  ex  (expr-before-colon kids)
  =/  qb  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  parts  (qbound-parts ?~(qb ~ (kids-of i.qb)))
  =/  dom  (as-set (eval range.parts e))
  =/  vn  ?~(vars.parts '' i.vars.parts)
  :+  %set  %set-enum
  %-  norm-set
  %+  turn  dom
  |=  x=value
  (eval ex (~(put by e) vn x))
::
++  expr-before-colon
  |=  kids=(list node)
  ^-  node
  |-  ^-  node
  ?~  kids  ~|(%eval-no-expr-before-colon !!)
  ?:  &(?=(%leaf -.i.kids) =(%colon kind.token.i.kids))
    ~|(%eval-empty-expr-before-colon !!)
  ?:  ?=(%node -.i.kids)  i.kids
  $(kids t.kids)
::
++  expr-after-colon
  ::  the first expression node following the `:` leaf
  |=  kids=(list node)
  ^-  node
  |-  ^-  node
  ?~  kids  ~|(%eval-no-colon !!)
  ?:  &(?=(%leaf -.i.kids) =(%colon kind.token.i.kids))
    |-  ^-  node
    ?~  t.kids  ~|(%eval-no-expr-after-colon !!)
    ?:  ?=(%node -.i.t.kids)  i.t.kids
    $(t.kids t.t.kids)
  $(kids t.kids)
::
++  eval-quant
  ::  \A x \in S : P  /  \E x \in S : P
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  forall  =(%forall (leaf-kind (snag 0 kids)))
  =/  qb  (skim kids |=(k=node (is-kind k %n-quantbound)))
  =/  parts  (qbound-parts ?~(qb ~ (kids-of i.qb)))
  =/  dom  (as-set (eval range.parts e))
  =/  body  (rear kids)
  =/  vn  ?~(vars.parts '' i.vars.parts)
  =/  test  |=(x=value (bool-of (eval body (~(put by e) vn x))))
  [%bool ?:(forall (levy dom test) (lien dom test))]
::
++  leaf-kind
  |=  n=node
  ^-  @tas
  ?>(?=(%leaf -.n) kind.token.n)
::
++  eval-opappl
  ::  standard-module operators applied as Op(args) and function
  ::  application f[e] (N_FcnAppl)
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  gid  (snag 0 kids)
  =/  op  (genid-name gid)
  =/  args  (turn (elems (snag 1 kids)) |=(k=node (eval k e)))
  ?:  =(op 'Cardinality')  (in (lent (as-set (snag 0 args))))
  ?:  =(op 'Len')  (in (lent (seq-of (snag 0 args))))
  ?:  =(op 'Head')  (snag 0 (seq-of (snag 0 args)))
  ?:  =(op 'Append')  [%seq (snoc (seq-of (snag 0 args)) (snag 1 args))]
  ?:  =(op 'Tail')  [%seq (slag 1 (seq-of (snag 0 args)))]
  ~|([%op op] !!)
::
++  eval
  ::  evaluate a constant expression node under environment `e`
  |=  [n=node e=env]
  ^-  value
  ?:  ?=(%leaf -.n)  ~|(%eval-leaf !!)
  ?+    kind.n  ~|([%eval-unhandled kind.n] !!)
      %n-parenexpr  (eval (snag 1 (kids-of n)) e)
      %n-number  (in (rash (num-lit n) dem))
      %n-string  [%str (str-lit n)]
      %n-generalid  (eval-genid n e)
      %n-infixexpr  (eval-infix n e)
      %n-prefixexpr  (eval-prefix n e)
      %n-setenumerate  [%set %set-enum (norm-set (turn (elems n) |=(k=node (eval k e))))]
      %n-tuple  [%seq (turn (elems n) |=(k=node (eval k e)))]
      %n-rcdconstructor  (eval-record n e)
      %n-recordcomponent  (eval-rcd-select n e)
      %n-ifthenelse  (eval-ite n e)
      %n-subsetof  (eval-subsetof n e)
      %n-setofall  (eval-setofall n e)
      %n-boundquant  (eval-quant n e)
      %n-fcnappl  (eval-fcnappl n e)
      %n-opapplication  (eval-opappl n e)
      %n-postfixexpr  (eval-postfix n e)
  ==
::
++  eval-postfix
  ::  a primed variable reference x': read the next-state binding stored
  ::  in the environment under the key "<name>'"
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  op  (op-name (snag 1 kids))
  ?.  =(op '\'')  ~|([%postfix op] !!)
  =/  nm  (genid-name (snag 0 kids))
  =/  hit  (~(get by e) (cat 3 nm '\''))
  ?~  hit  ~|([%unbound-prime nm] !!)
  u.hit
::
++  eval-fcnappl
  ::  f[e]: apply a sequence or function to an argument
  |=  [n=node e=env]
  ^-  value
  =/  kids  (kids-of n)
  =/  f  (eval (snag 0 kids) e)
  =/  arg  (eval (snag 2 kids) e)
  ?-    -.f
      %seq
    (snag (dec (abs:si (int-of arg))) p.f)
  ::
      %fcn
    =/  hit  (skim p.f |=([d=value *] (val-equal d arg)))
    ?~(hit ~|(%fcn-undef !!) r.i.hit)
  ::
      *  ~|(%not-a-function !!)
  ==
::
++  run
  ::  evaluate a parsed expression, catching evaluation errors like the
  ::  REPL ("Error evaluating expression")
  |=  n=node
  ^-  tape
  =/  res  (mule |.((render (eval n *env))))
  ?-  -.res
    %&  p.res
    %|  "Error evaluating expression"
  ==
::
++  find-expr
  ::  the body expression of the `Expr == ...` definition in a parsed
  ::  wrapper module
  |=  tree=node
  ^-  (unit node)
  ?.  (is-kind tree %n-module)  ~
  =/  b  (skim (kids-of tree) |=(k=node (is-kind k %n-body)))
  ?~  b  ~
  =/  defs  (skim (kids-of i.b) |=(k=node (is-kind k %n-operatordefinition)))
  ?~  defs  ~
  `(rear (kids-of i.defs))
::
++  eval-text
  ::  evaluate a constant TLA+ expression given as source text, matching
  ::  the tlc2.REPL rendering
  |=  txt=@t
  ^-  tape
  =/  src=@t  (crip "---- MODULE E ----\0aExpr == {(trip txt)}\0a====\0a")
  =/  pr  (parse:syntax src)
  ?:  ?=(%| -.pr)  "Error evaluating expression"
  =/  ex  (find-expr p.pr)
  ?~  ex  "Error evaluating expression"
  (run u.ex)
--

