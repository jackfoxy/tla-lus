/-  *tla-lus
/+  *test
/=  diag-lib  /lib/tla/diagnostics
|%
  ::  Tests For Deterministic Ordering
  ::
++  mk-diag
  |=  [fam=code-family num=@ud at=(unit loc)]
  ^-  diagnostic
  [[fam num] %error %parse 'msg' at ~]
::
++  d-global   (mk-diag %lus 1 ~)
++  d-a11-sany  (mk-diag %sany 2 `['A' [1 1] [1 5]])
++  d-a11-tlc   (mk-diag %tlc 2 `['A' [1 1] [1 5]])
++  d-a21       (mk-diag %sany 3 `['A' [2 1] [2 5]])
++  d-b11       (mk-diag %sany 4 `['B' [1 1] [1 5]])
::
++  expected
  ^-  (list diagnostic)
  ~[d-global d-a11-sany d-a11-tlc d-a21 d-b11]
::
++  test-sort-diags
  =/  shuffled
    ^-  (list diagnostic)
    ~[d-b11 d-a11-tlc d-global d-a21 d-a11-sany]
  (expect-eq !>(expected) !>((sort-diags:diag-lib shuffled)))
::
++  test-sort-diags-stable-under-resort
  =/  once  (sort-diags:diag-lib expected)
  (expect-eq !>(once) !>((sort-diags:diag-lib once)))
::
++  test-same-loc-family-order
  ::  same span: %sany sorts before %tlc
  =/  got  (sort-diags:diag-lib ~[d-a11-tlc d-a11-sany])
  (expect-eq !>(~[d-a11-sany d-a11-tlc]) !>(got))
::
++  test-code-number-tiebreak
  =/  lo  (mk-diag %sany 10 `['A' [1 1] [1 1]])
  =/  hi  (mk-diag %sany 20 `['A' [1 1] [1 1]])
  (expect-eq !>(~[lo hi]) !>((sort-diags:diag-lib ~[hi lo])))
::
++  test-sort-bindings
  =/  got
    %-  sort-bindings:diag-lib
    ~[['z' '1'] ['alpha' '2'] ['beta' '3']]
  (expect-eq !>(~[['alpha' '2'] ['beta' '3'] ['z' '1']]) !>(got))
--
