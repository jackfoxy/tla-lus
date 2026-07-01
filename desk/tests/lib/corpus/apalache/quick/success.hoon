/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: model-05c30549c03e
::
++  test-apalache-aplivehourclock-0549c03e
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/APLive".
    "HourClock.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/Liveness/APLive".
    "HourClock.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-05c30549c03e'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-1885aca3610f
::
++  test-apalache-apcigarettesmokers-aca3610f
  =/  manifest  (crip "specifications/CigaretteSmokers/manifest.json")
  =/  module
    %-  crip
    "specifications/CigaretteSmokers/APCigaretteSmoke".
    "rs.tla"
  =/  model
    %-  crip
    "specifications/CigaretteSmokers/APCigaretteSmoke".
    "rs.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-1885aca3610f'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-2c997566104f
::
++  test-apalache-apewd840-7566104f
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module  (crip "specifications/ewd840/APEWD840.tla")
  =/  model  (crip "specifications/ewd840/APEWD840.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-2c997566104f'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-318a9d7378a3
::
++  test-apalache-apparreach-9d7378a3
  =/  manifest  (crip "specifications/MisraReachability/manifest.json")
  =/  module  (crip "specifications/MisraReachability/APParReach.tla")
  =/  model  (crip "specifications/MisraReachability/APParReach.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-318a9d7378a3'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-382c3bc6dfc7
::
++  test-apalache-apbcastfolklore-3bc6dfc7
  =/  manifest  (crip "specifications/bcastFolklore/manifest.json")
  =/  module  (crip "specifications/bcastFolklore/APbcastFolklore.tla")
  =/  model  (crip "specifications/bcastFolklore/APbcastFolklore.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-382c3bc6dfc7'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-3f8986c3f759
::
++  test-apalache-apdiningphilosophers-86c3f759
  =/  manifest  (crip "specifications/DiningPhilosophers/manifest.json")
  =/  module
    %-  crip
    "specifications/DiningPhilosophers/APDiningPhilos".
    "ophers.tla"
  =/  model
    %-  crip
    "specifications/DiningPhilosophers/APDiningPhilos".
    "ophers.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3f8986c3f759'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-3fc53fbeb663
::
++  test-apalache-apbarrier-3fbeb663
  =/  manifest  (crip "specifications/barriers/manifest.json")
  =/  module  (crip "specifications/barriers/APBarrier.tla")
  =/  model  (crip "specifications/barriers/APBarrier.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-3fc53fbeb663'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-42117b6c66c3
::
++  test-apalache-aptokenring-7b6c66c3
  =/  manifest  (crip "specifications/ewd426/manifest.json")
  =/  module  (crip "specifications/ewd426/APTokenRing.tla")
  =/  model  (crip "specifications/ewd426/APTokenRing.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-42117b6c66c3'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-460e07cbb6b9
::
++  test-apalache-apsyncterminationdetection-07cbb6b9
  =/  manifest  (crip "specifications/ewd840/manifest.json")
  =/  module
    %-  crip
    "specifications/ewd840/APSyncTerminationDetection".
    ".tla"
  =/  model
    %-  crip
    "specifications/ewd840/APSyncTerminationDetection".
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
  :*  'model-460e07cbb6b9'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-4ec3f884d1b1
::
++  test-apalache-apdieharder-f884d1b1
  =/  manifest  (crip "specifications/DieHard/manifest.json")
  =/  module  (crip "specifications/DieHard/APDieHarder.tla")
  =/  model  (crip "specifications/DieHard/APDieHarder.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-4ec3f884d1b1'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-54c56ca1f4c0
::
++  test-apalache-aptcp-6ca1f4c0
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/APtcp.tla")
  =/  model  (crip "specifications/tcp/APtcp.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-54c56ca1f4c0'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-58221e6bcdbf
::
++  test-apalache-aplamportmutex-1e6bcdbf
  =/  manifest  (crip "specifications/lamport_mutex/manifest.json")
  =/  module  (crip "specifications/lamport_mutex/APLamportMutex.tla")
  =/  model  (crip "specifications/lamport_mutex/APLamportMutex.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-58221e6bcdbf'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-5a7d8f55776b
::
++  test-apalache-apchannel-8f55776b
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APChannel.".
    "tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APChannel.".
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
  :*  'model-5a7d8f55776b'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-5e7a2dd40788
::
++  test-apalache-apcoffeecan-2dd40788
  =/  manifest  (crip "specifications/CoffeeCan/manifest.json")
  =/  module  (crip "specifications/CoffeeCan/APCoffeeCan.tla")
  =/  model  (crip "specifications/CoffeeCan/APCoffeeCan.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-5e7a2dd40788'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-63c51107222c
::
++  test-apalache-apcrdt-1107222c
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module  (crip "specifications/FiniteMonotonic/APCRDT.tla")
  =/  model  (crip "specifications/FiniteMonotonic/APCRDT.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-63c51107222c'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-6a512f3cf498
::
++  test-apalache-apbosco-2f3cf498
  =/  manifest  (crip "specifications/bosco/manifest.json")
  =/  module  (crip "specifications/bosco/APbosco.tla")
  =/  model  (crip "specifications/bosco/APbosco.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-6a512f3cf498'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-6b02f3d0ede4
::
++  test-apalache-apchangroberts-f3d0ede4
  =/  manifest  (crip "specifications/chang_roberts/manifest.json")
  =/  module  (crip "specifications/chang_roberts/APChangRoberts.tla")
  =/  model  (crip "specifications/chang_roberts/APChangRoberts.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-6b02f3d0ede4'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-6d3552cfd9d7
::
++  test-apalache-apacp-sb-52cfd9d7
  =/  manifest  (crip "specifications/acp/manifest.json")
  =/  module  (crip "specifications/acp/APACP_SB.tla")
  =/  model  (crip "specifications/acp/APACP_SB.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-6d3552cfd9d7'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:10'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-732eae394473
::
++  test-apalache-apinnerfifo-ae394473
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APInnerFIF".
    "O.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APInnerFIF".
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
  :*  'model-732eae394473'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-738d107d4429
::
++  test-apalache-aptcommit-107d4429
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module  (crip "specifications/transaction_commit/APTCommit.tla")
  =/  model  (crip "specifications/transaction_commit/APTCommit.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-738d107d4429'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-78e456422cf1
::
++  test-apalache-apnbacg-guer01-56422cf1
  =/  manifest  (crip "specifications/nbacg_guer01/manifest.json")
  =/  module  (crip "specifications/nbacg_guer01/APnbacg_guer01.tla")
  =/  model  (crip "specifications/nbacg_guer01/APnbacg_guer01.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-78e456422cf1'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-7a13fc776a50
::
++  test-apalache-apclean-fc776a50
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/APclean.tla")
  =/  model  (crip "specifications/glowingRaccoon/APclean.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-7a13fc776a50'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-8b4f3df65f2f
::
++  test-apalache-aphourclock-3df65f2f
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/APHou".
    "rClock.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/Composing/APHou".
    "rClock.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-8b4f3df65f2f'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-9afc77d07b9c
::
++  test-apalache-apmcinnerfifo-77d07b9c
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APMCInnerF".
    "IFO.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APMCInnerF".
    "IFO.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-9afc77d07b9c'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-9fcefd52cc89
::
++  test-apalache-apreaderswriters-fd52cc89
  =/  manifest  (crip "specifications/ReadersWriters/manifest.json")
  =/  module
    %-  crip
    "specifications/ReadersWriters/APReadersWriters.t".
    "la"
  =/  model
    %-  crip
    "specifications/ReadersWriters/APReadersWriters.c".
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
  :*  'model-9fcefd52cc89'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-a2f8efaf066f
::
++  test-apalache-apcat-efaf066f
  =/  manifest  (crip "specifications/Moving_Cat_Puzzle/manifest.json")
  =/  module  (crip "specifications/Moving_Cat_Puzzle/APCat.tla")
  =/  model  (crip "specifications/Moving_Cat_Puzzle/APCat.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-a2f8efaf066f'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-a5080bd56f7e
::
++  test-apalache-apc1cs-0bd56f7e
  =/  manifest  (crip "specifications/c1cs/manifest.json")
  =/  module  (crip "specifications/c1cs/APc1cs.tla")
  =/  model  (crip "specifications/c1cs/APc1cs.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-a5080bd56f7e'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-a67deb25ffc1
::
++  test-apalache-aphourclock-eb25ffc1
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Liveness/APHour".
    "Clock.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/Liveness/APHour".
    "Clock.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-a67deb25ffc1'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-bbc5260487d4
::
++  test-apalache-apdisruptor-spmc-260487d4
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/APDisruptor_SPMC.tla")
  =/  model  (crip "specifications/Disruptor/APDisruptor_SPMC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-bbc5260487d4'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-c22e59460373
::
++  test-apalache-aphourclock-59460373
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/APHou".
    "rClock.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/HourClock/APHou".
    "rClock.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c22e59460373'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-c486cec151fa
::
++  test-apalache-apmissionariesandcannibals-cec151fa
  =/  manifest
    %-  crip
    "specifications/MissionariesAndCannibals/manifest".
    ".json"
  =/  module
    %-  crip
    "specifications/MissionariesAndCannibals/APMissio".
    "nariesAndCannibals.tla"
  =/  model
    %-  crip
    "specifications/MissionariesAndCannibals/APMissio".
    "nariesAndCannibals.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-c486cec151fa'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-cf19492ca9c2
::
++  test-apalache-apasynchinterface-492ca9c2
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/APAsynchInterface.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/APAsynchInterface.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-cf19492ca9c2'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-d589f3df3b60
::
++  test-apalache-apstages-f3df3b60
  =/  manifest  (crip "specifications/glowingRaccoon/manifest.json")
  =/  module  (crip "specifications/glowingRaccoon/APstages.tla")
  =/  model  (crip "specifications/glowingRaccoon/APstages.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-d589f3df3b60'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-d71a0501e212
::
++  test-apalache-apspanning-0501e212
  =/  manifest  (crip "specifications/spanning/manifest.json")
  =/  module  (crip "specifications/spanning/APspanning.tla")
  =/  model  (crip "specifications/spanning/APspanning.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-d71a0501e212'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-db3072dbe4ec
::
++  test-apalache-aphourclock2-72dbe4ec
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/HourClock/APHou".
    "rClock2.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/HourClock/APHou".
    "rClock2.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-db3072dbe4ec'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-dc26ae9e01fc
::
++  test-apalache-apchannel-ae9e01fc
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/APChannel.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/AsynchronousInt".
    "erface/APChannel.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-dc26ae9e01fc'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-dd572fa423ac
::
++  test-apalache-apspantree-2fa423ac
  =/  manifest  (crip "specifications/SpanningTree/manifest.json")
  =/  module  (crip "specifications/SpanningTree/APSpanTree.tla")
  =/  model  (crip "specifications/SpanningTree/APSpanTree.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-dd572fa423ac'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-dfe2f76764df
::
++  test-apalache-apinnerfifoinstanced-f76764df
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APInnerFIF".
    "OInstanced.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/FIFO/APInnerFIF".
    "OInstanced.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-dfe2f76764df'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-e5f1e3a24ecc
::
++  test-apalache-apdisruptor-mpmc-e3a24ecc
  =/  manifest  (crip "specifications/Disruptor/manifest.json")
  =/  module  (crip "specifications/Disruptor/APDisruptor_MPMC.tla")
  =/  model  (crip "specifications/Disruptor/APDisruptor_MPMC.cfg")
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-e5f1e3a24ecc'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-f1b6ca0f2a98
::
++  test-apalache-apchannel-ca0f2a98
  =/  manifest  (crip "specifications/SpecifyingSystems/manifest.json")
  =/  module
    %-  crip
    "specifications/SpecifyingSystems/Composing/APCha".
    "nnel.tla"
  =/  model
    %-  crip
    "specifications/SpecifyingSystems/Composing/APCha".
    "nnel.cfg"
  =/  options
    :*  %auto
        60
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'model-f1b6ca0f2a98'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
::
::  coverage-id: model-f99e075c422c
::
++  test-apalache-apreplicatedlog-075c422c
  =/  manifest  (crip "specifications/FiniteMonotonic/manifest.json")
  =/  module
    %-  crip
    "specifications/FiniteMonotonic/APReplicatedLog.t".
    "la"
  =/  model
    %-  crip
    "specifications/FiniteMonotonic/APReplicatedLog.c".
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
  :*  'model-f99e075c422c'
      manifest
      module
      model
      %apalache
      [%symbolic 5]
      %success
      '00:00:01'
      %.y
      ~
      options
  ==
--
