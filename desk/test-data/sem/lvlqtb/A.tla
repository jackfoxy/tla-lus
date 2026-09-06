---- MODULE A ----
VARIABLE x
Bad == \E i \in IF [](x = 0) THEN {} ELSE {} : TRUE
====
