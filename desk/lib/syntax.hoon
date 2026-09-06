/-  *tla-lus
/=  lex  /lib/lexer
/=  ast  /lib/ast
/=  src  /lib/source
|%
  ::  Native TLA+ Syntactic Analyzer
  ::
  ::  Port of the tla+.jj productions plus the hand-written
  ::  Operators/OperatorStack precedence engine at the pinned commit
  ::  (design notes: tools/notes/unit4-parser-notes.md). Produces the
  ::  same concrete syntax tree SANY builds, dumped in the AstDump.java
  ::  differential format.
  ::
  ::  v1 coverage: module frame, EXTENDS, VARIABLE/CONSTANT/RECURSIVE,
  ::  operator definitions with identifier LHS, and the expression
  ::  engine (prefix/infix/postfix/nfix via the operator stack, function
  ::  application, record access, parens, tuples, IF/LET/CASE, junction
  ::  lists with column discipline).
  ::
::  +|  Types
::
+$  node  syntax-node:ast
::  operator-table entry
+$  oper  [name=@t lo=@ud hi=@ud assoc=?(%none %left %right) fix=?(%prefix %postfix %infix %nfix)]
::  operator-stack element: op=~ for plain expressions
+$  osel  [n=(unit node) op=(unit oper)]
::  parse state: token stream + junction-list context + the SANY error
::  bookkeeping (unit 2): the bpa production stack, the `expecting`
::  string, the last consumed token, the current module name (for
::  Location.toString rendering), and the EOF position
+$  pst
  $:  rest=(list token)
      jctx=(list [b=@tas col=@ud])
      plv=(list (unit @ud))
      stk=(list [name=@t at=pos])
      exp=@t
      last=(unit token)
      mname=@t
      eofp=pos
  ==
::  parse result; the @t error is the fully rendered SANY error text
::  (multiple errors joined by the \01 separator, split by +dump-err)
++  pres  |$  [a]  (each [v=a s=pst] @t)
::
::  +|  Operator Table (Operators.java)
::
::
++  void-op  ^-  oper  ['$$_void' 0 0 %none %infix]
++  fcn-op   ^-  oper  ['[' 160 160 %left %postfix]
::
++  canon-ops
  ^-  (list oper)
  :~  ['[' 160 160 %left %postfix]
      ['.' 170 170 %left %infix]
      ['\'' 150 150 %none %postfix]
      ['^' 140 140 %none %infix]
      ['/' 130 130 %none %infix]
      ['*' 130 130 %left %infix]
      ['-' 110 110 %left %infix]
      ['-.' 120 120 %none %prefix]
      ['+' 100 100 %left %infix]
      ['=' 50 50 %none %infix]
      ['\\lnot' 40 40 %left %prefix]
      ['\\land' 30 30 %left %infix]
      ['\\lor' 30 30 %left %infix]
      ['~>' 20 20 %none %infix]
      ['=>' 10 10 %none %infix]
      ['[]' 40 150 %none %prefix]
      ['<>' 40 150 %none %prefix]
      ['ENABLED' 40 150 %none %prefix]
      ['UNCHANGED' 40 150 %none %prefix]
      ['SUBSET' 100 130 %none %prefix]
      ['UNION' 100 130 %none %prefix]
      ['DOMAIN' 100 130 %none %prefix]
      ['^+' 150 150 %none %postfix]
      ['^*' 150 150 %none %postfix]
      ['^#' 150 150 %none %postfix]
      ['\\cdot' 50 140 %left %infix]
      ['\\equiv' 20 20 %none %infix]
      ['-+->' 20 20 %none %infix]
      ['/=' 50 50 %none %infix]
      ['\\subseteq' 50 50 %none %infix]
      ['\\in' 50 50 %none %infix]
      ['\\notin' 50 50 %none %infix]
      ['<' 50 50 %none %infix]
      ['\\leq' 50 50 %none %infix]
      ['>' 50 50 %none %infix]
      ['\\geq' 50 50 %none %infix]
      ['\\times' 100 130 %left %nfix]
      ['\\' 80 80 %none %infix]
      ['\\intersect' 80 80 %left %infix]
      ['\\union' 80 80 %left %infix]
      ['...' 90 90 %none %infix]
      ['..' 90 90 %none %infix]
      ['|' 100 110 %left %infix]
      ['||' 100 110 %left %infix]
      ['&&' 130 130 %left %infix]
      ['&' 130 130 %left %infix]
      ['$$' 90 130 %left %infix]
      ['$' 90 130 %left %infix]
      ['??' 90 130 %left %infix]
      ['%%' 100 110 %left %infix]
      ['%' 100 110 %none %infix]
      ['##' 90 130 %left %infix]
      ['++' 100 100 %left %infix]
      ['--' 110 110 %left %infix]
      ['**' 130 130 %left %infix]
      ['//' 130 130 %none %infix]
      ['^^' 140 140 %none %infix]
      ['@@' 60 60 %left %infix]
      ['!!' 90 130 %none %infix]
      ['|-' 50 50 %none %infix]
      ['|=' 50 50 %none %infix]
      ['-|' 50 50 %none %infix]
      ['=|' 50 50 %none %infix]
      ['<:' 70 70 %none %infix]
      [':>' 70 70 %none %infix]
      [':=' 50 50 %none %infix]
      ['::=' 50 50 %none %infix]
      ['\\oplus' 100 100 %left %infix]
      ['\\ominus' 110 110 %left %infix]
      ['\\odot' 130 130 %left %infix]
      ['\\oslash' 130 130 %none %infix]
      ['\\otimes' 130 130 %left %infix]
      ['\\uplus' 90 130 %left %infix]
      ['\\sqcap' 90 130 %left %infix]
      ['\\sqcup' 90 130 %left %infix]
      ['\\div' 130 130 %none %infix]
      ['\\wr' 90 140 %none %infix]
      ['\\star' 130 130 %left %infix]
      ['\\o' 130 130 %left %infix]
      ['\\bigcirc' 130 130 %left %infix]
      ['\\bullet' 130 130 %left %infix]
      ['\\prec' 50 50 %none %infix]
      ['\\succ' 50 50 %none %infix]
      ['\\preceq' 50 50 %none %infix]
      ['\\succeq' 50 50 %none %infix]
      ['\\sim' 50 50 %none %infix]
      ['\\simeq' 50 50 %none %infix]
      ['\\ll' 50 50 %none %infix]
      ['\\gg' 50 50 %none %infix]
      ['\\asymp' 50 50 %none %infix]
      ['\\subset' 50 50 %none %infix]
      ['\\supset' 50 50 %none %infix]
      ['\\supseteq' 50 50 %none %infix]
      ['\\approx' 50 50 %none %infix]
      ['\\cong' 50 50 %none %infix]
      ['\\sqsubset' 50 50 %none %infix]
      ['\\sqsubseteq' 50 50 %none %infix]
      ['\\sqsupset' 50 50 %none %infix]
      ['\\sqsupseteq' 50 50 %none %infix]
      ['\\doteq' 50 50 %none %infix]
      ['\\propto' 50 50 %none %infix]
  ==
::
++  synonym-pairs
  ^-  (list [@t @t])
  :~  ['~' '\\lnot']      ['\\neg' '\\lnot']   ['¬' '\\lnot']
      ['□' '[]']          ['◇' '<>']
      ['/\\' '\\land']    ['∧' '\\land']
      ['\\/' '\\lor']     ['∨' '\\lor']
      ['<=>' '\\equiv']   ['≡' '\\equiv']      ['⇔' '\\equiv']
      ['#' '/=']          ['≠' '/=']
      ['<=' '\\leq']      ['=<' '\\leq']       ['≤' '\\leq']
      ['>=' '\\geq']      ['≥' '\\geq']
      ['\\X' '\\times']   ['×' '\\times']
      ['\\cap' '\\intersect']  ['∩' '\\intersect']
      ['\\cup' '\\union']      ['∪' '\\union']
      ['\\circ' '\\o']    ['∘' '\\o']
      ['(+)' '\\oplus']   ['⊕' '\\oplus']
      ['(-)' '\\ominus']  ['⊖' '\\ominus']
      ['(.)' '\\odot']    ['⊙' '\\odot']
      ['(/)' '\\oslash']  ['⊘' '\\oslash']
      ['(\\X)' '\\otimes']  ['⊗' '\\otimes']
      ['≈' '\\approx']    ['≔' ':=']
      ['≍' '\\asymp']     ['◯' '\\bigcirc']
      ['⩴' '::=']         ['●' '\\bullet']
      ['⋅' '\\cdot']      ['≅' '\\cong']
      ['÷' '\\div']       ['≐' '\\doteq']
      ['‥' '..']          ['…' '...']
      ['‼' '!!']          ['≫' '\\gg']
      ['⇒' '=>']          ['∈' '\\in']
      ['⫤' '=|']          ['↝' '~>']
      ['≪' '\\ll']        ['⊣' '-|']
      ['∉' '\\notin']     ['⇸' '-+->']
      ['≺' '\\prec']      ['⪯' '\\preceq']
      ['∝' '\\propto']    ['⁇' '??']
      ['⊨' '|=']          ['⊢' '|-']
      ['∼' '\\sim']       ['≃' '\\simeq']
      ['⊓' '\\sqcap']     ['⊔' '\\sqcup']
      ['⊏' '\\sqsubset']  ['⊑' '\\sqsubseteq']
      ['⊐' '\\sqsupset']  ['⊒' '\\sqsupseteq']
      ['⋆' '\\star']      ['⊂' '\\subset']
      ['⊆' '\\subseteq']  ['≻' '\\succ']
      ['⪰' '\\succeq']    ['⊃' '\\supset']
      ['⊇' '\\supseteq']  ['⊎' '\\uplus']
      ['‖' '||']          ['≀' '\\wr']
      ['⁺' '^+']
  ==
::
++  op-table
  ^-  (map @t oper)
  =/  base
    %-  malt
    %+  turn  canon-ops
    |=(o=oper [name.o o])
  %+  roll  synonym-pairs
  |=  [[alt=@t can=@t] acc=_base]
  (~(put by acc) alt (~(got by acc) can))
::
::  +|  Token Classification
::
::
++  is-op-kind
  ::  token kinds that participate in the operator stack
  |=  k=@tas
  ^-  ?
  ?:  ?=(?(%and %or %in %equals %casesep) k)  &
  =/  t  (trip k)
  ?&  (gte (lent t) 3)
      =("op-" (scag 3 t))
  ==
::
++  oper-of
  |=  tok=token
  ^-  (unit oper)
  ?.  (is-op-kind kind.tok)  ~
  (~(get by op-table) text.tok)
::
++  class-of
  ::  stack position class for a token, if any
  |=  tok=token
  ^-  (unit ?(%prefix %postfix %infix))
  =/  o  (oper-of tok)
  ?~  o  ~
  ?-  fix.u.o
    %prefix   `%prefix
    %postfix  `%postfix
    %infix    `%infix
    %nfix     `%infix
  ==
::
::  +|  State Helpers
::
::
++  peek
  |=  s=pst
  ^-  (unit token)
  ?~(rest.s ~ `i.rest.s)
::
++  advance
  |=  s=pst
  ^-  pst
  ?~(rest.s s s(rest t.rest.s, last `i.rest.s))
::
++  eat
  ::  consume one token of the given kind; failure renders the JavaCC
  ::  jj_consume_token error (Encountered ... and token ...)
  |=  [s=pst k=@tas]
  ^-  (pres token)
  ?~  rest.s
    [%| (perr-enc s 1)]
  ?.  =(k kind.i.rest.s)
    [%| (perr-enc s 1)]
  [%& i.rest.s s(rest t.rest.s, last `i.rest.s)]
::
++  fail-at
  ::  legacy helper kept for internal-only failure paths
  |=  [msg=@t tok=token]
  ^-  @t
  %-  crip
  ;:  welp
    (trip msg)
    " at line "
    (dec-tape:ast line.from.span.tok)
    ", column "
    (dec-tape:ast col.from.span.tok)
  ==
::
::  +|  SANY Error Rendering (unit 2)
::
::  Reproduces TLAplusParser.parse()'s error text byte-for-byte: the
::  ***Parse Error*** block with the optional `Was expecting`, the JavaCC
::  Encountered line, and the top of the bpa production stack.
::
++  bpa
  ::  production entry: push [name next-token-pos], clear expecting
  |=  [s=pst name=@t]
  ^-  pst
  s(stk [[name (peek-pos s)] stk.s], exp '')
::
++  epa
  ::  production exit: pop the entry, clear expecting
  |=  s=pst
  ^-  pst
  s(stk ?~(stk.s ~ t.stk.s), exp '')
::
++  set-exp
  |=  [s=pst e=@t]
  ^-  pst
  s(exp e)
::
++  peek-pos
  |=  s=pst
  ^-  pos
  ?~(rest.s eofp.s from.span.i.rest.s)
::
++  esc-image
  ::  JavaCC ParseException.add_escapes over a token image
  |=  img=@t
  ^-  tape
  %-  zing
  %+  turn  (img-codes img)
  |=  c=@c
  ^-  tape
  ?+  c
      ?:  &((gte c 0x20) (lte c 0x7e))  [`@tD`c ~]
      =/  hex  (render-hex c)
      "\\u{hex}"
    %8   "\\b"
    %9   "\\t"
    %10  "\\n"
    %12  "\\f"
    %13  "\\r"
    %34  "\\\""
    %39  "\\'"
    %92  "\\\\"
  ==
::
++  raw-image
  ::  a token image as printed raw in the Encountered echo; non-ascii
  ::  code points pass through as their UTF-8 bytes
  |=  img=@t
  ^-  tape
  (trip img)
::
++  img-codes
  ::  code points of a cord (zuse +tuba crashes on control chars)
  |=  img=@t
  ^-  (list @c)
  (turn (annotate:src img) |=(a=ach:src c.a))
::
++  render-hex
  ::  four lowercase hex digits, JavaCC add_escapes style
  |=  c=@c
  ^-  tape
  =/  raw  `tape`((x-co:co 4) c)
  %+  turn  raw
  |=  h=@tD
  ?:(&((gte h 'A') (lte h 'Z')) `@tD`(add h 32) h)
::
++  belch-index
  ::  where belchDEF would splice its "Beginning of definition" token:
  ::  the index (in toks) of the first token of the next definition LHS,
  ::  found by scanning for == exactly as TLAplusParser.belchDEF does
  |=  toks=(list token)
  ^-  (unit @ud)
  =/  n  (lent toks)
  =/  j  0
  |-  ^-  (unit @ud)
  ::  currentT = toks[j]; nextT = toks[j+1]; stop when nextT is a stopper
  ?:  (gte +(j) n)  ~
  =/  nxt  kind:(snag +(j) toks)
  ?:  ?=(?(%theorem %proposition %assumption %end-module) nxt)  ~
  ?.  =(%def kind:(snag j toks))
    $(j +(j))
  ?:  =(0 j)  `0
  `(belch-back toks (dec j))
::
++  belch-back
  ::  toks[i] is the token before ==; return the LHS start index
  |=  [toks=(list token) i=@ud]
  ^-  @ud
  =/  prev  (snag i toks)
  ?:  ?=(?(%rbr %rsb) kind.prev)
    ::  back over the balanced ( ) or [ ] group, then a leading identifier
    =/  depth  1
    =/  j  i
    |-  ^-  @ud
    ?:  =(0 j)  0
    =/  j1  (dec j)
    =/  k  kind:(snag j1 toks)
    ?:  &(?=(?(%lbr %lsb) k) =(1 depth))
      ?:  &(!=(0 j1) =(%identifier kind:(snag (dec j1) toks)))
        (dec j1)
      j1
    ?:  ?=(?(%lbr %lsb) k)  $(j j1, depth (dec depth))
    ?:  ?=(?(%rbr %rsb) k)  $(j j1, depth +(depth))
    $(j j1)
  ?:  =(%identifier kind.prev)
    ::  identifier possibly preceded by an infix/prefix operator
    ?:  =(0 i)  i
    =/  j1  (dec i)
    =/  pk  (snag j1 toks)
    ?.  ?&  (is-op-kind kind.pk)
            !?=([~ %postfix] (class-of pk))
            ?|  !?=([~ %infix] (class-of pk))
                &(!=(0 j1) =(%identifier kind:(snag (dec j1) toks)))
            ==
        ==
      i
    ?:  &(!=(0 j1) =(%substitute kind:(snag (dec j1) toks)))
      i
    ?:  ?=([~ %infix] (class-of pk))
      ?:(=(0 j1) j1 (dec j1))
    j1
  ::  not an identifier: an operator backs up one more token
  ?:  &((is-op-kind kind.prev) !=(0 i))
    (dec i)
  i
::
++  echo-toks
  ::  the JavaCC `Encountered "<tokens>"` echo: n token images from the
  ::  failing position; a spliced DEFBREAK renders as its synthetic image
  |=  [s=pst n=@ud brk=?]
  ^-  tape
  =/  bi=(unit @ud)  ?.(brk ~ (belch-index rest.s))
  =/  toks  rest.s
  =/  i  0
  =|  out=(list tape)
  |-  ^-  tape
  ?:  =(i n)  (zing (join " " (flop out)))
  ?:  &(?=(^ bi) =(u.bi i))
    ::  the synthetic token occupies one echo slot
    $(i +(i), out ["Beginning of definition" out], bi `(unit @ud)`~)
  ?~  toks
    (zing (join " " (flop `(list tape)`["<EOF>" out])))
  $(i +(i), toks t.toks, out [(raw-image text.i.toks) out])
::
++  encountered
  ::  ParseExceptionExtended.getShortMessage for a consume failure
  |=  [s=pst n=@ud brk=?]
  ^-  tape
  =/  at=pos  (peek-pos s)
  ;:  welp
    "Encountered \""
    (echo-toks s n brk)
    "\" at line "
    (dec-tape:ast line.at)
    ", column "
    (dec-tape:ast col.at)
    " and token \""
    ?~(last.s "" (esc-image text.u.last.s))
    "\" "
  ==
::
++  perr
  ::  the ***Parse Error*** block around a short message
  |=  [s=pst short=tape]
  ^-  @t
  %-  crip
  ;:  welp
    "***Parse Error***\0a"
    ?:  =('' exp.s)  ""
    "Was expecting \"{(trip exp.s)}\"\0a"
    short
    "\0a\0aResidual stack trace follows:\0a"
    (stack-tape stk.s)
  ==
::
++  perr-enc
  |=  [s=pst n=@ud]
  ^-  @t
  (perr s (encountered s n |))
::
++  perr-brk
  ::  Encountered echo with belchDEF splice substitution
  |=  [s=pst n=@ud]
  ^-  @t
  (perr s (encountered s n &))
::
++  stack-tape
  ::  top five production entries, most recent first
  |=  stk=(list [name=@t at=pos])
  ^-  tape
  %-  zing
  %+  turn  (scag 5 stk)
  |=  [name=@t at=pos]
  ^-  tape
  ;:  welp
    (trip name)
    " starting at line "
    (dec-tape:ast line.at)
    ", column "
    (dec-tape:ast col.at)
    ".\0a"
  ==
::
++  render-locn
  ::  tla2sany.st.Location.toString for a span in the current module
  |=  [sp=span mname=@t]
  ^-  tape
  ;:  welp
    "line "  (dec-tape:ast line.from.sp)
    ", col "  (dec-tape:ast col.from.sp)
    " to line "  (dec-tape:ast line.to.sp)
    ", col "  (dec-tape:ast col.to.sp)
    " of module "  (trip mname)
  ==
::
++  node-locn
  ::  a node's Location.toString; synthesized nodes have no span
  |=  [n=node mname=@t]
  ^-  tape
  =/  sp  (span-of:ast n)
  ?~  sp  (render-locn [[0 0] [0 0]] mname)
  (render-locn u.sp mname)
::
++  above
  ::  junction column discipline: token must sit right of current bullet
  |=  [s=pst tok=token]
  ^-  ?
  ?~  jctx.s  &
  (gth col.from.span.tok col.i.jctx.s)
::
++  new-bullet
  |=  [s=pst tok=token]
  ^-  ?
  ?~  jctx.s  |
  ?&  ?=(?(%and %or) kind.tok)
      =(kind.tok b.i.jctx.s)
      =(col.from.span.tok col.i.jctx.s)
  ==
::
::  +|  Node Builders
::
::
++  empty-idprefix  ^-  node  [%node %n-idprefix ~ 'N_IdPrefix' ~]
++  empty-node
  |=  kind=@tas
  ^-  node
  [%node kind ~ (~(gut by kind-names:ast) kind '?') ~]
::
++  gen-op-node
  ::  N_Gen*Op [empty-IdPrefix op-leaf-node]
  |=  [gen=@tas leafk=@tas tok=token]
  ^-  node
  (mk-node:ast gen ~[empty-idprefix (tok-node:ast leafk tok)])
::
++  general-id
  |=  tok=token
  ^-  node
  (mk-node:ast %n-generalid ~[empty-idprefix (leaf:ast tok)])
::
::  +|  Operator Stack (OperatorStack.java)
::
::
++  succ  |=([l=oper r=oper] (gth lo.l hi.r))
++  prec  |=([l=oper r=oper] (lth hi.l lo.r))
++  mixfix
  |=  o=oper
  ^-  (unit oper)
  ?:  ?=(%prefix fix.o)  `o
  (~(get by op-table) (cat 3 name.o '.'))
::
++  is-op    |=(e=osel ?=(^ op.e))
++  same-op  |=([a=oper b=oper] =(name.a name.b))
::
++  reduce-infix
  ::  reduce beneath the triggering top element:
  ::  [trig, right, op, left, ..] -> [trig, node, ..]
  |=  [stk=(list osel) o=oper]
  ^-  (list osel)
  ?.  ?=([^ ^ ^ ^ *] stk)  stk
  =/  right  (need n.i.t.stk)
  =/  opn    (need n.i.t.t.stk)
  =/  left   (need n.i.t.t.t.stk)
  =/  new
    ?:  &(?=(%nfix fix.o) ?=(%node -.left) =(%n-times kind.left))
      (mk-node:ast %n-times (welp kids.left ~[opn right]))
    ?:  ?=(%nfix fix.o)
      (mk-node:ast %n-times ~[left opn right])
    (mk-node:ast %n-infixexpr ~[left opn right])
  [i.stk [`new ~] t.t.t.t.stk]
::
++  reduce-prefix
  ::  [trig, operand, op, ..] -> [trig, node, ..]
  |=  stk=(list osel)
  ^-  (list osel)
  ?.  ?=([^ ^ ^ *] stk)  stk
  =/  operand  (need n.i.t.stk)
  =/  opn      (need n.i.t.t.stk)
  [i.stk [`(mk-node:ast %n-prefixexpr ~[opn operand]) ~] t.t.t.stk]
::
++  reduce-postfix
  ::  [trig, op, operand, ..] -> [trig, node, ..]; fcn-op = N_FcnAppl
  |=  stk=(list osel)
  ^-  (list osel)
  ?.  ?=([^ ^ ^ *] stk)  stk
  =/  o     (need op.i.t.stk)
  =/  opn   (need n.i.t.stk)
  =/  operand  (need n.i.t.t.stk)
  =/  new
    ?.  =(name:fcn-op name.o)
      (mk-node:ast %n-postfixexpr ~[operand opn])
    ?>  ?=(%node -.opn)
    (mk-node:ast %n-fcnappl [operand kids.opn])
  [i.stk [`new ~] t.t.t.stk]
::
++  osel-locn
  ::  an operator-stack element's Location.toString
  |=  [e=osel mn=@t]
  ^-  tape
  ?~  n.e  (render-locn [[0 0] [0 0]] mn)
  (node-locn u.n.e mn)
::
++  osel-line
  |=  e=osel
  ^-  @ud
  ?~  n.e  0
  =/  sp  (span-of:ast u.n.e)
  ?~(sp 0 line.from.u.sp)
::
++  follow-err
  ::  two adjacent expressions with no operator between them
  |=  [a=osel b=osel mn=@t]
  ^-  @t
  %-  crip
  ;:  welp
    "Expression at location "  (osel-locn a mn)
    " and expression at location "  (osel-locn b mn)
    " follow each other without any intervening operator."
  ==
::
++  reduce-stack
  ::  the reduceStack() loop; %| carries OperatorStack's exact
  ::  ParseException message text
  |=  [stk=(list osel) mn=@t]
  ^-  (each (list osel) @t)
  |-
  =/  n  (lent stk)
  ?:  =(0 n)  [%& stk]
  ?>  ?=(^ stk)
  =/  tm0  i.stk
  ?.  (is-op tm0)  [%& stk]
  =/  or  (need op.tm0)
  ?-    fix.or
      %postfix
    ?:  =(1 n)
      :-  %|
      %-  crip
      ;:  welp
        "\0a  Encountered postfix op "  (trip name.or)
        " in block "  (osel-locn tm0 mn)
        " on empty stack"
      ==
    ?>  ?=([^ ^ *] stk)
    =/  tm1  i.t.stk
    ?:  (is-op tm1)
      =/  ol  (need op.tm1)
      ?:  ?=(?(%infix %nfix %prefix) fix.ol)
        :-  %|
        %-  crip
        ;:  welp
          "\0a  Encountered postfix op "  (trip name.or)
          " in block "  (osel-locn tm0 mn)
          " following prefix or infix op "  (trip name.ol)  "."
        ==
      $(stk (reduce-postfix stk))
    ?:  (lth n 3)  [%& stk]
    ?>  ?=([^ ^ ^ *] stk)
    =/  tm2  i.t.t.stk
    ?.  (is-op tm2)
      [%| (follow-err tm2 tm1 mn)]
    =/  ol  (need op.tm2)
    ?:  (succ ol or)
      ?:  ?=(?(%infix %nfix) fix.ol)
        $(stk (reduce-infix stk ol))
      $(stk (reduce-prefix stk))
    ?.  (prec ol or)
      :-  %|
      %-  crip
      ;:  welp
        "Precedence conflict between ops "  (trip name.ol)
        " in block "  (osel-locn tm2 mn)
        " and "  (trip name.or)  "."
      ==
    [%& stk]
  ::
      %prefix
    ?:  =(1 n)  [%& stk]
    ?>  ?=([^ ^ *] stk)
    =/  tm1  i.t.stk
    ?.  (is-op tm1)
      :-  %|
      %-  crip
      ;:  welp
        "\0a  Encountered prefix op "  (trip name.or)
        " in block "  (osel-locn tm0 mn)
        " following an expression."
      ==
    =/  ol  (need op.tm1)
    ?:  ?=(%postfix fix.ol)
      :-  %|
      %-  crip
      ;:  welp
        "\0a  Encountered prefix op "  (trip name.or)
        " in block "  (osel-locn tm0 mn)
        " following postfix op "  (trip name.ol)  "."
      ==
    [%& stk]
  ::
      ?(%infix %nfix)
    ?:  =(1 n)
      ?~  (mixfix or)
        :-  %|
        %-  crip
        ;:  welp
          "\0a  Encountered infix op "  (trip name.or)
          " in block "  (osel-locn tm0 mn)
          " on empty stack."
        ==
      [%& stk]
    ?>  ?=([^ ^ *] stk)
    =/  tm1  i.t.stk
    ?:  (is-op tm1)
      =/  ol  (need op.tm1)
      ?:  ?=(%postfix fix.ol)
        $(stk (reduce-postfix stk))
      =/  mixr  (mixfix or)
      ?~  mixr
        ?:  =(name:void-op name.or)
          :-  %|
          %-  crip
          ;:  welp
            "\0a  Missing expression in block "  (osel-locn tm1 mn)
            " following prefix or infix op "  (trip name.ol)  "."
          ==
        :-  %|
        %-  crip
        ;:  welp
          "\0a  Encountered infix op "  (trip name.or)
          " in block "  (osel-locn tm1 mn)
          " following prefix or infix op "  (trip name.ol)  "."
        ==
      ?:  ?|  (succ ol u.mixr)
              &((same-op ol u.mixr) ?=(%left assoc.ol))
          ==
        :-  %|
        %-  crip
        ;:  welp
          "\0a  Precedence conflict between ops "  (trip name.ol)
          " in block "  (osel-locn tm1 mn)
          " and "  (trip name.u.mixr)  "."
        ==
      [%& stk]
    ?:  (lth n 3)  [%& stk]
    ?>  ?=([^ ^ ^ *] stk)
    =/  tm2  i.t.t.stk
    ?.  (is-op tm2)
      [%| (follow-err tm2 tm1 mn)]
    =/  ol  (need op.tm2)
    ::  unary-minus detection: mixfixable op in prefix position
    =/  olx
      =/  mixl  (mixfix ol)
      ?:  ?&  ?=(^ mixl)
              !(same-op u.mixl ol)
              ?|  =(3 n)
                  ?&  ?=([^ ^ ^ ^ *] stk)
                      (is-op i.t.t.t.stk)
                  ==
              ==
          ==
        u.mixl
      ol
    ?:  ?|  (succ olx or)
            &((same-op olx or) ?=(%left assoc.olx))
        ==
      ?:  ?=(?(%infix %nfix) fix.olx)
        $(stk (reduce-infix stk olx))
      ?:  ?=(%prefix fix.olx)
        $(stk (reduce-prefix stk))
      ?:  ?&  (lth (osel-line tm2) (osel-line tm1))
              =('=' name.or)
          ==
        :-  %|
        %-  crip
        ;:  welp
          "\0a  *** Hint *** You may have mistyped =="
          "\0a  Illegal combination of operators "  (trip name.olx)
          " in block "  (osel-locn tm2 mn)
          " and "  (trip name.or)  "."
        ==
      ?:  =(name:void-op name.or)
        :-  %|
        %-  crip
        ;:  welp
          "\0a Error following expression at  "
          (osel-locn tm2 mn)
          ", missing operator or separator."
        ==
      :-  %|
      %-  crip
      ;:  welp
        "\0a  Illegal combination of operators "  (trip name.olx)
        " in block "  (osel-locn tm2 mn)
        " and "  (trip name.or)  "."
      ==
    ?.  ?|  (prec olx or)
            &((same-op olx or) ?=(%right assoc.olx))
        ==
      :-  %|
      %-  crip
      ;:  welp
        "\0a  Precedence conflict between ops "  (trip name.olx)
        " in block "  (osel-locn tm2 mn)
        " and "  (trip name.or)  "."
      ==
    [%& stk]
  ==
::
++  final-reduce
  ::  OperatorStack.finalReduce: a failure yields the raw (unwrapped)
  ::  incomplete-expression text pushed straight onto PErrors
  |=  [stk=(list osel) mn=@t]
  ^-  (each node @t)
  =/  res  (reduce-stack [[~ `void-op] stk] mn)
  ?:  ?=(%| -.res)  res
  =/  out  p.res
  ?:  ?&(?=([^ ^ ~] out) ?=(^ n.i.t.out))
    [%& u.n.i.t.out]
  ::  bottom-first, without the void operator pushed above
  =/  elems  (snip (flop out))
  :-  %|
  %-  crip
  %+  welp  "Couldn't properly parse expression"
  %-  zing
  %+  turn  elems
  |=  e=osel
  ^-  tape
  ;:  welp
    "-- incomplete expression at "
    (osel-locn e mn)
    ".\0a"
  ==
::
++  push-and-reduce
  ::  push an operator element and reduce unless it is alone
  |=  [stk=(list osel) e=osel mn=@t]
  ^-  (each (list osel) @t)
  =/  new  [e stk]
  ?:  ?=([* ~] new)  [%& new]
  (reduce-stack new mn)
::
++  pre-in-empty-top
  |=  stk=(list osel)
  ^-  ?
  ?~  stk  &
  ?~  op.i.stk  |
  ?=(?(%prefix %infix %nfix) fix.u.op.i.stk)
::
::  +|  Expression Parsing
::
::  combined stack+state result for the engine phases
+$  xres  (each [stk=(list osel) s=pst] @t)
::
++  open-start
  ::  tokens beginning an OpenExpression (no ExtendableExpr entry)
  |=  s=pst
  ^-  ?
  =/  pk  (peek s)
  ?~  pk  |
  ?=  $?  %if  %case  %let  %choose
          %exists  %forall  %t-exists  %t-forall
      ==
    kind.u.pk
::
++  expression
  |=  s=pst
  ^-  (pres node)
  =/  stk0  stk.s
  =.  s  (bpa s 'Expression')
  =|  stk=(list osel)
  |-  ^-  (pres node)
  ::  leading prefix operators (unary minus arrives as infix '-')
  =/  pk  (peek s)
  =/  pcls  ?~(pk ~ (class-of u.pk))
  ?:  ?&  ?=(^ pk)
          (above s u.pk)
          ?|  &(?=([~ %prefix] pcls) !=('-.' text.u.pk))
              &(?=([~ %infix] pcls) =('-' text.u.pk))
          ==
      ==
    =/  o  (need (oper-of u.pk))
    =/  gen
      ?:  ?=(%prefix fix.o)
        (gen-op-node %n-genprefixop %n-prefixop u.pk)
      (gen-op-node %n-geninfixop %n-infixop u.pk)
    =/  pr  (push-and-reduce stk [`gen `o] mname.s)
    ?:  ?=(%| -.pr)  [%| (perr s (trip p.pr))]
    $(stk p.pr, s (advance s))
  ::  ExtendableExpr entry, except for open expressions
  =?  s  !(open-start s)  (bpa s 'ExtendableExpr')
  ::  operand, then its postfix/./[ chain
  =/  o1  (operand s stk)
  ?:  ?=(%| -.o1)  [%| p.o1]
  =/  c1  (chain s.p.o1 stk.p.o1)
  ?:  ?=(%| -.c1)  [%| p.c1]
  =.  stk  stk.p.c1
  =.  s    s.p.c1
  ::  infix continuation loops back to the prefix phase
  =/  ik  (peek s)
  =/  icls  ?~(ik ~ (class-of u.ik))
  ?:  ?&  ?=(^ ik)
          (above s u.ik)
          ?=([~ %infix] icls)
      ==
    =/  o  (need (oper-of u.ik))
    =/  gen  (gen-op-node %n-geninfixop %n-infixop u.ik)
    =/  pr  (push-and-reduce stk [`gen `o] mname.s)
    ?:  ?=(%| -.pr)  [%| (perr s (trip p.pr))]
    $(stk p.pr, s (advance s))
  ::  Expression's epa precedes finalReduce, so a reduction failure
  ::  reports the outer context: first the raw incomplete-expression
  ::  push, then the wrapped exception, exactly as parse() does
  =.  s  s(stk stk0, exp '')
  =/  fin  (final-reduce stk mname.s)
  ?:  ?=(%| -.fin)
    [%| (rap 3 ~[p.fin '\01' (perr s " Couldn't reduce expression stack.")])]
  [%& p.fin s]
::
++  operand
  ::  one ExtendableExpr operand pushed onto the stack; each alternative
  ::  enters its SANY production for the residual error stack, restored
  ::  at the join on success
  |=  [s=pst stk=(list osel)]
  ^-  xres
  =/  stk0  stk.s
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  =/  tok  u.pk
  ?.  (above s tok)
    [%| (perr-enc s 1)]
  ?:  ?&  ?=(?(%and %or) kind.tok)
          (pre-in-empty-top stk)
      ==
    =/  jr  (junctions s)
    ?:  ?=(%| -.jr)  [%| p.jr]
    [%& [[`v.p.jr ~] stk] s.p.jr(stk stk0, exp '')]
  =/  er
    ^-  (pres node)
    ?:  (is-op-kind kind.tok)
      (op-ref-operand (bpa s 'Primitive expression'))
    ?+    kind.tok  [%| (perr-enc s 1)]
        %lbr             (paren-expr s)
        %lbc             (set-expr (bpa s 'Some { } form'))
        %lsb             (sbracket-operand (bpa s 'Some [] Form'))
        %number-literal  (number-expr (bpa s 'Primitive expression'))
        %string-literal
      =/  s  (bpa (bpa s 'Primitive expression') 'String')
      [%& (tok-node:ast %n-string (cook-string tok)) (advance s)]
        %identifier      (ident-expr (bpa s 'Primitive expression') stk)
        ?(%proofsteplexeme %proofstepdotlexeme %proofimplicitsteplexeme)
      (ident-expr (bpa s 'Primitive expression') stk)
        %lab             (tuple-expr (bpa s 'Some << -- >> or >>_ Form'))
        %if              (if-then-else (bpa s 'IF THEN ELSE'))
        %let             (let-in (bpa s 'Case Other Arm'))
        %case            (case-expr (bpa s 'CASE Expression'))
        ?(%exists %forall)      (quant-expr (bpa s 'Quantified form'))
        ?(%t-exists %t-forall)
      (unbound-quant (bpa s 'Bound Quantified Expression'))
        %choose          (choose-expr (bpa s '(Un)Bounded Choose'))
        ?(%wf %sf)       (fairness-expr (bpa s 'Fairness Expression'))
        %lambda          (lambda-expr (bpa s 'Lambda'))
    ==
  ?:  ?=(%| -.er)  [%| p.er]
  [%& [[`v.p.er ~] stk] s.p.er(stk stk0, exp '')]
::
++  chain
  ::  postfix ops, record access, and function application
  |=  [s=pst stk=(list osel)]
  ^-  xres
  |-  ^-  xres
  =/  pk  (peek s)
  ?~  pk  [%& stk s]
  ?.  (above s u.pk)  [%& stk s]
  =/  pcls  (class-of u.pk)
  ?:  ?=([~ %postfix] pcls)
    =/  o  (need (oper-of u.pk))
    =/  gen  (gen-op-node %n-genpostfixop %n-postfixop u.pk)
    =/  pr  (push-and-reduce stk [`gen `o] mname.s)
    ?:  ?=(%| -.pr)  [%| (perr s (trip p.pr))]
    $(stk p.pr, s (advance s))
  ?:  =(%dot kind.u.pk)
    =/  dot  (leaf:ast u.pk)
    =.  s  (advance s)
    =/  ir  (eat s %identifier)
    ?:  ?=(%| -.ir)  [%| p.ir]
    =/  rr  (reduce-record stk dot (leaf:ast v.p.ir) mname.s)
    ?:  ?=(%| -.rr)  [%| (perr s (trip p.rr))]
    $(stk p.rr, s s.p.ir)
  ?:  =(%lsb kind.u.pk)
    =/  stk0  stk.s
    =.  s  (set-exp s 'function argument')
    =.  s  (bpa s 'Some [] Form')
    =/  ar  (sbracket-args s)
    ?:  ?=(%| -.ar)  [%| p.ar]
    =.  s  s.p.ar(stk stk0, exp '')
    =/  pr  (push-and-reduce stk [`v.p.ar `fcn-op] mname.s)
    ?:  ?=(%| -.pr)  [%| (perr s (trip p.pr))]
    $(stk p.pr)
  [%& stk s]
::
++  reduce-record
  ::  OperatorStack.reduceRecord: N_RecordComponent [left dot rhs]
  |=  [stk=(list osel) dot=node rhs=node mn=@t]
  ^-  (each (list osel) @t)
  ?~  stk
    :-  %|
    %-  crip
    ;:  welp
      "\0a    ``.'' has no left hand side at "
      (node-locn dot mn)
      "."
    ==
  =/  stk2  `(list osel)`stk
  =?  stk2  ?&  (is-op i.stk)
                ?=(^ t.stk)
                !(is-op i.t.stk)
                =(%postfix fix:(need op.i.stk))
            ==
    ::  humor the trigger-preserving reducer with a dummy top
    =/  tmp  (reduce-postfix [[~ ~] stk2])
    ?~(tmp ~ t.tmp)
  ?>  ?=(^ stk2)
  ?:  (is-op i.stk2)
    :-  %|
    %-  crip
    ;:  welp
      "\0a    ``.'' follows operator "
      (osel-locn i.stk2 mn)
      "."
    ==
  =/  left  (need n.i.stk2)
  =/  rcd  (mk-node:ast %n-recordcomponent ~[left dot rhs])
  [%& [[`rcd ~] t.stk2]]
::
++  sbracket-args
  ::  [ e (, e)* ] as a carrier node; reduce-postfix flattens its kids
  |=  s=pst
  ^-  (pres node)
  =/  lr  (eat s %lsb)
  ?:  ?=(%| -.lr)  [%| p.lr]
  =.  s  s.p.lr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.lr) kids]
  |-  ^-  (pres node)
  ::  an empty argument reports at the enclosing `Some [] Form` level
  ::  without entering Expression (per-caller, R1.3.5.6.4.5)
  =/  pk  (peek s)
  ?:  ?|(?=(~ pk) !(expr-start kind.u.pk))
    [%| (perr-enc s 1)]
  =/  er  (expression s)
  ?:  ?=(%| -.er)  [%| p.er]
  =.  s  s.p.er
  =.  kids  [v.p.er kids]
  =/  nk  (peek s)
  ?:  &(?=(^ nk) =(%comma kind.u.nk))
    =.  kids  [(leaf:ast u.nk) kids]
    $(s (advance s))
  =/  rr  (eat s %rsb)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =.  kids  [(leaf:ast v.p.rr) kids]
  [%& (mk-node:ast %n-fcnappl (flop kids)) s.p.rr]
::
++  junctions
  |=  s=pst
  ^-  (pres node)
  =/  stk0  stk.s
  =.  s  (bpa s 'AND-OR Junction')
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  ?>  ?=(?(%and %or) kind.u.pk)
  =/  bkind  kind.u.pk
  =/  listk  ?:(=(%and bkind) %n-conjlist %n-disjlist)
  =/  itemk  ?:(=(%and bkind) %n-conjitem %n-disjitem)
  =.  jctx.s  [[bkind col.from.span.u.pk] jctx.s]
  =|  items=(list node)
  |-  ^-  (pres node)
  =/  jstk  stk.s
  =.  s  (bpa s 'Junction Item')
  =/  br  (eat s bkind)
  ?:  ?=(%| -.br)  [%| p.br]
  =.  s  s.p.br
  =/  er  (expression s)
  ?:  ?=(%| -.er)  [%| p.er]
  =.  s  s.p.er(stk jstk, exp '')
  =/  item  (mk-node:ast itemk ~[(leaf:ast v.p.br) v.p.er])
  =/  ind  (check-indent s v.p.er item)
  ?^  ind  [%| (perr s (trip u.ind))]
  =.  items  [item items]
  =/  nk  (peek s)
  ?:  &(?=(^ nk) (new-bullet s u.nk))
    $
  ::  pop the junction context before returning
  =.  jctx.s  ?~(jctx.s ~ t.jctx.s)
  [%& (mk-node:ast listk (flop items)) s(stk stk0, exp '')]
::
++  paren-expr
  |=  s=pst
  ^-  (pres node)
  =/  lr  (eat s %lbr)
  ?:  ?=(%| -.lr)  [%| p.lr]
  =/  er  (expression s.p.lr)
  ?:  ?=(%| -.er)  [%| p.er]
  =/  rr  (eat s.p.er %rbr)
  ?:  ?=(%| -.rr)  [%| p.rr]
  :-  %&
  :_  s.p.rr
  %+  mk-node:ast  %n-parenexpr
  ~[(leaf:ast v.p.lr) v.p.er (leaf:ast v.p.rr)]
::
++  ident-expr
  ::  GeneralId (with optional !-IdPrefix) or OpApplication
  |=  [s=pst stk=(list osel)]
  ^-  (pres node)
  =/  gr  (general-id-full s)
  ?:  ?=(%| -.gr)  [%| p.gr]
  =.  s  s.p.gr
  =/  gid  v.p.gr
  =/  nk  (peek s)
  ?:  ?&  ?=(^ nk)
          =(%coloncolon kind.u.nk)
          (above s u.nk)
      ==
    (label-expr (epa s) gid stk)
  ?.  ?&  ?=(^ nk)
          =(%lbr kind.u.nk)
          (above s u.nk)
      ==
    [%& gid s]
  =/  ar  (op-args-tail s)
  ?:  ?=(%| -.ar)  [%| p.ar]
  =.  s  s.p.ar
  =/  app
    (mk-node:ast %n-opapplication ~[gid v.p.ar])
  =/  lk  (peek s)
  ?:  ?&  ?=(^ lk)
          =(%coloncolon kind.u.lk)
          (above s u.lk)
      ==
    (label-expr (epa s) app stk)
  [%& app s]
::
++  general-id-full
  ::  [element!]* final; elements: ident, ident(args), (args),
  ::  structops (<< >> : number); final: ident, operator, or @
  |=  s=pst
  ^-  (pres node)
  =|  elems=(list node)
  |-  ^-  (pres node)
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  =/  k2=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    `i.t.rest.s
  ::  proof-step reference: <1>a ! ...
  ?:  ?&  ?=(?(%proofsteplexeme %proofstepdotlexeme %proofimplicitsteplexeme) kind.u.pk)
          ?=(^ k2)  =(%bang kind.u.k2)
      ==
    =/  ct  (corrected-token s u.pk)
    =/  elem
      (mk-node:ast %n-idprefixelement ~[(leaf:ast ct) (leaf:ast u.k2)])
    $(s (advance (advance s)), elems [elem elems])
  ::  ident !  ->  plain element; a mid-chain `@` is the argument selector
  ::  (N_StructOp), not an identifier — matches SANY (R1.3.5.2)
  ?:  ?&  =(%identifier kind.u.pk)
          ?=(^ k2)  =(%bang kind.u.k2)
      ==
    =/  hd=node
      ?:  &(?=(^ elems) =('@' text.u.pk))
        (tok-node:ast %n-structop u.pk)
      (leaf:ast u.pk)
    =/  elem  (mk-node:ast %n-idprefixelement ~[hd (leaf:ast u.k2)])
    $(s (advance (advance s)), elems [elem elems])
  ::  ident ( args ) !  ->  application element
  ?:  ?&  =(%identifier kind.u.pk)
          ?=(^ k2)  =(%lbr kind.u.k2)
          (bang-after-parens ?~(rest.s ~ t.rest.s))
      ==
    =/  idl  (leaf:ast u.pk)
    =.  s  (advance s)
    =/  ar  (op-args-tail s)
    ?:  ?=(%| -.ar)  [%| p.ar]
    =.  s  s.p.ar
    =/  bk  (peek s)
    ?.  &(?=(^ bk) =(%bang kind.u.bk))
      [%| (perr-enc s 1)]
    =/  elem
      %+  mk-node:ast  %n-idprefixelement
      ~[idl v.p.ar (leaf:ast u.bk)]
    $(s (advance s), elems [elem elems])
  ::  ( args ) !  ->  argument-selection element
  ?:  ?&  =(%lbr kind.u.pk)
          ?=(^ elems)
          (bang-after-parens rest.s)
      ==
    =/  ar  (op-args-tail s)
    ?:  ?=(%| -.ar)  [%| p.ar]
    =.  s  s.p.ar
    =/  bk  (peek s)
    ?.  &(?=(^ bk) =(%bang kind.u.bk))
      [%| (perr-enc s 1)]
    =/  elem
      (mk-node:ast %n-idprefixelement ~[v.p.ar (leaf:ast u.bk)])
    $(s (advance s), elems [elem elems])
  ::  structop !  ->  navigation element
  ?:  ?&  ?=(^ elems)
          ?=(^ k2)  =(%bang kind.u.k2)
          ?=(?(%lab %rab %colon %number-literal) kind.u.pk)
      ==
    =/  sop
      ?:  =(%number-literal kind.u.pk)
        %+  mk-node:ast  %n-structop
        ~[(mk-node:ast %n-number ~[(leaf:ast u.pk)])]
      (tok-node:ast %n-structop u.pk)
    =/  elem
      (mk-node:ast %n-idprefixelement ~[sop (leaf:ast u.k2)])
    $(s (advance (advance s)), elems [elem elems])
  ::  operator-symbol selector element `!++!` / `!++(9,10)!`: an infix/
  ::  prefix/postfix operator used as a mid-chain subexpression selector,
  ::  with optional arguments, followed by a bang. A final operator (no
  ::  trailing bang) falls through to the final segment (R1.3.5.2)
  ?:  ?&  ?=(^ elems)
          (op-sym-tok u.pk)
          (op-sel-mid ?~(rest.s ~ t.rest.s))
      ==
    =/  opn  (op-sel-node u.pk)
    =.  s  (advance s)
    =/  nk  (peek s)
    ?:  &(?=(^ nk) =(%lbr kind.u.nk))
      =/  ar  (op-args-tail s)
      ?:  ?=(%| -.ar)  [%| p.ar]
      =.  s  s.p.ar
      =/  bk  (peek s)
      ?.  &(?=(^ bk) =(%bang kind.u.bk))  [%| (perr-enc s 1)]
      =/  elem
        (mk-node:ast %n-idprefixelement ~[opn v.p.ar (leaf:ast u.bk)])
      $(s (advance s), elems [elem elems])
    ?.  &(?=(^ nk) =(%bang kind.u.nk))  [%| (perr-enc s 1)]
    =/  elem  (mk-node:ast %n-idprefixelement ~[opn (leaf:ast u.nk)])
    $(s (advance s), elems [elem elems])
  ::  ( args )  as the final segment  ->  COp(1, 2)!(3): a trailing `!(args)`
  ::  is an N_OpArgs directly under the N_GeneralId (the preceding `!` was
  ::  consumed with the prior element); the mid-chain `(args)!` form is
  ::  handled above, so reaching here means no bang follows (R1.3.5.2)
  ?:  &(=(%lbr kind.u.pk) ?=(^ elems))
    =/  ar  (op-args-tail s)
    ?:  ?=(%| -.ar)  [%| p.ar]
    =/  pfx  (mk-node:ast %n-idprefix (flop elems))
    [%& (mk-node:ast %n-generalid ~[pfx v.p.ar]) s.p.ar]
  ::  final segment
  =/  fin
    ^-  (each node @t)
    ?:  ?=  $?  %proofsteplexeme  %proofstepdotlexeme
                %proofimplicitsteplexeme
            ==
          kind.u.pk
      [%& (leaf:ast (corrected-token s u.pk))]
    ?:  =(%identifier kind.u.pk)
      ?:  &(?=(^ elems) =('@' text.u.pk))
        [%& (tok-node:ast %n-structop u.pk)]
      [%& (leaf:ast u.pk)]
    ?:  &(?=(^ elems) ?=(?(%lab %rab %colon %number-literal) kind.u.pk))
      ?:  =(%number-literal kind.u.pk)
        :-  %&
        %+  mk-node:ast  %n-structop
        ~[(mk-node:ast %n-number ~[(leaf:ast u.pk)])]
      [%& (tok-node:ast %n-structop u.pk)]
    =/  cls  (class-of u.pk)
    ?:  |(?=([~ %prefix] cls) =('-.' text.u.pk))
      [%& (tok-node:ast %n-nonexpprefixop u.pk)]
    ?:  ?=([~ %infix] cls)
      [%& (tok-node:ast %n-infixop u.pk)]
    ?:  ?=([~ %postfix] cls)
      [%& (tok-node:ast %n-postfixop u.pk)]
    [%| (perr-enc s 1)]
  ?:  ?=(%| -.fin)  [%| p.fin]
  =.  s  (advance s)
  =/  pfx
    ?~  elems  empty-idprefix
    (mk-node:ast %n-idprefix (flop elems))
  [%& (mk-node:ast %n-generalid ~[pfx p.fin]) s]
::
++  bang-after-parens
  ::  preview: toks start at lbr; after the balanced rbr comes a bang
  |=  toks=(list token)
  ^-  ?
  ?~  toks  |
  ?.  =(%lbr kind.i.toks)  |
  =/  depth  1
  =/  t  t.toks
  |-  ^-  ?
  ?~  t  |
  ?:  =(0 depth)  =(%bang kind.i.t)
  ?:  =(%lbr kind.i.t)  $(t t.t, depth +(depth))
  ?:  =(%rbr kind.i.t)  $(t t.t, depth (dec depth))
  $(t t.t)
::
++  op-sym-tok
  ::  the token is an infix/prefix/postfix operator symbol, usable as a
  ::  subexpression selector (`!++`, `!^+`, ...) — R1.3.5.2
  |=  tok=token
  ^-  ?
  ?:  =('-.' text.tok)  &
  ?=(^ (class-of tok))
::
++  op-sel-node
  ::  the CST node for an operator symbol used as a subexpression selector,
  ::  by fixity class (mirrors the final-segment / op-ref-operand mapping)
  |=  tok=token
  ^-  node
  =/  cls  (class-of tok)
  ?:  |(?=([~ %prefix] cls) =('-.' text.tok))
    (tok-node:ast %n-nonexpprefixop tok)
  ?:  ?=([~ %postfix] cls)
    (tok-node:ast %n-postfixop tok)
  (tok-node:ast %n-infixop tok)
::
++  op-sel-mid
  ::  lookahead from just after an operator token: an optional balanced
  ::  `(...)` then a bang -> the operator is a mid-chain selector (as
  ::  opposed to a final operator, which is followed by no bang)
  |=  toks=(list token)
  ^-  ?
  ?~  toks  |
  ?:  =(%bang kind.i.toks)  &
  ?.  =(%lbr kind.i.toks)  |
  =/  depth  1
  =/  t  t.toks
  |-  ^-  ?
  ?~  t  |
  ?:  =(0 depth)  =(%bang kind.i.t)
  ?:  =(%lbr kind.i.t)  $(t t.t, depth +(depth))
  ?:  =(%rbr kind.i.t)  $(t t.t, depth (dec depth))
  $(t t.t)
::
++  op-ref-operand
  ::  operator token as a nonfix reference: GeneralId [+ args]
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =/  op1  (oper-of u.pk)
  ?:  &(?=(^ op1) ?=(%nfix fix.u.op1))
    [%| (perr-enc s 1)]
  =/  cls  (class-of u.pk)
  =/  opn
    ?:  |(?=([~ %prefix] cls) =('-.' text.u.pk))
      (tok-node:ast %n-nonexpprefixop u.pk)
    ?:  ?=([~ %postfix] cls)
      (tok-node:ast %n-postfixop u.pk)
    (tok-node:ast %n-infixop u.pk)
  =/  gid  (mk-node:ast %n-generalid ~[empty-idprefix opn])
  =.  s  (advance s)
  =/  lk  (peek s)
  ?.  &(?=(^ lk) =(%lbr kind.u.lk))
    [%& gid s]
  =/  ar  (op-args-tail s)
  ?:  ?=(%| -.ar)  [%| p.ar]
  :-  %&
  :_  s.p.ar
  (mk-node:ast %n-opapplication ~[gid v.p.ar])
::
++  op-args-tail
  ::  ( arg (, arg)* ) -> N_OpArgs; bare operators allowed as args
  |=  s=pst
  ^-  (pres node)
  =/  stk0  stk.s
  =.  s  (bpa s 'Optional Arguments')
  =/  lr  (eat s %lbr)
  ?:  ?=(%| -.lr)  [%| p.lr]
  =.  s  s.p.lr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.lr) kids]
  |-  ^-  (pres node)
  =/  ar  (op-arg s)
  ?:  ?=(%| -.ar)  [%| p.ar]
  =.  s  s.p.ar
  =.  kids  [v.p.ar kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  rr  (eat s %rbr)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =.  kids  [(leaf:ast v.p.rr) kids]
  [%& (mk-node:ast %n-opargs (flop kids)) s.p.rr(stk stk0, exp '')]
::
++  op-arg
  ::  a bare operator (followed by , or )) or an expression
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  =/  k2=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    `i.t.rest.s
  =/  op1  (oper-of u.pk)
  ::  \X and \times cannot be passed as infix operator arguments
  ?:  ?&  ?=(^ op1)
          ?=(^ k2)
          |(=(%comma kind.u.k2) =(%rbr kind.u.k2))
          |(=('\\X' text.u.pk) =('\\times' text.u.pk))
      ==
    :-  %|
    %+  perr  s
    ;:  welp
      (render-locn span.u.pk mname.s)
      ": \\X may not be used as an infix operator."
    ==
  ?:  ?&  ?=(^ op1)
          !?=(%nfix fix.u.op1)
          ?=(^ k2)
          |(=(%comma kind.u.k2) =(%rbr kind.u.k2))
      ==
    [%& (bare-op-node u.pk) (advance s)]
  (expression s)
::
++  bare-op-node
  ::  Gen*Op wrapper for a bare operator reference
  |=  tok=token
  ^-  node
  =/  cls  (class-of tok)
  ?:  |(?=([~ %prefix] cls) =('-.' text.tok))
    %+  mk-node:ast  %n-gennonexpprefixop
    ~[empty-idprefix (tok-node:ast %n-nonexpprefixop tok)]
  ?:  ?=([~ %postfix] cls)
    %+  mk-node:ast  %n-genpostfixop
    ~[empty-idprefix (tok-node:ast %n-postfixop tok)]
  %+  mk-node:ast  %n-geninfixop
  ~[empty-idprefix (tok-node:ast %n-infixop tok)]
::
++  tuple-expr
  ::  << >> | << e (, e)* >>
  |=  s=pst
  ^-  (pres node)
  =/  lr  (eat s %lab)
  ?:  ?=(%| -.lr)  [%| p.lr]
  =.  s  s.p.lr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.lr) kids]
  =/  nk  (peek s)
  ?:  &(?=(^ nk) =(%rab kind.u.nk))
    =.  kids  [(leaf:ast u.nk) kids]
    [%& (mk-node:ast %n-tuple (flop kids)) (advance s)]
  |-  ^-  (pres node)
  =/  er  (expression s)
  ?:  ?=(%| -.er)  [%| p.er]
  =.  s  s.p.er
  =.  kids  [v.p.er kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  ek2  (peek s)
  ?:  &(?=(^ ek2) =(%arab kind.u.ek2))
    =.  kids  [(leaf:ast u.ek2) kids]
    =/  sub  (subscript-expr (advance s))
    ?:  ?=(%| -.sub)  [%| p.sub]
    :-  %&
    :_  s.p.sub
    (mk-node:ast %n-actionexpr (flop [v.p.sub kids]))
  =/  rr  (eat s %rab)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =.  kids  [(leaf:ast v.p.rr) kids]
  [%& (mk-node:ast %n-tuple (flop kids)) s.p.rr]
::
++  if-then-else
  |=  s=pst
  ^-  (pres node)
  =/  i1  (eat s %if)
  ?:  ?=(%| -.i1)  [%| p.i1]
  =/  e1  (expression s.p.i1)
  ?:  ?=(%| -.e1)  [%| p.e1]
  =/  t1  (eat s.p.e1 %then)
  ?:  ?=(%| -.t1)  [%| p.t1]
  =/  e2  (expression s.p.t1)
  ?:  ?=(%| -.e2)  [%| p.e2]
  =/  l1  (eat s.p.e2 %else)
  ?:  ?=(%| -.l1)  [%| p.l1]
  =/  e3  (expression s.p.l1)
  ?:  ?=(%| -.e3)  [%| p.e3]
  :-  %&
  :_  s.p.e3
  %+  mk-node:ast  %n-ifthenelse
  :~  (leaf:ast v.p.i1)  v.p.e1
      (leaf:ast v.p.t1)  v.p.e2
      (leaf:ast v.p.l1)  v.p.e3
  ==
::
++  let-in
  |=  s=pst
  ^-  (pres node)
  =/  l1  (eat s %let)
  ?:  ?=(%| -.l1)  [%| p.l1]
  =.  s  s.p.l1
  ::  one or more definitions
  =|  defs=(list node)
  |-  ^-  (pres node)
  =/  dr
    =/  pk  (peek s)
    ?:  &(?=(^ pk) =(%recursive kind.u.pk))
      (recursive-prod s)
    (op-or-fun-def s 'Let Definitions')
  ?:  ?=(%| -.dr)
    ?~  defs  [%| p.dr]
    ::  no more definitions: expect IN
    =/  i1  (eat s %letin)
    ?:  ?=(%| -.i1)  [%| p.i1]
    =/  er  (expression s.p.i1)
    ?:  ?=(%| -.er)  [%| p.er]
    :-  %&
    :_  s.p.er
    %+  mk-node:ast  %n-letin
    :~  (leaf:ast v.p.l1)
        (mk-node:ast %n-letdefinitions (flop defs))
        (leaf:ast v.p.i1)
        v.p.er
    ==
  $(defs [v.p.dr defs], s s.p.dr)
::
++  case-expr
  |=  s=pst
  ^-  (pres node)
  =/  c1  (eat s %case)
  ?:  ?=(%| -.c1)  [%| p.c1]
  =.  s  s.p.c1
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.c1) kids]
  =/  a1  (case-arm (bpa s 'Case Arm'))
  ?:  ?=(%| -.a1)  [%| p.a1]
  =.  s  s.p.a1(stk stk.s, exp '')
  =.  kids  [v.p.a1 kids]
  |-  ^-  (pres node)
  =/  nk  (peek s)
  ?.  &(?=(^ nk) =(%casesep kind.u.nk))
    [%& (mk-node:ast %n-case (flop kids)) s]
  =/  sep  (leaf:ast u.nk)
  =.  s  (advance s)
  =/  ok  (peek s)
  ?:  &(?=(^ ok) =(%other kind.u.ok))
    ::  OTHER -> expr, then done
    =/  ot  (leaf:ast u.ok)
    =/  ostk  stk.s
    =.  s  (bpa (advance s) 'Case Other Arm')
    =/  ar  (eat s %arrow)
    ?:  ?=(%| -.ar)  [%| p.ar]
    =/  er  (expression s.p.ar)
    ?:  ?=(%| -.er)  [%| p.er]
    =.  s  s.p.er(stk ostk, exp '')
    =/  arm
      (mk-node:ast %n-otherarm ~[ot (leaf:ast v.p.ar) v.p.er])
    =.  kids  [arm sep kids]
    [%& (mk-node:ast %n-case (flop kids)) s]
  =/  a2  (case-arm (bpa s 'Case Arm'))
  ?:  ?=(%| -.a2)  [%| p.a2]
  =.  kids  [v.p.a2 sep kids]
  $(s s.p.a2(stk stk.s, exp ''))
::
++  case-arm
  |=  s=pst
  ^-  (pres node)
  =/  e1  (expression s)
  ?:  ?=(%| -.e1)  [%| p.e1]
  =/  ar  (eat s.p.e1 %arrow)
  ?:  ?=(%| -.ar)  [%| p.ar]
  =/  e2  (expression s.p.ar)
  ?:  ?=(%| -.e2)  [%| p.e2]
  :-  %&
  :_  s.p.e2
  (mk-node:ast %n-casearm ~[v.p.e1 (leaf:ast v.p.ar) v.p.e2])
::
::  +|  Unit-Level Productions
::
::
++  op-or-fun-def
  ::  identifier LHS with optional (params); == Expression or INSTANCE.
  ::  `lbl` names the residual-stack frame: `Definition` at module level,
  ::  `Let Definitions` inside a LET (R1.3.5.6.4.1)
  |=  [s=pst lbl=@t]
  ^-  (pres node)
  =/  lcl=(unit node)
    =/  pk  (peek s)
    ?.  &(?=(^ pk) =(%local kind.u.pk))  ~
    `(leaf:ast u.pk)
  =?  s  ?=(^ lcl)  (advance s)
  =.  s  (bpa s lbl)
  ::  prefix operator definition: op ident == e
  =/  p0  (peek s)
  =/  c0  ?~(p0 ~ (class-of u.p0))
  ?:  ?=([~ %prefix] c0)
    ?>  ?=(^ p0)
    =/  opl  (leaf:ast u.p0)
    =.  s  (advance s)
    =/  ir  (eat s %identifier)
    ?:  ?=(%| -.ir)  [%| p.ir]
    =/  lhs2
      %-  welp
      :_  [(mk-node:ast %n-prefixlhs ~[opl (leaf:ast v.p.ir)]) ~]
      ?~(lcl ~ ~[u.lcl])
    (finish-def2 s.p.ir lhs2)
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =/  idl  (leaf:ast v.p.ir)
  =/  n1  (peek s)
  =/  c1  ?~(n1 ~ (class-of u.n1))
  ::  postfix operator definition: ident op == e
  ?:  ?=([~ %postfix] c1)
    ?>  ?=(^ n1)
    =/  lhs2
      %-  welp
      :_  [(mk-node:ast %n-postfixlhs ~[idl (leaf:ast u.n1)]) ~]
      ?~(lcl ~ ~[u.lcl])
    (finish-def2 (advance s) lhs2)
  ::  infix operator definition: ident op ident == e
  ?:  ?=([~ %infix] c1)
    ?>  ?=(^ n1)
    =.  s  (advance s)
    =/  jr  (eat s %identifier)
    ?:  ?=(%| -.jr)  [%| p.jr]
    =/  lhs2
      %-  welp
      :_  :_  ~
          %+  mk-node:ast  %n-infixlhs
          ~[idl (leaf:ast u.n1) (leaf:ast v.p.jr)]
      ?~(lcl ~ ~[u.lcl])
    (finish-def2 s.p.jr lhs2)
  =/  fk  (peek s)
  ?:  &(?=(^ fk) =(%lsb kind.u.fk))
    ::  function definition: f[x \in S, ..] == e
    =.  s  (advance s)
    =|  kids=(list node)
    =.  kids  [(leaf:ast u.fk) idl ~]
    =?  kids  ?=(^ lcl)  (snoc kids u.lcl)
    |-  ^-  (pres node)
    =/  br  (quant-bound2 s)
    ?:  ?=(%| -.br)  [%| p.br]
    =.  s  s.p.br
    =.  kids  [v.p.br kids]
    =/  ck  (peek s)
    ?:  &(?=(^ ck) =(%comma kind.u.ck))
      =.  kids  [(leaf:ast u.ck) kids]
      $(s (advance s))
    =/  rr  (eat s %rsb)
    ?:  ?=(%| -.rr)  [%| p.rr]
    =.  s  s.p.rr
    =.  kids  [(leaf:ast v.p.rr) kids]
    =/  dr  (eat s %def)
    ?:  ?=(%| -.dr)  [%| p.dr]
    =/  er  (expression s.p.dr)
    ?:  ?=(%| -.er)  [%| p.er]
    :-  %&
    :_  (epa s.p.er)
    %+  mk-node:ast  %n-functiondefinition
    (flop [v.p.er (leaf:ast v.p.dr) kids])
  =|  lhs=(list node)
  =.  lhs  [idl lhs]
  =?  lhs  ?=(^ lcl)  (snoc lhs u.lcl)
  =/  nk  (peek s)
  ?:  &(?=(^ nk) =(%lbr kind.u.nk))
    =.  lhs  [(leaf:ast u.nk) lhs]
    =.  s  (advance s)
    |-  ^-  (pres node)
    =/  pr  (param-decl s)
    ?:  ?=(%| -.pr)  [%| p.pr]
    =.  s  s.p.pr
    =.  lhs  [v.p.pr lhs]
    =/  ck  (peek s)
    ?:  &(?=(^ ck) =(%comma kind.u.ck))
      =.  lhs  [(leaf:ast u.ck) lhs]
      $(s (advance s))
    =/  rr  (eat s %rbr)
    ?:  ?=(%| -.rr)  [%| p.rr]
    =.  lhs  [(leaf:ast v.p.rr) lhs]
    (finish-def s.p.rr (flop lhs))
  (finish-def s (flop lhs))
::
++  finish-def2
  ::  definition with a prebuilt (non-Ident) LHS node list
  |=  [s=pst lhs=(list node)]
  ^-  (pres node)
  =/  dr  (eat s %def)
  ?:  ?=(%| -.dr)  [%| p.dr]
  =/  er  (expression s.p.dr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  (epa s.p.er)
  %+  mk-node:ast  %n-operatordefinition
  (welp lhs ~[(leaf:ast v.p.dr) v.p.er])
::
++  param-decl
  ::  ident | ident(_,..) | _ op _ | _ op | op _
  |=  s=pst
  ^-  (pres node)
  ::  SANY's expecting set at a parameter declaration (R1.3.5.6.1)
  =.  s  (set-exp s 'Identifier, _ or prefix op')
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  =/  cls  (class-of u.pk)
  ?:  ?=([~ %prefix] cls)
    ::  op _  -> N_PrefixDecl
    =/  opl  (tok-node:ast %n-nonexpprefixop u.pk)
    =/  ur  (eat (advance s) %us)
    ?:  ?=(%| -.ur)  [%| p.ur]
    :-  %&
    :_  s.p.ur
    (mk-node:ast %n-prefixdecl ~[opl (leaf:ast v.p.ur)])
  ?:  =(%us kind.u.pk)
    =/  u1  (leaf:ast u.pk)
    =.  s  (advance s)
    =/  ok  (peek s)
    =/  ocl  ?~(ok ~ (class-of u.ok))
    ?:  ?=([~ %infix] ocl)
      ?>  ?=(^ ok)
      =/  opl  (tok-node:ast %n-infixop u.ok)
      =/  ur  (eat (advance s) %us)
      ?:  ?=(%| -.ur)  [%| p.ur]
      :-  %&
      :_  s.p.ur
      (mk-node:ast %n-infixdecl ~[u1 opl (leaf:ast v.p.ur)])
    ?:  ?=([~ %postfix] ocl)
      ?>  ?=(^ ok)
      :-  %&
      :_  (advance s)
      (mk-node:ast %n-postfixdecl ~[u1 (tok-node:ast %n-postfixop u.ok)])
    [%| (perr-enc s 1)]
  (op-decl s)
::
++  theorem-unit
  ::  THEOREM/PROPOSITION [name ==] (expr | AssumeProve) [Proof]
  |=  s=pst
  ^-  (pres node)
  ::  SANY's Theorem production (residual stack); popped on success
  ::  (R1.3.5.6.3)
  =.  s  (bpa s 'Theorem')
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =/  kw  (leaf:ast u.pk)
  =.  s  (advance s)
  =/  named  (named-head s)
  =?  s  ?=(^ named)  s.u.named
  =/  bk  (peek s)
  =/  er
    ^-  (pres node)
    ?:  &(?=(^ bk) ?=(?(%assume %boxassume) kind.u.bk))
      (assume-prove s)
    (expression s)
  ?:  ?=(%| -.er)  [%| p.er]
  =.  s  s.p.er
  =/  kids
    ^-  (list node)
    ?~  named  ~[kw v.p.er]
    ~[kw n.u.named d.u.named v.p.er]
  =/  nx  (peek s)
  ?.  &(?=(^ nx) (begins-proof s u.nx))
    [%& (mk-node:ast %n-theorem kids) (epa s)]
  =/  pr  (proof-prod s)
  ?:  ?=(%| -.pr)  [%| p.pr]
  :-  %&
  :_  (epa s.p.pr)
  (mk-node:ast %n-theorem (snoc kids v.p.pr))
::
++  named-head
  ::  lookahead ident == not followed by INSTANCE
  |=  s=pst
  ^-  (unit [n=node d=node s=pst])
  ?~  rest.s  ~
  ?.  =(%identifier kind.i.rest.s)  ~
  ?~  t.rest.s  ~
  ?.  =(%def kind.i.t.rest.s)  ~
  ?:  ?&  ?=(^ t.t.rest.s)
          =(%instance kind.i.t.t.rest.s)
      ==
    ~
  :^  ~  (leaf:ast i.rest.s)  (leaf:ast i.t.rest.s)
  s(rest t.t.rest.s)
::
++  use-hide-unit
  ::  USE/HIDE [items] [DEF(S) targets]
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =/  kw  (leaf:ast u.pk)
  =.  s  (advance s)
  =/  facts
    ^-  (each [ks=(list node) s=pst] @t)
    =/  dk  (peek s)
    ?:  &(?=(^ dk) =(%df kind.u.dk))  [%& ~ s]
    =|  ks=(list node)
    |-  ^-  (each [ks=(list node) s=pst] @t)
    =/  er  (use-hide-item s)
    ?:  ?=(%| -.er)  [%| p.er]
    =.  s  s.p.er
    =.  ks  (welp (flop v.p.er) ks)
    =/  ck  (peek s)
    ?.  &(?=(^ ck) =(%comma kind.u.ck))  [%& (flop ks) s]
    =.  ks  [(leaf:ast u.ck) ks]
    $(s (advance s))
  ?:  ?=(%| -.facts)  [%| p.facts]
  =.  s  s.p.facts
  =/  kids  `(list node)`(welp ~[kw] ks.p.facts)
  =/  dk  (peek s)
  ?.  &(?=(^ dk) =(%df kind.u.dk))
    [%& (mk-node:ast %n-useorhide kids) s]
  =.  kids  (snoc kids `node`(leaf:ast u.dk))
  =.  s  (advance s)
  |-  ^-  (pres node)
  =/  tr  (use-hide-item s)
  ?:  ?=(%| -.tr)  [%| p.tr]
  =.  s  s.p.tr
  =.  kids  (welp kids v.p.tr)
  =/  ck  (peek s)
  ?.  &(?=(^ ck) =(%comma kind.u.ck))
    [%& (mk-node:ast %n-useorhide kids) s]
  =.  kids  (snoc kids `node`(leaf:ast u.ck))
  $(s (advance s))
::
++  use-hide-item
  ::  a bare operator reference (as GeneralId), MODULE M, or expression
  |=  s=pst
  ^-  (each [v=(list node) s=pst] @t)
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  ?:  =(%module kind.u.pk)
    =/  mr  (eat (advance s) %identifier)
    ?:  ?=(%| -.mr)  [%| p.mr]
    [%& ~[(leaf:ast u.pk) `node`(leaf:ast v.p.mr)] s.p.mr]
  =/  k2=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    `i.t.rest.s
  ?:  ?&  (is-op-kind kind.u.pk)
          ?|  ?=(~ k2)
              =(%comma kind.u.k2)
              =(%df kind.u.k2)
              =(%end-module kind.u.k2)
              !(expr-start kind.u.k2)
          ==
      ==
    =/  cls  (class-of u.pk)
    =/  opn
      ?:  |(?=([~ %prefix] cls) =('-.' text.u.pk))
        (tok-node:ast %n-nonexpprefixop u.pk)
      ?:  ?=([~ %postfix] cls)
        (tok-node:ast %n-postfixop u.pk)
      (tok-node:ast %n-infixop u.pk)
    :-  %&
    :_  (advance s)
    ~[(mk-node:ast %n-generalid ~[empty-idprefix opn])]
  =/  er  (expression s)
  ?:  ?=(%| -.er)  [%| p.er]
  [%& ~[v.p.er] s.p.er]
::
++  expr-start
  ::  kinds that can begin an expression operand
  |=  k=@tas
  ^-  ?
  ?|  (is-op-kind k)
      ?=  $?  %identifier  %number-literal  %string-literal
              %lbr  %lbc  %lsb  %lab
              %if  %let  %case  %choose
              %exists  %forall  %t-exists  %t-forall
              %wf  %sf  %lambda
              %proofsteplexeme  %proofstepdotlexeme
              %proofimplicitsteplexeme
          ==
        k
  ==
::
++  label-expr
  ::  target :: Expression -> N_Label; the label must not change the
  ::  parse (labelDoesNotChangeParse)
  |=  [s=pst target=node stk=(list osel)]
  ^-  (pres node)
  =/  cr  (eat s %coloncolon)
  ?:  ?=(%| -.cr)  [%| p.cr]
  =/  er  (expression s.p.cr)
  ?:  ?=(%| -.er)  [%| p.er]
  ?.  (label-ok stk v.p.er)
    :-  %|
    %+  perr  s.p.er
    ;:  welp
      "Removing label at "
      (node-locn target mname.s)
      " would change expression parsing."
    ==
  :-  %&
  :_  s.p.er
  (mk-node:ast %n-label ~[target (leaf:ast v.p.cr) v.p.er])
::
++  label-ok
  |=  [stk=(list osel) labeled=node]
  ^-  ?
  ?.  ?&  ?=(%node -.labeled)
          ?=(?(%n-infixexpr %n-postfixexpr) kind.labeled)
      ==
    &
  ::  operator of the labeled expression
  =/  lop=(unit oper)
    =/  gio
      ^-  (unit node)
      ?~  kids.labeled  ~
      ?~  t.kids.labeled  ~
      `i.t.kids.labeled
    ?~  gio  ~
    ?.  ?=(%node -.u.gio)  ~
    ?~  kids.u.gio  ~
    ?~  t.kids.u.gio  ~
    =/  opn  i.t.kids.u.gio
    =/  img
      ?-  -.opn
        %leaf  text.token.opn
        %node  image.opn
      ==
    (~(get by op-table) img)
  ?~  lop  &
  ?~  stk  &
  ?~  op.i.stk  &
  (prec u.op.i.stk u.lop)
::
++  cook-string
  ::  N_String image is the unescaped string, quotes kept
  |=  tok=token
  ^-  token
  =/  raw  (trip text.tok)
  =|  out=tape
  |-
  ?~  raw  tok(text (crip (flop out)))
  ?.  =('\\' i.raw)
    $(raw t.raw, out [i.raw out])
  ?~  t.raw  $(raw t.raw, out [i.raw out])
  =/  e  i.t.raw
  =/  c
    ?:  =('n' e)  '\0a'
    ?:  =('t' e)  '\09'
    ?:  =('r' e)  '\0d'
    ?:  =('f' e)  '\0c'
    e
  $(raw t.t.raw, out [c out])
::
++  check-indent
  ::  Java checkIndentation: every descendant of the item body
  ::  (stopping at nested junction lists) must sit strictly right of
  ::  the current bullet; the error names the child and the whole item
  |=  [s=pst body=node item=node]
  ^-  (unit @t)
  ?~  jctx.s  ~
  =/  bullet  col.i.jctx.s
  =/  jl  (node-locn item mname.s)
  =/  nd  body
  |-  ^-  (unit @t)
  ?:  ?=(%leaf -.nd)  ~
  =/  kids  kids.nd
  |-  ^-  (unit @t)
  ?~  kids  ~
  =/  child  i.kids
  ?:  ?&  ?=(%node -.child)
          ?=(?(%n-conjlist %n-disjlist) kind.child)
      ==
    $(kids t.kids)
  =/  col=(unit @ud)
    ?-  -.child
      %leaf  `col.from.span.token.child
      %node  ?~(at.child ~ `col.from.u.at.child)
    ==
  ?:  &(?=(^ col) (lte u.col bullet))
    :-  ~
    %-  crip
    ;:  welp
      "Item at "
      (node-locn child mname.s)
      " is not properly indented inside conjunction or "
      " disjunction list item at "
      jl
    ==
  =/  r  ^$(nd child)
  ?^  r  r
  $(kids t.kids)
::
++  set-expr
  ::  { } | { e, .. } | { x \in S : p } | { e : x \in S }
  |=  s=pst
  ^-  (pres node)
  =/  lr  (eat s %lbc)
  ?:  ?=(%| -.lr)  [%| p.lr]
  =.  s  s.p.lr
  =/  lbc  (leaf:ast v.p.lr)
  =/  pk  (peek s)
  ?:  &(?=(^ pk) =(%rbc kind.u.pk))
    :-  %&
    :_  (advance s)
    (mk-node:ast %n-setenumerate ~[lbc (leaf:ast u.pk)])
  ?:  (match-fcn-const s)
    ::  SubsetOf: { binder \in S : p }
    =/  br
      ^-  (pres node)
      =/  bk  (peek s)
      ?:  &(?=(^ bk) =(%lab kind.u.bk))  (ident-tuple s)
      =/  ir  (eat s %identifier)
      ?:  ?=(%| -.ir)  [%| p.ir]
      [%& (leaf:ast v.p.ir) s.p.ir]
    ?:  ?=(%| -.br)  [%| p.br]
    =.  s  s.p.br
    =/  nr  (eat s %in)
    ?:  ?=(%| -.nr)  [%| p.nr]
    =.  s  s.p.nr
    =/  tin  (leaf:ast v.p.nr(kind %t-in))
    =/  er  (expression s)
    ?:  ?=(%| -.er)  [%| p.er]
    =.  s  s.p.er
    =/  ck2  (peek s)
    ?.  &(?=(^ ck2) =(%colon kind.u.ck2))
      ::  {x \in S} without a colon: reinterpret as an enumerate
      ::  element (the SANY recovery keeps the retagged t-in)
      =/  gidb
        (mk-node:ast %n-generalid ~[empty-idprefix v.p.br])
      =/  gio
        (mk-node:ast %n-geninfixop ~[empty-idprefix tin])
      =/  first
        (mk-node:ast %n-infixexpr ~[gidb gio v.p.er])
      (set-enum-tail s lbc first)
    =/  cr  (eat s %colon)
    ?:  ?=(%| -.cr)  [%| p.cr]
    =/  pr  (expression s.p.cr)
    ?:  ?=(%| -.pr)  [%| p.pr]
    =/  rr  (eat s.p.pr %rbc)
    ?:  ?=(%| -.rr)  [%| p.rr]
    :-  %&
    :_  s.p.rr
    %+  mk-node:ast  %n-subsetof
    :~  lbc  v.p.br  tin  v.p.er
        (leaf:ast v.p.cr)  v.p.pr  (leaf:ast v.p.rr)
    ==
  =/  e1  (expression s)
  ?:  ?=(%| -.e1)  [%| p.e1]
  =.  s  s.p.e1
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%colon kind.u.ck))
    ::  SetOfAll: { e : qb, qb, .. }
    =/  cl  (leaf:ast u.ck)
    =.  s  (advance s)
    =|  qs=(list node)
    |-  ^-  (pres node)
    =/  qr  (quant-bound2 s)
    ?:  ?=(%| -.qr)  [%| p.qr]
    =.  s  s.p.qr
    =.  qs  [v.p.qr qs]
    =/  mk  (peek s)
    ?:  &(?=(^ mk) =(%comma kind.u.mk))
      =.  qs  [(leaf:ast u.mk) qs]
      $(s (advance s))
    =/  rr  (eat s %rbc)
    ?:  ?=(%| -.rr)  [%| p.rr]
    :-  %&
    :_  s.p.rr
    %+  mk-node:ast  %n-setofall
    (welp ~[lbc v.p.e1 cl] (flop [(leaf:ast v.p.rr) qs]))
  ::  SetEnumerate
  (set-enum-tail s lbc v.p.e1)
::
++  set-enum-tail
  ::  remaining { first, .. } elements
  |=  [s=pst lbc=node first=node]
  ^-  (pres node)
  =|  kids=(list node)
  =.  kids  [first lbc ~]
  |-  ^-  (pres node)
  =/  mk  (peek s)
  ?:  &(?=(^ mk) =(%comma kind.u.mk))
    =.  s  (advance s)
    =/  er  (expression s)
    ?:  ?=(%| -.er)  [%| p.er]
    =.  s  s.p.er
    $(kids [v.p.er (leaf:ast u.mk) kids])
  =/  rr  (eat s %rbc)
  ?:  ?=(%| -.rr)  [%| p.rr]
  :-  %&
  :_  s.p.rr
  (mk-node:ast %n-setenumerate (flop [(leaf:ast v.p.rr) kids]))
::
++  quant-bound
  ::  ident \in expr -> N_QuantBound with t-in retag
  |=  s=pst
  ^-  (pres node)
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =/  nr  (eat s.p.ir %in)
  ?:  ?=(%| -.nr)  [%| p.nr]
  =/  er  (expression s.p.nr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er
  %+  mk-node:ast  %n-quantbound
  ~[(leaf:ast v.p.ir) (leaf:ast v.p.nr(kind %t-in)) v.p.er]
::
++  lambda-expr
  ::  LAMBDA ident (, ident)* : expr -> N_Lambda
  |=  s=pst
  ^-  (pres node)
  =/  kr  (eat s %lambda)
  ?:  ?=(%| -.kr)  [%| p.kr]
  =.  s  s.p.kr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.kr) kids]
  |-  ^-  (pres node)
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =.  kids  [(leaf:ast v.p.ir) kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  cr  (eat s %colon)
  ?:  ?=(%| -.cr)  [%| p.cr]
  =/  er  (expression s.p.cr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er
  %+  mk-node:ast  %n-lambda
  (flop [v.p.er (leaf:ast v.p.cr) kids])
::
++  number-expr
  ::  N_Number, or N_Real for digits.digits
  |=  s=pst
  ^-  (pres node)
  =/  nr  (eat s %number-literal)
  ?:  ?=(%| -.nr)  [%| p.nr]
  =.  s  s.p.nr
  =/  d1  (peek s)
  =/  d2=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    `i.t.rest.s
  ?.  ?&  ?=(^ d1)  =(%dot kind.u.d1)
          ?=(^ d2)  =(%number-literal kind.u.d2)
      ==
    [%& (mk-node:ast %n-number ~[(leaf:ast v.p.nr)]) s]
  :-  %&
  :_  (advance (advance s))
  %+  mk-node:ast  %n-real
  ~[(leaf:ast v.p.nr) (leaf:ast u.d1) (leaf:ast u.d2)]
::
++  ident-tuple
  ::  << ident (, ident)* >> -> N_IdentifierTuple
  |=  s=pst
  ^-  (pres node)
  =/  lr  (eat s %lab)
  ?:  ?=(%| -.lr)  [%| p.lr]
  =.  s  s.p.lr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.lr) kids]
  =/  ek  (peek s)
  ?:  &(?=(^ ek) =(%rab kind.u.ek))
    =.  kids  [(leaf:ast u.ek) kids]
    [%& (mk-node:ast %n-identifiertuple (flop kids)) (advance s)]
  |-  ^-  (pres node)
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =.  kids  [(leaf:ast v.p.ir) kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  rr  (eat s %rab)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =.  kids  [(leaf:ast v.p.rr) kids]
  [%& (mk-node:ast %n-identifiertuple (flop kids)) s.p.rr]
::
++  quant-bound2
  ::  (ident (, ident)* | identtuple) \in expr -> N_QuantBound
  |=  s=pst
  ^-  (pres node)
  ::  SANY's QuantBound production entry (residual stack `Quant Bound`);
  ::  popped on success in +finish-quant-bound (R1.3.5.6.1)
  =.  s  (bpa s 'Quant Bound')
  =|  kids=(list node)
  =/  pk  (peek s)
  ?:  &(?=(^ pk) =(%lab kind.u.pk))
    =/  tr  (ident-tuple s)
    ?:  ?=(%| -.tr)  [%| p.tr]
    =.  s  s.p.tr
    =.  kids  [v.p.tr kids]
    (finish-quant-bound s kids)
  |-  ^-  (pres node)
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =.  kids  [(leaf:ast v.p.ir) kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  (finish-quant-bound s kids)
::
++  finish-quant-bound
  |=  [s=pst kids=(list node)]
  ^-  (pres node)
  =/  nr  (eat s %in)
  ?:  ?=(%| -.nr)  [%| p.nr]
  =/  er  (expression s.p.nr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  (epa s.p.er)
  %+  mk-node:ast  %n-quantbound
  (flop [v.p.er (leaf:ast v.p.nr(kind %t-in)) kids])
::
++  quant-expr
  ::  \A/\E: bounded when the first binder group ends in \in
  |=  s=pst
  ^-  (pres node)
  ?:  (match-fcn-const (advance s))
    (bound-quant s)
  (unbound-quant s)
::
++  bound-quant
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =/  kw  (leaf:ast u.pk)
  =.  s  (advance s)
  =|  kids=(list node)
  =.  kids  [kw kids]
  |-  ^-  (pres node)
  =/  br  (quant-bound2 s)
  ?:  ?=(%| -.br)  [%| p.br]
  =.  s  s.p.br
  =.  kids  [v.p.br kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  cr  (eat s %colon)
  ?:  ?=(%| -.cr)  [%| p.cr]
  =/  er  (expression s.p.cr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er
  %+  mk-node:ast  %n-boundquant
  (flop [v.p.er (leaf:ast v.p.cr) kids])
::
++  unbound-quant
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =/  kw  (leaf:ast u.pk)
  =.  s  (advance s)
  ::  SANY reports an unbounded binder under the same QuantBound production
  ::  as a bounded one (residual stack `Quant Bound`); popped on success
  ::  (R1.3.5.6.1).  SANY enters QuantBound only once a bound variable
  ::  actually starts, so a bare `\A`/`\E` at end pushes nothing
  ::  (R1.3.5.6.4.1)
  =/  pk2  (peek s)
  =?  s  &(?=(^ pk2) =(%identifier kind.u.pk2))  (bpa s 'Quant Bound')
  =|  kids=(list node)
  =.  kids  [kw kids]
  |-  ^-  (pres node)
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =.  kids  [(leaf:ast v.p.ir) kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  cr  (eat s %colon)
  ?:  ?=(%| -.cr)  [%| p.cr]
  =/  er  (expression s.p.cr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  (epa s.p.er)
  %+  mk-node:ast  %n-unboundquant
  (flop [v.p.er (leaf:ast v.p.cr) kids])
::
++  choose-expr
  |=  s=pst
  ^-  (pres node)
  =/  cr  (eat s %choose)
  ?:  ?=(%| -.cr)  [%| p.cr]
  =.  s  s.p.cr
  =/  binder
    ^-  (pres node)
    =/  pk  (peek s)
    ?:  &(?=(^ pk) =(%lab kind.u.pk))  (ident-tuple s)
    =/  ir  (eat s %identifier)
    ?:  ?=(%| -.ir)  [%| p.ir]
    [%& (leaf:ast v.p.ir) s.p.ir]
  ?:  ?=(%| -.binder)  [%| p.binder]
  =.  s  s.p.binder
  =/  mb
    ^-  (pres node)
    =/  pk  (peek s)
    ?.  &(?=(^ pk) =(%in kind.u.pk))
      [%& (empty-node %n-maybebound) s]
    =/  er  (expression (advance s))
    ?:  ?=(%| -.er)  [%| p.er]
    :-  %&
    :_  s.p.er
    (mk-node:ast %n-maybebound ~[(leaf:ast u.pk(kind %t-in)) v.p.er])
  ?:  ?=(%| -.mb)  [%| p.mb]
  =.  s  s.p.mb
  =/  kr  (eat s %colon)
  ?:  ?=(%| -.kr)  [%| p.kr]
  =/  er  (expression s.p.kr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er
  %+  mk-node:ast  %n-unboundorboundchoose
  ~[(leaf:ast v.p.cr) v.p.binder v.p.mb (leaf:ast v.p.kr) v.p.er]
::
++  fairness-expr
  ::  WF_/SF_ subject ( expr )
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =/  wtok  u.pk
  =/  kw  (leaf:ast wtok)
  =.  s  (advance s)
  =/  stk0  stk.s
  =/  subj
    ^-  (pres node)
    =/  s  (bpa s 'restricted form of expression')
    =/  sk  (peek s)
    ?~  sk  [%| (perr-enc s 1)]
    ?:  =(%lbr kind.u.sk)  (paren-expr s)
    ?:  =(%lab kind.u.sk)  (tuple-expr s)
    =/  ir  (eat s %identifier)
    ?:  ?=(%| -.ir)  [%| p.ir]
    [%& (general-id v.p.ir) s.p.ir]
  ?:  ?=(%| -.subj)  [%| p.subj]
  =.  s  s.p.subj(stk stk0, exp '')
  =/  lr  (eat s %lbr)
  ::  subject parsed but no `(action)` follows: SANY aborts the whole
  ::  WF_/SF_ with a single custom message at the keyword, dropping the
  ::  caller's `Fairness Expression` frame (R1.3.5.6.4.3).  A bad SUBJECT
  ::  (e.g. WF_3) still propagates the normal Encountered error with the
  ::  frame -- see boundary/fairness.tla.
  ?:  ?=(%| -.lr)
    :-  %|
    %+  perr  s(stk ?~(stk.s ~ t.stk.s), exp '')
    ;:  welp
      "Ill-structured fairness expression at line "
      (dec-tape:ast line.from.span.wtok)
      ", column "
      (dec-tape:ast col.from.span.wtok)
    ==
  =/  er  (expression s.p.lr)
  ?:  ?=(%| -.er)  [%| p.er]
  =/  rr  (eat s.p.er %rbr)
  ?:  ?=(%| -.rr)  [%| p.rr]
  :-  %&
  :_  s.p.rr
  %+  mk-node:ast  %n-fairnessexpr
  ~[kw v.p.subj (leaf:ast v.p.lr) v.p.er (leaf:ast v.p.rr)]
::
++  sbracket-operand
  ::  [x \in S |-> e] | [a |-> e] | [a : S] | [S -> T] | [e EXCEPT ..]
  |=  s=pst
  ^-  (pres node)
  =/  lr  (eat s %lsb)
  ?:  ?=(%| -.lr)  [%| p.lr]
  =.  s  s.p.lr
  =/  lsb  (leaf:ast v.p.lr)
  ?:  (match-fcn-const s)
    ::  FcnConst
    =|  kids=(list node)
    =.  kids  [lsb kids]
    |-  ^-  (pres node)
    =/  br  (quant-bound2 s)
    ?:  ?=(%| -.br)  [%| p.br]
    =.  s  s.p.br
    =.  kids  [v.p.br kids]
    =/  ck  (peek s)
    ?:  &(?=(^ ck) =(%comma kind.u.ck))
      =.  kids  [(leaf:ast u.ck) kids]
      $(s (advance s))
    =/  mr  (eat s %mapto)
    ?:  ?=(%| -.mr)  [%| p.mr]
    =/  er  (expression s.p.mr)
    ?:  ?=(%| -.er)  [%| p.er]
    =/  rr  (eat s.p.er %rsb)
    ?:  ?=(%| -.rr)  [%| p.rr]
    :-  %&
    :_  s.p.rr
    %+  mk-node:ast  %n-fcnconst
    (flop [(leaf:ast v.p.rr) v.p.er (leaf:ast v.p.mr) kids])
  =/  k2=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    `i.t.rest.s
  =/  k1  (peek s)
  ?:  ?&  ?=(^ k1)  =(%identifier kind.u.k1)
          ?=(^ k2)  =(%mapto kind.u.k2)
      ==
    (record-fields s lsb %mapto %n-fieldval %n-rcdconstructor)
  ?:  ?&  ?=(^ k1)  =(%identifier kind.u.k1)
          ?=(^ k2)  =(%colon kind.u.k2)
      ==
    (record-fields s lsb %colon %n-fieldset %n-setofrcds)
  =/  e1  (expression s)
  ?:  ?=(%| -.e1)  [%| p.e1]
  =.  s  s.p.e1
  =/  nk  (peek s)
  ?:  &(?=(^ nk) =(%arrow kind.u.nk))
    =.  s  (advance s)
    =/  er  (expression s)
    ?:  ?=(%| -.er)  [%| p.er]
    =/  rr  (eat s.p.er %rsb)
    ?:  ?=(%| -.rr)  [%| p.rr]
    :-  %&
    :_  s.p.rr
    %+  mk-node:ast  %n-setoffcns
    ~[lsb v.p.e1 (leaf:ast u.nk) v.p.er (leaf:ast v.p.rr)]
  ?:  &(?=(^ nk) =(%except kind.u.nk))
    (except-tail s lsb v.p.e1 (leaf:ast u.nk))
  ?:  &(?=(^ nk) =(%arsb kind.u.nk))
    =/  sub  (subscript-expr (advance s))
    ?:  ?=(%| -.sub)  [%| p.sub]
    :-  %&
    :_  s.p.sub
    %+  mk-node:ast  %n-actionexpr
    ~[lsb v.p.e1 (leaf:ast u.nk) v.p.sub]
  [%| (perr-enc s 1)]
::
++  subscript-expr
  ::  the _v subscript: identifier, tuple, or parenthesized expr.  SANY
  ::  wraps it in the `restricted form of expression` production
  ::  (residual stack); popped on success (R1.3.5.6.4.3)
  |=  s=pst
  ^-  (pres node)
  =/  stk0  stk.s
  =.  s  (bpa s 'restricted form of expression')
  =/  pk  (peek s)
  =/  r=(pres node)
    ?~  pk  [%| (perr-enc s 1)]
    ?:  =(%lab kind.u.pk)  (tuple-expr s)
    ?:  =(%lbr kind.u.pk)  (paren-expr s)
    ?:  =(%identifier kind.u.pk)  (general-id-full s)
    [%| (perr-enc s 1)]
  ?:  ?=(%| -.r)  [%| p.r]
  [%& v.p.r s.p.r(stk stk0, exp '')]
::
++  record-fields
  ::  [ name sep expr/set, .. ] for RcdConstructor and SetOfRcds
  |=  [s=pst lsb=node sep=@tas fieldk=@tas nodek=@tas]
  ^-  (pres node)
  =|  kids=(list node)
  =.  kids  [lsb kids]
  |-  ^-  (pres node)
  ::  SANY wraps each field at the field name: a `name |-> value`
  ::  record-constructor field in a Field Value production, a `name : set`
  ::  set-of-records field in a Field Set production (residual stack
  ::  `Field Value`/`Field Set`); popped once the value/set parses
  ::  (R1.3.5.6.1)
  =.  s  (bpa s ?:(=(%mapto sep) 'Field Value' 'Field Set'))
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =/  sr  (eat s sep)
  ?:  ?=(%| -.sr)  [%| p.sr]
  =/  er  (expression s.p.sr)
  ?:  ?=(%| -.er)  [%| p.er]
  =.  s  (epa s.p.er)
  =/  field
    %+  mk-node:ast  fieldk
    ~[(leaf:ast v.p.ir) (leaf:ast v.p.sr) v.p.er]
  =.  kids  [field kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  rr  (eat s %rsb)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =.  kids  [(leaf:ast v.p.rr) kids]
  [%& (mk-node:ast nodek (flop kids)) s.p.rr]
::
++  except-tail
  ::  [ e EXCEPT !comp.. = v, .. ]
  |=  [s=pst lsb=node e1=node exc=node]
  ^-  (pres node)
  =.  s  (advance s)
  =|  kids=(list node)
  =.  kids  [exc e1 lsb ~]
  |-  ^-  (pres node)
  =/  sr  (except-spec s)
  ?:  ?=(%| -.sr)  [%| p.sr]
  =.  s  s.p.sr
  =.  kids  [v.p.sr kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  rr  (eat s %rsb)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =.  kids  [(leaf:ast v.p.rr) kids]
  [%& (mk-node:ast %n-except (flop kids)) s.p.rr]
::
++  except-spec
  ::  ! ( [expr,..] | .field )+ = expr
  |=  s=pst
  ^-  (pres node)
  =/  stk0  stk.s
  =.  s  (bpa s 'Except Spec')
  =/  br  (eat s %bang)
  ?:  ?=(%| -.br)  [%| p.br]
  =.  s  s.p.br
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.br) kids]
  |-  ^-  (pres node)
  ::  SANY wraps each `[expr,..]`/`.field` selector after the `!` in an
  ::  Except Component production (residual stack `Except Component`, at
  ::  the selector); popped once the component parses (R1.3.5.6.1).  The
  ::  first component after `!` is mandatory, so the frame is pushed on the
  ::  first iteration or whenever a selector begins -- but NOT at the
  ::  `= or ,` decision point after >=1 component (R1.3.5.6.4.2)
  =/  pk  (peek s)
  =/  sel=?  ?&(?=(^ pk) ?|(=(%lsb kind.u.pk) =(%dot kind.u.pk)))
  =/  first=?  ?=([* ~] kids)
  =?  s  |(first sel)  (bpa s 'Except Component')
  ?:  &(?=(^ pk) =(%lsb kind.u.pk))
    =.  s  (advance s)
    =|  ck=(list node)
    =.  ck  [(leaf:ast u.pk) ck]
    |-  ^-  (pres node)
    =/  er  (expression s)
    ?:  ?=(%| -.er)  [%| p.er]
    =.  s  s.p.er
    =.  ck  [v.p.er ck]
    =/  mk  (peek s)
    ?:  &(?=(^ mk) =(%comma kind.u.mk))
      =.  ck  [(leaf:ast u.mk) ck]
      $(s (advance s))
    =/  rr  (eat s %rsb)
    ?:  ?=(%| -.rr)  [%| p.rr]
    =.  s  s.p.rr
    =.  ck  [(leaf:ast v.p.rr) ck]
    ^$(kids [(mk-node:ast %n-exceptcomponent (flop ck)) kids], s (epa s))
  ?:  &(?=(^ pk) =(%dot kind.u.pk))
    =.  s  (advance s)
    =/  ak  (peek s)
    ?:  &(?=(^ ak) =('@' text.u.ak))
      [%| '@ used in !.@']
    =/  ir  (eat s %identifier)
    ?:  ?=(%| -.ir)  [%| p.ir]
    =.  s  s.p.ir
    =/  comp
      %+  mk-node:ast  %n-exceptcomponent
      ~[(leaf:ast u.pk) (leaf:ast v.p.ir)]
    $(kids [comp kids], s (epa s))
  ::  = expr terminates the spec (retagged t-equal); after >=1 component the
  ::  decision point expects `= or ,` (R1.3.5.6.4.2)
  =?  s  &(!first !sel)  (set-exp s '= or ,')
  =/  qr  (eat s %equals)
  ?:  ?=(%| -.qr)  [%| p.qr]
  =/  er  (expression s.p.qr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er(stk stk0, exp '')
  %+  mk-node:ast  %n-exceptspec
  (flop [v.p.er (leaf:ast v.p.qr(kind %t-equal)) kids])
::
::  +|  Proof Machinery (tla+.jj proof-level fields and productions)
::
+$  slev  $%([%star ~] [%plus ~] [%num n=@ud])
::
++  step-level
  |=  t=@t
  ^-  slev
  =/  cs  (trip t)
  ?~  cs  [%num 0]
  ?~  t.cs  [%num 0]
  ?:  =('*' i.t.cs)  [%star ~]
  ?:  =('+' i.t.cs)  [%plus ~]
  =/  n=@ud  0
  =/  rest  `tape`t.cs
  |-
  ?~  rest  [%num n]
  ?:  =('>' i.rest)  [%num n]
  $(rest t.rest, n (add (mul 10 n) (sub i.rest '0')))
::
++  step-kinds
  ^-  (set @tas)
  %-  silt
  ^-  (list @tas)
  :~  %proofsteplexeme  %proofimplicitsteplexeme  %proofstepdotlexeme
      %barelevellexeme  %unnumberedsteplexeme
  ==
::
++  begins-proof
  |=  [s=pst tok=token]
  ^-  ?
  ?:  ?=(?(%by %proof %obvious %omitted) kind.tok)  &
  ?.  (~(has in step-kinds) kind.tok)  |
  =/  lv  (step-level text.tok)
  ?:  ?=(%star -.lv)  ?=(~ plv.s)
  ?:  ?=(%plus -.lv)  &
  ?~  plv.s  &
  ?&  ?=(^ i.plv.s)
      (gth n.lv u.i.plv.s)
  ==
::
++  parent-level
  ::  level of the enclosing proof, or ~ for top level
  |=  s=pst
  ^-  (unit @ud)
  ?~  plv.s  ~
  ?~  t.plv.s  ~
  i.t.plv.s
::
++  correct-level
  ::  validate/set the current proof level for a step token
  |=  [s=pst tok=token]
  ^-  (each pst @t)
  ?~  plv.s  [%| (perr-enc s 1)]
  =/  lv  (step-level text.tok)
  =/  last=@ud  ?~((parent-level s) 0 +((need (parent-level s))))
  ?-    -.lv
      ?(%star %plus)
    ?~  i.plv.s
      [%& s(plv [`last t.plv.s])]
    [%& s]
  ::
      %num
    ?~  i.plv.s
      [%& s(plv [`n.lv t.plv.s])]
    ?:  =(n.lv u.i.plv.s)  [%& s]
    [%| (perr-enc s 1)]
  ==
::
++  corrected-token
  ::  canonical step number: +/* replaced, leading zeros dropped
  |=  [s=pst tok=token]
  ^-  token
  ?.  ?=  $?  %proofsteplexeme  %proofimplicitsteplexeme
              %proofstepdotlexeme
          ==
        kind.tok
    tok
  =/  level=@ud
    =/  cur  ?~(plv.s ~ i.plv.s)
    ?^  cur  u.cur
    ?~  (parent-level s)  0
    (need (parent-level s))
  =/  lv  (step-level text.tok)
  =/  lvn  ?:(?=(%num -.lv) n.lv level)
  =/  cs  (trip text.tok)
  =/  aft
    |-  ^-  tape
    ?~  cs  ~
    ?:  =('>' i.cs)  cs
    $(cs t.cs)
  tok(text (crip (welp ['<' (dec-tape:ast lvn)] aft)))
::
++  proof-prod
  ::  Proof(): BY-terminal, OBVIOUS/OMITTED, or step list + QED
  |=  s=pst
  ^-  (pres node)
  =.  plv.s  [~ plv.s]
  ::  SANY's Proof production (residual stack, at the proof start); popped
  ::  on success (R1.3.5.6.4.4)
  =.  s  (bpa s 'Proof')
  =/  res
    ^-  (pres node)
    =/  k1  (peek s)
    =/  k2=(unit token)
      ?~  rest.s  ~
      ?~  t.rest.s  ~
      `i.t.rest.s
    ?:  ?|  &(?=(^ k1) =(%by kind.u.k1))
            &(?=(^ k2) =(%by kind.u.k2))
        ==
      (use-hide-by s)
    ?:  ?|  &(?=(^ k1) ?=(?(%obvious %omitted) kind.u.k1))
            ?&  ?=(^ k1)  =(%proof kind.u.k1)
                ?=(^ k2)  ?=(?(%obvious %omitted) kind.u.k2)
            ==
        ==
      =/  pfl=(unit node)
        ?.  &(?=(^ k1) =(%proof kind.u.k1))  ~
        `(leaf:ast u.k1)
      =?  s  ?=(^ pfl)  (advance s)
      =/  ok  (peek s)
      ?>  ?=(^ ok)
      :-  %&
      :_  (advance s)
      %+  mk-node:ast  %n-terminalproof
      ?~(pfl ~[(leaf:ast u.ok)] ~[u.pfl (leaf:ast u.ok)])
    ::  step list ending in QED
    =|  kids=(list node)
    =?  kids  &(?=(^ k1) =(%proof kind.u.k1))
      [(leaf:ast u.k1) kids]
    =?  s  &(?=(^ k1) =(%proof kind.u.k1))  (advance s)
    |-  ^-  (pres node)
    =/  q2=(unit token)
      ?~  rest.s  ~
      ?~  t.rest.s  ~
      `i.t.rest.s
    ?:  &(?=(^ q2) =(%qed kind.u.q2))
      =/  qr  (qed-step s)
      ?:  ?=(%| -.qr)  [%| p.qr]
      :-  %&
      :_  s.p.qr
      (mk-node:ast %n-proof (flop [v.p.qr kids]))
    =/  sr  (step-prod s)
    ?:  ?=(%| -.sr)  [%| p.sr]
    $(s s.p.sr, kids [v.p.sr kids])
  ?:  ?=(%| -.res)  res
  =.  s  s.p.res
  =.  plv.s  ?~(plv.s ~ t.plv.s)
  [%& v.p.res (epa s)]
::
++  step-start
  ::  consume a step token: level check + canonical image
  |=  s=pst
  ^-  (each [n=node tok=token s=pst] @t)
  ::  SANY expects a `Step number` here (R1.3.5.6.4.4)
  =.  s  (set-exp s 'Step number')
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  ?.  (~(has in step-kinds) kind.u.pk)
    [%| (perr-enc s 1)]
  =/  cl  (correct-level s u.pk)
  ?:  ?=(%| -.cl)  [%| p.cl]
  =.  s  p.cl
  =/  ct  (corrected-token s u.pk)
  [%& (leaf:ast ct) u.pk (advance s)]
::
++  qed-step
  |=  s=pst
  ^-  (pres node)
  =/  st  (step-start s)
  ?:  ?=(%| -.st)  [%| p.st]
  =.  s  s.p.st
  =/  qr  (eat s %qed)
  ?:  ?=(%| -.qr)  [%| p.qr]
  =.  s  s.p.qr
  =/  qn  (mk-node:ast %n-qedstep ~[(leaf:ast v.p.qr)])
  =/  nx  (peek s)
  ?.  &(?=(^ nx) (begins-proof s u.nx))
    [%& (mk-node:ast %n-proofstep ~[n.p.st qn]) s]
  =/  pr  (proof-prod s)
  ?:  ?=(%| -.pr)  [%| p.pr]
  :-  %&
  :_  s.p.pr
  (mk-node:ast %n-proofstep ~[n.p.st qn v.p.pr])
::
++  def-ahead
  ::  belchDEF equivalence: a definition LHS starting here reaches ==
  |=  toks=(list token)
  ^-  ?
  ?~  toks  |
  =/  k1  kind.i.toks
  ::  prefix-op ident ==
  ?:  ?&  (is-op-kind k1)
          ?=(^ t.toks)
          =(%identifier kind.i.t.toks)
          ?=(^ t.t.toks)
          =(%def kind.i.t.t.toks)
      ==
    &
  ?.  =(%identifier k1)  |
  ?~  t.toks  |
  =/  k2  kind.i.t.toks
  ?:  =(%def k2)  &
  ::  ident ( .. ) ==   or   ident [ .. ] ==
  ?:  ?=(?(%lbr %lsb) k2)
    =/  open  k2
    =/  shut  ?:(=(%lbr k2) %rbr %rsb)
    =/  depth  1
    =/  t  t.t.toks
    |-  ^-  ?
    ?~  t  |
    ?:  =(0 depth)  =(%def kind.i.t)
    ?:  =(open kind.i.t)  $(t t.t, depth +(depth))
    ?:  =(shut kind.i.t)  $(t t.t, depth (dec depth))
    $(t t.t)
  ::  ident infix-op ident ==   or   ident postfix-op ==
  ?.  (is-op-kind k2)  |
  ?~  t.t.toks  |
  ?:  =(%def kind.i.t.t.toks)  &
  ?&  =(%identifier kind.i.t.t.toks)
      ?=(^ t.t.t.toks)
      =(%def kind.i.t.t.t.toks)
  ==
::
++  step-prod
  ::  Step(): step number + body + optional proof.  SANY's Step production
  ::  (residual stack, at the step number); popped on success (R1.3.5.6.4.4)
  |=  s=pst
  ^-  (pres node)
  =/  stk0  stk.s
  =.  s  (bpa s 'Step')
  =/  st  (step-start s)
  ?:  ?=(%| -.st)  [%| p.st]
  =.  s  s.p.st
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  =/  may-proof  ?=(?(%pick %case) kind.u.pk)
  ?:  ?&  !=(%define kind.u.pk)
          (def-ahead rest.s)
      ==
    =/  br  (def-step s)
    ?:  ?=(%| -.br)  [%| p.br]
    :-  %&
    :_  s.p.br(stk stk0, exp '')
    (mk-node:ast %n-proofstep ~[n.p.st v.p.br])
  =/  body
    ^-  (pres node)
    ?+    kind.u.pk
        ::  AssertStep: [SUFFICES] (AssumeProve | Expression)
      =/  suf=(unit node)
        ?.  =(%suffices kind.u.pk)  ~
        `(leaf:ast u.pk)
      =?  s  ?=(^ suf)  (advance s)
      =/  bk  (peek s)
      ::  no SUFFICES and the body can start neither an AssumeProve nor an
      ::  expression: SANY reports `proof step` without entering Expression
      ::  (R1.3.5.6.4.4)
      ?:  ?&  ?=(~ suf)
              ?|  ?=(~ bk)
                  ?&  !=(%assume kind.u.bk)
                      !=(%boxassume kind.u.bk)
                      !(expr-start kind.u.bk)
                  ==
              ==
          ==
        [%| (perr-enc (set-exp s 'proof step') 1)]
      =/  br
        ^-  (pres node)
        ?:  ?&  ?=(^ bk)
                ?=(?(%assume %boxassume) kind.u.bk)
            ==
          (assume-prove s)
        (expression s)
      ?:  ?=(%| -.br)  [%| p.br]
      :-  %&
      :_  s.p.br
      %+  mk-node:ast  %n-assertstep
      ?~(suf ~[v.p.br] ~[u.suf v.p.br])
    ::
        ?(%use %hide)
      (use-hide-by s)
    ::
        %instance
      (noninst s)
    ::
        ?(%defbreak %define)
      (def-step s)
    ::
        %have
      =/  er  (expression (advance s))
      ?:  ?=(%| -.er)  [%| p.er]
      :-  %&
      :_  s.p.er
      (mk-node:ast %n-havestep ~[(leaf:ast u.pk) v.p.er])
    ::
        %witness
      =.  s  (advance s)
      =|  ws=(list node)
      =.  ws  [(leaf:ast u.pk) ws]
      |-  ^-  (pres node)
      =/  er  (expression s)
      ?:  ?=(%| -.er)  [%| p.er]
      =.  s  s.p.er
      =.  ws  [v.p.er ws]
      =/  ck  (peek s)
      ?.  &(?=(^ ck) =(%comma kind.u.ck))
        [%& (mk-node:ast %n-witnessstep (flop ws)) s]
      =.  ws  [(leaf:ast u.ck) ws]
      $(s (advance s))
    ::
        %take
      (take-pick-step s %n-takestep |)
    ::
        %pick
      (take-pick-step s %n-pickstep &)
    ::
        %case
      =/  er  (expression (advance s))
      ?:  ?=(%| -.er)  [%| p.er]
      :-  %&
      :_  s.p.er
      (mk-node:ast %n-casestep ~[(leaf:ast u.pk) v.p.er])
    ==
  ?:  ?=(%| -.body)  [%| p.body]
  =.  s  s.p.body
  =/  may2
    ?|  may-proof
        ?&  ?=(%node -.v.p.body)
            ?=(%n-assertstep kind.v.p.body)
        ==
    ==
  =/  nx  (peek s)
  ?.  &(?=(^ nx) (begins-proof s u.nx))
    [%& (mk-node:ast %n-proofstep ~[n.p.st v.p.body]) s(stk stk0, exp '')]
  ?.  may2
    [%| (perr-enc s 1)]
  =/  pr  (proof-prod s)
  ?:  ?=(%| -.pr)  [%| p.pr]
  :-  %&
  :_  s.p.pr(stk stk0, exp '')
  (mk-node:ast %n-proofstep ~[n.p.st v.p.body v.p.pr])
::
++  def-step
  ::  [DEFINE] definition+ -> N_DefStep
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  =/  dfl=(unit node)
    ?.  &(?=(^ pk) =(%define kind.u.pk))  ~
    `(leaf:ast u.pk)
  =?  s  ?=(^ dfl)  (advance s)
  =|  ds=(list node)
  =?  ds  ?=(^ dfl)  [u.dfl ds]
  |-  ^-  (pres node)
  =/  dr  (op-or-fun-def s 'Definition')
  ?:  ?=(%| -.dr)
    ?~  ds  [%| p.dr]
    [%& (mk-node:ast %n-defstep (flop ds)) s]
  =.  s  s.p.dr
  =.  ds  [v.p.dr ds]
  ?:  (def-ahead rest.s)  $
  [%& (mk-node:ast %n-defstep (flop ds)) s]
::
++  take-pick-step
  ::  TAKE/PICK: quantbounds or plain idents [+ : expr for PICK]
  |=  [s=pst kind=@tas colon=?]
  ^-  (pres node)
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =.  s  (advance s)
  =|  kids=(list node)
  =.  kids  [(leaf:ast u.pk) kids]
  =/  bounded  (match-fcn-const s)
  =/  lr
    |-  ^-  (each [ks=(list node) s=pst] @t)
    =/  ir
      ^-  (pres node)
      ?:  bounded  (quant-bound2 s)
      =/  jr  (eat s %identifier)
      ?:  ?=(%| -.jr)  [%| p.jr]
      [%& (leaf:ast v.p.jr) s.p.jr]
    ?:  ?=(%| -.ir)  [%| p.ir]
    =.  s  s.p.ir
    =.  kids  [v.p.ir kids]
    =/  ck  (peek s)
    ?.  &(?=(^ ck) =(%comma kind.u.ck))  [%& (flop kids) s]
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  ?:  ?=(%| -.lr)  [%| p.lr]
  =.  s  s.p.lr
  =/  ks  ks.p.lr
  ?.  colon
    [%& (mk-node:ast kind ks) s]
  =/  cr  (eat s %colon)
  ?:  ?=(%| -.cr)  [%| p.cr]
  =/  er  (expression s.p.cr)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er
  (mk-node:ast kind (welp ks ~[(leaf:ast v.p.cr) v.p.er]))
::
++  use-hide-by
  ::  UseOrHideOrBy: [PROOF] BY [ONLY] | USE [ONLY] | HIDE, then
  ::  (MODULE id | expr) list and optional DEF(S) list
  |=  s=pst
  ^-  (pres node)
  ::  SANY's UseOrHideOrBy production (residual stack, at the proof start);
  ::  popped on success (R1.3.5.6.4.4)
  =/  stk0  stk.s
  =.  s  (bpa s 'UseOrHideOrBy')
  =|  kids=(list node)
  =/  kind=@tas  %n-useorhide
  =/  k1  (peek s)
  ?~  k1  [%| (perr-enc s 1)]
  =?  kids  =(%proof kind.u.k1)  [(leaf:ast u.k1) kids]
  =?  s  =(%proof kind.u.k1)  (advance s)
  =/  kw  (peek s)
  ?~  kw  [%| (perr-enc s 1)]
  ?.  ?=(?(%by %use %hide) kind.u.kw)
    [%| (perr-enc s 1)]
  =?  kind  =(%by kind.u.kw)  %n-terminalproof
  =.  kids  [(leaf:ast u.kw) kids]
  =.  s  (advance s)
  =/  ok  (peek s)
  =?  kids  ?&  ?=(^ ok)  =(%only kind.u.ok)
                !=(%hide kind.u.kw)
            ==
    [(leaf:ast u.ok) kids]
  =?  s  ?&  ?=(^ ok)  =(%only kind.u.ok)
             !=(%hide kind.u.kw)
         ==
    (advance s)
  ::  facts
  =/  fk  (peek s)
  =/  facts-done
    ?|  ?=(~ fk)
        =(%df kind.u.fk)
        !(uhb-item-start kind.u.fk)
    ==
  =/  fr
    ^-  (each [ks=(list node) s=pst] @t)
    ?:  facts-done  [%& ~ s]
    =|  ks=(list node)
    |-  ^-  (each [ks=(list node) s=pst] @t)
    =/  ir  (uhb-item s)
    ?:  ?=(%| -.ir)  [%| p.ir]
    =.  s  s.p.ir
    =.  ks  (welp (flop v.p.ir) ks)
    =/  ck  (peek s)
    ?.  &(?=(^ ck) =(%comma kind.u.ck))  [%& (flop ks) s]
    =.  ks  [`node`(leaf:ast u.ck) ks]
    $(s (advance s))
  ?:  ?=(%| -.fr)  [%| p.fr]
  =.  s  s.p.fr
  =.  kids  (welp (flop ks.p.fr) kids)
  ::  DEF(S) section
  =/  dk  (peek s)
  ?.  &(?=(^ dk) =(%df kind.u.dk))
    [%& (mk-node:ast kind (flop kids)) s(stk stk0, exp '')]
  =.  kids  [(leaf:ast u.dk) kids]
  =.  s  (advance s)
  |-  ^-  (pres node)
  =/  tr  (uhb-item s)
  ?:  ?=(%| -.tr)  [%| p.tr]
  =.  s  s.p.tr
  =.  kids  (welp (flop v.p.tr) kids)
  =/  ck  (peek s)
  ?.  &(?=(^ ck) =(%comma kind.u.ck))
    [%& (mk-node:ast kind (flop kids)) s(stk stk0, exp '')]
  =.  kids  [`node`(leaf:ast u.ck) kids]
  $(s (advance s))
::
++  uhb-item
  |=  s=pst
  ^-  (each [v=(list node) s=pst] @t)
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  ?:  =(%module kind.u.pk)
    =/  mr  (eat (advance s) %identifier)
    ?:  ?=(%| -.mr)  [%| p.mr]
    [%& ~[(leaf:ast u.pk) `node`(leaf:ast v.p.mr)] s.p.mr]
  =/  er  (expression s)
  ?:  ?=(%| -.er)  [%| p.er]
  [%& ~[v.p.er] s.p.er]
::
++  uhb-item-start
  |=  k=@tas
  ^-  ?
  |(=(%module k) (expr-start k))
::
++  assume-prove
  ::  [id ::] ASSUME items PROVE expr
  |=  s=pst
  ^-  (pres node)
  =/  k2=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    `i.t.rest.s
  =/  k1  (peek s)
  ?:  ?&  ?=(^ k1)  =(%identifier kind.u.k1)
          ?=(^ k2)  =(%coloncolon kind.u.k2)
      ==
    =/  gid  (general-id u.k1)
    =.  s  (advance (advance s))
    =/  ar  (assume-prove s)
    ?:  ?=(%| -.ar)  [%| p.ar]
    :-  %&
    :_  s.p.ar
    (mk-node:ast %n-label ~[gid (leaf:ast u.k2) v.p.ar])
  =/  kw  (peek s)
  ?~  kw  [%| (perr-enc s 1)]
  ?.  ?=(?(%assume %boxassume) kind.u.kw)
    [%| (perr-enc s 1)]
  ::  SANY's Assume-Prove production (residual stack, at the ASSUME);
  ::  popped on success (R1.3.5.6.4.4)
  =/  stk0  stk.s
  =.  s  (bpa s 'Assume-Prove')
  =.  s  (advance s)
  =|  kids=(list node)
  =.  kids  [(leaf:ast u.kw) kids]
  |-  ^-  (pres node)
  =/  ir  (ap-item s)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =.  kids  [v.p.ir kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  pr  (peek s)
  ?~  pr  [%| (perr-enc s 1)]
  ?.  ?=(?(%prove %boxprove) kind.u.pr)
    [%| (perr-enc s 1)]
  =.  kids  [(leaf:ast u.pr) kids]
  =/  er  (expression (advance s))
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er(stk stk0, exp '')
  (mk-node:ast %n-assumeprove (flop [v.p.er kids]))
::
++  ap-item
  ::  nested AssumeProve, NEW declaration, or expression
  |=  s=pst
  ^-  (pres node)
  =/  k1  (peek s)
  ?~  k1  [%| (perr-enc s 1)]
  =/  k3=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    ?~  t.t.rest.s  ~
    `i.t.t.rest.s
  =/  k2=(unit token)
    ?~  rest.s  ~
    ?~  t.rest.s  ~
    `i.t.rest.s
  ?:  ?|  ?=(?(%assume %boxassume) kind.u.k1)
          ?&  ?=(^ k2)  =(%coloncolon kind.u.k2)
              ?=(^ k3)  ?=(?(%assume %boxassume) kind.u.k3)
          ==
      ==
    (assume-prove s)
  ?:  ?|  =(%new kind.u.k1)
          ?=(?(%constant %variable %state %action %temporal) kind.u.k1)
      ==
    (new-symb s)
  (expression s)
::
++  new-symb
  ::  [NEW] [level-kw] decl [\in expr]
  |=  s=pst
  ^-  (pres node)
  =|  kids=(list node)
  =/  k1  (peek s)
  ?>  ?=(^ k1)
  =?  kids  =(%new kind.u.k1)  [(leaf:ast u.k1) kids]
  =?  s  =(%new kind.u.k1)  (advance s)
  =/  k2  (peek s)
  =?  kids
    ?&  ?=(^ k2)
        ?=(?(%constant %variable %state %action %temporal) kind.u.k2)
    ==
    [(leaf:ast u.k2) kids]
  =?  s
    ?&  ?=(^ k2)
        ?=(?(%constant %variable %state %action %temporal) kind.u.k2)
    ==
    (advance s)
  =/  dr  (param-decl s)
  ?:  ?=(%| -.dr)  [%| p.dr]
  =.  s  s.p.dr
  =.  kids  [v.p.dr kids]
  =/  nk  (peek s)
  ?.  &(?=(^ nk) =(%in kind.u.nk))
    [%& (mk-node:ast %n-newsymb (flop kids)) s]
  =.  kids  [(leaf:ast u.nk) kids]
  =/  er  (expression (advance s))
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er
  (mk-node:ast %n-newsymb (flop [v.p.er kids]))
::
++  match-fcn-const
  ::  lookahead: ident (, ident)* \in  or  << balanced >> \in
  |=  s=pst
  ^-  ?
  =/  toks  rest.s
  ?~  toks  |
  ?:  =(%lab kind.i.toks)
    =/  depth  1
    =/  t  t.toks
    |-  ^-  ?
    ?~  t  |
    ?:  =(0 depth)  =(%in kind.i.t)
    ?:  =(%lab kind.i.t)  $(t t.t, depth +(depth))
    ?:  =(%rab kind.i.t)  $(t t.t, depth (dec depth))
    $(t t.t)
  ?.  =(%identifier kind.i.toks)  |
  =/  t  t.toks
  |-  ^-  ?
  ?~  t  |
  ?:  =(%in kind.i.t)  &
  ?.  =(%comma kind.i.t)  |
  ?~  t.t  |
  ?.  =(%identifier kind.i.t.t)  |
  $(t t.t.t)
::
++  recursive-prod
  ::  RECURSIVE opdecl (, opdecl)*.  SANY's Recursive production wraps the
  ::  whole unit; each item is a Constant declaration items production
  ::  (residual stack); popped once each item parses (R1.3.5.6.4.4)
  |=  s=pst
  ^-  (pres node)
  =.  s  (bpa s 'Recursive')
  =/  kr  (eat s %recursive)
  ?:  ?=(%| -.kr)  [%| p.kr]
  =.  s  s.p.kr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.kr) kids]
  |-  ^-  (pres node)
  =.  s  (bpa s 'Constant declaration items')
  =/  dr  (param-decl s)
  ?:  ?=(%| -.dr)  [%| p.dr]
  =.  s  (epa s.p.dr)
  =.  kids  [v.p.dr kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  [%& (mk-node:ast %n-recursive (flop kids)) (epa s)]
::
++  op-decl
  ::  ident or ident(_,..,_) as N_IdentDecl
  |=  s=pst
  ^-  (pres node)
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  s.p.ir
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.ir) kids]
  =/  pk  (peek s)
  ?.  &(?=(^ pk) =(%lbr kind.u.pk))
    [%& (mk-node:ast %n-identdecl (flop kids)) s]
  =.  kids  [(leaf:ast u.pk) kids]
  =.  s  (advance s)
  |-  ^-  (pres node)
  =/  ur  (eat s %us)
  ?:  ?=(%| -.ur)  [%| p.ur]
  =.  s  s.p.ur
  =.  kids  [(leaf:ast v.p.ur) kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =/  rr  (eat s %rbr)
  ?:  ?=(%| -.rr)  [%| p.rr]
  =.  kids  [(leaf:ast v.p.rr) kids]
  [%& (mk-node:ast %n-identdecl (flop kids)) s.p.rr]
::
++  noninst
  ::  INSTANCE name [WITH substitution (, substitution)*]
  |=  s=pst
  ^-  (pres node)
  ::  SANY's NonLocalInstance production (residual stack); popped on
  ::  success (R1.3.5.6.3)
  =.  s  (bpa s 'NonLocalInstance')
  =/  kr  (eat s %instance)
  ?:  ?=(%| -.kr)  [%| p.kr]
  =/  nr  (eat s.p.kr %identifier)
  ?:  ?=(%| -.nr)  [%| p.nr]
  =.  s  s.p.nr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.nr) (leaf:ast v.p.kr) ~]
  =/  wk  (peek s)
  ?.  &(?=(^ wk) =(%with kind.u.wk))
    [%& (mk-node:ast %n-nonlocalinstance (flop kids)) (epa s)]
  =.  kids  [(leaf:ast u.wk) kids]
  =.  s  (advance s)
  |-  ^-  (pres node)
  =/  sr  (substitution s)
  ?:  ?=(%| -.sr)  [%| p.sr]
  =.  s  s.p.sr
  =.  kids  [v.p.sr kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  [%& (mk-node:ast %n-nonlocalinstance (flop kids)) (epa s)]
::
++  substitution
  ::  (ident | op) <- expr -> N_Substitution
  |=  s=pst
  ^-  (pres node)
  ::  SANY's Substitution production (residual stack); popped on success
  ::  (R1.3.5.6.3)
  =.  s  (bpa s 'Substitution')
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  =/  cls  (class-of u.pk)
  =/  target
    ^-  (each node @t)
    ?:  =(%identifier kind.u.pk)  [%& (leaf:ast u.pk)]
    ?:  ?=([~ %prefix] cls)
      [%& (tok-node:ast %n-nonexpprefixop u.pk)]
    ?:  ?=([~ %infix] cls)
      [%& (tok-node:ast %n-infixop u.pk)]
    ?:  ?=([~ %postfix] cls)
      [%& (tok-node:ast %n-postfixop u.pk)]
    [%| (perr-enc s 1)]
  ?:  ?=(%| -.target)  [%| p.target]
  =.  s  (advance s)
  =/  ar  (eat s %substitute)
  ?:  ?=(%| -.ar)  [%| p.ar]
  ::  a bare `<-` at the body end reports the missing RHS at the
  ::  Substitution level with `Expression or Op. Symbol`, rather than
  ::  entering the Expression production (SANY; R1.3.5.6.4)
  =/  rpk  (peek s.p.ar)
  ?:  ?|(?=(~ rpk) =(%end-module kind.u.rpk))
    [%| (perr-enc (set-exp s.p.ar 'Expression or Op. Symbol') 1)]
  =/  er  (expression s.p.ar)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  (epa s.p.er)
  (mk-node:ast %n-substitution ~[p.target (leaf:ast v.p.ar) v.p.er])
::
++  instance-unit
  ::  [LOCAL] INSTANCE .. -> N_Instance wrapper
  |=  s=pst
  ^-  (pres node)
  ::  SANY's Instance production wraps the NonLocalInstance (residual
  ::  stack); popped on success (R1.3.5.6.3)
  =.  s  (bpa s 'Instance')
  =/  lcl=(unit node)
    =/  pk  (peek s)
    ?.  &(?=(^ pk) =(%local kind.u.pk))  ~
    `(leaf:ast u.pk)
  =?  s  ?=(^ lcl)  (advance s)
  =/  nr  (noninst s)
  ?:  ?=(%| -.nr)  [%| p.nr]
  :-  %&
  :_  (epa s.p.nr)
  %+  mk-node:ast  %n-instance
  ?~(lcl ~[v.p.nr] ~[u.lcl v.p.nr])
::
++  assumption-unit
  ::  ASSUME/ASSUMPTION/AXIOM [name ==] expr -> N_Assumption
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?>  ?=(^ pk)
  =/  kw  (leaf:ast u.pk)
  =.  s  (advance s)
  =/  named  (named-head s)
  =/  er  (expression ?~(named s s.u.named))
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  s.p.er
  %+  mk-node:ast  %n-assumption
  ?~  named  ~[kw v.p.er]
  ~[kw n.u.named d.u.named v.p.er]
::
++  finish-def
  |=  [s=pst lhs=(list node)]
  ^-  (pres node)
  ::  a leading LOCAL leaf arrives at the head of the ordered lhs
  =/  lcl=(unit node)
    ?~  lhs  ~
    ?:  ?&  ?=(%leaf -.i.lhs)
            =(%local kind.token.i.lhs)
        ==
      `i.lhs
    ~
  =/  lhs2  ^-  (list node)
    ?~  lcl  lhs
    ?~(lhs ~ t.lhs)
  =/  dr  (eat s %def)
  ?:  ?=(%| -.dr)  [%| p.dr]
  =.  s  (set-exp s.p.dr 'Expression or Instance')
  =/  pk  (peek s)
  ?:  &(?=(^ pk) =(%instance kind.u.pk))
    =/  nr  (noninst s)
    ?:  ?=(%| -.nr)  [%| p.nr]
    :-  %&
    :_  (epa s.p.nr)
    %+  mk-node:ast  %n-moduledefinition
    %-  welp
    :_  ~[(mk-node:ast %n-identlhs lhs2) (leaf:ast v.p.dr) v.p.nr]
    ?~(lcl ~ ~[u.lcl])
  ::  the Definition choice fails here without entering Expression; LAMBDA
  ::  can start an operand but is NOT a valid definition body (only an
  ::  operator argument), so SANY rejects it here too (R1.3.5.6.4.3)
  ?:  ?|(?=(~ pk) !(expr-start kind.u.pk) =(%lambda kind.u.pk))
    [%| (perr-enc s 1)]
  =/  er  (expression s)
  ?:  ?=(%| -.er)  [%| p.er]
  :-  %&
  :_  (epa s.p.er)
  %+  mk-node:ast  %n-operatordefinition
  %-  welp
  :_  ~[(mk-node:ast %n-identlhs lhs2) (leaf:ast v.p.dr) v.p.er]
  ?~(lcl ~ ~[u.lcl])
::
++  const-decl
  ::  CONSTANT(S) param-decl (, param-decl)*
  |=  s=pst
  ^-  (pres node)
  ::  SANY: the whole unit is a Parameter declaration, each comma-item a
  ::  Constant declaration items production (residual stack); popped once
  ::  each item / the unit parses (R1.3.5.6.1)
  =.  s  (bpa s 'Parameter declaration')
  =/  kr  (eat s %constant)
  ?:  ?=(%| -.kr)  [%| p.kr]
  =.  s  s.p.kr
  =|  kids=(list node)
  =.  kids  [(mk-node:ast %n-consdecl ~[(leaf:ast v.p.kr)]) kids]
  |-  ^-  (pres node)
  =.  s  (bpa s 'Constant declaration items')
  =/  dr  (param-decl s)
  ?:  ?=(%| -.dr)  [%| p.dr]
  =.  s  (epa s.p.dr)
  =.  kids  [v.p.dr kids]
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  [%& (mk-node:ast %n-paramdeclaration (flop kids)) (epa s)]
::
++  decl-list
  ::  KEYWORD ident (, ident)* as [kw-leaf ident comma ident ...]
  |=  [s=pst kw=@tas kind=@tas wrap=?]
  ^-  (pres node)
  ::  SANY names the VARIABLE(S) unit a `variable declaration` production
  ::  (residual stack); popped on success (R1.3.5.6.1)
  =/  vardecl  =(%variable kw)
  =?  s  vardecl  (bpa s 'variable declaration')
  =/  kr  (eat s kw)
  ?:  ?=(%| -.kr)  [%| p.kr]
  =.  s  s.p.kr
  =|  kids=(list node)
  =.  kids  [(leaf:ast v.p.kr) kids]
  |-  ^-  (pres node)
  =.  s  (set-exp s 'Identifier')
  =/  ir  (eat s %identifier)
  ?:  ?=(%| -.ir)  [%| p.ir]
  =.  s  (set-exp s.p.ir 'comma or module body')
  =.  kids
    :_  kids
    ?.  wrap  (leaf:ast v.p.ir)
    (mk-node:ast %n-identdecl ~[(leaf:ast v.p.ir)])
  =/  ck  (peek s)
  ?:  &(?=(^ ck) =(%comma kind.u.ck))
    =.  kids  [(leaf:ast u.ck) kids]
    $(s (advance s))
  =?  s  vardecl  (epa s)
  [%& (mk-node:ast kind (flop kids)) s(exp '')]
::
++  body-end-ahead
  ::  the token after the current keyword is the module end (====) or EOF
  ::  — a bare keyword unit (`THEOREM`/`ASSUME`) at the body's end, which
  ::  SANY fails at the Unit choice rather than inside the unit (R1.3.5.6.3)
  |=  s=pst
  ^-  ?
  =/  n2=(unit token)  ?~(rest.s ~ ?~(t.rest.s ~ `i.t.rest.s))
  ?|(?=(~ n2) =(%end-module kind.u.n2))
::
++  body-unit
  |=  s=pst
  ^-  (pres node)
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  ?+    kind.u.pk
      (op-or-fun-def s 'Definition')
    ::
      ?(%bm0 %bm1 %bm2)
    (module-prod s)
    ::
      %separator
    [%& (leaf:ast u.pk) (advance s)]
    ::
      %variable
    (decl-list s %variable %n-variabledeclaration |)
    ::
      %constant
    (const-decl s)
    ::
      ?(%assume %assumption)
    ::  a bare ASSUME/THEOREM at the very end of the body fails the Unit
    ::  choice at the module-body level (SANY: `Encountered "ASSUME ===="`,
    ::  keyword unconsumed) rather than inside the unit (R1.3.5.6.3)
    ?:  (body-end-ahead s)  [%| (perr-brk s 2)]
    (assumption-unit s)
    ::
      ?(%theorem %proposition)
    ?:  (body-end-ahead s)  [%| (perr-brk s 2)]
    (theorem-unit s)
    ::
      ?(%use %hide)
    (use-hide-unit s)
    ::
      ?(%instance %local)
    ::  LOCAL INSTANCE or LOCAL definition; anything else after LOCAL
    ::  fails the Unit choice exactly as SANY's LOOKAHEAD(2) does
    ::  INSTANCE needs a module-name identifier next; else it fails the
    ::  Unit choice at the body level, keyword unconsumed (R1.3.5.6.3)
    =/  n2i=(unit token)  ?~(rest.s ~ ?~(t.rest.s ~ `i.t.rest.s))
    ?:  =(%instance kind.u.pk)
      ?:  ?&(?=(^ n2i) =(%identifier kind.u.n2i))  (instance-unit s)
      [%| (perr-brk s 2)]
    =/  n2=(unit token)  ?~(rest.s ~ ?~(t.rest.s ~ `i.t.rest.s))
    ?:  &(?=(^ n2) =(%instance kind.u.n2))
      (instance-unit s)
    ?:  (def-ahead ?~(rest.s ~ t.rest.s))
      (op-or-fun-def s 'Definition')
    [%| (perr-brk s 2)]
    ::
      %recursive
    (recursive-prod s)
  ==
::
++  unit-starts
  ::  Body()'s loop guard: can a module unit begin at this token?
  |=  s=pst
  ^-  ?
  =/  pk  (peek s)
  ?~  pk  |
  ?:  ?=  $?  %separator  %variable  %constant  %recursive
              %local  %instance  %assume  %assumption
              %theorem  %proposition  %use  %hide
              %bm0  %bm1  %bm2
          ==
        kind.u.pk
    &
  ::  a definition begins here iff belchDEF would splice its DEFBREAK
  ::  at exactly this token; +def-ahead covers the common LHS shapes
  ?|  (def-ahead rest.s)
      =(`(unit @ud)``0 (belch-index rest.s))
  ==
::
++  body-expecting
  ^-  @t
  'LOCAL, INSTANCE, PROOF, ASSUMPTION, THEOREM, RECURSIVE, declaration, or definition'
::
++  module-prod
  |=  s=pst
  ^-  (pres node)
  =/  stk0  stk.s
  =/  mn0   mname.s
  =.  s  (bpa s 'Module definition')
  =.  s  (set-exp s '---- MODULE')
  ::  BeginModule: bm ident separator
  =.  s  (bpa s 'Begin module')
  =.  s  (set-exp s '---- MODULE (beginning of module)')
  =/  pk  (peek s)
  ?~  pk  [%| (perr-enc s 1)]
  ?.  ?=(?(%bm0 %bm1 %bm2) kind.u.pk)
    [%| (perr-enc s 1)]
  =/  bm  (leaf:ast u.pk)
  =.  s  (advance s)
  =.  s  (set-exp s 'Identifier')
  =/  nr  (eat s %identifier)
  ?:  ?=(%| -.nr)  [%| p.nr]
  =.  s  s.p.nr
  =.  s  s(mname text.v.p.nr)
  =.  s  (set-exp s '----')
  =/  sr  (eat s %separator)
  ?:  ?=(%| -.sr)  [%| p.sr]
  =.  s  (epa s.p.sr)
  =/  begin
    (mk-node:ast %n-beginmodule ~[bm (leaf:ast v.p.nr) (leaf:ast v.p.sr)])
  ::  Extends
  =.  s  (set-exp s 'EXTENDS clause or module body')
  =.  s  (bpa s 'Extends')
  =/  ek  (peek s)
  =/  er
    ^-  (pres node)
    ?.  &(?=(^ ek) =(%extends kind.u.ek))
      [%& (empty-node %n-extends) s]
    (decl-list s %extends %n-extends |)
  ?:  ?=(%| -.er)  [%| p.er]
  =/  extends  v.p.er
  =.  s  (epa s.p.er)
  ::  Body: units while one can start, then ====
  =.  s  (set-exp s 'Module body')
  =.  s  (bpa s 'Module body')
  =.  s  (set-exp s body-expecting)
  =|  units=(list node)
  |-  ^-  (pres node)
  =/  bk  (peek s)
  ?:  &(?=(^ bk) !=(%end-module kind.u.bk) (unit-starts s))
    ::  pinned-bug parity (gh tlaplus/tlaplus): SANY rejects a named
    ::  theorem/assumption immediately following a nested module
    ?:  ?&  ?=(^ units)
            ?=(%node -.i.units)
            =(%n-module kind.i.units)
            ?=(?(%theorem %proposition %assume %assumption) kind.u.bk)
            ?=(^ (named-head (advance s)))
        ==
      [%| (perr-brk s 2)]
    =/  ur  (body-unit s)
    ?:  ?=(%| -.ur)  [%| p.ur]
    $(units [v.p.ur units], s s.p.ur)
  ::  EndModule; Body pops before the ==== consume
  =.  s  (epa s)
  =.  s  (set-exp s '==== or more Module body')
  =/  mr  (eat s %end-module)
  ?:  ?=(%| -.mr)  [%| p.mr]
  =.  s  s.p.mr
  =/  body
    ?~  units  (empty-node %n-body)
    (mk-node:ast %n-body (flop units))
  =/  endm
    (mk-node:ast %n-endmodule ~[(leaf:ast v.p.mr)])
  :-  %&
  :_  s(stk stk0, exp '', mname mn0)
  (mk-node:ast %n-module ~[begin extends body endm])
::
::  +|  Entry And Differential Dump
::
::
++  parse
  |=  text=@t
  ^-  (each node @t)
  =/  items  (lex:lex text)
  =/  lerr  (lex-err-text items)
  ?^  lerr  [%| u.lerr]
  =/  toks
    ^-  (list token)
    %+  murn  items
    |=  it=item:lex
    ^-  (unit token)
    ?:(?=(%tok -.it) `token.it ~)
  =/  mr  (module-prod [toks ~ ~ ~ '' ~ '' (parse-eof-pos text)])
  ?:  ?=(%| -.mr)  mr
  [%& v.p.mr]
::
++  lex-err-text
  ::  the parse()-level rendering of a lexical error: the raw
  ::  TokenMgrError text, or the EOF wrapper when the failing lexeme
  ::  spans lines (an unterminated comment or string)
  |=  items=(list item:lex)
  ^-  (unit @t)
  |-  ^-  (unit @t)
  ?~  items  ~
  ?.  ?=(%err -.i.items)  $(items t.items)
  =/  e  i.items
  ?.  &((has-eof msg.e) !=(bl.e el.e))  `msg.e
  :-  ~
  %-  crip
  %+  welp
    "Lexical \{error: EOF reached, possibly open comment starting around line "
  (dec-tape:ast bl.e)
::
++  has-eof
  |=  msg=@t
  ^-  ?
  =/  t  (trip msg)
  |-  ^-  ?
  ?~  t  |
  ?:  ?=([%'E' %'O' %'F' *] t)  &
  $(t +.t)
::
++  parse-eof-pos
  ::  the parser's EOF-token position: the begin of the trailing
  ::  whitespace run, one past the final character, or 0.0 when empty
  |=  text=@t
  ^-  pos
  =/  all  (annotate:src text)
  ?~  all  [0 0]
  =/  rev  (flop `(list ach:src)`all)
  =/  run=(unit pos)  ~
  |-  ^-  pos
  ?~  rev  (need run)
  ?:  ?=(?(%9 %10 %12 %13 %32) `@`c.i.rev)
    $(rev t.rev, run `[l.i.rev col.i.rev])
  ?~  run  [l.i.rev +(col.i.rev)]
  u.run
::
++  dump
  ::  AstDump.java format: ACCEPT + tree lines, or REJECT
  |=  text=@t
  ^-  wain
  =/  res  (parse text)
  ?:  ?=(%| -.res)  ~['REJECT']
  ['ACCEPT' (dump-node:ast p.res)]
::
++  dump-err
  ::  ParseErrDump.java format: ACCEPT alone, or REJECT + the verbatim
  ::  PErrors text, each entry terminated by a %% line
  |=  text=@t
  ^-  wain
  =/  res  (parse text)
  ?:  ?=(%| -.res)
    ::  explicit fold: the wet turn/zing composition fuse-loops on the
    ::  narrowed fork type here
    =/  errs=(list @t)  (split-errs `@t`p.res)
    =/  out=wain  ~['REJECT']
    |-  ^-  wain
    ?~  errs  out
    =/  seg=wain  (weld (cord-lines i.errs) `wain`~['%%'])
    $(errs t.errs, out (weld out seg))
  ~['ACCEPT']
::
++  cord-lines
  ::  split on newlines, keeping a trailing empty line
  |=  t=@t
  ^-  wain
  =/  tp  (trip t)
  =|  cur=tape
  =|  out=wain
  |-  ^-  wain
  ?~  tp  (flop [(crip (flop cur)) out])
  ?:  =('\0a' i.tp)
    $(tp t.tp, cur ~, out [(crip (flop cur)) out])
  $(tp t.tp, cur [i.tp cur])
::
++  split-errs
  ::  multiple accumulated errors travel joined by the \01 separator
  |=  msg=@t
  ^-  (list @t)
  =/  t  (trip msg)
  =|  cur=tape
  =|  out=(list @t)
  |-  ^-  (list @t)
  ?~  t  (flop [(crip (flop cur)) out])
  ?:  =('\01' i.t)
    $(t t.t, cur ~, out [(crip (flop cur)) out])
  $(t t.t, cur [i.t cur])
::
++  parse-typed
  ::  typed parse result for the pipeline (unit 2): the tree when the
  ::  parse succeeded, plus ordered diagnostics; every parse error is
  ::  fatal (SANY recovery beyond PErrors accumulation is not ported)
  |=  text=@t
  ^-  [tree=(unit node) diags=(list diagnostic) fatal=?]
  =/  res  (parse text)
  ?:  ?=(%| -.res)
    =/  msg  `@t`p.res
    :+  ~
      %+  turn  (split-errs msg)
      |=  e=@t
      ^-  diagnostic
      [[%sany 0] %error %parse e ~ ~]
    &
  [`p.res ~ |]
++  grammar-manifest
  ::  one entry per production section in doc/tla-bnf.md; the generated
  ::  test tests/lib/bnf.hoon fails when either side drifts
  ^-  (list @tas)
  :~
      %module
      %begin-module
      %extends
      %body
      %variable-declaration
      %param-declaration
      %ident-decl
      %op-decls
      %recursive
      %operator-definition
      %function-definition
      %module-definition
      %instance
      %assumption
      %theorem
      %use-or-hide
      %expression
      %junctions
      %general-id
      %op-application
      %atoms
      %action-expr
      %if-then-else
      %case
      %let-in
      %quantifiers
      %lambda
      %fairness
      %sets
      %records-functions
      %except
      %label
      %proof
      %proof-step
      %assume-prove
  ==
--