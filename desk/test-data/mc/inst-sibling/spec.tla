---- MODULE spec ----
\* R2.7.8 (R2.3.5's residue): an INSTANCE member that references a SIBLING
\* member of its own module. `SpecI`'s body carries a BARE `InitI`, while the
\* root defs map holds instanced members QUALIFIED as `I!InitI`.
EXTENDS Naturals
VARIABLE x
---- MODULE inner ----
EXTENDS Naturals
VARIABLE v
CONSTANT k
InitI == v = 0
NextI == v' = (v + 1) % k
SpecI == InitI /\ [][NextI]_v
====
I == INSTANCE inner WITH v <- x, k <- 3
Spec == I!SpecI
Inv == x < 9
====
