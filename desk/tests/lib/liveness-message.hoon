::  TLC console diagnostic for a temporal violation (unit 8.7.1):
::  live-message-lines renders the `Temporal property … was violated.` message,
::  the numbered counter-example trace (per-action getActions labels), a
::  Stuttering or `Back to state N` closer, and the reachability counts, matching
::  tlc2.TLC's console output byte-for-byte (blank lines / timestamp trimmed).
::  Covers stuttering, back-to-state, the ~> tableau (leadsto-viol), the LET-leaf
::  (letin-prop), the multi-step sink (wf-absent-viol), and the first-violated
::  property name (multi-property -> P1).
/+  *test
/=  check  /lib/check
|%
++  src-diamond-stutter  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(x = 1)\0a====\0a'
++  cfg-diamond-stutter  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-message-diamond-stutter
  %+  expect-eq
    !>(`wain`~['Error: Temporal property Live was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: Stuttering' '5 states generated, 2 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 2.'])
  !>((live-message-lines:check src-diamond-stutter cfg-diamond-stutter))
++  src-back-to-state  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = 1 - x\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Next)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-back-to-state  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-message-back-to-state
  %+  expect-eq
    !>(`wain`~['Error: Temporal property Live was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: <Next line 5, col 9 to line 5, col 18 of module A>' 'x = 1' 'Back to state 1: <Next line 5, col 9 to line 5, col 18 of module A>' '3 states generated, 2 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 2.'])
  !>((live-message-lines:check src-back-to-state cfg-back-to-state))
++  src-wf-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aA == x = 0 /\\ x\' = 1\0aB == x = 1 /\\ x\' = 0\0aNext == A \\/ B\0aSpec == Init /\\ [][Next]_x /\\ WF_x(A)\0aLive == <>[](x = 1)\0a====\0a'
++  cfg-wf-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-message-wf-viol
  %+  expect-eq
    !>(`wain`~['Error: Temporal property Live was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: <A line 5, col 6 to line 5, col 20 of module A>' 'x = 1' 'Back to state 1: <B line 6, col 6 to line 6, col 20 of module A>' '3 states generated, 2 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 2.'])
  !>((live-message-lines:check src-wf-viol cfg-wf-viol))
++  src-sf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aAy == x = 0 /\\ x\' = 1\0aBy == x = 1 /\\ x\' = 0\0aCy == x = 1 /\\ x\' = 2\0aDone == x = 2 /\\ x\' = 2\0aNext == Ay \\/ By \\/ Cy \\/ Done\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Ay) /\\ WF_x(By) /\\ WF_x(Cy)\0aLive == <>(x = 2)\0a====\0a'
++  cfg-sf-absent-viol  'SPECIFICATION Spec\0aPROPERTY Live\0a'
++  test-message-sf-absent-viol
  %+  expect-eq
    !>(`wain`~['Error: Temporal property Live was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: <Ay line 5, col 7 to line 5, col 21 of module A>' 'x = 1' 'Back to state 1: <By line 6, col 7 to line 6, col 21 of module A>' '5 states generated, 3 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 3.'])
  !>((live-message-lines:check src-sf-absent-viol cfg-sf-absent-viol))
++  src-leadsto-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ (x = 0 /\\ x\' = 1)\0aLive == (x = 0) ~> (x = 1)\0a====\0a'
++  cfg-leadsto-viol  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-message-leadsto-viol
  %+  expect-eq
    !>(`wain`~['Error: Temporal property Live was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: Stuttering' 'Warning: The stuttering counterexample above may be caused by the absence of a behavior specification (SPECIFICATION). Only INIT and NEXT have been provided, so TLC permits infinite stuttering. To rule out such counterexamples, use SPECIFICATION Spec, with Spec asserting a suitable fairness constraint (compare Chapter 8, page 87ff of Specifying Systems at https://lamport.azurewebsites.net/tla/book.html).' '4 states generated, 2 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 2.'])
  !>((live-message-lines:check src-leadsto-viol cfg-leadsto-viol))
++  src-wf-absent-viol  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aInc == x < 3 /\\ x\' = x + 1\0aNext == Inc \\/ (x = 3 /\\ x\' = 3)\0aLive == <>(x = 3)\0a====\0a'
++  cfg-wf-absent-viol  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-message-wf-absent-viol
  %+  expect-eq
    !>(`wain`~['Error: Temporal property Live was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: <Inc line 5, col 8 to line 5, col 26 of module A>' 'x = 1' 'State 3: <Inc line 5, col 8 to line 5, col 26 of module A>' 'x = 2' 'State 4: Stuttering' '5 states generated, 4 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 4.'])
  !>((live-message-lines:check src-wf-absent-viol cfg-wf-absent-viol))
++  src-letin-prop  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aLive == <>(LET y == 1 IN x = y)\0a====\0a'
++  cfg-letin-prop  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  test-message-letin-prop
  %+  expect-eq
    !>(`wain`~['Error: Temporal property Live was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: Stuttering' '5 states generated, 2 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 2.'])
  !>((live-message-lines:check src-letin-prop cfg-letin-prop))
++  src-multi-property  '---- MODULE A ----\0aEXTENDS Integers\0aVARIABLE x\0aInit == x = 0\0aNext == \\/ x\' = x\0a        \\/ x\' = 1\0aP1 == <>(x = 1)\0aP2 == []<>(x = 0)\0a====\0a'
++  cfg-multi-property  'INIT Init\0aNEXT Next\0aPROPERTY P1\0aPROPERTY P2\0a'
++  test-message-multi-property
  %+  expect-eq
    !>(`wain`~['Error: Temporal property P1 was violated.' 'Error: The following behavior constitutes a counter-example:' 'State 1: <Initial predicate>' 'x = 0' 'State 2: Stuttering' '5 states generated, 2 distinct states found, 0 states left on queue.' 'The depth of the complete state graph search is 2.'])
  !>((live-message-lines:check src-multi-property cfg-multi-property))
::  Symmetry + a temporal property (unit 8.7.2): APPROVED DIFFERENCE. TLC prints
::  warning 2279 and CONTINUES on the symmetry-reduced graph (out.txt = VERDICT
::  ok / WARN 2279). The port cannot yet run liveness on this spec class (the
::  model-value \E action errors "variable unassigned"), so it type-rejects with
::  the pinned 2279 text. This asserts the diagnostic content, NOT an oracle
::  match; full warn-and-continue awaits liveness-under-model-values support.
++  src-symmetry-live  '---- MODULE A ----\0aEXTENDS TLC\0aVARIABLE x\0aCONSTANT S\0aInit == x \\in S\0aNext == \\E s \\in S : x\' = s\0aPerms == Permutations(S)\0aSpec == Init /\\ [][Next]_x /\\ WF_x(Next)\0aLive == []<>(\\E s \\in S : x = s)\0a====\0a'
++  cfg-symmetry-live  'SPECIFICATION Spec\0aPROPERTY Live\0aSYMMETRY Perms\0aCONSTANT S = {a, b}\0a'
++  test-message-symmetry-live-rejected
  %+  expect-eq
    !>(`wain`~['Error: Declaring symmetry during liveness checking is dangerous. It might cause TLC to miss violations of the stated liveness properties. Please check liveness without symmetry defined.'])
  !>((live-message-lines:check src-symmetry-live cfg-symmetry-live))
--
