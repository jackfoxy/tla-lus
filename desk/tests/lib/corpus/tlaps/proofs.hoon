/-  *tla-lus-test
/+  *tla-lus-test-helpers
|%
::
::  coverage-id: proof-00a155f5f231
::
++  test-tlaps-simple-proof-55f5f231
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
  :*  'proof-00a155f5f231'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-0444d19369ff
::
++  test-tlaps-crdt-proof-d19369ff
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
  :*  'proof-0444d19369ff'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-086dbd42aad7
::
++  test-tlaps-asynchinterface-proof-bd42aad7
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
  :*  'proof-086dbd42aad7'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-13d792e3ef73
::
++  test-tlaps-internalmemory-proof-92e3ef73
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
  :*  'proof-13d792e3ef73'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-15459bd2d2a7
::
++  test-tlaps-spanning-proof-9bd2d2a7
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
  :*  'proof-15459bd2d2a7'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-1994b95285a3
::
++  test-tlaps-consensus-b95285a3
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
  :*  'proof-1994b95285a3'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-19eda07ab045
::
++  test-tlaps-cigarettesmokers-proof-a07ab045
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
  :*  'proof-19eda07ab045'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-1a5ab510bb1d
::
++  test-tlaps-voting-b510bb1d
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
  :*  'proof-1a5ab510bb1d'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-1f0cea1eb948
::
++  test-tlaps-bpconproof-ea1eb948
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/BPConProof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        2.700
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-1f0cea1eb948'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 45 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-2060a260b292
::
++  test-tlaps-ewd998pcal-proof-a260b292
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998PCal_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        600
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-2060a260b292'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 10 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-20e7ec25440e
::
++  test-tlaps-coffeecan-proof-ec25440e
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
  :*  'proof-20e7ec25440e'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-21db523bc780
::
++  test-tlaps-schedulingallocator-proof-523bc780
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module
    %-  crip
    "specifications/allocator/SchedulingAllocator_pro".
    "of.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        120
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-21db523bc780'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 2 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-2daf97815dcf
::
++  test-tlaps-internalmemory-proof-97815dcf
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
  :*  'proof-2daf97815dcf'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-3142a90633d2
::
++  test-tlaps-consensus-a90633d2
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
  :*  'proof-3142a90633d2'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-3ab832db06e8
::
++  test-tlaps-lamportmutex-proofs-32db06e8
  =/  manifest  (crip "specifications/lamport_mutex/manifest.json")
  =/  module
    %-  crip
    "specifications/lamport_mutex/LamportMutex_proofs".
    ".tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        300
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-3ab832db06e8'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 5 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-3afc9a3f64c0
::
++  test-tlaps-clean-proof-9a3f64c0
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
  :*  'proof-3afc9a3f64c0'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-438525d3d571
::
++  test-tlaps-ewd840-proof-25d3d571
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
  :*  'proof-438525d3d571'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-4aafae05cebf
::
++  test-tlaps-tcommit-proof-ae05cebf
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
  :*  'proof-4aafae05cebf'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-4c65c914510c
::
++  test-tlaps-internalmemory-proof-c914510c
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
  :*  'proof-4c65c914510c'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-4fcd309bb571
::
++  test-tlaps-peterson-309bb571
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
  :*  'proof-4fcd309bb571'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-56fd646f997f
::
++  test-tlaps-boulanger-646f997f
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module  (crip "specifications/Bakery-Boulangerie/Boulanger.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-56fd646f997f'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 3 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-5ce4001a6a47
::
++  test-tlaps-hourclock-proof-001a6a47
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
  :*  'proof-5ce4001a6a47'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-5d280d260530
::
++  test-tlaps-alternatingbit-proof-0d260530
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
  :*  'proof-5d280d260530'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-5dbe88b21683
::
++  test-tlaps-bcastbyz-88b21683
  =/  manifest  (crip "specifications/bcastByz/manifest.json")
  =/  module  (crip "specifications/bcastByz/bcastByz.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        300
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-5dbe88b21683'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 5 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-5fe1c7bd2547
::
++  test-tlaps-voucherlifecycle-proof-c7bd2547
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
  :*  'proof-5fe1c7bd2547'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-60a274785500
::
++  test-tlaps-hourclock-proof-74785500
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
  :*  'proof-60a274785500'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-69303cb0c847
::
++  test-tlaps-channel-proof-3cb0c847
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
  :*  'proof-69303cb0c847'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-69e72581137e
::
++  test-tlaps-simpleregular-2581137e
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
  :*  'proof-69e72581137e'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-6fdc007312ab
::
++  test-tlaps-asyncterminationdetection-proof-007312ab
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
  :*  'proof-6fdc007312ab'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-70a150a4bb95
::
++  test-tlaps-internalmemory-proof-50a4bb95
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
  :*  'proof-70a150a4bb95'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-783eab1a1b4c
::
++  test-tlaps-channel-proof-ab1a1b4c
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
  :*  'proof-783eab1a1b4c'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-82fc45c32c00
::
++  test-tlaps-elevator-proof-45c32c00
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
  :*  'proof-82fc45c32c00'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-83d9274feee2
::
++  test-tlaps-twophase-proof-274feee2
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
  :*  'proof-83d9274feee2'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-88dd06f4ba22
::
++  test-tlaps-spantree-proof-06f4ba22
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
  :*  'proof-88dd06f4ba22'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-8945ec8d2b32
::
++  test-tlaps-binarysearch-ec8d2b32
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
  :*  'proof-8945ec8d2b32'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-8a725dcb6fa4
::
++  test-tlaps-pconproof-5dcb6fa4
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
  :*  'proof-8a725dcb6fa4'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-991e979b00e4
::
++  test-tlaps-voting-proof-979b00e4
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
  :*  'proof-991e979b00e4'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-9a2c5ff6b3c4
::
++  test-tlaps-simple-5ff6b3c4
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
  :*  'proof-9a2c5ff6b3c4'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-9fd68a841add
::
++  test-tlaps-voteproof-8a841add
  =/  manifest  (crip "specifications/byzpaxos/manifest.json")
  =/  module  (crip "specifications/byzpaxos/VoteProof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-9fd68a841add'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 3 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-a0f2e0417249
::
++  test-tlaps-readerswriters-proof-e0417249
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
  :*  'proof-a0f2e0417249'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-a12ebba4c1e0
::
++  test-tlaps-bakery-bba4c1e0
  =/  manifest  (crip "specifications/Bakery-Boulangerie/manifest.json")
  =/  module  (crip "specifications/Bakery-Boulangerie/Bakery.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        120
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-a12ebba4c1e0'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 2 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-a4d85fa1ea8f
::
++  test-tlaps-channel-proof-5fa1ea8f
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
  :*  'proof-a4d85fa1ea8f'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-a50cb774aa9a
::
++  test-tlaps-syncterminationdetection-proof-b774aa9a
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
  :*  'proof-a50cb774aa9a'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-a9c4394f89d6
::
++  test-tlaps-ewd998-proof-394f89d6
  =/  manifest  (crip "specifications/ewd998/manifest.json")
  =/  module  (crip "specifications/ewd998/EWD998_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        120
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-a9c4394f89d6'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 2 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-aa744f68d794
::
++  test-tlaps-sumsequence-4f68d794
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/SumSequence.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-aa744f68d794'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 3 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-b092312c816c
::
++  test-tlaps-paxoscommit-proof-312c816c
  =/  manifest  (crip "specifications/transaction_commit/manifest.json")
  =/  module
    %-  crip
    "specifications/transaction_commit/PaxosCommit_pr".
    "oof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        300
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-b092312c816c'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 5 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-b36cada8d1c1
::
++  test-tlaps-keyvaluestore-proof-ada8d1c1
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
  :*  'proof-b36cada8d1c1'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-b86175ebca2f
::
++  test-tlaps-stages-proof-75ebca2f
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
  :*  'proof-b86175ebca2f'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-b86c0a2348c5
::
++  test-tlaps-voting-0a2348c5
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
  :*  'proof-b86c0a2348c5'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-ba980bfbcd04
::
++  test-tlaps-diehard-proof-0bfbcd04
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
  :*  'proof-ba980bfbcd04'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-bcddf476d18b
::
++  test-tlaps-quicksort-f476d18b
  =/  manifest  (crip "specifications/LoopInvariance/manifest.json")
  =/  module  (crip "specifications/LoopInvariance/Quicksort.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        600
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-bcddf476d18b'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 10 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-bebdb8e540dc
::
++  test-tlaps-allocatorimplementation-proof-b8e540dc
  =/  manifest  (crip "specifications/allocator/manifest.json")
  =/  module
    %-  crip
    "specifications/allocator/AllocatorImplementation".
    "_proof.tla"
  =/  model  (crip "")
  =/  options
    :*  %auto
        120
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-bebdb8e540dc'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 2 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-c1624bc8952e
::
++  test-tlaps-simpleregular-proof-4bc8952e
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
  :*  'proof-c1624bc8952e'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-c3c5a41ec8f8
::
++  test-tlaps-twophase-proof-a41ec8f8
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
  :*  'proof-c3c5a41ec8f8'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-c3cc9997dd27
::
++  test-tlaps-parreachproofs-9997dd27
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
  :*  'proof-c3cc9997dd27'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-c5d4d8308bb0
::
++  test-tlaps-hourclock-proof-d8308bb0
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
  :*  'proof-c5d4d8308bb0'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-c6521ed5441e
::
++  test-tlaps-innerfifo-proof-1ed5441e
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
  :*  'proof-c6521ed5441e'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-cb8e7d6b9a5e
::
++  test-tlaps-addtwo-7d6b9a5e
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
  :*  'proof-cb8e7d6b9a5e'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-d083ea6d1672
::
++  test-tlaps-tcp-proof-ea6d1672
  =/  manifest  (crip "specifications/tcp/manifest.json")
  =/  module  (crip "specifications/tcp/tcp_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        3.600
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-d083ea6d1672'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 60 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-d08523d4badb
::
++  test-tlaps-barriers-23d4badb
  =/  manifest  (crip "specifications/barriers/manifest.json")
  =/  module  (crip "specifications/barriers/Barriers.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        600
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-d08523d4badb'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 10 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-d1b14da1b55b
::
++  test-tlaps-ewd687a-proof-4da1b55b
  =/  manifest  (crip "specifications/ewd687a/manifest.json")
  =/  module  (crip "specifications/ewd687a/EWD687a_proof.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        180
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-d1b14da1b55b'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 3 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-d43ebcaee9c9
::
++  test-tlaps-consensus-bcaee9c9
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
  :*  'proof-d43ebcaee9c9'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-d4ac3530abbc
::
++  test-tlaps-twophase-3530abbc
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
  :*  'proof-d4ac3530abbc'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-d6dfd159230f
::
++  test-tlaps-reachabilityproofs-d159230f
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
  :*  'proof-d6dfd159230f'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-dbdc5efca53a
::
++  test-tlaps-hourclock-proof-5efca53a
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
  :*  'proof-dbdc5efca53a'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-dd071bbeae1c
::
++  test-tlaps-reachableproofs-1bbeae1c
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
  :*  'proof-dd071bbeae1c'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-df2fff9cb6e2
::
++  test-tlaps-lock-ff9cb6e2
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
  :*  'proof-df2fff9cb6e2'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-e1871a24de98
::
++  test-tlaps-majorityproof-1a24de98
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
  :*  'proof-e1871a24de98'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-e6345ed080d3
::
++  test-tlaps-findhighest-5ed080d3
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
  :*  'proof-e6345ed080d3'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-f7d3e721356c
::
++  test-tlaps-lockhs-e721356c
  =/  manifest
    %-  crip
    "specifications/locks_auxiliary_vars/manifest.jso".
    "n"
  =/  module  (crip "specifications/locks_auxiliary_vars/LockHS.tla")
  =/  model  (crip "")
  =/  options
    :*  %auto
        120
        ~
        ~
        ~
        ~
    ==
  %-  expect-corpus-case
  :*  'proof-f7d3e721356c'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 2 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-f9376a184a28
::
++  test-tlaps-missionariesandcannibals-proof-6a184a28
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
  :*  'proof-f9376a184a28'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-f979c93172ae
::
++  test-tlaps-simpleallocator-proof-c93172ae
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
  :*  'proof-f979c93172ae'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
::
::  coverage-id: proof-fb2439999d5c
::
++  test-tlaps-sums-even-39999d5c
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
  :*  'proof-fb2439999d5c'
      manifest
      module
      model
      %tlaps
      [%prove ~]
      %success
      'max 1 minutes'
      %.n
      ~
      options
  ==
--
