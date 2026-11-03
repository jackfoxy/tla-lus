---- MODULE spec ----
\* R4.2m: labeled expressions (`P :: e`, EWD840/EWD998's proof-ready style)
\* are their bodies -- in an action, in an invariant, and in a property.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == /\ step :: x < 3
        /\ bump :: x' = x + 1
Inv == ok :: x <= 3
====
