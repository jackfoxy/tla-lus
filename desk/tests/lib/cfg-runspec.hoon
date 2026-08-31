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
::
::  +|  R2.7.7.1 — `.cfg` keywords: acted on, or refused BY NAME
::
++  ukw
  ::  the refusal for a `.cfg` text, or "~" when the config is clean
  |=  cfg=@t
  ^-  tape
  =/  pr  (parse-cfg:config cfg)
  ?:  ?=(%| -.pr)  "PARSE-ERROR"
  =/  u  (unsupported-kw:config p.pr)
  ?~(u "~" (trip u.u))
::
++  starts
  ::  assert a refusal BEGINS with the expected text, comparing the prefix
  ::  rather than a hand-counted length -- the first draft counted three of
  ::  the four wrong
  |=  [r=tape want=tape]
  ^-  tang
  (expect-eq !>(want) !>((scag (lent want) r)))
::
++  test-cfg-keyword-coverage
  ::  THE DRIFT GUARD (R2.7.7.0 found this side had none, where the operator
  ::  surfaces have `gen-stdops-tests.py`). Every keyword the parser accepts is
  ::  either acted on or refused by name -- never both, never neither. A
  ::  keyword added to `+keywords` without a decision fails HERE, which is the
  ::  only reason POSTCONDITION could sit accepted-and-ignored for two
  ::  releases without a single test noticing
  =/  known  (~(uni in kw-handled:config) kw-refused:config)
  ;:  weld
    ::  the union covers the parser's keyword set exactly, both ways
    (expect-eq !>(~(wyt in keywords:config)) !>(~(wyt in known)))
    (expect-eq !>(*(list @t)) !>(~(tap in (~(dif in keywords:config) known))))
    (expect-eq !>(*(list @t)) !>(~(tap in (~(dif in known) keywords:config))))
    ::  and nothing is in both lists
    (expect-eq !>(*(list @t)) !>(~(tap in (~(int in kw-handled:config) kw-refused:config))))
  ==
::
++  test-cfg-clean-config-is-not-refused
  (expect-eq !>("~") !>((ukw 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a')))
::
++  test-cfg-postcondition-refused-by-name
  ::  the one that reported `ok` for a run tlc2 FAILS (R2.7.7.0's
  ::  `cfg-post-false`), so the refusal names the keyword and says why
  =/  r  (ukw 'INIT Init\0aNEXT Next\0aPOSTCONDITION Post\0a')
  ;:  weld
    (starts r "unsupported: POSTCONDITION Post")
    (expect-eq !>(&) !>(!=(~ (find "after state-space exploration" r))))
  ==
::
++  test-cfg-possible-refused-by-name
  =/  r  (ukw 'INIT Init\0aNEXT Next\0a_POSSIBLE Inv Inv2\0a')
  (starts r "unsupported: _POSSIBLE Inv")
::
++  test-cfg-periodic-refused-by-name
  ::  verdict-affecting at the pin: false ENDS the run (EC.TLC_ASSUMPTION_FALSE)
  =/  r  (ukw 'INIT Init\0aNEXT Next\0a_PERIODIC Inv\0a')
  (starts r "unsupported: _PERIODIC Inv")
::
++  test-cfg-rlreward-refused-by-name
  ::  the capability is out of scope (an RL simulation worker behind a JVM
  ::  system property); accepting the keyword silently is not
  =/  r  (ukw 'INIT Init\0aNEXT Next\0a_RL_REWARD Inv\0a')
  (starts r "unsupported: _RL_REWARD Inv")
--
