::  FiniteSets and Bags parity (unit 6C.4). Cardinality and IsFiniteSet take
::  a lazy DOMAIN, so an infinite descriptor answers instead of being forced;
::  every Bags operator starts from tlc2's Value.toFcnRcd. Expectations come
::  from desk/test-data/stdops/{st-finitesets,st-bags}.
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
++  bag
  ::  an expression in a module that EXTENDS Bags (plus helper operators for
  ::  the operator-argument cases)
  ::  the body arrives as a cord: `{` opens interpolation in a Hoon tape
  |=  [body=@t want=tape]
  ^-  tang
  =/  src=@t
    %-  crip
    ;:  weld
      "---- MODULE A ----\0a"
      "EXTENDS Integers, Bags\0a"
      "Inc(x) == x + 1\0a"
      "Same(x) == 1\0a"
      "Expr == "  (trip body)  "\0a===="
    ==
  =/  r  (eval-module-def:ne 'A' (malt ~[['A' src]]) 'Expr')
  =/  got
    ?:  ?=(%| -.r)  (weld "ERR: " (trip msg.p.r))
    (render:v p.r)
  (expect-eq !>(want) !>(got))
::
::  +|  FiniteSets
::
++  test-cardinality        (ex 'Cardinality(1..3)' "3")
++  test-cardinality-set    (ex 'Cardinality({3, 1, 2})' "3")
++  test-cardinality-dup    (ex 'Cardinality({1, 1, 2})' "2")
++  test-cardinality-empty  (ex 'Cardinality({})' "0")
++  test-cardinality-subset  (ex 'Cardinality(SUBSET {1, 2, 3})' "8")
++  test-cardinality-union
  (ex 'Cardinality(UNION {{1, 2}, {2, 3}})' "3")
::
++  test-is-finite-set        (ex 'IsFiniteSet({1, 2, 3})' "TRUE")
++  test-is-finite-set-empty  (ex 'IsFiniteSet({})' "TRUE")
++  test-is-finite-interval   (ex 'IsFiniteSet(1..3)' "TRUE")
++  test-is-finite-subset     (ex 'IsFiniteSet(SUBSET {1, 2})' "TRUE")
::
++  test-is-finite-nat
  ::  the infinite descriptors answer FALSE rather than being enumerated
  (ex 'IsFiniteSet(Nat)' "FALSE")
::
++  test-is-finite-int   (ex 'IsFiniteSet(Int)' "FALSE")
++  test-is-finite-seq   (ex 'IsFiniteSet(Seq(1..2))' "FALSE")
::
++  test-cardinality-nat
  %+  ex  'Cardinality(Nat)'
  "ERR: Attempted to compute cardinality of the value\0aNat"
::
++  test-cardinality-seq
  %+  ex  'Cardinality(Seq(1..2))'
  "ERR: Attempted to compute cardinality of the value\0aSeq(1..2)"
::
++  test-cardinality-not-a-set
  %+  ex  'Cardinality(3)'
  "ERR: Attempted to compute cardinality of the value\0a3"
::
++  test-is-finite-not-a-set
  %+  ex  'IsFiniteSet(3)'
  "ERR: Attempted to check if the integer 3 is a finite set."
::
::  +|  Bags: construction and queries
::
++  test-empty-bag     (bag 'EmptyBag' "<<>>")
++  test-set-to-bag    (bag 'SetToBag({1, 2})' "<<1, 1>>")
++  test-is-a-bag      (bag 'IsABag(SetToBag({1, 2}))' "TRUE")
++  test-is-a-bag-set  (bag 'IsABag({1, 2})' "FALSE")
++  test-is-a-bag-zero  (bag 'IsABag(1 :> 0)' "FALSE")
++  test-bag-card      (bag 'BagCardinality(SetToBag({1, 2}))' "2")
++  test-bag-card-multi  (bag 'BagCardinality(1 :> 2 @@ 2 :> 3)' "5")
++  test-bag-in        (bag 'BagIn(1, SetToBag({1, 2}))' "TRUE")
++  test-bag-not-in    (bag 'BagIn(9, SetToBag({1, 2}))' "FALSE")
++  test-copies-in     (bag 'CopiesIn(1, 1 :> 4)' "4")
++  test-copies-missing  (bag 'CopiesIn(9, SetToBag({1, 2}))' "0")
++  test-bag-to-set    (bag 'BagToSet(1 :> 2 @@ 2 :> 1)' (trip '{1, 2}'))
::
::  +|  Bags: algebra
::
++  test-bag-cup       (bag 'SetToBag({1, 2}) (+) SetToBag({1, 2})' "<<2, 2>>")
++  test-bag-cup-mixed  (bag '(1 :> 2) (+) (2 :> 3)' "<<2, 3>>")
++  test-bag-diff
  (bag '(SetToBag({1, 2}) (+) SetToBag({1, 2})) (-) SetToBag({1, 2})' "<<1, 1>>")
::
++  test-bag-diff-empties  (bag '(1 :> 1) (-) (1 :> 1)' "<<>>")
++  test-sq-subseteq   (bag 'SetToBag({1, 2}) \\sqsubseteq (1 :> 2 @@ 2 :> 2)' "TRUE")
++  test-sq-subseteq-false  (bag '(1 :> 3) \\sqsubseteq (1 :> 2)' "FALSE")
++  test-bag-union     (bag 'BagUnion({1 :> 1, 2 :> 1})' "<<1, 1>>")
++  test-bag-union-same
  ::  BagUnion({b, b}) = b, because the set is normalized first
  (bag 'BagUnion({1 :> 1, 1 :> 1})' "<<1>>")
::
++  test-bag-union-empty  (bag 'BagUnion({})' "<<>>")
::
::  +|  Bags: the operator argument
::
++  test-bag-of-all     (bag 'BagOfAll(Inc, SetToBag({1, 2}))' "(2 :> 1 @@ 3 :> 1)")
++  test-bag-of-all-collides
  ::  results that collide have their counts summed
  ::  a one-point function renders as a tuple, exactly as tlc2 does
  (bag 'BagOfAll(Same, SetToBag({1, 2}))' "<<2>>")
::
++  test-bag-of-all-not-operator
  %+  bag  'BagOfAll(3, SetToBag({1}))'
  "ERR: The first argument of BagOfAll should be an operator, but instead it is:\0a<Operator >"
::
::  +|  Bags: argument errors (the pin's text, including its quirks)
::
++  test-bag-card-not-a-bag
  %+  bag  'BagCardinality({1, 2})'
  %+  weld  "ERR: Applying BagCardinality to the following value,\0awhich is not a function with a finite domain:\0a"
  (trip '{1, 2}')
::
++  test-bag-card-not-positive
  %+  bag  'BagCardinality(1 :> 0)'
  ::  a one-point function renders as a tuple, as tlc2's FcnRcdValue does
  "ERR: Applying BagCardinality to the following value,\0awhich is not a bag:\0a<<0>>"
::
++  test-bag-to-set-not-a-function
  %+  bag  'BagToSet({1, 2})'
  %+  weld  "ERR: Applying BagToSet to the following value,\0awhich is not a function with a finite domain:\0a"
  (trip '{1, 2}')
::
++  test-set-to-bag-not-a-set
  ::  the pin's message names BagToSet here — a copy-paste in tlc2.module.Bags
  %+  bag  'SetToBag(3)'
  "ERR: Applying BagToSet to the following value,\0awhich is not a function with a finite domain:\0a3"
::
++  test-bag-cup-not-a-bag
  %+  bag  '{1} (+) (1 :> 1)'
  %+  weld  "ERR: The first argument of (+) should be a bag, but instead it is:\0a"
  (trip '{1}')
::
++  test-bag-union-not-a-set
  %+  bag  'BagUnion(3)'
  "ERR: Applying BagUnion to the following value,\0awhich is not a finite enumerable set:\0a3"
::
++  test-bag-union-element-not-a-bag
  %+  bag  'BagUnion({1, 2})'
  %+  weld  "ERR: Attempted to apply BagUnion to the following set, whose\0aelement is not a bag:\0a"
  (trip '{1, 2}')
::
::  +|  Bindings
::
++  test-bindings
  =/  src
    %-  malt
    :~  :-  'A'
        (crip "---- MODULE A ----\0aEXTENDS Integers, Bags, FiniteSets\0aExpr == 1\0a====")
    ==
  ;:  weld
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'BagIn' 2)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'BagOfAll' 2)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'Cardinality' 1)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'IsFiniteSet' 1)))
    ::  the one operator the pin does not override still evaluates its body
    (expect-eq !>(%body) !>((binding-in:ne 'A' src 'SubBag' 1)))
  ==
--
