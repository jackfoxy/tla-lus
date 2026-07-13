---- MODULE SemanticUndef ----
EXTENDS Naturals
Plus(a, b) == a + b
Bad1 == undefinedOp(1)
Bad2 == Plus(1)
====
