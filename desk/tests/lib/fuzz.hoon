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
|%
+$  fz-outcome  ?(%ok %rejected %bailed %budget)
::  a failing case: which run, what it produced, and the input that did it
+$  fz-fail     [i=@ud out=fz-outcome inp=@t]
::
++  fz-run
  ::  run `runs` seeded cases and return only the FAILURES, in order. The seed
  ::  fixes the whole run, so a reported failure replays exactly.
  |=  $:  seed=@
          runs=@ud
          gen=$-([@ud _og] [@t _og])
          stage=$-(@t fz-outcome)
      ==
  ^-  (list fz-fail)
  =/  rng  ~(. og seed)
  =/  i  0
  =|  acc=(list fz-fail)
  |-  ^-  (list fz-fail)
  ?:  =(i runs)  (flop acc)
  =^  inp  rng  (gen i rng)
  =/  out  (stage inp)
  ?:  ?=(?(%ok %rejected) out)  $(i +(i), rng rng)
  $(i +(i), rng rng, acc [[i out inp] acc])
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
::  +|  Stage adapters
::
++  fz-parse
  ::  the parser: any input must give a clean accept or reject, never a bail
  |=  inp=@t
  ^-  fz-outcome
  =/  r  (mule |.((parse:syntax inp)))
  ?:  ?=(%| -.r)  %bailed
  ?:(?=(%| -.p.r) %rejected %ok)
::
::  +|  Arms
::
::  200 reproducible random parses, none may bail
++  test-fuzz-parser-no-crash
  %+  expect-eq  !>(`(list fz-fail)`~)
  !>((fz-run 0xdead.beef 200 (gen-module 12) fz-parse))
::
::  a different seed, longer bodies -- still no bail
++  test-fuzz-parser-no-crash-long
  %+  expect-eq  !>(`(list fz-fail)`~)
  !>((fz-run 0xf00d 120 (gen-module 30) fz-parse))
::
::  raw non-module garbage parses cleanly (never bails)
++  garbage
  ^-  (list @t)
  :~  ''  '~~~~'  '===='  '---- MODULE'  '(((((('  'MODULE x =='
      '\\A \\E \\A :'  '{{{{}}}}'  '[]_[]_'  '<<<<>>>>'
  ==
::
++  test-fuzz-garbage-no-crash
  %+  expect-eq  !>(`(list fz-fail)`~)
  !>((fz-run 0x1 (lent garbage) (gen-fixed garbage) fz-parse))
::
::  the runner itself: it must REPORT a bail and a budget rather than pass them,
::  and must carry the offending input back. Synthetic stages, so this stays
::  true whatever the port does
++  test-fuzz-runner-classifies
  =/  bail-stage  |=(inp=@t ^-(fz-outcome =/(r (mule |.(!!)) ?:(?=(%| -.r) %bailed %ok))))
  =/  budget-stage  |=(inp=@t `fz-outcome`%budget)
  =/  ok-stage  |=(inp=@t `fz-outcome`%ok)
  =/  rej-stage  |=(inp=@t `fz-outcome`%rejected)
  =/  one  (gen-fixed ~['abc'])
  ;:  weld
    (expect-eq !>(`(list fz-fail)`~[[0 %bailed 'abc']]) !>((fz-run 0x2 1 one bail-stage)))
    (expect-eq !>(`(list fz-fail)`~[[0 %budget 'abc']]) !>((fz-run 0x2 1 one budget-stage)))
    (expect-eq !>(`(list fz-fail)`~) !>((fz-run 0x2 1 one ok-stage)))
    (expect-eq !>(`(list fz-fail)`~) !>((fz-run 0x2 1 one rej-stage)))
  ==
--
