::  Particle-tableau construction (unit 8.2): TBGraph node counts, ordering,
::  and self-loop structure over hand-built tableau formulae. The 16 corpus
::  TABLEAU counts are covered end-to-end by tests/lib/temporal-struct.
/+  *test
/=  tb  /lib/tableau
/=  tp  /lib/temporal
|%
::  a state-predicate leaf with a distinct span (column c), and negation/box
::  R2.7.6.3: `%state` carries the translation-time bindings an expanded
::  user-operator call needs; a synthetic probe leaf has none
++  stp  |=(c=@ud `live-expr:tp`[%state [%lit %num '0' `[[1 c] [1 +(c)]]] ~ ~])
++  box  |=(x=live-expr:tp `live-expr:tp`[%all x])
++  neg  |=(x=live-expr:tp `live-expr:tp`[%neg x])
++  evn  |=(x=live-expr:tp `live-expr:tp`[%even x])
::
::  []-P: a single tableau node that self-loops ({[]-P, -P, ()[]-P}).
++  test-box-neg-one-node
  =/  g  (build-tableau:tb (box (neg (stp 1))))
  ;:  weld
    (expect-eq !>(`@ud`1) !>((lent nodes.g)))
    (expect-eq !>(`@ud`1) !>(init-cnt.g))
    (expect-eq !>(`(list @ud)`~[0]) !>(nexts:(snag 0 nodes.g)))
  ==
::
::  []TRUE: also one self-looping node (constant leaf in the particle).
++  test-box-true-one-node
  =/  g  (build-tableau:tb (box `live-expr:tp`[%bool &]))
  (expect-eq !>(`@ud`1) !>((lent nodes.g)))
::
::  <>(P /\ []-Q): the leads-to tableau formula — three nodes.
++  test-leadsto-three-nodes
  =/  tf  (evn `live-expr:tp`[%conj ~[(stp 1) (box (neg (stp 2)))]])
  (expect-eq !>(`@ud`3) !>((lent nodes:(build-tableau:tb tf))))
::
::  tableau-size agrees with build-tableau, and a null tf is zero.
++  test-tableau-size
  ;:  weld
    (expect-eq !>(`@ud`1) !>((tableau-size:tb `(box (neg (stp 1))))))
    (expect-eq !>(`@ud`0) !>((tableau-size:tb ~)))
  ==
--
