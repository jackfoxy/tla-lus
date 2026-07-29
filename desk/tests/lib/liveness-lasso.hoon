::  Full liveness out.txt projection (unit 8.6): live-lasso-lines matches the
::  oracle LIVENESS/VERDICT/EC/STAT + CLASS/LOOP/TRACE/STATE projection
::  byte-for-byte. Covers stuttering-at-init, back-to-state (per-action
::  getActions labels), and the LET-bound leaf (letin-prop).
::  Excluded from the LASSO differential (owning unit): leadsto-viol — its
::  product is correct (tests/lib/liveness-product) but its accepting stutter
::  node is (x=0, tableau P3, non-init), so the port builds LOOP 2 where TLC
::  stutters at the init node (LOOP 1); the stutter-node SELECTION is 8.6.2.
::  Also open in 8.6.2: wf-absent-viol (multi-step sink stutter, LOOP 3).
/+  *test
/=  check  /lib/check
|%
++  src-diamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(x = 1)\0a====\0a'
++  cfg-diamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-lasso-diamond-stutter
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 5' 'STAT distinct 2' 'STAT queue 0' 'STAT depth 2' 'CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-diamond-stutter cfg-diamond-stutter))
++  src-boxdiamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == []<>(x = 1)\0a====\0a'
++  cfg-boxdiamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-lasso-boxdiamond-stutter
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 5' 'STAT distinct 2' 'STAT queue 0' 'STAT depth 2' 'CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-boxdiamond-stutter cfg-boxdiamond-stutter))
++  src-diamond-const-false  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aLive == <>FALSE\0a====\0a'
++  cfg-diamond-const-false  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-lasso-diamond-const-false
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 3' 'STAT distinct 2' 'STAT queue 0' 'STAT depth 2' 'CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-diamond-const-false cfg-diamond-const-false))
++  src-multi-property  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aP1 == <>(x = 1)\0aP2 == []<>(x = 0)\0a====\0a'
++  cfg-multi-property  'INIT Init\0aNEXT Next\0aPROPERTY P1\0aPROPERTY P2\0a'
++  test-lasso-multi-property
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 5' 'STAT distinct 2' 'STAT queue 0' 'STAT depth 2' 'CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-multi-property cfg-multi-property))
++  src-back-to-state  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Next)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-back-to-state  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-lasso-back-to-state
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 3' 'STAT distinct 2' 'STAT queue 0' 'STAT depth 2' 'CLASS back-to-state' 'LOOP 1' 'TRACE 3' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 0xf67893cfa654c4b3' 'LABEL <Next line 5, col 9 to line 5, col 18 of module A>' 'x = 1' 'ENDSTATE' 'STATE 1 -1' 'LABEL Back to state' 'ENDSTATE'])
  !>((live-lasso-lines:check src-back-to-state cfg-back-to-state))
++  src-wf-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aA == x = 0 /\\ x\' = 1\0aB == x = 1 /\\ x\' = 0\0aNext == A \\/ B\0aSpec == Init /\\ [][Next]_x /\\ WF_x(A)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-wf-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-lasso-wf-viol
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 3' 'STAT distinct 2' 'STAT queue 0' 'STAT depth 2' 'CLASS back-to-state' 'LOOP 1' 'TRACE 3' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 0xf67893cfa654c4b3' 'LABEL <A line 5, col 6 to line 5, col 20 of module A>' 'x = 1' 'ENDSTATE' 'STATE 1 -1' 'LABEL Back to state' 'ENDSTATE'])
  !>((live-lasso-lines:check src-wf-viol cfg-wf-viol))
++  src-sf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ WF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-absent-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-lasso-sf-absent-viol
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 5' 'STAT distinct 3' 'STAT queue 0' 'STAT depth 3' 'CLASS back-to-state' 'LOOP 1' 'TRACE 3' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 0xf67893cfa654c4b3' 'LABEL <Ay line 5, col 7 to line 5, col 21 of module A>' 'x = 1' 'ENDSTATE' 'STATE 1 -1' 'LABEL Back to state' 'ENDSTATE'])
  !>((live-lasso-lines:check src-sf-absent-viol cfg-sf-absent-viol))
++  src-letin-prop  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(LET y == 1 IN x = y)\0a====\0a'
++  cfg-letin-prop  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-lasso-letin-prop
  %+  expect-eq
    !>(`wain`~['LIVENESS' 'VERDICT violated-property' 'EC 2116' 'STAT generated 5' 'STAT distinct 2' 'STAT queue 0' 'STAT depth 2' 'CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-letin-prop cfg-letin-prop))
--
