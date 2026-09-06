::  canonical FP64 input bytes (WU6.8): equal-across-representation values
::  share a byte stream, structurally distinct values do not. Driven by text
::  so no value crosses the low-budget test core.
/+  *test
/=  ne  /lib/node-eval
|%
++  same
  |=  [a=@t b=@t]
  ^-  tang
  (expect-eq !>(%.y) !>(=((fp-of-text:ne a) (fp-of-text:ne b))))
::
++  diff
  |=  [a=@t b=@t]
  ^-  tang
  (expect-eq !>(%.n) !>(=((fp-of-text:ne a) (fp-of-text:ne b))))
::
::  cross-representation equal values -> identical bytes
++  test-intv-set   (same '1..3' '{1, 2, 3}')
++  test-tuple-fcn  (same '<<1, 2>>' '[i \\in 1..2 |-> i]')
++  test-rec-order  (same '[a |-> 1, b |-> 2]' '[b |-> 2, a |-> 1]')
++  test-set-order  (same '{3, 1, 2}' '{1, 2, 3}')
++  test-set-dedup  (same '{1, 1, 2}' '{1, 2}')
::  structurally distinct values -> distinct bytes
++  test-diff-set   (diff '{1, 2}' '{1, 3}')
++  test-diff-int   (diff '1' '2')
++  test-diff-str   (diff '"a"' '"b"')
++  test-diff-kind  (diff '1' '"1"')
++  test-diff-tuple  (diff '<<1, 2>>' '<<2, 1>>')
::  concrete byte stream: INTVALUE tag then -7 as 32-bit little-endian
++  test-bytes-neg
  (expect-eq !>(`(list @D)`~[1 249 255 255 255]) !>((fp-of-text:ne '-7')))
++  test-bytes-true
  (expect-eq !>(`(list @D)`~[0 't']) !>((fp-of-text:ne 'TRUE')))
--
