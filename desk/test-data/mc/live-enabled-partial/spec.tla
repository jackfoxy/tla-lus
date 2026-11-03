---- MODULE spec ----
\* R4.2s: ENABLED needs no complete successor. `Move` assigns `x` only, so
\* requiring every variable read `ENABLED Move` as FALSE, `WF_x(Move)` was
\* vacuous, and a stuttering counter-example was reported where tlc2 finds
\* none (Moving_Cat_Puzzle).
EXTENDS Naturals
VARIABLES x, y
Init == x = 0 /\ y = 0
Move == x' = (x + 1) % 3
Other == y' = 1 - y
Next == Move /\ Other
Spec == Init /\ [][Next]_<<x, y>> /\ WF_x(Move)
Prop == <>(x = 2)
====
