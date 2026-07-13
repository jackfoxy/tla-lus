---- MODULE Test ----
f[x \in Nat] == x
f[x, y \in Nat] == x
f[x, y \in Nat, z \in Real] == x
f[x \in [Nat -> (Nat)]] == x
====
