::  Unit-4.1 constraint-set algebra tests (SetOfLevelConstraints /
::  SetOfArgLevelConstraints / ArgLevelParam semantics): level
::  constraints min-merge, arg-level constraints max-merge, both
::  order-independent internally and deterministically rendered.
::  Table-driven over small key sets; rendering must not depend on Hoon
::  map tree shape, so merges built in different insertion orders must
::  render identically.
/+  *test
/=  semantic  /lib/semantic
|%
+$  lkey  lkey:semantic
::
++  kx  `lkey`['' 'x' %constant]
++  ky  `lkey`['' 'y' %variable]
++  kp  `lkey`['Op' 'p' %formal-param]
::  same name as kx, different owner: a distinct identity that renders
::  to the same text (SANY keys by SymbolNode identity)
++  kx2  `lkey`['b3.4' 'x' %formal-param]
::
++  lc-of
  |=  l=(list [lkey @ud])
  ^-  (map lkey @ud)
  =/  acc  *(map lkey @ud)
  |-  ^-  (map lkey @ud)
  ?~  l  acc
  $(l t.l, acc (lc-put:semantic acc i.l))
::
++  ac-of
  |=  l=(list [[lkey @ud] @ud])
  ^-  (map [k=lkey i=@ud] @ud)
  =/  acc  *(map [k=lkey i=@ud] @ud)
  |-  ^-  (map [k=lkey i=@ud] @ud)
  ?~  l  acc
  $(l t.l, acc (ac-put:semantic acc i.l))
::
++  rn-lc  |=(m=(map lkey @ud) (seg-set:semantic "lc" (rn-lc-entries:semantic m)))
++  rn-ac
  |=  m=(map [k=lkey i=@ud] @ud)
  (seg-set:semantic "alc" (rn-alc-entries:semantic m))
::
::  level constraints: insert keeps the tighter (smaller) maximum
++  test-lc-put-min
  ;:  weld
    %+  expect-eq
      !>  `(unit @ud)`[~ 1]
    !>  (~(get by (lc-of ~[[kx 3] [kx 1] [kx 2]])) kx)
  ::
    %+  expect-eq
      !>  `(unit @ud)`[~ 0]
    !>  (~(get by (lc-of ~[[kx 0] [kx 3]])) kx)
  ==
::
::  arg-level constraints: insert keeps the stronger (larger) minimum
++  test-ac-put-max
  ;:  weld
    %+  expect-eq
      !>  `(unit @ud)`[~ 3]
    !>  (~(get by (ac-of ~[[[kp 0] 1] [[kp 0] 3] [[kp 0] 2]])) [kp 0])
  ::
    %+  expect-eq
      !>  `(unit @ud)`[~ 2]
    !>  (~(get by (ac-of ~[[[kp 1] 2] [[kp 1] 0]])) [kp 1])
  ==
::
::  union merge direction matches insert direction
++  test-lc-uni-min
  =/  a  (lc-of ~[[kx 3] [ky 1]])
  =/  b  (lc-of ~[[kx 0] [kp 2]])
  =/  u  (lc-uni:semantic a b)
  ;:  weld
    (expect-eq !>(`(unit @ud)`[~ 0]) !>((~(get by u) kx)))
    (expect-eq !>(`(unit @ud)`[~ 1]) !>((~(get by u) ky)))
    (expect-eq !>(`(unit @ud)`[~ 2]) !>((~(get by u) kp)))
  ==
::
++  test-ac-uni-max
  =/  a  (ac-of ~[[[kx 0] 1] [[ky 2] 2]])
  =/  b  (ac-of ~[[[kx 0] 3]])
  =/  u  (ac-uni:semantic a b)
  ;:  weld
    (expect-eq !>(`(unit @ud)`[~ 3]) !>((~(get by u) [kx 0])))
    (expect-eq !>(`(unit @ud)`[~ 2]) !>((~(get by u) [ky 2])))
  ==
::
::  empty identities
++  test-uni-empty
  =/  a  (lc-of ~[[kx 2]])
  =/  c  (ac-of ~[[[kp 0] 1]])
  ;:  weld
    (expect-eq !>(a) !>((lc-uni:semantic a *(map lkey @ud))))
    (expect-eq !>(a) !>((lc-uni:semantic *(map lkey @ud) a)))
    (expect-eq !>(c) !>((ac-uni:semantic c *(map [k=lkey i=@ud] @ud))))
    (expect-eq !>(c) !>((ac-uni:semantic *(map [k=lkey i=@ud] @ud) c)))
  ==
::
::  order independence: permuted insertion and merge order reach the
::  same map and the same rendering
++  test-order-independent
  =/  a  (lc-of ~[[kx 3] [ky 1] [kp 2] [kx2 0]])
  =/  b  (lc-of ~[[kx2 0] [kp 2] [kx 3] [ky 1]])
  =/  c  (lc-uni:semantic (lc-of ~[[kx 3] [ky 1]]) (lc-of ~[[kp 2] [kx2 0]]))
  =/  d  (lc-uni:semantic (lc-of ~[[kp 2] [kx2 0]]) (lc-of ~[[kx 3] [ky 1]]))
  ;:  weld
    (expect-eq !>(a) !>(b))
    (expect-eq !>(c) !>(d))
    (expect-eq !>(a) !>(c))
    (expect-eq !>((rn-lc a)) !>((rn-lc d)))
  ==
::
::  conflicting duplicate keys collapse per identity; distinct
::  identities with the same name both render (SANY node-keyed sets)
++  test-render-duplicate-names
  =/  m  (lc-of ~[[kx 2] [kx2 2] [kx 3]])
  (expect-eq !>(" lc=\{x<=2,x<=2}") !>((rn-lc m)))
::
::  deterministic render: byte-lexicographic entry order (uppercase
::  before lowercase, exactly Java Collections.sort on strings)
++  test-render-sorted
  =/  m  (lc-of ~[[ky 1] [`lkey`['' 'P' %constant] 3] [kx 2]])
  (expect-eq !>(" lc=\{P<=3,x<=2,y<=1}") !>((rn-lc m)))
::
++  test-render-alc
  =/  m  (ac-of ~[[[kp 1] 2] [[kp 0] 0]])
  (expect-eq !>(" alc=\{(p,0)>=0,(p,1)>=2}") !>((rn-ac m)))
::
++  test-render-empty-omitted
  ;:  weld
    (expect-eq !>("") !>((rn-lc *(map lkey @ud))))
    (expect-eq !>("") !>((rn-ac *(map [k=lkey i=@ud] @ud))))
    (expect-eq !>("") !>((seg-set:semantic "lp" ~)))
  ==
::
::  the pure configuration-target validation gate (unit 4.6): accept a
::  resolved definition at or below the required maximum level, reject
::  with a structured diagnostic above it or when unresolved
++  spec-module
  ^-  @t
  %-  crip
  ;:  weld
    "---- MODULE A ----\0a"
    "VARIABLE x\0a"
    "Init == x = 0\0a"
    "Next == x' = x\0a"
    "====\0a"
  ==
::
++  checked
  ^-  sem-module:semantic
  (need (generate:semantic 'A' (malt ~[['A' spec-module]])))
::
++  test-validate-target-ok
  =/  m  checked
  ;:  weld
    (expect-eq !>([%& 1]) !>((validate-target:semantic m 'Init' 1)))
    (expect-eq !>([%& 2]) !>((validate-target:semantic m 'Next' 2)))
    (expect-eq !>([%& 1]) !>((validate-target:semantic m 'Init' 3)))
  ==
::
++  test-validate-target-level-reject
  =/  r  (validate-target:semantic checked 'Next' 1)
  ;:  weld
    (expect-eq !>(%|) !>(-.r))
    %+  expect-eq  !>(&)
    !>  ?&(?=(%| -.r) =(0 code.p.r) =(%error sev.p.r))
  ==
::
++  test-validate-target-unknown
  =/  r  (validate-target:semantic checked 'Nope' 3)
  (expect-eq !>(%|) !>(-.r))
::
::  driver-level lint controls (SanySettings suppressedCodes /
::  messagesAsErrorCodes): report-time filtering and elevation of
::  linting warnings, invisible to the semantic Errors channel
++  lint-warns
  ^-  (list sdiag:semantic)
  :~  [4.802 %warning ~ 'field bar']
      [4.802 %warning ~ 'field baz']
  ==
::
++  no-opts  `lint-options:semantic`[~ ~]
::
++  test-lint-passthrough
  =/  r  (apply-lint-options:semantic no-opts lint-warns)
  (expect-eq !>([%& lint-warns]) !>(r))
::
++  test-lint-suppress
  =/  o  `lint-options:semantic`[(silt ~[4.802]) ~]
  =/  r  (apply-lint-options:semantic o lint-warns)
  (expect-eq !>([%& `(list sdiag:semantic)`~]) !>(r))
::
++  test-lint-elevate
  =/  o  `lint-options:semantic`[~ (silt ~[4.802])]
  =/  r  (apply-lint-options:semantic o lint-warns)
  =/  want=(list sdiag:semantic)
    :~  [4.802 %error ~ 'field bar']
        [4.802 %error ~ 'field baz']
    ==
  (expect-eq !>([%& want]) !>(r))
::
++  test-lint-partial-suppress
  ::  suppression keys on code; a different code passes through untouched
  =/  mixed=(list sdiag:semantic)
    :~  [4.802 %warning ~ 'lint']
        [4.801 %warning ~ 'dup']
    ==
  =/  o  `lint-options:semantic`[(silt ~[4.802]) ~]
  =/  r  (apply-lint-options:semantic o mixed)
  (expect-eq !>([%& `(list sdiag:semantic)`[[4.801 %warning ~ 'dup'] ~]]) !>(r))
::
++  test-lint-overlap-rejected
  =/  o  `lint-options:semantic`[(silt ~[4.802]) (silt ~[4.802])]
  =/  r  (apply-lint-options:semantic o lint-warns)
  (expect-eq !>(%|) !>(-.r))
--
