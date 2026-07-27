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
    ::  unary minus. The pin declares it as `-.` in Integers; the WU3
    ::  generator names the node `-` with one argument, so the reachable key
    ::  is [Naturals '-' 1] (C1.2 revisits the naming with the oracle)
    [['Naturals' '-' 1] [| 0 |=(a=(list value:v) (negate a))]]
    ::  Sequences
    [['Sequences' '\\o' 2] [| 0 |=(a=(list value:v) (concat a))]]
    [['Sequences' 'Len' 1] [| 0 |=(a=(list value:v) (seq-len a))]]
    [['Sequences' 'Head' 1] [| 0 |=(a=(list value:v) (seq-head a))]]
    [['Sequences' 'Tail' 1] [| 0 |=(a=(list value:v) (seq-tail a))]]
    [['Sequences' 'Append' 2] [| 0 |=(a=(list value:v) (seq-append a))]]
    [['Sequences' 'SubSeq' 3] [| 0 |=(a=(list value:v) (sub-seq a))]]
    ::  FiniteSets
    [['FiniteSets' 'Cardinality' 1] [| 0 |=(a=(list value:v) (cardinality a))]]
  ==
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
  ::  StandardModule operators the evaluator itself must run, because an
  ::  argument is an OPERATOR rather than a value (tlc2 passes an OpValue and
  ::  applies it). The implementation lives in node-eval, where the semantic
  ::  nodes, the environment, and the recursion budget are in scope; this
  ::  table only claims the key so resolution stays in one place
  |=  k=op-key
  ^-  (unit @tas)
  ?:  =(k ['Sequences' 'SelectSeq' 2])  `%select-seq
  ~
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
++  cardinality
  |=  as=(list value:v)
  ^-  eres
  ?.  ?=([* ~] as)  [%| 0 'Cardinality expects one argument.']
  ?.  (set-like:v i.as)  [%| 0 'Cardinality expects a set.']
  [%& [%int (sun:si (lent (set-elems:v (normalize:v i.as))))]]
--
