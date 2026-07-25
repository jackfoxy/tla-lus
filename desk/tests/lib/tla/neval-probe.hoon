::  probe: constructs beyond the 37 REPL baseline, through node-eval.
/+  *test
/=  ne  /lib/tla/tlc/node-eval
|%
++  ck
  |=  [txt=@t want=@t]
  ^-  tang
  %+  expect-eq
    !>  want
  !>  (crip (eval-dbg:ne txt))
::
++  test-fcncon      (ck '[i \\in 1..3 |-> i]' '<<1, 2, 3>>')
++  test-fcncon-sq   (ck '[i \\in 1..3 |-> i * i]' '<<1, 4, 9>>')
++  test-except-at   (ck '[[i \\in 1..3 |-> i] EXCEPT ![2] = @ + 100]' '<<1, 102, 3>>')
++  test-except-rcd  (ck '[[a |-> 1, b |-> 2] EXCEPT !.b = 9]' '[a |-> 1, b |-> 9]')
++  test-setofall    (ck '{x * x : x \\in 1..3}' '{1, 4, 9}')
++  test-filter      (ck '{x \\in 1..6 : x > 3}' '{4, 5, 6}')
++  test-case-other  (ck 'CASE 1 = 2 -> 10 [] 1 = 1 -> 20 [] OTHER -> 30' '20')
++  test-case-def    (ck 'CASE 1 = 2 -> 10 [] OTHER -> 30' '30')
++  test-forall-t    (ck '\\A x \\in 1..3 : x > 0' 'TRUE')
++  test-exists-f    (ck '\\E x \\in 1..3 : x > 9' 'FALSE')
++  test-choose      (ck 'CHOOSE x \\in 1..10 : x * x = 25' '5')
++  test-setoffcns   (ck '[1..2 -> {5, 6}]' '{<<5, 5>>, <<5, 6>>, <<6, 5>>, <<6, 6>>}')
++  test-nested-let  (ck 'LET y == 3 IN y + 4' '7')
++  test-ifthen      (ck 'IF 3 > 2 THEN 1 ELSE 0' '1')
--
