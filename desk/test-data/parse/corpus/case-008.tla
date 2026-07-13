---- MODULE Test ----
op ==
  CASE A ->
    /\ CASE B -> C
       [] D -> E
  [] F -> G

op2 ==
  CASE H ->
    /\ CASE I -> J
       [] OTHER -> K
  [] L -> M

op3 ==
  CASE N ->
    /\ CASE O -> P
       [] Q -> R
    /\ S
  [] T -> U
====
