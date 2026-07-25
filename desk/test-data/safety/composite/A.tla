---- MODULE A ----
EXTENDS Naturals, Sequences
VARIABLE s
Init == s = <<0, 0>>
Next == s' = <<(s[1] + 1) % 2, s[2]>>
Inv == s[1] \in {0, 1}
====
