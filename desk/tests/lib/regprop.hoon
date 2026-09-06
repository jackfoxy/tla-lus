::  Registry contract properties (unit 6C.6): argument handling and laziness,
::  minLevel, shadowing, and the structural properties that keep the override
::  table honest — no bare-name reachability, no arity-blind gate, and a typed
::  rejection for everything the registry does not claim.
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
++  one
  |=  [ext=tape body=(list tape)]
  ^-  (map @t @t)
  =/  txt=@t
    %-  crip
    ;:  weld
      "---- MODULE A ----\0a"
      (weld ext "\0a")
      %+  roll  (flop body)
      |=([l=tape acc=tape] (weld (weld l "\0a") acc))
      "====\0a"
    ==
  (malt ~[['A' txt]])
::
++  two
  ::  a root module extending a user helper
  |=  [root=(list tape) helper=(list tape)]
  ^-  (map @t @t)
  =/  lines
    |=  ls=(list tape)
    ^-  tape
    %+  roll  (flop ls)
    |=([l=tape acc=tape] (weld (weld l "\0a") acc))
  %-  malt
  :~  ['A' (crip ;:(weld "---- MODULE A ----\0a" (lines root) "====\0a"))]
      ['H' (crip ;:(weld "---- MODULE H ----\0a" (lines helper) "====\0a"))]
  ==
::
++  val
  |=  [src=(map @t @t) want=tape]
  ^-  tang
  =/  r  (eval-module-def:ne 'A' src 'Expr')
  =/  got  ?:(?=(%| -.r) (weld "ERR: " (trip msg.p.r)) (render:v p.r))
  (expect-eq !>(want) !>(got))
::
++  keys  ~(tap in ~(key by registry:so))
::
::  +|  Laziness: which side evaluates the arguments
::
++  test-lazy-only-for-evaluation-overrides
  ::  every registry row takes evaluated arguments (a plain MethodValue);
  ::  laziness is reserved for the pin's `@Evaluation` overrides, which are
  ::  node-ops
  =/  bad
    =/  ks  keys
    |-  ^-  (list op-key:so)
    ?~  ks  ~
    =/  m  (op-meta:so i.ks)
    ?:  ?&(?=(^ m) lazy.u.m)  [i.ks $(ks t.ks)]
    $(ks t.ks)
  (expect-eq !>(*(list op-key:so)) !>(bad))
::
++  test-tlc-eval-is-lazy
  ::  the pin's Evaluation override receives the node and evaluates it itself
  =/  m  (op-meta:so ['TLC' 'TLCEval' 1])
  ;:  weld
    (expect-eq !>(&) !>(?=(^ m)))
    (expect-eq !>(&) !>(?:(?=(^ m) lazy.u.m |)))
  ==
::
++  test-tlc-eval-evaluates-its-argument
  %-  val
  :_  "5"
  (one "EXTENDS Integers, TLC" ~["Expr == TLCEval(2 + 3)"])
::
++  test-tlc-eval-passes-the-failure-through
  ::  it evaluates the node, so the argument's own typed failure surfaces
  %-  val
  :_  "ERR: The second argument of \\div is 0."
  (one "EXTENDS Integers, TLC" ~["Expr == TLCEval(1 \\div 0)"])
::
++  test-unused-operator-argument-is-not-evaluated
  ::  the lazy-argument rule the evaluator already applies to user operators:
  ::  a parameter the body never uses is never evaluated, so a failing
  ::  argument does not fail the application
  %-  val
  :_  "7"
  %+  one  "EXTENDS Integers"
  ~["Ignore(x) == 7" "Expr == Ignore(1 \\div 0)"]
::
::  +|  minLevel
::
++  test-min-level-carried
  ::  TLCGet is minLevel 1 in the pin; everything else in scope is 0
  =/  m  (op-meta:so ['TLC' 'TLCGet' 1])
  =/  z  (op-meta:so ['Naturals' '+' 2])
  ;:  weld
    (expect-eq !>(1) !>(?:(?=(^ m) level.u.m 0)))
    (expect-eq !>(0) !>(?:(?=(^ z) level.u.z 99)))
  ==
::
::  +|  Argument-type errors: category, operator, and position
::
++  test-arg-error-position-first
  %+  ex  '"a" + 1'
  "ERR: The first argument of + should be an integer, but instead it is:\0a\"a\""
::
++  test-arg-error-position-second
  %+  ex  '1 + "a"'
  "ERR: The second argument of + should be an integer, but instead it is:\0a\"a\""
::
++  test-arg-error-names-the-operator
  %+  ex  'Len(1)'
  "ERR: The argument of Len should be a sequence, but instead it is:\0a1"
::
++  test-arg-error-code-is-the-cast-code
  ::  the pin fails inside the MethodValue cast (EC 2154) and names the Java
  ::  signature; the code is kept and the volatile text normalized
  =/  r  (eval-module-def:ne 'A' (one "EXTENDS Integers" ~["Expr == 1 + \"a\""]) 'Expr')
  (expect-eq !>(2.154) !>(?:(?=(%| -.r) code.p.r 0)))
::
++  test-explicit-check-code
  ::  where tlc2 checks explicitly instead, the code is its own (EC 2266)
  =/  r  (eval-module-def:ne 'A' (one "EXTENDS Integers" ~["Expr == 1 < \"a\""]) 'Expr')
  (expect-eq !>(2.266) !>(?:(?=(%| -.r) code.p.r 0)))
::
::  +|  Shadowing: a user definition wins
::
++  test-root-definition-shadows-an-override
  %-  val
  :_  "42"
  %+  one  "EXTENDS Sequences"
  ~["Len(s) == 42" "Expr == Len(<<1, 2, 3>>)"]
::
++  test-imported-definition-shadows-an-override
  ::  the shadowing definition may come from a user module reached by EXTENDS
  %-  val
  :_  "99"
  %+  two  ~["EXTENDS H, Sequences" "Expr == Len(<<1>>)"]
  ~["Len(s) == 99"]
::
++  test-same-name-different-arity-is-a-different-operator
  ::  a user operator sharing a StandardModule name at another arity does not
  ::  collide with the override
  %-  val
  :_  "5"
  %+  one  "EXTENDS Sequences, Integers"
  ~["Len(a, b) == a + b" "Expr == Len(2, 3)"]
::
::  +|  Structural properties of the table
::
++  test-no-row-is-reachable-by-bare-name
  ::  every key is module-qualified: the same operator name under another
  ::  module resolves to nothing
  =/  bad
    =/  ks  keys
    |-  ^-  (list op-key:so)
    ?~  ks  ~
    =/  hit  (lookup:so make-senv:so [module='Zork' name=name.i.ks arity=arity.i.ks])
    ?^  hit  [i.ks $(ks t.ks)]
    $(ks t.ks)
  (expect-eq !>(*(list op-key:so)) !>(bad))
::
++  test-every-gate-checks-its-arity
  ::  applying a row's gate to the wrong number of arguments must fail; a
  ::  gate that ignored arity could return a value tlc2 never would
  =/  bad
    =/  ks  keys
    |-  ^-  (list op-key:so)
    ?~  ks  ~
    =/  imp  (lookup:so make-senv:so i.ks)
    ?~  imp  [i.ks $(ks t.ks)]
    =/  args  (reap +(arity.i.ks) `value:v`[%int --1])
    =/  r  (gate.u.imp args)
    ?:  ?=(%| -.r)  $(ks t.ks)
    [i.ks $(ks t.ks)]
  (expect-eq !>(*(list op-key:so)) !>(bad))
::
++  test-unclaimed-operators-are-typed-rejections
  ::  everything the registry, the node-op table, and the descriptors leave
  ::  unclaimed is a typed rejection naming itself — never a value
  ::
  ::  R2.7.6.0: `RandomElement` was one of the three unclaimed names and
  ::  R2.7.4.4 IMPLEMENTED it, so this arm read %override. It is now asserted
  ::  on the other side — deleting it would drop the only guard that the
  ::  operator still resolves — and the two names left standing are excluded
  ::  on SEMANTICS (a wall clock, a value with no canonical representation)
  ::  rather than on effort, so no later capability unit moves them.
  =/  src
    (one "EXTENDS Integers, TLC, Bags" ~["Expr == 1"])
  ;:  weld
    (expect-eq !>(%none) !>((binding-in:ne 'A' src 'JavaTime' 0)))
    (expect-eq !>(%none) !>((binding-in:ne 'A' src 'Any' 0)))
    (expect-eq !>(%override) !>((binding-in:ne 'A' src 'RandomElement' 1)))
    ::  and the body-evaluable exception is still exactly one operator
    (expect-eq !>(%body) !>((binding-in:ne 'A' src 'SubBag' 1)))
  ==
--
