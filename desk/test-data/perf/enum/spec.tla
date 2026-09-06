---- MODULE A ----
\* Hot path: ENUMERATION. SUBSET and \X over small bases, forced inside a
\* quantifier at every state -- the cursor / +force path, not the queue.
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == x < 12 /\ x' = x + 1
Inv  == /\ \A s \in SUBSET (1..6) : Card1(s) >= 0
        /\ \A p \in (1..8) \X (1..8) : p[1] >= 1
Card1(s) == IF s = {} THEN 0 ELSE 1
====
