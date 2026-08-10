---- MODULE A ----
EXTENDS Integers
SOp1a(a) == {x \in {1, 2} : a = x}
OOp2(A(_, _), a, b) == A(a, b)
E1 == OOp2(SOp1a!@, 2, 2)
COp(q, p) == \A x \in {1, 2} : lab(x) :: LET a ++ b == a + b + q + p + x IN q = (1 ++ 2)
OOp5(A(_, _, _, _, _), a1, a2, a3, a4, a5) == A(a1, a2, a3, a4, a5)
E2 == OOp5(COp!@!++, 1, 2, 3, 4, 5)
====
