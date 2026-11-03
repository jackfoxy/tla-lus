---- MODULE spec ----
\* R4.2t: tlc2 orders a state's variables by the java.util.Hashtable
\* enumeration of the module's SANY Context (String.hashCode, capacity and
\* insertion history over EVERY symbol), not by declaration. The port keeps
\* declaration order: an APPROVED DIFFERENCE (`tlc-var-order`).
EXTENDS Naturals
VARIABLES zeta, alpha, mid, Qux, beta2, beta10
Init == zeta = 0 /\ alpha = 1 /\ mid = 2 /\ Qux = 3 /\ beta2 = 4 /\ beta10 = 5
Next == UNCHANGED <<zeta, alpha, mid, Qux, beta2, beta10>>
Inv == zeta = 1
====
