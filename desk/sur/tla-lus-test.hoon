|%
::  +|  %shared-vocabulary
::
::  The molds the generated corpus and failure arms are written against, plus
::  the normalized public test shape the adapter returns.  Every generated
::  `.hoon` file under tests/lib does `/-  *tla-lus-test`, so this file is the
::  compile-time contract for the whole suite.  It is deliberately small: the
::  wire-level app contract lives in [[tla-lus]]; the runtime assumptions live
::  in [[tla-lus-test-adapter]].
::
::  +tool: which back-end tool a case exercises
::
::    Kept in one enum so tlc / apalache / tlaps cases stay attributable even
::    though they are split across separate corpus files.
::
+$  tool  ?(%tlc %apalache %sany %tlaps %pluscal)
::  +mode: execution mode submitted with a run
::
+$  mode
  $%  [%parse ~]                :: SANY parse / lint only
      [%prove ~]               :: TLAPS proof obligation discharge
      [%translate ~]           :: PlusCal -> TLA+ translation
      [%exhaustive ~]          :: TLC exhaustive search
      [%generate ~]            :: TLC state generation
      [%symbolic depth=@ud]    :: Apalache symbolic (bounded) check
      [%simulate traces=@ud]   :: TLC random simulation
  ==
::  +outcome: model-checking outcome categories with a stable oracle
::
::    A declared failure is a passing test when the observed outcome equals the
::    declared one, so the failure categories are first-class here.
::
+$  outcome
  ?(%success %safety-failure %liveness-failure %assumption-failure %deadlock-failure)
::  +status: terminal status / error category
::
::    Superset of +outcome that also carries parser, config, interface and
::    resource error categories used by the non-corpus failure suite.
::
+$  status  @tas
::  +run-stats: optional run statistics (distinct/total states, depth)
::
::    Shaped to match the generated literals; every field is a unit so a
::    partially-reported run still nests.  Depth is presently never asserted.
::
+$  run-stats  (unit [distinct=(unit @ud) total=(unit @ud) depth=(unit @ud)])
::  +options: submitted run options
::
+$  options
  $:  workers=?(%auto @ud)
      timeout=@ud
      seed=(unit @ud)
      max-states=(unit @ud)
      max-input=(unit @ud)
      flags=(list @t)
  ==
::  +scenario: how a failure case is driven through the Gall API
::
+$  scenario
  $?  %run                     :: ordinary submit-then-observe
      %invalid-mode            :: submit an unsupported mode
      %invalid-depth           :: submit a bad depth
      %invalid-seed            :: submit a bad seed
      %cancel                  :: submit then cancel before completion
      %malformed-mark          :: poke with the wrong mark
      %malformed-payload       :: poke with a malformed payload
      %unauthorized            :: poke from an unauthorized ship
      %unknown-scry            :: scry an unknown path
      %duplicate-request       :: reuse a live request id
      %missing-request-id      :: submit without a request id
      %query-before-submit     :: query a result before submitting
      %query-after-completion  :: query a result after completion
      %repeat                  :: submit the same run twice deterministically
      %concurrent              :: submit independent runs concurrently
      %restart                 :: submit, persist, restart, re-query
      %rejected-run-isolation  :: reject a run, confirm agent still usable
  ==
::  +corpus-case: one CI-validated manifest model, byte-attributable
::
+$  corpus-case
  $:  id=@t                    :: stable coverage id
      manifest=@t              :: Examples manifest path
      module=@t                :: module fixture path
      model=@t                 :: model/config fixture path
      =tool
      =mode
      expected=outcome         :: declared manifest result
      runtime=@t               :: declared runtime metadata
      quick=?                  :: quick regression vs full acceptance
      stats=run-stats          :: optional declared statistics
      =options
  ==
::  +failure-case: one deterministic public failure fixture
::
+$  failure-case
  $:  name=@t                  :: case name
      =scenario
      root=@t                  :: root module fixture path
      config=(unit @t)         :: optional config fixture path
      =tool
      =mode
      =options
      expected=status          :: declared terminal status / error category
      code=(unit @ud)          :: optional stable error code
      fragment=(unit @t)       :: optional diagnostic message fragment
      actions=(list @t)        :: optional counterexample action sequence
      loop=(unit @ud)          :: optional lasso loop-back index
  ==
::  +trace: normalized counterexample
::
::    Only the meaningful state/action sequence and loop point, never the
::    pretty-printed whitespace.
::
+$  trace
  $:  states=(list @t)
      loop=(unit @ud)
  ==
::  +report: the small public shape every observed run is normalized to
::
::    This is the ONLY shape the assertion helpers read.  If the app's real
::    API changes, only [[tla-lus-test-adapter]] must change to keep producing
::    this shape.
::
+$  report
  $:  id=@t                    :: echoed request id
      terminal=?               :: reached a terminal state
      status=status            :: terminal status / outcome category
      outcome=(unit outcome)   :: model-checking outcome if any
      code=(unit @ud)          :: stable error code if any
      summary=@t               :: diagnostic summary (fragment carrier)
      trace=(unit trace)       :: optional counterexample
      stats=run-stats          :: available run statistics
  ==
--
