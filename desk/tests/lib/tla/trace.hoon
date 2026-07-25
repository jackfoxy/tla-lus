::  Shortest-trace reconstruction over a branching (diamond) state graph
::  (Work Unit 7.4). A diamond has two length-2 paths from the initial state to
::  the violating state; deterministic BFS reaches it at the minimal depth. The
::  byte-exact deadlock and initial-violation traces live in the mc corpus;
::  here we assert the shortest-path depth/distinct via run-check (independent
::  of enumeration order and the deferred per-action trace labels).
/+  *test
/=  check  /lib/tla/check
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
--
