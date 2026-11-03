---- MODULE spec ----
\* R4.2m: membership in a set built from an INFINITE standard set is decided
\* on its structure, as tlc2's lazy values decide it: `N \in Nat \ {0}` (the
\* Examples' ASSUME idiom), `[P -> [P -> Nat]]`, `[a : Int]`, `Seq(Nat)`.
EXTENDS Naturals, Integers, Sequences
CONSTANT N
ASSUME N \in Nat \ {0}
ASSUME N \notin Int \ Nat
VARIABLE f, r, s
Init == /\ f = [p \in 1..2 |-> [q \in 1..2 |-> 0]]
        /\ r = [a |-> -1, b |-> 1]
        /\ s = <<0, 1>>
Next == /\ f[1][1] < 2
        /\ f' = [f EXCEPT ![1][1] = @ + 1]
        /\ UNCHANGED <<r, s>>
TypeOK == /\ f \in [1..2 -> [1..2 -> Nat]]
          /\ r \in [a : Int, b : Nat \ {0}]
          /\ s \in Seq(Nat)
====
