/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: model-cba774e6029a
::
++  test-tlc-mcdistributedreplicatedlog-74e6029a
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/MCDistributedRepl".
    "icatedLog.tla"
  =/  model
    %-  crip
    "specifications/FiniteMonotonic/MCDistributedRepl".
    "icatedLog.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-cba774e6029a'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %liveness-failure
      '00:00:05'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-cc0378b79dbc
::
++  test-tlc-mcrealtimehourclock-78b79dbc
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/MCReal".
    "TimeHourClock.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/RealTime/MCReal".
    "TimeHourClock.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-cc0378b79dbc'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %liveness-failure
      '00:00:01'
      %.y
      ~
      options
  ==
--
