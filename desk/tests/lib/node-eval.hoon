::  node-eval parity: 37 REPL goldens through the semantic-node evaluator.
::  Expected values are tlc2.REPL output at the pinned tlaplus commit.
/+  *test
/=  ne  /lib/node-eval
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
::
::  R4.Q3: the sorted-input shortcut in `+norm-set` and `+normalize` must
::  not trust `+vlth` across an interval and a set of the same elements:
::  this list rises, yet its first and last tuples are equal
++  test-q3-rising-skips-intervals
  %+  expect-eq
    !>  '2'
  !>  (crip (eval-text:ne 'Cardinality({<<1..2>>, <<5>>, <<{1, 2}>>})'))
::
::  R4.Q3: `+equal`'s fast paths stay exact across representations
++  test-q3-equal-across-forms
  %+  expect-eq
    !>  'TRUE'
  !>  %-  crip
      %-  eval-text:ne
      %+  rap  3
      :~  '/\\ <<1..2>> = <<{1, 2}>>  /\\ (1..0) = (5..4)  /\\ 1..3 # 1..2'
          '  /\\ [i \\in 1..2 |-> i] = <<1, 2>>'
          '  /\\ [a |-> 1, b |-> 2] = [b |-> 2, a |-> 1]'
          '  /\\ {<<1, 2>>, <<1, 2>>} = {<<1, 2>>}'
      ==
::
::  R4.Q4: a recursive function over several binders, one of them `Nat`
::  (TransitiveClosure's `CR[n \in Nat, v \in S]`), applied lazily
++  test-q4-recfcn-two-binders-nat
  %+  expect-eq
    !>  '5'
  !>  %-  crip
      %-  eval-text:ne
      'LET f[n \\in Nat, v \\in {1, 2}] == IF n = 0 THEN v ELSE f[n - 1, v] + 1 IN f[3, 2]'
::
++  test-q4-recfcn-two-binders-cross
  %+  expect-eq
    !>  '<<TRUE, FALSE>>'
  !>  %-  crip
      %-  eval-text:ne
      %+  rap  3
      :~  'LET g[n \\in Nat, v \\in {1, 2, 3}] == IF n = 0 THEN v = 1 '
          'ELSE g[n - 1, v] \\/ \\E u \\in {1, 2, 3} : g[n - 1, u] /\\ u + 1 = v '
          'IN <<g[2, 3], g[1, 3]>>'
      ==
::
::  R4.Q4: over finite binders the whole product is swept
++  test-q4-recfcn-two-binders-finite
  %+  expect-eq
    !>  '4'
  !>  %-  crip
      %-  eval-text:ne
      'LET f[n \\in 0..2, v \\in {1, 2}] == IF n = 0 THEN v ELSE f[n - 1, v] * 2 IN f[2, 1]'
::
::  R4.2au: CHOOSE takes the first element in NORMALIZED order, whatever the
::  domain is built from (tlc2 normalizes it, OPCODE_bc). A `\cup` used to
::  stream its operands in turn. Pin: <<1, 2, 6, 3, 1>>
++  test-choose-normalizes-cup
  %+  expect-eq
    !>  '<<1, 2, 6, 3, 1>>'
  !>  %-  crip
      %-  eval-text:ne
      %+  rap  3
      :~  '<<CHOOSE y \\in {3} \\cup {1} : TRUE, '
          'CHOOSE y \\in UNION {{5, 4}, {2}} : TRUE, '
          'CHOOSE y \\in ({7} \\cup {6}) \\ {} : TRUE, '
          'CHOOSE y \\in {3, 9} \\cup {1, 8} : y > 2, '
          'CHOOSE y \\in (2..3) \\cup {1} : TRUE>>'
      ==
--
