/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: model-a060d65a4699
::
++  test-apalache-einstein-d65a4699
  =/  manifest  (crip "specifications/EinsteinRiddle/manifest.json")
  =/  module  (crip "specifications/EinsteinRiddle/Einstein.tla")
  =/  model  (crip "specifications/EinsteinRiddle/Einstein.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-a060d65a4699'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
--
