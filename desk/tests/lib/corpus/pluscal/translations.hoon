/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: pluscal-073563532ac3
::
++  test-pluscal-2pcwithbtm-63532ac3
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
  :*  'pluscal-073563532ac3'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-1994b95285a3
::
++  test-pluscal-consensus-b95285a3
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
  :*  'pluscal-1994b95285a3'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-2e9811280173
::
++  test-pluscal-kvsnap-11280173
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
  :*  'pluscal-2e9811280173'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-3878abcaafcf
::
++  test-pluscal-queenspluscal-abcaafcf
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
  :*  'pluscal-3878abcaafcf'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-43baead62dae
::
++  test-pluscal-sailfish-ead62dae
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
  :*  'pluscal-43baead62dae'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-4fcd309bb571
::
++  test-pluscal-peterson-309bb571
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
  :*  'pluscal-4fcd309bb571'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-56fd646f997f
::
++  test-pluscal-boulanger-646f997f
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
  :*  'pluscal-56fd646f997f'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-617fe1ef862d
::
++  test-pluscal-ewd687apluscal-e1ef862d
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
  :*  'pluscal-617fe1ef862d'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-69e72581137e
::
++  test-pluscal-simpleregular-2581137e
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
  :*  'pluscal-69e72581137e'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-6a94b0483af8
::
++  test-pluscal-leastcircularsubstring-b0483af8
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
  :*  'pluscal-6a94b0483af8'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-769cb7fd7a5f
::
++  test-pluscal-diningphilosophers-b7fd7a5f
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
  :*  'pluscal-769cb7fd7a5f'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-7ddbdf5e04a1
::
++  test-pluscal-dijkstramutex-df5e04a1
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
  :*  'pluscal-7ddbdf5e04a1'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-880aac0ce8b1
::
++  test-pluscal-multipaxos-ac0ce8b1
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
  :*  'pluscal-880aac0ce8b1'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-8945ec8d2b32
::
++  test-pluscal-binarysearch-ec8d2b32
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
  :*  'pluscal-8945ec8d2b32'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-930b225354bb
::
++  test-pluscal-dijkstramutex-225354bb
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
  :*  'pluscal-930b225354bb'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-95bff9fe38d2
::
++  test-pluscal-changroberts-f9fe38d2
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
  :*  'pluscal-95bff9fe38d2'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-9a2c5ff6b3c4
::
++  test-pluscal-simple-5ff6b3c4
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
  :*  'pluscal-9a2c5ff6b3c4'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-a12ebba4c1e0
::
++  test-pluscal-bakery-bba4c1e0
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
  :*  'pluscal-a12ebba4c1e0'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-aa744f68d794
::
++  test-pluscal-sumsequence-4f68d794
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
  :*  'pluscal-aa744f68d794'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-ab302addf5e7
::
++  test-pluscal-tlcmc-2addf5e7
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
  :*  'pluscal-ab302addf5e7'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-b48cc6891ba5
::
++  test-pluscal-ewd998pcal-c6891ba5
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
  :*  'pluscal-b48cc6891ba5'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-bcddf476d18b
::
++  test-pluscal-quicksort-f476d18b
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
  :*  'pluscal-bcddf476d18b'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-bfc4dff9063c
::
++  test-pluscal-queenspluscal-dff9063c
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
  :*  'pluscal-bfc4dff9063c'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-c10e1702ec99
::
++  test-pluscal-dijkstramutex-1702ec99
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
  :*  'pluscal-c10e1702ec99'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-c47067ac6577
::
++  test-pluscal-echo-67ac6577
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
  :*  'pluscal-c47067ac6577'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-ca9788932169
::
++  test-pluscal-reachable-88932169
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
  :*  'pluscal-ca9788932169'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-cb8e7d6b9a5e
::
++  test-pluscal-addtwo-7d6b9a5e
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
  :*  'pluscal-cb8e7d6b9a5e'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-d08523d4badb
::
++  test-pluscal-barriers-23d4badb
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
  :*  'pluscal-d08523d4badb'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-df2fff9cb6e2
::
++  test-pluscal-lock-ff9cb6e2
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
  :*  'pluscal-df2fff9cb6e2'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-e6345ed080d3
::
++  test-pluscal-findhighest-5ed080d3
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
  :*  'pluscal-e6345ed080d3'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-ea2269a83e07
::
++  test-pluscal-parreach-69a83e07
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
  :*  'pluscal-ea2269a83e07'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
::
::  coverage-id: pluscal-ed08edd749b5
::
++  test-pluscal-slush-edd749b5
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
  :*  'pluscal-ed08edd749b5'
      manifest
      module
      model
      %pluscal
      [%translate ~]
      %success
      'translation'
      %.n
      ~
      options
  ==
--
