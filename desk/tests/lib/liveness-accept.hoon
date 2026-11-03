::  PossibleErrorModel accepting condition (unit 8.4): the pem acceptance
::  predicate over a candidate component, exercising the encoded WF_/SF_/promise
::  fairness semantics at the bit level (LiveWorker.checkComponent).
/+  *test
/=  lv  /lib/liveness
/=  tp  /lib/temporal
/=  tb  /lib/tableau
|%
::  a state leaf and its <>-promise, to build particles
::  R2.7.6.3: `%state` carries the translation-time bindings an expanded
::  user-operator call needs; a synthetic probe leaf has none
++  stp  |=(c=@ud `live-expr:tp`[%state [%lit %num '0' `[[1 c] [1 +(c)]]] ~ ~ ~])
++  evn  |=(x=live-expr:tp `live-expr:tp`[%even x])
::  a pem `[ae-action ae-state ea-action]` and an empty-particle node list
++  pm   |=([aea=(list @ud) aes=(list @ud) eaa=(list @ud)] `pem:tp`[aea aes eaa])
++  bare  |=(n=@ud `(list par:tb)`(reap n ~))       ::  n empty particles
++  nb    |=(n=@ud `(list (list ?))`(reap n ~))      ::  n empty bit rows
::
::  WF_v(A) contributes an AEAction ([]<>(¬EN ∨ A)): a cycle where that fires on
::  some transition is accepting; a cycle where it never fires (A continuously
::  enabled but never taken) is suppressed — the fair behaviour is not a
::  counterexample.
++  test-wf-fair-taken
  =/  c=comp:lv  [~[~[&]] (bare 1) ~[~[&]]]
  (expect !>((pem-accepting:lv (pm ~[0] ~ ~) ~ c)))
++  test-wf-unfair-suppressed
  =/  c=comp:lv  [~[~[|]] (bare 1) ~[~[|]]]
  (expect !>(!(pem-accepting:lv (pm ~[0] ~ ~) ~ c)))
::
::  AEAction "some edge": one of several edges firing suffices.
++  test-ae-action-some
  =/  c=comp:lv  [(nb 2) (bare 2) ~[~[|] ~[&]]]
  (expect !>((pem-accepting:lv (pm ~[0] ~ ~) ~ c)))
::
::  EAAction (<>[]E) must hold on EVERY edge; one violating edge rejects.
++  test-ea-action-every
  =/  ok=comp:lv    [(nb 2) (bare 2) ~[~[&] ~[&]]]
  =/  bad=comp:lv   [(nb 2) (bare 2) ~[~[&] ~[|]]]
  ;:  weld
    (expect !>((pem-accepting:lv (pm ~ ~ ~[0]) ~ ok)))
    (expect !>(!(pem-accepting:lv (pm ~ ~ ~[0]) ~ bad)))
  ==
::
::  AEState ([]<>S) needs S true at some node.
++  test-ae-state-some
  =/  yes=comp:lv  [~[~[|] ~[&]] (bare 2) (nb 2)]
  =/  no=comp:lv   [~[~[|] ~[|]] (bare 2) (nb 2)]
  ;:  weld
    (expect !>((pem-accepting:lv (pm ~ ~[0] ~) ~ yes)))
    (expect !>(!(pem-accepting:lv (pm ~ ~[0] ~) ~ no)))
  ==
::
::  A promise <>P is fulfilled by a node whose particle omits <>P, or contains
::  its body P; a component where every node carries <>P but not P is not
::  accepting (the eventuality is never discharged).
++  test-promise-fulfilled
  =/  p    (stp 1)
  =/  ev   (evn p)
  ::  node particles: one contains the body P -> fulfils <>P
  =/  met=comp:lv    [(nb 1) `(list par:tb)`~[~[ev p]] (nb 1)]
  =/  unmet=comp:lv  [(nb 1) `(list par:tb)`~[~[ev]] (nb 1)]
  ;:  weld
    (expect !>((pem-accepting:lv (pm ~ ~ ~) ~[ev] met)))
    (expect !>(!(pem-accepting:lv (pm ~ ~ ~) ~[ev] unmet)))
  ==
::
::  A conjunction of conditions: all must hold (SF-style two-conjunct pem).
++  test-conjunction
  =/  full=comp:lv     [~[~[&]] (bare 1) ~[~[& &]]]
  =/  partial=comp:lv  [~[~[&]] (bare 1) ~[~[& |]]]
  ;:  weld
    (expect !>((pem-accepting:lv (pm ~[0] ~[0] ~[1]) ~ full)))
    (expect !>(!(pem-accepting:lv (pm ~[0] ~[0] ~[1]) ~ partial)))
  ==
--
