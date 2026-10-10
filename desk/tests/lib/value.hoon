::  Smoke test for the canonical TLC value layer (unit 6.1).
::
::  Only a single value-typed expression: the zuse-408 mull has a very low
::  budget for the recursive `value` mold inside an external test core (more
::  than ~1-2 value constructions overflows it), so value.hoon is exercised
::  comprehensively two other ways instead — direct dojo evaluation, and the
::  differential EvalDump path once the semantic evaluator renders values to
::  text (unit 6.5). Production evaluation lives in a single core, so values
::  never cross a boundary there.
/+  *test
/=  v  /lib/value
|%
++  test-value-render-smoke
  (expect-eq !>("42") !>((render:v (vin:v 42))))
::
::  R4.P4: `+equal` now compares exact keys (`+ekey`); this checks it against
::  the pairwise relation it replaced, `+equal-norm-ref` over the normal forms,
::  on random values -- nested sets, intervals, tuples, records, functions --
::  drawn so that equal pairs (permuted, duplicated, interval-for-set, tuple-
::  for-function) are common. Every case must agree
++  test-ekey-matches-reference
  =/  rng  ~(. og 0xbeef.0044)
  =/  bad=@ud  0
  =/  i  0
  |-  ^-  tang
  ?:  =(i 600)  (expect-eq !>(0) !>(bad))
  =^  a  rng  (rand-val rng 3)
  =^  m  rng  (rads:rng 3)
  =^  b  rng  ?:(=(0 m) [a rng] ?:(=(1 m) [(twist a) rng] (rand-val rng 3)))
  =/  ref  (equal-norm-ref:v (normalize:v a) (normalize:v b))
  $(i +(i), bad ?:(=(ref (equal:v a b)) bad +(bad)))
::
++  twist
  ::  an EQUAL value in another representation: reversed and duplicated
  ::  elements, a tuple as a function, an interval as its set
  |=  a=value:v
  ^-  value:v
  ?+  -.a  a
    %set   [%set cls.a (weld (flop p.a) p.a)]
    %intv  [%set %set-enum (flop (expand-intv:v lo.a hi.a))]
    %seq   [%fcn (flop (fcn-pairs:v a))]
    %rec   [%fcn (flop (fcn-pairs:v a))]
    %fcn   [%fcn (flop p.a)]
  ==
::
++  rand-val
  |=  [rng=_og d=@ud]
  ^-  [value:v _og]
  =^  k  rng  (rads:rng ?:(=(0 d) 3 8))
  ?+  k  !!
    %0  =^(n rng (rads:rng 4) [[%int (sun:si n)] rng])
    %1  =^(n rng (rads:rng 3) [[%str ?:(=(0 n) 'a' ?:(=(1 n) 'b' 'c'))] rng])
    %2  =^(n rng (rads:rng 2) [[%bool =(0 n)] rng])
    %3  =^(n rng (rads:rng 3) [[%intv --1 (sun:si n)] rng])
    %4  =^(xs rng (rand-list rng (dec d)) [[%set %set-enum xs] rng])
    %5  =^(xs rng (rand-list rng (dec d)) [[%seq xs] rng])
    %6  =^(xs rng (rand-list rng (dec d)) [[%rec (rec-of xs)] rng])
    %7
      =^  xs  rng  (rand-list rng (dec d))
      [[%fcn (fcn-of xs)] rng]
  ==
::
++  rand-list
  |=  [rng=_og d=@ud]
  ^-  [(list value:v) _og]
  =^  n  rng  (rads:rng 4)
  =|  out=(list value:v)
  |-  ^-  [(list value:v) _og]
  ?:  =(0 n)  [out rng]
  =^  x  rng  (rand-val rng d)
  $(n (dec n), out [x out])
::
++  rec-of
  ::  distinct field names a, b, c ... over the values
  |=  xs=(list value:v)
  ^-  (list vfield:v)
  =/  i  0
  |-  ^-  (list vfield:v)
  ?~  xs  ~
  [[(snag i `(list @t)`~['a' 'b' 'c' 'd']) i.xs] $(xs t.xs, i +(i))]
::
++  fcn-of
  ::  distinct integer domain points 1, 2, 3 ... over the values
  |=  xs=(list value:v)
  ^-  (list vpair:v)
  =/  i  1
  |-  ^-  (list vpair:v)
  ?~  xs  ~
  [[[%int (sun:si i)] i.xs] $(xs t.xs, i +(i))]
--
