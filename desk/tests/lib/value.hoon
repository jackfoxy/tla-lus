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
/=  fpl  /lib/fingerprint
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
::  R4.P5: +fp-walk folds FP64 over a normalized value with no byte list;
::  on random values it must equal FP64 over the +fp-enc byte list. The
::  generator draws no model values or negative integers, so those start
::  the count
++  test-fp-walk-matches-bytes
  =/  rng  ~(. og 0xbeef.0045)
  =/  bad=@ud
    %+  roll  `(list value:v)`~[[%model 'm1'] [%int -5] [%str 'hello']]
    |=  [x=value:v n=@ud]
    =/  w  (fp-walk:fpl fp-new:fpl x)
    ?:(=(w (fp-bytes:fpl fp-new:fpl (fp-enc:v x))) n +(n))
  =/  i  0
  |-  ^-  tang
  ?:  =(i 400)  (expect-eq !>(0) !>(bad))
  =^  a  rng  (rand-val rng 3)
  =/  n  (normalize:v a)
  =/  w  (fp-walk:fpl fp-new:fpl n)
  $(i +(i), bad ?:(=(w (fp-bytes:fpl fp-new:fpl (fp-enc:v n))) bad +(bad)))
::
::  R4.P5: +i32 (bit arithmetic) against the +old:si formula it replaced,
::  across the sign, the 32-bit boundary and wrap-around
++  test-i32-matches-reference
  =/  ref
    |=  n=@sd
    ^-  @
    =/  o  (old:si n)
    (mod ?:(-.o +.o (sub (bex 32) (mod +.o (bex 32)))) (bex 32))
  =/  ns=(list @sd)
    :~  --0  --1  -1  --255  -256  --2.147.483.647  -2.147.483.648
        --4.294.967.296  -4.294.967.296  --4.294.967.297  -4.294.967.297
        --12.345.678.901  -12.345.678.901
    ==
  %+  expect-eq  !>(`(list @sd)`~)
  !>((skip ns |=(n=@sd =((ref n) (i32:v n)))))
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
