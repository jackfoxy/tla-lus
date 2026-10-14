---- MODULE spec ----
EXTENDS Naturals, TLC
K == IF PrintT("const K") THEN 7 ELSE 0
VARIABLE x
Init == x = 0 /\ PrintT(<<"init", x>>)
Next == x < 2 /\ x' = x + 1 /\ PrintT(<<"next", x, x'>>)
Inv == PrintT(<<"inv", x>>)
ASSUME Print("assume", K = K)
ASSUME \E i \in 1..3 : PrintT(<<"ex", i>>) /\ i = 2
====
