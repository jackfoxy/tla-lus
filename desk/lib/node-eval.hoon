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
      ::  R2.7.14b: `TLCExt!CounterExample` -- the counter-example the run just
      ::  produced, as a VALUE. tlc2 carries it in the evaluation `Context`
      ::  (`Tool.checkPostConditionWithCounterExample` does
      ::  `Context.Empty.cons(getCounterExampleDef(), value)`) and the
      ::  `@Evaluation` override reads it back with `c.lookup(...)`. The port's
      ::  `Context` analogue for run-scoped facts is this env, the same slot
      ::  `run` uses.
      ::
      ::  `~` is NOT "no counter-example": it is "not in the scope of a
      ::  POSTCONDITION at all". Measured at the pin, a CLEAN run evaluates
      ::  `new CounterExample()` -- an EMPTY record -- so `+eval-counter-example`
      ::  answers with the empty one either way, and `CounterExample.state = {}`
      ::  stays the idiom `_JsonTrace`/`_DotTrace` use to detect "no violation"
      ce=(unit value:v)
      ::  R4.P3 (H4): zero-arity CONSTANT-level definitions evaluated ONCE,
      ::  tlc2's `SpecProcessor.processConstantDefns`. Keyed by name, holding
      ::  the definition the value came from, so a LET of the same name (a
      ::  different `sem-def`) is never answered from here
      cdefs=(map @t [def=sem-def:sm val=value:v])
      ::  R4.2e: the search's state IDENTITY (symmetry group, VIEW body), so
      ::  the liveness product keys a successor exactly as the graph build
      ::  keyed it (`+live-key:lv`); `[~ ~]` = the plain FP64 identity
      idk=[perms=(list (map @t @t)) view=(unit sem:sm)]
      ::  R4.3: the scope each call-by-name INSTANCE substitution was written
      ::  in. tlc2 resolves a name by its SANY node, so `T <- SeqToSet(T) \cup
      ::  {<<state, succ>> : succ \in successors}` reads the INSTANTIATING
      ::  module's `successors` even though the instance substitutes its own
      ::  `successors` too; the port binds by name, and read in the instance
      ::  body's env the expression captured the sibling substitution
      ::  (TestGraphs' `Refinement`: a wrong implied-action failure)
      pout=(map @t clo)
      ::  R4.3: a bound on the elements an INIT `x \in {y \in S : P}`
      ::  assignment takes (0 = none), so a capped run never solves more
      ::  initial states than its state bound can register. The kernel sets
      ::  it and re-solves unbounded if the bound cut a smaller set (`trunc`)
      ilim=@ud
  ==
::  a call-by-name entry's defining scope (+outer-of), with the expression it
::  was recorded for: a later rebinding of the name leaves it stale. TWO
::  levels, not a recursive mold (one loops zuse-408's mold compiler): the
::  scope keeps its own parent's closures one level deep, enough for an
::  instance inside an instance (TestGraphs -> TLCMC -> MCReachability)
+$  clo1  [sub=sem:sm psub=(map @t sem:sm) vals=(map @t value:v)]
+$  clo
  $:  sub=sem:sm
      psub=(map @t sem:sm)
      vals=(map @t value:v)
      pout=(map @t clo1)
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
      ::  the NAMED half of the same store (R2.7.7.4a). tlc2 keys it on a
      ::  string beginning `s:` (`TLCGetSet.NAMED_REGISTER_PREFIX`), and
      ::  MEASURED, any other string is still the positional argument error:
      ::  `TLCSet("plain", 7)` raises `The first argument of TLCSet should be a
      ::  nonnegative integer`. The two halves coexist -- `TLCSet(3, 42)` and
      ::  `TLCSet("s:c", ..)` in one action leave both readable
      named=(map @t value:v)
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
      ::  R4.2a: the lines `TLC!Print` / `TLC!PrintT` wrote, NEWEST FIRST.
      ::  tlc2 prints at the moment of evaluation, so the output is a run-state
      ::  effect exactly as a draw or a `TLCSet` write is, and rides the same
      ::  carrier; the caller flops it
      out=(list @t)
      ::  R4.2f: the files `JsonSerialize` / `ndJsonSerialize` wrote, by the
      ::  path the spec named; a later write to the same path replaces it, as
      ::  the pin's `FileWriter` truncates. The job turns each into an artifact
      files=(map @t @t)
      ::  R4.2g: intermediate states an action composition generated
      ::  (`A \cdot B`'s `s -A-> t`), which tlc2 counts as generated
      ::  (`nss.incrementStatesGenerated`); `+bfs-step` adds and clears it
      xgen=@ud
      ::  R4.3: an `ilim`-bounded init assignment stopped before its domain
      ::  was exhausted
      trunc=?
  ==
::  a solver result carrying the run state, and its evaluator sibling. UNFACED,
::  like `[pres pst]` on the `-generate` path: a face on the head leaks into
::  whatever `=^` binds, so `p.r` on the bound result stops resolving
+$  sout  [sres rst]
+$  eout  [eres rst]
++  empty-rst  ^-(rst [~ ~ 0 0 ~ ~ 0 |])
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
    ?~  sb  [(lookup-val nm e) rs]
    ?:  (bare-self u.sb nm e)  [(lookup-var nm e) rs]
    (eval-rs u.sb (outer-of nm e) rs)
  ::
    ::  a substituted name resolves to the node it was bound to, in the
    ::  OUTER scope -- `v <- x` makes the inner module's `v` read the outer
    ::  state's `x`. Same call-by-name shape `%formal-param` uses (R2.3.5)
      %variable
    =/  sb  (~(get by psub.e) nm)
    ?~  sb  [(lookup-var nm e) rs]
    ?:  (bare-self u.sb nm e)  [(lookup-var nm e) rs]
    (eval-rs u.sb (outer-of nm e) rs)
  ::
    ::  R4.2ah: a NAMED theorem or assumption is its body (`+thm-defs:sm`)
      %thm-assump
    =/  tn  (cat 3 '$thm:' nm)
    ?.  (~(has by ops.e) tn)
      [[%| 0 'a theorem/assumption is not an evaluable value.'] rs]
    (eval-user n(name.op tn) e rs)
  ::
    %module-instance  [[%| 0 'a module instance is not an evaluable value.'] rs]
  ==
::
++  outer-of
  ::  the env a call-by-name entry's expression is read in. It was written in
  ::  an OUTER scope, where the inner name it is bound to does not exist:
  ::  braf's `RAF == INSTANCE RandomAccessFile WITH file_content <-
  ::  LogicalFileContent`, whose root body names the root's own
  ::  `file_content`, looped through the substitution
  ::  R4.3: an INSTANCE substitution is read in the scope it was written in
  ::  (`pout`), where neither the instance body's bindings nor the sibling
  ::  substitutions exist
  |=  [nm=@t e=eenv]
  ^-  eenv
  =/  o  (~(get by pout.e) nm)
  ?.  ?&(?=(^ o) =(`sub.u.o (~(get by psub.e) nm)))
    e(psub (~(del by psub.e) nm))
  %=  e
    psub  psub.u.o
    vals  vals.u.o
    pout  (~(run by pout.u.o) |=(c=clo1 `clo`[sub.c psub.c vals.c ~]))
  ==
::
++  by-name
  ::  R4.2m: the expression a bare CONSTANT or VARIABLE reference is bound to
  ::  call-by-name (`psub`), when it has no value of its own
  |=  [n=sem:sm e=eenv]
  ^-  (unit sem:sm)
  ?.  ?=(%apply -.n)  ~
  ?.  ?=(~ args.n)  ~
  ?.  ?=(?(%constant %new-constant %variable %formal-param) kind.op.n)  ~
  ?:  (~(has by vals.e) name.op.n)  ~
  =/  sb  (~(get by psub.e) name.op.n)
  ?~  sb  ~
  ?:  (bare-self u.sb name.op.n e)  ~
  sb
::
++  bnm
  ::  R4.2v: an operator's name WITHOUT its instance qualification
  ::  (`Buffer!Cardinality`, `$Local:I!Op` -> the last `!`-segment). The
  ::  StandardModule override registry is keyed by the operator's own name in
  ::  its own module; an instance-imported member carries a qualified one
  |=  nm=@t
  ^-  @t
  =/  t  (trip nm)
  =/  r  (flop t)
  =/  i  (find "!" r)
  ?~  i  nm
  (crip (flop (scag u.i r)))
::
++  self-ref
  ::  R4.2n: is a call-by-name binding of `nm` a bare reference to `nm`
  ::  itself? An unnamed `INSTANCE M` substitutes M's variables by NAME
  ::  (`sBit <- sBit`), and an operator may be called with a variable of its
  ::  formal's name; chasing such a binding re-reads the same binding forever,
  ::  an infinite recursion that exhausts the loom inside one event (it took
  ::  the ship down on MCAlternatingBit). `+deref-sem` has had this guard
  ::  since R2.3.5; the evaluator's lookups did not
  |=  [s=sem:sm nm=@t]
  ^-  ?
  ?.  ?=(%apply -.s)  |
  ?.  ?=(~ args.s)  |
  ?.  ?=(?(%variable %formal-param) kind.op.s)  |
  =(nm name.op.s)
::
++  bare-self
  ::  R4.3: a self-referential binding (`+self-ref`) with no recorded scope.
  ::  One an INSTANCE substitution recorded (`pout`) names the INSTANTIATING
  ::  module's `nm`, which may itself be substituted: EWD998Chan's nested
  ::  `INSTANCE EWD998` substitutes `active <- active`, EWD998Chan's own
  ::  `active <- Node2Nat(active)` -- read as the state variable, an
  ::  integer-domain function met a node (EWD998ChanID). `+outer-of` reads
  ::  such a binding in that scope, one level out, so it terminates
  |=  [s=sem:sm nm=@t e=eenv]
  ^-  ?
  ?.  (self-ref s nm)  |
  =/  o  (~(get by pout.e) nm)
  ?~  o  &
  !=(s sub.u.o)
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
  ::  R4.2m: a CONSTANT the config overrides (`C <- D`) has no value; it
  ::  denotes `D`'s definition, which `+apply-overrides:check` bound to its
  ::  name in `ops`
  ?:  ?&(!(~(has by vals.e) nm) (~(has by ops.e) nm))
    (eval-user n e rs)
  ::  R4.2m: a CONSTANT an INSTANCE substitution bound by name (`+bind-substs`)
  =/  sb  ?.(?=(~ args.n) ~ ?:((~(has by vals.e) nm) ~ (~(get by psub.e) nm)))
  ?:  &(?=(^ sb) !(bare-self u.sb nm e))  (eval-rs u.sb (outer-of nm e) rs)
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
  ::  R4.2m: a name bound call-by-name denotes its expression's set
  =/  sb  (by-name n e)
  ?^  sb  $(n u.sb, e (outer-of name.op.n e))
  =/  nm  name.op.n
  ?:  =(nm 'SUBSET')      (un-sexp %subset args.n e)
  ?:  =(nm 'UNION')       (un-sexp %union args.n e)
  ?:  =(nm '\\union')     (bin-sexp %cup args.n e)
  ?:  =(nm '\\intersect')  (bin-sexp %cap args.n e)
  ?:  =(nm '\\')          (bin-sexp %diff args.n e)
  ?:  |(=(nm '\\times') =(nm '$CartesianProd'))  (prod-sexp args.n e)
  ?:  =(nm '$SetOfFcns')  (fcns-sexp args.n e)
  ?:  =(nm '$SetOfRcds')  (rcds-sexp args.n e)
  ::  R4.2 (CoffeeCan): an instanced definition's `$SubstIn` wrapper, and a
  ::  zero-arity user definition with no value yet, denote their bodies'
  ::  sets, kept lazy as tlc2 keeps them (`Can == [black : 0..1000, white :
  ::  0..1000]` has 1,002,001 records; `{c \in Can : ...}` streams it)
  ?^  (anysubstin-mod:sm nm)
    =/  sp  (substin-parts:sm n)
    ?~  sp  (as-sexp (eval n e))
    =/  e2  (bind-substs e names.u.sp exprs.u.sp)
    ?:  ?=(%| -.e2)  e2
    $(n inner.u.sp, e p.e2)
  ::  a StandardModule set operator (Nat, Int) denotes an infinite set: it
  ::  has a lazy descriptor here, though it is not a value (unit 6C.2)
  =/  d  (~(get by ops.e) nm)
  ?~  d  (as-sexp (eval n e))
  ?:  ?&  ?=(~ args.n)
          ?=(%user-op kind.op.n)
          ?=(~ params.u.d)
          ?=(^ body.u.d)
          !(~(has by vals.e) nm)
          !(~(has by cdefs.e) nm)
          !(is-standard:so ov.e origin.u.d)
          ?=(~ (lookup:so ov.e [origin.u.d (bnm name.u.d) 0]))
          ?=(~ (node-op:so [origin.u.d (bnm name.u.d) 0]))
          (gth fuel.e 0)
      ==
    $(n u.body.u.d, fuel.e (dec fuel.e))
  =/  key=op-key:so  [origin.u.d (bnm name.u.d) (lent args.n)]
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
  ::  R4.2m: a labeled expression `P :: e` is its body (tlc2 LabelKind)
  ?:  &(=(nm '$Label') ?=(^ as))  (eval-rs i.as e rs)
  ::  R4.2am: a selected subexpression (`Thm!:`) is wrapped in `$Nop`, which
  ::  tlc2 evaluates as its argument (OPCODE_nop)
  ?:  &(=(nm '$Nop') ?=(^ as))  (eval-rs i.as e rs)
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
  ?:  &(=(nm '$SquareAct') ?=([* * ~] as))  (eval-act-sub | as e rs)
  ?:  &(=(nm '$AngleAct') ?=([* * ~] as))   (eval-act-sub & as e rs)
  ?:  =(nm 'ENABLED')     (eval-enabled-rs (snag 0 as) e rs)
  ::  set constructors (forced when used as a value)
  ?:  (~(has in set-ctor-names) nm)
    ::  a set constructor whose operand fails to evaluate is a typed failure,
    ::  not an assertion: `s \ {CHOOSE y \in s : TRUE}` with an empty `s` used
    ::  to crash the evaluator through +need-sexp's ?>, which a recursive
    ::  function definition reaches whenever a sweep tries a point it cannot
    ::  yet solve (R1.4.2)
    ::  R4.2aa: when an operand DRAWS (`UNION {.. RandomElement(..) ..}`,
    ::  SpanTreeRandom's `Edges`), the operands are evaluated on the stream
    ::  first, in order, and the set built from their values
    =/  dx=(unit sout-sexp)
      ?.  (sem-draws n e)  ~
      `(ctor-args-rs n e rs)
    ?^  dx
      =/  [r=(each sexp:v eval-err:v) rs2=rst]  u.dx
      ?:  ?=(%| -.r)  [r rs2]
      [(force:v p.r setmax.e) rs2]
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
  ::  R4.2g: `A \cdot B` as a predicate (Tool.java:2771): TRUE when some
  ::  `s0 -A-> t` (A solved from an EMPTY successor, not `copyWith`) has
  ::  `t -B-> s1`
  ?:  &(=(nm '\\cdot') ?=([* * ~] as))
    ?.  (cdot-on e)  [[%| 0 cdot-msg] rs]
    =^  ra  rs  (solve i.as %next s0.e ~ e rs)
    ?:  ?=(%| -.ra)  [ra rs]
    =/  ts  p.ra
    |-  ^-  eout
    ?~  ts  [[%& [%bool |]] rs]
    =^  b  rs  (eval-bool-rs i.t.as e(s0 i.ts, primed |) rs)
    ?:  ?=(%| -.b)  [b rs]
    ?:  p.b  [[%& [%bool &]] rs]
    $(ts t.ts)
  ::  R4.2a: above the boundary when the body DRAWS or PRINTS
  ::  (`+sem-draws`): tlc2 prints at each evaluation, so `\E p \in S :
  ::  IF Ok(p) THEN PrintT(p) ELSE FALSE` (Stones) must print per witness
  ::  tried, and stop where the quantifier stops
  ?:  &(=(nm '$BoundedForall') (sem-draws n e))  (eval-quant-rs n e %all rs)
  ?:  &(=(nm '$BoundedExists') (sem-draws n e))  (eval-quant-rs n e %ex rs)
  ?:  &(=(nm '$BoundedChoose') (sem-draws n e))  (eval-quant-rs n e %choose rs)
  ?:  &(=(nm '$SubsetOf') (sem-draws n e))  (eval-quant-rs n e %filter rs)
  ?:  =(nm '$BoundedForall')  [(eval-forall n e) rs]
  ?:  =(nm '$BoundedExists')  [(eval-exists n e) rs]
  ?:  =(nm '$BoundedChoose')  [(eval-choose n e) rs]
  ?:  =(nm '$SubsetOf')   [(eval-subsetof n e) rs]
  ::  R4.2aa: above the boundary when the body DRAWS (`+body-draws`): tlc2
  ::  evaluates `{e : x \in S}` and `[x \in S |-> e]` eagerly, element by
  ::  element, on ONE advancing RNG, so `{RandomElement(T) : n \in N}` draws
  ::  once per `n`. Below the boundary every element drew from the same
  ::  state and got the same value (SpanTreeRandom's `Edges` came out empty)
  ?:  =(nm '$SetOfAll')
    ?.  (body-draws n e)  [(eval-setofall n e) rs]
    (eval-image-rs n e | rs)
  ?:  |(=(nm '$FcnConstructor') =(nm '$NonRecursiveFcnSpec'))
    ?.  (body-draws n e)  [(eval-fcncon n e) rs]
    (eval-image-rs n e & rs)
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
+$  sout-sexp  [(each sexp:v eval-err:v) rst]
::
++  ctor-args-rs
  ::  R4.2aa: a set constructor's operands evaluated on the stream, in
  ::  order, then the constructor's descriptor over their values. `$SetOfRcds`
  ::  (field names ride the operands) keeps the descriptor path
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  sout-sexp
  =/  nm  name.op.n
  =/  as  args.n
  =|  vs=(list value:v)
  =/  xs  as
  |-  ^-  sout-sexp
  ?^  xs
    =^  r  rs  (eval-rs i.xs e rs)
    ?:  ?=(%| -.r)  [r rs]
    $(xs t.xs, vs [p.r vs])
  =.  vs  (flop vs)
  :_  rs
  ?:  &(=(nm 'SUBSET') ?=([* ~] vs))  [%& [%subset i.vs]]
  ?:  &(=(nm 'UNION') ?=([* ~] vs))  [%& [%union i.vs]]
  ?:  &(=(nm '\\union') ?=([* * ~] vs))  [%& [%cup i.vs i.t.vs]]
  ?:  &(=(nm '\\intersect') ?=([* * ~] vs))  [%& [%cap i.vs i.t.vs]]
  ?:  &(=(nm '\\') ?=([* * ~] vs))  [%& [%diff i.vs i.t.vs]]
  ?:  |(=(nm '\\times') =(nm '$CartesianProd'))  [%& [%prod vs]]
  ?:  &(=(nm '$SetOfFcns') ?=([* * ~] vs))  [%& [%fcns i.vs i.t.vs]]
  (eval-domain n e)
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
++  eval-act-sub
  ::  `[A]_e` (`ang` |) is A \/ e' = e; `<<A>>_e` (`ang` &) is A /\ e' # e
  ::  (Tool.eval OPCODE_sa / OPCODE_aa: A first, then the subscript)
  |=  [ang=? as=(list sem:sm) e=eenv rs=rst]
  ^-  eout
  =^  a  rs  (eval-rs (snag 0 as) e rs)
  ?:  ?=(%| -.a)  [a rs]
  ?.  ?=(%bool -.p.a)
    :_  rs
    :+  %|  0
    ?:  ang
      'Attempted to evaluate an expression of form <A>_e, but A was not a boolean.'
    'Attempted to evaluate an expression of form [A]_e, but A was not a boolean.'
  ?:  =(ang !p.p.a)  [[%& [%bool p.p.a]] rs]
  =^  u  rs  (eval-unchanged (slag 1 as) e rs)
  ?:  ?=(%| -.u)  [u rs]
  ?>  ?=(%bool -.p.u)
  [[%& [%bool ?:(ang !p.p.u p.p.u)]] rs]
::
++  bi-in
  |=  [as=(list sem:sm) e=eenv neg=? rs=rst]
  ^-  eout
  =^  x  rs  (eval-rs (snag 0 as) e rs)
  ?:  ?=(%| -.x)  [x rs]
  =/  m  (memb-node p.x (snag 1 as) e)
  ?:  ?=(%| -.m)  [m rs]
  [[%& [%bool ?:(neg !p.m p.m)]] rs]
::
++  memb-node
  ::  R4.2m: membership decided on the STRUCTURE of the set expression, as
  ::  tlc2's lazy values decide it (SetDiffValue, SetCupValue, SetCapValue,
  ::  SetOfFcnsValue, SetOfRcdsValue, SubsetValue each delegate `member`
  ::  to their operands). The flat `sexp` forces every operand to a value,
  ::  so an infinite operand -- `N \in Nat \ {0}` (12 Examples ASSUMEs),
  ::  `req \in [Proc -> [Proc -> Nat]]`, `[age : Int]` -- failed
  ::  "unsupported StandardModule operator". Anything else is the existing
  ::  lazy descriptor path, so finite membership is unchanged
  |=  [x=value:v n=sem:sm e=eenv]
  ^-  (each ? eval-err:v)
  =/  sb  (by-name n e)
  ?^  sb  $(n u.sb, e ?.(?=(%apply -.n) e (outer-of name.op.n e)))
  =/  dflt
    |.  ^-  (each ? eval-err:v)
    =/  sd  (eval-domain n e)
    ?:  ?=(%| -.sd)  sd
    (set-member:v x p.sd)
  ?.  ?=(%apply -.n)  $:dflt
  =/  nm  name.op.n
  =/  as  args.n
  ::  R4.2 (MCNano): an instanced definition's body is its `$SubstIn`
  ::  wrapper; membership is decided on the INNER structure under the
  ::  substitutions, as eval binds them. `distributedLedger \in [Node ->
  ::  N!Ledger]` forced `[Hash -> SignedBlock \cup {NoBlock}]` (> 1,000,000)
  ?^  (anysubstin-mod:sm nm)
    =/  sp  (substin-parts:sm n)
    ?~  sp  $:dflt
    =/  e2  (bind-substs e names.u.sp exprs.u.sp)
    ?:  ?=(%| -.e2)  e2
    $(n inner.u.sp, e p.e2)
  ?:  ?&(=(nm '\\') ?=([* * ~] as))
    =/  a  $(n i.as)
    ?:  |(?=(%| -.a) !p.a)  a
    =/  b  $(n i.t.as)
    ?:  ?=(%| -.b)  b
    [%& !p.b]
  ?:  ?&(=(nm '\\union') ?=([* * ~] as))
    =/  a  $(n i.as)
    ?:  |(?=(%| -.a) p.a)  a
    $(n i.t.as)
  ?:  ?&(=(nm '\\intersect') ?=([* * ~] as))
    =/  a  $(n i.as)
    ?:  |(?=(%| -.a) !p.a)  a
    $(n i.t.as)
  ::  R4.2ag: `x \in {y \in S : P}` is `x \in S /\ P[y := x]`, decided
  ::  lazily as tlc2's `SetPredValue.member` does. MCQuicksort's
  ::  `UV \in DomainPartitions` filters `SUBSET SUBSET (1..Len(seq0))`: the
  ::  flat path built all 65,536 subsets on every state
  ?:  ?&  =(nm '$SubsetOf')
          ?=([* ~] as)
          ?=([* ~] (flatten-bound bound.n))
      ==
    =/  g  (snag 0 (flatten-bound bound.n))
    =/  m  $(n rng.g)
    ?:  |(?=(%| -.m) !p.m)  m
    (eval-bool i.as (bind-group e g x))
  ::  `UNION {S1, ..., Sn}`: a member of some Si (tlc2's UnionValue.member
  ::  asks each element set). Disruptor's `slots: UNION {[0 .. LastIndex ->
  ::  Values \union {NULL}]}` with `Values <- Int`
  ?:  ?&  =(nm 'UNION')
          ?=([* ~] as)
          ?=(%apply -.i.as)
          =('$SetEnumerate' name.op.i.as)
      ==
    =/  ss  args.i.as
    |-  ^-  (each ? eval-err:v)
    ?~  ss  [%& |]
    =/  r  ^$(n i.ss)
    ?:  |(?=(%| -.r) p.r)  r
    $(ss t.ss)
  ?:  ?&(=(nm 'SUBSET') ?=([* ~] as))
    ?.  (set-like:v x)  [%& |]
    =/  els  (set-elems:v (normalize:v x))
    |-  ^-  (each ? eval-err:v)
    ?~  els  [%& &]
    =/  r  ^$(x i.els, n i.as)
    ?:  |(?=(%| -.r) !p.r)  r
    $(els t.els)
  ?:  ?&(=(nm '$SetOfFcns') ?=([* * ~] as))
    ?.  (fcn-like:v x)  [%& |]
    =/  ps  (fcn-pairs:v x)
    =/  d  (eval i.as e)
    ?:  ?=(%| -.d)  d
    =/  dom-x  (normalize:v [%set %set-enum (turn ps |=(pr=vpair:v d.pr))])
    ?.  (equal:v dom-x p.d)  [%& |]
    |-  ^-  (each ? eval-err:v)
    ?~  ps  [%& &]
    =/  r  ^$(x r.i.ps, n i.t.as)
    ?:  |(?=(%| -.r) !p.r)  r
    $(ps t.ps)
  ?:  =(nm '$SetOfRcds')
    ?.  ?=(%rec -.x)  [%& |]
    ?.  =((lent p.x) (lent as))  [%& |]
    |-  ^-  (each ? eval-err:v)
    ?~  as  [%& &]
    =/  pr  i.as
    ?.  ?=(%apply -.pr)  [%| 0 'malformed set-of-records field.']
    =/  k  (lit-str (snag 0 args.pr))
    =/  hit  (skim p.x |=(fd=vfield:v =(k k.fd)))
    ?~  hit  [%& |]
    =/  r  ^$(x v.i.hit, n (snag 1 args.pr))
    ?:  |(?=(%| -.r) !p.r)  r
    $(as t.as)
  ::  `Seq(R)`: a sequence whose every element is in R (tlc2
  ::  Sequences.member), when `Seq` is still the StandardModule's
  =/  d  (~(get by ops.e) nm)
  ::  a zero-arity user DEFINITION (`Message == TokenMsg \cup BasicMsg`,
  ::  EWD998Chan) is its body: tlc2's value for it is the same lazy set.
  ::  A StandardModule operator keeps its own handling (the descriptor or
  ::  override path below), and the fuel bounds a definition that names
  ::  itself
  ::  (a constant definition R4.P3 already evaluated answers from its value)
  =/  cd  ?.(?=(~ as) ~ (~(get by cdefs.e) nm))
  ?:  &(?=(^ cd) ?=(^ d) =(def.u.cd u.d))
    (set-member:v x [%set val.u.cd])
  ::  R4.2aa: so does one with a VALUE in `vals` -- a definition drawn at
  ::  startup (`+startup-draws`) or valued by the config. Expanding its body
  ::  re-drew it: SpanTreeRandom's `\A e \in Edges : e \in Edges` was FALSE
  ?:  &(?=(~ as) ?=(%user-op kind.op.n) (~(has by vals.e) nm))
    (set-member:v x [%set (~(got by vals.e) nm)])
  ?:  ?&  ?=(^ d)
          ?=(~ as)
          ?=(%user-op kind.op.n)
          ?=(~ params.u.d)
          ?=(^ body.u.d)
          !(is-standard:so ov.e origin.u.d)
          (gth fuel.e 0)
      ==
    $(n u.body.u.d, fuel.e (dec fuel.e))
  ::  R4.2ag: so is an application of a user operator (`U \in DPs(4)`):
  ::  its arguments bound in the caller's env, as `+eval-user` binds them,
  ::  and membership decided on the body's structure
  ?:  ?&  ?=(^ d)
          ?=(^ as)
          ?=(%user-op kind.op.n)
          ?=(^ body.u.d)
          =((lent params.u.d) (lent as))
          (levy params.u.d |=(p=spar:sm =(0 arity.p)))
          !(is-standard:so ov.e origin.u.d)
          ?=(~ (lookup:so ov.e [origin.u.d (bnm name.u.d) (lent as)]))
          ?=(~ (node-op:so [origin.u.d (bnm name.u.d) (lent as)]))
          (gth fuel.e 0)
      ==
    =/  e2  (bind-params e params.u.d as)
    ?:  ?=(%| -.e2)  e2
    $(n u.body.u.d, e p.e2(fuel (dec fuel.e)))
  ?:  ?&  ?=(^ d)
          ?=([* ~] as)
          =('Seq' (bnm name.u.d))
          (is-descriptor:so [origin.u.d (bnm name.u.d) 1])
      ==
    =/  tp  (to-tuple:v x)
    ?~  tp  $:dflt
    =/  els  u.tp
    |-  ^-  (each ? eval-err:v)
    ?~  els  [%& &]
    =/  r  ^$(x i.els, n i.as)
    ?:  |(?=(%| -.r) !p.r)  r
    $(els t.els)
  $:dflt
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
  ?:  ?=(%| -.sb)
    ::  R4.2m: B has no lazy descriptor (`[content : M, age : Int]`): tlc2's
    ::  `isSubsetEq` streams A and asks B's lazy `member` per element, which
    ::  `+memb-node` decides on B's structure
    =/  els  (drain-sexp p.sa)
    ?:  ?=(%| -.els)  els
    =/  es  p.els
    |-  ^-  eres
    ?~  es  [%& [%bool &]]
    =/  m  (memb-node i.es rn e)
    ?:  ?=(%| -.m)  m
    ?.  p.m  [%& [%bool |]]
    $(es t.es)
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
  =/  rf  (recfcn-infinite (snag 0 as) e)
  ?^  rf  (apply-recfcn u.rf (snag 1 as) e rs)
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
  =/  f  (lit-str (snag 1 as))
  ::  tlc2's `r.f` wording (Tool.java OPCODE_rs), up to the expression's
  ::  location, which it appends and a span here cannot name (no module)
  ?:  ?&  ?=(%rec -.p.r)
          !(lien p.p.r |=(fd=vfield:v =(k.fd f)))
      ==
    :_  rs
    :+  %|  0
    %+  rap  3
    :~  'Attempted to select nonexistent field "'  f  '" from the record\0a'
        (crip (render:v p.r))
    ==
  [(apply:v p.r [%str f] |) rs]
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
    e      e(vals (~(put by vals.e) i.names i.vs), psub (~(del by psub.e) i.names))
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
  ::  R4.2c (TestGraphs): a binding SHADOWS a call-by-name entry of the same
  ::  name -- an unnamed `INSTANCE TLCMC` binds its variable `i` by name, and
  ::  `{seq[i] : i \in 1..Len(seq)}` inside it then read the STATE variable
  ::  for its bound `i`
  ?.  tup.g
    ?~  nms.g  e
    e(vals (~(put by vals.e) i.nms.g w), psub (~(del by psub.e) i.nms.g))
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
++  bound-domains
  ::  every binder group's domain, drained to elements and all evaluated in
  ::  ONE env. `Tool.contexts` passes the SAME context `c` to each
  ::  `eval(domains[i], ...)`, so the bounds of `\E i \in S, j \in T` are
  ::  INDEPENDENT -- unlike a function constructor's, which +ctx-doms binds
  ::  prefix-wise. Measured, not assumed. R3.0c
  |=  [gs=(list bgroup) e=eenv]
  ^-  (each (list (list value:v)) eval-err:v)
  ?~  gs  [%& ~]
  =/  sd  (eval-domain rng.i.gs e)
  ?:  ?=(%| -.sd)  sd
  =/  els  (drain-sexp p.sd)
  ?:  ?=(%| -.els)  els
  =/  rest  $(gs t.gs)
  ?:  ?=(%| -.rest)  rest
  [%& [p.els p.rest]]
::
++  bind-rows
  ::  the odometer over drained domains, one value per group.
  ::  `ContextEnumerator.nextElement` advances index 0 first and carries
  ::  upward, so the LEADING binder varies FASTEST -- which is the order the
  ::  successor stream is compared in, not just a set. R3.0c
  |=  ds=(list (list value:v))
  ^-  (list (list value:v))
  ?~  ds  ~[~]
  =/  rest  $(ds t.ds)
  %-  zing
  %+  turn  rest
  |=  r=(list value:v)
  (turn i.ds |=(w=value:v `(list value:v)`[w r]))
::
++  draw-orders
  ::  one randomized index permutation PER BINDER GROUP, drawn in GROUP ORDER.
  ::
  ::  R3.0d, and the ordering IS the unit, so it was measured before it was
  ::  written. `Tool.contexts(Ordering.RANDOMIZED, ...)` builds one
  ::  `ValueEnumeration` per group and each `SubsetEnumerator` draws exactly
  ::  twice at CONSTRUCTION -- `nextInt(n)` for the seed and `nextPrime` for
  ::  the increment -- which is what `+subset-indices` reproduces. And
  ::  **`SubsetEnumerator.reset()` is `i = 0` and nothing else**
  ::  (`EnumerableValue.java:172`): it rewinds, it does NOT reseed. So an
  ::  inner group REPLAYS the same permutation on every carry of the odometer,
  ::  the draws all happen up front in group order, and no RNG value is
  ::  consumed during enumeration. That is why this arm can draw everything
  ::  once and hand the walk a fixed list
  |=  [ds=(list (list value:v)) es=@]
  ^-  [(list (list @ud)) @]
  ?~  ds  [~ es]
  =/  nn  (lent i.ds)
  =^  ixs  es  (subset-indices:rg es nn nn)
  =^  rest  es  $(ds t.ds)
  [[ixs rest] es]
::
++  order-rows
  ::  the odometer over drained domains under a per-group index PERMUTATION --
  ::  `+bind-rows` with each group walked in its drawn order instead of its
  ::  enumeration order. Index 0 still advances FIRST
  ::  (`ContextEnumerator.nextElement`), so the LEADING binder varies fastest
  ::  here exactly as it does in the exhaustive path. R3.0d
  |=  [ds=(list (list value:v)) os=(list (list @ud))]
  ^-  (list (list value:v))
  ?~  ds  ~[~]
  ?~  os  ~[~]
  =/  rest  $(ds t.ds, os t.os)
  %-  zing
  %+  turn  rest
  |=  r=(list value:v)
  %+  turn  i.os
  |=(ix=@ud `(list value:v)`[(snag ix i.ds) r])
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
++  eval-quant-rs
  ::  R4.2a: `\A`, `\E`, `CHOOSE` and the set filter over their bound
  ::  domains in tlc2's enumeration order (`+bound-domains`, `+bind-rows`:
  ::  ContextEnumerator, leading binder fastest), the body on the carrier,
  ::  stopping where tlc2 stops (the first FALSE, the first TRUE, the first
  ::  witness). CHOOSE and the filter take one binder group, as below the
  ::  boundary
  |=  [n=sem-apply:sm e=eenv k=?(%all %ex %choose %filter) rs=rst]
  ^-  eout
  =/  bs  (flatten-bound bound.n)
  ?~  bs  [[%| 0 'unbounded quantifier is not enumerable.'] rs]
  ?:  &(?=(?(%choose %filter) k) ?=(^ t.bs))
    [[%| 0 'CHOOSE expects one bounded variable.'] rs]
  =/  ds  (bound-domains bs e)
  ?:  ?=(%| -.ds)  [ds rs]
  =/  body  (snag 0 args.n)
  =/  rows  (bind-rows p.ds)
  =|  keep=(list value:v)
  |-  ^-  eout
  ?~  rows
    :_  rs
    ?-  k
      %all     [%& [%bool &]]
      %ex      [%& [%bool |]]
      %choose  [%| 0 'CHOOSE: no element of the domain satisfies the predicate.']
      %filter  [%& (normalize:v [%set %set-enum (flop keep)])]
    ==
  =^  b  rs  (eval-bool-rs body (bind-vals e bs i.rows) rs)
  ?:  ?=(%| -.b)  [b rs]
  ?-  k
    %all     ?.(p.b [[%& [%bool |]] rs] $(rows t.rows))
    %ex      ?:(p.b [[%& [%bool &]] rs] $(rows t.rows))
    %choose  ?:(p.b [[%& (snag 0 i.rows)] rs] $(rows t.rows))
    %filter  $(rows t.rows, keep ?:(p.b [(snag 0 i.rows) keep] keep))
  ==
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
++  body-draws
  ::  R4.2aa: may a one-binder set map or function constructor draw? Its
  ::  body names a drawing operator, directly or through the definitions it
  ::  reaches (`+reach-names`). Conservative: a false positive only takes
  ::  the eager path, which a set map materializes anyway
  ::  The whole node is tested, its bound included: a draw in the DOMAIN
  ::  (`{m : m \in RandomElement(..)}`) must advance the stream too
  |=  [n=sem-apply:sm e=eenv]
  ^-  ?
  ?.  ?=([* ~] (flatten-bound bound.n))  |
  (sem-draws n e)
::
++  sem-draws
  ::  R4.2aa: does `s` name a drawing operator, directly or through the
  ::  definitions it reaches?
  |=  [s=sem:sm e=eenv]
  ^-  ?
  =/  rn  (reach-names s ops.e)
  ?|  (~(has in rn) 'RandomElement')
      ::  R4.2a: a print is an effect on the same carrier
      (~(has in rn) 'Print')
      (~(has in rn) 'PrintT')
      (~(has in rn) 'RandomSubset')
      (~(has in rn) 'RandomSetOfSubsets')
      (~(has in rn) 'TestRandomSetOfSubsets')
  ==
::
++  eval-image-rs
  ::  R4.2aa: `{e : x \in S}` (`fcn` |) or `[x \in S |-> e]` (`fcn` &) over
  ::  one binder, the body evaluated per element in enumeration order with
  ::  the run state threaded
  |=  [n=sem-apply:sm e=eenv fcn=? rs=rst]
  ^-  eout
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)  [[%| 0 'a set map expects one bounded variable.'] rs]
  =/  body  (snag 0 args.n)
  ::  the domain first, as tlc2 does; on the stream when it draws
  =/  sdr=[sd=(each sexp:v eval-err:v) rs=rst]
    ?.  (sem-draws rng.i.bs e)  [(eval-domain rng.i.bs e) rs]
    =^  dv  rs  (eval-rs rng.i.bs e rs)
    ?:  ?=(%| -.dv)  [dv rs]
    [[%& [%set p.dv]] rs]
  =/  sd  sd.sdr
  =.  rs  rs.sdr
  ?:  ?=(%| -.sd)  [sd rs]
  =/  els  (drain-sexp p.sd)
  ?:  ?=(%| -.els)  [els rs]
  =/  xs  p.els
  =|  out=(list vpair:v)
  |-  ^-  eout
  ?~  xs
    =/  ps  (flop out)
    :_  rs
    :-  %&
    ?:  fcn  (normalize:v [%fcn ps])
    (normalize:v [%set %set-enum (turn ps |=(p=vpair:v r.p))])
  =^  r  rs  (eval-rs body (bind-group e i.bs i.xs) rs)
  ?:  ?=(%| -.r)  [r rs]
  $(xs t.xs, out [[i.xs p.r] out])
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
++  recfcn-infinite
  ::  R4.2 (MCEcho): `f[a]` where `f` names a recursive function definition
  ::  over `Nat` or `Int` (`trcl[n \in Nat] == ...` in Relation.tla's
  ::  `TransitiveClosure`). tlc2 keeps it a lazy FcnLambdaValue and evaluates
  ::  only the applied point, so the infinite domain is never enumerated; the
  ::  port cannot enumerate it either. The definition, its one plain binder
  ::  and its domain, when it is such a function
  |=  [f=sem:sm e=eenv]
  ^-  (unit [n=sem-apply:sm g=bgroup sd=sexp:v])
  ?.  ?=(%apply -.f)  ~
  ?.  ?=(~ args.f)  ~
  ?.  ?=(%user-op kind.op.f)  ~
  ?:  (~(has by vals.e) name.op.f)  ~
  =/  d  (~(get by ops.e) name.op.f)
  ?~  d  ~
  ?.  ?=(~ params.u.d)  ~
  ?~  body.u.d  ~
  =/  b  u.body.u.d
  ?.  ?=(%apply -.b)  ~
  ?.  =('$RecursiveFcnSpec' name.op.b)  ~
  =/  bs  (flatten-bound bound.b)
  ?.  ?=([* ~] bs)  ~
  ?:  tup.i.bs  ~
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  ~
  ?.  ?=(?(%nats %ints) -.p.sd)  ~
  `[b i.bs p.sd]
::
++  apply-recfcn
  ::  the applied point of an infinite-domain recursive function: the fixpoint
  ::  of +eval-recfcn over the points between 0 and the argument, which is
  ::  every point a well-founded recursion toward 0 can reach. The same value
  ::  tlc2's lazy application computes, and each point is solved once (tlc2
  ::  re-evaluates the body per reference). An argument outside the domain,
  ::  or a point the restricted sweep cannot solve, is the definition's own
  ::  failure
  |=  [rf=[n=sem-apply:sm g=bgroup sd=sexp:v] xa=sem:sm e=eenv rs=rst]
  ^-  eout
  =^  x  rs  (eval-rs xa e rs)
  ?:  ?=(%| -.x)  [x rs]
  ?.  ?=(%int -.p.x)
    [[%| 0 'Attempted to enumerate the non-enumerable set Nat.'] rs]
  =/  [neg=? mag=@ud]  =/(o (old:si p.p.x) [!-.o +.o])
  ?:  &(neg ?=(%nats -.sd.rf))
    [[%| 0 'Attempted to enumerate the non-enumerable set Nat.'] rs]
  =/  pts=(list value:v)
    %+  turn  (gulf 0 mag)
    |=(i=@ud [%int ?:(neg (new:si | i) (sun:si i))])
  =/  r  (recfcn-fix n.rf g.rf pts e)
  ?:  ?=(%| -.r)  [r rs]
  [(apply:v p.r p.x &) rs]
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
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)
    [%| 0 'function constructor over multiple binders is unsupported.']
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  =/  fr  (force:v p.sd setmax.e)
  ?:  ?=(%| -.fr)  fr
  =/  el  (elemsof-e:v p.fr)
  ?:  ?=(%| -.el)  el
  (recfcn-fix n i.bs p.el e)
::
++  recfcn-fix
  ::  +eval-recfcn's sweep to a fixpoint over the domain points `pts`
  |=  [n=sem-apply:sm g=bgroup pts=(list value:v) e=eenv]
  ^-  eres
  ?~  ubound.n  [%| 0 'recursive function definition without a self-binder.']
  =/  fnm  name.i.ubound.n
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
      [g i.ps]
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
  ::  R4.2u: a config may assign a VALUE to a zero-arity DEFINITION
  ::  (`Faded = Faded`, `NULL = NULL`), and tlc2 then uses the value -- the
  ::  idiom that keeps `Faded == CHOOSE c : c \notin Color`, an unbounded
  ::  CHOOSE tlc2 refuses to evaluate, from ever being evaluated. The value
  ::  was bound (`+consts-of:check`) and never read
  ?:  &(?=(~ args.n) (~(has by vals.e) nm))  [[%& (~(got by vals.e) nm)] rs]
  =/  d   (~(get by ops.e) nm)
  ?~  d
    [[%| 0 (rap 3 ~['undefined operator: ' nm])] rs]
  =/  def  u.d
  ::  R4.2b: the key is the DEFINITION's own name -- a definition reached
  ::  through an operator parameter (`MapThenFoldSet(op(_,_), …)` given `+`)
  ::  is named `op` where it is referenced and `+` in its module
  =/  key=op-key:so  [origin.def (bnm name.def) (lent args.n)]
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
          !(body-allowed:so ov.e origin.def (bnm name.def))
      ==
    [[%| (unsupported:so key)] rs]
  ::  R4.P3: a constant definition already evaluated once (`+with-cdefs`)
  =/  cd  ?~(args.n (~(get by cdefs.e) nm) ~)
  ?:  &(?=(^ cd) =(def.u.cd def))  [[%& val.u.cd] rs]
  ?:  =(0 fuel.e)  [[%| 0 'evaluation recursion/resource limit exceeded.'] rs]
  ?~  body.def  [[%| 0 (rap 3 ~['operator has no evaluable body: ' nm])] rs]
  ?.  =((lent params.def) (lent args.n))
    [[%| 0 (rap 3 ~['wrong number of arguments to ' nm])] rs]
  ::  R4.P11: a module-level, STATE-level arity-0 definition is memoized
  ::  (`+eval-sdef`), so the references made while one state is expanded
  ::  share one evaluation. GameOfLife's `sc[<<x, y>> \in ...] == ...` was
  ::  re-materialized at every one of its 18 references per state
  ::  R4.3: a CONSTANT-level one too -- `+with-cdefs` leaves a tlc2-lazy set
  ::  uncached (`+lazy-set`). `+sdef-env` cuts the states to the variables
  ::  it reaches, so one that reads none is evaluated once, not per state.
  ::  The graph's level is NOT trusted for that: under INSTANCE a "constant"
  ::  definition reads the state through a substitution (TLCSailfish2's
  ::  BlockDag over `vs`), and cleared states read "unassigned: vs"
  ?:  ?&(?=(~ args.n) (lte lvl.def 1) !=('' origin.def))
    (eval-sdef u.body.def (sdef-env u.body.def e(fuel (dec fuel.e)) ~) rs)
  =/  e2  (bind-params e params.def args.n)
  ?:  ?=(%| -.e2)  [e2 rs]
  =/  ew  p.e2(fuel (dec fuel.e))
  ::  R4.2c: an INSTANCE member's body is its `WITH` wrapper; its own
  ::  parameters must win over a substitution of the same name
  ::  (`+keep-params`)
  =/  sp  (substin-parts:sm u.body.def)
  ?~  sp  (eval-app def u.body.def ew rs)
  =/  e3  (bind-substs ew names.u.sp exprs.u.sp)
  ?:  ?=(%| -.e3)  [e3 rs]
  (eval-app def inner.u.sp (keep-params p.e3 ew params.def) rs)
::
++  eval-app
  ::  R4.3: an application of a module-level constant- or state-level
  ::  operator is memoized as R4.P11 memoizes its arity-0 definitions: the
  ::  key is the body and the environment cut to what it can read, its
  ::  bound parameters included (MCEWD687a's `IsTreeWithRoot` applies
  ::  `SimplePath(G)`, hence `SeqOf`, once per node with the same `G`).
  ::  The states are cut by `+sdef-env` to the variables the reach names
  ::  (not by the graph's level, which INSTANCE substitutions defeat)
  |=  [def=sem-def:sm b=sem:sm ew=eenv rs=rst]
  ^-  eout
  ?.  ?&((lte lvl.def 1) !=('' origin.def))  (eval-rs b ew rs)
  (eval-sdef b (sdef-env b ew (turn params.def |=(p=spar:sm name.p))) rs)
::
++  keep-params
  ::  R4.2c (TestGraphs): re-assert an operator's own parameters over the
  ::  INSTANCE substitutions its body's wrapper bound. tlc2 resolves a name by
  ::  its NODE, so `SuccessorsOf(state, SG)` -- declared in TLCMC BEFORE the
  ::  `VARIABLE state` the instance substitutes by name -- reads its PARAMETER;
  ::  the port binds both by name, and the wrapper, bound after the
  ::  parameters, captured `state` as the current state's variable. `ew` is the
  ::  env with only the parameters bound
  |=  [e=eenv ew=eenv ps=(list spar:sm)]
  ^-  eenv
  ?~  ps  e
  =/  nm  name.i.ps
  =/  v  (~(get by vals.ew) nm)
  =/  b  (~(get by psub.ew) nm)
  =/  o  (~(get by ops.ew) nm)
  =?  e  ?=(^ v)  e(vals (~(put by vals.e) nm u.v), psub (~(del by psub.e) nm))
  =?  e  ?=(^ b)  e(psub (~(put by psub.e) nm u.b), vals (~(del by vals.e) nm))
  =?  e  &((gth arity.i.ps 0) ?=(^ o))  e(ops (~(put by ops.e) nm u.o))
  $(ps t.ps)
::
++  eval-sdef
  ::  R4.P11: `+eval-rs` memoized with `~+`. The key is the whole sample --
  ::  body, environment and carrier -- so a hit is exact: the evaluation is
  ::  a pure function of them, whatever the body does (a draw or a `TLCSet`
  ::  is part of the memoized carrier). What makes references HIT is
  ::  `+sdef-env`, which cuts the environment to what the body can read
  |=  [b=sem:sm e=eenv rs=rst]
  ^-  eout
  ~+
  (eval-rs b e rs)
::
++  sdef-env
  ::  the environment a module-level arity-0 definition can observe: the
  ::  `vals`/`psub` bindings named anywhere in its body or in the bodies it
  ::  reaches (`+reach-names`; constants, and any INSTANCE substitution
  ::  read through a reached member), never the call site's other locals;
  ::  the successor state only where it can be read (primed or ENABLED)
  ::  R4.3: only the names FREE in that reach (`+free-reach`), so a
  ::  caller's local that the body rebinds cannot matter, plus `keep`, the
  ::  applied operator's own formals. `SeqOf(set, n)`'s `n` had put
  ::  AreConnectedIn's `n` in every key. (A cut by every name bound ANYWHERE
  ::  in the reach dropped EWD998Chan's constant `N`, read freely elsewhere)
  |=  [b=sem:sm e=eenv keep=(list @t)]
  ^-  eenv
  =/  ns  (~(gas in (free-reach b ops.e)) keep)
  =.  vals.e
    %-  malt
    ^-  (list [@t value:v])
    (skim ~(tap by vals.e) |=([k=@t *] (~(has in ns) k)))
  =.  psub.e
    %-  malt
    ^-  (list [@t sem:sm])
    (skim ~(tap by psub.e) |=([k=@t *] (~(has in ns) k)))
  =.  pout.e
    %-  malt
    ^-  (list [@t clo])
    (skim ~(tap by pout.e) |=([k=@t *] (~(has in ns) k)))
  ::  R4.3: and the states cut to the variables the reach names, unless a
  ::  call-by-name binding is kept (its expression may read others).
  ::  MCInnerSerial's `totalOpOrder` reads only `opQ`, but keyed on the whole
  ::  successor it missed for each of up to 65,536 `opOrder'` candidates
  =?  e  ?=(~ psub.e)
    =/  rv=(set @)  (reach-names b ops.e)
    =/  cut
      |=  st=state
      ^-  state
      %-  malt
      ^-  (list [@t value:v])
      (skim ~(tap by st) |=([k=@t *] (~(has in rv) k)))
    e(s0 (cut s0.e), s1 (cut s1.e))
  ?:  |(primed.e enabled.e)  e
  e(s1 ~)
::
++  free-reach
  ::  R4.3: the names a body can look up in its caller's environment: those
  ::  FREE in it, scope by scope -- a quantifier's or constructor's variables
  ::  are bound in its body (not in its ranges), a LET's names in its
  ::  definitions and body, an operator's formals in its own body -- and,
  ::  through every operator it reaches by name, those free in that
  ::  operator's body. `~+`: once per body and operator table
  |=  [b=sem:sm ops=(map @t sem-def:sm)]
  ^-  (set @t)
  ~+
  =|  out=(set @t)
  =|  seen=(set @t)
  =/  stk=(list [x=sem:sm bd=(set @t)])  ~[[b ~]]
  |-  ^-  (set @t)
  ?~  stk  out
  =/  x  x.i.stk
  =/  bd  bd.i.stk
  ?-    -.x
      ?(%lit %atref %nullodn)  $(stk t.stk)
  ::
      %letin
    =/  ln=(set @t)  (~(gas in bd) (turn lets.x |=(d=sem-def:sm name.d)))
    =/  ks  t.stk
    =?  ks  ?=(^ body.x)  [[u.body.x ln] ks]
    =/  ls=(list sem-def:sm)  lets.x
    |-  ^-  (set @t)
    ?~  ls  ^$(stk ks)
    =/  pb=(set @t)  (~(gas in ln) (turn params.i.ls |=(p=spar:sm name.p)))
    $(ls t.ls, ks ?~(body.i.ls ks [[u.body.i.ls pb] ks]))
  ::
      %apply
    =/  nm  name.op.x
    =?  out  !(~(has in bd) nm)  (~(put in out) nm)
    ::  binder groups: each range sees the variables of the groups before
    ::  it; the body sees them all
    =/  gs=(list sem-bound:sm)  bound.x
    =/  inner=(set @t)  (~(gas in bd) (turn ubound.x |=(v=sbind:sm name.v)))
    =/  ks  t.stk
    =^  ks  inner
      |-  ^-  [(list [x=sem:sm bd=(set @t)]) (set @t)]
      ?~  gs  [ks inner]
      =?  ks  ?=(^ range.i.gs)  [[u.range.i.gs inner] ks]
      %=  $
        gs     t.gs
        inner  (~(gas in inner) (turn vars.i.gs |=(v=sbind:sm name.v)))
      ==
    ::  an INSTANCE wrapper: its substitution expressions are in the OUTER
    ::  scope; only the wrapped body (its last argument) sees the names
    =.  ks
      ?.  ?=(^ (anysubstin-mod:sm nm))
        (weld (turn args.x |=(a=sem:sm [a inner])) ks)
      =/  rv=(list sem:sm)  (flop args.x)
      ?~  rv  ks
      :-  [i.rv inner]
      (weld (turn (flop t.rv) |=(a=sem:sm [a bd])) ks)
    ::  an operator reached by name: its own body, under its own formals
    ?:  (~(has in bd) nm)  $(stk ks)
    ?:  (~(has in seen) nm)  $(stk ks)
    =/  d  (~(get by ops) nm)
    ?~  d  $(stk ks)
    =.  seen  (~(put in seen) nm)
    ?~  body.u.d  $(stk ks)
    =/  pb=(set @t)  (silt (turn params.u.d |=(p=spar:sm name.p)))
    $(stk [[u.body.u.d pb] ks])
  ==
::
++  reach-names
  ::  every atom in `b` and in the body of every operator it reaches by
  ::  name, transitively -- a superset of the names its evaluation can look
  ::  up. `~+`: once per body and operator table
  |=  [b=sem:sm ops=(map @t sem-def:sm)]
  ^-  (set @)
  ~+
  =|  out=(set @)
  =|  seen=(set @t)
  =/  stk=(list *)  ~[b]
  |-  ^-  (set @)
  ?~  stk  out
  =/  x  i.stk
  ?^  x  $(stk [-.x +.x t.stk])
  =.  out  (~(put in out) x)
  ?:  (~(has in seen) x)  $(stk t.stk)
  =/  d  (~(get by ops) x)
  ?~  d  $(stk t.stk)
  ?~  body.u.d  $(stk t.stk, seen (~(put in seen) x))
  $(stk [u.body.u.d t.stk], seen (~(put in seen) x))
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
  ::  R4.2b: CommunityModules overrides with an operator argument
  ?:  ?=(?(%fold-left %fold-left-dom %fold-right %fold-right-dom %fold-function %fold-seq %fold-function-on-set %fold-set %fold-bag %quantify %remove-first-match %select-in-seq %select-last-in-seq %select-in-subseq %select-last-in-subseq %causal-order) tag)
    [(eval-cm-op tag n e) rs]
  ?:  ?=(%tlc-eval tag)       (eval-tlc-eval n e rs)
  ::  R2.7.4.3: the REGISTER STORE. These four are the reason the carrier
  ::  exists -- `%tlc-get` READS `regs.rs`, `%tlc-set` WRITES it, and the two
  ::  TLCExt surfaces do both
  ?:  ?=(%tlc-get tag)        (eval-tlc-get n e rs)
  ?:  ?=(%tlc-set tag)        (eval-tlc-set n e rs)
  ?:  ?=(%tlc-get-or-default tag)  (eval-tlc-get-or-default n e rs)
  ?:  ?=(%tlc-get-and-set tag)     (eval-tlc-get-and-set n e rs)
  ?:  ?=(%tlc-eval-def tag)        (eval-tlc-eval-def n e rs)
  ::  R2.7.4.4: the DRAW. It spends `es.rs`, so it carries for the same reason
  ?:  ?=(%random-element tag)      (eval-random-element n e rs)
  ::  R4.2a: the console WRITE, a line on the carrier
  ?:  ?=(%print tag)               (eval-print n e | rs)
  ?:  ?=(%print-t tag)             (eval-print n e & rs)
  ::  R4.2c: the run's environment, a record (`$env`, the request's `env`)
  ?:  ?=(%io-env tag)
    [[%& (~(gut by vals.e) '$env' [%rec ~])] rs]
  ::  R4.2f: a file WRITE, on the carrier
  ?:  ?=(%json-serialize tag)      (eval-json-write n e | rs)
  ?:  ?=(%nd-json-serialize tag)   (eval-json-write n e & rs)
  ::  R2.7.4.5: the `Randomization` module -- all three DRAW
  ?:  ?=(%random-subset tag)         (eval-random-subset n e rs)
  ?:  ?=(%random-set-of-subsets tag)  (eval-random-set-of-subsets n e rs)
  ?:  ?=(%test-rsos tag)             (eval-test-rsos n e rs)
  ?:  ?=(%assert-error tag)   (eval-assert-error n e rs)
  ?:  ?=(%tlc-cache tag)      (eval-tlc-cache n e rs)
  ?:  ?=(%tlc-defer tag)      [(eval-tlc-defer n e) rs]
  ::  R2.7.14b: reads the counter-example out of the env, the port's analogue
  ::  of tlc2's `c.lookup(tool.getCounterExampleDef())`, and falls back to the
  ::  EMPTY record exactly as `TLCExt.error` returns `new CounterExample()`
  ?:  ?=(%counter-example tag)  [[%& ?~(ce.e empty-counter-example u.ce.e)] rs]
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
++  eval-tlc-eval-def
  ::  TLCExt!TLCEvalDefinition(name) — resolve `name` in the ROOT module's
  ::  definitions and evaluate it (R2.7.10). tlc2 takes the root `ModuleNode`
  ::  and `getOpDef(name)`; the port's `ops.e` IS that table, so the lookup is
  ::  the same one every user-operator application already makes.
  ::
  ::  A non-string argument, and a name that resolves to nothing, are both the
  ::  pin's one-argument error -- `TLC_MODULE_ONE_ARGUMENT_ERROR` naming
  ::  `TLCEvalDefinition`
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* ~] args.n)
    [[%| 0 'TLCEvalDefinition expects one argument.'] rs]
  =^  k  rs  (eval-rs i.args.n e rs)
  ?:  ?=(%| -.k)  [k rs]
  ?.  ?=(%str -.p.k)
    [[%| (one-arg-error:so 'TLCEvalDefinition' 'string' p.k)] rs]
  =/  d  (~(get by ops.e) p.p.k)
  ?~  d
    [[%| (one-arg-error:so 'TLCEvalDefinition' 'string' p.k)] rs]
  ?~  body.u.d
    [[%| (one-arg-error:so 'TLCEvalDefinition' 'string' p.k)] rs]
  (eval-rs u.body.u.d e rs)
::
++  eval-tlc-get
  ::  TLC!TLCGet — also an `@Evaluation` override in the pin, so it receives
  ::  the node and evaluates the key itself. The answer is tlc2's EC 2145 for
  ::  a key TLC does not define, and a typed rejection naming a key it does
  ::  (this evaluator cannot reach engine state)
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* ~] args.n)  [[%| 0 'TLCGet expects one argument.'] rs]
  =^  k  rs  (eval-rs i.args.n e rs)
  ?:  ?=(%| -.k)  [k rs]
  ::  R4.2g: `TLCGet("-D<key>")` is the Java system property `<key>`, and the
  ::  key string itself when it is unset (`System.getProperty(k, "-D" + k)`,
  ::  TLCGetSet.java:485). The properties are the request's (`$props`)
  ?:  ?&  ?=(%str -.p.k)
          =('-D' (end [3 2] p.p.k))
      ==
    =/  pv  (run-prop e (rsh [3 2] p.p.k))
    [[%& [%str ?~(pv p.p.k u.pv)]] rs]
  ::  R4.2w: `TLCGet("config")`, the run's configuration record (`$config`,
  ::  bound by the job kernel; the console path has none and keeps the
  ::  refusal by name)
  ?:  &(?=(%str -.p.k) =('config' p.p.k) (~(has by vals.e) '$config'))
    [[%& (~(got by vals.e) '$config')] rs]
  [(tlc-get:so ~[p.k] run.e regs.rs named.rs) rs]
::
++  run-prop
  ::  R4.2g: a Java system property of this run (the request's `props`, bound
  ::  as the record `$props` by the job kernel; none on the console path)
  |=  [e=eenv k=@t]
  ^-  (unit @t)
  =/  r  (~(get by vals.e) '$props')
  ?~  r  ~
  ?.  ?=(%rec -.u.r)  ~
  =/  hit  (skim p.u.r |=(f=vfield:v =(k k.f)))
  ?~  hit  ~
  ?.  ?=(%str -.v.i.hit)  ~
  `p.v.i.hit
::
++  eval-json-write
  ::  R4.2f: `JsonSerialize(path, v)` writes `ToJson(v)` (a sequence or a
  ::  record) and `ndJsonSerialize(path, s)` one `ToJson` line per element of
  ::  the sequence `s`; both are TRUE (Json.java). The file is the carrier's
  ::  `files` entry for `path`
  |=  [n=sem-apply:sm e=eenv nd=? rs=rst]
  ^-  eout
  =/  op=@t  ?:(nd 'ndJsonSerialize' 'JsonSerialize')
  ?.  ?=([* * ~] args.n)  [[%| 0 (cat 3 op ' expects two arguments.')] rs]
  =^  a  rs  (eval-rs i.args.n e rs)
  ?:  ?=(%| -.a)  [a rs]
  =^  b  rs  (eval-rs i.t.args.n e rs)
  ?:  ?=(%| -.b)  [b rs]
  ?.  ?=(%str -.p.a)  [[%| (arg-error:so 2.169 1 op 'string' | p.a)] rs]
  =/  tup  (to-tuple:v p.b)
  =/  txt=(each tape @t)
    ?:  nd
      ?~  tup  [%| '']
      =/  ls  (json-list:so u.tup)
      ?:  ?=(%| -.ls)  ls
      [%& (zing (turn p.ls |=(t=tape (snoc t '\0a'))))]
    ?.  |(?=(^ tup) ?=(%rec -.p.b))  [%| '']
    (json-node:so p.b)
  ?:  ?=(%| -.txt)
    ?.  =('' p.txt)  [[%| 0 p.txt] rs]
    =/  what=@t  ?:(nd 'sequence' 'sequence or record')
    [[%| (arg-error:so 2.169 2 op what | p.b)] rs]
  :-  [%& [%bool &]]
  rs(files (~(put by files.rs) p.p.a (crip p.txt)))
::
++  eval-print
  ::  R4.2a: `TLC!Print(v1, v2)` writes `ppr(v1) + "  " + ppr(v2)` and is v2;
  ::  `TLC!PrintT(v)` writes `ppr(v)` and is TRUE (TLC.java:63-101). Both
  ::  arguments are evaluated first, in order, on the carrier; an evaluation
  ::  failure writes nothing. `ppr`'s line wrapping of a long value is not
  ::  reproduced: the line is the one-line rendering
  |=  [n=sem-apply:sm e=eenv one=? rs=rst]
  ^-  eout
  ?:  one
    ?.  ?=([* ~] args.n)  [[%| 0 'PrintT expects one argument.'] rs]
    =^  a  rs  (eval-rs i.args.n e rs)
    ?:  ?=(%| -.a)  [a rs]
    [[%& [%bool &]] rs(out [(crip (render:v p.a)) out.rs])]
  ?.  ?=([* * ~] args.n)  [[%| 0 'Print expects two arguments.'] rs]
  =^  a  rs  (eval-rs i.args.n e rs)
  ?:  ?=(%| -.a)  [a rs]
  =^  b  rs  (eval-rs i.t.args.n e rs)
  ?:  ?=(%| -.b)  [b rs]
  :-  [%& p.b]
  rs(out [(crip :(weld (render:v p.a) "  " (render:v p.b))) out.rs])
::
++  eval-random-element
  ::  TLC!RandomElement(S) — one uniform draw from a FINITE set, ADVANCING
  ::  the enumeration generator on the carrier (R2.7.4.4).
  ::
  ::  The pin is `SetEnumValue.randomElement` / `IntervalValue.randomElement`:
  ::  `elems.elementAt((int) Math.floor(get().nextDouble() * size()))` over the
  ::  NORMALIZED element list. So the draw is exactly one `nextDouble`, scaled
  ::  and floored — `+floor-scaled:rg`, the same arm the `-generate` path
  ::  already spends — and which element it names depends on the port's element
  ::  ORDER matching tlc2's normalized order (`tlc-value-order`, parity).
  ::
  ::  The argument goes through `+eval-domain` and is then FORCED, the way
  ::  `+eval-cardinality` does it, so an infinite descriptor (`Nat`, `Int`,
  ::  `Seq(S)`) reports the pin's "a finite set" rather than being enumerated:
  ::  there `toSetEnum` returns null and `RandomElement` throws
  ::  TLC_MODULE_APPLYING_TO_WRONG_VALUE
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* ~] args.n)  [[%| 0 'RandomElement expects one argument.'] rs]
  =/  sd  (eval-domain i.args.n e)
  ?:  ?=(%| -.sd)  [sd rs]
  ::  an INFINITE descriptor must report "a finite set" rather than the
  ::  forcing failure: measured at the pin, `RandomElement(Nat)` is
  ::  `Applying RandomElement to the following value,\0awhich is not a finite
  ::  set:\0aNat` -- `toSetEnum()` returns null there and the operator throws
  ::  its own TLC_MODULE_APPLYING_TO_WRONG_VALUE, never an enumeration error
  =/  fr  (force:v p.sd setmax.e)
  ?:  ?=(%| -.fr)  [(random-element-wrong i.args.n e) rs]
  =/  el  (elemsof-e:v p.fr)
  ?:  ?=(%| -.el)  [[%| (random-element-error:so p.fr)] rs]
  ?~  p.el  [[%| (random-element-error:so p.fr)] rs]
  =/  els=(list value:v)  p.el
  =^  ix  es.rs  (floor-scaled:rg es.rs (lent els))
  [[%& (snag ix els)] rs]
::
++  finite-set-arg
  ::  a `Randomization` set argument: evaluated as a lazy DOMAIN (so an
  ::  infinite descriptor is NAMED rather than enumerated, the treatment
  ::  `Cardinality` and `RandomElement` already get) and then forced to its
  ::  normalized element list. The pin's guard is
  ::  `!(v instanceof EnumerableValue) || !isFinite()`, so a non-set and an
  ::  infinite set take the SAME branch and get the same message -- which is
  ::  why one arm answers both. A `%|` carries either a genuine evaluation
  ::  failure to propagate or the offending value ALREADY RENDERED
  |=  [n=sem:sm e=eenv]
  ^-  (each (list value:v) (each @t eval-err:v))
  =/  sd  (eval-domain n e)
  ?:  ?=(%| -.sd)  [%| (arg-rendered n e)]
  ?:  (infinite:v p.sd)  [%| %& (crip (sexp-name:v p.sd))]
  =/  fr  (force:v p.sd setmax.e)
  ?:  ?=(%| -.fr)  [%| (arg-rendered n e)]
  ?.  (set-like:v p.fr)  [%| %& (crip (render:v p.fr))]
  [%& (set-elems:v (normalize:v p.fr))]
::
++  arg-rendered
  ::  the argument as tlc2's `Values.ppr` renders it, for the "but instead it
  ::  is:" tail -- or the evaluation failure, if it has one to report
  |=  [n=sem:sm e=eenv]
  ^-  (each @t eval-err:v)
  =/  vv  (eval n e)
  ?:  ?=(%| -.vv)  [%| p.vv]
  [%& (crip (render:v p.vv))]
::
++  int-arg
  ::  a `Randomization` count argument. The pin checks `instanceof IntValue`
  ::  and then `< 0`, and BOTH report the same "nonnegative integer" message
  ::  -- though a negative literal never reaches it, because `-1` fails SANY
  ::  before TLC runs (measured: "Parsing or semantic analysis failed")
  |=  [n=sem:sm e=eenv rs=rst]
  ^-  [(each @ud (each @t eval-err:v)) rst]
  =^  r  rs  (eval-rs n e rs)
  ?:  ?=(%| -.r)  [[%| %| p.r] rs]
  ?.  ?=(%int -.p.r)  [[%| %& (crip (render:v p.r))] rs]
  ?:  (slth:v p.p.r --0)  [[%| %& (crip (render:v p.r))] rs]
  [[%& (abs:si p.p.r)] rs]
::
++  bad-arg
  ::  turn a `+int-arg` / `+finite-set-arg` rejection into the answer: a
  ::  propagated evaluation failure, or the pin's EC 2169 naming the value
  |=  [r=(each @t eval-err:v) i=@ud op=@t what=@t]
  ^-  eres
  ?:  ?=(%| -.r)  [%| p.r]
  [%| (rsub-arg-error:so i op what p.r)]
::
++  eval-random-subset
  ::  Randomization!RandomSubset(k, S) -- `EnumerableValue.getRandomSubset(k)`,
  ::  which is `elements(k)` collected into a `SetEnumValue`. The enumeration
  ::  is tlc2's `SubsetEnumerator`: an LCG over the NORMALIZED element list,
  ::  seeded with `nextInt(n)` and incremented by a `nextPrime` draw, both from
  ::  the carrier's enumeration generator. `+subset-indices:rg` is that walk and
  ::  has been in `lib/rng` since unit 9; R2.7.4.5 is its first LIVE caller.
  ::
  ::  The result is a SET, so `k > |S|` is not an error -- over the accepted
  ::  indices the LCG's period is |S|, so it simply yields every element
  ::  (measured: `RandomSubset(7, 1..5)` is `{1, 2, 3, 4, 5}`) -- and `k = 0`
  ::  is the empty set
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * ~] args.n)  [[%| 0 'RandomSubset expects two arguments.'] rs]
  =^  kr  rs  (int-arg i.args.n e rs)
  ?:  ?=(%| -.kr)
    [(bad-arg p.kr 1 'RandomSubset' 'nonnegative integer') rs]
  =/  sr  (finite-set-arg i.t.args.n e)
  ?:  ?=(%| -.sr)
    ::  the pin passes "a finite set" into a template that already supplies
    ::  the article, so it prints "should be a a finite set". Measured
    [(bad-arg p.sr 2 'RandomSubset' 'a finite set') rs]
  =/  els=(list value:v)  p.sr
  =^  ixs  es.rs  (subset-indices:rg es.rs p.kr (lent els))
  [[%& [%set %set-enum (norm-set:v (turn ixs |=(i=@ud (snag i els))))]] rs]
::
++  eval-random-set-of-subsets
  ::  Randomization!RandomSetOfSubsets(k, n, S) --
  ::  `new SubsetValue(S).getRandomSetOfSubsets(k, n / |S|)`, which is the
  ::  `CoinTossingSubsetEnumerator`: k picks, and each pick walks the whole
  ::  normalized element list tossing `nextDouble() < probability` per element.
  ::  The picks land in a SET, so duplicates collapse and the answer usually
  ::  has FEWER than k elements (measured at the pin:
  ::  `RandomSetOfSubsets(4, 2, 1..4)` at `-seed 12345` is
  ::  `{{1, 4}, {2, 3}, {1, 2, 3}}` -- four picks, three distinct).
  ::
  ::  NB this is the `(int, double)` overload of `getRandomSetOfSubsets`. The
  ::  `(int, int)` one -- the only path in tlc2 that touches
  ::  `util.Combinatorics` -- has no caller at all; see the R2.7.4.5 notes
  |=  [nd=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * * ~] args.nd)
    [[%| 0 'RandomSetOfSubsets expects three arguments.'] rs]
  =^  kr  rs  (int-arg i.args.nd e rs)
  ?:  ?=(%| -.kr)
    [(bad-arg p.kr 1 'RandomSetOfSubsets' 'nonnegative integer') rs]
  =^  nr  rs  (int-arg i.t.args.nd e rs)
  ?:  ?=(%| -.nr)
    [(bad-arg p.nr 2 'RandomSetOfSubsets' 'nonnegative integer') rs]
  =/  sr  (finite-set-arg i.t.t.args.nd e)
  ?:  ?=(%| -.sr)
    [(bad-arg p.sr 3 'RandomSetOfSubsets' 'finite set') rs]
  =/  els=(list value:v)  p.sr
  =/  size  (lent els)
  ::  the pin's own order: the `numberOfPicks` bound is checked BEFORE `n` is
  ::  compared to the cardinality, so `RandomSetOfSubsets(100, 9, 1..4)`
  ::  reports the FIRST argument, not the second. `31 - numberOfLeadingZeros(k)
  ::  + 1` is the bit length of k, which is `+xeb`
  ?:  ?&((gth (xeb p.kr) size) (gth p.kr (bex size)))
    [[%| (rsos-too-many-error:so p.kr size)] rs]
  ?:  (gth p.nr size)
    :_  rs
    :-  %|
    %^  rsub-arg-error:so  2  'RandomSetOfSubsets'
    ['nonnegative integer in range 0..Cardinality(S)' (crip (render-int:v (sun:si p.nr)))]
  =^  picks  rs  (coin-toss-picks els p.kr p.nr size rs)
  [[%& [%set %set-enum (norm-set:v picks)]] rs]
::
++  coin-toss-picks
  ::  `CoinTossingSubsetEnumerator`: `k` picks, each one a full pass over the
  ::  element list spending exactly one `nextDouble` PER ELEMENT -- including
  ::  the elements it does NOT take, which is what makes the stream position
  ::  after a pick independent of the pick's contents
  |=  [els=(list value:v) k=@ud n=@ud size=@ud rs=rst]
  ^-  [(list value:v) rst]
  ?:  =(0 size)  [~ rs]
  =/  prob  (div:rd (sun:rd n) (sun:rd size))
  =|  out=(list value:v)
  =/  i  0
  |-  ^-  [(list value:v) rst]
  ?:  =(i k)  [(flop out) rs]
  =^  pick  rs
    =/  rest  els
    =|  acc=(list value:v)
    |-  ^-  [value:v rst]
    ?~  rest  [[%set %set-enum (norm-set:v (flop acc))] rs]
    =^  d  es.rs  (next-double:rg es.rs)
    ?:  (lth:rd d prob)  $(rest t.rest, acc [i.rest acc])
    $(rest t.rest)
  $(i +(i), out [pick out])
::
++  eval-test-rsos
  ::  Randomization!TestRandomSetOfSubsets(k, n, S) --
  ::  `[i \in 1..5 |-> Cardinality(RandomSetOfSubsets(k, n, S))]`.
  ::
  ::  The pin has NO Java override for this one, so tlc2 runs that body. This
  ::  port cannot: the five draws sit inside a FUNCTION CONSTRUCTOR and under
  ::  `Cardinality`, and both are below the R2.7.4.1b carrier boundary -- the
  ::  constructor's binder does not thread `rst`, and `+eval-cardinality` takes
  ::  its argument as a lazy domain and discards it. Running the body would
  ::  make ONE draw sequence and report its cardinality five times. So the arm
  ::  is NATIVE, exactly as `TLCGetAndSet` is in R2.7.4.3 and for the same
  ::  reason: a silently dropped draw is the one outcome R2's acceptance
  ::  forbids. Measured at the pin, `TestRandomSetOfSubsets(4, 2, 1..4)` at
  ::  `-seed 12345` is `<<3, 3, 4, 3, 3>>` -- five DIFFERENT draw sequences
  |=  [nd=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * * ~] args.nd)
    [[%| 0 'TestRandomSetOfSubsets expects three arguments.'] rs]
  =|  out=(list value:v)
  =/  i  0
  |-  ^-  eout
  ?:  =(i 5)  [[%& [%seq (flop out)]] rs]
  =^  r  rs  (eval-random-set-of-subsets nd e rs)
  ?:  ?=(%| -.r)  [r rs]
  =/  c  (sun:si (lent (set-elems:v p.r)))
  $(i +(i), out [[%int c] out])
::
++  random-element-wrong
  ::  the argument is not a FINITE set: name its VALUE the way tlc2 does, not
  ::  the enumeration failure -- the same shape `+cardinality-error` uses for
  ::  the same reason
  |=  [n=sem:sm e=eenv]
  ^-  eres
  =/  vv  (eval n e)
  ?:  ?=(%| -.vv)  vv
  [%| (random-element-error:so p.vv)]
::
++  eval-tlc-set
  ::  TLC!TLCSet(i, v) — the register WRITE (R2.7.4.3). Both arguments are
  ::  evaluated left to right, and each one's own effect on the store is
  ::  visible to the next, which is what makes `TLCSet(0, TLCGet(0) + 1)`
  ::  accumulate
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * ~] args.n)  [[%| 0 'TLCSet expects two arguments.'] rs]
  =^  as  rs  (eval-args-rs args.n e rs)
  ?:  ?=(%| -.as)  [as rs]
  =/  sr  (tlc-set:so p.as regs.rs named.rs)
  =.  regs.rs   regs.sr
  =.  named.rs  named.sr
  [r.sr rs]
::
++  eval-tlc-get-or-default
  ::  TLCExt!TLCGetOrDefault(i, d) — the register READ that answers `d` on an
  ::  unset index rather than raising EC 2145
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * ~] args.n)
    [[%| 0 'TLCGetOrDefault expects two arguments.'] rs]
  =^  as  rs  (eval-args-rs args.n e rs)
  ?:  ?=(%| -.as)  [as rs]
  [(tlc-get-or-default:so p.as regs.rs named.rs) rs]
::
++  eval-tlc-get-and-set
  ::  TLCExt!TLCGetAndSet(key, Op(_,_), val, defaultVal) — read-modify-write,
  ::  returning the OLD value.
  ::
  ::  The pin has no Java method for this: TLCExt.tla defines it as
  ::  `LET oldVal == TLCGetOrDefault(key, defaultVal)
  ::   IN CHOOSE v \in {oldVal} : TLCSet(key, Op(oldVal, val))`.
  ::  The port implements it natively rather than evaluating that body,
  ::  because the body hides its write inside a CHOOSE and CHOOSE is BELOW the
  ::  R2.7.4.1b carrier boundary -- `+choose-over:v` takes a gate that cannot
  ::  hand `rst` back, so evaluating the body would drop the write silently.
  ::  Measured at the pin: with `Op == +` and `val = 10` from default 0, the
  ::  successive answers are 0, 10, 20 while the register becomes 10, 20, 30
  |=  [n=sem-apply:sm e=eenv rs=rst]
  ^-  eout
  ?.  ?=([* * * * ~] args.n)
    [[%| 0 'TLCGetAndSet expects four arguments.'] rs]
  =/  keyn  i.args.n
  =/  opn   i.t.args.n
  =/  valn  i.t.t.args.n
  =/  defn  i.t.t.t.args.n
  ::  argument order follows the TLA+ body: the key, then the default (both
  ::  needed for the READ), then the operand
  =^  kv  rs  (eval-rs keyn e rs)
  ?:  ?=(%| -.kv)  [kv rs]
  =^  dv  rs  (eval-rs defn e rs)
  ?:  ?=(%| -.dv)  [dv rs]
  =/  old  (tlc-get-or-default:so ~[p.kv p.dv] regs.rs named.rs)
  ?:  ?=(%| -.old)  [old rs]
  =^  vv  rs  (eval-rs valn e rs)
  ?:  ?=(%| -.vv)  [vv rs]
  =/  od  (resolve-oparg opn e)
  ?~  od  [[%| (op-arg-error 'TLCGetAndSet' 'operator' opn)] rs]
  =^  nv  rs  (apply-def-rs u.od ~[p.old p.vv] e rs)
  ?:  ?=(%| -.nv)  [nv rs]
  ::  R2.7.7.4a: `TLCGetAndSet` inherits the named half for free -- its key
  ::  is whatever `TLCGet`/`TLCSet` accept, so a named one now works here too
  =/  sw  (tlc-set:so ~[p.kv p.nv] regs.rs named.rs)
  ?:  ?=(%| -.r.sw)  [r.sw rs]
  =.  regs.rs   regs.sw
  =.  named.rs  named.sw
  [[%& p.old] rs]
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
    ::  R3.0b: tlc2 reports the VALUE the comparator returned, not the operator
    ::  -- `SortSeq(<<1, 2>>, LAMBDA x, y : x)` names `2`. The `<Operator>`
    ::  placeholder was right only while a LAMBDA could not be applied at all
    [%| (arg-error:so 2.169 2 'SortSeq' 'boolean function' | p.r)]
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
++  apply-op
  ::  apply an operator ARGUMENT: a Java-overridden one (`+` from Naturals,
  ::  passed bare) through its override, any other through its body
  |=  [d=sem-def:sm vs=(list value:v) e=eenv]
  ^-  eres
  =/  ov  (lookup:so ov.e [origin.d (bnm name.d) (lent vs)])
  ?^  ov  (gate.u.ov vs)
  (apply-def d vs e)
::
++  cm-op
  ::  R4.2b: the operator argument at position `i` of a CommunityModules
  ::  override (tlc2 hands it an OpValue)
  |=  [op=@t i=@ud n=sem-apply:sm e=eenv]
  ^-  (each sem-def:sm eval-err:v)
  =/  a  (snag i args.n)
  =/  od  (resolve-oparg a e)
  ?~  od  [%| (op-arg-error op 'operator' a)]
  [%& u.od]
::
++  eval-cm-op
  ::  R4.2b: CommunityModules' Java overrides that take an OPERATOR argument,
  ::  ported from the pinned deps jar (tools/gen-cm-tests.py measures each
  ::  against the pin). Each walks its collection in the override's order,
  ::  which is where the TLA+ bodies (a CHOOSE-driven fold) disagree
  |=  [tag=@tas n=sem-apply:sm e=eenv]
  ^-  eres
  =/  ev  |=(i=@ud (eval (snag i args.n) e))
  ?+    tag  [%| 0 (rap 3 ~['internal: unknown CommunityModules op ' tag])]
  ::
  ::  FoldLeft(op, base, seq): acc = op(acc, s[i]), first to last;
  ::  FoldLeftDomain the same over the indices
      ?(%fold-left %fold-left-dom)
    =/  nm  ?:(?=(%fold-left tag) 'FoldLeft' 'FoldLeftDomain')
    =/  od  (cm-op nm 0 n e)
    ?:  ?=(%| -.od)  od
    =/  b  (ev 1)
    ?:  ?=(%| -.b)  b
    =/  sv  (ev 2)
    ?:  ?=(%| -.sv)  sv
    =/  t  (to-tuple:v p.sv)
    ?~  t  [%| (arg-error:so 2.169 3 nm 'sequence' | p.sv)]
    =/  xs=(list value:v)
      ?:  ?=(%fold-left tag)  u.t
      (turn (gulf 1 (lent u.t)) |=(i=@ud [%int (sun:si i)]))
    =/  acc  p.b
    |-  ^-  eres
    ?~  xs  [%& acc]
    =/  r  (apply-op p.od ~[acc i.xs] e)
    ?:  ?=(%| -.r)  r
    $(xs t.xs, acc p.r)
  ::
  ::  FoldRight(op, seq, base): acc = op(s[i], acc), last to first
      ?(%fold-right %fold-right-dom)
    =/  nm  ?:(?=(%fold-right tag) 'FoldRight' 'FoldRightDomain')
    =/  od  (cm-op nm 0 n e)
    ?:  ?=(%| -.od)  od
    =/  sv  (ev 1)
    ?:  ?=(%| -.sv)  sv
    =/  b  (ev 2)
    ?:  ?=(%| -.b)  b
    =/  t  (to-tuple:v p.sv)
    ?~  t  [%| (arg-error:so 2.169 2 nm 'sequence' | p.sv)]
    =/  xs=(list value:v)
      %-  flop
      ?:  ?=(%fold-right tag)  u.t
      (turn (gulf 1 (lent u.t)) |=(i=@ud [%int (sun:si i)]))
    =/  acc  p.b
    |-  ^-  eres
    ?~  xs  [%& acc]
    =/  r  (apply-op p.od ~[i.xs acc] e)
    ?:  ?=(%| -.r)  r
    $(xs t.xs, acc p.r)
  ::
  ::  FoldFunction / FoldSeq (op, base, fun): acc = op(fun[d], acc) over the
  ::  domain in order; FoldFunctionOnSet over the given subdomain
      ?(%fold-function %fold-seq %fold-function-on-set)
    =/  nm
      ?-  tag
        %fold-function  'FoldFunction'
        %fold-seq  'FoldSeq'
        %fold-function-on-set  'FoldFunctionOnSet'
      ==
    =/  od  (cm-op nm 0 n e)
    ?:  ?=(%| -.od)  od
    =/  b  (ev 1)
    ?:  ?=(%| -.b)  b
    =/  fv  (ev 2)
    ?:  ?=(%| -.fv)  fv
    =/  ps  (to-fcn-pairs:v (normalize:v p.fv))
    ?~  ps  [%| (arg-error:so 2.169 3 'FoldFunction' 'function' | p.fv)]
    =/  ds=(each (list value:v) eval-err:v)
      ?.  ?=(%fold-function-on-set tag)  [%& (turn u.ps |=(p=vpair:v d.p))]
      =/  iv  (ev 3)
      ?:  ?=(%| -.iv)  iv
      ?.  (set-like:v p.iv)
        [%| (arg-error:so 2.169 4 nm 'set' | p.iv)]
      [%& (set-elems:v (normalize:v p.iv))]
    ?:  ?=(%| -.ds)  ds
    =/  xs  p.ds
    =/  acc  p.b
    |-  ^-  eres
    ?~  xs  [%& acc]
    =/  x  (apply:v p.fv i.xs |)
    ?:  ?=(%| -.x)  x
    =/  r  (apply-op p.od ~[p.x acc] e)
    ?:  ?=(%| -.r)  r
    $(xs t.xs, acc p.r)
  ::
  ::  FoldSet(op, base, S): acc = op(x, acc) over S in normalized order
      %fold-set
    =/  od  (cm-op 'FoldSet' 0 n e)
    ?:  ?=(%| -.od)  od
    =/  b  (ev 1)
    ?:  ?=(%| -.b)  b
    =/  sv  (ev 2)
    ?:  ?=(%| -.sv)  sv
    ?.  (set-like:v p.sv)  [%| (arg-error:so 2.169 3 'FoldSet' 'set' | p.sv)]
    =/  xs  (set-elems:v (normalize:v p.sv))
    =/  acc  p.b
    |-  ^-  eres
    ?~  xs  [%& acc]
    =/  r  (apply-op p.od ~[i.xs acc] e)
    ?:  ?=(%| -.r)  r
    $(xs t.xs, acc p.r)
  ::
  ::  FoldBag(op, base, B): acc = op(acc, x), each x as many times as B[x]
      %fold-bag
    =/  od  (cm-op 'FoldBag' 0 n e)
    ?:  ?=(%| -.od)  od
    =/  b  (ev 1)
    ?:  ?=(%| -.b)  b
    =/  bv  (ev 2)
    ?:  ?=(%| -.bv)  bv
    =/  ps  (to-fcn-pairs:v (normalize:v p.bv))
    ?~  ps  [%| (arg-error:so 2.169 3 'FoldBag' 'bag' | p.bv)]
    =/  xs  u.ps
    =/  acc  p.b
    |-  ^-  eres
    ?~  xs  [%& acc]
    ?.  &(?=(%int -.r.i.xs) (syn:si p.r.i.xs) !=(--0 p.r.i.xs))
      [%| (wrong-value-error:so 'FoldBag' 'an element of Nat' r.i.xs)]
    =/  k  (abs:si p.r.i.xs)
    |-  ^-  eres
    ?:  =(0 k)  ^$(xs t.xs, acc acc)
    =/  r  (apply-op p.od ~[acc d.i.xs] e)
    ?:  ?=(%| -.r)  r
    $(k (dec k), acc p.r)
  ::
  ::  Quantify(S, P): how many elements satisfy P
      %quantify
    =/  sv  (ev 0)
    ?:  ?=(%| -.sv)  sv
    ?.  (set-like:v p.sv)  [%| (arg-error:so 2.169 1 'Quantify' 'set' | p.sv)]
    =/  od  (cm-op 'Quantify' 1 n e)
    ?:  ?=(%| -.od)  od
    =/  xs  (set-elems:v (normalize:v p.sv))
    =|  c=@ud
    |-  ^-  eres
    ?~  xs  [%& [%int (sun:si c)]]
    =/  r  (apply-op p.od ~[i.xs] e)
    ?:  ?=(%| -.r)  r
    ?.  ?=(%bool -.p.r)  [%| (op-arg-error 'Quantify' 'boolean-valued operator' (snag 1 args.n))]
    $(xs t.xs, c ?:(p.p.r +(c) c))
  ::
  ::  RemoveFirstMatch(s, Test): drop the first element Test accepts
      %remove-first-match
    =/  sv  (ev 0)
    ?:  ?=(%| -.sv)  sv
    =/  t  (to-tuple:v p.sv)
    ?~  t  [%| (arg-error:so 2.169 1 'RemoveFirstMatch' 'sequence' | p.sv)]
    =/  od  (cm-op 'RemoveFirstMatch' 1 n e)
    ?:  ?=(%| -.od)  od
    =/  xs  u.t
    =|  out=(list value:v)
    |-  ^-  eres
    ?~  xs  [%& [%seq (flop out)]]
    =/  r  (apply-op p.od ~[i.xs] e)
    ?:  ?=(%| -.r)  r
    ?.  ?=(%bool -.p.r)
      [%| (op-arg-error 'RemoveFirstMatch' 'boolean-valued function' (snag 1 args.n))]
    ?:  p.p.r  [%& [%seq (weld (flop out) t.xs)]]
    $(xs t.xs, out [i.xs out])
  ::
  ::  SelectInSeq / SelectLastInSeq (s, Test) and their SubSeq forms
  ::  (s, from, to, Test): the 1-based index of the first (last) match, 0
      ?(%select-in-seq %select-last-in-seq %select-in-subseq %select-last-in-subseq)
    =/  sub  ?=(?(%select-in-subseq %select-last-in-subseq) tag)
    =/  last  ?=(?(%select-last-in-seq %select-last-in-subseq) tag)
    =/  nm
      ?-  tag
        %select-in-seq  'SelectInSeq'
        %select-last-in-seq  'SelectLastInSeq'
        %select-in-subseq  'SelectInSubSeq'
        %select-last-in-subseq  'SelectLastInSubSeq'
      ==
    =/  sv  (ev 0)
    ?:  ?=(%| -.sv)  sv
    =/  t  (to-tuple:v p.sv)
    ?~  t  [%| (arg-error:so 2.169 1 nm 'sequence' | p.sv)]
    =/  len  (lent u.t)
    =/  od  (cm-op nm ?:(sub 3 1) n e)
    ?:  ?=(%| -.od)  od
    =/  rng=(each [lo=@ud hi=@ud] eval-err:v)
      ?.  sub  [%& 1 len]
      =/  fv  (ev 1)
      ?:  ?=(%| -.fv)  fv
      =/  tv  (ev 2)
      ?:  ?=(%| -.tv)  tv
      ?.  ?=(%int -.p.fv)  [%| (arg-error:so 2.169 2 nm 'natural' | p.fv)]
      ?.  ?=(%int -.p.tv)  [%| (arg-error:so 2.169 3 nm 'natural' | p.tv)]
      ?:  (slth:v p.p.tv p.p.fv)  [%& 1 0]
      =/  ok  |=(x=@s &((syn:si x) !=(--0 x) (lte (abs:si x) len)))
      ?.  (ok p.p.fv)  [%| 0 (rap 3 ~['The second argument of ' nm ' is not in the domain of its first argument.'])]
      ?.  (ok p.p.tv)  [%| 0 (rap 3 ~['The third argument of ' nm ' is not in the domain of its first argument.'])]
      [%& (abs:si p.p.fv) (abs:si p.p.tv)]
    ?:  ?=(%| -.rng)  rng
    ?:  (gth lo.p.rng hi.p.rng)  [%& [%int --0]]
    =/  is=(list @ud)  (gulf lo.p.rng hi.p.rng)
    =?  is  last  (flop is)
    |-  ^-  eres
    ?~  is  [%& [%int --0]]
    =/  r  (apply-op p.od ~[(snag (dec i.is) u.t)] e)
    ?:  ?=(%| -.r)  r
    ?.  ?=(%bool -.p.r)
      [%| (op-arg-error nm 'boolean-valued operator' (snag ?:(sub 3 1) args.n))]
    ?:  p.p.r  [%& [%int (sun:si i.is)]]
    $(is t.is)
  ::
      %causal-order
    :-  %|
    :-  0
    'unsupported CommunityModules operator: VectorClocks!CausalOrder; its order is java.util.HashMap\'s'
  ==
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
  =/  key=op-key:so  [origin.u.d (bnm name.u.d) ar]
  ?^  (lookup:so ov.e key)  %override
  ?^  (node-op:so key)  %override
  ?:  (is-descriptor:so key)  %override
  ?:  ?&  (is-standard:so ov.e origin.u.d)
          !(body-allowed:so ov.e origin.u.d (bnm name.u.d))
      ==
    %none
  ?~(body.u.d %none %body)
::
++  bind-params
  ::  R4.2: every argument is evaluated in the CALLER's env (`e0`), never in
  ::  the env being extended -- else `Attacks(Append(queens, c), i,
  ::  Len(queens) + 1)` read `queens` as the formal the FIRST argument had
  ::  just bound (N-Queens: "index 3 of tuple <<1, 1>>")
  |=  [e=eenv ps=(list spar:sm) as=(list sem:sm)]
  ^-  (each eenv eval-err:v)
  =/  e0  e
  |-  ^-  (each eenv eval-err:v)
  ?~  ps  [%& e]
  ?~  as  [%| 0 'argument count mismatch.']
  ?:  (gth arity.i.ps 0)
    =/  od  (resolve-oparg i.as e0)
    ?~  od
      [%| 0 (rap 3 ~['unsupported operator-valued argument: ' (oparg-name i.as) '.'])]
    $(ps t.ps, as t.as, e e(ops (~(put by ops.e) name.i.ps u.od)))
  ?.  used.i.ps
    ::  an unused expression parameter is not evaluated (lazy argument), and
    ::  still shadows an outer binding of its name
    =/  nm  name.i.ps
    $(ps t.ps, as t.as, e e(psub (~(del by psub.e) nm), vals (~(del by vals.e) nm)))
  =/  av  (eval i.as e0)
  ?:  ?=(%| -.av)  av
  ::  R4.2c (TestGraphs): the parameter SHADOWS a call-by-name entry of its
  ::  name -- `RemoveAt(s, i)` inside an unnamed `INSTANCE TLCMC`, whose
  ::  variable `i` is bound by name, read the STATE variable for `i`
  %=  $
    ps  t.ps
    as  t.as
    e   e(vals (~(put by vals.e) name.i.ps p.av), psub (~(del by psub.e) name.i.ps))
  ==
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
++  lambda-def
  ::  the anonymous operator behind a LAMBDA operator argument. SANY builds a
  ::  synthesized OpDefNode named LAMBDA and points the OpArgNode at it;
  ::  `+lambda-of` (lib/semantic) encodes exactly that as the reserved `$OpArg`
  ::  apply — parameters in `bound`, the generated body as the args TAIL — so
  ::  the definition is BUILT here rather than looked up, which is why
  ::  `+resolve-oparg`'s name lookup could never find it. R3.0b
  |=  n=sem:sm
  ^-  (unit sem-def:sm)
  ?.  ?=(%apply -.n)  ~
  ?.  =('$OpArg' name.op.n)  ~
  ?~  ubound.n  ~
  ?.  =('LAMBDA' name.i.ubound.n)  ~
  ::  a named op-arg carries only the arity literal; a LAMBDA carries the
  ::  body after it, and its parameters as the single bound group
  ?.  ?=([* * ~] args.n)  ~
  ?~  bound.n  ~
  =/  ps=(list spar:sm)
    %+  turn  vars.i.bound.n
    |=(b=sbind:sm `spar:sm`[name.b 0 & at.b])
  :-  ~
  :*  %sdef  'LAMBDA'  (lent ps)  &  lvl.n  at.n  ps
      `i.t.args.n  ''
  ==
::
++  resolve-oparg
  ::  an operator passed as an argument: a bare reference to a known op, or a
  ::  LAMBDA, which has no name to resolve and is built instead
  |=  [n=sem:sm e=eenv]
  ^-  (unit sem-def:sm)
  =/  nm  (oparg-name n)
  ?:  =('' nm)  ~
  ?:  =('LAMBDA' nm)  (lambda-def n)
  =/  d  (~(get by ops.e) nm)
  ?^  d  d
  (builtin-def n nm)
::
++  builtin-def
  ::  R4.2 (MCKVsnap): a BUILT-IN operator passed as an argument
  ::  (`ReduceSet(\intersect, S, b)`, Util.tla) is SANY's OpArgNode over the
  ::  built-in's own node; it has no definition to look up, so one is built:
  ::  formals that no source can name, the built-in applied to them
  |=  [n=sem:sm nm=@t]
  ^-  (unit sem-def:sm)
  ?.  ?=(%apply -.n)  ~
  ?.  =('$OpArg' name.op.n)  ~
  ?.  ?=(%builtin kind.op.n)  ~
  ?.  ?=([[%lit %num * *] ~] args.n)  ~
  =/  ar=@ud  (rash val.i.args.n dem)
  =/  ps=(list @t)
    (turn (gulf 1 ar) |=(i=@ud (cat 3 '$arg' (crip (a-co:co i)))))
  :-  ~
  :*  %sdef  nm  ar  |  lvl.n  ~
      (turn ps |=(p=@t `spar:sm`[p 0 & ~]))
      `[%apply [nm %builtin] lvl.n ~ ~ ~ (turn ps |=(p=@t `sem:sm`[%apply [p %formal-param] 0 ~ ~ ~ ~]))]
      ''
  ==
::
++  eval-letin
  |=  [n=sem-letin:sm e=eenv rs=rst]
  ^-  eout
  ?~  body.n  [[%| 0 'LET with no body.'] rs]
  (eval-rs u.body.n (with-lets lets.n e) rs)
::
++  with-lets
  ::  a LET's definitions in scope. Each SHADOWS an outer binding of its
  ::  name: a bound variable or parameter in `vals`/`psub` would otherwise
  ::  win (+eval-user reads a zero-arity name's `vals` entry first). Nano's
  ::  `\E block \in received[node] : ... LET block == signedBlock.block`
  ::  read the quantifier's signed block as `block`
  |=  [ls=(list sem-def:sm) e=eenv]
  ^-  eenv
  |-  ^-  eenv
  ?~  ls  e
  %=  $
    ls      t.ls
    ops.e   (~(put by ops.e) name.i.ls i.ls)
    vals.e  (~(del by vals.e) name.i.ls)
    psub.e  (~(del by psub.e) name.i.ls)
  ==
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
  ::  R4.2p: RECURSIVELY, as tlc2's `processUnchanged` is -- a tuple element
  ::  that is itself a tuple, and a zero-arity DEFINITION naming variables
  ::  (`UNCHANGED vars` with `vars == <<x, y>>`, `UNCHANGED <<cycle, doubles>>`),
  ::  were dropped, so those variables went unassigned and the successor was
  ::  "incomplete" (8 Examples rows). `ops` resolves the definitions; the
  ::  fuel bounds a definition that names itself
  |=  [n=sem:sm psub=(map @t sem:sm) ops=(map @t sem-def:sm)]
  ^-  (list @t)
  =/  fuel  64
  |-  ^-  (list @t)
  ?:  =(0 fuel)  ~
  =.  n  (deref-sem n psub)
  =.  n  (deref-letin n)
  ?.  ?=(%apply -.n)  ~
  ?:  ?=(%variable kind.op.n)  ~[name.op.n]
  ::  R4.2c (TestGraphs): an INSTANCE member (`UNCHANGED vars` with TLCMC's
  ::  `vars` reached through `INSTANCE TLCMC`) is its wrapper: its variables
  ::  name the substituted targets
  ?:  ?=(^ (anysubstin-mod:sm name.op.n))
    =/  sp  (substin-parts:sm n)
    ?~  sp  ~
    =/  ns  names.u.sp
    =/  xs  exprs.u.sp
    =/  ps2  psub
    |-  ^-  (list @t)
    ?:  |(?=(~ ns) ?=(~ xs))  ^$(n inner.u.sp, psub ps2, fuel (dec fuel))
    $(ns t.ns, xs t.xs, ps2 (~(put by ps2) name.i.ns i.xs))
  ?:  =('$Tuple' name.op.n)
    =/  as  args.n
    |-  ^-  (list @t)
    ?~  as  ~
    (weld ^$(n i.as, fuel (dec fuel)) $(as t.as))
  ?:  &(?=(%user-op kind.op.n) ?=(~ args.n))
    =/  d  (~(get by ops) name.op.n)
    ?~  d  ~
    ?~  body.u.d  ~
    ?.  ?=(~ params.u.d)  ~
    $(n u.body.u.d, fuel (dec fuel))
  ~
::
++  complete
  |=  [st=state vars=(set @t)]
  ^-  ?
  (levy ~(tap in vars) |=(nm=@t (~(has by st) nm)))
::
++  filter-lim
  ::  R4.3: the first `lim` elements of a one-binder set filter in its
  ::  domain's enumeration order, without materializing the rest, and
  ::  whether elements were left (CoffeeCan3000Beans: about 4.5 million
  ::  initial states, solved in one slice before any could be registered)
  |=  [n=sem-apply:sm e=eenv lim=@ud]
  ^-  (each [els=(list value:v) cut=?] eval-err:v)
  =/  bs  (flatten-bound bound.n)
  ?.  ?=([* ~] bs)  [%| 0 'a set filter expects one bounded variable.']
  =/  sd  (eval-domain rng.i.bs e)
  ?:  ?=(%| -.sd)  sd
  =/  body  (snag 0 args.n)
  =/  rc  (enum:v p.sd)
  ?:  ?=(%| -.rc)  rc
  =|  acc=(list value:v)
  =/  k  0
  =/  cur  p.rc
  |-  ^-  (each [els=(list value:v) cut=?] eval-err:v)
  =/  st  (enum-next:v cur)
  =/  es  -.st
  ?-    -.es
      %done  [%& (flop acc) |]
      %item
    ?:  (gte k lim)  [%& (flop acc) &]
    =/  b  (eval-bool body (bind-group e i.bs v.es))
    ?:  ?=(%| -.b)  b
    ?.  p.b  $(cur +.st)
    $(acc [v.es acc], k +(k), cur +.st)
  ==
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
++  in-force
  ::  R4.3: is the call-by-name substitution `nm <- x` already bound in `e`,
  ::  innermost or in the scopes its recorded closures restore?
  |=  [nm=@t x=sem:sm e=eenv]
  ^-  ?
  =/  o  (~(get by pout.e) nm)
  ?~  o  |
  ?:  =(`x (~(get by psub.e) nm))  &
  ?:  =(`x (~(get by psub.u.o) nm))  &
  =/  o2  (~(get by pout.u.o) nm)
  ?~  o2  |
  =(`x (~(get by psub.u.o2) nm))
::
++  clo-of
  ::  the closure of a call-by-name substitution `sub` written in env `e`
  |=  [sub=sem:sm e=eenv]
  ^-  clo
  :*  sub  psub.e  vals.e
      (~(run by pout.e) |=(c=clo `clo1`[sub.c psub.c vals.c]))
  ==
::
++  bind-substs
  ::  bind an INSTANCE's `WITH` substitutions (R2.3.5). Same split `+bind-psub`
  ::  makes for operator parameters, and for the same reason: a substitution
  ::  onto a bare state variable (`v <- x`) is kept as a NODE so the inner
  ::  module's `v'` is still an assignment to the outer `x`, while a value
  ::  substitution (`k <- 3`) is evaluated once and bound through `vals`, which
  ::  is where a CONSTANT reference reads from
  ::  R4.2: each substitution is evaluated in the INSTANTIATING env (`e0`),
  ::  as tlc2's `getVal(sub.getExpr(), c, ...)` uses `c`, not the context
  ::  being extended
  |=  [e=eenv ns=(list sbind:sm) as=(list sem:sm)]
  ^-  (each eenv eval-err:v)
  =/  e0  e
  |-  ^-  (each eenv eval-err:v)
  ?~  ns  [%& e]
  ?~  as  [%& e]
  ::  R4.2o: an OPERATOR-valued substitution (`XInit <- XInit` for a
  ::  `CONSTANT XInit(_)`, a `$OpArg`) binds the operator, as `+bind-psub`
  ::  binds an operator parameter: the inner `XInit(x)` then expands it
  ?:  &(?=(%apply -.i.as) =('$OpArg' name.op.i.as))
    =/  od  (resolve-oparg i.as e0)
    ?~  od  $(ns t.ns, as t.as)
    $(ns t.ns, as t.as, e e(ops (~(put by ops.e) name.i.ns u.od)))
  ::  R4.3: the SAME substitution already in force -- the port wraps every
  ::  member of an instance in its `WITH`, so `EWD998Chan!Next` calling its
  ::  sibling `System` binds the instance's substitutions again, from inside
  ::  the instance. Rebound there, its closure was the instance's own scope
  ::  and `active <- Node2Nat(active)` applied `Node2Nat` twice
  ::  (EWD998ChanID). tlc2 binds them once; the binding in force is kept
  ::  At ANY level of the scope chain: the port also wraps each member in
  ::  every ENCLOSING instance's `WITH`, so a sibling call inside TLCMC's
  ::  `MCR` re-applied TestGraphs' outer `S <- S` from inside MCR's scope,
  ::  over MCR's own `S <- SeqToSet(S)` (`Len` of a set, TestGraphs)
  ?:  (in-force name.i.ns i.as e0)
    $(ns t.ns, as t.as)
  ?:  (state-var-ref i.as e0)
    =.  pout.e  (~(put by pout.e) name.i.ns (clo-of i.as e0))
    $(ns t.ns, as t.as, e e(psub (~(put by psub.e) name.i.ns i.as)))
  ::  R4.2n: a STATE-DEPENDENT expression (`y <- x % 2`) is bound LAZILY as
  ::  well, as tlc2's `getVal(expr, con, false)` does (a LazyValue): an inner
  ::  VARIABLE reads it through `psub`, so `y'` evaluates `(x % 2)'` in the
  ::  successor. Bound eagerly, `y'` found no `y` in the successor state. An
  ::  inner CONSTANT still reads the value from `vals`
  ::
  ::  R4.2d: ONLY by name. Its current-state value used to be bound in
  ::  `vals` as well, and `vals` is where `+eval-user` answers a zero-arity
  ::  name first (R4.2u's config value for a definition) -- so the implicit
  ::  `chosen <- chosen` of `C == INSTANCE Consensus` (Voting's `chosen` is a
  ::  DEFINITION) read the CURRENT value for `chosen'`, and the refinement
  ::  `[][C!Next]_chosen` failed on every step: MCVoting reported a liveness
  ::  (implied-action) failure where tlc2 succeeds. An inner CONSTANT bound
  ::  this way reads it through `psub` (`+apply-const`)
  ::  R4.3: and an expression that READS the state whatever its recorded
  ::  level -- a `WITH` expression carries level 0 in the graph (`x <- x * 2`,
  ::  `y <- Dbl(x)`), so it was evaluated once, at the current state, and an
  ::  implied action through the instance read the wrong value or none
  ?:  |((gth (sem-level i.as) 0) (reads-state i.as e0))
    =.  pout.e  (~(put by pout.e) name.i.ns (clo-of i.as e0))
    $(ns t.ns, as t.as, psub.e (~(put by psub.e) name.i.ns i.as))
  =/  av  (eval i.as e0)
  ::  R4.2m: an expression with no VALUE -- `Values <- Int`, an infinite
  ::  set (Disruptor's RingBuffer) -- is bound by name too, as tlc2 binds
  ::  the lazy value; a reference reads it where it is used (membership,
  ::  `+eval-domain`), and a genuine error surfaces there
  ?:  ?=(%| -.av)
    =.  pout.e  (~(put by pout.e) name.i.ns (clo-of i.as e0))
    $(ns t.ns, as t.as, psub.e (~(put by psub.e) name.i.ns i.as))
  $(ns t.ns, as t.as, e e(vals (~(put by vals.e) name.i.ns p.av)))
::
++  reads-state
  ::  R4.3: may `s` read the state? It names a declared variable or a
  ::  call-by-name binding, directly or through what it reaches (a superset,
  ::  so a misjudgment only binds lazily, which is always sound)
  |=  [s=sem:sm e=eenv]
  ^-  ?
  =/  rn  (reach-names s ops.e)
  ?|  (lien ~(tap in vars.e) |=(n=@t (~(has in rn) n)))
      (lien ~(tap by psub.e) |=([n=@t *] (~(has in rn) n)))
  ==
::
++  sem-level
  |=  s=sem:sm
  ^-  @ud
  ?-  -.s
    %apply    lvl.s
    %letin    lvl.s
    %atref    lvl.s
    %lit      0
    %nullodn  0
  ==
::
++  bind-psub
  ::  bind an operator's parameters for solving: a bare state-variable argument
  ::  is kept as a NODE (call-by-name, so it stays assignable in the body); an
  ::  operator argument resolves through `ops`; any other value argument is
  ::  evaluated once in the caller env and bound through `vals`.
  ::  R4.2n: `ev` is the env a value argument is EVALUATED in -- the solving
  ::  env (`+senv`), which holds the current state. Evaluated in `e`, whose
  ::  state is not the one being solved from, a state-dependent argument
  ::  failed (`Return(c, alloc[c])`: "variable is unassigned in the current
  ::  state"), and an ENABLED test reads a failure as FALSE -- so a fairness
  ::  condition on such an action was silently vacuous
  |=  [e=eenv ev=eenv ps=(list spar:sm) as=(list sem:sm)]
  ^-  (each eenv eval-err:v)
  ?~  ps  [%& e]
  ?~  as  [%& e]
  ?:  (gth arity.i.ps 0)
    =/  od  (resolve-oparg i.as ev)
    ?~  od
      [%| 0 (rap 3 ~['unsupported operator-valued argument: ' (oparg-name i.as) '.'])]
    $(ps t.ps, as t.as, e e(ops (~(put by ops.e) name.i.ps u.od)))
  ::  each binding SHADOWS the other table's entry of the name: a `%formal-
  ::  param` reads `psub` first, so a stale call-by-name `src` from an outer
  ::  call captured this call's value `src` (CheckpointCoordination:
  ::  "variable is unassigned in the current state: src")
  =/  nm  name.i.ps
  ::  the argument is bound as the variable it DENOTES in the caller (chased
  ::  through the caller's `psub`): `Connected(Leader, p)` binds `src` to
  ::  `Leader`, and its `ConnectedOneWay(src, dst)` must bind its own `src`
  ::  to `Leader` too, not to the node `src`, which names itself there
  ?:  (state-var-ref i.as ev)
    =/  dn  (deref-sem i.as psub.ev)
    $(ps t.ps, as t.as, e e(psub (~(put by psub.e) nm dn), vals (~(del by vals.e) nm)))
  ::  R4.2o: a PRIMED state variable (`XAct(0, x, x')`, TwoPhase) is bound by
  ::  name too, as tlc2 binds every argument lazily: `xNext = xInit` in the
  ::  body is then an assignment to `x'` (`+assignable-sem` chases it), where
  ::  evaluating `x'` here read a successor that does not exist yet
  ?:  ?&  ?=(%apply -.i.as)
          =('\'' name.op.i.as)
          ?=([* ~] args.i.as)
          (state-var-ref i.args.i.as ev)
      ==
    =/  dn  i.as(args ~[(deref-sem i.args.i.as psub.ev)])
    $(ps t.ps, as t.as, e e(psub (~(put by psub.e) nm dn), vals (~(del by vals.e) nm)))
  ?.  used.i.ps
    $(ps t.ps, as t.as, e e(psub (~(del by psub.e) nm), vals (~(del by vals.e) nm)))
  ::  R4.3 (LockHS): an ACTION argument (`NoStutter(NoHistoryChange(l0(self)))`)
  ::  cannot be evaluated before the successor is solved, and tlc2 binds
  ::  every argument lazily: bound by name, read in the CALLER's scope (its
  ::  closure, as an INSTANCE substitution's), and solved where the body uses
  ::  it in action position. Likewise one that fails to evaluate here
  =/  lazy=eenv
    %=  e
      psub  (~(put by psub.e) nm i.as)
      pout  (~(put by pout.e) nm (clo-of i.as ev))
      vals  (~(del by vals.e) nm)
    ==
  ?:  (gth (sem-level i.as) 1)  $(ps t.ps, as t.as, e lazy)
  =/  av  (eval i.as ev)
  ?:  ?=(%| -.av)  $(ps t.ps, as t.as, e lazy)
  $(ps t.ps, as t.as, e e(vals (~(put by vals.e) nm p.av), psub (~(del by psub.e) nm)))
::
++  solve
  |=  [n=sem:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  ?.  ?=(%apply -.n)
    ?:  ?=(%letin -.n)  (solve-letin n mode cur part e s)
    (solve-filter n mode cur part e s)
  =/  nm  name.op.n
  ::  R4.2m: a labeled action `P :: A` is solved as `A`; R4.2am: so is a
  ::  selected one (`$Nop`)
  ?:  &(|(=(nm '$Label') =(nm '$Nop')) ?=(^ args.n))  $(n i.args.n)
  ?:  |(=(nm '$ConjList') =(nm '\\land'))
    (solve-conj args.n mode cur part e s)
  ?:  |(=(nm '$DisjList') =(nm '\\lor'))
    (solve-disj args.n mode cur part e s)
  ?:  =(nm '$IfThenElse')  (solve-ite args.n mode cur part e s)
  ?:  =(nm '$Case')  (solve-case args.n mode cur part e s)
  ::  R4.2 (MCRealTimeHourClock): `[A]_e` in action position is `A \/
  ::  UNCHANGED e` (`getNextStates` OPCODE_sa: A's successors, then
  ::  `processUnchanged`), `BigNext == [NowNext]_now /\ [HCnxt]_hr`
  ?:  &(=(nm '$SquareAct') ?=([* * ~] args.n))
    =^  r  s  (solve i.args.n mode cur part e s)
    ?:  ?=(%| -.r)  [r s]
    =^  u  s  (solve-unchanged i.t.args.n mode cur part e s)
    ?:  ?=(%| -.u)  [u s]
    [[%& (weld p.r p.u)] s]
  ::  R4.2g: action composition `A \cdot B` -- `s -A-> t -B-> u`
  ?:  &(=(nm '\\cdot') ?=([* * ~] args.n))
    (solve-cdot i.args.n i.t.args.n mode cur part e s)
  ::  R4.2d: `P => A` in action position solves A when P holds and is
  ::  satisfied as-is when it does not (OPCODE_implies in both
  ::  `getInitStates` and `getNextStates`); filtering it as a boolean lost
  ::  the successors a `\E` in A enumerates
  ?:  &(=(nm '=>') ?=([* * ~] args.n))
    =^  b  s  (eval-bool-rs i.args.n (senv mode cur part e) s)
    ?:  ?=(%| -.b)  [b s]
    ?.  p.b  [[%& ~[part]] s]
    (solve i.t.args.n mode cur part e s)
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
    =/  dn  (snag 1 args.n)
    ?:  ?&  =(%init mode)
            !=(0 ilim.e)
            ?=(%apply -.dn)
            =('$SubsetOf' name.op.dn)
            !(sem-draws dn e)
        ==
      =/  lf  (filter-lim dn (senv mode cur part e) ilim.e)
      ?:  ?=(%| -.lf)  [lf s]
      :-  [%& (turn els.p.lf |=(x=value:v (~(put by part) u.as x)))]
      s(trunc |(trunc.s cut.p.lf))
    =/  sd  (eval-domain dn (senv mode cur part e))
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
  ::  R4.3 (LockHS): a formal parameter bound by name to an expression is
  ::  that expression in action position (tlc2's getNextStates follows the
  ::  Context binding), solved in the caller's scope, not filtered
  ?:  ?&(?=(%formal-param kind.op.n) ?=(~ args.n))
    =/  sb  (~(get by psub.e) nm)
    ?:  ?|(?=(~ sb) (bare-self u.sb nm e) (state-var-ref u.sb e))
      (solve-filter n mode cur part e s)
    (solve u.sb mode cur part (outer-of nm e) s)
  ::  R4.2o: a CONSTANT operator bound to an operator (an INSTANCE's
  ::  `$OpArg` substitution, or a config `F <- G`) is expanded like a user
  ::  operator, so an assignment in its body still assigns
  ?:  ?|  ?=(%user-op kind.op.n)
          ?&  ?=(?(%constant %new-constant) kind.op.n)
              !(~(has by vals.e) nm)
              (~(has by ops.e) nm)
      ==  ==
    =/  d  (~(get by ops.e) nm)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  (solve-filter n mode cur part e s)
    ?.  =((lent params.u.d) (lent args.n))  (solve-filter n mode cur part e s)
    ::  R4.2d: an arity-0 definition with a precomputed VALUE (a constant
    ::  definition, `+with-cdefs`; a drawn or config-valued one in `vals`) is
    ::  that value at the pin -- `lookup` returns it, not the OpDefNode -- so
    ::  it is a boolean, never expanded and enumerated
    ?:  ?&  ?=(~ args.n)
            ?|  (~(has by vals.e) nm)
                =/  cd  (~(get by cdefs.e) nm)
                &(?=(^ cd) =(def.u.cd u.d))
        ==  ==
      (solve-filter n mode cur part e s)
    ?:  =(0 fuel.e)
      [[%| 0 'evaluation recursion/resource limit exceeded.'] s]
    =/  e2  (bind-psub e(fuel (dec fuel.e)) (senv mode cur part e) params.u.d args.n)
    ?:  ?=(%| -.e2)  [e2 s]
    ::  R4.2c: the member's own parameters win over its wrapper's
    ::  substitutions (`+keep-params`)
    =/  sp  (substin-parts:sm u.body.u.d)
    ?~  sp  (solve u.body.u.d mode cur part p.e2 s)
    =/  e3  (bind-substs (senv mode cur part p.e2) names.u.sp exprs.u.sp)
    ?:  ?=(%| -.e3)  [e3 s]
    (solve inner.u.sp mode cur part (keep-params p.e3 p.e2 params.u.d) s)
  (solve-filter n mode cur part e s)
::
++  cdot-msg
  ::  the pin's refusal when the property is not set (Tool.java:1527)
  ^-  @t
  %+  rap  3
  :~  'The current version of TLC does not support action composition.  '
      'An incomplete implementation can be enabled via the '
      'tlc2.tool.impl.Tool.cdot=true java property.'
  ==
::
++  cdot-on
  ::  R4.2g: is action composition enabled for this run?
  |=  e=eenv
  ^-  ?
  =(`'true' (run-prop e 'tlc2.tool.impl.Tool.cdot'))
::
++  solve-cdot
  ::  R4.2g: tlc2's experimental `\cdot` in the next-state relation
  ::  (Tool.java:1487-1530, behind `-Dtlc2.tool.impl.Tool.cdot=true`): the
  ::  intermediate state `t` starts as `s0.copyWith(s1)` -- the CURRENT values
  ::  of the variables the successor has already assigned -- A is solved from
  ::  s0 into it, and B from each such `t` into the successor. The
  ::  intermediate states count as generated (`xgen`). Without the property
  ::  it is the pin's refusal
  |=  [a=sem:sm b=sem:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  ?.  (cdot-on e)  [[%| 0 cdot-msg] s]
  =/  t0=state
    %-  malt
    %+  murn  ~(tap by part)
    |=  [k=@t *]
    ^-  (unit [@t value:v])
    =/  c  (~(get by cur) k)
    ?~(c ~ `[k u.c])
  =^  ra  s  (solve a mode cur t0 e s)
  ?:  ?=(%| -.ra)  [ra s]
  =.  xgen.s  (add xgen.s (lent p.ra))
  =/  ts  p.ra
  =|  out=(list state)
  |-  ^-  sout
  ?~  ts  [[%& (flop out)] s]
  =^  rb  s  (solve b mode i.ts part e s)
  ?:  ?=(%| -.rb)  [rb s]
  $(ts t.ts, out (weld (flop p.rb) out))
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
  (solve u.body.n mode cur part (with-lets lets.n e) s)
::
++  solve-conj
  ::  thread the partial state left-to-right across the conjuncts
  ::  R4.2d: DEPTH-first, one partial state at a time, as tlc2's
  ::  `ActionItemList` is (OPCODE_cl solves `args[0]` with the rest pushed
  ::  as continuations), so evaluation order -- and with it the RNG and
  ::  `TLCSet` order -- is the pin's. And tlc2's fast path: once EVERY
  ::  variable is assigned, the remaining conjuncts are evaluated as booleans
  ::  instead of solved (`Tool.getNextStatesAllAssigned` under the default
  ::  `TLCGlobals.warn`, `getInitStates`' `ps.allAssigned()` branch), so a
  ::  later `\E` or `\/` adds no duplicate successors. Measured: `x' = x + 1
  ::  /\ \E q \in {1, 2, 3} : q > 0` generates 1 successor per state at the
  ::  pin, where solving the `\E` gave 3. The FIRST conjunct of a list is
  ::  never fast-pathed: tlc2 solves `args[0]` directly
  |=  [cs=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  first=?  &
  |-  ^-  sout
  ?~  cs  [[%& ~[part]] s]
  ?:  &(!first (complete part vars.e))  (conj-bools cs mode cur part e s)
  =^  r  s  (solve i.cs mode cur part e s)
  ?:  ?=(%| -.r)  [r s]
  =/  ps  p.r
  =|  out=(list state)
  |-  ^-  sout
  ?~  ps  [[%& (flop out)] s]
  =^  r2  s  ^$(cs t.cs, part i.ps, first |)
  ?:  ?=(%| -.r2)  [r2 s]
  $(ps t.ps, out (weld (flop p.r2) out))
::
++  conj-bools
  ::  R4.2d: the all-assigned fast path -- every remaining conjunct is a
  ::  boolean filter on the complete state (`+solve-filter` keeps the INIT
  ::  coverage `secondary` count tlc2 increments here)
  |=  [cs=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  ?~  cs  [[%& ~[part]] s]
  =^  r  s  (solve-filter i.cs mode cur part e s)
  ?:  ?=(%| -.r)  [r s]
  ?~  p.r  [r s]
  $(cs t.cs)
::
++  solve-each
  ::  solve `n` from every partial state, concatenating results in order.
  ::  R4.P1 (H10): the three solvers here accumulate REVERSED and flop once;
  ::  `(weld out p.r)` copied the whole accumulator per step, O(n^2) in the
  ::  states produced (ElevatorSafetyMedium: 19,683 initial states)
  |=  [n=sem:sm mode=?(%init %next) cur=state parts=(list state) e=eenv s=rst]
  ^-  sout
  =|  out=(list state)
  |-  ^-  sout
  ?~  parts  [[%& (flop out)] s]
  =^  r  s  (solve n mode cur i.parts e s)
  ?:  ?=(%| -.r)  [r s]
  $(parts t.parts, out (weld (flop p.r) out))
::
++  solve-disj
  ::  branch: each disjunct solved from the same partial state, in order
  |=  [ds=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =|  out=(list state)
  |-  ^-  sout
  ?~  ds  [[%& (flop out)] s]
  =^  r  s  (solve i.ds mode cur part e s)
  ?:  ?=(%| -.r)  [r s]
  $(ds t.ds, out (weld (flop p.r) out))
::
++  solve-ite
  |=  [as=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =^  b  s  (eval-bool-rs (snag 0 as) (senv mode cur part e) s)
  ?:  ?=(%| -.b)  [b s]
  (solve ?:(p.b (snag 1 as) (snag 2 as)) mode cur part e s)
::
++  solve-case
  ::  R4.2 (ReadersWriters): `Tool.getInitStates`/`getNextStates`
  ::  OPCODE_case -- the guards are evaluated in order, the first TRUE one's
  ::  arm is SOLVED (so `CASE p -> Read(a) [] q -> Write(a)` assigns), OTHER
  ::  only when no guard holds. Filtering the CASE as a boolean evaluated the
  ::  arm's primed variables before they were assigned
  |=  [as=(list sem:sm) mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  other=(unit sem:sm)  ~
  |-  ^-  sout
  ?~  as
    ?^  other  (solve u.other mode cur part e s)
    :_  s
    :+  %|  0
    ?:  ?=(%init mode)
      'In computing initial states, TLC encountered a CASE with no conditions true.'
    'In computing next states, TLC encountered a CASE with no conditions true.'
  =/  pr  i.as
  ?.  ?=(%apply -.pr)  [[%| 0 'malformed CASE arm.'] s]
  =/  guard  (snag 0 args.pr)
  =/  body   (snag 1 args.pr)
  ?:  ?=(%nullodn -.guard)  $(as t.as, other `body)
  =^  b  s  (eval-rs guard (senv mode cur part e) s)
  ?:  ?=(%| -.b)  [b s]
  ?.  ?=(%bool -.p.b)
    :_  s
    :+  %|  0
    %+  rap  3
    :~  'In computing '  ?:(?=(%init mode) 'initial' 'next')
        ' states, a non-boolean expression ('  (type-name:v p.b)
        ') was used as a guard condition of a CASE.'
    ==
  ?:  p.p.b  (solve body mode cur part e s)
  $(as t.as)
::
++  solve-exists
  ::  \E x \in S : A — branch over the domain in enumeration order. SEVERAL
  ::  binders are the PRODUCT of their domains: tlc2 runs one
  ::  `ContextEnumerator` over every bound group (`Tool.getNextStates`,
  ::  OPCODE_be), so `\E a \in A, m \in M : A` is not a different construct,
  ::  only a longer odometer. R3.0c
  |=  [n=sem-apply:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  bs  (flatten-bound bound.n)
  =/  ds  (bound-domains bs (senv mode cur part e))
  ?:  ?=(%| -.ds)  [ds s]
  =/  body  (snag 0 args.n)
  =|  out=(list state)
  =/  rows  (bind-rows p.ds)
  |-  ^-  sout
  ?~  rows  [[%& (flop out)] s]
  =^  r  s  (solve body mode cur part (bind-vals e bs i.rows) s)
  ?:  ?=(%| -.r)  [r s]
  $(rows t.rows, out (weld (flop p.r) out))
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
  =/  ds  (bound-domains bs (senv mode cur part e))
  ?:  ?=(%| -.ds)  [ds s]
  =/  body  (snag 0 args.n)
  =/  acc=(list state)  ~[part]
  =/  rows  (bind-rows p.ds)
  |-  ^-  sout
  ?~  rows  [[%& acc] s]
  =^  step  s  (solve-each body mode cur acc (bind-vals e bs i.rows) s)
  ?:  ?=(%| -.step)  [step s]
  $(rows t.rows, acc p.step)
::
++  solve-unchanged
  ::  UNCHANGED e assigns each named variable to its current value
  |=  [arg=sem:sm mode=?(%init %next) cur=state part=state e=eenv s=rst]
  ^-  sout
  =/  names  (unchanged-vars arg psub.e ops.e)
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
  -:(eval-enabled-rs n e empty-rst)
::
++  eval-enabled-rs
  ::  R2.7.4.3 MEASURED the pin and the answer is that ENABLED must NOT
  ::  discard. `Tool.enabled` throws the WITNESS away, but `TLCSet` writes a
  ::  static field, so anything the witness search wrote survives: with
  ::  `A == TLCSet(0, TLCGetOrDefault(0,0) + 1) /\ x' = x + 1`, evaluating
  ::  `ENABLED A` once per expansion leaves the register at 1, then 2. So the
  ::  carrier goes IN (the search must read the live store) and comes back
  ::  OUT (its writes are kept) -- only the witness state is dropped.
  ::
  ::  R2.7.4.1b had this discarding, correctly, while nothing wrote; this is
  ::  the increment that makes it observable, and the measurement is what
  ::  changed it
  |=  [n=sem:sm e=eenv rs=rst]
  ^-  eout
  =^  r  rs  (solve n %next s0.e ~ e(enabled &) rs)
  ?:  ?=(%| -.r)  [r rs]
  [[%& [%bool ?=(^ p.r)]] rs]
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
  ::  R4.2ah: the module's own named theorems, as `$thm:` definitions
  =.  defs.m  (weld defs.m (thm-defs:sm name.m thmdefs.m))
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
  [~ (defmap-of mo) ~ default-fuel s0 s1 | | (vars-of mo) ~ 0 make-senv:so ~ ~ ~ [~ ~] ~ 0]
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
  (with-cdefs [consts defs ~ default-fuel ~ ~ | | vars ~ 0 make-senv:so ~ ~ ~ [~ ~] ~ 0])
::
++  with-cdefs
  ::  R4.P3 (H4): tlc2's `SpecProcessor.processConstantDefns` -- every
  ::  arity-0 definition whose body is CONSTANT-level is evaluated once,
  ::  before the search, and references read the value. Measured: Paxos's
  ::  `PaxosTypeOK` re-built `Message` (about 240 records) per state, 86% of
  ::  the run, and CoffeeCan's `TypeInvariant` re-built `Can` (10,201 records)
  ::  per initial state. As in tlc2:
  ::  - a definition that FAILS to evaluate is left lazy (the error, if it
  ::    matters, surfaces where it is referenced);
  ::  - an overridden operator is not a definition here (`+lookup:so` /
  ::    `+node-op:so` answer it);
  ::  - StandardModule definitions are skipped (their bodies are dummies).
  ::  A definition whose evaluation TOUCHES THE RUN STATE (a random draw,
  ::  `TLCSet`) is not cached here: R4.2aa's `+startup-draws` evaluates the
  ::  drawing ones once, in tlc2's order, into `vals`.
  ::  `~+`: the environment is rebuilt per expansion (`+env-of`), and the
  ::  memo cache answers every rebuild after the first from the same inputs
  |=  e=eenv
  ^-  eenv
  ~+
  =/  ds  ~(tap by ops.e)
  =|  acc=(map @t [def=sem-def:sm val=value:v])
  |-  ^-  eenv
  ?~  ds  e(cdefs acc)
  =/  nm  p.i.ds
  =/  d   q.i.ds
  ::  R4.2ah: a named theorem (`$thm:`) is evaluated only where referenced;
  ::  tlc2's `processConstantDefns` walks `getOpDefs()`, which has none
  ?.  ?&  ?=(~ params.d)
          !=('$thm:' (end [3 5] nm))
          ::  R4.2c: not a definition that reaches an override with a
          ::  minLevel above 0 (`TLCGet`, `CounterExample`): SANY gives it
          ::  level 0, but tlc2's level bound takes the override's minLevel, so
          ::  `Lvl == TLCGet("level") < K` is STATE-level there and never
          ::  constant-folded. Cached here it froze at its startup value, and a
          ::  CONSTRAINT built on it pruned nothing
          =(0 lvl.d)
          ?=(^ body.d)
          !(reaches-run-op u.body.d ops.e)
          !(lazy-set u.body.d ops.e)
          !(is-standard:so ov.e origin.d)
          ?=(~ (lookup:so ov.e [origin.d (bnm name.d) 0]))
          ?=(~ (node-op:so [origin.d (bnm name.d) 0]))
      ==
    $(ds t.ds)
  =/  r  (mule |.((eval-rs u.body.d e empty-rst)))
  ?.  ?=(%& -.r)  $(ds t.ds)
  =/  [res=eres rs=rst]  p.r
  ?.  &(?=(%& -.res) =(empty-rst rs))  $(ds t.ds)
  $(ds t.ds, acc (~(put by acc) nm [d p.res]))
::
++  lazy-set
  ::  R4.3: does a body denote a set tlc2 keeps LAZY (the class rules of
  ::  `+sexp-class:v`, read off the expression)? `processConstantDefns`
  ::  caches such a value as an unenumerated SetOfRcdsValue, SubsetValue, ...;
  ::  materialized here, MultiPaxos's unused `NodeStates` (about 3 x 10^9
  ::  records) never finished, and a 192,000-record one cost 565 s. Left
  ::  uncached, a reference evaluates it through `+eval-sdef`'s memo, and
  ::  membership never materializes it (`+memb-node`). A misjudged class only
  ::  moves cost, never a value
  |=  [b=sem:sm ops=(map @t sem-def:sm)]
  ^-  ?
  =/  fuel  32
  |-  ^-  ?
  ?.  ?=(%apply -.b)  |
  ?:  =(0 fuel)  |
  =/  nm  name.op.b
  ?:  ?|  =(nm 'SUBSET')  =(nm '$SetOfFcns')  =(nm '$SetOfRcds')
          =(nm '\\times')  =(nm '$CartesianProd')
      ==
    &
  ?:  =(nm 'UNION')
    ?.  ?=([[%apply *] *] args.b)  &
    !=('$SetEnumerate' name.op.i.args.b)
  ?:  ?&  ?=([* * ~] args.b)
          |(=(nm '\\union') =(nm '\\intersect') =(nm '\\'))
      ==
    =/  l  $(b i.args.b, fuel (dec fuel))
    ?:  =(nm '\\')  l
    =/  r  $(b i.t.args.b, fuel (dec fuel))
    ?:(=(nm '\\union') |(l r) &(l r))
  ?.  ?&(?=(~ args.b) ?=(%user-op kind.op.b))  |
  =/  d  (~(get by ops) nm)
  ?~  d  |
  ?.  ?&(?=(~ params.u.d) ?=(^ body.u.d))  |
  $(b u.body.u.d, fuel (dec fuel))
::
++  reaches-run-op
  ::  R4.2c: does a body reach an operator whose override has minLevel > 0?
  |=  [b=sem:sm ops=(map @t sem-def:sm)]
  ^-  ?
  =/  rn  (reach-names b ops)
  |((~(has in rn) 'TLCGet') (~(has in rn) 'CounterExample'))
::
++  startup-draws
  ::  R4.2aa: the definitions `+with-cdefs` leaves per-reference because
  ::  they DRAW. tlc2's `processConstantDefns` evaluates them once too, on the
  ::  main thread, from `new Random(seed)`, in the order it walks the module
  ::  table: each module's constant substitutions (`C <- R` evaluates R),
  ::  then its `getOpDefs()` in declaration order, the first module to reach
  ::  a definition evaluating it. Measured at the pin (seeds 0 and 1):
  ::  `B == RandomElement(0..99)` declared before `A` takes the FIRST draw,
  ::  an EXTENDed module's definition precedes both, and `D == B + ...`
  ::  reuses B's value and draws once. The ASSUMEs and then the initial-state
  ::  solve continue the SAME stream (BFS, DFID and simulate alike).
  ::
  ::  `ord` is that order (the caller builds it from the module); `rs` the
  ::  carrier, its `es` the scrambled seed. R4.2a: a definition that PRINTS
  ::  is evaluated here once as well, its lines on `out`. A drawn value joins `vals`, the slot a config value
  ::  for a definition uses (R4.2u), so every later env reads it. A
  ::  definition that draws and then FAILS stays lazy, but its draws are
  ::  spent, as Java's are before the exception it swallows. Not drawn
  ::  here: instance members (`I!R`; tlc2 skips a parametrized instance's
  ::  definitions) and a name the config already gave a value. A
  ::  substituted constant (`C <- R`) still re-evaluates R's body per
  ::  reference, as tlc2 does (only `R` itself is cached; measured: 6
  ::  distinct states for `Next == x' = C`)
  |=  $:  ord=(list sem-def:sm)
          defs=(map @t sem-def:sm)
          consts=(map @t value:v)
          vars=(set @t)
          rs=rst
      ==
  ^-  [vals=(map @t value:v) rs=rst]
  =/  e  (make-env defs consts vars)
  =|  seen=(set @t)
  |-  ^-  [vals=(map @t value:v) rs=rst]
  ?~  ord  [vals.e rs]
  =/  d   i.ord
  =/  nm  name.d
  ?:  (~(has in seen) nm)  $(ord t.ord)
  =.  seen  (~(put in seen) nm)
  ?.  ?&  ?=(~ params.d)
          =(0 lvl.d)
          ?=(^ body.d)
          =(`d (~(get by defs) nm))
          !(~(has by vals.e) nm)
          =(nm (bnm nm))
          !=('$thm:' (end [3 5] nm))
          !(is-standard:so ov.e origin.d)
          ?=(~ (lookup:so ov.e [origin.d nm 0]))
          ?=(~ (node-op:so [origin.d nm 0]))
      ==
    $(ord t.ord)
  =/  r  (mule |.((eval-rs u.body.d e rs)))
  ?.  ?=(%& -.r)  $(ord t.ord)
  =/  [res=eres rs2=rst]  p.r
  ::  R4.2a: a PRINT is a run-state effect too, and tlc2 prints it here, once.
  ::  A register write is not (it stays per-reference, as before)
  ?:  &(=(es.rs es.rs2) =(out.rs out.rs2))  $(ord t.ord)
  ?.  &(=(regs.rs regs.rs2) =(named.rs named.rs2))  $(ord t.ord)
  ?.  ?=(%& -.res)  $(ord t.ord, rs rs2)
  $(ord t.ord, rs rs2, vals.e (~(put by vals.e) nm p.res))
::
++  empty-counter-example
  ::  `new CounterExample()` -- the value a run with no violation evaluates
  ::  `TLCExt!CounterExample` to. Both fields are the EMPTY SET, which is the
  ::  test `_JsonTrace` and `_DotTrace` use (`CounterExample.state = {}`)
  ^-  value:v
  :-  %rec
  :~  ['action' [%set %set-enum ~]]
      ['state' [%set %set-enum ~]]
  ==
::
++  with-ce
  ::  R2.7.14b: the counter-example value applied to a prebuilt env, for the
  ::  duration of POSTCONDITION evaluation only -- tlc2 conses it onto an
  ::  otherwise EMPTY Context for exactly that call and nothing else sees it
  |=  [e=eenv v=value:v]
  ^-  eenv
  e(ce `v)
::
++  with-idk
  ::  R4.2e: the search identity applied to a prebuilt env (see `idk`)
  |=  [e=eenv perms=(list (map @t @t)) view=(unit sem:sm)]
  ^-  eenv
  e(idk [perms view])
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
++  next-states-raw-rs
  ::  R4.2j: `+next-states-rs` without the completeness check, so the caller
  ::  can report WHICH successor is incomplete and which variables it lacks
  ::  (EC 2109) together with the behavior that led to it
  |=  [cur=state body=sem:sm e=eenv s=rst]
  ^-  sout
  (solve body %next cur ~ e(s0 cur) s)
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
++  prow-items
  ::  the same, over ROWS of a multi-group product rather than elements of one
  ::  group -- one deferred conjunct per remaining context, in odometer order
  ::  (R3.0d)
  |=  [body=sem:sm gs=(list bgroup) rows=(list (list value:v)) e=eenv]
  ^-  (list pitem)
  ?~  rows  ~
  [[body (bind-vals e gs i.rows)] $(rows t.rows)]
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
    (psolve u.body.n cur part (with-lets lets.n e) acts p fil)
  =/  nm  name.op.n
  ?:  &(|(=(nm '$Label') =(nm '$Nop')) ?=(^ args.n))  $(n i.args.n)
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
    ::  R3.0d: several binders are the product here too. `contexts()` builds
    ::  ONE ContextEnumerator over every group, so the domains are evaluated in
    ::  the OUTER context and the odometer runs the leading binder fastest --
    ::  the same two facts the exhaustive path was measured on (R3.0c) -- with
    ::  each group additionally walked in its own drawn permutation
    =/  bs  (flatten-bound bound.n)
    =/  ds  (bound-domains bs (senv %next cur part e))
    ?:  ?=(%| -.ds)  [[%err p.ds] p]
    ?:  (lien p.ds |=(xs=(list value:v) ?=(~ xs)))  [[%none ~] p]
    =^  os  es.rs.p  (draw-orders p.ds es.rs.p)
    =/  body  (snag 0 args.n)
    =/  rows  (order-rows p.ds os)
    |-  ^-  [pres pst]
    ?~  rows  [[%none ~] p]
    =^  res  p  (psolve body cur part (bind-vals e bs i.rows) acts p fil)
    ?.  ?=(%none -.res)  [res p]
    $(rows t.rows)
  ::  a bounded universal is NOT randomized by tlc2: it solves the first
  ::  element now and defers the rest onto the continuation
  ?:  =(nm '$BoundedForall')
    ::  R3.0d: multi-binder here too, and NOT randomized -- tlc2 calls the
    ::  plain `contexts(pred, ...)`, i.e. `Ordering.NORMALIZED`, takes the
    ::  FIRST context now and defers the rest onto the ActionItemList. So this
    ::  is `+bind-rows` (no draw, no RNG consumed) with the head solved and the
    ::  tail deferred, which is what the single-binder code already did
    =/  bs  (flatten-bound bound.n)
    =/  ds  (bound-domains bs (senv %next cur part e))
    ?:  ?=(%| -.ds)  [[%err p.ds] p]
    =/  rows  (bind-rows p.ds)
    ?~  rows  (pnext cur part acts p fil)
    =/  body  (snag 0 args.n)
    =/  rest  (flop (prow-items body bs t.rows e))
    (psolve body cur part (bind-vals e bs i.rows) (weld rest acts) p fil)
  ?:  =(nm 'UNCHANGED')
    =/  names  (unchanged-vars (snag 0 args.n) psub.e ops.e)
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
  ?:  ?|  ?=(%user-op kind.op.n)
          ?&  ?=(?(%constant %new-constant) kind.op.n)
              !(~(has by vals.e) nm)
              (~(has by ops.e) nm)
      ==  ==
    =/  d  (~(get by ops.e) nm)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  (pfilter n cur part e acts p fil)
    ?.  =((lent params.u.d) (lent args.n))  (pfilter n cur part e acts p fil)
    ?:  =(0 fuel.e)  [[%err 0 'evaluation recursion/resource limit exceeded.'] p]
    =/  e2  (bind-psub e(fuel (dec fuel.e)) (senv %next cur part e) params.u.d args.n)
    ?:  ?=(%| -.e2)  [[%err p.e2] p]
    (psolve u.body.u.d cur part p.e2 acts p fil)
  (pfilter n cur part e acts p fil)
::
++  pred-bool
  ::  a state/action predicate BODY as a boolean under given states.
  ::  The carrier-discarding wrapper (R2.7.4.1's signature policy)
  |=  [body=sem:sm s0=state s1=state e=eenv]
  ^-  (each ? eval-err:v)
  (eval-bool body e(s0 s0, s1 s1))
::
++  pred-bool-rs
  ::  R2.7.4.3: the carrying form. A CONSTRAINT or an INVARIANT may contain a
  ::  `TLCSet`, and at the pin that write lands in the same static store the
  ::  next-state relation reads -- `Tool.isInModel` / `Tool.isValid` evaluate
  ::  under the ordinary evaluator with nothing special about the store
  |=  [body=sem:sm s0=state s1=state e=eenv rs=rst]
  ^-  bout
  (eval-bool-rs body e(s0 s0, s1 s1) rs)
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
