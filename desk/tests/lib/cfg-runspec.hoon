::  Hand-written unit tests for the unit-5.4 typed run-spec assembly.
::  Not differential (the run-spec is an internal typed hand-off, not a
::  Java-visible noun); asserts mode selection, section multiplicity and
::  order, the deadlock flag, and that assembly reuses validate-config's
::  rejections. Base spec: a constant-free A.tla with Init/Next/Inv/Spec.
/+  *test
/=  config  /lib/config
|%
++  basemap
  ^-  (map @t @t)
  %-  malt
  ^-  (list [@t @t])
  :~  :-  'A'
      '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = x + 1\0aInv == x >= 0\0aInv2 == x /= 5\0aSpec == Init /\\ [][Next]_x\0a====\0a'
  ==
::
++  rs
  |=  cfg=@t
  ^-  (each run-spec:config cfg-vdiag:config)
  (run-spec-of:config 'A' basemap cfg)
::
++  join-c
  |=  l=(list @t)
  ^-  tape
  ?~  l  "~"
  ?~  t.l  (trip i.l)
  :(weld (trip i.l) "," $(l t.l))
::
++  summ
  ::  a comparable projection of a run-spec result
  |=  r=(each run-spec:config cfg-vdiag:config)
  ^-  tape
  ?:  ?=(%| -.r)  (weld "REJECT " (trip (scot %ud code.p.r)))
  =/  s  p.r
  =/  md=tape
    ?-  -.mode.s
      %spec       (weld "spec:" (trip name.mode.s))
      %init-next  :(weld "in:" ?~(init.mode.s "~" (trip u.init.mode.s)) "/" ?~(next.mode.s "~" (trip u.next.mode.s)))
    ==
  =/  iv=tape  (join-c invariants.s)
  =/  pr=tape  (join-c properties.s)
  =/  dl=tape  ?:(deadlock.s "y" "n")
  :(weld md " inv=" iv " prop=" pr " dl=" dl)
::
++  test-run-spec-init-next
  %+  expect-eq
    !>  "in:Init/Next inv=Inv prop=~ dl=y"
  !>  (summ (rs 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'))
::
++  test-run-spec-spec-mode
  %+  expect-eq
    !>  "spec:Spec inv=~ prop=~ dl=y"
  !>  (summ (rs 'SPECIFICATION Spec\0a'))
::
++  test-run-spec-deadlock-false
  %+  expect-eq
    !>  "in:Init/Next inv=~ prop=~ dl=n"
  !>  (summ (rs 'INIT Init\0aNEXT Next\0aCHECK_DEADLOCK FALSE\0a'))
::
++  test-run-spec-multi-invariant
  %+  expect-eq
    !>  "in:Init/Next inv=Inv,Inv2 prop=~ dl=y"
  !>  (summ (rs 'INIT Init\0aNEXT Next\0aINVARIANT Inv Inv2\0a'))
::
++  test-run-spec-reject-undef
  %+  expect-eq
    !>  "REJECT 2.229"
  !>  (summ (rs 'INIT NoSuchInit\0aNEXT Next\0a'))
::
++  test-run-spec-reject-both
  %+  expect-eq
    !>  "REJECT 2.227"
  !>  (summ (rs 'SPECIFICATION Spec\0aINIT Init\0aNEXT Next\0a'))
--
