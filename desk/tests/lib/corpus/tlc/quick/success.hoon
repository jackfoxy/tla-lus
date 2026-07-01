/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: model-001d09121b38
::
++  test-tlc-coffeecan1000beans-09121b38
  =/  manifest  (crip "specifications/CoffeeCan/manifest.json")
  =/  module  (crip "specifications/CoffeeCan/CoffeeCan.tla")
  =/  model  (crip "specifications/CoffeeCan/CoffeeCan1000Beans.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-001d09121b38'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:15'
      %.y
      [~ [~ 501.500] [~ 2.000.002] ~]
      options
  ==
::
::  coverage-id: model-02372d3e6c7e
::
++  test-tlc-hourclock-2d3e6c7e
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/HourC".
    "lock.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/HourClock/HourC".
    "lock.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-02372d3e6c7e'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 12] [~ 24] ~]
      options
  ==
::
::  coverage-id: model-05a8017e840b
::
++  test-tlc-mcwritethroughcache-017e840b
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "CWriteThroughCache.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "CWriteThroughCache.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-05a8017e840b'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 5.196] [~ 28.170] ~]
      options
  ==
::
::  coverage-id: model-0732b6443578
::
++  test-tlc-spantreetest4nodes-b6443578
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/SpanTreeTest.tla")
  =/  model
    %-  crip
    "specifications/SpanningTree/SpanTreeTest4Nodes.c".
    "fg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-0732b6443578'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 3.984] [~ 21.784] ~]
      options
  ==
::
::  coverage-id: model-08a3565ac9a4
::
++  test-tlc-printvalues-565ac9a4
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/PrintValues.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/PrintValues.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-08a3565ac9a4'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-0cfe484348f2
::
++  test-tlc-mcmajority-484348f2
  =/  manifest  (crip "specifications/Majority/manifest.json")
  =/  module  (crip "specifications/Majority/MCMajority.tla")
  =/  model  (crip "specifications/Majority/MCMajority.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-0cfe484348f2'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 2.733] [~ 3.459] ~]
      options
  ==
::
::  coverage-id: model-0d22f637d5d7
::
++  test-tlc-paxos-f637d5d7
  =/  manifest  (crip "specifications/SimplifiedFastPaxos/manifest.json")
  =/  module  (crip "specifications/SimplifiedFastPaxos/Paxos.tla")
  =/  model  (crip "specifications/SimplifiedFastPaxos/Paxos.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-0d22f637d5d7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 1.207] [~ 13.290] ~]
      options
  ==
::
::  coverage-id: model-107e65dd58be
::
++  test-tlc-kvstore-65dd58be
  =/  manifest  (crip "specifications/btree/manifest.json")
  =/  module  (crip "specifications/btree/kvstore.tla")
  =/  model  (crip "specifications/btree/kvstore.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-107e65dd58be'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 2.641] [~ 28.585] ~]
      options
  ==
::
::  coverage-id: model-112937e7b980
::
++  test-tlc-mcecho-37e7b980
  =/  manifest  (crip "specifications/echo/manifest.json")
  =/  module  (crip "specifications/echo/MCEcho.tla")
  =/  model  (crip "specifications/echo/MCEcho.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-112937e7b980'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 75] [~ 116] ~]
      options
  ==
::
::  coverage-id: model-12f58d65ed99
::
++  test-tlc-ewd998pcal-8d65ed99
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998PCal.tla")
  =/  model  (crip "specifications/ewd998/EWD998PCal.cfg")
  =/  options
    :*  %auto
        63
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-12f58d65ed99'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:21'
      %.y
      [~ [~ 321.370] [~ 2.808.396] ~]
      options
  ==
::
::  coverage-id: model-130e943e78e9
::
++  test-tlc-mcfindhighest-943e78e9
  =/  manifest  (crip "specifications/LearnProofs/manifest.json")
  =/  module  (crip "specifications/LearnProofs/MCFindHighest.tla")
  =/  model  (crip "specifications/LearnProofs/MCFindHighest.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-130e943e78e9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 742] [~ 1.523] ~]
      options
  ==
::
::  coverage-id: model-13d26d2e8bc6
::
++  test-tlc-catevenboxes-6d2e8bc6
  =/  manifest  (crip "specifications/Moving_Cat_Puzzle/manifest.json")
  =/  module  (crip "specifications/Moving_Cat_Puzzle/Cat.tla")
  =/  model
    %-  crip
    "specifications/Moving_Cat_Puzzle/CatEvenBoxes.cf".
    "g"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-13d26d2e8bc6'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 48] [~ 128] ~]
      options
  ==
::
::  coverage-id: model-148dae928462
::
++  test-tlc-diningphilosophers-ae928462
  =/  manifest  (crip "specifications/DiningPhilosophers/manifest.json")
  =/  module
    %-  crip
    "specifications/DiningPhilosophers/DiningPhilosop".
    "hers.tla"
  =/  model
    %-  crip
    "specifications/DiningPhilosophers/DiningPhilosop".
    "hers.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-148dae928462'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 67] [~ 336] ~]
      options
  ==
::
::  coverage-id: model-15f3d7f96ce1
::
++  test-tlc-voucherlifecycle-d7f96ce1
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherLifeCycle.tla")
  =/  model  (crip "specifications/byihive/VoucherLifeCycle.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-15f3d7f96ce1'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 64] [~ 193] ~]
      options
  ==
::
::  coverage-id: model-1660a65f6e99
::
++  test-tlc-mccrdt-a65f6e99
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module  (crip "specifications/FiniteMonotonic/MCCRDT.tla")
  =/  model  (crip "specifications/FiniteMonotonic/MCCRDT.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~['tlc2.tool.impl.Tool.cdot=true']
    ==
  %-  expect-corpus-case
  :*  'model-1660a65f6e99'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 25.000] [~ 1.350.001] ~]
      options
  ==
::
::  coverage-id: model-172d463e5260
::
++  test-tlc-tlcsailfish1-463e5260
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/TLCSailfish1.tla")
  =/  model  (crip "specifications/dag-consensus/TLCSailfish1.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-172d463e5260'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 109.604] [~ 314.144] ~]
      options
  ==
::
::  coverage-id: model-18539c444062
::
++  test-tlc-mcyoyonopruning-9c444062
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/MCYoYoNoPruning.tla")
  =/  model  (crip "specifications/YoYo/MCYoYoNoPruning.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-18539c444062'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 60] [~ 110] ~]
      options
  ==
::
::  coverage-id: model-1aa2a74f45ef
::
++  test-tlc-voucherissue-a74f45ef
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherIssue.tla")
  =/  model  (crip "specifications/byihive/VoucherIssue.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-1aa2a74f45ef'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.199] [~ 26.848] ~]
      options
  ==
::
::  coverage-id: model-1b06acea1214
::
++  test-tlc-mcconsensus-acea1214
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCConse".
    "nsus.tla"
  =/  model
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCConse".
    "nsus.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-1b06acea1214'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4] [~ 4] ~]
      options
  ==
::
::  coverage-id: model-1b524a353683
::
++  test-tlc-mcreplicatedlog-4a353683
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/MCReplicatedLog.t".
    "la"
  =/  model
    %-  crip
    "specifications/FiniteMonotonic/MCReplicatedLog.c".
    "fg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~['tlc2.tool.impl.Tool.cdot=true']
    ==
  %-  expect-corpus-case
  :*  'model-1b524a353683'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 1.363] [~ 17.425] ~]
      options
  ==
::
::  coverage-id: model-1e666b5f5f3c
::
++  test-tlc-bcastbyznobcast-6b5f5f3c
  =/  manifest  (crip "specifications/bcastByz/manifest.json")
  =/  module  (crip "specifications/bcastByz/bcastByz.tla")
  =/  model  (crip "specifications/bcastByz/bcastByzNoBcast.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-1e666b5f5f3c'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 45] [~ 90] ~]
      options
  ==
::
::  coverage-id: model-1ff21b2668f7
::
++  test-tlc-btree-1b2668f7
  =/  manifest  (crip "specifications/btree/manifest.json")
  =/  module  (crip "specifications/btree/btree.tla")
  =/  model  (crip "specifications/btree/btree.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-1ff21b2668f7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:15'
      %.y
      [~ [~ 374.727] [~ 2.820.091] ~]
      options
  ==
::
::  coverage-id: model-21eae4c6aaa7
::
++  test-tlc-mc-e4c6aaa7
  =/  manifest  (crip "specifications/SDP_Verification/manifest.json")
  =/  module
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_New_S".
    "olution_Spec/MC.tla"
  =/  model
    %-  crip
    "specifications/SDP_Verification/SDP_Attack_New_S".
    "olution_Spec/MC.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-21eae4c6aaa7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 2.881] [~ 6.826] ~]
      options
  ==
::
::  coverage-id: model-227e52a2d830
::
++  test-tlc-lockhs-52a2d830
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module  (crip "specifications/locks_auxiliary_vars/LockHS.tla")
  =/  model  (crip "specifications/locks_auxiliary_vars/LockHS.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-227e52a2d830'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 28] [~ 41] ~]
      options
  ==
::
::  coverage-id: model-24aa2ddb7623
::
++  test-tlc-prisonerlightunknown-2ddb7623
  =/  manifest
    %-  crip
    "specifications/Prisoners_Single_Switch/manifest.".
    "json"
  =/  module
    %-  crip
    "specifications/Prisoners_Single_Switch/Prisoner.".
    "tla"
  =/  model
    %-  crip
    "specifications/Prisoners_Single_Switch/PrisonerL".
    "ightUnknown.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-24aa2ddb7623'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 62] [~ 188] ~]
      options
  ==
::
::  coverage-id: model-2f0d1c70e3b7
::
++  test-tlc-mcreachabilitytestrandomgraphs-1c70e3b7
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/MCReachabilityT".
    "est.tla"
  =/  model
    %-  crip
    "specifications/MisraReachability/MCReachabilityT".
    "estRandomGraphs.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-2f0d1c70e3b7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-329ae53b86ef
::
++  test-tlc-abcorrectness-e53b86ef
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/ABCorrectne".
    "ss.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/TLC/ABCorrectne".
    "ss.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-329ae53b86ef'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 20] [~ 36] ~]
      options
  ==
::
::  coverage-id: model-34c6d3f5d26c
::
++  test-tlc-mcreachabilitytestallgraphs-d3f5d26c
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module
    %-  crip
    "specifications/MisraReachability/MCReachabilityT".
    "est.tla"
  =/  model
    %-  crip
    "specifications/MisraReachability/MCReachabilityT".
    "estAllGraphs.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-34c6d3f5d26c'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:20'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-357d7ba28f93
::
++  test-tlc-allocatorrefinement-7ba28f93
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module  (crip "specifications/allocator/AllocatorRefinement.tla")
  =/  model  (crip "specifications/allocator/AllocatorRefinement.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-357d7ba28f93'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 1.690] [~ 5.854] ~]
      options
  ==
::
::  coverage-id: model-36b3496d8609
::
++  test-tlc-product-496d8609
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/product.tla")
  =/  model  (crip "specifications/glowingRaccoon/product.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-36b3496d8609'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 305] [~ 376] ~]
      options
  ==
::
::  coverage-id: model-38623f8d5c7e
::
++  test-tlc-prisonersolo-3f8d5c7e
  =/  manifest
    %-  crip
    "specifications/Prisoners_Single_Switch/manifest.".
    "json"
  =/  module
    %-  crip
    "specifications/Prisoners_Single_Switch/Prisoner.".
    "tla"
  =/  model
    %-  crip
    "specifications/Prisoners_Single_Switch/PrisonerS".
    "olo.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-38623f8d5c7e'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 2] [~ 3] ~]
      options
  ==
::
::  coverage-id: model-391b0b136950
::
++  test-tlc-testgraphs-0b136950
  =/  manifest  (crip "specifications/TLC/manifest.json")
  =/  module  (crip "specifications/TLC/TestGraphs.tla")
  =/  model  (crip "specifications/TLC/TestGraphs.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-391b0b136950'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 2.590] [~ 2.790] ~]
      options
  ==
::
::  coverage-id: model-3ab242daafb2
::
++  test-tlc-cigarettesmokers-42daafb2
  =/  manifest  (crip "specifications/CigaretteSmokers/manifest.json")
  =/  module
    %-  crip
    "specifications/CigaretteSmokers/CigaretteSmokers".
    ".tla"
  =/  model
    %-  crip
    "specifications/CigaretteSmokers/CigaretteSmokers".
    ".cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3ab242daafb2'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 6] [~ 15] ~]
      options
  ==
::
::  coverage-id: model-3b49a2426dc4
::
++  test-tlc-asynchinterface-a2426dc4
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/AsynchInterface.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/AsynchInterface.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3b49a2426dc4'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 12] [~ 30] ~]
      options
  ==
::
::  coverage-id: model-3c5233e5db11
::
++  test-tlc-mcliveinternalmemory-33e5db11
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/MCLive".
    "InternalMemory.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/Liveness/MCLive".
    "InternalMemory.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3c5233e5db11'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.408] [~ 21.400] ~]
      options
  ==
::
::  coverage-id: model-3d05e18788f8
::
++  test-tlc-barriers-e18788f8
  =/  manifest  (crip "specifications/barriers/manifest.json")
  =/  module  (crip "specifications/barriers/Barriers.tla")
  =/  model  (crip "specifications/barriers/Barriers.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3d05e18788f8'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 29.279] [~ 104.515] ~]
      options
  ==
::
::  coverage-id: model-3f771f0bd3b4
::
++  test-tlc-ewd840-json-1f0bd3b4
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/EWD840_json.tla")
  =/  model  (crip "specifications/ewd840/EWD840_json.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3f771f0bd3b4'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 1.566] [~ 15.986] ~]
      options
  ==
::
::  coverage-id: model-44f6594f8070
::
++  test-tlc-elevatorsafetysmall-594f8070
  =/  manifest  (crip "specifications/MultiCarElevator/manifest.json")
  =/  module  (crip "specifications/MultiCarElevator/Elevator.tla")
  =/  model
    %-  crip
    "specifications/MultiCarElevator/ElevatorSafetySm".
    "all.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-44f6594f8070'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:15'
      %.y
      [~ [~ 4.122] [~ 14.296] ~]
      options
  ==
::
::  coverage-id: model-46fc83530270
::
++  test-tlc-mcparreach-83530270
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/MCParReach.tla")
  =/  model  (crip "specifications/MisraReachability/MCParReach.cfg")
  =/  options
    :*  %auto
        90
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-46fc83530270'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:30'
      %.y
      [~ [~ 393] [~ 747] ~]
      options
  ==
::
::  coverage-id: model-4c1b5d4f6484
::
++  test-tlc-fastpaxos-5d4f6484
  =/  manifest  (crip "specifications/SimplifiedFastPaxos/manifest.json")
  =/  module  (crip "specifications/SimplifiedFastPaxos/FastPaxos.tla")
  =/  model  (crip "specifications/SimplifiedFastPaxos/FastPaxos.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4c1b5d4f6484'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:20'
      %.y
      [~ [~ 25.617] [~ 320.053] ~]
      options
  ==
::
::  coverage-id: model-4d70609a383d
::
++  test-tlc-mcinnersequential-609a383d
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/MCInnerSequential.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/AdvancedExample".
    "s/MCInnerSequential.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4d70609a383d'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 3.528] [~ 24.368] ~]
      options
  ==
::
::  coverage-id: model-4fb33979ae12
::
++  test-tlc-nbacg-guer01-3979ae12
  =/  manifest  (crip "specifications/nbacg_guer01/manifest.json")
  =/  module  (crip "specifications/nbacg_guer01/nbacg_guer01.tla")
  =/  model  (crip "specifications/nbacg_guer01/nbacg_guer01.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4fb33979ae12'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 24.922] [~ 159.538] ~]
      options
  ==
::
::  coverage-id: model-503ec7b87ad9
::
++  test-tlc-tcommit-c7b87ad9
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/TCommit.tla")
  =/  model  (crip "specifications/transaction_commit/TCommit.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-503ec7b87ad9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 34] [~ 94] ~]
      options
  ==
::
::  coverage-id: model-522a435170a1
::
++  test-tlc-asyncterminationdetection-435170a1
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd998/AsyncTerminationDetection.".
    "tla"
  =/  model
    %-  crip
    "specifications/ewd998/AsyncTerminationDetection.".
    "cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-522a435170a1'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.097] [~ 53.271] ~]
      options
  ==
::
::  coverage-id: model-57f643236cb5
::
++  test-tlc-mcpaxos-43236cb5
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/MCPaxos.tla")
  =/  model  (crip "specifications/Paxos/MCPaxos.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-57f643236cb5'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 25] [~ 82] ~]
      options
  ==
::
::  coverage-id: model-5c970f3450d9
::
++  test-tlc-mcbakery-0f3450d9
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module  (crip "specifications/Bakery-Boulangerie/MCBakery.tla")
  =/  model  (crip "specifications/Bakery-Boulangerie/MCBakery.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-5c970f3450d9'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 655.200] [~ 3.403.584] ~]
      options
  ==
::
::  coverage-id: model-5de8e73e259d
::
++  test-tlc-syncterminationdetection-e73e259d
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd840/SyncTerminationDetection.t".
    "la"
  =/  model
    %-  crip
    "specifications/ewd840/SyncTerminationDetection.c".
    "fg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-5de8e73e259d'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 129] [~ 3.722] ~]
      options
  ==
::
::  coverage-id: model-5ef98c43339d
::
++  test-tlc-spantree-8c43339d
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/SpanTree.tla")
  =/  model  (crip "specifications/SpanningTree/SpanTree.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-5ef98c43339d'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 1.236] [~ 10.278] ~]
      options
  ==
::
::  coverage-id: model-601991bc096b
::
++  test-tlc-vouchercancel-91bc096b
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherCancel.tla")
  =/  model  (crip "specifications/byihive/VoucherCancel.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-601991bc096b'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.199] [~ 26.848] ~]
      options
  ==
::
::  coverage-id: model-61c58aee78d8
::
++  test-tlc-2pcwithbtm-8aee78d8
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/2PCwithBTM.tla")
  =/  model  (crip "specifications/transaction_commit/2PCwithBTM.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-61c58aee78d8'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 1.245] [~ 5.841] ~]
      options
  ==
::
::  coverage-id: model-62015d615100
::
++  test-tlc-peterson-5d615100
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module  (crip "specifications/locks_auxiliary_vars/Peterson.tla")
  =/  model  (crip "specifications/locks_auxiliary_vars/Peterson.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-62015d615100'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 42] [~ 77] ~]
      options
  ==
::
::  coverage-id: model-62b838782fbb
::
++  test-tlc-mcconsensus-38782fbb
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/MCConsensus.tla")
  =/  model  (crip "specifications/Paxos/MCConsensus.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-62b838782fbb'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4] [~ 7] ~]
      options
  ==
::
::  coverage-id: model-67773fac7928
::
++  test-tlc-mcnanosmall-3fac7928
  =/  manifest  (crip "specifications/NanoBlockchain/manifest.json")
  =/  module  (crip "specifications/NanoBlockchain/MCNano.tla")
  =/  model  (crip "specifications/NanoBlockchain/MCNanoSmall.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-67773fac7928'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 3.003] [~ 6.083] ~]
      options
  ==
::
::  coverage-id: model-69c661040ff2
::
++  test-tlc-mcpaxostiny-61040ff2
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
    "Tiny.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-69c661040ff2'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 3.921] [~ 23.563] ~]
      options
  ==
::
::  coverage-id: model-6b39e75d0205
::
++  test-tlc-mcquicksort-e75d0205
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/MCQuicksort.tla")
  =/  model  (crip "specifications/LoopInvariance/MCQuicksort.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-6b39e75d0205'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 4.548] [~ 11.223] ~]
      options
  ==
::
::  coverage-id: model-6cb63993ee01
::
++  test-tlc-twophase-3993ee01
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/TwoPhase.tla")
  =/  model  (crip "specifications/transaction_commit/TwoPhase.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-6cb63993ee01'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 288] [~ 1.146] ~]
      options
  ==
::
::  coverage-id: model-71f7bdc522cd
::
++  test-tlc-tokenring-bdc522cd
  =/  manifest  (crip "specifications/ewd426/manifest.json")
  =/  module  (crip "specifications/ewd426/TokenRing.tla")
  =/  model  (crip "specifications/ewd426/TokenRing.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-71f7bdc522cd'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 46.656] [~ 248.832] ~]
      options
  ==
::
::  coverage-id: model-732debd9f4fe
::
++  test-tlc-clean-ebd9f4fe
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/clean.tla")
  =/  model  (crip "specifications/glowingRaccoon/clean.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-732debd9f4fe'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 63] [~ 99] ~]
      options
  ==
::
::  coverage-id: model-737258a6492b
::
++  test-tlc-simple-58a6492b
  =/  manifest  (crip "specifications/TeachingConcurrency/manifest.json")
  =/  module  (crip "specifications/TeachingConcurrency/Simple.tla")
  =/  model  (crip "specifications/TeachingConcurrency/Simple.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-737258a6492b'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 723] [~ 1.842] ~]
      options
  ==
::
::  coverage-id: model-74114d86e108
::
++  test-tlc-vouchertransfer-4d86e108
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherTransfer.tla")
  =/  model  (crip "specifications/byihive/VoucherTransfer.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-74114d86e108'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.197] [~ 26.848] ~]
      options
  ==
::
::  coverage-id: model-795d48fc861a
::
++  test-tlc-bcastbyz-48fc861a
  =/  manifest  (crip "specifications/bcastByz/manifest.json")
  =/  module  (crip "specifications/bcastByz/bcastByz.tla")
  =/  model  (crip "specifications/bcastByz/bcastByz.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-795d48fc861a'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 14.424] [~ 227.344] ~]
      options
  ==
::
::  coverage-id: model-7e556fe924e1
::
++  test-tlc-voucherredeem-6fe924e1
  =/  manifest  (crip "specifications/byihive/manifest.json")
  =/  module  (crip "specifications/byihive/VoucherRedeem.tla")
  =/  model  (crip "specifications/byihive/VoucherRedeem.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-7e556fe924e1'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.199] [~ 26.848] ~]
      options
  ==
::
::  coverage-id: model-7f25f5dd28be
::
++  test-tlc-lock-f5dd28be
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module  (crip "specifications/locks_auxiliary_vars/Lock.tla")
  =/  model  (crip "specifications/locks_auxiliary_vars/Lock.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-7f25f5dd28be'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 12] [~ 21] ~]
      options
  ==
::
::  coverage-id: model-828414407401
::
++  test-tlc-livehourclock-14407401
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/LiveHo".
    "urClock.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/Liveness/LiveHo".
    "urClock.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-828414407401'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 12] [~ 24] ~]
      options
  ==
::
::  coverage-id: model-83cd941eca2e
::
++  test-tlc-prisonersololightunknown-941eca2e
  =/  manifest
    %-  crip
    "specifications/Prisoners_Single_Switch/manifest.".
    "json"
  =/  module
    %-  crip
    "specifications/Prisoners_Single_Switch/Prisoner.".
    "tla"
  =/  model
    %-  crip
    "specifications/Prisoners_Single_Switch/PrisonerS".
    "oloLightUnknown.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-83cd941eca2e'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4] [~ 6] ~]
      options
  ==
::
::  coverage-id: model-83e22d8b20ff
::
++  test-tlc-prisoner-2d8b20ff
  =/  manifest
    %-  crip
    "specifications/Prisoners_Single_Switch/manifest.".
    "json"
  =/  module
    %-  crip
    "specifications/Prisoners_Single_Switch/Prisoner.".
    "tla"
  =/  model
    %-  crip
    "specifications/Prisoners_Single_Switch/Prisoner.".
    "cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-83e22d8b20ff'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 16] [~ 49] ~]
      options
  ==
::
::  coverage-id: model-8534603ce583
::
++  test-tlc-mcleastcircularsubstringsmall-603ce583
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
    "cularSubstringSmall.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-8534603ce583'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 8.554] [~ 8.681] ~]
      options
  ==
::
::  coverage-id: model-883eb99c38df
::
++  test-tlc-ewd998chanid-b99c38df
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998ChanID.tla")
  =/  model  (crip "specifications/ewd998/EWD998ChanID.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-883eb99c38df'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 14] [~ 15] ~]
      options
  ==
::
::  coverage-id: model-8c114922d38f
::
++  test-tlc-voteproof-4922d38f
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/VoteProof.tla")
  =/  model  (crip "specifications/byzpaxos/VoteProof.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-8c114922d38f'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 6.962] [~ 318.877] ~]
      options
  ==
::
::  coverage-id: model-906e0b9f76eb
::
++  test-tlc-ewd840-0b9f76eb
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/EWD840.tla")
  =/  model  (crip "specifications/ewd840/EWD840.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-906e0b9f76eb'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 302] [~ 2.001] ~]
      options
  ==
::
::  coverage-id: model-946988c767fe
::
++  test-tlc-mc-88c767fe
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_2/MC.tla"
  =/  model
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_2/MC.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-946988c767fe'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-959f749e8962
::
++  test-tlc-mc-sums-even-749e8962
  =/  manifest  (crip "specifications/sums_even/manifest.json")
  =/  module  (crip "specifications/sums_even/MC_sums_even.tla")
  =/  model  (crip "specifications/sums_even/MC_sums_even.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-959f749e8962'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-99a21ee3f151
::
++  test-tlc-consensus-1ee3f151
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/Consensus.tla")
  =/  model  (crip "specifications/byzpaxos/Consensus.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-99a21ee3f151'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4] [~ 4] ~]
      options
  ==
::
::  coverage-id: model-99f5b2eb3545
::
++  test-tlc-mcvoting-b2eb3545
  =/  manifest
    %-  crip
    "specifications/PaxosHowToWinATuringAward/manifes".
    "t.json"
  =/  module
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCVotin".
    "g.tla"
  =/  model
    %-  crip
    "specifications/PaxosHowToWinATuringAward/MCVotin".
    "g.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-99f5b2eb3545'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 6.752] [~ 41.017] ~]
      options
  ==
::
::  coverage-id: model-adad5884f179
::
++  test-tlc-coffeecan100beans-5884f179
  =/  manifest  (crip "specifications/CoffeeCan/manifest.json")
  =/  module  (crip "specifications/CoffeeCan/CoffeeCan.tla")
  =/  model  (crip "specifications/CoffeeCan/CoffeeCan100Beans.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-adad5884f179'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 5.150] [~ 20.002] ~]
      options
  ==
::
::  coverage-id: model-aec13b3a93a7
::
++  test-tlc-catoddboxes-3b3a93a7
  =/  manifest  (crip "specifications/Moving_Cat_Puzzle/manifest.json")
  =/  module  (crip "specifications/Moving_Cat_Puzzle/Cat.tla")
  =/  model  (crip "specifications/Moving_Cat_Puzzle/CatOddBoxes.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-aec13b3a93a7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 30] [~ 78] ~]
      options
  ==
::
::  coverage-id: model-af53f57851a7
::
++  test-tlc-mclivewritethroughcache-f57851a7
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/MCLive".
    "WriteThroughCache.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/Liveness/MCLive".
    "WriteThroughCache.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-af53f57851a7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 5.196] [~ 28.170] ~]
      options
  ==
::
::  coverage-id: model-b7111229f2ee
::
++  test-tlc-mcalternatingbit-1229f2ee
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/TLC/MCAlternati".
    "ngBit.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/TLC/MCAlternati".
    "ngBit.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-b7111229f2ee'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 240] [~ 1.392] ~]
      options
  ==
::
::  coverage-id: model-b7deb902fe50
::
++  test-tlc-ewd998chantrace-b902fe50
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998ChanTrace.tla")
  =/  model  (crip "specifications/ewd998/EWD998ChanTrace.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-b7deb902fe50'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-bd71f2116b65
::
++  test-tlc-acp-nb-tlc-f2116b65
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_NB_TLC.tla")
  =/  model  (crip "specifications/acp/ACP_NB_TLC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-bd71f2116b65'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.284] [~ 23.988] ~]
      options
  ==
::
::  coverage-id: model-c03ced77dd57
::
++  test-tlc-prisoners-ed77dd57
  =/  manifest  (crip "specifications/Prisoners/manifest.json")
  =/  module  (crip "specifications/Prisoners/Prisoners.tla")
  =/  model  (crip "specifications/Prisoners/Prisoners.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c03ced77dd57'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 214] [~ 860] ~]
      options
  ==
::
::  coverage-id: model-c1d0c945230f
::
++  test-tlc-blockdagtest-c945230f
  =/  manifest  (crip "specifications/dag-consensus/manifest.json")
  =/  module  (crip "specifications/dag-consensus/BlockDagTest.tla")
  =/  model  (crip "specifications/dag-consensus/BlockDagTest.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c1d0c945230f'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-c4679752575a
::
++  test-tlc-simpleregular-9752575a
  =/  manifest  (crip "specifications/TeachingConcurrency/manifest.json")
  =/  module
    %-  crip
    "specifications/TeachingConcurrency/SimpleRegular".
    ".tla"
  =/  model
    %-  crip
    "specifications/TeachingConcurrency/SimpleRegular".
    ".cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c4679752575a'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 277.726] [~ 1.454.776] ~]
      options
  ==
::
::  coverage-id: model-c5d28caafda3
::
++  test-tlc-nbacc-ray97-8caafda3
  =/  manifest  (crip "specifications/nbacc_ray97/manifest.json")
  =/  module  (crip "specifications/nbacc_ray97/nbacc_ray97.tla")
  =/  model  (crip "specifications/nbacc_ray97/nbacc_ray97.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c5d28caafda3'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 3.016] [~ 49.592] ~]
      options
  ==
::
::  coverage-id: model-c5f0f798869e
::
++  test-tlc-mcnanomedium-f798869e
  =/  manifest  (crip "specifications/NanoBlockchain/manifest.json")
  =/  module  (crip "specifications/NanoBlockchain/MCNano.tla")
  =/  model  (crip "specifications/NanoBlockchain/MCNanoMedium.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c5f0f798869e'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:15'
      %.y
      [~ [~ 530.587] [~ 1.120.079] ~]
      options
  ==
::
::  coverage-id: model-c7236f5aa8e3
::
++  test-tlc-barrier-6f5aa8e3
  =/  manifest  (crip "specifications/barriers/manifest.json")
  =/  module  (crip "specifications/barriers/Barrier.tla")
  =/  model  (crip "specifications/barriers/Barrier.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c7236f5aa8e3'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 64] [~ 194] ~]
      options
  ==
::
::  coverage-id: model-c730062d3baa
::
++  test-tlc-mcvoting-062d3baa
  =/  manifest  (crip "specifications/Paxos/manifest.json")
  =/  module  (crip "specifications/Paxos/MCVoting.tla")
  =/  model  (crip "specifications/Paxos/MCVoting.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c730062d3baa'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 77] [~ 451] ~]
      options
  ==
::
::  coverage-id: model-cbf443f471ab
::
++  test-tlc-mcinternalmemory-43f471ab
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "CInternalMemory.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/CachingMemory/M".
    "CInternalMemory.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-cbf443f471ab'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4.408] [~ 21.400] ~]
      options
  ==
::
::  coverage-id: model-d16bbccdba76
::
++  test-tlc-slushsmall-bccdba76
  =/  manifest  (crip "specifications/SlushProtocol/manifest.json")
  =/  module  (crip "specifications/SlushProtocol/Slush.tla")
  =/  model  (crip "specifications/SlushProtocol/SlushSmall.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-d16bbccdba76'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:15'
      %.y
      [~ [~ 274.678] [~ 1.621.541] ~]
      options
  ==
::
::  coverage-id: model-d374a244e85d
::
++  test-tlc-simplemath-a244e85d
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/SimpleMath/Simp".
    "leMath.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/SimpleMath/Simp".
    "leMath.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-d374a244e85d'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-d65d295eafcb
::
++  test-tlc-channel-295eafcb
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/Channel.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/Channel.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-d65d295eafcb'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 12] [~ 30] ~]
      options
  ==
::
::  coverage-id: model-d8d55fa93314
::
++  test-tlc-multipaxos-mc-small-5fa93314
  =/  manifest  (crip "specifications/MultiPaxos-SMR/manifest.json")
  =/  module  (crip "specifications/MultiPaxos-SMR/MultiPaxos_MC.tla")
  =/  model
    %-  crip
    "specifications/MultiPaxos-SMR/MultiPaxos_MC_smal".
    "l.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-d8d55fa93314'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 343.796] [~ 736.012] ~]
      options
  ==
::
::  coverage-id: model-d92872ffe580
::
++  test-tlc-mcchangroberts-72ffe580
  =/  manifest  (crip "specifications/chang_roberts/manifest.json")
  =/  module  (crip "specifications/chang_roberts/MCChangRoberts.tla")
  =/  model  (crip "specifications/chang_roberts/MCChangRoberts.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-d92872ffe580'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 137] [~ 227] ~]
      options
  ==
::
::  coverage-id: model-db4756f049cd
::
++  test-tlc-mc-56f049cd
  =/  manifest  (crip "specifications/CarTalkPuzzle/manifest.json")
  =/  module
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_1/MC.tla"
  =/  model
    %-  crip
    "specifications/CarTalkPuzzle/CarTalkPuzzle.toolb".
    "ox/Model_1/MC.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-db4756f049cd'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-dbaeab68bb35
::
++  test-tlc-gameoflife-ab68bb35
  =/  manifest  (crip "specifications/GameOfLife/manifest.json")
  =/  module  (crip "specifications/GameOfLife/GameOfLife.tla")
  =/  model  (crip "specifications/GameOfLife/GameOfLife.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-dbaeab68bb35'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 65.536] [~ 131.072] ~]
      options
  ==
::
::  coverage-id: model-dcd78a126ea0
::
++  test-tlc-mctwophase-8a126ea0
  =/  manifest  (crip "specifications/TwoPhase/manifest.json")
  =/  module  (crip "specifications/TwoPhase/MCTwoPhase.tla")
  =/  model  (crip "specifications/TwoPhase/MCTwoPhase.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-dcd78a126ea0'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 4] [~ 5] ~]
      options
  ==
::
::  coverage-id: model-dcdf4f75c1a7
::
++  test-tlc-disruptor-mpmc-liveliness-4f75c1a7
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/Disruptor_MPMC.tla")
  =/  model
    %-  crip
    "specifications/Disruptor/Disruptor_MPMC_liveline".
    "ss.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-dcdf4f75c1a7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 14.365] [~ 44.581] ~]
      options
  ==
::
::  coverage-id: model-ddf2cd066153
::
++  test-tlc-mc-cd066153
  =/  manifest  (crip "specifications/ReadersWriters/manifest.json")
  =/  module  (crip "specifications/ReadersWriters/MC.tla")
  =/  model  (crip "specifications/ReadersWriters/MC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-ddf2cd066153'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 21.527] [~ 59.674] ~]
      options
  ==
::
::  coverage-id: model-e3cad5dafe97
::
++  test-tlc-mcyoyopruning-d5dafe97
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/MCYoYoPruning.tla")
  =/  model  (crip "specifications/YoYo/MCYoYoPruning.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e3cad5dafe97'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 102] [~ 157] ~]
      options
  ==
::
::  coverage-id: model-e40decf7599c
::
++  test-tlc-mctcp-ecf7599c
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/MCtcp.tla")
  =/  model  (crip "specifications/tcp/MCtcp.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e40decf7599c'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 1.182] [~ 6.322] ~]
      options
  ==
::
::  coverage-id: model-e5756c338a03
::
++  test-tlc-spantreerandom-6c338a03
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/SpanTreeRandom.tla")
  =/  model  (crip "specifications/SpanningTree/SpanTreeRandom.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e5756c338a03'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-e63aaad35eea
::
++  test-tlc-chameneos-aad35eea
  =/  manifest  (crip "specifications/Chameneos/manifest.json")
  =/  module  (crip "specifications/Chameneos/Chameneos.tla")
  =/  model  (crip "specifications/Chameneos/Chameneos.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e63aaad35eea'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 34.534] [~ 104.697] ~]
      options
  ==
::
::  coverage-id: model-e7771d07b0cd
::
++  test-tlc-elevatorlivenessmedium-1d07b0cd
  =/  manifest  (crip "specifications/MultiCarElevator/manifest.json")
  =/  module  (crip "specifications/MultiCarElevator/Elevator.tla")
  =/  model
    %-  crip
    "specifications/MultiCarElevator/ElevatorLiveness".
    "Medium.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e7771d07b0cd'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 4.122] [~ 14.296] ~]
      options
  ==
::
::  coverage-id: model-e7f918b6a387
::
++  test-tlc-hourclock2-18b6a387
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/HourC".
    "lock2.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/HourClock/HourC".
    "lock2.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e7f918b6a387'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 12] [~ 24] ~]
      options
  ==
::
::  coverage-id: model-e8d108d57dd1
::
++  test-tlc-allocatorimplementation-08d57dd1
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module
    %-  crip
    "specifications/allocator/AllocatorImplementation".
    ".tla"
  =/  model
    %-  crip
    "specifications/allocator/AllocatorImplementation".
    ".cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e8d108d57dd1'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:15'
      %.y
      [~ [~ 17.701] [~ 64.414] ~]
      options
  ==
::
::  coverage-id: model-eb87b4da3ad7
::
++  test-tlc-disruptor-mpmc-b4da3ad7
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/Disruptor_MPMC.tla")
  =/  model  (crip "specifications/Disruptor/Disruptor_MPMC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-eb87b4da3ad7'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 112.929] [~ 422.781] ~]
      options
  ==
::
::  coverage-id: model-ed3da665facf
::
++  test-tlc-disruptor-spmc-a665facf
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/Disruptor_SPMC.tla")
  =/  model  (crip "specifications/Disruptor/Disruptor_SPMC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-ed3da665facf'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 8.496] [~ 28.049] ~]
      options
  ==
::
::  coverage-id: model-f0d0504ef2ff
::
++  test-tlc-transitiveclosure-504ef2ff
  =/  manifest  (crip "specifications/TransitiveClosure/manifest.json")
  =/  module
    %-  crip
    "specifications/TransitiveClosure/TransitiveClosu".
    "re.tla"
  =/  model
    %-  crip
    "specifications/TransitiveClosure/TransitiveClosu".
    "re.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f0d0504ef2ff'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-f40f19346b56
::
++  test-tlc-mcinnerfifo-19346b56
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/MCInnerFIF".
    "O.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/FIFO/MCInnerFIF".
    "O.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f40f19346b56'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 3.864] [~ 9.660] ~]
      options
  ==
::
::  coverage-id: model-f48bc4394eae
::
++  test-tlc-mc-c4394eae
  =/  manifest  (crip "specifications/SingleLaneBridge/manifest.json")
  =/  module  (crip "specifications/SingleLaneBridge/MC.tla")
  =/  model  (crip "specifications/SingleLaneBridge/MC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f48bc4394eae'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 3.605] [~ 20.181] ~]
      options
  ==
::
::  coverage-id: model-f54b5f993561
::
++  test-tlc-bufferedrandomaccessfile-5f993561
  =/  manifest  (crip "specifications/braf/manifest.json")
  =/  module  (crip "specifications/braf/BufferedRandomAccessFile.tla")
  =/  model  (crip "specifications/braf/BufferedRandomAccessFile.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f54b5f993561'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:09'
      %.y
      [~ [~ 3.316] [~ 128.581] ~]
      options
  ==
::
::  coverage-id: model-f60b96e23377
::
++  test-tlc-yoyoallgraphs-96e23377
  =/  manifest  (crip "specifications/YoYo/manifest.json")
  =/  module  (crip "specifications/YoYo/YoYoAllGraphs.tla")
  =/  model  (crip "specifications/YoYo/YoYoAllGraphs.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f60b96e23377'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:02'
      %.y
      [~ [~ 26.731] [~ 48.535] ~]
      options
  ==
::
::  coverage-id: model-f67196759408
::
++  test-tlc-mclamportmutex-96759408
  =/  manifest  (crip "specifications/lamport_mutex/manifest.json")
  =/  module  (crip "specifications/lamport_mutex/MCLamportMutex.tla")
  =/  model  (crip "specifications/lamport_mutex/MCLamportMutex.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f67196759408'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 724.274] [~ 2.729.079] ~]
      options
  ==
::
::  coverage-id: model-f738aa147aea
::
++  test-tlc-mcbinarysearch-aa147aea
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/MCBinarySearch.tla")
  =/  model  (crip "specifications/LoopInvariance/MCBinarySearch.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f738aa147aea'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 27.953] [~ 34.383] ~]
      options
  ==
::
::  coverage-id: model-f867afe91bc1
::
++  test-tlc-stones-afe91bc1
  =/  manifest  (crip "specifications/Stones/manifest.json")
  =/  module  (crip "specifications/Stones/Stones.tla")
  =/  model  (crip "specifications/Stones/Stones.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f867afe91bc1'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 0] [~ 0] ~]
      options
  ==
::
::  coverage-id: model-fa3107cc70e0
::
++  test-tlc-acp-sb-tlc-07cc70e0
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/ACP_SB_TLC.tla")
  =/  model  (crip "specifications/acp/ACP_SB_TLC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-fa3107cc70e0'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 54.944] [~ 218.352] ~]
      options
  ==
::
::  coverage-id: model-fb42db0774c1
::
++  test-tlc-simpleallocator-db0774c1
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module  (crip "specifications/allocator/SimpleAllocator.tla")
  =/  model  (crip "specifications/allocator/SimpleAllocator.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-fb42db0774c1'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:05'
      %.y
      [~ [~ 400] [~ 1.633] ~]
      options
  ==
::
::  coverage-id: model-fb772cb48048
::
++  test-tlc-stages-2cb48048
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/stages.tla")
  =/  model  (crip "specifications/glowingRaccoon/stages.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-fb772cb48048'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:01'
      %.y
      [~ [~ 83] [~ 93] ~]
      options
  ==
::
::  coverage-id: model-fcbfee94b55f
::
++  test-tlc-schedulingallocator-ee94b55f
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module  (crip "specifications/allocator/SchedulingAllocator.tla")
  =/  model  (crip "specifications/allocator/SchedulingAllocator.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-fcbfee94b55f'
      manifest
      module
      model
      %tlc
      [%exhaustive ~]
      %success
      '00:00:10'
      %.y
      [~ [~ 1.690] [~ 5.854] ~]
      options
  ==
--
