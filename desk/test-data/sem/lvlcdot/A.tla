---- MODULE A ----
VARIABLE x
Good == (x' = x) \cdot (x' = x)
Bad == ([]TRUE) \cdot (x' = x)
====
