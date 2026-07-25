::  Invariants (ordered, first-violated), state/action constraints (prune),
::  deadlock flag honoring, and invariant evaluation errors (Work Unit 7.3).
::  Driven through run-check:check (result + run-stats), so no value crosses the
::  low-budget test core. Expected verdicts/counts match tlc2.TLC (SafetyDump).
/+  *test
/=  check  /lib/tla/check
|%
++  run  |=([s=@t c=@t] ^-(result:check -:(run-check:check s c 0)))
::  a module with an explicit VARIABLE x and the supplied definition lines
++  mod
  |=  defs=tape
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"  "EXTENDS Integers\0a"  "VARIABLE x\0a"
    defs  "====\0a"
  ==
::
::  +|  Multiple invariants, checked in declaration order
::
::  Small (x < 10) holds while NotThree (x # 3) is violated first at x = 3;
::  the reported invariant is the first violated in declaration order
++  test-multi-inv-order
  =/  m  (mod "Init == x = 0\0aNext == x' = x + 1\0aSmall == x < 10\0aNotThree == x # 3\0a")
  =/  c  ^-(@t (crip "INIT Init\0aNEXT Next\0aINVARIANT Small\0aINVARIANT NotThree\0a"))
  =/  r  (run m c)
  %+  expect-eq
    !>  [%.y 'NotThree']
  !>  ?:  ?=([%violated [%invariant *] *] r)  [%.y name.violation.r]  [%.n '']
::
::  +|  State constraint (CONSTRAINT): prune before enqueue
::
::  Bound (x =< 4) bounds the reachable set to x in 0..4 (5 distinct); x = 5 is
::  generated but pruned, so the run completes without deadlock or violation
++  test-state-constraint
  =/  m  (mod "Init == x = 0\0aNext == x' = x + 1\0aBound == x =< 4\0a")
  =/  c  ^-(@t (crip "INIT Init\0aNEXT Next\0aCONSTRAINT Bound\0a"))
  =/  r  (run m c)
  %+  expect-eq
    !>  [%.y `@ud`5]
  !>  ?:(?=([%ok *] r) [%.y distinct.stats.r] [%.n 0])
::
::  +|  Action constraint (ACTION_CONSTRAINT): prune the transition
::
++  test-action-constraint
  =/  m  (mod "Init == x = 0\0aNext == x' = x + 1\0aNoBig == x' =< 4\0a")
  =/  c  ^-(@t (crip "INIT Init\0aNEXT Next\0aACTION_CONSTRAINT NoBig\0a"))
  =/  r  (run m c)
  %+  expect-eq
    !>  [%.y `@ud`5]
  !>  ?:(?=([%ok *] r) [%.y distinct.stats.r] [%.n 0])
::
::  +|  Deadlock detection honoring the CHECK_DEADLOCK flag
::
::  Next has no successor at x = 2; with deadlock checking on (the default) that
::  is a violation, with it off the run completes
++  ddl-mod  (mod "Init == x = 0\0aNext == x < 2 /\\ x' = x + 1\0a")
++  test-deadlock-on
  =/  r  (run ddl-mod ^-(@t (crip "INIT Init\0aNEXT Next\0a")))
  (expect-eq !>(%.y) !>(?=([%violated [%deadlock *] *] r)))
++  test-deadlock-off
  =/  r  (run ddl-mod ^-(@t (crip "INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a")))
  (expect-eq !>(%.y) !>(?=([%ok *] r)))
::
::  +|  Evaluation error during an invariant check
::
::  an invariant that raises an evaluation error (division by zero) is a typed
::  failure at the check point, not a false %ok or a silent skip
++  test-inv-eval-error
  =/  m  (mod "Init == x = 0\0aNext == x' = x + 1\0aBad == (x \\div 0) = 0\0a")
  =/  c  ^-(@t (crip "INIT Init\0aNEXT Next\0aINVARIANT Bad\0a"))
  =/  r  (run m c)
  (expect-eq !>(%.y) !>(?=([%failed *] r)))
--
