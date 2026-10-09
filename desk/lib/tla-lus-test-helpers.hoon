/-  *tla-lus-test
/+  *test, adapter=tla-lus-test-adapter
|%
  ::  tla-lus-test-helpers: the one assertion every black-box arm calls
  ::
  ::  The status is the primary assertion. The code, the message fragment
  ::  and the counterexample's action labels and loop point are asserted
  ::  whenever the case names them -- the generator only names what its
  ::  oracle actually produced. No arm passes because the test crashed: a
  ::  crashing agent is caught by the adapter and reported as a status.
  ::
++  expect-case
  |=  c=bb-case
  ^-  tang
  =/  r=report  (observe:adapter c)
  =/  what=tape
    "{(trip name.c)} [%{(trip scenario.c)}] expect %{(trip expected.c)}"
  %+  category  what
  ;:  weld
    (expect-eq !>(expected.c) !>(status.r))
    ?~(code.c ~ (expect-eq !>(code.c) !>(code.r)))
  ::
    ?~  fragment.c  ~
    ?^  (find (trip u.fragment.c) (trip summary.r))  ~
    :~  leaf+"fragment not found: {(trip u.fragment.c)}"
        leaf+"in summary: {(trip summary.r)}"
    ==
  ::
    ?:  &(=(~ actions.c) =(~ loop.c))  ~
    (expect-eq !>([actions.c loop.c]) !>([actions.r loop.r]))
  ==
--
