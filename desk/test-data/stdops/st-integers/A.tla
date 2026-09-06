---- MODULE A ----
EXTENDS Integers
Neg == -5
NegExpr == -(3 + 4)
DivNegL == (-7) \div 2
DivNegR == 7 \div (-2)
DivBothNeg == (-7) \div (-2)
ModNegL == (-7) % 3
IntSet == Int
IntMem == (-3) \in Int
NatMemNeg == (-3) \in Nat
NegInterval == (-2)..2
Cmp == (-3) < (-2)
====
