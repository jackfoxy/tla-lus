---- MODULE A ----
VARIABLE x
R == INSTANCE B WITH y <- x
F == WF_R!vars(x' = x)
G == SF_R!vars(x' = x)
====
