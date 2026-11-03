---- MODULE spec ----
EXTENDS Naturals, Sequences, TLC, Json
VARIABLE x
Init == x = << ToJson([a |-> 1, b |-> "s\"q"]),
               ToJson(<<1, <<>>, {3, 2}>>),
               ToJson([i \in 1..2 |-> TRUE]),
               ToJson((1 :> "x") @@ (3 :> "y")),
               ToJsonArray({"p", "q"}),
               ToJsonObject(<<10, 20>>),
               JsonSerialize("out.json", <<1, 2>>) >>
Next == UNCHANGED x
Inv == x[1] = ""
====
