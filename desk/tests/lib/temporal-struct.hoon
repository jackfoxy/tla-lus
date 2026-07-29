::  Full structural projection (unit 8.1.3): render-struct must match
::  LivenessStruct's struct.txt (the OrderOfSolution.toString rendering)
::  minus the TABLEAU node count, for every liveness corpus case. Modules
::  are the exact corpus A.tla so Location spans match. GENERATED from
::  desk/test-data/liveness/<case>/{A.tla,A.txt,struct.txt} — do not edit.
/+  *test
/=  check  /lib/check
|%
++  src-back-to-state  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Next)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-back-to-state  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-struct-back-to-state
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 1' 'CHECKACTION 1' 'PEMS 1' 'TF' '/\\ []<>-line 7, col 14 to line 7, col 18 of module A' '/\\ []<>\\/ (-ENABLED <line 6, col 36 to line 6, col 39 of module A>_line 6, col 34 to line 6, col 34 of module A)' '       \\/ (<line 6, col 36 to line 6, col 39 of module A>_line 6, col 34 to line 6, col 34 of module A)' 'ENDTF'])
  !>((live-struct-full:check src-back-to-state cfg-back-to-state))
++  src-box-state  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == [](x = 0)\0a====\0a'
++  cfg-box-state  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-struct-box-state
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 0'])
  !>((live-struct-full:check src-box-state cfg-box-state))
++  src-boxdiamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == []<>(x = 1)\0a====\0a'
++  cfg-boxdiamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-struct-boxdiamond-stutter
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 1' 'PEMS 1' 'TF' '/\\ <>[]-line 7, col 14 to line 7, col 18 of module A' 'ENDTF'])
  !>((live-struct-full:check src-boxdiamond-stutter cfg-boxdiamond-stutter))
++  src-diamond-const-false  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aLive == <>FALSE\0a====\0a'
++  cfg-diamond-const-false  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-struct-diamond-const-false
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 0' 'PEMS 1' 'TF' '[]TRUE' 'ENDTF'])
  !>((live-struct-full:check src-diamond-const-false cfg-diamond-const-false))
++  src-diamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(x = 1)\0a====\0a'
++  cfg-diamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-struct-diamond-stutter
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 0' 'PEMS 1' 'TF' '[]-line 7, col 12 to line 7, col 16 of module A' 'ENDTF'])
  !>((live-struct-full:check src-diamond-stutter cfg-diamond-stutter))
++  src-leadsto-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aGo == x = 0 /\\ x\' = 1\0aNext == Go \\/ (x = 1 /\\ x\' = 1)\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Go)\0aLive == (x = 0) ~> (x = 1)\0a====\0a'
++  cfg-leadsto-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-struct-leadsto-pass
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 1' 'CHECKSTATE 0' 'CHECKACTION 1' 'PEMS 1' 'TF' '/\\ <>/\\ (line 8, col 10 to line 8, col 14 of module A)' '     /\\ ([]-line 8, col 21 to line 8, col 25 of module A)' '/\\ /\\ []<>\\/ (-ENABLED <line 7, col 36 to line 7, col 37 of module A>_line 7, col 34 to line 7, col 34 of module A)' '          \\/ (<line 7, col 36 to line 7, col 37 of module A>_line 7, col 34 to line 7, col 34 of module A)' 'ENDTF'])
  !>((live-struct-full:check src-leadsto-pass cfg-leadsto-pass))
++  src-leadsto-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ (x = 0 /\\ x\' = 1)\0aLive == (x = 0) ~> (x = 1)\0a====\0a'
++  cfg-leadsto-viol  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-struct-leadsto-viol
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 1' 'CHECKSTATE 0' 'CHECKACTION 0' 'PEMS 1' 'TF' '<>/\\ (line 7, col 10 to line 7, col 14 of module A)' '     /\\ ([]-line 7, col 21 to line 7, col 25 of module A)' 'ENDTF'])
  !>((live-struct-full:check src-leadsto-viol cfg-leadsto-viol))
++  src-letin-prop  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(LET y == 1 IN x = y)\0a====\0a'
++  cfg-letin-prop  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-struct-letin-prop
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 0' 'PEMS 1' 'TF' '[]-line 7, col 26 to line 7, col 30 of module A' 'ENDTF'])
  !>((live-struct-full:check src-letin-prop cfg-letin-prop))
++  src-multi-property  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aP1 == <>(x = 1)\0aP2 == []<>(x = 0)\0a====\0a'
++  cfg-multi-property  'INIT Init\0aNEXT Next\0aPROPERTY P1\0aPROPERTY P2\0a'
++  test-struct-multi-property
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 2' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 0' 'PEMS 1' 'TF' '[]-line 7, col 10 to line 7, col 14 of module A' 'ENDTF' '--- 1 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 1' 'PEMS 1' 'TF' '/\\ <>[]-line 8, col 12 to line 8, col 16 of module A' 'ENDTF'])
  !>((live-struct-full:check src-multi-property cfg-multi-property))
++  src-sf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ WF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-absent-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-struct-sf-absent-viol
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 3' 'PEMS 1' 'TF' '/\\ []-line 11, col 12 to line 11, col 16 of module A' '/\\ /\\ []<>\\/ (-ENABLED <line 10, col 36 to line 10, col 37 of module A>_line 10, col 34 to line 10, col 34 of module A)' '          \\/ (<line 10, col 36 to line 10, col 37 of module A>_line 10, col 34 to line 10, col 34 of module A)' '   /\\ []<>\\/ (-ENABLED <line 10, col 48 to line 10, col 49 of module A>_line 10, col 46 to line 10, col 46 of module A)' '          \\/ (<line 10, col 48 to line 10, col 49 of module A>_line 10, col 46 to line 10, col 46 of module A)' '   /\\ []<>\\/ (-ENABLED <line 10, col 60 to line 10, col 61 of module A>_line 10, col 58 to line 10, col 58 of module A)' '          \\/ (<line 10, col 60 to line 10, col 61 of module A>_line 10, col 58 to line 10, col 58 of module A)' 'ENDTF'])
  !>((live-struct-full:check src-sf-absent-viol cfg-sf-absent-viol))
++  src-sf-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ SF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-struct-sf-pass
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 4' 'PEMS 2' 'TF' '/\\ []-line 11, col 12 to line 11, col 16 of module A' '/\\ \\/ /\\ <>[]-ENABLED <line 10, col 60 to line 10, col 61 of module A>_line 10, col 58 to line 10, col 58 of module A' '      /\\ []<>\\/ (-ENABLED <line 10, col 36 to line 10, col 37 of module A>_line 10, col 34 to line 10, col 34 of module A)' '             \\/ (<line 10, col 36 to line 10, col 37 of module A>_line 10, col 34 to line 10, col 34 of module A)' '      /\\ []<>\\/ (-ENABLED <line 10, col 48 to line 10, col 49 of module A>_line 10, col 46 to line 10, col 46 of module A)' '             \\/ (<line 10, col 48 to line 10, col 49 of module A>_line 10, col 46 to line 10, col 46 of module A)' '   \\/ /\\ []<>\\/ (-ENABLED <line 10, col 36 to line 10, col 37 of module A>_line 10, col 34 to line 10, col 34 of module A)' '             \\/ (<line 10, col 36 to line 10, col 37 of module A>_line 10, col 34 to line 10, col 34 of module A)' '      /\\ []<>\\/ (-ENABLED <line 10, col 48 to line 10, col 49 of module A>_line 10, col 46 to line 10, col 46 of module A)' '             \\/ (<line 10, col 48 to line 10, col 49 of module A>_line 10, col 46 to line 10, col 46 of module A)' '      /\\ []<><line 10, col 60 to line 10, col 61 of module A>_line 10, col 58 to line 10, col 58 of module A' 'ENDTF'])
  !>((live-struct-full:check src-sf-pass cfg-sf-pass))
++  src-spec-fairness-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 2 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 2 /\\ x\' = 2)\0aFairness == WF_x(Inc)\0aSpec == Init /\\ [][Next]_x /\\ Fairness\0aLive == <>(x = 2)\0a====\0a'
++  cfg-spec-fairness-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-struct-spec-fairness-pass
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 1' 'PEMS 1' 'TF' '/\\ []-line 9, col 12 to line 9, col 16 of module A' '/\\ /\\ []<>\\/ (-ENABLED <line 7, col 18 to line 7, col 20 of module A>_line 7, col 16 to line 7, col 16 of module A)' '          \\/ (<line 7, col 18 to line 7, col 20 of module A>_line 7, col 16 to line 7, col 16 of module A)' 'ENDTF'])
  !>((live-struct-full:check src-spec-fairness-pass cfg-spec-fairness-pass))
++  src-symmetry-live  '---- MODULE A ----\0aEXTENDS TLC\0aVARIABLE x\0aCONSTANT S\0aInit == x \\in S\0aNext == \\E s \\in S : x\' = s\0aPerms == Permutations(S)\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Next)\0aLive == []<>(\\E s \\in S : x = s)\0a====\0a'
++  cfg-symmetry-live  'SPECIFICATION Spec\0aPROPERTY Live\0aSYMMETRY Perms\0aCONSTANT S = {a, b}\0a'
++  test-struct-symmetry-live
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 2' 'PEMS 1' 'TF' '/\\ <>[]-line 9, col 14 to line 9, col 31 of module A' '/\\ []<>\\/ (-ENABLED <line 8, col 36 to line 8, col 39 of module A>_line 8, col 34 to line 8, col 34 of module A)' '       \\/ (<line 8, col 36 to line 8, col 39 of module A>_line 8, col 34 to line 8, col 34 of module A)' 'ENDTF'])
  !>((live-struct-full-raw:check src-symmetry-live cfg-symmetry-live))
++  src-wf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 3 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 3 /\\ x\' = 3)\0aLive == <>(x = 3)\0a====\0a'
++  cfg-wf-absent-viol  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-struct-wf-absent-viol
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 0' 'PEMS 1' 'TF' '[]-line 7, col 12 to line 7, col 16 of module A' 'ENDTF'])
  !>((live-struct-full:check src-wf-absent-viol cfg-wf-absent-viol))
++  src-wf-pass  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 3 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 3 /\\ x\' = 3)\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Inc)\0aLive == <>(x = 3)\0a====\0a'
++  cfg-wf-pass  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-struct-wf-pass
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 0' 'CHECKACTION 1' 'PEMS 1' 'TF' '/\\ []-line 8, col 12 to line 8, col 16 of module A' '/\\ /\\ []<>\\/ (-ENABLED <line 7, col 36 to line 7, col 38 of module A>_line 7, col 34 to line 7, col 34 of module A)' '          \\/ (<line 7, col 36 to line 7, col 38 of module A>_line 7, col 34 to line 7, col 34 of module A)' 'ENDTF'])
  !>((live-struct-full:check src-wf-pass cfg-wf-pass))
++  src-wf-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aA == x = 0 /\\ x\' = 1\0aB == x = 1 /\\ x\' = 0\0aNext == A \\/ B\0aSpec == Init /\\ [][Next]_x /\\ WF_x(A)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-wf-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-struct-wf-viol
  %+  expect-eq
    !>(`wain`~['LIVESTRUCT' 'OOS 1' '--- 0 ---' 'PROMISES 0' 'CHECKSTATE 1' 'CHECKACTION 1' 'PEMS 1' 'TF' '/\\ []<>-line 9, col 14 to line 9, col 18 of module A' '/\\ []<>\\/ (-ENABLED <line 8, col 36 to line 8, col 36 of module A>_line 8, col 34 to line 8, col 34 of module A)' '       \\/ (<line 8, col 36 to line 8, col 36 of module A>_line 8, col 34 to line 8, col 34 of module A)' 'ENDTF'])
  !>((live-struct-full:check src-wf-viol cfg-wf-viol))
--
