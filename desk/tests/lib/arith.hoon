::  Naturals / Integers parity (unit 6C.2): floored division, tlc2's modulo
::  contract, Expt, the 32-bit IntValue range, and Nat/Int membership. Every
::  expectation is the pinned tlc2 behavior captured in
::  desk/test-data/stdops/{st-naturals,st-integers,st-arith-errors}.
/+  *test
/=  ne  /lib/node-eval
/=  so  /lib/stdops
|%
++  ex
  ::  a constant expression through the semantic-node evaluator; a typed
  ::  failure renders as "ERR: <message>"
  |=  [txt=@t want=tape]
  ^-  tang
  (expect-eq !>(want) !>((eval-dbg:ne txt)))
::
::  +|  Division And Modulo (tlc2.module.Naturals.Divide / Mod)
::
++  test-div-pos       (ex '7 \\div 2' "3")
++  test-div-neg-left  (ex '(-7) \\div 2' "-4")
++  test-div-neg-right  (ex '7 \\div (-2)' "-4")
++  test-div-both-neg  (ex '(-7) \\div (-2)' "3")
++  test-div-exact-neg  (ex '(-6) \\div 2' "-3")
++  test-div-zero
  (ex '5 \\div 0' "ERR: The second argument of \\div is 0.")
::
++  test-mod-pos       (ex '7 % 3' "1")
++  test-mod-neg-left  (ex '(-7) % 3' "2")
++  test-mod-zero
  %+  ex  '5 % 0'
  "ERR: The second argument of % should be a positive number, but instead it is:\0a0"
::
++  test-mod-negative-divisor
  %+  ex  '5 % (-2)'
  "ERR: The second argument of % should be a positive number, but instead it is:\0a-2"
::
::  +|  Exponentiation (tlc2.module.Naturals.Expt)
::
++  test-expt          (ex '2 ^ 10' "1024")
++  test-expt-one      (ex '7 ^ 1' "7")
++  test-expt-zero-exp  (ex '7 ^ 0' "1")
++  test-expt-neg-base  (ex '(-2) ^ 3' "-8")
++  test-expt-zero-zero
  (ex '0 ^ 0' "ERR: 0^0 is undefined.")
::
++  test-expt-negative-exponent
  %+  ex  '2 ^ (-1)'
  "ERR: The second argument of ^ should be a natural number, but instead it is:\0a-1"
::
++  test-expt-overflow
  (ex '2 ^ 31' "ERR: Overflow when computing 2^31")
::
::  +|  The 32-bit IntValue Range (EC 2178 / 2265)
::
++  test-overflow-plus
  (ex '2147483647 + 1' "ERR: Overflow when computing 2147483647+1")
::
++  test-overflow-minus
  (ex '(-2147483647) - 2' "ERR: Overflow when computing -2147483647-2")
::
++  test-overflow-times
  (ex '100000 * 100000' "ERR: Overflow when computing 100000*100000")
::
++  test-in-range-max   (ex '2147483646 + 1' "2147483647")
++  test-in-range-min   (ex '(-2147483647) - 1' "-2147483648")
::
++  test-literal-too-big
  %+  ex  '2147483648'
  "ERR: TLC can't handle a number this big.\0a2147483648"
::
::  +|  Argument Errors
::
++  test-compare-non-integer
  %+  ex  '1 < "a"'
  "ERR: The second argument of < should be an integer, but instead it is:\0a\"a\""
::
++  test-arith-non-integer
  ::  the pin fails inside the MethodValue cast, naming the Java signature;
  ::  the message is normalized here (compatibility.md)
  %+  ex  '1 + "a"'
  "ERR: The second argument of + should be an integer, but instead it is:\0a\"a\""
::
::  +|  Nat And Int (infinite StandardModule sets)
::
++  test-nat-member       (ex '3 \\in Nat' "TRUE")
++  test-nat-member-zero  (ex '0 \\in Nat' "TRUE")
++  test-nat-non-member   (ex '(-1) \\in Nat' "FALSE")
++  test-int-member-neg   (ex '(-3) \\in Int' "TRUE")
++  test-nat-notin        (ex '(-1) \\notin Nat' "TRUE")
++  test-subseteq-nat     (ex '1..3 \\subseteq Nat' "TRUE")
++  test-subseteq-int     (ex '(-2)..2 \\subseteq Int' "TRUE")
++  test-subseteq-not-nat  (ex '(-2)..2 \\subseteq Nat' "FALSE")
::
++  test-nat-member-wrong-kind
  %+  ex  '"a" \\in Nat'
  "ERR: Attempted to check if the value:\0a\"a\"\0ais an element of Nat."
::
++  test-nat-not-enumerable
  ::  quantifying over Nat is an error, never a hang or a truncation
  %+  ex  '\\A x \\in Nat : x > 0'
  "ERR: Attempted to enumerate the non-enumerable set Nat."
::
++  test-nat-as-value
  ::  tlc2 renders `Nat` as a UserValue; there is no such value kind here, so
  ::  a value position is a typed rejection (compatibility.md)
  %+  ex  'Nat'
  "ERR: unsupported StandardModule operator: Naturals!Nat/0"
::
::  +|  Intervals Still Route Through The Registry
::
++  test-interval        (ex '1..5' "1..5")
::  the empty-set rendering is written as a cord: `{` opens interpolation
::  inside a double-quoted Hoon tape
++  test-interval-empty  (ex '5..1' (trip '{}'))
++  test-interval-neg    (ex '(-2)..2' "-2..2")
::
++  test-set-descriptor-keys
  ::  the two set-denoting standard operators, and nothing else
  =/  nat  (set-descriptor:so ['Naturals' 'Nat' 0])
  =/  int  (set-descriptor:so ['Integers' 'Int' 0])
  =/  non  (set-descriptor:so ['Naturals' '+' 2])
  ;:  weld
    (expect-eq !>(&) !>(?=(^ nat)))
    (expect-eq !>(&) !>(?=(^ int)))
    (expect-eq !>(&) !>(?=(~ non)))
  ==
--
