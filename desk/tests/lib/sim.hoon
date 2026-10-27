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
::
::  R4.Q8b: in simulation a PROPERTY is binned as in the exhaustive check: an
::  implied action is its own kind (`Action property ... is violated`), a
::  box-state one an invariant, and an implied init is never checked (tlc2's
::  simulator does not -- `Init`'s `x = 0` against `x = 1` passes there)
++  prop-spec
  ^~
  '''
  ---- MODULE spec ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 5
  Spec == Init /\ [][Next]_x
  Bad == [][x' > x]_x
  BoxP == [](x < 3)
  BadInit == x = 1 /\ [][TRUE]_x
  ====
  '''
::
++  test-sim-prop-kinds
  =/  k
    |=  p=@t
    =/  r
      %:  simulate-spec:check  prop-spec
        (rap 3 ~['SPECIFICATION Spec\0aPROPERTY ' p '\0a'])
        1  3  10
      ==
    ?~(viol.r %none kind.u.viol.r)
  %+  expect-eq
    !>  `(list @tas)`~[%action %invariant %none]
  !>  `(list @tas)`~[(k 'Bad') (k 'BoxP') (k 'BadInit')]
::
::  R4.Q8b: a CONSTRAINT that fails to evaluate on a successor ends the run
::  with the error (tlc2: `Tool.isInModel` throws out of `addElement`). It
::  used to drop the successor, so every behavior ended after one state and
::  the run reported success
++  test-sim-constraint-error-ends-run
  =/  src
    %-  of-wain:format
    :~  '---- MODULE spec ----'
        'EXTENDS Naturals'
        'VARIABLE x'
        'Init == x = 0'
        'Next == x\' = x + 1'
        'Constr == x = 0 \\/ x < (CHOOSE y \\in {} : TRUE)'
        '===='
    ==
  =/  r
    %:  simulate-spec:check  src
      'INIT Init\0aNEXT Next\0aCONSTRAINT Constr\0aCHECK_DEADLOCK FALSE\0a'
      1  3  10
    ==
  (expect-eq !>([%.y %.n]) !>([?=(^ err.r) ?=(^ viol.r)]))
--
