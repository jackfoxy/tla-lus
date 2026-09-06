::  action solving: initial / successor state streams + ENABLED (WU6.7).
/+  *test
/=  ne  /lib/node-eval
/=  v   /lib/value
|%
++  mod
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "EXTENDS Integers\0a"
    "VARIABLE x, y\0a"
    "Init == x = 1 /\\ y = 2\0a"
    "Next == \\/ (x' = x + 1 /\\ y' = y)\0a"
    "         \\/ (x' = x /\\ y' = y + 1)\0a"
    "NextE == \\E d \\in 1..2 : (x' = x + d) /\\ UNCHANGED y\0a"
    "Enab == ENABLED (x' = x + 1 /\\ y' = y)\0a"
    "EnabF == ENABLED ((x' = x) /\\ (x' = x + 1))\0a"
    "Bad == x' = x + 1\0a"
    "====\0a"
  ==
::
++  src  (malt ~[['A' mod]])
++  st
  |=  l=(list [@t @ud])
  ^-  state:ne
  (malt (turn l |=([nm=@t n=@ud] [nm (vin:v n)])))
::
++  init-states
  |=  want=(list tape)
  ^-  tang
  =/  r  (solve-init:ne 'A' src 'Init')
  =/  got  ?:(?=(%& -.r) (render-states:ne p.r) ~[(weld "ERR: " (trip msg.p.r))])
  (expect-eq !>(want) !>(got))
::
++  next-states
  |=  [nm=@t cur=(list [@t @ud]) want=(list tape)]
  ^-  tang
  =/  r  (solve-next:ne 'A' src nm (st cur))
  =/  got  ?:(?=(%& -.r) (render-states:ne p.r) ~[(weld "ERR: " (trip msg.p.r))])
  (expect-eq !>(want) !>(got))
::
++  enab
  |=  [nm=@t s0=(list [@t @ud]) want=?]
  ^-  tang
  =/  r  (eval-pred:ne 'A' src nm (st s0) ~)
  =/  got=@t
    ?.  ?=(%& -.r)  (crip (weld "ERR: " (trip msg.p.r)))
    ?:(p.r 'TRUE' 'FALSE')
  (expect-eq !>(?:(want 'TRUE' 'FALSE')) !>(got))
::
::  Init: one initial state
++  test-init  (init-states ~["x=1,y=2"])
::  Next: a disjunction — two successors, in branch order
++  test-next  (next-states 'Next' ~[['x' 1] ['y' 2]] ~["x=2,y=2" "x=1,y=3"])
::  \E d \in {1,2} + UNCHANGED: domain order
++  test-nexte  (next-states 'NextE' ~[['x' 5] ['y' 7]] ~["x=6,y=7" "x=7,y=7"])
::  incomplete next state (y' never assigned) -> typed failure
++  test-incomplete
  =/  r  (solve-next:ne 'A' src 'Bad' (st ~[['x' 1] ['y' 2]]))
  (expect-eq !>(|) !>(?=(%& -.r)))
::  ENABLED: witness exists / conflicting assignment has none
++  test-enab-true   (enab 'Enab' ~[['x' 1] ['y' 2]] &)
++  test-enab-false  (enab 'EnabF' ~[['x' 1] ['y' 2]] |)
--
