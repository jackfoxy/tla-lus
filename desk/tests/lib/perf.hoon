::  Tier-3 CANDIDATE WORKLOADS (R2.8.1a).
::
::  NOT a gate, and not yet a harness. R2.8.1a's whole output is a measured
::  DISTRIBUTION: these arms exist so the same bounded work can be run many
::  times and its run-to-run spread reported, which is what decides whether
::  R2.8.1c ships a threshold at all. R1.1.R3's warning is the reason the
::  order is this way round — "a flaky gate is one everyone learns to ignore",
::  so the variance is measured BEFORE any threshold is chosen.
::
::  One workload per hot path named in the plan: the BFS queue, the evaluator,
::  enumeration, fingerprinting, safety with invariants, and liveness. Each
::  asserts its OWN RESULT as well as running — a workload that silently stops
::  doing the work would otherwise keep reporting a fast, meaningless time,
::  which is the perf-harness version of a gate that is not run.
::
::  Timing is read off the test runner's own `took` line per arm; nothing here
::  observes a clock, so the arms stay reproducible (R2.6.1).
/+  *test
/=  check  /lib/check
|%
++  run  |=([s=@t c=@t] ^-(result:check -:(run-check:check s c 0)))
::
::  +|  Queue / safety BFS — many states, trivial values
::
::  a modulo counter over a wide branching relation: the cost is dominated by
::  enqueue / dedup / fingerprint-set membership, which is the queue path
++  queue-spec
  ^~
  '''
  ---- MODULE A ----
  EXTENDS Integers
  VARIABLES x, y
  Init == x = 0 /\ y = 0
  Next == \/ /\ x' = (x + 1) % 24
             /\ y' = y
          \/ /\ y' = (y + 1) % 24
             /\ x' = x
  Inv  == x < 24 /\ y < 24
  ====
  '''
++  test-perf-queue
  =/  r  (run queue-spec 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a')
  %+  expect-eq
    !>  [%.y `@ud`576]
  !>  ?:(?=([%ok *] r) [%.y distinct.stats.r] [%.n 0])
::
::  +|  Evaluator — few states, arithmetic-heavy predicate
::
::  the state graph is a line; almost all the time is +eval over a nested
::  arithmetic/boolean expression re-solved at every state
++  eval-spec
  ^~
  '''
  ---- MODULE A ----
  EXTENDS Integers
  VARIABLE x
  Init == x = 0
  Next == x < 40 /\ x' = x + 1
  Heavy(n) == ((n * n) + (n * 3) - 1) % 7
  Inv == /\ Heavy(x) >= 0
         /\ Heavy(x + 1) >= 0
         /\ Heavy(x + 2) >= 0
         /\ \A i \in 1..12 : Heavy(x + i) >= 0
  ====
  '''
++  test-perf-eval
  =/  c  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aCHECK_DEADLOCK FALSE\0a'
  =/  r  (run eval-spec c)
  %+  expect-eq
    !>  [%.y `@ud`41]
  !>  ?:(?=([%ok *] r) [%.y distinct.stats.r] [%.n 0])
::
::  +|  Enumeration — lazy set constructors forced per state
::
::  SUBSET and \X over small bases, enumerated inside a quantifier at every
::  state: the cursor / `+force` path rather than the queue
++  enum-spec
  ^~
  '''
  ---- MODULE A ----
  EXTENDS Integers
  VARIABLE x
  Init == x = 0
  Next == x < 12 /\ x' = x + 1
  Inv  == /\ \A s \in SUBSET (1..6) : Cardinality1(s) >= 0
          /\ \A p \in (1..8) \X (1..8) : p[1] >= 1
  Cardinality1(s) == IF s = {} THEN 0 ELSE 1
  ====
  '''
++  test-perf-enum
  =/  c  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aCHECK_DEADLOCK FALSE\0a'
  =/  r  (run enum-spec c)
  %+  expect-eq
    !>  [%.y `@ud`13]
  !>  ?:(?=([%ok *] r) [%.y distinct.stats.r] [%.n 0])
::
::  +|  Fingerprinting — structured values, many distinct states
::
::  each state carries a record and a sequence, so every dedup pays a full
::  structural +fp-enc rather than an integer one
++  fp-spec
  ^~
  '''
  ---- MODULE A ----
  EXTENDS Integers, Sequences
  VARIABLE r
  Init == r = [a |-> 0, b |-> <<0, 0, 0>>, c |-> "z"]
  Next == /\ r.a < 60
          /\ r' = [a |-> r.a + 1,
                   b |-> <<r.a, r.a + 1, r.a + 2>>,
                   c |-> r.c]
  Inv  == r.a >= 0
  ====
  '''
++  test-perf-fp
  =/  c  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0aCHECK_DEADLOCK FALSE\0a'
  =/  r  (run fp-spec c)
  %+  expect-eq
    !>  [%.y `@ud`61]
  !>  ?:(?=([%ok *] r) [%.y distinct.stats.r] [%.n 0])
::
::  +|  Liveness — the 8.2-8.6 engine over a small graph
::
::  the tableau build and lasso search, which is a different cost curve from
::  the safety search and the one most likely to move under a change to it
++  live-spec
  ^~
  '''
  ---- MODULE A ----
  EXTENDS Integers
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 12
  Spec == Init /\ [][Next]_x /\ WF_x(Next)
  Live == <>(x = 11)
  ====
  '''
++  test-perf-live
  =/  r  (run live-spec 'SPECIFICATION Spec\0aPROPERTY Live\0a')
  (expect-eq !>(%.y) !>(?=([%ok *] r)))
--
