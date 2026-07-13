---- MODULE Test ----
op1 ==
  /\ 1
  /\ 2
      ASSUME x

op2 ==
  /\ 3
  /\ 4
      LOCAL INSTANCE ModuleName

op3 ==
  /\ 5
  /\ 6
      -----------------

op4 ==
  /\ 7
  /\ 8
      ---- MODULE Nested ----
      ====

op5 ==
  /\ 9
  /\ 10
      VARIABLES x, y
====
