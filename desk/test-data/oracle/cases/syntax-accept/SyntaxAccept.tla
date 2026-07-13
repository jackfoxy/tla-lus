---- MODULE SyntaxAccept ----
EXTENDS Naturals
VARIABLE st
Rec == [a |-> 1, b |-> 2]
Upd(r) == [r EXCEPT !.a = @ + 1]
Fun == [i \in 1..3 |-> i * i]
Quant == \A i \in 1..3 : \E j \in 1..3 : i <= j
Lets ==
  LET sq(i) == i * i
      three == 3
  IN  sq(three)
Init == st = 0
Next == st' = st + 1
Spec == Init /\ [][Next]_st
====
