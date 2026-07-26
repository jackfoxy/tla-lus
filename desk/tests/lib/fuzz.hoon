::  Fuzz robustness (unit 14): the lexer/parser must never crash -- for any
::  input they return a clean accept (%&) or reject (%|), never a bail.
::  Inputs are seeded random token sequences wrapped in a module frame, so
::  runs are reproducible; any reduced crash found here becomes a permanent
::  regression fixture under test-data/parse.
/+  *test
/=  syntax  /lib/syntax
|%
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
++  fuzz-parse-ok
  ::  parse `runs` random module bodies; & iff none crashed (each returns a
  ::  clean each) -- deterministic in `seed`
  |=  [seed=@ runs=@ud len=@ud]
  ^-  ?
  =/  rng  ~(. og seed)
  =/  i  0
  |-  ^-  ?
  ?:  =(i runs)  &
  =^  body  rng  (rand-body rng len)
  =/  text=@t  (crip "---- MODULE F ----\0a{(trip body)}\0a====\0a")
  =/  r  (mule |.((parse:syntax text)))
  ?:  ?=(%| -.r)  |
  $(i +(i))
::
::  200 reproducible random parses, none may crash
++  test-fuzz-parser-no-crash
  (expect-eq !>(%.y) !>((fuzz-parse-ok 0xdead.beef 200 12)))
::
::  a different seed, longer bodies -- still no crash
++  test-fuzz-parser-no-crash-long
  (expect-eq !>(%.y) !>((fuzz-parse-ok 0xf00d 120 30)))
::
++  all-parse-ok
  ::  & iff every input parses without crashing (clean each either way)
  |=  inputs=(list @t)
  ^-  ?
  ?~  inputs  &
  =/  r  (mule |.((parse:syntax i.inputs)))
  ?:  ?=(%| -.r)  |
  $(inputs t.inputs)
::
::  raw non-module garbage parses cleanly (never bails)
++  test-fuzz-garbage-no-crash
  %+  expect-eq  !>(%.y)
  !>  %-  all-parse-ok
      :~  ''  '~~~~'  '===='  '---- MODULE'  '(((((('  'MODULE x =='
          '\\A \\E \\A :'  '{{{{}}}}'  '[]_[]_'  '<<<<>>>>'
      ==
--
