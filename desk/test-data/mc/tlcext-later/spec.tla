---- MODULE spec ----
\* R2.7.10: the three TLCExt surfaces the inventory carried as `later:` --
\* TLCFP (a value's FP64, downcast to a signed 32-bit int), TLCEvalDefinition
\* (evaluate a definition by name in the root module) and TLCModelValue.
\* TLCFP is reproducible under `-fp 0` only, which is the pin's property: an
\* unseeded run picks a different polynomial and answers differently every run.
EXTENDS Integers, TLC, TLCExt
VARIABLE x
Foo == 41 + 1
Init == x = 0
Next == UNCHANGED x
Post == /\ TLCFP(3) = -244908333
        /\ TLCFP("ab") = 1031263210
        /\ TLCFP({1, 2}) = 2120042859
        /\ TLCEvalDefinition("Foo") = 42
        /\ TLCModelValue("mv1") = TLCModelValue("mv1")
====
