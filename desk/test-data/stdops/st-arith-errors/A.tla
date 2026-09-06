---- MODULE A ----
EXTENDS Integers
DivZero == 5 \div 0
ModZero == 5 % 0
ModNegDivisor == 5 % (-2)
OverflowPlus == 2147483647 + 1
OverflowMinus == (-2147483647) - 2
OverflowTimes == 100000 * 100000
ExptOverflow == 2 ^ 31
BadArgPlus == 1 + "a"
BadArgLt == 1 < "a"
====
