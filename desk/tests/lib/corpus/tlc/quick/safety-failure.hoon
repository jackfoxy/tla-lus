/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: model-0356ae57544e
::
++  test-tlc-missionariesandcannibals-ae57544e
  =/  manifest
    %-  crip
    "specifications/MissionariesAndCannibals/manifest".
    ".json"
  =/  module
    %-  crip
    "specifications/MissionariesAndCannibals/Missiona".
    "riesAndCannibals.tla"
  =/  model
    %-  crip
    "specifications/MissionariesAndCannibals/Missiona".
    "riesAndCannibals.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-0356ae57544e'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-1f609b8250f7
::
++  test-tlc-slidingpuzzles-anim-9b8250f7
  =/  manifest  (crip "specifications/SlidingPuzzles/manifest.json")
  =/  module
    %-  crip
    "specifications/SlidingPuzzles/SlidingPuzzles_ani".
    "m.tla"
  =/  model
    %-  crip
    "specifications/SlidingPuzzles/SlidingPuzzles_ani".
    "m.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-1f609b8250f7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:10'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-30888be77284
::
++  test-tlc-mc-8be77284
  =/  manifest  (crip "specifications/SDP_Verification/manifest.json")
  =/  module
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_Spec/".
    "MC.tla"
  =/  model
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_Spec/".
    "MC.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-30888be77284'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:05'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-36399d537196
::
++  test-tlc-acp-nb-wrong-tlc-9d537196
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_NB_WRONG_TLC.tla")
  =/  model  (crip "specifications/acp/ACP_NB_WRONG_TLC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-36399d537196'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-3ca335ae5049
::
++  test-tlc-mc-35ae5049
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module
    %-  crip
    "specifications/N-Queens/Queens.toolbox/FourQueen".
    "s/MC.tla"
  =/  model
    %-  crip
    "specifications/N-Queens/Queens.toolbox/FourQueen".
    "s/MC.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3ca335ae5049'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-4b261ac60f11
::
++  test-tlc-mcdieharder-1ac60f11
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/MCDieHarder.tla")
  =/  model  (crip "specifications/DieHard/MCDieHarder.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4b261ac60f11'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-4e88937e6c6e
::
++  test-tlc-mccheckpointcoordinationfailure-937e6c6e
  =/  manifest
    %-  crip
    "specifications/CheckpointCoordination/manifest.j".
    "son"
  =/  module
    %-  crip
    "specifications/CheckpointCoordination/MCCheckpoi".
    "ntCoordination.tla"
  =/  model
    %-  crip
    "specifications/CheckpointCoordination/MCCheckpoi".
    "ntCoordinationFailure.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4e88937e6c6e'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:10'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-73505a0003b9
::
++  test-tlc-diehard-5a0003b9
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/DieHard.tla")
  =/  model  (crip "specifications/DieHard/DieHard.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-73505a0003b9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-76c3816cc676
::
++  test-tlc-mc-816cc676
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module
    %-  crip
    "specifications/tower_of_hanoi/Hanoi.toolbox/Mode".
    "l_1/MC.tla"
  =/  model
    %-  crip
    "specifications/tower_of_hanoi/Hanoi.toolbox/Mode".
    "l_1/MC.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-76c3816cc676'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-873f218f2ca6
::
++  test-tlc-hanoi-anim-218f2ca6
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module  (crip "specifications/tower_of_hanoi/Hanoi_anim.tla")
  =/  model  (crip "specifications/tower_of_hanoi/Hanoi_anim.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-873f218f2ca6'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-8800a2cd3bdb
::
++  test-tlc-slidingpuzzles-a2cd3bdb
  =/  manifest  (crip "specifications/SlidingPuzzles/manifest.json")
  =/  module  (crip "specifications/SlidingPuzzles/SlidingPuzzles.tla")
  =/  model  (crip "specifications/SlidingPuzzles/SlidingPuzzles.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-8800a2cd3bdb'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:05'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-b009bef6a21c
::
++  test-tlc-mcdiehardest-bef6a21c
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/MCDieHardest.tla")
  =/  model  (crip "specifications/DieHard/MCDieHardest.cfg")
  =/  options
    :*  1
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-b009bef6a21c'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-c1c79df460d7
::
++  test-tlc-mc-spanning-9df460d7
  =/  manifest  (crip "specifications/spanning/manifest.json")
  =/  module  (crip "specifications/spanning/MC_spanning.tla")
  =/  model  (crip "specifications/spanning/MC_spanning.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c1c79df460d7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-cd9ac70144ff
::
++  test-tlc-mc-c70144ff
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module
    %-  crip
    "specifications/N-Queens/QueensPluscal.toolbox/Fo".
    "urQueens/MC.tla"
  =/  model
    %-  crip
    "specifications/N-Queens/QueensPluscal.toolbox/Fo".
    "urQueens/MC.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-cd9ac70144ff'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %safety-failure
      '00:00:01'
      %.y
      ~
      options
  ==
--
