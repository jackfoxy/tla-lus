---- MODULE spec ----
\* R2.7.7.4a: NAMED registers. tlc2 keys them on a string beginning `s:`
\* (TLCGetSet.NAMED_REGISTER_PREFIX); the integer store coexists. The counter
\* is bumped from the next-state relation, so it counts EVALUATIONS, and the
\* postcondition reads it three ways: directly, through TLCGetOrDefault, and
\* through the per-worker aggregate TLCGet("all:named").
EXTENDS Naturals, Sequences, TLC, TLCExt
VARIABLE x
Init == x = 0
Next == x' = x + 1 /\ x < 2 /\ TLCSet("s:c", TLCGetOrDefault("s:c", 0) + 1) /\ TLCSet(3, 42)
Post == /\ TLCGet("s:c") = 2
        /\ TLCGetOrDefault("s:c", 0) = 2
        /\ TLCGetOrDefault("s:nope", 5) = 5
        /\ TLCGet(3) = 42
        /\ TLCGet("all:named") = ("s:c" :> <<2>>)
====
