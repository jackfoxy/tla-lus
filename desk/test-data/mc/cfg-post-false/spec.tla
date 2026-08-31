---- MODULE spec ----
\* R2.7.7.0: a POSTCONDITION that is FALSE after exploration. tlc2 completes
\* the search, then evaluates it and fails; the port parses the keyword into
\* `cfg-ast` and evaluates nothing, so it reports a clean run.
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0
Next == x' = 1 - x
Post == TLCGet("distinct") = 999
====
