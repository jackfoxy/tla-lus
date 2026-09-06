---- MODULE Test ----
USE x, MODULE M, 1 + 3
HIDE DEFS MODULE M, -., *, ^+
USE x, MODULE M DEF MODULE M, x
====
