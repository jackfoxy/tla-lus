---- MODULE spec ----
\* R2.7.15c: TWO implied inits. The one that FAILS is declared SECOND, so a
\* head-of-list router warns once, checks once, and completes clean.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
InitOk  == x >= 0
InitBad == x = 5
====
