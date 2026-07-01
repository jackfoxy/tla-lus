/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: parse-0004fdbc2837
::
++  test-sany-tlcsailfish1-fdbc2837
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/TLCSailfish1.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0004fdbc2837'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-008ed0639806
::
++  test-sany-cf1s-folklore-d0639806
  =/  manifest  (crip "specifications/cf1s-folklore/manifest.json")
  =/  module  (crip "specifications/cf1s-folklore/cf1s_folklore.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-008ed0639806'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-00a155f5f231
::
++  test-sany-simple-proof-55f5f231
  =/  manifest  (crip "specifications/TeachingConcurrency/manifest.json")
  =/  module
    %-  crip
    "specifications/TeachingConcurrency/Simple_proof.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-00a155f5f231'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-00cc1cadc158
::
++  test-sany-slidingpuzzles-anim-1cadc158
  =/  manifest  (crip "specifications/SlidingPuzzles/manifest.json")
  =/  module
    %-  crip
    "specifications/SlidingPuzzles/SlidingPuzzles_ani".
    "m.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-00cc1cadc158'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-01459e10340b
::
++  test-sany-bcastfolklore-9e10340b
  =/  manifest  (crip "specifications/bcastFolklore/manifest.json")
  =/  module  (crip "specifications/bcastFolklore/bcastFolklore.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-01459e10340b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-01fad87651f6
::
++  test-sany-mclivewritethroughcache-d87651f6
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/MCLive".
    "WriteThroughCache.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-01fad87651f6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0269d3954610
::
++  test-sany-hourclock-d3954610
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/HourC".
    "lock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0269d3954610'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-02c1e2e1df44
::
++  test-sany-reachability-e2e1df44
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/Reachability.tl".
    "a"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-02c1e2e1df44'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-02f777503d32
::
++  test-sany-liveinternalmemory-77503d32
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/LiveIn".
    "ternalMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-02f777503d32'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0386c3eb757b
::
++  test-sany-apmajority-c3eb757b
  =/  manifest  (crip "specifications/Majority/manifest.json")
  =/  module  (crip "specifications/Majority/APMajority.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0386c3eb757b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0444d19369ff
::
++  test-sany-crdt-proof-d19369ff
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module  (crip "specifications/FiniteMonotonic/CRDT_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0444d19369ff'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-073563532ac3
::
++  test-sany-2pcwithbtm-63532ac3
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/2PCwithBTM.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-073563532ac3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0739379300ea
::
++  test-sany-writethroughcacheinstanced-379300ea
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/WriteT".
    "hroughCacheInstanced.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0739379300ea'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-086dbd42aad7
::
++  test-sany-asynchinterface-proof-bd42aad7
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/AsynchInterface_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-086dbd42aad7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0916a8681438
::
++  test-sany-realtimehourclock-a8681438
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/RealTi".
    "meHourClock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0916a8681438'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0985dd42c2d0
::
++  test-sany-memoryinterface-dd42c2d0
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/Memory".
    "Interface.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0985dd42c2d0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0a6de2cb7d81
::
++  test-sany-mc-hdisksynod-e2cb7d81
  =/  manifest  (crip "specifications/diskpaxos/manifest.json")
  =/  module  (crip "specifications/diskpaxos/MC_HDiskSynod.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0a6de2cb7d81'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0ad88427c564
::
++  test-sany-apasynchinterface-8427c564
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/APAsynchInterface.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0ad88427c564'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0b112751c947
::
++  test-sany-voucherlifecycle-2751c947
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherLifeCycle.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0b112751c947'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0b9c5cb3c321
::
++  test-sany-acp-sb-5cb3c321
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_SB.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0b9c5cb3c321'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0bb7b6d81447
::
++  test-sany-mcprisoners-b6d81447
  =/  manifest  (crip "specifications/Prisoners/manifest.json")
  =/  module  (crip "specifications/Prisoners/MCPrisoners.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0bb7b6d81447'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0c94264dee73
::
++  test-sany-mcmajority-264dee73
  =/  manifest  (crip "specifications/Majority/manifest.json")
  =/  module  (crip "specifications/Majority/MCMajority.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0c94264dee73'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0ca6fd78d048
::
++  test-sany-nano-fd78d048
  =/  manifest  (crip "specifications/NanoBlockchain/manifest.json")
  =/  module  (crip "specifications/NanoBlockchain/Nano.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0ca6fd78d048'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0d1ad7c46c5a
::
++  test-sany-apmissionariesandcannibals-d7c46c5a
  =/  manifest
    %-  crip
    "specifications/MissionariesAndCannibals/manifest".
    ".json"
  =/  module
    %-  crip
    "specifications/MissionariesAndCannibals/APMissio".
    "nariesAndCannibals.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0d1ad7c46c5a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0dfca86ecc69
::
++  test-sany-prisoner-a86ecc69
  =/  manifest
    %-  crip
    "specifications/Prisoners_Single_Switch/manifest.".
    "json"
  =/  module
    %-  crip
    "specifications/Prisoners_Single_Switch/Prisoner.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0dfca86ecc69'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0e4ced6d7cef
::
++  test-sany-knuthyao-ed6d7cef
  =/  manifest  (crip "specifications/KnuthYao/manifest.json")
  =/  module  (crip "specifications/KnuthYao/KnuthYao.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0e4ced6d7cef'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0ec9a50b3a39
::
++  test-sany-cbc-max-a50b3a39
  =/  manifest  (crip "specifications/cbc_max/manifest.json")
  =/  module  (crip "specifications/cbc_max/cbc_max.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0ec9a50b3a39'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-0f31d7d0abc6
::
++  test-sany-jointactionmemory-d7d0abc6
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Joint".
    "ActionMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-0f31d7d0abc6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-10002b7226a4
::
++  test-sany-environmentcontroller-2b7226a4
  =/  manifest  (crip "specifications/detector_chan96/manifest.json")
  =/  module
    %-  crip
    "specifications/detector_chan96/EnvironmentContro".
    "ller.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-10002b7226a4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1080ffc1674a
::
++  test-sany-aptcommit-ffc1674a
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/APTCommit.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1080ffc1674a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-10c8ae54d62d
::
++  test-sany-apspanning-ae54d62d
  =/  manifest  (crip "specifications/spanning/manifest.json")
  =/  module  (crip "specifications/spanning/APspanning.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-10c8ae54d62d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-128c11dd47a9
::
++  test-sany-paxos-11dd47a9
  =/  manifest  (crip "specifications/SimplifiedFastPaxos/manifest.json")
  =/  module  (crip "specifications/SimplifiedFastPaxos/Paxos.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-128c11dd47a9'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-12a3213f0d72
::
++  test-sany-blockdag-213f0d72
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/BlockDag.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-12a3213f0d72'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-13d792e3ef73
::
++  test-sany-internalmemory-proof-92e3ef73
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/Intern".
    "alMemory_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-13d792e3ef73'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-14f85fb75b26
::
++  test-sany-ewd998chantrace-5fb75b26
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998ChanTrace.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-14f85fb75b26'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-15459bd2d2a7
::
++  test-sany-spanning-proof-9bd2d2a7
  =/  manifest  (crip "specifications/spanning/manifest.json")
  =/  module  (crip "specifications/spanning/spanning_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-15459bd2d2a7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-16e01ab6b6f4
::
++  test-sany-aphourclock-1ab6b6f4
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/APHou".
    "rClock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-16e01ab6b6f4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-16fb7a6786a5
::
++  test-sany-blockdagtest-7a6786a5
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/BlockDagTest.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-16fb7a6786a5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-18930a1ee580
::
++  test-sany-rtmemory-0a1ee580
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/RTMemo".
    "ry.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-18930a1ee580'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1994b95285a3
::
++  test-sany-consensus-b95285a3
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/Consensus.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1994b95285a3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-19eda07ab045
::
++  test-sany-cigarettesmokers-proof-a07ab045
  =/  manifest  (crip "specifications/CigaretteSmokers/manifest.json")
  =/  module
    %-  crip
    "specifications/CigaretteSmokers/CigaretteSmokers".
    "_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-19eda07ab045'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-19f00db72c04
::
++  test-sany-twophase-0db72c04
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/TwoPhase.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-19f00db72c04'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1a5ab510bb1d
::
++  test-sany-voting-b510bb1d
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/Voting.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1a5ab510bb1d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1b33dd088d13
::
++  test-sany-mcdistributedreplicatedlog-dd088d13
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/MCDistributedRepl".
    "icatedLog.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1b33dd088d13'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1ba53ad5251c
::
++  test-sany-btree-3ad5251c
  =/  manifest  (crip "specifications/btree/manifest.json")
  =/  module  (crip "specifications/btree/btree.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1ba53ad5251c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1c7deee47df8
::
++  test-sany-dieharder-eee47df8
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/DieHarder.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1c7deee47df8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1c94425b5bf2
::
++  test-sany-livewritethroughcache-425b5bf2
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/LiveWr".
    "iteThroughCache.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1c94425b5bf2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1ca01dd224a7
::
++  test-sany-spa-attack-new-1dd224a7
  =/  manifest  (crip "specifications/SDP_Verification/manifest.json")
  =/  module
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_New_S".
    "olution_Spec/SPA_Attack_New.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1ca01dd224a7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1ef523854eb3
::
++  test-sany-schedulingallocator-23854eb3
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module  (crip "specifications/allocator/SchedulingAllocator.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1ef523854eb3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1f0cea1eb948
::
++  test-sany-bpconproof-ea1eb948
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/BPConProof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1f0cea1eb948'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-1f5747188eb4
::
++  test-sany-mcfindhighest-47188eb4
  =/  manifest  (crip "specifications/LearnProofs/manifest.json")
  =/  module  (crip "specifications/LearnProofs/MCFindHighest.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-1f5747188eb4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-204c14580f91
::
++  test-sany-channel-14580f91
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/Channel.tl".
    "a"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-204c14580f91'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2060a260b292
::
++  test-sany-ewd998pcal-proof-a260b292
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998PCal_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2060a260b292'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-20e7ec25440e
::
++  test-sany-coffeecan-proof-ec25440e
  =/  manifest  (crip "specifications/CoffeeCan/manifest.json")
  =/  module  (crip "specifications/CoffeeCan/CoffeeCan_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-20e7ec25440e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-21db523bc780
::
++  test-sany-schedulingallocator-proof-523bc780
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module
    %-  crip
    "specifications/allocator/SchedulingAllocator_pro".
    "of.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-21db523bc780'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-22b788abba5f
::
++  test-sany-mc-88abba5f
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module
    %-  crip
    "specifications/N-Queens/QueensPluscal.toolbox/Fo".
    "urQueens/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-22b788abba5f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-23287aafd2f1
::
++  test-sany-levelspec-7aafd2f1
  =/  manifest  (crip "specifications/LevelChecking/manifest.json")
  =/  module  (crip "specifications/LevelChecking/LevelSpec.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-23287aafd2f1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-233aabf246c1
::
++  test-sany-elevator-abf246c1
  =/  manifest  (crip "specifications/MultiCarElevator/manifest.json")
  =/  module  (crip "specifications/MultiCarElevator/Elevator.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-233aabf246c1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2533c82e76b4
::
++  test-sany-ewd998chan-opts-c82e76b4
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998Chan_opts.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2533c82e76b4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-26066f6ca112
::
++  test-sany-apspantree-6f6ca112
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/APSpanTree.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-26066f6ca112'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-26f4d9e1eb3c
::
++  test-sany-apreaderswriters-d9e1eb3c
  =/  manifest  (crip "specifications/ReadersWriters/manifest.json")
  =/  module
    %-  crip
    "specifications/ReadersWriters/APReadersWriters.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-26f4d9e1eb3c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2702b34b9ec8
::
++  test-sany-mcreachabilitytest-b34b9ec8
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/MCReachabilityT".
    "est.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2702b34b9ec8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2af68166a894
::
++  test-sany-channel-8166a894
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Chann".
    "el.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2af68166a894'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2bdc84ade71d
::
++  test-sany-yoyoallgraphs-84ade71d
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/YoYoAllGraphs.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2bdc84ade71d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2c2e7ecfd55d
::
++  test-sany-cartalkpuzzle-7ecfd55d
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_3/CarTalkPuzzle.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2c2e7ecfd55d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2c96e3ea0e81
::
++  test-sany-mcbinarysearch-e3ea0e81
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/MCBinarySearch.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2c96e3ea0e81'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2cee2c1a04ff
::
++  test-sany-testmcreachability-2c1a04ff
  =/  manifest  (crip "specifications/TLC/manifest.json")
  =/  module  (crip "specifications/TLC/TestMCReachability.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2cee2c1a04ff'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2daf97815dcf
::
++  test-sany-internalmemory-proof-97815dcf
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/Intern".
    "alMemory_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2daf97815dcf'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2e9811280173
::
++  test-sany-kvsnap-11280173
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/KVsnap.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2e9811280173'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2eb6821a5316
::
++  test-sany-mctwophase-821a5316
  =/  manifest  (crip "specifications/TwoPhase/manifest.json")
  =/  module  (crip "specifications/TwoPhase/MCTwoPhase.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2eb6821a5316'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2f3c9c8e0d1b
::
++  test-sany-transitiveclosure-9c8e0d1b
  =/  manifest  (crip "specifications/TransitiveClosure/manifest.json")
  =/  module
    %-  crip
    "specifications/TransitiveClosure/TransitiveClosu".
    "re.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2f3c9c8e0d1b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-2ff19baac961
::
++  test-sany-fastpaxos-9baac961
  =/  manifest  (crip "specifications/SimplifiedFastPaxos/manifest.json")
  =/  module  (crip "specifications/SimplifiedFastPaxos/FastPaxos.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-2ff19baac961'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-30a7b6fba741
::
++  test-sany-internalmemory-b6fba741
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/Intern".
    "alMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-30a7b6fba741'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-311c3da529ad
::
++  test-sany-apacp-sb-3da529ad
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/APACP_SB.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-311c3da529ad'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3142a90633d2
::
++  test-sany-consensus-a90633d2
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/Consensus.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3142a90633d2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3145c4f9bd56
::
++  test-sany-aba-asyn-byz-c4f9bd56
  =/  manifest  (crip "specifications/aba-asyn-byz/manifest.json")
  =/  module  (crip "specifications/aba-asyn-byz/aba_asyn_byz.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3145c4f9bd56'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3156b491ecf5
::
++  test-sany-mcinnerfifo-b491ecf5
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/MCInnerFIF".
    "O.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3156b491ecf5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-31c379f61b1f
::
++  test-sany-yoyonopruning-79f61b1f
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/YoYoNoPruning.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-31c379f61b1f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-32dbbf44d18b
::
++  test-sany-tokenring-bf44d18b
  =/  manifest  (crip "specifications/ewd426/manifest.json")
  =/  module  (crip "specifications/ewd426/TokenRing.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-32dbbf44d18b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-33892e0d41a0
::
++  test-sany-internalmemory-2e0d41a0
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Inter".
    "nalMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-33892e0d41a0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-340de4d14b37
::
++  test-sany-apdieharder-e4d14b37
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/APDieHarder.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-340de4d14b37'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3830aaf5cb85
::
++  test-sany-mc-aaf5cb85
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_1/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3830aaf5cb85'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-386f33d279ac
::
++  test-sany-apchannel-33d279ac
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APChannel.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-386f33d279ac'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3878abcaafcf
::
++  test-sany-queenspluscal-abcaafcf
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module
    %-  crip
    "specifications/N-Queens/QueensPluscal.toolbox/Fo".
    "urQueens/QueensPluscal.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3878abcaafcf'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-388fd798ffa0
::
++  test-sany-mcinternalmemory-d798ffa0
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/MCInte".
    "rnalMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-388fd798ffa0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3920f2396514
::
++  test-sany-mcparreach-f2396514
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/MCParReach.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3920f2396514'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3ab832db06e8
::
++  test-sany-lamportmutex-proofs-32db06e8
  =/  manifest  (crip "specifications/lamport_mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/lamport_mutex/LamportMutex_proofs".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3ab832db06e8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3ad67f52cda5
::
++  test-sany-mcyoyopruning-7f52cda5
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/MCYoYoPruning.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3ad67f52cda5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3afc9a3f64c0
::
++  test-sany-clean-proof-9a3f64c0
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/clean_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3afc9a3f64c0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3b99a44828d9
::
++  test-sany-apinnerfifoinstanced-a44828d9
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APInnerFIF".
    "OInstanced.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3b99a44828d9'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3c166244e733
::
++  test-sany-apmcinnerfifo-6244e733
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APMCInnerF".
    "IFO.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3c166244e733'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3cb5b68753f2
::
++  test-sany-mcbakery-b68753f2
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module  (crip "specifications/Bakery-Boulangerie/MCBakery.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3cb5b68753f2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3de3899ce53b
::
++  test-sany-mcliveinternalmemory-899ce53b
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/MCLive".
    "InternalMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3de3899ce53b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3df8bb336364
::
++  test-sany-innersequential-bb336364
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/InnerSequential.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3df8bb336364'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-3f38e16ad409
::
++  test-sany-cartalkpuzzle-e16ad409
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_2/CarTalkPuzzle.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-3f38e16ad409'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-408cd4e2b6b6
::
++  test-sany-apbarrier-d4e2b6b6
  =/  manifest  (crip "specifications/barriers/manifest.json")
  =/  module  (crip "specifications/barriers/APBarrier.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-408cd4e2b6b6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-409d44a7ed1a
::
++  test-sany-abcorrectness-44a7ed1a
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/ABCorrectne".
    "ss.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-409d44a7ed1a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4146b89e966f
::
++  test-sany-apsinglelanebridge-b89e966f
  =/  manifest  (crip "specifications/SingleLaneBridge/manifest.json")
  =/  module
    %-  crip
    "specifications/SingleLaneBridge/APSingleLaneBrid".
    "ge.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4146b89e966f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-434558759bc8
::
++  test-sany-asynchinterface-58759bc8
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/AsynchInterface.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-434558759bc8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-438525d3d571
::
++  test-sany-ewd840-proof-25d3d571
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/EWD840_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-438525d3d571'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-43baead62dae
::
++  test-sany-sailfish-ead62dae
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/Sailfish.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-43baead62dae'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-455df6c8e257
::
++  test-sany-mcwritethroughcache-f6c8e257
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "CWriteThroughCache.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-455df6c8e257'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-45a9e30a8e90
::
++  test-sany-mc-e30a8e90
  =/  manifest  (crip "specifications/dijkstra-mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/Safety-4-processors/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-45a9e30a8e90'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-45ab4288f8dc
::
++  test-sany-epfailuredetector-4288f8dc
  =/  manifest  (crip "specifications/detector_chan96/manifest.json")
  =/  module
    %-  crip
    "specifications/detector_chan96/EPFailureDetector".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-45ab4288f8dc'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-46ad836394fb
::
++  test-sany-mcleastcircularsubstring-836394fb
  =/  manifest
    %-  crip
    "specifications/LeastCircularSubstring/manifest.j".
    "son"
  =/  module
    %-  crip
    "specifications/LeastCircularSubstring/MCLeastCir".
    "cularSubstring.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-46ad836394fb'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-46c5b834c813
::
++  test-sany-apsyncterminationdetection-b834c813
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd840/APSyncTerminationDetection".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-46c5b834c813'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-47a354d67dbf
::
++  test-sany-disruptor-mpmc-54d67dbf
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/Disruptor_MPMC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-47a354d67dbf'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-494b197b0fb1
::
++  test-sany-apchangroberts-197b0fb1
  =/  manifest  (crip "specifications/chang_roberts/manifest.json")
  =/  module  (crip "specifications/chang_roberts/APChangRoberts.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-494b197b0fb1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4a14e4235c40
::
++  test-sany-ewd998chanid-shiviz-e4235c40
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998ChanID_shiviz.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4a14e4235c40'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4aafae05cebf
::
++  test-sany-tcommit-proof-ae05cebf
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module
    %-  crip
    "specifications/transaction_commit/TCommit_proof.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4aafae05cebf'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4bf85eba7f90
::
++  test-sany-apcrdt-5eba7f90
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module  (crip "specifications/FiniteMonotonic/APCRDT.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4bf85eba7f90'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4c65c914510c
::
++  test-sany-internalmemory-proof-c914510c
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/I".
    "nternalMemory_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4c65c914510c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4c8c2b6866ce
::
++  test-sany-apcat-2b6866ce
  =/  manifest  (crip "specifications/Moving_Cat_Puzzle/manifest.json")
  =/  module  (crip "specifications/Moving_Cat_Puzzle/APCat.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4c8c2b6866ce'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4d1bcb9f0f85
::
++  test-sany-ewd840-anim-cb9f0f85
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/EWD840_anim.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4d1bcb9f0f85'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4d5215a9edd3
::
++  test-sany-bnfgrammars-15a9edd3
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/BNFGrammars".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4d5215a9edd3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4e1ba05775a6
::
++  test-sany-reals-a05775a6
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/Reals.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4e1ba05775a6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4e6d2a99627b
::
++  test-sany-mc-2a99627b
  =/  manifest  (crip "specifications/SingleLaneBridge/manifest.json")
  =/  module  (crip "specifications/SingleLaneBridge/MC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4e6d2a99627b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4e943d715076
::
++  test-sany-mc-3d715076
  =/  manifest  (crip "specifications/SDP_Verification/manifest.json")
  =/  module
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_Spec/".
    "MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4e943d715076'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4f37f6e28f57
::
++  test-sany-nbacc-ray97-f6e28f57
  =/  manifest  (crip "specifications/nbacc_ray97/manifest.json")
  =/  module  (crip "specifications/nbacc_ray97/nbacc_ray97.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4f37f6e28f57'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-4fcd309bb571
::
++  test-sany-peterson-309bb571
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module  (crip "specifications/locks_auxiliary_vars/Peterson.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-4fcd309bb571'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5198976f0d09
::
++  test-sany-smokeewd998-976f0d09
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/SmokeEWD998.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5198976f0d09'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-52d3f9fd2306
::
++  test-sany-mcinternalmemory-f9fd2306
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "CInternalMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-52d3f9fd2306'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5314a885d123
::
++  test-sany-vouchertransfer-a885d123
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherTransfer.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5314a885d123'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-53fa05951521
::
++  test-sany-hanoiseq-05951521
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module  (crip "specifications/tower_of_hanoi/HanoiSeq.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-53fa05951521'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-54360ba53bb9
::
++  test-sany-printvalues-0ba53bb9
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/PrintValues.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-54360ba53bb9'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-54cc4142466f
::
++  test-sany-mcvoting-4142466f
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCVotin".
    "g.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-54cc4142466f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-553459d71566
::
++  test-sany-product-59d71566
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/product.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-553459d71566'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-55af816e7c8e
::
++  test-sany-ewd998-816e7c8e
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-55af816e7c8e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-56c19f426968
::
++  test-sany-livehourclock-9f426968
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/LiveHo".
    "urClock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-56c19f426968'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-56fd646f997f
::
++  test-sany-boulanger-646f997f
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module  (crip "specifications/Bakery-Boulangerie/Boulanger.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-56fd646f997f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-572d518dfcf2
::
++  test-sany-binaryhourclock-518dfcf2
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Binar".
    "yHourClock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-572d518dfcf2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-58b849a0f360
::
++  test-sany-simknuthyao-49a0f360
  =/  manifest  (crip "specifications/KnuthYao/manifest.json")
  =/  module  (crip "specifications/KnuthYao/SimKnuthYao.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-58b849a0f360'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-596317e898f8
::
++  test-sany-bits-17e898f8
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module  (crip "specifications/tower_of_hanoi/Bits.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-596317e898f8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5ce4001a6a47
::
++  test-sany-hourclock-proof-001a6a47
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/HourC".
    "lock_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5ce4001a6a47'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5d280d260530
::
++  test-sany-alternatingbit-proof-0d260530
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/Alternating".
    "Bit_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5d280d260530'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5dbe88b21683
::
++  test-sany-bcastbyz-88b21683
  =/  manifest  (crip "specifications/bcastByz/manifest.json")
  =/  module  (crip "specifications/bcastByz/bcastByz.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5dbe88b21683'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5deab1ab8f45
::
++  test-sany-apnbacg-guer01-b1ab8f45
  =/  manifest  (crip "specifications/nbacg_guer01/manifest.json")
  =/  module  (crip "specifications/nbacg_guer01/APnbacg_guer01.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5deab1ab8f45'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5e016b94de37
::
++  test-sany-memory-6b94de37
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/Memory".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5e016b94de37'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5e8c4e8539b7
::
++  test-sany-ewd998chan-4e8539b7
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998Chan.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5e8c4e8539b7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5fbe96fde28b
::
++  test-sany-folds-96fde28b
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/Folds.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5fbe96fde28b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5fde874da5aa
::
++  test-sany-tlaplusgrammar-874da5aa
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Syntax/TLAPlusG".
    "rammar.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5fde874da5aa'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-5fe1c7bd2547
::
++  test-sany-voucherlifecycle-proof-c7bd2547
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module
    %-  crip
    "specifications/byihive/VoucherLifeCycle_proof.tl".
    "a"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-5fe1c7bd2547'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6012f4068271
::
++  test-sany-memory-f4068271
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "emory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6012f4068271'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-603908b1045a
::
++  test-sany-apbosco-08b1045a
  =/  manifest  (crip "specifications/bosco/manifest.json")
  =/  module  (crip "specifications/bosco/APbosco.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-603908b1045a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-60a274785500
::
++  test-sany-hourclock-proof-74785500
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/HourCl".
    "ock_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-60a274785500'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-612ba56555fd
::
++  test-sany-testgraphs-a56555fd
  =/  manifest  (crip "specifications/TLC/manifest.json")
  =/  module  (crip "specifications/TLC/TestGraphs.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-612ba56555fd'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6133db6e1007
::
++  test-sany-channel-db6e1007
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/Channel.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6133db6e1007'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-617fe1ef862d
::
++  test-sany-ewd687apluscal-e1ef862d
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/EWD687aPlusCal.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-617fe1ef862d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6210383a1226
::
++  test-sany-apparreach-383a1226
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/APParReach.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6210383a1226'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-624a763d091f
::
++  test-sany-apprisoners-763d091f
  =/  manifest  (crip "specifications/Prisoners/manifest.json")
  =/  module  (crip "specifications/Prisoners/APPrisoners.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-624a763d091f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-63757c3605a8
::
++  test-sany-memory-7c3605a8
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/Memory".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-63757c3605a8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-63854411fdc0
::
++  test-sany-tcp-4411fdc0
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/tcp.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-63854411fdc0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-63cb96eac58b
::
++  test-sany-indinv-apa-96eac58b
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/IndInv_apa.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-63cb96eac58b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-64e65c495eb3
::
++  test-sany-queens-5c495eb3
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module  (crip "specifications/N-Queens/Queens.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-64e65c495eb3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-65495688c5a6
::
++  test-sany-digraph-5688c5a6
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/Digraph.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-65495688c5a6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-661361b2e075
::
++  test-sany-diehard-61b2e075
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/DieHard.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-661361b2e075'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6864580ad37b
::
++  test-sany-writethroughcache-580ad37b
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/W".
    "riteThroughCache.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6864580ad37b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-69303cb0c847
::
++  test-sany-channel-proof-3cb0c847
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Chann".
    "el_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-69303cb0c847'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-696b3ccba874
::
++  test-sany-innerfifo-3ccba874
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/InnerFIFO.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-696b3ccba874'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-69e72581137e
::
++  test-sany-simpleregular-2581137e
  =/  manifest  (crip "specifications/TeachingConcurrency/manifest.json")
  =/  module
    %-  crip
    "specifications/TeachingConcurrency/SimpleRegular".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-69e72581137e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6a031fcd6432
::
++  test-sany-sequences-1fcd6432
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/Sequen".
    "ces.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6a031fcd6432'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6a61ea0732e6
::
++  test-sany-kvstore-ea0732e6
  =/  manifest  (crip "specifications/btree/manifest.json")
  =/  module  (crip "specifications/btree/kvstore.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6a61ea0732e6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6a94b0483af8
::
++  test-sany-leastcircularsubstring-b0483af8
  =/  manifest
    %-  crip
    "specifications/LeastCircularSubstring/manifest.j".
    "son"
  =/  module
    %-  crip
    "specifications/LeastCircularSubstring/LeastCircu".
    "larSubstring.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6a94b0483af8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6b0c1f827d51
::
++  test-sany-nbacg-guer01-1f827d51
  =/  manifest  (crip "specifications/nbacg_guer01/manifest.json")
  =/  module  (crip "specifications/nbacg_guer01/nbacg_guer01.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6b0c1f827d51'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6c161bcb808e
::
++  test-sany-acp-nb-wrong-tlc-1bcb808e
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_NB_WRONG_TLC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6c161bcb808e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6c23a70d8d94
::
++  test-sany-allocatorrefinement-a70d8d94
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module  (crip "specifications/allocator/AllocatorRefinement.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6c23a70d8d94'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6eaeb6f0f9ea
::
++  test-sany-aplamportmutex-b6f0f9ea
  =/  manifest  (crip "specifications/lamport_mutex/manifest.json")
  =/  module  (crip "specifications/lamport_mutex/APLamportMutex.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6eaeb6f0f9ea'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6fbdba1b0586
::
++  test-sany-mc-ba1b0586
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_2/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6fbdba1b0586'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-6fdc007312ab
::
++  test-sany-asyncterminationdetection-proof-007312ab
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd998/AsyncTerminationDetection_".
    "proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-6fdc007312ab'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-70999bb9c696
::
++  test-sany-cartalkpuzzle-9bb9c696
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module  (crip "specifications/CarTalkPuzzle/CarTalkPuzzle.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-70999bb9c696'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-70a150a4bb95
::
++  test-sany-internalmemory-proof-50a4bb95
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Inter".
    "nalMemory_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-70a150a4bb95'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-70a346dc094a
::
++  test-sany-voucherissue-46dc094a
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherIssue.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-70a346dc094a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-70c8349bf815
::
++  test-sany-mccheckpointcoordination-349bf815
  =/  manifest
    %-  crip
    "specifications/CheckpointCoordination/manifest.j".
    "son"
  =/  module
    %-  crip
    "specifications/CheckpointCoordination/MCCheckpoi".
    "ntCoordination.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-70c8349bf815'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-711aa45720ef
::
++  test-sany-acp-nb-tlc-a45720ef
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_NB_TLC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-711aa45720ef'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-72016b70409a
::
++  test-sany-acp-nb-6b70409a
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_NB.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-72016b70409a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-737d1e63a849
::
++  test-sany-naturals-1e63a849
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/Natura".
    "ls.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-737d1e63a849'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-74679c84d204
::
++  test-sany-apkeyvaluestore-9c84d204
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/APKeyValueStore.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-74679c84d204'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-74833c3e9093
::
++  test-sany-cartalkpuzzle-3c3e9093
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_1/CarTalkPuzzle.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-74833c3e9093'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7486b0f20221
::
++  test-sany-aplivehourclock-b0f20221
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/APLive".
    "HourClock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7486b0f20221'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-74dbfc7a6ce7
::
++  test-sany-simpleallocator-fc7a6ce7
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module  (crip "specifications/allocator/SimpleAllocator.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-74dbfc7a6ce7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-75345d773a74
::
++  test-sany-distributedreplicatedlog-5d773a74
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/DistributedReplic".
    "atedLog.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-75345d773a74'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-769cb7fd7a5f
::
++  test-sany-diningphilosophers-b7fd7a5f
  =/  manifest  (crip "specifications/DiningPhilosophers/manifest.json")
  =/  module
    %-  crip
    "specifications/DiningPhilosophers/DiningPhilosop".
    "hers.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-769cb7fd7a5f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-771db08f5474
::
++  test-sany-alternatingbit-b08f5474
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/Alternating".
    "Bit.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-771db08f5474'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-783eab1a1b4c
::
++  test-sany-channel-proof-ab1a1b4c
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/Channel_pr".
    "oof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-783eab1a1b4c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-79ba42073757
::
++  test-sany-channelrefinement-42073757
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Chann".
    "elRefinement.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-79ba42073757'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7d7b07f5d581
::
++  test-sany-cigarettesmokers-07f5d581
  =/  manifest  (crip "specifications/CigaretteSmokers/manifest.json")
  =/  module
    %-  crip
    "specifications/CigaretteSmokers/CigaretteSmokers".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7d7b07f5d581'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7ddbdf5e04a1
::
++  test-sany-dijkstramutex-df5e04a1
  =/  manifest  (crip "specifications/dijkstra-mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/Safety-4-processors/DijkstraMutex.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7ddbdf5e04a1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7e339eaa3aed
::
++  test-sany-mcnano-9eaa3aed
  =/  manifest  (crip "specifications/NanoBlockchain/manifest.json")
  =/  module  (crip "specifications/NanoBlockchain/MCNano.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7e339eaa3aed'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7ee0dbe1e914
::
++  test-sany-gameoflife-dbe1e914
  =/  manifest  (crip "specifications/GameOfLife/manifest.json")
  =/  module  (crip "specifications/GameOfLife/GameOfLife.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7ee0dbe1e914'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7fb932a5e54a
::
++  test-sany-apinnerfifo-32a5e54a
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APInnerFIF".
    "O.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7fb932a5e54a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7fbd7a16a69f
::
++  test-sany-stategraphs-7a16a69f
  =/  manifest  (crip "specifications/TLC/manifest.json")
  =/  module  (crip "specifications/TLC/StateGraphs.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7fbd7a16a69f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7fc7ced769a3
::
++  test-sany-apadiehardest-ced769a3
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/APADieHardest.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7fc7ced769a3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-7fdf88e8efd0
::
++  test-sany-apclean-88e8efd0
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/APclean.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-7fdf88e8efd0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-80b55d91dffa
::
++  test-sany-mcdiehardest-5d91dffa
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/MCDieHardest.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-80b55d91dffa'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-818a6bf08e2b
::
++  test-sany-paxos-6bf08e2b
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/Paxos.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-818a6bf08e2b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-824e61784e96
::
++  test-sany-mckvs-61784e96
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/MCKVS.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-824e61784e96'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-82fc45c32c00
::
++  test-sany-elevator-proof-45c32c00
  =/  manifest  (crip "specifications/MultiCarElevator/manifest.json")
  =/  module
    %-  crip
    "specifications/MultiCarElevator/Elevator_proof.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-82fc45c32c00'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-83d9274feee2
::
++  test-sany-twophase-proof-274feee2
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module
    %-  crip
    "specifications/transaction_commit/TwoPhase_proof".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-83d9274feee2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-860f62690ae4
::
++  test-sany-spantreerandom-62690ae4
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/SpanTreeRandom.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-860f62690ae4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-870922ffdb59
::
++  test-sany-mc-22ffdb59
  =/  manifest  (crip "specifications/ReadersWriters/manifest.json")
  =/  module  (crip "specifications/ReadersWriters/MC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-870922ffdb59'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8732b3e99e34
::
++  test-sany-relation-b3e99e34
  =/  manifest  (crip "specifications/echo/manifest.json")
  =/  module  (crip "specifications/echo/Relation.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8732b3e99e34'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-87987a0a4a2e
::
++  test-sany-cat-7a0a4a2e
  =/  manifest  (crip "specifications/Moving_Cat_Puzzle/manifest.json")
  =/  module  (crip "specifications/Moving_Cat_Puzzle/Cat.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-87987a0a4a2e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-880aac0ce8b1
::
++  test-sany-multipaxos-ac0ce8b1
  =/  manifest  (crip "specifications/MultiPaxos-SMR/manifest.json")
  =/  module  (crip "specifications/MultiPaxos-SMR/MultiPaxos.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-880aac0ce8b1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-88461eb61c63
::
++  test-sany-internalmemory-1eb61c63
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/Intern".
    "alMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-88461eb61c63'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8867e841b680
::
++  test-sany-aphourclock-e841b680
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/APHour".
    "Clock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8867e841b680'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-88ac5539d5a3
::
++  test-sany-aptokenring-5539d5a3
  =/  manifest  (crip "specifications/ewd426/manifest.json")
  =/  module  (crip "specifications/ewd426/APTokenRing.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-88ac5539d5a3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-88d4f7763503
::
++  test-sany-diehardest-f7763503
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/DieHardest.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-88d4f7763503'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-88dd06f4ba22
::
++  test-sany-spantree-proof-06f4ba22
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/SpanTree_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-88dd06f4ba22'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8945ec8d2b32
::
++  test-sany-binarysearch-ec8d2b32
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/BinarySearch.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8945ec8d2b32'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-897b337f4702
::
++  test-sany-hourclock-337f4702
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/HourCl".
    "ock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-897b337f4702'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8a725dcb6fa4
::
++  test-sany-pconproof-5dcb6fa4
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/PConProof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8a725dcb6fa4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8a7ad011a3fc
::
++  test-sany-apchannel-d011a3fc
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/APCha".
    "nnel.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8a7ad011a3fc'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8a9ffb389426
::
++  test-sany-memoryinterface-fb389426
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Memor".
    "yInterface.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8a9ffb389426'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8ad9dde1bf2b
::
++  test-sany-apdiningphilosophers-dde1bf2b
  =/  manifest  (crip "specifications/DiningPhilosophers/manifest.json")
  =/  module
    %-  crip
    "specifications/DiningPhilosophers/APDiningPhilos".
    "ophers.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8ad9dde1bf2b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-8c39baea23b7
::
++  test-sany-apdisruptor-spmc-baea23b7
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/APDisruptor_SPMC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-8c39baea23b7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-901c2e9572c8
::
++  test-sany-ringbuffer-2e9572c8
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/RingBuffer.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-901c2e9572c8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-915fd61272e7
::
++  test-sany-memoryinterface-d61272e7
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "emoryInterface.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-915fd61272e7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-91c4134a5af9
::
++  test-sany-bnfgrammars-134a5af9
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/BNFGrammars.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-91c4134a5af9'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-921c0ab348d4
::
++  test-sany-functions-0ab348d4
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/Functions.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-921c0ab348d4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-930b225354bb
::
++  test-sany-dijkstramutex-225354bb
  =/  manifest  (crip "specifications/dijkstra-mutex/manifest.json")
  =/  module  (crip "specifications/dijkstra-mutex/DijkstraMutex.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-930b225354bb'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-932f4295ba00
::
++  test-sany-hanoi-4295ba00
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module
    %-  crip
    "specifications/tower_of_hanoi/Hanoi.toolbox/Mode".
    "l_1/Hanoi.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-932f4295ba00'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9347b2ec6cfa
::
++  test-sany-stuttering-b2ec6cfa
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module
    %-  crip
    "specifications/locks_auxiliary_vars/Stuttering.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9347b2ec6cfa'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-942563acb667
::
++  test-sany-mcecho-63acb667
  =/  manifest  (crip "specifications/echo/manifest.json")
  =/  module  (crip "specifications/echo/MCEcho.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-942563acb667'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-94fcc52c0a4e
::
++  test-sany-alternate-c52c0a4e
  =/  manifest  (crip "specifications/TwoPhase/manifest.json")
  =/  module  (crip "specifications/TwoPhase/Alternate.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-94fcc52c0a4e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-95bff9fe38d2
::
++  test-sany-changroberts-f9fe38d2
  =/  manifest  (crip "specifications/chang_roberts/manifest.json")
  =/  module  (crip "specifications/chang_roberts/ChangRoberts.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-95bff9fe38d2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-96836aa20b12
::
++  test-sany-mcrealtimehourclock-6aa20b12
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/MCReal".
    "TimeHourClock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-96836aa20b12'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-96d5a1adc948
::
++  test-sany-configfilegrammar-a1adc948
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/ConfigFileG".
    "rammar.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-96d5a1adc948'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-97e05dc0efc7
::
++  test-sany-mcchangroberts-5dc0efc7
  =/  manifest  (crip "specifications/chang_roberts/manifest.json")
  =/  module  (crip "specifications/chang_roberts/MCChangRoberts.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-97e05dc0efc7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9874f30cb6e3
::
++  test-sany-compositefifo-f30cb6e3
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/Compo".
    "siteFIFO.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9874f30cb6e3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-98b93374a3e2
::
++  test-sany-syncterminationdetection-3374a3e2
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd840/SyncTerminationDetection.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-98b93374a3e2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-991e979b00e4
::
++  test-sany-voting-proof-979b00e4
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/Voting_".
    "proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-991e979b00e4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9930482e082d
::
++  test-sany-huang-482e082d
  =/  manifest  (crip "specifications/Huang/manifest.json")
  =/  module  (crip "specifications/Huang/Huang.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9930482e082d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9939e2e3f903
::
++  test-sany-bufferedrandomaccessfile-e2e3f903
  =/  manifest  (crip "specifications/braf/manifest.json")
  =/  module  (crip "specifications/braf/BufferedRandomAccessFile.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9939e2e3f903'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9a2c5ff6b3c4
::
++  test-sany-simple-5ff6b3c4
  =/  manifest  (crip "specifications/TeachingConcurrency/manifest.json")
  =/  module  (crip "specifications/TeachingConcurrency/Simple.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9a2c5ff6b3c4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9dac097835f3
::
++  test-sany-hourclock2-097835f3
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/HourC".
    "lock2.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9dac097835f3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9f5f571f3517
::
++  test-sany-bits-571f3517
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module
    %-  crip
    "specifications/tower_of_hanoi/Hanoi.toolbox/Mode".
    "l_1/Bits.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9f5f571f3517'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9f69559d0efa
::
++  test-sany-apprisoner-559d0efa
  =/  manifest
    %-  crip
    "specifications/Prisoners_Single_Switch/manifest.".
    "json"
  =/  module
    %-  crip
    "specifications/Prisoners_Single_Switch/APPrisone".
    "r.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9f69559d0efa'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9f71f7a3e80d
::
++  test-sany-apchameneos-f7a3e80d
  =/  manifest  (crip "specifications/Chameneos/manifest.json")
  =/  module  (crip "specifications/Chameneos/APChameneos.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9f71f7a3e80d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9fc9cdb111aa
::
++  test-sany-differentialequations-cdb111aa
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/DifferentialEquations.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9fc9cdb111aa'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-9fd68a841add
::
++  test-sany-voteproof-8a841add
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/VoteProof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-9fd68a841add'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a0f2e0417249
::
++  test-sany-readerswriters-proof-e0417249
  =/  manifest  (crip "specifications/ReadersWriters/manifest.json")
  =/  module
    %-  crip
    "specifications/ReadersWriters/ReadersWriters_pro".
    "of.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a0f2e0417249'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a10afb6ad282
::
++  test-sany-paxoscommit-fb6ad282
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module
    %-  crip
    "specifications/transaction_commit/PaxosCommit.tl".
    "a"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a10afb6ad282'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a12ebba4c1e0
::
++  test-sany-bakery-bba4c1e0
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module  (crip "specifications/Bakery-Boulangerie/Bakery.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a12ebba4c1e0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a17bc0ccc0c4
::
++  test-sany-lamportmutex-c0ccc0c4
  =/  manifest  (crip "specifications/lamport_mutex/manifest.json")
  =/  module  (crip "specifications/lamport_mutex/LamportMutex.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a17bc0ccc0c4'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a2e857e79f61
::
++  test-sany-mc-57e79f61
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module
    %-  crip
    "specifications/N-Queens/Queens.toolbox/FourQueen".
    "s/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a2e857e79f61'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a406354bcbee
::
++  test-sany-apewd840-354bcbee
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/APEWD840.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a406354bcbee'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a47223818d0a
::
++  test-sany-prob-23818d0a
  =/  manifest  (crip "specifications/KnuthYao/manifest.json")
  =/  module  (crip "specifications/KnuthYao/Prob.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a47223818d0a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a4d85fa1ea8f
::
++  test-sany-channel-proof-5fa1ea8f
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/Channel_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a4d85fa1ea8f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a50ac75fc695
::
++  test-sany-tlcsailfish2-c75fc695
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/TLCSailfish2.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a50ac75fc695'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a50cb774aa9a
::
++  test-sany-syncterminationdetection-proof-b774aa9a
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd840/SyncTerminationDetection_p".
    "roof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a50cb774aa9a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a53faf128b74
::
++  test-sany-spantreetest-af128b74
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/SpanTreeTest.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a53faf128b74'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a66eee46d0be
::
++  test-sany-ewd998chanid-ee46d0be
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998ChanID.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a66eee46d0be'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a6d20fbd9a49
::
++  test-sany-apstages-0fbd9a49
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/APstages.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a6d20fbd9a49'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a6d246de8c8c
::
++  test-sany-apdistributedreplicatedlog-46de8c8c
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/APDistributedRepl".
    "icatedLog.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a6d246de8c8c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a71822243a38
::
++  test-sany-barrier-22243a38
  =/  manifest  (crip "specifications/barriers/manifest.json")
  =/  module  (crip "specifications/barriers/Barrier.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a71822243a38'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a755602b5056
::
++  test-sany-queens-602b5056
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module
    %-  crip
    "specifications/N-Queens/Queens.toolbox/FourQueen".
    "s/Queens.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a755602b5056'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a77d5b7af751
::
++  test-sany-vouchercancel-5b7af751
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherCancel.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a77d5b7af751'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a8c7611c8c59
::
++  test-sany-hdisksynod-611c8c59
  =/  manifest  (crip "specifications/diskpaxos/manifest.json")
  =/  module  (crip "specifications/diskpaxos/HDiskSynod.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a8c7611c8c59'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a9aec98ffd52
::
++  test-sany-graphs-c98ffd52
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/Graphs.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a9aec98ffd52'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a9c4394f89d6
::
++  test-sany-ewd998-proof-394f89d6
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a9c4394f89d6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-a9fb5bd31af7
::
++  test-sany-asyncterminationdetection-5bd31af7
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd998/AsyncTerminationDetection.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-a9fb5bd31af7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-aa744f68d794
::
++  test-sany-sumsequence-4f68d794
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/SumSequence.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-aa744f68d794'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-aa8ee0184cfd
::
++  test-sany-integers-e0184cfd
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/Intege".
    "rs.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-aa8ee0184cfd'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ab302addf5e7
::
++  test-sany-tlcmc-2addf5e7
  =/  manifest  (crip "specifications/TLC/manifest.json")
  =/  module  (crip "specifications/TLC/TLCMC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ab302addf5e7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-adae43c0b7d0
::
++  test-sany-mcinnersequential-43c0b7d0
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/MCInnerSequential.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-adae43c0b7d0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ae18b7b8874e
::
++  test-sany-acp-sb-tlc-b7b8874e
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_SB_TLC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ae18b7b8874e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-aeb9f1f56f4d
::
++  test-sany-mc-f1f56f4d
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_3/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-aeb9f1f56f4d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-af68eb96f4f1
::
++  test-sany-innerserial-eb96f4f1
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/InnerSerial.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-af68eb96f4f1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-afb09531c493
::
++  test-sany-disruptor-spmc-9531c493
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/Disruptor_SPMC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-afb09531c493'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b05da9c90f22
::
++  test-sany-keyvaluestore-a9c90f22
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/KeyValueStore.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b05da9c90f22'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b092312c816c
::
++  test-sany-paxoscommit-proof-312c816c
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module
    %-  crip
    "specifications/transaction_commit/PaxosCommit_pr".
    "oof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b092312c816c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b0ebcf82f209
::
++  test-sany-c1cs-cf82f209
  =/  manifest  (crip "specifications/c1cs/manifest.json")
  =/  module  (crip "specifications/c1cs/c1cs.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b0ebcf82f209'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b10ba1548ca0
::
++  test-sany-mcewd687a-a1548ca0
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/MCEWD687a.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b10ba1548ca0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b1b36f36c77c
::
++  test-sany-mcpaxos-6f36c77c
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCPaxos".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b1b36f36c77c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b2f8204f6321
::
++  test-sany-stones-204f6321
  =/  manifest  (crip "specifications/Stones/manifest.json")
  =/  module  (crip "specifications/Stones/Stones.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b2f8204f6321'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b36cada8d1c1
::
++  test-sany-keyvaluestore-proof-ada8d1c1
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module
    %-  crip
    "specifications/KeyValueStore/KeyValueStore_proof".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b36cada8d1c1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b3d449b69553
::
++  test-sany-internalmemory-49b69553
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/I".
    "nternalMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b3d449b69553'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b3fb9c35b4a9
::
++  test-sany-replicatedlog-9c35b4a9
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module  (crip "specifications/FiniteMonotonic/ReplicatedLog.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b3fb9c35b4a9'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b48cc6891ba5
::
++  test-sany-ewd998pcal-c6891ba5
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998PCal.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b48cc6891ba5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b4c13cd9b2a0
::
++  test-sany-stages-3cd9b2a0
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/stages.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b4c13cd9b2a0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b52463c45ced
::
++  test-sany-aphourclock2-63c45ced
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/APHou".
    "rClock2.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b52463c45ced'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b5616421a215
::
++  test-sany-ewd687a-6421a215
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/EWD687a.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b5616421a215'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b56f288288b5
::
++  test-sany-voucherredeem-288288b5
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherRedeem.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b56f288288b5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b5c391e56c96
::
++  test-sany-missionariesandcannibals-91e56c96
  =/  manifest
    %-  crip
    "specifications/MissionariesAndCannibals/manifest".
    ".json"
  =/  module
    %-  crip
    "specifications/MissionariesAndCannibals/Missiona".
    "riesAndCannibals.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b5c391e56c96'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b5d75cfd1bb1
::
++  test-sany-spantree-5cfd1bb1
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/SpanTree.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b5d75cfd1bb1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b60515435595
::
++  test-sany-apcf1s-folklore-15435595
  =/  manifest  (crip "specifications/cf1s-folklore/manifest.json")
  =/  module  (crip "specifications/cf1s-folklore/APcf1s_folklore.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b60515435595'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b6b97437937f
::
++  test-sany-einstein-7437937f
  =/  manifest  (crip "specifications/EinsteinRiddle/manifest.json")
  =/  module  (crip "specifications/EinsteinRiddle/Einstein.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b6b97437937f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b6d089508a4c
::
++  test-sany-bags-89508a4c
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/Bags.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b6d089508a4c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b707bcc82101
::
++  test-sany-serialmemory-bcc82101
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/SerialMemory.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b707bcc82101'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b7dee2c84c81
::
++  test-sany-bosco-e2c84c81
  =/  manifest  (crip "specifications/bosco/manifest.json")
  =/  module  (crip "specifications/bosco/bosco.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b7dee2c84c81'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b86175ebca2f
::
++  test-sany-stages-proof-75ebca2f
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/stages_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b86175ebca2f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b86c0a2348c5
::
++  test-sany-voting-0a2348c5
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/Voting.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b86c0a2348c5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-b98910d57a22
::
++  test-sany-apchannel-10d57a22
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/APChannel.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-b98910d57a22'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ba62c03e8864
::
++  test-sany-aphourclock-c03e8864
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/APHou".
    "rClock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ba62c03e8864'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ba980bfbcd04
::
++  test-sany-diehard-proof-0bfbcd04
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/DieHard_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ba980bfbcd04'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-bab6a34ea19d
::
++  test-sany-majority-a34ea19d
  =/  manifest  (crip "specifications/Majority/manifest.json")
  =/  module  (crip "specifications/Majority/Majority.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-bab6a34ea19d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-bafacca1d3d5
::
++  test-sany-readerswriters-cca1d3d5
  =/  manifest  (crip "specifications/ReadersWriters/manifest.json")
  =/  module  (crip "specifications/ReadersWriters/ReadersWriters.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-bafacca1d3d5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-bbe72165fd85
::
++  test-sany-protoreals-2165fd85
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/ProtoR".
    "eals.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-bbe72165fd85'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-bcddf476d18b
::
++  test-sany-quicksort-f476d18b
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/Quicksort.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-bcddf476d18b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-bebdb8e540dc
::
++  test-sany-allocatorimplementation-proof-b8e540dc
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module
    %-  crip
    "specifications/allocator/AllocatorImplementation".
    "_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-bebdb8e540dc'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-bfc4dff9063c
::
++  test-sany-queenspluscal-dff9063c
  =/  manifest  (crip "specifications/N-Queens/manifest.json")
  =/  module  (crip "specifications/N-Queens/QueensPluscal.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-bfc4dff9063c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c0b4ef1713cc
::
++  test-sany-util-ef1713cc
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/Util.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c0b4ef1713cc'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c0e728ef132c
::
++  test-sany-tcommit-28ef132c
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/TCommit.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c0e728ef132c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c0f969b54a5f
::
++  test-sany-mctcp-69b54a5f
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/MCtcp.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c0f969b54a5f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c10e1702ec99
::
++  test-sany-dijkstramutex-1702ec99
  =/  manifest  (crip "specifications/dijkstra-mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/LSpec-model/DijkstraMutex.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c10e1702ec99'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c10fc415d65e
::
++  test-sany-reachabilitytest-c415d65e
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/ReachabilityTes".
    "t.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c10fc415d65e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c1624bc8952e
::
++  test-sany-simpleregular-proof-4bc8952e
  =/  manifest  (crip "specifications/TeachingConcurrency/manifest.json")
  =/  module
    %-  crip
    "specifications/TeachingConcurrency/SimpleRegular".
    "_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c1624bc8952e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c2647656faef
::
++  test-sany-synod-7656faef
  =/  manifest  (crip "specifications/diskpaxos/manifest.json")
  =/  module  (crip "specifications/diskpaxos/Synod.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c2647656faef'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c3688ae4ad06
::
++  test-sany-peano-8ae4ad06
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/Peano.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c3688ae4ad06'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c3c5a41ec8f8
::
++  test-sany-twophase-proof-a41ec8f8
  =/  manifest  (crip "specifications/TwoPhase/manifest.json")
  =/  module  (crip "specifications/TwoPhase/TwoPhase_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c3c5a41ec8f8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c3cc9997dd27
::
++  test-sany-parreachproofs-9997dd27
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/ParReachProofs.".
    "tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c3cc9997dd27'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c3db9285019f
::
++  test-sany-hourclock-9285019f
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/HourCl".
    "ock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c3db9285019f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c41a243f42e3
::
++  test-sany-mcdieharder-243f42e3
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/MCDieHarder.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c41a243f42e3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c47067ac6577
::
++  test-sany-echo-67ac6577
  =/  manifest  (crip "specifications/echo/manifest.json")
  =/  module  (crip "specifications/echo/Echo.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c47067ac6577'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c583b42ae07c
::
++  test-sany-ewd998chanid-export-b42ae07c
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998ChanID_export.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c583b42ae07c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c5d4d8308bb0
::
++  test-sany-hourclock-proof-d8308bb0
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/HourCl".
    "ock_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c5d4d8308bb0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c6274df8e1d2
::
++  test-sany-apcoffeecan-4df8e1d2
  =/  manifest  (crip "specifications/CoffeeCan/manifest.json")
  =/  module  (crip "specifications/CoffeeCan/APCoffeeCan.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c6274df8e1d2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c6521ed5441e
::
++  test-sany-innerfifo-proof-1ed5441e
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/InnerFIFO_".
    "proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c6521ed5441e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c6867b67857d
::
++  test-sany-clientcentric-7b67857d
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/ClientCentric.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c6867b67857d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c692787a5528
::
++  test-sany-registerinterface-787a5528
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/RegisterInterface.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c692787a5528'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-c8a24595e566
::
++  test-sany-fifo-4595e566
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module  (crip "specifications/SpecifyingSystems/FIFO/FIFO.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-c8a24595e566'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ca95559d9daa
::
++  test-sany-mcalternatingbit-559d9daa
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/MCAlternati".
    "ngBit.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ca95559d9daa'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ca9788932169
::
++  test-sany-reachable-88932169
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/Reachable.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ca9788932169'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-cad524756c91
::
++  test-sany-mcreplicatedlog-24756c91
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/MCReplicatedLog.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-cad524756c91'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-cb2781b876e3
::
++  test-sany-apcigarettesmokers-81b876e3
  =/  manifest  (crip "specifications/CigaretteSmokers/manifest.json")
  =/  module
    %-  crip
    "specifications/CigaretteSmokers/APCigaretteSmoke".
    "rs.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-cb2781b876e3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-cb8e7d6b9a5e
::
++  test-sany-addtwo-7d6b9a5e
  =/  manifest  (crip "specifications/LearnProofs/manifest.json")
  =/  module  (crip "specifications/LearnProofs/AddTwo.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-cb8e7d6b9a5e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-cc1331e87e4c
::
++  test-sany-mcconsensus-31e87e4c
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCConse".
    "nsus.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-cc1331e87e4c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ce7718c35395
::
++  test-sany-apc1cs-18c35395
  =/  manifest  (crip "specifications/c1cs/manifest.json")
  =/  module  (crip "specifications/c1cs/APc1cs.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ce7718c35395'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-cefae09e5ff6
::
++  test-sany-bnfgrammars-e09e5ff6
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Syntax/BNFGramm".
    "ars.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-cefae09e5ff6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d083ea6d1672
::
++  test-sany-tcp-proof-ea6d1672
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/tcp_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d083ea6d1672'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d08523d4badb
::
++  test-sany-barriers-23d4badb
  =/  manifest  (crip "specifications/barriers/manifest.json")
  =/  module  (crip "specifications/barriers/Barriers.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d08523d4badb'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d08e38a137b0
::
++  test-sany-spa-attack-38a137b0
  =/  manifest  (crip "specifications/SDP_Verification/manifest.json")
  =/  module
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_Spec/".
    "SPA_Attack.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d08e38a137b0'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d1b131ea3cf1
::
++  test-sany-mc-31ea3cf1
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module
    %-  crip
    "specifications/tower_of_hanoi/Hanoi.toolbox/Mode".
    "l_1/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d1b131ea3cf1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d1b14da1b55b
::
++  test-sany-ewd687a-proof-4da1b55b
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/EWD687a_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d1b14da1b55b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d2d663b1ccb5
::
++  test-sany-checkpointcoordination-63b1ccb5
  =/  manifest
    %-  crip
    "specifications/CheckpointCoordination/manifest.j".
    "son"
  =/  module
    %-  crip
    "specifications/CheckpointCoordination/Checkpoint".
    "Coordination.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d2d663b1ccb5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d2d8fa7499e2
::
++  test-sany-slidingpuzzles-fa7499e2
  =/  manifest  (crip "specifications/SlidingPuzzles/manifest.json")
  =/  module  (crip "specifications/SlidingPuzzles/SlidingPuzzles.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d2d8fa7499e2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d31a410a8c86
::
++  test-sany-mckvsnap-410a8c86
  =/  manifest  (crip "specifications/KeyValueStore/manifest.json")
  =/  module  (crip "specifications/KeyValueStore/MCKVsnap.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d31a410a8c86'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d36770acf2f3
::
++  test-sany-apreachable-70acf2f3
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/APReachable.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d36770acf2f3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d3a77064269a
::
++  test-sany-mcrealtime-7064269a
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/MCReal".
    "Time.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d3a77064269a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d3a921eb316a
::
++  test-sany-mccrdt-21eb316a
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module  (crip "specifications/FiniteMonotonic/MCCRDT.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d3a921eb316a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d3dbb692d9f8
::
++  test-sany-mc-sums-even-b692d9f8
  =/  manifest  (crip "specifications/sums_even/manifest.json")
  =/  module  (crip "specifications/sums_even/MC_sums_even.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d3dbb692d9f8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d3fd96e752ce
::
++  test-sany-smokeewd998-sc-96e752ce
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/SmokeEWD998_SC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d3fd96e752ce'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d43932ae21ae
::
++  test-sany-chameneos-32ae21ae
  =/  manifest  (crip "specifications/Chameneos/manifest.json")
  =/  module  (crip "specifications/Chameneos/Chameneos.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d43932ae21ae'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d43ebcaee9c9
::
++  test-sany-consensus-bcaee9c9
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/Consens".
    "us.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d43ebcaee9c9'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d482667d2c17
::
++  test-sany-memoryinterface-667d2c17
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/Memory".
    "Interface.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d482667d2c17'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d49b73b38545
::
++  test-sany-crdt-73b38545
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module  (crip "specifications/FiniteMonotonic/CRDT.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d49b73b38545'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d4ac3530abbc
::
++  test-sany-twophase-3530abbc
  =/  manifest  (crip "specifications/TwoPhase/manifest.json")
  =/  module  (crip "specifications/TwoPhase/TwoPhase.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d4ac3530abbc'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d4d9513f5621
::
++  test-sany-mcinnerserial-513f5621
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/MCInnerSerial.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d4d9513f5621'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d51473a872d8
::
++  test-sany-mcconsensus-73a872d8
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/MCConsensus.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d51473a872d8'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d644132df5b6
::
++  test-sany-spanning-132df5b6
  =/  manifest  (crip "specifications/spanning/manifest.json")
  =/  module  (crip "specifications/spanning/spanning.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d644132df5b6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d6dfd159230f
::
++  test-sany-reachabilityproofs-d159230f
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/ReachabilityPro".
    "ofs.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d6dfd159230f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d7ac589fb624
::
++  test-sany-apbcastfolklore-589fb624
  =/  manifest  (crip "specifications/bcastFolklore/manifest.json")
  =/  module  (crip "specifications/bcastFolklore/APbcastFolklore.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d7ac589fb624'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d7b52a2f3f5a
::
++  test-sany-hourclock-2a2f3f5a
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/HourC".
    "lock.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d7b52a2f3f5a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-d9f679aa6613
::
++  test-sany-aptcp-79aa6613
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/APtcp.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-d9f679aa6613'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-dab7175836ae
::
++  test-sany-mcyoyonopruning-175836ae
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/MCYoYoNoPruning.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-dab7175836ae'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-dbdc5efca53a
::
++  test-sany-hourclock-proof-5efca53a
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/HourC".
    "lock_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-dbdc5efca53a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-dbdd7cec9421
::
++  test-sany-realtime-ss-7cec9421
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/RealTi".
    "me_SS.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-dbdd7cec9421'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-dc02aa962c80
::
++  test-sany-utils-aa962c80
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/Utils.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-dc02aa962c80'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-dd071bbeae1c
::
++  test-sany-reachableproofs-1bbeae1c
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/ReachableProofs".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-dd071bbeae1c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-dd577940e446
::
++  test-sany-mcquicksort-7940e446
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/MCQuicksort.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-dd577940e446'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-df2fff9cb6e2
::
++  test-sany-lock-ff9cb6e2
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module  (crip "specifications/locks_auxiliary_vars/Lock.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-df2fff9cb6e2'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e00a9d70bc2c
::
++  test-sany-mcreachable-9d70bc2c
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/MCReachable.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e00a9d70bc2c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e012e6f55251
::
++  test-sany-simplemath-e6f55251
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/SimpleMath/Simp".
    "leMath.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e012e6f55251'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e090558acf49
::
++  test-sany-mc-558acf49
  =/  manifest  (crip "specifications/SDP_Verification/manifest.json")
  =/  module
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_New_S".
    "olution_Spec/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e090558acf49'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e0cb663149e7
::
++  test-sany-mcpaxos-663149e7
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/MCPaxos.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e0cb663149e7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e1871a24de98
::
++  test-sany-majorityproof-1a24de98
  =/  manifest  (crip "specifications/Majority/manifest.json")
  =/  module  (crip "specifications/Majority/MajorityProof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e1871a24de98'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e2a1ca11322e
::
++  test-sany-mcboulanger-ca11322e
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module
    %-  crip
    "specifications/Bakery-Boulangerie/MCBoulanger.tl".
    "a"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e2a1ca11322e'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e47f1da34f0c
::
++  test-sany-singlelanebridge-1da34f0c
  =/  manifest  (crip "specifications/SingleLaneBridge/manifest.json")
  =/  module
    %-  crip
    "specifications/SingleLaneBridge/SingleLaneBridge".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e47f1da34f0c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e52455c2bb16
::
++  test-sany-prisoners-55c2bb16
  =/  manifest  (crip "specifications/Prisoners/manifest.json")
  =/  module  (crip "specifications/Prisoners/Prisoners.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e52455c2bb16'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e5365cc9e0f6
::
++  test-sany-finitesets-5cc9e0f6
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Standard/Finite".
    "Sets.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e5365cc9e0f6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e53b286d760c
::
++  test-sany-paxos-286d760c
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/Paxos.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e53b286d760c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e58dc856e07b
::
++  test-sany-yoyopruning-c856e07b
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/YoYoPruning.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e58dc856e07b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e6108d7f1cde
::
++  test-sany-apdisruptor-mpmc-8d7f1cde
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/APDisruptor_MPMC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e6108d7f1cde'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e6134efcb645
::
++  test-sany-utils-4efcb645
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/Utils.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e6134efcb645'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e6345ed080d3
::
++  test-sany-findhighest-5ed080d3
  =/  manifest  (crip "specifications/LearnProofs/manifest.json")
  =/  module  (crip "specifications/LearnProofs/FindHighest.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e6345ed080d3'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e78eb92aae89
::
++  test-sany-age-channel-b92aae89
  =/  manifest  (crip "specifications/detector_chan96/manifest.json")
  =/  module  (crip "specifications/detector_chan96/Age_Channel.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e78eb92aae89'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e85c1c5d9e8c
::
++  test-sany-zsequences-1c5d9e8c
  =/  manifest
    %-  crip
    "specifications/LeastCircularSubstring/manifest.j".
    "son"
  =/  module
    %-  crip
    "specifications/LeastCircularSubstring/ZSequences".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e85c1c5d9e8c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e8c9e01bde8f
::
++  test-sany-hanoi-anim-e01bde8f
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module  (crip "specifications/tower_of_hanoi/Hanoi_anim.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e8c9e01bde8f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-e8de79576739
::
++  test-sany-mc-spanning-79576739
  =/  manifest  (crip "specifications/spanning/manifest.json")
  =/  module  (crip "specifications/spanning/MC_spanning.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-e8de79576739'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ea2269a83e07
::
++  test-sany-parreach-69a83e07
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/ParReach.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ea2269a83e07'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ebc539c19a5d
::
++  test-sany-ewd840-json-39c19a5d
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/EWD840_json.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ebc539c19a5d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ec2ef0cd86d1
::
++  test-sany-hanoi-f0cd86d1
  =/  manifest  (crip "specifications/tower_of_hanoi/manifest.json")
  =/  module  (crip "specifications/tower_of_hanoi/Hanoi.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ec2ef0cd86d1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ec9a1d51643f
::
++  test-sany-mclamportmutex-1d51643f
  =/  manifest  (crip "specifications/lamport_mutex/manifest.json")
  =/  module  (crip "specifications/lamport_mutex/MCLamportMutex.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ec9a1d51643f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ecd820f7cbd1
::
++  test-sany-disksynod-20f7cbd1
  =/  manifest  (crip "specifications/diskpaxos/manifest.json")
  =/  module  (crip "specifications/diskpaxos/DiskSynod.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ecd820f7cbd1'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ed08edd749b5
::
++  test-sany-slush-edd749b5
  =/  manifest  (crip "specifications/SlushProtocol/manifest.json")
  =/  module  (crip "specifications/SlushProtocol/Slush.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ed08edd749b5'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ed35eb13b6d6
::
++  test-sany-innerfifoinstanced-eb13b6d6
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/InnerFIFOI".
    "nstanced.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ed35eb13b6d6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-ed8cac245efe
::
++  test-sany-ewd998-optssc-ac245efe
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998_optsSC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-ed8cac245efe'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-efb800ba0f51
::
++  test-sany-rtwritethroughcache-00ba0f51
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/RTWrit".
    "eThroughCache.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-efb800ba0f51'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f00938b8a371
::
++  test-sany-writethroughcacheinstanced-38b8a371
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/W".
    "riteThroughCacheInstanced.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f00938b8a371'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f00b18c5020a
::
++  test-sany-ewd687a-anim-18c5020a
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/EWD687a_anim.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f00b18c5020a'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f24ff98b862d
::
++  test-sany-mcvoting-f98b862d
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/MCVoting.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f24ff98b862d'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f3966f863659
::
++  test-sany-clean-6f863659
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/clean.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f3966f863659'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f4f26e1810a7
::
++  test-sany-writethroughcache-6e1810a7
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/RealTime/WriteT".
    "hroughCache.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f4f26e1810a7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f7d3e721356c
::
++  test-sany-lockhs-e721356c
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module  (crip "specifications/locks_auxiliary_vars/LockHS.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f7d3e721356c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f7f91d0e7e81
::
++  test-sany-ewd998-opts-1d0e7e81
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998_opts.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f7f91d0e7e81'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f9376a184a28
::
++  test-sany-missionariesandcannibals-proof-6a184a28
  =/  manifest
    %-  crip
    "specifications/MissionariesAndCannibals/manifest".
    ".json"
  =/  module
    %-  crip
    "specifications/MissionariesAndCannibals/Missiona".
    "riesAndCannibals_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f9376a184a28'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f979c93172ae
::
++  test-sany-simpleallocator-proof-c93172ae
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module
    %-  crip
    "specifications/allocator/SimpleAllocator_proof.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f979c93172ae'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-f9bd4c6aa28c
::
++  test-sany-coffeecan-4c6aa28c
  =/  manifest  (crip "specifications/CoffeeCan/manifest.json")
  =/  module  (crip "specifications/CoffeeCan/CoffeeCan.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-f9bd4c6aa28c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fa55f0d6b4b7
::
++  test-sany-multipaxos-mc-f0d6b4b7
  =/  manifest  (crip "specifications/MultiPaxos-SMR/manifest.json")
  =/  module  (crip "specifications/MultiPaxos-SMR/MultiPaxos_MC.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fa55f0d6b4b7'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fad1b2debc3c
::
++  test-sany-allocatorimplementation-b2debc3c
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module
    %-  crip
    "specifications/allocator/AllocatorImplementation".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fad1b2debc3c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fb2439999d5c
::
++  test-sany-sums-even-39999d5c
  =/  manifest  (crip "specifications/sums_even/manifest.json")
  =/  module  (crip "specifications/sums_even/sums_even.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fb2439999d5c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fb76f4457f9c
::
++  test-sany-simtokenring-f4457f9c
  =/  manifest  (crip "specifications/ewd426/manifest.json")
  =/  module  (crip "specifications/ewd426/SimTokenRing.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fb76f4457f9c'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fb9449caadf6
::
++  test-sany-apreplicatedlog-49caadf6
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/APReplicatedLog.t".
    "la"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fb9449caadf6'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fbe83bbbb99f
::
++  test-sany-mcreachability-3bbbb99f
  =/  manifest  (crip "specifications/TLC/manifest.json")
  =/  module  (crip "specifications/TLC/MCReachability.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fbe83bbbb99f'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fc2e9a7d2a16
::
++  test-sany-ewd998-anim-9a7d2a16
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998_anim.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fc2e9a7d2a16'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fd02118fb4d9
::
++  test-sany-apringbuffer-118fb4d9
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/APRingBuffer.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fd02118fb4d9'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fde7f864b40b
::
++  test-sany-mc-f864b40b
  =/  manifest  (crip "specifications/dijkstra-mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/dijkstra-mutex/DijkstraMutex.tool".
    "box/LSpec-model/MC.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fde7f864b40b'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
::
::  coverage-id: parse-fe9810893647
::
++  test-sany-ewd840-10893647
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/EWD840.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'parse-fe9810893647'
      manifest
      module
      model
      %sany
      [%parse ~]
      %success
      'parse-only'
      %.y
      ~
      options
  ==
--
