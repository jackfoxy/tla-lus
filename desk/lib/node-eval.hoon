/-  *tla-lus
/=  v   /lib/value
/=  sm  /lib/semantic
/=  so  /lib/stdops
::  Semantic-node expression evaluator (PORT-COMPLETION-PLAN-2 unit 6.5).
::
::  A dispatcher over the Work Unit 3 typed semantic graph (`sem` nodes) that
::  produces canonical TLC values via the unit 6.1-6.4 value core. It retires
::  the CST `eval-text` for constant/state expressions: literals, builtin and
::  user-defined applications, LET, EXCEPT, binders, and control are evaluated
::  from stable graph identities. Set-consuming positions (\in, \subseteq, the
::  bounded binders) go through `eval-domain` so the 6.3 lazy enumerators are
::  not bypassed; a set used as a plain value is forced. StandardModule
::  operators (`+`, `<`, `..`, `\o`, `Len`, …) resolve through the unit-6C
::  override registry in `lib/stdops`, keyed by [module name arity] exactly
::  as tlc2 binds a Java method to the module that declares the operator: an
::  override beats the vendored TLA+ body (`Naturals.tla` defines `a+b ==
::  {a, b}`), and a StandardModule operator with neither an override nor an
::  explicit body-evaluable classification is a typed unsupported failure,
::  never a wrong value.
::
|%
::  +|  Evaluation Context
::
::  Two maps rather than one tagged union: unioning the recursive `value` and
::  `sem-def` molds in a fresh $% risks the zuse-408 mold hang. `vals` holds
::  value bindings (constants, bound variables, expression parameters, arity-0
::  LET values via their defs); `ops` holds operator definitions (module defs,
::  LET operators, operator-valued parameters). `atv` is the EXCEPT `@` value.
::  a state maps a stable variable identity to its assigned value; absence
::  means unassigned (a typed failure when such a variable is read). WU6.6
::  evaluates fully-assigned state/action predicates; partial-successor
::  action solving is WU6.7.
+$  state  (map @t value:v)
+$  eenv
  $:  vals=(map @t value:v)
      ops=(map @t sem-def:sm)
      atv=(unit value:v)
      fuel=@ud
      ::  current (s0) and successor (s1) states; `primed` resolves variable
      ::  references from s1 (the EvalControl.Primed bit), `enabled` marks an
      ::  ENABLED context (WU6.7 successor search)
      s0=state
      s1=state
      primed=?
      enabled=?
      ::  declared VARIABLE names — the assignable identities the action
      ::  solver (WU6.7) and ENABLED distinguish from constants/operators
      vars=(set @t)
      ::  call-by-name substitution for operator parameters (WU6.7 / R1.5.1):
      ::  a formal param bound to the argument NODE (not its value), so an
      ::  assignable state variable passed to an action operator stays
      ::  assignable in the body — tlc2's Context does the same, keeping the
      ::  argument as an OpApplNode. Value/operator arguments still bind
      ::  through `vals`/`ops`; only bare state-variable arguments land here.
      psub=(map @t sem:sm)
      ::  the StandardModule override registry, built once per environment
      ::  (unit 6C.1); rebuilding the table inside an evaluation loop would
      ::  cost a map construction per operator application
      ov=senv:so
  ==
+$  eres  (each value:v eval-err:v)
::  the action solver yields the ordered list of complete states satisfying
::  an action; a typed failure short-circuits (matching tlc2's stream)
+$  sres  (each (list state) eval-err:v)
::  the single typed evaluation-diagnostic shape (WU6.8): a tlc2 EC number
::  and coarse category, message, source location, operator/evaluation stack,
::  and whether a checker may recover. Per-site emission (replacing the bare
::  [code msg] eval-err) and EvalDump error fixtures are the follow-on sweep.
+$  ec-category
  $?  %undefined       ::  undefined operator or identifier
      %type            ::  type error (non-boolean, wrong argument kind)
      %non-enumerable  ::  infinite / non-enumerable domain
      %resource        ::  recursion / cardinality / work-budget limit
      %incomplete      ::  incomplete initial or next state
      %comparison      ::  illegal comparison (typed model, incomparable)
      %arithmetic      ::  division or modulo by zero
      %no-case         ::  CASE with no true guard and no OTHER
      %choose-empty    ::  CHOOSE over an unsatisfiable domain
      %except          ::  EXCEPT on a non-function / bad selector
      %unsupported     ::  family 4/5 behavior deferred in Phase B
      %runtime         ::  uncategorized runtime failure
  ==
+$  ev-diag
  $:  code=@ud
      category=ec-category
      msg=@t
      at=(unit [line=@ud col=@ud])
      stack=(list @t)
      recoverable=?
  ==
::
++  to-diag
  ::  lift a bare eval-err into the typed diagnostic shape under a category
  |=  [err=eval-err:v category=ec-category]
  ^-  ev-diag
  [code.err category msg.err ~ ~ &]
::
++  default-fuel  10.000
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
      %num
    ::  tlc2 integers are 32-bit: a larger numeral is EC 2265, which fails
    ::  the whole run there and this expression here (unit 6C.2)
    =/  x  (sun:si (rash val.n dem))
    ?.  (in-range:so x)
      [%| 2.265 (rap 3 ~['TLC can\'t handle a number this big.\0a' val.n])]
    [%& [%int x]]
    %str  [%& [%str val.n]]
    ::  tlc2 rejects a decimal literal while PROCESSING the spec, not while
    ::  evaluating, so its failure has no error code (a TLCRuntimeException,
    ::  not an EvalException) and takes the whole module down. The port rejects
    ::  at evaluation with the pin's wording; the outcome is the same typed
    ::  rejection, the timing differs (R1.4.5, compatibility.md)
    %dec  [%| 0 (cat 3 'TLC can\'t handle real numbers. ' val.n)]
  ==
::
++  eval-apply
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  nm  name.op.n
  =/  kd  kind.op.n
  ?:  ?=(%builtin kd)  (eval-builtin n e)
  ?-  kd
      %constant      (apply-const nm n e)
      %new-constant  (apply-const nm n e)
      %user-op       (eval-user n e)
      %formal-param
    ?.  =(~ args.n)  (eval-user n e)
    ::  a param bound call-by-name (a substituted argument node) is evaluated
    ::  in place; otherwise it is a value parameter resolved from `vals`
    =/  s  (~(get by psub.e) nm)
    ?~(s (lookup-val nm e) (eval u.s e))
  ::
    %variable         (lookup-var nm e)
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
++  apply-const
  ::  a CONSTANT reference. Arity-0 resolves to its value; a constant OPERATOR
  ::  (`CONSTANT F(_)` bound by a cfg `F(a) = v` enumeration) is applied at the
  ::  argument (arity 1) or the argument tuple (arity n) — the config builds it
  ::  as a function value (tlc2's OpRcdValue), so application is `F[args]`
  |=  [nm=@t n=sem-apply:sm e=eenv]
  ^-  eres
  ?~  args.n  (lookup-val nm e)
  =/  fv  (~(get by vals.e) nm)
  ?~  fv  [%| 0 (rap 3 ~['undefined identifier: ' nm])]
  =/  as  (eval-args args.n e)
  ?:  ?=(%| -.as)  as
  =/  dp=value:v  ?:(=(1 (lent p.as)) (snag 0 p.as) [%seq p.as])
  (apply:v u.fv dp |)
::
++  lookup-var
  ::  a variable resolves from the successor state under a prime, else the
  ::  current state; an unassigned read is a typed failure
  |=  [nm=@t e=eenv]
  ^-  eres
  =/  st  ?:(primed.e s1.e s0.e)
  =/  hit  (~(get by st) nm)
  ?~  hit
    ?:  primed.e
      [%| 0 (rap 3 ~['primed variable is unassigned in the successor state: ' nm])]
    [%| 0 (rap 3 ~['variable is unassigned in the current state: ' nm])]
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
  ::  a StandardModule set operator (Nat, Int) denotes an infinite set: it
  ::  has a lazy descriptor here, though it is not a value (unit 6C.2)
  =/  d  (~(get by ops.e) nm)
  ?~  d  (as-sexp (eval n e))
  =/  key=op-key:so  [origin.u.d nm (lent args.n)]
  ?.  (is-descriptor:so key)  (as-sexp (eval n e))
  ::  Seq(S) carries its range, so the arguments are evaluated first
  =/  as  (eval-args args.n e)
  ?:  ?=(%| -.as)  as
  =/  sd  (set-descriptor:so key p.as)
  ?~  sd  (as-sexp (eval n e))
  [%& u.sd]
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
  ::  prime and UNCHANGED (state/action; WU6.6)
  ?:  =(nm '\'')          (eval (snag 0 as) e(primed &))
  ?:  =(nm 'UNCHANGED')   (eval-unchanged as e)
  ?:  =(nm 'ENABLED')     (eval-enabled (snag 0 as) e)
  ::  set constructors (forced when used as a value)
  ?:  (~(has in set-ctor-names) nm)
    ::  a set constructor whose operand fails to evaluate is a typed failure,
    ::  not an assertion: `s \ {CHOOSE y \in s : TRUE}` with an empty `s` used
    ::  to crash the evaluator through +need-sexp's ?>, which a recursive
    ::  function definition reaches whenever a sweep tries a point it cannot
    ::  yet solve (R1.4.2)
    =/  sx  (eval-domain n e)
    ?:  ?=(%| -.sx)  sx
    (force:v p.sx)
  ?:  =(nm 'DOMAIN')
    =/  a  (eval (snag 0 as) e)
    ?:  ?=(%| -.a)  a
    ::  tlc2 returns the domain VALUE the function was built from, unchanged,
    ::  so `DOMAIN [i \in 1..3 |-> i]` is an IntervalValue while
    ::  `DOMAIN [i \in {1, 2, 3} |-> i]` is a SetEnumValue for the same set --
    ::  provenance, not shape. The port's `%fcn` does not carry its domain, so
    ::  recover it from the EXPRESSION where the expression reaches a
    ::  constructor; otherwise fall back to enumerating the pairs (R1.4.5b)
    ?.  ?=(%fcn -.p.a)  (domain:v p.a)
    =/  de  (domain-expr (snag 0 as) e 8)
    ?~(de (domain:v p.a) [%& u.de])
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
  ?:  =(nm '$RecursiveFcnSpec')  (eval-recfcn n e)
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
++  eval-unchanged
  ::  UNCHANGED e is e' = e: the successor value of e equals its current
  ::  value (tuples and composites compare structurally via +val-eq)
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  cur  (eval (snag 0 as) e(primed |))
  ?:  ?=(%| -.cur)  cur
  =/  nxt  (eval (snag 0 as) e(primed &))
  ?:  ?=(%| -.nxt)  nxt
  =/  r  (val-eq:v p.nxt p.cur)
  ?:  ?=(%| -.r)  r
  [%& [%bool p.r]]
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
++  subset-arg
  ::  the argument of a `SUBSET _` application, if `n` is one
  |=  n=sem:sm
  ^-  (unit sem:sm)
  ?.  ?=(%apply -.n)  ~
  ?.  =('SUBSET' name.op.n)  ~
  ?~  args.n  ~
  `i.args.n
::
++  bi-subseteq
  ::  `A \subseteq B`, kept lazy: both sides are set descriptors and A is
  ::  streamed, so a lazy left set (SUBSET/UNION/[D->R]) is never forced. tlc2
  ::  reduces `SUBSET A \subseteq SUBSET B` to `A \subseteq B` (SubsetValue.
  ::  isSubsetEq) to avoid materializing the power set; peel matching SUBSETs
  ::  first, then compare the underlying sets lazily.
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  ln  (snag 0 as)
  =/  rn  (snag 1 as)
  |-
  =/  la  (subset-arg ln)
  =/  lb  (subset-arg rn)
  ?:  ?&(?=(^ la) ?=(^ lb))
    $(ln u.la, rn u.lb)
  =/  sa  (eval-domain ln e)
  ?:  ?=(%| -.sa)  sa
  =/  sb  (eval-domain rn e)
  ?:  ?=(%| -.sb)  sb
  =/  r  (sexp-subseteq:v p.sa p.sb)
  ?:(?=(%| -.r) r [%& [%bool p.r]])
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
++  domain-expr
  ::  the domain VALUE a function expression was built from, when the
  ::  expression reaches a constructor. tlc2's DOMAIN hands back the value the
  ::  function was constructed over rather than re-deriving a set from the
  ::  points, which is why `1..3` survives as an IntervalValue and `{1, 2, 3}`
  ::  does not; the port's `%fcn` keeps only its pairs, so the provenance is
  ::  recovered here instead. Definition references are followed (a definition
  ::  is where a constructor usually lives) under a small fuel bound; anything
  ::  else -- a function that arrived as a parameter, an EXCEPT, a conditional
  ::  -- yields ~ and the caller enumerates, which is the pre-R1.4.5b answer
  |=  [n=sem:sm e=eenv fuel=@ud]
  ^-  (unit value:v)
  ?:  =(0 fuel)  ~
  ?.  ?=(%apply -.n)  ~
  =/  nm  name.op.n
  ?:  ?|  =(nm '$FcnConstructor')
          =(nm '$NonRecursiveFcnSpec')
          =(nm '$RecursiveFcnSpec')
      ==
    =/  bs  (flatten-bound bound.n)
    ::  a multi-binder constructor's domain is the tuple set, which tlc2
    ::  builds rather than carries, so only the single-binder case applies
    ?.  ?=([* ~] bs)  ~
    ::  evaluate the range as an ordinary VALUE, not through +eval-domain and
    ::  +force: forcing is exactly what destroys the interval, turning `1..3`
    ::  into an eager `%set` and losing the distinction this arm exists for
    =/  r  (eval rng.i.bs e)
    ?:(?=(%| -.r) ~ `p.r)
  ::  a reference to an arity-0 definition: look through to its body
  ?.  =(~ args.n)  ~
  =/  d  (~(get by ops.e) nm)
  ?~  d  ~
  ?~  body.u.d  ~
  $(n u.body.u.d, fuel (dec fuel))
::
++  lambda-form
  ::  is this expression a function-lambda form? tlc2 keeps `[x \in S |-> e]`
  ::  and a recursive spec as a lazy FcnLambdaValue, while a definition's value
  ::  is a normalized FcnRcdValue, and the two classes word an out-of-domain
  ::  failure differently
  |=  n=sem:sm
  ^-  ?
  ?.  ?=(%apply -.n)  |
  =/  nm  name.op.n
  ?|  =(nm '$FcnConstructor')
      =(nm '$NonRecursiveFcnSpec')
      =(nm '$RecursiveFcnSpec')
  ==
::
++  eval-fcnapply
  |=  [as=(list sem:sm) e=eenv]
  ^-  eres
  =/  f  (eval (snag 0 as) e)
  ?:  ?=(%| -.f)  f
  =/  x  (eval (snag 1 as) e)
  ?:  ?=(%| -.x)  x
  ::  tlc2 words an out-of-domain failure by the function's value class, and a
  ::  lambda FORM is what stays a FcnLambdaValue there (R1.4.5)
  (apply:v p.f p.x (lambda-form (snag 0 as)))
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
  (apply:v p.r [%str (lit-str (snag 1 as))] |)
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
+$  bgroup
  ::  one binder to iterate: the names it binds, its range, and whether it
  ::  DESTRUCTURES. `i, j \in S` is two bgroups (each name ranges over the
  ::  whole of S); `<<i, j>> \in S` is ONE bgroup carrying both names, since
  ::  a single element of S is taken apart across them (R1.3.8)
  $:  nms=(list @t)
      rng=sem:sm
      tup=?
  ==
::
++  flatten-bound
  ::  expand a bound list into the binders to iterate. A plain group becomes
  ::  one bgroup per variable; a tuple group stays one bgroup
  |=  bs=(list sem-bound:sm)
  ^-  (list bgroup)
  ?~  bs  ~
  =/  here=(list bgroup)
    ?~  range.i.bs  ~
    ?:  tuple.i.bs
      ~[[(turn vars.i.bs |=(b=sbind:sm name.b)) u.range.i.bs &]]
    (turn vars.i.bs |=(b=sbind:sm [~[name.b] u.range.i.bs |]))
  (weld here $(bs t.bs))
::
++  bind-names
  ::  bind names to a positional value list (zips to the shorter)
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
++  bind-group
  ::  bind ONE binder group to ONE domain element. A plain group binds its
  ::  single name to the element; a tuple group destructures the element
  ::  across its names. A tuple binder over a non-tuple element binds
  ::  nothing, so the body fails on the unbound name rather than silently
  ::  seeing the whole element (R1.3.8)
  |=  [e=eenv g=bgroup w=value:v]
  ^-  eenv
  ?.  tup.g
    ?~(nms.g e e(vals (~(put by vals.e) i.nms.g w)))
  ?.  ?=(%seq -.w)  e
  (bind-names e nms.g p.w)
::
++  bind-vals
  ::  bind a whole binding context: one value per bgroup, each destructured
  ::  or not according to its group
  |=  [e=eenv gs=(list bgroup) vs=(list value:v)]
  ^-  eenv
  ?~  gs  e
  ?~  vs  e
  $(gs t.gs, vs t.vs, e (bind-group e i.gs i.vs))
::
++  ctx-doms
  ::  a cdom per binder group: evaluate its range with the prefix bound
  |=  [bs=(list bgroup) e=eenv]
  ^-  (list cdom:v)
  %+  turn  bs
  |=  bd=bgroup
  |=(pre=(list value:v) (eval-domain rng.bd (bind-vals e bs pre)))
::
++  eval-forall
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?~  bs  [%| 0 'unbounded quantifier is not enumerable.']

  =/  body  (snag 0 args.n)
  =/  r
    %+  all-ctx:v  (ctx-doms bs e)
    |=(pre=(list value:v) (eval-bool body (bind-vals e bs pre)))
  ?:(?=(%| -.r) r [%& [%bool p.r]])
::
++  eval-exists
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?~  bs  [%| 0 'unbounded quantifier is not enumerable.']

  =/  body  (snag 0 args.n)
  =/  r
    %+  ex-ctx:v  (ctx-doms bs e)
    |=(pre=(list value:v) (eval-bool body (bind-vals e bs pre)))
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
  |=(w=value:v (eval-bool body (bind-group e i.bs w)))
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
  |=(w=value:v (eval-bool body (bind-group e i.bs w)))
::
++  eval-setofall
  ::  {e : x \in S} and, over several binders, {e : x \in S, y \in T(x)} —
  ::  the one-binder case keeps the streaming +map-over so a large domain is
  ::  never materialized; several binders walk the binding context (R1.4.3)
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?~  bs  [%| 0 'a set-of-all expects a bounded variable.']
  =/  body  (snag 0 args.n)
  ?.  ?=([* ~] bs)
  
    =/  r
      %^  ctx-map:v  (ctx-doms bs e)  ~
      |=(pre=(list value:v) (eval body (bind-vals e bs pre)))
    ?:  ?=(%| -.r)  r
    [%& (normalize:v [%set p.r])]
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  %+  map-over:v  p.sd
  |=(w=value:v (eval body (bind-group e i.bs w)))
::
++  eval-fcncon
  ::  [x \in S |-> e] and, over several binders, [x \in S, y \in T |-> e],
  ::  whose domain point is the binding TUPLE (R1.4.3). tlc2 prints such a
  ::  function in construction order; the port normalizes function pairs into
  ::  its storage order, which is the same function — compatibility.md
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  bs  (flatten-bound bound.n)
  ?~  bs  [%| 0 'a function constructor expects a bounded variable.']
  =/  body  (snag 0 args.n)
  ?.  ?=([* ~] bs)
  
    =/  r
      %^  ctx-fcn:v  (ctx-doms bs e)  ~
      |=(pre=(list value:v) (eval body (bind-vals e bs pre)))
    ?:  ?=(%| -.r)  r
    [%& (normalize:v [%fcn p.r])]
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  %+  fcn-over:v  p.sd
  |=(w=value:v (eval body (bind-group e i.bs w)))
::
++  recfcn-partial
  ::  the points solved so far, in domain order, as a function value — what
  ::  the self-binder is bound to while the remaining points are solved
  |=  [pts=(list value:v) sol=(map @ud value:v)]
  ^-  value:v
  =|  acc=(list vpair:v)
  =/  i=@ud  0
  |-  ^-  value:v
  ?~  pts  (normalize:v [%fcn (flop acc)])
  =/  r  (~(get by sol) i)
  $(pts t.pts, i +(i), acc ?~(r acc [[i.pts u.r] acc]))
::
++  eval-recfcn
  ::  a recursive function definition, `f[x \in S] == e(f, x)`. tlc2 builds a
  ::  LAZY FcnLambdaValue and forces a point only when it is applied, so the
  ::  body may refer to ANY other point, not merely an earlier one — measured
  ::  at the pin, `Fwd[n \in 1..3] == IF n = 3 THEN 0 ELSE Fwd[n + 1] + 1`
  ::  evaluates to <<2, 1, 0>>. A single pass in domain order would therefore
  ::  be wrong, so this sweeps the domain to a fixpoint: each point is tried
  ::  with the self-binder bound to the points solved so far, and sweeping
  ::  stops when a whole pass solves nothing new. That terminates on every
  ::  well-founded definition regardless of which direction it recurses, and
  ::  a definition that cannot progress reports the failure its last attempt
  ::  produced (tlc2 instead returns the unforced lambda, printing the body's
  ::  source span — the port has no unforced-value form; compatibility.md)
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?~  ubound.n  [%| 0 'recursive function definition without a self-binder.']
  =/  fnm  name.i.ubound.n
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)
    [%| 0 'function constructor over multiple binders is unsupported.']
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  =/  fr  (force:v p.sd)
  ?:  ?=(%| -.fr)  fr
  =/  el  (elemsof-e:v p.fr)
  ?:  ?=(%| -.el)  el
  =/  pts  p.el
  =/  body  (snag 0 args.n)
  =/  tot  (lent pts)
  =|  sol=(map @ud value:v)
  =/  last=eval-err:v  [0 'recursive function definition does not converge.']
  |-  ^-  eres
  ?:  =(tot ~(wyt by sol))  [%& (recfcn-partial pts sol)]
  ::  one sweep: the partial function is rebuilt per point, so a point solved
  ::  earlier in this sweep is already visible to the next one
  =/  sw
    =/  ps  pts
    =/  i=@ud  0
    =/  s2  sol
    =/  e2  last
    |-  ^-  [(map @ud value:v) eval-err:v]
    ?~  ps  [s2 e2]
    ?^  (~(get by s2) i)  $(ps t.ps, i +(i))
    ::  the self-binder plus this point, destructured if the binder is a
    ::  tuple pattern (R1.3.8)
    =/  ev2=eenv
      %+  bind-group
        e(vals (~(put by vals.e) fnm (recfcn-partial pts s2)))
      [i.bs i.ps]
    =/  r  (eval body ev2)
    ?:  ?=(%| -.r)  $(ps t.ps, i +(i), e2 p.r)
    $(ps t.ps, i +(i), s2 (~(put by s2) i p.r))
  ?:  =(~(wyt by -.sw) ~(wyt by sol))  [%| +.sw]
  $(sol -.sw, last +.sw)
::
::  +|  User-Defined Operators And LET
::
++  eval-user
  ::  resolution order, mirroring SpecProcessor: a Java override bound to
  ::  the defining module wins; otherwise the definition's own body is
  ::  evaluated — but only for a user module, or for the few StandardModule
  ::  operators the pin leaves un-overridden (`body-ok:so`), because a
  ::  vendored standard body is a dummy
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  =/  nm  name.op.n
  =/  d   (~(get by ops.e) nm)
  ?~  d
    [%| 0 (rap 3 ~['undefined operator: ' nm])]
  =/  def  u.d
  =/  key=op-key:so  [origin.def nm (lent args.n)]
  =/  ov  (lookup:so ov.e key)
  ?^  ov
    =/  as  (eval-args args.n e)
    ?:  ?=(%| -.as)  as
    (gate.u.ov p.as)
  ::  an override that needs the evaluator itself (an operator argument)
  =/  nop  (node-op:so key)
  ?^  nop  (eval-node-op tag.u.nop n e)
  ?:  ?&  (is-standard:so ov.e origin.def)
          !(body-allowed:so ov.e origin.def nm)
      ==
    [%| (unsupported:so key)]
  ?:  =(0 fuel.e)  [%| 0 'evaluation recursion/resource limit exceeded.']
  ?~  body.def  [%| 0 (rap 3 ~['operator has no evaluable body: ' nm])]
  ?.  =((lent params.def) (lent args.n))
    [%| 0 (rap 3 ~['wrong number of arguments to ' nm])]
  =/  e2  (bind-params e params.def args.n)
  ?:  ?=(%| -.e2)  e2
  (eval u.body.def p.e2(fuel (dec fuel.e)))
::
++  eval-node-op
  ::  StandardModule overrides that take an operator argument. tlc2 receives
  ::  an OpValue and applies it per element; here the operator argument is
  ::  resolved through the ordinary operator-valued-parameter path and
  ::  applied by the same evaluator, under the same recursion budget
  |=  [tag=@tas n=sem-apply:sm e=eenv]
  ^-  eres
  ?:  ?=(%bag-of-all tag)     (eval-bag-of-all n e)
  ?:  ?=(%cardinality tag)    (eval-cardinality n e)
  ?:  ?=(%is-finite-set tag)  (eval-is-finite n e)
  ?:  ?=(%sort-seq tag)       (eval-sort-seq n e)
  ?:  ?=(%tlc-eval tag)       (eval-tlc-eval n e)
  ?:  ?=(%tlc-get tag)        (eval-tlc-get n e)
  ?.  ?=(%select-seq tag)  [%| 0 'unsupported operator-argument override.']
  ?.  ?=([* * ~] args.n)
    [%| 0 'SelectSeq expects two arguments.']
  =/  sv  (eval i.args.n e)
  ?:  ?=(%| -.sv)  sv
  =/  t  (to-tuple:v p.sv)
  ?~  t  [%| (arg-error:so 2.169 1 'SelectSeq' 'sequence' | p.sv)]
  ::  an empty sequence is answered before the operator is even examined
  ?~  u.t  [%& [%seq ~]]
  =/  od  (resolve-oparg i.t.args.n e)
  ?~  od  [%| (op-arg-error 'SelectSeq' 'operator' i.t.args.n)]
  =/  keep
    ::  widen: `u.t` is narrowed to a non-empty list, which would make the
    ::  loop's `?~` vain
    =/  els=(list value:v)  u.t
    =|  acc=(list value:v)
    |-  ^-  (each (list value:v) eval-err:v)
    ?~  els  [%& (flop acc)]
    =/  r  (apply-def u.od ~[i.els] e)
    ?:  ?=(%| -.r)  r
    ?.  ?=(%bool -.p.r)
      [%| (op-arg-error 'SelectSeq' 'boolean-valued operator' i.t.args.n)]
    ?:  p.p.r  $(els t.els, acc [i.els acc])
    $(els t.els)
  ?:  ?=(%| -.keep)  keep
  [%& [%seq p.keep]]
::
++  eval-cardinality
  ::  FiniteSets!Cardinality. The argument is evaluated as a lazy DOMAIN, so
  ::  an infinite descriptor (Nat, Int, Seq) is answered with tlc2's EC 2181
  ::  instead of being forced, and a finite lazy set (SUBSET S, [D -> R]) is
  ::  counted through the 6.3 cursor under its budget
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?.  ?=([* ~] args.n)  [%| 0 'Cardinality expects one argument.']
  =/  dom  (eval-domain i.args.n e)
  ?:  ?=(%| -.dom)  (cardinality-error i.args.n e)
  ::  an ordinary value wrapped as a domain is only a set if it looks like
  ::  one; tlc2 reports the value, not an enumeration failure
  ?:  ?&(?=(%set -.p.dom) !(set-like:v s.p.dom))
    [%| (card-err (crip (render:v s.p.dom)))]
  ?:  (infinite:v p.dom)
    [%| (card-err (crip (sexp-name:v p.dom)))]
  =/  f  (force:v p.dom)
  ?:  ?=(%| -.f)  f
  [%& [%int (sun:si (lent (set-elems:v p.f)))]]
::
++  cardinality-error
  ::  the argument is not a set at all: name it the way tlc2 does (its
  ::  value, not the enumeration failure)
  |=  [n=sem:sm e=eenv]
  ^-  eres
  =/  vv  (eval n e)
  ?:  ?=(%| -.vv)  vv
  [%| (card-err (crip (render:v p.vv)))]
::
++  card-err
  ::  EC 2181
  |=  what=@t
  ^-  eval-err:v
  [2.181 (rap 3 ~['Attempted to compute cardinality of the value\0a' what])]
::
++  eval-is-finite
  ::  FiniteSets!IsFiniteSet — false for the infinite descriptors, true for
  ::  any other set, and an error for a non-set (tlc2's Value.isFinite fails
  ::  on an atom)
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?.  ?=([* ~] args.n)  [%| 0 'IsFiniteSet expects one argument.']
  =/  dom  (eval-domain i.args.n e)
  ?:  ?&(?=(%& -.dom) !?&(?=(%set -.p.dom) !(set-like:v s.p.dom)))
    [%& [%bool !(infinite:v p.dom)]]
  =/  vv  (eval i.args.n e)
  ?:  ?=(%| -.vv)  vv
  :-  %|
  :-  0
  %^  rap  3  'Attempted to check if the integer '
  ~[(crip (render:v p.vv)) ' is a finite set.']
::
++  eval-bag-of-all
  ::  Bags!BagOfAll(F(_), b): apply the operator to each domain point,
  ::  summing the counts of results that collide
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?.  ?=([* * ~] args.n)  [%| 0 'BagOfAll expects two arguments.']
  =/  od  (resolve-oparg i.args.n e)
  ?~  od
    :-  %|
    :-  2.266
    %^  rap  3  'The first argument of BagOfAll should be an operator, '
    ~['but instead it is:\0a<Operator ' (oparg-name i.args.n) '>']
  =/  bv  (eval i.t.args.n e)
  ?:  ?=(%| -.bv)  bv
  =/  ps  (to-fcn-pairs:v p.bv)
  ?~  ps
    :-  %|
    %^  arg-error:so  2.169  2
    ['BagOfAll' 'function with a finite domain' | p.bv]
  =|  acc=(list vpair:v)
  =/  l=(list vpair:v)  u.ps
  |-  ^-  eres
  ?~  l  [%& (normalize:v [%fcn (flop acc)])]
  =/  r  (apply-def u.od ~[d.i.l] e)
  ?:  ?=(%| -.r)  r
  =/  hit  (skim acc |=(pr=vpair:v (equal:v d.pr p.r)))
  ?~  hit  $(l t.l, acc [[p.r r.i.l] acc])
  =/  n2
    ?:  ?&(?=(%int -.r.i.hit) ?=(%int -.r.i.l))
      `value:v`[%int (sum:si p.r.i.hit p.r.i.l)]
    r.i.l
  %=  $
    l    t.l
    acc  [[p.r n2] (skip acc |=(pr=vpair:v (equal:v d.pr p.r)))]
  ==
::
++  eval-tlc-eval
  ::  TLC!TLCEval(e) — the pin's `@Evaluation` override: it receives the
  ::  unevaluated node and evaluates it itself (there it defeats TLC's
  ::  caching; here it is the lazy argument contract in one operator)
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?.  ?=([* ~] args.n)  [%| 0 'TLCEval expects one argument.']
  (eval i.args.n e)
::
++  eval-tlc-get
  ::  TLC!TLCGet — also an `@Evaluation` override in the pin, so it receives
  ::  the node and evaluates the key itself. The answer is tlc2's EC 2145 for
  ::  a key TLC does not define, and a typed rejection naming a key it does
  ::  (this evaluator cannot reach engine state)
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?.  ?=([* ~] args.n)  [%| 0 'TLCGet expects one argument.']
  =/  k  (eval i.args.n e)
  ?:  ?=(%| -.k)  k
  (tlc-get:so ~[p.k])
::
++  eval-sort-seq
  ::  TLC!SortSeq(s, cmp): tlc2's insertion sort, with the comparator applied
  ::  by the evaluator (an operator argument). The first-argument message
  ::  really does say "natural number" in the pin
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?.  ?=([* * ~] args.n)  [%| 0 'SortSeq expects two arguments.']
  =/  sv  (eval i.args.n e)
  ?:  ?=(%| -.sv)  sv
  =/  t  (to-tuple:v p.sv)
  ?~  t  [%| (arg-error:so 2.169 1 'SortSeq' 'natural number' | p.sv)]
  ?~  u.t  [%& [%seq ~]]
  =/  od  (resolve-oparg i.t.args.n e)
  ?~  od  [%| (op-arg-error 'SortSeq' 'operator' i.t.args.n)]
  ::  insert each element into the sorted prefix, exactly as tlc2 does, so
  ::  equal elements keep their relative order
  =/  els=(list value:v)  u.t
  =|  acc=(list value:v)
  |-  ^-  eres
  ?~  els  [%& [%seq acc]]
  =/  ins  (sort-insert u.od i.els acc e)
  ?:  ?=(%| -.ins)  ins
  $(els t.els, acc p.ins)
::
++  sort-insert
  ::  place `x` in the already-sorted `done`, walking back while the
  ::  comparator says the new element precedes the one before it
  |=  [d=sem-def:sm x=value:v done=(list value:v) e=eenv]
  ^-  (each (list value:v) eval-err:v)
  =|  head=(list value:v)
  =/  rest  (flop done)
  |-  ^-  (each (list value:v) eval-err:v)
  ?~  rest  [%& [x head]]
  =/  r  (apply-def d ~[x i.rest] e)
  ?:  ?=(%| -.r)  r
  ?.  ?=(%bool -.p.r)
    [%| 2.169 'The second argument of SortSeq should be a boolean function, but instead it is:\0a<Operator>']
  ?.  p.p.r  [%& (weld (flop rest) [x head])]
  $(rest t.rest, head [i.rest head])
::
++  op-arg-error
  ::  EC 2169 for an operator argument: tlc2 renders the OpValue, which has
  ::  no value counterpart here, so the operator is named as `<Operator X>`
  |=  [op=@t what=@t arg=sem:sm]
  ^-  eval-err:v
  =/  nm  =/(n (oparg-name arg) ?:(=('' n) 'LAMBDA' n))
  :-  2.169
  %^  rap  3  'The second argument of '
  ~[op ' should be a ' what ', but instead it is:\0a<Operator ' nm '>']
::
++  apply-def
  ::  apply an operator definition to already-evaluated arguments
  |=  [d=sem-def:sm vs=(list value:v) e=eenv]
  ^-  eres
  ?:  =(0 fuel.e)  [%| 0 'evaluation recursion/resource limit exceeded.']
  ?~  body.d  [%| 0 (rap 3 ~['operator has no evaluable body: ' name.d])]
  ?.  =((lent params.d) (lent vs))
    [%| 0 (rap 3 ~['wrong number of arguments to ' name.d])]
  =/  names  (turn params.d |=(p=spar:sm name.p))
  (eval u.body.d (bind-names e(fuel (dec fuel.e)) names vs))
::
++  binding-of
  ::  what an operator resolves to, mirroring the oracle's BINDINGS
  ::  projection (ModuleOpDump): a Java override, its TLA+ body, or nothing
  |=  [e=eenv nm=@t ar=@ud]
  ^-  ?(%override %body %none)
  =/  d  (~(get by ops.e) nm)
  ?~  d  %none
  =/  key=op-key:so  [origin.u.d nm ar]
  ?^  (lookup:so ov.e key)  %override
  ?^  (node-op:so key)  %override
  ?:  (is-descriptor:so key)  %override
  ?:  ?&  (is-standard:so ov.e origin.u.d)
          !(body-allowed:so ov.e origin.u.d nm)
      ==
    %none
  ?~(body.u.d %none %body)
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
++  oparg-name
  ::  the operator an argument names. A bare reference to an operator of
  ::  nonzero arity is generated as SANY's OpArgNode — the reserved `$OpArg`
  ::  apply whose `ubound` carries the referenced name (lib/semantic
  ::  +oparg-of); a nullary reference is the name itself
  |=  n=sem:sm
  ^-  @t
  ?.  ?=(%apply -.n)  ''
  ?.  =('$OpArg' name.op.n)  name.op.n
  ?~(ubound.n '' name.i.ubound.n)
::
++  resolve-oparg
  ::  an operator passed as an argument: a bare reference to a known op
  |=  [n=sem:sm e=eenv]
  ^-  (unit sem-def:sm)
  =/  nm  (oparg-name n)
  ?:  =('' nm)  ~
  (~(get by ops.e) nm)
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
::  +|  Action Solving (WU6.7): initial and successor state streams
::
::  `solve` walks an action predicate the way tlc2's getInitStates/
::  getNextStates + ActionItemList do: a conjunction threads the partial
::  state, a disjunction branches, a bounded \E branches over its domain, an
::  equality whose left side is an ASSIGNABLE state variable (an unprimed var
::  in %init, a primed var in %next, not yet bound) ASSIGNS it, every other
::  boolean sub-expression FILTERS (prune the branch when false). The partial
::  state is `part`; for %init it is read under plain names (the state being
::  built), for %next it is the successor read under a prime while `cur` is
::  the fixed current state. Assignment vs filtering is decided by resolved
::  variable identity, never by rendered names. Branch and binding order
::  match Java so the ordered stream is comparable.
::
++  senv
  ::  the evaluation env for a filter/rhs during solving
  |=  [mode=?(%init %next) cur=state part=state e=eenv]
  ^-  eenv
  ?:  =(%init mode)  e(s0 part, s1 ~, primed |)
  e(s0 cur, s1 part, primed |)
::
++  deref-sem
  ::  resolve a call-by-name parameter to the argument node it was bound to
  ::  (R1.5.1); non-params and unbound params pass through. Substituted nodes
  ::  are always plain variable references, so chasing cannot self-loop.
  |=  [n=sem:sm psub=(map @t sem:sm)]
  ^-  sem:sm
  ?.  ?=(%apply -.n)  n
  ?.  ?=(%formal-param kind.op.n)  n
  ?.  ?=(~ args.n)  n
  =/  s  (~(get by psub) name.op.n)
  ?~(s n $(n u.s))
::
++  deref-letin
  ::  unwrap a LET whose body just names one of its own 0-ary definitions:
  ::  `LET y == a' IN y` denotes the same occurrence as `a'`. tlc2's Tool
  ::  pushes a LetInNode's definitions into the context and recurses on the
  ::  body in action position, so a primed variable reached through a LET
  ::  binding is still the action's assignment target (R1.5.9)
  |=  n=sem:sm
  ^-  sem:sm
  =/  cur  n
  |-  ^-  sem:sm
  ?.  ?=(%letin -.cur)  cur
  ?~  body.cur  cur
  =/  b  u.body.cur
  ?.  ?=(%apply -.b)  cur
  ?.  ?=(~ args.b)  cur
  =/  hit
    =/  ls  lets.cur
    |-  ^-  (unit sem:sm)
    ?~  ls  ~
    ?:  &(=(name.i.ls name.op.b) =(0 arity.i.ls))  body.i.ls
    $(ls t.ls)
  ?~  hit  cur
  $(cur u.hit)
::
++  assignable-sem
  ::  the variable name assigned by `lhs`, if it is an unbound assignable
  |=  $:  lhs=sem:sm  mode=?(%init %next)  vars=(set @t)
          part=state  psub=(map @t sem:sm)
      ==
  ^-  (unit @t)
  =.  lhs  (deref-sem lhs psub)
  ::  a LET-wrapped target resolves to the same assignable (R1.5.9)
  =.  lhs  (deref-sem (deref-letin lhs) psub)
  ?.  ?=(%apply -.lhs)  ~
  =/  nm=(unit @t)
    ?:  =(%next mode)
      ?.  =('\'' name.op.lhs)  ~
      =/  a  (deref-sem (snag 0 args.lhs) psub)
      ?.  ?=(%apply -.a)  ~
      ?.  ?=(%variable kind.op.a)  ~
      `name.op.a
    ?.  ?=(%variable kind.op.lhs)  ~
    `name.op.lhs
  ?~  nm  ~
  ?.  (~(has in vars) u.nm)  ~
  ?:  (~(has by part) u.nm)  ~
  nm
::
++  unchanged-vars
  ::  the variable names of UNCHANGED e (a variable or a tuple of variables)
  |=  n=sem:sm
  ^-  (list @t)
  ?.  ?=(%apply -.n)  ~
  ?:  ?=(%variable kind.op.n)  ~[name.op.n]
  ?.  =('$Tuple' name.op.n)  ~
  %+  murn  args.n
  |=  a=sem:sm
  ?:(&(?=(%apply -.a) ?=(%variable kind.op.a)) `name.op.a ~)
::
++  complete
  |=  [st=state vars=(set @t)]
  ^-  ?
  (levy ~(tap in vars) |=(nm=@t (~(has by st) nm)))
::
++  drain-sexp
  ::  the domain's elements in TLC enumeration order (branch order)
  |=  x=sexp:v
  ^-  (each (list value:v) eval-err:v)
  =/  rc  (enum:v x)
  ?:  ?=(%| -.rc)  rc
  =|  acc=(list value:v)
  =/  cur  p.rc
  |-  ^-  (each (list value:v) eval-err:v)
  =/  st  (enum-next:v cur)
  =/  es  -.st
  ?-  -.es
    %done  [%& (flop acc)]
    %item  $(acc [v.es acc], cur +.st)
  ==
::
++  state-var-ref
  ::  the node is a bare reference to a declared state variable
  |=  [n=sem:sm e=eenv]
  ^-  ?
  =.  n  (deref-sem n psub.e)
  ?.  ?=(%apply -.n)  |
  ?.  ?=(~ args.n)  |
  ?.  ?=(%variable kind.op.n)  |
  (~(has in vars.e) name.op.n)
::
++  bind-psub
  ::  bind an operator's parameters for solving: a bare state-variable argument
  ::  is kept as a NODE (call-by-name, so it stays assignable in the body); an
  ::  operator argument resolves through `ops`; any other value argument is
  ::  evaluated once in the caller env and bound through `vals`
  |=  [e=eenv ps=(list spar:sm) as=(list sem:sm)]
  ^-  (each eenv eval-err:v)
  ?~  ps  [%& e]
  ?~  as  [%& e]
  ?:  (gth arity.i.ps 0)
    =/  od  (resolve-oparg i.as e)
    ?~  od  [%| 0 'unsupported operator-valued argument.']
    $(ps t.ps, as t.as, e e(ops (~(put by ops.e) name.i.ps u.od)))
  ?:  (state-var-ref i.as e)
    $(ps t.ps, as t.as, e e(psub (~(put by psub.e) name.i.ps i.as)))
  ?.  used.i.ps
    $(ps t.ps, as t.as)
  =/  av  (eval i.as e)
  ?:  ?=(%| -.av)  av
  $(ps t.ps, as t.as, e e(vals (~(put by vals.e) name.i.ps p.av)))
::
++  solve
  |=  [n=sem:sm mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  ?.  ?=(%apply -.n)
    ?:  ?=(%letin -.n)  (solve-letin n mode cur part e)
    (solve-filter n mode cur part e)
  =/  nm  name.op.n
  ?:  |(=(nm '$ConjList') =(nm '\\land'))
    (solve-conj args.n mode cur part e)
  ?:  |(=(nm '$DisjList') =(nm '\\lor'))
    (solve-disj args.n mode cur part e)
  ?:  =(nm '$IfThenElse')  (solve-ite args.n mode cur part e)
  ?:  =(nm '$BoundedExists')  (solve-exists n mode cur part e)
  ?:  =(nm '$BoundedForall')  (solve-forall n mode cur part e)
  ?:  =(nm 'UNCHANGED')  (solve-unchanged (snag 0 args.n) mode cur part e)
  ?:  =(nm '=')
    =/  as  (assignable-sem (snag 0 args.n) mode vars.e part psub.e)
    ?~  as  (solve-filter n mode cur part e)
    =/  rv  (eval (snag 1 args.n) (senv mode cur part e))
    ?:  ?=(%| -.rv)  rv
    [%& ~[(~(put by part) u.as p.rv)]]
  ::  `x \in S` on an unbound assignable var is a NONDETERMINISTIC assignment:
  ::  enumerate S in TLC order, one successor per element (init + next). Any
  ::  other `\in` (a bound var, a membership filter) prunes as a boolean.
  ?:  =(nm '\\in')
    =/  as  (assignable-sem (snag 0 args.n) mode vars.e part psub.e)
    ?~  as  (solve-filter n mode cur part e)
    =/  sd  (eval-domain (snag 1 args.n) (senv mode cur part e))
    ?:  ?=(%| -.sd)  sd
    =/  els  (drain-sexp p.sd)
    ?:  ?=(%| -.els)  els
    [%& (turn p.els |=(x=value:v (~(put by part) u.as x)))]
  ::  `x \subseteq S` on an unbound assignable var enumerates the powerset of S
  ::  as candidate assignments (the set-valued sibling of `\in`)
  ?:  =(nm '\\subseteq')
    =/  as  (assignable-sem (snag 0 args.n) mode vars.e part psub.e)
    ?~  as  (solve-filter n mode cur part e)
    =/  rv  (eval (snag 1 args.n) (senv mode cur part e))
    ?:  ?=(%| -.rv)  rv
    =/  els  (drain-sexp [%subset p.rv])
    ?:  ?=(%| -.els)  els
    [%& (turn p.els |=(x=value:v (~(put by part) u.as x)))]
  ::  a user-op reference in action position is expanded to its body and solved
  ::  (e.g. `Next == Inc \/ Dec`), so a primed variable in the body is not
  ::  filtered as a boolean. Parameters are bound call-by-name (`+bind-psub`):
  ::  an assignable variable passed as an argument (`Init(s)`, `Next(s)`) stays
  ::  assignable, mirroring tlc2's Context substitution.
  ?:  ?=(%user-op kind.op.n)
    =/  d  (~(get by ops.e) nm)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  (solve-filter n mode cur part e)
    ?.  =((lent params.u.d) (lent args.n))  (solve-filter n mode cur part e)
    ?:  =(0 fuel.e)  [%| 0 'evaluation recursion/resource limit exceeded.']
    =/  e2  (bind-psub e(fuel (dec fuel.e)) params.u.d args.n)
    ?:  ?=(%| -.e2)  e2
    (solve u.body.u.d mode cur part p.e2)
  (solve-filter n mode cur part e)
::
++  solve-filter
  |=  [n=sem:sm mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  =/  b  (eval-bool n (senv mode cur part e))
  ?:  ?=(%| -.b)  b
  ?:(p.b [%& ~[part]] [%& ~])
::
++  solve-letin
  |=  [n=sem-letin:sm mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  ?~  body.n  [%| 0 'LET with no body in an action.']
  =/  e2=eenv
    =/  os  ops.e
    |-  ^-  eenv
    ?~  lets.n  e(ops os)
    $(lets.n t.lets.n, os (~(put by os) name.i.lets.n i.lets.n))
  (solve u.body.n mode cur part e2)
::
++  solve-conj
  ::  thread the partial state left-to-right across the conjuncts
  |=  [cs=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  =/  acc=(list state)  ~[part]
  |-  ^-  sres
  ?~  cs  [%& acc]
  =/  step  (solve-each i.cs mode cur acc e)
  ?:  ?=(%| -.step)  step
  $(cs t.cs, acc p.step)
::
++  solve-each
  ::  solve `n` from every partial state, concatenating results in order
  |=  [n=sem:sm mode=?(%init %next) cur=state parts=(list state) e=eenv]
  ^-  sres
  =|  out=(list state)
  |-  ^-  sres
  ?~  parts  [%& out]
  =/  r  (solve n mode cur i.parts e)
  ?:  ?=(%| -.r)  r
  $(parts t.parts, out (weld out p.r))
::
++  solve-disj
  ::  branch: each disjunct solved from the same partial state, in order
  |=  [ds=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  =|  out=(list state)
  |-  ^-  sres
  ?~  ds  [%& out]
  =/  r  (solve i.ds mode cur part e)
  ?:  ?=(%| -.r)  r
  $(ds t.ds, out (weld out p.r))
::
++  solve-ite
  |=  [as=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  =/  b  (eval-bool (snag 0 as) (senv mode cur part e))
  ?:  ?=(%| -.b)  b
  (solve ?:(p.b (snag 1 as) (snag 2 as)) mode cur part e)
::
++  solve-exists
  ::  \E x \in S : A — branch over the domain in enumeration order
  |=  [n=sem-apply:sm mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)
    [%| 0 'an action existential over multiple binders is unsupported.']
  =/  sd  (eval-domain rng.i.bs (senv mode cur part e))
  ?:  ?=(%| -.sd)  sd
  =/  els  (drain-sexp p.sd)
  ?:  ?=(%| -.els)  els
  =/  body  (snag 0 args.n)
  =|  out=(list state)
  =/  xs  p.els
  |-  ^-  sres
  ?~  xs  [%& out]
  =/  e2  (bind-group e i.bs i.xs)
  =/  r  (solve body mode cur part e2)
  ?:  ?=(%| -.r)  r
  $(xs t.xs, out (weld out p.r))
::
++  solve-forall
  ::  \A x \in S : A — a bounded universal in action position is the
  ::  conjunction of A over the domain (tlc2 expands a bounded \A the same way
  ::  in getInitStates/getNextStates); thread the partial state through each
  ::  element in enumeration order, so `x = e` on the first element assigns and
  ::  a later element filters against it
  |=  [n=sem-apply:sm mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)
    [%| 0 'an action universal over multiple binders is unsupported.']
  =/  sd  (eval-domain rng.i.bs (senv mode cur part e))
  ?:  ?=(%| -.sd)  sd
  =/  els  (drain-sexp p.sd)
  ?:  ?=(%| -.els)  els
  =/  body  (snag 0 args.n)
  =/  acc=(list state)  ~[part]
  =/  xs  p.els
  |-  ^-  sres
  ?~  xs  [%& acc]
  =/  e2  (bind-group e i.bs i.xs)
  =/  step  (solve-each body mode cur acc e2)
  ?:  ?=(%| -.step)  step
  $(xs t.xs, acc p.step)
::
++  solve-unchanged
  ::  UNCHANGED e assigns each named variable to its current value
  |=  [arg=sem:sm mode=?(%init %next) cur=state part=state e=eenv]
  ^-  sres
  =/  names  (unchanged-vars arg)
  =/  out=state  part
  =.  out
    |-  ^-  state
    ?~  names  out
    =/  cv  (~(get by cur) i.names)
    ?~  cv  $(names t.names)
    $(names t.names, out (~(put by out) i.names u.cv))
  [%& ~[out]]
::
++  eval-enabled
  ::  ENABLED A: a successor satisfying A exists from the current state; the
  ::  witness is discarded (EvalControl.Enabled). Primed variables the action
  ::  does not constrain are existentially free (tlc2's Tool.enabled), so any
  ::  satisfying PARTIAL assignment enables A — completeness is not required.
  |=  [n=sem:sm e=eenv]
  ^-  eres
  =/  r  (solve n %next s0.e ~ e(enabled &))
  ?:  ?=(%| -.r)  r
  [%& [%bool ?=(^ p.r)]]
::
::  +|  Test / Driver Entrypoints
::
++  defmap-of
  ::  the operators visible inside a module: everything inherited through
  ::  EXTENDS first, then the module's own definitions, so a local
  ::  definition shadows an imported one of the same name (unit 6C.1)
  |=  m=sem-module:sm
  ^-  (map @t sem-def:sm)
  =/  acc
    =|  acc=(map @t sem-def:sm)
    =/  is  imports.m
    |-  ^-  (map @t sem-def:sm)
    ?~  is  acc
    $(is t.is, acc (~(put by acc) name.i.is i.is))
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
  (eval u.body.u.d (base-env u.mo ~ ~))
::
++  binding-in
  ::  what `nm` applied to `ar` arguments resolves to inside module `root`
  ::  — the Hoon side of the oracle's BINDINGS projection (ModuleOpDump),
  ::  so registry-vs-body resolution is differentially checkable
  |=  [root=@t src=(map @t @t) nm=@t ar=@ud]
  ^-  ?(%override %body %none %nograph)
  =/  mo  (generate:sm root src)
  ?~  mo  %nograph
  (binding-of (base-env u.mo ~ ~) nm ar)
::
++  vars-of
  |=  mo=sem-module:sm
  ^-  (set @t)
  (silt (turn vars.mo |=([nm=@t at=sspan:sm] nm)))
::
++  base-env
  ::  the initial environment for a module's definitions under given states
  |=  [mo=sem-module:sm s0=state s1=state]
  ^-  eenv
  [~ (defmap-of mo) ~ default-fuel s0 s1 | | (vars-of mo) ~ make-senv:so]
::
++  eval-pred
  ::  evaluate the boolean definition `nm` under current/successor states
  ::  (a constant predicate: empty states; a state predicate: only s0; a
  ::  fully-assigned action predicate: both). The result must be boolean.
  |=  [root=@t src=(map @t @t) nm=@t s0=state s1=state]
  ^-  (each ? eval-err:v)
  =/  mo  (generate:sm root src)
  ?~  mo  [%| 0 'semantic graph generation failed.']
  =/  d  (~(get by (defmap-of u.mo)) nm)
  ?~  d  [%| 0 'definition not found.']
  ?~  body.u.d  [%| 0 'definition has no body.']
  (eval-bool u.body.u.d (base-env u.mo s0 s1))
::
++  solve-init
  ::  the complete ordered stream of initial states satisfying `nm`; every
  ::  state must assign all variables, else a typed incomplete-init failure
  |=  [root=@t src=(map @t @t) nm=@t]
  ^-  sres
  =/  mo  (generate:sm root src)
  ?~  mo  [%| 0 'semantic graph generation failed.']
  =/  d  (~(get by (defmap-of u.mo)) nm)
  ?~  d  [%| 0 'definition not found.']
  ?~  body.u.d  [%| 0 'definition has no body.']
  =/  e  (base-env u.mo ~ ~)
  =/  r  (solve u.body.u.d %init ~ ~ e)
  ?:  ?=(%| -.r)  r
  ?.  (levy p.r |=(st=state (complete st vars.e)))
    [%| 0 'incomplete initial state: a variable is unassigned.']
  [%& p.r]
::
++  solve-next
  ::  the complete ordered stream of successor states of `cur` under `nm`
  |=  [root=@t src=(map @t @t) nm=@t cur=state]
  ^-  sres
  =/  mo  (generate:sm root src)
  ?~  mo  [%| 0 'semantic graph generation failed.']
  =/  d  (~(get by (defmap-of u.mo)) nm)
  ?~  d  [%| 0 'definition not found.']
  ?~  body.u.d  [%| 0 'definition has no body.']
  =/  e  (base-env u.mo cur ~)
  =/  r  (solve u.body.u.d %next cur ~ e)
  ?:  ?=(%| -.r)  r
  ?.  (levy p.r |=(st=state (complete st vars.e)))
    [%| 0 'incomplete next state: a variable is unassigned.']
  [%& p.r]
::
++  make-env
  ::  a static evaluation environment from a module's operator definitions,
  ::  the config constant assignments, and the declared variables (WU6.9: the
  ::  context the checker builds once and reuses across the BFS)
  |=  [defs=(map @t sem-def:sm) consts=(map @t value:v) vars=(set @t)]
  ^-  eenv
  [consts defs ~ default-fuel ~ ~ | | vars ~ make-senv:so]
::
++  init-states
  ::  the complete initial-state stream for an Init BODY under a prebuilt env
  |=  [body=sem:sm e=eenv]
  ^-  sres
  =/  r  (solve body %init ~ ~ e)
  ?:  ?=(%| -.r)  r
  ?.  (levy p.r |=(st=state (complete st vars.e)))
    [%| 0 'incomplete initial state: a variable is unassigned.']
  [%& p.r]
::
++  next-states
  ::  the complete successor stream of `cur` for a Next BODY under a prebuilt
  ::  env (the checker's per-state call; the graph is generated once, upstream)
  |=  [cur=state body=sem:sm e=eenv]
  ^-  sres
  =/  r  (solve body %next cur ~ e(s0 cur))
  ?:  ?=(%| -.r)  r
  ?.  (levy p.r |=(st=state (complete st vars.e)))
    [%| 0 'incomplete next state: a variable is unassigned.']
  [%& p.r]
::
++  pred-bool
  ::  a state/action predicate BODY as a boolean under given states
  |=  [body=sem:sm s0=state s1=state e=eenv]
  ^-  (each ? eval-err:v)
  (eval-bool body e(s0 s0, s1 s1))
::
++  render-states
  ::  a stable rendering of a state stream for differential comparison:
  ::  each state as "k=<v>,…" (vars sorted), states in stream order
  |=  sts=(list state)
  ^-  (list tape)
  %+  turn  sts
  |=  st=state
  =/  ps  (sort ~(tap by st) |=([a=[k=@t *] b=[k=@t *]] (aor k.a k.b)))
  %+  roll  ps
  |=  [[k=@t val=value:v] acc=tape]
  =/  piece  "{(trip k)}={(render:v val)}"
  ?~(acc piece "{acc},{piece}")
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
++  fp-of-text
  ::  the canonical FP64 input bytes of a constant expression (WU6.8), driven
  ::  by text so no value crosses a low-budget test core
  |=  txt=@t
  ^-  (list @D)
  =/  src=@t
    %-  crip
    ;:  weld
      "---- MODULE E ----\0a"
      "EXTENDS Integers, Sequences, FiniteSets\0a"
      "Expr == {(trip txt)}\0a====\0a"
    ==
  =/  r  (eval-module-def 'E' (malt ~[['E' src]]) 'Expr')
  ?:(?=(%| -.r) ~ (fp-input:v p.r))
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
