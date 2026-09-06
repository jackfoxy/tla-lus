---- MODULE A ----
CONSTANT c
THEOREM Foo == c = 0
  OBVIOUS
THEOREM Bar == c = 1
  <1>1. c = 1
    OBVIOUS
  <1>2. QED
USE Foo
HIDE Bar
====
