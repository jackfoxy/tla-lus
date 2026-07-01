|%
::  +|  %assumed-public-contract
::
::  The minimal wire contract the black-box suite assumes of the %tla-lus
::  agent.  This is intentionally tiny: one poke to submit a run and one
::  scry/subscription response carrying lifecycle state and a terminal
::  result.  The mark and scry-path that bind these types to the live agent
::  are named only in [[tla-lus-test-adapter]], so a later API change touches
::  one file.
::
::  +request-id: caller-chosen id echoed on every response
::
+$  request-id  @t
::  +source: the module (or bundle) to run
::
::    A single root path resolves EXTENDS/INSTANCE against its sibling
::    fixtures; a bundle carries an explicit file map when there is no Clay
::    tree to resolve against.
::
+$  source
  $%  [%path root=@t]
      [%bundle root=@t files=(map @t @t)]
  ==
::  +mode: execution mode (mirrors the test vocabulary)
::
+$  mode
  $%  [%parse ~]
      [%prove ~]
      [%translate ~]
      [%exhaustive ~]
      [%generate ~]
      [%symbolic depth=@ud]
      [%simulate traces=@ud]
  ==
::  +options: run options
::
+$  options
  $:  workers=?(%auto @ud)
      timeout=@ud
      seed=(unit @ud)
      max-states=(unit @ud)
      max-input=(unit @ud)
      flags=(list @t)
  ==
::  +run-request: the sole submit payload
::
+$  run-request
  $:  id=request-id
      =source
      config=(unit @t)
      =mode
      =options
  ==
::  +action: the sole poke
::
+$  action
  $%  [%run =run-request]
      [%cancel id=request-id]
  ==
::  +phase: lifecycle phase of a submitted run
::
+$  phase  ?(%queued %running %done %failed %cancelled)
::  +result: terminal result carried by the response
::
::    Deliberately close to the test-side report; the adapter narrows it.
::
+$  result
  $:  =phase
      status=@tas
      code=(unit @ud)
      summary=@t
      states=(list @t)
      loop=(unit @ud)
      distinct=(unit @ud)
      total=(unit @ud)
      depth=(unit @ud)
  ==
::  +update: the sole scry / subscription response
::
+$  update
  $:  id=request-id
      =phase
      result=(unit result)
  ==
--
