---------------------------- MODULE A ----------------------------
(* R4.4 fixture: the ASCII spellings tlauc rewrites, original text *)
EXTENDS Naturals, Sequences, FiniteSets
CONSTANT S
VARIABLES x, y

B == INSTANCE B WITH c <- S

TypeOK == /\ x \in SUBSET S
          /\ y \in Seq(S) \X Nat
          /\ \A e \in x : e \notin {}

Sets == (x \cup {}) \cap (S \ {}) \subseteq S /\ ({} \subseteq S \/ TRUE)

Logic(p, q) == (p => q) /\ (~p <=> ~~p) /\ (p \equiv p) /\ (p # q)

Cmp(a, b) == /\ a =< b
             /\ b >= a
             /\ a <= b
             /\ a \leq b \/ a \geq b
             /\ \/ a < b
                \/ a > b
                \/ a /= b

Tup == << 1, <<2, 3>> >> \o <<4>>

F == [e \in S |-> e]

G == [S -> S]

H == \E e \in S : \A f \in S : e = f

Init == x = {} /\ y = << <<>>, 0 >>

Next == /\ x' = x
        /\ UNCHANGED y

Spec == Init /\ [][Next]_<<x, y>> /\ WF_<<x, y>>(Next)

Live == <>[](x = {}) /\ []<>(x = {}) /\ ((x = {}) ~> (x = {}))

Arrow == (x = {}) -+-> (x = {})

Range == 1..3

Lam == LET Twice(a) == a + a IN Twice(1)

THEOREM Thm == TypeOK => TRUE
====================================================================
