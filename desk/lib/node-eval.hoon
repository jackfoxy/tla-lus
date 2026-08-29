/-  *tla-lus
/=  v   /lib/value
/=  sm  /lib/semantic
/=  so  /lib/stdops
/=  rg  /lib/rng
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
      ::  the run's `max-set-size` (tlc2 `-maxSetSize`); 0 = engine default.
      ::  Carried on the env because the bound bites where a lazy set is
      ::  MATERIALIZED, deep inside evaluation (R2.4.1)
      setmax=@ud
      ::  the StandardModule override registry, built once per environment
      ::  (unit 6C.1); rebuilding the table inside an evaluation loop would
      ::  cost a map construction per operator application
      ov=senv:so
      ::  the live run statistics `TLC!TLCGet` reads (R2.6.1). `~` means no
      ::  checker is running -- a constant expression or the REPL -- which is
      ::  where the pin's `TLCGlobals.mainChecker` is null and every statistic
      ::  key raises EC 2145. These CHANGE during the search, so a caller
      ::  rebuilds them per expansion rather than once per run
      ::  (the mold lives in lib/stdops, which cannot import this file)
      run=(unit tlc-run:so)
  ==
+$  eres  (each value:v eval-err:v)
::  the action solver yields the ordered list of complete states satisfying
::  an action; a typed failure short-circuits (matching tlc2's stream)
+$  sres  (each (list state) eval-err:v)
::  +|  The Run Carrier (R2.7.4.1)
::
::  `eenv` is read-only by construction, so nothing an evaluation MUTATES can
::  escape through it. Three consumers need exactly that -- a register store
::  `TLCSet` writes and `TLCGet(int)` reads back, an RNG that must advance
::  across draws inside ONE evaluation, and the initial-state coverage counter
::  -- so the mutable run state rides the RETURN instead, threaded by `=^`.
::
::  It is carried on BOTH branches of a result, never inside the success
::  branch: a write that precedes a CAUGHT failure (`TLCExt!AssertError`) is
::  still a write at the pin, which mutated a Java field before throwing.
::
::  `rst` is NOT part of the checked state and never enters a fingerprint: it
::  is worker-local side-channel state, which is what `IdThread.setLocalValue`
::  is at the pin.
+$  rst
  $:  ::  the `TLCSet` register store (R2.7.4.3)
      regs=(map @ud value:v)
      ::  `java.util.Random` state for Randomization/RandomElement
      ::  (R2.7.4.4/.5), the same seed `+next-int-bound:rg` advances
      es=@
      ::  initial-state candidates rejected by a conjunct evaluated once the
      ::  state was ALREADY FULLY ASSIGNED -- the `secondary` half of the INIT
      ::  coverage line, which is what `SafetyDump` projects (R2.7.4.2b).
      ::  Measured at the pin: `x \in 0..3 /\ y = 0 /\ x > 1` reports 2:4,
      ::  the same conjuncts reordered so the rejection happens while `y` is
      ::  still unassigned reports 2:2 (`Tool.getInitStates`'s allAssigned
      ::  branch is the only site that increments it)
      irej=@ud
  ==
::  a solver result carrying the run state, and its evaluator sibling. UNFACED,
::  like `[pres pst]` on the `-generate` path: a face on the head leaks into
::  whatever `=^` binds, so `p.r` on the bound result stops resolving
+$  sout  [sres rst]
+$  eout  [eres rst]
++  empty-rst  ^-(rst [~ 0 0])
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
  ::  the carrier-discarding wrapper (R2.7.4.1). The ~100 call sites that do
  ::  not care about run state -- every test entrypoint, every constant-level
  ::  evaluation -- keep this shape; the paths that must see a `TLCSet` write
  ::  or an advanced RNG seed take `+eval-rs`
  |=  [n=sem:sm e=eenv]
  ^-  eres
  -:(eval-rs n e empty-rst)
::
++  eval-rs
  |=  [n=sem:sm e=eenv rs=rst]
  ^-  eout
  ?-  -.n
    %lit      [(eval-lit n) rs]
    %atref    ?~(atv.e [[%| 0 'no @ value in scope.'] rs] [[%& u.atv.e] rs])
    %nullodn  [[%| 0 'unresolved operator (nullODN).'] rs]
    %letin    (eval-letin n e rs)
    %apply    (eval-apply-rs n e rs)
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
++  eval-apply-rs
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  =/  nm  name.op.n
  =/  kd  kind.op.n
  ?:  ?=(%builtin kd)  (eval-builtin-rs n e rs)
  ?-  kd
      %constant      (apply-const nm n e rs)
      %new-constant  (apply-const nm n e rs)
      %user-op       (eval-user n e rs)
      %formal-param
    ?.  =(~ args.n)  (eval-user n e rs)
    ::  a param bound call-by-name (a substituted argument node) is evaluated
    ::  in place; otherwise it is a value parameter resolved from `vals`
    =/  sb  (~(get by psub.e) nm)
    ?~(sb [(lookup-val nm e) rs] (eval-rs u.sb e rs))
  ::
    ::  a substituted name resolves to the node it was bound to, in the
    ::  OUTER scope -- `v <- x` makes the inner module's `v` read the outer
    ::  state's `x`. Same call-by-name shape `%formal-param` uses (R2.3.5)
      %variable
    =/  sb  (~(get by psub.e) nm)
    ?~(sb [(lookup-var nm e) rs] (eval-rs u.sb e rs))
  ::
    %thm-assump       [[%| 0 'a theorem/assumption is not an evaluable value.'] rs]
    %module-instance  [[%| 0 'a module instance is not an evaluable value.'] rs]
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
  |=  [nm=@t n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?~  args.n  [(lookup-val nm e) rs]
  =/  fv  (~(get by vals.e) nm)
  ?~  fv  [[%| 0 (rap 3 ~['undefined identifier: ' nm])] rs]
  =^  as  rs  (eval-args-rs args.n e rs)
  ?:  ?=(%| -.as)  [as rs]
  =/  dp=value:v  ?:(=(1 (lent p.as)) (snag 0 p.as) [%seq p.as])
  [(apply:v u.fv dp |) rs]
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
  ::  the carrier-discarding wrapper (R2.7.4.1b), kept for the arms that have
  ::  not been converted yet and for the ~100 call sites outside this file
  |=  [as=(list sem:sm) e=eenv]
  ^-  (each (list value:v) eval-err:v)
  -:(eval-args-rs as e empty-rst)
::
+$  ares  (each (list value:v) eval-err:v)
+$  aout  [ares rst]
::
++  eval-args-rs
  ::  arguments are evaluated LEFT TO RIGHT and each one's effect on the run
  ::  state is visible to the next, which is tlc2's order too -- `Tool.eval`
  ::  walks `args[i]` in index order against the same worker
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  aout
  =|  acc=(list value:v)
  |-  ^-  aout
  ?~  as  [[%& (flop acc)] rs]
  =^  r  rs  (eval-rs i.as e rs)
  ?:  ?=(%| -.r)  [r rs]
  $(as t.as, acc [p.r acc])
::
++  eval-bool
  ::  the carrier-discarding wrapper (R2.7.4.1b)
  |=  [n=sem:sm e=eenv]
  ^-  (each ? eval-err:v)
  -:(eval-bool-rs n e empty-rst)
::
+$  bres  (each ? eval-err:v)
+$  bout  [bres rst]
::
++  eval-bool-rs
  |=  [n=sem:sm e=eenv rs=rst]
  ^-  bout
  =^  r  rs  (eval-rs n e rs)
  ?:  ?=(%| -.r)  [r rs]
  ?.  ?=(%bool -.p.r)
    :_  rs
    [%| 0 (rap 3 ~['a non-boolean was used where a boolean is required: ' (crip (render:v p.r))])]
  [[%& p.p.r] rs]
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
  (force:v p.s setmax.e)
::
::  +|  Builtin Dispatch
::
++  eval-builtin
  ::  the carrier-discarding wrapper (R2.7.4.1b)
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  -:(eval-builtin-rs n e empty-rst)
::
++  eval-builtin-rs
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  =/  nm  name.op.n
  =/  as  args.n
  ::  arity-0 constants
  ?:  =(nm 'TRUE')     [[%& [%bool &]] rs]
  ?:  =(nm 'FALSE')    [[%& [%bool |]] rs]
  ?:  =(nm 'BOOLEAN')  [[%& [%set %set-enum ~[[%bool |] [%bool &]]]] rs]
  ::  equality and logic
  ?:  =(nm '=')        (bi-eq as e | rs)
  ?:  =(nm '/=')       (bi-eq as e & rs)
  ?:  |(=(nm '\\lnot') =(nm '\\neg'))  (un-not as e rs)
  ?:  =(nm '\\land')   (eval-conj ~[(snag 0 as) (snag 1 as)] e rs)
  ?:  =(nm '\\lor')    (eval-disj ~[(snag 0 as) (snag 1 as)] e rs)
  ?:  =(nm '$ConjList')  (eval-conj as e rs)
  ?:  =(nm '$DisjList')  (eval-disj as e rs)
  ?:  =(nm '=>')       (bi-imply as e rs)
  ?:  =(nm '\\equiv')  (bi-equiv as e rs)
  ::  membership
  ?:  =(nm '\\in')     (bi-in as e | rs)
  ?:  =(nm '\\notin')  (bi-in as e & rs)
  ::  `\subseteq` reaches the operands only through `+eval-domain`, which is
  ::  BELOW the carrier boundary (see the note on that arm), so there is
  ::  nothing for it to thread
  ?:  =(nm '\\subseteq')  [(bi-subseteq as e) rs]
  ::  prime and UNCHANGED (state/action; WU6.6)
  ?:  =(nm '\'')          (eval-rs (snag 0 as) e(primed &) rs)
  ?:  =(nm 'UNCHANGED')   (eval-unchanged as e rs)
  ?:  =(nm 'ENABLED')     [(eval-enabled (snag 0 as) e) rs]
  ::  set constructors (forced when used as a value)
  ?:  (~(has in set-ctor-names) nm)
    ::  a set constructor whose operand fails to evaluate is a typed failure,
    ::  not an assertion: `s \ {CHOOSE y \in s : TRUE}` with an empty `s` used
    ::  to crash the evaluator through +need-sexp's ?>, which a recursive
    ::  function definition reaches whenever a sweep tries a point it cannot
    ::  yet solve (R1.4.2)
    =/  sx  (eval-domain n e)
    ?:  ?=(%| -.sx)  [sx rs]
    [(force:v p.sx setmax.e) rs]
  ?:  =(nm 'DOMAIN')
    =^  a  rs  (eval-rs (snag 0 as) e rs)
    ?:  ?=(%| -.a)  [a rs]
    ::  tlc2 returns the domain VALUE the function was built from, unchanged,
    ::  so `DOMAIN [i \in 1..3 |-> i]` is an IntervalValue while
    ::  `DOMAIN [i \in {1, 2, 3} |-> i]` is a SetEnumValue for the same set --
    ::  provenance, not shape. The port's `%fcn` does not carry its domain, so
    ::  recover it from the EXPRESSION where the expression reaches a
    ::  constructor; otherwise fall back to enumerating the pairs (R1.4.5b)
    ?.  ?=(%fcn -.p.a)  [(domain:v p.a) rs]
    =/  de  (domain-expr (snag 0 as) e 8)
    :_  rs
    ?~(de (domain:v p.a) [%& u.de])
  ::  functions, tuples, records
  ?:  =(nm '$FcnApply')   (eval-fcnapply as e rs)
  ?:  =(nm '$Except')     (eval-except n e rs)
  ?:  =(nm '$SetEnumerate')  (eval-setenum as e rs)
  ?:  =(nm '$Tuple')      (eval-tuple as e rs)
  ?:  =(nm '$RcdConstructor')  (eval-rcd as e rs)
  ?:  =(nm '$RcdSelect')  (eval-rcd-select as e rs)
  ::  control
  ?:  =(nm '$IfThenElse')  (eval-ite as e rs)
  ?:  =(nm '$Case')       (eval-case as e rs)
  ::  BINDERS ARE BELOW THE CARRIER BOUNDARY (R2.7.4.1b). Each of these hands
  ::  a per-element gate to a STREAMING combinator in `lib/value.hoon`
  ::  (`all-ctx`, `ex-ctx`, `choose-over`, `filter-over`, `map-over`,
  ::  `fcn-over`, `ctx-map`, `ctx-fcn`), which decides if and when to call it;
  ::  a gate cannot thread `rst` back out through a combinator that does not
  ::  carry one. Threading them means reshaping the whole lazy set layer, and
  ::  that is a change to `lib/value.hoon`, not to this file -- see the notes
  ::  for what R2.7.4.3/.4 must do about it
  ?:  =(nm '$BoundedForall')  [(eval-forall n e) rs]
  ?:  =(nm '$BoundedExists')  [(eval-exists n e) rs]
  ?:  =(nm '$BoundedChoose')  [(eval-choose n e) rs]
  ?:  =(nm '$SubsetOf')   [(eval-subsetof n e) rs]
  ?:  =(nm '$SetOfAll')   [(eval-setofall n e) rs]
  ?:  |(=(nm '$FcnConstructor') =(nm '$NonRecursiveFcnSpec'))
    [(eval-fcncon n e) rs]
  ?:  =(nm '$RecursiveFcnSpec')  [(eval-recfcn n e) rs]
  ::  INSTANCE substitution (R2.3.5): `$SubstIn:M` / `$APSubstIn:M` wraps an
  ::  instanced member's body in the instance's `WITH` bindings. tlc2 threads
  ::  these as a `Context` (`Specs.addSubsts` / `SubstInNode`); the port binds
  ::  them into the environment and evaluates the inner body
  ?^  (anysubstin-mod:sm nm)
    =/  sp  (substin-parts:sm n)
    ?~  sp  [[%| 0 (rap 3 ~['malformed substitution wrapper: ' nm])] rs]
    =/  e2  (bind-substs e names.u.sp exprs.u.sp)
    ?:  ?=(%| -.e2)  [e2 rs]
    (eval-rs inner.u.sp p.e2 rs)
  [[%| 0 (rap 3 ~['unsupported builtin operator: ' nm])] rs]
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
  |=  [as=(list sem:sm) e=eenv neg=? rs=rst]
  ^-  eout
  =^  a  rs  (eval-rs (snag 0 as) e rs)
  ?:  ?=(%| -.a)  [a rs]
  =^  b  rs  (eval-rs (snag 1 as) e rs)
  ?:  ?=(%| -.b)  [b rs]
  =/  r  (val-eq:v p.a p.b)
  ?:  ?=(%| -.r)  [r rs]
  [[%& [%bool ?:(neg !p.r p.r)]] rs]
::
++  un-not
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  b  rs  (eval-bool-rs (snag 0 as) e rs)
  ?:(?=(%| -.b) [b rs] [[%& [%bool !p.b]] rs])
::
++  bi-imply
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  a  rs  (eval-bool-rs (snag 0 as) e rs)
  ?:  ?=(%| -.a)  [a rs]
  ::  short-circuit: a FALSE antecedent leaves the consequent unevaluated, so
  ::  a write inside it does not happen -- which is tlc2's behaviour too
  ?.  p.a  [[%& [%bool &]] rs]
  =^  b  rs  (eval-bool-rs (snag 1 as) e rs)
  ?:(?=(%| -.b) [b rs] [[%& [%bool p.b]] rs])
::
++  bi-equiv
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  a  rs  (eval-bool-rs (snag 0 as) e rs)
  ?:  ?=(%| -.a)  [a rs]
  =^  b  rs  (eval-bool-rs (snag 1 as) e rs)
  ?:(?=(%| -.b) [b rs] [[%& [%bool =(p.a p.b)]] rs])
::
++  eval-unchanged
  ::  UNCHANGED e is e' = e: the successor value of e equals its current
  ::  value (tuples and composites compare structurally via +val-eq)
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  cur  rs  (eval-rs (snag 0 as) e(primed |) rs)
  ?:  ?=(%| -.cur)  [cur rs]
  =^  nxt  rs  (eval-rs (snag 0 as) e(primed &) rs)
  ?:  ?=(%| -.nxt)  [nxt rs]
  =/  r  (val-eq:v p.nxt p.cur)
  ?:  ?=(%| -.r)  [r rs]
  [[%& [%bool p.r]] rs]
::
++  bi-in
  |=  [as=(list sem:sm) e=eenv neg=? rs=rst]
  ^-  eout
  =^  x  rs  (eval-rs (snag 0 as) e rs)
  ?:  ?=(%| -.x)  [x rs]
  =/  s  (eval-domain (snag 1 as) e)
  ?:  ?=(%| -.s)  [s rs]
  =/  m  (set-member:v p.x p.s)
  ?:  ?=(%| -.m)  [m rs]
  [[%& [%bool ?:(neg !p.m p.m)]] rs]
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
  ::  `+conj-list:v`'s short-circuit, inlined so the run state threads from
  ::  one conjunct to the NEXT. That threading is the whole point of the
  ::  carrier: measured at the pin, a `TLCSet` write is visible to a later
  ::  conjunct of the SAME evaluation, and a `bthunk` handed to a combinator
  ::  in `lib/value.hoon` has no way to hand `rst` back. Semantics are
  ::  unchanged -- stop at the first FALSE, suppress later errors
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  |-  ^-  eout
  ?~  as  [[%& [%bool &]] rs]
  =^  r  rs  (eval-bool-rs i.as e rs)
  ?:  ?=(%| -.r)  [r rs]
  ?.  p.r  [[%& [%bool |]] rs]
  $(as t.as)
::
++  eval-disj
  ::  `+disj-list:v` inlined, for the reason `+eval-conj` gives: stop at the
  ::  first TRUE, suppress later errors, thread the run state across the
  ::  disjuncts that DID run
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  |-  ^-  eout
  ?~  as  [[%& [%bool |]] rs]
  =^  r  rs  (eval-bool-rs i.as e rs)
  ?:  ?=(%| -.r)  [r rs]
  ?:  p.r  [[%& [%bool &]] rs]
  $(as t.as)
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
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  f  rs  (eval-rs (snag 0 as) e rs)
  ?:  ?=(%| -.f)  [f rs]
  =^  x  rs  (eval-rs (snag 1 as) e rs)
  ?:  ?=(%| -.x)  [x rs]
  ::  tlc2 words an out-of-domain failure by the function's value class, and a
  ::  lambda FORM is what stays a FcnLambdaValue there (R1.4.5)
  [(apply:v p.f p.x (lambda-form (snag 0 as))) rs]
::
++  eval-setenum
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  vs  rs  (eval-args-rs as e rs)
  ?:(?=(%| -.vs) [vs rs] [[%& (normalize:v [%set %set-enum p.vs])] rs])
::
++  eval-tuple
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  vs  rs  (eval-args-rs as e rs)
  ?:(?=(%| -.vs) [vs rs] [[%& [%seq p.vs]] rs])
::
++  eval-rcd
  ::  [a |-> e1, b |-> e2] — args are $Pair(name-str, value-expr)
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =|  acc=(list vfield:v)
  |-  ^-  eout
  ?~  as
    [(mk-rec:v (flop acc)) rs]
  =/  pr  i.as
  ?.  ?=(%apply -.pr)  [[%| 0 'malformed record field.'] rs]
  =/  k  (lit-str (snag 0 args.pr))
  =^  fv  rs  (eval-rs (snag 1 args.pr) e rs)
  ?:  ?=(%| -.fv)  [fv rs]
  $(as t.as, acc [[k p.fv] acc])
::
++  eval-rcd-select
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  r  rs  (eval-rs (snag 0 as) e rs)
  ?:  ?=(%| -.r)  [r rs]
  [(apply:v p.r [%str (lit-str (snag 1 as))] |) rs]
::
++  eval-ite
  ::  `+if-val:v` inlined so the TAKEN branch's run state comes back out.
  ::  Only the taken branch is evaluated, exactly as before
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  c  rs  (eval-rs (snag 0 as) e rs)
  ?:  ?=(%| -.c)  [c rs]
  ?.  ?=(%bool -.p.c)
    :_  rs
    [%| 0 (rap 3 ~['A non-boolean was used as an IF guard: ' (crip (render:v p.c)) '.'])]
  ?:  p.p.c  (eval-rs (snag 1 as) e rs)
  (eval-rs (snag 2 as) e rs)
::
++  eval-case
  ::  args are $Pair(guard, body); an OTHER arm's guard is a %nullodn.
  ::  `+case-val:v` inlined for the carrier: guards run IN ORDER and each
  ::  one's run state is visible to the next, the first true guard's body
  ::  runs, unselected bodies are never evaluated (so their errors stay
  ::  suppressed) -- the same semantics, threaded
  |=  [as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =/  other=(unit sem:sm)  ~
  =/  cs  as
  |-  ^-  eout
  ?~  cs
    ?~  other
      [[%| 0 'CASE: no OTHER case, and no guard evaluated to TRUE.'] rs]
    (eval-rs u.other e rs)
  =/  pr  i.cs
  ?.  ?=(%apply -.pr)  [[%| 0 'malformed CASE arm.'] rs]
  =/  guard  (snag 0 args.pr)
  =/  body   (snag 1 args.pr)
  ?:  ?=(%nullodn -.guard)
    $(cs t.cs, other `body)
  =^  g  rs  (eval-bool-rs guard e rs)
  ?:  ?=(%| -.g)  [g rs]
  ?:  p.g  (eval-rs body e rs)
  $(cs t.cs)
::
::  +|  EXCEPT
::
++  eval-except
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  =^  tv  rs  (eval-rs (snag 0 args.n) e rs)
  ?:  ?=(%| -.tv)  [tv rs]
  =/  cur  p.tv
  =/  clauses  (slag 1 args.n)
  |-  ^-  eout
  ?~  clauses  [[%& cur] rs]
  =/  pr  i.clauses
  ?.  ?=(%apply -.pr)  [[%| 0 'malformed EXCEPT clause.'] rs]
  =/  seqn  (snag 0 args.pr)
  =/  rhs   (snag 1 args.pr)
  ?.  ?=(%apply -.seqn)  [[%| 0 'malformed EXCEPT path.'] rs]
  =^  pathr  rs  (eval-args-rs args.seqn e rs)
  ?:  ?=(%| -.pathr)  [pathr rs]
  =/  sel  (except-select:v cur p.pathr)
  ?:  ?=(%| -.sel)  [sel rs]
  ?~  p.sel  $(clauses t.clauses)
  =^  rv  rs  (eval-rs rhs e(atv `u.p.sel) rs)
  ?:  ?=(%| -.rv)  [rv rs]
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
    [%& (normalize:v [%set %set-enum p.r])]
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
  =/  fr  (force:v p.sd setmax.e)
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
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  =/  nm  name.op.n
  =/  d   (~(get by ops.e) nm)
  ?~  d
    [[%| 0 (rap 3 ~['undefined operator: ' nm])] rs]
  =/  def  u.d
  =/  key=op-key:so  [origin.def nm (lent args.n)]
  =/  ov  (lookup:so ov.e key)
  ?^  ov
    =^  as  rs  (eval-args-rs args.n e rs)
    ?:  ?=(%| -.as)  [as rs]
    ::  a plain override gate is a PURE function of its argument values
    ::  (`lookup:so` returns `gate`), so it cannot touch the run state; the
    ::  ones that can are the `node-op` overrides just below, which take the
    ::  evaluator itself
    [(gate.u.ov p.as) rs]
  ::  an override that needs the evaluator itself (an operator argument)
  =/  nop  (node-op:so key)
  ?^  nop  (eval-node-op-rs tag.u.nop n e rs)
  ?:  ?&  (is-standard:so ov.e origin.def)
          !(body-allowed:so ov.e origin.def nm)
      ==
    [[%| (unsupported:so key)] rs]
  ?:  =(0 fuel.e)  [[%| 0 'evaluation recursion/resource limit exceeded.'] rs]
  ?~  body.def  [[%| 0 (rap 3 ~['operator has no evaluable body: ' nm])] rs]
  ?.  =((lent params.def) (lent args.n))
    [[%| 0 (rap 3 ~['wrong number of arguments to ' nm])] rs]
  =/  e2  (bind-params e params.def args.n)
  ?:  ?=(%| -.e2)  [e2 rs]
  (eval-rs u.body.def p.e2(fuel (dec fuel.e)) rs)
::
++  eval-node-op
  ::  StandardModule overrides that take an operator argument. tlc2 receives
  ::  an OpValue and applies it per element; here the operator argument is
  ::  resolved through the ordinary operator-valued-parameter path and
  ::  applied by the same evaluator, under the same recursion budget
  |=  [tag=@tas n=sem-apply:sm e=eenv]
  ^-  eres
  -:(eval-node-op-rs tag n e empty-rst)
::
++  eval-node-op-rs
  ::  THE WRITE POINT. These are the overrides that receive the unevaluated
  ::  node and call the evaluator themselves, so they are where `TLCSet`
  ::  (R2.7.4.3) and `RandomElement` (R2.7.4.4) will read and write `rst`.
  ::  Everything above this arm now threads the carrier to it and back
  |=  [tag=@tas n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ::  the FiniteSets / Sequences overrides drive the streaming layer, which is
  ::  below the carrier boundary; they pass `rst` through untouched
  ?:  ?=(%bag-of-all tag)     [(eval-bag-of-all n e) rs]
  ?:  ?=(%cardinality tag)    [(eval-cardinality n e) rs]
  ?:  ?=(%is-finite-set tag)  [(eval-is-finite n e) rs]
  ?:  ?=(%sort-seq tag)       [(eval-sort-seq n e) rs]
  ?:  ?=(%tlc-eval tag)       (eval-tlc-eval n e rs)
  ?:  ?=(%tlc-get tag)        [(eval-tlc-get n e) rs]
  ?:  ?=(%assert-error tag)   (eval-assert-error n e rs)
  ?:  ?=(%tlc-cache tag)      (eval-tlc-cache n e rs)
  ?:  ?=(%tlc-defer tag)      [(eval-tlc-defer n e) rs]
  ?.  ?=(%select-seq tag)  [[%| 0 'unsupported operator-argument override.'] rs]
  ?.  ?=([* * ~] args.n)
    [[%| 0 'SelectSeq expects two arguments.'] rs]
  =^  sv  rs  (eval-rs i.args.n e rs)
  ?:  ?=(%| -.sv)  [sv rs]
  =/  t  (to-tuple:v p.sv)
  ?~  t  [[%| (arg-error:so 2.169 1 'SelectSeq' 'sequence' | p.sv)] rs]
  ::  an empty sequence is answered before the operator is even examined
  ?~  u.t  [[%& [%seq ~]] rs]
  =/  od  (resolve-oparg i.t.args.n e)
  ?~  od  [[%| (op-arg-error 'SelectSeq' 'operator' i.t.args.n)] rs]
  =^  keep  rs
    ::  widen: `u.t` is narrowed to a non-empty list, which would make the
    ::  loop's `?~` vain
    =/  els=(list value:v)  u.t
    =|  acc=(list value:v)
    |-  ^-  aout
    ?~  els  [[%& (flop acc)] rs]
    =^  r  rs  (apply-def-rs u.od ~[i.els] e rs)
    ?:  ?=(%| -.r)  [r rs]
    ?.  ?=(%bool -.p.r)
      [[%| (op-arg-error 'SelectSeq' 'boolean-valued operator' i.t.args.n)] rs]
    ?:  p.p.r  $(els t.els, acc [i.els acc])
    $(els t.els)
  ?:  ?=(%| -.keep)  [keep rs]
  [[%& [%seq p.keep]] rs]
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
  =/  f  (force:v p.dom setmax.e)
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
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* ~] args.n)  [[%| 0 'TLCEval expects one argument.'] rs]
  (eval-rs i.args.n e rs)
::
++  eval-assert-error
  ::  TLCExt!AssertError(err, exp) — evaluate `exp`; if it FAILS, compare the
  ::  failure's message to `err` and answer TRUE on a match, FALSE otherwise.
  ::  An expression that evaluates cleanly is FALSE, since no error occurred.
  ::
  ::  This is the one TLCExt operator that reads more naturally here than in
  ::  the pin: there it is a `try/catch` around `EvalException`, and this
  ::  evaluator already returns a failure as a VALUE (`eres`'s `%|` arm), so
  ::  "catching" is just branching on it.
  ::
  ::  The `err` argument is checked SYNTACTICALLY, as `assertError` does with
  ::  `Assert.check(args[0] instanceof StringNode, ...)` — a computed string
  ::  is rejected even though it would evaluate to one
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * ~] args.n)  [[%| 0 'AssertError expects two arguments.'] rs]
  =/  ea  i.args.n
  ?.  ?=(%lit -.ea)
    :_  rs
    :-  %|
    :-  0
    %^  rap  3  'In computing AssertError, a non-string expression was used '
    ~['as the err of an AssertError(err, exp).']
  =^  ev  rs  (eval-rs ea e rs)
  ?:  ?=(%| -.ev)  [ev rs]
  ?.  ?=(%str -.p.ev)
    :_  rs
    :-  %|
    :-  0
    %^  rap  3  'In computing AssertError, a non-string expression was used '
    ~['as the err of an AssertError(err, exp).']
  ::  R2.7.4.1b: `exp`'s run state is kept even when `exp` FAILS. That is the
  ::  reason the carrier rides BOTH branches of `eres` (R2.7.4.0): a `TLCSet`
  ::  write that precedes a failing conjunct really happened at the pin -- it
  ::  mutated a Java field -- and AssertError is exactly the operator that
  ::  CATCHES such a failure instead of letting it end the run
  =^  r  rs  (eval-rs i.t.args.n e rs)
  ?:  ?=(%& -.r)  [[%& %bool |] rs]
  [[%& %bool =(p.p.ev msg.p.r)] rs]
::
++  eval-tlc-cache
  ::  TLCExt!TLCCache(expression, closure) — MEMOIZATION, and memoization of a
  ::  pure expression is observationally the identity. The pin keys a cache on
  ::  `closure`'s value and stores it on the expression node (constant level) or
  ::  on `s0` (variable level); either way the answer it returns is exactly
  ::  `expression`'s value, so evaluating it is at parity by construction.
  ::
  ::  `closure` is still evaluated, because the pin evaluates it to build the
  ::  key before it decides anything — so a `closure` that FAILS fails the
  ::  operator here too, rather than being skipped on a cache hit this engine
  ::  does not have
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * ~] args.n)  [[%| 0 'TLCCache expects two arguments.'] rs]
  =^  k  rs  (eval-rs i.t.args.n e rs)
  ?:  ?=(%| -.k)  [k rs]
  (eval-rs i.args.n e rs)
::
++  eval-tlc-defer
  ::  TLCExt!TLCDefer(exp) — returns TRUE and arranges for `exp` to be
  ::  evaluated LATER, by `TLCState.setCallable`. Measured at the pin, who runs
  ::  that callable decides the whole behavior: `execCallable` is invoked by
  ::  `SimulationWorker` and `ExplorationWorker` and NOT by `ModelChecker`, so
  ::  under BFS the deferred expression is never evaluated at all — a spec with
  ::  `TLCDefer(PrintT(...))` prints nothing and runs otherwise unchanged.
  ::
  ::  So TRUE-without-evaluating is not an approximation under BFS; it is what
  ::  tlc2 does. Under SIMULATION the callable does run, and this engine has no
  ::  post-step hook to run it in, so that case is refused BY NAME rather than
  ::  silently dropping an effect the pin performs
  |=  [n=sem-apply:sm e=eenv]
  ^-  eres
  ?.  ?=([* ~] args.n)  [%| 0 'TLCDefer expects one argument.']
  ?:  ?&(?=(^ run.e) sim.u.run.e)
    :-  %|
    :-  0
    %^  rap  3  'unsupported StandardModule operator: TLCExt!TLCDefer in '
    ~['simulation; the deferred expression needs a post-step hook this engine has not built']
  [%& %bool &]
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
  (tlc-get:so ~[p.k] run.e)
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
  -:(apply-def-rs d vs e empty-rst)
::
++  apply-def-rs
  |=  [d=sem-def:sm vs=(list value:v) e=eenv rs=rst]
  ^-  eout
  ?:  =(0 fuel.e)  [[%| 0 'evaluation recursion/resource limit exceeded.'] rs]
  ?~  body.d  [[%| 0 (rap 3 ~['operator has no evaluable body: ' name.d])] rs]
  ?.  =((lent params.d) (lent vs))
    [[%| 0 (rap 3 ~['wrong number of arguments to ' name.d])] rs]
  =/  names  (turn params.d |=(p=spar:sm name.p))
  (eval-rs u.body.d (bind-names e(fuel (dec fuel.e)) names vs) rs)
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
  |=  [n=sem-letin:sm e=eenv rs=rst]
  ^-  eout
  ?~  body.n  [[%| 0 'LET with no body.'] rs]
  =/  e2=eenv
    =/  os  ops.e
    |-  ^-  eenv
    ?~  lets.n  e(ops os)
    $(lets.n t.lets.n, os (~(put by os) name.i.lets.n i.lets.n))
  (eval-rs u.body.n e2 rs)
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
  ::  R2.3.5: an INSTANCE substitution binds a %variable name the same way, so
  ::  `v <- x` has to be chased here too or the action solver will not see the
  ::  inner `v'` as an assignment to the outer `x`. Bounded: a self-substitution
  ::  (`x <- x`) would otherwise spin
  |=  [n=sem:sm psub=(map @t sem:sm)]
  ^-  sem:sm
  =/  fuel  32
  |-  ^-  sem:sm
  ?:  =(0 fuel)  n
  ?.  ?=(%apply -.n)  n
  ?.  ?=(?(%formal-param %variable) kind.op.n)  n
  ?.  ?=(~ args.n)  n
  =/  s  (~(get by psub) name.op.n)
  ?~  s  n
  ?:  =(u.s n)  n
  $(n u.s, fuel (dec fuel))
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
  ::  the variable names of UNCHANGED e (a variable or a tuple of variables).
  ::  `psub` is consulted so a SUBSTITUTED variable names its outer target --
  ::  `UNCHANGED v` under `v <- x` is `UNCHANGED x` (R2.3.5)
  |=  [n=sem:sm psub=(map @t sem:sm)]
  ^-  (list @t)
  =.  n  (deref-sem n psub)
  ?.  ?=(%apply -.n)  ~
  ?:  ?=(%variable kind.op.n)  ~[name.op.n]
  ?.  =('$Tuple' name.op.n)  ~
  %+  murn  args.n
  |=  a=sem:sm
  =.  a  (deref-sem a psub)
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
++  bind-substs
  ::  bind an INSTANCE's `WITH` substitutions (R2.3.5). Same split `+bind-psub`
  ::  makes for operator parameters, and for the same reason: a substitution
  ::  onto a bare state variable (`v <- x`) is kept as a NODE so the inner
  ::  module's `v'` is still an assignment to the outer `x`, while a value
  ::  substitution (`k <- 3`) is evaluated once and bound through `vals`, which
  ::  is where a CONSTANT reference reads from
  |=  [e=eenv ns=(list sbind:sm) as=(list sem:sm)]
  ^-  (each eenv eval-err:v)
  ?~  ns  [%& e]
  ?~  as  [%& e]
  ?:  (state-var-ref i.as e)
    $(ns t.ns, as t.as, e e(psub (~(put by psub.e) name.i.ns i.as)))
  =/  av  (eval i.as e)
  ?:  ?=(%| -.av)  av
  $(ns t.ns, as t.as, e e(vals (~(put by vals.e) name.i.ns p.av)))
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
  |=  [n=sem:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  ?.  ?=(%apply -.n)
    ?:  ?=(%letin -.n)  (solve-letin n mode cur part e s)
    (solve-filter n mode cur part e s)
  =/  nm  name.op.n
  ?:  |(=(nm '$ConjList') =(nm '\\land'))
    (solve-conj args.n mode cur part e s)
  ?:  |(=(nm '$DisjList') =(nm '\\lor'))
    (solve-disj args.n mode cur part e s)
  ?:  =(nm '$IfThenElse')  (solve-ite args.n mode cur part e s)
  ?:  =(nm '$BoundedExists')  (solve-exists n mode cur part e s)
  ?:  =(nm '$BoundedForall')  (solve-forall n mode cur part e s)
  ?:  =(nm 'UNCHANGED')  (solve-unchanged (snag 0 args.n) mode cur part e s)
  ?:  =(nm '=')
    =/  as  (assignable-sem (snag 0 args.n) mode vars.e part psub.e)
    ?~  as  (solve-filter n mode cur part e s)
    ::  R2.7.4.1b: the assignment's RIGHT-HAND SIDE now carries. This is the
    ::  site R2.7.4.4 needs -- `x' = RandomElement(0..2)` draws here, and the
    ::  advanced seed has to reach the NEXT conjunct through `+solve-conj`
    =^  rv  s  (eval-rs (snag 1 args.n) (senv mode cur part e) s)
    ?:  ?=(%| -.rv)  [rv s]
    [[%& ~[(~(put by part) u.as p.rv)]] s]
  ::  `x \in S` on an unbound assignable var is a NONDETERMINISTIC assignment:
  ::  enumerate S in TLC order, one successor per element (init + next). Any
  ::  other `\in` (a bound var, a membership filter) prunes as a boolean.
  ?:  =(nm '\\in')
    =/  as  (assignable-sem (snag 0 args.n) mode vars.e part psub.e)
    ?~  as  (solve-filter n mode cur part e s)
    =/  sd  (eval-domain (snag 1 args.n) (senv mode cur part e))
    ?:  ?=(%| -.sd)  [sd s]
    =/  els  (drain-sexp p.sd)
    ?:  ?=(%| -.els)  [els s]
    [[%& (turn p.els |=(x=value:v (~(put by part) u.as x)))] s]
  ::  `x \subseteq S` on an unbound assignable var enumerates the powerset of S
  ::  as candidate assignments (the set-valued sibling of `\in`)
  ?:  =(nm '\\subseteq')
    =/  as  (assignable-sem (snag 0 args.n) mode vars.e part psub.e)
    ?~  as  (solve-filter n mode cur part e s)
    =^  rv  s  (eval-rs (snag 1 args.n) (senv mode cur part e) s)
    ?:  ?=(%| -.rv)  [rv s]
    =/  els  (drain-sexp [%subset p.rv])
    ?:  ?=(%| -.els)  [els s]
    [[%& (turn p.els |=(x=value:v (~(put by part) u.as x)))] s]
  ::  a user-op reference in action position is expanded to its body and solved
  ::  (e.g. `Next == Inc \/ Dec`), so a primed variable in the body is not
  ::  filtered as a boolean. Parameters are bound call-by-name (`+bind-psub`):
  ::  an assignable variable passed as an argument (`Init(s)`, `Next(s)`) stays
  ::  assignable, mirroring tlc2's Context substitution.
  ::  an INSTANCE substitution in ACTION position binds and descends, exactly as
  ::  a user-op expands: otherwise the inner module's `v' = ...` would be
  ::  evaluated as a boolean filter instead of solved as an assignment (R2.3.5)
  ?:  ?=(^ (anysubstin-mod:sm nm))
    =/  sp  (substin-parts:sm n)
    ?~  sp  (solve-filter n mode cur part e s)
    =/  e2  (bind-substs (senv mode cur part e) names.u.sp exprs.u.sp)
    ?:  ?=(%| -.e2)  [e2 s]
    (solve inner.u.sp mode cur part p.e2 s)
  ?:  ?=(%user-op kind.op.n)
    =/  d  (~(get by ops.e) nm)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  (solve-filter n mode cur part e s)
    ?.  =((lent params.u.d) (lent args.n))  (solve-filter n mode cur part e s)
    ?:  =(0 fuel.e)
      [[%| 0 'evaluation recursion/resource limit exceeded.'] s]
    =/  e2  (bind-psub e(fuel (dec fuel.e)) params.u.d args.n)
    ?:  ?=(%| -.e2)  [e2 s]
    (solve u.body.u.d mode cur part p.e2 s)
  (solve-filter n mode cur part e s)
::
++  solve-filter
  |=  [n=sem:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  ::  R2.7.4.1b: a FILTER carries too -- a guard may contain a `TLCSet`, and
  ::  the pin's write happens whether the guard came back true or false
  =^  b  s  (eval-bool-rs n (senv mode cur part e) s)
  ?:  ?=(%| -.b)  [b s]
  ?:  p.b  [[%& ~[part]] s]
  ::  R2.7.4.2b: the INIT coverage line's SECOND column is
  ::  `getEvalCount() + secondary`, and the secondary counts exactly this --
  ::  an initial-state candidate rejected by a conjunct evaluated once the
  ::  state was ALREADY FULLY ASSIGNED. That is `Tool.getInitStates`'s
  ::  `ps.allAssigned()` branch (`Tool.java:536-556`), which increments
  ::  `cm.getRoot().incSecondary()` and abandons the candidate; a rejection
  ::  while a variable is still unassigned increments nothing. Measured at the
  ::  pin: `Init == x \in 0..3 /\ y = 0 /\ x > 1` reports `2:4`, and the same
  ::  conjuncts reordered so `x > 1` runs before `y` is bound report `2:2`.
  ::  Counted ONCE per rejected candidate, which falls out of the solver's
  ::  short-circuit: a filter that yields no state leaves `+solve-each` with
  ::  nothing to iterate, so no later conjunct is evaluated for it
  =?  irej.s  ?&(?=(%init mode) (complete part vars.e))  +(irej.s)
  [[%& ~] s]
::
++  solve-letin
  |=  [n=sem-letin:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  ?~  body.n  [[%| 0 'LET with no body in an action.'] s]
  =/  e2=eenv
    =/  os  ops.e
    |-  ^-  eenv
    ?~  lets.n  e(ops os)
    $(lets.n t.lets.n, os (~(put by os) name.i.lets.n i.lets.n))
  (solve u.body.n mode cur part e2 s)
::
++  solve-conj
  ::  thread the partial state left-to-right across the conjuncts
  |=  [cs=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  acc=(list state)  ~[part]
  |-  ^-  sout
  ?~  cs  [[%& acc] s]
  =^  step  s  (solve-each i.cs mode cur acc e s)
  ?:  ?=(%| -.step)  [step s]
  $(cs t.cs, acc p.step)
::
++  solve-each
  ::  solve `n` from every partial state, concatenating results in order
  |=  [n=sem:sm mode=?(%init %next) cur=state parts=(list state) e=eenv s=rst]
  ^-  sout
  =|  out=(list state)
  |-  ^-  sout
  ?~  parts  [[%& out] s]
  =^  r  s  (solve n mode cur i.parts e s)
  ?:  ?=(%| -.r)  [r s]
  $(parts t.parts, out (weld out p.r))
::
++  solve-disj
  ::  branch: each disjunct solved from the same partial state, in order
  |=  [ds=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =|  out=(list state)
  |-  ^-  sout
  ?~  ds  [[%& out] s]
  =^  r  s  (solve i.ds mode cur part e s)
  ?:  ?=(%| -.r)  [r s]
  $(ds t.ds, out (weld out p.r))
::
++  solve-ite
  |=  [as=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =^  b  s  (eval-bool-rs (snag 0 as) (senv mode cur part e) s)
  ?:  ?=(%| -.b)  [b s]
  (solve ?:(p.b (snag 1 as) (snag 2 as)) mode cur part e s)
::
++  solve-exists
  ::  \E x \in S : A — branch over the domain in enumeration order
  |=  [n=sem-apply:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)
    [[%| 0 'an action existential over multiple binders is unsupported.'] s]
  =/  sd  (eval-domain rng.i.bs (senv mode cur part e))
  ?:  ?=(%| -.sd)  [sd s]
  =/  els  (drain-sexp p.sd)
  ?:  ?=(%| -.els)  [els s]
  =/  body  (snag 0 args.n)
  =|  out=(list state)
  =/  xs  p.els
  |-  ^-  sout
  ?~  xs  [[%& out] s]
  =/  e2  (bind-group e i.bs i.xs)
  =^  r  s  (solve body mode cur part e2 s)
  ?:  ?=(%| -.r)  [r s]
  $(xs t.xs, out (weld out p.r))
::
++  solve-forall
  ::  \A x \in S : A — a bounded universal in action position is the
  ::  conjunction of A over the domain (tlc2 expands a bounded \A the same way
  ::  in getInitStates/getNextStates); thread the partial state through each
  ::  element in enumeration order, so `x = e` on the first element assigns and
  ::  a later element filters against it
  |=  [n=sem-apply:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)
    [[%| 0 'an action universal over multiple binders is unsupported.'] s]
  =/  sd  (eval-domain rng.i.bs (senv mode cur part e))
  ?:  ?=(%| -.sd)  [sd s]
  =/  els  (drain-sexp p.sd)
  ?:  ?=(%| -.els)  [els s]
  =/  body  (snag 0 args.n)
  =/  acc=(list state)  ~[part]
  =/  xs  p.els
  |-  ^-  sout
  ?~  xs  [[%& acc] s]
  =/  e2  (bind-group e i.bs i.xs)
  =^  step  s  (solve-each body mode cur acc e2 s)
  ?:  ?=(%| -.step)  [step s]
  $(xs t.xs, acc p.step)
::
++  solve-unchanged
  ::  UNCHANGED e assigns each named variable to its current value
  |=  [arg=sem:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  names  (unchanged-vars arg psub.e)
  =/  out=state  part
  =.  out
    |-  ^-  state
    ?~  names  out
    =/  cv  (~(get by cur) i.names)
    ?~  cv  $(names t.names)
    $(names t.names, out (~(put by out) i.names u.cv))
  [[%& ~[out]] s]
::
++  eval-enabled
  ::  ENABLED A: a successor satisfying A exists from the current state; the
  ::  witness is discarded (EvalControl.Enabled). Primed variables the action
  ::  does not constrain are existentially free (tlc2's Tool.enabled), so any
  ::  satisfying PARTIAL assignment enables A — completeness is not required.
  |=  [n=sem:sm e=eenv]
  ^-  eres
  ::  R2.7.4.1b: ENABLED still DISCARDS the carrier, and now that the
  ::  evaluator carries it that is a deliberate decision rather than an
  ::  accident. `Tool.enabled` runs the action's witness search under
  ::  `EvalControl.Enabled` and throws the witness away; the port does the
  ::  same, so anything the search wrote is thrown away with it. Nothing
  ::  writes yet, so it is still behaviour-free -- but R2.7.4.3 must MEASURE
  ::  the pin before claiming parity here, because tlc2's `TLCSet` writes a
  ::  static field and would survive a discarded witness where this does not
  =/  r=sres  -:(solve n %next s0.e ~ e(enabled &) empty-rst)
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
  [~ (defmap-of mo) ~ default-fuel s0 s1 | | (vars-of mo) ~ 0 make-senv:so ~]
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
  =/  r=sres  -:(solve u.body.u.d %init ~ ~ e empty-rst)
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
  =/  r=sres  -:(solve u.body.u.d %next cur ~ e empty-rst)
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
  [consts defs ~ default-fuel ~ ~ | | vars ~ 0 make-senv:so ~]
::
++  with-setmax
  ::  the run's `max-set-size` applied to a prebuilt env (R2.4.1). A separate
  ::  arm rather than a `+make-env` parameter because `+make-env` has ~30 call
  ::  sites across `check`/`job`/tests, and only the ones that HAVE a `limits`
  ::  need to say anything
  |=  [e=eenv lim=@ud]
  ^-  eenv
  e(setmax lim)
::
++  with-run
  ::  the live run statistics applied to a prebuilt env (R2.6.1), the same
  ::  shape `+with-setmax` uses and for the same reason. Unlike `setmax` these
  ::  change as the search runs, so the search sets them per expansion
  |=  [e=eenv r=tlc-run:so]
  ^-  eenv
  e(run `r)
::
++  init-states
  ::  the complete initial-state stream for an Init BODY under a prebuilt env.
  ::  The carrier-discarding wrapper: R2.7.4.2b adds the variant that keeps it,
  ::  for the INIT coverage counter
  |=  [body=sem:sm e=eenv]
  ^-  sres
  -:(init-states-rs body e empty-rst)
::
++  init-states-rs
  |=  [body=sem:sm e=eenv s=rst]
  ^-  sout
  =^  r  s  (solve body %init ~ ~ e s)
  ?:  ?=(%| -.r)  [r s]
  ?.  (levy p.r |=(st=state (complete st vars.e)))
    [[%| 0 'incomplete initial state: a variable is unassigned.'] s]
  [[%& p.r] s]
::
++  next-states
  ::  the complete successor stream of `cur` for a Next BODY under a prebuilt
  ::  env (the checker's per-state call; the graph is generated once, upstream).
  ::  The carrier-discarding wrapper, per R2.7.4.1's signature policy: the
  ::  ~100 existing call sites keep their shape and only the paths that need
  ::  the run state take the `-rs` variant
  |=  [cur=state body=sem:sm e=eenv]
  ^-  sres
  -:(next-states-rs cur body e empty-rst)
::
++  next-states-rs
  |=  [cur=state body=sem:sm e=eenv s=rst]
  ^-  sout
  =^  r  s  (solve body %next cur ~ e(s0 cur) s)
  ?:  ?=(%| -.r)  [r s]
  ?.  (levy p.r |=(st=state (complete st vars.e)))
    [[%| 0 'incomplete next state: a variable is unassigned.'] s]
  [[%& p.r] s]
::
::
::  +|  Probabilistic Successors (tlc2 `-generate`, R2.4.6)
::
::  `-generate` sets `Tool.probabilistic`, which takes a DIFFERENT path through
::  `getNextStates`: the disjuncts, the bounded existential, `\in` and
::  `\subseteq` are visited in RANDOMIZED order and the walk RETURNS as soon as
::  the next-state functor has accepted one successor, so a step generates one
::  successor instead of every successor.
::
::  That early return is a property of tlc2's CPS shape -- `getNextStates`
::  threads an `ActionItemList` continuation through every opcode -- and cannot
::  be bolted onto `+solve`, which returns a LIST per node and threads a list of
::  partial states through a conjunction. `/\ x' \in S /\ y' \in T` has to stop
::  at the first accepted PAIR, and only a continuation can say that. So this is
::  a second solver family rather than a flag on the first, which is what the
::  R2.4.6 row meant by "a different successor-pick engine, not a flag".
::
::  Initial states are NOT affected: `getInitStates` has no probabilistic
::  branch, so `%init` never reaches here.
::
::  one deferred conjunct: the node still to be solved and the environment it
::  was pushed with (tlc2's ActionItemList carries a Context per item)
+$  pitem  [n=sem:sm e=eenv]
::  the walk's threaded state: the ENUMERATION generator (tlc2's
::  `RandomEnumerableValues` -- a java.util.Random seeded with `-seed`), the
::  SIMULATION generator (the worker's `localRng`, which is what
::  `TLCGlobals.simulator.getRNG()` hands back on a worker thread, measured --
::  NOT the Simulator's own), and the running count of successors GENERATED
::  R2.7.4.1b: the enumeration generator is NOT a second seed channel -- it IS
::  the carrier's. Measured at the pin: `TLC!RandomElement` draws through
::  `RandomEnumerableValues.get()` (`SetEnumValue.randomElement` /
::  `IntervalValue.randomElement`), the very generator `-generate`'s
::  probabilistic enumeration spends. Keeping two would let a spec that uses
::  both diverge silently, so `pst` EMBEDS the carrier and `es.rs.p` is the
::  single enumeration seed
+$  pst  [rs=rst ls=@ ngen=@ud]
::  the next-state functor's verdict on one complete successor, i.e. what
::  `SimulationWorker.addElement` does after counting: check the invariants (a
::  violation throws), then CONSTRAINT / ACTION_CONSTRAINT (a failure drops it)
+$  fres  $@(?(%keep %drop) [%viol nm=@t])
+$  pres
  $%  [%found st=state]
      [%viol nm=@t st=state]
      [%none ~]
      [%err p=eval-err:v]
  ==
::
++  pitems
  ::  the deferred conjuncts of a conjunction, each carrying the current env
  |=  [as=(list sem:sm) e=eenv]
  ^-  (list pitem)
  ?~  as  ~
  [[i.as e] $(as t.as)]
::
++  pgroup-items
  ::  a bounded universal's remaining elements as deferred conjuncts, each with
  ::  its own binding (tlc2 conses them onto the ActionItemList and solves the
  ::  FIRST element now, so the pushed ones end up in reverse)
  |=  [body=sem:sm g=bgroup xs=(list value:v) e=eenv]
  ^-  (list pitem)
  ?~  xs  ~
  [[body (bind-group e g i.xs)] $(xs t.xs)]
::
++  next-states-prob
  ::  ONE successor of `cur` under a Next BODY, on the `-generate` path: the
  ::  walk returns as soon as `fil` accepts a successor. `p` carries both
  ::  generators and the states-generated count, threaded in and out
  |=  [cur=state body=sem:sm e=eenv p=pst fil=$-(state fres)]
  ^-  [pres pst]
  =^  res  p  (psolve body cur ~ e(s0 cur) ~ p fil)
  ?.  ?=(%found -.res)  [res p]
  ?.  (complete st.res vars.e)
    [[%err 0 'incomplete next state: a variable is unassigned.'] p]
  [res p]
::
++  pnext
  ::  continue with the deferred conjuncts; an empty continuation means the
  ::  successor is COMPLETE. tlc2 counts it there (`collectPreSuccessor`, before
  ::  any filtering) and only then runs the functor
  |=  $:  cur=state  part=state  acts=(list pitem)
          p=pst  fil=$-(state fres)
      ==
  ^-  [pres pst]
  ?^  acts
    (psolve n.i.acts cur part e.i.acts t.acts p fil)
  =.  ngen.p  +(ngen.p)
  =/  f  (fil part)
  ?@  f
    ?:(?=(%keep f) [[%found part] p] [[%none ~] p])
  [[%viol nm.f part] p]
::
++  pfilter
  ::  a boolean conjunct: it prunes, it never assigns
  |=  $:  n=sem:sm  cur=state  part=state  e=eenv
          acts=(list pitem)  p=pst  fil=$-(state fres)
      ==
  ^-  [pres pst]
  =^  b  rs.p  (eval-bool-rs n (senv %next cur part e) rs.p)
  ?:  ?=(%| -.b)  [[%err p.b] p]
  ?.  p.b  [[%none ~] p]
  (pnext cur part acts p fil)
::
++  pbind-elems
  ::  bind `vn` to each element and continue, in RANDOMIZED order, stopping at
  ::  the first successor the functor accepts.
  ::
  ::  The deterministic pass afterwards is tlc2's, not a slip: the probabilistic
  ::  branches of OPCODE_in and OPCODE_se have NO early return after their loop
  ::  (unlike OPCODE_dl and OPCODE_be), so when the randomized pass accepts
  ::  nothing the ordinary enumeration runs AGAIN over the same elements -- and
  ::  `collectPreSuccessor` counts them a second time. Measured at the pin: a
  ::  run whose CONSTRAINT drops every successor of its last state reports 8
  ::  states generated where the arithmetic without the fall-through gives 6
  |=  $:  vn=@t  xs=(list value:v)  cur=state  part=state
          acts=(list pitem)  p=pst  fil=$-(state fres)
      ==
  ^-  [pres pst]
  =/  nn  (lent xs)
  ?:  =(0 nn)  [[%none ~] p]
  =^  ixs  es.rs.p  (subset-indices:rg es.rs.p nn nn)
  =/  rr
    |-  ^-  [pres pst]
    ?~  ixs  [[%none ~] p]
    =^  res  p  (pnext cur (~(put by part) vn (snag i.ixs xs)) acts p fil)
    ?.  ?=(%none -.res)  [res p]
    $(ixs t.ixs)
  =/  r1  -.rr
  =.  p   +.rr
  ?.  ?=(%none -.r1)  [r1 p]
  =/  ys  xs
  |-  ^-  [pres pst]
  ?~  ys  [[%none ~] p]
  =^  res  p  (pnext cur (~(put by part) vn i.ys) acts p fil)
  ?.  ?=(%none -.res)  [res p]
  $(ys t.ys)
::
++  psolve
  ::  the probabilistic sibling of +solve. Mode is always %next
  |=  $:  n=sem:sm  cur=state  part=state  e=eenv
          acts=(list pitem)  p=pst  fil=$-(state fres)
      ==
  ^-  [pres pst]
  ?.  ?=(%apply -.n)
    ?.  ?=(%letin -.n)  (pfilter n cur part e acts p fil)
    ?~  body.n  [[%err 0 'LET with no body in an action.'] p]
    =/  e2=eenv
      =/  os  ops.e
      =/  ls  lets.n
      |-  ^-  eenv
      ?~  ls  e(ops os)
      $(ls t.ls, os (~(put by os) name.i.ls i.ls))
    (psolve u.body.n cur part e2 acts p fil)
  =/  nm  name.op.n
  ?:  |(=(nm '$ConjList') =(nm '\\land'))
    ?~  args.n  (pnext cur part acts p fil)
    (psolve i.args.n cur part e (weld (pitems t.args.n e) acts) p fil)
  ?:  |(=(nm '$DisjList') =(nm '\\lor'))
    =/  alen  (lent args.n)
    ?:  =(0 alen)  [[%none ~] p]
    =^  ix  ls.p  (floor-scaled:rg ls.p alen)
    =^  pr  ls.p  (next-prime:rg ls.p)
    =/  i  0
    =/  idx  ix
    |-  ^-  [pres pst]
    ?:  =(i alen)  [[%none ~] p]
    =^  res  p  (psolve (snag idx args.n) cur part e acts p fil)
    ?.  ?=(%none -.res)  [res p]
    $(i +(i), idx (mod (add idx pr) alen))
  ?:  =(nm '$IfThenElse')
    =/  b  (eval-bool (snag 0 args.n) (senv %next cur part e))
    ?:  ?=(%| -.b)  [[%err p.b] p]
    (psolve ?:(p.b (snag 1 args.n) (snag 2 args.n)) cur part e acts p fil)
  ::  tlc2 REFUSES here rather than picking a branch: `Probabilistic evaluation
  ::  of next-state relation not implemented for CASE yet.` (Tool.java:1323),
  ::  which aborts the run with no model checking at all
  ?:  =(nm '$Case')
    :_  p
    :-  %err
    :-  0
    'unsupported: probabilistic evaluation of the next-state relation is not implemented for CASE (tlc2 -generate refuses the same way).'
  ?:  =(nm '$BoundedExists')
    =/  bs  (flatten-bound bound.n)
    ?.  ?=([* ~] bs)
      [[%err 0 'an action existential over multiple binders is unsupported.'] p]
    =/  sd  (eval-domain rng.i.bs (senv %next cur part e))
    ?:  ?=(%| -.sd)  [[%err p.sd] p]
    =/  el  (drain-sexp p.sd)
    ?:  ?=(%| -.el)  [[%err p.el] p]
    =/  xs=(list value:v)  p.el
    =/  nn  (lent xs)
    ?:  =(0 nn)  [[%none ~] p]
    =^  ixs  es.rs.p  (subset-indices:rg es.rs.p nn nn)
    =/  body  (snag 0 args.n)
    |-  ^-  [pres pst]
    ?~  ixs  [[%none ~] p]
    =/  e2  (bind-group e i.bs (snag i.ixs xs))
    =^  res  p  (psolve body cur part e2 acts p fil)
    ?.  ?=(%none -.res)  [res p]
    $(ixs t.ixs)
  ::  a bounded universal is NOT randomized by tlc2: it solves the first
  ::  element now and defers the rest onto the continuation
  ?:  =(nm '$BoundedForall')
    =/  bs  (flatten-bound bound.n)
    ?.  ?=([* ~] bs)
      [[%err 0 'an action universal over multiple binders is unsupported.'] p]
    =/  sd  (eval-domain rng.i.bs (senv %next cur part e))
    ?:  ?=(%| -.sd)  [[%err p.sd] p]
    =/  el  (drain-sexp p.sd)
    ?:  ?=(%| -.el)  [[%err p.el] p]
    =/  xs=(list value:v)  p.el
    ?~  xs  (pnext cur part acts p fil)
    =/  body  (snag 0 args.n)
    =/  rest  (flop (pgroup-items body i.bs t.xs e))
    (psolve body cur part (bind-group e i.bs i.xs) (weld rest acts) p fil)
  ?:  =(nm 'UNCHANGED')
    =/  names  (unchanged-vars (snag 0 args.n) psub.e)
    =/  out=state  part
    =.  out
      |-  ^-  state
      ?~  names  out
      =/  cv  (~(get by cur) i.names)
      ?~  cv  $(names t.names)
      $(names t.names, out (~(put by out) i.names u.cv))
    (pnext cur out acts p fil)
  ?:  =(nm '=')
    =/  as  (assignable-sem (snag 0 args.n) %next vars.e part psub.e)
    ?~  as  (pfilter n cur part e acts p fil)
    =^  rv  rs.p  (eval-rs (snag 1 args.n) (senv %next cur part e) rs.p)
    ?:  ?=(%| -.rv)  [[%err p.rv] p]
    (pnext cur (~(put by part) u.as p.rv) acts p fil)
  ?:  =(nm '\\in')
    =/  as  (assignable-sem (snag 0 args.n) %next vars.e part psub.e)
    ?~  as  (pfilter n cur part e acts p fil)
    =/  sd  (eval-domain (snag 1 args.n) (senv %next cur part e))
    ?:  ?=(%| -.sd)  [[%err p.sd] p]
    =/  el  (drain-sexp p.sd)
    ?:  ?=(%| -.el)  [[%err p.el] p]
    (pbind-elems u.as p.el cur part acts p fil)
  ?:  =(nm '\\subseteq')
    =/  as  (assignable-sem (snag 0 args.n) %next vars.e part psub.e)
    ?~  as  (pfilter n cur part e acts p fil)
    =^  rv  rs.p  (eval-rs (snag 1 args.n) (senv %next cur part e) rs.p)
    ?:  ?=(%| -.rv)  [[%err p.rv] p]
    =/  el  (drain-sexp [%subset p.rv])
    ?:  ?=(%| -.el)  [[%err p.el] p]
    (pbind-elems u.as p.el cur part acts p fil)
  ?:  ?=(^ (anysubstin-mod:sm nm))
    =/  sp  (substin-parts:sm n)
    ?~  sp  (pfilter n cur part e acts p fil)
    =/  e2  (bind-substs (senv %next cur part e) names.u.sp exprs.u.sp)
    ?:  ?=(%| -.e2)  [[%err p.e2] p]
    (psolve inner.u.sp cur part p.e2 acts p fil)
  ?:  ?=(%user-op kind.op.n)
    =/  d  (~(get by ops.e) nm)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  (pfilter n cur part e acts p fil)
    ?.  =((lent params.u.d) (lent args.n))  (pfilter n cur part e acts p fil)
    ?:  =(0 fuel.e)  [[%err 0 'evaluation recursion/resource limit exceeded.'] p]
    =/  e2  (bind-psub e(fuel (dec fuel.e)) params.u.d args.n)
    ?:  ?=(%| -.e2)  [[%err p.e2] p]
    (psolve u.body.u.d cur part p.e2 acts p fil)
  (pfilter n cur part e acts p fil)
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
