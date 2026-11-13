/-  *tla-lus
/=  ast      /lib/ast
/=  syntax   /lib/syntax
/=  ev       /lib/eval
/=  config   /lib/config
/=  ne       /lib/node-eval
/=  fp       /lib/fingerprint
/=  sem-lib  /lib/semantic
/=  tp       /lib/temporal
/=  tb       /lib/tableau
/=  lv       /lib/liveness
/=  vl       /lib/value
/=  rng      /lib/rng
/=  diag     /lib/diagnostics
|%
  ::  TLC Safety Model Checking (deterministic single-worker BFS)
  ::
  ::  A first increment of unit 10: generate initial and next states from
  ::  the Init/Next predicates (the TLC assignment semantics for /\, \/,
  ::  =, \E, IF, and UNCHANGED), explore with deterministic breadth-first
  ::  search over fingerprinted states, check an invariant, detect
  ::  deadlock, and emit TLC's terminal summary (states generated /
  ::  distinct / depth) and, on an invariant violation, the shortest
  ::  behavior trace. Expression evaluation reuses lib/eval; a primed
  ::  variable x' reads the partial next-state binding stored under the
  ::  key "<name>'".
  ::
::  +|  Types
::
+$  node   syntax-node:ast
+$  value  value:ev
+$  state  (map @t value)   ::  variable -> value
::  a node in the reachability graph: state, its BFS depth, and the
::  fingerprint of its predecessor (for trace reconstruction)
+$  seen-entry  [depth=@ud pred=@t]
::
::  +|  Node Helpers
::
::
++  kids-of   kids-of:ev
++  is-kind   is-kind:ev
++  op-name   op-name:ev
++  genid-name  genid-name:ev
++  leaf-kind
  |=  n=node
  ^-  @tas
  ?>(?=(%leaf -.n) kind.token.n)
::
++  leaf-text
  |=  n=node
  ^-  @t
  ?>(?=(%leaf -.n) text.token.n)
::
::  +|  Fingerprinting
::
::
++  fingerprint
  ::  the canonical FP64 fingerprint of a state (Work Unit 7.1): FP64 extended
  ::  over each variable's WU6.8 fp-input bytes in `order` (TLC's declaration
  ::  order), matching TLCState.fingerPrint. The visited map is keyed by this
  ::  fingerprint — no rendered text is ever a key. Worn as `@t` only so the
  ::  existing @t-keyed seen/queue molds and the %live cursor are unchanged.
  |=  [order=(list @t) st=state]
  ^-  @t
  (@t (state-fp:fp order st))
::
::  +|  Config / Spec Extraction
::
::
++  body-of-def
  ::  the body expression of the operator definition named `nm`
  |=  [tree=node nm=@t]
  ^-  (unit node)
  ?.  (is-kind tree %n-module)  ~
  =/  b  (skim (kids-of tree) |=(k=node (is-kind k %n-body)))
  ?~  b  ~
  =/  defs
    %+  skim  (kids-of i.b)
    |=  u=node
    ?.  (is-kind u %n-operatordefinition)  |
    =(nm (def-name u))
  ?~  defs  ~
  `(rear (kids-of i.defs))
::
++  def-name
  |=  u=node
  ^-  @t
  =/  kids  (kids-of u)
  ?~  kids  ''
  =/  lhs  i.kids
  ?.  ?=(%node -.lhs)  ''
  =/  ids  (skim (kids-of lhs) |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~(ids '' (leaf-text i.ids))
::
++  var-names
  ::  the declared VARIABLE names of a module
  |=  tree=node
  ^-  (set @t)
  =/  b  (skim (kids-of tree) |=(k=node (is-kind k %n-module)))
  =/  body
    =/  bb  (skim (kids-of tree) |=(k=node (is-kind k %n-body)))
    ?~(bb ~ (kids-of i.bb))
  %-  ~(gas in *(set @t))
  %-  zing
  %+  turn  body
  |=  u=node
  ^-  (list @t)
  ?.  (is-kind u %n-variabledeclaration)  ~
  %+  murn  (kids-of u)
  |=  k=node
  ^-  (unit @t)
  ?.  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))  ~
  `(leaf-text k)
::
++  var-order
  ::  the declared VARIABLE names of a module in TLC's canonical (source
  ::  declaration) order, which fixes the FP64 state-fingerprint byte order
  |=  tree=node
  ^-  (list @t)
  =/  b  (skim (kids-of tree) |=(k=node (is-kind k %n-module)))
  =/  body
    =/  bb  (skim (kids-of tree) |=(k=node (is-kind k %n-body)))
    ?~(bb ~ (kids-of i.bb))
  %-  zing
  %+  turn  body
  |=  u=node
  ^-  (list @t)
  ?.  (is-kind u %n-variabledeclaration)  ~
  %+  murn  (kids-of u)
  |=  k=node
  ^-  (unit @t)
  ?.  &(?=(%leaf -.k) =(%identifier (leaf-kind k)))  ~
  `(leaf-text k)
::
++  elems  elems:ev
::
++  perms-of-value
  ::  a set of functions over model values, as the name-to-name bijections
  ::  the orbit machinery uses (unit 6C.5). ~ when a function is not a
  ::  model-value permutation
  |=  v=value
  ^-  (unit (list (map @t @t)))
  ?.  ?=(%set -.v)  ~
  =|  out=(list (map @t @t))
  =/  fs  p.v
  |-  ^-  (unit (list (map @t @t)))
  ?~  fs  `(flop out)
  ?.  ?=(%fcn -.i.fs)  ~
  =/  one
    =|  m=(map @t @t)
    =/  ps  p.i.fs
    |-  ^-  (unit (map @t @t))
    ?~  ps  `m
    ?.  ?&(?=(%model -.d.i.ps) ?=(%model -.r.i.ps))  ~
    $(ps t.ps, m (~(put by m) p.d.i.ps p.r.i.ps))
  ?~  one  ~
  $(fs t.fs, out [u.one out])
::
++  symmetry-perms
  ::  the permutation group for the SYMMETRY operator. The definition is
  ::  EVALUATED (so `Permutations` is the registry override, one
  ::  implementation shared with every other caller) and its value read as
  ::  model-value bijections; a definition that does not denote such a set
  ::  is a typed rejection rather than a silent loss of reduction
  |=  [defs=(map @t sem-def:sem-lib) consts=(map @t value) vars=(set @t) sym=(unit @t)]
  ^-  (each (list (map @t @t)) @t)
  ?~  sym  [%& ~]
  =/  b  (sem-body defs u.sym)
  ?~  b  [%| (rap 3 ~['SYMMETRY operator is not defined: ' u.sym])]
  =/  r  (eval:ne u.b (make-env:ne defs consts vars))
  ?:  ?=(%| -.r)  [%| msg.p.r]
  =/  ps  (perms-of-value p.r)
  ?~  ps
    [%| (rap 3 ~['SYMMETRY ' u.sym ' is not a set of model-value permutations'])]
  [%& u.ps]
::
++  cfg-names
  ::  the INIT/NEXT/first-INVARIANT/first-PROPERTY names from a .cfg via
  ::  the real config parser (unit 5); ~ when the cfg is malformed. Full
  ::  config-vs-graph validation is the job kernel's %config stage — these
  ::  engine helpers only need the target names off a well-formed cfg.
  |=  cfg=@t
  ^-  (unit [in=(unit @t) nx=(unit @t) iv=(unit @t) pp=(unit @t)])
  =/  pr  (parse-cfg:config cfg)
  ?:  ?=(%| -.pr)  ~
  =/  a  p.pr
  :-  ~
  :*  init.a
      next.a
      ?~(invariants.a ~ `i.invariants.a)
      ?~(properties.a ~ `i.properties.a)
  ==
::
::  +|  Breadth-First Exploration (resumable cursor, unit P2-1)
::
::
+$  visit  [depth=@ud pred=@t st=state]
+$  outcome
  ::  `viols` is non-empty only under `-continue` (R2.4.2): the search ran to
  ::  completion and reports EVERY violation it passed, in discovery order.
  ::  The verdict is still `%ok` -- measured at the pin, tlc2 prints
  ::  `Model checking completed. No error has been found.` even after
  ::  reporting violations, because that line is about the SEARCH completing
  $%  [%ok gen=@ud distinct=@ud queued=@ud depth=@ud viols=(list [name=@t trace=(list state)])]
      [%inv gen=@ud distinct=@ud queued=@ud depth=@ud trace=(list state) name=@t initial=?]
      ::  R2.7.15a: an IMPLIED ACTION violation -- tlc2's EC 2112. Its own
      ::  variant rather than `%inv` because the report line differs
      ::  (`Error: Action property <name> is violated.`) and the wire has
      ::  carried the distinction since R2.7.13's `[%action name]`. No
      ::  `initial` flag: `[][A]_v` is checked on a TRANSITION, so there is
      ::  always a predecessor
      [%action gen=@ud distinct=@ud queued=@ud depth=@ud trace=(list state) name=@t]
      [%deadlock gen=@ud distinct=@ud queued=@ud depth=@ud trace=(list state)]
      [%limited what=?(%states %depth) gen=@ud distinct=@ud queued=@ud depth=@ud]
      ::  a typed evaluation failure during the search (WU6.9). R4.2j: `ec` is
      ::  the pin's error code (0 when the port has none to report) and
      ::  `trace` the behavior tlc2 prints with it (`~` when it prints none)
      [%error msg=@t ec=@ud trace=(list state)]
  ==
::  one `Tool.getActions` leaf action: its name, its next-state body, and the
::  bound-variable CONTEXT the decomposition bound into it. Non-empty only for
::  an action split out of a constant-level `\E` (R2.4.6): tlc2 enumerates such
::  a bound at spec-processing time and emits one action per element, carrying
::  the binding in that action's `Context`
+$  act  [name=@t body=sem:sem-lib ctx=(map @t value)]
::  fixed parameters of one search
+$  bfs-opts
  ::  WU6.9: the search runs on Work Unit 3 SEMANTIC nodes via node-eval, not
  ::  the CST. `next`/`inv` are semantic bodies; `defs`/`consts` build the
  ::  evaluation context (operator definitions + config constant assignments).
  $:  next=sem:sem-lib
      invs=(list [name=@t body=sem:sem-lib])   ::  invariants, declaration order
      cons=(list sem:sem-lib)                  ::  state constraints (CONSTRAINT)
      acons=(list sem:sem-lib)                 ::  action constraints
      ::  R2.7.7.4b: `_POSSIBLE`'s predicates with their LEVELS. Not folded
      ::  into `cons`/`acons` because `_Track` must never prune -- it answers
      ::  TRUE whatever the predicate does, and only the count is kept
      poss=(list [name=@t body=sem:sem-lib lvl=@ud])
      vars=(set @t)
      order=(list @t)   ::  vars in TLC declaration order (FP64 byte order)
      perms=(list (map @t @t))   ::  symmetry group (empty = no symmetry)
      defs=(map @t sem-def:sem-lib)
      consts=(map @t value)
      deadlock=?     ::  report deadlocked states as violations
      cap=@ud        ::  distinct-state bound (0 = unbounded)
      maxd=@ud       ::  graph-depth bound (0 = unbounded)
      ::  VIEW body, if the config declares one. A state's IDENTITY is then
      ::  the fingerprint of this expression's value rather than of its
      ::  bindings, so a view changes `distinct`, the graph's shape, and
      ::  whether a run terminates (R2.3.1)
      view=(unit sem:sem-lib)
      ::  the run's `max-set-size` (tlc2 `-maxSetSize`); 0 = engine default.
      ::  Carried here because `+env-of` is where the search's evaluation
      ::  context is built (R2.4.1)
      setmax=@ud
      ::  tlc2's `-continue` (R2.4.2): keep searching past a violation instead
      ::  of stopping at the first. Measured at the pin, the violating state is
      ::  still ENQUEUED -- the same spec reports a violation at depth 3 AND at
      ::  depth 4, and depth 4 is only reachable THROUGH the depth-3 violator
      cont=?
      ::  R2.7.4.2b: the getActions decomposition, built ONCE by the caller
      ::  (which usually needs it for trace labels anyway) instead of rebuilt
      ::  per `+bfs-step` call. `~` means "build it here", which the paths that
      ::  do not have one yet still rely on
      acts=(list act)
      ::  everything the coverage block needs that the search does not
      ::  otherwise carry (R2.7.4.2b)
      cov=cov-opts
      ::  tlc2's `-seed` (R2.7.4.4). `RandomEnumerableValues.setSeed(seed)` is
      ::  called for BFS as well as simulation, and it is the ONLY thing that
      ::  makes a `RandomElement` run reproducible: without it tlc2 draws a
      ::  seed from `new Random().nextLong()` and does not even print it in the
      ::  BFS banner. The per-predecessor reseed is `fingerPrint ^ seed`, so a
      ::  reproducing run is pinned to `-fp 0` as well (R2.6.2)
      seed=@ud
      ::  R2.7.15a: IMPLIED ACTIONS -- the `A` of each `[][A]_v` PROPERTY,
      ::  checked on EVERY TRANSITION. tlc2 checks them inside the search
      ::  (`Tool.getImpliedActions`), so a violation stops it and the counts
      ::  reported are the ones standing at that moment. The port used to build
      ::  the whole reachability graph and then scan it (`+implied-action-run`,
      ::  retired with this), which got the verdict and trace right and the
      ::  COUNTS wrong -- 5/4/depth 4 against the pin's 2/2/2 on
      ::  `prop-act-viol`. `implied-act-viol` could not see it: its violation is
      ::  on the LAST transition, where a completed graph and a stopped one
      ::  agree.
      ::
      ::  Beside `acons` and not folded into it: an action CONSTRAINT prunes
      ::  the transition, an implied action REPORTS it. Same hook, opposite
      ::  answer to a false predicate
      iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
      ::  R4.P5c: key `seen` on the identity key (`+state-key:fp`) rather than
      ::  FP64. Only where no output reads a fingerprint: set for the safety
      ::  search of a spec that never draws (`+draws`), never for a temporal
      ::  graph build (lasso choice follows map order) or a spec whose
      ::  per-state reseed is `fingerPrint ^ seed`. `_|`: off unless asked
      hkey=_|
      ::  R4.QS: the constant definitions `+with-cdefs:ne` evaluated, carried
      ::  so that `+env-of` does not depend on its `~+` entry surviving a
      ::  slice: per-state memo entries evict it, and EWD998ChanID re-ran
      ::  them for 13 s at every slice. Empty: `+env-of` evaluates them
      cd=(map @t [def=sem-def:sem-lib val=value])
  ==
::
+$  cov-opts
  ::  tlc2's `-coverage` (R2.7.4.2b). `on` gates the COUNTING, not just the
  ::  reporting: a run without it pays nothing.
  ::
  ::  There is no INTERVAL here on purpose. `TLCGlobals.coverageInterval` only
  ::  gates PERIODIC reporting -- measured at the pin, the end-of-run block is
  ::  byte-identical for `-coverage 0`, `1` and `2`, because a corpus-sized run
  ::  never reaches the interval -- so the interval is a WALL-CLOCK behaviour,
  ::  and no reproducible run may observe the wall clock (the rule R2.6.1
  ::  applied to `TLCGet("duration")`). The port takes coverage as on/off and
  ::  refuses an interval BY NAME at submit, rather than accepting a number and
  ::  ignoring it, which is the silent option R2.1 forbids
  ::  `_|` and not `?`: the loobean BUNT is `%.y`, so a plain `*cov-opts` would
  ::  turn coverage ON for every path that defaults this record -- which is
  ::  every path except the safety search the option reaches
  $:  on=_|
      ::  the root module's name, for the labels
      modn=@t
      ::  the INIT operator's name, and its two counts -- both known before the
      ::  search starts. `gen` is the initial states the predicate produced
      ::  (`Tool.getInitStates`'s `addElement`), `rej` the candidates it
      ::  rejected once they were ALREADY FULLY ASSIGNED (the `allAssigned`
      ::  branch's `incSecondary`), which arrives on the R2.7.4.1a carrier as
      ::  `irej`. A rejection while a variable is still unassigned counts
      ::  nothing: `x \in 0..3 /\ y = 0 /\ x > 1` reports `2:4`, the same
      ::  conjuncts reordered `2:2`
      iname=@t
      cvi=[gen=@ud rej=@ud]
      ::  CONSTRAINT / ACTION_CONSTRAINT names, index-aligned with `cons` and
      ::  `acons`. Names rather than a reshaped `cons` mold: the counters are
      ::  keyed by index anyway, and `(list sem)` is threaded through the
      ::  simulation and DFID engines too
      cnames=(list @t)
      anames=(list @t)
  ==
::
++  env-of
  ::  the node-eval evaluation context for a search
  |=  o=bfs-opts
  ^-  eenv:ne
  (with-setmax:ne (cenv-of o) setmax.o)
::
++  cenv-of
  ::  R4.QS: `+make-env:ne` on the search's inputs, from the constant
  ::  definitions the options carry when they carry them
  |=  o=bfs-opts
  ^-  eenv:ne
  ?~  cd.o  (make-env:ne defs.o consts.o vars.o)
  (make-env-cd:ne defs.o consts.o vars.o cd.o)
::
++  run-stats-at
  ::  the live `TLC!TLCGet` statistics for the state about to be expanded
  ::  (R2.6.1). Read BEFORE its successors are registered, which is where the
  ::  pin reads them: `TLCGetStringValue` runs while the next-state relation is
  ::  being evaluated, and `numOfGenStates`/`theFPSet` have not yet taken this
  ::  expansion's successors
  |=  [cur=bfs-cursor lvl=@ud]
  ^-  tlc-run:so:ne
  [| lvl `[depth.cur distinct.cur len.queue.cur gen.cur]]
::
++  env-at
  ::  `+env-of` carrying those statistics
  |=  [o=bfs-opts cur=bfs-cursor lvl=@ud]
  ^-  eenv:ne
  (with-run:ne (env-of o) (run-stats-at cur lvl))
::  everything required to resume a search byte-identically
+$  bfs-cursor
  $:  init-todo=(list state)  ::  initial states not yet registered
      queue=fifo              ::  frontier fingerprints, BFS order
      seen=(map @t visit)
      ::  registered initial states, NEWEST FIRST (R4.P1: a `snoc` per initial
      ::  state was O(inits)); readers `flop` it back to registration order
      inits=(list @t)
      gen=@ud
      distinct=@ud
      depth=@ud
      ::  out-degree samples as TLC collects them: one per DEQUEUED state, the
      ::  count of its newly-distinct successors (Worker.outDegree.addSample of
      ::  unseenSuccessorStates). A bucket histogram (sample -> count), which is
      ::  what tlc2's BucketStatistics keeps, so min/mean/95th/max all derive
      ::  from it rather than only the max (R1.5.12b)
      outdeg=(map @ud @ud)
      ::  violations passed so far under `-continue` (R2.4.2), as
      ::  [invariant-name, violating state's fingerprint] in discovery order.
      ::  Fingerprints rather than traces: the cursor is PERSISTED and bounded
      ::  by `max-noun-bytes`, and every trace is rebuildable from `seen`
      viols=(list [name=@t fp=@t])
      ::  R2.7.4.2b: per-ACTION coverage counters, keyed by the action's index
      ::  in `acts.o`. `gen` is every successor that action produced (tlc2's
      ::  `Worker.addElement` -> `cm.incInvocations()`, counted BEFORE any
      ::  constraint filtering); `dis` is how many of them were newly distinct
      ::  (`incSecondary`, only when the fingerprint was unseen). Measured at
      ::  the pin, two actions that generate the SAME successor both count it
      ::  in `gen` and the `dis` credit goes to whichever ran first, which is
      ::  why this is counted here and not re-solved afterwards (R2.7.4.0)
      cvn=(map @ud [gen=@ud dis=@ud])
      ::  R2.7.4.2b: per-CONSTRAINT coverage counters, keyed by the
      ::  constraint's index in `cons.o` / `acons.o`. `Tool.isInModel` and
      ::  `Tool.isInActions` count the OPPOSITE way round from an action:
      ::  `pri` (`incInvocations`) counts the evaluations that came back
      ::  FALSE, `sec` (`incSecondary`) the ones that came back TRUE, and the
      ::  reported pair is `sec : pri + sec`. Both loops short-circuit on the
      ::  first false constraint, so a later constraint is not evaluated at all
      ::  -- which is why these are tallied where the loop runs
      cvc=(map @ud [pri=@ud sec=@ud])
      cva=(map @ud [pri=@ud sec=@ud])
      ::  R2.7.4.3/.4: the R2.7.4.1 CARRIER, run-scoped, on the cursor rather
      ::  than inside an evaluation -- because the pin's state is a worker
      ::  field that outlives every expansion.
      ::
      ::  `regs` is `TLC!TLCSet`'s register store: measured,
      ::  `TLCSet(0, TLCGet(0) + 1)` counts 100, 101, 102, 103 across
      ::  successive states, and a write made while solving the INITIAL states
      ::  is still there when `Next` first runs.
      ::
      ::  `es` is `RandomEnumerableValues`'s generator. It is NOT run-scoped
      ::  the way `regs` is: `TLCStateRandom.initialize` reseeds it to
      ::  `state.fingerPrint() ^ randomSeed` ONCE PER PREDECESSOR STATE and
      ::  then leaves it alone, so every draw made while expanding that state
      ::  -- across all its actions and all conjuncts -- comes from one
      ::  advancing stream. `+bfs-step` reseeds it when it dequeues a state.
      ::
      ::  Neither is part of the checked state: neither enters a fingerprint,
      ::  and two states differing only in them are the same state
      rs=rst:ne
      ::  R4.Q8: each state's successor keys, REVERSED, deduplicated in first-
      ::  occurrence order, constraint-pruned transitions excluded -- recorded
      ::  on a liveness graph build (FP64 keys, `!hkey`), so the product build
      ::  reads the edges instead of solving every state's successors again
      ::  (tlc2's LiveCheck records them while the search runs)
      succ=(map @t (list @t))
  ==
+$  bfs-slice
  $%  [%more cur=bfs-cursor]
      [%done out=outcome cur=bfs-cursor]
  ==
::
++  bfs-init
  ::  a fresh cursor over the already-solved initial states (init solving
  ::  happens once at %config, so its typed failures surface immediately);
  ::  registration is budgeted in +bfs-step
  |=  is=(list state)
  ^-  bfs-cursor
  [is *fifo ~ ~ (lent is) 0 0 ~ ~ ~ ~ ~ empty-rst:ne ~]
::
::  R4.P1 (H1/H2): the BFS frontier as a two-list FIFO with its length kept,
::  so enqueue, dequeue and the `states left on queue` count are O(1)
::  (amortized). A `(list @t)` made each `snoc` and each per-state `lent`
::  O(queue), quadratic over a run (measured: c = 5.2e-8 s/state^2)
+$  fifo  [front=(list @t) back=(list @t) len=@ud]
++  fi-put
  |=  [q=fifo x=@t]
  ^-  fifo
  q(back [x back.q], len +(len.q))
++  fi-pop
  |=  q=fifo
  ^-  (unit [i=@t q=fifo])
  =?  q  ?=(~ front.q)  q(front (flop back.q), back ~)
  ?~  front.q  ~
  `[i.front.q [t.front.q back.q (dec len.q)]]
::
++  bfs-init-regs
  ::  a fresh cursor that INHERITS the carrier the initial-state solve already
  ::  built (R2.7.4.3/.4): `Init == x = 0 /\ TLCSet(0, 100)` must leave 100
  ::  visible to the first `Next`, and the solve happens once at %config,
  ::  before any cursor exists. The init phase's advanced `es` comes along for
  ::  the same reason, though `+bfs-step` reseeds it per predecessor state
  |=  [is=(list state) rs=rst:ne]
  ^-  bfs-cursor
  =/  c  (bfs-init is)
  c(rs rs)
::
++  con-hold
  ::  do all state constraints (CONSTRAINT) hold on `st`? (each bool / eval err)
  |=  [cs=(list sem:sem-lib) st=state e=eenv:ne]
  ^-  (each ? @t)
  =/  r  (con-hold-n cs st e)
  ?:(?=(%| -.r) r [%& ok.p.r])
::
++  con-hold-n
  ::  `+con-hold` also reporting HOW MANY constraints it evaluated, which is
  ::  what the coverage tally needs: `Tool.isInModel` walks the constraint
  ::  vector and returns on the first FALSE one, so constraints `0 ..< n-1`
  ::  were TRUE (`incSecondary`) and, when `ok` is false, constraint `n-1` was
  ::  FALSE (`incInvocations`). Constraints past that were not evaluated at all
  |=  [cs=(list sem:sem-lib) st=state e=eenv:ne]
  ^-  (each [ok=? n=@ud] @t)
  =/  n=@ud  0
  |-  ^-  (each [ok=? n=@ud] @t)
  ?~  cs  [%& & n]
  =/  r  (pred-bool:ne i.cs st ~ e)
  ?:  ?=(%| -.r)  [%| msg.p.r]
  ?.  p.r  [%& | +(n)]
  $(cs t.cs, n +(n))
::
++  acon-hold
  ::  do all action constraints (ACTION_CONSTRAINT) hold on the transition
  ::  cur -> nxt? (an action-level predicate: cur under plain names, nxt primed)
  |=  [cs=(list sem:sem-lib) cur=state nxt=state e=eenv:ne]
  ^-  (each ? @t)
  =/  r  (acon-hold-n cs cur nxt e)
  ?:(?=(%| -.r) r [%& ok.p.r])
::
++  acon-hold-n
  ::  `+acon-hold` with the same evaluated-count as `+con-hold-n`
  ::  (`Tool.isInActions` short-circuits identically)
  |=  [cs=(list sem:sem-lib) cur=state nxt=state e=eenv:ne]
  ^-  (each [ok=? n=@ud] @t)
  =/  n=@ud  0
  |-  ^-  (each [ok=? n=@ud] @t)
  ?~  cs  [%& & n]
  =/  r  (pred-bool:ne i.cs cur nxt e)
  ?:  ?=(%| -.r)  [%| msg.p.r]
  ?.  p.r  [%& | +(n)]
  $(cs t.cs, n +(n))
::
++  poss-key  ^~(`@t`'s:_possible')
::
++  track-possible
  ::  `_Possible!_Track(P, "P")` (R2.7.7.4b), natively rather than through the
  ::  synthetic module `SpecProcessor.processConfigPossible` generates. The
  ::  vendored body is
  ::
  ::    _Track(expr, name) == TLCSet("s:_possible", <update>(TLCGetOrDefault(
  ::                            "s:_possible", <<>>), expr))
  ::
  ::  where the update INCREMENTS the name's count when `expr` is TRUE and
  ::  otherwise ensures the name is PRESENT at 0 (`old @@ (name :> 0)` keeps an
  ::  existing count, since `@@` prefers the left). So a never-witnessed
  ::  predicate ends at 0 rather than absent, and `_CheckName` fails on either.
  ::
  ::  It is wired as a CONSTRAINT at the pin, which is why it always answers
  ::  TRUE -- it must never prune. This arm therefore returns only the carrier:
  ::  the predicate's own truth value is counted, never propagated.
  |=  [ps=(list [name=@t body=sem:sem-lib lvl=@ud]) st=state nxt=(unit state) e=eenv:ne rs=rst:ne]
  ^-  rst:ne
  ?~  ps  rs
  =/  rec  (~(gut by named.rs) poss-key `value`[%fcn ~])
  =^  r  rs
    ?~  nxt  (pred-bool-rs:ne body.i.ps st ~ e rs)
    (pred-bool-rs:ne body.i.ps st u.nxt e rs)
  ::  an evaluation FAILURE is not a witness and not a crash: the pin evaluates
  ::  this inside a constraint, where a throw would end the run -- but nothing
  ::  in the corpus reaches it, so it is counted as not-witnessed rather than
  ::  guessed at
  =/  hit=?  &(?=(%& -.r) p.r)
  ::  narrowed ONCE: the union does not survive into the later expressions
  =/  pairs=(list vpair:vl)  ?:(?=(%fcn -.rec) p.rec ~)
  =/  key=value  [%str name.i.ps]
  =/  cur=@ud
    =/  f  (skim pairs |=(v=vpair:vl =(d.v key)))
    ?~(f 0 ?:(?=(%int -.r.i.f) (abs:si p.r.i.f) 0))
  =/  nv=@ud  ?:(hit +(cur) cur)
  =/  others  (skip pairs |=(v=vpair:vl =(d.v key)))
  ::  the record is kept in canonical (sorted-domain) order, as every other
  ::  `%fcn` this engine builds is
  =.  named.rs
    %+  ~(put by named.rs)  poss-key
    :-  %fcn
    %+  sort  `(list vpair:vl)`[[key `value`[%int (sun:si nv)]] others]
    |=([a=vpair:vl b=vpair:vl] (vlth:vl d.a d.b))
  $(ps t.ps, rs rs)
::
++  con-hold-rs
  ::  `+con-hold-n` carrying the R2.7.4.3 register store: a CONSTRAINT may
  ::  contain a `TLCSet`, and at the pin that write lands in the same store
  ::  the next-state relation reads
  |=  [cs=(list sem:sem-lib) st=state e=eenv:ne rs=rst:ne]
  ^-  [(each [ok=? n=@ud] @t) rst:ne]
  =/  n=@ud  0
  |-  ^-  [(each [ok=? n=@ud] @t) rst:ne]
  ?~  cs  [[%& & n] rs]
  =^  r  rs  (pred-bool-rs:ne i.cs st ~ e rs)
  ?:  ?=(%| -.r)  [[%| msg.p.r] rs]
  ?.  p.r  [[%& | +(n)] rs]
  $(cs t.cs, n +(n))
::
++  acon-hold-rs
  ::  `+acon-hold-n` carrying the register store
  |=  [cs=(list sem:sem-lib) cur=state nxt=state e=eenv:ne rs=rst:ne]
  ^-  [(each [ok=? n=@ud] @t) rst:ne]
  =/  n=@ud  0
  |-  ^-  [(each [ok=? n=@ud] @t) rst:ne]
  ?~  cs  [[%& & n] rs]
  =^  r  rs  (pred-bool-rs:ne i.cs cur nxt e rs)
  ?:  ?=(%| -.r)  [[%| msg.p.r] rs]
  ?.  p.r  [[%& | +(n)] rs]
  $(cs t.cs, n +(n))
::
++  first-violated-rs
  ::  `+first-violated` carrying the register store: an INVARIANT may write it
  ::  too, and `Tool.isValid` evaluates under the ordinary evaluator
  |=  [ivs=(list [name=@t body=sem:sem-lib]) st=state e=eenv:ne rs=rst:ne]
  ^-  [(unit (each @t @t)) rst:ne]
  ?~  ivs  [~ rs]
  =^  r  rs  (pred-bool-rs:ne body.i.ivs st ~ e rs)
  ?:  ?=(%| -.r)  [`[%| msg.p.r] rs]
  ?.  p.r  [`[%& name.i.ivs] rs]
  $(ivs t.ivs)
::
++  cov-tally
  ::  fold one constraint-loop outcome into a per-index counter map: the first
  ::  `n-1` constraints came back TRUE, and the `n`th came back FALSE when the
  ::  loop stopped early. A no-op when coverage is off, so a plain run pays
  ::  only the branch
  |=  [m=(map @ud [pri=@ud sec=@ud]) on=? ok=? n=@ud]
  ^-  (map @ud [pri=@ud sec=@ud])
  ?.  on  m
  =/  trues  ?:(ok n (dec n))
  =/  i=@ud  0
  |-  ^-  (map @ud [pri=@ud sec=@ud])
  ?:  =(i trues)
    ?:  ok  m
    =/  h=[pri=@ud sec=@ud]  (~(gut by m) i [0 0])
    (~(put by m) i [+(pri.h) sec.h])
  =/  h=[pri=@ud sec=@ud]  (~(gut by m) i [0 0])
  $(i +(i), m (~(put by m) i [pri.h +(sec.h)]))
::
++  od-stats
  ::  tlc2.util.statistics.BucketStatistics over the out-degree histogram,
  ::  reported by ModelChecker as `min, round(mean), round(p95), max`
  ::  (ModelChecker.java:890). Empty (no state dequeued) renders all zeros --
  ::  TLC only prints the line when getObservations() > 0. R1.5.12b
  |=  h=(map @ud @ud)
  ^-  [min=@ud mean=@ud p95=@ud max=@ud]
  =/  ks  (sort ~(tap in ~(key by h)) lth)
  ?~  ks  [0 0 0 0]
  =/  obs  (roll ~(val by h) add)
  ?:  =(0 obs)  [0 0 0 0]
  ::  largest observed sample (the list is ascending; walked rather than
  ::  +rear'd, which nest-fails on a ?~-narrowed list)
  =/  mx
    =/  l=(list @ud)  t.ks
    =/  m=@ud  i.ks
    |-  ^-  @ud
    ?~  l  m
    $(l t.l, m i.l)
  ::  getMean: sum(sample * count) / observations, then Math.round (half up)
  =/  sum
    %+  roll  ~(tap by h)
    |=([[k=@ud v=@ud] a=@ud] (add a (mul k v)))
  =/  mean  (div (add (mul 2 sum) obs) (mul 2 obs))
  ::  getPercentile(.95): pos = (int)(obs * .95), then the first bucket (in
  ::  ascending sample order) at which the running count EXCEEDS pos
  =/  pos  (div (mul obs 95) 100)
  =/  p95
    =/  l=(list @ud)  ks
    =/  cnt=@ud  0
    |-  ^-  @ud
    ?~  l  mx
    =.  cnt  (add cnt (~(gut by h) i.l 0))
    ?:((gth cnt pos) i.l $(l t.l))
  [i.ks mean p95 mx]
::
++  first-decimal
  ::  the text of the first decimal literal anywhere in a parse tree, `~` if
  ::  there is none (R2.7.3).
  ::
  ::  tlc2 rejects a decimal at SPEC PROCESSING, not at evaluation:
  ::  `SpecProcessor.processConstantDefns` fails on a `DecimalKind` node. So the
  ::  scope is the whole module, not the reachable definitions -- measured at
  ::  the pin, an UNUSED `Dec == 1.5`, a decimal inside an action-level `Next`
  ::  and one inside an unused state-level definition all abort the run before
  ::  any state is computed. The port used to reject at evaluation, which meant
  ::  a spec with an unused decimal RAN here and ABORTED there: not a difference
  ::  of timing but of VERDICT
  |=  n=node
  ^-  (unit @t)
  ::  every leaf under the node, joined: `+num-value` takes only the FIRST,
  ::  which is the integer part -- `1.5` came back as `1`
  ?:  (is-kind n %n-real)  `(real-text n)
  =/  ks  (kids-of n)
  |-  ^-  (unit @t)
  ?~  ks  ~
  =/  hit  (first-decimal i.ks)
  ?^  hit  hit
  $(ks t.ks)
::
++  err-lines
  ::  a typed failure rendered as TLC's console lines. Most carry one line, but
  ::  a few of the pin's templates are MULTI-LINE -- EC 2244's is
  ::  `TLC can't handle real numbers.\n%1%` -- and collapsing those into one
  ::  cord printed the literal on the same line as the message (R2.7.3)
  |=  msg=@t
  ^-  wain
  =/  t=tape  (trip (cat 3 'Error: ' msg))
  =|  cur=tape
  =|  out=wain
  |-  ^-  wain
  ?~  t  (flop [(crip (flop cur)) out])
  ?:  =(10 i.t)
    $(t t.t, cur ~, out [(crip (flop cur)) out])
  $(t t.t, cur [i.t cur])
::
++  real-text
  ::  the full text of an N_Real, reassembled from its leaves
  |=  n=node
  ^-  @t
  %+  rap  3
  %+  turn  (skim (kids-of n) |=(k=node ?=(%leaf -.k)))
  |=(k=node (leaf-text k))
::
++  decimal-error
  ::  the pinned EC 2244 failure for a spec carrying a decimal literal
  |=  txt=@t
  ^-  @t
  (ec-body:diag 2.244 ~[txt])
::
++  first-violated
  ::  the first invariant (declaration order) violated by `st`; ~ = all hold,
  ::  [%& name] = violated, [%| msg] = an evaluation error during the check
  |=  [ivs=(list [name=@t body=sem:sem-lib]) st=state e=eenv:ne]
  ^-  (unit (each @t @t))
  ?~  ivs  ~
  =/  r  (pred-bool:ne body.i.ivs st ~ e)
  ?:  ?=(%| -.r)  `[%| msg.p.r]
  ?.  p.r  `[%& name.i.ivs]
  $(ivs t.ivs)
::
++  first-bad-action
  ::  the first IMPLIED ACTION (declaration order) broken by the transition
  ::  cur -> nxt; ~ = all hold, [%& name] = violated, [%| msg] = an evaluation
  ::  error. The shape `+first-violated` has, over a transition rather than a
  ::  state -- `Tool.isValid(impliedAction, curState, succState)`
  ::  R2.7.15b: the SQUARE action, not the bare one. `[A]_v` is
  ::  `A \/ UNCHANGED v`, so a step that leaves the subscript alone satisfies
  ::  it whatever `A` says -- checking `A` by itself reported a violation on
  ::  every stuttering step, on this engine and on DFID alike
  |=  [ias=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)]) cur=state nxt=state e=eenv:ne]
  ^-  (unit (each @t @t))
  ?~  ias  ~
  =/  r  (pred-bool:ne body.i.ias cur nxt e)
  ?:  ?=(%| -.r)  `[%| msg.p.r]
  ?:  p.r  $(ias t.ias)
  ::  `A` failed, so the step violates `[A]_v` only if the SUBSCRIPT CHANGED.
  ::  An unevaluable subscript is the run's own typed error, as an unevaluable
  ::  `A` is -- it is not read as "unchanged"
  ::  no subscript in the graph: fall back to reporting on `A` alone, which is
  ::  what every consumer did before R2.7.15b. Recorded rather than guessed --
  ::  comparing the WHOLE STATE instead would report violations tlc2 does not
  ::  whenever `v` is a strict subset of the variables
  ?~  sub.i.ias  `[%& name.i.ias]
  =/  s0  (eval:ne u.sub.i.ias e(s0 cur, s1 nxt, primed |))
  ?:  ?=(%| -.s0)  `[%| msg.p.s0]
  =/  s1  (eval:ne u.sub.i.ias e(s0 cur, s1 nxt, primed &))
  ?:  ?=(%| -.s1)  `[%| msg.p.s1]
  ?:  =(p.s0 p.s1)  $(ias t.ias)
  `[%& name.i.ias]
::
++  register
  ::  admit one generated state at depth `d`. TLC order: a state pruned by a
  ::  CONSTRAINT (or a transition pruned by an ACTION_CONSTRAINT) is not
  ::  enqueued; a first-seen in-model state is enqueued and checked against the
  ::  invariants in declaration order. `prev` is the predecessor state (~ for an
  ::  initial state), needed to evaluate action constraints. A CONSTRAINT-pruned
  ::  state is not enqueued or counted, but TLC still checks its invariants, so a
  ::  violation on the pruned boundary is reported (R1.5.1).
  |=  [o=bfs-opts cur=bfs-cursor st=state d=@ud pred=@t prev=(unit state)]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  =/  e  (env-of o)
  ::  R4.2c: the constraints see the run too -- `TLCGet("level")` in a
  ::  CONSTRAINT is the level of the state being checked (measured: `Lvl ==
  ::  TLCGet("level") < 4` keeps 3 distinct states). Without the run it read
  ::  the constant-context 0, so such a constraint pruned nothing
  =/  ce  (with-run:ne e [| d `[depth.cur distinct.cur len.queue.cur gen.cur]])
  ::  the CONSTRAINT counters are tallied where the loop runs (R2.7.4.2b):
  ::  tlc2 counts a FALSE constraint as the primary and a TRUE one as the
  ::  secondary, and its loop stops at the first false, so a later constraint
  ::  contributes nothing for this state
  ::  R2.7.7.4b: `_POSSIBLE`'s STATE-level predicates are model constraints at
  ::  the pin, evaluated by `isInModel` for EVERY discovered state -- including
  ::  a terminal one, which is the pin's stated reason for not routing them
  ::  through action constraints. Tracked BEFORE the constraint check, since a
  ::  constraint-pruned state was still discovered
  =.  rs.cur  (track-possible (skim poss.o |=([* * l=@ud] (lte l 1))) st ~ e rs.cur)
  =^  ch  rs.cur  (con-hold-rs cons.o st ce rs.cur)
  ?:  ?=(%| -.ch)  [`[%error p.ch 0 ~] cur]
  =.  cvc.cur  (cov-tally cvc.cur on.cov.o ok.p.ch n.p.ch)
  ?.  ok.p.ch  (check-pruned o cur st pred e d)
  ?^  prev
    ::  and the ACTION-level ones are action constraints, evaluated on every
    ::  transition
    =.  rs.cur  (track-possible (skim poss.o |=([* * l=@ud] (gth l 1))) u.prev `st e rs.cur)
    =^  ah  rs.cur  (acon-hold-rs acons.o u.prev st ce rs.cur)
    ?:  ?=(%| -.ah)  [`[%error p.ah 0 ~] cur]
    =.  cva.cur  (cov-tally cva.cur on.cov.o ok.p.ah n.p.ah)
    ?.  ok.p.ah  [~ cur]
    ::  R2.7.15a: the IMPLIED ACTIONS, at the same hook and with the opposite
    ::  answer to a false predicate -- an action CONSTRAINT prunes the
    ::  transition, an implied action REPORTS it and stops the search. The
    ::  counts are therefore the ones standing HERE, which is the whole point:
    ::  `+implied-action-run` reported a completed graph's instead
    ::  the IMPLIED ACTIONS are checked inside `+register-in`, after the
    ::  invariants and before the enqueue -- see the note there
    (register-in o cur st d pred e prev)
  (register-in o cur st d pred e prev)
::
++  check-pruned
  ::  a CONSTRAINT-pruned state: check its invariants (declaration order) but do
  ::  not dedup, count, or enqueue it. A violation ends the run; the trace is the
  ::  predecessor's behavior extended by this state (it is absent from `seen`).
  |=  [o=bfs-opts cur=bfs-cursor st=state pred=@t e=eenv:ne d=@ud]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  ::  a CONSTRAINT-pruned state is not counted or entered, so the statistics it
  ::  sees are the ones standing before it (R2.6.1)
  =/  ie  (with-run:ne e [| d `[depth.cur distinct.cur len.queue.cur gen.cur]])
  =^  iv  rs.cur  (first-violated-rs invs.o st ie rs.cur)
  ?~  iv  [~ cur]
  ::  R4.2j: an invariant that fails to EVALUATE is tlc2's EC 2103 (`The
  ::  error occurred when TLC was evaluating the nested expressions ...`),
  ::  whose cause is the evaluation message
  ?:  ?=(%| -.u.iv)  [`[%error p.u.iv 2.103 ~] cur]
  :_  cur
  :-  ~
  :*  %inv  gen.cur  distinct.cur  len.queue.cur  depth.cur
      (weld (trace-to seen.cur pred) ~[st])  p.u.iv  =('' pred)
  ==
::
++  register-in
  ::  the in-model path: dedup, depth bound, ordered invariant check, the
  ::  IMPLIED ACTIONS (R2.7.15b -- both before the enqueue), then enqueue.
  ::  `prev` is the PREDECESSOR STATE, `~` for an initial state: an implied
  ::  action is a predicate over a transition and there is none into an
  ::  initial state, which is why tlc2 checks them in `doNext` and not in
  ::  `getInitStates`
  |=  [o=bfs-opts cur=bfs-cursor st=state d=@ud pred=@t e=eenv:ne prev=(unit state)]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  ::  the state's identity is its symmetry-orbit representative (7.5); with no
  ::  symmetry group `canon` is `st` and `fp` is the plain FP64 state fingerprint
  =/  cst  (canonicalize:fp perms.o order.o st)
  ::  under a VIEW the identity is the view's VALUE, evaluated on the
  ::  symmetry representative — tlc2's order exactly (R2.3.1). A view that
  ::  fails to evaluate falls back to the plain fingerprint rather than
  ::  silently conflating states
  =/  fp=@t
    ?~  view.o  (state-id o cst)
    =/  vr  (eval:ne u.view.o e(s0 cst, s1 cst, primed |))
    ?:  ?=(%| -.vr)  (state-id o cst)
    ?:  hkey.o  (@t (view-key:fp p.vr))
    (@t (view-fp:fp p.vr))
  ::  R2.7.15b: the IMPLIED ACTIONS are checked on EVERY TRANSITION, whether or
  ::  not the successor is new -- tlc2's DFID comment says so in as many words
  ::  ("We need to do it even if succState is not new"), and `implied-act-viol`
  ::  is the case that proves it: `Next == x' = (x + 1) %% 4` violates
  ::  `[][x' = x + 1]_x` on the 3 -> 0 step, and state 0 was seen at depth 1.
  ::  Checking only new successors reported nothing at all.
  =/  ia0  ?~(prev ~ (first-bad-action iacts.o u.prev st (env-of o)))
  =?  succ.cur  &(!hkey.o !=('' pred))
    =/  ss=(list @t)  (~(gut by succ.cur) pred ~)
    ?:  (lien ss |=(x=@t =(x fp)))  succ.cur
    (~(put by succ.cur) pred [fp ss])
  ?:  (~(has by seen.cur) fp)
    ::  a REVISITED successor: nothing is counted or enqueued, so the statistics
    ::  are the ones standing before it, and the trace runs through THIS
    ::  predecessor rather than the one that first discovered the state
    ?~  ia0  [~ cur]
    ?:  ?=(%| -.u.ia0)  [`[%error p.u.ia0 0 ~] cur]
    ?:  cont.o  [~ cur]
    :_  cur
    :-  ~
    :*  %action  gen.cur  distinct.cur  len.queue.cur  depth.cur
        (weld (trace-to seen.cur pred) ~[st])  p.u.ia0
    ==
  ?:  &(!=(0 maxd.o) (gth d maxd.o))
    [`[%limited %depth gen.cur distinct.cur len.queue.cur depth.cur] cur]
  ::  TLC order (doNext): the state is counted distinct and its invariants are
  ::  checked BEFORE it is enqueued, so a violating state is counted but never
  ::  enqueued (fixing the states-left-on-queue count)
  =.  distinct.cur  +(distinct.cur)
  =.  depth.cur     (max depth.cur d)
  ::  R4.P6a: the ACTUAL state is stored and later expanded, as tlc2 enqueues
  ::  `succState`; only the identity (`fp`, and a VIEW's `minVals`) uses the
  ::  orbit representative. Successors register in action order from their
  ::  stored predecessor, so `+trace-to` walks the very trace tlc2 rebuilds
  ::  (`TLCTrace.getTrace`: first match in action order). Storing the
  ::  representative printed it in symmetry traces, with `<unknown action>`
  =.  seen.cur      (~(put by seen.cur) fp [d pred st])
  ::  the invariant is checked on the actual state (`isValid(inv,
  ::  succState)`); identical to the representative without a symmetry group
  ::  R2.6.1/R2.6.3: the INVARIANT is evaluated here, so it needs the run
  ::  statistics too -- `TLCGet("distinct")` in an invariant is as legal as in a
  ::  next-state relation. tlc2 checks the invariant right after the state is
  ::  entered in the set, so `distinct` INCLUDES this state, which is why the
  ::  counters are read after the increments above. `level` is the state's own
  ::  depth: `isValid(inv, succState)` passes it as s0
  =/  ie  (with-run:ne e [| d `[depth.cur distinct.cur len.queue.cur gen.cur]])
  =^  iv  rs.cur  (first-violated-rs invs.o st ie rs.cur)
  ?^  iv
    ::  R4.2j: an invariant that fails to EVALUATE is tlc2's EC 2103 (`The
  ::  error occurred when TLC was evaluating the nested expressions ...`),
  ::  whose cause is the evaluation message
  ?:  ?=(%| -.u.iv)  [`[%error p.u.iv 2.103 ~] cur]
    ::  `-continue` (R2.4.2): record the violation and carry on. The state is
    ::  still ENQUEUED below -- measured at the pin, a violator's successors are
    ::  explored and can violate in turn, which is how the same spec reports at
    ::  depth 3 and again at depth 4
    ?:  cont.o
      =.  viols.cur  (snoc viols.cur [p.u.iv fp])
      =.  queue.cur  (fi-put queue.cur fp)
      =?  inits.cur  =('' pred)  [fp inits.cur]
      [~ cur]
    :_  cur
    :-  ~
    :*  %inv  gen.cur  distinct.cur  len.queue.cur  depth.cur
        (trace-to seen.cur fp)  p.u.iv  =('' pred)
    ==
  ::  R2.7.15b: the IMPLIED ACTIONS, here and not at the caller. ORDER is
  ::  tlc2's -- invariants first and only for a NEW state, then the implied
  ::  actions on every transition -- and the POSITION matters as much: the
  ::  check sits BEFORE the enqueue, exactly where the invariant check does,
  ::  so a violating successor is counted but never queued. Running it at the
  ::  caller (R2.7.15a's first attempt) reported `1 states left on queue`
  ::  where the pin reports 0
  ?^  ia0
    ?:  ?=(%| -.u.ia0)  [`[%error p.u.ia0 0 ~] cur]
    ?:  cont.o
      =.  queue.cur  (fi-put queue.cur fp)
      =?  inits.cur  =('' pred)  [fp inits.cur]
      [~ cur]
    :_  cur
    :-  ~
    :*  %action  gen.cur  distinct.cur  len.queue.cur  depth.cur
        (trace-to seen.cur fp)  p.u.ia0
    ==
  =.  queue.cur  (fi-put queue.cur fp)
  =?  inits.cur  =('' pred)  [fp inits.cur]
  [~ cur]
::
++  state-id
  ::  a state's identity in `seen`: FP64, or the identity key (R4.P5c)
  |=  [o=bfs-opts st=state]
  ^-  @t
  ?:  hkey.o  (@t (state-key:fp order.o st))
  (@t (state-fp:fp order.o st))
::
++  draws
  ::  R4.P5c: may the search draw a random value? Then the per-state reseed
  ::  (`fingerPrint ^ seed`) is observable and FP64 must stay the key.
  ::  Static and conservative: a drawing operator (`+draw-op`) is in scope
  ::  and its name, or its base name, appears anywhere in another
  ::  definition's body. A false positive only keeps FP64
  |=  defs=(map @t sem-def:sem-lib)
  ^-  ?
  =/  ds  ~(tap by defs)
  =/  dn  (draw-names defs)
  ?~  dn  |
  %+  lien  ds
  |=  [nm=@t d=sem-def:sem-lib]
  ?~  body.d  |
  ?:  (draw-op origin.d nm)  |
  (lien `(list @t)`dn |=(x=@t (has-atom u.body.d x)))
::
++  draw-names
  ::  the names under which a drawing operator (`+draw-op`) is in scope,
  ::  qualified and base
  |=  defs=(map @t sem-def:sem-lib)
  ^-  (list @t)
  %-  zing
  %+  murn  ~(tap by defs)
  |=  [nm=@t d=sem-def:sem-lib]
  ^-  (unit (list @t))
  ?.  (draw-op origin.d nm)  ~
  `~[nm (base-name nm)]
::
++  print-names
  ::  R4.2a: the names under which `TLC!Print` / `TLC!PrintT` are in scope
  |=  defs=(map @t sem-def:sem-lib)
  ^-  (list @t)
  %-  zing
  %+  murn  ~(tap by defs)
  |=  [nm=@t d=sem-def:sem-lib]
  ^-  (unit (list @t))
  ?.  =('TLC' origin.d)  ~
  =/  b  (base-name nm)
  ?.  |(=('Print' b) =('PrintT' b))  ~
  `~[nm b]
::
++  may-draw
  ::  R4.2aa: may STARTUP draw -- a definition (`+draws`) or an ASSUME
  ::  naming a drawing operator? Static and conservative, as `+draws` is;
  ::  when it says no, the startup pass and the ASSUME pre-pass are skipped
  ::  and the initial-state solve starts from the seed, which is then exact
  |=  [defs=(map @t sem-def:sem-lib) asmz=(list sem-thm:sem-lib)]
  ^-  ?
  ?:  (draws defs)  &
  ::  R4.2a: or prints: `Print`/`PrintT` named anywhere (a definition or an
  ::  ASSUME), whose lines must come out in startup order
  =/  dn  (weld (draw-names defs) (print-names defs))
  ?~  dn  |
  ?:  %+  lien  ~(tap by defs)
      |=  [nm=@t d=sem-def:sem-lib]
      ?~  body.d  |
      (lien `(list @t)`dn |=(x=@t (has-atom u.body.d x)))
    &
  %+  lien  asmz
  |=  t=sem-thm:sem-lib
  ?~  body.t  |
  (lien `(list @t)`dn |=(x=@t (has-atom u.body.t x)))
::
++  startup-order
  ::  R4.2aa: the order tlc2's `processConstantDefns` reaches definitions
  ::  in (see `+startup-draws:ne`): the EXTENDS closure dependency-first
  ::  (`imports`), then the root's constant substitutions (`C <- R`, in
  ::  CONSTANT declaration order), then the root's own definitions. A
  ::  substitution for a constant an EXTENDed module declares is placed with
  ::  the root's, ahead of the root's definitions: tlc2 would evaluate it
  ::  with that module, so this differs only when that module also draws
  |=  [mo=sem-module:sem-lib ov=(map @t @t) defs=(map @t sem-def:sem-lib)]
  ^-  (list sem-def:sem-lib)
  =/  subs=(list sem-def:sem-lib)
    %+  murn  consts.mo
    |=  [name=@t arity=@ud at=sspan:sem-lib]
    ^-  (unit sem-def:sem-lib)
    =/  r  (~(get by ov) name)
    ?~  r  ~
    (~(get by defs) u.r)
  (weld imports.mo (weld subs defs.mo))
::
++  assume-rs
  ::  R4.2aa: the RNG state after the ASSUMEs, which tlc2 evaluates on the
  ::  same stream between the startup definitions and the initial-state
  ::  solve (measured: `ASSUME ... RandomElement(0..99) ...` takes the draw
  ::  after the constant definitions', and Init the next). Same walk as
  ::  `+check-assumes`: an AXIOM is skipped, the first false or failing
  ::  assumption ends it (the run stops there)
  ::  R4.2a: the whole carrier, so an ASSUME's PRINTS come out too
  |=  [asmz=(list sem-thm:sem-lib) e=eenv:ne rs=rst:ne]
  ^-  rst:ne
  ?~  asmz  rs
  ?:  axiom.i.asmz  $(asmz t.asmz)
  ?~  body.i.asmz  $(asmz t.asmz)
  =/  r  (mule |.((eval-bool-rs:ne u.body.i.asmz e rs)))
  ?.  ?=(%& -.r)  rs
  =/  [b=bres:ne rs2=rst:ne]  p.r
  ?.  &(?=(%& -.b) p.b)  rs2
  $(asmz t.asmz, rs rs2)
::
++  draw-op
  ::  the StandardModule operators that spend the enumeration RNG
  ::  (`+eval-node-op-rs`: %random-element, %random-subset,
  ::  %random-set-of-subsets, %test-rsos)
  |=  [origin=@t nm=@t]
  ^-  ?
  =/  b  (base-name nm)
  ?|  &(=('TLC' origin) =('RandomElement' b))
      ?&  =('Randomization' origin)
          ?|  =('RandomSubset' b)
              =('RandomSetOfSubsets' b)
              =('TestRandomSetOfSubsets' b)
      ==  ==
  ==
::
++  base-name
  ::  an instance-qualified name without its prefixes: `R!S!Op` -> `Op`
  |=  nm=@t
  ^-  @t
  =/  t  (flop (trip nm))
  (crip (flop (scag (fall (find "!" t) (lent t)) t)))
::
++  has-atom
  |=  [n=* a=@]
  ^-  ?
  ?@  n  =(n a)
  |($(n -.n) $(n +.n))
::
++  viols-of
  ::  the recorded `-continue` violations with their traces rebuilt from
  ::  `seen` (R2.4.2). Done at the DONE boundary rather than as they are found,
  ::  so the persisted cursor never carries a trace
  |=  cur=bfs-cursor
  ^-  (list [name=@t trace=(list state)])
  %+  turn  viols.cur
  |=  [name=@t fp=@t]
  [name (trace-to seen.cur fp)]
::
++  register-all
  |=  [o=bfs-opts cur=bfs-cursor sts=(list state) d=@ud pred=@t prev=(unit state)]
  ^-  [out=(unit outcome) cur=bfs-cursor]
  |-  ^-  [out=(unit outcome) cur=bfs-cursor]
  ?~  sts  [~ cur]
  =/  rr  (register o cur i.sts d pred prev)
  ?^  out.rr  rr
  $(sts t.sts, cur cur.rr)
::
++  bfs-step
  ::  spend up to `budget` work units (one per state registered or
  ::  generated), then return the cursor. The outcome and every count
  ::  are independent of how the search is sliced.
  ::  narrowing note: ?^/?~ test local copies (todo, q), never wings of
  ::  `cur`, so recursing with a fresh wide cursor never nest-fails
  |=  [o=bfs-opts cur=bfs-cursor budget=@ud]
  ^-  bfs-slice
  ::  R2.7.4.2: the next-state relation is expanded PER ACTION, in getActions
  ::  order, the way tlc2's worker loop does it -- `Tool.getNextStates(action,
  ::  ...)` once per action, `Worker.addElement` once per successor. It is the
  ::  same decomposition the trace labels already use. Expanding here rather
  ::  than solving the whole relation in one call is what makes a successor
  ::  ATTRIBUTABLE to the action that produced it: measured at the pin, two
  ::  actions generating the SAME successor are counted separately and the
  ::  distinct credit goes to whichever ran first, which no after-the-fact
  ::  fingerprint match can reconstruct (R2.7.4.0). The action list depends
  ::  only on the spec and the constants -- tlc2 evaluates a constant-level
  ::  `\E` bound against `TLCState.Empty` -- so it is built once per slice
  ::  R2.7.4.2b: the caller usually built this already (it needs the same list
  ::  for trace labels), so take it when offered and only build it here when
  ::  the path has none
  =/  acts  ?^(acts.o acts.o (get-actions next.o '' defs.o (env-of o)))
  =/  spent  0
  |-  ^-  bfs-slice
  ?:  (gte spent budget)  [%more cur]
  ::  the state bound before anything else: R4.3 -- checked only after the
  ::  initial states, a model with more of them than the bound (MCLeast-
  ::  CircularSubstringMedium) ran out of time registering them instead
  ?:  ?&(!=(0 cap.o) (gth distinct.cur cap.o))
    [%done [%limited %states gen.cur distinct.cur len.queue.cur depth.cur] cur]
  ::  register pending initial states first (depth 1, no predecessor)
  =/  todo  init-todo.cur
  ?^  todo
    =/  rr  (register o cur(init-todo t.todo) i.todo 1 '' ~)
    ?^  out.rr  [%done u.out.rr cur.rr]
    $(cur cur.rr, spent +(spent))
  =/  q  (fi-pop queue.cur)
  ?~  q
    [%done [%ok gen.cur distinct.cur 0 depth.cur (viols-of cur)] cur]
  =/  fp   i.u.q
  =/  vis  (~(got by seen.cur) fp)
  ::  the statistics `TLCGet` reads are those standing BEFORE this expansion,
  ::  so the environment is built once for the whole state and not per action
  ::  (R2.6.1's measured read point)
  =/  e    (env-at o cur depth.vis)
  ::  R2.7.4.4: reseed the enumeration RNG for THIS predecessor state, once,
  ::  before any of its actions run. `TLCStateRandom.initialize` sets
  ::  `state.fingerPrint() ^ randomSeed` and then refuses to reseed for the
  ::  same state again, so every draw made while expanding it -- across all
  ::  actions and all conjuncts -- comes from one advancing stream. That is
  ::  what makes `x' = RandomElement(S) /\ y' = RandomElement(S)` able to
  ::  produce two DIFFERENT values, which a fresh-per-evaluation RNG cannot
  ::  through `+scramble:rng`, because `es` is the RAW 48-bit LCG state and
  ::  `Random.setSeed` stores `(seed ^ multiplier) & (2^48-1)`, not the seed
  ::  R4.P5c: under the identity key the spec never draws, so no reseed
  =?  es.rs.cur  !hkey.o  (scramble:rng (mix `@`fp seed.o))
  =/  before  distinct.cur
  ::  each action's successors are registered as they are generated, so a
  ::  violation found under an earlier action pre-empts a later one -- tlc2's
  ::  order, since `doNextCheckInvariants` throws out of the worker loop
  ::  before the remaining actions are evaluated
  =/  rr
    =/  as  acts
    =/  ix  0
    =/  c2  cur(queue q.u.q)
    |-  ^-  [out=(unit outcome) cur=bfs-cursor]
    ?~  as  [~ c2]
    ::  R2.7.4.3: the expansion reads AND writes the run-scoped store, so a
    ::  `TLCSet` in one action is visible to the next action, the next state,
    ::  and the constraints/invariants that follow
    =^  nr  rs.c2  (next-states-raw-rs:ne st.vis body.i.as (act-env e ctx.i.as) rs.c2)
    ::  R4.2j: a successor that fails to EVALUATE is the error's own code
    ::  (`\div` by 0 is EC 2179) with the behavior up to the state being
    ::  expanded, as tlc2 prints it
    ?:  ?=(%| -.nr)  [`[%error msg.p.nr code.p.nr (trace-to seen.c2 fp)] c2]
    ::  R4.2j: an INCOMPLETE successor is EC 2109, naming its unassigned
    ::  variables (sorted, `TLCStateMutExt.getUnassigned`) and the action when
    ::  the relation has several (`ModelChecker.doNextSetErr`); the behavior
    ::  printed ends WITH the incomplete successor
    =/  bad  (skim p.nr |=(s=state !(complete:ne s vars.o)))
    ?^  bad
      =/  miss=(list @t)
        %+  sort  (skip ~(tap in vars.o) |=(v=@t (~(has by i.bad) v)))
        aor
      =/  msg=@t
        %+  rap  3
        :~  'Successor state is not completely specified by '
            ?:(?=([* ~] acts) 'the next-state action' (rap 3 ~['action ' name.i.as ' of the next-state relation']))
            '. The following variable'  ?:(?=([* ~] miss) ' is' 's are')
            ' not defined: '  (rap 3 (join ', ' miss))  '.'
        ==
      [`[%error msg 2.109 (snoc (trace-to seen.c2 fp) i.bad)] c2]
    =/  ng  (lent p.nr)
    =/  d0  distinct.c2
    =.  gen.c2  (add gen.c2 ng)
    ::  R4.2g: and the intermediate states an action composition generated
    =.  gen.c2  (add gen.c2 xgen.rs.c2)
    =.  xgen.rs.c2  0
    =/  r  (register-all o c2 p.nr +(depth.vis) fp `st.vis)
    ::  the coverage tally for THIS action: every successor it generated, and
    ::  how many of those were newly distinct. Recorded even when the
    ::  registration stopped early on a violation -- tlc2's counters likewise
    ::  hold whatever the worker had done when it threw
    =/  c3  cur.r
    =?  cvn.c3  on.cov.o
      =/  hit=[gen=@ud dis=@ud]  (~(gut by cvn.c3) ix [0 0])
      %+  ~(put by cvn.c3)  ix
      [(add gen.hit ng) (add dis.hit (sub distinct.c3 d0))]
    ?^  out.r  [out.r c3]
    $(as t.as, ix +(ix), c2 c3)
  ?^  out.rr  [%done u.out.rr cur.rr]
  =/  cost  (sub gen.cur.rr gen.cur)
  ::  R4.QS: and the solver's candidates, a sixteenth of a unit each, so a
  ::  slice of expensive expansions ends after a few of them, not 256
  =/  wk  (div wrk.rs.cur.rr 16)
  =.  wrk.rs.cur.rr  0
  ?:  =(0 cost)
    ::  a dequeued state with NO successors still contributes a 0 out-degree
    ::  sample: TLC calls outDegree.addSample(unseenSuccessorStates) for every
    ::  state it dequeues, so a sink pulls the distribution's min to 0 (R1.5.12b)
    =.  outdeg.cur.rr  (~(put by outdeg.cur.rr) 0 +((~(gut by outdeg.cur.rr) 0 0)))
    ?.  deadlock.o  $(cur cur.rr, spent :(add spent 1 wk))
    :+  %done
      :*  %deadlock  gen.cur.rr  distinct.cur.rr  len.queue.cur.rr
          depth.cur.rr  (trace-to seen.cur.rr fp)
      ==
    cur.rr
  ::  TLC out-degree sample: the number of newly-distinct successors this state
  ::  produced (Worker.outDegree.addSample of unseenSuccessorStates)
  =/  sample  (sub distinct.cur.rr before)
  =.  outdeg.cur.rr
    (~(put by outdeg.cur.rr) sample +((~(gut by outdeg.cur.rr) sample 0)))
  $(cur cur.rr, spent :(add spent cost wk))
::
++  explore
  ::  deterministic BFS from the initial states; stops at the first
  ::  invariant violation or (unless disabled) deadlock, in BFS order.
  ::  `cap` bounds the distinct-state count (0 = unbounded); exceeding it
  ::  yields %limited with the statistics so far, so a caller can bound a
  ::  single event's work.
  |=  [is=(list state) o=bfs-opts]
  ^-  [out=outcome od=out-degree]
  =/  cur  (bfs-init is)
  |-  ^-  [out=outcome od=out-degree]
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)  [out.r (od-stats outdeg.cur.r)]
  $(cur cur.r)
::
++  explore-full
  ::  `+explore` also returning the final CURSOR, which is where the coverage
  ::  counters live (R2.7.4.2b). Same search, same slicing, same result
  |=  [is=(list state) o=bfs-opts]
  ^-  [out=outcome od=out-degree cur=bfs-cursor]
  (explore-full-regs is empty-rst:ne o)
::
++  explore-full-regs
  ::  `+explore-full` seeded with the carrier the initial-state solve left
  ::  (R2.7.4.3/.4)
  |=  [is=(list state) rs=rst:ne o=bfs-opts]
  ^-  [out=outcome od=out-degree cur=bfs-cursor]
  =/  cur  (bfs-init-regs is rs)
  |-  ^-  [out=outcome od=out-degree cur=bfs-cursor]
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)  [out.r (od-stats outdeg.cur.r) cur.r]
  $(cur cur.r)
::
++  explore-cursor
  ::  run the search to completion in `budget`-sized slices and return the final
  ::  cursor, exposing the statistics (max out-degree) the outcome omits. The
  ::  result is independent of `budget` (the slice-boundary resume contract)
  |=  [is=(list state) o=bfs-opts budget=@ud]
  ^-  bfs-cursor
  =/  cur  (bfs-init is)
  |-  ^-  bfs-cursor
  =/  r  (bfs-step o cur budget)
  ?:  ?=(%done -.r)  cur.r
  $(cur cur.r)
::
++  trace-to
  ::  the behavior (list of states, initial first) ending at `fp`
  |=  [seen=(map @t visit) fp=@t]
  ^-  (list state)
  =|  out=(list state)
  |-  ^-  (list state)
  =/  vis  (~(get by seen) fp)
  ?~  vis  out
  =.  out  [st.u.vis out]
  ?:  =('' pred.u.vis)  out
  $(fp pred.u.vis)
::
::  +|  Output (TLC terminal summary + trace)
::
::
++  module-name-of
  |=  tree=node
  ^-  @t
  =/  bm  (skim (kids-of tree) |=(k=node (is-kind k %n-beginmodule)))
  ?~  bm  ''
  =/  ids  (skim (kids-of i.bm) |=(k=node &(?=(%leaf -.k) =(%identifier (leaf-kind k)))))
  ?~(ids '' (leaf-text i.ids))
::
++  state-pairs
  ::  [var rendered-value] pairs of a state in TLC's DECLARATION order:
  ::  `TLCStateMut.toString` walks `vars[i]`, which SpecProcessor fills from
  ::  the root module's `getVariableDecls()` — the same order `+var-order`
  ::  already computes for the FP64 byte order. A binding the order does not
  ::  name follows in sorted order, so a rendering can never silently drop one
  |=  [order=(list @t) st=state]
  ^-  (list [@t @t])
  =/  named  (skim order |=(k=@t (~(has by st) k)))
  =/  rest
    %+  sort
      %+  skim  ~(tap in ~(key by st))
      |=(k=@t !(lien order |=(o=@t =(o k))))
    aor
  %+  turn  (weld named rest)
  |=  k=@t
  [k (crip (render:vl (~(got by st) k)))]
::
++  alias-state
  ::  ALIAS rendering (R2.3.2), a faithful port of `Tool.evalAlias`.
  ::
  ::  tlc2 does NOT thread an alias through its printer: `evalAlias` evaluates
  ::  the alias expression and calls `.toState()` on the resulting record, so
  ::  the RECORD BECOMES THE STATE and the ordinary state printer renders it.
  ::  The port does the same — which is why no renderer signature changes.
  ::
  ::  The alias is evaluated against BOTH the current state and its successor
  ::  (`eval(getAliasSpec(), Context.Empty, current, successor, …)`), so a
  ::  primed reference resolves against the successor. The last state of a
  ::  trace has no successor and is paired with ITSELF, which is what makes
  ::  `x' # x` print FALSE there and TRUE everywhere else — measured against
  ::  the pin.
  ::
  ::  On an evaluation error tlc2 does not fail the run: it returns the
  ::  original state plus an `_ALIASEvalError` field carrying the message.
  ::  Reproduced, because a trace that cannot render is still a trace.
  |=  [al=sem:sem-lib e=eenv:ne cur=state suc=state]
  ^-  [order=(list @t) st=state]
  =/  r  (eval:ne al e(s0 cur, s1 suc, primed |))
  ?:  ?=(%| -.r)
    :-  ~['_ALIASEvalError']
    (~(put by cur) '_ALIASEvalError' [%str msg.p.r])
  ?.  ?=(%rec -.p.r)
    ::  not a record: tlc2's `toState()` yields null and the current state is
    ::  rendered unchanged
    [~ cur]
  ::  the record's fields become the bindings. tlc2's `RecordValue.toState()`
  ::  walks the record's `names` in CONSTRUCTOR order, but the port's `%rec`
  ::  value normalizes its field list at construction, so the evaluated value
  ::  cannot report source order. Recover it from the alias's OWN semantic
  ::  node -- the `$RcdConstructor` field sequence -- and fall back to the
  ::  normalized order when the node names no fields (an alias that is not a
  ::  bare constructor: a record built by a conditional or an operator call)
  =/  fs  p.p.r
  =/  nrm  (turn fs |=(f=vfield:vl k.f))
  =/  src  (turn (rcd-pairs:sem-lib al) |=(pr=[fname=@t *] fname.pr))
  :-  ?:(=((sy src) (sy nrm)) src nrm)
  (~(gas by *state) (turn fs |=(f=vfield:vl [k.f v.f])))
::
++  render-state
  ::  a trace state's bindings, one per line. A SINGLE variable renders bare
  ::  (`x = v`); two or more render as a conjunct list (`/\ x = v`) — exactly
  ::  `TLCStateMut.toString`'s `vlen == 1` branch and its `else`
  ::  `-view` (R2.4.3): `TLCGlobals.useView` makes `TLCStateMut.toString()`
  ::  render the VIEW'S VALUE instead of the bindings -- measured at the pin,
  ::  a bare `0` / `1` / `2`: no `/\\`, no names, no separator. `vw` is the
  ::  VIEW body, non-~ only when the flag is set; an unevaluable view falls
  ::  back to the bindings rather than printing nothing
  ::  `-difftrace` (R2.4.3): `dif` is the PREVIOUS state; a binding equal to
  ::  its value is omitted (`TLCStateMut.toString(lastState)`). Measured at the
  ::  pin, tlc2 honours this in SIMULATION only, so only that path passes it
  |=  $:  order=(list @t)  st=state
          vw=(unit sem:sem-lib)  e=eenv:ne
          dif=(unit state)
      ==
  ^-  wain
  ?^  vw
    =/  r  (eval:ne u.vw e(s0 st, s1 st, primed |))
    ?:  ?=(%& -.r)  ~[(crip (render:vl p.r))]
    $(vw ~)
  ^-  wain
  =/  ps0  (state-pairs order st)
  =/  ps
    ?~  dif  ps0
    %+  skip  ps0
    |=  [k=@t v=@t]
    =/  o  (~(get by u.dif) k)
    ?~(o | =(v (crip (render:vl u.o))))
  =/  bare=?  ?=([* ~] ps)
  %+  turn  ps
  |=  [k=@t v=@t]
  ?:  bare  (crip "{(trip k)} = {(trip v)}")
  (crip "/\\ {(trip k)} = {(trip v)}")
::
++  render-trace
  ::  `State N: <label>` blocks; state 1 is the initial predicate, each later
  ::  state is labeled with the specific getActions leaf action that generated
  ::  it from its predecessor (Tool.getActions decomposition, R1.5.4). With no
  ::  action context (`actions` ~) it falls back to the whole-Next label — the
  ::  single-action case renders identically either way.
  |=  $:  trace=(list state)  next-label=@t
          actions=(list act)
          e=eenv:ne  order=(list @t)  modn=@t
          al=(unit sem:sem-lib)
          ::  `-view` (R2.4.3): the VIEW body when the flag is set, so every
          ::  rendered state prints its VALUE instead of its bindings
          vw=(unit sem:sem-lib)
          ::  `-difftrace` (R2.4.3): print only CHANGED bindings
          dif=?
      ==
  ^-  wain
  =/  i  1
  =/  prev=(unit state)  ~
  %-  zing
  |-  ^-  (list wain)
  ?~  trace  ~
  =/  label=@t
    ?~  prev  '<Initial predicate>'
    ?~  actions  next-label
    ::  R2.6.1: the re-solve evaluates the next-state relation again, so a
    ::  spec whose Next reads `TLCGet("level")` needs the PREDECESSOR's level
    ::  or no action matches and every state falls back to `<unknown action>`.
    ::  A trace position IS its level (state i is at level i), so this one is
    ::  reconstructible; the counters are not, and stay `~`
    %:  edge-action-label
      u.prev  (@t (state-fp:fp order i.trace))  actions
      (with-run:ne e [| (dec i) ~])  order  modn
    ==
  ::  ALIAS: the record BECOMES the state (R2.3.2). Its successor is the next
  ::  trace state, and the LAST state is paired with itself -- which is what
  ::  makes a primed reference print FALSE there, measured against the pin
  =/  shown=[order=(list @t) st=state]
    ?~  al  [order i.trace]
    =/  suc  ?~(t.trace i.trace i.t.trace)
    (alias-state u.al e i.trace suc)
  :_  $(trace t.trace, i +(i), prev `i.trace)
  ;:  weld
    ~[(crip "State {(a-tape i)}: {(trip label)}")]
    (render-state order.shown st.shown vw e ?:(dif prev ~))
    ~['']
  ==
::
++  a-co
  |=(n=@ud (crip (a-tape n)))
::
++  a-tape
  |=  n=@ud
  ^-  tape
  ?:  =(0 n)  "0"
  =|  o=tape
  |-  ^-  tape
  ?:  =(0 n)  o
  $(n (div n 10), o [(add '0' (mod n 10)) o])
::
::  +|  Coverage Report (R2.7.4.2b)
::
::
++  span-lth
  ::  `tla2sany.st.Location.compareTo` as a `+sort` predicate: begin line,
  ::  begin column, end line, end column. A span-less node sorts first
  |=  [a=sspan:sem-lib b=sspan:sem-lib]
  ^-  ?
  ?~  a  ?=(^ b)
  ?~  b  |
  ?.  =(line.from.u.a line.from.u.b)  (lth line.from.u.a line.from.u.b)
  ?.  =(col.from.u.a col.from.u.b)    (lth col.from.u.a col.from.u.b)
  ?.  =(line.to.u.a line.to.u.b)      (lth line.to.u.a line.to.u.b)
  (lth col.to.u.a col.to.u.b)
::
++  cov-pair-line
  ::  `<label>: A:B`
  |=  [lab=@t a=@ud b=@ud]
  ^-  @t
  (crip "{(trip lab)}: {(a-tape a)}:{(a-tape b)}")
::
++  cov-next-lines
  ::  the NEXT-action coverage lines. tlc2 shares ONE `ActionWrapper` between
  ::  every action whose `pred` is the same semantic node
  ::  (`CostModelCreator.create`'s `cms` map is keyed on `nextAction.pred`), so
  ::  the N actions a constant-level `\E` decomposes into report as ONE line
  ::  with their counters SUMMED -- measured at the pin, `\E i \in 1..2 :
  ::  Bump(i)` reports a single `<Bump …>: 2:12`. The port's `+get-actions`
  ::  recurses into the same `sem` noun for each element, so grouping by that
  ::  noun reproduces the sharing exactly.
  ::
  ::  The lines are then ordered by the action's OWN span, not by decomposition
  ::  order: `CostModelCreator` collects them into a `TreeSet` comparing
  ::  `pred.getLocation()`, which is why `Next == Dec \/ Inc` reports `Inc`
  ::  first. The pair is `secondary : getEvalCount()` -- newly-distinct
  ::  successors, then every successor the action generated
  |=  [o=bfs-opts cur=bfs-cursor acts=(list act) modn=@t]
  ^-  wain
  ::  fold the per-index tallies into one entry per distinct action span,
  ::  keeping the first occurrence as the group's representative.
  ::  EXPLICIT loop: `acts` holds the recursive `sem`/`value` molds, which
  ::  fuse-loop a wet `turn`/`roll` (the R2.4.2 trap)
  =|  groups=(list cov-group)
  =/  as  acts
  =/  ix=@ud  0
  |-  ^-  wain
  ?~  as
    ::  `+sort` is stable, so equal spans keep decomposition order
    %+  turn  (sort (flop groups) |=([p=cov-group q=cov-group] (span-lth at.p at.q)))
    |=(g=cov-group (cov-pair-line lab.g dis.g gen.g))
  =/  hit=[gen=@ud dis=@ud]  (~(gut by cvn.cur) ix [0 0])
  =/  at  (sem-at body.i.as)
  ?:  (has-group groups at)
    ::  a later element of the same `\E`: add its counters to the group the
    ::  first element opened, rather than opening a second line
    $(as t.as, ix +(ix), groups (bump-group groups at gen.hit dis.hit))
  =/  lab
    %:  cov-label
      name.i.as
      (def-decl defs.o name.i.as)
      at
      (def-body-span defs.o name.i.as)
      modn
    ==
  %=  $
    as      t.as
    ix      +(ix)
    groups  [[at lab gen.hit dis.hit] groups]
  ==
::
+$  cov-group  [at=sspan:sem-lib lab=@t gen=@ud dis=@ud]
::
++  has-group
  |=  [gs=(list cov-group) at=sspan:sem-lib]
  ^-  ?
  ?~  gs  |
  ?:(=(at.i.gs at) & $(gs t.gs))
::
++  bump-group
  |=  [gs=(list cov-group) at=sspan:sem-lib g=@ud d=@ud]
  ^-  (list cov-group)
  ?~  gs  ~
  ?.  =(at.i.gs at)  [i.gs $(gs t.gs)]
  [i.gs(gen (add gen.i.gs g), dis (add dis.i.gs d)) $(gs t.gs)]
::
++  cov-con-lines
  ::  the CONSTRAINT / ACTION_CONSTRAINT lines. `Tool.isInModel` counts a FALSE
  ::  evaluation as the primary and a TRUE one as the secondary, and reports
  ::  `secondary : primary + secondary` -- the opposite orientation from a NEXT
  ::  action, and the reason these are tallied at the constraint loop rather
  ::  than derived from the state counts
  |=  $:  nms=(list @t)  m=(map @ud [pri=@ud sec=@ud])
          defs=(map @t sem-def:sem-lib)  modn=@t
      ==
  ^-  wain
  =/  ns  nms
  =/  ix=@ud  0
  |-  ^-  wain
  ?~  ns  ~
  =/  h=[pri=@ud sec=@ud]  (~(gut by m) ix [0 0])
  :_  $(ns t.ns, ix +(ix))
  %^  cov-pair-line
      (cov-label i.ns (def-decl defs i.ns) ~ ~ modn)
    sec.h
  (add pri.h sec.h)
::
++  cov-inv-lines
  ::  the INVARIANT lines, which carry NO counts (`TLC_COVERAGE_PROPERTY`,
  ::  template `%1%`) -- the `ActionWrapper.report()` assertion is literally
  ::  that a PROP relation's counters are both zero.
  ::
  ::  A CONSTANT-level invariant is absent from the block because it is absent
  ::  from the run: `SpecProcessor` resolves it to a `BoolValue`, warns
  ::  (EC 2158) and never adds it to the invariant vector. The port still
  ::  CHECKS such an invariant -- a separate, pre-existing difference on
  ::  `tlc-safety-invariant` -- but it must not report coverage for an action
  ::  tlc2 does not have, so the filter is applied here
  |=  $:  invs=(list [name=@t body=sem:sem-lib])
          defs=(map @t sem-def:sem-lib)  modn=@t
      ==
  ^-  wain
  =/  is  invs
  |-  ^-  wain
  ?~  is  ~
  ?:  =(0 (sem-lvl body.i.is))  $(is t.is)
  :-  (cov-label name.i.is (def-decl defs name.i.is) ~ ~ modn)
  $(is t.is)
::
++  cov-report
  ::  the whole `-coverage` block, in `CostModelCreator.report()`'s order:
  ::  VARIABLEs, the INIT action, the NEXT actions sorted by span, the
  ::  INVARIANTs, the ACTION_CONSTRAINTs, then the state CONSTRAINTs.
  ::
  ::  TWO line kinds the port declares as ABSENT rather than reporting wrongly
  ::  (both tested approved differences, and both already outside the
  ::  `SafetyDump` projection):
  ::
  ::  - the per-VARIABLE `TLC_COVERAGE_VAR` line, whose count is a
  ::    `CountDistinct.SyncedHyperLogLog(10)` ESTIMATE over
  ::    `v.fingerPrint(FP64.New())`. Reproducing it needs bit-identical HLL
  ::    registers and pins the run to `-fp 0`; it is an estimator, not a fact
  ::    about the spec.
  ::  - the indented per-NODE sub-expression lines (EC 2221 / 2775), which are
  ::    `getEvalCount()` on an `OpApplNodeWrapper` inside evaluation -- the
  ::    only coverage consumer of the R2.7.4.1 return-carrier, and the one
  ::    quantity a structurally different evaluator cannot mean the same thing
  ::    by
  ::
  ::  The timestamp on the header is dropped, as every other wall-clock line in
  ::  the port's output is
  |=  [o=bfs-opts cur=bfs-cursor acts=(list act)]
  ^-  wain
  ?.  on.cov.o  ~
  =*  c     cov.o
  =/  modn  modn.c
  ;:  weld
    :_  ~
    %^  cat  3
      'The coverage statistics (see https://explain.tlapl.us/module-coverage-statistics '
    'for how to interpret the following statistics).'
    ::  INIT: `getEvalCount() : getEvalCount() + secondary`
    :_  ~
    %^  cov-pair-line
        (cov-label iname.c (def-decl defs.o iname.c) ~ ~ modn)
      gen.cvi.c
    (add gen.cvi.c rej.cvi.c)
    (cov-next-lines o cur acts modn)
    (cov-inv-lines invs.o defs.o modn)
    (cov-con-lines anames.c cva.cur defs.o modn)
    (cov-con-lines cnames.c cvc.cur defs.o modn)
    ~['End of statistics.']
  ==
::
++  cov-refusal
  ::  a run that PRINTS A COUNTEREXAMPLE cannot report coverage honestly, and
  ::  says so by name instead of printing numbers that are not the pin's.
  ::
  ::  Measured at the pin (R2.7.4.0, re-measured 2026-08-26 with
  ::  `-noGenerateSpecTE`, which changes nothing): tlc2 reconstructs the trace
  ::  by RE-INVOKING the initial predicate and the actions, with coverage still
  ::  recording, so the block a violating run prints counts the search AND the
  ::  re-solve. The same spec that reports `<Init …>: 1:1` and `<A …>: 2:2`
  ::  under `-deadlock` reports `3:3` and `2:6` when the deadlock trace is
  ::  printed. The port re-solves for trace LABELS but not identically, so its
  ::  counters are the search's alone -- a different number, not a
  ::  reproduction, which is why it is withheld rather than shown
  ^-  wain
  :~  '-coverage: no statistics for a run that prints a counterexample.'
      'tlc2 re-invokes the initial predicate and the actions to reconstruct the trace, with coverage still recording, so its counters there include that re-solve; this port does not reproduce it and will not report a different number under the same name.'
  ==
::
++  counts-lines
  |=  [gen=@ud distinct=@ud queued=@ud depth=@ud]
  ^-  wain
  :~  (crip "{(a-tape gen)} states generated, {(a-tape distinct)} distinct states found, {(a-tape queued)} states left on queue.")
      (crip "The depth of the complete state graph search is {(a-tape depth)}.")
  ==
::
++  next-span-label
  ::  `<NAME line BL, col BC to line EL, col EC of module M>` for the whole
  ::  next-state relation. `nm` is the ROOT action name: the NEXT operator's
  ::  name in INIT/NEXT mode, and `Action` when the relation came from a
  ::  SPECIFICATION — tlc2 builds that action with a null `opDef`, so
  ::  `Action.isNamed` is false and `getLocation` prints its generic
  ::  `"Action"` (`Action.java:100-107`)
  |=  [nm=@t next-body=node modn=@t]
  ^-  @t
  =/  sp  (span-of:ast next-body)
  ?~  sp  (crip "<{(trip nm)}>")
  =*  s  u.sp
  %-  crip
  ;:  weld
    "<"  (trip nm)  " line "  (a-tape line.from.s)  ", col "  (a-tape col.from.s)
    " to line "  (a-tape line.to.s)  ", col "  (a-tape col.to.s)
    " of module "  (trip modn)  ">"
  ==
::
::  +|  Coverage Labels (R2.7.4.2b)
::
::
++  loc-tape
  ::  a span as tlc2's `Location.toString()`, which every coverage and trace
  ::  label embeds
  |=  [s=span modn=@t]
  ^-  tape
  ;:  weld
    "line "  (a-tape line.from.s)  ", col "  (a-tape col.from.s)
    " to line "  (a-tape line.to.s)  ", col "  (a-tape col.to.s)
    " of module "  (trip modn)
  ==
::
++  sem-at
  ::  the source span an IR node carries (a `%nullodn` carries none)
  |=  s=sem:sem-lib
  ^-  sspan:sem-lib
  ?-  -.s
    %apply    at.s
    %letin    at.s
    %atref    at.s
    %lit      at.s
    %nullodn  ~
  ==
::
++  decl-span
  ::  the DECLARATION span of a definition -- `Action.getDeclaration()`, the
  ::  `N_IdentLHS` subtree. The coverage label uses this where the TRACE label
  ::  uses the BODY span, which is why `Init` reports as `col 1 to col 4` and
  ::  not as its body's `col 9 to col 13` (R2.7.4.0).
  ::
  ::  Derived from what `sem-def` already stores rather than by widening the
  ::  mold: the declaration starts where the definition starts, and ends at the
  ::  name's last column for an arity-0 operator, or one column past the last
  ::  parameter's last column -- the `)` -- for a parameterized one. Checked
  ::  against the pin: `Init` -> col 1-4, `Cons2` -> col 1-5, `Bump(i)` -> col
  ::  1-7. A parameter with no recorded span falls back to the name form
  |=  d=sem-def:sem-lib
  ^-  sspan:sem-lib
  ?~  at.d  ~
  =*  s  u.at.d
  =/  by-name=pos  [line.from.s (dec (add col.from.s (met 3 name.d)))]
  ::  EXPLICIT walk to the last parameter: `rear` is wet, and the dev notes
  ::  record wet stdlib gates nest-failing on the `$+`-named IR records
  =/  lastp=(unit spar:sem-lib)
    =/  ps  params.d
    =|  acc=(unit spar:sem-lib)
    |-  ^-  (unit spar:sem-lib)
    ?~  ps  acc
    $(ps t.ps, acc `i.ps)
  =/  fin=pos
    ?~  lastp  by-name
    ?~  at.u.lastp  by-name
    [line.to.u.at.u.lastp +(col.to.u.at.u.lastp)]
  `[from.s fin]
::
++  def-decl
  ::  `+decl-span` of a named definition, `~` when the name is unknown
  |=  [defs=(map @t sem-def:sem-lib) nm=@t]
  ^-  sspan:sem-lib
  =/  d  (~(get by defs) nm)
  ?~(d ~ (decl-span u.d))
::
++  def-body-span
  ::  the span of a named definition's BODY, which `+cov-label` compares the
  ::  action's own predicate span against to decide 1:1 vs 1:N
  |=  [defs=(map @t sem-def:sem-lib) nm=@t]
  ^-  sspan:sem-lib
  =/  d  (~(get by defs) nm)
  ?~  d  ~
  ?~  body.u.d  ~
  (sem-at u.body.u.d)
::
++  cov-label
  ::  one coverage line's label. `<Name declaration>` when the action's own
  ::  predicate IS the whole definition body (the 1:1 mapping), else
  ::  `<Name declaration (bl bc el ec)>` carrying the actual disjunct's
  ::  coordinates -- `ActionWrapper.printLocation()`. Measured at the pin:
  ::  `<Next line 5, col 1 to line 5, col 4 of module PD (5 10 5 24)>` for
  ::  `Next == (x = 0 /\ x' = 1) \/ (x = 1 /\ x' = 2)`.
  ::
  ::  `pred` is the action's span and `defn` the definition body's; passing
  ::  `pred` as `~` asks for the 1:1 form unconditionally, which is what the
  ::  non-action lines (invariants, constraints) want
  |=  [nm=@t decl=sspan:sem-lib pred=sspan:sem-lib defn=sspan:sem-lib modn=@t]
  ^-  @t
  ?~  decl  (crip "<{(trip nm)}>")
  =/  head=tape  ;:(weld "<" (trip nm) " " (loc-tape u.decl modn))
  ?~  pred  (crip (weld head ">"))
  ?:  =(pred defn)  (crip (weld head ">"))
  =*  a  u.pred
  %-  crip
  ;:  weld
    head  " ("  (a-tape line.from.a)  " "  (a-tape col.from.a)
    " "  (a-tape line.to.a)  " "  (a-tape col.to.a)  ")>"
  ==
::
::  +|  Liveness (temporal properties, no fairness)
::
::
+$  graph  [seen=(map @t visit) inits=(list @t) gen=@ud distinct=@ud depth=@ud]
::
++  build-graph
  ::  the complete reachability graph via deterministic BFS (no early
  ::  stop), with per-state depth and predecessor for trace reconstruction
  |=  [is=(list state) o=bfs-opts]
  ^-  graph
  =/  cur  (bfs-init is)
  |-  ^-  graph
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)
    [seen.cur.r (flop inits.cur.r) gen.cur.r distinct.cur.r depth.cur.r]
  $(cur cur.r)
::
++  live-graph-cap
  ::  the distinct-state safety bound for a temporal graph build (R1.5.5). The
  ::  liveness path builds the WHOLE reachability graph before searching for a
  ::  lasso, so an unbounded build hangs on a large/looping state space; a build
  ::  reaching this many distinct states stops and yields %limited (TLC's own
  ::  liveness is unbounded, so a spec past the bound is a documented divergence,
  ::  not a hang). Small temporal specs are far below it and are unaffected.
  ^~  100.000
::
++  build-graph-cap
  ::  +build-graph that also reports whether the distinct-state `cap` (o.cap,
  ::  0 = unbounded) was reached (R1.5.5). A capped liveness build yields
  ::  %limited rather than a verdict on a partial graph, and never hangs.
  |=  [is=(list state) o=bfs-opts]
  ^-  [g=graph capped=?]
  =/  r  (build-graph-out is o)
  [g.r capped.r]
::
++  build-graph-out
  ::  +build-graph-cap that also returns the search OUTCOME. The liveness path
  ::  needs it: tlc2 finds a DEADLOCK in the state search (ModelChecker.doNext)
  ::  and aborts the run there, so the final liveness check never runs. The port
  ::  built the temporal graph with deadlock checking OFF and went straight to
  ::  the liveness report, which is why `Github710d`/`Github710e` reported a
  ::  temporal violation where TLC reports `Deadlock reached` over the same
  ::  state count (R1.6.6). `+bfs-step` stops at the first deadlock, so the
  ::  graph is complete exactly when the outcome is not one.
  ::  R2.7.7.4a: the final CARRIER rides out too, so a POSTCONDITION on this
  ::  path reads the registers the search wrote -- same reason as the safety
  ::  path, where the cursor was already in scope
  |=  [is=(list state) o=bfs-opts]
  ^-  [g=graph capped=? out=outcome rs=rst:ne]
  =/  cur  (bfs-init is)
  |-  ^-  [g=graph capped=? out=outcome rs=rst:ne]
  =/  r  (bfs-step o cur 1.024)
  ?:  ?=(%done -.r)
    :^    [seen.cur.r (flop inits.cur.r) gen.cur.r distinct.cur.r depth.cur.r]
        ?=(%limited -.out.r)
      out.r
    rs.cur.r
  $(cur cur.r)
::
::  +|  Seeded Simulation (bounded, reproducible, resumable)
::
::
+$  sim-result
  $:  traces=@ud       ::  behaviors generated (numOfGenTraces)
      steps=@ud        ::  state transitions taken
      gen=@ud          ::  states generated (|inits| + successors, 9.3b)
      mean=@ud         ::  trace-length mean over completed behaviors (Welford)
      var=@ud          ::  Var(X) = round(m2 / (traces + 1))
      sd=@ud           ::  round(sqrt(m2 / (traces + 1)))
      ::  the first violating behavior, if any: an invariant broken on a
      ::  successor, a temporal PROPERTY broken by a completed behavior, or a
      ::  DEADLOCK -- a state with no surviving successor, which ends the whole
      ::  simulation when deadlock checking is on (R1.7c). `name` is '' for a
      ::  deadlock, which has none.
      viol=(unit [kind=?(%invariant %action %property %deadlock) name=@t path=(list state)])
      ::  a typed engine REFUSAL that ends the run with no verdict at all
      ::  (R2.4.6). The deterministic walk has no such outcome -- a solver
      ::  failure there drops the action -- but the `-generate` walk does: tlc2
      ::  throws `UnsupportedOperationException` on a CASE in probabilistic
      ::  position and ABORTS, exit 255, with no model checking performed. A
      ::  run that ends this way has no `viol` and no statistics worth reading
      err=(unit @t)
  ==
::  fixed parameters of one simulation run (built once from search-ctx). The
::  successor generation is the unit-7 semantic path (node-eval), and the RNG is
::  java.util.Random (lib/rng), so a run reproduces `tlc2.TLC -simulate`.
::  the env is NOT stored built: eenv carries the override registry `ov`, whose
::  op-impls are gates, and a kont round-trip clams them to bunt gates (a core
::  cannot survive `;;`). Like bfs-opts, carry defs/consts/vars and rebuild the
::  env per event (sim-step), so the registry is always freshly constructed.
+$  sim-opts
  $:  actions=(list act)   ::  getActions leaves, source order
      invs=(list [name=@t body=sem:sem-lib])     ::  invariants, decl order
      cons=(list sem:sem-lib)                    ::  CONSTRAINT (R1.7)
      acons=(list sem:sem-lib)                   ::  ACTION_CONSTRAINT (R1.7)
      ddl=?       ::  check deadlock (TLC's `deadlock && getCheckDeadlock()`)
      oss=(list oos:tp)          ::  normalized temporal PROPERTY (~ none; 9.3a)
      pname=@t                   ::  PROPERTY name (for the temporal verdict)
      defs=(map @t sem-def:sem-lib)              ::  operator definitions
      consts=(map @t value)                      ::  CONSTANT assignments
      vars=(set @t)                              ::  VARIABLE names
      order=(list @t)            ::  vars in declaration order (fingerprints)
      num=@ud     ::  behaviors to simulate
      depth=@ud   ::  transitions per behavior
      ::  tlc2's `-generate` (R2.4.6): pick successors PROBABILISTICALLY --
      ::  `Tool.probabilistic`, which walks the nondeterministic constructs in
      ::  randomized order and stops at the first successor the functor accepts,
      ::  so a step generates one successor instead of all of them
      prob=?
      ::  R4.Q8b: the IMPLIED ACTIONS of the PROPERTYs (`+bin-properties`),
      ::  checked on every generated successor after the invariants, as
      ::  `SimulationWorker.addElement` does. Implied INITS are not: the
      ::  simulator never checks them (measured at the pin)
      iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
  ==
::  everything required to resume a run byte-identically: the RNG is the raw
::  48-bit java.util.Random state (lib/rng), advanced only at step boundaries,
::  so slicing never changes a draw
+$  sim-cursor
  $:  s=@                    ::  localRng state
      inits=(list state)
      t=@ud                  ::  behaviors completed
      steps=@ud
      maxn=@ud               ::  deepest transition index reached
      gen=@ud                ::  states generated so far (9.3b)
      tm=@s                  ::  Welford running mean of completed trace lengths
      tm2=@s                 ::  Welford running M2
      walk=(unit [cur=state n=@ud path=(list state)])
      ::  the ENUMERATION generator's state (tlc2 `RandomEnumerableValues`, a
      ::  java.util.Random seeded with the run's seed). Only `-generate` draws
      ::  from it, but it rides the cursor so a resumed run is byte-identical
      es=@
  ==
+$  sim-slice
  $%  [%more cur=sim-cursor]
      [%done res=sim-result cur=sim-cursor]
  ==
::
++  nth-state
  ::  index into a state list; the dry sample widens a ?~-narrowed list
  ::  past the wet +snag (the recursive value mold otherwise mull-grows)
  |=  [i=@ud l=(list state)]
  ^-  state
  (snag i l)
::
++  nth-action
  ::  index into an action list (dry, same recursive-mold reason as +nth-state)
  |=  [i=@ud l=(list act)]
  ^-  act
  (snag i l)
::
++  succ-level
  ::  R4.2as: the env a SUCCESSOR's invariants and constraints see -- its own
  ::  level, one above the expanded state's (`TLCGet("level")` is the
  ::  evaluated state's `getLevel()`)
  |=  e=eenv:ne
  ^-  eenv:ne
  ?~  run.e  e
  e(run `u.run.e(level +(level.u.run.e)))
::
++  sim-nexts
  ::  SimulationWorker's next-state functor for one action, in generation order.
  ::  Per successor it does exactly what `SimulationWorker.addElement` does, in
  ::  that order (SimulationWorker.java:560-620):
  ::
  ::    1. `collectPreSuccessor` -- the state is COUNTED as generated here,
  ::       BEFORE any filtering, so `ngen` counts every successor produced
  ::    2. the invariants, in declaration order; a violation ends the run
  ::       (addElement throws before the state is added), returned as %viol
  ::    3. `isInModel(t) && isInActions(s, t)` -- the CONSTRAINT / ACTION_
  ::       CONSTRAINT filter. A pruned successor is silently DROPPED from the
  ::       successor set, but it was already counted and already
  ::       invariant-checked, so a violation on the pruned boundary is still
  ::       reported (the same rule +register applies in the BFS, R1.5.1)
  ::
  ::  A constraint that fails to EVALUATE drops the successor rather than
  ::  raising: the simulation path has no typed error channel (the `%|` arm
  ::  below makes the same choice for a solver failure). Named, not silent --
  ::  tlc2 would report TLC_INVARIANT_EVALUATION_FAILED's action analogue.
  ::
  ::  R2.4.6: the `%viol` arm carries `ngen` too. `collectPreSuccessor` runs
  ::  BEFORE the invariant check, so every successor generated up to AND
  ::  INCLUDING the violating one is counted; the old shape dropped the whole
  ::  violating invocation from the run's states-generated total.
  |=  $:  cur=state  a=act
          invs=(list [name=@t body=sem:sem-lib])
          iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
          cons=(list sem:sem-lib)  acons=(list sem:sem-lib)
          e=eenv:ne
      ==
  ^-  $%  [%viol name=@t st=state ngen=@ud act=?]
          [%ok nx=(list state) ngen=@ud]
          [%err msg=@t ngen=@ud]
      ==
  =/  nr  (next-states:ne cur body.a (act-env e ctx.a))
  ?:  ?=(%| -.nr)  [%ok ~ 0]
  =/  gen  p.nr
  =/  ei  (succ-level e)
  =|  keep=(list state)
  =|  n=@ud
  |-  ^-  $%  [%viol name=@t st=state ngen=@ud act=?]
              [%ok nx=(list state) ngen=@ud]
              [%err msg=@t ngen=@ud]
          ==
  ?~  gen  [%ok (flop keep) n]
  =/  fv  (first-violated invs i.gen ei)
  ?^  fv  [%viol ?-(-.u.fv %& p.u.fv, %| p.u.fv) i.gen +(n) |]
  ::  R4.Q8b: then the implied actions, on the transition (EC 2112)
  =/  fa  (first-bad-action iacts cur i.gen e)
  ?^  fa  [%viol ?-(-.u.fa %& p.u.fa, %| p.u.fa) i.gen +(n) &]
  =/  ch  (con-hold cons i.gen ei)
  ::  R4.Q8b: a constraint that fails to EVALUATE ends the run with its
  ::  error, as tlc2's does (`Tool.isInModel` throws out of `addElement`);
  ::  dropping the successor masked SmokeEWD998's refused
  ::  `TLCGet("duration")` as a clean run of one-state behaviors
  ?:  ?=(%| -.ch)  [%err p.ch +(n)]
  =/  ah  (acon-hold acons cur i.gen e)
  ?:  ?=(%| -.ah)  [%err p.ah +(n)]
  =/  in=?  &(p.ch p.ah)
  $(gen t.gen, n +(n), keep ?:(in [i.gen keep] keep))
::
::  what one action invocation yielded during a simulation step: a violating
::  successor, a non-empty surviving successor set, or nothing
+$  step-res
  $%  [%viol name=@t st=state act=?]
      [%ok nx=(list state)]
      [%none ~]
      ::  a typed engine refusal, reachable only on the `-generate` walk
      ::  (R2.4.6): it ABORTS the run rather than dropping the action, because
      ::  that is what tlc2 does with the shapes `Tool.probabilistic` refuses
      [%err msg=@t]
  ==
::
++  sim-nexts-det
  ::  +sim-nexts in `+$ step-res` shape, with the generated count folded into
  ::  the threaded `pst` instead of returned alongside
  |=  $:  cur=state  a=act
          invs=(list [name=@t body=sem:sem-lib])
          iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
          cons=(list sem:sem-lib)  acons=(list sem:sem-lib)
          e=eenv:ne  p=pst:ne
      ==
  ^-  [step-res pst:ne]
  =/  r  (sim-nexts cur a invs iacts cons acons e)
  ?:  ?=(%viol -.r)
    [[%viol name.r st.r act.r] p(ngen (add ngen.p ngen.r))]
  ?:  ?=(%err -.r)
    [[%err msg.r] p(ngen (add ngen.p ngen.r))]
  =.  ngen.p  (add ngen.p ngen.r)
  ?~  nx.r  [[%none ~] p]
  [[%ok nx.r] p]
::
++  sim-nexts-prob
  ::  the `-generate` next-state functor for one action: the probabilistic walk
  ::  returns at most ONE successor -- the first the functor accepts -- so the
  ::  successor-pick draw that follows always sees a one-element list.
  ::
  ::  Unlike the deterministic path, a failure here does NOT drop the action:
  ::  the shapes `Tool.probabilistic` refuses -- a CASE in action position --
  ::  abort tlc2 outright (exit 255, no model checking), so the refusal ends
  ::  the whole run through `sim-result.err`
  |=  $:  cur=state  a=act
          invs=(list [name=@t body=sem:sem-lib])
          iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
          cons=(list sem:sem-lib)  acons=(list sem:sem-lib)
          e=eenv:ne  p=pst:ne
      ==
  ^-  [step-res pst:ne]
  =/  ei  (succ-level e)
  =/  fil
    |=  st=state
    ^-  fres:ne
    =/  fv  (first-violated invs st ei)
    ?^  fv  [%viol ?-(-.u.fv %& p.u.fv, %| p.u.fv) |]
    =/  fa  (first-bad-action iacts cur st e)
    ?^  fa  [%viol ?-(-.u.fa %& p.u.fa, %| p.u.fa) &]
    =/  ch  (con-hold cons st ei)
    ?:  ?=(%| -.ch)  [%err p.ch]
    =/  ah  (acon-hold acons cur st e)
    ?:  ?=(%| -.ah)  [%err p.ah]
    ?:(&(p.ch p.ah) %keep %drop)
  =^  r  p  (next-states-prob:ne cur body.a (act-env e ctx.a) p fil)
  ?-  -.r
    %found  [[%ok ~[st.r]] p]
    %viol   [[%viol nm.r st.r act.r] p]
    %none   [[%none ~] p]
    %err    [[%err msg.p.r] p]
  ==
::
++  welford-add
  ::  fold one completed behavior of length `tl` into the running mean/m2 with
  ::  the online integer algorithm tlc2 SimulationWorkerStatistics uses; `k` is
  ::  the 1-based behavior count (numOfGenTraces at collectPostTrace).
  |=  [tm=@s tm2=@s tl=@ud k=@ud]
  ^-  [@s @s]
  =/  tls    (sun:si tl)
  =/  delta  (dif:si tls tm)
  =/  ntm    (sum:si tm (fra:si delta (sun:si k)))
  =/  ntm2   (sum:si tm2 (pro:si delta (dif:si tls ntm)))
  [ntm ntm2]
::
++  mk-result
  ::  finalize the run statistics. `gt` is the reported behavior count
  ::  (numOfGenTraces): completed behaviors, plus the current one when it
  ::  violated (a violating behavior is counted but excluded from the Welford
  ::  trace-length stats, as collectPostTrace runs only on a clean behavior).
  ::  Var(X) and SD use TLC's `genTrace + 1` div-by-zero guard.
  |=  $:  gt=@ud  cur=sim-cursor
          viol=(unit [kind=?(%invariant %action %property %deadlock) name=@t path=(list state)])
          err=(unit @t)
      ==
  ^-  sim-result
  =/  m2   (abs:si tm2.cur)
  =/  d    +(gt)
  =/  var  (div (add (mul 2 m2) d) (mul 2 d))       ::  round(m2 / d)
  =/  sd
    =/  x  (div:rd (sun:rd m2) (sun:rd d))
    (abs:si (need (toi:rd (add:rd (sqt:rd x) .~0.5))))
  [gt steps.cur gen.cur (abs:si tm.cur) var sd viol err]
::
++  sim-live-viol
  ::  the completed behavior (chronological) if it breaks the temporal PROPERTY,
  ::  else ~. tlc2 LiveCheck.checkTrace over the trace's stutter graph, via the
  ::  8.2–8.6 engine (+trace-lasso). `path` is newest-first (the walk order).
  |=  [o=sim-opts path=(list state) e=eenv:ne]
  ^-  (unit (list state))
  ?~  oss.o  ~
  =/  chron  (flop path)
  ?~  (trace-lasso:lv oss.o chron e order.o)  ~
  `chron
::
++  sim-step
  ::  spend up to `budget` work units (one per transition or behavior boundary).
  ::  Per step the RNG is drawn as TLC's SimulationWorker: nextDouble for the
  ::  action index, nextPrime for the retry stride, then nextDouble for the
  ::  successor pick. The draw sequence is fixed, so the run is a pure function
  ::  of [opts cursor] regardless of slicing. When a behavior completes (depth
  ::  or deadlock) its trace is checked against the temporal PROPERTY (9.3a).
  |=  [o=sim-opts cur=sim-cursor budget=@ud]
  ^-  sim-slice
  ?:  =(~ inits.cur)  [%done (mk-result 0 cur ~ ~) cur]
  ::  build the node-eval env (with its override registry) once per event; the
  ::  kont stores defs/consts/vars, never the built env (see +$ sim-opts)
  ::  R2.6.3: marked `%sim` so `TLCExt!TLCDefer`, whose deferred expression the
  ::  Simulation worker DOES execute (and the BFS one does not), can refuse here
  ::  by name instead of silently dropping the effect
  =/  e  (with-run:ne (make-env:ne defs.o consts.o vars.o) [& 0 ~])
  =/  spent  0
  |-  ^-  sim-slice
  ?:  (gte spent budget)  [%more cur]
  ?:  =(num.o t.cur)  [%done (mk-result t.cur cur ~ ~) cur]
  =/  mw  walk.cur
  ?~  mw
    ::  a) start a behavior at a random initial state (TLC checks invariants
    ::  only on successors in simulation, never on the initial state)
    =^  i0  s.cur  (floor-scaled:rng s.cur (lent inits.cur))
    =/  start  (nth-state i0 inits.cur)
    $(walk.cur `[start 0 ~[start]], spent +(spent))
  =/  w  u.mw
  ?:  =(n.w depth.o)
    ::  behavior reached full depth: check the temporal property, then fold its
    ::  length into the Welford trace-length stats and start the next behavior
    =/  lv  (sim-live-viol o path.w e)
    ?^  lv
      [%done (mk-result +(t.cur) cur `[%property pname.o u.lv] ~) cur]
    =/  wf  (welford-add tm.cur tm2.cur (min depth.o (lent path.w)) +(t.cur))
    $(walk.cur ~, t.cur +(t.cur), tm.cur -.wf, tm2.cur +.wf, spent +(spent))
  =/  alen  (lent actions.o)
  ?:  =(0 alen)
    =/  lv  (sim-live-viol o path.w e)
    ?^  lv
      [%done (mk-result +(t.cur) cur `[%property pname.o u.lv] ~) cur]
    =/  wf  (welford-add tm.cur tm2.cur (min depth.o (lent path.w)) +(t.cur))
    $(walk.cur ~, t.cur +(t.cur), tm.cur -.wf, tm2.cur +.wf, spent +(spent))
  ::  b) pick an action and the retry stride prime, then walk actions from that
  ::  index until one yields successors ((index + p) % alen per retry)
  =^  index  s.cur  (floor-scaled:rng s.cur alen)
  =^  p      s.cur  (next-prime:rng s.cur)
  ::  the retry loop threads BOTH generators and the generated count through
  ::  `pst`: an action whose successors were all constrained out still counted
  ::  them (collectPreSuccessor) and, under `-generate`, still spent enumeration
  ::  draws, so neither may be lost across a retry
  =/  fnd
    =/  tries  0
    ::  R2.7.4.1b: `pst` now EMBEDS the R2.7.4.1 carrier, because the
    ::  enumeration seed and `RandomElement`'s are the same generator at the
    ::  pin. The cursor still owns the seed across steps; it is loaded into
    ::  the carrier here and read back below
    ::  bound to its own face first: `empty-rst:ne(es …)` parses as a `%=` on
    ::  `ne`, the library core, not on the arm's product
    =/  rs0=rst:ne  empty-rst:ne
    =/  pp=pst:ne  [rs0(es es.cur) s.cur 0]
    ::  R4.2as: `TLCGet("level")` is the expanded state's position in the
    ::  behavior (the initial state is level 1); it read the constant 0, so
    ::  EWD840_anim's `TLCGet("level") < 20` held on every behavior
    =/  e  (with-run:ne e [& +(n.w) ~])
    |-  ^-  [step-res pst:ne]
    ?:  =(tries alen)  [[%none ~] pp]
    =/  a  (nth-action index actions.o)
    =^  r  pp
      ?:  prob.o  (sim-nexts-prob cur.w a invs.o iacts.o cons.o acons.o e pp)
      (sim-nexts-det cur.w a invs.o iacts.o cons.o acons.o e pp)
    ?.  ?=(%none -.r)  [r pp]
    $(tries +(tries), index (mod (add index p) alen))
  =/  found  -.fnd
  =.  es.cur   es.rs.fnd
  =.  s.cur    ls.fnd
  =.  gen.cur  (add gen.cur ngen.fnd)
  ?:  ?=(%err -.found)
    ::  a `-generate` refusal: the run ENDS with no verdict, as tlc2 aborts
    [%done (mk-result t.cur cur ~ `msg.found) cur]
  ?:  ?=(%none -.found)
    ::  no action produced a SURVIVING successor. Anything it did generate was
    ::  still counted before the constraint dropped it.
    ::  tlc2 SimulationWorker.java:692-698 --
    ::
    ::      if (nextStates.empty()) {
    ::        if (checkDeadlock) { return ... EC.TLC_DEADLOCK_REACHED ... }
    ::        break;
    ::      }
    ::
    ::  so with deadlock checking ON this ends the WHOLE simulation with the
    ::  behavior up to and including the deadlocked state (`getTrace(curState)`
    ::  -- there is no successor to extend it by), and the temporal PROPERTY is
    ::  NOT checked first: the `return` pre-empts the post-trace path that runs
    ::  the liveness check, the same deadlock-over-liveness precedence R1.6.6
    ::  established for the exhaustive checker. With it OFF, `break` just ends
    ::  this behavior and the next one starts -- the fold below.
    ?:  ddl.o
      [%done (mk-result +(t.cur) cur `[%deadlock '' (flop path.w)] ~) cur]
    =/  lv  (sim-live-viol o path.w e)
    ?^  lv
      [%done (mk-result +(t.cur) cur `[%property pname.o u.lv] ~) cur]
    =/  wf  (welford-add tm.cur tm2.cur (min depth.o (lent path.w)) +(t.cur))
    $(walk.cur ~, t.cur +(t.cur), tm.cur -.wf, tm2.cur +.wf, spent +(spent))
  ?:  ?=(%viol -.found)
    ::  an invariant violation ends the run with the offending behavior. The
    ::  successors this action generated are still COUNTED (R2.4.6): tlc2's
    ::  `collectPreSuccessor` runs before `addElement` checks the invariant --
    ::  which the `gen.cur` fold above now does for every outcome
    :+  %done
      =/  vk  ?:(act.found %action %invariant)
      (mk-result +(t.cur) cur `[vk name.found (flop [st.found path.w])] ~)
    cur
  ::  d) pick one successor and make it the current state; every successor the
  ::  chosen action generated counts toward states-generated (collectPre)
  =^  j  s.cur  (floor-scaled:rng s.cur (lent nx.found))
  =/  s1  (nth-state j nx.found)
  %=  $
    spent      +(spent)
    walk.cur   `[s1 +(n.w) [s1 path.w]]
    steps.cur  +(steps.cur)
    maxn.cur   (max maxn.cur +(n.w))
  ==
::
++  sim-cursor-init
  ::  a fresh simulation cursor. Single-worker Simulator seeds the worker RNG
  ::  from one nextLong of the user-seeded generator, then the worker scrambles
  ::  it (new RandomGenerator(workerSeed)); that scrambled value is the state.
  |=  [inits=(list state) seed=@]
  ^-  sim-cursor
  =/  wseed  -:(next-long:rng (scramble:rng seed))
  ::  states generated counts the initial states first (tlc2 getInitStates).
  ::  The enumeration generator is seeded with the RUN's seed directly
  ::  (`RandomEnumerableValues.setSeed(seed)`, TLC.java:1400), not the worker's
  [(scramble:rng wseed) inits 0 0 0 (lent inits) --0 --0 ~ (scramble:rng seed)]
::
++  simulate
  ::  bounded seeded simulation: up to `num` random behaviors, each up to
  ::  `depth` transitions, byte-identical to `tlc2.TLC -simulate -workers 1`.
  |=  [o=sim-opts inits=(list state) seed=@]
  ^-  sim-result
  =/  cur  (sim-cursor-init inits seed)
  |-  ^-  sim-result
  =/  r  (sim-step o cur 1.024)
  ?:  ?=(%done -.r)  res.r
  $(cur cur.r)
::
++  simulate-spec
  ::  run a bounded seeded simulation from spec + config source, returning a
  ::  structured summary (traces / steps / whether a violation was found)
  |=  [spec=@t cfg=@t seed=@ traces=@ud depth=@ud]
  ^-  sim-result
  (sim-spec-mode spec cfg seed traces depth |)
::
++  generate-spec
  ::  the same run under tlc2's `-generate` (R2.4.6): probabilistic successor
  ::  picking. Same seed, same statistics shape, a different walk
  |=  [spec=@t cfg=@t seed=@ traces=@ud depth=@ud]
  ^-  sim-result
  (sim-spec-mode spec cfg seed traces depth &)
::
++  sim-spec-mode
  |=  [spec=@t cfg=@t seed=@ traces=@ud depth=@ud prob=?]
  ^-  sim-result
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [0 0 0 0 0 0 ~ ~]
  =*  c  p.sc
  =/  actions  (get-actions nsb.c aname.c defs.c (make-env:ne defs.c consts.c vars.c))
  =/  pname  ?~(pp.c '' u.pp.c)
  =/  o=sim-opts
    :*  actions  (weld invs.c binvs.c)  cons.c  acons.c  ddl.c  oss.c  pname
        defs.c  consts.c  vars.c  order.c  traces  depth  prob  iacts.c
    ==
  (simulate o is.c seed)
::
++  sem-body
  ::  the semantic body of the operator definition named `nm`
  |=  [defs=(map @t sem-def:sem-lib) nm=@t]
  ^-  (unit sem:sem-lib)
  =/  d  (~(get by defs) nm)
  ?~(d ~ body.u.d)
::
++  resolve-bodies
  ::  the sem bodies of a name list (unresolvable names dropped)
  |=  [defs=(map @t sem-def:sem-lib) nms=(list @t)]
  ^-  (list sem:sem-lib)
  %+  murn  nms
  |=(nm=@t (sem-body defs nm))
::
++  resolve-names
  ::  the config names `+resolve-bodies` KEPT, in the same order -- the index
  ::  alignment the coverage block's per-constraint counters key on
  |=  [defs=(map @t sem-def:sem-lib) nms=(list @t)]
  ^-  (list @t)
  %+  murn  nms
  |=  nm=@t
  ^-  (unit @t)
  ?~((sem-body defs nm) ~ `nm)
::
++  resolve-invs
  ::  named invariants paired with their sem bodies, in declaration order
  |=  [defs=(map @t sem-def:sem-lib) nms=(list @t)]
  ^-  (list [name=@t body=sem:sem-lib])
  %+  murn  nms
  |=  nm=@t
  ^-  (unit [name=@t body=sem:sem-lib])
  =/  b  (sem-body defs nm)
  ?~(b ~ `[nm u.b])
::
::  the shared WU6.9 search context: everything the safety/liveness engines
::  need, resolved from the semantic graph, with the initial states solved
+$  sctx
  $:  is=(list state)                       ::  solved initial states
      defs=(map @t sem-def:sem-lib)
      consts=(map @t value)
      vars=(set @t)
      order=(list @t)                        ::  vars in declaration order
      perms=(list (map @t @t))               ::  symmetry group (SYMMETRY)
      asmz=(list sem-thm:sem-lib)            ::  module ASSUME bodies
      nsb=sem:sem-lib                        ::  Next body
      invs=(list [name=@t body=sem:sem-lib])  ::  invariants (declaration order)
      cons=(list sem:sem-lib)                 ::  state constraints
      acons=(list sem:sem-lib)                ::  action constraints
      ::  the CONFIG names of those constraints, index-aligned with the two
      ::  lists above (`+resolve-bodies` drops a name with no definition, so
      ::  the same filter builds these). Only the coverage block needs them,
      ::  and it needs them by index -- which is why the constraint lists
      ::  themselves are left alone rather than reshaped into named pairs
      ::  through the simulation and DFID engines too (R2.7.4.2b)
      cnames=(list @t)
      anames=(list @t)
      ddl=?                                   ::  check deadlock (cfg flag)
      pp=(unit @t)                           ::  property name (liveness)
      ::  R2.7.12: the IMPLIED TEMPORALS -- every PROPERTY that reaches the
      ::  liveness engine, with its body, in declaration order (tlc2's
      ::  `Tool.getImpliedTemporals()`). `pp` is the FIRST property's name and
      ::  is only a fallback now: which property a counter-example violates is
      ::  decided POST-HOC against the lasso, over this list
      props=(list [name=@t body=sem:sem-lib])
      ::  R2.7.15a: the other three bins `+bin-properties` fills, so every
      ::  engine routes the WHOLE list instead of testing `pp`. `binvs` are
      ::  the `[]P` box-state properties, appended to the INVARIANT vector
      ::  after the config's own; `iinits` the level<=1 implied inits;
      ::  `iacts` the `[][A]_v` implied actions, checked on every transition
      binvs=(list [name=@t body=sem:sem-lib])
      iinits=(list [name=@t body=sem:sem-lib])
      iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
      ::  R2.7.15b: the raw `PROPERTY` names in CONFIG ORDER. The four bins
      ::  above are derived from it and cannot reconstruct it -- a consumer
      ::  that re-bins (DFID) needs the original order, because the EC 2255
      ::  state-level warnings are emitted in it
      pnames=(list @t)
      fair=(list sem:sem-lib)                ::  fairness conjuncts (WF_/SF_/
                                             ::  []temporal) from a SPECIFICATION
                                             ::  decomposition (SpecProcessor
                                             ::  getTemporals); empty in
                                             ::  INIT/NEXT mode (unit 5.3c/8.1)
      sname=(unit @t)                        ::  the SPECIFICATION's name and
      sloc=sspan:sem-lib                     ::  definition span, for the EC 2259
                                             ::  stuttering hint (R1.8.1.3)
      tree=node
      view=(unit sem:sem-lib)                ::  VIEW body (R2.3.1): a state's
                                             ::  identity is this expression's
                                             ::  value, not its bindings
      alias=(unit sem:sem-lib)               ::  ALIAS body (R2.3.2): a trace
                                             ::  state renders as this record's
                                             ::  fields, not its bindings
      aname=@t                               ::  ROOT action name: the NEXT
                                             ::  operator's name, or `Action`
                                             ::  under a SPECIFICATION (tlc2
                                             ::  builds that action with a null
                                             ::  opDef, so `Action.getLocation`
                                             ::  prints its generic "Action")
      nl=@t                                  ::  whole-relation span label
      vrend=(unit sem:sem-lib)               ::  `-view` (R2.4.3): the VIEW body
                                             ::  when the render flag is set
      swarn=(list @t)                        ::  SPECIFICATION-decomposition
                                             ::  warnings, printed BEFORE the
                                             ::  verdict (R2.3.5): today the
                                             ::  EC 2145 subscript-coverage one
      ::  R2.7.4.2b: the INIT operator's name, and the candidates the initial
      ::  predicate rejected once they were already fully assigned -- the two
      ::  halves of the INIT coverage line
      iname=@t
      irej=@ud
      ::  R2.7.7.3: the POSTCONDITION names, evaluated after exploration.
      ::  Carried here rather than re-parsed at the render site, and NOT
      ::  resolved yet -- the pin resolves them when it fetches them, after
      ::  the search, so an unresolvable name must fail there and not before
      pcs=(list @t)
      ::  R2.7.7.4b: `_POSSIBLE`'s predicates, resolved with their LEVELS --
      ::  state-level ones are tracked as model constraints, action-level ones
      ::  as action constraints, which is how the pin wires them
      poss=(list [name=@t body=sem:sem-lib lvl=@ud])
      ::  R2.7.4.3/.4: the CARRIER as the INITIAL-STATE solve left it. An
      ::  `Init` conjunct may write the register store
      ::  (`Init == x = 0 /\ TLCSet(0, 100)`) or draw from the RNG
      ::  (`Init == x = RandomElement(0..9)`), and the pin's state outlives
      ::  that phase -- measured, the first `Next` reads 100 back. The solve
      ::  happens once at %config, before any cursor exists, so it is carried
      ::  here and seeded into the cursor
      irs=rst:ne
      ::  R4.2aa: the RNG state after the startup definitions, where the
      ::  ASSUMEs start drawing (`+check-assumes`)
      ses=@
      ::  R4.2a: what the startup definitions and the ASSUMEs PRINTED, oldest
      ::  first -- the whole console output of a run whose ASSUME fails
      aout=(list @t)
      oss=(list oos:tp)                      ::  the normalized temporal
                                             ::  decomposition (unit 8.1), built
                                             ::  from the PROPERTY + fairness via
                                             ::  temporal.hoon; carried for the
                                             ::  8.2 tableau/product to consume
  ==
::
++  sem-lvl
  ::  the level of an IR node (apply/letin/atref carry it; a literal is
  ::  constant-level, nullodn has none)
  |=  s=sem:sem-lib
  ^-  @ud
  ?-  -.s
    %apply    lvl.s
    %letin    lvl.s
    %atref    lvl.s
    %lit      0
    %nullodn  0
  ==
::
++  weld-sem
  ::  hand-rolled weld over the recursive `sem` mold (wet weld fuse-loops it)
  |=  [a=(list sem:sem-lib) b=(list sem:sem-lib)]
  ^-  (list sem:sem-lib)
  ?~  a  b
  [i.a $(a t.a)]
::
++  rev-sem
  ::  hand-rolled reverse over the recursive `sem` mold (wet flop fuse-loops it)
  |=  l=(list sem:sem-lib)
  ^-  (list sem:sem-lib)
  =|  acc=(list sem:sem-lib)
  |-  ^-  (list sem:sem-lib)
  ?~  l  acc
  $(l t.l, acc [i.l acc])
::
++  max-lvl
  ::  hand-rolled max level over IR nodes (wet roll fuse-loops the mold)
  |=  l=(list sem:sem-lib)
  ^-  @ud
  =|  m=@ud
  |-  ^-  @ud
  ?~  l  m
  $(l t.l, m (max m (sem-lvl i.l)))
::
++  resolve-ref
  ::  resolve an arity-0 user-operator reference to its body; leave any other
  ::  node unchanged (TLC's nextPred wraps the `Next` reference and getNextStates
  ::  expands it — our solver takes the resolved body)
  |=  [s=sem:sem-lib defs=(map @t sem-def:sem-lib)]
  ^-  (unit sem:sem-lib)
  ?.  ?=(%apply -.s)  `s
  ?.  &(?=(%user-op kind.op.s) =(~ args.s))  `s
  =/  d  (~(get by defs) name.op.s)
  ?~  d  ~
  body.u.d
::
++  conjoin-inits
  ::  the initial predicate is the conjunction of the SPECIFICATION's
  ::  init conjuncts (TLC's initPredVec); a single conjunct passes through
  |=  [l=(list sem:sem-lib) sp=(unit span)]
  ^-  (unit sem:sem-lib)
  ?~  l  ~
  ?~  t.l  `i.l
  `[%apply ['$ConjList' %builtin] (max-lvl l) sp ~ ~ l]
::
++  is-false-body
  ::  is this definition body the constant FALSE?
  |=  b=sem:sem-lib
  ^-  ?
  ?.  ?=(%apply -.b)  |
  &(?=(%builtin kind.op.b) =('FALSE' name.op.b))
::
++  decompose-spec
  ::  port of SpecProcessor.processConfigSpec: structurally decompose a
  ::  SPECIFICATION body into its init conjuncts, its next-state action, and
  ::  its fairness/temporal conjuncts. A worklist (never `turn`/`roll` over the
  ::  recursive `sem` mold) processes conjuncts depth-first in source order.
  ::  R2.3.5 lands the subscript-variable-coverage warning and LazyValue
  ::  parameter inlining. INSTANCE substitution stays deferred and is now
  ::  deferred for a REASON that is written down: peeling `$SubstIn` here is
  ::  easy (`+substin-parts` already exists), but the substituted body then has
  ::  to be EVALUATED, and `node-eval` has no `$SubstIn` case -- an inner
  ::  module's `v` must resolve through `v <- x` to the outer state's binding,
  ::  which is a renaming frame in the evaluator, not a value binding. That is
  ::  engine work in `lib/node-eval`, not decomposition.
  ::
  ::  `vars` is the declared state-variable set: the subscript of `[][A]_v` is
  ::  checked against it and each variable the subscript does not cover raises
  ::  EC 2145 (a WARNING; the run proceeds). `~` skips the check.
  |=  [body=sem:sem-lib defs=(map @t sem-def:sem-lib) vars=(list @t)]
  ^-  $:  inits=(list sem:sem-lib)
          next=(unit sem:sem-lib)
          fair=(list sem:sem-lib)
          err=(unit @t)
          warn=(list @t)
      ==
  =/  work=(list sem:sem-lib)  ~[body]
  =|  inits=(list sem:sem-lib)
  =|  fair=(list sem:sem-lib)
  =|  warn=(list @t)
  ::  the INSTANCE substitution wrappers peeled so far, innermost FIRST --
  ::  tlc2's `subs` list, consumed by `Specs.addSubsts` at every leaf
  =|  subs=(list [mod=@t names=(list sbind:sem-lib) exprs=(list sem:sem-lib) inner=sem:sem-lib lvl=@ud at=sspan:sem-lib])
  =/  next=(unit sem:sem-lib)  ~
  |-  ^-  [(list sem:sem-lib) (unit sem:sem-lib) (list sem:sem-lib) (unit @t) (list @t)]
  ?~  work  [(rev-sem inits) next (rev-sem fair) ~ (flop warn)]
  =/  p     i.work
  =/  rest  t.work
  ?.  ?=(%apply -.p)
    ?:  ?=(%letin -.p)
      ?~  body.p  $(work rest)
      $(work [u.body.p rest])
    ::  a literal/atref conjunct: route by level
    =/  l  (sem-lvl p)
    ?:  (lte l 1)  $(work rest, inits [(add-subs p subs) inits])
    ?:  =(3 l)     $(work rest, fair [(add-subs p subs) fair])
    [inits next fair `'cannot handle this conjunct in the SPECIFICATION' warn]
  =/  op  name.op.p
  ::  EC 2237: a conjunct that is constantly FALSE makes the whole spec
  ::  trivially false, and tlc2 names the conjunct AS WRITTEN — the operator
  ::  name for `Falsy == FALSE`, the literal for an inline `FALSE` (R1.8.1.3)
  ?:  &(?=(%builtin kind.op.p) =('FALSE' op))
    [inits next fair `'The spec is trivially false because FALSE is false.' warn]
  ::  INSTANCE substitution (R2.3.5): `Spec == I!SpecI` reaches the behaviour
  ::  spec THROUGH an instance, so the conjunct is a `$SubstIn` wrapper. tlc2
  ::  pushes the wrapper onto `subs`, decomposes the body, and re-wraps every
  ::  leaf with `Specs.addSubsts` -- the leaves are evaluated later and must
  ::  still carry the bindings. `+substin-parts` peels and `+rewrap-substin`
  ::  re-wraps, so `subs` is that stack, applied at each emission point
  ?:  ?=(^ (anysubstin-mod:sem-lib op))
    =/  sp  (substin-parts:sem-lib p)
    ?~  sp  $(work rest)
    $(work [inner.u.sp rest], subs [u.sp subs])
  ::  LazyValue parameter inlining (R2.3.5), in the one shape the port can
  ::  soundly do it: `Op(A)` where `Op(i) == i`. The body IS the formal, so the
  ::  apply simply DENOTES `A` and decomposition continues on `A` -- no context
  ::  has to survive into a leaf. That is Github1244's shape
  ::  (`MyInit(myInit) == myInit`, `Spec == MyInit(Init) /\ [][Next]_vars`).
  ::
  ::  tlc2 inlines ANY parameterized body because its `Action` carries the
  ::  `Context`, so a formal left inside an emitted leaf still resolves when the
  ::  action is evaluated. The port's leaves carry no context, so a body
  ::  decomposition does not fully reach would emit an UNBOUND formal.
  ::  Measured, not predicted: inlining unconditionally regressed tier-2
  ::  `AssignmentInitNeg` to `Error: undefined identifier: var` -- a spec that
  ::  passes by falling through to the level check below and letting
  ::  `node-eval`'s own operator application bind the formals properly. So
  ::  every other parameterized operator is left to the evaluator, which
  ::  already handles it
  =/  ident-arg
    ^-  (unit sem:sem-lib)
    ?.  ?&(?=(%user-op kind.op.p) ?=([* ~] args.p))  ~
    =/  d  (~(get by defs) op)
    ?~  d  ~
    ?~  body.u.d  ~
    ?.  =(1 (lent params.u.d))  ~
    =/  b  u.body.u.d
    ?.  ?&(?=(%apply -.b) ?=(%formal-param kind.op.b) ?=(~ args.b))  ~
    `i.args.p
  ?^  ident-arg  $(work [u.ident-arg rest])
  ?:  &(?=(%user-op kind.op.p) =(~ args.p))
    ::  arity-0 user operator: expand its body (init if state-level, else recurse)
    =/  d  (~(get by defs) op)
    ::  R2.3.5: inside an INSTANCE substitution a bare name is the INNER
    ::  module's, and the root `defs` map holds instanced members under their
    ::  qualified names (`I!InitI`) -- a member referencing a SIBLING member
    ::  (`SpecI == InitI /\ [][NextI]_v`) therefore resolves to nothing here.
    ::  That is a gap in instance GENERATION, not in substitution (which works:
    ::  `inst-keys` and `spec-inst-flat` both run), so it is refused by name
    ::  rather than dropped -- dropping it produced `the SPECIFICATION has no
    ::  initial predicate`, which described nothing the caller wrote
    ?:  &(?=(~ d) ?=(^ subs))
      :^  inits  next  fair
      :-  `(crip "unsupported: instanced member references a sibling of its own module ({(trip op)}); the root defs map holds instanced members qualified (unit 3)")
      warn
    ?~  d  $(work rest)
    ?~  body.u.d  $(work rest)
    ?:  (is-false-body u.body.u.d)
      :^  inits  next  fair
      :-  `(crip "The spec is trivially false because {(trip op)} is false.")
      warn
    ?:  =(1 (sem-lvl u.body.u.d))
      $(work rest, inits [(add-subs u.body.u.d subs) inits])
    $(work [u.body.u.d rest])
  ?:  |(=(op '$ConjList') =(op '\\land'))
    $(work (weld-sem args.p rest))
  ?:  =('$Nop' (end [3 4] op))
    ?~  args.p  $(work rest)
    $(work [i.args.p rest])
  ?:  =(op '[]')
    =/  arg  ?~(args.p p i.args.p)
    ?:  &(?=(%apply -.arg) =('$SquareAct' name.op.arg))
      ::  [][A]_v: the next-state relation is A (the first SquareAct argument)
      ?^  next  [inits next fair `'the SPECIFICATION has more than one next-state relation' warn]
      ?~  args.arg  [inits next fair `'malformed [A]_v in the SPECIFICATION' warn]
      ::  EC 2145 (R2.3.5): `[A]_v`'s SUBSCRIPT must mention every declared
      ::  state variable, or TLC's analysis is unsound -- a variable outside it
      ::  is never compared, so a step that changes it looks like stuttering.
      ::  tlc2 WARNS per uncovered variable and proceeds
      ::  (`SpecProcessor.java:1327-1339`), which is what makes this a warning
      ::  worth having rather than a rejection: the run still produces a result,
      ::  it is just a result about a smaller relation than the author wrote
      ::  the subscript is read in the INNER scope when the spec was reached
      ::  through an INSTANCE, so `[NextI]_v` under `v <- x` covers `x`, not
      ::  `v`. Translate through the substitutions before comparing against the
      ::  declared variables, or every instanced spec warns spuriously (R2.3.5)
      =/  subv
        %+  turn  ?~(t.args.arg ~ (subscript-vars i.t.args.arg defs))
        |=(nm=@t (subst-var-name nm subs))
      ::  the message is TWO console lines, so it is two `wain` entries -- not
      ::  one entry with an embedded newline. Built by an EXPLICIT loop: a wet
      ::  `turn`/`skip` here fuses against this arm's own recursive product
      ::  type and `fuse-loop`s the zuse-408 compiler, the same trap
      ::  `+render-outcome` records for its initial-state branch
      =.  warn  (subscript-warns vars subv warn)
      $(work rest, next `(add-subs i.args.arg subs))
    ?:  (lte (sem-lvl arg) 1)
      [inits next fair `'TLC cannot handle a [] of a state predicate in the SPECIFICATION' warn]
    $(work rest, fair [(add-subs p subs) fair])
  ::  any other conjunct: route by level
  =/  l  (sem-lvl p)
  ?:  (lte l 1)  $(work rest, inits [(add-subs p subs) inits])
  ?:  =(3 l)     $(work rest, fair [(add-subs p subs) fair])
  [inits next fair `'cannot handle this conjunct in the SPECIFICATION' warn]
::
++  subst-var-name
  ::  translate a name through the INSTANCE substitutions it was read under,
  ::  innermost outward: `v` under `v <- x` is `x`. A substitution onto
  ::  anything but a bare variable leaves the name alone -- it names no single
  ::  declared variable, which is exactly the case EC 2145 should still warn on
  |=  $:  nm=@t
          subs=(list [mod=@t names=(list sbind:sem-lib) exprs=(list sem:sem-lib) inner=sem:sem-lib lvl=@ud at=sspan:sem-lib])
      ==
  ^-  @t
  ?~  subs  nm
  =/  hit
    =/  ns  names.i.subs
    =/  xs  exprs.i.subs
    |-  ^-  (unit sem:sem-lib)
    ?~  ns  ~
    ?~  xs  ~
    ?:(=(name.i.ns nm) `i.xs $(ns t.ns, xs t.xs))
  ?~  hit  $(subs t.subs)
  =/  x  u.hit
  ?.  ?&(?=(%apply -.x) ?=(%variable kind.op.x) ?=(~ args.x))
    $(subs t.subs)
  $(nm name.op.x, subs t.subs)
::
++  add-subs
  ::  re-wrap a decomposed leaf in the INSTANCE substitutions it was reached
  ::  through -- `Specs.addSubsts` (`Specs.java:82`). Innermost first, so each
  ::  wrap goes OUTSIDE the last and the nesting matches the source (R2.3.5)
  |=  $:  n=sem:sem-lib
          subs=(list [mod=@t names=(list sbind:sem-lib) exprs=(list sem:sem-lib) inner=sem:sem-lib lvl=@ud at=sspan:sem-lib])
      ==
  ^-  sem:sem-lib
  ?~  subs  n
  %=  $
    subs  t.subs
    n     (rewrap-substin:sem-lib mod.i.subs names.i.subs exprs.i.subs n lvl.i.subs at.i.subs)
  ==
::
++  subscript-warns
  ::  EC 2145 lines for every declared variable the subscript does not cover.
  ::  `acc` is carried REVERSED, as `+decompose-spec`'s `warn` is (it flops on
  ::  return), so each two-line message is pushed second-line-first
  |=  [vars=(list @t) subv=(list @t) acc=(list @t)]
  ^-  (list @t)
  ?~  vars  acc
  =/  covered  (lien subv |=(w=@t =(w i.vars)))
  =?  acc  !covered
    :+  (crip "does not seem to contain the state variable {(trip i.vars)}")
      'Warning: The subscript of the next-state relation specified by the specification'
    acc
  $(vars t.vars)
::
++  subscript-vars
  ::  the state variables a `[A]_v` SUBSCRIPT covers — a port of
  ::  `SpecProcessor.SubscriptCollector` (R2.3.5). A bare variable counts; a
  ::  TUPLE recurses into its members; a 0-ary user operator expands to its
  ::  body; EVERY OTHER built-in is IGNORED rather than descended into, which
  ::  is the Java's own rule ("Variables that appear in other kinds of
  ::  expressions are ignored") and is why `<<x, y>>` covers both while
  ::  `x + y` covers neither
  |=  [sub=sem:sem-lib defs=(map @t sem-def:sem-lib)]
  ^-  (list @t)
  =/  work=(list sem:sem-lib)  ~[sub]
  =|  out=(list @t)
  =|  seen=(set @t)
  |-  ^-  (list @t)
  ?~  work  (flop out)
  =/  p     i.work
  =/  rest  t.work
  ?.  ?=(%apply -.p)
    ?:  ?=(%letin -.p)
      ?~(body.p $(work rest) $(work [u.body.p rest]))
    $(work rest)
  ?:  ?=(%variable kind.op.p)
    $(work rest, out [name.op.p out])
  ?:  &(?=(%builtin kind.op.p) =('$Tuple' name.op.p))
    $(work (weld-sem args.p rest))
  ?:  &(?=(%builtin kind.op.p) =('$Nop' (end [3 4] name.op.p)))
    ?~(args.p $(work rest) $(work [i.args.p rest]))
  ::  every other built-in is ignored, exactly as the Java ignores it
  ?:  ?=(%builtin kind.op.p)  $(work rest)
  ?.  ?=(%user-op kind.op.p)  $(work rest)
  ::  a user operator expands to its body once (a cycle would not terminate)
  ?:  (~(has in seen) name.op.p)  $(work rest)
  =/  d  (~(get by defs) name.op.p)
  ?~  d  $(work rest)
  ?~  body.u.d  $(work rest)
  $(work [u.body.u.d rest], seen (~(put in seen) name.op.p))
::
++  resolve-targets
  ::  resolve the Init body, Next body, fairness conjuncts, and the Next
  ::  operator name from either INIT/NEXT config keys or a SPECIFICATION.
  ::  Takes the three NAMES rather than a whole `cfg-ast`, so the job kernel
  ::  can call it with a `run-mode` and the console path with its ast, and
  ::  both resolve a SPECIFICATION the same way (R1.8.3)
  ::  `vars` is the declared state-variable order, passed through so the
  ::  decomposition can raise the EC 2145 subscript-coverage warning (R2.3.5)
  |=  $:  [in=(unit @t) nx=(unit @t) sp=(unit @t)]
          defs=(map @t sem-def:sem-lib)
          vars=(list @t)
      ==
  ^-  (each [init=sem:sem-lib next=sem:sem-lib fair=(list sem:sem-lib) nname=(unit @t) warn=(list @t)] @t)
  ?:  &(?=(^ in) ?=(^ nx))
    =/  isb  (sem-body defs u.in)
    =/  nsb  (sem-body defs u.nx)
    ?~  isb  [%| 'no Init definition']
    ?~  nsb  [%| 'no Next definition']
    ::  INIT/NEXT mode has no subscript to check -- the warning is a property
    ::  of `[A]_v`, which only a SPECIFICATION carries
    [%& u.isb u.nsb ~ `u.nx ~]
  ?~  sp  [%| 'no INIT/NEXT or SPECIFICATION in config']
  =/  sb  (sem-body defs u.sp)
  ?~  sb  [%| 'no specification definition']
  =/  d  (decompose-spec u.sb defs vars)
  ?^  err.d  [%| u.err.d]
  ?~  next.d  [%| 'the SPECIFICATION has no next-state relation']
  =/  nsb  (resolve-ref u.next.d defs)
  ?~  nsb  [%| 'the next-state relation is undefined']
  =/  isb  (conjoin-inits inits.d (sem-span:config u.sb))
  ::  the Next span label uses the operator name when the action is a
  ::  user-op reference (as in [][Next]_v)
  =/  nname=(unit @t)
    =/  n  u.next.d
    ?:(&(?=(%apply -.n) ?=(%user-op kind.op.n)) `name.op.n ~)
  ::  R3.2: a SPECIFICATION with a next-state relation but NO INITIAL
  ::  PREDICATE is not an error either. `BagsTest`'s `Spec == [][TRUE]_<<>>`
  ::  is the shape -- a module of ASSUMEs with a dummy spec to make TLC run --
  ::  and tlc2 answers it exactly as it answers a config with no behaviour spec
  ::  at all: zero initial states, `Model checking completed`, 0/0/0, depth 0.
  ::  The init is handed on as `%nullodn`, the same marker R3.0a's no-behaviour
  ::  path uses, and `+search-ctx-seed` reads THAT rather than a second flag,
  ::  so both shapes take one code path. R3.0a fixed the sibling at line 2449
  ::  and did not sweep the bin; this is the sweep
  ?~  isb  [%& [%nullodn ~] u.nsb fair.d nname warn.d]
  [%& u.isb u.nsb fair.d nname warn.d]
::
++  search-ctx
  ::  `+search-ctx-seed` for a run that pins no `-seed`, which is every path
  ::  that predates R2.7.4.4 and every spec with no `TLC!RandomElement` in it
  |=  [spec=@t cfg=@t]
  ^-  (each sctx @t)
  (search-ctx-seed spec cfg 0)
::
++  search-ctx-seed
  ::  parse, generate the WU3 graph, resolve config targets, solve the
  ::  initial states; a typed failure short-circuits with a message line
  ::  R2.7.4.4: the INITIAL-state solve draws from the run's `-seed` ALONE.
  ::  `IdThread.getCurrentState()` is null there -- initial states are computed
  ::  off a worker -- so `TLCStateRandom` never reseeds and the whole init
  ::  phase runs from `new Random(randomSeed)`. The per-predecessor
  ::  `fingerPrint ^ seed` reseeding starts only in `+bfs-step`
  |=  [spec=@t cfg=@t seed=@ud]
  ^-  (each sctx @t)
  =/  pr  (parse:syntax spec)
  ?:  ?=(%| -.pr)  [%| 'parse error']
  =/  tree  p.pr
  ::  R2.7.3: a decimal literal takes the module down at SPEC PROCESSING, before
  ::  anything is evaluated, so the check belongs here rather than in the
  ::  evaluator (see `+first-decimal`)
  =/  dec  (first-decimal tree)
  ?^  dec  [%| (decimal-error u.dec)]
  =/  vars  (var-names tree)
  =/  order  (var-order tree)
  =/  cr  (parse-cfg:config cfg)
  ?:  ?=(%| -.cr)  [%| 'config error']
  =/  ca  p.cr
  ::  R2.7.7.1: a `.cfg` keyword this engine parses but does not act on is
  ::  refused BY NAME here, before anything runs. Both paths parse the config
  ::  themselves, so the kernel repeats this check rather than sharing a call
  ::  site -- the shape R2.7.5 used for the EC 2279 guard.
  ::
  ::  R2.7.7.2: but a MALFORMED name is the pin's diagnostic, not ours, so the
  ::  name check runs FIRST -- below, once the module is generated. The
  ::  refusal moved with it
  ::  R2.7.5 annotated the mold: a bare `?~(.. ~ `x)` infers a union with no
  ::  `u` face, so `u.pp` was `-find.u.pp` until the `(unit @t)` named it
  =/  pp=(unit @t)  ?~(properties.ca ~ `i.properties.ca)
  =/  modn  (module-name-of tree)
  =/  mo  (generate:sem-lib modn (malt ~[[modn spec]]))
  ?~  mo  [%| 'semantic error']
  ::  R2.7.7.2: the `.cfg` keyword names the pin resolves at spec processing.
  ::  The console never calls `+validate-config`, so without this a caller
  ::  here sees R2.7.7.1's refusal for a config the pin rejects with its own
  ::  diagnostic -- and the refusal is only right once the name resolves
  =/  kwd  (ck-keyword-names:config u.mo ca)
  ?^  kwd  [%| msg.u.kwd]
  =/  ukw  (unsupported-kw:config ca)
  ?^  ukw  [%| u.ukw]
  =/  defs  (apply-overrides (defmap-of:ne u.mo) overrides.ca mod-overrides.ca)
  ::  R3.0a: a config that declares NO behaviour spec AT ALL -- neither an
  ::  INIT/NEXT pair nor a SPECIFICATION -- is not an error. tlc2 runs it as an
  ::  ordinary breadth-first search over ZERO initial states and reports
  ::  `Model checking completed. No error has been found.` with `0 states
  ::  generated, 0 distinct states found, 0 states left on queue.` at depth 0.
  ::  That is the documented idiom for using TLC to EVALUATE EXPRESSIONS: the
  ::  module is a list of ASSUMEs and checking them is the entire run
  ::  (`SpecifyingSystems/SimpleMath`, `AsynchronousInterface/PrintValues`).
  ::  The port refused it in `+resolve-targets`, and refused BEFORE
  ::  `+check-assumes`, so it did not check the assumptions either -- the one
  ::  thing such a module is for. An INIT without a NEXT (or the reverse) is
  ::  still the config error `+resolve-targets` reports; only the total absence
  ::  of a behaviour spec takes this path
  =/  nospec  &(?=(~ init.ca) ?=(~ next.ca) ?=(~ spec.ca))
  ::  resolve Init/Next (and fairness) from INIT/NEXT keys or a SPECIFICATION
  =/  rt=(each [init=sem:sem-lib next=sem:sem-lib fair=(list sem:sem-lib) nname=(unit @t) warn=(list @t)] @t)
    ?:  nospec  [%& [%nullodn ~] [%nullodn ~] ~ ~ ~]
    (resolve-targets [init.ca next.ca spec.ca] defs (var-order tree))
  ?:  ?=(%| -.rt)  [%| p.rt]
  =/  isb   init.p.rt
  ::  R3.0a/R3.2: nothing to solve -- either the config declares no behaviour
  ::  spec at all, or its SPECIFICATION has no initial predicate. `%nullodn`
  ::  is the marker for both, so the run has zero initial states and the search
  ::  never expands
  =/  noinit  ?=(%nullodn -.isb)
  =/  nsb   next.p.rt
  =/  fair  fair.p.rt
  =/  consts
    %-  ~(uni by (override-consts (const-map cfg) overrides.ca))
    (mod-const-vals defs mod-constants.ca)
  =/  nb  ?~(nname.p.rt ~ (body-of-def tree u.nname.p.rt))
  ::  R2.7.5: SYMMETRY with a temporal PROPERTY now WARNS AND CONTINUES, as
  ::  tlc2 does (EC 2279), instead of type-rejecting.
  ::
  ::  Unit 8.7.2 refused it and recorded an engine blocker — "the port cannot
  ::  yet run liveness on that spec class (model-value \E init/actions error
  ::  'variable unassigned')". **Re-measured here, that blocker is STALE.** It
  ::  predates R1.5.1's solver work and R2.4.6's `+get-actions` rebuild, which
  ::  are exactly the two constructs it names (`x \in S` as a nondeterministic
  ::  assignment, a constant-level `\E` in action position). With the guard
  ::  relaxed the port runs the `symmetry-live` fixture to `Model checking
  ::  completed. No error has been found.` over 4 generated / 1 distinct /
  ::  depth 1 — the pin's verdict and the pin's counts exactly. Only the
  ::  warning LINE was missing.
  ::
  ::  Keyed on the SYMMETRY declaration, as tlc2's warning is: `Permutations(S)`
  ::  over model values yields no perms, so the declaration is what it can see.
  ::
  ::  It is NOT keyed on `pp` alone. A `[]P` box-state PROPERTY is folded into
  ::  the INVARIANT vector by `processConfigProps` and never reaches the
  ::  liveness checker, so tlc2 prints no warning for it -- measured on
  ::  `Prop == []Inv` under `SYMMETRY Perms`: no warning, `ok`, 1 distinct. The
  ::  guard therefore asks for a GENUINE temporal property, the same test
  ::  `+check` uses to route between the safety and liveness engines
  ::  R4.2n: "genuine" is the temporal bin being non-empty, now that a
  ::  property is binned part by part
  =/  gbins  (bin-properties properties.ca defs)
  =/  genuine-temporal  ?=(^ temps.gbins)
  =/  symwarn=(list @t)
    ?.  &(?=(^ symmetry.ca) genuine-temporal)  ~
    :_  ~
    %^    cat  3
        'Warning: Declaring symmetry during liveness checking is dangerous. '
      %^  cat  3
        'It might cause TLC to miss violations of the stated liveness properties. '
      'Please check liveness without symmetry defined.'
  ::  ALIAS is LIVE as of R2.3.2 -- resolved below and carried on `sctx`, and
  ::  applied by `+render-trace`, by the EC 2107/2108 initial-state branches,
  ::  and so by every safety path. Its own liveness refusal sits at the genuine
  ::  temporal branch of `+check` rather than here, because a `[]P` box-state
  ::  PROPERTY runs on the SAFETY path and does render the alias correctly --
  ::  a `?=(^ pp)` guard here would over-refuse it. VIEW is LIVE as of
  ::  R2.3.1 -- resolved below and carried on `sctx` -- except alongside a
  ::  temporal PROPERTY, where the liveness module recomputes plain state
  ::  fingerprints (`+succ-fps`, `+trace-graph`) that would not match a
  ::  view-keyed graph. That is the same latent mismatch symmetry+liveness is
  ::  refused for; it is narrowed, not ignored
  ::  R4.2e: no longer refused -- the liveness product keys a state by the
  ::  same identity the graph build used (`+live-key:lv`, the env's `idk`)
  ::  R4.2aa: the drawing constant definitions, once, in tlc2's order; the
  ::  ASSUMEs and then the initial-state solve continue the same stream
  =/  rs00=rst:ne  empty-rst:ne
  =.  es.rs00  (scramble:rng seed)
  =/  sd=[vals=(map @t value) rs=rst:ne]
    ?.  (may-draw defs assumes.u.mo)  [consts rs00]
    %:  startup-draws:ne
      (startup-order u.mo overrides.ca defs)
      defs  consts  vars  rs00
    ==
  =.  consts  vals.sd
  =/  irs0=rst:ne
    ?.  (may-draw defs assumes.u.mo)  rs.sd
    (assume-rs assumes.u.mo (make-env:ne defs consts vars) rs.sd)
  =/  pr  (symmetry-perms defs consts vars symmetry.ca)
  ?:  ?=(%| -.pr)  [%| p.pr]
  =/  perms  p.pr
  =/  rs0=rst:ne  empty-rst:ne
  =/  irc=sout:ne
    ::  no behaviour spec: no initial-state solve to run, and the `%nullodn`
    ::  bodies above are never evaluated because the search has nothing to
    ::  expand from. R3.0a
    ?:  noinit  [[%& ~] irs0]
    %^  init-states-rs:ne  isb  (make-env:ne defs consts vars)
    irs0
  =/  ir   -.irc
  ?:  ?=(%| -.ir)  [%| msg.p.ir]
  =/  invs   (resolve-invs defs invariants.ca)
  =/  cons   (resolve-bodies defs constraints.ca)
  =/  acons  (resolve-bodies defs action-constraints.ca)
  =/  cnames  (resolve-names defs constraints.ca)
  =/  anames  (resolve-names defs action-constraints.ca)
  =/  ddl    !=(%false deadlock.ca)
  ::  build the normalized temporal decomposition for a liveness run (unit
  ::  8.1.4): the production setup now derives the oos via temporal.hoon rather
  ::  than the CST — the verdict still comes from the first-increment recognizer
  ::  (unit 8.5 retires that). Empty for a pure-safety run; a non-boolean
  ::  constant leaf is a typed rejection (unit 8.1.5).
  ::  R1.8.1.1: only a genuinely TEMPORAL property goes to the liveness
  ::  normalizer. A box-invariant, an implied init (level 1) or an implied
  ::  action (`[][A]_v`) is checked elsewhere, and feeding one of the latter two
  ::  to `normalize:tp` bails — which is why a `[][A]_v` PROPERTY crashed here
  ::  before the routing existed
  =/  ppb=(unit sem:sem-lib)
    ?~  properties.ca  ~
    (sem-body defs i.properties.ca)
  =/  non-temporal=?
    ?~  ppb  |
    ?|  (lte (sem-lvl:sem-lib u.ppb) 1)
        ?=(^ (implied-action-inner u.ppb))
    ==
  ::  R2.7.12: `Tool.getImpliedTemporals()` -- the PROPERTIES that reach the
  ::  liveness engine, which is what post-hoc attribution asks about. The three
  ::  exclusions are `processConfigProps`': a `[]P` box-state goes to the
  ::  INVARIANT vector, a level<=1 predicate is an IMPLIED INIT and a `[][A]_v`
  ::  an IMPLIED ACTION. Same three tests `+check`'s routing uses, applied to
  ::  EVERY property rather than to the first
  ::  R2.7.15a: EVERY property binned on its own shape, so the routing is
  ::  order-independent. `+implied-temporals` remains the liveness bin's own
  ::  accessor (the job kernel and R2.7.12's attribution both call it)
  =/  bins  (bin-properties properties.ca defs)
  =/  itemporals  temps.bins
  =/  or=(each (list oos:tp) aerr:tp)
    ::  R2.7.15b: from the TEMPORAL BIN, not the head of the property list.
    ::  This used to answer `~` whenever the FIRST property was not genuinely
    ::  temporal, so a spec declaring an implied action first and a temporal
    ::  property second built no `oss` at all -- and the liveness engine had
    ::  nothing to report even once R2.7.15a routed the run to it
    ?~  temps.bins  [%& ~]
    %:  oss-of
      (turn temps.bins |=([* b=sem:sem-lib] b))
      modn  fair  (make-env:ne defs consts vars)
    ==
  ?:  ?=(%| -.or)  [%| msg.p.or]
  =/  sloc=sspan:sem-lib
    ?~  spec.ca  ~
    =/  d  (~(get by defs) u.spec.ca)
    ?~(d ~ at.u.d)
  :-  %&
  =/  aname=@t  ?~(nname.p.rt 'Action' u.nname.p.rt)
  ::  the VIEW body, resolved like any other config target (R2.3.1)
  =/  vwb=(unit sem:sem-lib)  ?~(view.ca ~ (sem-body defs u.view.ca))
  ::  the ALIAS body, resolved like any other config target (R2.3.2)
  =/  alb=(unit sem:sem-lib)  ?~(alias.ca ~ (sem-body defs u.alias.ca))
  :*  p.ir  defs  consts  vars  order  perms  assumes.u.mo  nsb
      invs  cons  acons  cnames  anames  ddl  pp  itemporals
      binvs.bins  iinits.bins  iacts.bins  properties.ca
      fair  spec.ca  sloc  tree
      vwb  alb  aname
      ?~(nb '' (next-span-label aname u.nb modn))
      ::  `-view` is a REQUEST option; `check:check` takes none, so the console
      ::  path never sets it. The kernel supplies it via `+check-opts` (R2.4.3)
      `(unit sem:sem-lib)`~
      ::  R2.7.5: the 2279 warning rides the same `swarn` channel R2.3.5's
      ::  EC 2145 subscript warning uses -- printed BEFORE the verdict
      (weld symwarn warn.p.rt)
      ?~(init.ca '' u.init.ca)
      irej.+.irc
      postconditions.ca
      ::  resolved here, where `defs` is in scope; the config validator has
      ::  already rejected an unresolvable or temporal-level name
      %+  murn  possible.ca
      |=  nm=@t
      ^-  (unit [@t sem:sem-lib @ud])
      =/  d  (~(get by defs) nm)
      ?~  d  ~
      ?~  body.u.d  ~
      `[nm u.body.u.d lvl.u.d]
      +.irc
      es.rs.sd
      (flop out.irs0)
      p.or
  ==
::
++  build-live-oss
  ::  the normalized OrderOfSolutions for a spec's PROPERTY list under its
  ::  fairness (unit 8.1); shared by the production setup and the differential.
  ::  A constant leaf is evaluated under the constant env, so a non-boolean is a
  ::  typed rejection (aerr).
  |=  $:  ca=cfg-ast:config
          defs=(map @t sem-def:sem-lib)
          consts=(map @t value)
          vars=(set @t)
          fair=(list sem:sem-lib)
          modn=@t
      ==
  ^-  (each (list oos:tp) aerr:tp)
  =/  pbods=(list sem:sem-lib)
    =/  ps  properties.ca
    |-  ^-  (list sem:sem-lib)
    ?~  ps  ~
    =/  b  (sem-body defs i.ps)
    ?~  b  $(ps t.ps)
    [u.b $(ps t.ps)]
  (oss-of pbods modn fair (make-env:ne defs consts vars))
::
++  oss-of
  ::  normalize temporal property bodies + fairness conjuncts into the
  ::  OrderOfSolution list (exposes temporal.normalize for the job kernel's
  ::  %liveness setup and the differential's build-live-oss)
  |=  [pbods=(list sem:sem-lib) modn=@t fair=(list sem:sem-lib) env=eenv:ne]
  ^-  (each (list oos:tp) aerr:tp)
  (normalize:tp pbods modn fair env)
::
++  apply-overrides
  ::  R4.2m: the config's `lhs <- rhs` substitutions, which were validated
  ::  (EC 2223-2226) and then IGNORED: `Nat <- NatOverride`,
  ::  `Seq <- LimitedSeq`, `Acceptor <- MCAcceptor` (123 in the Examples
  ::  corpus). tlc2 makes the name `lhs` denote `rhs`'s definition
  ::  (`SpecProcessor`'s override of the OpDefNode, and of a CONSTANT's
  ::  value -- `processConstantDefns` then evaluates a constant-level one
  ::  once). Here `lhs` is rebound to `rhs`'s definition in the operator
  ::  map; a CONSTANT reference with no value reads it (`+apply-const:ne`),
  ::  and R4.P3's `+with-cdefs` evaluates it once when it is constant-level.
  ::  `lhs <-[M] rhs` overrides a definition `lhs` that module `M` supplies
  |=  $:  defs=(map @t sem-def:sem-lib)
          ov=(map @t @t)
          mov=(map @t (map @t @t))
      ==
  ^-  (map @t sem-def:sem-lib)
  =/  os  ~(tap by ov)
  =/  out  defs
  =.  out
    |-  ^-  (map @t sem-def:sem-lib)
    ?~  os  out
    =/  d  (~(get by defs) q.i.os)
    ?~  d  $(os t.os)
    $(os t.os, out (~(put by out) p.i.os u.d))
  =/  ms  ~(tap by mov)
  |-  ^-  (map @t sem-def:sem-lib)
  ?~  ms  out
  =/  ps  ~(tap by q.i.ms)
  =.  out
    |-  ^-  (map @t sem-def:sem-lib)
    ?~  ps  out
    =/  d  (~(get by defs) q.i.ps)
    ?~  d  $(ps t.ps)
    ::  R4.2 (MCPaxos): EVERY entry that is `M`'s `lhs`, under whatever
    ::  instance qualification imported it (`V!Ballot` from `V == INSTANCE
    ::  Voting`) -- tlc2 overrides the OpDefNode itself, which each
    ::  instantiation shares
    =/  named=(list [k=@t v=sem-def:sem-lib])
      (skim ~(tap by out) |=([k=@t *] =(p.i.ps (bnm:ne k))))
    =/  hits=(list @t)
      %+  murn  named
      |=  [k=@t v=sem-def:sem-lib]
      ^-  (unit @t)
      ?.  =(p.i.ms origin.v)  ~
      `k
    ::  R4.2 (LeastCircularSubstring): an `lhs` that `M` INHERITS
    ::  (`Nat <- [ZSequences]ZSeqNat`, Nat from Naturals): tlc2 sets the
    ::  override on that one definition's body (`opDefs[j].getBody()
    ::  .setToolObject`), a node every module shares, so every reference to
    ::  it takes `rhs`. Taken when `lhs` has a single defining module
    =?  hits  ?&  ?=(~ hits)
                  ?=(^ named)
                  (levy t.named |=([* v=sem-def:sem-lib] =(origin.v origin.v.i.named)))
              ==
      (turn named |=([k=@t *] k))
    =.  out
      %+  roll  hits
      |=  [k=@t o=_out]
      (~(put by o) k u.d)
    $(ps t.ps)
  $(ms t.ms)
::
++  override-consts
  ::  R4.2v: `lhs <- rhs` where `rhs` is itself a CONSTANT with a value
  ::  (`Leader <- L`, `L = L`): `lhs` takes that value
  |=  [consts=(map @t value) ov=(map @t @t)]
  ^-  (map @t value)
  =/  os  ~(tap by ov)
  =/  out  consts
  |-  ^-  (map @t value)
  ?~  os  out
  =/  v  (~(get by consts) q.i.os)
  ?~  v  $(os t.os)
  $(os t.os, out (~(put by out) p.i.os u.v))
::
++  consts-of
  ::  config constant assignments as an evaluation binding map (WU6.9 task 1).
  ::  An arity-0 assignment binds a value directly; `F(a,..) = v` assignments (a
  ::  constant OPERATOR, tlc2's OpRcdValue) are grouped by name into a function
  ::  value applied at the argument (arity 1) or the argument tuple (arity n) —
  ::  see +apply-const in node-eval (R1.5.3).
  |=  cs=(list cfg-const:config)
  ^-  (map @t value)
  =/  built
    =|  vals=(map @t value)
    =|  ops=(map @t (list vpair:vl))
    |-  ^-  [v=(map @t value) o=(map @t (list vpair:vl))]
    ?~  cs  [vals ops]
    ?~  args.i.cs
      $(cs t.cs, vals (~(put by vals) lhs.i.cs val.i.cs))
    =/  dp=value  ?:(=(1 (lent args.i.cs)) i.args.i.cs [%seq args.i.cs])
    =/  ex  (~(gut by ops) lhs.i.cs *(list vpair:vl))
    $(cs t.cs, ops (~(put by ops) lhs.i.cs (snoc ex [dp val.i.cs])))
  =/  vals  v.built
  =/  os  ~(tap by o.built)
  |-  ^-  (map @t value)
  ?~  os  vals
  $(os t.os, vals (~(put by vals) p.i.os [%fcn q.i.os]))
::
++  const-map
  |=  cfg=@t
  ^-  (map @t value)
  =/  pr  (parse-cfg:config cfg)
  ?:(?=(%| -.pr) ~ (consts-of constants.p.pr))
::
++  mod-const-vals
  ::  R4.2u: module-scoped value assignments (`NoBlock = [Nano]NoBlockVal`),
  ::  parsed into `mod-constants` and never applied. Each definition module
  ::  `M` supplies under that name -- `NoBlock` when EXTENDed, `N!NoBlock`
  ::  through `N == INSTANCE Nano` (an instance member keeps its module as
  ::  origin) -- takes the value, as a root `NoBlock = v` does
  |=  [defs=(map @t sem-def:sem-lib) mc=(map @t (list cfg-const:config))]
  ^-  (map @t value)
  =/  ds  ~(tap by defs)
  =/  ms  ~(tap by mc)
  =|  out=(map @t value)
  |-  ^-  (map @t value)
  ?~  ms  out
  =/  vs  (consts-of q.i.ms)
  =/  hits
    %+  murn  ds
    |=  [k=@t d=sem-def:sem-lib]
    ^-  (unit [@t value])
    ?.  =(p.i.ms origin.d)  ~
    =/  v  (~(get by vs) (bnm:ne k))
    ?~(v ~ `[k u.v])
  $(ms t.ms, out (~(uni by out) (malt hits)))
::
++  kind-name
  ::  the tlc2 value class a value corresponds to, the stable kind
  ::  discriminator the oracle projection prints (unit 6C.8)
  |=  x=value
  ^-  tape
  ?-  -.x
    %bool   "BoolValue"
    %int    "IntValue"
    %str    "StringValue"
    %model  "ModelValue"
    %intv   "IntervalValue"
    ::  R2.7.2: the class a set was BUILT as, which the port used to lose when
    ::  a lazy construction was forced. `%set-enum` is an ordinary set literal
    %set
      ::  R2.7.16 added the other six. R2.7.2 emitted only three because only
      ::  three appeared in the goldens it had -- every other construction
      ::  forced to a plain SetEnumValue there, which was true of that corpus
      ::  and not of the language (`ev-lazyclass`, R2.7.13)
      ?+  cls.x  "SetEnumValue"
        %subset    "SubsetValue"
        %k-subset  "KSubsetValue"
        %prod      "SetOfTuplesValue"
        %set-pred  "SetPredValue"
        %set-cup   "SetCupValue"
        %set-cap   "SetCapValue"
        %set-diff  "SetDiffValue"
        %union     "UnionValue"
        %fcns      "SetOfFcnsValue"
        %rcds      "SetOfRcdsValue"
      ==
    %seq    "TupleValue"
    %rec    "RecordValue"
    %fcn    "FcnRcdValue"
  ==
::
++  kind-of
  ::  the tlc2 value class a definition's result corresponds to. Almost always
  ::  a property of the VALUE, but a recursive function definition is the one
  ::  case where it is a property of the EXPRESSION: tlc2 keeps a
  ::  $RecursiveFcnSpec as a lazy FcnLambdaValue, while the identical function
  ::  written as a plain constructor normalizes to a FcnRcdValue. Measured at
  ::  the pin: `R1[n \in 1..3] == ...` is FcnLambdaValue and renders <<1, 2, 6>>,
  ::  `NR1 == [n \in 1..3 |-> n]` is FcnRcdValue and renders <<1, 2, 3>> — same
  ::  rendering, different class — so the class cannot be read off the value
  ::  R2.7.16: and the FUNCTION class is the second such case, for the same
  ::  reason. `Tool.java`'s function constructor (OPCODE_fc / nrfs / rfs)
  ::  evaluates every DOMAIN and sets `isFcnRcd` iff every one of them is
  ::  `Reducible`; only then does it normalize to a FcnRcdValue. The port's
  ::  `%fcn` keeps its pairs and not its domains' classes, so the decision is
  ::  read off the EXPRESSION here rather than off the value -- no `vfcn`
  ::  mold change, which is the same shape the `$RecursiveFcnSpec` case
  ::  already had. `e` is the env the definition was evaluated under; the
  ::  domains are re-evaluated in it, which is affordable because this arm is
  ::  reached only by `+project-defs` (a diagnostic projection), never by the
  ::  search. Every domain is evaluated in the SAME context in tlc2
  ::  (`dvals[i] = this.eval(domains[i], c, ...)`), so re-evaluating each one
  ::  against `e` is its rule, not an approximation
  |=  [b=sem:sem-lib x=value e=eenv:ne]
  ^-  tape
  ?:  ?&  ?=(%apply -.b)
          =('$RecursiveFcnSpec' name.op.b)
          ?=(?(%fcn %seq) -.x)
      ==
    ::  a RECURSIVE spec forces `isFcnRcd = false` outright, whatever its
    ::  domains are, so this test stays FIRST
    "FcnLambdaValue"
  ?.  ?&(?=(%fcn -.x) (lambda-form:ne b))  (kind-name x)
  ?:((fcn-doms-reducible b e) "FcnRcdValue" "FcnLambdaValue")
::
++  fcn-doms-reducible
  ::  `isFcnRcd`: EVERY domain of a function constructor is `Reducible`.
  ::  Measured at the pin -- `[i \in 1..2, j \in {1, 2} |-> i + j]` is a
  ::  FcnRcdValue and `[i \in 1..2, j \in ((1..2) \X (1..2)) |-> i]` a
  ::  FcnLambdaValue, so it is every domain and not the first. An EMPTY
  ::  domain is Reducible like any other (`[x \in {} |-> 1]` is FcnRcdValue)
  ::  A domain that fails to evaluate is not read as Reducible: the value it
  ::  is being asked about does not exist, and the caller has already
  ::  reported the failure through its own channel
  |=  [b=sem:sem-lib e=eenv:ne]
  ^-  ?
  ?.  ?=(%apply -.b)  |
  ::  an EXPLICIT loop, not `levy`: the binder carries a `sem`, and a wet gate
  ::  over it nest-fails with the two `sem` identities the trace prints
  ::  (`rng=#3` against `rng=^#3.#sem`) -- the zuse-408 trap `+finish-bfs`
  ::  records for `turn` over the recursive `state` mold, same cause
  =/  bs  (flatten-bound:ne bound.b)
  ::  no binders at all is not a constructor
  ?:  =(~ bs)  |
  |-  ^-  ?
  ?~  bs  &
  =/  r  (eval:ne rng.i.bs e)
  ?.  ?=(%& -.r)  |
  ?.  (reducible:vl p.r)  |
  $(bs t.bs)
::
++  project-defs
  ::  every arity-0 definition of a module, sorted by name and evaluated once
  ::  under the config's constant assignments, in the oracle's projection
  ::  form: "<name> <kind> <canonical value>" or "<name> ! EC<code> <message>".
  ::  Newlines in a diagnostic become spaces, exactly as ModuleOpDump's
  ::  projection collapses them. `skip` names the definitions this port
  ::  deliberately answers differently (unit 6C.8's differential comparator);
  ::  the graph is generated ONCE for the whole case
  |=  [spec=@t cfg=@t skip=(list @t)]
  ^-  (list tape)
  (project-defs-with spec cfg ~ skip)
::
++  project-defs-with
  ::  +project-defs over a module set: `mods` are the other modules the root
  ::  `A` reaches (R4.2b: the CommunityModules sources the pin loads from its
  ::  jar)
  |=  [spec=@t cfg=@t mods=(list [@t @t]) skip=(list @t)]
  ^-  (list tape)
  =/  mo  (generate:sem-lib 'A' (malt [['A' spec] mods]))
  ?~  mo  ~["! no semantic graph"]
  =/  defs  (defmap-of:ne u.mo)
  =/  e  (make-env:ne defs (const-map cfg) (vars-of:ne u.mo))
  =/  skipped  (silt skip)
  =/  names
    %+  sort
      %+  murn  defs.u.mo
      |=  d=sem-def:sem-lib
      ^-  (unit @t)
      ?:  |(!=(0 arity.d) (~(has in skipped) name.d))  ~
      ?~(body.d ~ `name.d)
    aor
  %+  turn  names
  |=  nm=@t
  ^-  tape
  =/  d  (~(get by defs) nm)
  ?~  d  :(weld (trip nm) " ! no definition")
  ?~  body.u.d  :(weld (trip nm) " ! no body")
  =/  r  (eval:ne u.body.u.d e)
  ?:  ?=(%& -.r)
    :(weld (trip nm) " " (kind-of u.body.u.d p.r e) " " (render:vl p.r))
  ::  code 0 means "no TLC error code", which is what a TLCRuntimeException
  ::  carries; the oracle projection prints no `EC…` for those, so neither do
  ::  we (R1.4.5)
  ?:  =(0 code.p.r)
    :(weld (trip nm) " ! " (flat-msg msg.p.r))
  ;:  weld
    (trip nm)  " ! EC"  (a-co:co code.p.r)  " "  (flat-msg msg.p.r)
  ==
::
++  flat-msg
  ::  a diagnostic on one line, as the oracle projection prints it
  |=  m=@t
  ^-  tape
  (turn (trip m) |=(c=@tD ?:(=(c 10) ' ' c)))
::
++  check-assumes
  ::  TLC Tool.checkAssumptions, run before the search: every module ASSUME
  ::  must evaluate to TRUE under the constant environment. A FALSE assumption
  ::  is EC 2104 (assumption-false); a non-boolean value or evaluation error is
  ::  EC 2105 (assumption-error). ~ when all assumptions hold.
  ::  An AXIOM-marked assumption is SKIPPED, exactly as tlc2 does
  ::  (`(!isAxiom[i]) && !isValidAssumption(...)`, Tool.java:3651): SANY sets
  ::  isAxiom only when the source keyword image is literally `AXIOM`
  ::  (AssumeNode.java:65), so `ASSUME`/`ASSUMPTION` are still checked and a
  ::  false AXIOM does not fail the run. R1.5.13
  ::
  ::  The messages are tlc2's MP templates with the assumption's LOCATION as
  ::  `%1%` (R4.2j: they had been `An assumption is false.` and `Evaluating an
  ::  assumption failed: ...`, which no test compared against the pin).
  ::  `at` is that location, which the job kernel reports as the violated
  ::  assumption's name. The module is the root's: `sem-thm` carries no
  ::  origin, so an ASSUME imported through EXTENDS is located in the root
  ::
  ::  R4.2aa: `es` is the RNG state the startup definitions left
  ::  (`+startup-draws:ne`); an assumption that draws continues it
  |=  [asmz=(list sem-thm:sem-lib) e=eenv:ne modn=@t es=@]
  ^-  (unit [ec=@ud msg=@t at=@t])
  ?~  asmz  ~
  ?:  axiom.i.asmz  $(asmz t.asmz)
  ?~  body.i.asmz  $(asmz t.asmz)
  ::  the BODY's span, not the declaration's: tlc2 locates the expression
  ::  (`col 8` past `ASSUME `), measured
  =/  loc  (locn-tape (sem-at u.body.i.asmz) modn)
  =/  [r=bres:ne rs=rst:ne]  (eval-bool-rs:ne u.body.i.asmz e `rst:ne`[~ ~ es 0 ~ ~ 0 | 0])
  ?:  ?=(%| -.r)
    `[2.105 (rap 3 ~['Evaluating assumption ' loc ' failed.\0a' msg.p.r]) loc]
  ?.  p.r  `[2.104 (rap 3 ~['Assumption ' loc ' is false.']) loc]
  $(asmz t.asmz, es es.rs)
::
++  out-stats
  ::  the four counters off an outcome. Each arm carries them, but `%limited`
  ::  leads with `what`, so the faces do not line up across the union and a
  ::  bare `depth.out` cannot resolve -- hence the explicit dispatch
  |=  o=outcome
  ^-  [gen=@ud distinct=@ud queued=@ud depth=@ud]
  ?-  -.o
    %ok        [gen.o distinct.o queued.o depth.o]
    %inv       [gen.o distinct.o queued.o depth.o]
    %action    [gen.o distinct.o queued.o depth.o]
    %deadlock  [gen.o distinct.o queued.o depth.o]
    %limited   [gen.o distinct.o queued.o depth.o]
    %error     [0 0 0 0]
  ==
::
++  cli-postconditions
  ::  R2.7.14b: `-postCondition mod!op` as postcondition NAMES, to be appended
  ::  to the config's own. tlc2 puts both in one `POST_CONDITIONS` list and
  ::  `Spec.getPostConditionSpecs` resolves them together, so this is a second
  ::  ENTRY POINT into R2.7.7.3's machinery, not a second mechanism -- which is
  ::  also why the CLI ones run AFTER the `.cfg` ones, in the order given.
  ::
  ::  The module half is checked against the definition's ORIGIN, the same
  ::  field `+eval-user` keys its StandardModule override lookup on. A name
  ::  that resolves in a DIFFERENT module is passed through unchanged so
  ::  `+post-cond-lines` reports it exactly as it reports an unknown one --
  ::  tlc2's unexpected-exception wrapper, measured by `cfg-post-undef`. There
  ::  is no separate diagnostic for "right name, wrong module" at the pin.
  ::  A name that resolves in a DIFFERENT module is REFUSED here rather than
  ::  evaluated. The port's `defs` is keyed by bare name, so evaluating it
  ::  would silently honour `Other!Post` by running the root module's `Post` --
  ::  accepting an option and doing something else, which is the one thing R2.1
  ::  forbids. tlc2 would not find it at all; a refusal naming the mismatch is
  ::  the port's analogue, and unlike a guessed diagnostic it is reproducible.
  |=  [xs=(list [module=@t op=@t]) defs=(map @t sem-def:sem-lib)]
  ^-  (each (list @t) @t)
  ?~  xs  [%& ~]
  =/  x  i.xs
  =/  d  (~(get by defs) op.x)
  ?:  ?&  ?=(^ d)
          !=(origin.u.d module.x)
      ==
    :-  %|
    %-  crip
    ;:  weld
      "unsupported: -postCondition "  (trip module.x)  "!"  (trip op.x)
      " names a module other than "  (trip origin.u.d)  ", where "
      (trip op.x)  " is defined"
    ==
  =/  r  $(xs t.xs)
  ?:(?=(%| -.r) r [%& [op.x p.r]])
::
++  post-cond-lines
  ::  POSTCONDITION, evaluated AFTER state-space exploration (R2.7.7.3), the
  ::  way `Tool.checkPostConditionWithContext` does. Measured at the pin:
  ::
  ::    - it runs on a CLEAN run and after a VIOLATION alike, and its line
  ::      sits between the safety trace and the counts -- the slot R2.7.5's
  ::      post-error temporal block already uses;
  ::    - on a clean run whose postcondition is FALSE, `Model checking
  ::      completed. No error has been found.` is NOT printed: the error
  ::      replaces it (`MP.printError` is the run's outcome);
  ::    - the NAMES resolve here, not at spec processing -- the pin prints the
  ::      state counts first and only then fails on an unresolvable one, which
  ::      is why R2.7.7.2 left this clause to this unit.
  ::
  ::  EC 2404 `Postcondition %1% at %2% is false.`, EC 2405 for an evaluation
  ::  failure, where %2% is the BODY's location (tlc2 passes
  ::  `pc.getPred().toString()`, an ExprNode, whose toString is its location).
  ::  `e` must already carry the run statistics -- a postcondition typically
  ::  reads them through `TLCGet`
  ::  R2.7.7.4a: the CARRIER matters here. A postcondition reads what the run
  ::  wrote -- that is the whole of `_Possible`'s design, and measured, a
  ::  postcondition reading `TLCGet("s:c")` after a `TLCSet("s:c", ..)` in the
  ::  next-state relation sees the count. Evaluating with a fresh `rst` answers
  ::  `TLCGet(s:c) was undefined.` instead, so the run's FINAL carrier is
  ::  passed in
  |=  $:  pcs=(list @t)  defs=(map @t sem-def:sem-lib)  e=eenv:ne  modn=@t
          rs=rst:ne
          ::  R2.7.7.4b: `_POSSIBLE` generates one `_CheckName(P)` POSTCONDITION
          ::  per predicate. They run after the config's own, and each reports
          ::  the USER's predicate name and BODY location, not the generated
          ::  operator's -- the pin wraps them in a `PossibleAction` for exactly
          ::  that. `_CheckName` fails when the count is 0 OR the name is absent
          poss=(list [name=@t body=sem:sem-lib lvl=@ud])
      ==
  ^-  wain
  ?~  pcs  (possible-lines poss rs modn)
  =/  d  (~(get by defs) i.pcs)
  ::  an unresolvable name is the pin's `getPostConditionSpecs` failure, and it
  ::  arrives as an UNEXPECTED EXCEPTION rather than a typed diagnostic --
  ::  `Assert.fail` throws where TLC has no handler for it (measured:
  ::  `cfg-post-undef`)
  ?~  d  (unexpected-exception (v-notdef:config 'post condition' i.pcs))
  ?~  body.u.d  (unexpected-exception (v-notdef:config 'post condition' i.pcs))
  =/  loc  (loc-str:config modn (sem-span:config u.body.u.d))
  =/  r  (pred-bool-rs:ne u.body.u.d ~ ~ e rs)
  ?:  ?=(%| -.-.r)
    (err-lines (ec-body:diag 2.405 ~[i.pcs loc msg.p.-.r]))
  ?.  p.-.r
    (err-lines (ec-body:diag 2.404 ~[i.pcs loc]))
  ::  a postcondition's own writes are visible to the NEXT one, as they are to
  ::  a later conjunct of one (R2.7.4.3's measured rule)
  $(pcs t.pcs, rs +.r)
::
++  possible-lines
  ::  the generated `_Possible!_CheckName` postconditions (R2.7.7.4b): a
  ::  `_POSSIBLE` predicate never witnessed is EC 2404, exactly as a false
  ::  config postcondition is.
  ::
  ::  The pin ALSO prints the counts record first (`_CheckName`'s body is
  ::  `PrintT(counts) /\ FALSE`). This engine has no Print channel -- the
  ::  standing `tlc-module-tlc` difference -- so that line is absent here and
  ::  the case is an approved difference rather than byte-exact
  |=  [poss=(list [name=@t body=sem:sem-lib lvl=@ud]) rs=rst:ne modn=@t]
  ^-  wain
  ?~  poss  ~
  =/  rec  (~(gut by named.rs) poss-key `value`[%fcn ~])
  =/  pairs=(list vpair:vl)  ?:(?=(%fcn -.rec) p.rec ~)
  =/  f  (skim pairs |=(v=vpair:vl =(d.v `value`[%str name.i.poss])))
  =/  n=@ud  ?~(f 0 ?:(?=(%int -.r.i.f) (abs:si p.r.i.f) 0))
  ?:  =(0 n)
    %-  err-lines
    %+  ec-body:diag  2.404
    ~[name.i.poss (loc-str:config modn (sem-span:config body.i.poss))]
  $(poss t.poss)
::
++  unexpected-exception
  ::  tlc2's wrapper for a throw it has no handler for (`TLC.process`'s catch,
  ::  EC.GENERAL): four fixed lines, the exception's class, then the message.
  ::  Reproduced rather than replaced by a typed diagnostic because that is
  ::  what a caller comparing output sees -- and because a postcondition name
  ::  that does not resolve reaches the pin through exactly this path
  |=  msg=@t
  ^-  wain
  ::  only the FIRST line carries `Error: `; the message follows on its own
  ::  lines, the first of them opening with `: ` -- so this cannot go through
  ::  `+err-lines`, which prefixes every rendering it makes
  =/  t=tape  (trip (cat 3 ': ' msg))
  =|  cur=tape
  =|  out=wain
  =/  tail=wain
    |-  ^-  wain
    ?~  t  (flop [(crip (flop cur)) out])
    ?:  =(10 i.t)
      $(t t.t, cur ~, out [(crip (flop cur)) out])
    $(t t.t, cur [i.t cur])
  %+  weld
    :~  'Error: TLC threw an unexpected exception.'
        'This was probably caused by an error in the spec or model.'
        'See the User Output or TLC Console for clues to what happened.'
        'The exception was a java.lang.RuntimeException'
    ==
  tail
::
++  live-struct
  ::  the temporal-normalization count projection (unit 8.1) for a spec+cfg,
  ::  matching LivenessStruct's OOS/promises/checkState/checkAction/pems counts
  ::  (the TABLEAU node count is unit 8.2). Resolves the PROPERTY bodies and the
  ::  SPECIFICATION fairness conjuncts, then runs temporal.hoon's normalize.
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  (render-counts:tp oss.p.sc)
::
++  live-tabs
  ::  the TABLEAU block (R1.6.2: the graph, not just its node count) for each
  ::  OrderOfSolution, in order (hand-rolled; a wet turn over the oos list
  ::  fuse-loops the recursive live-expr it carries)
  |=  [oss=(list oos:tp) modn=@t]
  ^-  (list wain)
  ?~  oss  ~
  [(render-tableau:tb modn tf.i.oss) $(oss t.oss)]
::
++  live-struct-full
  ::  the full structural projection (unit 8.2): the LivenessStruct output
  ::  including the TABLEAU node count, the OrderOfSolution.toString rendering,
  ::  and the counts. Reads the oos the PRODUCTION search context builds (unit
  ::  8.1.4), so this differential exercises the decomposition the liveness path
  ::  carries and the tableau built from it.
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  =/  modn  (module-name-of tree.p.sc)
  (render-struct:tp oss.p.sc modn (live-tabs oss.p.sc modn))
::
++  states-of
  ::  the reachable graph's fingerprint -> state map (drops depth/predecessor)
  |=  seen=(map @t visit)
  ^-  (map @t state)
  (~(run by seen) |=(w=visit st.w))
::
++  product-counts
  ::  the behavior-graph product node/init counts (unit 8.3) for each
  ::  OrderOfSolution: build the reachable graph once, then pair it with each
  ::  oos tableau via lib/liveness
  |=  c=sctx
  ^-  (list [nodes=@ud inits=@ud])
  =/  o=bfs-opts  [nsb.c ~ cons.c acons.c ~ vars.c order.c perms.c defs.c consts.c | 0 0 view.c 0 | ~ *cov-opts 0 ~ | ~]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
  =/  oss  oss.c
  |-  ^-  (list [nodes=@ud inits=@ud])
  ?~  oss  ~
  :-  (build-product:lv i.oss states inits.g nsb.c env order.c)
  $(oss t.oss)
::
++  render-product
  ::  the PRODUCT projection (unit 8.3, extended R1.6.3): per OrderOfSolution
  ::  the product node and initial-node COUNTS, then the graph itself — each
  ::  node's checkState bits and each outgoing edge's checkAction bits. State
  ::  fingerprints project as a RANK (the index in the ascending ordering of the
  ::  reachable state fingerprints) rather than raw: both sides compute the same
  ::  FP64, so the rank agrees, and it keeps the golden readable.
  |=  [counts=(list [nodes=@ud inits=@ud]) blocks=(list wain)]
  ^-  wain
  =/  hd=@t  (crip "OOS {(scow %ud (lent counts))}")
  =/  body
    =/  i  0
    =|  acc=(list @t)
    |-  ^-  (list @t)
    ?~  counts  (flop acc)
    =/  blk=wain  ?:((gth (lent blocks) i) (snag i blocks) ~)
    =/  block=(list @t)
      %+  weld
        ^-  wain
        :~  (crip "--- {(scow %ud i)} ---")
            (crip "NODES {(scow %ud nodes.i.counts)}")
            (crip "INITS {(scow %ud inits.i.counts)}")
        ==
      blk
    $(counts t.counts, i +(i), acc (weld (flop block) acc))
  `wain`['PRODUCT' hd body]
::
++  product-blocks
  ::  the per-OrderOfSolution PNODE/PEDGE lines: the labeled product from
  ::  lib/liveness, rendered in fingerprint-rank order so the projection is a
  ::  SET and not a traversal artifact
  |=  c=sctx
  ^-  (list wain)
  =/  o=bfs-opts  [nsb.c ~ cons.c acons.c ~ vars.c order.c perms.c defs.c consts.c | 0 0 view.c 0 | ~ *cov-opts 0 ~ | ~]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
  =/  ranks   (fp-ranks states)
  =/  oss  oss.c
  |-  ^-  (list wain)
  ?~  oss  ~
  :-  (render-product-graph:lv i.oss states inits.g nsb.c env order.c ranks)
  $(oss t.oss)
::
++  fp-ranks
  ::  state fingerprint -> its index in the ascending fingerprint ordering
  |=  states=(map @t state:ne)
  ^-  (map @t @ud)
  =/  fps  (sort ~(tap in ~(key by states)) lth)
  =|  acc=(map @t @ud)
  =/  i  0
  |-  ^-  (map @t @ud)
  ?~  fps  acc
  $(fps t.fps, i +(i), acc (~(put by acc) i.fps i))
::
++  live-product
  ::  the product projection for a spec+cfg via the production search context
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  (render-product (product-counts p.sc) (product-blocks p.sc))
::
++  live-verdict-lines
  ::  the liveness VERDICT/EC projection (unit 8.5) for a spec+cfg — the
  ::  temporal-property verdict via the SCC/acceptance search over the product
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  =*  c  p.sc
  =/  o=bfs-opts  [nsb.c ~ cons.c acons.c ~ vars.c order.c perms.c defs.c consts.c | 0 0 view.c 0 | ~ *cov-opts 0 ~ | ~]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
  ?:  (live-verdict:lv oss.c states inits.g nsb.c env order.c)
    ~['VERDICT violated-property' 'EC 2116']
  ~['VERDICT ok' 'EC 0']
::
++  live-lasso-lines
  ::  the lasso CLASS/LOOP/TRACE/STATE projection (unit 8.6) for a violated
  ::  spec: the stuttering lasso (an initial state that stutters) or a
  ::  back-to-state lasso (a real cycle returning to an earlier state), with
  ::  per-state action labels from getActions
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  =*  c  p.sc
  =/  o=bfs-opts  [nsb.c ~ cons.c acons.c ~ vars.c order.c perms.c defs.c consts.c | 0 0 view.c 0 | ~ *cov-opts 0 ~ | ~]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
  =/  l  (find-lasso:lv oss.c states inits.g nsb.c env order.c)
  ?~  l  ~['(no lasso)']
  =/  modn     (module-name-of tree.c)
  =/  actions  (get-actions nsb.c aname.c defs.c env)
  =/  np    (lent prefix.u.l)
  =/  stut  =(%stuttering class.u.l)
  =/  marker-num    ?:(stut +(np) loop.u.l)
  ::  the prefix states: state 1 is the initial predicate, each later state is
  ::  labeled with the action that generated it
  =/  prefix-lines=wain
    =/  i  1
    =/  prev=(unit @t)  ~
    =/  ps  prefix.u.l
    |-  ^-  wain
    ?~  ps  ~
    =/  st  (~(got by states) i.ps)
    =/  label=@t
      ?~  prev  'LABEL <Initial predicate>'
      %-  crip
      %+  weld  "LABEL "
      (trip (edge-action-label (~(got by states) u.prev) i.ps actions env order.c modn))
    %+  weld
      ;:  weld
        ~[(crip "STATE {(scow %ud i)} {(fp-hex i.ps)}")]
        ~[label]
        (render-state order.c st ~ *eenv:ne ~)
        ~['ENDSTATE']
      ==
    $(ps t.ps, i +(i), prev `i.ps)
  =/  marker=wain
    :~  (crip "STATE {(scow %ud marker-num)} -1")
        ?:(stut 'LABEL Stuttering' 'LABEL Back to state')
        'ENDSTATE'
    ==
  =/  header=wain
    :~  'LIVENESS'
        'VERDICT violated-property'
        'EC 2116'
        (crip "STAT generated {(scow %ud gen.g)}")
        (crip "STAT distinct {(scow %ud distinct.g)}")
        'STAT queue 0'
        (crip "STAT depth {(scow %ud depth.g)}")
    ==
  ;:  weld
    header
    :~  (crip "CLASS {(trip class.u.l)}")
        (crip "LOOP {(scow %ud loop.u.l)}")
        (crip "TRACE {(scow %ud +(np))}")
    ==
    prefix-lines
    marker
  ==
::
++  violated-props
  ::  R2.7.12: `Liveness.findViolatedProperties` -- POST-HOC PROPERTY
  ::  ATTRIBUTION. The lasso is already built and already sound; this asks each
  ::  IMPLIED TEMPORAL separately whether THIS behaviour satisfies it, and
  ::  returns the names of those it does not, in declaration order.
  ::
  ::  The port reported the FIRST `PROPERTY` instead, which is right only when
  ::  the first property is the violated one. Measured at the pin on a two-
  ::  property spec whose first property HOLDS: tlc2 names the second.
  ::
  ::  A property whose live-expression cannot be built is SKIPPED, not
  ::  reported -- tlc2 catches there and degrades to a smaller set rather than
  ::  crashing, since the counter-example is already valid.
  |=  $:  props=(list [name=@t body=sem:sem-lib])
          l=lasso:lv  states=(map @t state:ne)
          env=eenv:ne  modn=@t
      ==
  ^-  (list @t)
  =/  sts=(list state:ne)  (turn prefix.l |=(fp=@t (~(got by states) fp)))
  ?~  sts  ~
  ::  `cyclePos` is `states.size() - 1` at the moment the cycle is appended --
  ::  the 0-based index of the state the cycle returns to. `loop` is that
  ::  index 1-based, for a stuttering closer (the last state) and for a
  ::  back-to-state one alike
  =/  cyc  ?:(=(0 loop.l) (dec (lent sts)) (dec loop.l))
  =|  out=(list @t)
  |-  ^-  (list @t)
  ?~  props  (flop out)
  =/  lr  (ast:tp body.i.props [modn 0 ~ ~ ~] env)
  ?:  ?=(%| -.lr)  $(props t.props)
  ?:  (eval-on-lasso:lv p.lr sts cyc 0 env)  $(props t.props)
  ?:  (lien out |=(n=@t =(n name.i.props)))  $(props t.props)
  $(props t.props, out [name.i.props out])
::
++  violated-header
  ::  R2.7.12: MP's `TLC_TEMPORAL_PROPERTY_VIOLATED` template, which has a
  ::  PLURAL form the port never emitted -- `Temporal properties A and B were
  ::  violated.` for two, `A, B, and C were violated.` for three or more. An
  ::  empty attribution falls back to `pname`, the first PROPERTY, which is
  ::  what this printed unconditionally before
  |=  [ns=(list @t) pname=@t]
  ^-  @t
  ?~  ns
    (crip "Error: Temporal property {(trip pname)} was violated.")
  ?~  t.ns
    (crip "Error: Temporal property {(trip i.ns)} was violated.")
  =/  n  (lent ns)
  =/  body=tape
    =/  i=@ud  1
    =/  l=(list @t)  ns
    |-  ^-  tape
    ?~  l  ""
    =/  sep=tape
      ?:  =(i 1)  ""
      ?:  =(i n)  ?:(=(n 2) " and " ", and ")
      ", "
    :(weld sep (trip i.l) $(l t.l, i +(i)))
  (crip "Error: Temporal properties {body} were violated.")
::
++  live-report
  ::  the TLC console diagnostic for a temporal run from an ALREADY-BUILT graph
  ::  (unit 8.8.1): shared by the `live-message-lines` differential and the job
  ::  kernel's %liveness stage. Returns the lasso (for the typed result/trace)
  ::  and the console `wain`. The whole-graph find-lasso; the job kernel instead
  ::  builds the lasso via the sliced product cursor and calls +live-render.
  |=  $:  oss=(list oos:tp)  states=(map @t state:ne)  inits=(list @t)
          nsb=sem:sem-lib  env=eenv:ne  order=(list @t)  modn=@t
          defs=(map @t sem-def:sem-lib)  pname=@t
          ::  R2.7.12: the implied temporals, for post-hoc attribution
          props=(list [name=@t body=sem:sem-lib])
          gen=@ud  distinct=@ud  depth=@ud
          ::  context for the EC 2257/2259 stuttering hint (R1.8.1.3)
          sname=(unit @t)  sloc=sspan:sem-lib  fair=(list sem:sem-lib)
          aname=@t                      ::  root action name (`sctx`'s)
          ::  R2.7.14a/b: what the POSTCONDITION block needs. The LINES cannot
          ::  be built by the caller any more, because R2.7.14b binds
          ::  `TLCExt!CounterExample` to the lasso and the lasso is found HERE
          ::  -- handing the caller one would mean building the product twice
          pcs=(list @t)  rs=rst:ne
          poss=(list [name=@t body=sem:sem-lib lvl=@ud])
          ::  R4.2i: the ALIAS the lasso is rendered through
          al=(unit sem:sem-lib)
      ==
  ^-  [lasso=(unit lasso:lv) report=wain]
  ::  find the lasso AND the OrderOfSolution that produced it: tlc2 tests the
  ::  hint against `this.oos` — the one being reported — not against every
  ::  solution, so a spec whose FIRST violated property has empty PEMs prints no
  ::  hint even when a later property would have one (multi-property)
  =/  hit
    =/  os  oss
    |-  ^-  [l=(unit lasso:lv) o=(list oos:tp)]
    ?~  os  [~ ~]
    =/  r  (oos-lasso:lv i.os states inits nsb env order)
    ?^(r [r ~[i.os]] $(os t.os))
  ::  R2.7.14b: the counter-example as a VALUE, bound for the POSTCONDITION
  ::  and for nothing else -- tlc2 conses it onto an otherwise empty Context
  ::  for exactly that call. `loop` is 0 when the counter-example carries no
  ::  closer, which is `+box-free-tf`: that is the LiveCheck call site, and its
  ::  CounterExample gets no closing edge
  =/  cev=(unit value)
    ?~  l.hit  ~
    :-  ~
    %:  counter-example-value
      (turn prefix.u.l.hit |=(fp=@t (~(got by states) fp)))
      order
      (get-actions nsb aname defs env)
      env
      modn
      ?:((box-free-tf o.hit) 0 loop.u.l.hit)
    ==
  =/  pcl=wain
    %:  post-cond-lines
      pcs
      defs
      %-  ?~(cev same |=(x=eenv:ne (with-ce:ne x u.cev)))
      (with-run:ne env [| 0 `[depth distinct 0 gen]])
      modn
      rs
      poss
    ==
  :-  l.hit
  %-  live-render
  :*  l.hit  states  nsb  env  order  modn  defs  pname  props
      gen  distinct  depth
      (stutter-gate o.hit sname sloc fair modn)
      aname
      (box-free-tf o.hit)
      pcl
      al
  ==
::
++  live-render
  ::  render the console diagnostic from a resolved lasso (unit 8.8.2a): shared
  ::  by +live-report and the job kernel's sliced %check phase. `Model checking
  ::  completed…` for a pass (l is ~), else the `Temporal property … was
  ::  violated.` counter-example (numbered `State N:` trace with getActions
  ::  labels, `Stuttering` / `Back to state N:` closer, and the counts).
  |=  $:  l=(unit lasso:lv)  states=(map @t state:ne)
          nsb=sem:sem-lib  env=eenv:ne  order=(list @t)  modn=@t
          defs=(map @t sem-def:sem-lib)  pname=@t
          ::  R2.7.12: the implied temporals, for post-hoc attribution
          props=(list [name=@t body=sem:sem-lib])
          gen=@ud  distinct=@ud  depth=@ud
          gate=wain                     ::  EC 2257/2259 hint (R1.8.1.3)
          aname=@t                      ::  root action name (`sctx`'s)
          ::  R2.7.5: suppress the CLOSER entirely. tlc2 ends the
          ::  counter-example at its last prefix state -- no `State N:
          ::  Stuttering`, no `Back to state` -- whenever the violated
          ::  property's TABLEAU FORMULA carries no `[]`; see `+box-free-tf`
          noclose=?
          ::  R2.7.14: the POSTCONDITION lines. R2.7.7.3 wired postconditions
          ::  into the CLEAN and the SAFETY-ERROR reports and left the TEMPORAL
          ::  one out; measured at the pin, a POSTCONDITION runs after a
          ::  temporal violation too, and its line sits between the EC
          ::  2257/2259 hint and the counts. `~` when every postcondition holds
          pcl=wain
          ::  R4.2i: the ALIAS each prefix state is rendered through
          al=(unit sem:sem-lib)
      ==
  ^-  wain
  =/  footer  (counts-lines gen distinct 0 depth)
  ?~  l
    ::  a CLEAN temporal run: a failing postcondition REPLACES `Model checking
    ::  completed.` rather than being appended to it -- the same rule R2.7.7.3
    ::  measured on the safety path, since the error IS the run's outcome
    ?^  pcl  (weld pcl footer)
    ['Model checking completed. No error has been found.' footer]
  =/  actions  (get-actions nsb aname defs env)
  =/  np       (lent prefix.u.l)
  =/  stut     =(%stuttering class.u.l)
  ::  the numbered prefix states (factored out by R2.7.5: the post-error
  ::  second block renders the same prefix with no closer and no counts)
  ::  R4.2i, measured: under an ALIAS the last prefix state is paired with
  ::  the state the cycle returns to, and with itself under a stuttering or
  ::  suppressed closer
  =/  lsuc=(unit @t)
    ?:  |(stut noclose)  ~
    `(snag (dec loop.u.l) prefix.u.l)
  =/  body=wain
    (live-prefix-lines prefix.u.l states actions env order modn al lsuc)
  ::  the closer: a stuttering self-loop is a new numbered `State`, a
  ::  back-to-state cycle is `Back to state <loop>: <action reaching it>`
  =/  closer=wain
    ?:  stut
      ~[(crip "State {(a-tape +(np))}: Stuttering")]
    =/  last-fp   (rear prefix.u.l)
    =/  loop-fp   (snag (dec loop.u.l) prefix.u.l)
    =/  label
      (edge-action-label (~(got by states) last-fp) loop-fp actions env order modn)
    ~[(crip "Back to state {(a-tape loop.u.l)}: {(trip label)}")]
  ;:  weld
    ~[(violated-header (violated-props props u.l states env modn) pname)]
    ~['Error: The following behavior constitutes a counter-example:']
    body
    ?:(noclose ~ closer)
    ::  the 2257/2259 hint sits between the stuttering marker and the counts,
    ::  and only after a STUTTERING closer (R1.8.1.3) -- so a suppressed closer
    ::  suppresses the hint with it: there is no stuttering to explain
    ?:(|(noclose !stut) ~ gate)
    ::  R2.7.14: measured order is counter-example, closer, hint, POSTCONDITION,
    ::  counts -- `Warning: The stuttering counterexample above ...` then
    ::  `Error: Postcondition <name> at <loc> is false.` then the statistics
    pcl
    footer
  ==
::
++  live-prefix-lines
  ::  the numbered prefix states of a lasso: state 1 is the initial predicate,
  ::  each later state labeled with the action that generated it (no
  ::  fingerprint line). Shared by `+live-render` and `+post-error-live`
  ::  R4.2i: under an ALIAS (`al`) each state is rendered as `+alias-state`
  ::  renders a safety trace -- paired with the next prefix state, and the
  ::  LAST with `lsuc` (the state the cycle returns to; ~ is itself), as the
  ::  pin pairs them (`LiveWorker`)
  |=  $:  prefix=(list @t)  states=(map @t state:ne)  actions=(list act)
          env=eenv:ne  order=(list @t)  modn=@t
          al=(unit sem:sem-lib)  lsuc=(unit @t)
      ==
  ^-  wain
  =/  i  1
  =/  prev=(unit @t)  ~
  =/  ps  prefix
  |-  ^-  wain
  ?~  ps  ~
  =/  st  (~(got by states) i.ps)
  =/  label=@t
    ?~  prev  '<Initial predicate>'
    (edge-action-label (~(got by states) u.prev) i.ps actions env order modn)
  =/  shown=[order=(list @t) st=state:ne]
    ?~  al  [order st]
    =/  suc=state:ne
      ?^  t.ps  (~(got by states) i.t.ps)
      ?~(lsuc st (~(got by states) u.lsuc))
    (alias-state u.al env st suc)
  %+  weld
    ;:  weld
      ~[(crip "State {(a-tape i)}: {(trip label)}")]
      (render-state order.shown st.shown ~ *eenv:ne ~)
    ==
  $(ps t.ps, i +(i), prev `i.ps)
::
++  post-error-live
  ::  R2.7.5: THE SECOND REPORT BLOCK. A safety error (deadlock, invariant)
  ::  ends the state search, and R1.6.6 had it pre-empt the liveness report
  ::  entirely. MEASURED at the pin, that is too strong -- tlc2 prints the
  ::  safety trace and then, in its own block before the statistics,
  ::  `Error: Temporal property <P> was violated.` with a counter-example.
  ::
  ::  Two conditions, both measured, and BOTH needed:
  ::
  ::  1. the state QUEUE IS EMPTY at the error. `Github710d` (deadlock, 0
  ::     queued) and an invariant violation with 0 queued both print the block;
  ::     the same specs with one state left on the queue do NOT. Stable from
  ::     4 states to 20.001.
  ::  2. the violated property's tableau formula is BOX-FREE -- `+box-free-tf`,
  ::     the same predicate that decides whether the counter-example carries a
  ::     closer. Equivalently: tlc2 appends this block exactly for the
  ::     counter-examples it would render WITHOUT a closer, which is why the
  ::     block has none.
  ::
  ::  The row this unit came from says "after a deadlock". Measured, it is not
  ::  deadlock-specific: an INVARIANT violation gets the block too, which also
  ::  corrects R2.3.4's note at the temporal console path ("an INVARIANT
  ::  alongside a temporal PROPERTY prints ... NO temporal verdict") -- true
  ::  for the `<>` property that unit measured, not in general.
  |=  $:  out=outcome  oss=(list oos:tp)  states=(map @t state:ne)
          inits=(list @t)  nsb=sem:sem-lib  env=eenv:ne
          order=(list @t)  modn=@t  defs=(map @t sem-def:sem-lib)
          pname=@t  props=(list [name=@t body=sem:sem-lib])  aname=@t
          al=(unit sem:sem-lib)
      ==
  ^-  wain
  ?.  ?=(?(%inv %deadlock) -.out)  ~
  ?.  =(0 queued.out)  ~
  ::  the box-free test is PER OrderOfSolution, on the one that produced the
  ::  lasso -- not over the whole list. `Github710d` declares `NeverThree` AND
  ::  `Tautology`, and only the first is box-free
  =/  hit
    =/  os  oss
    |-  ^-  [l=(unit lasso:lv) o=(list oos:tp)]
    ?~  os  [~ ~]
    =/  r  (oos-lasso:lv i.os states inits nsb env order)
    ?^(r [r ~[i.os]] $(os t.os))
  ?~  l.hit  ~
  ?.  (box-free-tf o.hit)  ~
  ;:  weld
    ~[(violated-header (violated-props props u.l.hit states env modn) pname)]
    ~['Error: The following behavior constitutes a counter-example:']
    %-  live-prefix-lines
    :*  prefix.u.l.hit  states  (get-actions nsb aname defs env)
        env  order  modn  al  ~
    ==
  ==
::
++  box-free-tf
  ::  R2.7.11a: moved to `+box-free-tf:lv` -- `+lasso-of-product`
  ::  needs the same predicate to choose which accepting stutter to
  ::  report, and liveness.hoon cannot depend on check.hoon.
  box-free-tf:lv
::
++  stutter-gate
  ::  the hint tlc2 appends AFTER a STUTTERING counterexample (EC 2257 / 2259,
  ::  `Liveness.printStutteringCounterExampleWarning`). It fires only when the
  ::  OrderOfSolution has a non-empty PEM — a `<>P` whose tableau has no pending
  ::  obligation prints no hint, which is why a naive `<>(x = 1)` probe does not
  ::  show it. 2259 when a SPECIFICATION is configured but carries no fairness
  ::  (naming the spec and its source location); 2257 when only INIT/NEXT were
  ::  given, so TLC permits infinite stuttering
  |=  [oss=(list oos:tp) sname=(unit @t) sloc=(unit span) fair=(list sem:sem-lib) modn=@t]
  ^-  wain
  ::  tlc2 suppresses the hint when EVERY OrderOfSolution has box-free promises
  ::  AND every one of its PEMs is itself EMPTY — `isEmpty` meaning no `<>[]A`,
  ::  no `[]<>S` and no `[]<>A` condition (`PossibleErrorModel.isEmpty`), not an
  ::  empty PEM LIST. Testing the list was wrong: a spec with one condition-free
  ::  PEM would then have printed a hint tlc2 omits (live-diamond)
  =/  quiet
    %+  levy  oss
    |=  o=oos:tp
    ?:  (lien promises.o has-box:tp)  |
    %+  levy  pems.o
    |=  m=pem:tp
    &(=(~ ea-action.m) =(~ ae-state.m) =(~ ae-action.m))
  ?:  quiet  ~
  ?^  sname
    ?^  fair  ~
    :_  ~
    %-  crip
    ;:  weld
      "Warning: The stuttering counterexample above may be caused by the "
      "absence of a fairness constraint in the behavior specification "
      "{(trip u.sname)} defined at {(trip (locn-tape sloc modn))}. To rule out "
      "such counterexamples, conjoin a suitable fairness constraint to "
      "{(trip u.sname)} (compare Chapter 8, page 87ff of Specifying Systems at "
      "https://lamport.azurewebsites.net/tla/book.html)."
    ==
  :_  ~
  %-  crip
  ;:  weld
    "Warning: The stuttering counterexample above may be caused by the absence "
    "of a behavior specification (SPECIFICATION). Only INIT and NEXT have been "
    "provided, so TLC permits infinite stuttering. To rule out such "
    "counterexamples, use SPECIFICATION Spec, with Spec asserting a suitable "
    "fairness constraint (compare Chapter 8, page 87ff of Specifying Systems "
    "at https://lamport.azurewebsites.net/tla/book.html)."
  ==
::
++  locn-tape
  ::  `line BL, col BC to line EL, col EC of module M` — the bare location tlc2
  ::  prints for a definition (the same shape +action-label wraps in angles)
  |=  [sp=(unit span) modn=@t]
  ^-  @t
  ?~  sp  (crip "module {(trip modn)}")
  =*  s  u.sp
  %-  crip
  ;:  weld
    "line "  (a-tape line.from.s)  ", col "  (a-tape col.from.s)
    " to line "  (a-tape line.to.s)  ", col "  (a-tape col.to.s)
    " of module "  (trip modn)
  ==
::
++  live-message-lines
  ::  the TLC console diagnostic for a temporal violation (unit 8.7.1), rendered
  ::  from the 8.2–8.6 liveness engine's lasso — a thin differential wrapper over
  ::  `+live-report` (which the job kernel also uses, unit 8.8.1).
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  =*  c  p.sc
  =/  o=bfs-opts  [nsb.c ~ cons.c acons.c ~ vars.c order.c perms.c defs.c consts.c | 0 0 view.c 0 | ~ *cov-opts 0 ~ | ~]
  =/  g       (build-graph is.c o)
  =/  states  (states-of seen.g)
  =/  env     (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
  =/  modn    (module-name-of tree.c)
  =/  pname   ?~(pp.c '' u.pp.c)
  =/  r
    %-  live-report
    :*  oss.c  states  inits.g  nsb.c  env  order.c  modn  defs.c  pname
        props.c
        gen.g  distinct.g  depth.g  sname.c  sloc.c  fair.c  aname.c
        ::  the `live-message-lines` differential renders the lasso alone, so
        ::  it declares no postconditions (R2.7.14)
        ~  empty-rst:ne  ~  ~
    ==
  ::  R2.7.5: the `swarn` channel prints BEFORE the verdict on the production
  ::  path (`+check-in`), so the differential wrapper carries it too -- else
  ::  the EC 2279 warn-and-continue would be invisible to this shard
  (weld swarn.c report.r)
::
::
::  +|  DFID — Depth-First Iterative Deepening (R2.5)
::
::  A port of `tlc2.tool.DFIDModelChecker` + `DFIDWorker` + the
::  `FPIntSet`/`MemFPIntSet` visited set. It is a SECOND search engine rather
::  than a mode of `+bfs-step`, for the reason R2.5.0 measured: the visited set
::  is not a set. Each fingerprint carries a STATUS WORD — a DONE bit, a
::  LEVELED bit compared against a global parity that alternates 2, 0, 2, 0 on
::  every level, and the level in the high bits — so one sweep invalidates the
::  previous sweep's marks in O(1) instead of clearing the set. The BFS `seen`
::  map cannot express that.
::
::  ONE APPROVED DIFFERENCE, and it is forced by the oracle rather than by the
::  port: `DFIDWorker.getInit`/`getNext` descend into a RANDOM eligible
::  successor, drawn from a generator seeded off the clock
::  (`new RandomGenerator()` takes `java.util.Random()`'s no-arg seed, then
::  reseeds from `nextLong()`); `-seed` does not reach it. Measured at the pin,
::  six runs of the same TLC on one unchanged spec reported THREE different
::  counterexamples while every count was byte-identical. So the DFS ORDER — and
::  with it the counterexample trace — is not a function of the specification
::  and cannot be a parity target. This port descends in generation order. Every
::  COUNT is order-independent and is matched exactly.
::
+$  dfid-opts
  $:  ::  the getActions decomposition, NOT the whole next-state relation.
      ::  `DFIDModelChecker.doNext` loops over `tool.getActions()` and does
      ::  `numOfGenStates.getAndAdd(sz)` per ACTION, so a doNext that stops at a
      ::  violating successor has counted that action's whole vector and none of
      ::  the later actions'. Counting the merged relation instead over-reports
      ::  every terminating run by the successors tlc2 never generated
      acts=(list act)
      ::  INVARIANTs, plus a `[]P` box-state PROPERTY: `processConfigProps`
      ::  appends that to the SAME `invVec` the config's INVARIANTs fill, so it
      ::  is not a separate check and DFID does not refuse it
      invs=(list [name=@t body=sem:sem-lib])
      ::  IMPLIED ACTIONS (`[][A]_v`): checked per TRANSITION inside `doNext`,
      ::  right after the invariants. The BFS path scans a finished graph
      ::  instead, which DFID never has -- so this one is done tlc2's own way
      iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
      ::  an IMPLIED INIT (a level-1 PROPERTY): checked per initial state
      iinits=(list [name=@t body=sem:sem-lib])
      cons=(list sem:sem-lib)                  ::  CONSTRAINT
      acons=(list sem:sem-lib)                 ::  ACTION_CONSTRAINT
      vars=(set @t)
      order=(list @t)
      defs=(map @t sem-def:sem-lib)
      consts=(map @t value)
      deadlock=?
      setmax=@ud
      ::  tlc2's `-dfid num`: the deepest level a sweep may reach. `runTLC`
      ::  returns immediately for a depth below 2, so 0 and 1 explore the
      ::  initial states and nothing else
      maxd=@ud
  ==
::  one frame of the explicit DFS stack: the state, its fingerprint, and the
::  successors still eligible to descend into (tlc2's succStateStack/succFPStack)
+$  dfid-frame  [st=state fp=@t sucs=(list [st=state fp=@t])]
::  the first violation a run found, held until the run ENDS. tlc2 reports all
::  four the same way -- `setErrState` + `printTrace` -- and all four leave the
::  worker walking, which is what makes one shape enough
+$  dfid-hit
  $:  kind=?(%inv %action %prop %deadlock)
      name=@t
      trace=(list state)
      initial=?
  ==
::  the resumable DFID cursor. `lvl`/`leveled` are `FPIntSet.Level`/`Leveled`;
::  `stack` is innermost-FIRST; `more` is the worker's `moreLevel`, which tlc2
::  resets per sweep because `runTLC` builds a NEW worker for every level
+$  dfid-cursor
  $:  inits=(list [st=state fp=@t])
      fps=(map @t @ud)          ::  fingerprint -> status word
      lvl=@ud
      leveled=@ud
      todo=(list [st=state fp=@t])   ::  initial states left in THIS sweep
      stack=(list dfid-frame)
      gen=@ud
      more=?
      ::  `stopCode`: set the moment a violation is found. It ends the run at
      ::  the next `getInit`, NOT at the violation -- see `+dfid-step`
      stop=?
      hit=(unit dfid-hit)
      ::  the per-level progress lines, in order (EC 2205)
      levels=(list [lvl=@ud gen=@ud distinct=@ud])
  ==
::  a DFID run's terminal outcome. `%ok` is reached only when a sweep found no
::  more levels to explore INSIDE the bound; a run that stops because it hit
::  `maxd` is `%limited %depth`, because tlc2 prints no completion line there
+$  dfid-out
  $%  [%ok gen=@ud distinct=@ud levels=(list [lvl=@ud gen=@ud distinct=@ud])]
      [%limited gen=@ud distinct=@ud levels=(list [lvl=@ud gen=@ud distinct=@ud])]
      $:  %inv
          gen=@ud  distinct=@ud
          levels=(list [lvl=@ud gen=@ud distinct=@ud])
          trace=(list state)  name=@t  initial=?
      ==
      $:  %action
          gen=@ud  distinct=@ud
          levels=(list [lvl=@ud gen=@ud distinct=@ud])
          trace=(list state)  name=@t
      ==
      $:  %prop
          gen=@ud  distinct=@ud
          levels=(list [lvl=@ud gen=@ud distinct=@ud])
          trace=(list state)  name=@t
      ==
      $:  %deadlock
          gen=@ud  distinct=@ud
          levels=(list [lvl=@ud gen=@ud distinct=@ud])
          trace=(list state)
      ==
      [%error msg=@t]
  ==
+$  dfid-slice
  $%  [%more cur=dfid-cursor]
      [%done out=dfid-out cur=dfid-cursor]
  ==
::
::  +|  DFID status words (FPIntSet)
::
++  st-new   0
++  st-done  1
++  is-done      |=(s=@ud =(1 (dis s 1)))
++  is-completed
  |=  [s=@ud leveled=@ud]
  ^-  ?
  |(=(leveled (dis s 2)) =(1 (dis s 1)))
++  st-level     |=(s=@ud (rsh [0 2] s))
++  is-leaf-st
  |=  [s=@ud lvl=@ud]
  ^-  ?
  |(=(0 s) =(lvl (rsh [0 2] s)))
::
++  set-status
  ::  MemFPIntSet.setStatus: OR `s` into an existing entry and return the
  ::  PREVIOUS status; insert a fresh entry as `(Level << 2) | Leveled | s`
  ::  and return NEW. The returned value is the one every caller tests
  |=  [m=(map @t @ud) fp=@t s=@ud lvl=@ud leveled=@ud]
  ^-  [old=@ud m=(map @t @ud)]
  =/  e  (~(get by m) fp)
  ?^  e  [u.e (~(put by m) fp (con u.e s))]
  [st-new (~(put by m) fp (con (con (lsh [0 2] lvl) leveled) s))]
::
++  set-leveled
  ::  MemFPIntSet.setLeveled: replace the LEVELED bit with the current parity
  |=  [m=(map @t @ud) fp=@t leveled=@ud]
  ^-  (map @t @ud)
  =/  e  (~(get by m) fp)
  ?~  e  m
  (~(put by m) fp (con (dis u.e (not 0 32 2)) leveled))
::
++  dfid-env
  |=  o=dfid-opts
  ^-  eenv:ne
  =/  e  (make-env:ne defs.o consts.o vars.o)
  ?:(=(0 setmax.o) e (with-setmax:ne e setmax.o))
::
++  dfid-fp
  ::  R4.P5c: DFID reads no fingerprint (no reseed, no graph, no symmetry),
  ::  so its visited set is keyed on the identity key
  |=  [o=dfid-opts st=state]
  ^-  @t
  (@t (state-key:fp order.o st))
::
++  dfid-trace
  ::  the behavior the DFS stack currently holds, oldest first, extended by
  ::  `tail`. tlc2's DFID trace is the STACK, not a shortest path -- which is
  ::  the other half of why it is not reproducible
  |=  [stack=(list dfid-frame) tail=(list state)]
  ^-  (list state)
  =|  out=(list state)
  |-  ^-  (list state)
  ?~  stack  (weld out tail)
  $(stack t.stack, out [st.i.stack out])
::
++  dfid-verdict
  ::  the terminal outcome. The counts are the run's FINAL ones, never the ones
  ::  standing when a violation was found: `setErrState` only sets `stopCode`,
  ::  and the worker's DFS loop does not test it, so the walk from the current
  ::  initial state runs to its end and keeps counting. Measured at the pin --
  ::  the branching spec at `-dfid 8` reports 18/9, where stopping at the
  ::  violation gives 14/7
  |=  [cur=dfid-cursor fin=?(%ok %limited)]
  ^-  dfid-out
  =/  ls   (flop levels.cur)
  =/  dis  ~(wyt by fps.cur)
  ?^  hit.cur
    =*  h  u.hit.cur
    ?-  kind.h
      %deadlock  [%deadlock gen.cur dis ls trace.h]
      %inv       [%inv gen.cur dis ls trace.h name.h initial.h]
      %action    [%action gen.cur dis ls trace.h name.h]
      %prop      [%prop gen.cur dis ls trace.h name.h]
    ==
  ?-  fin
    %ok       [%ok gen.cur dis ls]
    %limited  [%limited gen.cur dis ls]
  ==
::
++  dfid-succs
  ::  `DFIDModelChecker.doNext`'s inner loop, over ONE action's successor
  ::  vector. `halt` is tlc2's early `return allSuccNonLeaf`: the vector is
  ::  abandoned at the violator and no later action runs, but the DFS walk goes
  ::  on regardless -- only `stopCode` was set
  |=  $:  o=dfid-opts  cur=dfid-cursor  fr=dfid-frame
          nx=(list state)  keep=(list [st=state fp=@t])
          done=?  noleaf=?  e=eenv:ne
      ==
  ^-  $:  err=(unit @t)  halt=?
          keep=(list [st=state fp=@t])
          done=?  noleaf=?  cur=dfid-cursor
      ==
  |-
  ^-  $:  err=(unit @t)  halt=?
          keep=(list [st=state fp=@t])
          done=?  noleaf=?  cur=dfid-cursor
      ==
  ?~  nx  [~ | keep done noleaf cur]
  =/  ch  (con-hold cons.o i.nx e)
  ?:  ?=(%| -.ch)  [`p.ch & keep done noleaf cur]
  =/  ah  (acon-hold acons.o st.fr i.nx e)
  ?:  ?=(%| -.ah)  [`p.ah & keep done noleaf cur]
  ::  `isInModel(succ) && isInActions(cur, succ)`: a pruned state is not entered
  ::  in the set and its status stays NEW, so it is still invariant-checked
  =/  in-model  &(p.ch p.ah)
  =/  sfp  (dfid-fp o i.nx)
  =^  status  fps.cur
    ?.  in-model  [st-new fps.cur]
    (set-status fps.cur sfp st-new lvl.cur leveled.cur)
  =?  done    in-model  &(done (is-done status))
  =?  noleaf  in-model  &(noleaf !(is-leaf-st status lvl.cur))
  ::  addElement happens BEFORE the invariant check, so a violating successor is
  ::  still on its parent's frame when the walk backtracks through it
  =?  keep  &(in-model !(is-completed status leveled.cur))
    [[i.nx sfp] keep]
  ::  ORDER MATTERS, and it is tlc2's: the INVARIANTS first and only for a
  ::  status of NEW (which covers both a first-seen in-model state and every
  ::  out-of-model one), then the IMPLIED ACTIONS on EVERY transition, new
  ::  successor or not -- tlc2 says so in as many words, "We need to do it even
  ::  if succState is not new". A transition breaking both names the invariant
  =/  iv  ?.(=(st-new status) ~ (first-violated invs.o i.nx e))
  ?^  iv
    ?:  ?=(%| -.u.iv)  [`p.u.iv & keep done noleaf cur]
    ::  `setErrState` reports only the FIRST violation (it returns false once
    ::  `errState` is set, so `printTrace` never runs again); every later one
    ::  is silent but still truncates its own doNext
    =?  hit.cur  ?=(~ hit.cur)
      `[%inv p.u.iv (dfid-trace stack.cur ~[st.fr i.nx]) |]
    [~ & keep done noleaf cur(stop &)]
  =/  ia  (first-bad-action iacts.o st.fr i.nx e)
  ?~  ia  $(nx t.nx)
  ?:  ?=(%| -.u.ia)  [`p.u.ia & keep done noleaf cur]
  =?  hit.cur  ?=(~ hit.cur)
    `[%action p.u.ia (dfid-trace stack.cur ~[st.fr i.nx]) |]
  [~ & keep done noleaf cur(stop &)]
::
++  dfid-next
  ::  `DFIDModelChecker.doNext` for ONE state: the successors still eligible to
  ::  descend into, whether every successor was a non-leaf (`allSuccNonLeaf`,
  ::  which drives `moreLevel`), and the updated set
  |=  [o=dfid-opts cur=dfid-cursor fr=dfid-frame leaf=? e=eenv:ne]
  ^-  $:  err=(unit @t)
          sucs=(list [st=state fp=@t])
          noleaf=?
          cur=dfid-cursor
      ==
  =|  keep=(list [st=state fp=@t])
  =/  done    &
  =/  noleaf  &
  =/  dead    &
  =/  acts  acts.o
  |-
  ^-  $:  err=(unit @t)
          sucs=(list [st=state fp=@t])
          noleaf=?
          cur=dfid-cursor
      ==
  ?^  acts
    =/  nr  (next-states:ne st.fr body.i.acts (act-env e ctx.i.acts))
    ?:  ?=(%| -.nr)  [`msg.p.nr ~ & cur]
    =/  nx  p.nr
    ::  `numOfGenStates.getAndAdd(sz)` runs before tlc2 looks at any successor
    ::  of this action, so an abandoned vector still counts in full
    =.  gen.cur  (add gen.cur (lent nx))
    =.  dead     &(dead ?=(~ nx))
    =/  r  (dfid-succs o cur fr nx keep done noleaf e)
    ?^  err.r  [err.r ~ & cur.r]
    ?:  halt.r  [~ (flop keep.r) noleaf.r cur.r]
    $(acts t.acts, cur cur.r, keep keep.r, done done.r, noleaf noleaf.r)
  ::  deadlock is reported exactly like an invariant violation -- and, exactly
  ::  like one, it does not stop the walk
  ?:  &(dead deadlock.o)
    =?  hit.cur  ?=(~ hit.cur)
      `[%deadlock '' (dfid-trace stack.cur ~[st.fr]) |]
    [~ (flop keep) noleaf cur(stop &)]
  ::  DONE when all children are DONE, or this is a leaf and no child is one
  =?  fps.cur  |(done &(leaf noleaf))
    +:(set-status fps.cur fp.fr st-done lvl.cur leveled.cur)
  [~ (flop keep) noleaf cur]
::
++  dfid-eligible
  ::  DFIDWorker.getNext: the successors still worth descending into -- not
  ::  completed at this level, and recorded DEEPER than where we now stand, so a
  ::  state already reachable in fewer steps is not re-expanded
  |=  [sucs=(list [st=state fp=@t]) m=(map @t @ud) leveled=@ud curl=@ud]
  ^-  (list [st=state fp=@t])
  ?~  sucs  ~
  =/  s  (~(gut by m) fp.i.sucs 0)
  ?:  ?&(!(is-completed s leveled) (lth curl (st-level s)))
    [i.sucs $(sucs t.sucs)]
  $(sucs t.sucs)
::
++  dfid-step
  ::  spend up to `budget` work units (one per state expanded), then return the
  ::  cursor. Every count is independent of how the run is sliced
  |=  [o=dfid-opts cur=dfid-cursor budget=@ud]
  ^-  dfid-slice
  =/  e  (dfid-env o)
  =/  spent  0
  |-  ^-  dfid-slice
  ?:  (gte spent budget)  [%more cur]
  ::  inside a walk? `DFIDWorker.run`'s inner `while (!isLeaf)` loop does NOT
  ::  test `stopCode`, so a walk that has already found a violation runs to its
  ::  end -- backtracking, expanding the frontier and counting all the way
  =/  stk  stack.cur
  ?^  stk
    =/  fr    i.stk
    =/  curl  (lent stk)
    =/  elig  (dfid-eligible sucs.fr fps.cur leveled.cur curl)
    ?~  elig
      ::  nothing left below this state: mark it leveled and backtrack. At
      ::  `curLevel == 1` tlc2 breaks out of the walk, which is the same thing
      ::  as this stack becoming empty
      =.  fps.cur  (set-leveled fps.cur fp.fr leveled.cur)
      $(cur cur(stack t.stk), spent +(spent))
    ::  descend into the first eligible successor. tlc2 picks a RANDOM one and
    ::  does NOT remove it from the frame -- re-visiting is prevented by the
    ::  status word, not by consuming the list -- so `sucs.fr` is left intact
    =/  ch  i.elig
    ::  isLeaf = curLevel >= toLevel - 1, where toLevel is the level of THIS
    ::  sweep (`lvl.cur`), not the run's bound
    =/  leaf  (gte curl (dec (max 1 lvl.cur)))
    =/  nfr=dfid-frame  [st.ch fp.ch ~]
    =/  dn  (dfid-next o cur nfr leaf e)
    ?^  err.dn  [%done [%error u.err.dn] cur.dn]
    =.  cur  cur.dn
    =.  more.cur  |(more.cur !noleaf.dn)
    ::  `isLeaf` is tlc2's LOOP CONDITION, not a "do not push" flag:
    ::  `while (!isLeaf) { ... }` in DFIDWorker.run, so the first descent that
    ::  reaches the sweep's depth ends the WHOLE walk from this initial state
    ::  and the worker goes back to `getInit()`. It does not carry on with the
    ::  parent's other successors, and it does NOT level anything on the way out
    =.  stack.cur  ?:(leaf ~ [nfr(sucs sucs.dn) stk])
    $(spent +(spent))
  ::  the walk is over, so we are back at `while (this.stopCode == 0)`
  ?:  stop.cur  [%done (dfid-verdict cur %ok) cur]
  ::  getInit: the first initial state not yet completed at this level. It is
  ::  NOT consumed -- a walk that ended on a leaf left it uncompleted, and tlc2
  ::  picks it again and descends afresh
  =/  td  todo.cur
  ?^  td
    =/  s  (~(gut by fps.cur) fp.i.td 0)
    ?:  (is-completed s leveled.cur)
      $(cur cur(todo t.td), spent +(spent))
    ::  isLeaf = toLevel < 2 for an initial state; no sweep runs below level 2,
    ::  so this is always false, and tlc2's `runTLC` is why
    =/  leaf  (lth lvl.cur 2)
    =/  fr=dfid-frame  [st.i.td fp.i.td ~]
    =/  dn  (dfid-next o cur fr leaf e)
    ?^  err.dn  [%done [%error u.err.dn] cur.dn]
    =.  cur  cur.dn
    =.  more.cur  |(more.cur !noleaf.dn)
    =.  stack.cur  ?:(leaf ~ ~[fr(sucs sucs.dn)])
    $(spent +(spent))
  ::  the sweep is over. `terminated = !moreLevel`; otherwise open the next
  ::  level, unless the bound is reached -- in which case tlc2 prints no
  ::  completion line, so the run is %limited rather than %ok
  ?.  more.cur       [%done (dfid-verdict cur %ok) cur]
  ?:  (gte lvl.cur maxd.o)  [%done (dfid-verdict cur %limited) cur]
  =/  nl  +(lvl.cur)
  %=  $
    levels.cur   [[nl gen.cur ~(wyt by fps.cur)] levels.cur]
    lvl.cur      nl
    leveled.cur  (sub 2 leveled.cur)
    todo.cur     inits.cur
    stack.cur    ~
    more.cur     |
    spent        +(spent)
  ==
::
++  dfid-cursor-init
  ::  `doInit`: every initial state is counted, entered in the set at Level 1 /
  ::  Leveled 0, and invariant-checked in declaration order. A violation there
  ::  is EC 2107 and returns before any level runs, so the cursor comes back
  ::  already stopped, holding the states inserted SO FAR and no others
  |=  [o=dfid-opts is=(list state) e=eenv:ne]
  ^-  [err=(unit @t) cur=dfid-cursor]
  ::  Level 1 / Leveled 0, and `more` TRUE so the first step OPENS level 2 --
  ::  tlc2's loop is `for (level = 2; level <= DFIDMax; level++)`, so no sweep
  ::  ever runs at level 1
  ::  `*?` is TRUE, so both flags are set explicitly rather than bunted
  =|  cur=dfid-cursor
  =.  lvl.cur      1
  =.  leveled.cur  0
  =.  more.cur     &
  =.  stop.cur     |
  =.  gen.cur      (lent is)
  =/  todo  is
  |-  ^-  [err=(unit @t) cur=dfid-cursor]
  ?~  todo  [~ cur(inits (flop inits.cur))]
  =/  f  (dfid-fp o i.todo)
  =^  status  fps.cur  (set-status fps.cur f st-new 1 0)
  =?  inits.cur  =(st-new status)  [[i.todo f] inits.cur]
  ?.  =(st-new status)  $(todo t.todo)
  ::  `doInit` is STATE-MAJOR: for each initial state every INVARIANT first
  ::  (EC 2107) and only then every implied init (EC 2108), so an invariant
  ::  false on the same state wins
  =/  iv  (first-violated invs.o i.todo e)
  ?^  iv
    ?:  ?=(%| -.u.iv)  [`p.u.iv cur(inits (flop inits.cur))]
    :-  ~
    cur(inits (flop inits.cur), stop &, hit `[%inv p.u.iv ~[i.todo] &])
  =/  ip  (first-violated iinits.o i.todo e)
  ?~  ip  $(todo t.todo)
  ?:  ?=(%| -.u.ip)  [`p.u.ip cur(inits (flop inits.cur))]
  :-  ~
  cur(inits (flop inits.cur), stop &, hit `[%prop p.u.ip ~[i.todo] &])
::
++  dfid-opts-of
  ::  the DFID options a resolved config implies, with its PROPERTY routed
  ::  exactly as `+check` routes it -- which is what decides whether DFID runs
  ::  at all. `checkLiveness`, and so `DFIDModelChecker`'s refusal, is set only
  ::  by the branch that reaches the liveness engine; the other three are
  ::  ordinary checks DFID performs like any other. `warn` carries the EC 2255
  ::  state-level warning the implied-init branch owes
  |=  $:  acts=(list act)
          invs=(list [name=@t body=sem:sem-lib])
          cons=(list sem:sem-lib)  acons=(list sem:sem-lib)
          vars=(set @t)  order=(list @t)
          defs=(map @t sem-def:sem-lib)  consts=(map @t value)
          ::  R2.7.15b: the PROPERTY NAMES, all of them. This used to take the
          ::  head of the list and its body, so DFID routed on the first
          ::  property exactly as `+check` did before R2.7.15a
          props=(list @t)
          deadlock=?  setmax=@ud  maxd=@ud
      ==
  ^-  (each [o=dfid-opts warn=wain] @t)
  =/  base=dfid-opts
    :*  acts  invs  ~  ~  cons  acons  vars  order
        defs  consts  deadlock  setmax  maxd
    ==
  ::  R2.7.15b: the same binning every other engine uses. A GENUINE temporal
  ::  property is what makes DFID refuse (upstream issue 548 -- `checkLiveness`
  ::  is set only by the branch that reaches the liveness engine); the other
  ::  three bins are ordinary checks DFID performs like any other
  =/  bins  (bin-properties props defs)
  ?^  temps.bins  [%| dfid-refusal]
  :-  %&
  :_  (turn (swarn-names props defs) state-level-warn)
  %=  base
    invs    (weld invs binvs.bins)
    iinits  iinits.bins
    iacts   iacts.bins
  ==
::
++  dfid-setup
  ::  `+dfid-opts-of` over a resolved `sctx`, for the console path
  |=  [c=sctx maxd=@ud setmax=@ud]
  ^-  (each [o=dfid-opts warn=wain] @t)
  =/  e  (make-env:ne defs.c consts.c vars.c)
  %-  dfid-opts-of
  :*  (get-actions nsb.c aname.c defs.c e)
      invs.c  cons.c  acons.c  vars.c  order.c  defs.c  consts.c
      pnames.c
      ddl.c  setmax  maxd
  ==
::
++  dfid-spec
  ::  run a DFID search from spec + config source, returning its outcome
  |=  [spec=@t cfg=@t maxd=@ud]
  ^-  dfid-out
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [%error p.sc]
  =*  c  p.sc
  =/  su  (dfid-setup c maxd 0)
  ?:  ?=(%| -.su)  [%error p.su]
  =/  o   o.p.su
  =/  ci  (dfid-cursor-init o is.c (dfid-env o))
  ?^  err.ci  [%error u.err.ci]
  =/  cur  cur.ci
  ?:  stop.cur  (dfid-verdict cur %ok)
  |-  ^-  dfid-out
  =/  r  (dfid-step o cur 1.024)
  ?:  ?=(%done -.r)  out.r
  $(cur cur.r)
::
::  +|  DFID reporting
::
::  DFID has its OWN reporter, not a parameterization of the BFS one. Measured
::  line by line at the pin (R2.5.0): the init line is EC 2208 and carries no
::  timestamp, progress is EC 2205 per LEVEL rather than `Progress(N)`, and the
::  final counts are EC 2204 -- with NO `states left on queue` term, no
::  `The depth of the complete state graph search is N.` line and no average
::  outdegree line. A run that stops at the bound prints no completion line at
::  all, which is why `%limited` renders only counts
::
++  dfid-init-line
  |=  [gen=@ud distinct=@ud]
  ^-  @t
  (ec-body:diag 2.208 ~[(a-co gen) (a-co distinct)])
::
++  dfid-levels-of
  ::  the per-level lines an outcome carries. Every arm but %error has them,
  ::  but at different axes, so a bare `levels.res` over the union forks
  |=  res=dfid-out
  ^-  (list [lvl=@ud gen=@ud distinct=@ud])
  ?-  -.res
    %error     ~
    %ok        levels.res
    %limited   levels.res
    %inv       levels.res
    %action    levels.res
    %prop      levels.res
    %deadlock  levels.res
  ==
::
++  dfid-level-lines
  |=  ls=(list [lvl=@ud gen=@ud distinct=@ud])
  ^-  wain
  %+  turn  ls
  |=  [lvl=@ud gen=@ud distinct=@ud]
  (ec-body:diag 2.205 ~[(a-co lvl) (a-co gen) (a-co distinct)])
::
++  dfid-counts-line
  |=  [gen=@ud distinct=@ud]
  ^-  @t
  (ec-body:diag 2.204 ~[(a-co gen) (a-co distinct)])
::
++  render-dfid-trace
  ::  DFID's trace has NO action labels: `printInvariantTrace` and
  ::  `printErrorTrace` both print the ordinal and nothing else, where the BFS
  ::  trace names the getActions leaf. The two printers also differ in
  ::  WHITESPACE, and a renderer has to reproduce it. `printTrace` routes ONLY
  ::  EC 2110 to `printInvariantTrace`, so an invariant violation prints
  ::  `State N: ` with a trailing space (TLC_STATE_PRINT2, template `%1%: %2%`
  ::  with an empty info) and everything else -- deadlock, action property,
  ::  runtime error -- goes to `printErrorTrace` and its `State N:` with none
  ::  (TLC_STATE_PRINT1, template `%1%:`)
  |=  $:  trace=(list state)  order=(list @t)
          e=eenv:ne  vw=(unit sem:sem-lib)  spaced=?
      ==
  ^-  wain
  =/  i  1
  %-  zing
  |-  ^-  (list wain)
  ?~  trace  ~
  :_  $(trace t.trace, i +(i))
  ;:  weld
    ~[(crip "State {(a-tape i)}:{?:(spaced " " "")}")]
    (render-state order i.trace vw e ~)
    ~['']
  ==
::
++  render-dfid-outcome
  ::  TLC's terminal lines for a DFID outcome, init line first. `ngen`/`ndis`
  ::  are `doInit`'s own two numbers: every initial state generated, and the
  ::  distinct in-model ones actually kept
  |=  $:  res=dfid-out  order=(list @t)
          e=eenv:ne  al=(unit sem:sem-lib)  vw=(unit sem:sem-lib)
          ngen=@ud  ndis=@ud
      ==
  ^-  wain
  ?:  ?=(%error -.res)  ~[(crip "Error: {(trip msg.res)}")]
  ::  an INITIAL-state violation returns from `doInit`, so `modelCheckImpl`
  ::  never reaches the EC 2208 line or the level loop -- measured at the pin,
  ::  such a run prints its error block and nothing else
  =/  initial=?  ?|(?=(%prop -.res) ?&(?=(%inv -.res) initial.res))
  =/  head=wain
    ?:  initial  ~
    :-  (dfid-init-line ngen ndis)
    (dfid-level-lines (dfid-levels-of res))
  ::  the offending initial state, rendered inline. An ALIAS applies here too
  ::  (R2.3.2): tlc2 builds both EC 2107 and EC 2108 from
  ::  `evalAlias(curState, curState)`, the initial state being its own successor
  =/  init-state
    |=  trace=(list state)
    ^-  wain
    ?~  trace  ~
    =/  shown=[order=(list @t) st=state]
      ?~  al  [order i.trace]
      (alias-state u.al e i.trace i.trace)
    (render-state order.shown st.shown vw e ~)
  %+  weld  head
  ?-    -.res
      %ok
    :~  'Model checking completed. No error has been found.'
        (dfid-counts-line gen.res distinct.res)
    ==
  ::
      %limited
    ::  the bound was reached: tlc2's level loop simply ends, `reportSuccess`
    ::  never runs, and the summary prints alone. Measured -- `-dfid 2` on a
    ::  deeper graph prints counts and NO verdict line
    ~[(dfid-counts-line gen.res distinct.res)]
  ::
      %inv
    ?:  initial.res
      %+  weld
        ~[(crip "Error: Invariant {(trip name.res)} is violated by the initial state:")]
      (init-state trace.res)
    ;:  weld
      ~[(cat 3 'Error: ' (ec-body:diag 2.110 ~[name.res]))]
      ~['Error: The behavior up to this point is:']
      (render-dfid-trace trace.res order e vw &)
      ~[(dfid-counts-line gen.res distinct.res)]
    ==
  ::
      %prop
    ::  an implied init can only fail on an INITIAL state, so like EC 2107 it
    ::  prints its state inline and no statistics follow
    %+  weld
      ~[(crip "Error: Property {(trip name.res)} is violated by the initial state:")]
    (init-state trace.res)
  ::
      %action
    ;:  weld
      ~[(crip "Error: Action property {(trip name.res)} is violated.")]
      ~['Error: The behavior up to this point is:']
      ::  UNSPACED: `printTrace` routes only EC 2110 to `printInvariantTrace`;
      ::  everything else -- this and the deadlock -- goes to `printErrorTrace`
      ::  and its `State N:` with no trailing space. Measured at the pin
      (render-dfid-trace trace.res order e vw |)
      ~[(dfid-counts-line gen.res distinct.res)]
    ==
  ::
      %deadlock
    ;:  weld
      ~['Error: Deadlock reached.']
      ~['Error: The behavior up to this point is:']
      (render-dfid-trace trace.res order e vw |)
      ~[(dfid-counts-line gen.res distinct.res)]
    ==
  ==
::
++  dfid-refusal
  ::  `DFIDModelChecker.java:67`. It keys on `checkLiveness`, i.e. on a GENUINE
  ::  temporal property -- a `[]P` box-state one routes to the invariant path
  ::  and runs, so this cannot key on `PROPERTY` being present. Note the DOUBLE
  ::  space before `Please`, which is in the Java string literal
  %^  cat  3
    'Depth-First Iterative Deepening mode does not support checking liveness '
  %^  cat  3
    'properties (https://github.com/tlaplus/tlaplus/issues/548).  Please check '
  'liveness properties in Breadth-First-Search mode.'
::
++  dfid-check
  ::  the DFID counterpart of `+check`: TLC's terminal output for
  ::  `tlc2.TLC -dfid <maxd>` on this spec + config
  |=  [spec=@t cfg=@t maxd=@ud]
  ^-  wain
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  =*  c  p.sc
  =/  su  (dfid-setup c maxd 0)
  ?:  ?=(%| -.su)  ~[(cat 3 'Error: ' p.su)]
  =/  ae  (check-assumes asmz.c (make-env:ne defs.c consts.c vars.c) (module-name-of tree.c) ses.c)
  ?^  ae  (snoc aout.c (cat 3 'Error: ' msg.u.ae))
  =/  o   o.p.su
  =/  e   (dfid-env o)
  =/  ci  (dfid-cursor-init o is.c e)
  ?^  err.ci  ~[(crip "Error: {(trip u.err.ci)}")]
  =/  ndis  ~(wyt by fps.cur.ci)
  =/  out
    ?:  stop.cur.ci  (dfid-verdict cur.ci %ok)
    =/  cur  cur.ci
    |-  ^-  dfid-out
    =/  r  (dfid-step o cur 1.024)
    ?:  ?=(%done -.r)  out.r
    $(cur cur.r)
  ;:  weld
    swarn.c
    warn.p.su
    (render-dfid-outcome out order.c e alias.c vrend.c (lent is.c) ndis)
  ==
::
++  get-actions
  ::  Tool.getActions: decompose a next-state relation into named leaf actions.
  ::  A user-op reference recurses into its body (renaming the action), a
  ::  disjunction recurses each disjunct, a constant-level `\E` enumerates,
  ::  anything else is a leaf action. `e` is the constant-only environment the
  ::  `\E` bound is evaluated in (tlc2 evaluates it against `TLCState.Empty`)
  |=  [n=sem:sem-lib nm=@t defs=(map @t sem-def:sem-lib) e=eenv:ne]
  ^-  (list act)
  (get-actions-in n nm defs e ~)
::
++  get-actions-in
  ::  +get-actions carrying the bound-variable context accumulated so far
  |=  $:  n=sem:sem-lib  nm=@t  defs=(map @t sem-def:sem-lib)
          e=eenv:ne  ctx=(map @t value)
      ==
  ^-  (list act)
  ?:  ?=(%letin -.n)
    ?~  body.n  ~[[nm n ctx]]
    ::  R4.2n: descend, as `getActions` does, but put each action back under
    ::  the LET. tlc2's nodes LINK to the LET's definitions; the port names
    ::  them, so a stripped LET left `x' = b` with no `b` ("undefined
    ::  operator", MultiCarElevator's `CallElevator`). The wrapper takes the
    ::  body's span, which is the action's location at the pin
    =/  as  $(n u.body.n)
    =|  out=(list act)
    |-  ^-  (list act)
    ?~  as  (flop out)
    =/  w=sem:sem-lib  n(body `body.i.as, at (sspan-of:tp body.i.as))
    $(as t.as, out [[name.i.as w ctx.i.as] out])
  ?.  ?=(%apply -.n)  ~[[nm n ctx]]
  =/  op  name.op.n
  ::  operator inlining is BOUNDED by the environment's `fuel`, the same
  ::  counter `+solve` spends on the same recursion. tlc2 needs no explicit
  ::  bound because `getActionsAppl` wraps its descent in
  ::  `catch (Throwable e) { /*SKIP*/ }` and a self-referential action operator
  ::  simply overflows the Java stack into the leaf-action fallback; Hoon has
  ::  no such catch, so the fallback has to be reached by counting. Exhausting
  ::  the fuel yields exactly that fallback -- the single leaf action
  ?:  =(0 fuel.e)  ~[[nm n ctx]]
  ?:  ?&(?=(%user-op kind.op.n) ?=(~ args.n))
    =/  d  (~(get by defs) op)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  ~[[nm n ctx]]
    $(n u.body.u.d, nm op, e e(fuel (dec fuel.e)))
  ::  an APPLIED user operator whose arguments are all CONSTANT-level is
  ::  inlined too, renaming the action to the operator (`Tool.getActionsAppl`,
  ::  the `opcode == 0` branch: it evaluates each argument against
  ::  `TLCState.Empty`, conses it onto the context, and recurses into
  ::  `opDef.getBody()` with `opDef` as the action name). This is what makes
  ::  `(\E i \in 1..2 : Bump(i)) \/ Yup` report and label as `Bump`/`Yup`
  ::  rather than twice as `Next` -- measured at the pin, whose coverage line
  ::  is `<Bump line 5, col 1 to line 5, col 7>` (R2.7.4.2b).
  ::
  ::  A state-level argument stops the recursion, exactly as tlc2's
  ::  `argLevel != 0` break does, and so does any failure to evaluate one --
  ::  tlc2 wraps the whole attempt in `catch (Throwable e) { /*SKIP*/ }` and
  ::  falls back to the single leaf action
  ?:  ?&(?=(%user-op kind.op.n) ?=(^ args.n))
    =/  d  (~(get by defs) op)
    ?:  ?|(?=(~ d) ?=(~ body.u.d))  ~[[nm n ctx]]
    ?.  =(arity.u.d (lent args.n))  ~[[nm n ctx]]
    ?.  =(0 (max-lvl args.n))  ~[[nm n ctx]]
    =/  bd  (bind-args args.n params.u.d e ctx)
    ?~  bd  ~[[nm n ctx]]
    $(n u.body.u.d, nm op, e e.u.bd(fuel (dec fuel.e)), ctx ctx.u.bd)
  ?:  |(=(op '$DisjList') =(op '\\lor'))
    (get-actions-list args.n nm defs e ctx)
  ::  `\E i \in S : body` -- tlc2's getActions ENUMERATES S against
  ::  `TLCState.Empty` and recurses into args[0] once per element, carrying the
  ::  binding in the element's Context (Tool.getActionsAppl OPCODE_be), so each
  ::  resulting action carries the BODY's span, not the whole quantifier's.
  ::
  ::  R1.5.12 kept ONE action here and recorded that one-vs-N "no port surface
  ::  can distinguish". R2.4.6 MEASURED otherwise: in SIMULATION the action
  ::  COUNT is the divisor of the action-index draw and the successor count is
  ::  the divisor of the successor-pick draw, so N actions of one successor and
  ::  one action of N successors spend the same draws to different ends --
  ::  `\E n \in 1..3 : x' = x + n` diverged from `tlc2 -simulate` on every seed
  ::  tried, and reported 25 states generated where tlc2 reported 14.
  ::
  ::  The FALLBACK is tlc2's own: `getActionsAppl` wraps the enumeration in a
  ::  `try`, and an empty domain (`Enum.isDone()`) or any throw (a bound that
  ::  needs a state, a non-enumerable bound) leaves exactly the single
  ::  whole-quantifier action this arm used to return unconditionally
  ?:  =(op '$BoundedExists')
    ?~  args.n  ~[[nm n ctx]]
    =/  fb=(list act)
      ?.  ?=(%apply -.i.args.n)  ~[[nm n ctx]]
      ~[[nm n(at at.i.args.n) ctx]]
    =/  bs  (flatten-bound:ne bound.n)
    ?.  ?=([* ~] bs)  fb
    =/  sd  (eval-domain:ne rng.i.bs e(s0 ~, s1 ~, primed |))
    ?:  ?=(%| -.sd)  fb
    =/  els  (drain-sexp:ne p.sd)
    ?:  ?=(%| -.els)  fb
    ?~  p.els  fb
    ::  EXPLICIT loop: a wet `turn` over the recursive `value`/`sem` molds
    ::  fuse-loops the zuse-408 compiler here (the R2.4.2 trap)
    =/  xs=(list value)  p.els
    =|  out=(list act)
    |-  ^-  (list act)
    ?~  xs  out
    =/  e2  (bind-group:ne e i.bs i.xs)
    =/  c2  (ctx-bind ctx i.bs i.xs)
    $(xs t.xs, out (weld out (get-actions-in i.args.n nm defs e2 c2)))
  ~[[nm n ctx]]
::
++  ctx-bind
  ::  +bind-group on a bare context map: bind ONE binder group to ONE domain
  ::  element, destructuring a tuple group across its names
  |=  [ctx=(map @t value) g=bgroup:ne w=value]
  ^-  (map @t value)
  ?.  tup.g
    ?~(nms.g ctx (~(put by ctx) i.nms.g w))
  ?.  ?=(%seq -.w)  ctx
  =/  ns  nms.g
  =/  vs  p.w
  |-  ^-  (map @t value)
  ?~  ns  ctx
  ?~  vs  ctx
  $(ns t.ns, vs t.vs, ctx (~(put by ctx) i.ns i.vs))
::
++  bind-args
  ::  bind an applied operator's CONSTANT arguments to its formals, in both the
  ::  evaluation environment and the action's carried context -- the
  ::  `con1 = con1.cons(formals[i], aval)` loop of `Tool.getActionsAppl`.
  ::  `~` when any argument fails to evaluate, which is tlc2's `catch`
  ::  fallback to the single leaf action (R2.7.4.2b)
  |=  $:  args=(list sem:sem-lib)  ps=(list spar:sem-lib)
          e=eenv:ne  ctx=(map @t value)
      ==
  ^-  (unit [e=eenv:ne ctx=(map @t value)])
  ::  EXPLICIT loop: a wet `turn`/`zip` over the recursive `sem`/`value` molds
  ::  fuse-loops the zuse-408 compiler here (the R2.4.2 trap)
  =/  as  args
  =/  fs  ps
  |-  ^-  (unit [e=eenv:ne ctx=(map @t value)])
  ?~  as  `[e ctx]
  ?~  fs  ~
  ::  the argument is evaluated against the EMPTY state, as tlc2 does
  ::  (`this.eval(args[i], con, TLCState.Empty, cm)`)
  =/  av  (eval:ne i.as e(s0 ~, s1 ~, primed |))
  ?:  ?=(%| -.av)  ~
  %=  $
    as   t.as
    fs   t.fs
    e    e(vals (~(put by vals.e) name.i.fs p.av))
    ctx  (~(put by ctx) name.i.fs p.av)
  ==
::
++  act-env
  ::  an action's evaluation environment: the run's env plus the bindings the
  ::  getActions decomposition bound into that action (R2.4.6)
  |=  [e=eenv:ne ctx=(map @t value)]
  ^-  eenv:ne
  ?:  =(~ ctx)  e
  e(vals (~(uni by vals.e) ctx))
::
++  get-actions-list
  |=  $:  l=(list sem:sem-lib)  nm=@t  defs=(map @t sem-def:sem-lib)
          e=eenv:ne  ctx=(map @t value)
      ==
  ^-  (list act)
  ?~  l  ~
  (weld (get-actions-in i.l nm defs e ctx) $(l t.l))
::
++  action-label
  ::  `<name line BL, col BC to line EL, col EC of module M>`
  |=  [nm=@t sp=(unit span) modn=@t]
  ^-  @t
  ?~  sp  (crip "<{(trip nm)}>")
  =*  s  u.sp
  %-  crip
  ;:  weld
    "<"  (trip nm)  " line "  (a-tape line.from.s)  ", col "  (a-tape col.from.s)
    " to line "  (a-tape line.to.s)  ", col "  (a-tape col.to.s)
    " of module "  (trip modn)  ">"
  ==
::
++  edge-action-label
  ::  the label of the action that generates state `s1fp` from `s0`: the first
  ::  getActions leaf whose next-state relation reaches that fingerprint
  |=  $:  s0=state  s1fp=@t
          actions=(list act)
          e=eenv:ne  order=(list @t)  modn=@t
      ==
  ^-  @t
  ?~  actions  '<unknown action>'
  =/  r  (next-states:ne s0 body.i.actions (act-env e ctx.i.actions))
  ?:  ?=(%| -.r)  $(actions t.actions)
  ?:  (lien p.r |=(st=state =(s1fp (@t (state-fp:fp order st)))))
    =/  nm  (cat 3 name.i.actions (act-sig i.actions e))
    (action-label nm (sem-span:config body.i.actions) modn)
  $(actions t.actions)
::
++  act-sig
  ::  R4.2n: tlc2 `Action.getLocation` prints the action operator's FORMAL
  ::  PARAMETERS bound in its context, `Inc(1)` or `Op(1,"a")` (joined by `,`
  ::  with no space, each value's `toString`), and nothing when there are none.
  ::  A trace through a parametrized action was labelled `Inc` here. (The
  ::  coverage block's labels carry no arguments at the pin, and use their
  ::  own arm.)
  |=  [a=act e=eenv:ne]
  ^-  @t
  =/  d  (~(get by ops.e) name.a)
  ?~  d  ''
  =/  vs=(list tape)
    %+  murn  params.u.d
    |=  p=spar:sem-lib
    ^-  (unit tape)
    =/  v  (~(get by ctx.a) name.p)
    ?~(v ~ `(render:vl u.v))
  ?~  vs  ''
  =/  out=tape  i.vs
  =/  rest  t.vs
  |-  ^-  @t
  ?~  rest  (crip :(weld "(" out ")"))
  $(out :(weld out "," i.rest), rest t.rest)
::
++  edge-action
  ::  the STRUCTURED form of +edge-action-label: the action that generates
  ::  `s1fp` from `s0` as [name span], for the wire trace's per-state `action`
  ::  field (the rendered text form is what the report artifact prints).
  ::  ~ when no action matches. R1.5.12b
  |=  $:  s0=state  s1fp=@t
          actions=(list act)
          e=eenv:ne  order=(list @t)  modn=@t
      ==
  ^-  (unit [name=@t at=(unit loc)])
  ?~  actions  ~
  =/  r  (next-states:ne s0 body.i.actions (act-env e ctx.i.actions))
  ?:  ?=(%| -.r)  $(actions t.actions)
  ?:  (lien p.r |=(st=state =(s1fp (@t (state-fp:fp order st)))))
    =/  sp  (sem-span:config body.i.actions)
    `[name.i.actions ?~(sp ~ `[modn u.sp])]
  $(actions t.actions)
::
++  ce-state-rec
  ::  R2.7.14b: `TLCStateInfo.toRecordValue()` -- a trace state as a RECORD of
  ::  its variable bindings, in declaration order (`+normalize` sorts by field
  ::  name, which is what value equality here depends on)
  |=  [order=(list @t) st=state]
  ^-  value
  %-  normalize:vl
  :-  %rec
  %+  murn  order
  |=  v=@t
  ^-  (unit vfield:vl)
  =/  x  (~(get by st) v)
  ?~(x ~ `[v u.x])
::
++  ce-loc-rec
  ::  the `location` field of an action record: `RecordValue(Location)` --
  ::  beginLine / beginColumn / endLine / endColumn / module
  |=  at=(unit loc)
  ^-  value
  ?~  at  (normalize:vl [%rec ~])
  =*  sp  span.u.at
  %-  normalize:vl
  :-  %rec
  :~  ['beginLine' [%int (new:si & line.from.sp)]]
      ['beginColumn' [%int (new:si & col.from.sp)]]
      ['endLine' [%int (new:si & line.to.sp)]]
      ['endColumn' [%int (new:si & col.to.sp)]]
      ['module' [%str src.u.at]]
  ==
::
++  ce-action-rec
  ::  `RecordValue(Action)` -- `[name |-> .., location |-> ..]`. tlc2 adds
  ::  `context`/`parameters` when the action TAKES parameters; no corpus case
  ::  has one, so those two fields are UNMEASURED and deliberately absent
  ::  rather than guessed (the `_LAZYSET` discipline)
  |=  a=(unit [name=@t at=(unit loc)])
  ^-  value
  ?~  a  (normalize:vl [%rec ~[['name' [%str '']] ['location' (ce-loc-rec ~)]]])
  %-  normalize:vl
  :-  %rec
  :~  ['name' [%str name.u.a]]
      ['location' (ce-loc-rec at.u.a)]
  ==
::
++  counter-example-value
  ::  R2.7.14b: `TLCExt!CounterExample` -- the counter-example the run just
  ::  produced, as tlc2's `CounterExample` RecordValue:
  ::
  ::    [ state  |-> { <<n, [vars]>> : n \in 1..Len(trace) },
  ::      action |-> { <<from, actionRec, to>> } ]
  ::
  ::  `loop` is tlc2's `loopOrdinal`, 1-based: **0 means no closing edge**.
  ::  That is not a detail — it is the difference between the two liveness
  ::  call sites, and both corpus fixtures depend on it:
  ::
  ::    LiveCheck   `new CounterExample(states)`                 loopOrdinal 0
  ::                the safety-LIKE violation ("treat it as a lasso where the
  ::                last state stutters forever") -- `gh1389-counting`, whose
  ::                POSTCONDITION asserts 10 states and **9** actions
  ::    LiveWorker  `new CounterExample(states, action, stateNumber)`
  ::                the genuine lasso, closing edge appended -- `gh1389-violc`,
  ::                whose POSTCONDITION asserts 2 states and **2** actions and
  ::                names both endpoints of the back edge
  ::
  ::  The port already computes that discriminator: a counter-example with NO
  ::  closer is exactly `+box-free-tf`'s, which is R2.7.11a's rule seen from
  ::  the other side. A safety trace passes `loop` 0 for the same reason.
  |=  $:  sts=(list state)  order=(list @t)
          actions=(list act)  e=eenv:ne  modn=@t
          loop=@ud
      ==
  ^-  value
  =/  n  (lent sts)
  ::  the numbered state tuples, `<<i, rec>>`
  =/  tups=(list value)
    =/  i=@ud  1
    =/  l  sts
    |-  ^-  (list value)
    ?~  l  ~
    [[%seq ~[[%int (new:si & i)] (ce-state-rec order i.l)]] $(l t.l, i +(i))]
  ::  the forward edges: state i -> state i+1, labelled with the action that
  ::  generated i+1 (`+edge-action`, the same resolution the trace labels use)
  =/  fwd=(list value)
    =/  i=@ud  1
    =/  l  sts
    |-  ^-  (list value)
    ?~  l  ~
    ?~  t.l  ~
    =/  a
      %:  edge-action
        i.l  (@t (state-fp:fp order i.t.l))  actions  e  order  modn
      ==
    :-  :-  %seq
        :~  (snag (dec i) tups)
            (ce-action-rec a)
            (snag i tups)
        ==
    $(l t.l, i +(i))
  ::  the closing edge, when the lasso has one: last -> sts[loop]
  =/  back=(list value)
    ?:  |(=(0 loop) =(0 n))  ~
    =/  last  (rear sts)
    =/  a
      %:  edge-action
        last  (@t (state-fp:fp order (snag (dec loop) sts)))  actions  e  order  modn
      ==
    :_  ~
    :-  %seq
    :~  (snag (dec n) tups)
        (ce-action-rec a)
        (snag (dec loop) tups)
    ==
  %-  normalize:vl
  :-  %rec
  :~  ['action' (normalize:vl [%set %set-enum (weld fwd back)])]
      ['state' (normalize:vl [%set %set-enum tups])]
  ==
::
++  fp-hex
  ::  a state fingerprint as TLC prints it: "0x" + lowercase hex, no separators
  |=  fp=@t
  ^-  tape
  (weld "0x" (skip (slag 2 (scow %ux `@ux`fp)) |=(c=@tD =('.' c))))
::
++  raw-live-oss
  ::  the normalized oos via the raw path (parse/generate/resolve-targets/
  ::  normalize, skipping search-ctx's symmetry-with-temporal rejection so the
  ::  symmetry-live corpus case is still exercised); the module name is returned
  ::  for the structural rendering
  |=  [spec=@t cfg=@t]
  ^-  (each [modn=@t oss=(list oos:tp)] @t)
  =/  pr  (parse:syntax spec)
  ?:  ?=(%| -.pr)  [%| 'parse error']
  =/  tree  p.pr
  =/  cr  (parse-cfg:config cfg)
  ?:  ?=(%| -.cr)  [%| 'config']
  =/  ca  p.cr
  =/  modn  (module-name-of tree)
  =/  mo  (generate:sem-lib modn (malt ~[[modn spec]]))
  ?~  mo  [%| 'semantic error']
  =/  defs  (apply-overrides (defmap-of:ne u.mo) overrides.ca mod-overrides.ca)
  ::  the raw oos path needs no subscript warning -- it renders the temporal
  ::  decomposition, never a verdict
  =/  rt  (resolve-targets [init.ca next.ca spec.ca] defs ~)
  ?:  ?=(%| -.rt)  [%| p.rt]
  =/  pbods=(list sem:sem-lib)
    =/  ps  properties.ca
    |-  ^-  (list sem:sem-lib)
    ?~  ps  ~
    =/  b  (sem-body defs i.ps)
    ?~  b  $(ps t.ps)
    [u.b $(ps t.ps)]
  =/  env  (make-env:ne defs (const-map cfg) (var-names tree))
  =/  or  (normalize:tp pbods modn fair.p.rt env)
  ?:  ?=(%| -.or)  [%| msg.p.or]
  [%& modn p.or]
::
++  live-struct-raw
  ::  the count projection via the raw path (see +raw-live-oss)
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  or  (raw-live-oss spec cfg)
  ?:  ?=(%| -.or)  ~[(cat 3 'Error: ' p.or)]
  (render-counts:tp oss.p.or)
::
++  live-struct-full-raw
  ::  the full structural projection via the raw path (see +raw-live-oss)
  |=  [spec=@t cfg=@t]
  ^-  wain
  =/  or  (raw-live-oss spec cfg)
  ?:  ?=(%| -.or)  ~[(cat 3 'Error: ' p.or)]
  (render-struct:tp oss.p.or modn.p.or (live-tabs oss.p.or modn.p.or))
::
++  check
  ::  model-check a spec + config, returning TLC's terminal output lines
  |=  [spec=@t cfg=@t]
  ^-  wain
  (check-in spec cfg | 0)
::
++  check-cov
  ::  `+check` with tlc2's `-coverage` (R2.7.4.2b): the same run, plus the
  ::  coverage block between the completion line and the statistics
  |=  [spec=@t cfg=@t]
  ^-  wain
  (check-in spec cfg & 0)
::
++  check-seed
  ::  `+check` with tlc2's `-seed` (R2.7.4.4). A spec that draws through
  ::  `TLC!RandomElement` is only reproducible with the seed pinned, so the
  ::  differential corpus needs an entry point that supplies one
  |=  [spec=@t cfg=@t seed=@ud]
  ^-  wain
  (check-in spec cfg | seed)
::
++  init-progress
  ::  R4.2n: `DoInitFunctor.addElement` prints EC 2269 `Computed N initial
  ::  states...` before adding a state when the count so far is a power of two
  ::  above 1 -- so for each power of two p with 2 <= p < n. Always ahead of
  ::  any verdict: the initial states are all generated before it
  |=  n=@ud
  ^-  wain
  =/  p  2
  |-  ^-  wain
  ?:  (gte p n)  ~
  :-  (rap 3 ~['Computed ' (crip ((d-co:co 1) p)) ' initial states...'])
  $(p (mul 2 p))
::
++  check-in
  ::  `+check` carrying the coverage flag and the run's `-seed`
  |=  [spec=@t cfg=@t cvg=? seed=@ud]
  ^-  wain
  =/  sc  (search-ctx-seed spec cfg seed)
  ?:  ?=(%| -.sc)  (err-lines p.sc)
  =*  c  p.sc
  =/  ae  (check-assumes asmz.c (make-env:ne defs.c consts.c vars.c) (module-name-of tree.c) ses.c)
  ?^  ae  (snoc aout.c (cat 3 'Error: ' msg.u.ae))
  ::  coverage alongside a temporal PROPERTY is refused BY NAME rather than
  ::  silently dropped: the counters this port collects live on the safety
  ::  search's BFS cursor, and the liveness / implied-init / implied-action
  ::  paths run a different engine over a graph built for a different purpose.
  ::  tlc2 does report coverage there; this port does not, and says so (R2.1)
  ?:  ?&(cvg ?=(^ pp.c))
    ~['unsupported: -coverage with a temporal PROPERTY (the port collects coverage on the safety search only)']
  ::  under a SPECIFICATION the INIT action has no declaration to name -- tlc2
  ::  builds it with a null `opDef`, so `ActionWrapper.printLocation()` falls
  ::  back to `action.toString()` rather than the `<Name location>` form every
  ::  other line uses. Refused by name instead of labelled wrongly (R2.1)
  ?:  ?&(cvg ?=(^ sname.c))
    ~['unsupported: -coverage with a SPECIFICATION (the INIT action has no declaration to label; use INIT/NEXT)']
  ::  SPECIFICATION-decomposition warnings print BEFORE the verdict and do not
  ::  change it — today the EC 2145 subscript-coverage one (R2.3.5). tlc2
  ::  emits them while processing the config, ahead of every run line
  %+  weld  swarn.c
  ::  R4.2a: what `Print`/`PrintT` wrote while the constant definitions, the
  ::  ASSUMEs and the initial states were evaluated, in that order (the pin
  ::  prints at the moment of evaluation). The search's own lines follow from
  ::  `+safety-run`
  %+  weld  (flop out.irs.c)
  ::  R4.2n: EC 2269, printed while the initial states are computed
  %+  weld  (init-progress (lent is.c))
  ::  a temporal PROPERTY: a pure []P box-state is a state invariant, rendered
  ::  through the safety terminal output; every other form runs the 8.2–8.6
  ::  engine and renders tlc2.TLC's temporal console diagnostic (unit 8.9)
  ::  R2.7.15a: EVERY property is binned by `+bin-properties` at `+search-ctx`,
  ::  so this routes the WHOLE list. tlc2's order of precedence, measured:
  ::  an IMPLIED INIT aborts during initial-state computation and prints no
  ::  state-graph counts, so it comes first; then the SAFETY pass, which
  ::  carries the config's INVARIANTs, the box-state properties appended after
  ::  them (`processConfigInvariants()` fills `invVec` first, R2.3.4) and the
  ::  implied actions as a per-transition check; and only if that completes
  ::  clean does the liveness engine report. That is `ModelChecker.doNext`
  ::  returning on a violation, generalized from INVARIANT to every
  ::  safety-side bin
  ::  R2.7.15c: the IMPLIED INITS, all of them. tlc2 checks a level<=1 PROPERTY
  ::  only while computing the INITIAL STATES (`Tool.getImpliedInits`), which is
  ::  why this cannot be folded into the invariant vector -- an invariant is
  ::  checked at every state, and folding would report violations at states
  ::  tlc2 never tests. The EC 2255 state-level warning is emitted for EVERY one
  ::  of them, in config order, whether or not it holds; measured at the pin
  ::  (`prop-init-second`), where the FAILING implied init is declared SECOND
  =/  iwarn  (turn (swarn-names pnames.c defs.c) state-level-warn)
  =/  ilines=(unit wain)
    ?~  iinits.c  ~
    =/  b
      %-  first-bad-init
      [is.c invs.c iinits.c (make-env:ne defs.c consts.c vars.c)]
    ?~  b  ~
    ::  an evaluation error is the RUN's typed failure, not a violation: fall
    ::  through and let the search raise it where every other check does
    ?:  ?=(%| -.u.b)  ~
    :-  ~
    %:  init-viol-lines
      p.u.b  order.c  alias.c  vrend.c  (make-env:ne defs.c consts.c vars.c)
    ==
  ?^  ilines  (weld iwarn u.ilines)
  ::  the implied inits held (or there were none), so the run carries on into
  ::  the rest of the routing exactly as tlc2 does -- which is the second half
  ::  of this fix: the old code went straight to `+safety-run` from here, so a
  ::  box-state property, an implied action or a temporal property declared
  ::  BESIDE an implied init was never checked at all (`prop-init-live`)
  %+  weld  iwarn
  ?:  ?|(?=(^ binvs.c) ?=(^ iacts.c))
    ::  a safety-side property is declared, so the SAFETY pass owns the verdict
    ::  unless it completes clean. When it does AND a temporal property is also
    ::  declared, the run continues into the liveness engine below -- which is
    ::  the case `prop-act-ok` and `prop-box-then-live` pin and the port used
    ::  to miss entirely
    =/  o=bfs-opts
      :*  nsb.c  (weld invs.c binvs.c)  cons.c  acons.c  poss.c
          vars.c  order.c  perms.c  defs.c  consts.c  ddl.c  0  0  view.c  0  |
          ~  *cov-opts  0  iacts.c  !(draws defs.c)  ~
      ==
    =/  actions  (get-actions nsb.c aname.c defs.c (make-env:ne defs.c consts.c vars.c))
    =/  env      (make-env:ne defs.c consts.c vars.c)
    =/  modn     (module-name-of tree.c)
    =/  er       (explore is.c o)
    ?.  ?=(%ok -.out.er)
      (render-outcome out.er nl.c actions env order.c modn alias.c vrend.c | ~ ~ ~)
    ::  clean: fall through to the liveness engine if a temporal property was
    ::  declared too, else report the safety completion
    ?~  props.c
      (render-outcome out.er nl.c actions env order.c modn alias.c vrend.c | ~ ~ ~)
    (live-run c)
  ?~  props.c
    (safety-run c cvg seed)
  (live-run c)
::
++  bin-properties
  ::  R2.7.15a: `SpecProcessor.processConfigProps` -- EVERY declared PROPERTY
  ::  binned on its OWN shape, which is what makes the routing
  ::  ORDER-INDEPENDENT. Measured: `prop-box-viol` and `prop-box-last` declare
  ::  the same two properties in opposite orders and the pin gives the same
  ::  verdict, while the port -- which routed on the HEAD of the list -- gave
  ::  two different ones.
  ::
  ::  R4.2n: and binned PART BY PART. tlc2 first decomposes a property
  ::  (`+prop-parts`) through INSTANCE substitutions, LET, zero-arity
  ::  definitions and conjunctions, and bins each part; the port binned each
  ::  property whole, so `HCini /\ [][HCnxt]_hr` or a refinement `P!Spec`
  ::  (`Init /\ [][Next]_v /\ WF_v(Next)`) reached the liveness converter
  ::  as one formula and was refused there.
  ::
  ::  The four bins, in tlc2's own order of preference:
  ::
  ::    `[]P` with a state-level P  -> the INVARIANT vector (and it is reported
  ::                                   as an `Invariant`, not as a temporal
  ::                                   property -- measured); named for `P`
  ::                                   when `P` is a bare operator name
  ::    level <= 1                  -> an IMPLIED INIT, checked while computing
  ::                                   the initial states
  ::    `[][A]_v`                   -> an IMPLIED ACTION, checked on every
  ::                                   transition
  ::    anything else               -> the liveness engine
  ::
  ::  A name with no definition is DROPPED here, as `+resolve-invs` already
  ::  drops its own -- the config validator owns that diagnostic and reports
  ::  it before any of this runs
  |=  [props=(list @t) defs=(map @t sem-def:sem-lib)]
  ^-  $:  binvs=(list [name=@t body=sem:sem-lib])
          iinits=(list [name=@t body=sem:sem-lib])
          iacts=(list [name=@t body=sem:sem-lib sub=(unit sem:sem-lib)])
          temps=(list [name=@t body=sem:sem-lib])
      ==
  ?~  props  [~ ~ ~ ~]
  =/  rest  $(props t.props)
  =/  b  (sem-body defs i.props)
  ?~  b  rest
  =/  ps  (flop (prop-parts i.props u.b defs))
  |-
  ?~  ps  rest
  =/  nm  name.i.ps
  =/  x   body.i.ps
  =/  ws  ws.i.ps
  ::  R4.2af: `processConfigProps` UNROLLS `\A i \in S : P(i)` over a
  ::  constant S into one part per element, each named by the location of
  ::  `P(i)` (`expr.toString()`) and binned on ITS shape. Every element part
  ::  carries the same name and the same bin, so one part `\A i \in S :
  ::  P'(i)` -- P' the binned form -- is observationally the same (measured:
  ::  `\A i \in {1, 2} : [](x < i + 1)` is `Invariant line 7, col 24 to line
  ::  7, col 36 of module spec is violated`, a safety stop). A part that bins
  ::  as TEMPORAL keeps the whole formula and its property name, as the
  ::  liveness report names the PROPERTY
  =/  fa  (const-forall x)
  ?^  fa
    =/  fb  body.u.fa
    =/  fnm  (loc-str:config mo.i.ps (sspan-of:tp fb))
    =/  wrap  |=(b=sem:sem-lib (rewrap ws (rebound q.u.fa b)))
    =/  fbinner  (box-state-inner:tp fb)
    ?^  fbinner
      =/  bn=@t
        ?.  ?&(?=(%apply -.u.fbinner) ?=(~ args.u.fbinner) ?=(%user-op kind.op.u.fbinner))
          fnm
        name.op.u.fbinner
      $(ps t.ps, binvs.rest [[bn (wrap u.fbinner)] binvs.rest])
    ?:  (lte (sem-lvl:sem-lib fb) 1)
      $(ps t.ps, iinits.rest [[fnm (wrap fb)] iinits.rest])
    =/  fia  (implied-action-parts fb)
    ?^  fia
      =/  ia=[name=@t body=sem:sem-lib sub=(unit sem:sem-lib)]
        :+  fnm  (wrap body.u.fia)
        ?~(sub.u.fia ~ `(rewrap ws u.sub.u.fia))
      $(ps t.ps, iacts.rest [ia iacts.rest])
    $(ps t.ps, temps.rest [[i.props (rewrap ws x)] temps.rest])
  =/  binner  (box-state-inner:tp x)
  ?^  binner
    =/  bn=@t
      ?.  ?&(?=(%apply -.u.binner) ?=(~ args.u.binner) ?=(%user-op kind.op.u.binner))
        nm
      name.op.u.binner
    $(ps t.ps, binvs.rest [[bn (rewrap ws u.binner)] binvs.rest])
  ?:  (lte (sem-lvl:sem-lib x) 1)
    $(ps t.ps, iinits.rest [[nm (rewrap ws x)] iinits.rest])
  =/  iact  (implied-action-parts x)
  ?^  iact
    =/  ia=[name=@t body=sem:sem-lib sub=(unit sem:sem-lib)]
      :+  nm  (rewrap ws body.u.iact)
      ?~(sub.u.iact ~ `(rewrap ws u.sub.u.iact))
    $(ps t.ps, iacts.rest [ia iacts.rest])
  ::  a TEMPORAL part keeps the configured PROPERTY's name: tlc2's
  ::  violation report names the property (`Temporal property Prop was
  ::  violated.` for `Prop == Live`), not the part (measured)
  $(ps t.ps, temps.rest [[i.props (rewrap ws x)] temps.rest])
::
++  prop-parts
  ::  R4.2n: `SpecProcessor.processConfigProps`' structural decomposition of
  ::  one PROPERTY, in source order. Each part is the conjunct, its name, and
  ::  the INSTANCE-substitution / LET wrappers it was found under
  ::  (innermost first), which `+rewrap` puts back so the part evaluates as it
  ::  did inside the whole -- tlc2's `Specs.addSubsts(pred, subs)`. Through:
  ::  a substitution wrapper, a LET, a zero-arity definition (renaming the
  ::  part, as tlc2 does), `/\` (infix and bulleted) and `$Nop`. A
  ::  conjunction member is named by its location (`conj.toString()`, a
  ::  SemanticNode's Location), in the module that defines it -- which is
  ::  why `mo` is threaded: a span carries no module.
  ::  Not ported: tlc2 also unrolls a `\A` over a constant set into per-element
  ::  parts, and inlines a parameterized instance's arguments; such a
  ::  property stays whole here and its parts reach the liveness converter,
  ::  which expands the quantifier itself (`+quant-of:tp`)
  |=  [name=@t s=sem:sem-lib defs=(map @t sem-def:sem-lib)]
  ^-  (list [name=@t body=sem:sem-lib ws=(list sem:sem-lib) mo=@t])
  =|  ws=(list sem:sem-lib)
  =|  seen=(set @t)
  =/  mo=@t
    =/  d  (~(get by defs) name)
    ?~(d '' origin.u.d)
  |-  ^-  (list [name=@t body=sem:sem-lib ws=(list sem:sem-lib) mo=@t])
  ?:  ?=(%letin -.s)
    ?~  body.s  ~[[name s ws mo]]
    $(s u.body.s, ws [s ws])
  ?.  ?=(%apply -.s)  ~[[name s ws mo]]
  ?^  (anysubstin-mod:sem-lib name.op.s)
    =/  sp  (substin-parts:sem-lib s)
    ?~  sp  ~[[name s ws mo]]
    $(s inner.u.sp, ws [s ws], mo mod.u.sp)
  ?:  ?&  ?=(~ args.s)
          ?=(%user-op kind.op.s)
          !(~(has in seen) name.op.s)
      ==
    =/  d  (~(get by defs) name.op.s)
    ?~  d  ~[[name s ws mo]]
    ?~  body.u.d  ~[[name s ws mo]]
    ?.  ?=(~ params.u.d)  ~[[name s ws mo]]
    %=  $
      name  name.op.s
      s     u.body.u.d
      seen  (~(put in seen) name.op.s)
      mo    ?:(=('' origin.u.d) mo origin.u.d)
    ==
  ::  R4.2af: a parameterized operator applied with arguments, outside any
  ::  substitution (`Check(x, 2)`, `SM(42)!Spec`): `processConfigProps` binds
  ::  the formals to the arguments (`getOpContext`, lazily) and recurses into
  ::  the body. The binding rides as a substitution wrapper over the formals,
  ::  which `+bind-substs` evaluates the same lazy way, and `+rewrap` puts it
  ::  back around every part. Only for CONSTANT-level arguments: the body's
  ::  levels were computed with constant formals, so a state-level argument
  ::  (`Check(x, 2)`) would leave a temporal leaf looking constant; such a
  ::  property stays whole, as before
  ?:  ?&  ?=(^ args.s)
          ?=(%user-op kind.op.s)
          ?=(~ ws)
          !(~(has in seen) name.op.s)
          (levy `(list sem:sem-lib)`args.s |=(a=sem:sem-lib =(0 (sem-lvl:sem-lib a))))
      ==
    =/  d  (~(get by defs) name.op.s)
    ?~  d  ~[[name s ws mo]]
    ?~  body.u.d  ~[[name s ws mo]]
    ::  not a recursive operator (`!odn.getInRecursive()`): its body reaches
    ::  its own name
    ?:  (~(has in (reach-names:ne u.body.u.d defs)) name.op.s)  ~[[name s ws mo]]
    ?.  =((lent params.u.d) (lent args.s))  ~[[name s ws mo]]
    ?.  (levy params.u.d |=(p=spar:sem-lib =(0 arity.p)))  ~[[name s ws mo]]
    =/  om  ?:(=('' origin.u.d) mo origin.u.d)
    =/  w=sem:sem-lib
      :*  %apply  [(cat 3 '$SubstIn:' om) %builtin]  lvl.s  at.s
          (turn params.u.d |=(p=spar:sem-lib `sbind:sem-lib`[name.p | ~]))
          ~
          (snoc args.s u.body.u.d)
      ==
    %=  $
      name  name.op.s
      s     u.body.u.d
      ws    [w ws]
      seen  (~(put in seen) name.op.s)
      mo    om
    ==
  ?:  =('$Nop' (end [3 4] name.op.s))
    ?~  args.s  ~[[name s ws mo]]
    $(s i.args.s)
  ?.  |(=('$ConjList' name.op.s) =('\\land' name.op.s))
    ~[[name s ws mo]]
  =/  as=(list sem:sem-lib)  args.s
  =|  out=(list [name=@t body=sem:sem-lib ws=(list sem:sem-lib) mo=@t])
  |-  ^-  (list [name=@t body=sem:sem-lib ws=(list sem:sem-lib) mo=@t])
  ?~  as  out
  =/  nm  (loc-str:config mo (sspan-of:tp i.as))
  $(as t.as, out (weld out ^$(s i.as, name nm)))
::
++  const-forall
  ::  R4.2af: `\A i \in S : P` whose domains are constant-level -- the shape
  ::  `processConfigProps` unrolls (`opDefEvaluator.contexts` succeeds)
  |=  s=sem:sem-lib
  ^-  (unit [q=sem-apply:sem-lib body=sem:sem-lib])
  ?.  ?=(%apply -.s)  ~
  ?.  =('$BoundedForall' name.op.s)  ~
  ?.  ?=([* ~] args.s)  ~
  ?~  bound.s  ~
  ?.  %+  levy  `(list sem-bound:sem-lib)`bound.s
      |=  b=sem-bound:sem-lib
      ?~(range.b | =(0 (sem-lvl:sem-lib u.range.b)))
    ~
  `[s i.args.s]
::
++  rebound
  ::  the quantifier `q` around a new body
  |=  [q=sem-apply:sem-lib b=sem:sem-lib]
  ^-  sem:sem-lib
  q(args ~[b], lvl (sem-lvl:sem-lib b))
::
++  rewrap
  ::  put a part back under the wrappers it was found in (innermost first);
  ::  each wrapper takes the part's own level, so a part binned as an
  ::  implied init still reads as state level
  |=  [ws=(list sem:sem-lib) x=sem:sem-lib]
  ^-  sem:sem-lib
  ?~  ws  x
  =/  w  i.ws
  =/  lv  (sem-lvl:sem-lib x)
  =/  y=sem:sem-lib
    ?:  ?=(%letin -.w)  w(body `x, lvl lv)
    ?.  ?=(%apply -.w)  x
    w(args (snoc (scag (lent ubound.w) `(list sem:sem-lib)`args.w) x), lvl lv)
  $(ws t.ws, x y)
::
++  swarn-names
  ::  EC 2255's subjects: tlc2 warns for a PROPERTY whose DEFINITION is state
  ::  level, once per property, before any decomposition -- so a state-level
  ::  part of a temporal property (a spec's `Init`) draws no warning
  |=  [props=(list @t) defs=(map @t sem-def:sem-lib)]
  ^-  (list @t)
  %+  skim  props
  |=  p=@t
  =/  b  (sem-body defs p)
  ?~(b | (lte (sem-lvl:sem-lib u.b) 1))
::
++  implied-temporals
  ::  R2.7.12: `Tool.getImpliedTemporals()` -- the PROPERTY parts that reach
  ::  the liveness engine, with their bodies, in declaration order: the
  ::  temporal bin of `+bin-properties`, which is what post-hoc attribution
  ::  asks about (`+violated-props`)
  |=  [props=(list @t) defs=(map @t sem-def:sem-lib)]
  ^-  (list [name=@t body=sem:sem-lib])
  temps:(bin-properties props defs)
::
++  implied-action-parts
  ::  R2.7.15b: BOTH halves of a `[][A]_v` implied action -- the action AND its
  ::  SUBSCRIPT. `+implied-action-inner` returns only `A`, and every consumer
  ::  (the retired `+first-bad-step`, DFID's `+first-bad-action`) checked `A`
  ::  alone, which reports a violation on a STUTTERING step that tlc2 permits:
  ::  `[A]_v` is `A \/ UNCHANGED v`, so a step leaving `v` alone satisfies it
  ::  whatever `A` says. Measured at the pin on `[][x' = x + 1]_x` with a
  ::  `x' = x` disjunct in Next -- BFS and DFID both complete clean, and the
  ::  port reported `Action property ActOk is violated.` on both
  ::  The SUBSCRIPT is OPTIONAL in the graph. `+decompose-spec` guards it the
  ::  same way (`?~(t.args.arg ~ (subscript-vars ...))`), so a `[A]_v` whose
  ::  `v` did not survive generation is a shape this side already sees
  |=  s=sem:sem-lib
  ^-  (unit [body=sem:sem-lib sub=(unit sem:sem-lib)])
  ?.  ?=(%apply -.s)  ~
  ?.  =('[]' name.op.s)  ~
  ?~  args.s  ~
  =/  a  i.args.s
  ?.  ?=(%apply -.a)  ~
  ?.  =('$SquareAct' name.op.a)  ~
  ?~  args.a  ~
  `[i.args.a ?~(t.args.a ~ `i.t.args.a)]
::
++  implied-action-inner
  ::  the A of a `[][A]_v` implied-action property — a box over a square-action
  ::  (SpecProcessor routes these to the implied-action list, checked on every
  ::  transition rather than by the liveness engine). ~ if not that shape
  |=  s=sem:sem-lib
  ^-  (unit sem:sem-lib)
  ?.  ?=(%apply -.s)  ~
  ?.  =('[]' name.op.s)  ~
  ?~  args.s  ~
  =/  a  i.args.s
  ?.  ?=(%apply -.a)  ~
  ?.  =('$SquareAct' name.op.a)  ~
  ?~(args.a ~ `i.args.a)
::
++  state-level-warn
  ::  EC 2255 TLC_LIVE_FORMULA_STATE_LEVEL: tlc2 always warns that a state-level
  ::  PROPERTY is only checked in the initial state -- before the verdict, and
  ::  whether or not the property holds
  |=  pname=@t
  ^-  @t
  %-  crip
  ;:  weld
    "Warning: The formula {(trip pname)} is a state-level formula, but it "
    "was used as a PROPERTY (or PROPERTIES), where a temporal formula is "
    "typically expected. State-level formulas used as PROPERTY or PROPERTIES "
    "are only checked in the initial state. To verify that the formula "
    "{(trip pname)} holds in all states of every behavior, use INVARIANT "
    "{(trip pname)} instead. Alternatively, applying the \"always\" temporal "
    "operator ([]) to the state-level formula {(trip pname)} changes it into "
    "a temporal formula, asserting that {(trip pname)} holds in all states "
    "of every behavior. See https://explain.tlapl.us/invariants-and-properties "
    "for additional details."
  ==
::
++  first-bad-init
  ::  R2.7.15c: `ModelChecker.doInit`, and it is STATE-MAJOR -- for each
  ::  initial state every INVARIANT (EC 2107, `:1187`) and only then every
  ::  IMPLIED INIT (EC 2108, `:1199`), so an INVARIANT false on the same
  ::  initial state wins. Measured at the pin by `inv-prop-init`.
  ::
  ::  Shared by all three engines, which is the point of the arm: the console
  ::  renders both codes from it, while `+run-check` and the job kernel act on
  ::  the `%prop` half only and leave the `%inv` half to their own search,
  ::  which reaches the same state and reports it with its own counts.
  ::
  ::  An evaluation error comes back `%|` and is NOT read as a violation --
  ::  `+first-violated`'s rule. Every caller falls through to the engine, which
  ::  raises it as the run's own typed failure rather than naming a property
  |=  $:  is=(list state)
          invs=(list [name=@t body=sem:sem-lib])
          iinits=(list [name=@t body=sem:sem-lib])
          e=eenv:ne
      ==
  ^-  (unit (each [kind=?(%inv %prop) name=@t st=state] @t))
  ?~  is  ~
  =/  iv  (first-violated invs i.is e)
  ?^  iv
    ?:  ?=(%| -.u.iv)  `[%| p.u.iv]
    `[%& %inv p.u.iv i.is]
  =/  ip  (first-violated iinits i.is e)
  ?~  ip  $(is t.is)
  ?:  ?=(%| -.u.ip)  `[%| p.u.ip]
  `[%& %prop p.u.ip i.is]
::
++  init-viol-lines
  ::  the console lines for an initial-state violation: the offending state and
  ::  NO state-graph counts, because tlc2 aborts while computing the initial
  ::  states and never reports any (measured, R1.8.1.1). EC 2107 for an
  ::  INVARIANT, EC 2108 for an IMPLIED INIT -- and EC 2108 is built from
  ::  `evalAlias(curState, curState)` exactly as EC 2107 is
  ::  (`ModelChecker.java:1199`), so an ALIAS renders this state too (R2.3.2)
  ::  the arguments are EXPLICIT rather than an `sctx` because the job kernel
  ::  calls this too and never builds one (R2.7.15c)
  |=  $:  bad=[kind=?(%inv %prop) name=@t st=state]
          order=(list @t)
          al=(unit sem:sem-lib)
          vr=(unit sem:sem-lib)
          e=eenv:ne
      ==
  ^-  wain
  =/  shown=[order=(list @t) st=state]
    ?~  al  [order st.bad]
    (alias-state u.al e st.bad st.bad)
  =/  head=@t
    ?:  ?=(%inv kind.bad)
      (crip "Error: Invariant {(trip name.bad)} is violated by the initial state:")
    (crip "Error: Property {(trip name.bad)} is violated by the initial state:")
  :-  head
  (render-state order.shown st.shown vr e ~)
::
::  R2.7.15c RETIRED `+implied-init-run`.
::
::  It took ONE name and ONE body -- the HEAD of the implied-init bin --
::  emitted one EC 2255 warning, checked one property, and on a clean
::  answer went straight to `+safety-run`. Both halves were wrong:
::  tlc2 warns about and checks EVERY state-level PROPERTY (measured,
::  `prop-init-second`), and a run whose implied inits hold carries on
::  into the WHOLE of the rest of the routing, not into a bare safety
::  search (`prop-init-live`). The check is `+first-bad-init` now, the
::  rendering `+init-viol-lines`, and the routing lives in `+check-in`
::  where the other three bins are routed.
::
::  R2.7.15a RETIRED `+implied-action-run` and `+first-bad-step`.
::
::  They built the WHOLE reachability graph and then scanned it for the
::  first bad step, which got the verdict and the trace right and the
::  COUNTS wrong -- a completed search's, where tlc2 stops at the
::  violation. Implied actions are now a per-transition check on
::  `bfs-opts.iacts`, beside the action CONSTRAINTS and at the same hook,
::  which is where tlc2 has them; `+first-bad-action` (R2.5's, shared
::  with DFID) is the predicate.
::
++  cov-of
  ::  the coverage inputs a `sctx` already carries: the module name for the
  ::  labels, the INIT operator's name and its two counts (`irej` comes off the
  ::  R2.7.4.1a carrier in `+search-ctx`), and the constraint names
  |=  [c=sctx on=?]
  ^-  cov-opts
  :*  on  (module-name-of tree.c)  iname.c  [(lent is.c) irej.c]
      cnames.c  anames.c
  ==
::
++  live-run
  ::  R2.7.15a: the LIVENESS path, extracted from `+check` unchanged so the
  ::  routing above can reach it from two places -- directly, and after a
  ::  safety pass that completed clean (a spec declaring BOTH a box-state or
  ::  implied-action property AND a temporal one, which the port used to
  ::  route to one bin and never check the other)
  |=  c=sctx
  ^-  wain
  ::  `pp` is only the FALLBACK name now (R2.7.12): which property a
  ::  counter-example violates is decided post-hoc over `props`
  =/  pname  ?~(pp.c '' u.pp.c)
  ::  R1.8.1.1: use the OrderOfSolutions `search-ctx` already built, which
  ::  includes the fairness conjuncts `decompose-spec` extracted from the
  ::  SPECIFICATION. Rebuilding it here with `~` for fairness — as this did —
  ::  silently discarded every WF_/SF_ the SPEC declared, so a fair spec had a
  ::  stuttering counterexample and EVERY liveness property reported violated.
  ::  `live-verdict-lines` used `oss.c` and got these same specs right, which
  ::  is why the differential passed while production did not.
  ::  the temporal graph build is bounded (R1.5.5) so `check:check` never hangs
  ::  on a large/looping state space; a capped build renders %limited.
  ::  It also PRUNES with the model CONSTRAINT / ACTION_CONSTRAINT, as every
  ::  liveness graph build here does: tlc2 drops a constrained state before it
  ::  is enqueued, so liveness runs over the constrained graph, and a spec
  ::  whose state space is finite only under its constraint (test-model's
  ::  `LivenessConstraintWarning`: `history' = history \o <<pc>>` bounded by
  ::  `Len(history) < 3`) grew without bound here until R1.8.1.4 passed them.
  ::  DEADLOCK CHECKING IS ON here (R1.6.6). tlc2 reaches a deadlock in the
  ::  state search and aborts the run, so the final liveness check never runs:
  ::  `Github710d`/`Github710e` report `Deadlock reached`, not the temporal
  ::  violation the port used to report over the same state count.
  ::  ALIAS is live on the temporal path too (R4.2i): the lasso's prefix
  ::  states render through it (`+live-prefix-lines`), as `LiveWorker` does
  ::  R2.3.4: the graph build carries the config's INVARIANTs. It used to
  ::  pass `~`, so an INVARIANT alongside a temporal PROPERTY was simply not
  ::  checked -- which is why the kernel refused the combination rather than
  ::  running it. `+bfs-step` already checks `invs` and stops at the first
  ::  violation, so no new checking machinery was needed here, only the list
  =/  o=bfs-opts
    [nsb.c invs.c cons.c acons.c ~ vars.c order.c perms.c defs.c consts.c ddl.c live-graph-cap 0 view.c 0 | ~ *cov-opts 0 ~ | ~]
  =/  bg    (build-graph-out is.c o)
  =/  modn  (module-name-of tree.c)
  ?:  capped.bg
    :-  'Model checking stopped: state limit reached.'
    (counts-lines gen.g.bg distinct.g.bg 0 depth.g.bg)
  ::  an INVARIANT violation, a deadlock, or a typed evaluation failure is
  ::  the state search's own verdict and pre-empts the liveness report,
  ::  exactly as it pre-empts tlc2's final check: `ModelChecker.doNext`
  ::  returns on the violation and `modelCheck` never reaches the temporal
  ::  pass. Measured at the pin -- `INVARIANT Tight` + `PROPERTY Live` prints
  ::  the safety trace and counts, and NO temporal verdict (R2.3.4)
  ?:  ?=(?(%inv %deadlock %error) -.out.bg)
    ::  R2.7.5: the safety verdict still comes first, but it no longer ENDS
    ::  the report -- `+post-error-live` appends tlc2's second block when the
    ::  queue was empty at the error and the property is box-free. `~`
    ::  otherwise, which is R1.6.6's behaviour unchanged
    =/  post=wain
      %-  post-error-live
      :*  out.bg  oss.c  (states-of seen.g.bg)  inits.g.bg  nsb.c
          (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
          order.c  modn  defs.c
          pname  props.c  aname.c  alias.c
      ==
    ::  R2.7.7.3: the postconditions run here too -- measured, they run
    ::  after a VIOLATION as well as on a clean run
    =/  bst  (out-stats out.bg)
    =/  pcl=wain
      ?:  ?=(%error -.out.bg)  ~
      %:  post-cond-lines
        pcs.c
        defs.c
        %+  with-run:ne  (make-env:ne defs.c consts.c vars.c)
        [| 0 `[depth.bst distinct.bst queued.bst gen.bst]]
        modn
        rs.bg
        poss.c
      ==
    %-  render-outcome
    :*  out.bg  nl.c  (get-actions nsb.c aname.c defs.c (make-env:ne defs.c consts.c vars.c))
        (make-env:ne defs.c consts.c vars.c)  order.c  modn  alias.c  vrend.c  |
        ~  post  pcl
    ==
  ::  R2.7.14a: the POSTCONDITION runs here too -- measured at the pin, a
  ::  temporal violation is followed by `Error: Postcondition <name> at
  ::  <loc> is false.` before the counts. R2.7.7.3 wired the clean and
  ::  safety-error paths and this one was simply absent. R2.7.14b moved the
  ::  BUILD into `+live-report`, which is where the lasso `CounterExample`
  ::  binds to already exists
  =/  r
    %-  live-report
    :*  oss.c  (states-of seen.g.bg)  inits.g.bg  nsb.c
        (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
        order.c  modn  defs.c  pname
        props.c
        gen.g.bg  distinct.g.bg  depth.g.bg  sname.c  sloc.c  fair.c  aname.c
        pcs.c  rs.bg  poss.c  alias.c
    ==
  report.r
::
++  safety-run
  ::  the plain safety search and its terminal lines. Factored out (R1.8.1.1)
  ::  so an IMPLIED-INIT property that HOLDS can fall through to it: tlc2 checks
  ::  such a property while computing initial states and, if it passes, carries
  ::  on with the ordinary model check.
  ::  `cvg` is tlc2's `-coverage` (R2.7.4.2b): it turns the counters on and
  ::  renders the block between the completion line and the statistics
  |=  [c=sctx cvg=? seed=@ud]
  ^-  wain
  =/  env      (make-env:ne defs.c consts.c vars.c)
  =/  actions  (get-actions nsb.c aname.c defs.c env)
  =/  modn     (module-name-of tree.c)
  ::  the getActions decomposition is passed IN rather than rebuilt per slice
  ::  (R2.7.4.2b) -- this path needs it for the trace labels anyway
  =/  o=bfs-opts
    :*  nsb.c  invs.c  cons.c  acons.c  poss.c  vars.c  order.c  perms.c  defs.c
        consts.c  ddl.c  0  0  view.c  0  |  actions  (cov-of c cvg)  seed  ~
        !(draws defs.c)  cdefs.env
    ==
  =/  r  (explore-full-regs is.c irs.c o)
  ::  R2.7.7.3: the postconditions see the run's FINAL statistics -- that is
  ::  what `TLCGet("distinct")` inside one reads, and reading them before the
  ::  search would answer with the counters standing at zero
  =/  st  (out-stats out.r)
  =/  pcl=wain
    ?:  ?=(%error -.out.r)  ~
    %:  post-cond-lines
      pcs.c
      defs.c
      (with-run:ne env [| 0 `[depth.st distinct.st queued.st gen.st]])
      modn
      rs.cur.r
      poss.c
    ==
  ::  R4.2a: the search's prints (the carrier began with the initial-state
  ::  solve's, which `+check-in` has already written), before the verdict
  =/  sout  out.rs.cur.r
  =/  bp=wain  (flop (scag (sub (lent sout) (lent out.irs.c)) sout))
  %+  weld  bp
  %-  render-outcome
  :*  out.r  nl.c  actions  env  order.c  modn  alias.c  vrend.c  |
      (cov-report o cur.r actions)  ~  pcl
  ==
::
++  render-outcome
  ::  TLC's terminal lines for a safety outcome. `actions`/`e`/`order`/`modn`
  ::  give the getActions per-action trace labels (R1.5.4); pass ~ actions to
  ::  fall back to the single whole-Next label.
  |=  $:  res=outcome  nl=@t
          actions=(list act)
          e=eenv:ne  order=(list @t)  modn=@t
          al=(unit sem:sem-lib)
          ::  `-view` (R2.4.3): the VIEW body when the flag is set, so every
          ::  rendered state prints its VALUE instead of its bindings
          vw=(unit sem:sem-lib)
          ::  `-difftrace` (R2.4.3): print only CHANGED bindings
          dif=?
          ::  the `-coverage` block (R2.7.4.2b), `~` when coverage is off. It
          ::  is placed by outcome rather than by the caller: tlc2 prints it
          ::  between the completion line and the statistics, and a run that
          ::  PRINTS A COUNTEREXAMPLE gets `+cov-refusal` in its place, because
          ::  the pin's counters there include its trace re-solve
          cov=wain
          ::  R2.7.5: the SECOND report block. After a safety error that ends
          ::  the search with an EMPTY queue, tlc2 still reports a violated
          ::  temporal property -- its own block, between the safety trace and
          ::  the statistics. `~` when there is none; see `+post-error-live`
          post=wain
          ::  R2.7.7.3: the POSTCONDITION lines, in the same slot as `post`.
          ::  On a CLEAN run a failing postcondition REPLACES `Model checking
          ::  completed. No error has been found.` -- measured: the pin prints
          ::  the error and the counts, and no completion line
          pcl=wain
      ==
  ^-  wain
  ?-    -.res
      %ok
    ::  `-continue` (R2.4.2): every violation the completed search passed is
    ::  reported FIRST, in discovery order, each as the ordinary EC 2110 block.
    ::  Then the completion line -- which tlc2 prints even here, because it is
    ::  about the SEARCH completing and not about the verdict. Measured at the
    ::  pin: two violations followed by `No error has been found.` and the
    ::  FULL counts, which are the whole graph's rather than the prefix's
    ::  EXPLICIT loop: a wet `turn` over the recursive `state` mold fuse-loops
    ::  the zuse-408 compiler here, the same trap `+render-outcome`'s
    ::  initial-state branch and `+subscript-warns` already record
    =/  vlines=wain
      =/  vs  viols.res
      =|  acc=(list wain)
      |-  ^-  wain
      ?~  vs  (zing (flop acc))
      =/  blk=wain
        ;:  weld
          ~[(crip "Error: Invariant {(trip name.i.vs)} is violated.")]
          ~['Error: The behavior up to this point is:']
          (render-trace trace.i.vs nl actions e order modn al vw dif)
        ==
      $(vs t.vs, acc [blk acc])
    ::  a `-continue` run that PASSED violations printed their traces above, so
    ::  its counters are in the same position as a stopped run's and the block
    ::  is withheld the same way
    =/  blk=wain
      ?~  cov  ~
      ?~(viols.res cov cov-refusal)
    ;:  weld
      vlines
      ?^(pcl pcl ~['Model checking completed. No error has been found.'])
      blk
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      %limited
    ;:  weld
      :_  ~
      ?:  =(%states what.res)
        'Model checking stopped: state limit reached.'
      'Model checking stopped: depth limit reached.'
      cov
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      %inv
    ::  an initial-state violation (EC 2107) prints a distinct message with the
    ::  offending state inline and no statistics summary; a behavior violation
    ::  (EC 2110) prints the numbered trace and the counts (matching TLC)
    ?:  initial.res
      ::  a single offending initial state, rendered inline (a wet `turn` over
      ::  the recursive state mold fuse-loops the zuse-408 compiler). The ALIAS
      ::  applies HERE too (R2.3.2): `ModelChecker.java:1187` builds the EC 2107
      ::  message from `evalAlias(curState, curState)` -- the initial state is
      ::  its own successor, so a primed reference sees no change, exactly as
      ::  the last state of a printed trace does
      ;:  weld
        ~[(crip "Error: Invariant {(trip name.res)} is violated by the initial state:")]
        ?~  trace.res  ~
        =/  shown=[order=(list @t) st=state]
          ?~  al  [order i.trace.res]
          (alias-state u.al e i.trace.res i.trace.res)
        (render-state order.shown st.shown vw e ~)
        ?~(cov ~ cov-refusal)
      ==
    ;:  weld
      ~[(crip "Error: Invariant {(trip name.res)} is violated.")]
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl actions e order modn al vw dif)
      post
      pcl
      ?~(cov ~ cov-refusal)
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      ::  R2.7.15a: EC 2112. Same block shape as an invariant behaviour
      ::  violation -- headline, `The behavior up to this point is:`, the
      ::  trace, the counts -- with tlc2's wording for an implied action, and
      ::  the counts are the ones standing WHERE THE SEARCH STOPPED
      ::  (`prop-act-viol`: 2/2/2, not the completed graph's 5/4/4)
      %action
    ;:  weld
      ~[(crip "Error: Action property {(trip name.res)} is violated.")]
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl actions e order modn al vw dif)
      post
      pcl
      ?~(cov ~ cov-refusal)
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      %deadlock
    ;:  weld
      ~['Error: Deadlock reached.']
      ~['Error: The behavior up to this point is:']
      (render-trace trace.res nl actions e order modn al vw dif)
      post
      pcl
      ?~(cov ~ cov-refusal)
      (counts-lines gen.res distinct.res queued.res depth.res)
    ==
  ::
      %error  ~[(crip "Error: {(trip msg.res)}")]
  ==
::
::  +|  Structured Result (for the Gall job engine, unit 13)
::
::
++  run-check
  ::  run the pipeline on inline source, returning the wire-typed result
  ::  and run statistics. `cap` bounds the distinct-state count so a single
  ::  invocation is bounded; a spec that exceeds it yields %limited.
  |=  [spec=@t cfg=@t cap=@ud]
  ^-  [result run-stats]
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [[%failed p.sc] *run-stats]
  =*  c  p.sc
  =/  ae  (check-assumes asmz.c (make-env:ne defs.c consts.c vars.c) (module-name-of tree.c) ses.c)
  ?^  ae  [[%failed msg.u.ae] *run-stats]
  ::  a temporal property: a pure []P box-state is a state invariant (checked by
  ::  the safety search, unit 8.9); every other form runs the 8.2–8.6 engine
  ::  R2.7.15a: the same binning the console path uses, over EVERY property.
  ::  R2.7.15c: and that now includes the IMPLIED INITS, which this engine used
  ::  to compute and drop. They are checked HERE rather than folded into the
  ::  invariant vector because tlc2 checks them only while computing the
  ::  initial states; the wire shape is `%property` with `initial=&`, the
  ::  variant R2.7.1 added for exactly this code (EC 2108), and the statistics
  ::  are ZERO because a run that aborts during initial-state computation
  ::  reports none -- the same thing the console prints, which is no counts
  ::  at all. An `%inv` answer is left to the search below: it reaches the same
  ::  initial state and reports it with the counters it actually accumulated
  =/  ib=(unit (each [kind=?(%inv %prop) name=@t st=state] @t))
    ?~  iinits.c  ~
    %-  first-bad-init
    [is.c invs.c iinits.c (make-env:ne defs.c consts.c vars.c)]
  ?:  ?=([~ %& %prop *] ib)
    [[%violated [%property name.p.u.ib &] *run-stats] *run-stats]
  =/  o=bfs-opts
    :*  nsb.c  (weld invs.c binvs.c)  cons.c  acons.c  poss.c  vars.c  order.c
        perms.c  defs.c  consts.c  ddl.c  cap  0  view.c  0  |  ~  *cov-opts  0
        iacts.c  !(draws defs.c)  ~
    ==
  =/  er  (explore is.c o)
  ?.  ?=(%ok -.out.er)  (explore-outcome out.er od.er)
  ?~  props.c  (explore-outcome out.er od.er)
  ::  the safety pass completed clean and a temporal property is declared, so
  ::  the liveness engine reports. The temporal graph build is bounded by `cap`
  ::  (R1.5.5): a capped build yields %limited rather than a lasso verdict on a
  ::  partial graph
  =/  lo=bfs-opts
    [nsb.c ~ cons.c acons.c poss.c vars.c order.c perms.c defs.c consts.c | cap 0 view.c 0 | ~ *cov-opts 0 ~ | ~]
  =/  bg  (build-graph-cap is.c lo)
  ::  the liveness graph build samples no out-degree (no BFS frontier)
  =/  st  [gen.g.bg distinct.g.bg 0 depth.g.bg [0 0 0 0]]
  ?:  capped.bg  [[%limited %states st] st]
  =/  l
    %-  find-lasso:lv
    :*  oss.c  (states-of seen.g.bg)  inits.g.bg  nsb.c
        (with-idk:ne (make-env:ne defs.c consts.c vars.c) perms.c view.c)
        order.c
    ==
  ?~  l  [[%ok st] st]
  ::  R2.7.12: the name is the post-hoc attribution's, `pp` only a fallback
  =/  vps  (violated-props props.c u.l (states-of seen.g.bg) (make-env:ne defs.c consts.c vars.c) (module-name-of tree.c))
  =/  vnm  ?^(vps i.vps ?~(pp.c '' u.pp.c))
  [[%violated [%property vnm %.n] st] st]
::
++  explore-outcome
  ::  a safety outcome as the wire result + run-stats (shared by run-check's
  ::  invariant and box-state paths)
  |=  [res=outcome od=out-degree]
  ^-  [result run-stats]
  ?-    -.res
      %ok        =/  st  [gen.res distinct.res queued.res depth.res od]  [[%ok st] st]
      %limited   =/  st  [gen.res distinct.res queued.res depth.res od]  [[%limited what.res st] st]
      %inv       =/  st  [gen.res distinct.res queued.res depth.res od]  [[%violated [%invariant name.res initial.res] st] st]
      ::  R2.7.15a: EC 2112 on the wire, the variant R2.7.13 added
      %action    =/  st  [gen.res distinct.res queued.res depth.res od]  [[%violated [%action name.res] st] st]
      %deadlock  =/  st  [gen.res distinct.res queued.res depth.res od]  [[%violated [%deadlock ~] st] st]
      %error     [[%failed msg.res] *run-stats]
  ==
::
++  run-stats-full
  ::  the final statistics of a safety search including the max out-degree that
  ::  the wire run-stats does not carry, run in `budget`-sized slices (for
  ::  statistics and pause/resume-equality differential tests)
  |=  [spec=@t cfg=@t cap=@ud budget=@ud]
  ^-  [gen=@ud distinct=@ud queued=@ud depth=@ud outdeg=[min=@ud mean=@ud p95=@ud max=@ud]]
  =/  sc  (search-ctx spec cfg)
  ?:  ?=(%| -.sc)  [0 0 0 0 [0 0 0 0]]
  =*  c  p.sc
  =/  o=bfs-opts
    [nsb.c invs.c cons.c acons.c poss.c vars.c order.c perms.c defs.c consts.c ddl.c cap 0 view.c 0 | ~ *cov-opts 0 ~ !(draws defs.c) ~]
  =/  cur  (explore-cursor is.c o budget)
  [gen.cur distinct.cur len.queue.cur depth.cur (od-stats outdeg.cur)]
--

