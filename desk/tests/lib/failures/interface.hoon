/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  failure-id: failure-ad3598bd4d44
::
++  test-interface-malformed-mark-98bd4d44
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
  :*  'malformed-mark'
      %malformed-mark
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      ~
      [~ 'mark']
      ~
      ~
  ==
::
::  failure-id: failure-1fe30622d84b
::
++  test-interface-malformed-payload-0622d84b
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
  :*  'malformed-payload'
      %malformed-payload
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      ~
      [~ 'payload']
      ~
      ~
  ==
::
::  failure-id: failure-064d47a07074
::
++  test-interface-unauthorized-poke-47a07074
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
  :*  'unauthorized-poke'
      %unauthorized
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      ~
      [~ 'unauthorized']
      ~
      ~
  ==
::
::  failure-id: failure-3271288f0033
::
++  test-interface-unknown-scry-288f0033
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
  :*  'unknown-scry'
      %unknown-scry
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      [~ 5.999]
      [~ 'unknown scry']
      ~
      ~
  ==
::
::  failure-id: failure-641e381072bc
::
++  test-interface-duplicate-request-id-381072bc
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
  :*  'duplicate-request-id'
      %duplicate-request
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      ~
      [~ 'duplicate']
      ~
      ~
  ==
::
::  failure-id: failure-9de435bd1d29
::
++  test-interface-missing-request-id-35bd1d29
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
  :*  'missing-request-id'
      %missing-request-id
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      ~
      [~ 'request id']
      ~
      ~
  ==
::
::  failure-id: failure-5aeb3a80eb31
::
++  test-interface-query-before-submit-3a80eb31
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
  :*  'query-before-submit'
      %query-before-submit
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %interface-error
      [~ 5.999]
      [~ 'absent']
      ~
      ~
  ==
::
::  failure-id: failure-53f116cdd0a6
::
++  test-interface-query-after-completion-16cdd0a6
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
  :*  'query-after-completion'
      %query-after-completion
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %success
      ~
      ~
      ~
      ~
  ==
::
::  failure-id: failure-f01222eb3120
::
++  test-interface-deterministic-repeat-22eb3120
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
  :*  'deterministic-repeat'
      %repeat
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %success
      ~
      ~
      ~
      ~
  ==
::
::  failure-id: failure-0459ef356bf8
::
++  test-interface-concurrent-independent-ef356bf8
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
  :*  'concurrent-independent'
      %concurrent
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %success
      ~
      ~
      ~
      ~
  ==
::
::  failure-id: failure-8857d38818a1
::
++  test-interface-restart-persistence-d38818a1
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
  :*  'restart-persistence'
      %restart
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %success
      ~
      ~
      ~
      ~
  ==
::
::  failure-id: failure-f16b3298d30e
::
++  test-interface-rejected-run-isolation-3298d30e
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
  :*  'rejected-run-isolation'
      %rejected-run-isolation
      root
      [~ config]
      %tlc
      [%exhaustive ~]
      options
      %success
      ~
      ~
      ~
      ~
  ==
--
