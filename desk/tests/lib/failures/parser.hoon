/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  failure-id: failure-8e0e15639535
::
++  test-parser-lexical-error-15639535
  =/  root  (crip "tests/fixtures/failures/parser/Lexical.tla")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'lexical-error'
      %run
      root
      ~
      %sany
      [%parse ~]
      options
      %lexical-error
      [~ 4.000]
      [~ 'lexical']
      ~
      ~
  ==
::
::  failure-id: failure-78bb2e56f194
::
++  test-parser-parse-error-2e56f194
  =/  root  (crip "tests/fixtures/failures/parser/Parse.tla")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'parse-error'
      %run
      root
      ~
      %sany
      [%parse ~]
      options
      %parse-error
      [~ 4.001]
      [~ 'syntax']
      ~
      ~
  ==
::
::  failure-id: failure-89b717e15883
::
++  test-parser-semantic-error-17e15883
  =/  root  (crip "tests/fixtures/failures/parser/Semantic.tla")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'semantic-error'
      %run
      root
      ~
      %sany
      [%parse ~]
      options
      %semantic-error
      [~ 4.002]
      [~ 'semantic']
      ~
      ~
  ==
::
::  failure-id: failure-fa44f79bedd0
::
++  test-parser-level-error-f79bedd0
  =/  root  (crip "tests/fixtures/failures/parser/Level.tla")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'level-error'
      %run
      root
      ~
      %sany
      [%parse ~]
      options
      %level-error
      [~ 4.002]
      [~ 'level']
      ~
      ~
  ==
::
::  failure-id: failure-8cc73c15379f
::
++  test-parser-module-name-mismatch-3c15379f
  =/  root  (crip "tests/fixtures/failures/parser/WrongName.tla")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'module-name-mismatch'
      %run
      root
      ~
      %sany
      [%parse ~]
      options
      %parse-error
      [~ 4.001]
      [~ 'module name']
      ~
      ~
  ==
::
::  failure-id: failure-79ccca0e951a
::
++  test-parser-missing-dependency-ca0e951a
  =/  root
    %-  crip
    "tests/fixtures/failures/parser/MissingDependency".
    ".tla"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'missing-dependency'
      %run
      root
      ~
      %sany
      [%parse ~]
      options
      %semantic-error
      [~ 4.002]
      [~ 'dependency']
      ~
      ~
  ==
::
::  failure-id: failure-ded0df690a23
::
++  test-parser-malformed-dependency-df690a23
  =/  root
    %-  crip
    "tests/fixtures/failures/parser/MalformedDependen".
    "cy.tla"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-failure-case
  :*  'malformed-dependency'
      %run
      root
      ~
      %sany
      [%parse ~]
      options
      %parse-error
      [~ 4.001]
      [~ 'Broken']
      ~
      ~
  ==
--
