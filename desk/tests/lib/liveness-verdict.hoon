::  Liveness VERDICT/EC differential (unit 8.5): live-verdict-lines must match
::  the ProductDump/LivenessDump out.txt verdict for the corpus. leadsto-viol
::  and letin-prop verdicts are covered by the whole-out.txt liveness-lasso
::  differential; leadsto-pass is here (VERDICT ok). Excluded: box-state (a state
::  invariant routed to the safety engine, 8.9), symmetry-live (typed reject,
::  8.7 approved-difference).
/+  *test
/=  check  /lib/check
|%
++  src-back-to-state  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Next)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-back-to-state  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-verdict-back-to-state
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-back-to-state cfg-back-to-state))
++  src-boxdiamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == []<>(x = 1)\0a====\0a'
++  cfg-boxdiamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-verdict-boxdiamond-stutter
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-boxdiamond-stutter cfg-boxdiamond-stutter))
++  src-diamond-const-false  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aLive == <>FALSE\0a====\0a'
++  cfg-diamond-const-false  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-verdict-diamond-const-false
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-diamond-const-false cfg-diamond-const-false))
++  src-diamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(x = 1)\0a====\0a'
++  cfg-diamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-verdict-diamond-stutter
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-diamond-stutter cfg-diamond-stutter))
++  src-multi-property  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aP1 == <>(x = 1)\0aP2 == []<>(x = 0)\0a====\0a'
++  cfg-multi-property  'INIT Init\0aNEXT Next\0aPROPERTY P1\0aPROPERTY P2\0a'
++  test-verdict-multi-property
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-multi-property cfg-multi-property))
++  src-sf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ WF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-absent-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-verdict-sf-absent-viol
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-sf-absent-viol cfg-sf-absent-viol))
++  src-sf-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ SF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-verdict-sf-pass
  %+  expect-eq
    !>(`wain`~['VERDICT ok' 'EC 0'])
  !>((live-verdict-lines:check src-sf-pass cfg-sf-pass))
++  src-spec-fairness-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 2 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 2 /\\ x\' = 2)\0aFairness == WF_x(Inc)\0aSpec == Init /\\ [][Next]_x /\\ Fairness\0aLive == <>(x = 2)\0a====\0a'
++  cfg-spec-fairness-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-verdict-spec-fairness-pass
  %+  expect-eq
    !>(`wain`~['VERDICT ok' 'EC 0'])
  !>((live-verdict-lines:check src-spec-fairness-pass cfg-spec-fairness-pass))
++  src-wf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 3 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 3 /\\ x\' = 3)\0aLive == <>(x = 3)\0a====\0a'
++  cfg-wf-absent-viol  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-verdict-wf-absent-viol
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-wf-absent-viol cfg-wf-absent-viol))
++  src-wf-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 3 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 3 /\\ x\' = 3)\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Inc)\0aLive == <>(x = 3)\0a====\0a'
++  cfg-wf-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-verdict-wf-pass
  %+  expect-eq
    !>(`wain`~['VERDICT ok' 'EC 0'])
  !>((live-verdict-lines:check src-wf-pass cfg-wf-pass))
++  src-wf-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aA == x = 0 /\\ x\' = 1\0aB == x = 1 /\\ x\' = 0\0aNext == A \\/ B\0aSpec == Init /\\ [][Next]_x /\\ WF_x(A)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-wf-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-verdict-wf-viol
  %+  expect-eq
    !>(`wain`~['VERDICT violated-property' 'EC 2116'])
  !>((live-verdict-lines:check src-wf-viol cfg-wf-viol))
::  leads-to under fairness holds (unblocked by the 8.2/8.3 ~> tableau + 8.4
::  fairness work); SPECIFICATION-form config keeps it out of PRODUCTION (unit-5
::  residue), but the differential runs through search-ctx (unit 8.9)
++  src-leadsto-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aGo == x = 0 /\\ x\' = 1\0aNext == Go \\/ (x = 1 /\\ x\' = 1)\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Go)\0aLive == (x = 0) ~> (x = 1)\0a====\0a'
++  cfg-leadsto-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-verdict-leadsto-pass
  %+  expect-eq
    !>(`wain`~['VERDICT ok' 'EC 0'])
  !>((live-verdict-lines:check src-leadsto-pass cfg-leadsto-pass))
--
