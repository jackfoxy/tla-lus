---- MODULE spec ----
EXTENDS TLC, Integers

\* In TLA+ a RECORD is a function whose domain is a set of strings, and tlc2
\* compares the two representations equal (RecordValue vs FcnRcdValue). The
\* port keeps `%rec` outside `+fcn-like`, so these are FALSE here and TRUE at
\* the pin -- the whole of BagsTest's divergence, and nothing to do with Bags.
ASSUME([a |-> 1] = ("a" :> 1))
ASSUME([a |-> 1, b |-> 2] = ("a" :> 1) @@ ("b" :> 2))
ASSUME([x \in {"a"} |-> 1] = [a |-> 1])

\* this one AGREES, which is what makes the diagnosis precise: the domain is
\* built right, only the equality is not
ASSUME(DOMAIN [a |-> 1] = {"a"})

Spec == [][TRUE]_<<>>
=====================
