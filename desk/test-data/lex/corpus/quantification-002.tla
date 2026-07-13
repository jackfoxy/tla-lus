---- MODULE Test ----
op == \A <<x, y>> \in Nat, <<z>> \in Int, <<a, b, c>> \in Real : FALSE
op == \E <<x, y>> \in Nat, <<a, b>> \in Int : TRUE
====
