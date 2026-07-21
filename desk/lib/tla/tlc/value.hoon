/-  *tla-lus
/=  ev  /lib/tla/eval
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
::  named $+ type with a $:-form record) — the exact shape lib/tla/eval
::  proves compiles. Lazy finite-set descriptors (SUBSET/UNION/SetOfFcns…)
::  are subunit 6.3 and are added there behind isolation tests, not grown
::  into this union speculatively.
::
::  +|  Types
::
::  Reuse the value mold already proven to compile under zuse-408 in
::  lib/tla/eval (a freshly-defined $+-recursive $% overflows the mold
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
    [%set (norm-set (turn p.v normalize))]
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
    %intv   "{(render-int lo.v)}..{(render-int hi.v)}"
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
  =/  sorted  (sort ps |=([x=vpair y=vpair] (vlth d.x d.y)))
  %+  roll  sorted
  |=  [pr=vpair acc=tape]
  =/  piece  "{(render d.pr)} :> {(render r.pr)}"
  ?~(acc piece "{acc} @@ {piece}")
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
++  vset-c   |=(l=(list value) `value`[%set l])
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
++  apply
  ::  f[x]: function, tuple (integer index), or record (string field)
  |=  [f=value x=value]
  ^-  vres
  ?-  -.f
      %fcn
    =/  hit  (find-image p.f x)
    ?~  hit  [%| 0 (rap 3 ~['applying a function outside its domain: ' (crip (render x))])]
    [%& u.hit]
      %seq
    =/  i  (idx-of x)
    ?:  |(=(0 i) (gth i (lent p.f)))
      [%| 0 (rap 3 ~['applying a tuple outside its domain: ' (crip (render x))])]
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
    %fcn   [%& (normalize [%set (turn p.f |=(pr=vpair d.pr))])]
    %seq   [%& [%intv --1 (sun:si (lent p.f))]]
    %rec   [%& (normalize [%set (turn p.f |=(fd=vfield `value`[%str k.fd]))])]
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
    %intv   (canonicalize [%set (set-elems v)])
    %seq    [%seq (turn p.v canonicalize)]
    %set    [%set (norm-set (turn p.v canonicalize))]
      %rec
    [%rec (turn p.v |=(f=vfield [k.f (canonicalize v.f)]))]
      %fcn
    [%fcn (turn p.v |=(pr=vpair [(canonicalize d.pr) (canonicalize r.pr)]))]
  ==
--
