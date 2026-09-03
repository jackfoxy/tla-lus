/-  *tla-lus
/=  ev  /lib/eval
|%
::  Canonical TLC values (PORT-COMPLETION-PLAN-2 unit 6, subunit 6.1).
::
::  The stable value interface the core evaluator (6.5), enumerator (6.3),
::  and fingerprint encoder (6.8) build on. Representation is distinct from
::  view: a tuple is a list of values (not a function rendering), an
::  interval is [lo hi] (not an eager set), a record is a field list (not a
::  rendered string). Rendered text is never identity.
::
::  Molds follow the zuse-408 recursive recipe (every cycle member is a
::  named $+ type with a $:-form record) — the exact shape lib/eval
::  proves compiles. Lazy finite-set descriptors (SUBSET/UNION/SetOfFcns…)
::  are subunit 6.3 and are added there behind isolation tests, not grown
::  into this union speculatively.
::
::  +|  Types
::
::  Reuse the value mold already proven to compile under zuse-408 in
::  lib/eval (a freshly-defined $+-recursive $% overflows the mold
::  compiler even in an isomorphic shape; aliasing the built one is the
::  same fix config.hoon uses). Tuples are the %seq member; a vpair's
::  image field is `r`. In 6.5 the mold ownership moves here and eval
::  aliases it, once the CST evaluator is retired.
+$  value   value:ev
+$  vfield  vfield:ev
+$  vpair   vpair:ev
::  a stable kind discriminator (legal cross-kind comparison + diagnostics)
+$  value-kind  @tas
::
::  +|  Kind
::
++  vkind
  |=  v=value
  ^-  value-kind
  -.v
::
++  type-name
  ::  the human name used in TLC evaluation diagnostics
  |=  v=value
  ^-  @t
  ?-  -.v
    %bool   'a boolean'
    %int    'an integer'
    %str    'a string'
    %model  'a model value'
    %intv   'a set'
    %set    'a set'
    %seq  'a tuple'
    %rec    'a record'
    %fcn    'a function'
  ==
::
::  +|  Signed-Integer And String Order (private, total)
::
++  slth
  ::  a < b for signed integers (@sd)
  |=  [a=@sd b=@sd]
  ^-  ?
  =/  da  (old:si a)
  =/  db  (old:si b)
  ?:  &(-.da !-.db)   |                 ::  a>=0, b<0
  ?:  &(!-.da -.db)   &                 ::  a<0, b>=0
  ?:  &(-.da -.db)    (lth +.da +.db)   ::  both >=0
  (gth +.da +.db)                       ::  both <0: more negative is smaller
::
++  strlth
  ::  bytewise lexicographic (UTF-8), a private storage order
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
::  kind order used only for private storage (NOT TLC comparison, which is
::  partial and lives in +compare)
++  kind-rank
  |=  v=value
  ^-  @ud
  ?-  -.v
    %bool  0   %int   1   %intv  1   %str   2   %model  3
    %seq  4  %set   5   %rec   6   %fcn   7
  ==
::
::  +|  Coercions For Cross-Representation Equality
::
++  set-like  |=(v=value ?=(?(%set %intv) -.v))
++  fcn-like  |=(v=value ?=(?(%fcn %seq) -.v))
::
++  expand-intv
  |=  [lo=@sd hi=@sd]
  ^-  (list value)
  ?:  (slth hi lo)  ~
  [[%int lo] $(lo (sum:si lo --1))]
::
++  set-elems
  ::  a set or interval as a plain element list
  |=  v=value
  ^-  (list value)
  ?-  -.v
    %set   p.v
    %intv  (expand-intv lo.v hi.v)
    %bool  ~
    %int   ~
    %str   ~
    %model  ~
    %seq  ~
    %rec   ~
    %fcn   ~
  ==
::
++  fcn-pairs
  ::  a function or tuple as domain->value pairs (tuple domain = 1..n)
  |=  v=value
  ^-  (list vpair)
  ?-  -.v
    %fcn   p.v
      %seq
    =|  i=@sd
    =.  i  --1
    |-  ^-  (list vpair)
    ?~  p.v  ~
    [[[%int i] i.p.v] $(p.v t.p.v, i (sum:si i --1))]
  ::
    %bool  ~
    %int   ~
    %str   ~
    %model  ~
    %intv  ~
    %rec   ~
    %set   ~
  ==
::
++  to-fcn-pairs
  ::  tlc2's Value.toFcnRcd: a function is one, and so are a tuple (domain
  ::  1..n) and a record (string domain). Bags are exactly these values
  |=  v=value
  ^-  (unit (list vpair))
  ?+  -.v  ~
    %fcn  `p.v
    %seq  `(fcn-pairs v)
    %rec  `(turn p.v |=(f=vfield `vpair`[[%str k.f] v.f]))
  ==
::
++  to-tuple
  ::  tlc2's Value.toTuple: a tuple is a sequence, and so is a function whose
  ::  domain is exactly 1..n (its values in index order). Anything else is
  ::  not a sequence — the distinction every Sequences operator makes
  |=  v=value
  ^-  (unit (list value))
  ?:  ?=(%seq -.v)  `p.v
  ?.  ?=(%fcn -.v)  ~
  =/  n  (normalize v)
  ?.  ?=(%fcn -.n)  ~
  =|  acc=(list value)
  =/  ps  p.n
  =/  i=@sd  --1
  |-  ^-  (unit (list value))
  ?~  ps  `(flop acc)
  ?.  ?=(%int -.d.i.ps)  ~
  ?.  =(p.d.i.ps i)  ~
  $(ps t.ps, acc [r.i.ps acc], i (sum:si i --1))
::
::  +|  Equality (total, cross-representation)
::
++  equal
  |=  [a=value b=value]
  ^-  ?
  (equal-norm (normalize a) (normalize b))
::
++  equal-norm
  ::  both inputs already normalized
  |=  [a=value b=value]
  ^-  ?
  ?:  &((set-like a) (set-like b))
    (elems-equal (set-elems a) (set-elems b))
  ?:  &((fcn-like a) (fcn-like b))
    (fcn-equal (fcn-pairs a) (fcn-pairs b))
  ?-  -.a
    %bool   &(?=(%bool -.b) =(p.a p.b))
    %int    &(?=(%int -.b) =(p.a p.b))
    %str    &(?=(%str -.b) =(p.a p.b))
    %model  &(?=(%model -.b) =(p.a p.b))
    %rec    &(?=(%rec -.b) (rec-equal p.a p.b))
    %intv   |
    %set    |
    %seq  |
    %fcn    |
  ==
::
++  elems-equal
  ::  two element lists denote the same set: same size, mutual membership
  |=  [a=(list value) b=(list value)]
  ^-  ?
  ?.  =((lent a) (lent b))  |
  ?&  (levy a |=(x=value (lien b |=(y=value (equal-norm x y)))))
      (levy b |=(y=value (lien a |=(x=value (equal-norm x y)))))
  ==
::
++  fcn-equal
  ::  same domain (as a set) and equal image at each domain point
  |=  [a=(list vpair) b=(list vpair)]
  ^-  ?
  ?.  =((lent a) (lent b))  |
  %+  levy  a
  |=  pa=vpair
  %+  lien  b
  |=  pb=vpair
  &((equal-norm d.pa d.pb) (equal-norm r.pa r.pb))
::
++  rec-equal
  ::  same key set, equal value per key (field-order independent)
  |=  [a=(list vfield) b=(list vfield)]
  ^-  ?
  ?.  =((lent a) (lent b))  |
  %+  levy  a
  |=  fa=vfield
  %+  lien  b
  |=  fb=vfield
  &(=(k.fa k.fb) (equal-norm v.fa v.fb))
::
::  +|  Normalization (representation-preserving canonical form)
::
++  normalize
  ::  idempotent: sets sorted+deduped, record fields sorted by key,
  ::  function pairs sorted by domain, every component normalized.
  ::  Intervals and tuples keep their representation (views, not eager).
  |=  v=value
  ^-  value
  ?-  -.v
    %bool   v
    %int    v
    %str    v
    %model  v
    %intv   v
    %seq  [%seq (turn p.v normalize)]
      %rec
    :-  %rec
    %+  sort  (turn p.v |=(f=vfield [k.f (normalize v.f)]))
    |=([x=vfield y=vfield] (strlth k.x k.y))
      %fcn
    :-  %fcn
    %+  sort  (turn p.v |=(pr=vpair [(normalize d.pr) (normalize r.pr)]))
    |=([x=vpair y=vpair] (vlth d.x d.y))
      %set
    ::  R2.7.2: `cls` survives normalization. Normalizing reorders and dedups
    ::  ELEMENTS; it does not change what the set was BUILT as, and resetting
    ::  it here would erase every class before it could be observed
    [%set cls.v (norm-set (turn p.v normalize))]
  ==
::
++  norm-set
  ::  elements already normalized: keep-first dedup by equality, then sort
  ::  into the private storage order
  |=  vs=(list value)
  ^-  (list value)
  =/  uniq
    |-  ^-  (list value)
    ?~  vs  ~
    ?:  (lien t.vs |=(x=value (equal-norm i.vs x)))
      $(vs t.vs)
    [i.vs $(vs t.vs)]
  (sort uniq vlth)
::
::  +|  Private Storage Order (total; distinct from TLC +compare)
::
++  vlth
  ::  a total strict order over normalized values, used only for stable
  ::  storage/dedup — NOT the (partial) TLC comparison operator
  |=  [a=value b=value]
  ^-  ?
  =/  ra  (kind-rank a)
  =/  rb  (kind-rank b)
  ?.  =(ra rb)  (lth ra rb)
  ?-  -.a
      %bool   &(?=(%bool -.b) &(!p.a p.b))
      %int
    ?:  ?=(%int -.b)   (slth p.a p.b)
    ?>  ?=(%intv -.b)  (slth p.a lo.b)
      %intv
    ?:  ?=(%int -.b)   (slth lo.a p.b)
    ?>  ?=(%intv -.b)  (slth lo.a lo.b)
      %str    ?>(?=(%str -.b) (strlth p.a p.b))
      %model  ?>(?=(%model -.b) (strlth p.a p.b))
      %seq  ?>(?=(%seq -.b) (list-lth p.a p.b))
      %set    ?>(?=(%set -.b) (list-lth p.a p.b))
      %rec    ?>(?=(%rec -.b) (rec-lth p.a p.b))
      %fcn    ?>(?=(%fcn -.b) (pair-lth p.a p.b))
  ==
::
++  list-lth
  ::  shorter first, then elementwise
  |=  [a=(list value) b=(list value)]
  ^-  ?
  ?.  =((lent a) (lent b))  (lth (lent a) (lent b))
  |-  ^-  ?
  ?~  a  |
  ?~  b  |
  ?:  (equal-norm i.a i.b)  $(a t.a, b t.b)
  (vlth i.a i.b)
::
++  rec-lth
  |=  [a=(list vfield) b=(list vfield)]
  ^-  ?
  ?.  =((lent a) (lent b))  (lth (lent a) (lent b))
  |-  ^-  ?
  ?~  a  |
  ?~  b  |
  ?.  =(k.i.a k.i.b)  (strlth k.i.a k.i.b)
  ?:  (equal-norm v.i.a v.i.b)  $(a t.a, b t.b)
  (vlth v.i.a v.i.b)
::
++  pair-lth
  |=  [a=(list vpair) b=(list vpair)]
  ^-  ?
  ?.  =((lent a) (lent b))  (lth (lent a) (lent b))
  |-  ^-  ?
  ?~  a  |
  ?~  b  |
  ?.  (equal-norm d.i.a d.i.b)  (vlth d.i.a d.i.b)
  ?:  (equal-norm r.i.a r.i.b)  $(a t.a, b t.b)
  (vlth r.i.a r.i.b)
::
::  +|  TLC Comparison Operator (partial: fails on incomparable values)
::
++  compare
  ::  the semantic `<`/`<=` order: only integers compare; everything else
  ::  is a typed failure (never a convenient Hoon total order). Returns
  ::  -1 | 0 | +1 or a diagnostic message.
  |=  [a=value b=value]
  ^-  (each @sd @t)
  ?:  ?&(?=(%int -.a) ?=(%int -.b))
    ?:  (equal-norm a b)  [%& --0]
    ?:  (slth p.a p.b)  [%& -1]
    [%& --1]
  [%| (rap 3 ~['Attempted to compare ' (type-name a) ' with ' (type-name b) '.'])]
::
::  +|  Rendering (matches tlc2 Value.toString / the REPL)
::
++  num-tape
  |=  m=@ud
  ^-  tape
  ?:  =(0 m)  "0"
  =|  acc=tape
  |-  ^-  tape
  ?:  =(0 m)  acc
  $(m (div m 10), acc [(add '0' (mod m 10)) acc])
::
++  render-int
  ::  plain decimal, no dot grouping (Hoon's scow %ud would insert dots)
  |=  n=@sd
  ^-  tape
  =/  o  (old:si n)
  ?:(-.o (num-tape +.o) ['-' (num-tape +.o)])
::
++  join-commas
  |=  ts=(list tape)
  ^-  tape
  ?~  ts  ~
  ?~  t.ts  i.ts
  (weld i.ts (weld ", " $(ts t.ts)))
::
++  render
  |=  v=value
  ^-  tape
  ?-  -.v
    %bool   ?:(p.v "TRUE" "FALSE")
    %int    (render-int p.v)
    %str    :(weld (trip '"') (esc-str p.v) (trip '"'))
    %model  (trip p.v)
    ::  tlc2's IntervalValue renders an empty interval as the empty set
    %intv   ?:((slth hi.v lo.v) (trip '{}') "{(render-int lo.v)}..{(render-int hi.v)}")
      %seq
    "<<{(join-commas (turn p.v render))}>>"
      %set
    =/  es  (turn (norm-set (turn p.v normalize)) render)
    "\{{(join-commas es)}}"
      %rec
    "[{(join-commas (turn (sort-fields p.v) render-field))}]"
      %fcn
    (render-fcn p.v)
  ==
::
++  esc-str
  ::  TLC re-escapes the double quote in a string body
  |=  s=@t
  ^-  tape
  %-  zing
  %+  turn  (trip s)
  |=(c=@tD ?:(=('"' c) "\\\"" ~[c]))
::
++  sort-fields
  |=  fs=(list vfield)
  ^-  (list vfield)
  (sort fs |=([x=vfield y=vfield] (strlth k.x k.y)))
::
++  render-field
  |=  f=vfield
  ^-  tape
  "{(trip k.f)} |-> {(render v.f)}"
::
++  render-fcn
  ::  a function renders as a tuple (contiguous 1..n domain), a record
  ::  (all-string domain), or the (d :> v @@ …) form otherwise
  |=  ps=(list vpair)
  ^-  tape
  ?:  =(~ ps)  "<<>>"
  ?:  (contiguous ps)
    "<<{(join-commas (turn ps |=(pr=vpair (render r.pr))))}>>"
  ?:  (levy ps |=(pr=vpair ?=(%str -.d.pr)))
    =/  fs  (turn ps |=(pr=vpair `vfield`[?>(?=(%str -.d.pr) p.d.pr) r.pr]))
    "[{(join-commas (turn (sort-fields fs) render-field))}]"
  ::  tlc2 parenthesizes this form: `(2 :> 1 @@ 3 :> 1)`
  =/  sorted  (sort ps |=([x=vpair y=vpair] (vlth d.x d.y)))
  =/  body
    %+  roll  sorted
    |=  [pr=vpair acc=tape]
    =/  piece  "{(render d.pr)} :> {(render r.pr)}"
    ?~(acc piece "{acc} @@ {piece}")
  "({body})"
::
++  contiguous
  ::  domain is exactly 1..n in order
  |=  ps=(list vpair)
  ^-  ?
  =|  i=@sd
  =.  i  --1
  |-  ^-  ?
  ?~  ps  &
  ?.  &(?=(%int -.d.i.ps) =(i p.d.i.ps))  |
  $(ps t.ps, i (sum:si i --1))
::
::  +|  Constructors (convenience)
::
++  vin   |=(n=@ud `value`[%int (sun:si n)])
++  vni   |=(n=@sd `value`[%int n])
++  vb    |=(b=? `value`[%bool b])
++  vs    |=(s=@t `value`[%str s])
++  vm    |=(m=@t `value`[%model m])
++  vintv-c  |=([lo=@sd hi=@sd] `value`[%intv lo hi])
++  vset-c   |=(l=(list value) `value`[%set %set-enum l])
++  vseq-c   |=(l=(list value) `value`[%seq l])
++  vrec-c   |=(l=(list vfield) `value`[%rec l])
++  vfcn-c   |=(l=(list vpair) `value`[%fcn l])
::
::  +|  Composite Access: application and DOMAIN (unit 6.2)
::
::  a typed evaluation failure (unit 6.8 refines the EC-coded shape); vres
::  is a value or such a failure
+$  eval-err  [code=@ud msg=@t]
+$  vres      (each value eval-err)
::
++  idx-of
  ::  a 1-based positive-integer index as @ud (0 = not a positive int)
  |=  x=value
  ^-  @ud
  ?.  ?=(%int -.x)  0
  =/  o  (old:si p.x)
  ?.(-.o 0 +.o)
::
++  find-image
  ::  the image of x under function pairs (domain compared with +equal)
  |=  [ps=(list vpair) x=value]
  ^-  (unit value)
  ?~  ps  ~
  ?:  (equal d.i.ps x)  `r.i.ps
  $(ps t.ps)
::
++  int-dom-msg
  ::  tlc2's wording when a function whose domain is all integers is applied to
  ::  a non-integer (FcnRcdValue.apply, measured at the pin)
  |=  x=value
  ^-  @t
  %^  cat  3
    'Attempted to apply function with integer domain to the non-integer argument '
  (crip (render x))
::
++  apply-oob
  ::  the out-of-domain failure text. tlc2 has THREE wordings here, measured at
  ::  the pin, and which one appears depends on the function's value class and
  ::  on the argument:
  ::
  ::    [i \in 1..3 |-> i][9]   FcnLambdaValue  In applying the function …
  ::    F == […]  F[9]          FcnRcdValue     Attempted to apply function: …
  ::    F["x"]                  FcnRcdValue     …with integer domain to the non-integer…
  ::
  ::  The class split is the same one +kind-of:check reads off the expression:
  ::  a lambda form stays lazy in tlc2, a definition's value is normalized
  |=  [f=value x=value lam=?]
  ^-  @t
  ?:  &(!lam ?=(%fcn -.f) (int-domain f) !?=(%int -.x))
    (int-dom-msg x)
  ?:  lam
    %^  cat  3  'In applying the function '
    %^  cat  3  (crip (render f))
    %^  cat  3  ', the first argument is: '
    %^  cat  3  (crip (render x))
    ' which is not in its domain.'
  %^  cat  3  'Attempted to apply function: '
  %^  cat  3  (crip (render f))
  %^  cat  3  ' to argument '
  %^  cat  3  (crip (render x))
  ', which is not in the domain of the function.'
::
++  int-domain
  ::  every domain point of a function is an integer
  |=  f=value
  ^-  ?
  ?.  ?=(%fcn -.f)  |
  (levy p.f |=(pr=vpair ?=(%int -.d.pr)))
::
++  apply
  ::  f[x]: function, tuple (integer index), or record (string field).
  ::  `lam` says the function EXPRESSION was a lambda form (a function
  ::  constructor or recursive spec) rather than something already reduced to a
  ::  value: tlc2 keeps the former as a FcnLambdaValue and the latter as a
  ::  FcnRcdValue, and the two classes word an out-of-domain failure
  ::  differently (R1.4.5, measured at the pin -- see +apply-oob)
  |=  [f=value x=value lam=?]
  ^-  vres
  ?-  -.f
      %fcn
    =/  hit  (find-image p.f x)
    ?~  hit  [%| 0 (apply-oob f x lam)]
    [%& u.hit]
      %seq
    =/  i  (idx-of x)
    ?:  |(=(0 i) (gth i (lent p.f)))
      ::  a tuple IS a function with an integer domain, so a non-integer
      ::  selector takes the integer-domain wording, not the index one
      ?:  =(0 (idx-of x))
        [%| 0 (int-dom-msg x)]
      :-  %|
      :-  0
      %^  cat  3  'Attempted to access index '
      %^  cat  3  (crip (render x))
      %^  cat  3  ' of tuple '
      %^  cat  3  (crip (render f))
      ' which is out of bounds.'
    [%& (snag (dec i) p.f)]
      %rec
    ?.  ?=(%str -.x)  [%| 0 'applying a record to a non-string selector']
    =/  hit  (skim p.f |=(fd=vfield =(k.fd p.x)))
    ?~  hit  [%| 0 (rap 3 ~['record has no field ' p.x])]
    [%& v.i.hit]
      %intv
    ::  an interval is a set, not a function
    [%| 0 'applying a set as a function']
    %bool   [%| 0 'applying a boolean as a function']
    %int    [%| 0 'applying an integer as a function']
    %str    [%| 0 'applying a string as a function']
    %model  [%| 0 'applying a model value as a function']
    %set    [%| 0 'applying a set as a function']
  ==
::
++  domain
  ::  DOMAIN f: function domain (set), tuple domain (1..n), record fields
  |=  f=value
  ^-  vres
  ?-  -.f
    %fcn   [%& (normalize [%set %set-enum (turn p.f |=(pr=vpair d.pr))])]
    %seq   [%& [%intv --1 (sun:si (lent p.f))]]
    %rec   [%& (normalize [%set %set-enum (turn p.f |=(fd=vfield `value`[%str k.fd]))])]
    %bool  [%| 0 'DOMAIN of a boolean']
    %int   [%| 0 'DOMAIN of an integer']
    %str   [%| 0 'DOMAIN of a string']
    %model  [%| 0 'DOMAIN of a model value']
    %intv  [%| 0 'DOMAIN of a set']
    %set   [%| 0 'DOMAIN of a set']
  ==
::
::  +|  EXCEPT (unit 6.2)
::
::  A selector path is a list of already-evaluated selector values (a
::  function/record domain point, or a 1-based tuple index). tlc2's Tool
::  evaluates each clause of `[base EXCEPT !p1 = r1, !p2 = r2, ...]` in
::  source order: it resolves the path with +except-select (binding the
::  current value as `@` in the replacement), then rebuilds with
::  +except-put. Three select outcomes mirror Value.select/Tool.OPCODE_exc:
::    %|          a hard failure — applying EXCEPT to a non-function, or a
::                wrong-typed selector (propagates, aborts evaluation).
::    [%& ~]      a miss — some path step is out of domain: the whole clause
::                is skipped and TLC warns TLC_EXCEPT_APPLIED_TO_UNKNOWN_FIELD.
::    [%& `old]   a hit — `old` is the value at the path (bound as `@`).
::  Clause folding and `@`/replacement evaluation are wired by the 6.5
::  evaluator; +except-put is only reached on a hit, so every step is
::  present and structural sharing keeps earlier values immutable.
::
+$  sel-res  (each (unit value) eval-err)
::
++  except-nonfcn
  |=  base=value
  ^-  sel-res
  :-  %|
  :-  0
  (rap 3 ~['Attempted to apply EXCEPT construct to the value ' (crip (render base)) '.'])
::
++  sel-step
  ::  one path step: the child at selector `sel` in `base`
  |=  [base=value sel=value]
  ^-  sel-res
  ?-  -.base
      %fcn   [%& (find-image p.base sel)]
      %seq
    ?.  ?=(%int -.sel)
      :-  %|
      :-  0
      (rap 3 ~['Attempted to access tuple at a non integral index: ' (crip (render sel))])
    =/  i  (idx-of sel)
    ?:  |(=(0 i) (gth i (lent p.base)))  [%& ~]
    [%& `(snag (dec i) p.base)]
      %rec
    ?.  ?=(%str -.sel)
      :-  %|
      :-  0
      (rap 3 ~['Attempted to access record by a non-string argument: ' (crip (render sel))])
    =/  hit  (skim p.base |=(fd=vfield =(k.fd p.sel)))
    ?~(hit [%& ~] [%& `v.i.hit])
  ::
    %intv   (except-nonfcn base)
    %set    (except-nonfcn base)
    %bool   (except-nonfcn base)
    %int    (except-nonfcn base)
    %str    (except-nonfcn base)
    %model  (except-nonfcn base)
  ==
::
++  except-select
  ::  resolve a selector path to its current value (the `@` binding), a
  ::  miss (skip the clause), or a hard failure
  |=  [base=value path=(list value)]
  ^-  sel-res
  ?~  path  [%& `base]
  =/  step  (sel-step base i.path)
  ?-  -.step
    %|  step
    %&  ?~(p.step [%& ~] $(base u.p.step, path t.path))
  ==
::
++  except-put
  ::  rebuild `base` with the value at `path` replaced by `rhs` (tlc2
  ::  takeExcept); a step that does not match leaves `base` unchanged
  |=  [base=value path=(list value) rhs=value]
  ^-  value
  ?~  path  rhs
  ?-  -.base
      %fcn
    :-  %fcn
    %+  turn  p.base
    |=  pr=vpair
    ?.  (equal d.pr i.path)  pr
    [d.pr (except-put r.pr t.path rhs)]
      %seq
    =/  i  (idx-of i.path)
    ?:  |(=(0 i) (gth i (lent p.base)))  base
    =/  old  (snag (dec i) p.base)
    [%seq (snap p.base (dec i) (except-put old t.path rhs))]
      %rec
    :-  %rec
    %+  turn  p.base
    |=  fd=vfield
    ?.  &(?=(%str -.i.path) =(k.fd p.i.path))  fd
    [k.fd (except-put v.fd t.path rhs)]
  ::
    %intv   base
    %set    base
    %bool   base
    %int    base
    %str    base
    %model  base
  ==
::
::  +|  Model Values (unit 6.2)
::
::  A model value carries a name (its `%model` payload). Following tlc2
::  ModelValue, a name longer than two characters whose second character is
::  `_` is TYPED with type = its first character; every other name is
::  untyped (type 0). Structural +equal is total (same name = equal) so
::  model values sit in sets/domains without error; the typed-comparison
::  failures surface only at the semantic `=` (+val-eq) and `\in` (+member).
::
++  mv-type
  |=  name=@t
  ^-  @
  =/  s  (trip name)
  ?.  (gth (lent s) 2)  0
  ?.  =('_' (snag 1 s))  0
  (snag 0 s)
::
++  val-eq
  ::  the semantic `=` operator: +equal, plus tlc2's typed model errors
  |=  [a=value b=value]
  ^-  (each ? eval-err)
  ?:  ?&(?=(%model -.a) ?=(%model -.b))
    =/  ta  (mv-type p.a)
    =/  tb  (mv-type p.b)
    ?:  |(=(0 ta) =(0 tb) =(ta tb))  [%& =(p.a p.b)]
    :-  %|
    :-  0
    (rap 3 ~['Attempted to check equality of the differently-typed model values ' p.a ' and ' p.b '.'])
  ?:  &(?=(%model -.a) !=(0 (mv-type p.a)))
    [%| 0 (rap 3 ~['Attempted to check equality of typed model value ' p.a ' and non-model value ' (crip (render b)) '.'])]
  ?:  &(?=(%model -.b) !=(0 (mv-type p.b)))
    [%| 0 (rap 3 ~['Attempted to check equality of typed model value ' p.b ' and non-model value ' (crip (render a)) '.'])]
  [%& (equal a b)]
::
++  member
  ::  the semantic `\in` over a set or interval, surfacing typed model errors
  |=  [x=value s=value]
  ^-  (each ? eval-err)
  ?.  (set-like s)
    [%| 0 (rap 3 ~['Attempted to check membership in the non-set value ' (crip (render s)) '.'])]
  =/  es  (set-elems s)
  |-  ^-  (each ? eval-err)
  ?~  es  [%& |]
  =/  r  (val-eq x i.es)
  ?-  -.r
    %|  r
    %&  ?:(p.r [%& &] $(es t.es))
  ==
::
::  +|  Canonical Constructors With Duplicate Detection (unit 6.2)
::
++  find-dup-key
  |=  fs=(list vfield)
  ^-  (unit @t)
  ?~  fs  ~
  ?:  (lien t.fs |=(f=vfield =(k.f k.i.fs)))  `k.i.fs
  $(fs t.fs)
::
++  find-dup-dom
  |=  ps=(list vpair)
  ^-  (unit value)
  ?~  ps  ~
  ?:  (lien t.ps |=(pr=vpair (equal d.pr d.i.ps)))  `d.i.ps
  $(ps t.ps)
::
++  mk-rec
  ::  canonical record; a repeated field name is a typed failure (tlc2
  ::  RecordValue.normalize)
  |=  fs=(list vfield)
  ^-  vres
  =/  dup  (find-dup-key fs)
  ?~  dup  [%& (normalize [%rec fs])]
  [%| 0 (rap 3 ~['Field name ' u.dup ' occurs multiple times in record.'])]
::
++  mk-fcn
  ::  canonical function; a repeated domain point is a typed failure (tlc2
  ::  FcnRcdValue.normalize)
  |=  ps=(list vpair)
  ^-  vres
  =/  dup  (find-dup-dom ps)
  ?~  dup  [%& (normalize [%fcn ps])]
  [%| 0 (rap 3 ~['The value ' (crip (render u.dup)) ' occurs multiple times in the function domain.'])]
::
::  +|  Finite Enumeration And Lazy Sets (unit 6.3)
::
::  A `sexp` is a lazy finite-set descriptor. Its operands are ordinary
::  `value`s (already-evaluated sets/intervals): a lazy set used as an
::  operand of another is forced to an eager `%set` first, so `sexp` is a
::  FLAT (non-recursive) union and the cursor never nests — sidestepping the
::  zuse-408 recursive-mold hazard entirely. TLC keeps these lazy (Subset/
::  Union/SetOfFcns/…Value); we mirror the observable enumeration ORDER and
::  keep membership/emptiness lazy, forcing to a normalized `%set` only when
::  a lazy set must become a value element, be rendered, or be fingerprinted.
::
+$  sexp
  $%  [%set s=value]                     ::  explicit set / interval
      [%cup a=value b=value]             ::  S \cup T
      [%cap a=value b=value]             ::  S \cap T
      [%diff a=value b=value]            ::  S \ T
      [%union s=value]                   ::  UNION S  (S a set of sets)
      [%prod ss=(list value)]            ::  S1 \X ... \X Sn  (set of tuples)
      [%fcns dom=value rng=value]        ::  [D -> R]
      [%rcds fs=(list [k=@t s=value])]   ::  [a: S, b: T, ...]
      [%subset s=value]                  ::  SUBSET S
      ::  the infinite StandardModule sets (units 6C.2, 6C.3). tlc2
      ::  represents them as UserValues whose `member` is structural and
      ::  whose `isFinite` is false: membership and \subseteq work,
      ::  enumeration does not
      [%nats ~]                          ::  Naturals!Nat
      [%ints ~]                          ::  Integers!Int
      [%seqs s=value]                    ::  Sequences!Seq(S)
  ==
::  one enumeration step: an element, or exhaustion
+$  estep  $%  [%item v=value]  [%done ~]  ==
::  a resumable, jam-safe enumeration cursor (WU1 continuation state). Every
::  sub-enumeration is a finite value's element list, so the cursor is flat.
+$  ecur
  $%  ::  a precomputed ordered element list at index `i` (linear
      ::  constructors: explicit set, interval, cup, cap, diff, union)
      [%elems es=(list value) i=@ud]
      ::  an odometer over per-dimension element lists (exponential
      ::  constructors: product, set-of-functions, set-of-records);
      ::  rightmost dimension varies fastest, matching TLC
      $:  %odo
          dims=(list (list value))
          ix=(list @ud)
          mk=?(%tuple %fcn %rec)
          dom=(list value)                ::  %fcn: domain points, in order
          ks=(list @t)                    ::  %rec: field names, in order
          done=?
      ==
      ::  SUBSET S in TLC cardinality order: {}, singletons, pairs, …, S
      [%subset es=(list value) k=@ud comb=(list @ud) done=?]
  ==
::  the largest domain we materialize; larger is a typed non-enumerable
::  overflow rather than a hang or silent truncation
++  max-card  1.000.000
::
::  +|  Enumeration Helpers
::
++  elemsof-e
  ::  the normalized element list of a set-like value, else a typed
  ::  non-enumerable failure
  |=  v=value
  ^-  (each (list value) eval-err)
  ?.  (set-like v)
    [%| 0 (rap 3 ~['Attempted to enumerate the non-enumerable value ' (crip (render v)) '.'])]
  [%& (set-elems (normalize v))]
::
++  elemsof-all
  ::  elemsof-e over each operand, short-circuiting on the first failure
  |=  vs=(list value)
  ^-  (each (list (list value)) eval-err)
  =|  acc=(list (list value))
  |-  ^-  (each (list (list value)) eval-err)
  ?~  vs  [%& (flop acc)]
  =/  r  (elemsof-e i.vs)
  ?:  ?=(%| -.r)  r
  $(vs t.vs, acc [p.r acc])
::
++  memb
  ::  structural membership of x in a set-like value (equality-based)
  |=  [x=value s=value]
  ^-  ?
  (lien (set-elems s) |=(e=value (equal x e)))
::
::  +|  Cursor Construction (sexp -> ecur)
::
++  enum
  |=  x=sexp
  ^-  (each ecur eval-err)
  ?-  -.x
      %set
    =/  r  (elemsof-e s.x)
    ?:  ?=(%| -.r)  r
    [%& %elems p.r 0]
  ::
      %cup
    =/  ra  (elemsof-e a.x)
    ?:  ?=(%| -.ra)  ra
    =/  rb  (elemsof-e b.x)
    ?:  ?=(%| -.rb)  rb
    [%& %elems (weld p.ra p.rb) 0]
  ::
      %cap
    =/  ra  (elemsof-e a.x)
    ?:  ?=(%| -.ra)  ra
    ?.  (set-like b.x)
      [%| 0 (rap 3 ~['Attempted to enumerate the non-enumerable value ' (crip (render b.x)) '.'])]
    [%& %elems (skim p.ra |=(e=value (memb e b.x))) 0]
  ::
      %diff
    =/  ra  (elemsof-e a.x)
    ?:  ?=(%| -.ra)  ra
    [%& %elems (skim p.ra |=(e=value !(memb e b.x))) 0]
  ::
      %union
    =/  rs  (elemsof-e s.x)
    ?:  ?=(%| -.rs)  rs
    =/  rd  (elemsof-all p.rs)
    ?:  ?=(%| -.rd)  rd
    [%& %elems (zing p.rd) 0]
  ::
      %prod
    =/  rd  (elemsof-all ss.x)
    ?:  ?=(%| -.rd)  rd
    =/  done  (lien p.rd |=(d=(list value) ?=(~ d)))
    [%& %odo p.rd (reap (lent p.rd) 0) %tuple ~ ~ done]
  ::
      %fcns
    =/  rr  (elemsof-e rng.x)
    ?:  ?=(%| -.rr)  rr
    =/  rd  (elemsof-e dom.x)
    ?:  ?=(%| -.rd)  rd
    =/  dims  (reap (lent p.rd) p.rr)
    =/  done  &(!=(0 (lent p.rd)) =(0 (lent p.rr)))
    [%& %odo dims (reap (lent p.rd) 0) %fcn p.rd ~ done]
  ::
      %rcds
    =/  ks  (turn fs.x |=(f=[k=@t s=value] k.f))
    =/  rd  (elemsof-all (turn fs.x |=(f=[k=@t s=value] s.f)))
    ?:  ?=(%| -.rd)  rd
    =/  done  (lien p.rd |=(d=(list value) ?=(~ d)))
    [%& %odo p.rd (reap (lent p.rd) 0) %rec ~ ks done]
  ::
      %subset
    =/  r  (elemsof-e s.x)
    ?:  ?=(%| -.r)  r
    [%& %subset p.r 0 ~ |]
  ::
    %nats  [%| (non-enumerable 'Nat')]
    %ints  [%| (non-enumerable 'Int')]
    %seqs  [%| (non-enumerable (crip (seqs-name s.x)))]
  ==
::
++  seqs-name
  ::  Sequences.toString for the unbounded case
  |=  s=value
  ^-  tape
  ;:(weld "Seq(" (render s) ")")
::
++  sexp-name
  ::  how tlc2 renders a lazy set that has no value form (the infinite
  ::  UserValues); "" for the ordinary constructions, which do have one
  |=  x=sexp
  ^-  tape
  ?+  -.x  ""
    %nats  "Nat"
    %ints  "Int"
    %seqs  (seqs-name s.x)
  ==
::
++  infinite
  ::  the descriptors tlc2 reports as not finite (UserObj.isFinite false)
  |=  x=sexp
  ^-  ?
  ?=(?(%nats %ints %seqs) -.x)
::
++  non-enumerable
  ::  tlc2 refuses to enumerate an infinite UserObj set (isFinite false):
  ::  membership and \subseteq are answered structurally, quantification
  ::  and materialization are errors
  |=  nm=@t
  ^-  eval-err
  :-  0
  (rap 3 ~['Attempted to enumerate the non-enumerable set ' nm '.'])
::
::  +|  Stepping The Cursor
::
++  odo-current
  ::  the value picked in each dimension at the current index vector
  |=  [dims=(list (list value)) ix=(list @ud)]
  ^-  (list value)
  ?~  dims  ~
  ?~  ix  ~
  [(snag i.ix i.dims) $(dims t.dims, ix t.ix)]
::
++  odo-advance
  ::  advance ix as an odometer over dims; the rightmost digit is fastest
  ::  (matching tlc2's SetOfTuples/Fcns/Rcds enumerators)
  |=  [dims=(list (list value)) ix=(list @ud)]
  ^-  [ix=(list @ud) done=?]
  ?~  ix  [~ &]
  ?~  dims  [~ &]
  =/  sub  $(ix t.ix, dims t.dims)
  ?.  done.sub  [[i.ix ix.sub] |]
  =/  ni  +(i.ix)
  ?:  (lth ni (lent i.dims))
    [[ni (reap (lent t.ix) 0)] |]
  [[0 (reap (lent t.ix) 0)] &]
::
++  zip-vp
  |=  [ds=(list value) vs=(list value)]
  ^-  (list vpair)
  ?~  ds  ~
  ?~  vs  ~
  [[i.ds i.vs] $(ds t.ds, vs t.vs)]
::
++  zip-vf
  |=  [ks=(list @t) vs=(list value)]
  ^-  (list vfield)
  ?~  ks  ~
  ?~  vs  ~
  [[i.ks i.vs] $(ks t.ks, vs t.vs)]
::
++  odo-build
  |=  [mk=?(%tuple %fcn %rec) dom=(list value) ks=(list @t) cells=(list value)]
  ^-  value
  ?-  mk
    %tuple  [%seq cells]
    %fcn    (normalize [%fcn (zip-vp dom cells)])
    %rec    (normalize [%rec (zip-vf ks cells)])
  ==
::
++  next-comb
  ::  the lexicographically next k-combination of 0..n-1 after `comb`, or ~
  ::  when `comb` is the last (largest) k-combination
  |=  [n=@ud k=@ud comb=(list @ud)]
  ^-  (unit (list @ud))
  ?:  =(k 0)  ~
  =/  maxv  (sub n k)
  =/  found=(unit @ud)  ~
  =.  found
    =/  i  0
    |-  ^-  (unit @ud)
    ?:  =(i k)  found
    =?  found  (lth (snag i comb) (add i maxv))  `i
    $(i +(i))
  ?~  found  ~
  =/  fv  +((snag u.found comb))
  :-  ~
  %+  turn  (gulf 0 (dec k))
  |=  j=@ud
  ?:  (lth j u.found)  (snag j comb)
  (add fv (sub j u.found))
::
++  subset-advance
  ::  step SUBSET enumeration: cardinality k ascending, each k in lex order
  |=  [n=@ud k=@ud comb=(list @ud)]
  ^-  [k=@ud comb=(list @ud) done=?]
  ?:  =(k 0)
    ?:  =(n 0)  [1 ~ &]
    [1 ~[0] |]
  =/  nxt  (next-comb n k comb)
  ?^  nxt  [k u.nxt |]
  ?:  (gth +(k) n)  [+(k) ~ &]
  [+(k) (gulf 0 k) |]
::
++  enum-next
  ::  one bounded step; returns the element (or exhaustion) and the resumed
  ::  cursor. Cursor state is a flat jam-safe noun (WU1 save/load).
  |=  cur=ecur
  ^-  [estep ecur]
  ?-  -.cur
      %elems
    ?:  (gte i.cur (lent es.cur))  [[%done ~] cur]
    [[%item (snag i.cur es.cur)] cur(i +(i.cur))]
  ::
      %odo
    ?:  done.cur  [[%done ~] cur]
    =/  cells  (odo-current dims.cur ix.cur)
    =/  item   (odo-build mk.cur dom.cur ks.cur cells)
    =/  adv    (odo-advance dims.cur ix.cur)
    [[%item item] cur(ix ix.adv, done done.adv)]
  ::
      %subset
    ?:  done.cur  [[%done ~] cur]
    =/  item  (normalize [%set %set-enum (turn comb.cur |=(j=@ud (snag j es.cur)))])
    =/  adv   (subset-advance (lent es.cur) k.cur comb.cur)
    [[%item item] cur(k k.adv, comb comb.adv, done done.adv)]
  ==
::
::  +|  Cardinality Bound, Force, And Test Projection
::
++  cap-mul
  ::  a*b, saturating just past max-card so overflow is detectable
  |=  [a=@ud b=@ud]
  ^-  @ud
  =/  p  (mul a b)
  ?:((gth p max-card) +(max-card) p)
::
++  cur-bound
  ::  an upper bound on the cursor's element count (exact for odo/subset),
  ::  or a typed overflow for an unmanageably large domain
  |=  c=ecur
  ^-  (each @ud eval-err)
  ?-  -.c
      %elems   [%& (lent es.c)]
      %odo
    =/  lens  (turn dims.c |=(d=(list value) (lent d)))
    =|  acc=@ud  =.  acc  1
    |-  ^-  (each @ud eval-err)
    ?~  lens  [%& acc]
    $(lens t.lens, acc (cap-mul acc i.lens))
  ::
      %subset
    ?:  (gth (lent es.c) 20)
      [%| 0 'SUBSET argument too large to enumerate.']
    [%& (bex (lent es.c))]
  ==
::
++  reducible
  ::  R2.7.16: tlc2's `Reducible`, and it is the WHOLE of the representation
  ::  rule. The interface has exactly TWO implementors in the entire tree --
  ::  `IntervalValue` and `SetEnumValue` -- and every class decision in
  ::  `Tool.java`'s set operators, in `SetEnumValue`/`IntervalValue`'s own
  ::  `cup`/`cap`/`diff`, and in the function constructor's `isFcnRcd` is this
  ::  predicate applied to an operand and nothing else.
  ::
  ::  In port terms that is an `%intv`, or a `%set` whose class is `%set-enum`
  ::  -- which is why `+sexp-class` answering `%set-enum` has to MEAN
  ::  "Reducible" rather than merely "printed as SetEnumValue"
  |=  v=value
  ^-  ?
  ?+  -.v  |
    %intv  &
    %set   =(%set-enum cls.v)
  ==
::
++  empty-val
  ::  an empty set-like value. `SetEnumValue.cup` and `IntervalValue.cup` both
  ::  open `if (size == 0) return set;`, so an empty Reducible operand of
  ::  `\cup` makes the result the OTHER OPERAND ITSELF (R2.7.16)
  |=  v=value
  ^-  ?
  ?+  -.v  |
    %set   ?=(~ p.v)
    %intv  (slth hi.v lo.v)
  ==
::
++  union-eager
  ::  `UnionValue.union`: UNION S combines into a SetEnumValue only when S is
  ::  a SetEnumValue AND every element of S is a SetEnumValue. Measured, and
  ::  the asymmetry is real: the test is `instanceof SetEnumValue`, NOT
  ::  `instanceof Reducible`, so `UNION {1..2, 3..4}` -- whose elements are
  ::  INTERVALS, which are Reducible -- is a UnionValue at the pin while
  ::  `UNION {{1, 2}, {3}}` is a SetEnumValue
  |=  s=value
  ^-  ?
  ?.  ?=(%set -.s)  |
  ?.  =(%set-enum cls.s)  |
  (levy p.s |=(e=value ?:(?=(%set -.e) =(%set-enum cls.e) |)))
::
++  sexp-class
  ::  the tlc2 VALUE CLASS a lazy construction denotes (R2.7.2). This is the
  ::  class `EvalDump` prints and the one the port used to lose at `+force`.
  ::
  ::  `%set` PROPAGATES its operand's class rather than flattening it, which is
  ::  the rule the R1.3.8 residue recorded and a naive port gets wrong: the
  ::  class is not a property of the operator. `{x \in 1..6 : P}` is a
  ::  SetEnumValue at the pin while `{x \in (A \X B) : P}` is a SetPredValue --
  ::  same filter, different base
  ::
  ::  R2.7.16 makes this RECURSIVE on the operands' classes, which is what
  ::  R2.7.2 left unmeasured and R2.7.13 measured. Every rule below was read
  ::  off `Tool.java` AND confirmed against the pin, per operator, because the
  ::  three binary operators do NOT share one rule:
  ::
  ::    `\cup`   eager iff BOTH operands are Reducible -- `Tool` forces through
  ::             either one, but `SetEnumValue.cup`/`IntervalValue.cup` fall
  ::             back to a SetCupValue unless the OTHER is Reducible too
  ::    `\cap`   eager iff EITHER is (both `cap`s only need `member` on the
  ::             other side, so one Reducible operand is enough)
  ::    `\`      eager iff the LEFT is (`Tool` tests `arg1` alone)
  ::    UNION    `+union-eager`, which is a strictly narrower test
  ::
  ::  The unconditionally-lazy ones stay unconditional, measured over lazy
  ::  operands too: SUBSET, `\X`, `[D -> R]` and `[a: S]` keep their class
  ::  whatever they are built from
  |=  x=sexp
  ^-  @tas
  ?-  -.x
    %set     ?:(?=(%set -.s.x) cls.s.x %set-enum)
    %subset  %subset
    %prod    %prod
    %cup     ?:(&((reducible a.x) (reducible b.x)) %set-enum %set-cup)
    %cap     ?:(|((reducible a.x) (reducible b.x)) %set-enum %set-cap)
    %diff    ?:((reducible a.x) %set-enum %set-diff)
    %union   ?:((union-eager s.x) %set-enum %union)
    ::  R2.7.2 left these UNMEASURED rather than guess a class. Measured now,
    ::  and they are their own classes unconditionally -- `[(1..2) -> (1..2)]`
    ::  is a SetOfFcnsValue at the pin even though both operands are Reducible
    %fcns    %fcns
    %rcds    %rcds
    ::  the infinite UserValues never reach `+force` (enumeration refuses
    ::  first), so these are unreachable rather than meaningful
    %nats    %set-enum
    %ints    %set-enum
    %seqs    %set-enum
  ==
::
++  force
  ::  materialize a lazy set into a normalized eager %set (the boundary at
  ::  which a lazy set must become a value); typed overflow if too large.
  ::  `lim` is the run's `max-set-size` (0 = `max-card`, the engine default,
  ::  which is tlc2's own 1,000,000). This is the port's `ValueVec
  ::  .ensureCapacity` -- measured at the pin, that is the site `-maxSetSize`
  ::  actually reaches, and it names the BOUND rather than the actual size
  |=  [x=sexp lim=@ud]
  ^-  (each value eval-err)
  ::  R2.7.16: `\cup` with an EMPTY Reducible operand returns the OTHER
  ::  OPERAND ITSELF -- both `SetEnumValue.cup` and `IntervalValue.cup` open
  ::  `if (size == 0) return set;` -- so the result keeps that operand's own
  ::  class, including IntervalValue, which no forced `%set` could carry.
  ::  `Tool` tests `arg1` first, so the order here is its order. Measured:
  ::  `{} \cup ((1..2) \X (1..2))` and `(1..0) \cup ((1..2) \X (1..2))` are
  ::  both SetOfTuplesValue at the pin, as are the two with the operands
  ::  swapped. This is the one place a class is not decided by `+sexp-class`,
  ::  because no forcing happens at all
  ?:  ?&(?=(%cup -.x) (reducible a.x) (empty-val a.x))  [%& b.x]
  ?:  ?&(?=(%cup -.x) (reducible b.x) (empty-val b.x))  [%& a.x]
  =/  cap  ?:(=(0 lim) max-card lim)
  =/  rc  (enum x)
  ?:  ?=(%| -.rc)  rc
  =/  bnd  (cur-bound p.rc)
  ?:  ?=(%| -.bnd)  bnd
  ?:  (gth p.bnd cap)
    [%| 0 (crip "Attempted to construct a set with too many elements (>{<cap>}).")]
  =|  acc=(list value)
  =/  cur  p.rc
  |-  ^-  (each value eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    ::  R2.7.2: the forced set remembers WHAT IT WAS. This is the boundary the
    ::  class used to be lost at -- the enumeration was always lazy, the
    ::  representation was not
    %done  [%& (normalize [%set (sexp-class x) acc])]
    %item  $(acc [v.es acc], cur +.st)
  ==
::
++  enum-tapes
  ::  render every element in ENUMERATION order (a test/inspection witness;
  ::  returns tapes so no value crosses a low-budget test core)
  |=  x=sexp
  ^-  (each (list tape) eval-err)
  =/  rc  (enum x)
  ?:  ?=(%| -.rc)  rc
  =|  acc=(list tape)
  =/  cur  p.rc
  |-  ^-  (each (list tape) eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& (flop acc)]
    %item  $(acc [(render v.es) acc], cur +.st)
  ==
::
::  +|  Lazy Membership And Emptiness (no materialization)
::
++  all-memb
  ::  each es.i is a structural member of the corresponding ss.i
  |=  [es=(list value) ss=(list value)]
  ^-  ?
  ?~  es  ?=(~ ss)
  ?~  ss  |
  ?:  (memb i.es i.ss)  $(es t.es, ss t.ss)
  |
::
++  set-empty
  ::  emptiness by one bounded step — never materializes the domain
  |=  x=sexp
  ^-  (each ? eval-err)
  ::  the infinite sets are never empty (Seq(S) always contains <<>>)
  ?:  ?=(?(%nats %ints %seqs) -.x)  [%& |]
  =/  rc  (enum x)
  ?:  ?=(%| -.rc)  rc
  =/  st  (enum-next p.rc)
  [%& ?=(%done -.-.st)]
::
++  set-member
  ::  lazy membership: decided structurally on the descriptor, never by
  ::  enumerating an exponential domain (mirrors tlc2's lazy member)
  |=  [e=value x=sexp]
  ^-  (each ? eval-err)
  ?-  -.x
    %set    [%& (memb e s.x)]
    %cup    [%& |((memb e a.x) (memb e b.x))]
    %cap    [%& &((memb e a.x) (memb e b.x))]
    %diff   [%& &((memb e a.x) !(memb e b.x))]
  ::
      %union
    =/  rs  (elemsof-e s.x)
    ?:  ?=(%| -.rs)  rs
    [%& (lien p.rs |=(m=value ?:((set-like m) (memb e m) |)))]
  ::
      %prod
    ?.  ?=(%seq -.e)  [%& |]
    [%& (all-memb p.e ss.x)]
  ::
      %fcns
    ?.  (fcn-like e)  [%& |]
    =/  ps  (fcn-pairs e)
    =/  dom-e  (normalize [%set %set-enum (turn ps |=(pr=vpair d.pr))])
    ?.  (equal dom-e dom.x)  [%& |]
    [%& (levy ps |=(pr=vpair (memb r.pr rng.x)))]
  ::
      %rcds
    ?.  ?=(%rec -.e)  [%& |]
    ?.  =((lent p.e) (lent fs.x))  [%& |]
    :-  %&
    %+  levy  fs.x
    |=  f=[k=@t s=value]
    =/  hit  (skim p.e |=(fd=vfield =(k.fd k.f)))
    ?~  hit  |
    (memb v.i.hit s.f)
  ::
      %subset
    ?.  (set-like e)  [%& |]
    [%& (levy (set-elems e) |=(el=value (memb el s.x)))]
  ::
    %nats  (int-set-member e 'Nat')
    %ints  (int-set-member e 'Int')
  ::
      %seqs
    ::  tlc2.module.Sequences.member: a sequence whose every element is in
    ::  the range; a non-sequence model value is not a member, anything
    ::  else is an error
    =/  tp  (to-tuple e)
    ?~  tp  (not-a-member e (crip (seqs-name s.x)))
    [%& (levy u.tp |=(el=value (memb el s.x)))]
  ==
::
++  sexp-subseteq
  ::  lazy `la \subseteq lb` over descriptors (tlc2 Value.isSubsetEq): stream
  ::  `la`, failing on the first element not in `lb`; membership in `lb` stays
  ::  lazy. Bounded by `max-card` so a genuinely large left set overflows rather
  ::  than hangs (the caller reduces SUBSET A \subseteq SUBSET B to A \subseteq B
  ::  first, so the powerset is never streamed here).
  |=  [la=sexp lb=sexp]
  ^-  (each ? eval-err)
  =/  rc  (enum la)
  ?:  ?=(%| -.rc)  rc
  =/  cur  p.rc
  =|  n=@ud
  |-  ^-  (each ? eval-err)
  ?:  (gth n max-card)  [%| 0 'Set too large to enumerate.']
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& &]
      %item
    =/  m  (set-member v.es lb)
    ?:  ?=(%| -.m)  m
    ?.  p.m  [%& |]
    $(cur +.st, n +(n))
  ==
::
++  not-a-member
  ::  the shared "is not even a candidate" branch of tlc2's UserObj.member
  |=  [e=value nm=@t]
  ^-  (each ? eval-err)
  ?:  ?=(%model -.e)
    ?.  =(0 (mv-type p.e))
      :-  %|
      :-  0
      %^  rap  3  'Attempted to check if the typed model value '
      ~[p.e ' is an element of\0a' nm]
    [%& |]
  :-  %|
  :-  2.158
  %^  rap  3  'Attempted to check if the value:\0a'
  ~[(crip (render e)) '\0ais an element of ' nm '.']
::
++  int-set-member
  ::  membership in Nat / Int, mirroring tlc2.module.Naturals.member: an
  ::  integer decides structurally, an untyped model value is not a member,
  ::  a typed model value and any other kind are errors
  |=  [e=value nm=@t]
  ^-  (each ? eval-err)
  ?:  ?=(%int -.e)
    [%& ?:(=(nm 'Int') & !(slth p.e --0))]
  (not-a-member e nm)
::
::  +|  Binders, Quantifiers, CHOOSE, Constructors, Control (unit 6.4)
::
::  These evaluate expression BODIES (a quantifier/filter predicate, a
::  set-of-all/function image, a CASE guard, an IF/CASE branch), which is the
::  6.5 semantic-node evaluator's job. So they are parameterized by Hoon
::  gates: the 6.5 evaluator supplies each gate as `|=(v (eval node ctx(x v)))`
::  over a jam-safe (node, context) pair, and the resumable state is the 6.3
::  cursor. Branch/guard gates are deferred (thunks) so only the SELECTED
::  branch is evaluated — unselected branches' errors are suppressed, as in
::  tlc2. Multiple/dependent binders (`\A x\in S, y\in T(x) : P`) are the
::  `(list cdom)` context enumerator; single-variable forms use the `sexp`
::  primitives directly.
::
+$  vpred   $-(value (each ? eval-err))        ::  single-binder predicate
+$  vmap    $-(value (each value eval-err))     ::  single-binder image
+$  vthunk  $-(~ (each value eval-err))         ::  a deferred value (branch)
+$  bthunk  $-(~ (each ? eval-err))             ::  a deferred boolean (guard)
+$  cpred   $-((list value) (each ? eval-err))  ::  multi-binder predicate
+$  cdom    $-((list value) (each sexp eval-err))  ::  prefix-dependent domain
+$  cmap    $-((list value) (each value eval-err)) ::  multi-binder image
::
::  +|  Streaming Primitives Over A Cursor
::
++  stream-find
  ::  the first element satisfying `p`, streamed (short-circuit); ~ if none
  |=  [x=sexp p=vpred]
  ^-  (each (unit value) eval-err)
  =/  rc  (enum x)
  ?:  ?=(%| -.rc)  rc
  =/  cur  p.rc
  |-  ^-  (each (unit value) eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& ~]
      %item
    =/  r  (p v.es)
    ?:  ?=(%| -.r)  r
    ?:  p.r  [%& `v.es]
    $(cur +.st)
  ==
::
++  stream-collect
  ::  fold every element: `f` returns ~ to drop or `x to keep x (in order)
  |=  [x=sexp f=$-(value (each (unit value) eval-err))]
  ^-  (each (list value) eval-err)
  =/  rc  (enum x)
  ?:  ?=(%| -.rc)  rc
  =|  acc=(list value)
  =/  cur  p.rc
  |-  ^-  (each (list value) eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& (flop acc)]
      %item
    =/  r  (f v.es)
    ?:  ?=(%| -.r)  r
    ?~  p.r  $(cur +.st)
    $(acc [u.p.r acc], cur +.st)
  ==
::
::  +|  Bounded Quantifiers And CHOOSE
::
++  ex-over
  ::  \E x \in S : P  — short-circuit on the first witness
  |=  [x=sexp p=vpred]
  ^-  (each ? eval-err)
  =/  r  (stream-find x p)
  ?:  ?=(%| -.r)  r
  [%& ?=(^ p.r)]
::
++  all-over
  ::  \A x \in S : P  — short-circuit on the first counterexample
  |=  [x=sexp p=vpred]
  ^-  (each ? eval-err)
  =/  r
    %+  stream-find  x
    |=(v=value =/(b (p v) ?:(?=(%| -.b) b [%& !p.b])))
  ?:  ?=(%| -.r)  r
  [%& ?=(~ p.r)]
::
++  choose-over
  ::  CHOOSE x \in S : P  — deterministic first satisfying element in TLC
  ::  enumeration order (stable across pause/resume: a pure fn of the
  ::  cursor); typed failure when no element satisfies P
  |=  [x=sexp p=vpred]
  ^-  (each value eval-err)
  =/  r  (stream-find x p)
  ?:  ?=(%| -.r)  r
  ?~  p.r
    [%| 0 'CHOOSE: no element of the domain satisfies the predicate.']
  [%& u.p.r]
::
::  +|  Enumerable Constructors ({x∈S:P}, {e:x∈S}, [x∈S|->e])
::
++  filter-over
  ::  {x \in S : P}  — streamed filter, normalized result set
  |=  [x=sexp p=vpred]
  ^-  (each value eval-err)
  =/  r
    %+  stream-collect  x
    |=  v=value
    ^-  (each (unit value) eval-err)
    =/  b  (p v)
    ?:  ?=(%| -.b)  b
    ?:(p.b [%& `v] [%& ~])
  ?:  ?=(%| -.r)  r
  ::  R2.7.2: a filter over a LAZY base is tlc2's SetPredValue; a filter over
  ::  an eager one is a plain SetEnumValue. Measured -- `{x \in ((1..2) \X
  ::  (1..2)) : TRUE}` is SetPredValue at the pin while `{x \in 1..6 : P}` is
  ::  SetEnumValue, which is why the class cannot be read off the OPERATOR and
  ::  has to be read off the base set
  =/  base  (sexp-class x)
  =/  cls  ?:(=(%set-enum base) %set-enum %set-pred)
  [%& (normalize [%set cls p.r])]
::
++  map-over
  ::  {e(x) : x \in S}  — streamed image, normalized (deduped) result set
  |=  [x=sexp f=vmap]
  ^-  (each value eval-err)
  =/  r
    %+  stream-collect  x
    |=  v=value
    ^-  (each (unit value) eval-err)
    =/  w  (f v)
    ?:(?=(%| -.w) w [%& `p.w])
  ?:  ?=(%| -.r)  r
  [%& (normalize [%set %set-enum p.r])]
::
++  fcn-over
  ::  [x \in S |-> e(x)]  — a function pairing each domain element with e
  |=  [x=sexp f=vmap]
  ^-  (each value eval-err)
  =/  rc  (enum x)
  ?:  ?=(%| -.rc)  rc
  =|  acc=(list vpair)
  =/  cur  p.rc
  |-  ^-  (each value eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& (normalize [%fcn (flop acc)])]
      %item
    =/  r  (f v.es)
    ?:  ?=(%| -.r)  r
    $(acc [[v.es p.r] acc], cur +.st)
  ==
::
::  +|  Multi-Binder Context Enumeration (dependent bounds)
::
++  ctx-go
  ::  visit bindings over ordered domains, streaming nested cursors; each
  ::  domain gate sees the prefix bound so far (dependent bounds). Returns
  ::  the first prefix whose completed binding satisfies `p`, else ~.
  |=  [ds=(list cdom) pre=(list value) p=cpred]
  ^-  (each (unit (list value)) eval-err)
  ?~  ds
    =/  r  (p pre)
    ?:  ?=(%| -.r)  r
    ?:  p.r  [%& `pre]  [%& ~]
  =/  rs  (i.ds pre)
  ?:  ?=(%| -.rs)  rs
  =/  rc  (enum p.rs)
  ?:  ?=(%| -.rc)  rc
  =/  cur  p.rc
  |-  ^-  (each (unit (list value)) eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& ~]
      %item
    =/  sub  (ctx-go t.ds (snoc pre v.es) p)
    ?:  ?=(%| -.sub)  sub
    ?^  p.sub  sub
    $(cur +.st)
  ==
::
++  ctx-map
  ::  {e(x1, …, xk) : x1 \in S1, x2 \in S2(x1), …} — the multi-binder analogue
  ::  of +map-over: every binding is visited (no short-circuit) and mapped,
  ::  results collected in visit order. The caller normalizes, so visit order
  ::  is not observable in the result set
  |=  [ds=(list cdom) pre=(list value) f=cmap]
  ^-  (each (list value) eval-err)
  ?~  ds
    =/  r  (f pre)
    ?:  ?=(%| -.r)  r
    [%& ~[p.r]]
  =/  rs  (i.ds pre)
  ?:  ?=(%| -.rs)  rs
  =/  rc  (enum p.rs)
  ?:  ?=(%| -.rc)  rc
  =|  acc=(list (list value))
  =/  cur  p.rc
  |-  ^-  (each (list value) eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& (zing (flop acc))]
      %item
    =/  sub  (ctx-map t.ds (snoc pre v.es) f)
    ?:  ?=(%| -.sub)  sub
    $(acc [p.sub acc], cur +.st)
  ==
::
++  ctx-fcn
  ::  [x1 \in S1, x2 \in S2, … |-> e] — one pair per binding, the binding
  ::  TUPLE being the domain point, exactly as tlc2 keys a multi-binder
  ::  function. The caller normalizes the pairs into storage order
  |=  [ds=(list cdom) pre=(list value) f=cmap]
  ^-  (each (list vpair) eval-err)
  ?~  ds
    =/  r  (f pre)
    ?:  ?=(%| -.r)  r
    [%& ~[[[%seq pre] p.r]]]
  =/  rs  (i.ds pre)
  ?:  ?=(%| -.rs)  rs
  =/  rc  (enum p.rs)
  ?:  ?=(%| -.rc)  rc
  =|  acc=(list (list vpair))
  =/  cur  p.rc
  |-  ^-  (each (list vpair) eval-err)
  =/  st  (enum-next cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& (zing (flop acc))]
      %item
    =/  sub  (ctx-fcn t.ds (snoc pre v.es) f)
    ?:  ?=(%| -.sub)  sub
    $(acc [p.sub acc], cur +.st)
  ==
::
++  ex-ctx
  ::  \E x1\in S1, x2\in S2(x1), … : P
  |=  [ds=(list cdom) p=cpred]
  ^-  (each ? eval-err)
  =/  r  (ctx-go ds ~ p)
  ?:  ?=(%| -.r)  r
  [%& ?=(^ p.r)]
::
++  all-ctx
  ::  \A x1\in S1, x2\in S2(x1), … : P
  |=  [ds=(list cdom) p=cpred]
  ^-  (each ? eval-err)
  =/  r
    %^  ctx-go  ds  ~
    |=(pre=(list value) =/(b (p pre) ?:(?=(%| -.b) b [%& !p.b])))
  ?:  ?=(%| -.r)  r
  [%& ?=(~ p.r)]
::
::  +|  Control: IF, CASE, Conjunction/Disjunction Lists
::
++  if-val
  ::  IF c THEN t ELSE e — only the taken branch is evaluated
  |=  [c=value t=vthunk e=vthunk]
  ^-  (each value eval-err)
  ?.  ?=(%bool -.c)
    [%| 0 (rap 3 ~['A non-boolean was used as an IF guard: ' (crip (render c)) '.'])]
  ?:(p.c (t ~) (e ~))
::
++  case-val
  ::  CASE — guards evaluated in order (lazily), first true guard's body is
  ::  the result; else OTHER; else a typed "no case" failure. Unselected
  ::  bodies are never evaluated, so their errors are suppressed.
  |=  [arms=(list [g=bthunk b=vthunk]) other=(unit vthunk)]
  ^-  (each value eval-err)
  |-  ^-  (each value eval-err)
  ?~  arms
    ?~  other
      [%| 0 'CASE: no OTHER case, and no guard evaluated to TRUE.']
    (u.other ~)
  =/  gr  (g.i.arms ~)
  ?:  ?=(%| -.gr)  gr
  ?:  p.gr  (b.i.arms ~)
  $(arms t.arms)
::
++  conj-list
  ::  /\ list — short-circuit on the first FALSE; later errors suppressed
  |=  cs=(list bthunk)
  ^-  (each ? eval-err)
  ?~  cs  [%& &]
  =/  r  (i.cs ~)
  ?:  ?=(%| -.r)  r
  ?.  p.r  [%& |]
  $(cs t.cs)
::
++  disj-list
  ::  \/ list — short-circuit on the first TRUE; later errors suppressed
  |=  cs=(list bthunk)
  ^-  (each ? eval-err)
  ?~  cs  [%& |]
  =/  r  (i.cs ~)
  ?:  ?=(%| -.r)  r
  ?:  p.r  [%& &]
  $(cs t.cs)
::
::  +|  Canonical FP64 Input Bytes (unit 6.8)
::
::  The exact byte stream tlc2 folds into FP64 for a value's fingerprint (the
::  INPUT contract; Work Unit 7 owns the hash itself). Reproduces the
::  `Value.fingerPrint` Extend order: a KIND tag byte, then the components.
::  `Extend(int)` is 4 bytes little-endian, `Extend(byte/char)` is one byte,
::  `Extend(String)` is the chars. Values are normalized first so equal
::  values yield identical bytes across representations — crucially, tlc2
::  fingerprints an interval AS a SetEnum of ints, and a tuple/record AS an
::  FcnRcd (int-keyed / string-keyed), so those cross-representation equals
::  coincide here too. One documented deviation: a MODEL value's tlc2
::  fingerprint folds the UniqueString interning id (`tok`), which is not
::  reproducible (the deferred family-5 UniqueString-order difference); we
::  fold the model NAME instead — still injective over model values, but not
::  byte-identical to tlc2 for model values.
::
::  tlc2 ValueConstants kind bytes used here:
++  k-bool   0
++  k-int    1
++  k-str    3
++  k-set    5
++  k-fcn    9
++  k-model  22
::
++  int32-le
  ::  a 32-bit two's-complement little-endian encoding (tlc2 ints are Java
  ::  ints; Extend folds the low byte first)
  |=  n=@sd
  ^-  (list @D)
  =/  o  (old:si n)
  =/  u  (mod ?:(-.o +.o (sub (bex 32) (mod +.o (bex 32)))) (bex 32))
  ~[(cut 3 [0 1] u) (cut 3 [1 1] u) (cut 3 [2 1] u) (cut 3 [3 1] u)]
::
++  fp-input
  ::  the canonical fingerprint-input byte stream for a value
  |=  v=value
  ^-  (list @D)
  (fp-enc (normalize v))
::
++  fp-enc
  ::  encode an already-normalized value. Recursion over the value lists is
  ::  hand-rolled: a wet turn/zing over the recursive value mold fuse-loops
  ::  the zuse-408 compiler.
  |=  v=value
  ^-  (list @D)
  ?-  -.v
      %bool   ~[k-bool ?:(p.v 't' 'f')]
      %int    [k-int (int32-le p.v)]
      %str    (fp-str p.v)
      %model  :(weld ~[k-model] (int32-le (sun:si (met 3 p.v))) (rip 3 p.v))
      %intv
    =/  els  (expand-intv lo.v hi.v)
    :-  k-set
    %+  weld  (int32-le (sun:si (lent els)))
    (fp-set els)
  ::
      %set
    :-  k-set
    %+  weld  (int32-le (sun:si (lent p.v)))
    (fp-set p.v)
  ::
      %seq
    :-  k-fcn
    %+  weld  (int32-le (sun:si (lent p.v)))
    =/  i  1
    |-  ^-  (list @D)
    ?~  p.v  ~
    %+  weld
      :(weld ~[k-int] (int32-le (sun:si i)) (fp-enc i.p.v))
    $(p.v t.p.v, i +(i))
  ::
      %rec
    :-  k-fcn
    %+  weld  (int32-le (sun:si (lent p.v)))
    |-  ^-  (list @D)
    ?~  p.v  ~
    (weld (weld (fp-str k.i.p.v) (fp-enc v.i.p.v)) $(p.v t.p.v))
  ::
      %fcn
    :-  k-fcn
    %+  weld  (int32-le (sun:si (lent p.v)))
    |-  ^-  (list @D)
    ?~  p.v  ~
    (weld (weld (fp-enc d.i.p.v) (fp-enc r.i.p.v)) $(p.v t.p.v))
  ==
::
++  fp-set
  ::  concatenated element encodings (hand-rolled to avoid a fuse-loop)
  |=  vs=(list value)
  ^-  (list @D)
  ?~  vs  ~
  (weld (fp-enc i.vs) $(vs t.vs))
::
++  fp-str
  ::  a STRINGVALUE fingerprint field: tag, length, chars
  |=  s=@t
  ^-  (list @D)
  :(weld ~[k-str] (int32-le (sun:si (met 3 s))) (rip 3 s))
::
::  +|  Canonical Key (single-value-arg equality witness for tests)
::
::  +equal takes two values, and nesting the recursive value mold into a
::  two-cell gate sample nest-fails the zuse-408 mull when called from an
::  external test core (a single value arg, as +render takes, is fine).
::  +canon renders a fully-canonicalized value (intervals expanded to sets,
::  so cross-representation equals coincide) as a tape: for the finite
::  values in scope, (canon a) == (canon b) iff (equal a b). Tests compare
::  canon strings; production equality still uses +equal.
++  canon  |=(v=value (render (canonicalize v)))
::
++  canonicalize
  ::  fold representation views into one canonical form: an interval
  ::  becomes its explicit set; a tuple stays a tuple (render already
  ::  unifies it with a contiguous function). Recurse into components.
  |=  v=value
  ^-  value
  ?-  -.v
    %bool   v
    %int    v
    %str    v
    %model  v
    ::  canonicalize is the IDENTITY form (fingerprinting, equality). A set's
    ::  class is NOT part of its identity at the pin -- `SUBSET {1,2}` and the
    ::  same elements written out are the same value -- so `cls` is flattened
    ::  to `%set-enum` here on purpose, and only here
    %intv   (canonicalize [%set %set-enum (set-elems v)])
    %seq    [%seq (turn p.v canonicalize)]
    %set    [%set %set-enum (norm-set (turn p.v canonicalize))]
      %rec
    [%rec (turn p.v |=(f=vfield [k.f (canonicalize v.f)]))]
      %fcn
    [%fcn (turn p.v |=(pr=vpair [(canonicalize d.pr) (canonicalize r.pr)]))]
  ==
--
