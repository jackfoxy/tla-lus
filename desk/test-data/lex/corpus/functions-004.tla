---- MODULE Test ----
op == [
  x, y \in Nat, <<a, b>> \in
    /\ A
    /\ B
      |->
        /\ A
        /\ B
            ]
====
