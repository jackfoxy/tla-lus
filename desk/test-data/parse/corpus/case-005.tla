---- MODULE Test ----
op ==
  \/  CASE 1 -> 2
      [] 3 -> 2
      [] OTHER -> 5
  \/ 6
====
