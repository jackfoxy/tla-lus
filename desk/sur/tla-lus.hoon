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
::  Bumped when a caller-visible noun changes. 1 = the unit-2 frozen wire;
::  2 = unit 10 — a %clay bundle's `root` is a module name (it was a
::  path), the async read nouns below exist, and `step-result` gained
::  %await. The action/update shells are unchanged.
++  api-version  2
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
      ::  sorted by var, +sort-bindings:diagnostics
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
  ==
::
::  +|  Requests
::
+$  fairness  ?(%none %wf %sf %wf-next)
::  mirrors pcal.trans -wf/-sf/-wfNext/-nof, -termination, -nocfg
+$  pcal-opts  [=fairness termination=? gen-cfg=?]
+$  analyze-flags  [syntax=? semantic=? level=? lint=?]
+$  check-mode
  $%  [%exhaustive deadlock=?]
      [%simulate seed=@ud num=@ud depth=@ud]
  ==
+$  check-opts
  $:  translate=?
      ::  cfg source override; ~ uses the bundle's cfg
      cfg=(unit source-name)
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
  ==
+$  request
  $:  =op
      src=source-bundle
      =limits
      ::  Clay is read-only unless the caller opts in; writing still
      ::  requires the explicit write action (unit 13)
      allow-write=?
  ==
::
::  +|  Results
::
+$  violation
  $%  [%invariant name=@t]
      [%deadlock ~]
      [%property name=@t]
      [%liveness name=@t]
      [%assumption name=@t]
  ==
+$  limit-kind  ?(%source %modules %states %depth %time %artifact %noun)
+$  run-stats
  $:  generated=@ud
      distinct=@ud
      queued=@ud
      depth=@ud
  ==
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
+$  step-result
  $%  [%more events=(list event) =job]
      [%stop events=(list event) =job]
      ::  a pure stage requests external Clay reads and pauses; the agent
      ::  performs them and resumes the job with the responses (unit 10)
      [%await events=(list event) reads=(list read-request) =job]
  ==
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
