/-  *tla-lus-test
/+  *test, adapter=tla-lus-test-adapter
::  tla-lus-test-helpers: the two assertions every generated arm calls.
::
::  Each arm hands a fully-specified case to the adapter, receives the
::  normalized +report, and asserts the externally observable result.  A
::  declared failure passes exactly when the observed category equals the
::  declared one, so expected failures are ordinary passing tests.  Neither
::  helper uses +expect-fail: a Gall crash is never the pass condition here,
::  so a crash in the suite surfaces as a failure, not a green test.
::
|%
::  +observed-category: the single terminal category a report reduces to
::
::    An outcome (if any) dominates the raw status, so %success and every
::    failure category compare uniformly against a declared value.
::
++  observed-category
  |=  =report
  ^-  @tas
  ?~  outcome.report  status.report
  u.outcome.report
::  +expect-corpus-case: assert a CI-validated manifest model
::
::    Primary assertion: observed outcome category equals the declared
::    manifest result.  Secondary (only for a terminated, deterministic
::    exhaustive run that exposes statistics): declared distinct/total/depth
::    match.  The failure line names manifest, module, model and expectation.
::
++  expect-corpus-case
  |=  c=corpus-case
  ^-  tang
  =/  =report  (run-corpus:adapter c)
  =/  observed=@tas  (observed-category report)
  =/  base=tang
    %+  category
      ;:  weld
        "corpus {(trip manifest.c)}"
        " :: {(trip module.c)}"
        ?:(=('' model.c) "" " :: {(trip model.c)}")
        " expect %{(trip expected.c)}"
      ==
    (expect-eq !>(`@tas`expected.c) !>(observed))
  =?  base
      ?&  terminal.report
          ?=([%exhaustive ~] mode.c)
          ?=(^ stats.c)
          ?=(^ stats.report)
      ==
    %+  weld  base
    (expect-eq !>(u.stats.c) !>(u.stats.report))
  base
::  +expect-failure-case: assert a deterministic public failure fixture
::
::    Primary assertion: observed status category equals the declared one.
::    Secondaries, only when the run terminated and the app exposes the datum:
::    stable error code matches; declared message fragment appears in the
::    summary; declared counterexample action sequence and loop point match.
::
++  expect-failure-case
  |=  c=failure-case
  ^-  tang
  =/  =report  (run-failure:adapter c)
  =/  observed=@tas  (observed-category report)
  =/  base=tang
    %+  category
      ;:  weld
        "failure {(trip name.c)}"
        " [%{(trip scenario.c)}]"
        " root {(trip root.c)}"
        " expect %{(trip expected.c)}"
      ==
    (expect-eq !>(`@tas`expected.c) !>(observed))
  =?  base  ?&(terminal.report ?=(^ code.c) ?=(^ code.report))
    %+  weld  base
    (expect-eq !>(u.code.c) !>(u.code.report))
  =?  base  ?&(terminal.report ?=(^ fragment.c) !=('' summary.report))
    %+  weld  base
    ^-  tang
    ?^  (find (trip u.fragment.c) (trip summary.report))
      ~
    :~  leaf+"fragment not found: {(trip u.fragment.c)}"
        leaf+"in summary: {(trip summary.report)}"
    ==
  =?  base  ?&(terminal.report ?=(^ trace.report) |(?=(^ actions.c) ?=(^ loop.c)))
    %+  weld  base
    %+  expect-eq
      !>  [actions.c loop.c]
      !>  [states.u.trace.report loop.u.trace.report]
  base
--
