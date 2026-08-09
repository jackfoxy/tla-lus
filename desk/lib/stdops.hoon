/-  *tla-lus
/=  v   /lib/value
/=  sd  /lib/stdmods
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
  (silt ~[['Bags' 'SubBag'] ['Bags' 'Sum']])
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
    [['TLC' 'Permutations' 1] [| 0 |=(a=(list value:v) (permutations a))]]
    [['TLC' 'Print' 2] [| 0 |=(a=(list value:v) (print-op 'Print' a))]]
    [['TLC' 'PrintT' 1] [| 0 |=(a=(list value:v) (print-op 'PrintT' a))]]
    [['TLC' 'TLCSet' 2] [| 0 |=(a=(list value:v) (tlc-set a))]]
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
  [%& (normalize:v [%set (turn u.ps |=(pr=vpair:v d.pr))])]
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
  ?~  ps  [%& (normalize:v [%set fs])]
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
++  print-op
  ::  TLC!Print / TLC!PrintT write to TLC's console. Gall owns effects here
  ::  and the evaluation path has no output channel yet, so this is a typed
  ::  rejection naming what is missing — never a silent no-op that returns
  ::  the value (plan-2 invariant 8)
  |=  [nm=@t as=(list value:v)]
  ^-  eres
  :-  %|
  :-  0
  %^  rap  3  'unsupported StandardModule operator: TLC!'
  ~[nm '; it writes to the TLC console and this engine has no output channel']
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
++  tlc-get
  ::  TLCGet(k): a key the pin does not define is EC 2145, exactly as there;
  ::  a defined key would report engine state the evaluator cannot reach, so
  ::  it is a typed rejection naming the key rather than a plausible number
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'TLCGet expects one argument.']
  ?:  ?=(%int -.i.as)
    [%| 2.145 (rap 3 ~['TLCGet(' (crip (render:v i.as)) ') was undefined.'])]
  ?.  ?=(%str -.i.as)
    [%| (one-arg-error 'TLCGet' 'nonnegative integer' i.as)]
  ?.  (~(has in tlc-get-keys) p.i.as)
    [%| 2.145 (rap 3 ~['TLCGet(' p.i.as ') was undefined.'])]
  :-  %|
  :-  0
  %^  rap  3  'unsupported StandardModule operator: TLC!TLCGet; the key '
  ~[p.i.as ' reports engine state the evaluator cannot reach']
::
++  tlc-set
  ::  TLCSet(k, v) mutates engine state: a typed rejection, never a silent
  ::  TRUE
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* * ~] as)  [%| 0 'TLCSet expects two arguments.']
  :-  %|
  :-  0
  %^  rap  3  'unsupported StandardModule operator: TLC!TLCSet; '
  ~['it mutates engine state, which this evaluator does not own']
--
