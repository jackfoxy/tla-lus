---- MODULE Test ----
r == [a EXCEPT !.a.b["c"] = "b", ![2].x = @]
====
