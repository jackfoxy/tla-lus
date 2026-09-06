---- MODULE Test ----
op ==
  /\ CASE 1 ->
      /\ 2
      /\ 3
        [] 4 -> 5
  /\ 6
====
