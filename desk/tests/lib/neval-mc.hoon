::  node-eval solver reproduces the model-checking corpus constructs, so it
::  is a drop-in for check.hoon's CST solver (WU6.9 integration check).
/+  *test
/=  ne  /lib/node-eval
/=  v   /lib/value
|%
++  cyc
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE spec ----\0a"  "EXTENDS Naturals\0a"  "VARIABLE x\0a"
    "Init == x = 0\0a"  "Next == x' = (x + 1) % 4\0a"  "Inv == x < 4\0a"  "====\0a"
  ==
++  two
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE spec ----\0a"  "VARIABLES a, b\0a"
    "Init == a = FALSE /\\ b = FALSE\0a"
    "Next == \\/ (a' = ~a /\\ b' = b)\0a         \\/ (b' = ~b /\\ a' = a)\0a"
    "Inv == TRUE\0a"  "====\0a"
  ==
++  csrc  (malt ~[['spec' cyc]])
++  tsrc  (malt ~[['spec' two]])
++  st  |=(l=(list [@t @ud]) `state:ne`(malt (turn l |=([nm=@t n=@ud] [nm (vin:v n)]))))
++  bst  |=(l=(list [@t ?]) `state:ne`(malt (turn l |=([nm=@t b=?] [nm `value:v`[%bool b]]))))
::
++  cnext
  |=  [cur=(list [@t @ud]) want=(list tape)]
  ^-  tang
  =/  r  (solve-next:ne 'spec' csrc 'Next' (st cur))
  =/  got  ?:(?=(%& -.r) (render-states:ne p.r) ~[(weld "ERR: " (trip msg.p.r))])
  (expect-eq !>(want) !>(got))
::
::  cyc: x' = (x+1) % 4 wraps 3 -> 0
++  test-cyc-init   %+  expect-eq  !>  `(list tape)`~["x=0"]
  !>  =/(r (solve-init:ne 'spec' csrc 'Init') ?:(?=(%& -.r) (render-states:ne p.r) ~))
++  test-cyc-0  (cnext ~[['x' 0]] ~["x=1"])
++  test-cyc-3  (cnext ~[['x' 3]] ~["x=0"])
::  twobit: a'=~a (bool not) in an assignment; disjunction branch order
++  test-two-init
  %+  expect-eq  !>  `(list tape)`~["a=FALSE,b=FALSE"]
  !>  =/(r (solve-init:ne 'spec' tsrc 'Init') ?:(?=(%& -.r) (render-states:ne p.r) ~))
++  test-two-next
  =/  r  (solve-next:ne 'spec' tsrc 'Next' (bst ~[['a' |] ['b' |]]))
  =/  got  ?:(?=(%& -.r) (render-states:ne p.r) ~[(weld "ERR: " (trip msg.p.r))])
  (expect-eq !>(`(list tape)`~["a=TRUE,b=FALSE" "a=FALSE,b=TRUE"]) !>(got))
--
