---- MODULE spec ----
\* R4.2u/v: a config VALUE for a DEFINITION (`Faded = Faded`) replaces it, so
\* `Faded == CHOOSE c : c \notin Color` -- an unbounded CHOOSE tlc2 refuses --
\* is never evaluated (Chameneos, Paxos's `None`); and `Leader <- L` gives a
\* CONSTANT the value of another constant (EWD687a).
EXTENDS Naturals
CONSTANTS Color, Leader, L
VARIABLE c
Faded == CHOOSE x : x \notin Color
Init == c = Faded
Next == \/ c = Faded /\ c' \in Color
        \/ c \in Color /\ c' = Leader
TypeOK == c \in Color \cup {Faded, Leader}
====
