::  Symmetry reduction (Work Unit 7.5): a state's identity is its orbit
::  representative under the permutation group named by SYMMETRY, so symmetric
::  states collapse to one distinct state. Symmetry with a temporal property is
::  an unsafe combination TLC rejects. Driven through run-check:check (no value
::  crosses the low-budget test core). cfg cords are single-quoted so the `{`
::  of a model-value set is literal (double quotes would interpolate).
/+  *test
/=  check  /lib/check
|%
++  spec
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "EXTENDS Naturals, TLC\0a"
    "CONSTANT P\0a"
    "VARIABLE x\0a"
    "Init == \\E p \\in P : x = p\0a"
    "Next == \\E p \\in P : x' = p\0a"
    "Perms == Permutations(P)\0a"
    "Inv == TRUE\0a"
    "====\0a"
  ==
++  spec-prop
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "EXTENDS Naturals, TLC\0a"
    "CONSTANT P\0a"
    "VARIABLE x\0a"
    "Init == \\E p \\in P : x = p\0a"
    "Next == \\E p \\in P : x' = p\0a"
    "Perms == Permutations(P)\0a"
    "Inv == TRUE\0a"
    "Prop == []Inv\0a"
    "====\0a"
  ==
++  cfg
  ^-  @t
  'CONSTANT P = {a, b}\0aSYMMETRY Perms\0aINIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
++  cfg-prop
  ^-  @t
  'CONSTANT P = {a, b}\0aSYMMETRY Perms\0aINIT Init\0aNEXT Next\0aPROPERTY Prop\0a'
::
::  the two initial states x=a and x=b are one orbit under Permutations({a,b}),
::  so the search finds a single distinct state (TLC reports distinct = 1)
++  test-symmetry-reduced
  =/  r  ^-(result:check -:(run-check:check spec cfg 0))
  %+  expect-eq
    !>  [%.y `@ud`1]
  !>  ?:(?=([%ok *] r) [%.y distinct.stats.r] [%.n 0])
::
::  symmetry combined with a temporal property is a typed rejection (WU8 owns
::  liveness under symmetry), never a plausible %ok
++  test-symmetry-property-rejected
  =/  r  ^-(result:check -:(run-check:check spec-prop cfg-prop 0))
  (expect-eq !>(%.y) !>(?=([%failed *] r)))
--
