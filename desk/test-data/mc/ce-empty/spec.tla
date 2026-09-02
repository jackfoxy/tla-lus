---- MODULE spec ----
\* R2.7.14b: a CLEAN run evaluates `TLCExt!CounterExample` to `new
\* CounterExample()` -- an EMPTY record -- because the value is consed onto
\* the Context only on a violation path. `CounterExample.state = {}` is the
\* test _JsonTrace and _DotTrace use to detect "no violation", so it is the
\* one this case pins.
EXTENDS Naturals, FiniteSets, TLCExt
VARIABLE x
Init == x = 0
Next == x' = 1 - x
Inv  == x \in 0..1
PostCondition ==
    /\ CounterExample.state = {}
    /\ CounterExample.action = {}
    /\ Cardinality(CounterExample.state) = 0
====
