/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: model-0460e4666ca9
::
++  test-tlc-coffeecan3000beans-e4666ca9
  =/  manifest  (crip "specifications/CoffeeCan/manifest.json")
  =/  module  (crip "specifications/CoffeeCan/CoffeeCan.tla")
  =/  model  (crip "specifications/CoffeeCan/CoffeeCan3000Beans.cfg")
  =/  options
    :*  %auto
        450
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-0460e4666ca9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:02:30'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-0bd527d1f0a9
::
++  test-tlc-elevatorlivenesslarge-27d1f0a9
  =/  manifest  (crip "specifications/MultiCarElevator/manifest.json")
  =/  module  (crip "specifications/MultiCarElevator/Elevator.tla")
  =/  model
    %-  crip
    "specifications/MultiCarElevator/ElevatorLiveness".
    "Large.cfg"
  =/  options
    :*  %auto
        1.980
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-0bd527d1f0a9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:11:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-194c8e3f4fcc
::
++  test-tlc-mcnanolarge-8e3f4fcc
  =/  manifest  (crip "specifications/NanoBlockchain/manifest.json")
  =/  module  (crip "specifications/NanoBlockchain/MCNano.tla")
  =/  model  (crip "specifications/NanoBlockchain/MCNanoLarge.cfg")
  =/  options
    :*  %auto
        3.600
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-194c8e3f4fcc'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:20:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-2568eb3e93b2
::
++  test-tlc-mc-eb3e93b2
  =/  manifest  (crip "specifications/dijkstra-mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/LSpec-model/MC.tla"
  =/  model
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/LSpec-model/MC.cfg"
  =/  options
    :*  %auto
        150
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-2568eb3e93b2'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:50'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-272666b0926c
::
++  test-tlc-environmentcontroller-66b0926c
  =/  manifest  (crip "specifications/detector_chan96/manifest.json")
  =/  module
    %-  crip
    "specifications/detector_chan96/EnvironmentContro".
    "ller.tla"
  =/  model
    %-  crip
    "specifications/detector_chan96/EnvironmentContro".
    "ller.cfg"
  =/  options
    :*  %auto
        21.600
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-272666b0926c'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '02:00:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-34c31b2f6293
::
++  test-tlc-mckvssafetysmall-1b2f6293
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/MCKVS.tla")
  =/  model
    %-  crip
    "specifications/KeyValueStore/MCKVSSafetySmall.cf".
    "g"
  =/  options
    :*  %auto
        120
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-34c31b2f6293'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:40'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-387d78ba4bbc
::
++  test-tlc-mcewd687a-78ba4bbc
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/MCEWD687a.tla")
  =/  model  (crip "specifications/ewd687a/MCEWD687a.cfg")
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-387d78ba4bbc'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-3a92b55b2fcb
::
++  test-tlc-mckvsnap-b55b2fcb
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/MCKVsnap.tla")
  =/  model  (crip "specifications/KeyValueStore/MCKVsnap.cfg")
  =/  options
    :*  %auto
        150
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3a92b55b2fcb'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:50'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-3c88724765f7
::
++  test-tlc-bcastfolklore-724765f7
  =/  manifest  (crip "specifications/bcastFolklore/manifest.json")
  =/  module  (crip "specifications/bcastFolklore/bcastFolklore.tla")
  =/  model  (crip "specifications/bcastFolklore/bcastFolklore.cfg")
  =/  options
    :*  %auto
        5.400
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3c88724765f7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:30:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-45c700758fe7
::
++  test-tlc-ewd998chan-00758fe7
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998Chan.tla")
  =/  model  (crip "specifications/ewd998/EWD998Chan.cfg")
  =/  options
    :*  %auto
        900
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-45c700758fe7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:05:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-4b851211e8ec
::
++  test-tlc-ewd998-1211e8ec
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998.tla")
  =/  model  (crip "specifications/ewd998/EWD998.cfg")
  =/  options
    :*  %auto
        9.000
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4b851211e8ec'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:50:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-4dff38e59328
::
++  test-tlc-slushlarge-38e59328
  =/  manifest  (crip "specifications/SlushProtocol/manifest.json")
  =/  module  (crip "specifications/SlushProtocol/Slush.tla")
  =/  model  (crip "specifications/SlushProtocol/SlushLarge.cfg")
  =/  options
    :*  %auto
        9.000
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4dff38e59328'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:50:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-53d02b6e62e1
::
++  test-tlc-huang-2b6e62e1
  =/  manifest  (crip "specifications/Huang/manifest.json")
  =/  module  (crip "specifications/Huang/Huang.tla")
  =/  model  (crip "specifications/Huang/Huang.cfg")
  =/  options
    :*  %auto
        120
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-53d02b6e62e1'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:40'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-5abee17044e6
::
++  test-tlc-mckvssafetylarge-e17044e6
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/MCKVS.tla")
  =/  model
    %-  crip
    "specifications/KeyValueStore/MCKVSSafetyLarge.cf".
    "g"
  =/  options
    :*  %auto
        78.480
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-5abee17044e6'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '07:16:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-6ffde417df78
::
++  test-tlc-mccheckpointcoordination-e417df78
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
    "ntCoordination.cfg"
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-6ffde417df78'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-77b6d6184621
::
++  test-tlc-mcboulanger-d6184621
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module
    %-  crip
    "specifications/Bakery-Boulangerie/MCBoulanger.tl".
    "a"
  =/  model
    %-  crip
    "specifications/Bakery-Boulangerie/MCBoulanger.cf".
    "g"
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-77b6d6184621'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-855b92119d65
::
++  test-tlc-paxoscommit-92119d65
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module
    %-  crip
    "specifications/transaction_commit/PaxosCommit.tl".
    "a"
  =/  model
    %-  crip
    "specifications/transaction_commit/PaxosCommit.cf".
    "g"
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-855b92119d65'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      [~ [~ 1.321.761] [~ 16.959.159] ~]
      options
  ==
::
::  coverage-id: model-8b8f29093aae
::
++  test-tlc-mckvssafetymedium-29093aae
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/MCKVS.tla")
  =/  model
    %-  crip
    "specifications/KeyValueStore/MCKVSSafetyMedium.c".
    "fg"
  =/  options
    :*  %auto
        810
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-8b8f29093aae'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:04:30'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-8f77f31129f6
::
++  test-tlc-elevatorsafetylarge-f31129f6
  =/  manifest  (crip "specifications/MultiCarElevator/manifest.json")
  =/  module  (crip "specifications/MultiCarElevator/Elevator.tla")
  =/  model
    %-  crip
    "specifications/MultiCarElevator/ElevatorSafetyLa".
    "rge.cfg"
  =/  options
    :*  %auto
        1.800
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-8f77f31129f6'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:10:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-970102b71e8b
::
++  test-tlc-slushmedium-02b71e8b
  =/  manifest  (crip "specifications/SlushProtocol/manifest.json")
  =/  module  (crip "specifications/SlushProtocol/Slush.tla")
  =/  model  (crip "specifications/SlushProtocol/SlushMedium.cfg")
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-970102b71e8b'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-9a20797ec41a
::
++  test-tlc-multipaxos-mc-797ec41a
  =/  manifest  (crip "specifications/MultiPaxos-SMR/manifest.json")
  =/  module  (crip "specifications/MultiPaxos-SMR/MultiPaxos_MC.tla")
  =/  model  (crip "specifications/MultiPaxos-SMR/MultiPaxos_MC.cfg")
  =/  options
    :*  %auto
        1.419
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-9a20797ec41a'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:07:53'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-a32a31a8edb9
::
++  test-tlc-bosco-31a8edb9
  =/  manifest  (crip "specifications/bosco/manifest.json")
  =/  module  (crip "specifications/bosco/bosco.tla")
  =/  model  (crip "specifications/bosco/bosco.cfg")
  =/  options
    :*  %auto
        540
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-a32a31a8edb9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:03:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-a5b54b4bcaca
::
++  test-tlc-elevatorsafetymedium-4b4bcaca
  =/  manifest  (crip "specifications/MultiCarElevator/manifest.json")
  =/  module  (crip "specifications/MultiCarElevator/Elevator.tla")
  =/  model
    %-  crip
    "specifications/MultiCarElevator/ElevatorSafetyMe".
    "dium.cfg"
  =/  options
    :*  %auto
        540
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-a5b54b4bcaca'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:03:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-ad019869ff91
::
++  test-tlc-tlcsailfish2-9869ff91
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/TLCSailfish2.tla")
  =/  model  (crip "specifications/dag-consensus/TLCSailfish2.cfg")
  =/  options
    :*  %auto
        0
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-ad019869ff91'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      'unknown'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-afeabcaee2ca
::
++  test-tlc-cf1s-folklore-bcaee2ca
  =/  manifest  (crip "specifications/cf1s-folklore/manifest.json")
  =/  module  (crip "specifications/cf1s-folklore/cf1s_folklore.tla")
  =/  model  (crip "specifications/cf1s-folklore/cf1s_folklore.cfg")
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-afeabcaee2ca'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-b425a9a9a345
::
++  test-tlc-pconproof-a9a9a345
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/PConProof.tla")
  =/  model  (crip "specifications/byzpaxos/PConProof.cfg")
  =/  options
    :*  %auto
        1.080
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-b425a9a9a345'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:06:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-ba73fdbdac3d
::
++  test-tlc-smokeewd998-fdbdac3d
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/SmokeEWD998.tla")
  =/  model  (crip "specifications/ewd998/SmokeEWD998.cfg")
  =/  options
    :*  %auto
        60
        [~ 1]
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-ba73fdbdac3d'
      manifest
      module
      model
      %tlc
      [%simulate 100]
      %success
      '00:00:05'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-bf7590f3a358
::
++  test-tlc-aba-asyn-byz-90f3a358
  =/  manifest  (crip "specifications/aba-asyn-byz/manifest.json")
  =/  module  (crip "specifications/aba-asyn-byz/aba_asyn_byz.tla")
  =/  model  (crip "specifications/aba-asyn-byz/aba_asyn_byz.cfg")
  =/  options
    :*  %auto
        1.800
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-bf7590f3a358'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:10:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-c79793a65f02
::
++  test-tlc-mcpaxossmall-93a65f02
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCPaxos".
    ".tla"
  =/  model
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCPaxos".
    "Small.cfg"
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c79793a65f02'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-e0bdc2caaeee
::
++  test-tlc-mcinnerserial-c2caaeee
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/MCInnerSerial.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/MCInnerSerial.cfg"
  =/  options
    :*  %auto
        270
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e0bdc2caaeee'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:30'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-e1f2232b8185
::
++  test-tlc-mc-232b8185
  =/  manifest  (crip "specifications/dijkstra-mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/Safety-4-processors/MC.tla"
  =/  model
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/Safety-4-processors/MC.cfg"
  =/  options
    :*  %auto
        360
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e1f2232b8185'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:02:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-e3673c91a3e0
::
++  test-tlc-mcreachable-3c91a3e0
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/MCReachable.tla")
  =/  model  (crip "specifications/MisraReachability/MCReachable.cfg")
  =/  options
    :*  %auto
        270
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e3673c91a3e0'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:30'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-e8afe5708b80
::
++  test-tlc-ewd998small-e5708b80
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998.tla")
  =/  model  (crip "specifications/ewd998/EWD998Small.cfg")
  =/  options
    :*  %auto
        900
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e8afe5708b80'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:05:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-ee81fe8ce78e
::
++  test-tlc-mcleastcircularsubstringmedium-fe8ce78e
  =/  manifest
    %-  crip
    "specifications/LeastCircularSubstring/manifest.j".
    "son"
  =/  module
    %-  crip
    "specifications/LeastCircularSubstring/MCLeastCir".
    "cularSubstring.tla"
  =/  model
    %-  crip
    "specifications/LeastCircularSubstring/MCLeastCir".
    "cularSubstringMedium.cfg"
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-ee81fe8ce78e'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:01:00'
      %.n
      ~
      options
  ==
::
::  coverage-id: model-f25d444e12a9
::
++  test-tlc-testmcreachability-444e12a9
  =/  manifest  (crip "specifications/TLC/manifest.json")
  =/  module  (crip "specifications/TLC/TestMCReachability.tla")
  =/  model  (crip "specifications/TLC/TestMCReachability.cfg")
  =/  options
    :*  %auto
        0
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f25d444e12a9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      'unknown'
      %.n
      ~
      options
  ==
--
