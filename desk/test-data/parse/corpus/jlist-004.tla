---- MODULE Test ----
conj ==
  /\ lbl :: A
  /\ B := C
  /\ D ::= E

disj ==
  \/ lbl :: A
  \/ B := C
  \/ D ::= E
====
