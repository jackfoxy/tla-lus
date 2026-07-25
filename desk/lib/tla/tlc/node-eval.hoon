/-  *tla-lus
/=  v   /lib/tla/tlc/value
/=  sm  /lib/tla/semantic
::  Semantic-node expression evaluator (PORT-COMPLETION-PLAN-2 unit 6.5).
::
::  A dispatcher over the Work Unit 3 typed semantic graph (`sem` nodes) that
::  produces canonical TLC values via the unit 6.1-6.4 value core. It retires
::  the CST `eval-text` for constant/state expressions: literals, builtin and
::  user-defined applications, LET, EXCEPT, binders, and control are evaluated
::  from stable graph identities. Set-consuming positions (\in, \subseteq, the
::  bounded binders) go through `eval-domain` so the 6.3 lazy enumerators are
::  not bypassed; a set used as a plain value is forced. StandardModule
::  arithmetic/order/sequence operators (`+`, `<`, `..`, `\o`, `Len`, …) are
::  UserDefinedOpKind with no evaluable body, so a native table supplies them
::  (family 4 overrides proper remain deferred; an unknown one is a typed
::  unsupported failure, never a wrong value).
::
|%
::  +|  Evaluation Context
::
::  Two maps rather than one tagged union: unioning the recursive `value` and
::  `sem-def` molds in a fresh $% risks the zuse-408 mold hang. `vals` holds
::  value bindings (constants, bound variables, expression parameters, arity-0
::  LET values via their defs); `ops` holds operator definitions (module defs,
::  LET operators, operator-valued parameters). `atv` is the EXCEPT `@` value.
+$  eenv
  $:  vals=(map @t value:v)
      ops=(map @t sem-def:sm)
      atv=(unit value:v)
      fuel=@ud
  ==
+$  eres  (each value:v eval-err:v)
::
++  default-fuel  10.000
::
++  native-set
  ::  StandardModule operators supplied natively in Phase B (family 4 proper
  ::  is deferred). Anything else reached as a bodyless op is unsupported.
  ^-  (set @t)
  %-  silt
  ^-  (list @t)
  :~  '+'  '-'  '*'  '^'  '\\div'  '%'  '<'  '>'  '\\leq'  '\\geq'
      '..'  '\\o'  'Len'  'Head'  'Tail'  'Append'  'Cardinality'
  ==
::
::  +|  Top-Level Dispatch
::
++  eval
  |=  [n=sem:sm e=eenv]
  ^-  eres
  ?-  -.n
    %lit      (eval-lit n)
    %atref    ?~(atv.e [%| 0 'no @ value in scope.'] [%& u.atv.e])
    %nullodn  [%| 0 'unresolved operator (nullODN).']
    %letin    (eval-letin n e)
    %apply    (eval-apply n e)
  ==
::
++  eval-lit
  |=  n=sem-lit:sm
  ^-  eres
  ?-  kind.n
    %num  [%& [%int (sun:si (rash val.n dem))]]
    %str  [%& [%str val.n]]
    %dec  [%| 0 'decimal (Real) literals are unsupported.']
  ==
::
++  eval-apply
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  nm  name.op.n
  =/  kd  kind.op.n
  ?:  ?=(%builtin kd)  (eval-builtin n e)
  ?-  kd
      %constant      (lookup-val nm e)
      %new-constant  (lookup-val nm e)
      %user-op       (eval-user n e)
      %formal-param
    ?:(=(~ args.n) (lookup-val nm e) (eval-user n e))
  ::
    %variable         [%| 0 'variable reference requires a state (unit 6.6).']
    %thm-assump       [%| 0 'a theorem/assumption is not an evaluable value.']
    %module-instance  [%| 0 'a module instance is not an evaluable value.']
  ==
::
++  lookup-val
  |=  [nm=@t e=eenv]
  ^-  eres
  =/  hit  (~(get by vals.e) nm)
  ?~  hit  [%| 0 (rap 3 ~['undefined identifier: ' nm])]
  [%& u.hit]
::
::  +|  Helpers: Argument And Boolean Evaluation
::
++  eval-args
  |=  [as=(list sem:sm) e=eenv]
  ^-  (each (list value:v) eval-err:v)
  =|  acc=(list value:v)
  |-  ^-  (each (list value:v) eval-err:v)
  ?~  as  [%& (flop acc)]
  =/  r  (eval i.as e)
  ?:  ?=(%| -.r)  r
  $(as t.as, acc [p.r acc])
::
++  eval-bool
  |=  [n=sem:sm e=eenv]
  ^-  (each ? eval-err:v)
  =/  r  (eval n e)
  ?:  ?=(%| -.r)  r
  ?.  ?=(%bool -.p.r)
    [%| 0 (rap 3 ~['a non-boolean was used where a boolean is required: ' (crip (render:v p.r))])]
  [%& p.p.r]
::
++  lit-str
  ::  the string content of a %lit %str node (record field / selector)
  |=  n=sem:sm
  ^-  @t
  ?.  ?=(%lit -.n)  ''
  val.n
::
::  +|  Set-Denoting Positions (kept lazy)
::
++  eval-domain
  ::  evaluate a node that denotes a set to a lazy `sexp`, so membership and
  ::  bounded enumeration never force an exponential domain
  |=  [n=sem:sm e=eenv]
  ^-  (each sexp:v eval-err:v)
  ?.  ?=(%apply -.n)  (as-sexp (eval n e))
  =/  nm  name.op.n
  ?:  =(nm 'SUBSET')      (un-sexp %subset args.n e)
  ?:  =(nm 'UNION')       (un-sexp %union args.n e)
  ?:  =(nm '\\union')     (bin-sexp %cup args.n e)
  ?:  =(nm '\\intersect')  (bin-sexp %cap args.n e)
  ?:  =(nm '\\')          (bin-sexp %diff args.n e)
  ?:  |(=(nm '\\times') =(nm '$CartesianProd'))  (prod-sexp args.n e)
  ?:  =(nm '$SetOfFcns')  (fcns-sexp args.n e)
  ?:  =(nm '$SetOfRcds')  (rcds-sexp args.n e)
  (as-sexp (eval n e))
::
++  as-sexp
  ::  wrap an evaluated set value as a sexp; a non-set is non-enumerable
  |=  r=eres
  ^-  (each sexp:v eval-err:v)
  ?:  ?=(%| -.r)  r
  [%& [%set p.r]]
::
++  un-sexp
  |=  [tag=?(%subset %union) as=(list sem:sm) e=eenv]
  ^-  (each sexp:v eval-err:v)
  =/  a  (eval (snag 0 as) e)
  ?:  ?=(%| -.a)  a
  ?-  tag
    %subset  [%& [%subset p.a]]
    %union   [%& [%union p.a]]
  ==
::
++  bin-sexp
  |=  [tag=?(%cup %cap %diff) as=(list sem:sm) e=eenv]
  ^-  (each sexp:v eval-err:v)
  =/  a  (eval (snag 0 as) e)
  ?:  ?=(%| -.a)  a
  =/  b  (eval (snag 1 as) e)
  ?:  ?=(%| -.b)  b
  ?-  tag
    %cup   [%& [%cup p.a p.b]]
    %cap   [%& [%cap p.a p.b]]
    %diff  [%& [%diff p.a p.b]]
  ==
::
++  prod-sexp
  |=  [as=(list sem:sm) e=eenv]
  ^-  (each sexp:v eval-err:v)
  =/  vs  (eval-args as e)
  ?:  ?=(%| -.vs)  vs
  [%& [%prod p.vs]]
::
++  fcns-sexp
  |=  [as=(list sem:sm) e=eenv]
  ^-  (each sexp:v eval-err:v)
  =/  d  (eval (snag 0 as) e)
  ?:  ?=(%| -.d)  d
  =/  r  (eval (snag 1 as) e)
  ?:  ?=(%| -.r)  r
  [%& [%fcns p.d p.r]]
::
++  rcds-sexp
  ::  [a: S, b: T] — args are $Pair(name-str, set-expr)
  |=  [as=(list sem:sm) e=eenv]
  ^-  (each sexp:v eval-err:v)
  =|  acc=(list [k=@t s=value:v])
  |-  ^-  (each sexp:v eval-err:v)
  ?~  as  [%& [%rcds (flop acc)]]
  =/  pr  i.as
  ?.  ?=(%apply -.pr)  [%| 0 'malformed set-of-records field.']
  =/  k  (lit-str (snag 0 args.pr))
  =/  sv  (eval (snag 1 args.pr) e)
  ?:  ?=(%| -.sv)  sv
  $(as t.as, acc [[k p.sv] acc])
::
++  force-set
  ::  a set-denoting node evaluated to an eager normalized %set value
  |=  [n=sem:sm e=eenv]
  ^-  eres
  =/  s  (eval-domain n e)
  ?:  ?=(%| -.s)  s
  (force:v p.s)
::
::  +|  Builtin Dispatch
::
++  eval-builtin
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  nm  name.op.n
  =/  as  args.n
  ::  arity-0 constants
  ?:  =(nm 'TRUE')     [%& [%bool &]]
  ?:  =(nm 'FALSE')    [%& [%bool |]]
  ?:  =(nm 'BOOLEAN')  [%& [%set ~[[%bool |] [%bool &]]]]
  ::  equality and logic
  ?:  =(nm '=')        (bi-eq as e |)
  ?:  =(nm '/=')       (bi-eq as e &)
  ?:  |(=(nm '\\lnot') =(nm '\\neg'))  (un-not as e)
  ?:  =(nm '\\land')   (eval-conj ~[(snag 0 as) (snag 1 as)] e)
  ?:  =(nm '\\lor')    (eval-disj ~[(snag 0 as) (snag 1 as)] e)
  ?:  =(nm '$ConjList')  (eval-conj as e)
  ?:  =(nm '$DisjList')  (eval-disj as e)
  ?:  =(nm '=>')       (bi-imply as e)
  ?:  =(nm '\\equiv')  (bi-equiv as e)
  ::  membership
  ?:  =(nm '\\in')     (bi-in as e |)
  ?:  =(nm '\\notin')  (bi-in as e &)
  ?:  =(nm '\\subseteq')  (bi-subseteq as e)
  ::  set constructors (forced when used as a value)
  ?:  (~(has in set-ctor-names) nm)
    (force:v (need-sexp (eval-domain n e)))
  ?:  =(nm 'DOMAIN')
    =/  a  (eval (snag 0 as) e)
    ?:(?=(%| -.a) a (domain:v p.a))
  ::  functions, tuples, records
  ?:  =(nm '$FcnApply')   (eval-fcnapply as e)
  ?:  =(nm '$Except')     (eval-except n e)
  ?:  =(nm '$SetEnumerate')  (eval-setenum as e)
  ?:  =(nm '$Tuple')      (eval-tuple as e)
  ?:  =(nm '$RcdConstructor')  (eval-rcd as e)
  ?:  =(nm '$RcdSelect')  (eval-rcd-select as e)
  ::  control
  ?:  =(nm '$IfThenElse')  (eval-ite as e)
  ?:  =(nm '$Case')       (eval-case as e)
  ::  binders
  ?:  =(nm '$BoundedForall')  (eval-forall n e)
  ?:  =(nm '$BoundedExists')  (eval-exists n e)
  ?:  =(nm '$BoundedChoose')  (eval-choose n e)
  ?:  =(nm '$SubsetOf')   (eval-subsetof n e)
  ?:  =(nm '$SetOfAll')   (eval-setofall n e)
  ?:  |(=(nm '$FcnConstructor') =(nm '$NonRecursiveFcnSpec'))
    (eval-fcncon n e)
  [%| 0 (rap 3 ~['unsupported builtin operator: ' nm])]
::
++  set-ctor-names
  ^-  (set @t)
  %-  silt
  ^-  (list @t)
  :~  'SUBSET'  'UNION'  '\\union'  '\\intersect'  '\\'  '\\times'
      '$CartesianProd'  '$SetOfFcns'  '$SetOfRcds'
  ==
::
++  need-sexp
  |=  s=(each sexp:v eval-err:v)
  ^-  sexp:v
  ?>(?=(%& -.s) p.s)
::
++  bi-eq
  |=  [as=(list sem:sm) e=eenv neg=?]
  ^-  eres
  =/  a  (eval (snag 0 as) e)
  ?:  ?=(%| -.a)  a
  =/  b  (eval (snag 1 as) e)
  ?:  ?=(%| -.b)  b
  =/  r  (val-eq:v p.a p.b)
  ?:  ?=(%| -.r)  r
  [%& [%bool ?:(neg !p.r p.r)]]
::
++  un-not
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  b  (eval-bool (snag 0 as) e)
  ?:(?=(%| -.b) b [%& [%bool !p.b]])
::
++  bi-imply
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  a  (eval-bool (snag 0 as) e)
  ?:  ?=(%| -.a)  a
  ?.  p.a  [%& [%bool &]]
  =/  b  (eval-bool (snag 1 as) e)
  ?:(?=(%| -.b) b [%& [%bool p.b]])
::
++  bi-equiv
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  a  (eval-bool (snag 0 as) e)
  ?:  ?=(%| -.a)  a
  =/  b  (eval-bool (snag 1 as) e)
  ?:(?=(%| -.b) b [%& [%bool =(p.a p.b)]])
::
++  bi-in
  |=  [as=(list sem:sm) e=eenv neg=?]
  ^-  eres
  =/  x  (eval (snag 0 as) e)
  ?:  ?=(%| -.x)  x
  =/  s  (eval-domain (snag 1 as) e)
  ?:  ?=(%| -.s)  s
  =/  m  (set-member:v p.x p.s)
  ?:  ?=(%| -.m)  m
  [%& [%bool ?:(neg !p.m p.m)]]
::
++  bi-subseteq
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  a  (eval (snag 0 as) e)
  ?:  ?=(%| -.a)  a
  ?.  (set-like:v p.a)  [%| 0 'left of \\subseteq is not a set.']
  =/  s  (eval-domain (snag 1 as) e)
  ?:  ?=(%| -.s)  s
  =/  els  (set-elems:v (normalize:v p.a))
  |-  ^-  eres
  ?~  els  [%& [%bool &]]
  =/  m  (set-member:v i.els p.s)
  ?:  ?=(%| -.m)  m
  ?.  p.m  [%& [%bool |]]
  $(els t.els)
::
++  eval-conj
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  r  (conj-list:v (turn as |=(a=sem:sm |=(~ (eval-bool a e)))))
  ?:(?=(%| -.r) r [%& [%bool p.r]])
::
++  eval-disj
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  r  (disj-list:v (turn as |=(a=sem:sm |=(~ (eval-bool a e)))))
  ?:(?=(%| -.r) r [%& [%bool p.r]])
::
++  eval-fcnapply
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  f  (eval (snag 0 as) e)
  ?:  ?=(%| -.f)  f
  =/  x  (eval (snag 1 as) e)
  ?:  ?=(%| -.x)  x
  (apply:v p.f p.x)
::
++  eval-setenum
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  vs  (eval-args as e)
  ?:(?=(%| -.vs) vs [%& (normalize:v [%set p.vs])])
::
++  eval-tuple
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  vs  (eval-args as e)
  ?:(?=(%| -.vs) vs [%& [%seq p.vs]])
::
++  eval-rcd
  ::  [a |-> e1, b |-> e2] — args are $Pair(name-str, value-expr)
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =|  acc=(list vfield:v)
  |-  ^-  eres
  ?~  as
    (mk-rec:v (flop acc))
  =/  pr  i.as
  ?.  ?=(%apply -.pr)  [%| 0 'malformed record field.']
  =/  k  (lit-str (snag 0 args.pr))
  =/  fv  (eval (snag 1 args.pr) e)
  ?:  ?=(%| -.fv)  fv
  $(as t.as, acc [[k p.fv] acc])
::
++  eval-rcd-select
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  r  (eval (snag 0 as) e)
  ?:  ?=(%| -.r)  r
  (apply:v p.r [%str (lit-str (snag 1 as))])
::
++  eval-ite
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  c  (eval (snag 0 as) e)
  ?:  ?=(%| -.c)  c
  %^  if-val:v  p.c
    |=(~ (eval (snag 1 as) e))
  |=(~ (eval (snag 2 as) e))
::
++  eval-case
  ::  args are $Pair(guard, body); an OTHER arm's guard is a %nullodn
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =|  arms=(list [g=bthunk:v b=vthunk:v])
  =/  other=(unit vthunk:v)  ~
  |-  ^-  eres
  ?~  as
    (case-val:v (flop arms) other)
  =/  pr  i.as
  ?.  ?=(%apply -.pr)  [%| 0 'malformed CASE arm.']
  =/  guard  (snag 0 args.pr)
  =/  body   (snag 1 args.pr)
  ?:  ?=(%nullodn -.guard)
    $(as t.as, other `|=(~ (eval body e)))
  =/  arm  [`bthunk:v`|=(~ (eval-bool guard e)) `vthunk:v`|=(~ (eval body e))]
  $(as t.as, arms [arm arms])
::
::  +|  EXCEPT
::
++  eval-except
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  tv  (eval (snag 0 args.n) e)
  ?:  ?=(%| -.tv)  tv
  =/  cur  p.tv
  =/  clauses  (slag 1 args.n)
  |-  ^-  eres
  ?~  clauses  [%& cur]
  =/  pr  i.clauses
  ?.  ?=(%apply -.pr)  [%| 0 'malformed EXCEPT clause.']
  =/  seqn  (snag 0 args.pr)
  =/  rhs   (snag 1 args.pr)
  ?.  ?=(%apply -.seqn)  [%| 0 'malformed EXCEPT path.']
  =/  pathr  (eval-args args.seqn e)
  ?:  ?=(%| -.pathr)  pathr
  =/  sel  (except-select:v cur p.pathr)
  ?:  ?=(%| -.sel)  sel
  ?~  p.sel  $(clauses t.clauses)
  =/  rv  (eval rhs e(atv `u.p.sel))
  ?:  ?=(%| -.rv)  rv
  $(cur (except-put:v cur p.pathr p.rv), clauses t.clauses)
::
::  +|  Binders
::
++  flatten-bound
  ::  expand each `x, y \in S` group into one (name, range) per variable
  |=  bs=(list sem-bound:sm)
  ^-  (list [nm=@t rng=sem:sm])
  ?~  bs  ~
  =/  here=(list [nm=@t rng=sem:sm])
    ?~  range.i.bs  ~
    (turn vars.i.bs |=(b=sbind:sm [name.b u.range.i.bs]))
  (weld here $(bs t.bs))
::
++  bind-vals
  ::  bind var names to a positional binding tuple (zips to the shorter)
  |=  [e=eenv names=(list @t) vs=(list value:v)]
  ^-  eenv
  ?~  names  e
  ?~  vs  e
  %=  $
    names  t.names
    vs     t.vs
    e      e(vals (~(put by vals.e) i.names i.vs))
  ==
::
++  ctx-doms
  ::  a cdom per flattened binder: evaluate its range with the prefix bound
  |=  [bs=(list [nm=@t rng=sem:sm]) names=(list @t) e=eenv]
  ^-  (list cdom:v)
  %+  turn  bs
  |=  bd=[nm=@t rng=sem:sm]
  |=(pre=(list value:v) (eval-domain rng.bd (bind-vals e names pre)))
::
++  eval-forall
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?~  bs  [%| 0 'unbounded quantifier is not enumerable.']
  =/  names  (turn bs |=(b=[nm=@t rng=sem:sm] nm.b))
  =/  body  (snag 0 args.n)
  =/  r
    %+  all-ctx:v  (ctx-doms bs names e)
    |=(pre=(list value:v) (eval-bool body (bind-vals e names pre)))
  ?:(?=(%| -.r) r [%& [%bool p.r]])
::
++  eval-exists
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?~  bs  [%| 0 'unbounded quantifier is not enumerable.']
  =/  names  (turn bs |=(b=[nm=@t rng=sem:sm] nm.b))
  =/  body  (snag 0 args.n)
  =/  r
    %+  ex-ctx:v  (ctx-doms bs names e)
    |=(pre=(list value:v) (eval-bool body (bind-vals e names pre)))
  ?:(?=(%| -.r) r [%& [%bool p.r]])
::
++  eval-choose
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)  [%| 0 'CHOOSE expects one bounded variable.']
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  =/  body  (snag 0 args.n)
  %+  choose-over:v  p.sd
  |=(w=value:v (eval-bool body e(vals (~(put by vals.e) nm.i.bs w))))
::
++  eval-subsetof
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)  [%| 0 'a set filter expects one bounded variable.']
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  =/  body  (snag 0 args.n)
  %+  filter-over:v  p.sd
  |=(w=value:v (eval-bool body e(vals (~(put by vals.e) nm.i.bs w))))
::
++  eval-setofall
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)  [%| 0 'a set-of-all expects one bounded variable.']
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  =/  body  (snag 0 args.n)
  %+  map-over:v  p.sd
  |=(w=value:v (eval body e(vals (~(put by vals.e) nm.i.bs w))))
::
++  eval-fcncon
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)  [%| 0 'function constructor over multiple binders is unsupported.']
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  =/  body  (snag 0 args.n)
  %+  fcn-over:v  p.sd
  |=(w=value:v (eval body e(vals (~(put by vals.e) nm.i.bs w))))
::
::  +|  User-Defined Operators And LET
::
++  eval-user
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  nm  name.op.n
  =/  d   (~(get by ops.e) nm)
  ?~  d
    ?:  (~(has in native-set) nm)
      =/  as  (eval-args args.n e)
      ?:(?=(%| -.as) as (eval-native nm p.as e))
    [%| 0 (rap 3 ~['undefined or unsupported operator: ' nm])]
  ?:  =(0 fuel.e)  [%| 0 'evaluation recursion/resource limit exceeded.']
  =/  def  u.d
  ?~  body.def  [%| 0 (rap 3 ~['operator has no evaluable body: ' nm])]
  ?.  =((lent params.def) (lent args.n))
    [%| 0 (rap 3 ~['wrong number of arguments to ' nm])]
  =/  e2  (bind-params e params.def args.n)
  ?:  ?=(%| -.e2)  e2
  (eval u.body.def p.e2(fuel (dec fuel.e)))
::
++  bind-params
  |=  [e=eenv ps=(list spar:sm) as=(list sem:sm)]
  ^-  (each eenv eval-err:v)
  ?~  ps  [%& e]
  ?~  as  [%| 0 'argument count mismatch.']
  ?:  (gth arity.i.ps 0)
    =/  od  (resolve-oparg i.as e)
    ?~  od  [%| 0 'unsupported operator-valued argument.']
    $(ps t.ps, as t.as, e e(ops (~(put by ops.e) name.i.ps u.od)))
  ?.  used.i.ps
    ::  an unused expression parameter is not evaluated (lazy argument)
    $(ps t.ps, as t.as)
  =/  av  (eval i.as e)
  ?:  ?=(%| -.av)  av
  $(ps t.ps, as t.as, e e(vals (~(put by vals.e) name.i.ps p.av)))
::
++  resolve-oparg
  ::  an operator passed as an argument: a bare reference to a known op
  |=  [n=sem:sm e=eenv]
  ^-  (unit sem-def:sm)
  ?.  ?=(%apply -.n)  ~
  (~(get by ops.e) name.op.n)
::
++  eval-letin
  |=  [n=sem-letin:sm e=eenv]
  ^-  eres
  ?~  body.n  [%| 0 'LET with no body.']
  =/  e2=eenv
    =/  os  ops.e
    |-  ^-  eenv
    ?~  lets.n  e(ops os)
    $(lets.n t.lets.n, os (~(put by os) name.i.lets.n i.lets.n))
  (eval u.body.n e2)
::
::  +|  Native StandardModule Operators
::
++  eval-native
  |=  [nm=@t as=(list value:v) e=eenv]
  ^-  eres
  ?:  =(nm '..')
    ?.  ?=([* * ~] as)  [%| 0 '.. expects two arguments.']
    ?.  &(?=(%int -.i.as) ?=(%int -.i.t.as))  [%| 0 'non-integer interval bound.']
    [%& [%intv p.i.as p.i.t.as]]
  ?:  =(nm '\\o')
    ?.  ?=([* * ~] as)  [%| 0 '\\o expects two arguments.']
    ?.  &(?=(%seq -.i.as) ?=(%seq -.i.t.as))  [%| 0 '\\o expects two sequences.']
    [%& [%seq (weld p.i.as p.i.t.as)]]
  ?:  =(nm 'Len')
    ?.  ?=([* ~] as)  [%| 0 'Len expects one argument.']
    ?.  ?=(%seq -.i.as)  [%| 0 'Len expects a sequence.']
    [%& [%int (sun:si (lent p.i.as))]]
  ?:  =(nm 'Head')
    ?.  ?=([* ~] as)  [%| 0 'Head expects one argument.']
    ?.  ?=(%seq -.i.as)  [%| 0 'Head expects a sequence.']
    ?~  p.i.as  [%| 0 'Head of the empty sequence.']
    [%& i.p.i.as]
  ?:  =(nm 'Tail')
    ?.  ?=([* ~] as)  [%| 0 'Tail expects one argument.']
    ?.  ?=(%seq -.i.as)  [%| 0 'Tail expects a sequence.']
    ?~  p.i.as  [%| 0 'Tail of the empty sequence.']
    [%& [%seq t.p.i.as]]
  ?:  =(nm 'Append')
    ?.  ?=([* * ~] as)  [%| 0 'Append expects two arguments.']
    ?.  ?=(%seq -.i.as)  [%| 0 'Append expects a sequence.']
    [%& [%seq (snoc p.i.as i.t.as)]]
  ?:  =(nm 'Cardinality')
    ?.  ?=([* ~] as)  [%| 0 'Cardinality expects one argument.']
    ?.  (set-like:v i.as)  [%| 0 'Cardinality expects a set.']
    [%& [%int (sun:si (lent (set-elems:v (normalize:v i.as))))]]
  ::  binary integer operators
  ?.  ?=([* * ~] as)  [%| 0 (rap 3 ~['unsupported native operator or arity: ' nm])]
  ?.  &(?=(%int -.i.as) ?=(%int -.i.t.as))
    [%| 0 (rap 3 ~['non-integer argument to ' nm])]
  =/  x  p.i.as
  =/  y  p.i.t.as
  ?:  =(nm '+')  [%& [%int (sum:si x y)]]
  ?:  =(nm '-')  [%& [%int (dif:si x y)]]
  ?:  =(nm '*')  [%& [%int (pro:si x y)]]
  ?:  =(nm '^')  [%& [%int (sun:si (pow (abs:si x) (abs:si y)))]]
  ?:  =(nm '\\div')
    ?:  =(y --0)  [%| 0 'division by zero.']
    [%& [%int (sun:si (div (abs:si x) (abs:si y)))]]
  ?:  =(nm '%')
    ?:  =(y --0)  [%| 0 'modulo by zero.']
    [%& [%int (sun:si (mod (abs:si x) (abs:si y)))]]
  ?:  =(nm '<')      [%& [%bool (slth:v x y)]]
  ?:  =(nm '>')      [%& [%bool (slth:v y x)]]
  ?:  =(nm '\\leq')  [%& [%bool !(slth:v y x)]]
  ?:  =(nm '\\geq')  [%& [%bool !(slth:v x y)]]
  [%| 0 (rap 3 ~['unsupported native operator: ' nm])]
::
::  +|  Test / Driver Entrypoints
::
++  defmap-of
  |=  m=sem-module:sm
  ^-  (map @t sem-def:sm)
  =|  acc=(map @t sem-def:sm)
  |-  ^-  (map @t sem-def:sm)
  ?~  defs.m  acc
  $(defs.m t.defs.m, acc (~(put by acc) name.i.defs.m i.defs.m))
::
++  eval-module-def
  ::  evaluate the arity-0 definition `nm` of a generated module graph
  |=  [root=@t src=(map @t @t) nm=@t]
  ^-  eres
  =/  mo  (generate:sm root src)
  ?~  mo  [%| 0 'semantic graph generation failed.']
  =/  d  (~(get by (defmap-of u.mo)) nm)
  ?~  d  [%| 0 'definition not found.']
  ?~  body.u.d  [%| 0 'definition has no body.']
  (eval u.body.u.d [~ (defmap-of u.mo) ~ default-fuel])
::
++  eval-text
  ::  evaluate a constant expression via the semantic graph, rendered like
  ::  the tlc2 REPL (the retirement path for the CST +eval-text)
  |=  txt=@t
  ^-  tape
  =/  src=@t
    %-  crip
    ;:  weld
      "---- MODULE E ----\0a"
      "EXTENDS Integers, Sequences, FiniteSets\0a"
      "Expr == {(trip txt)}\0a====\0a"
    ==
  =/  r  (eval-module-def 'E' (malt ~[['E' src]]) 'Expr')
  ?:  ?=(%| -.r)  "Error evaluating expression"
  (render:v p.r)
::
++  eval-dbg
  ::  like +eval-text but surfacing the typed error message (debugging)
  |=  txt=@t
  ^-  tape
  =/  src=@t
    %-  crip
    ;:  weld
      "---- MODULE E ----\0a"
      "EXTENDS Integers, Sequences, FiniteSets\0a"
      "Expr == {(trip txt)}\0a====\0a"
    ==
  =/  r  (eval-module-def 'E' (malt ~[['E' src]]) 'Expr')
  ?:  ?=(%| -.r)  (weld "ERR: " (trip msg.p.r))
  (render:v p.r)
--
