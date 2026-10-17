/-  *tla-lus
/=  v   /lib/value
/=  sd  /lib/stdmods
/=  fpl  /lib/fingerprint
::  StandardModule override registry (PORT-COMPLETION-PLAN-2 unit 6C, C1.1).
::
::  tlc2 binds a Java method to a StandardModule operator by the operator's
::  *module* and *identifier* (SpecProcessor.processConstantDefns, with the
::  Java method name mapped through TLARegistry), never by a bare name; the
::  method's own parameter count is the arity. This is the Hoon equivalent:
::  one row per included operator, keyed [module name arity].
::
::  Two rules the vendored module texts make non-negotiable:
::
::  1. An override beats the TLA+ body. `Naturals.tla` defines `a+b == {a,b}`
::     and `Nat == {}` — deliberate dummies "overridden by TLC in the Java
::     class tlc2.module.Naturals" — so evaluating a StandardModule body that
::     the pin overrides silently produces garbage.
::  2. A StandardModule operator that is neither in this registry nor
::     explicitly body-evaluable (+body-ok) is a typed unsupported failure.
::     Falling through to its body would return that same garbage.
::
::  The classification of every reachable operator is generated into
::  desk/test-data/stdops/inventory.txt (subunit C1.0); this file implements
::  the `required` rows, subunit by subunit.
::
|%
::  +|  Registry Shape
::
+$  op-key   [module=@t name=@t arity=@ud]
+$  eres     (each value:v eval-err:v)
::  a native operator receives already-evaluated arguments, as a Java
::  MethodValue does. `lazy` marks the Evaluation-annotated overrides that
::  take unevaluated arguments (none yet — subunit C1.6); `level` is
::  MethodValue.minLevel.
+$  op-gate  $-((list value:v) eres)
+$  op-impl  [lazy=? level=@ud gate=op-gate]
::  the per-run registry view: the operator table, the set of module names
::  that are StandardModules (their bodies are dummies), and the operators
::  allowed to evaluate their vendored TLA+ body because the pin does not
::  override them. Built once per environment (+make-senv) — the table must
::  never be rebuilt inside an evaluation loop.
+$  senv
  $:  reg=(map op-key op-impl)
      stds=(set @t)
      bodies=(set [module=@t name=@t])
  ==
::
++  make-senv
  ^-  senv
  [registry standard-names body-ok]
::
++  standard-names
  ::  the vendored StandardModules, by name (lib/stdmods is generated from
  ::  the pinned tla2sany/StandardModules)
  ^-  (set @t)
  ~(key by standard-modules:sd)
::
++  body-ok
  ::  StandardModule operators the pin does NOT override, so their vendored
  ::  TLA+ definition is the behavior (inventory.txt class `body`)
  ^-  (set [@t @t])
  ::  R2.6.3: `TLCExt!AssertEq` joins them. It has NO Java override in the pin
  ::  -- its vendored body is `IF a # b THEN PrintT(..) /\ a = b ELSE a = b`,
  ::  over `PrintT` and `Assert`, both already implemented -- so evaluating the
  ::  definition IS the behavior, and a native arm would be a second copy of it
  (silt ~[['Bags' 'SubBag'] ['Bags' 'Sum'] ['TLCExt' 'AssertEq']])
::
++  lookup
  |=  [s=senv k=op-key]
  ^-  (unit op-impl)
  (~(get by reg.s) k)
::
++  is-standard
  |=  [s=senv mod=@t]
  ^-  ?
  (~(has in stds.s) mod)
::
++  body-allowed
  |=  [s=senv mod=@t nm=@t]
  ^-  ?
  (~(has in bodies.s) [mod nm])
::
++  unsupported
  ::  the typed rejection for a StandardModule operator with no native
  ::  implementation: it names the module, operator, and arity, and never
  ::  returns a value (plan-2 invariant 8)
  |=  k=op-key
  ^-  eval-err:v
  :-  0
  %^  rap  3  'unsupported StandardModule operator: '
  ~[module.k '!' name.k '/' (crip ((d-co:co 1) arity.k))]
::
::  +|  The Table
::
::  Every row is one Java override of the pinned tree. Subunit C1.1 seeds the
::  operators the bare-name `native-set` used to serve, now module- and
::  arity-qualified; C1.2-C1.5 fill in the rest.
::
++  registry
  ^-  (map op-key op-impl)
  %-  malt
  ^-  (list [op-key op-impl])
  :~
    ::  Naturals (C1.2: floored \div, positive-% divisor with a
    ::  non-negative remainder, Expt, and the 32-bit IntValue range)
    [['Naturals' '+' 2] [| 0 |=(a=(list value:v) (arith '+' a))]]
    [['Naturals' '-' 2] [| 0 |=(a=(list value:v) (arith '-' a))]]
    [['Naturals' '*' 2] [| 0 |=(a=(list value:v) (arith '*' a))]]
    [['Naturals' '^' 2] [| 0 |=(a=(list value:v) (arith '^' a))]]
    [['Naturals' '\\div' 2] [| 0 |=(a=(list value:v) (arith '\\div' a))]]
    [['Naturals' '%' 2] [| 0 |=(a=(list value:v) (arith '%' a))]]
    [['Naturals' '<' 2] [| 0 |=(a=(list value:v) (compare '<' a))]]
    [['Naturals' '>' 2] [| 0 |=(a=(list value:v) (compare '>' a))]]
    [['Naturals' '\\leq' 2] [| 0 |=(a=(list value:v) (compare '\\leq' a))]]
    [['Naturals' '\\geq' 2] [| 0 |=(a=(list value:v) (compare '\\geq' a))]]
    [['Naturals' '..' 2] [| 0 |=(a=(list value:v) (dotdot a))]]
    ::  unary minus. The pin declares it as `-.` in Integers; the generator
    ::  now canonicalizes a prefix `-` to `-.` (+canon-prefix-op, R1.3.5.1)
    ::  so the reachable key matches the pin exactly: [Integers '-.' 1]
    [['Integers' '-.' 1] [| 0 |=(a=(list value:v) (negate a))]]
    ::  Sequences
    [['Sequences' '\\o' 2] [| 0 |=(a=(list value:v) (concat a))]]
    [['Sequences' 'Len' 1] [| 0 |=(a=(list value:v) (seq-len a))]]
    [['Sequences' 'Head' 1] [| 0 |=(a=(list value:v) (seq-head a))]]
    [['Sequences' 'Tail' 1] [| 0 |=(a=(list value:v) (seq-tail a))]]
    [['Sequences' 'Append' 2] [| 0 |=(a=(list value:v) (seq-append a))]]
    [['Sequences' 'SubSeq' 3] [| 0 |=(a=(list value:v) (sub-seq a))]]
    ::  Bags (C1.4). The pin's messages name the infix operators as `(+)`
    ::  and `(-)`, and SetToBag reports itself as `BagToSet` — both are the
    ::  pinned text, reproduced rather than corrected
    [['Bags' 'EmptyBag' 0] [| 0 |=(a=(list value:v) (empty-bag a))]]
    [['Bags' 'IsABag' 1] [| 0 |=(a=(list value:v) (is-a-bag a))]]
    [['Bags' 'BagCardinality' 1] [| 0 |=(a=(list value:v) (bag-card a))]]
    [['Bags' 'BagIn' 2] [| 0 |=(a=(list value:v) (bag-in a))]]
    [['Bags' 'CopiesIn' 2] [| 0 |=(a=(list value:v) (copies-in a))]]
    [['Bags' '\\oplus' 2] [| 0 |=(a=(list value:v) (bag-cup a))]]
    [['Bags' '\\ominus' 2] [| 0 |=(a=(list value:v) (bag-diff a))]]
    [['Bags' '\\sqsubseteq' 2] [| 0 |=(a=(list value:v) (sq-subseteq a))]]
    [['Bags' 'BagUnion' 1] [| 0 |=(a=(list value:v) (bag-union a))]]
    [['Bags' 'BagToSet' 1] [| 0 |=(a=(list value:v) (bag-to-set a))]]
    [['Bags' 'SetToBag' 1] [| 0 |=(a=(list value:v) (set-to-bag a))]]
    ::  TLC's two function constructors (C1.5's module, landed here because
    ::  a bag literal is written with them)
    [['TLC' ':>' 2] [| 0 |=(a=(list value:v) (make-fcn a))]]
    [['TLC' '@@' 2] [| 0 |=(a=(list value:v) (combine-fcn a))]]
    ::  TLC (C1.5). The side-effecting and engine-state operators are typed
    ::  rejections that name what they would need, never silent no-ops
    [['TLC' 'Assert' 2] [| 0 |=(a=(list value:v) (assert-op a))]]
    [['TLC' 'ToString' 1] [| 0 |=(a=(list value:v) (to-string a))]]
    ::  R4.2f: the pure half of tla2tools' `Json` module (tlc2/module/Json.java,
    ::  which CI's module search puts ahead of CommunityModules' copy)
    [['Json' 'ToJson' 1] [| 0 |=(a=(list value:v) (json-str %node a))]]
    [['Json' 'ToJsonArray' 1] [| 0 |=(a=(list value:v) (json-str %array a))]]
    [['Json' 'ToJsonObject' 1] [| 0 |=(a=(list value:v) (json-str %object a))]]
    ::  R4.2f (user decision 2026-10-13): the two READERS are refused by name,
    ::  an approved difference: a file read is not part of a run's sources
    [['Json' 'JsonDeserialize' 1] [| 0 |=(a=(list value:v) (json-read-refused 'JsonDeserialize'))]]
    [['Json' 'ndJsonDeserialize' 1] [| 0 |=(a=(list value:v) (json-read-refused 'ndJsonDeserialize'))]]
    ::  R4.2h: CommunityModules' process and file surfaces, refused by name
    ::  (their TLA+ bodies are dummies; a run has no process and reads or
    ::  writes only through its request and artifacts)
    [['IOUtils' 'IOExec' 1] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'IOExec' 'it runs a process'))]]
    [['IOUtils' 'IOEnvExec' 2] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'IOEnvExec' 'it runs a process'))]]
    [['IOUtils' 'IOExecTemplate' 2] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'IOExecTemplate' 'it runs a process'))]]
    [['IOUtils' 'IOEnvExecTemplate' 3] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'IOEnvExecTemplate' 'it runs a process'))]]
    [['IOUtils' 'IOSerialize' 3] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'IOSerialize' 'it writes a file'))]]
    [['IOUtils' 'IODeserialize' 2] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'IODeserialize' 'it reads a file'))]]
    [['IOUtils' 'Serialize' 3] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'Serialize' 'it writes a file'))]]
    [['IOUtils' 'Deserialize' 2] [| 0 |=(a=(list value:v) (io-refused 'IOUtils' 'Deserialize' 'it reads a file'))]]
    [['CSV' 'CSVWrite' 3] [| 0 |=(a=(list value:v) (io-refused 'CSV' 'CSVWrite' 'it writes a file'))]]
    [['CSV' 'CSVWriteRecord' 4] [| 0 |=(a=(list value:v) (io-refused 'CSV' 'CSVWriteRecord' 'it writes a file'))]]
    [['CSV' 'CSVRead' 3] [| 0 |=(a=(list value:v) (io-refused 'CSV' 'CSVRead' 'it reads a file'))]]
    [['CSV' 'CSVRecords' 1] [| 0 |=(a=(list value:v) (io-refused 'CSV' 'CSVRecords' 'it reads a file'))]]
    [['TLC' 'Permutations' 1] [| 0 |=(a=(list value:v) (permutations a))]]
    ::  TLCExt!TLCNoOp is the identity function in the pin -- `return val` and
    ::  nothing else (R2.6.3)
    [['TLCExt' 'TLCNoOp' 1] [| 0 |=(a=(list value:v) (tlc-no-op a))]]
    ::  R2.7.10: the two plain value operators of the three `later:` surfaces.
    ::  `TLCEvalDefinition` is the third and is an `@Evaluation` override, so
    ::  it lives on the node-op path beside `TLCGet`
    [['TLCExt' 'TLCFP' 1] [| 0 |=(a=(list value:v) (tlc-fp a))]]
    [['TLCExt' 'TLCModelValue' 1] [| 0 |=(a=(list value:v) (tlc-model-value a))]]
  ==
::
::  FiniteSets!Cardinality and !IsFiniteSet are `node-op`s, not rows: their
::  argument is a SET, so it is evaluated as a lazy domain (a descriptor like
::  Nat must answer rather than be forced into a value).
::
::  +|  Diagnostics
::
::  The pinned message templates (tlc2.output.MP), with the TLC error code in
::  the `eval-err` code field. `Values.ppr` renders the offending value, and
::  the templates really do embed newlines — the oracle projection collapses
::  them, the compatibility layer documents it.
::
++  ordinal
  |=  i=@ud
  ^-  @t
  ?:(=(i 2) 'second' ?:(=(i 3) 'third' 'first'))
::
++  arg-error
  ::  "The <n> argument of <op> should be a[n] <what>, but instead it is:
  ::  \n<v>" — EC 2169 for tlc2's explicit checks, 2266 for its "an" variant,
  ::  and 2154 where the pin instead fails inside the MethodValue cast with
  ::  a message naming the Java signature (volatile; normalized here, see
  ::  compatibility.md)
  |=  [ec=@ud i=@ud op=@t what=@t an=? got=value:v]
  ^-  eval-err:v
  :-  ec
  %^  rap  3  'The '
  :~  (ordinal i)  ' argument of '  op  ' should be a'  ?:(an 'n ' ' ')
      what  ', but instead it is:\0a'  (crip (render:v got))
  ==
::
++  overflow
  ::  EC 2178: TLC integers are 32-bit Java ints
  |=  [op=@t x=@s y=@s]
  ^-  eval-err:v
  :-  2.178
  %^  rap  3  'Overflow when computing '
  ~[(crip (render-int:v x)) op (crip (render-int:v y))]
::
++  int-max  `@s`--2.147.483.647
++  int-min  `@s`-2.147.483.648
::
++  in-range
  ::  the value fits tlc2's IntValue (a Java int)
  |=  x=@s
  ^-  ?
  &(!(slth:v x int-min) !(slth:v int-max x))
::
::  +|  Naturals / Integers (subunit C1.2)
::
++  two-ints
  ::  the two integer arguments of a binary arithmetic/order operator. tlc2
  ::  declares the arithmetic methods over IntValue, so a non-integer fails
  ::  in the MethodValue cast with a message naming the Java signature; that
  ::  text is volatile, so the normalized argument-error message is used
  ::  (compatibility.md records the normalization)
  |=  [nm=@t as=(list value:v) ec=@ud]
  ^-  (each [x=@s y=@s] eval-err:v)
  ?.  ?=([* * ~] as)
    [%| 0 (rap 3 ~[nm ' expects two arguments.'])]
  ?.  ?=(%int -.i.as)    [%| (arg-error ec 1 nm 'integer' & i.as)]
  ?.  ?=(%int -.i.t.as)  [%| (arg-error ec 2 nm 'integer' & i.t.as)]
  [%& p.i.as p.i.t.as]
::
++  arith
  |=  [nm=@t as=(list value:v)]
  ^-  eres
  =/  ab  (two-ints nm as 2.154)
  ?:  ?=(%| -.ab)  ab
  =/  x  x.p.ab
  =/  y  y.p.ab
  ?:  =(nm '^')  (expt x y)
  ?:  =(nm '\\div')
    ::  EC 2179, and Java's floor correction: the quotient truncates toward
    ::  zero, then drops by one when it is negative and inexact
    ?:  =(y --0)  [%| 2.179 'The second argument of \\div is 0.']
    =/  q  (fra:si x y)
    =/  qq  ?:(&((slth:v q --0) !=((pro:si q y) x)) (dif:si q --1) q)
    [%& [%int qq]]
  ?:  =(nm '%')
    ::  tlc2 requires a POSITIVE divisor and returns a non-negative
    ::  remainder (a = b * (a \div b) + (a % b))
    ?.  (slth:v --0 y)  [%| (arg-error 2.169 2 nm 'positive number' | [%int y])]
    =/  r  (rem:si x y)
    [%& [%int ?:((slth:v r --0) (sum:si r y) r)]]
  ?.  |(=(nm '+') =(nm '-') =(nm '*'))
    [%| 0 (rap 3 ~['unsupported arithmetic operator: ' nm])]
  =/  r
    ?:  =(nm '+')  (sum:si x y)
    ?:  =(nm '-')  (dif:si x y)
    (pro:si x y)
  ?.  (in-range r)  [%| (overflow nm x y)]
  [%& [%int r]]
::
++  expt
  ::  tlc2.module.Naturals.Expt: a negative exponent is an argument error,
  ::  0^0 is undefined, and each multiplication is range-checked
  |=  [x=@s y=@s]
  ^-  eres
  ?:  (slth:v y --0)
    [%| (arg-error 2.169 2 '^' 'natural number' | [%int y])]
  ?:  =(y --0)
    ?:  =(x --0)  [%| 2.180 '0^0 is undefined.']
    [%& [%int --1]]
  =/  n  (abs:si y)
  =/  acc  x
  =/  i  1
  |-  ^-  eres
  ?:  (gte i n)  [%& [%int acc]]
  =/  nx  (pro:si acc x)
  ?.  (in-range nx)  [%| (overflow '^' x y)]
  $(acc nx, i +(i))
::
++  compare
  ::  tlc2 checks these explicitly (EC 2266, "an integer")
  |=  [nm=@t as=(list value:v)]
  ^-  eres
  =/  ab  (two-ints nm as 2.266)
  ?:  ?=(%| -.ab)  ab
  =/  x  x.p.ab
  =/  y  y.p.ab
  ?:  =(nm '<')      [%& [%bool (slth:v x y)]]
  ?:  =(nm '>')      [%& [%bool (slth:v y x)]]
  ?:  =(nm '\\leq')  [%& [%bool !(slth:v y x)]]
  ?:  =(nm '\\geq')  [%& [%bool !(slth:v x y)]]
  [%| 0 (rap 3 ~['unsupported comparison operator: ' nm])]
::
++  negate
  ::  Integers!-. — the unary minus, range-checked like the pin
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'unary minus expects one argument.']
  ?.  ?=(%int -.i.as)  [%| (arg-error 2.154 1 '-' 'integer' & i.as)]
  ::  only the minimum negates out of range; the pin prints the literal
  ::  "--2147483648" for it
  ?:  =(p.i.as int-min)  [%| 2.178 'Overflow when computing --2147483648']
  [%& [%int (dif:si --0 p.i.as)]]
::
++  set-descriptor
  ::  StandardModule operators that denote a SET rather than a value. tlc2
  ::  represents these as infinite UserValues; here they are lazy `sexp`
  ::  descriptors, so membership and \subseteq work while enumeration is a
  ::  typed non-enumerable failure. Used from a set-denoting position only —
  ::  as a plain value they are still a typed rejection (no UserValue kind).
  ::  Arguments arrive evaluated (Seq(S) carries its range)
  |=  [k=op-key as=(list value:v)]
  ^-  (unit sexp:v)
  ?:  =(k ['Naturals' 'Nat' 0])  `[%nats ~]
  ?:  =(k ['Integers' 'Int' 0])  `[%ints ~]
  ?:  =(k ['Sequences' 'Seq' 1])
    ?~(as ~ `[%seqs i.as])
  ~
::
++  is-descriptor
  ::  whether the key denotes a set (so a set position evaluates arguments
  ::  and builds a descriptor instead of a value)
  |=  k=op-key
  ^-  ?
  ?|  =(k ['Naturals' 'Nat' 0])
      =(k ['Integers' 'Int' 0])
      =(k ['Sequences' 'Seq' 1])
  ==
::
++  node-op
  ::  StandardModule operators the evaluator itself must run, because the
  ::  override needs something a value cannot carry: an OPERATOR argument
  ::  (tlc2 passes an OpValue and applies it), a lazy SET argument, or — for
  ::  the pin's `@Evaluation` overrides — the unevaluated node itself. The
  ::  implementation lives in node-eval, where the semantic nodes, the
  ::  environment, and the recursion budget are in scope; this table claims
  ::  the key and carries the same metadata a registry row does, so the
  ::  argument contract is recorded for every implemented operator
  |=  k=op-key
  ^-  (unit [tag=@tas lazy=? level=@ud])
  ?:  =(k ['Sequences' 'SelectSeq' 2])     `[%select-seq | 0]
  ?:  =(k ['Bags' 'BagOfAll' 2])           `[%bag-of-all | 0]
  ?:  =(k ['FiniteSets' 'Cardinality' 1])  `[%cardinality | 0]
  ?:  =(k ['FiniteSets' 'IsFiniteSet' 1])  `[%is-finite-set | 0]
  ?:  =(k ['TLC' 'SortSeq' 2])             `[%sort-seq | 0]
  ::  the one `@Evaluation` override in scope: tlc2 hands it the node, the
  ::  context, and the states, and it decides what to evaluate
  ?:  =(k ['TLC' 'TLCEval' 1])             `[%tlc-eval & 0]
  ::  TLCGet is `@Evaluation`-annotated too, at minLevel 1 (it is state-level,
  ::  so TLC never constant-folds it); the datum is carried and checked even
  ::  though this engine has no constant-folding pass
  ?:  =(k ['TLC' 'TLCGet' 1])              `[%tlc-get & 1]
  ::  R2.7.4.3: the REGISTER STORE. `TLCSet` is a plain `@TLAPlusOperator` in
  ::  the pin, not an `@Evaluation` one, but it belongs here rather than in the
  ::  registry because a registry gate is a PURE function of its argument
  ::  VALUES and this one WRITES: it needs the R2.7.4.1 carrier, which only the
  ::  evaluator holds. `TLCGetOrDefault` reads the same store, and
  ::  `TLCGetAndSet` reads-modifies-writes it through an operator argument.
  ::
  ::  `TLCGetAndSet` has no Java method at the pin at all -- it is a TLA+ body
  ::  in TLCExt.tla, `CHOOSE v \in {oldVal} : TLCSet(key, Op(oldVal, val))`.
  ::  The port implements it NATIVELY instead of evaluating that body, because
  ::  the body hides its write inside a CHOOSE and CHOOSE is below the
  ::  R2.7.4.1b carrier boundary -- running it would DROP the write silently,
  ::  which is the one outcome R2's acceptance forbids. Measured at the pin,
  ::  `TLCGetAndSet(1, Add, 10, 0)` returns 0, 10, 20 on successive
  ::  expansions while the register goes 10, 20, 30; the native arm reproduces
  ::  exactly that
  ::  R2.7.4.4: `TLC!RandomElement` DRAWS -- it advances the enumeration RNG
  ::  the carrier holds, and its argument is a SET, so it needs both the
  ::  carrier and the lazy-domain treatment `Cardinality` gets
  ?:  =(k ['TLC' 'RandomElement' 1])        `[%random-element | 0]
  ::  R4.2a: `Print` / `PrintT` WRITE the console at the moment of evaluation,
  ::  which here is a line on the carrier (`out`), so they are node-ops for the
  ::  same reason `TLCSet` is. Plain `@TLAPlusOperator`s at the pin
  ?:  =(k ['TLC' 'Print' 2])                `[%print | 0]
  ?:  =(k ['TLC' 'PrintT' 1])               `[%print-t | 0]
  ::  R4.2f: `JsonSerialize` / `ndJsonSerialize` WRITE a file at the pin; here
  ::  the file is a job artifact, written through the carrier (`files`)
  ?:  =(k ['Json' 'JsonSerialize' 2])       `[%json-serialize | 0]
  ::  R4.2c: CommunityModules' `IOUtils!IOEnv`, the process environment as a
  ::  record. A node-op because the value is the RUN's (the request's `env`),
  ::  which only the evaluator's env carries
  ?:  =(k ['IOUtils' 'IOEnv' 0])            `[%io-env | 0]
  ?:  =(k ['Json' 'ndJsonSerialize' 2])     `[%nd-json-serialize | 0]
  ?:  =(k ['TLC' 'TLCSet' 2])               `[%tlc-set | 0]
  ?:  =(k ['TLCExt' 'TLCGetOrDefault' 2])   `[%tlc-get-or-default | 0]
  ?:  =(k ['TLCExt' 'TLCGetAndSet' 4])      `[%tlc-get-and-set | 0]
  ::  TLCExt's non-debugger `@Evaluation` overrides (R2.6.3). All three receive
  ::  the unevaluated node, which is the whole point of each: `AssertError` has
  ::  to CATCH the argument's evaluation failure, `TLCCache` decides whether to
  ::  evaluate at all, and `TLCDefer` deliberately does not evaluate
  ::  R2.7.4.5: the `Randomization` module. All three DRAW, so all three ride
  ::  the carrier. `RandomSubset` and `RandomSetOfSubsets` are Java overrides
  ::  at the pin; `TestRandomSetOfSubsets` is NOT -- it is a TLA+ body,
  ::  `[i \in 1..5 |-> Cardinality(RandomSetOfSubsets(k, n, S))]`, whose five
  ::  draws sit inside a FUNCTION CONSTRUCTOR and under `Cardinality`, both
  ::  below the R2.7.4.1b carrier boundary. Evaluating that body would run one
  ::  draw sequence and report it five times, so it is implemented NATIVELY --
  ::  the same call the pin's own `RandomSetOfSubsets` makes, five times, on
  ::  the carrier. Identical reasoning to `TLCGetAndSet` in R2.7.4.3
  ?:  =(k ['Randomization' 'RandomSubset' 2])            `[%random-subset | 0]
  ?:  =(k ['Randomization' 'RandomSetOfSubsets' 3])      `[%random-set-of-subsets | 0]
  ?:  =(k ['Randomization' 'TestRandomSetOfSubsets' 3])  `[%test-rsos | 0]
  ?:  =(k ['TLCExt' 'AssertError' 2])      `[%assert-error & 0]
  ?:  =(k ['TLCExt' 'TLCCache' 2])         `[%tlc-cache & 0]
  ?:  =(k ['TLCExt' 'TLCDefer' 1])         `[%tlc-defer & 0]
  ::  R2.7.10: an `@Evaluation` override that resolves a definition BY NAME in
  ::  the ROOT module and evaluates it, so it needs the node and the env
  ?:  =(k ['TLCExt' 'TLCEvalDefinition' 1])  `[%tlc-eval-def & 0]
  ::  R2.7.14b: `TLCExt!CounterExample` is arity-0 and its vendored body is the
  ::  placeholder `TRUE`, so evaluating the definition is meaningless -- the pin
  ::  has an `@Evaluation` override that reads the value out of the evaluation
  ::  Context. It takes no arguments and needs only the env, which is why it is
  ::  a node-op rather than a registry gate
  ?:  =(k ['TLCExt' 'CounterExample' 0])   `[%counter-example & 1]
  ~
::
++  op-meta
  ::  the argument contract of an implemented operator: `lazy` is true only
  ::  where the pin uses an `@Evaluation` override (which receives the
  ::  unevaluated node); `level` is its `minLevel`. Both are checked against
  ::  the generated inventory by tools/gen-stdops-tests.py, so they cannot
  ::  drift from the annotations on the pinned methods
  |=  k=op-key
  ^-  (unit [lazy=? level=@ud])
  =/  n  (node-op k)
  ?^  n  `[lazy.u.n level.u.n]
  =/  r  (~(get by registry) k)
  ?~  r  ~
  `[lazy.u.r level.u.r]
::
++  dotdot
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 '.. expects two arguments.']
  ?.  &(?=(%int -.i.as) ?=(%int -.i.t.as))  [%| 0 'non-integer interval bound.']
  [%& [%intv p.i.as p.i.t.as]]
::
++  one-arg-error
  ::  EC 2283: "The argument of <op> should be a <what>, but instead it is:
  ::  \n<v>"
  |=  [op=@t what=@t got=value:v]
  ^-  eval-err:v
  :-  2.283
  %^  rap  3  'The argument of '
  ~[op ' should be a ' what ', but instead it is:\0a' (crip (render:v got))]
::
++  empty-seq-error
  ::  EC 2184
  |=  op=@t
  ^-  eval-err:v
  [2.184 (rap 3 ~['Attempted to apply ' op ' to the empty sequence.'])]
::
++  evaluating-error
  ::  EC 2182: "Evaluating an expression of the form <form> when s is not a
  ::  <what>:\n<v>" — the shape Append and \o report
  |=  [form=@t what=@t got=value:v]
  ^-  eval-err:v
  :-  2.182
  %^  rap  3  'Evaluating an expression of the form '
  :~  form  ' when s is not a '  what  ':\0a'  (crip (render:v got))
  ==
::
++  not-in-domain
  ::  EC 2183, with the pin's punctuation
  |=  [i=@ud op=@t s=value:v got=value:v]
  ^-  eval-err:v
  :-  2.183
  %^  rap  3  'The '
  :~  (ordinal i)  ' argument of '  op
      ' must be in the domain of its first argument:\0a'
      (crip (render:v s))  '\0a, but instead it is\0a'
      (crip (render:v got))
  ==
::
++  as-seq
  ::  the sequence view of a value (tuple, or a function with domain 1..n)
  |=  x=value:v
  ^-  (unit (list value:v))
  (to-tuple:v x)
::
++  str-chars
  ::  a string as its one-character values, so SubSeq can slice it
  |=  c=@t
  ^-  (list value:v)
  (turn (trip c) |=(ch=@tD `value:v`[%str (crip ~[ch])]))
::
++  concat
  ::  tlc2.module.Sequences.Concat: strings concatenate, sequences append;
  ::  the first non-sequence is reported as `s \o t`, the second as `t \o s`
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 '\\o expects two arguments.']
  ?:  ?=(%str -.i.as)
    ?.  ?=(%str -.i.t.as)
      [%| (evaluating-error 't \\o s' 'string' i.t.as)]
    [%& [%str (cat 3 p.i.as p.i.t.as)]]
  =/  a  (as-seq i.as)
  ?~  a  [%| (evaluating-error 's \\o t' 'sequence' i.as)]
  =/  b  (as-seq i.t.as)
  ?~  b  [%| (evaluating-error 't \\o s' 'sequence' i.t.as)]
  [%& [%seq (weld u.a u.b)]]
::
++  seq-len
  ::  a string has a length too (LL, 2013)
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'Len expects one argument.']
  ?:  ?=(%str -.i.as)  [%& [%int (sun:si (lent (trip p.i.as)))]]
  =/  t  (as-seq i.as)
  ?~  t  [%| (one-arg-error 'Len' 'sequence' i.as)]
  [%& [%int (sun:si (lent u.t))]]
::
++  seq-head
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'Head expects one argument.']
  =/  t  (as-seq i.as)
  ?~  t  [%| (one-arg-error 'Head' 'sequence' i.as)]
  ?~  u.t  [%| (empty-seq-error 'Head')]
  [%& i.u.t]
::
++  seq-tail
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'Tail expects one argument.']
  ?:  ?=(%str -.i.as)
    =/  cs  (trip p.i.as)
    ?~  cs  [%| (empty-seq-error 'Tail')]
    [%& [%str (crip t.cs)]]
  =/  t  (as-seq i.as)
  ?~  t  [%| (one-arg-error 'Tail' 'sequence' i.as)]
  ?~  u.t  [%| (empty-seq-error 'Tail')]
  [%& [%seq t.u.t]]
::
++  seq-append
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 'Append expects two arguments.']
  =/  t  (as-seq i.as)
  ?~  t  [%| (evaluating-error 'Append(s, v)' 'sequence' i.as)]
  [%& [%seq (snoc u.t i.t.as)]]
::
++  sub-seq
  ::  tlc2.module.Sequences.SubSeq, including its string form: beg > end is
  ::  the empty result BEFORE any range check, then each bound must lie in
  ::  the domain (EC 2183)
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * * ~] as)  [%| 0 'SubSeq expects three arguments.']
  =/  s  i.as
  =/  m  i.t.as
  =/  n  i.t.t.as
  =/  str=?  ?=(%str -.s)
  =/  t=(unit (list value:v))
    ?:  ?=(%str -.s)  `(str-chars p.s)
    (as-seq s)
  ?~  t  [%| (arg-error 2.169 1 'SubSeq' 'sequence' | s)]
  ?.  ?=(%int -.m)  [%| (arg-error 2.169 2 'SubSeq' 'natural number' | m)]
  ?.  ?=(%int -.n)  [%| (arg-error 2.169 3 'SubSeq' 'natural number' | n)]
  ?:  (slth:v p.n p.m)
    [%& ?:(str [%str ''] [%seq ~])]
  =/  ln  (sun:si (lent u.t))
  ?:  |((slth:v p.m --1) (slth:v ln p.m))
    [%| (not-in-domain 2 'SubSeq' s m)]
  ?:  |((slth:v p.n --1) (slth:v ln p.n))
    [%| (not-in-domain 3 'SubSeq' s n)]
  =/  beg  (dec (abs:si p.m))
  =/  cnt  (add 1 (sub (abs:si p.n) (abs:si p.m)))
  =/  els  (scag cnt (slag beg u.t))
  ?.  str  [%& [%seq els]]
  :-  %&
  :-  %str
  %+  roll  (flop els)
  |=([e=value:v acc=@t] ?:(?=(%str -.e) (cat 3 p.e acc) acc))
::
++  wrong-value-error
  ::  EC 2176: "Applying <op> to the following value,\nwhich is not <what>:
  ::  \n<v>"
  |=  [op=@t what=@t got=value:v]
  ^-  eval-err:v
  :-  2.176
  %^  rap  3  'Applying '
  :~  op  ' to the following value,\0awhich is not '  what  ':\0a'
      (crip (render:v got))
  ==
::
++  make-fcn
  ::  TLC!:> — the one-point function [x \in {d} |-> e]
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 ':> expects two arguments.']
  [%& [%fcn ~[[i.as i.t.as]]]]
::
++  combine-fcn
  ::  TLC!@@ — merge two functions; the LEFT operand wins a collision
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 '@@ expects two arguments.']
  =/  pa  (to-fcn-pairs:v i.as)
  ?~  pa  [%| (arg-error 2.169 1 '@@' 'function' | i.as)]
  =/  pb  (to-fcn-pairs:v i.t.as)
  ?~  pb  [%| (arg-error 2.169 2 '@@' 'function' | i.t.as)]
  =/  extra
    %+  skim  u.pb
    |=(pr=vpair:v ?=(~ (bag-lookup d.pr u.pa)))
  [%& (normalize:v [%fcn (weld u.pa extra)])]
::
::  +|  Bags (subunit C1.4)
::
::  A bag is tlc2's FcnRcdValue with positive integer counts, so every
::  operator starts from `to-fcn-pairs` (Value.toFcnRcd) and compares domain
::  points by value equality, never by rendering.
::
++  empty-bag
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=(~ as)  [%| 0 'EmptyBag expects no arguments.']
  [%& [%fcn ~]]
::
++  bag-of
  |=  x=value:v
  ^-  (unit (list vpair:v))
  (to-fcn-pairs:v x)
::
++  positive-count
  |=  x=value:v
  ^-  ?
  &(?=(%int -.x) (slth:v --0 p.x))
::
++  bag-lookup
  ::  the count of `e` in the bag's pairs, by value equality
  |=  [e=value:v ps=(list vpair:v)]
  ^-  (unit value:v)
  ?~  ps  ~
  ?:  (equal:v e d.i.ps)  `r.i.ps
  $(ps t.ps)
::
++  is-a-bag
  ::  MAK 02/23/2018: a non-function is FALSE, not an error
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'IsABag expects one argument.']
  =/  ps  (bag-of i.as)
  ?~  ps  [%& [%bool |]]
  [%& [%bool (levy u.ps |=(pr=vpair:v (positive-count r.pr)))]]
::
++  bag-card
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'BagCardinality expects one argument.']
  =/  ps  (bag-of i.as)
  ?~  ps
    [%| (wrong-value-error 'BagCardinality' 'a function with a finite domain' i.as)]
  =|  n=@s
  =/  l  u.ps
  |-  ^-  eres
  ?~  l  [%& [%int n]]
  ?.  (positive-count r.i.l)
    [%| (wrong-value-error 'BagCardinality' 'a bag' i.as)]
  ?>  ?=(%int -.r.i.l)
  $(l t.l, n (sum:si n p.r.i.l))
::
++  bag-in
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 'BagIn expects two arguments.']
  =/  ps  (bag-of i.t.as)
  ?~  ps  [%| (arg-error 2.169 2 'BagIn' 'bag' | i.t.as)]
  =/  hit  (bag-lookup i.as u.ps)
  ?~  hit  [%& [%bool |]]
  ?.  ?=(%int -.u.hit)  [%| (arg-error 2.169 2 'BagIn' 'bag' | i.t.as)]
  [%& [%bool (slth:v --0 p.u.hit)]]
::
++  copies-in
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 'CopiesIn expects two arguments.']
  =/  ps  (bag-of i.t.as)
  ?~  ps  [%| (arg-error 2.169 2 'CopiesIn' 'bag' | i.t.as)]
  =/  hit  (bag-lookup i.as u.ps)
  ?~  hit  [%& [%int --0]]
  ?.  ?=(%int -.u.hit)  [%| (arg-error 2.169 2 'CopiesIn' 'bag' | i.t.as)]
  [%& u.hit]
::
++  both-bags
  ::  the two operands of an infix bag operator, with the pin's operator
  ::  spelling in the diagnostic
  |=  [op=@t as=(list value:v) need-bag=?]
  ^-  (each [a=(list vpair:v) b=(list vpair:v)] eval-err:v)
  ?.  ?=([* * ~] as)
    [%| 0 (rap 3 ~[op ' expects two arguments.'])]
  =/  pa  (bag-of i.as)
  =/  pb  (bag-of i.t.as)
  ?~  pa  [%| (arg-error 2.169 1 op 'bag' | i.as)]
  ?~  pb  [%| (arg-error 2.169 2 op 'bag' | i.t.as)]
  ?.  ?|  !need-bag
          &((levy u.pa |=(p=vpair:v (positive-count r.p))))
      ==
    [%| (arg-error 2.169 1 op 'bag' | i.as)]
  ?.  ?|  !need-bag
          &((levy u.pb |=(p=vpair:v (positive-count r.p))))
      ==
    [%| (arg-error 2.169 2 op 'bag' | i.t.as)]
  [%& u.pa u.pb]
::
++  bag-cup
  ::  b1 (+) b2: counts add; the pin names this operator `(+)`
  |=  as=(list value:v)
  ^-  eres
  =/  ab  (both-bags '(+)' as &)
  ?:  ?=(%| -.ab)  ab
  =/  out
    =/  l  a.p.ab
    =|  acc=(list vpair:v)
    |-  ^-  (list vpair:v)
    ?~  l  (flop acc)
    =/  other  (bag-lookup d.i.l b.p.ab)
    =/  n
      ?~  other  r.i.l
      ?:  ?&(?=(%int -.r.i.l) ?=(%int -.u.other))
        `value:v`[%int (sum:si p.r.i.l p.u.other)]
      r.i.l
    $(l t.l, acc [[d.i.l n] acc])
  =/  extra
    %+  skim  b.p.ab
    |=(pr=vpair:v ?=(~ (bag-lookup d.pr a.p.ab)))
  [%& (normalize:v [%fcn (weld out extra)])]
::
++  bag-diff
  ::  b1 (-) b2: counts subtract, non-positive results drop out
  |=  as=(list value:v)
  ^-  eres
  =/  ab  (both-bags '(-)' as |)
  ?:  ?=(%| -.ab)  ab
  =/  out
    =/  l  a.p.ab
    =|  acc=(list vpair:v)
    |-  ^-  (list vpair:v)
    ?~  l  (flop acc)
    ?.  ?=(%int -.r.i.l)  $(l t.l)
    =/  other  (bag-lookup d.i.l b.p.ab)
    =/  n
      ?~  other  p.r.i.l
      ?:  ?=(%int -.u.other)  (dif:si p.r.i.l p.u.other)
      p.r.i.l
    ?.  (slth:v --0 n)  $(l t.l)
    $(l t.l, acc [[d.i.l [%int n]] acc])
  [%& (normalize:v [%fcn out])]
::
++  sq-subseteq
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 '\\sqsubseteq expects two arguments.']
  =/  pa  (bag-of i.as)
  ?~  pa
    [%| (wrong-value-error '\\sqsubseteq' 'a function with a finite domain' i.as)]
  =/  pb  (bag-of i.t.as)
  ?~  pb
    [%| (wrong-value-error '\\sqsubseteq' 'a function with a finite domain' i.t.as)]
  =/  l  u.pa
  |-  ^-  eres
  ?~  l  [%& [%bool &]]
  ?.  ?=(%int -.r.i.l)  $(l t.l)
  =/  other  (bag-lookup d.i.l u.pb)
  =/  n
    ?~  other  p.r.i.l
    ?:  ?=(%int -.u.other)  (dif:si p.r.i.l p.u.other)
    p.r.i.l
  ?:  (slth:v --0 n)  [%& [%bool |]]
  $(l t.l)
::
++  bag-to-set
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'BagToSet expects one argument.']
  =/  ps  (bag-of i.as)
  ?~  ps
    [%| (wrong-value-error 'BagToSet' 'a function with a finite domain' i.as)]
  [%& (normalize:v [%set %set-enum (turn u.ps |=(pr=vpair:v d.pr))])]
::
++  set-to-bag
  ::  the pin's message really does say BagToSet here (a copy-paste in
  ::  tlc2.module.Bags); the text is reproduced, not corrected
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'SetToBag expects one argument.']
  ?.  (set-like:v i.as)
    [%| (wrong-value-error 'BagToSet' 'a function with a finite domain' i.as)]
  =/  es  (set-elems:v (normalize:v i.as))
  [%& (normalize:v [%fcn (turn es |=(e=value:v `vpair:v`[e [%int --1]]))])]
::
++  bag-union
  ::  BagUnion(S): S a finite set of bags; identical bags collapse, since
  ::  the set is normalized first (MAK 02/20/2018)
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'BagUnion expects one argument.']
  ?.  (set-like:v i.as)
    [%| (wrong-value-error 'BagUnion' 'a finite enumerable set' i.as)]
  =/  es  (set-elems:v (normalize:v i.as))
  ?~  es  (empty-bag ~)
  ?~  t.es  [%& i.es]
  =|  acc=(list vpair:v)
  ::  widen: `es` is narrowed to a two-or-more list by the guards above
  =/  l=(list value:v)  es
  |-  ^-  eres
  ?~  l  [%& (normalize:v [%fcn (flop acc)])]
  =/  ps  (bag-of i.l)
  ?~  ps
    [%| 2.177 (rap 3 ~['Attempted to apply BagUnion to the following set, whose\0aelement is not a bag:\0a' (crip (render:v i.as))])]
  =/  merged
    =/  m  u.ps
    =/  a  acc
    |-  ^-  (list vpair:v)
    ?~  m  a
    =/  hit  (bag-lookup d.i.m a)
    ?~  hit  $(m t.m, a [i.m a])
    =/  n
      ?:  ?&(?=(%int -.r.i.m) ?=(%int -.u.hit))
        `value:v`[%int (sum:si p.r.i.m p.u.hit)]
      r.i.m
    %=  $
      m  t.m
      a  [[d.i.m n] (skip a |=(pr=vpair:v (equal:v d.pr d.i.m)))]
    ==
  $(l t.l, acc merged)
::  +|  TLC Module (subunit C1.5)
::
++  assert-op
  ::  TLC!Assert: TRUE passes through, anything else is EC 2132 naming the
  ::  second argument
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 'Assert expects two arguments.']
  ?:  ?&(?=(%bool -.i.as) p.i.as)  [%& i.as]
  :-  %|
  :-  2.132
  %^  rap  3  'The first argument of Assert evaluated to FALSE; '
  ~['the second argument was: ' (crip (render:v i.t.as))]
::
++  io-refused
  ::  R4.2h: a CommunityModules process or file operator, refused by name
  |=  [mod=@t nm=@t why=@t]
  ^-  eres
  :-  %|
  :-  0
  %+  rap  3
  :~  'unsupported CommunityModules operator: '  mod  '!'  nm  '; '  why
      ', and a run has no process and touches no file outside its request'
  ==
::
++  json-read-refused
  ::  R4.2f: `JsonDeserialize` / `ndJsonDeserialize` read a FILE by a path
  ::  relative to tlc2's working directory. A run here reads only the sources
  ::  its request names, so the operator is refused by name (approved
  ::  difference, compatibility.md), never answered with an invented value
  |=  nm=@t
  ^-  eres
  :-  %|
  :-  0
  %+  rap  3
  :~  'unsupported StandardModule operator: Json!'  nm
      '; it reads a file, and a run reads only the sources its request names'
  ==
::
++  json-str
  ::  R4.2f: `ToJson` / `ToJsonArray` / `ToJsonObject` -- the value as Gson's
  ::  compact JSON text, a string value
  |=  [k=?(%node %array %object) as=(list value:v)]
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'expects one argument.']
  =/  r
    ?-  k
      %node    (json-node i.as)
      %array   (json-array i.as)
      %object  (json-object i.as)
    ==
  ?:  ?=(%| -.r)  [%| 0 p.r]
  [%& [%str (crip p.r)]]
::
++  json-node
  ::  R4.2f: `Json.getNode` -- a record is an object, a tuple an array, a
  ::  string or model value a JSON string, an integer a number, a boolean a
  ::  boolean, a function an object (an ARRAY when its domain is 1..n), any
  ::  finite set an array of its normalized elements
  |=  x=value:v
  ^-  (each tape @t)
  ?-  -.x
    %rec    (json-object x)
    %seq    (json-array x)
    %str    [%& (json-quote p.x)]
    %model  [%& (json-quote p.x)]
    %int    [%& (render:v x)]
    %bool   [%& ?:(p.x "true" "false")]
    %fcn    (json-object x)
    %set    (json-array x)
    %intv   (json-array x)
  ==
::
++  json-array
  ::  R4.2f: `Json.getArrayNode`
  |=  x=value:v
  ^-  (each tape @t)
  =/  els=(unit (list value:v))
    ?+  -.x  ~
      %seq   `p.x
      %set   `(set-elems:v (normalize:v x))
      %intv  `(set-elems:v (normalize:v x))
      %fcn   ?.((json-seq-fcn x) ~ `(turn p.x |=(q=vpair:v r.q)))
    ==
  ?~  els
    ?:  ?=(%fcn -.x)  (json-object x)
    [%| (json-unsupported x)]
  =/  ns  (json-list u.els)
  ?:  ?=(%| -.ns)  ns
  [%& :(weld "[" (join-json p.ns) "]")]
::
++  json-object
  ::  R4.2f: `Json.getObjectNode`: a record by its fields; a TUPLE by its
  ::  0-based positions ("0", "1", ...); a function by its domain (a string key
  ::  as itself, any other as its `toString`), unless its domain is 1..n, in
  ::  which case it is an array
  |=  x=value:v
  ^-  (each tape @t)
  =/  kvs=(unit (list [k=tape v=value:v]))
    ?+  -.x  ~
        %rec
      `(turn p.x |=(f=vfield:v [(trip k.f) v.f]))
        %seq
      =|  i=@ud
      =/  es  p.x
      =|  out=(list [k=tape v=value:v])
      |-  ^-  (unit (list [k=tape v=value:v]))
      ?~  es  `(flop out)
      $(es t.es, i +(i), out [[(a-co:co i) i.es] out])
        %fcn
      ?:  (json-seq-fcn x)  ~
      %-  some
      %+  turn  p.x
      |=  q=vpair:v
      :_  r.q
      ?:(?=(%str -.d.q) (trip p.d.q) (render:v d.q))
    ==
  ?~  kvs
    ?:  &(?=(%fcn -.x) (json-seq-fcn x))  (json-array x)
    [%| (json-unsupported x)]
  =|  out=(list tape)
  =/  ks  u.kvs
  |-  ^-  (each tape @t)
  ?~  ks  [%& :(weld "\{" (join-json (flop out)) "}")]
  =/  n  (json-node v.i.ks)
  ?:  ?=(%| -.n)  n
  $(ks t.ks, out [:(weld (json-quote (crip k.i.ks)) ":" p.n) out])
::
++  json-seq-fcn
  ::  `Json.isValidSequence`: every domain point an integer, and the domain
  ::  exactly 1..n in order
  |=  x=value:v
  ^-  ?
  ?.  ?=(%fcn -.x)  |
  =/  i  1
  =/  ps  p.x
  |-  ^-  ?
  ?~  ps  &
  ?.  ?=(%int -.d.i.ps)  |
  ?.  =(d.i.ps [%int (sun:si i)])  |
  $(ps t.ps, i +(i))
::
++  json-list
  |=  vs=(list value:v)
  ^-  (each (list tape) @t)
  =|  out=(list tape)
  |-  ^-  (each (list tape) @t)
  ?~  vs  [%& (flop out)]
  =/  n  (json-node i.vs)
  ?:  ?=(%| -.n)  n
  $(vs t.vs, out [p.n out])
::
++  join-json
  |=  ts=(list tape)
  ^-  tape
  ?~  ts  ~
  ?~  t.ts  i.ts
  :(weld i.ts "," $(ts t.ts))
::
++  json-unsupported
  |=  x=value:v
  ^-  @t
  (rap 3 ~['Cannot convert value: unsupported value type ' (crip (render:v x))])
::
++  json-quote
  ::  Gson's string escaping (`JsonWriter.string`, not HTML-safe): `"` and `\`
  ::  escaped, \t \b \n \r \f by name, every other control character below
  ::  0x20 as \u00XX (byte-wise: Gson's escapes of U+2028/U+2029 are not
  ::  reproduced)
  |=  t=@t
  ^-  tape
  =/  cs  (trip t)
  =|  out=tape
  |-  ^-  tape
  ?~  cs  :(weld "\"" (flop out) "\"")
  =/  c  i.cs
  =/  rep=tape
    ?:  =(c '"')   "\\\""
    ?:  =(c '\\')  "\\\\"
    ?:  =(c '\09')  "\\t"
    ?:  =(c '\08')  "\\b"
    ?:  =(c '\0a')  "\\n"
    ?:  =(c '\0d')  "\\r"
    ?:  =(c '\0c')  "\\f"
    ?:  (lth c 0x20)
      =/  h  ((x-co:co 4) c)
      (weld "\\u" h)
    [c ~]
  $(cs t.cs, out (weld (flop rep) out))
::
++  to-string
  ::  TLC!ToString: the canonical rendering, as a string value
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'ToString expects one argument.']
  [%& [%str (crip (render:v i.as))]]
::
++  permutations
  ::  TLC!Permutations(S): every bijection of a finite set onto itself, as
  ::  functions. The empty set has one permutation, the empty function
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'Permutations expects one argument.']
  ?.  (set-like:v i.as)
    [%| (wrong-value-error 'Permutations' 'a finite set' i.as)]
  =/  es  (set-elems:v (normalize:v i.as))
  =/  ps  (orderings es)
  =|  fs=(list value:v)
  |-  ^-  eres
  ?~  ps  [%& (normalize:v [%set %set-enum fs])]
  $(ps t.ps, fs [[%fcn (zip-pairs es i.ps)] fs])
::
++  zip-pairs
  |=  [ds=(list value:v) rs=(list value:v)]
  ^-  (list vpair:v)
  ?~  ds  ~
  ?~  rs  ~
  [[i.ds i.rs] $(ds t.ds, rs t.rs)]
::
++  drop-eq
  ::  the elements of `vs` that do not equal `x`
  |=  [x=value:v vs=(list value:v)]
  ^-  (list value:v)
  =|  out=(list value:v)
  |-  ^-  (list value:v)
  ?~  vs  (flop out)
  ?:  (equal:v x i.vs)  $(vs t.vs)
  $(vs t.vs, out [i.vs out])
::
++  orderings
  ::  every ordering of a list, deterministically. Hand-rolled on purpose:
  ::  the wet list gates (turn/skip/zing) over the recursive `value` mold
  ::  fuse-loop the zuse-408 mold compiler, which shows up as the loom
  ::  filling rather than as a type error
  |=  vs=(list value:v)
  ^-  (list (list value:v))
  ?~  vs  ~[~]
  =|  out=(list (list value:v))
  =/  l=(list value:v)  vs
  |-  ^-  (list (list value:v))
  ?~  l  out
  =/  subs  ^$(vs (drop-eq i.l vs))
  =/  o2
    =/  ss  subs
    =/  acc  out
    |-  ^-  (list (list value:v))
    ?~  ss  acc
    $(ss t.ss, acc [[i.l i.ss] acc])
  $(l t.l, out o2)
::
++  tlc-get-keys
  ::  the named TLCGet values the pin defines (tlc2.module.TLCGetSet)
  ^-  (set @t)
  %-  silt
  ^-  (list @t)
  :~  'diameter'  'distinct'  'queue'  'duration'  'generated'  'level'
      'config'  'spec'  'coverage'  'action'  'install'  'id'  'behavior'
      'all'  'all:named'  'mode'  'deadlock'  'seed'  'fingerprint'
      'worker'  'traces'  'depth'  'aril'  'sched'  'revision'  'stats'
      'exit'  'pause'
  ==
::
::  what tlc2's statistic keys read, at the moment of evaluation (R2.6.1).
::  Every field is something the port's own search cursor already holds; none
::  of it is new engine state -- which is the correction this unit made to its
::  own row. `level` is `s0.getLevel()`, the height of the state being expanded
::  (0 in a constant or initial-predicate context) and NOT monotone, where
::  `diameter` (`TLCTrace.getLevelForReporting()`) is
+$  tlc-run
  $:  ::  which engine is running. `TLCExt!TLCDefer` is the one operator whose
      ::  BEHAVIOR differs between them at the pin -- measured, its deferred
      ::  expression is never executed under BFS (`execCallable` is called by
      ::  the Simulation and Exploration workers, not by `ModelChecker`) and IS
      ::  executed under `-simulate` (R2.6.3)
      sim=?
      level=@ud
      ::  the four counters, `~` where they are not reconstructible. The
      ::  trace-label re-solve is the case that needs this: it knows each trace
      ::  state's LEVEL (its position) but not the search counts at the moment
      ::  that state was generated, and inventing zeros there would answer
      ::  `TLCGet("generated")` with a plausible wrong number. Absent, those
      ::  keys raise EC 2145 -- which is exactly what the pin does when no
      ::  checker is running
      counts=(unit [diameter=@ud distinct=@ud queued=@ud generated=@ud])
  ==
::
++  tlc-stat-keys
  ::  the keys R2.6.1 ANSWERS: each reads a number the port's own search cursor
  ::  already holds, so none of them needs engine state the evaluator lacks --
  ::  which is the correction R2.6.1's measurement made to its own row
  ^-  (set @t)
  (silt ~['level' 'diameter' 'distinct' 'queue' 'generated'])
::
++  tlc-get
  ::  TLCGet(k). `run` is the live statistics, `~` outside a checking run.
  ::
  ::  Three answers, and the split is tlc2's own:
  ::    * a key the pin does not define at all      -> EC 2145
  ::    * a statistic key, inside a run             -> the number
  ::    * a statistic key with no checker running   -> EC 2145, because that is
  ::      where `TLCGlobals.mainChecker` is null and the pin throws
  ::      TLC_MODULE_TLCGET_UNDEFINED
  ::  Everything else keeps its typed rejection naming what is missing.
  ::
  ::  `level` is the exception that needs no checker: `TLCGetStringValue` tests
  ::  `EvalControl.isConst/isInit` FIRST and returns `INIT_LEVEL - 1` = 0 before
  ::  it ever touches `mainChecker`
  |=  $:  as=(list value:v)  run=(unit tlc-run)
          regs=(map @ud value:v)  named=(map @t value:v)
      ==
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'TLCGet expects one argument.']
  ?:  ?=(%int -.i.as)
    ::  R2.7.4.3: an integer key reads the run-scoped register store `TLCSet`
    ::  writes (`IdThread.getLocalValue`). Only an UNSET index is EC 2145 now
    ::  -- measured at the pin, `TLCGet(3)` with nothing written reports
    ::  `TLCGet(3) was undefined.`, and a written index answers its value.
    ::  A NEGATIVE index is the argument error, not the undefined one:
    ::  `TLCGetSet.TLCGetEval` guards `idx >= 0` and falls through to
    ::  TLC_MODULE_ONE_ARGUMENT_ERROR otherwise
    ?:  (syn:si p.i.as)
      =/  ix  (abs:si p.i.as)
      =/  hit  (~(get by regs) ix)
      ?~  hit
        [%| 2.145 (rap 3 ~['TLCGet(' (crip (render:v i.as)) ') was undefined.'])]
      [%& u.hit]
    [%| (one-arg-error 'TLCGet' 'nonnegative integer' i.as)]
  ?.  ?=(%str -.i.as)
    [%| (one-arg-error 'TLCGet' 'nonnegative integer' i.as)]
  ::  R2.7.7.4a: a NAMED register read. Measured at the pin, an unset one is
  ::  EC 2145 with the key UNQUOTED: `TLCGet(s:nope) was undefined.`
  ?:  (named-key p.i.as)
    =/  hit  (~(get by named) p.i.as)
    ?~  hit
      [%| 2.145 (rap 3 ~['TLCGet(' p.i.as ') was undefined.'])]
    [%& u.hit]
  ::  the per-worker aggregate: a RECORD keyed by register name whose values
  ::  are SEQUENCES, one element per worker (`("s:c" :> <<2>>)` measured).
  ::  This engine is single-worker by design, so every sequence has length 1
  ?:  =('all:named' p.i.as)
    :-  %&
    :-  %fcn
    %+  turn  ~(tap by named)
    |=([k=@t v=value:v] [[%str k] [%seq ~[v]]])
  ?.  (~(has in tlc-get-keys) p.i.as)
    [%| 2.145 (rap 3 ~['TLCGet(' p.i.as ') was undefined.'])]
  ::  level is answered with or without a checker
  ?:  =('level' p.i.as)
    [%& %int (sun:si ?~(run 0 level.u.run))]
  ?.  (~(has in tlc-stat-keys) p.i.as)
    :-  %|
    :-  0
    %^  rap  3  'unsupported StandardModule operator: TLC!TLCGet; the key '
    ?:  =('duration' p.i.as)
      ~[p.i.as ' reads the wall clock, which no reproducible run may observe']
    ~[p.i.as ' reports engine state the evaluator cannot reach']
  ?~  run
    [%| 2.145 (rap 3 ~['TLCGet(' p.i.as ') was undefined.'])]
  =/  cs  counts.u.run
  ?~  cs
    [%| 2.145 (rap 3 ~['TLCGet(' p.i.as ') was undefined.'])]
  =/  n=@ud
    ?+  p.i.as  0
      %diameter   diameter.u.cs
      %distinct   distinct.u.cs
      %queue      queued.u.cs
      %generated  generated.u.cs
    ==
  [%& %int (sun:si n)]
::
++  tlc-fp
  ::  TLCExt!TLCFP(v) — the value's FP64 fingerprint, downcast (R2.7.10).
  ::  `FP64.Hash(long fp)` is literally `(int) fp`, so the answer is the LOW 32
  ::  BITS AS A SIGNED int, and the port's `+fp-value` is the same FP64 over
  ::  the same canonical byte encoding.
  ::
  ::  Reproducible under `-fp 0` ONLY, and that is the pin's own property, not
  ::  a port limitation: `FP64.New()` takes its polynomial from the `-fp`
  ::  index, so an unseeded run answers differently every time -- measured,
  ::  `TLCFP(3)` gave 661005754 and then 1287323929 across two runs of the same
  ::  jar, and -244908333 twice under `-fp 0`. The same precondition
  ::  R2.7.4.4's RNG carries
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'TLCFP expects one argument.']
  =/  fp  (fp-value:fpl i.as)
  ::  the low 32 bits, read as a two's-complement signed integer
  =/  lo  (mod fp (bex 32))
  :-  %&
  :-  %int
  ?:  (gte lo (bex 31))  (dif:si (sun:si lo) (sun:si (bex 32)))
  (sun:si lo)
::
++  tlc-model-value
  ::  TLCExt!TLCModelValue(s) — `ModelValue.add(name)` (R2.7.10). tlc2 INTERNS
  ::  it; the port's model value IS its name (`tlc-value-model`'s approved
  ::  difference), so there is nothing to intern and the answer is the value
  ::  itself. A non-string argument is the pin's one-argument error
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'TLCModelValue expects one argument.']
  ?.  ?=(%str -.i.as)
    [%| (one-arg-error 'ModelValue' 'string' i.as)]
  [%& %model p.i.as]
::
++  tlc-no-op
  ::  TLCExt!TLCNoOp(v) == v. `tlcNoOp` is `return val;` -- the pin uses it to
  ::  defeat constant folding, which this evaluator does not do, so the identity
  ::  is the whole behavior
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'TLCNoOp expects one argument.']
  [%& i.as]
::
++  named-key
  ::  a NAMED register key: tlc2's `TLCGetSet.NAMED_REGISTER_PREFIX` is the
  ::  literal `s:`, and measured, nothing else counts -- `TLCSet("plain", 7)`
  ::  is the positional argument error at the pin, not a named write
  |=  k=@t
  ^-  ?
  =('s:' (end [3 2] k))
::
++  tlc-set
  ::  TLC!TLCSet(i, v) — the run-scoped, worker-local REGISTER STORE
  ::  (`IdThread.setLocalValue`), read back by `TLCGet(i)` and
  ::  `TLCExt!TLCGetOrDefault(i, d)`. Returns TRUE, so it composes as a
  ::  conjunct.
  ::
  ::  MEASURED at the pin (R2.7.4.3), and every one of these is a corpus case:
  ::    * the store ACCUMULATES across state expansions --
  ::      `TLCSet(0, TLCGet(0) + 1)` in a next-state relation prints
  ::      100, 101, 102, 103, and an `Init` write is still there in `Next`;
  ::    * the write is visible to a LATER CONJUNCT of the SAME evaluation --
  ::      `TLCSet(0, 42) /\ x' = TLCGet(0)` builds the state x = 42;
  ::    * it is NOT part of the checked state, so it never enters a
  ::      fingerprint; two states differing only in the register are the
  ::      same state.
  ::
  ::  The index must be a nonnegative integer; the pin guards `idx >= 0` and
  ::  otherwise raises the argument error, which is the same shape `TLCGet`
  ::  uses. A non-integer index is that error too
  ::  R2.7.7.4a: a string key beginning `s:` is a NAMED register
  ::  (`TLCGetSet.NAMED_REGISTER_PREFIX`), written into the second half of the
  ::  store. Measured, the prefix is the whole rule: `TLCSet("plain", 7)` is
  ::  still the positional argument error at the pin
  |=  [as=(list value:v) regs=(map @ud value:v) named=(map @t value:v)]
  ^-  [r=eres regs=(map @ud value:v) named=(map @t value:v)]
  ?.  ?=([* * ~] as)  [[%| 0 'TLCSet expects two arguments.'] regs named]
  ::  the STRING keys are not register indices at all: `"exit"` stops the
  ::  checker and `"pause"` blocks the search on stdin. Both are real tlc2
  ::  capabilities, so neither may be reported as a bad argument -- they are
  ::  refused BY NAME, which is what separates "this port has not built it"
  ::  from "your spec is wrong" (R2.1)
  ?:  ?&(?=(%str -.i.as) =('exit' p.i.as))
    :+  :-  %|
        :-  0
        %^  rap  3  'unsupported StandardModule operator: TLC!TLCSet("exit"); it '
        ~['stops the checker mid-run, which this engine has no control channel for']
      regs
    named
  ?:  ?&(?=(%str -.i.as) =('pause' p.i.as))
    :+  :-  %|
        :-  0
        %^  rap  3  'unsupported StandardModule operator: TLC!TLCSet("pause"); it '
        ~['suspends the search until stdin is read, and no reproducible run may block on a console']
      regs
    named
  ::  anything else is the pin's own POSITIONAL argument error -- measured,
  ::  `TLCGetSet.TLCSet` throws TLC_MODULE_ARGUMENT_ERROR with
  ::  `{"first", "TLCSet", "nonnegative integer", …}`
  ::  the NAMED register write
  ?:  ?&(?=(%str -.i.as) (named-key p.i.as))
    [[%& %bool &] regs (~(put by named) p.i.as i.t.as)]
  ?.  ?=(%int -.i.as)
    [[%| (arg-error 2.169 1 'TLCSet' 'nonnegative integer' | i.as)] regs named]
  ?.  (syn:si p.i.as)
    [[%| (arg-error 2.169 1 'TLCSet' 'nonnegative integer' | i.as)] regs named]
  [[%& %bool &] (~(put by regs) (abs:si p.i.as) i.t.as) named]
::
++  random-element-error
  ::  the pin's message when the argument is not a finite set
  |=  got=value:v
  ^-  eval-err:v
  (wrong-value-error 'RandomElement' 'a finite set' got)
::
++  rsub-arg-error
  ::  `Randomization`'s argument errors are all EC 2169
  ::  `TLC_MODULE_ARGUMENT_ERROR` on the ordinary template, but the offending
  ::  value arrives ALREADY RENDERED: an infinite descriptor has no `value:v`
  ::  to hold, and the pin prints its name bare (`Nat`, not `"Nat"`).
  ::
  ::  Two of the pin's `what` strings are reproduced VERBATIM including a
  ::  quirk: `RandomSubset`'s second argument passes "a finite set" into a
  ::  template that already supplies the article, so the pin prints "should be
  ::  a a finite set" -- measured, not inferred. `RandomSetOfSubsets`'s third
  ::  passes "finite set" and reads correctly. Reproducing the doubled article
  ::  is the difference between matching the pin and improving on it
  |=  [i=@ud op=@t what=@t got=@t]
  ^-  eval-err:v
  :-  2.169
  %^  rap  3  'The '
  :~  (ordinal i)  ' argument of '  op  ' should be a '
      what  ', but instead it is:\0a'  got
  ==
::
++  rsos-too-many-error
  ::  the pin's `numberOfPicks` bound: "nonnegative integer that is smaller
  ::  than the subset's size of 2^<|S|>", and note the value it prints is the
  ::  INTEGER `numberOfPicks`, not `Values.ppr` of the argument node
  |=  [k=@ud size=@ud]
  ^-  eval-err:v
  =/  what=@t
    %^  rap  3  'nonnegative integer that is smaller than the subset\'s size of 2^'
    ~[(crip (render-int:v (sun:si size)))]
  (rsub-arg-error 1 'RandomSetOfSubsets' what (crip (render-int:v (sun:si k))))
::
++  tlc-get-or-default
  ::  TLCExt!TLCGetOrDefault(i, d) — the same read as `TLCGet(i)` but an unset
  ::  index answers `d` instead of raising EC 2145. Measured at the pin:
  ::  77 before the write, 9 after it.
  ::
  ::  The pin does NOT guard `idx >= 0` here (unlike `TLCGet`), and a key that
  ::  is neither an integer nor a named-register string falls through to
  ::  `return defVal` -- so an unusable key is the DEFAULT, not an error. The
  ::  named-register form (`"s:..."`) is a separate surface this does not claim
  |=  [as=(list value:v) regs=(map @ud value:v) named=(map @t value:v)]
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 'TLCGetOrDefault expects two arguments.']
  ::  R2.7.7.4a: the named half. An unset named key is still the DEFAULT here,
  ::  where `TLCGet` raises EC 2145 -- measured both ways
  ?:  ?&(?=(%str -.i.as) (named-key p.i.as))
    =/  hit  (~(get by named) p.i.as)
    ?~(hit [%& i.t.as] [%& u.hit])
  ?.  ?=(%int -.i.as)  [%& i.t.as]
  ?.  (syn:si p.i.as)  [%& i.t.as]
  =/  hit  (~(get by regs) (abs:si p.i.as))
  ?~(hit [%& i.t.as] [%& u.hit])
--
