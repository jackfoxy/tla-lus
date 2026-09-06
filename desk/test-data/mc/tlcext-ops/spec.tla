---- MODULE spec ----
EXTENDS Naturals, TLC, TLCExt
VARIABLE x
Init == x = 0
Next == x < 2 /\ x' = x + 1
Inv == /\ TLCNoOp(x) < 3
       /\ AssertEq(x, x)
       /\ AssertError("nope", 1 \div 0) = FALSE
       /\ AssertError("The second argument of \\div is 0.", 1 \div 0)
       /\ TLCCache(x + 1, x) = x + 1
       /\ TLCDefer(TRUE)
====
