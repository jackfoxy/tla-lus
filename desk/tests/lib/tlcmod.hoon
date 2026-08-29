::  TLC module parity (unit 6C.5): the pure operators (Assert, ToString,
::  Permutations, SortSeq, :>, @@), and the typed rejections that stand in
::  for TLC's console output and engine state. Expectations come from
::  desk/test-data/stdops/{st-tlc,st-tlc-errors}.
/+  *test
/=  ne  /lib/node-eval
/=  so  /lib/stdops
/=  v   /lib/value
|%
++  tlcext
  ::  the same driver over a module that also EXTENDS TLCExt, for the two
  ::  register surfaces that live there (R2.7.4.3)
  |=  [body=@t want=tape]
  ^-  tang
  =/  src=@t
    %-  crip
    ;:  weld
      "---- MODULE A ----\0a"
      "EXTENDS Integers, Sequences, FiniteSets, TLC, TLCExt\0a"
      "Add(a, b) == a + b\0a"
      "Expr == "  (trip body)  "\0a===="
    ==
  =/  r  (eval-module-def:ne 'A' (malt ~[['A' src]]) 'Expr')
  %+  expect-eq  !>(want)
  !>  ^-  tape
  ?:  ?=(%| -.r)  (weld "ERR: " (trip msg.p.r))
  (render:v p.r)
::
++  tlc
  ::  an expression in a module that EXTENDS TLC, with helper operators for
  ::  the operator-argument cases and a model-value constant set
  |=  [body=@t want=tape]
  ^-  tang
  =/  src=@t
    %-  crip
    ;:  weld
      "---- MODULE A ----\0a"
      "EXTENDS Integers, Sequences, FiniteSets, TLC\0a"
      "Lt(x, y) == x < y\0a"
      "Bad(x, y) == x\0a"
      "Expr == "  (trip body)  "\0a===="
    ==
  =/  r  (eval-module-def:ne 'A' (malt ~[['A' src]]) 'Expr')
  =/  got
    ?:  ?=(%| -.r)  (weld "ERR: " (trip msg.p.r))
    (render:v p.r)
  (expect-eq !>(want) !>(got))
::
::  +|  Assert
::
++  test-assert-true   (tlc 'Assert(TRUE, "never")' "TRUE")
::
++  test-assert-false
  %+  tlc  'Assert(FALSE, "boom")'
  "ERR: The first argument of Assert evaluated to FALSE; the second argument was: \"boom\""
::
++  test-assert-non-boolean
  %+  tlc  'Assert(1, "boom")'
  "ERR: The first argument of Assert evaluated to FALSE; the second argument was: \"boom\""
::
::  +|  ToString
::
++  test-to-string-int   (tlc 'ToString(42)' "\"42\"")
++  test-to-string-set   (tlc 'ToString({1, 2})' "\"\{1, 2}\"")
++  test-to-string-seq   (tlc 'ToString(<<1, 2>>)' "\"<<1, 2>>\"")
++  test-to-string-bool  (tlc 'ToString(TRUE)' "\"TRUE\"")
::
::  +|  Function constructors
::
++  test-make-fcn     (tlc '1 :> "a"' "<<\"a\">>")
++  test-combine      (tlc '(1 :> "a") @@ (2 :> "b")' "<<\"a\", \"b\">>")
++  test-combine-left
  ::  the LEFT operand wins a domain collision
  (tlc '(1 :> "a") @@ (1 :> "b")' "<<\"a\">>")
::
++  test-combine-not-function
  %+  tlc  '1 @@ 2'
  "ERR: The first argument of @@ should be a function, but instead it is:\0a1"
::
::  +|  SortSeq (an operator argument, applied by the evaluator)
::
++  test-sort-seq        (tlc 'SortSeq(<<3, 1, 2>>, Lt)' "<<1, 2, 3>>")
++  test-sort-seq-sorted  (tlc 'SortSeq(<<1, 2, 3>>, Lt)' "<<1, 2, 3>>")
++  test-sort-seq-empty  (tlc 'SortSeq(<<>>, Lt)' "<<>>")
++  test-sort-seq-dups   (tlc 'SortSeq(<<2, 1, 2>>, Lt)' "<<1, 2, 2>>")
::
++  test-sort-seq-not-sequence
  %+  tlc  'SortSeq({1, 2}, Lt)'
  "ERR: The first argument of SortSeq should be a natural number, but instead it is:\0a\{1, 2}"
::
++  test-sort-seq-not-boolean
  %+  tlc  'SortSeq(<<1, 2>>, Bad)'
  "ERR: The second argument of SortSeq should be a boolean function, but instead it is:\0a<Operator>"
::
::  +|  Permutations (one implementation, shared with SYMMETRY)
::
++  test-permutations-empty  (tlc 'Permutations({})' (trip '{<<>>}'))
::
++  test-permutations-count
  ::  3 elements give 3! = 6 permutations
  (tlc 'Cardinality(Permutations({1, 2, 3}))' "6")
::
++  test-permutations-pair
  (tlc 'Permutations({1, 2})' (trip '{<<1, 2>>, <<2, 1>>}'))
::
++  test-permutations-not-a-set
  %+  tlc  'Permutations(3)'
  "ERR: Applying Permutations to the following value,\0awhich is not a finite set:\0a3"
::
::  +|  Side effects and engine state: typed rejections, never silent no-ops
::
++  test-print
  %+  tlc  'Print("hello", 7)'
  "ERR: unsupported StandardModule operator: TLC!Print; it writes to the TLC console and this engine has no output channel"
::
++  test-print-t
  %+  tlc  'PrintT("hello")'
  "ERR: unsupported StandardModule operator: TLC!PrintT; it writes to the TLC console and this engine has no output channel"
::
++  test-tlc-get-level-outside-a-run
  ::  R2.6.1: `level` is answered with or WITHOUT a checker. `TLCGetStringValue`
  ::  tests `EvalControl.isConst/isInit` first and returns `INIT_LEVEL - 1` = 0
  ::  before it ever touches `mainChecker`, so a constant context is 0, not an
  ::  error. Inside a search it is the level of the state being expanded --
  ::  covered by `tests/lib/mc` `tlcget-level`, whose state graph is BUILT from
  ::  it and matches the pin byte-for-byte
  (tlc 'TLCGet("level")' "0")
::
++  test-tlc-get-stat-outside-a-run
  ::  a statistic key with no checker running is EC 2145, which is what the pin
  ::  does when `TLCGlobals.mainChecker` is null
  (tlc 'TLCGet("distinct")' "ERR: TLCGet(distinct) was undefined.")
::
++  test-tlc-get-duration-refused
  ::  a key the pin DEFINES and this engine will not answer: the wall clock is
  ::  not something a reproducible run may observe. Refused by name, never a
  ::  plausible number (R2.1)
  %+  tlc  'TLCGet("duration")'
  "ERR: unsupported StandardModule operator: TLC!TLCGet; the key duration reads the wall clock, which no reproducible run may observe"
::
++  test-tlc-get-unreachable-key-refused
  ::  a key the pin defines and this engine cannot reach, distinct from the
  ::  wall-clock case above and from an undefined key below
  %+  tlc  'TLCGet("worker")'
  "ERR: unsupported StandardModule operator: TLC!TLCGet; the key worker reports engine state the evaluator cannot reach"
::
++  test-tlc-get-unknown-key
  ::  the pin's own EC 2145 for a key it does not define
  (tlc 'TLCGet("zork")' "ERR: TLCGet(zork) was undefined.")
::
++  test-tlc-get-register-unset
  ::  R2.7.4.3: an integer key reads the register store `TLCSet` writes. An
  ::  index nothing has written is still the pin's EC 2145 FOR THAT INDEX --
  ::  measured, `TLCGet(3)` on a fresh run reports `TLCGet(3) was undefined.`
  ::  The blanket "every integer index is undefined" of R2.6.1 is gone; only
  ::  an unset one is.
  ::
  ::  A constant-context evaluation like this one has an EMPTY store, so the
  ::  answer is the same text it always was -- what changed is that a run
  ::  which HAS written the index now answers the value, which the
  ::  `tests/lib/mc` cases `tlcset-graph` / `tlcset-same-eval` pin by BUILDING
  ::  THE STATE GRAPH out of it
  (tlc 'TLCGet(3)' "ERR: TLCGet(3) was undefined.")
::
++  test-tlc-set-returns-true
  ::  R2.7.4.3: `TLCSet` is implemented. It answers TRUE so it composes as a
  ::  conjunct, which is how every spec uses it
  (tlc 'TLCSet(0, 42)' "TRUE")
::
++  test-tlc-set-then-get
  ::  the write is visible to a LATER CONJUNCT of the SAME evaluation --
  ::  measured at the pin, `TLCSet(0, 42) /\ x' = TLCGet(0)` builds x = 42.
  ::  Here the same fact in one constant expression
  (tlc 'TLCSet(0, 42) /\\ TLCGet(0) = 42' "TRUE")
::
++  test-tlc-set-non-integer-key
  ::  a key that is neither a nonnegative integer nor one of the pin's string
  ::  surfaces is the pin's own POSITIONAL argument error -- measured,
  ::  `TLCGetSet.TLCSet` throws TLC_MODULE_ARGUMENT_ERROR with
  ::  `{"first", "TLCSet", "nonnegative integer", …}`
  %+  tlc  'TLCSet("zork", TRUE)'
  "ERR: The first argument of TLCSet should be a nonnegative integer, but instead it is:\0a\"zork\""
::
++  test-tlc-set-exit-refused
  ::  `TLCSet("exit", TRUE)` is a REAL tlc2 capability -- it stops the checker
  ::  mid-run -- so it must not be reported as a bad argument. Refused by
  ::  name, which is what separates "this port has not built it" from "your
  ::  spec is wrong" (R2.1)
  %+  tlc  'TLCSet("exit", TRUE)'
  "ERR: unsupported StandardModule operator: TLC!TLCSet(\"exit\"); it stops the checker mid-run, which this engine has no control channel for"
::
++  test-tlc-set-pause-refused
  %+  tlc  'TLCSet("pause", TRUE)'
  "ERR: unsupported StandardModule operator: TLC!TLCSet(\"pause\"); it suspends the search until stdin is read, and no reproducible run may block on a console"
::
++  test-tlc-get-or-default-unset
  ::  TLCExt!TLCGetOrDefault(i, d) answers `d` on an unset index instead of
  ::  raising EC 2145 -- measured 77 before the write, 9 after it
  (tlcext 'TLCGetOrDefault(5, 77)' "77")
::
++  test-tlc-get-or-default-set
  (tlcext 'TLCSet(5, 9) /\\ TLCGetOrDefault(5, 77) = 9' "TRUE")
::
++  test-tlc-get-and-set
  ::  TLCExt!TLCGetAndSet(key, Op, val, default) returns the OLD value and
  ::  stores `Op(old, val)`. The pin has no Java method for it -- TLCExt.tla
  ::  defines it as `CHOOSE v \\in {oldVal} : TLCSet(key, Op(oldVal, val))` --
  ::  and the port implements it NATIVELY, because that body hides its write
  ::  inside a CHOOSE, which is below the R2.7.4.1b carrier boundary and would
  ::  drop it silently. Measured at the pin: 0, then 10, then 20, with the
  ::  register at 10, 20, 30
  (tlcext 'TLCGetAndSet(1, Add, 10, 0)' "0")
::
++  test-tlc-get-and-set-stores
  (tlcext 'TLCGetAndSet(1, Add, 10, 0) = 0 /\\ TLCGetOrDefault(1, 99) = 10' "TRUE")
::
::  +|  Excluded operators stay typed rejections
::
++  test-java-time
  (tlc 'JavaTime' "ERR: unsupported StandardModule operator: TLC!JavaTime/0")
::
++  test-any
  (tlc 'Any' "ERR: unsupported StandardModule operator: TLC!Any/0")
::
++  test-random-element
  ::  R2.7.4.4: `RandomElement` draws through the enumeration generator on the
  ::  R2.7.4.1 carrier. A CONSTANT-context evaluation like this one starts from
  ::  an unseeded (0) carrier, so the draw is deterministic here; what the draw
  ::  DEPENDS on -- the per-predecessor reseed `fingerPrint ^ seed`, and the
  ::  fact that two draws in one evaluation come from one advancing stream --
  ::  is pinned by the `tests/lib/mc` cases `rnd-one-draw` / `rnd-two-draws`
  ::  / `rnd-two-draws-alt`, whose STATE COUNTS differ by seed
  (tlc 'RandomElement({1, 2}) \\in {1, 2}' "TRUE")
::
++  test-random-element-advances
  ::  two draws in ONE evaluation come from one ADVANCING stream, so they are
  ::  independent draws rather than the same value twice -- a fresh-per-eval
  ::  generator makes `a` and `b` equal. Measured at the pin from the other
  ::  side: `x' = RandomElement(0..2) /\\ y' = RandomElement(0..2)` produced 2
  ::  and 1 under `-seed 12345`. Over a 1.000-element domain a coincidence is
  ::  not what a passing run means, but the STATE COUNTS in the `rnd-two-draws`
  ::  mc cases are the load-bearing evidence; this arm localizes the failure
  (tlc 'LET a == RandomElement(0..999) b == RandomElement(0..999) IN a # b' "TRUE")
::
++  test-random-element-not-a-set
  ::  the pin's TLC_MODULE_APPLYING_TO_WRONG_VALUE (EC 2176), naming "a finite
  ::  set" -- what `toSetEnum` returning null gets, the same arm `Permutations`
  ::  uses. Measured at the pin on a NON-SET argument rather than on an
  ::  infinite one: `Nat` and `Seq(S)` in an argument position are both this
  ::  port's own approved differences (there is no UserValue kind, so the
  ::  argument is rejected before `RandomElement` ever runs), and asserting
  ::  the pin's wording there would assert something no build can produce
  %+  tlc  'RandomElement(3)'
  "ERR: Applying RandomElement to the following value,\0awhich is not a finite set:\0a3"
::
::  +|  Bindings
::
++  test-bindings
  =/  src
    %-  malt
    :~  :-  'A'
        (crip "---- MODULE A ----\0aEXTENDS Integers, TLC\0aExpr == 1\0a====")
    ==
  ;:  weld
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'Assert' 2)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'ToString' 1)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'Permutations' 1)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'SortSeq' 2)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'Print' 2)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'TLCGet' 1)))
    ::  C1.6 implements the Evaluation contract with TLCEval
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'TLCEval' 1)))
    ::  R2.7.4.4 implements the draw; it is a node-op, so it binds
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'RandomElement' 1)))
  ==
--
