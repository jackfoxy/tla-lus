::  Fuzz robustness (unit 11 / R1.2): every stage must return a typed accept or
::  a typed rejection for ANY input -- never a bail, and always terminating.
::
::  R1.2.1 replaced three ad-hoc parser arms with ONE runner. `+fz-run` drives a
::  seeded generator into a stage adapter and classifies each case four ways:
::
::    %ok        the stage produced a result
::    %rejected  the stage produced a TYPED rejection -- also a pass
::    %bailed    the stage crashed (`mule` caught it)     -- a FAILURE
::    %budget    the stage hit a work cap instead of finishing -- a FAILURE on
::               this corpus, whose inputs are all small
::
::  `%budget` exists because `mule` catches a bail but NOT a loop: R1.8.1.4 found
::  a liveness build that ran 480 s on a five-state spec. Hoon has no timeout to
::  impose from outside, so the harness cannot bound a stage itself -- each stage
::  adapter must call its stage with the caps it already has (`live-graph-cap`,
::  `+expand-cap`, `fuel:eenv`) and report a cap-hit as `%budget`. That is a
::  contract on the adapter, stated here because it cannot be enforced in code.
::
::  A failure carries its INPUT, so the case can be reduced and committed as a
::  fixture in the corpus that owns the stage (see doc/testing.md).
/+  *test
/=  syntax  /lib/syntax
/=  semantic  /lib/semantic
/=  config  /lib/config
/=  check  /lib/check
/=  job  /lib/job
|%
+$  fz-outcome  ?(%ok %rejected %bailed %budget)
::  a failing case: which run, what it produced, and the input that did it
+$  fz-fail     [i=@ud out=fz-outcome inp=@t]
::
++  fz-run
  ::  run `runs` seeded cases in ONE pass, returning both the FAILURES (each
  ::  carrying the input that caused it) and how many cases the stage actually
  ::  produced a result for.
  ::
  ::  Both in one pass on purpose. The two were separate arms until the shard
  ::  became the slowest in the suite -- every stage ran twice, once to collect
  ::  failures and once to count reach, for numbers that come from the same
  ::  seeded sequence. Merging them halves the work and puts each stage's floor
  ::  next to the run it describes.
  |=  $:  seed=@
          runs=@ud
          gen=$-([@ud _og] [@t _og])
          stage=$-(@t fz-outcome)
      ==
  ^-  [fails=(list fz-fail) ok=@ud]
  =/  rng  ~(. og seed)
  =/  i  0
  =/  ok  0
  =|  acc=(list fz-fail)
  |-  ^-  [fails=(list fz-fail) ok=@ud]
  ?:  =(i runs)  [(flop acc) ok]
  =^  inp  rng  (gen i rng)
  =/  out  (stage inp)
  ?:  ?=(?(%ok %rejected) out)
    $(i +(i), rng rng, ok ?:(?=(%ok out) +(ok) ok))
  $(i +(i), rng rng, acc [[i out inp] acc])
::
++  expect-clean
  ::  a stage passes when nothing bailed or hit a cap AND the mutations still
  ::  REACH it at least `floor` times. Without the floor an arm passes trivially
  ::  when every mutation is rejected at the parse step and the stage under test
  ::  never runs -- the fuzz form of a differential that has stopped measuring.
  ::  Pass a floor of 0 where reach is not a meaningful notion (the parser
  ::  accepts almost no random token soup, and a decoding arm has no parse step)
  |=  [r=[fails=(list fz-fail) ok=@ud] floor=@ud]
  ^-  tang
  %+  weld
    (expect-eq !>(`(list fz-fail)`~) !>(fails.r))
  (expect-eq !>(%.y) !>((gte ok.r floor)))
::
::  +|  Generators
::
++  vocab
  ^-  (list @t)
  :~  'MODULE'  'EXTENDS'  'VARIABLE'  'CONSTANT'  'ASSUME'  'THEOREM'
      '=='  '/\\'  '\\/'  'IF'  'THEN'  'ELSE'  '\\A'  '\\E'  'CHOOSE'
      '{'  '}'  '['  ']'  '<<'  '>>'  '('  ')'  ':'  ','  '.'  '|->'
      '+'  '-'  '*'  '='  '<'  '>'  '#'  '\\in'  '\\cup'  '~'  '['  ']_'
      'SUBSET'  'UNION'  'DOMAIN'  'LET'  'IN'  'EXCEPT'  '!'  '@'
      'x'  'y'  'S'  'Foo'  'Init'  'Next'  '0'  '1'  '42'  'TRUE'  'FALSE'
  ==
::
++  rand-body
  ::  n random vocabulary words separated by spaces
  |=  [rng=_og n=@ud]
  ^-  [@t _og]
  =/  words  vocab
  =/  wc  (lent words)
  =|  out=tape
  =/  i  0
  |-  ^-  [@t _og]
  ?:  =(i n)  [(crip out) rng]
  =^  idx  rng  (rads:rng wc)
  =/  w  (snag idx words)
  $(i +(i), out (welp out (welp " " (trip w))), rng rng)
::
++  gen-module
  ::  a random token body wrapped in a module frame. Reaches the lexer and the
  ::  parser; it essentially never PARSES, so it does not reach the stages past
  ::  them -- those mutate the existing corpora instead (R1.2.0 decision (b))
  |=  n=@ud
  ^-  $-([@ud _og] [@t _og])
  |=  [i=@ud rng=_og]
  ^-  [@t _og]
  =^  body  rng  (rand-body rng n)
  [(crip "---- MODULE F ----\0a{(trip body)}\0a====\0a") rng]
::
++  gen-fixed
  ::  a generator over a fixed input list, for hand-written adversarial cases
  |=  l=(list @t)
  ^-  $-([@ud _og] [@t _og])
  |=  [i=@ud rng=_og]
  ^-  [@t _og]
  [?:((gth (lent l) i) (snag i l) '') rng]
::
::  +|  Mutation over valid corpus inputs (R1.2.2)
::
::  A random token stream reaches the lexer and the parser and essentially never
::  PARSES, so it never reaches the semantic graph or the config validator. The
::  R1.2.0 decision was to MUTATE valid inputs instead: a small edit to a module
::  that already parses lands close enough to stay interesting, and the repo is
::  full of such modules. The bases below are corpus cases, inlined because a
::  test cannot scry Clay for `test-data`.
::
++  lines-of
  ::  split on newline, keeping no trailing empty (hand-rolled)
  |=  t=@t
  ^-  (list tape)
  =/  c  (trip t)
  =|  cur=tape
  =|  acc=(list tape)
  |-  ^-  (list tape)
  ?~  c
    ?~(cur (flop acc) (flop [(flop cur) acc]))
  ?:  =(10 i.c)  $(c t.c, cur ~, acc [(flop cur) acc])
  $(c t.c, cur [i.c cur])
::
++  unlines
  |=  l=(list tape)
  ^-  @t
  ?~  l  ''
  %-  crip
  |-  ^-  tape
  ?~  t.l  i.l
  :(weld i.l "\0a" $(l t.l))
::
++  drop-at
  |=  [i=@ud l=(list tape)]
  ^-  (list tape)
  ?~  l  ~
  ?:(=(0 i) t.l [i.l $(i (dec i), l t.l)])
::
++  dup-at
  |=  [i=@ud l=(list tape)]
  ^-  (list tape)
  ?~  l  ~
  ?:(=(0 i) [i.l i.l t.l] [i.l $(i (dec i), l t.l)])
::
++  put-at
  |=  [i=@ud v=tape l=(list tape)]
  ^-  (list tape)
  ?~  l  ~
  ?:(=(0 i) [v t.l] [i.l $(i (dec i), l t.l)])
::
++  mutate
  ::  one edit, chosen by the rng: drop a line, duplicate a line, swap two, or
  ::  replace a line with a random token soup. Line-level on purpose -- a
  ::  character-level edit almost always breaks the parse, and a module that
  ::  does not parse tells the SEMANTIC stage nothing
  |=  [t=@t rng=_og]
  ^-  [@t _og]
  =/  ls  (lines-of t)
  =/  n  (lent ls)
  ?:  =(0 n)  [t rng]
  =^  op   rng  (rads:rng 4)
  =^  a    rng  (rads:rng n)
  =^  b    rng  (rads:rng n)
  ?+  op  [t rng]
    %0  [(unlines (drop-at a ls)) rng]
    %1  [(unlines (dup-at a ls)) rng]
  ::
      %2
    =/  va  (snag a ls)
    =/  vb  (snag b ls)
    [(unlines (put-at a vb (put-at b va ls))) rng]
  ::
      %3
    =^  body  rng  (rand-body rng 6)
    [(unlines (put-at a (trip body) ls)) rng]
  ==
::
++  gen-mutate
  ::  pick a base at random, then apply 1-3 edits
  |=  bases=(list @t)
  ^-  $-([@ud _og] [@t _og])
  |=  [i=@ud rng=_og]
  ^-  [@t _og]
  ::  `=(0 n)` rather than `?~ bases`: a ?~-narrowed list nest-fails the WET
  ::  `snag` (`-have.%~`), the zuse-408 hazard this repo hits repeatedly
  =/  n  (lent bases)
  ?:  =(0 n)  ['' rng]
  =^  bi  rng  (rads:rng n)
  =^  k   rng  (rads:rng 3)
  =/  t  (snag bi `(list @t)`bases)
  =/  j  0
  |-  ^-  [@t _og]
  ?:  (gth j k)  [t rng]
  =^  t2  rng  (mutate t rng)
  $(j +(j), t t2, rng rng)
::
::  +|  Corpus bases (inlined; a test cannot scry Clay)
::
++  base-modules
  ^-  (list @t)
  :~  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aNext == x\' = x + 1\0aInv == x >= 0\0aOp(a) == a + 1\0aSpec == Init /\\ [][Next]_x\0a====\0a'
      '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aA == x = 0 /\\ x\' = 1\0aB == x = 1 /\\ x\' = 0\0aNext == A \\/ B\0aSpec == Init /\\ [][Next]_x /\\ WF_x(A)\0aLive == <>[](x = 1)\0a====\0a'
      '---- MODULE A ----\0aEXTENDS Integers\0aCONSTANT C\0aVARIABLE x, y\0aInit == x = C /\\ y = 0\0aNext == x\' = x /\\ y\' = y + 1\0a====\0a'
  ==
::
++  base-cfgs
  ^-  (list @t)
  :~  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
      'SPECIFICATION Spec\0aPROPERTY Live\0a'
      'CONSTANT C = 1\0aINIT Init\0aNEXT Next\0aCONSTRAINT Inv\0a'
  ==
::
::
++  fz-parse
  ::  the parser: any input must give a clean accept or reject, never a bail
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((parse:syntax inp)))
  ?:  ?=(%| -.r)  %bailed
  ?:(?=(%| -.p.r) %rejected %ok)
::
::  NOTE on `%budget` for the three adapters below: `generate:semantic`,
::  `+parse-cfg` and `+run-spec-of` walk a FINITE parse tree, so there is no
::  state space to bound and no cap to pass -- they cannot report `%budget`.
::  The adapter's budget obligation (see the header) binds the stages that
::  ITERATE, which are `.3`'s and `.4`'s.
::
++  fz-sem
  ::  the semantic graph: a module that does not resolve is `~`, a typed
  ::  rejection; anything else must be a graph, never a bail
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((generate:semantic 'A' (malt ~[['A' inp]]))))
  ?:  ?=(%| -.r)  %bailed
  ?:(?=(~ p.r) %rejected %ok)
::
++  fz-cfg
  ::  the .cfg parser: a malformed config is a CFG_* diagnostic, never a bail
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((parse-cfg:config inp)))
  ?:  ?=(%| -.r)  %bailed
  ?:(?=(%| -.p.r) %rejected %ok)
::
++  fz-runspec-cfg
  ::  the whole config path -- parse, validate against the graph, assemble the
  ::  run-spec -- with the MODULE fixed and the .cfg mutated. This is the
  ::  surface a user actually supplies, and `+build-defns` was rewritten
  ::  wholesale in R1.8.1.3b
  |=  spec=@t
  ^-  $-(@t fz-outcome)
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((run-spec-of:config 'A' (malt ~[['A' spec]]) inp)))
  ?:  ?=(%| -.r)  %bailed
  ?:(?=(%| -.p.r) %rejected %ok)
::
++  fz-runspec-spec
  ::  the same path with the .cfg fixed and the MODULE mutated
  |=  cfg=@t
  ^-  $-(@t fz-outcome)
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((run-spec-of:config 'A' (malt ~[['A' inp]]) cfg)))
  ?:  ?=(%| -.r)  %bailed
  ?:(?=(%| -.p.r) %rejected %ok)
::
++  fz-check-lines
  ::  classify `check:check`'s terminal output. A run that produced state
  ::  COUNTS actually reached the checker; a cap-hit is `%budget`; anything
  ::  else is a typed rejection before the search
  ::  `=(~ w)` rather than `?~ w`: a ?~-narrowed list nest-fails the WET `lien`
  ::  with `-have.%~` (the zuse-408 hazard, hit again here)
  |=  w=wain
  ^-  fz-outcome
  ?:  =(~ w)  %rejected
  ?:  =('Model checking stopped: state limit reached.' (snag 0 `wain`w))  %budget
  =/  ran
    %+  lien  `wain`w
    |=(l=@t ?=(^ (fand "distinct states found" (trip l))))
  ?:(ran %ok %rejected)
::
++  fz-check
  ::  the whole checker -- normalize, tableau, product, SCC, lasso -- over a
  ::  mutated MODULE with the .cfg fixed. This is the first adapter over a stage
  ::  that ITERATES, so the budget obligation from the header applies: it is
  ::  discharged because `check:check` carries `live-graph-cap` itself and
  ::  renders a cap-hit as the `state limit reached` line, which
  ::  `+fz-check-lines` maps to `%budget`
  |=  cfg=@t
  ^-  $-(@t fz-outcome)
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((check:check inp cfg)))
  ?:(?=(%| -.r) %bailed (fz-check-lines p.r))
::
++  fz-check-cfg
  ::  the same with the MODULE fixed and the .cfg mutated
  |=  spec=@t
  ^-  $-(@t fz-outcome)
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((check:check spec inp)))
  ?:(?=(%| -.r) %bailed (fz-check-lines p.r))
::
++  live-module
  ::  a liveness base: a SPECIFICATION with fairness and a temporal PROPERTY
  ^-  @t
  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x\0aInit == x = 0\0aA == x = 0 /\\ x\' = 1\0aB == x = 1 /\\ x\' = 0\0aNext == A \\/ B\0aSpec == Init /\\ [][Next]_x /\\ WF_x(A)\0aLive == <>[](x = 1)\0a====\0a'
::
++  live-cfg
  ^-  @t
  'SPECIFICATION Spec\0aPROPERTY Live\0a'
::
++  safety-module
  ::  a safety base: INIT/NEXT with an INVARIANT, so the run exercises
  ::  `lib/node-eval`'s init/next SOLVING through the BFS rather than the
  ::  liveness engine. There is no smaller text-driven entry to the evaluator
  ::  -- it is reached through the checker (R1.2.4)
  ^-  @t
  '---- MODULE A ----\0aEXTENDS Naturals\0aVARIABLE x, y\0aInit == x \\in 0..2 /\\ y = 0\0aNext == x\' = (x + 1) % 3 /\\ y\' = y\0aInv == x \\in 0..2\0a====\0a'
::
++  safety-cfg
  ^-  @t
  'INIT Init\0aNEXT Next\0aINVARIANT Inv\0a'
::
::
::  +|  R1.2.5: decoding a persisted continuation
::
::  The only surface where the hostile input is a STORED NOUN rather than a
::  spec. `+load-kont` is `;;(kont (cue k.c))` -- a bare coercion over an atom
::  that survived a restart, a state migration, or a disk. It crashes on
::  anything that is not a valid `kont`, which is FINE only because every one of
::  its three call sites wraps it in `mule` and treats the failure as a typed
::  outcome (`+step` fails the job with a restart notice, the two read-routing
::  arms fall through). This arm drives the PRODUCTION entry, `+step`, so it
::  tests that contract rather than the unguarded internal arm.
::
++  gen-atom
  ::  a random atom -- garbage where a jammed continuation should be. Includes
  ::  0 and small atoms, which `cue` treats specially
  |=  bits=@ud
  ^-  $-([@ud _og] [@t _og])
  |=  [i=@ud rng=_og]
  ^-  [@t _og]
  =^  a  rng  (rads:rng (bex bits))
  [`@t`a rng]
::
++  gen-corrupt
  ::  a VALID jammed continuation with one bit flipped, or truncated -- the
  ::  shapes a real disk or a version skew produces, which pure garbage does not
  |=  base=@
  ^-  $-([@ud _og] [@t _og])
  |=  [i=@ud rng=_og]
  ^-  [@t _og]
  =/  w  (met 0 base)
  ?:  =(0 w)  [`@t`base rng]
  =^  op  rng  (rads:rng 2)
  =^  b   rng  (rads:rng w)
  ?:  =(0 op)  [`@t`(mix base (bex b)) rng]
  [`@t`(end [0 b] base) rng]
::
++  fz-kont
  ::  a corrupt continuation must fail the JOB, never the event
  |=  inp=@t
  ^-  fz-outcome
  =/  j=job-3:job  *job-3:job
  =.  cont.j  `[%1 `@`inp]
  =/  r  (mule |.((step:job j 1 `@da`0)))
  ?:  ?=(%| -.r)  %bailed
  %ok
::
::
::  +|  Arms
::
::  One arm per stage: each runs its seeds ONCE and asserts both "nothing
::  bailed or hit a cap" and "the mutations still reached the stage at least
::  N times". The reach numbers are exact and reproducible (fixed seeds);
::  those measured on the R1.2.2-.5 ship runs are named beside each floor.
::
::  200 reproducible random parses, none may bail. No reach floor: a random
::  token soup essentially never parses, and that is the point of the arm
++  test-fuzz-parser-no-crash
  %+  expect-clean
    (fz-run 0xdead.beef 200 (gen-module 12) fz-parse)
  0
::
::  a different seed, longer bodies -- still no bail
++  test-fuzz-parser-no-crash-long
  %+  expect-clean
    (fz-run 0xf00d 120 (gen-module 30) fz-parse)
  0
::
++  garbage
  ^-  (list @t)
  :~  ''  '~~~~'  '===='  '---- MODULE'  '(((((('  'MODULE x =='
      '\\A \\E \\A :'  '{{{{}}}}'  '[]_[]_'  '<<<<>>>>'
  ==
::
::  raw non-module garbage parses cleanly (never bails)
++  test-fuzz-garbage-no-crash
  %+  expect-clean
    (fz-run 0x1 (lent garbage) (gen-fixed garbage) fz-parse)
  0
::
::  +|  R1.2.2 arms: semantic graph + config  (reach measured 99 / 91 / 29 / 16)
::
++  test-fuzz-sem
  %+  expect-clean
    (fz-run 0xbeef.0001 200 (gen-mutate base-modules) fz-sem)
  60
::
++  test-fuzz-cfg-parse
  %+  expect-clean
    (fz-run 0xbeef.0002 200 (gen-mutate base-cfgs) fz-cfg)
  60
::
++  test-fuzz-runspec-cfg
  %+  expect-clean
    %-  fz-run
    :*  0xbeef.0003  150
        (gen-mutate base-cfgs)
        (fz-runspec-cfg (snag 0 `(list @t)`base-modules))
    ==
  15
::
++  test-fuzz-runspec-spec
  %+  expect-clean
    %-  fz-run
    :*  0xbeef.0004  150
        (gen-mutate base-modules)
        (fz-runspec-spec (snag 0 `(list @t)`base-cfgs))
    ==
  8
::
::  +|  R1.2.3 arms: temporal normalizer + liveness  (reach measured 10 / 12)
::
++  test-fuzz-live-module
  %+  expect-clean
    (fz-run 0xbeef.0005 40 (gen-mutate ~[live-module]) (fz-check live-cfg))
  5
::
++  test-fuzz-live-cfg
  %+  expect-clean
    (fz-run 0xbeef.0006 40 (gen-mutate ~[live-cfg]) (fz-check-cfg live-module))
  6
::
::  +|  R1.2.4 arms: the evaluator, through the safety search
::
::  These reach least of all -- the base has a five-line body, so a single line
::  edit breaks it more often than not. Measured 5 / 40 and 8 / 40, which is why
::  the module arm runs 80 cases: thin reach is a finding, not something to hide
::  behind a low floor
++  test-fuzz-safety-module
  %+  expect-clean
    (fz-run 0xbeef.0007 80 (gen-mutate ~[safety-module]) (fz-check safety-cfg))
  5
::
++  test-fuzz-safety-cfg
  %+  expect-clean
    (fz-run 0xbeef.0008 40 (gen-mutate ~[safety-cfg]) (fz-check-cfg safety-module))
  4
::
::  +|  R1.2.5 arms: decoding. No reach floor -- there is no parse step to be
::  rejected at, so every case reaches `+step` by construction
::
++  test-fuzz-kont-garbage
  %+  expect-clean
    (fz-run 0xbeef.0009 200 (gen-atom 64) fz-kont)
  0
::
::  bit-flips and truncations of a REAL jammed continuation
++  test-fuzz-kont-corrupt
  %+  expect-clean
    (fz-run 0xbeef.000a 200 (gen-corrupt (jam `kont:job`[%load *lcur:job])) fz-kont)
  0
::
++  test-fuzz-runner-classifies
  =/  bail-stage  |=(inp=@t ^-(fz-outcome =/(r (mule |.(!!)) ?:(?=(%| -.r) %bailed %ok))))
  =/  budget-stage  |=(inp=@t `fz-outcome`%budget)
  =/  ok-stage  |=(inp=@t `fz-outcome`%ok)
  =/  rej-stage  |=(inp=@t `fz-outcome`%rejected)
  =/  one  (gen-fixed ~['abc'])
  ;:  weld
    %+  expect-eq  !>(`[(list fz-fail) @ud]`[~[[0 %bailed 'abc']] 0])
    !>((fz-run 0x2 1 one bail-stage))
  ::
    %+  expect-eq  !>(`[(list fz-fail) @ud]`[~[[0 %budget 'abc']] 0])
    !>((fz-run 0x2 1 one budget-stage))
  ::
  ::  the ok stage COUNTS, the rejected stage does not -- that difference is
  ::  what every reach floor rests on
    %+  expect-eq  !>(`[(list fz-fail) @ud]`[~ 1])
    !>((fz-run 0x2 1 one ok-stage))
  ::
    %+  expect-eq  !>(`[(list fz-fail) @ud]`[~ 0])
    !>((fz-run 0x2 1 one rej-stage))
  ==
--
