/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  failure-id: failure-505b615e8fe4
::
++  test-config-missing-config-615e8fe4
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/config/Missing.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'missing-config'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %config-error
      [~ 5.001]
      [~ 'config']
      ~
      ~
  ==
::
::  failure-id: failure-c31ce24df770
::
++  test-config-malformed-config-e24df770
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/config/Malformed.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'malformed-config'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %config-error
      [~ 5.003]
      [~ 'identifier']
      ~
      ~
  ==
::
::  failure-id: failure-71020d2f5204
::
++  test-config-duplicate-config-0d2f5204
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/config/Duplicate.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'duplicate-config'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %config-error
      [~ 5.004]
      [~ 'twice']
      ~
      ~
  ==
::
::  failure-id: failure-376771037d74
::
++  test-config-unassigned-constant-71037d74
  =/  root  (crip "tests/fixtures/failures/config/Unassigned.tla")
  =/  config  (crip "tests/fixtures/failures/config/Unassigned.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'unassigned-constant'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %config-error
      [~ 5.002]
      [~ 'constant']
      ~
      ~
  ==
::
::  failure-id: failure-2d0ec837f9fb
::
++  test-config-unknown-constant-c837f9fb
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config
    %-  crip
    "tests/fixtures/failures/config/UnknownConstant.c".
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
  :*  'unknown-constant'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %config-error
      [~ 5.002]
      [~ 'constant']
      ~
      ~
  ==
::
::  failure-id: failure-6deb7d152083
::
++  test-config-wrong-level-invariant-7d152083
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config
    %-  crip
    "tests/fixtures/failures/config/WrongInvariant.cf".
    "g"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'wrong-level-invariant'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %level-error
      [~ 2.146]
      [~ 'invariant']
      ~
      ~
  ==
::
::  failure-id: failure-88ecd234bff3
::
++  test-config-wrong-level-property-d234bff3
  =/  root  (crip "tests/fixtures/failures/valid/Valid.tla")
  =/  config  (crip "tests/fixtures/failures/config/WrongProperty.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'wrong-level-property'
      %run
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %config-error
      [~ 5.002]
      [~ 'property']
      ~
      ~
  ==
--
