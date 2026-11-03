::  state / prime / UNCHANGED evaluation (WU6.6) through node-eval.
/+  *test
/=  ne  /lib/node-eval
/=  v   /lib/value
|%
++  mod
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE S ----\0a"
    "EXTENDS Integers\0a"
    "VARIABLE x, y\0a"
    "Inv == x < y\0a"
    "Bump == x' = x + 1\0a"
    "Keep == UNCHANGED y\0a"
    "Both == (x' = x + 1) /\\ (UNCHANGED y)\0a"
    "Sum == x' + y\0a"
    "K == 2\0a"
    "G == x + K\0a"
    "F == G + K\0a"
    "FAt == \\A p \\in \{5} : F = p\0a"
    "FPr == F' = F + 1\0a"
    "Sq[i \\in 1..2] == i + x\0a"
    "SqAt == \\A i \\in \{7} : Sq[1] = 1 + x /\\ i = 7\0a"
    "====\0a"
  ==
::
++  src  (malt ~[['S' mod]])
++  st
  |=  l=(list [@t @ud])
  ^-  state:ne
  (malt (turn l |=([nm=@t n=@ud] [nm (vin:v n)])))
::
++  bp
  |=  [nm=@t s0=(list [@t @ud]) s1=(list [@t @ud]) want=?]
  ^-  tang
  =/  r  (eval-pred:ne 'S' src nm (st s0) (st s1))
  =/  got=@t
    ?.  ?=(%& -.r)  (crip (weld "ERR: " (trip msg.p.r)))
    ?:(p.r 'TRUE' 'FALSE')
  %+  expect-eq
    !>  ?:(want 'TRUE' 'FALSE')
  !>  got
::
::  state predicate: unprimed vars from the current state
++  test-inv-true   (bp 'Inv' ~[['x' 1] ['y' 2]] ~ &)
++  test-inv-false  (bp 'Inv' ~[['x' 3] ['y' 2]] ~ |)
::  prime: x' resolves from the successor state
++  test-bump-true   (bp 'Bump' ~[['x' 1]] ~[['x' 2]] &)
++  test-bump-false  (bp 'Bump' ~[['x' 1]] ~[['x' 5]] |)
::  UNCHANGED y is y' = y
++  test-keep-true   (bp 'Keep' ~[['y' 3]] ~[['y' 3]] &)
++  test-keep-false  (bp 'Keep' ~[['y' 3]] ~[['y' 4]] |)
::  composite action predicate
++  test-both-true   (bp 'Both' ~[['x' 1] ['y' 3]] ~[['x' 2] ['y' 3]] &)
++  test-both-false  (bp 'Both' ~[['x' 1] ['y' 3]] ~[['x' 2] ['y' 9]] |)
::  R4.P11: a state-level arity-0 definition is memoized per state; its
::  value follows the state, reaches constants through other definitions,
::  ignores the call site's locals, and a primed reference reads s1
++  test-sdef-memo
  ;:  weld
    (bp 'FAt' ~[['x' 1] ['y' 0]] ~ &)
    (bp 'FAt' ~[['x' 2] ['y' 0]] ~ |)
    (bp 'FPr' ~[['x' 1] ['y' 0]] ~[['x' 2] ['y' 0]] &)
    (bp 'FPr' ~[['x' 1] ['y' 0]] ~[['x' 3] ['y' 0]] |)
    (bp 'SqAt' ~[['x' 4] ['y' 0]] ~ &)
  ==
--
