---- MODULE A ----
EXTENDS Naturals, Sequences, VectorClocks
Log == << [n |-> 1, vc |-> [p |-> 2, q |-> 0]],
          [n |-> 2, vc |-> [p |-> 0, q |-> 1]],
          [n |-> 1, vc |-> [p |-> 1, q |-> 0]] >>
CO == CausalOrder(Log, LAMBDA l : l.vc, LAMBDA l : IF l.n = 1 THEN "p" ELSE "q", LAMBDA vc : DOMAIN vc)
====
