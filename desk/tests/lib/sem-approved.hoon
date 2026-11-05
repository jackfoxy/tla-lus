::  The semantic graph's approved differences (R4.5.1, R4.5.2), asserted on
::  the port's side; each names its ledger row. The pin's own output is
::  captured in test-data/sem/<case>/golden.txt (inst-noparam,
::  mdef-inner-ext), whose generated arms gen-sem-tests.py withholds or cuts
::  to the DIAGS.
/+  *test
/=  semantic  /lib/semantic
|%
::
++  test-substin-zero-wrapper
  ::  `sem-substin-zero`: an INSTANCE of a module with no CONSTANT or
  ::  VARIABLE wraps each imported body in `substin subs=0`, where SemDump
  ::  shows the body alone
  %+  expect-eq
    !>  ^-  wain
    :~  'ACCEPT'
        'MODULE A 1.1-3.4'
        '  def I!F arity=0 local=n L0 2.1-2.15'
        '    substin subs=0 L0 2.1-2.15'
        '      in'
        '        num 1 L0 2.6-2.6'
        '  instance name=I module=B local=n L0 2.1-2.15'
        'LEVELS'
        'lvl MODULE A L-1'
        'lvl I!F L0'
    ==
  !>
  %+  dump-sem:semantic  'A'
  %-  malt
  ^-  (list [@t @t])
  :~  ['A' '---- MODULE A ----\0aI == INSTANCE B\0a====\0a']
      ['B' '---- MODULE B ----\0aF == 1\0a====\0a']
  ==
::
++  test-inner-module-section-not-rendered
  ::  `sem-inner-module-dump`: SemDump nests an inner module's own section
  ::  (`MODULE Inner`, its declarations and definitions, its LEVELS rows) in
  ::  the parent's dump; the port's dump is the parent's alone. The pin's is
  ::  test-data/sem/mdef-inner-ext/golden.txt
  %+  expect-eq
    !>  ^-  wain
    :~  'ACCEPT'
        'MODULE A 1.1-7.4'
        '  def P arity=0 local=n L0 6.1-6.24'
        '    apply $BoundedExists opkind=BuiltInKind L0 6.6-6.24'
        '      bound m L-1 6.9-6.9'
        '        apply $SetEnumerate opkind=BuiltInKind L0 6.15-6.17'
        '          num 1 L0 6.16-6.16'
        '      apply TRUE opkind=BuiltInKind L0 6.21-6.24'
        'LEVELS'
        'lvl MODULE A L-1'
        'lvl P L0'
    ==
  !>
  %+  dump-sem:semantic  'A'
  %-  malt
  ^-  (list [@t @t])
  :~  :-  'A'
      %-  crip
      ;:  weld
        "---- MODULE A ----\0a---- MODULE Inner ----\0aEXTENDS B\0a"
        "Q == m\0a====\0aP == \\E m \\in \{1} : TRUE\0a====\0a"
      ==
      ['B' '---- MODULE B ----\0aVARIABLE m\0a====\0a']
  ==
::
++  test-multiply-defined-first-line
  ::  `sem-diag-location`: SANY's 4201 Multiply-defined message continues
  ::  on a second line naming the other symbol's location ("with the one
  ::  at line 2, col 10 to line 2, col 10 of module A."); the port's
  ::  message is the first line, trailing space included
  =/  ag
    %+  analyze-graph:semantic  'A'
    %-  malt
    ^-  (list [@t @t])
    :~  :-  'A'
        '---- MODULE A ----\0aVARIABLE i\0aP == \\E i \\in {1} : TRUE\0a====\0a'
    ==
  =/  msgs=(list @t)
    ?~  ag  ~
    (turn sem.u.ag |=(d=sdiag:semantic msg.d))
  %+  expect-eq
    !>  ^-  (list @t)
    ~['Multiply-defined symbol \'i\': this definition or declaration conflicts ']
  !>  msgs
--
