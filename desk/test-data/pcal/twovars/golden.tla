---- MODULE twovars ----
EXTENDS Integers
(* --algorithm twovars
variables a = 3, b = 5;
begin
  Swap:
    if a < b then
      a := b;
    else
      b := a;
    end if;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "27a19419" /\ chksum(tla) = "8705e886")
VARIABLES pc, a, b

vars == << pc, a, b >>

Init == (* Global variables *)
        /\ a = 3
        /\ b = 5
        /\ pc = "Swap"

Swap == /\ pc = "Swap"
        /\ IF a < b
              THEN /\ a' = b
                   /\ b' = b
              ELSE /\ b' = a
                   /\ a' = a
        /\ pc' = "Done"

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Swap
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
