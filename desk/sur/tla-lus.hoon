|%
  ::  %tla-lus Shared Wire Nouns
  ::
  ::  Frozen by work unit 2. Public poke/update/scry nouns and the shared
  ::  compiler-interface types every /lib library builds on. Lexical
  ::  and semantic vocabularies (token kinds, node kinds) stay open @tas
  ::  tags; units 3-6 fill them without changing these shells.
  ::
  ::  Deterministic ordering contracts (comparators in /lib/diagnostics):
  ::    diagnostics  global (at=~) first, then by source name, span,
  ::                 code family, code number, message
  ::    modules      dependency order, ties by name (unit 5)
  ::    bindings     by variable name, alphabetical
  ::    traces       by state index (inherent)
  ::
::  +|  API Revision
::
::  Bumped when a caller-visible noun changes AFTER a release. Nothing has
::  been released, so this is 1: the wire as it ships, with no pre-release
::  revision history to carry.
::  STAYS 1 through R2.7.1's wire change, and that is the desk's own rule
::  rather than an oversight: `compatibility.md` §10.6 records that pre-release
::  reshapes are NOT versions -- "no ship ever held that state and no caller
::  ever saw that wire" -- and R2's own preamble says nothing has shipped and
::  the wire may be reshaped freely. Bumping here would re-create exactly the
::  pre-release version history §10.6 deliberately removed. It moves at release
++  api-version  1
::
::  +|  Identifiers
::
::  caller-chosen request id; duplicate active ids are rejected
+$  req-id       @ta
+$  module-name  @t
::  file identity a span points into (module name or cfg name)
+$  source-name  @t
::
::  +|  Positions And Spans
::
::  1-indexed logical positions, matching SANY Location semantics;
::  CRLF normalization must not change reported positions
+$  pos   [line=@ud col=@ud]
::  inclusive start/end
+$  span  [from=pos to=pos]
+$  loc   [src=source-name =span]
::
::  +|  Source Identity Vs Content
::
::  where text came from; never carries the text itself
+$  source-id
  $%  [%inline name=source-name]
      [%clay =ship =desk cas=case =path]
  ==
::  resolved content fed to the compiler pipeline
+$  source-text  [id=source-id text=@t]
::  resolver contract: inline and Clay resolvers implement this (unit 5)
+$  resolver  $-(module-name (unit source-text))
::
::  +|  Lexical And Syntactic Shells
::
::  kind vocabularies land with the lexer (unit 3) and parser (unit 4).
::  NOTE: the recursive syntax-tree mold moves in with the parser (unit
::  4); recursive molds in this desk need obelisk-style $+ annotations
::  and careful shape or the zuse-408 mold compiler overflows.
+$  token  [kind=@tas text=@t =span]
::
::  +|  Diagnostics
::
+$  severity  ?(%error %warning %info)
::  code namespaces: SANY ErrorCode, PlusCal, TLC EC, and %tla-lus itself
+$  code-family  ?(%sany %pcal %tlc %lus)
+$  diag-code    [family=code-family num=@ud]
::  pipeline stages; used for run progress and diagnostic provenance
+$  stage
  $?  %starting   ::  request validation and setup
      %translate  ::  PlusCal translation
      %parse      ::  SANY lexing/parsing
      %modules    ::  module resolution and dependency order
      %semantic   ::  semantic graph construction
      %level      ::  level checking
      %lint       ::  lint rules
      %config     ::  TLC .cfg processing
      %init       ::  initial-state generation
      %explore    ::  successor exploration
      %checkpoint ::  checkpointing
      %liveness   ::  liveness checking
      %simulate   ::  simulation
      %dfid       ::  depth-first iterative deepening (R2.5)
      %terminal   ::  finished (any result)
  ==
+$  diagnostic
  $:  code=diag-code
      =severity
      =stage
      message=@t
      ::  ~ for diagnostics not tied to a source location
      at=(unit loc)
      related=(list loc)
  ==
::
::  +|  Traces And Artifacts
::
::  values render as canonical text until unit 9 lands typed values
+$  binding  [var=@t val=@t]
+$  trace-state
  $:  index=@ud
      action=(unit [name=@t at=(unit loc)])
      ::  in TLC's variable DECLARATION order (+state-pairs), or, under an
      ::  ALIAS, in the alias record's own constructor order (R2.3.2)
      bindings=(list binding)
  ==
+$  trace
  $:  kind=?(%safety %lasso %simulate)
      states=(list trace-state)
      ::  lasso back-edge target index for liveness counterexamples
      loop-start=(unit @ud)
  ==
+$  artifact-name  @ta
+$  artifact
  $%  [%text text=@t]
      [%trace =trace]
      ::  every counterexample of a `-continue` run (R2.4.2), in discovery
      ::  order. A separate ARTIFACT rather than a change to `result` or
      ::  `violation`: those two were R2.7.1's to reshape (the EC 2107/2110
      ::  split, since done). Keeping the counterexample list OUT of `result`
      ::  still holds on its own terms -- a completed `-continue` run has one
      ::  verdict and many counterexamples, which is an artifact's shape, not a
      ::  result's
      [%violations viols=(list [=violation =trace])]
  ==
::
::  +|  Requests
::
+$  fairness  ?(%none %wf %sf %wf-next)
::  mirrors pcal.trans -wf/-sf/-wfNext/-nof, -termination, -nocfg
+$  pcal-opts  [=fairness termination=? gen-cfg=?]
+$  analyze-flags  [syntax=? semantic=? level=? lint=?]
+$  check-mode
  $%  ::  `seed` is tlc2's `-seed` (R2.7.4.4), and it is NOT simulation-only:
      ::  `RandomEnumerableValues.setSeed(seed)` runs for BFS too, and it is
      ::  the only thing that makes a spec using `TLC!RandomElement`
      ::  reproducible -- without `-seed` tlc2 draws one from
      ::  `new Random().nextLong()` and does not even print it in the BFS
      ::  banner. The per-predecessor reseed is `fingerPrint ^ seed`, so a
      ::  reproducing run is pinned to the default FP64 index too (R2.6.2)
      [%exhaustive deadlock=? seed=@ud]
      ::  `generate` is tlc2's `-generate` (R2.4.6): the same seeded run with
      ::  PROBABILISTIC successor picking (`Tool.probabilistic`). It is a field
      ::  on this variant rather than a variant of its own because tlc2 spells
      ::  it that way too -- both flags set `RunMode.SIMULATE`, and every rule
      ::  that keys on simulation (the stage plan, `-difftrace`, the ALIAS
      ::  refusal) applies unchanged to both
      [%simulate seed=@ud num=@ud depth=@ud generate=?]
      ::  tlc2's `-dfid num` (R2.5): depth-first iterative deepening, a real
      ::  run mode rather than a flag on one -- `TLCGlobals.DFIDMax` plus
      ::  `RunMode.DFID`, which selects `DFIDModelChecker` over `ModelChecker`.
      ::  `depth` is the deepest LEVEL a sweep may reach; below 2 no sweep runs
      ::  at all, so 0 and 1 explore the initial states and stop. A run that
      ::  ends at the bound is `%limited %depth`, never `%ok` -- tlc2 prints no
      ::  completion line there, and reporting one would claim a search it did
      ::  not finish.
      ::
      ::  DFID does NOT support liveness and says so
      ::  (`DFIDModelChecker.java:67`, upstream issue 548); the refusal keys on
      ::  a GENUINE temporal property, so a `[]P` box-state one still runs, as
      ::  it does in tlc2
      [%dfid depth=@ud deadlock=?]
  ==
+$  check-opts
  $:  translate=?
      ::  tlc2's `-view` (R2.4.3): render every trace state as the VIEW's
      ::  VALUE instead of its bindings (`TLCGlobals.useView`). Needs a VIEW in
      ::  the config; without one it has nothing to render and is refused
      view=?
      ::  tlc2's `-difftrace` (R2.4.3): print only the bindings that CHANGED
      ::  from the previous state. Measured at the pin, this is honoured in
      ::  SIMULATION only -- an exhaustive run's output is byte-identical with
      ::  and without the flag -- so it is refused outside `%simulate`
      difftrace=?
      ::  tlc2's `-continue` (R2.4.2): keep searching past a violation and
      ::  report every one, instead of stopping at the first. The run then
      ::  COMPLETES, so `result` is still `%ok`/`%limited` and the
      ::  counterexamples arrive as a `%violations` artifact -- measured at the
      ::  pin, tlc2 prints `Model checking completed. No error has been found.`
      ::  after reporting them, because that line is about the search finishing
      continue=?
      ::  cfg source override (tlc2's `-config`): names one of an %inline
      ::  bundle's own sources to use as the config, replacing the bundle's
      ::  `cfg`. `~` uses the bundle's cfg. A %clay bundle selects its config
      ::  by PATH (`src.cfg`) instead, because the file's Clay mark is part of
      ::  the reference and a bare name cannot supply it
      cfg=(unit source-name)
      ::  tlc2's `-coverage` (R2.7.4.2b): report the per-action / per-constraint
      ::  coverage counters after the run. A BOOLEAN, not tlc2's interval
      ::  argument -- `TLCGlobals.coverageInterval` only gates PERIODIC
      ::  reporting, and the end-of-run block is byte-identical for
      ::  `-coverage 0`, `1` and `2` because a corpus-sized run never reaches
      ::  the interval. The interval is therefore a WALL-CLOCK behaviour, and
      ::  no reproducible run may observe the wall clock (the rule R2.6.1
      ::  applied to `TLCGet("duration")`), so the port has no field for it and
      ::  a caller who wants one is refused by name rather than served a number
      ::  that does nothing (R2.1)
      coverage=?
      mode=check-mode
  ==
+$  op
  $%  [%translate opts=pcal-opts]
      [%analyze flags=analyze-flags]
      [%check opts=check-opts]
  ==
+$  source-bundle
  $%  [%inline root=module-name modules=(map module-name @t) cfg=(unit @t)]
      $:  %clay
          =ship
          =desk
          cas=case
          ::  root module name; the file is <root-dir>/<lowercased-name>/tla
          root=module-name
          ::  cfg file path within the desk (the desk has no %cfg mark, so
          ::  a Clay-served cfg uses a non-.tla mark, e.g. /spec-cfg/txt)
          cfg=(unit path)
          ::  module-search root directories, tried in order
          roots=(list path)
      ==
  ==
::
::  +|  Async Source Loading (unit 10)
::
::  A pure stage may not read Clay; instead it returns tagged read-requests
::  and resumes when the agent delivers read-responses.
::
::  a canonical, escape-free reference to one Clay file. Unit 10.2 adds the
::  lib/source-path construction guard that rejects `..`/absolute/out-of-root
+$  source-ref  [=ship =desk cas=case =path]
::  one pending Clay read the kernel asks the agent to perform
+$  read-request   [tag=@ud =source-ref]
::  the agent's answer: text on success, a typed error message on failure
+$  read-response  [tag=@ud res=(each @t @t)]
::
+$  limits
  $:  max-source=@ud    ::  total source bytes
      max-modules=@ud
      max-states=@ud
      max-depth=@ud
      max-time=@dr
      max-artifact=@ud  ::  stored artifact bytes
      ::  the largest set a run may MATERIALIZE -- tlc2's `-maxSetSize`
      ::  (`TLCGlobals.setBound`, default 1,000,000). Exceeding it FAILS the
      ::  run in tlc2, so this is a parity bound and not only an ergonomic
      ::  one; 0 means the engine default (R2.4.1)
      max-set-size=@ud
  ==
+$  request
  $:  =op
      src=source-bundle
      =limits
      ::  where a terminal run's artifacts are written, if anywhere. `~` is
      ::  read-only, which is the default and was the ONLY behaviour before
      ::  R2.2. A boolean could not express this: "may write" says nothing
      ::  about WHERE, and an %inline bundle has no desk to infer one from
      write=(unit write-target)
      ::  tlc2's `-messagesAsErrors` (R2.4.5): diagnostic codes to PROMOTE to
      ::  errors. This is not a display concern -- measured at the pin,
      ::  promotion calls `Assert.fail` at the moment the diagnostic is
      ::  emitted (`MP.printWarning`), so the run ABORTS THERE and reports the
      ::  statistics it had reached, rather than restyling a message at the
      ::  end. A caller filtering severities off a completed run cannot
      ::  reproduce that: they would hold a finished run's result where tlc2
      ::  produced a partial one.
      ::
      ::  It lives on `request` rather than `check-opts` because it applies to
      ::  `%analyze` and `%check` alike. Only WARNINGS are promotable, which is
      ::  tlc2's rule too: `isTlcMessageAsError` is consulted in `printWarning`
      ::  and nowhere else, so promoting an error code or an info code is inert
      ::  in both. Measured: `-messagesAsErrors 2110` (an error) leaves the run
      ::  byte-identical
      promote=(set diag-code)
  ==
::  a write destination: the desk and the directory under it. The ship is
::  always our own — Clay cannot write to another ship's desk — and the
::  revision is always the head, so unlike a `source-ref` there is no case:
::  a write that landed at a pinned past revision would be meaningless.
::  Built only by `+write-ref:source-path`, which additionally refuses a
::  target that lies under the run's own read roots
+$  write-target  [=desk pax=path]
::
::  +|  Results
::
::  R2.7.1 splits what tlc2 reports as two distinct error codes and this wire
::  used to collapse into one. `initial` is TRUE for a violation found while
::  COMPUTING THE INITIAL STATES and FALSE for one found by a behavior:
::
::    invariant  EC 2107 `Invariant %1% is violated by the initial state:`
::               EC 2110 `Invariant %1% is violated.`
::    property   EC 2108 `Property %1% is violated by the initial state:`
::
::  The difference is not cosmetic. An initial-state violation has no behavior
::  and tlc2 prints no state-graph statistics for it, so a caller that cannot
::  tell them apart cannot know whether the `trace` it holds is a
::  counterexample or a single offending state -- the console report has always
::  distinguished them, and only the typed result did not.
::
::  `%deadlock`, `%liveness` and `%assumption` take no flag: a deadlock and a
::  liveness violation are properties of a behavior by construction, and an
::  ASSUME is checked before any state exists.
+$  violation
  $%  [%invariant name=@t initial=?]
      [%deadlock ~]
      [%property name=@t initial=?]
      ::  R2.7.13: an IMPLIED ACTION violation, tlc2's
      ::  TLC_ACTION_PROPERTY_VIOLATED_BEHAVIOR (EC 2112) -- a `[][A]_v`
      ::  PROPERTY whose A fails on some transition. It had been folded into
      ::  `[%property name %.n]`, which already carried EC 2116 (a temporal
      ::  property violated by a behavior), so one wire shape meant two of
      ::  tlc2's three property codes and a caller could not tell a broken
      ::  step from a broken behavior. R2.7.1 split 2107/2110 for invariants
      ::  and named this as wanting its own variant; this is that variant
      [%action name=@t]
      [%liveness name=@t]
      [%assumption name=@t]
  ==
+$  limit-kind  ?(%source %modules %states %depth %time %artifact %noun)
+$  run-stats
  $:  generated=@ud
      distinct=@ud
      queued=@ud
      depth=@ud
      ::  state-graph out-degree distribution, as TLC reports it: one sample
      ::  per dequeued state (its newly-distinct successor count), summarized
      ::  min / round(mean) / round(95th percentile) / max (R1.5.12b)
      outdeg=out-degree
  ==
+$  out-degree  [min=@ud mean=@ud p95=@ud max=@ud]
::  terminal results; a counterexample is never collapsed into %failed
+$  result
  $%  [%ok stats=run-stats]
      [%failed reason=@t]
      [%violated =violation stats=run-stats]
      [%cancelled ~]
      [%limited kind=limit-kind stats=run-stats]
  ==
::
::  +|  Jobs And Resumable Steps
::
+$  progress  [done=@ud total=@ud]
+$  job
  $:  =request
      =stage
      ::  stages not yet entered; drained one per bounded step
      pending=(list stage)
      =progress
      stats=run-stats
      ::  chronological
      diags=(list diagnostic)
      artifacts=(map artifact-name artifact)
      ::  set exactly once; ^ means terminal
      result=(unit result)
  ==
::  everything a step emits, in order; the agent fans these out as facts
+$  event
  $%  [%stage =stage]
      [%progress =progress]
      [%diagnostic =diagnostic]
      [%result =result]
  ==
::  one bounded slice of work: more work remains, or the job is terminal
::  (result distinguishes ok/failed/violated/cancelled/limited)
::
::  +|  Poke Actions
::
::  unit 13 adds %write-translation
+$  action
  $%  [%submit id=req-id =request]
      [%cancel id=req-id]
      [%delete-result id=req-id]
  ==
::
::  +|  Subscription Updates
::
+$  update
  $%  [%ack id=req-id]
      [%rejected id=req-id reason=@t]
      [%deleted id=req-id]
      [%job id=req-id =event]
  ==
--
