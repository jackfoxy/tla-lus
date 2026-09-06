::  String and model-value order (unit 6C.7, family 5).
::
::  tlc2 orders StringValues and ModelValues by their UniqueString `tok` — the
::  position at which the string was first interned during THAT RUN. The
::  measurement in desk/test-data/stdops/intern-order.txt shows the order is a
::  property of the run rather than of the spec: the same fixture renders
::  differently under two of tlc2's own drivers, and `CHOOSE` even picks a
::  different element. This port orders lexicographically instead — the same
::  answer on every run, machine, and pipeline — and these are the adversarial
::  cases that fix the boundary of that documented divergence.
/+  *test
/=  ne  /lib/node-eval
/=  v   /lib/value
|%
++  ex
  |=  [txt=@t want=tape]
  ^-  tang
  (expect-eq !>(want) !>((eval-dbg:ne txt)))
::
++  mv
  ::  an expression over a config-free module with model-value-like strings is
  ::  not expressible, so model-value order is exercised through the value
  ::  core directly
  |=  [vals=(list @t) want=tape]
  ^-  tang
  =/  s  (normalize:v [%set %set-enum (turn vals |=(nm=@t `value:v`[%model nm]))])
  (expect-eq !>(want) !>((render:v s)))
::
::  +|  Where the two orders agree
::
++  test-agrees-single-letters   (ex '{"b", "a"}' (trip '{"a", "b"}'))
++  test-agrees-numbers          (ex '{3, 1, 2}' (trip '{1, 2, 3}'))
++  test-agrees-prefix-free      (ex '{"x", "y", "z"}' (trip '{"x", "y", "z"}'))
::
::  +|  Where they part: prefixes and repeated first letters
::
++  test-adversarial-set
  ::  tlc2 (FastTool driver) renders {"bb", "a", "ab"}; lexicographically it
  ::  is a, ab, bb, and that is what this port answers on every run
  (ex '{"bb", "a", "ab"}' (trip '{"a", "ab", "bb"}'))
::
++  test-adversarial-longer
  ::  the pinned fixture's `Longer`: tlc2's two drivers disagree with each
  ::  other here ({"aa", "ab", "b", "z"} vs {"ab", "b", "z", "aa"})
  (ex '{"z", "aa", "ab", "b"}' (trip '{"aa", "ab", "b", "z"}'))
::
++  test-choose-is-the-lexicographic-first
  ::  tlc2's CHOOSE over this set returns "bb" under one driver; here it is
  ::  always the lexicographically smallest element
  (ex 'CHOOSE x \\in {"bb", "a", "ab"} : TRUE' "\"a\"")
::
++  test-record-fields-are-lexicographic
  ::  tlc2 renders record fields in interning order ([bb |-> 1, a |-> 2,
  ::  ab |-> 3]); here they are sorted by key
  %+  ex  '[bb |-> 1, a |-> 2, ab |-> 3]'
  "[a |-> 2, ab |-> 3, bb |-> 1]"
::
++  test-domain-of-record-is-lexicographic
  %+  ex  'DOMAIN [bb |-> 1, a |-> 2, ab |-> 3]'
  (trip '{"a", "ab", "bb"}')
::
::  +|  Model values
::
++  test-model-values-lexicographic
  ::  tlc2 renders {zz, aa, mm} (config order under one driver, interning
  ::  order under another); here it is aa, mm, zz
  (mv ~['zz' 'aa' 'mm'] (trip '{aa, mm, zz}'))
::
++  test-model-values-agree-when-sorted
  (mv ~['a' 'b' 'c'] (trip '{a, b, c}'))
::
::  +|  What the divergence does NOT change
::
++  test-membership-is-unaffected
  ::  order is a rendering and CHOOSE concern; membership, equality, and
  ::  cardinality are not
  ;:  weld
    (ex '"ab" \\in {"bb", "a", "ab"}' "TRUE")
    (ex '"zz" \\in {"bb", "a", "ab"}' "FALSE")
    (ex 'Cardinality({"bb", "a", "ab"})' "3")
    (ex '{"bb", "a"} = {"a", "bb"}' "TRUE")
  ==
::
++  test-dedup-is-unaffected
  (ex 'Cardinality({"a", "a", "b"})' "2")
::
++  test-order-is-stable-across-shapes
  ::  the same three strings sort the same way however they are written, so a
  ::  result never depends on where in the spec a string first appeared —
  ::  which is exactly the tlc2 property this port trades away
  ;:  weld
    (ex '{"bb", "a", "ab"}' (trip '{"a", "ab", "bb"}'))
    (ex '{"ab", "bb", "a"}' (trip '{"a", "ab", "bb"}'))
    (ex '{"a"} \\union {"bb", "ab"}' (trip '{"a", "ab", "bb"}'))
  ==
--
