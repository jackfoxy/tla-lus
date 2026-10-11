::  node-eval solver reproduces the model-checking corpus constructs, so it
::  is a drop-in for check.hoon's CST solver (WU6.9 integration check).
/+  *test
/=  ne  /lib/node-eval
/=  v   /lib/value
/=  sm  /lib/semantic
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
::
::  R4.P3 (H4): the arity-0 CONSTANT-level definitions are evaluated once into
::  the environment (tlc2's `SpecProcessor.processConstantDefns`); a
::  state-level one, a parameterized one, and one whose evaluation draws a
::  random value are not
++  cdef-src
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE spec ----\0a"  "EXTENDS Naturals, TLC\0a"  "VARIABLE x\0a"
    "C == \{n * 2 : n \\in 1..3}\0a"  "D == C \\cup \{0}\0a"
    "V == x + 1\0a"  "P(n) == n + 1\0a"  "R == RandomElement(1..9)\0a"
    "====\0a"
  ==
++  test-constant-defs-evaluated-once
  =/  mo  (need (generate:sm 'spec' (malt ~[['spec' cdef-src]])))
  =/  e   (make-env:ne (defmap-of:ne mo) ~ (vars-of:ne mo))
  %+  expect-eq
    !>  `(list [@t tape])`~[['C' "\{2, 4, 6}"] ['D' "\{0, 2, 4, 6}"]]
  !>  %+  sort
        %+  turn  ~(tap by cdefs.e)
        |=([nm=@t [* val=value:v]] [nm (render:v val)])
      |=([a=[@t tape] b=[@t tape]] (aor -.a -.b))
::
::  R4.1c: a nested inner module sees its parent's context up to it (the
::  parent's EXTENDS here); an INSTANCE inside a LET is generated and its
::  members evaluate, with a LET-local name substituted for a parameter
++  nest-src
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE spec ----\0a"  "EXTENDS Naturals\0a"  "VARIABLE y\0a"
    "---- MODULE In ----\0a"  "VARIABLE x\0a"
    "Step == x < 3 /\\ x' = x + 1\0a"  "====\0a"
    "S == INSTANCE In WITH x <- y\0a"  "Init == y = 0\0a"
    "Next == S!Step\0a"  "====\0a"
  ==
++  let-src
  ^-  (map @t @t)
  %-  malt
  :~  :-  'spec'
      %-  crip
      ;:  weld
        "---- MODULE spec ----\0a"  "EXTENDS Naturals\0a"  "VARIABLE x\0a"
        "Init == x = 0\0a"
        "Next == LET k == 1\0a"
        "            M == INSTANCE Inner WITH N <- k\0a"
        "        IN  x' = M!Twice(x) % 8\0a"
        "====\0a"
      ==
    ::
      :-  'Inner'
      %-  crip
      ;:  weld
        "---- MODULE Inner ----\0a"  "EXTENDS Naturals\0a"  "CONSTANT N\0a"
        "Twice(a) == 2 * a + N\0a"  "====\0a"
      ==
  ==
++  nexts
  |=  [src=(map @t @t) cur=(list [@t @ud])]
  ^-  (list tape)
  =/  r  (solve-next:ne 'spec' src 'Next' (st cur))
  ?:(?=(%& -.r) (render-states:ne p.r) ~[(weld "ERR: " (trip msg.p.r))])
::
++  test-nested-inner-sees-parent
  =/  src  (malt ~[['spec' nest-src]])
  ;:  weld
    (expect-eq !>(%accept) !>((sany-verdict:sm 'spec' src)))
    (expect-eq !>(`(list tape)`~["y=2"]) !>((nexts src ~[['y' 1]])))
    (expect-eq !>(`(list tape)`~) !>((nexts src ~[['y' 3]])))
  ==
::
++  test-instance-inside-let
  ;:  weld
    (expect-eq !>(%accept) !>((sany-verdict:sm 'spec' let-src)))
    (expect-eq !>(`(list tape)`~["x=3"]) !>((nexts let-src ~[['x' 1]])))
    (expect-eq !>(`(list tape)`~["x=3"]) !>((nexts let-src ~[['x' 5]])))
  ==
--
