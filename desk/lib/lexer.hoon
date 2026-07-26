/-  *tla-lus
/=  src  /lib/source
|%
  ::  Native TLA+ Lexer
  ::
  ::  Port of the JavaCC lexical grammar in tla+.jj at the pinned
  ::  upstream commit (see doc/port-map.md): lexical states DEFAULT,
  ::  PRAGMA, SPEC, IN_COMMENT, EMBEDDED, IN_EOL_COMMENT; maximal munch
  ::  with declaration-order tie-breaking; comment pieces emitted exactly
  ::  as SANY's SPECIAL_TOKEN chain; TokenMgrError-format lexical errors.
  ::
  ::  +lex stops when module nesting returns to zero, mirroring the fact
  ::  that SANY never lexes past the root module's ====; +dump renders
  ::  the stream in the differential format shared with the Java
  ::  TokenDump oracle harness.
  ::
::  +|  Types
::
+$  ach   ach:src
+$  achs  (list ach)
+$  item
  $%  [%tok =token]
      [%com text=@t =span]
      ::  bl/el: the failing lexeme's begin line and the error line, for
      ::  the parse()-level EOF wrapper (unit 2); msg is the byte-exact
      ::  TokenMgrError text
      [%err msg=@t bl=@ud el=@ud]
  ==
::  fixed-lexeme table entry: code points, kind
+$  entry  [cs=(list @c) kind=@tas]
::
::  +|  Fixed Lexemes (declaration order per tla+.jj)
::
::
++  fixed-raw
  ^-  (list [@t @tas])
  :~  ::  keywords and punctuation
      ['ACTIONS' %action]     ['ACTION' %action]
      ['ASSUMPTION' %assumption]  ['AXIOM' %assumption]
      ['ASSUME' %assume]      ['[]ASSUME' %boxassume]
      ['CASE' %case]          ['CHOOSE' %choose]
      ['CONSTANTS' %constant]  ['CONSTANT' %constant]
      ['ELSE' %else]          ['EXCEPT' %except]
      ['\\E' %exists]         ['\\exists' %exists]  ['∃' %exists]
      ['EXTENDS' %extends]
      ['\\A' %forall]         ['\\forall' %forall]  ['∀' %forall]
      ['IF' %if]              ['INSTANCE' %instance]
      ['LET' %let]            ['IN' %letin]
      ['LOCAL' %local]        ['MODULE' %module]
      ['NEW' %new]            ['OTHER' %other]
      ['PROPOSITION' %proposition]  ['LEMMA' %proposition]
      ['COROLLARY' %proposition]
      ['SF_' %sf]
      ['\\EE' %t-exists]      ['\\AA' %t-forall]
      ['THEN' %then]          ['BY' %by]
      ['ONLY' %only]          ['DEFINE' %define]
      ['DEFS' %df]            ['DEF' %df]
      ['THEOREM' %theorem]    ['USE' %use]
      ['HIDE' %hide]          ['HAVE' %have]
      ['OBVIOUS' %obvious]    ['OMITTED' %omitted]
      ['LAMBDA' %lambda]      ['TAKE' %take]
      ['PROOF' %proof]        ['PROVE' %prove]
      ['[]PROVE' %boxprove]   ['QED' %qed]
      ['RECURSIVE' %recursive]
      ['STATE' %state]
      ['TEMPORALS' %temporal]  ['TEMPORAL' %temporal]
      ['PICK' %pick]          ['WITNESS' %witness]
      ['SUFFICES' %suffices]
      ['VARIABLES' %variable]  ['VARIABLE' %variable]
      ['WF_' %wf]             ['WITH' %with]
      [',' %comma]            ['::' %coloncolon]  ['∷' %coloncolon]
      [':' %colon]
      ['.' %dot]              ['_' %us]
      ['==' %def]             ['≜' %def]
      ['(' %lbr]              [')' %rbr]
      ['-|-' %defbreak]
      ['[' %lsb]              [']_' %arsb]        [']' %rsb]
      ['{' %lbc]              ['}' %rbc]
      ['<<' %lab]             ['⟨' %lab]
      ['>>_' %arab]           ['⟩_' %arab]
      ['>>' %rab]             ['⟩' %rab]
      ['!' %bang]
      ['->' %arrow]           ['→' %arrow]
      ['<-' %substitute]      ['←' %substitute]
      ['|->' %mapto]          ['↦' %mapto]
      ::  postfix operators
      ['\'' %op-57]
      ['^+' %op-68]           ['⁺' %op-68]
      ['^*' %op-69]           ['^#' %op-70]
      ::  prefix operators
      ['-.' %op-76]
      ['\\lnot' %op-26]       ['¬' %op-26]
      ['\\neg' %op-29]        ['~' %op-58]
      ['[]' %casesep]         ['□' %casesep]
      ['<>' %op-61]           ['◇' %op-61]
      ['ENABLED' %op-112]     ['UNCHANGED' %op-113]
      ['SUBSET' %op-114]      ['UNION' %op-115]
      ['DOMAIN' %op-116]
      ::  infix operators
      ['//' %op-1]
      ['/\\' %and]            ['∧' %and]
      ['/=' %op-3]            ['/' %op-4]
      ['\\/' %or]             ['∨' %or]
      ['\\approx' %op-6]      ['\\asymp' %op-7]
      ['\\bigcirc' %op-8]     ['\\bullet' %op-9]
      ['\\cap' %op-10]        ['\\cdot' %op-11]
      ['\\circ' %op-12]       ['\\cong' %op-13]
      ['\\cup' %op-14]        ['\\div' %op-15]
      ['\\doteq' %op-16]      ['\\equiv' %op-17]
      ['\\geq' %op-18]        ['\\gg' %op-19]
      ['\\in' %in]            ['∈' %in]
      ['\\intersect' %op-21]  ['\\union' %op-22]
      ['\\land' %op-23]       ['\\leq' %op-24]
      ['\\ll' %op-25]         ['\\lor' %op-27]
      ['\\o' %op-30]          ['\\odot' %op-31]
      ['\\ominus' %op-32]     ['\\oplus' %op-33]
      ['\\oslash' %op-34]     ['\\otimes' %op-35]
      ['\\prec' %op-36]       ['\\preceq' %op-37]
      ['\\propto' %op-38]     ['\\sim' %op-39]
      ['\\simeq' %op-40]      ['\\sqcap' %op-41]
      ['\\sqcup' %op-42]      ['\\sqsubset' %op-43]
      ['\\sqsupset' %op-44]   ['\\sqsubseteq' %op-45]
      ['\\sqsupseteq' %op-46]  ['\\star' %op-47]
      ['\\subset' %op-48]     ['\\subseteq' %op-49]
      ['\\succ' %op-50]       ['\\succeq' %op-51]
      ['\\supset' %op-52]     ['\\supseteq' %op-53]
      ['\\uplus' %op-54]      ['\\wr' %op-55]
      ['\\' %op-56]
      ['~>' %op-59]
      ['=>' %op-62]           ['=<' %op-63]
      ['=|' %op-64]           ['=' %equals]
      ['##' %op-66]           ['#' %op-67]
      ['^^' %op-71]           ['^' %op-72]
      ['--' %op-73]           ['-|' %op-74]
      ['-+->' %op-75]         ['-' %op-77]
      ['**' %op-78]           ['*' %op-79]
      ['++' %op-80]           ['+' %op-81]
      ['<=>' %op-82]          ['<:' %op-83]
      ['<=' %op-84]           ['<' %op-85]
      ['>=' %op-86]           ['>' %op-87]
      ['...' %op-88]          ['..' %op-89]
      ['||' %op-90]           ['|' %op-91]
      ['|-' %op-92]           ['|=' %op-93]
      ['&&' %op-94]           ['&' %op-95]
      ['$$' %op-96]           ['$' %op-97]
      ['??' %op-98]
      ['%%' %op-100]          ['%' %op-101]
      ['@@' %op-102]          ['!!' %op-103]
      [':>' %op-104]          [':=' %op-105]
      ['::=' %op-106]
      ['(+)' %op-107]         ['(-)' %op-108]
      ['(.)' %op-109]         ['(/)' %op-110]
      ['(\\X)' %op-111]
      ['\\notin' %op-117]
      ['≈' %op-infix-approx-uc]      ['≔' %op-infix-assign-uc]
      ['≍' %op-infix-asymp-uc]       ['◯' %op-infix-bigcirc-uc]
      ['⩴' %op-infix-bnf-rule-uc]    ['●' %op-infix-bullet-uc]
      ['∩' %op-infix-cap-uc]         ['⋅' %op-infix-cdot-uc]
      ['∘' %op-infix-circ-uc]        ['≅' %op-infix-cong-uc]
      ['∪' %op-infix-cup-uc]         ['÷' %op-infix-div-uc]
      ['≐' %op-infix-doteq-uc]       ['‥' %op-infix-dots-2-uc]
      ['…' %op-infix-dots-3-uc]      ['≡' %op-infix-equiv-uc]
      ['‼' %op-infix-excl-uc]        ['≥' %op-infix-geq-uc]
      ['≫' %op-infix-gg-uc]          ['⇔' %op-infix-iff-uc]
      ['⇒' %op-infix-implies-uc]     ['⫤' %op-infix-ld-ttile-uc]
      ['↝' %op-infix-leads-to-uc]    ['≤' %op-infix-leq-uc]
      ['≪' %op-infix-ll-uc]          ['⊣' %op-infix-ls-ttile-uc]
      ['≠' %op-infix-neq-uc]         ['∉' %op-infix-notin-uc]
      ['⊙' %op-infix-odot-uc]        ['⊖' %op-infix-ominus-uc]
      ['⊕' %op-infix-oplus-uc]       ['⊘' %op-infix-oslash-uc]
      ['⊗' %op-infix-otimes-uc]      ['⇸' %op-infix-plus-arrow-uc]
      ['≺' %op-infix-prec-uc]        ['⪯' %op-infix-preceq-uc]
      ['∝' %op-infix-propto-uc]      ['⁇' %op-infix-qq-uc]
      ['⊨' %op-infix-rd-ttile-uc]    ['⊢' %op-infix-rs-ttile-uc]
      ['∼' %op-infix-sim-uc]         ['≃' %op-infix-simeq-uc]
      ['⊓' %op-infix-sqcap-uc]       ['⊔' %op-infix-sqcup-uc]
      ['⊏' %op-infix-sqsubset-uc]    ['⊑' %op-infix-sqsubseteq-uc]
      ['⊐' %op-infix-sqsupset-uc]    ['⊒' %op-infix-sqsupseteq-uc]
      ['⋆' %op-infix-star-uc]        ['⊂' %op-infix-subset-uc]
      ['⊆' %op-infix-subseteq-uc]    ['≻' %op-infix-succ-uc]
      ['⪰' %op-infix-succeq-uc]      ['⊃' %op-infix-supset-uc]
      ['⊇' %op-infix-supseteq-uc]    ['×' %op-infix-times-uc]
      ['⊎' %op-infix-uplus-uc]       ['‖' %op-infix-vertvert-uc]
      ['≀' %op-infix-wr-uc]
      ['\\times' %op-118]     ['\\X' %op-119]
  ==
::
++  fixed-table
  ^-  (list entry)
  %+  turn  fixed-raw
  |=  [t=@t k=@tas]
  ^-  entry
  [(codepoints:src t) k]
::
::  +|  Character Classes
::
::
++  is-digit  |=(c=@c &((gte c '0') (lte c '9')))
++  is-letter
  |=  c=@c
  ?|  &((gte c 'a') (lte c 'z'))
      &((gte c 'A') (lte c 'Z'))
  ==
++  is-word   |=(c=@c ?|((is-letter c) (is-digit c) =(c '_')))
++  is-ld     |=(c=@c ?|((is-letter c) (is-digit c)))
++  is-octal  |=(c=@c &((gte c '0') (lte c '7')))
++  is-bin    |=(c=@c |(=(c '0') =(c '1')))
++  is-hex
  |=  c=@c
  ?|  (is-digit c)
      &((gte c 'a') (lte c 'f'))
      &((gte c 'A') (lte c 'F'))
  ==
++  is-space  |=(c=@c |(=(c ' ') =(c '\09') =(c '\0a') =(c '\0d')))
::
::  +|  Small Helpers
::
::
++  cs-of  |=(s=achs `(list @c)`(turn s |=(a=ach c.a)))
::
++  asc
  ::  ASCII tape literal to code points
  |=(t=tape `(list @c)`(turn t |=(c=@tD `@c`c)))
::
++  starts-with
  |=  [s=achs cs=(list @c)]
  ^-  ?
  ?~  cs  &
  ?~  s   |
  ?.  =(c.i.s i.cs)  |
  $(s t.s, cs t.cs)
::
++  run-while
  ::  length of the maximal prefix satisfying f
  |=  [s=achs f=$-(@c ?)]
  ^-  @ud
  =/  n=@ud  0
  |-
  ?~  s  n
  ?.  (f c.i.s)  n
  $(s t.s, n +(n))
::
++  mk-token
  |=  [kind=@tas taken=achs]
  ^-  token
  ?>  ?=(^ taken)
  =/  hed  i.taken
  =/  las  (rear taken)
  :+  kind
    (crip (utf8-tape:src (cs-of taken)))
  [[l.hed col.hed] [l.las col.las]]
::
++  dec-tape
  |=  n=@ud
  ^-  tape
  ?:  =(0 n)  "0"
  =|  out=tape
  |-
  ?:  =(0 n)  out
  $(n (div n 10), out [(add '0' (mod n 10)) out])
::
::  +|  Sub-Matchers (each yields candidate [len kind] or none)
::
::
++  match-fixed
  ::  longest fixed lexeme; also the alive length for error reporting
  |=  s=achs
  ^-  [best=(unit [len=@ud kind=@tas]) alive=@ud]
  =/  best=(unit [len=@ud kind=@tas])  ~
  =/  alive=@ud  0
  =/  tbl  fixed-table
  |-
  ?~  tbl  [best alive]
  =/  elen  (lent cs.i.tbl)
  =?  best  ?&  (starts-with s cs.i.tbl)
                ?~(best & (gth elen len.u.best))
            ==
    `[elen kind.i.tbl]
  =/  pfx  (live-prefix s cs.i.tbl)
  =?  alive  (gth pfx alive)  pfx
  $(tbl t.tbl)
::
++  live-prefix
  ::  chars of s matching a strict prefix of cs (pattern still alive)
  |=  [s=achs cs=(list @c)]
  ^-  @ud
  =/  n=@ud  0
  |-
  ?~  cs  0        ::  complete match is an accept, not a live prefix
  ?~  s   n
  ?.  =(c.i.s i.cs)  n
  ?~  t.cs  0      ::  full match
  $(s t.s, cs t.cs, n +(n))
::
++  match-number
  |=  s=achs
  ^-  (unit @ud)
  ?~  s  ~
  ?:  (is-digit c.i.s)
    `(run-while s is-digit)
  ?.  =('\\' c.i.s)  ~
  ?~  t.s  ~
  =/  c2  c.i.t.s
  =/  t2  `achs`t.t.s
  =/  n
    ?:  |(=(c2 'o') =(c2 'O'))  (run-while t2 is-octal)
    ?:  |(=(c2 'b') =(c2 'B'))  (run-while t2 is-bin)
    ?:  |(=(c2 'h') =(c2 'H'))  (run-while t2 is-hex)
    0
  ?:  =(0 n)  ~
  `(add 2 n)
::
++  match-word
  ::  identifier per CASE0/1/2/3/6/N plus @ and number-set letters
  |=  s=achs
  ^-  (unit @ud)
  ?~  s  ~
  =/  c0  c.i.s
  ?:  =('@' c0)  `1
  ?:  (lien (codepoints:src 'ℕℤℝ') |=(n=@c =(n c0)))  `1
  =/  run  (run-while s is-word)
  ?:  =(0 run)  ~
  =/  has-letter
    =/  k  run
    =/  t  `achs`s
    |-  ^-  ?
    ?:  =(0 k)  |
    ?^  t
      ?:  (is-letter c.i.t)  &
      $(k (dec k), t t.t)
    |
  ?:  =('_' c0)
    ?:(has-letter `run ~)
  ?:  (is-digit c0)
    ?:(has-letter `run ~)
  ?.  |(=('W' c0) =('S' c0))  `run
  ::  uppercase W/S: CASE2 second char may not be F; CASE3 covers WF/SF
  ?:  =(1 run)  `1
  =/  c1  c:(snag 1 `achs`s)
  ?.  =('F' c1)  `run
  ?:  =(2 run)  `2
  =/  c2  c:(snag 2 `achs`s)
  ?:  =('_' c2)  `2
  `run
::
++  match-junction
  ::  BAND/BOR: no-underscore word run directly followed by ./\ or .\/
  |=  s=achs
  ^-  (unit [len=@ud kind=@tas])
  ?~  s  ~
  =/  c0  c.i.s
  =/  run  (run-while s is-ld)
  ?:  =(0 run)  ~
  =/  ok
    ?:  (is-digit c0)  &
    ?:  |(=('W' c0) =('S' c0))
      ?&  (gte run 2)
          !=('F' c:(snag 1 `achs`s))
      ==
    (is-letter c0)
  ?.  ok  ~
  =/  rest  (slag run `achs`s)
  ?:  (starts-with rest (asc "./\\"))  `[(add run 3) %band]
  ?:  (starts-with rest (asc ".\\/"))  `[(add run 3) %bor]
  ~
::
++  match-proof
  ::  the five proof-step lexemes; longest wins, declaration order ties
  |=  s=achs
  ^-  (unit [len=@ud kind=@tas])
  ?~  s  ~
  ?.  =('<' c.i.s)  ~
  =/  body  t.s
  =/  dl  (run-while body is-digit)
  =/  [lvl=@ud implicit=?]
    ?:  (gth dl 0)  [dl |]
    ?~  body  [0 |]
    ?:  |(=('+' c.i.body) =('*' c.i.body))  [1 &]
    [0 |]
  ?:  =(0 lvl)  ~
  =/  aft-lvl  (slag lvl body)
  ?~  aft-lvl  ~
  ?.  =('>' c.i.aft-lvl)  ~
  =/  base  (add 2 lvl)
  =/  suf  t.aft-lvl
  ::  candidates in declaration order
  =/  step=(unit @ud)
    ?:  implicit  ~
    =/  m  (run-while suf is-word)
    ?:(=(0 m) ~ `(add base m))
  =/  imp=(unit @ud)
    ?.  implicit  ~
    =/  m  (run-while suf is-ld)
    ?:(=(0 m) ~ `(add base m))
  =/  stepdot=(unit @ud)
    =/  m  (run-while suf is-word)
    ?:  =(0 m)  ~
    =/  dots  (run-while (slag m suf) |=(c=@c =(c '.')))
    ?:  =(0 dots)  ~
    `:(add base m dots)
  =/  bare=(unit @ud)  `base
  =/  unnum=(unit @ud)
    ?~  suf  ~
    ?:  |(=('*' c.i.suf) =('-' c.i.suf))
      =/  dots  (run-while t.suf |=(c=@c =(c '.')))
      `:(add base 1 dots)
    =/  dots  (run-while suf |=(c=@c =(c '.')))
    ?:(=(0 dots) ~ `(add base dots))
  =/  cands=(list [len=@ud kind=@tas])
    %+  murn
      ^-  (list [(unit @ud) @tas])
      :~  [step %proofsteplexeme]
          [imp %proofimplicitsteplexeme]
          [stepdot %proofstepdotlexeme]
          [bare %barelevellexeme]
          [unnum %unnumberedsteplexeme]
      ==
    |=  [u=(unit @ud) k=@tas]
    ^-  (unit [@ud @tas])
    ?~(u ~ `[u.u k])
  %+  roll  cands
  |=  [c=[len=@ud kind=@tas] acc=(unit [len=@ud kind=@tas])]
  ?~  acc  `c
  ?:  (gth len.c len.u.acc)  `c
  acc
::
++  match-dashes
  ::  SEPARATOR and in-spec module header
  |=  s=achs
  ^-  (unit [len=@ud kind=@tas])
  =/  run  (run-while s |=(c=@c =(c '-')))
  ?:  (lth run 4)  ~
  =/  bm  (match-module-tail (slag run s))
  ?~  bm  `[run %separator]
  `[(add run u.bm) %bm0]
::
++  match-module-tail
  ::  optional spaces then the MODULE literal; length past the dashes
  |=  s=achs
  ^-  (unit @ud)
  =/  sp  (run-while s |=(c=@c =(c ' ')))
  ?.  (starts-with (slag sp s) (asc "MODULE"))  ~
  `(add sp 6)
::
++  match-equals
  |=  s=achs
  ^-  (unit @ud)
  =/  run  (run-while s |=(c=@c =(c '=')))
  ?:((gte run 4) `run ~)
::
::  +|  String Scanner
::
::
+$  string-result
  $%  [%ok len=@ud]
      [%fail consumed=@ud]
      [%fail-eof ~]
  ==
::
++  scan-string
  ::  s starts at the opening quote
  |=  s=achs
  ^-  string-result
  ?>  ?=(^ s)
  =/  n=@ud  1
  =/  t  `achs`t.s
  |-
  ?~  t  [%fail-eof ~]
  =/  c  c.i.t
  ?:  =('"' c)   [%ok +(n)]
  ?:  |(=('\0a' `@c`c) =('\0d' `@c`c))  [%fail n]
  ?.  =('\\' c)
    $(t t.t, n +(n))
  ?~  t.t  [%fail-eof ~]
  =/  e  c.i.t.t
  ?:  ?|  =('n' e)  =('t' e)  =('r' e)
          =('f' e)  =('\\' e)  =('"' e)
      ==
    $(t t.t.t, n (add 2 n))
  ::  the backslash was consumed; the escape char kills the match
  [%fail +(n)]
::
::  +|  Lexical-Error Formatting (TokenMgrError.LexicalError)
::
::
++  hex4
  |=  n=@
  ^-  tape
  =|  out=tape
  =/  k  4
  |-
  ?:  =(0 k)  out
  =/  d  (mod n 16)
  %=  $
    n    (div n 16)
    k    (dec k)
    out  [(add d ?:((lth d 10) '0' 87)) out]
  ==
::
++  add-escapes
  ::  JavaCC TokenMgrError.addEscapes over code points
  |=  cs=(list @c)
  ^-  tape
  %-  zing
  %+  turn  cs
  |=  c=@c
  ^-  tape
  ?:  =(0 c)  ""
  ?:  =(8 c)     "\\b"
  ?:  =(9 c)     "\\t"
  ?:  =(10 c)    "\\n"
  ?:  =(12 c)    "\\f"
  ?:  =(13 c)    "\\r"
  ?:  =('"' c)   "\\\""
  ?:  =('\'' c)  "\\'"
  ?:  =('\\' c)  "\\\\"
  ?:  &((gte c 0x20) (lte c 0x7e))  (utf8-tape:src ~[c])
  (weld "\\u" (hex4 c))
::
++  render-err
  |=  [eof=? l=@ud c=@ud after=(list @c) cur=@c]
  ^-  @t
  %-  crip
  ;:  welp
    "Lexical error at line "
    (dec-tape l)
    ", column "
    (dec-tape c)
    ".  Encountered: "
    ?:  eof  "<EOF> "
    ;:  welp
      "\""
      (add-escapes ~[cur])
      "\" ("
      (dec-tape `@ud`cur)
      "), "
    ==
    "after : \""
    (add-escapes after)
    "\""
  ==
::
::  +|  Comment Scanners
::
::
++  mk-com
  |=  piece=achs
  ^-  item
  ?>  ?=(^ piece)
  =/  las  (rear piece)
  :+  %com
    (crip (utf8-tape:src (cs-of piece)))
  [[l.i.piece col.i.piece] [l.las col.las]]
::
++  open-len
  ::  block-comment opener length at s: 3 for (*., 2 for (*, else 0
  |=  s=achs
  ^-  @ud
  ?:  (starts-with s (asc "(*."))  3
  ?:  (starts-with s (asc "(*"))   2
  0
::
++  scan-block
  ::  whole block comment; one %com item per SPECIAL_TOKEN boundary
  |=  [s=achs eofp=[l=@ud c=@ud]]
  ^-  [items=(list item) rest=achs]
  =/  opening  (open-len s)
  =/  bl  ?~(s l.eofp l.i.s)
  =/  bufr=achs  (flop (scag opening `achs`s))
  =/  rest=achs  (slag opening `achs`s)
  =/  emb=@ud  0
  =|  out=(list item)
  |-  ^-  [(list item) achs]
  ?~  rest
    :_  ~
    %-  flop
    ^-  (list item)
    [[%err (render-err & l.eofp c.eofp ~ `@c`0) bl l.eofp] out]
  =/  ol  (open-len rest)
  ?:  (gth ol 0)
    =/  piece  (weld (flop bufr) (scag ol `achs`rest))
    %=  $
      out   [(mk-com piece) out]
      rest  (slag ol `achs`rest)
      bufr  ~
      emb   +(emb)
    ==
  ?:  (starts-with rest (asc "*)"))
    =/  piece  (weld (flop bufr) (scag 2 `achs`rest))
    =/  nrest  (slag 2 `achs`rest)
    ?:  =(0 emb)
      [(flop [(mk-com piece) out]) nrest]
    %=  $
      out   [(mk-com piece) out]
      rest  nrest
      bufr  ~
      emb   (dec emb)
    ==
  $(rest t.rest, bufr [i.rest bufr])
::
++  scan-eol
  ::  \* to end of line; the newline is part of the comment image
  |=  [s=achs eofp=[l=@ud c=@ud]]
  ^-  [items=(list item) rest=achs]
  =/  bl  ?~(s l.eofp l.i.s)
  =/  bufr=achs  (flop (scag 2 `achs`s))
  =/  rest=achs  (slag 2 `achs`s)
  |-  ^-  [(list item) achs]
  ?~  rest
    [[%err (render-err & l.eofp c.eofp ~ `@c`0) bl l.eofp]~ ~]
  =/  c  `@c`c.i.rest
  ?:  =('\0d' c)
    =/  two  ?:((starts-with t.rest (asc "\0a")) 2 1)
    =/  piece  (weld (flop bufr) (scag two `achs`rest))
    [[(mk-com piece)]~ (slag two `achs`rest)]
  ?:  =('\0a' c)
    =/  piece  (weld (flop bufr) (scag 1 `achs`rest))
    [[(mk-com piece)]~ (slag 1 `achs`rest)]
  $(rest t.rest, bufr [i.rest bufr])
::
::  +|  Main Loop
::
::
++  has-err
  |=  is=(list item)
  ^-  ?
  (lien is |=(i=item ?=(%err -.i)))
::
++  lex  |=(text=@t (lex-in text %default))
::  lex a .cfg file: TLC's ModelConfig drives the token manager directly in
::  lexstate SPEC (=2), bypassing module-frame detection, so we seed %spec
::  with depth=1/saw=& (no ---- BEGIN_MODULE precedes the tokens).
++  lex-cfg  |=(text=@t (lex-in text %spec))
++  lex-in
  |=  [text=@t start=?(%default %pragma %spec)]
  ^-  (list item)
  =/  all  (annotate:src text)
  =/  eofp  (eof-pos:src all)
  =/  s  all
  =/  state=?(%default %pragma %spec)  start
  =/  depth=@ud  ?:(=(%spec start) 1 0)
  =/  saw=?  =(%spec start)
  =|  out=(list item)
  |-  ^-  (list item)
  ?~  s  (flop out)
  ?-    state
      %default
    =/  dash  (run-while s |=(c=@c =(c '-')))
    ?:  (gte dash 4)
      =/  tail  (match-module-tail (slag dash `achs`s))
      ?~  tail  $(s t.s)
      =/  len  (add dash u.tail)
      %=  $
        s      (slag len `achs`s)
        state  %spec
        depth  1
        saw    &
        out    [[%tok (mk-token %bm1 (scag len `achs`s))] out]
      ==
    ?:  &(=(3 dash) (starts-with (slag 3 `achs`s) (asc ">")))
      %=  $
        s      (slag 4 `achs`s)
        state  %pragma
        out    [[%tok (mk-token %begin-pragma (scag 4 `achs`s))] out]
      ==
    $(s t.s)
  ::
      %pragma
    =/  dash  (run-while s |=(c=@c =(c '-')))
    ?:  (gte dash 4)
      =/  tail  (match-module-tail (slag dash `achs`s))
      ?~  tail  $(s t.s)
      =/  len  (add dash u.tail)
      %=  $
        s      (slag len `achs`s)
        state  %spec
        depth  1
        saw    &
        out    [[%tok (mk-token %bm2 (scag len `achs`s))] out]
      ==
    ?:  (is-digit c.i.s)
      =/  n  (run-while s is-digit)
      %=  $
        s    (slag n `achs`s)
        out  [[%tok (mk-token %number (scag n `achs`s))] out]
      ==
    $(s t.s)
  ::
      %spec
    ?:  (is-space c.i.s)  $(s t.s)
    ?:  (gth (open-len s) 0)
      =/  res  (scan-block s eofp)
      =.  out  (weld (flop items.res) out)
      ?:  (has-err items.res)  (flop out)
      $(s rest.res)
    ?:  (starts-with s (asc "\\*"))
      =/  res  (scan-eol s eofp)
      =.  out  (weld (flop items.res) out)
      ?:  (has-err items.res)  (flop out)
      $(s rest.res)
    ?:  =('"' `@c`c.i.s)
      =/  res  (scan-string s)
      ?-    -.res
          %ok
        =/  tok  (mk-token %string-literal (scag len.res `achs`s))
        $(s (slag len.res `achs`s), out [[%tok tok] out])
      ::
          %fail
        =/  killer  (snag consumed.res `achs`s)
        =/  after  (cs-of (scag consumed.res `achs`s))
        %-  flop
        ^-  (list item)
        :_  out
        [%err (render-err | l.killer col.killer after c.killer) l.i.s l.killer]
      ::
          %fail-eof
        =/  after
          =/  n  (lent s)
          ?:  (lte n 1)  ~
          (cs-of s)
        %-  flop
        ^-  (list item)
        :_  out
        [%err (render-err & l.eofp c.eofp after `@c`0) l.i.s l.eofp]
      ==
    ::  general maximal munch
    =/  fixed  (match-fixed s)
    =/  cands=(list [len=@ud kind=@tas rank=@ud])
      %-  zing
      ^-  (list (list [len=@ud kind=@tas rank=@ud]))
      :~  =/  m  (match-dashes s)
          ?~(m ~ [[len.u.m kind.u.m 10] ~])
        ::
          =/  m  (match-equals s)
          ?~(m ~ [[u.m %end-module 10] ~])
        ::
          ?~(best.fixed ~ [[len.u.best.fixed kind.u.best.fixed 20] ~])
        ::
          =/  m  (match-number s)
          ?~(m ~ [[u.m %number-literal 30] ~])
        ::
          =/  m  (match-junction s)
          ?~(m ~ [[len.u.m kind.u.m 40] ~])
        ::
          =/  m  (match-word s)
          ?~(m ~ [[u.m %identifier 60] ~])
        ::
          =/  m  (match-proof s)
          ?~(m ~ [[len.u.m kind.u.m 70] ~])
      ==
    =/  best=(unit [len=@ud kind=@tas rank=@ud])
      %+  roll  cands
      |=  [c=[len=@ud kind=@tas rank=@ud] acc=(unit [len=@ud kind=@tas rank=@ud])]
      ?~  acc  `c
      ?:  (gth len.c len.u.acc)  `c
      ?:  &(=(len.c len.u.acc) (lth rank.c rank.u.acc))  `c
      acc
    ?~  best
      ::  no accept: consume the live prefix, then report
      =/  alive  alive.fixed
      =/  after  (cs-of (scag alive `achs`s))
      =/  killer  (slag alive `achs`s)
      ?~  killer
        =/  aft  ?:((lte alive 1) ~ after)
        %-  flop
        `(list item)`[[%err (render-err & l.eofp c.eofp aft `@c`0) l.i.s l.eofp] out]
      %-  flop
      ^-  (list item)
      :_  out
      [%err (render-err | l.i.killer col.i.killer after c.i.killer) l.i.s l.i.killer]
    =/  tok  (mk-token kind.u.best (scag len.u.best `achs`s))
    =/  ndepth
      ?:  ?=(?(%bm0 %bm1 %bm2) kind.u.best)  +(depth)
      ?:  ?=(%end-module kind.u.best)
        ?:((gth depth 0) (dec depth) 0)
      depth
    =/  nsaw  |(saw ?=(?(%bm0 %bm1 %bm2) kind.u.best))
    =.  out  [[%tok tok] out]
    ?:  &(nsaw =(0 ndepth) ?=(%end-module kind.u.best))
      (flop out)
    %=  $
      s      (slag len.u.best `achs`s)
      depth  ndepth
      saw    nsaw
    ==
  ==
::
::  +|  Differential Dump
::
::
++  esc-image
  |=  t=@t
  ^-  tape
  %-  zing
  %+  turn  (trip t)
  |=  c=@tD
  ^-  tape
  ?:  =('\\' c)   "\\\\"
  ?:  =('\0a' c)  "\\n"
  ?:  =('\0d' c)  "\\r"
  ?:  =('\09' c)  "\\t"
  [c ~]
::
++  span-tape
  |=  sp=span
  ^-  tape
  ;:  welp
    (dec-tape line.from.sp)  "."  (dec-tape col.from.sp)
    " "
    (dec-tape line.to.sp)  "."  (dec-tape col.to.sp)
  ==
::
++  dump
  ::  one line per item, matching the Java TokenDump format
  |=  text=@t
  ^-  wain
  %+  turn  (lex text)
  |=  it=item
  ^-  @t
  ?-    -.it
      %tok
    %-  crip
    ;:  welp
      "T "  (trip kind.token.it)  " "
      (span-tape span.token.it)  " "
      (esc-image text.token.it)
    ==
  ::
      %com
    %-  crip
    ;:  welp
      "C "  (span-tape span.it)  " "  (esc-image text.it)
    ==
  ::
      %err
    (crip (welp "E " (esc-image msg.it)))
  ==
--
