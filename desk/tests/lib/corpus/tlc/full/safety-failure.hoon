/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: model-3e812d282cb5
::
++  test-tlc-ewd687a-anim-2d282cb5
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/EWD687a_anim.tla")
  =/  model  (crip "specifications/ewd687a/EWD687a_anim.cfg")
  =/  options
    :*  %auto
        60
        [~ 1]
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3e812d282cb5'
      manifest
      module
      model
      %tlc
      [%simulate 100]
      %safety-failure
      '00:00:01'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-ce855d0f7961
::
++  test-tlc-ewd840-anim-5d0f7961
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/EWD840_anim.tla")
  =/  model  (crip "specifications/ewd840/EWD840_anim.cfg")
  =/  options
    :*  %auto
        60
        [~ 1]
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-ce855d0f7961'
      manifest
      module
      model
      %tlc
      [%simulate 100]
      %safety-failure
      '00:00:01'
      %.n
      ~
      options
  ==
--
