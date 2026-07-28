::  Temporal-property normalization (unit 8.1): the live-expression / oos / pem
::  decomposition count projection must match LivenessStruct (struct.txt), minus
::  the TABLEAU node count (unit 8.2). Driven through check.hoon's live-struct.
/+  *test
/=  check  /lib/check
|%
++  exp1
  ::  the expected count projection for a single OrderOfSolution
  |=  [pr=@ud cs=@ud ca=@ud pm=@ud]
  ^-  wain
  :~  'OOS 1'
      '--- 0 ---'
      (crip "PROMISES {(scow %ud pr)}")
      (crip "CHECKSTATE {(scow %ud cs)}")
      (crip "CHECKACTION {(scow %ud ca)}")
      (crip "PEMS {(scow %ud pm)}")
  ==
::
++  cfg-in-next  'INIT Init\0aNEXT Next\0aPROPERTY Live\0a'
++  cfg-spec     'SPECIFICATION Spec\0aPROPERTY Live\0a'
::
::  <>P (no fairness): -<>P = []-P, one tableau formula, no fairness bins.
++  mod-diamond
  '''
  ---- MODULE A ----
  EXTENDS Integers
  VARIABLE x
  Init == x = 0
  Next == \/ x' = x
          \/ x' = 1
  Live == <>(x = 1)
  ====
  '''
++  test-diamond
  (expect-eq !>((exp1 0 0 0 1)) !>((live-struct:check mod-diamond cfg-in-next)))
::
::  []<>P: -[]<>P = <>[]-P, classified <>[]state? no -- <>[]-P has action-free
::  state body, so it lands as an EAAction check (checkAction 1).
++  mod-boxdiamond
  '''
  ---- MODULE A ----
  EXTENDS Integers
  VARIABLE x
  Init == x = 0
  Next == \/ x' = x
          \/ x' = 1
  Live == []<>(x = 1)
  ====
  '''
++  test-boxdiamond
  (expect-eq !>((exp1 0 0 1 1)) !>((live-struct:check mod-boxdiamond cfg-in-next)))
::
::  P ~> Q: the tableau formula <>(P /\ []-Q) carries one promise.
++  mod-leadsto
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == \/ x' = x
          \/ (x = 0 /\ x' = 1)
  Live == (x = 0) ~> (x = 1)
  ====
  '''
++  test-leadsto
  (expect-eq !>((exp1 1 0 0 1)) !>((live-struct:check mod-leadsto cfg-in-next)))
::
::  WF_x(Inc) fairness + <>P: one pem, one action check ([]<>(-EN \/ A)).
++  mod-wf
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Inc == x < 3 /\ x' = x + 1
  Next == Inc \/ (x = 3 /\ x' = 3)
  Spec == Init /\ [][Next]_x /\ WF_x(Inc)
  Live == <>(x = 3)
  ====
  '''
++  test-wf
  (expect-eq !>((exp1 0 0 1 1)) !>((live-struct:check mod-wf cfg-spec)))
::
::  SF splits into two disjuncts sharing a tf -> two pems, four action checks.
++  mod-sf
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Ay == x = 0 /\ x' = 1
  By == x = 1 /\ x' = 0
  Cy == x = 1 /\ x' = 2
  Done == x = 2 /\ x' = 2
  Next == Ay \/ By \/ Cy \/ Done
  Spec == Init /\ [][Next]_x /\ WF_x(Ay) /\ WF_x(By) /\ SF_x(Cy)
  Live == <>(x = 2)
  ====
  '''
++  test-sf
  (expect-eq !>((exp1 0 0 4 2)) !>((live-struct:check mod-sf cfg-spec)))
::
::  <>[]P with WF fairness: a state check ([]<>state) plus the fairness action.
++  mod-back
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = 1 - x
  Spec == Init /\ [][Next]_x /\ WF_x(Next)
  Live == <>[](x = 1)
  ====
  '''
++  test-back
  (expect-eq !>((exp1 0 1 1 1)) !>((live-struct:check mod-back cfg-spec)))
::
::  []P over a pure state predicate routes to an invariant, not a temporal
::  property -> zero OrderOfSolutions.
++  mod-box-state
  '''
  ---- MODULE A ----
  EXTENDS Integers
  VARIABLE x
  Init == x = 0
  Next == \/ x' = x
          \/ x' = 1
  Live == [](x = 0)
  ====
  '''
++  test-box-state
  (expect-eq !>(`wain`~['OOS 0']) !>((live-struct:check mod-box-state cfg-in-next)))
::
::  The same WF spec without the fairness (INIT/NEXT): the property alone,
::  one tableau formula, no fairness bins.
++  test-wf-absent
  (expect-eq !>((exp1 0 0 0 1)) !>((live-struct:check mod-wf cfg-in-next)))
::
::  <>[]P violated despite WF: []<>state check + the WF action check.
++  mod-wf-viol
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  A == x = 0 /\ x' = 1
  B == x = 1 /\ x' = 0
  Next == A \/ B
  Spec == Init /\ [][Next]_x /\ WF_x(A)
  Live == <>[](x = 1)
  ====
  '''
++  test-wf-viol
  (expect-eq !>((exp1 0 1 1 1)) !>((live-struct:check mod-wf-viol cfg-spec)))
::
::  Three WF conjuncts, no cross-product (all AEAction): one pem, three checks.
++  mod-sf-absent
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Ay == x = 0 /\ x' = 1
  By == x = 1 /\ x' = 0
  Cy == x = 1 /\ x' = 2
  Done == x = 2 /\ x' = 2
  Next == Ay \/ By \/ Cy \/ Done
  Spec == Init /\ [][Next]_x /\ WF_x(Ay) /\ WF_x(By) /\ WF_x(Cy)
  Live == <>(x = 2)
  ====
  '''
++  test-sf-absent
  (expect-eq !>((exp1 0 0 3 1)) !>((live-struct:check mod-sf-absent cfg-spec)))
::
::  P ~> Q under fairness: one promise (from the tf) plus the WF action check.
++  mod-leadsto-pass
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Go == x = 0 /\ x' = 1
  Next == Go \/ (x = 1 /\ x' = 1)
  Spec == Init /\ [][Next]_x /\ WF_x(Go)
  Live == (x = 0) ~> (x = 1)
  ====
  '''
++  test-leadsto-pass
  (expect-eq !>((exp1 1 0 1 1)) !>((live-struct:check mod-leadsto-pass cfg-spec)))
::
::  Fairness reached through a named arity-0 operator (Fairness == WF_x(Inc)):
::  decompose-spec expands the operator body to recover the WF conjunct.
++  mod-spec-fair
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Inc == x < 2 /\ x' = x + 1
  Next == Inc \/ (x = 2 /\ x' = 2)
  Fairness == WF_x(Inc)
  Spec == Init /\ [][Next]_x /\ Fairness
  Live == <>(x = 2)
  ====
  '''
++  test-spec-fair
  (expect-eq !>((exp1 0 0 1 1)) !>((live-struct:check mod-spec-fair cfg-spec)))
::
::  symmetry + liveness: search-ctx typed-rejects this combination, so the
::  normalization is exercised through the raw path. []<>P under WF fairness:
::  one state-derived action check plus the fairness action check (OOS 1,
::  checkAction 2, one pem).
++  mod-symmetry-live
  '''
  ---- MODULE A ----
  EXTENDS TLC
  VARIABLE x
  CONSTANT S
  Init == x \in S
  Next == \E s \in S : x' = s
  Perms == Permutations(S)
  Spec == Init /\ [][Next]_x /\ WF_x(Next)
  Live == []<>(\E s \in S : x = s)
  ====
  '''
++  cfg-symmetry
  'SPECIFICATION Spec\0aPROPERTY Live\0aSYMMETRY Perms\0aCONSTANT S = {a, b}\0a'
++  test-symmetry-live
  %+  expect-eq
    !>((exp1 0 0 2 1))
  !>((live-struct-raw:check mod-symmetry-live cfg-symmetry))
--
