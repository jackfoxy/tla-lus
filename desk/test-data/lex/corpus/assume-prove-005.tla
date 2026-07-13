---- MODULE Test ----
THEOREM thm ==
  ASSUME
    NEW f,
    1 + 2,
    /\ 1
    /\ 2,
    lbl :: ASSUME P PROVE Q
  PROVE C
OMITTED
====
