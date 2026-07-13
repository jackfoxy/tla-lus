---- MODULE SemanticInstance ----
EXTENDS Naturals
VARIABLE w
I == INSTANCE Inner WITH c <- 42, v <- w
InnerInv == I!Inv
====
