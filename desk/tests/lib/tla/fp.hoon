::  FP64 fingerprints + FPSet semantics (Work Unit 7.1). Vectors captured from
::  tlc2 at the pinned commit via SafetyDump/-fp 0 (desk/test-data/safety trace
::  fingerprints). Values never cross this low-budget test core: fingerprints
::  are computed from the WU6.8 `fp-of-text` byte stream, not constructed values
::  (except the single state-fp arm, which builds a tiny state via `vin`).
/+  *test
/=  fp  /lib/tla/tlc/fingerprint
/=  ne  /lib/tla/tlc/node-eval
/=  v   /lib/tla/tlc/value
|%
::  FP64 hash of a constant expression's value (New then Extend over fp-input)
++  h   |=(t=@t ^-(@ux (fp-bytes:fp fp-new:fp (fp-of-text:ne t))))
::  FP64 over two variables' value byte streams, in order a then b
++  h2
  |=  [a=@t b=@t]
  ^-  @ux
  (fp-bytes:fp (fp-bytes:fp fp-new:fp (fp-of-text:ne a)) (fp-of-text:ne b))
::  a value fingerprints identically across representations
++  same  |=([a=@t b=@t] (expect-eq !>(%.y) !>(=((h a) (h b)))))
++  diff  |=([a=@t b=@t] (expect-eq !>(%.n) !>(=((h a) (h b)))))
++  is    |=([f=@ux t=@t] (expect-eq !>(f) !>((h t))))
::
::  +|  single-value vectors (match SafetyDump trace fingerprints)
::
++  test-fp-int0  (is 0xd0ba.3e88.0dcd.d983 '0')
++  test-fp-int1  (is 0xf678.93cf.a654.c4b3 '1')
++  test-fp-int3  (is 0xbbfd.c940.f166.fed3 '3')
::
::  +|  state fingerprints (FP64 over variables in declaration order)
::
::  the diamond initial state {a |-> 0, b |-> 0} fingerprints to the oracle
::  value 0x17e2.5f7c.55c6.ef92; the byte-composition (var a then var b) must
::  match the state-fp arm folding over the same order
++  test-fp-state-ab-bytes  (expect-eq !>(0x17e2.5f7c.55c6.ef92) !>((h2 '0' '0')))
++  test-fp-state-ab-arm
  %+  expect-eq
    !>  0x17e2.5f7c.55c6.ef92
  !>  ^-  @ux
  (state-fp:fp ~['a' 'b'] (malt ~[['a' (vin:v 0)] ['b' (vin:v 0)]]))
::  order matters: swapping the variable order changes the fingerprint
++  test-fp-state-order
  (expect-eq !>(%.n) !>(=((h2 '0' '1') (h2 '1' '0'))))
::
::  +|  cross-representation collapse (equal values share a fingerprint)
::
++  test-fp-intv-set   (same '1..3' '{1, 2, 3}')
++  test-fp-tuple-fcn  (same '<<1, 2>>' '[i \\in 1..2 |-> i]')
++  test-fp-rec-order  (same '[a |-> 1, b |-> 2]' '[b |-> 2, a |-> 1]')
::
::  +|  distinct values -> distinct fingerprints
::
++  test-fp-diff-set   (diff '{1, 2}' '{1, 3}')
++  test-fp-diff-kind  (diff '1' '"1"')
::
::  +|  FPSet observable semantics (membership, first-seen depth, distinct)
::
++  test-fps-empty
  (expect-eq !>([%.n 0]) !>([(fs-has:fp fs-empty:fp 0xaa) (fs-size:fp fs-empty:fp)]))
++  test-fps-put-new
  =/  r  (fs-put:fp fs-empty:fp 0xaa 3)
  %+  expect-eq
    !>  [%.y %.y 1 `@ud`3]
  !>  :*  added.r
          (fs-has:fp +.r 0xaa)
          (fs-size:fp +.r)
          (need (fs-depth:fp +.r 0xaa))
      ==
++  test-fps-put-seen
  ::  re-inserting a present fingerprint at a deeper depth is not "added" and
  ::  keeps the original first-seen depth
  =/  r0  (fs-put:fp fs-empty:fp 0xaa 3)
  =/  r1  (fs-put:fp +.r0 0xaa 9)
  %+  expect-eq
    !>  [%.n 1 `@ud`3]
  !>  [added.r1 (fs-size:fp +.r1) (need (fs-depth:fp +.r1 0xaa))]
++  test-fps-distinct
  =/  r0  (fs-put:fp fs-empty:fp 0xaa 1)
  =/  r1  (fs-put:fp +.r0 0xbb 2)
  (expect-eq !>(`@ud`2) !>((fs-size:fp +.r1)))
--
