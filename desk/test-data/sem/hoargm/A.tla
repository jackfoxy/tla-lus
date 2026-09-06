---- MODULE A ----
VARIABLE x
H(F(_)) == F(1)
Two(a, b) == a
Bad == H(Two)
Bad2 == H(x)
Bad3 == H(x + 1)
====
