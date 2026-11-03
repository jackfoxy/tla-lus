---- MODULE spec ----
EXTENDS Naturals, Sequences
VARIABLES q, r, w
Rd(a) == r' = r + a /\ UNCHANGED w
Wr(a) == w' = w + a /\ UNCHANGED r
Step == /\ q /= <<>>
        /\ LET p == Head(q) IN
           CASE p[1] = "r" -> Rd(p[2])
             [] p[1] = "w" -> Wr(p[2])
             [] OTHER -> UNCHANGED <<r, w>>
        /\ q' = Tail(q)
Init == q = <<<<"r", 1>>, <<"x", 0>>, <<"w", 2>>, <<"r", 3>>>> /\ r = 0 /\ w = 0
Next == Step
====
