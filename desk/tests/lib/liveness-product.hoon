::  Behavior-graph product node/init counts (unit 8.3): live-product must
::  match tools/oracle/ProductDump (desk/test-data/liveness/<case>/product.txt)
::  for every liveness corpus case. GENERATED — do not edit. symmetry-live is
::  Excluded: symmetry-live (production reject, 8.7); letin-prop (LET-bound leaf
::  needs its binding to eval consistency); leadsto-{pass,viol} (~> tableau product).
/+  *test
/=  check  /lib/check
|%
++  src-back-to-state  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Next)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-back-to-state  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-product-back-to-state
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-back-to-state cfg-back-to-state))
++  src-box-state  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == [](x = 0)\0a====\0a'
++  cfg-box-state  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-product-box-state
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 0'])
  !>((live-product:check src-box-state cfg-box-state))
++  src-boxdiamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == []<>(x = 1)\0a====\0a'
++  cfg-boxdiamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-product-boxdiamond-stutter
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-boxdiamond-stutter cfg-boxdiamond-stutter))
++  src-diamond-const-false  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aLive == <>FALSE\0a====\0a'
++  cfg-diamond-const-false  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-product-diamond-const-false
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-diamond-const-false cfg-diamond-const-false))
++  src-diamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(x = 1)\0a====\0a'
++  cfg-diamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-product-diamond-stutter
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 1' 'INITS 1'])
  !>((live-product:check src-diamond-stutter cfg-diamond-stutter))
++  src-multi-property  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aP1 == <>(x = 1)\0aP2 == []<>(x = 0)\0a====\0a'
++  cfg-multi-property  'INIT Init\0aNEXT Next\0aPROPERTY P1\0aPROPERTY P2\0a'
++  test-product-multi-property
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 2' '--- 0 ---' 'NODES 1' 'INITS 1' '--- 1 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-multi-property cfg-multi-property))
++  src-sf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ WF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-absent-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-product-sf-absent-viol
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-sf-absent-viol cfg-sf-absent-viol))
++  src-sf-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ SF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-product-sf-pass
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-sf-pass cfg-sf-pass))
++  src-spec-fairness-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 2 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 2 /\\ x\' = 2)\0aFairness == WF_x(Inc)\0aSpec == Init /\\ [][Next]_x /\\ Fairness\0aLive == <>(x = 2)\0a====\0a'
++  cfg-spec-fairness-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-product-spec-fairness-pass
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-spec-fairness-pass cfg-spec-fairness-pass))
++  src-wf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 3 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 3 /\\ x\' = 3)\0aLive == <>(x = 3)\0a====\0a'
++  cfg-wf-absent-viol  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-product-wf-absent-viol
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 3' 'INITS 1'])
  !>((live-product:check src-wf-absent-viol cfg-wf-absent-viol))
++  src-wf-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 3 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 3 /\\ x\' = 3)\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Inc)\0aLive == <>(x = 3)\0a====\0a'
++  cfg-wf-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-product-wf-pass
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 3' 'INITS 1'])
  !>((live-product:check src-wf-pass cfg-wf-pass))
++  src-wf-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aA == x = 0 /\\ x\' = 1\0aB == x = 1 /\\ x\' = 0\0aNext == A \\/ B\0aSpec == Init /\\ [][Next]_x /\\ WF_x(A)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-wf-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-product-wf-viol
  %+  expect-eq
    !>(`wain`~['PRODUCT' 'OOS 1' '--- 0 ---' 'NODES 2' 'INITS 1'])
  !>((live-product:check src-wf-viol cfg-wf-viol))
--
