---- MODULE A ----
CONSTANT MS
Plain == {"b", "a"}
Adversarial == {"bb", "a", "ab"}
Longer == {"z", "aa", "ab", "b"}
Rec == [bb |-> 1, a |-> 2, ab |-> 3]
Dom == DOMAIN [bb |-> 1, a |-> 2, ab |-> 3]
Ch == CHOOSE x \in {"bb", "a", "ab"} : TRUE
Models == MS
ChModel == CHOOSE x \in MS : TRUE
Pair == <<"bb", "a">>
====
