---- MODULE spec ----
\* R4.2m: a config `<-` override of a StandardModule set (`Nat <- NatOverride`,
\* MCBakery / MCLamportMutex), and of a CONSTANT by a definition
\* (`Limit <- MCLimit`). Both were validated and then IGNORED.
EXTENDS Naturals
CONSTANT Limit
VARIABLE x
NatOverride == 0..2
MCLimit == 2
Init == x = 0
Next == \E k \in Nat : k > x /\ k <= Limit /\ x' = k
TypeOK == x \in Nat
====
