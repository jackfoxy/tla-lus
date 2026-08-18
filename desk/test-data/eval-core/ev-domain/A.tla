---- MODULE A ----
EXTENDS Integers, Sequences
FromIv == DOMAIN [i \in 1..3 |-> i]
FromSet == DOMAIN [i \in {1, 2, 3} |-> i]
FromSetGap == DOMAIN [i \in {1, 3} |-> i]
FromZero == DOMAIN [i \in 0..2 |-> i]
FromTup == DOMAIN <<7, 8, 9>>
FromRcd == DOMAIN [a |-> 1, b |-> 2]
Neg == DOMAIN [i \in (-2)..1 |-> i]
Single == DOMAIN [i \in 2..2 |-> i]
EmptyD == DOMAIN [i \in {} |-> i]
Named == [i \in 1..4 |-> i * i]
NamedDom == DOMAIN Named
====
