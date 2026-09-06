---- MODULE Test ----
INSTANCE M WITH
  A <- /\ 1,
  B <- /\ 2,
  C <- /\ \/ 3
          \/ 4,
  D <- \/ 5
====
