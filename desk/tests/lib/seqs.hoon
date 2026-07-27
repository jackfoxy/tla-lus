::  Sequences parity (unit 6C.3): the tuple/function duality of tlc2's
::  Value.toTuple, string forms, SubSeq, SelectSeq through the
::  operator-valued-parameter path, and Seq(S) as a non-enumerable set.
::  Expectations come from desk/test-data/stdops/{st-sequences,st-seq-errors}.
/+  *test
/=  ne  /lib/node-eval
/=  so  /lib/stdops
/=  v   /lib/value
|%
++  ex
  |=  [txt=@t want=tape]
  ^-  tang
  (expect-eq !>(want) !>((eval-dbg:ne txt)))
::
++  defs
  ::  a module with helper operators, so an operator argument has something
  ::  to resolve to (LAMBDA is not in the WU3 graph)
  |=  [body=tape want=tape]
  ^-  tang
  =/  src=@t
    %-  crip
    ;:  weld
      "---- MODULE A ----\0a"
      "EXTENDS Integers, Sequences, FiniteSets\0a"
      "Pos(x) == x > 1\0a"
      "NotBool(x) == x\0a"
      "Expr == "  body  "\0a===="
    ==
  =/  r  (eval-module-def:ne 'A' (malt ~[['A' src]]) 'Expr')
  =/  got
    ?:  ?=(%| -.r)  (weld "ERR: " (trip msg.p.r))
    (render:v p.r)
  (expect-eq !>(want) !>(got))
::
::  +|  Len / Head / Tail: tuples, functions, and strings
::
++  test-len          (ex 'Len(<<1, 2, 3>>)' "3")
++  test-len-empty    (ex 'Len(<<>>)' "0")
++  test-len-function  (ex 'Len([i \\in 1..3 |-> i * i])' "3")
++  test-len-string   (ex 'Len("abc")' "3")
++  test-head         (ex 'Head(<<1, 2, 3>>)' "1")
++  test-head-function  (ex 'Head([i \\in 1..3 |-> i * i])' "1")
++  test-tail         (ex 'Tail(<<1, 2, 3>>)' "<<2, 3>>")
++  test-tail-string  (ex 'Tail("abc")' "\"bc\"")
++  test-append       (ex 'Append(<<1, 2>>, 3)' "<<1, 2, 3>>")
++  test-append-function
  (ex 'Append([i \\in 1..2 |-> i], 9)' "<<1, 2, 9>>")
::
++  test-concat       (ex '<<1, 2>> \\o <<3>>' "<<1, 2, 3>>")
++  test-concat-empty  (ex '<<>> \\o <<3>>' "<<3>>")
++  test-concat-string  (ex '"ab" \\o "cd"' "\"abcd\"")
::
::  +|  Argument Errors (tlc2's exact templates)
::
++  test-head-empty
  (ex 'Head(<<>>)' "ERR: Attempted to apply Head to the empty sequence.")
::
++  test-tail-empty
  (ex 'Tail(<<>>)' "ERR: Attempted to apply Tail to the empty sequence.")
::
++  test-tail-empty-string
  (ex 'Tail("")' "ERR: Attempted to apply Tail to the empty sequence.")
::
++  test-len-not-sequence
  %+  ex  'Len(1..2)'
  "ERR: The argument of Len should be a sequence, but instead it is:\0a1..2"
::
++  test-append-not-sequence
  %+  ex  'Append(1..2, 3)'
  "ERR: Evaluating an expression of the form Append(s, v) when s is not a sequence:\0a1..2"
::
++  test-concat-not-sequence
  ::  `\o` binds tighter than `..`, so the interval needs its parentheses
  %+  ex  '<<1>> \\o (1..2)'
  "ERR: Evaluating an expression of the form t \\o s when s is not a sequence:\0a1..2"
::
++  test-concat-string-mixed
  %+  ex  '"ab" \\o <<1>>'
  "ERR: Evaluating an expression of the form t \\o s when s is not a string:\0a<<1>>"
::
::  +|  SubSeq
::
++  test-subseq        (ex 'SubSeq(<<1, 2, 3>>, 2, 3)' "<<2, 3>>")
++  test-subseq-one    (ex 'SubSeq(<<1, 2, 3>>, 1, 1)' "<<1>>")
++  test-subseq-empty  (ex 'SubSeq(<<1, 2, 3>>, 3, 2)' "<<>>")
++  test-subseq-string  (ex 'SubSeq("abcd", 2, 3)' "\"bc\"")
++  test-subseq-string-empty  (ex 'SubSeq("abcd", 3, 2)' "\"\"")
++  test-subseq-function  (ex 'SubSeq([i \\in 1..3 |-> i], 2, 3)' "<<2, 3>>")
::
++  test-subseq-high-out-of-domain
  %+  ex  'SubSeq(<<1, 2>>, 1, 5)'
  "ERR: The third argument of SubSeq must be in the domain of its first argument:\0a<<1, 2>>\0a, but instead it is\0a5"
::
++  test-subseq-low-out-of-domain
  %+  ex  'SubSeq(<<1, 2>>, 0, 1)'
  "ERR: The second argument of SubSeq must be in the domain of its first argument:\0a<<1, 2>>\0a, but instead it is\0a0"
::
++  test-subseq-non-integer
  %+  ex  'SubSeq(<<1, 2>>, "a", 1)'
  "ERR: The second argument of SubSeq should be a natural number, but instead it is:\0a\"a\""
::
++  test-subseq-not-sequence
  %+  ex  'SubSeq(1..3, 1, 2)'
  "ERR: The first argument of SubSeq should be a sequence, but instead it is:\0a1..3"
::
::  +|  SelectSeq (an operator argument, applied by the evaluator)
::
++  test-selectseq        (defs "SelectSeq(<<1, 2, 3>>, Pos)" "<<2, 3>>")
++  test-selectseq-none   (defs "SelectSeq(<<1>>, Pos)" "<<>>")
++  test-selectseq-empty  (defs "SelectSeq(<<>>, Pos)" "<<>>")
++  test-selectseq-function
  (defs "SelectSeq([i \\in 1..3 |-> i], Pos)" "<<2, 3>>")
::
++  test-selectseq-not-boolean
  %+  defs  "SelectSeq(<<1, 2>>, NotBool)"
  "ERR: The second argument of SelectSeq should be a boolean-valued operator, but instead it is:\0a<Operator NotBool>"
::
++  test-selectseq-not-sequence
  %+  defs  "SelectSeq(1..2, Pos)"
  "ERR: The first argument of SelectSeq should be a sequence, but instead it is:\0a1..2"
::
::  +|  Seq(S): membership yes, enumeration no
::
++  test-seq-member      (ex '<<1, 2>> \\in Seq(1..3)' "TRUE")
++  test-seq-member-empty  (ex '<<>> \\in Seq(1..3)' "TRUE")
++  test-seq-non-member  (ex '<<4>> \\in Seq(1..3)' "FALSE")
++  test-seq-over-nat
  ::  a descriptor over a descriptor: Seq's range is a VALUE here, and Nat
  ::  is not one, so this is a typed rejection (compatibility.md)
  %+  ex  '<<1, 2>> \\in Seq(Nat)'
  "ERR: unsupported StandardModule operator: Naturals!Nat/0"

::
++  test-seq-member-not-sequence
  %+  ex  '1 \\in Seq(1..3)'
  "ERR: Attempted to check if the value:\0a1\0ais an element of Seq(1..3)."
::
++  test-seq-not-enumerable
  %+  ex  '\\A s \\in Seq(1..2) : Len(s) > 0'
  "ERR: Attempted to enumerate the non-enumerable set Seq(1..2)."
::
++  test-seq-as-value
  ::  tlc2 renders `Seq({1})` as a UserValue; a value position is a typed
  ::  rejection here (compatibility.md)
  %+  ex  'Seq(1..2)'
  "ERR: unsupported StandardModule operator: Sequences!Seq/1"
::
::  +|  Bindings
::
++  test-bindings
  ::  every C1.3 operator now binds to an override, including the ones the
  ::  evaluator runs itself (SelectSeq) and the descriptor (Seq)
  =/  src
    (malt ~[['A' (crip "---- MODULE A ----\0aEXTENDS Sequences\0aExpr == 1\0a====")]])
  ;:  weld
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'SubSeq' 3)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'SelectSeq' 2)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'Seq' 1)))
  ==
::
++  test-node-op-keys
  ::  the operator-argument table claims exactly the SelectSeq key
  ;:  weld
    (expect-eq !>(&) !>(?=(^ (node-op:so ['Sequences' 'SelectSeq' 2]))))
    (expect-eq !>(&) !>(?=(~ (node-op:so ['Sequences' 'Len' 1]))))
  ==
--
