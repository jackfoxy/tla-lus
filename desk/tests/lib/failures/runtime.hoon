/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  failure-id: failure-b84cc0681b9a
::
++  test-runtime-false-assumption-c0681b9a
  =/  root  (crip "tests/fixtures/failures/runtime/Assumption.tla")
  =/  config  (crip "tests/fixtures/failures/runtime/Assumption.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'false-assumption'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %assumption-failure
      [~ 2.104]
      [~ 'assumption']
      ~
      ~
  ==
::
::  failure-id: failure-e54f4830461e
::
++  test-runtime-incomplete-initial-state-4830461e
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/IncompleteInit.t".
    "la"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/IncompleteInit.c".
    "fg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'incomplete-initial-state'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %evaluation-error
      [~ 2.106]
      [~ 'initial']
      ~
      ~
  ==
::
::  failure-id: failure-63fc591e1310
::
++  test-runtime-incomplete-next-state-591e1310
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/IncompleteNext.t".
    "la"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/IncompleteNext.c".
    "fg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'incomplete-next-state'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %evaluation-error
      [~ 2.109]
      [~ 'next']
      ~
      ~
  ==
::
::  failure-id: failure-9af037bd6441
::
++  test-runtime-no-initial-states-37bd6441
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/NoInitialStates.".
    "tla"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/NoInitialStates.".
    "cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'no-initial-states'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %evaluation-error
      [~ 2.118]
      [~ 'initial']
      ~
      ~
  ==
::
::  failure-id: failure-e3358bde0fe9
::
++  test-runtime-no-constraint-states-8bde0fe9
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/NoConstraintStat".
    "es.tla"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/NoConstraintStat".
    "es.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'no-constraint-states'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %evaluation-error
      [~ 2.256]
      [~ 'constraint']
      ~
      ~
  ==
::
::  failure-id: failure-3a91e9c8a066
::
++  test-runtime-invariant-in-initial-state-e9c8a066
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/InvariantInitial".
    ".tla"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/InvariantInitial".
    ".cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invariant-in-initial-state'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %safety-failure
      [~ 2.107]
      [~ 'invariant']
      ~['Init']
      ~
  ==
::
::  failure-id: failure-824b46a38683
::
++  test-runtime-invariant-in-reachable-state-46a38683
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/InvariantReachab".
    "le.tla"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/InvariantReachab".
    "le.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invariant-in-reachable-state'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %safety-failure
      [~ 2.110]
      [~ 'invariant']
      ~['Init' 'Next']
      ~
  ==
::
::  failure-id: failure-bd2a4a5c9159
::
++  test-runtime-invariant-evaluation-4a5c9159
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/InvariantEvaluat".
    "ion.tla"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/InvariantEvaluat".
    "ion.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invariant-evaluation'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %evaluation-error
      [~ 2.111]
      [~ 'evaluation']
      ~
      ~
  ==
::
::  failure-id: failure-e648ad10790d
::
++  test-runtime-action-property-ad10790d
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/ActionProperty.t".
    "la"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/ActionProperty.c".
    "fg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'action-property'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %safety-failure
      [~ 2.112]
      [~ 'action']
      ~['Init' 'Next']
      ~
  ==
::
::  failure-id: failure-f0dbe51bcb5d
::
++  test-runtime-deadlock-e51bcb5d
  =/  root  (crip "tests/fixtures/failures/runtime/Deadlock.tla")
  =/  config  (crip "tests/fixtures/failures/runtime/Deadlock.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'deadlock'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %deadlock-failure
      [~ 2.114]
      [~ 'deadlock']
      ~['Init']
      ~
  ==
::
::  failure-id: failure-3d580bf9bde6
::
++  test-runtime-liveness-lasso-0bf9bde6
  =/  root  (crip "tests/fixtures/failures/runtime/Liveness.tla")
  =/  config  (crip "tests/fixtures/failures/runtime/Liveness.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'liveness-lasso'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %liveness-failure
      [~ 2.116]
      [~ 'temporal']
      ~['Init' 'Next']
      [~ 1]
  ==
::
::  failure-id: failure-fa83fbeb2c0a
::
++  test-runtime-liveness-with-symmetry-fbeb2c0a
  =/  root
    %-  crip
    "tests/fixtures/failures/runtime/LivenessSymmetry".
    ".tla"
  =/  config
    %-  crip
    "tests/fixtures/failures/runtime/LivenessSymmetry".
    ".cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'liveness-with-symmetry'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %config-error
      [~ 2.279]
      [~ 'symmetry']
      ~
      ~
  ==
::
::  failure-id: failure-55bcafe08989
::
++  test-runtime-expression-evaluation-afe08989
  =/  root  (crip "tests/fixtures/failures/runtime/Evaluation.tla")
  =/  config  (crip "tests/fixtures/failures/runtime/Evaluation.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'expression-evaluation'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %evaluation-error
      [~ 2.179]
      [~ 'division']
      ~
      ~
  ==
::
::  failure-id: failure-74a11f00810b
::
++  test-runtime-invalid-mode-1f00810b
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invalid-mode'
      %invalid-mode
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %parameter-error
      [~ 3.113]
      [~ 'mode']
      ~
      ~
  ==
::
::  failure-id: failure-e8273899acba
::
++  test-runtime-invalid-flag-3899acba
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~['--not-a-real-flag']
    ==
  %-  expect-failure-case
  :*  'invalid-flag'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %parameter-error
      [~ 3.113]
      [~ 'flag']
      ~
      ~
  ==
::
::  failure-id: failure-22317bc905c1
::
++  test-runtime-invalid-worker-7bc905c1
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  0
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invalid-worker'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %parameter-error
      [~ 3.105]
      [~ 'worker']
      ~
      ~
  ==
::
::  failure-id: failure-294b90e7d1a5
::
++  test-runtime-invalid-depth-90e7d1a5
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invalid-depth'
      %invalid-depth
      root
      [~ config]
      %tlc
      [%simulate 1]
      options
      %parameter-error
      [~ 3.107]
      [~ 'depth']
      ~
      ~
  ==
::
::  failure-id: failure-d84f2ac3beb3
::
++  test-runtime-invalid-seed-2ac3beb3
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invalid-seed'
      %invalid-seed
      root
      [~ config]
      %tlc
      [%simulate 1]
      options
      %parameter-error
      [~ 1.102]
      [~ 'seed']
      ~
      ~
  ==
::
::  failure-id: failure-2e6fd75751fc
::
++  test-runtime-invalid-timeout-d75751fc
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        0
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invalid-timeout'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %parameter-error
      ~
      [~ 'timeout']
      ~
      ~
  ==
::
::  failure-id: failure-01522bb2291b
::
++  test-runtime-invalid-path-2bb2291b
  =/  root  (crip "tests/fixtures/failures/../../etc/passwd")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'invalid-path'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      ~
      [~ 'path']
      ~
      ~
  ==
::
::  failure-id: failure-7d519acb5612
::
++  test-runtime-cancellation-9acb5612
  =/  root  (crip "tests/fixtures/failures/runtime/Unbounded.tla")
  =/  config  (crip "tests/fixtures/failures/runtime/Unbounded.cfg")
  =/  options
    :*  %auto
        30
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'cancellation'
      %cancel
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %cancelled
      ~
      [~ 'cancel']
      ~
      ~
  ==
::
::  failure-id: failure-bc9e14ed81df
::
++  test-runtime-timeout-14ed81df
  =/  root  (crip "tests/fixtures/failures/runtime/Unbounded.tla")
  =/  config  (crip "tests/fixtures/failures/runtime/Unbounded.cfg")
  =/  options
    :*  %auto
        1
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'timeout'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %timeout
      ~
      [~ 'timeout']
      ~
      ~
  ==
::
::  failure-id: failure-d528187d0b09
::
++  test-runtime-resource-limit-187d0b09
  =/  root  (crip "tests/fixtures/failures/runtime/Unbounded.tla")
  =/  config  (crip "tests/fixtures/failures/runtime/Unbounded.cfg")
  =/  options
    :*  %auto
        60
        ~
        [~ 10]
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'resource-limit'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %resource-limit
      ~
      [~ 'state limit']
      ~
      ~
  ==
::
::  failure-id: failure-4054c0d27668
::
++  test-runtime-worker-process-failure-c0d27668
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~['--test-worker-command=/definitely/missing']
    ==
  %-  expect-failure-case
  :*  'worker-process-failure'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %process-failure
      ~
      [~ 'worker']
      ~
      ~
  ==
::
::  failure-id: failure-f5ba87665f6f
::
++  test-runtime-oversized-input-87665f6f
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/valid/Valid.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        [~ 1]
        ~
    ==
  %-  expect-failure-case
  :*  'oversized-input'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %resource-limit
      ~
      [~ 'input']
      ~
      ~
  ==
--
