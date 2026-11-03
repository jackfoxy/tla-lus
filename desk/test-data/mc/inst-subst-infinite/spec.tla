---- MODULE spec ----
\* R4.2m: an INSTANCE substitution by an INFINITE set (`Values <- Int`,
\* Disruptor's RingBuffer; `Boxes` built from `Int`, detector_chan96) is
\* bound lazily: membership and `\subseteq` decide it on its structure.
EXTENDS Integers
---- MODULE Buf ----
CONSTANT Values
VARIABLE slot
TypeOK == /\ slot \in Values
          /\ {slot} \subseteq Values
          /\ {[v |-> slot]} \subseteq [v : Values]
====
VARIABLE x
B == INSTANCE Buf WITH Values <- Int, slot <- x
Init == x = -1
Next == x < 1 /\ x' = x + 1
Inv == B!TypeOK
====
