---- MODULE A ----
EXTENDS TLC, Integers, Sequences
Ev == TLCEval(2 + 3)
EvSet == TLCEval({1, 2} \cup {2, 3})
EvNest == TLCEval(TLCEval(7))
EvFcn == TLCEval([i \in 1..3 |-> i * i])
Pr == Print("side", 42)
PrT == PrintT("alone")
PrNest == Print("a", Print("b", 1))
====
