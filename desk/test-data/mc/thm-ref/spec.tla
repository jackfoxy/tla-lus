---- MODULE spec ----
EXTENDS Naturals
---- MODULE Inner ----
EXTENDS Naturals
CONSTANT K
LEMMA Pos == \A i \in 0..K : i <= K
====
CONSTANT N
P(k) == INSTANCE Inner WITH K <- k
THEOREM T1 == N + 1 > N
VARIABLE x
Init == x = IF T1 /\ (\A k \in 1..N : P(k)!Pos) THEN 1 ELSE 0
Next == UNCHANGED x
Inv == x = 0
ASSUME T1
====
