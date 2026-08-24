::  SPECIFICATION decomposition (SpecProcessor.processConfigSpec port, WU5.3c/8.1):
::  a SPECIFICATION `Init /\ [][Next]_v /\ Fairness` resolves to the same Init and
::  Next the INIT/NEXT config keys give, and its WF_/SF_ conjuncts are extracted
::  as the fairness list the liveness engine (unit 8) consumes.
/+  *test
/=  check  /lib/check
|%
++  mod-safety
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 3
  Spec == Init /\ [][Next]_x
  Inv == x < 3
  ====
  '''
::
::  A SPECIFICATION run and the equivalent INIT/NEXT run must be byte-identical:
::  the decomposition recovers the same initial predicate and next-state action.
++  test-spec-mode-matches-init-next
  =/  a  (check:check mod-safety 'SPECIFICATION Spec\0aINVARIANT Inv\0a')
  =/  b  (check:check mod-safety 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a')
  (expect-eq !>(b) !>(a))
::
::  A fairness conjunct in the SPECIFICATION is extracted (getTemporals): the
::  decomposition yields exactly one WF_ fairness node.
++  mod-fair
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Inc == x < 2 /\ x' = x + 1
  Next == Inc \/ (x = 2 /\ x' = 2)
  Spec == Init /\ [][Next]_x /\ WF_x(Inc)
  Inv == x < 3
  ====
  '''
::
++  test-fairness-conjunct-extracted
  =/  sc  (search-ctx:check mod-fair 'SPECIFICATION Spec\0aINVARIANT Inv\0a')
  ?:  ?=(%| -.sc)  (expect-eq !>(`@t`'ok') !>(p.sc))
  (expect-eq !>(1) !>((lent fair.p.sc)))
::
::  No fairness in an INIT/NEXT run: the fairness list is empty.
++  test-init-next-has-no-fairness
  =/  sc  (search-ctx:check mod-safety 'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a')
  ?:  ?=(%| -.sc)  (expect-eq !>(`@t`'ok') !>(p.sc))
  (expect-eq !>(0) !>((lent fair.p.sc)))
::
::  +|  Named Non-Ports Of The Decomposition (R2.3.5)
::
++  mod-inst
  ::  a SPECIFICATION reached THROUGH an INSTANCE: `I!SpecI` is a `$SubstIn`
  ::  wrapper over the inner module's spec
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  ---- MODULE inner ----
  EXTENDS Naturals
  VARIABLE v
  CONSTANT k
  SpecI == (v = 0) /\ [][v' = (v + 1) % k]_v
  ====
  I == INSTANCE inner WITH v <- x, k <- 3
  Spec == I!SpecI
  Inv == x < 9
  ====
  '''
::
++  test-instance-substitution-runs
  ::  R2.3.5: a SPECIFICATION reached THROUGH an instance decomposes and runs.
  ::  `+decompose-spec` peels the `$SubstIn` and re-wraps every leaf with the
  ::  instance's bindings (`Specs.addSubsts`); `node-eval` binds them, keeping
  ::  a substitution onto a bare state variable as a NODE so the inner module's
  ::  `v' = ...` is still an assignment to the OUTER `x`
  %+  expect-eq
    !>  ^-  wain
    :~  'Model checking completed. No error has been found.'
        '4 states generated, 3 distinct states found, 0 states left on queue.'
        'The depth of the complete state graph search is 3.'
    ==
  !>  (check:check mod-inst 'SPECIFICATION Spec\0aINVARIANT Inv\0a')
::
++  mod-inst-sibling
  ::  the residue R2.3.5 FOUND rather than inherited: an instanced member that
  ::  references a SIBLING member of its own module
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  ---- MODULE inner ----
  EXTENDS Naturals
  VARIABLE v
  CONSTANT k
  InitI == v = 0
  NextI == v' = (v + 1) % k
  SpecI == InitI /\ [][NextI]_v
  ====
  I == INSTANCE inner WITH v <- x, k <- 3
  Spec == I!SpecI
  Inv == x < 9
  ====
  '''
::
++  test-instance-sibling-reference-refused-by-name
  ::  NOT a substitution failure -- substitution works, as the arm above shows.
  ::  The root `defs` map holds instanced members QUALIFIED (`I!InitI`), so a
  ::  bare sibling reference inside the substitution resolves to nothing. That
  ::  is instance GENERATION (unit 3), and it is refused by name because
  ::  dropping it produced `the SPECIFICATION has no initial predicate` --
  ::  true of nothing the caller wrote
  %+  expect-eq
    !>  ^-  wain
    :~  'Error: unsupported: instanced member references a sibling of its own module (InitI); the root defs map holds instanced members qualified (unit 3)'
    ==
  !>  (check:check mod-inst-sibling 'SPECIFICATION Spec\0aINVARIANT Inv\0a')
::
++  mod-lazy
  ::  a parameterized operator as the behaviour spec (Github1244's shape)
  '''
  ---- MODULE A ----
  EXTENDS Naturals
  VARIABLE x
  Init == x = 0
  Next == x' = (x + 1) % 3
  MyInit(i) == i
  Spec == MyInit(Init) /\ [][Next]_x
  Inv == x < 9
  ====
  '''
::
++  test-lazy-parameter-inlining
  ::  R2.3.5: `MyInit(Init)` inlines -- formals bind to arguments and the body
  ::  is decomposed in that scope, so `Init` reaches the init-conjunct list.
  ::  Before, the un-inlined apply became an init conjunct and evaluating it
  ::  bound nothing: `variable is unassigned in the current state: x`
  %+  expect-eq
    !>  ^-  wain
    :~  'Model checking completed. No error has been found.'
        '4 states generated, 3 distinct states found, 0 states left on queue.'
        'The depth of the complete state graph search is 3.'
    ==
  !>  (check:check mod-lazy 'SPECIFICATION Spec\0aINVARIANT Inv\0a')
--
