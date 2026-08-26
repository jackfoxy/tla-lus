::  Shortest-trace reconstruction over a branching (diamond) state graph
::  (Work Unit 7.4). A diamond has two length-2 paths from the initial state to
::  the violating state; deterministic BFS reaches it at the minimal depth. The
::  byte-exact deadlock and initial-violation traces live in the mc corpus;
::  here we assert the shortest-path depth/distinct via run-check (independent
::  of enumeration order). Per-action trace labels (getActions) are exercised by
::  the disjunction cases below (R1.5.4).
/+  *test
/=  check  /lib/check
/=  sem-lib  /lib/semantic
/=  ne  /lib/node-eval
|%
++  diamond
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "EXTENDS Integers\0a"
    "VARIABLES a, b\0a"
    "Init == a = 0 /\\ b = 0\0a"
    "Next == \\E i \\in 0..1 : /\\ a' = (IF i = 0 /\\ a = 0 THEN 1 ELSE a)\0a"
    "                         /\\ b' = (IF i = 1 /\\ b = 0 THEN 1 ELSE b)\0a"
    "Inv == ~(a = 1 /\\ b = 1)\0a"
    "====\0a"
  ==
++  cfg  ^-(@t (crip "INIT Init\0aNEXT Next\0aINVARIANT Inv\0a"))
::
::  the invariant is violated at (a=1, b=1), reachable by two length-2 paths;
::  BFS finds it at depth 3 with 4 distinct states (the diamond), and one state
::  is left on the queue at the violation (matching tlc2.TLC)
++  test-diamond-shortest
  =/  r  -:(run-check:check diamond cfg 0)
  %+  expect-eq
    !>  [%.y `@ud`4 `@ud`3]
  !>  ?:  ?=([%violated [%invariant *] *] r)
        [%.y distinct.stats.r depth.stats.r]
      [%.n 0 0]
::  the violating state is counted distinct but not enqueued, so exactly one
::  state remains on the queue (the un-expanded sibling)
++  test-diamond-queued
  =/  r  -:(run-check:check diamond cfg 0)
  %+  expect-eq
    !>  `@ud`1
  !>  ?:(?=([%violated *] r) queued.stats.r 0)
::
::  +|  Per-action trace labels (Tool.getActions decomposition, R1.5.4)
::
::  each non-initial trace state is labeled with the SPECIFIC action that
::  generated it, not the whole-Next span: `\/` splits into per-disjunct leaf
::  actions and a user-op reference renames to the innermost named action,
::  exactly as tlc2.Tool.getActions + TLCStateInfo.info. Verified against
::  SafetyDump's LABEL projection.
++  state-labels
  ::  the `State N: <label>` lines of a rendered check run
  |=  w=wain
  ^-  (list @t)
  %+  murn  w
  |=(l=@t ?:(=("State " (scag 6 (trip l))) `l ~))
::  an inline disjunction: state 2/3 carry the FIRST disjunct's span, not the
::  two-line whole-Next span (line 5 col 12 .. line 6 col 31)
++  disj
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"  "EXTENDS Naturals\0a"  "VARIABLES x, y\0a"
    "Init == x = 0 /\\ y = 0\0a"
    "Next == \\/ x' = x + 1 /\\ y' = y\0a"
    "        \\/ y' = y + 1 /\\ x' = x\0a"
    "Inv == x < 2\0a"  "====\0a"
  ==
++  test-disj-action-labels
  %+  expect-eq
    !>  ^-  (list @t)
    :~  'State 1: <Initial predicate>'
        'State 2: <Next line 5, col 12 to line 5, col 31 of module A>'
        'State 3: <Next line 5, col 12 to line 5, col 31 of module A>'
    ==
  !>  (state-labels (check:check disj cfg))
::  named sub-actions: the disjunction of two user ops; the label renames to the
::  innermost op (`Inc`) and uses its BODY span (col 8 .. 26)
++  named
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"  "EXTENDS Naturals\0a"  "VARIABLE x\0a"
    "Init == x = 0\0a"
    "Inc == x < 3 /\\ x' = x + 1\0a"
    "Dec == x > 0 /\\ x' = x - 1\0a"
    "Next == Inc \\/ Dec\0a"
    "Inv == x < 2\0a"  "====\0a"
  ==
++  test-named-action-labels
  %+  expect-eq
    !>  ^-  (list @t)
    :~  'State 1: <Initial predicate>'
        'State 2: <Inc line 5, col 8 to line 5, col 26 of module A>'
        'State 3: <Inc line 5, col 8 to line 5, col 26 of module A>'
    ==
  !>  (state-labels (check:check named cfg))
::
::  +|  Coverage action SET (R1.5.11) and the counterexample refusal (R2.7.4.2b)
::
::  The `coverage` safety corpus case. R1.5.11 could only assert the action SET
::  here, because the COUNTS were then believed to be `getEvalCount()`, an
::  engine-internal evaluation tally. R2.7.4.0 MEASURED otherwise -- every
::  number on an INIT / NEXT / CONSTRAINT line is a count of STATES at a checker
::  boundary (`Worker.addElement`, `Tool.getInitStates`, `Tool.isInModel`) --
::  so the counts are now reproduced and compared line for line in the
::  GENERATED `tests/lib/coverage` shard (tools/gen-coverage-tests.py).
::
::  What stays here is the decomposition this all rests on: getActions splits
::  `Next == Inc \/ Dec` into the two named leaf actions, in source order.
++  cov-spec
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"  "EXTENDS Naturals\0a"  "VARIABLE x\0a"
    "Init == x = 0\0a"  "Inc == x < 3 /\\ x' = x + 1\0a"
    "Dec == x > 0 /\\ x' = x - 1\0a"  "Next == Inc \\/ Dec\0a"
    "Inv == TRUE\0a"  "====\0a"
  ==
::
++  test-coverage-action-set
  %+  expect-eq
    !>  ^-  (list @t)
    ~['Inc' 'Dec']
  !>
  =/  mo  (generate:sem-lib 'A' (malt ~[['A' cov-spec]]))
  ?~  mo  ~['NO-MODULE']
  =/  defs  (defmap-of:ne u.mo)
  =/  nsb  (sem-body:check defs 'Next')
  ?~  nsb  ~['NO-NEXT']
  =/  e  (base-env:ne u.mo ~ ~)
  (turn (get-actions:check u.nsb 'Next' defs e) |=([n=@t *] n))
::
::  A run that PRINTS A COUNTEREXAMPLE reports NO coverage block. tlc2
::  reconstructs the trace by re-invoking the initial predicate and the actions
::  with coverage still recording, so its counters there are the search's PLUS
::  that re-solve: the same spec that reports `<Init …>: 1:1` / `<A …>: 2:2`
::  under `-deadlock` reports `3:3` / `2:6` when the deadlock trace is printed
::  (measured 2026-08-25, re-measured with `-noGenerateSpecTE`, unchanged).
::  The port does not reproduce the re-solve, so it withholds the numbers and
::  says so by name rather than publishing different ones (R2.1)
++  dead-spec
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"  "EXTENDS Naturals\0a"  "VARIABLE x\0a"
    "Init == x = 0\0a"  "Step == x < 2 /\\ x' = x + 1\0a"
    "Next == Step\0a"  "Inv == TRUE\0a"  "====\0a"
  ==
::
++  test-coverage-refused-on-counterexample
  %+  expect-eq
    !>  ^-  (list @t)
    :~  '-coverage: no statistics for a run that prints a counterexample.'
    ==
  !>
  %+  skim  (check-cov:check dead-spec cfg)
  |=(l=@t =('-coverage: no statistics for a run that prints a counterexample.' l))
::
::  ...and a clean run of the SAME shape does report one
++  test-coverage-reported-on-clean-run
  %+  expect-eq
    !>  %.y
  !>
  =/  w  (check-cov:check cov-spec cfg)
  ?&  (lien w |=(l=@t =('The coverage statistics ' (end [3 24] l))))
      (lien w |=(l=@t =('End of statistics.' l)))
  ==
--
