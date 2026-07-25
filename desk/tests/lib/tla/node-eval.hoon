::  node-eval parity: 37 REPL goldens through the semantic-node evaluator.
::  Expected values are tlc2.REPL output at the pinned tlaplus commit.
/+  *test
/=  ne  /lib/tla/tlc/node-eval
|%
::
++  test-neval-000
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne 'TRUE'))
::
++  test-neval-001
  %+  expect-eq
    !>  'FALSE'
  !>  (crip (eval-text:ne 'FALSE'))
::
++  test-neval-002
  %+  expect-eq
    !>  '7'
  !>  (crip (eval-text:ne '1 + 2 * 3'))
::
++  test-neval-003
  %+  expect-eq
    !>  '3'
  !>  (crip (eval-text:ne '10 \\div 3'))
::
++  test-neval-004
  %+  expect-eq
    !>  '1'
  !>  (crip (eval-text:ne '10 % 3'))
::
++  test-neval-005
  %+  expect-eq
    !>  '32'
  !>  (crip (eval-text:ne '2 ^ 5'))
::
++  test-neval-006
  %+  expect-eq
    !>  '"hello"'
  !>  (crip (eval-text:ne '"hello"'))
::
++  test-neval-007
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '1 = 1'))
::
++  test-neval-008
  %+  expect-eq
    !>  'FALSE'
  !>  (crip (eval-text:ne '1 = 2'))
::
++  test-neval-009
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '1 < 2'))
::
++  test-neval-010
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '3 > 2'))
::
++  test-neval-011
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '1 /= 2'))
::
++  test-neval-012
  %+  expect-eq
    !>  'FALSE'
  !>  (crip (eval-text:ne 'TRUE /\\ FALSE'))
::
++  test-neval-013
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne 'TRUE \\/ FALSE'))
::
++  test-neval-014
  %+  expect-eq
    !>  'FALSE'
  !>  (crip (eval-text:ne '~TRUE'))
::
++  test-neval-015
  %+  expect-eq
    !>  'FALSE'
  !>  (crip (eval-text:ne 'TRUE => FALSE'))
::
++  test-neval-016
  %+  expect-eq
    !>  '{1, 2, 3}'
  !>  (crip (eval-text:ne '{1, 2, 3}'))
::
++  test-neval-017
  %+  expect-eq
    !>  '{1, 2, 3}'
  !>  (crip (eval-text:ne '{3, 1, 2, 2}'))
::
++  test-neval-018
  %+  expect-eq
    !>  '{1, 2, 3}'
  !>  (crip (eval-text:ne '{1, 2} \\cup {2, 3}'))
::
++  test-neval-019
  %+  expect-eq
    !>  '{2, 3}'
  !>  (crip (eval-text:ne '{1, 2, 3} \\cap {2, 3, 4}'))
::
++  test-neval-020
  %+  expect-eq
    !>  '{1, 3}'
  !>  (crip (eval-text:ne '{1, 2, 3} \\ {2}'))
::
++  test-neval-021
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '2 \\in {1, 2, 3}'))
::
++  test-neval-022
  %+  expect-eq
    !>  'FALSE'
  !>  (crip (eval-text:ne '5 \\in {1, 2, 3}'))
::
++  test-neval-023
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '{1, 2} \\subseteq {1, 2, 3}'))
::
++  test-neval-024
  %+  expect-eq
    !>  '<<1, 2, 3>>'
  !>  (crip (eval-text:ne '<<1, 2, 3>>'))
::
++  test-neval-025
  %+  expect-eq
    !>  '[a |-> 1, b |-> 2]'
  !>  (crip (eval-text:ne '[a |-> 1, b |-> 2]'))
::
++  test-neval-026
  %+  expect-eq
    !>  '1..5'
  !>  (crip (eval-text:ne '1..5'))
::
++  test-neval-027
  %+  expect-eq
    !>  '{{}, {1}, {2}, {1, 2}}'
  !>  (crip (eval-text:ne 'SUBSET {1, 2}'))
::
++  test-neval-028
  %+  expect-eq
    !>  '{1, 2, 3}'
  !>  (crip (eval-text:ne 'UNION {{1, 2}, {2, 3}}'))
::
++  test-neval-029
  %+  expect-eq
    !>  '{"a", "b"}'
  !>  (crip (eval-text:ne 'DOMAIN [a |-> 1, b |-> 2]'))
::
++  test-neval-030
  %+  expect-eq
    !>  '1'
  !>  (crip (eval-text:ne 'IF 3 > 2 THEN 1 ELSE 0'))
::
++  test-neval-031
  %+  expect-eq
    !>  '3'
  !>  (crip (eval-text:ne 'Cardinality({1, 2, 3})'))
::
++  test-neval-032
  %+  expect-eq
    !>  '{3, 4}'
  !>  (crip (eval-text:ne '{x \\in {1, 2, 3, 4} : x > 2}'))
::
++  test-neval-033
  %+  expect-eq
    !>  '{1, 4, 9}'
  !>  (crip (eval-text:ne '{x * x : x \\in {1, 2, 3}}'))
::
++  test-neval-034
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '\\A x \\in {1, 2, 3} : x > 0'))
::
++  test-neval-035
  %+  expect-eq
    !>  'TRUE'
  !>  (crip (eval-text:ne '\\E x \\in {1, 2, 3} : x > 2'))
::
++  test-neval-036
  %+  expect-eq
    !>  '1'
  !>  (crip (eval-text:ne '[a |-> 1, b |-> 2].a'))
--
