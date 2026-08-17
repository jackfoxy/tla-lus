::  Safety state generation + assumption checking (Work Unit 7.2). ASSUME is
::  checked before the search (Tool.checkAssumptions): a false assumption is a
::  typed failure, a non-boolean one an evaluation failure, never a silent skip.
::  Init/successor streams keep TLC's branch/binding order; an incomplete next
::  state is a typed failure at the TLC point.
/+  *test
/=  check  /lib/check
/=  ne     /lib/node-eval
/=  v      /lib/value
|%
++  spec
  ::  a module with the given ASSUME line (empty for none)
  |=  assume=tape
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "EXTENDS Naturals\0a"
    "VARIABLE x\0a"
    ?~(assume "" (weld assume "\0a"))
    "Init == x = 0\0a"
    "Next == x' = (x + 1) % 3\0a"
    "Inv == x < 3\0a"
    "====\0a"
  ==
++  cfg  ^-(@t (crip "INIT Init\0aNEXT Next\0aINVARIANT Inv\0a"))
++  verdict  |=(s=tape =/(rr (run-check:check (spec s) cfg 0) -.-.rr))
::
::  +|  Assumption checking (Tool.checkAssumptions)
::
::  a false assumption stops the run before search (EC 2104)
++  test-assume-false
  (expect-eq !>(~['Error: An assumption is false.']) !>((check:check (spec "ASSUME 1 = 2") cfg)))
::  a satisfied assumption lets the run complete (%ok)
++  test-assume-ok
  (expect-eq !>(%ok) !>((verdict "ASSUME 1 + 1 = 2")))
::  no assumption at all: the run completes normally
++  test-assume-none
  (expect-eq !>(%ok) !>((verdict "")))
::  a non-boolean assumption is an evaluation failure (EC 2105), not %ok
++  test-assume-nonbool
  =/  out  (check:check (spec "ASSUME 1 + 1") cfg)
  =/  ln   ?~(out "" (trip i.out))
  (expect-eq !>(%.y) !>((gulf-match ln "Error: Evaluating an assumption failed:")))
::  a conjunction of assumptions: all must hold
++  test-assume-false-still-fails
  (expect-eq !>(%failed) !>((verdict "ASSUME 2 = 3")))
::  an AXIOM is SKIPPED by Tool.checkAssumptions (`(!isAxiom[i]) && ...`), so a
::  false one does NOT fail the run -- measured against tlc2.TLC, which reports
::  `Model checking completed. No error has been found.` for `AXIOM 1 = 2`
::  where `ASSUME 1 = 2` gives `Assumption ... is false.` (R1.5.13)
++  test-axiom-false-skipped
  (expect-eq !>(%ok) !>((verdict "AXIOM 1 = 2")))
::  ...but only the literal `AXIOM` keyword marks an axiom (AssumeNode.java:65),
::  so ASSUMPTION is still a checked assumption
++  test-assumption-false-fails
  (expect-eq !>(%failed) !>((verdict "ASSUMPTION 1 = 2")))
::
::  +|  Ordered state generation (branch / binding order at the TLC point)
::
++  src  (malt ~[['A' gen-mod]])
++  gen-mod
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "EXTENDS Integers\0a"
    "VARIABLE x\0a"
    "Init == x = 0 \\/ x = 1 \\/ x = 2\0a"
    "Step == \\E d \\in 1..2 : x' = x + d\0a"
    "Half == x' = x\0a"
    "====\0a"
  ==
::  Init disjunction is enumerated in source order
++  test-init-order
  =/  r  (solve-init:ne 'A' src 'Init')
  =/  got  ?:(?=(%& -.r) (render-states:ne p.r) ~["ERR"])
  (expect-eq !>(~["x=0" "x=1" "x=2"]) !>(got))
::  \E over a domain enumerates in TLC element order
++  test-next-exists-order
  =/  r  (solve-next:ne 'A' src 'Step' (malt ~[['x' (vin:v 0)]]))
  =/  got  ?:(?=(%& -.r) (render-states:ne p.r) ~["ERR"])
  (expect-eq !>(~["x=1" "x=2"]) !>(got))
::
::  +|  Incomplete-assignment detection (typed failure at the TLC point)
::
::  a Next that leaves a declared variable unassigned is a typed failure,
::  not a silently dropped or half-built successor
++  test-incomplete-next
  =/  bad  (malt ~[['A' bad-mod]])
  =/  r  (solve-next:ne 'A' bad 'Next' (malt ~[['x' (vin:v 0)] ['y' (vin:v 0)]]))
  (expect-eq !>(%.y) !>(?=(%| -.r)))
++  bad-mod
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "EXTENDS Integers\0a"
    "VARIABLE x, y\0a"
    "Init == x = 0 /\\ y = 0\0a"
    "Next == x' = x + 1\0a"
    "====\0a"
  ==
::
++  gulf-match
  ::  does tape `s` start with tape `pre`
  |=  [s=tape pre=tape]
  ^-  ?
  ?~  pre  %.y
  ?~  s  %.n
  ?.  =(i.s i.pre)  %.n
  $(s t.s, pre t.pre)
--
