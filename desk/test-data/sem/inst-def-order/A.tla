---- MODULE A ----
VARIABLE x
R == INSTANCE B WITH y <- x
F == WF_R!vars(R!Next)
G == SF_R!vars(R!Next)
====
