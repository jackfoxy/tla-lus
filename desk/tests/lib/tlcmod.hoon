::  TLC module parity (unit 6C.5): the pure operators (Assert, ToString,
::  Permutations, SortSeq, :>, @@), and the typed rejections that stand in
::  for TLC's console output and engine state. Expectations come from
::  desk/test-data/stdops/{st-tlc,st-tlc-errors}.
/+  *test
/=  ne  /lib/node-eval
/=  so  /lib/stdops
/=  v   /lib/value
|%
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
++  test-tlc-get-register
  ::  an integer key reads the register store `TLCSet` writes. Nothing writes
  ::  it yet, so every index is unset -- the pin's EC 2145 for that index
  (tlc 'TLCGet(3)' "ERR: TLCGet(3) was undefined.")
::
++  test-tlc-set
  ::  R2.6.1 measured what the write IS -- a run-scoped register that
  ::  accumulates across state expansions -- and the reason it stays refused
  ::  is now that measurement rather than a generality
  %+  tlc  'TLCSet("exit", TRUE)'
  "ERR: unsupported StandardModule operator: TLC!TLCSet; it writes a run-scoped register the evaluator cannot carry out of an evaluation"
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
  ::  unit 9 owns TLC's RNG
  %+  tlc  'RandomElement({1, 2})'
  "ERR: unsupported StandardModule operator: TLC!RandomElement/1"
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
    ::  unit 9 owns TLC's RNG
    (expect-eq !>(%none) !>((binding-in:ne 'A' src 'RandomElement' 1)))
  ==
--
