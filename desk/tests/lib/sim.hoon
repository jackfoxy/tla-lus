::  Property tests for bounded seeded simulation (unit 12).
::  These assert engine properties -- reproducibility, bounded
::  termination, and violation discovery -- rather than a differential
::  oracle match, mirroring the unit-2 pause/resume-identical style.
/+  *test
/=  check  /lib/check
|%
++  invfail-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = x + 1
  Inv == x < 3
  ====
  '''
::
++  invfail-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::
++  cyc-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 4
  Inv == x < 4
  ====
  '''
::
++  cyc-cfg  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::
++  summary
  ::  a scalar projection of a run (no recursive value molds to vase)
  |=  r=sim-result:check
  ^-  [traces=@ud steps=@ud hit=?]
  [traces.r steps.r ?=(^ viol.r)]
::
::  same seed and limits produce identical results
++  test-sim-reproducible
  %+  expect-eq
    !>  (summary (simulate-spec:check cyc-spec cyc-cfg 42 8 12))
  !>  (summary (simulate-spec:check cyc-spec cyc-cfg 42 8 12))
::
::  a bounded run never exceeds the trace limit (terminates cleanly)
++  test-sim-bounded
  =/  r  (simulate-spec:check cyc-spec cyc-cfg 7 3 20)
  (expect-eq !>(%.y) !>((lte traces.r 3)))
::
::  simulation discovers a reachable invariant violation
++  test-sim-finds-violation
  =/  r  (simulate-spec:check invfail-spec invfail-cfg 1 1 10)
  (expect-eq !>(%.y) !>(?=(^ viol.r)))
::
::  a spec whose invariant always holds yields no violation
++  test-sim-no-violation
  =/  r  (simulate-spec:check cyc-spec cyc-cfg 99 5 20)
  (expect-eq !>(%.y) !>(?=(~ viol.r)))
--
