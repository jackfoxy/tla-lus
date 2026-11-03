/-  api=tla-lus
|%
  ::  Black-Box Suite Vocabulary (R4.0f)
  ::
  ::  The July 2026 suite (`prompt-tests.md`) re-founded on the real wire.
  ::  Every generated arm under tests/lib/blackbox/ builds one +bb-case
  ::  and hands it to +expect-case; the adapter is the only file that knows
  ::  how a case becomes pokes, wakes and scries. (Not `case`: that face is
  ::  the Clay revision mold, and shadowing it fails far from here.)
  ::
  ::  The corpus half of the July suite is not here: a manifest model is many
  ::  Behn slices on a live agent, so tools/examples.py drives it through the
  ::  public wire instead (desk/test-data/blackbox/models.json).
  ::
::  +|  Types
::
::  +scenario: how a case is driven through the Gall API
::
+$  scenario
  $?  %run                     ::  submit, wake to a result
      %cancel                  ::  submit, one wake, cancel
      %malformed-mark          ::  poke with a mark the agent does not take
      %malformed-payload       ::  poke the right mark with an ill-typed noun
      %unauthorized            ::  poke from a foreign ship
      %unknown-scry            ::  peek a path the agent does not serve
      %duplicate-request       ::  reuse an active request id
      %query-before-submit     ::  peek a job that was never submitted
      %query-after-completion  ::  peek a finished job again
      %repeat                  ::  run the same request twice
      %concurrent              ::  run two jobs with interleaved wakes
      %restart                 ::  save and reload the agent mid-run
      %rejected-run-isolation  ::  a rejected submit, then a good one
  ==
::  +fixture: an inline source bundle (root, modules, cfg text)
::
+$  fixture  [root=@t modules=(list [@t @t]) cfg=(unit @t)]
::  +over: request limits a case overrides; ~ keeps the engine default
::
+$  over
  $:  max-states=(unit @ud)
      max-time=(unit @dr)
      max-source=(unit @ud)
  ==
::  +bb-case: one scenario and the value its named oracle expects
::
::    `expected` is upstream CI's outcome category for a TLC run
::    (`tla_utils.resolve_tlc_exit_code`), a SANY category for an analyze
::    run, or the documented agent answer; the generator records which.
::
+$  bb-case
  $:  name=@t
      =scenario
      src=fixture
      =op:api
      =over
      expected=@tas
      code=(unit @ud)
      fragment=(unit @t)
      actions=(list @t)
      loop=(unit @ud)
  ==
::  +report: the small public shape every observed run is normalized to
::
+$  report
  $:  status=@tas
      code=(unit @ud)
      summary=@t
      actions=(list @t)
      loop=(unit @ud)
  ==
--
