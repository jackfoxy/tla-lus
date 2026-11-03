---- MODULE A ----
EXTENDS Naturals
M == INSTANCE B WITH C <- LAMBDA s, l : s < l
Y == M!Ok(0)
====
