---- MODULE counter ----
EXTENDS Naturals
(* --algorithm counter
variables x = 0;
begin
  Loop:
    while x < 10 do
      x := x + 1;
    end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "2bb0f610" /\ chksum(tla) = "256526f5")
VARIABLES pc, x

vars == << pc, x >>

Init == (* Global variables *)
        /\ x = 0
        /\ pc = "Loop"

Loop == /\ pc = "Loop"
        /\ IF x < 10
              THEN /\ x' = x + 1
                   /\ pc' = "Loop"
              ELSE /\ pc' = "Done"
                   /\ x' = x

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Loop
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
