::  Stuttering lasso trace (unit 8.6): live-lasso-lines matches the out.txt
::  CLASS/LOOP/TRACE/STATE projection for the stuttering-at-init cases.
::  Back-to-state lassos (per-action labels) are a follow-on.  GENERATED.
/+  *test
/=  check  /lib/check
|%
++  src-diamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(x = 1)\0a====\0a'
++  cfg-diamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-lasso-diamond-stutter
  %+  expect-eq
    !>(`wain`~['CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-diamond-stutter cfg-diamond-stutter))
++  src-boxdiamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == []<>(x = 1)\0a====\0a'
++  cfg-boxdiamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-lasso-boxdiamond-stutter
  %+  expect-eq
    !>(`wain`~['CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-boxdiamond-stutter cfg-boxdiamond-stutter))
++  src-diamond-const-false  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aLive == <>FALSE\0a====\0a'
++  cfg-diamond-const-false  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-lasso-diamond-const-false
  %+  expect-eq
    !>(`wain`~['CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-diamond-const-false cfg-diamond-const-false))
++  src-multi-property  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aP1 == <>(x = 1)\0aP2 == []<>(x = 0)\0a====\0a'
++  cfg-multi-property  'INIT Init\0aNEXT Next\0aPROPERTY P1\0aPROPERTY P2\0a'
++  test-lasso-multi-property
  %+  expect-eq
    !>(`wain`~['CLASS stuttering' 'LOOP 1' 'TRACE 2' 'STATE 1 0xd0ba3e880dcdd983' 'LABEL <Initial predicate>' 'x = 0' 'ENDSTATE' 'STATE 2 -1' 'LABEL Stuttering' 'ENDSTATE'])
  !>((live-lasso-lines:check src-multi-property cfg-multi-property))
--
