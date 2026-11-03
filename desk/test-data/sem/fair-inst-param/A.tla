---- MODULE A ----
VARIABLE x
I(z) == INSTANCE B WITH y <- z
F == WF_I(x)!vars(x' = x)
====
