---- MODULE Test ----
THEOREM TRUE
<*> /\ 1
    /\ 2
      <+> QED BY
        \/ 1
        \/ 2
          <*> QED
====
