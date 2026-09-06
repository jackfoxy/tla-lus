::  Search statistics + slice-boundary resume equality (Work Unit 7.6). The
::  generated/distinct/queued/depth counters are byte-compared against TLC in
::  the mc corpus; here we check the max out-degree (newly-distinct successors
::  of any state, TLC's maximum out-degree) and that every counter is
::  independent of how the search is sliced. Driven through run-stats-full so
::  no value crosses the low-budget test core.
/+  *test
/=  check  /lib/check
|%
++  full  |=([s=@t c=@t] (run-stats-full:check s c 0 1.024))
::
::  +|  test specs
::
::  two independent toggles: the initial state (0,0) has two newly-distinct
::  successors (1,0) and (0,1), so the maximum out-degree is 2; 4 distinct
::  states, depth 3 (matching tlc2.TLC's "maximum 2" out-degree report)
++  toggles
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"  "EXTENDS Integers\0a"  "VARIABLES x, y\0a"
    "Init == x = 0 /\\ y = 0\0a"
    "Next == \\/ (x' = 1 - x /\\ y' = y)\0a"
    "        \\/ (y' = 1 - y /\\ x' = x)\0a"
    "Inv == TRUE\0a"  "====\0a"
  ==
::  a single variable stepping through a cycle: each state has exactly one
::  newly-distinct successor, so the maximum out-degree is 1
++  chain
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"  "EXTENDS Integers\0a"  "VARIABLE x\0a"
    "Init == x = 0\0a"  "Next == x' = (x + 1) % 4\0a"  "Inv == TRUE\0a"  "====\0a"
  ==
++  cfg  ^-(@t (crip "INIT Init\0aNEXT Next\0aINVARIANT Inv\0a"))
::
::  +|  max out-degree
::
++  test-outdeg-diamond
  =/  s  (full toggles cfg)
  (expect-eq !>([`@ud`4 `@ud`2]) !>([distinct.s max.outdeg.s]))
++  test-outdeg-chain
  =/  s  (full chain cfg)
  (expect-eq !>([`@ud`4 `@ud`1]) !>([distinct.s max.outdeg.s]))
::
::  +|  slice-boundary resume equality: every counter is independent of budget
::
++  test-stats-slice-invariant
  =/  whole  (run-stats-full:check toggles cfg 0 1.024)
  =/  sliced  (run-stats-full:check toggles cfg 0 1)
  (expect-eq !>(whole) !>(sliced))
++  test-stats-slice-chain
  =/  whole  (run-stats-full:check chain cfg 0 1.024)
  =/  sliced  (run-stats-full:check chain cfg 0 1)
  (expect-eq !>(whole) !>(sliced))
--
