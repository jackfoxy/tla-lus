/-  *tla-lus
/=  lex  /lib/tla/lexer
/=  eval  /lib/tla/eval
|%
::  TLC .cfg processing (PORT-COMPLETION-PLAN-2 unit 5).
::
::  Faithful port of tlc2.tool.impl.ModelConfig.parse/parseValue at the
::  pinned commit: the full ModelConfig line grammar over the WU3 token
::  manager (lexstate SPEC via lex-cfg), CONSTANT/override machinery,
::  parseValue, byte-exact rawConstants, and the CFG_* diagnostic family
::  (5001-5006). +dump-cfg renders the normalized projection shared with
::  the Java ConfigDump oracle (tools/oracle/ConfigDump.java).
::
::  ModelConfig.parse throws ConfigFileException on the FIRST malformed
::  construct, so at most one CFG diagnostic per file. Config-vs-graph
::  semantic validation (TLC_CONFIG_*) and the typed run-spec are units
::  5.3/5.4; this file only lexes, parses, and renders the config AST.
::
::  +|  Types
::
::  a parsed .cfg value (parseValue). Reuse eval.hoon's proven canonical
::  value mold rather than defining a second $+-recursive $% union in this
::  file (the zuse-408 mold compiler overflows on a freshly-defined one).
::  cfg only ever produces %int (from NUMBER_LITERAL, always >=0), %str
::  (quotes stripped), %bool, %model, and %set of these.
+$  cfg-value  value:eval
::  a CONSTANT assignment line: lhs (! ) args (op form) rhs value
+$  cfg-const  [lhs=@t args=(list cfg-value) val=cfg-value]
::  parsed config, in ModelConfig storage order
+$  cfg-ast
  $:  init=(unit @t)
      next=(unit @t)
      spec=(unit @t)
      view=(unit @t)
      symmetry=(unit @t)
      alias=(unit @t)
      periodic=(unit @t)
      rlreward=(unit @t)
      deadlock=?(%true %false %undef)       ::  %undef last so it is the bunt
      invariants=(list @t)
      properties=(list @t)
      constraints=(list @t)
      action-constraints=(list @t)
      postconditions=(list @t)
      possible=(list @t)
      constants=(list cfg-const)
      overrides=(map @t @t)                 ::  lhs -> rhs (main module)
      mod-overrides=(map @t (map @t @t))    ::  mod -> lhs -> rhs
      mod-constants=(map @t (list cfg-const))
      raw=(list @t)                         ::  rawConstants buffers, verbatim
  ==
::  a config-file diagnostic (EC 5001-5006) with its rendered message
+$  cfg-diag  [code=@ud line=@ud msg=@t]
+$  cfg-result  (each cfg-ast cfg-diag)
::  a config token, projected from the lexer stream
+$  ctok  [img=@t line=@ud num=? str=?]
::  a +pull result: the token (~ = EOF), remaining stream, buffer, line
+$  ptok  [tok=(unit ctok) rest=(list ctok) buf=@t ln=@ud]
::
::  +|  Lexing
::
++  ctoks
  ::  project the WU3 lexer stream (in SPEC state) to config tokens:
  ::  drop comments; a lexical error is the getNextToken TokenMgrError
  ::  swallow, so truncate the stream to EOF there.
  |=  cfg=@t
  ^-  (list ctok)
  =/  items  (lex-cfg:lex cfg)
  |-  ^-  (list ctok)
  ?~  items  ~
  ?-  -.i.items
    %com  $(items t.items)
    %err  ~
      %tok
    =/  tk  token.i.items
    :_  $(items t.items)
    :*  img=text.tk
        line=line.from.span.tk
        num=?=(%number-literal kind.tk)
        str=?=(%string-literal kind.tk)
    ==
  ==
::
::  +|  Keyword Table
::
++  keywords
  ^-  (set @t)
  %-  sy
  ^-  (list @t)
  :~  'CONSTANT'  'CONSTANTS'  'CONSTRAINT'  'CONSTRAINTS'
      'ACTION_CONSTRAINT'  'ACTION_CONSTRAINTS'
      'INVARIANT'  'INVARIANTS'  'INIT'  'NEXT'  'VIEW'  'SYMMETRY'
      'SPECIFICATION'  'PROPERTY'  'PROPERTIES'  'ALIAS'
      'POSTCONDITION'  'POSTCONDITIONS'  '_PERIODIC'  '_RL_REWARD'
      '_POSSIBLE'  'CHECK_DEADLOCK'
  ==
::
::  +|  Small Helpers
::
++  num-cord
  |=  n=@ud
  ^-  @t
  ?:  =(0 n)  '0'
  =|  acc=tape
  |-  ^-  @t
  ?:  =(0 n)  (crip acc)
  $(n (div n 10), acc [(add '0' (mod n 10)) acc])
::
++  read-dec  |=(t=@t `@ud`(slav %ud t))
::
++  unquote
  ::  strip the surrounding quotes of a STRING_LITERAL image
  |=  t=@t
  ^-  @t
  =/  tp  (trip t)
  ?:  (lth (lent tp) 2)  t
  (crip (scag (sub (lent tp) 2) (slag 1 tp)))
::
++  cord-lte
  ::  byte-lexicographic (matches java.lang.String.compareTo on ASCII)
  |=  [a=@t b=@t]
  ^-  ?
  =/  la  (trip a)
  =/  lb  (trip b)
  |-  ^-  ?
  ?~  la  &
  ?~  lb  |
  ?:  =(i.la i.lb)  $(la t.la, lb t.lb)
  (lth i.la i.lb)
::
++  emsg
  ::  render a CFG_* (5002-5006) message; arg is the keyword or symbol
  |=  [code=@ud line=@ud arg=@t]
  ^-  @t
  =/  pre
    %+  rap  3
    :~  'TLC found an error in the configuration file at line '
        (num-cord line)  '\0a'
    ==
  ?:  =(code 5.003)
    (rap 3 ~[pre 'The keyword ' arg ' was not followed by an identifier.'])
  ?:  =(code 5.004)
    (rap 3 ~[pre 'The keyword ' arg ' appeared twice.'])
  ?:  =(code 5.005)
    (rap 3 ~[pre 'Expected an identifier after ' arg '.'])
  ?:  =(code 5.006)
    (rap 3 ~[pre 'It was expecting ' arg ', but did not find it.'])
  pre
::
++  ed  |=([c=@ud l=@ud a=@t] ^-(cfg-diag [c l (emsg c l a)]))
::
::  +|  Buffer-Appending Token Reader (getNextToken(tmgr, buf))
::
++  pull
  ::  pop the head token, appending "<image> " to the rawConstants buffer
  ::  and advancing the current line; EOF appends nothing (only reached on
  ::  error paths, whose buffer is discarded)
  |=  [toks=(list ctok) buf=@t ln=@ud]
  ^-  [tok=(unit ctok) rest=(list ctok) buf=@t ln=@ud]
  ?~  toks  [~ ~ buf ln]
  [`i.toks t.toks (rap 3 ~[buf img.i.toks ' ']) line.i.toks]
::
::  +|  parseValue
::
++  parse-value
  ::  toks head is the current value token, already appended to buf
  |=  [toks=(list ctok) buf=@t ln=@ud]
  ^-  (each [v=cfg-value rest=(list ctok) buf=@t ln=@ud] cfg-diag)
  ?~  toks  [%| (ed 5.006 ln 'a value')]
  =/  cur  i.toks
  ?:  num.cur  [%& [%int (sun:si (read-dec img.cur))] t.toks buf line.cur]
  ?:  str.cur  [%& [%str (unquote img.cur)] t.toks buf line.cur]
  ?:  =(img.cur 'TRUE')   [%& [%bool &] t.toks buf line.cur]
  ?:  =(img.cur 'FALSE')  [%& [%bool |] t.toks buf line.cur]
  ?.  =(img.cur '{')
    [%& [%model img.cur] t.toks buf line.cur]
  ::  set enumeration: pull the token after '{'
  =/  p  (pull t.toks buf line.cur)
  ?:  ?&(?=(^ tok.p) =(img.u.tok.p '}'))
    [%& [%set ~] rest.p buf.p ln.p]
  ::  non-empty: parse elements until a non-comma, then require '}'
  =|  acc=(list cfg-value)
  =/  el-toks=(list ctok)  ?~(tok.p ~ [u.tok.p rest.p])
  =/  cbuf  buf.p
  =/  cln   ln.p
  |-  ^-  (each [v=cfg-value rest=(list ctok) buf=@t ln=@ud] cfg-diag)
  =/  r  (parse-value el-toks cbuf cln)
  ?:  ?=(%| -.r)  r
  =/  ev  v.p.r
  =/  q  (pull rest.p.r buf.p.r ln.p.r)
  ?:  ?|(?=(~ tok.q) !=(img.u.tok.q ','))
    ?.  ?&(?=(^ tok.q) =(img.u.tok.q '}'))
      [%| (ed 5.006 ln.q '}')]
    [%& [%set (flop [ev acc])] rest.q buf.q ln.q]
  ::  comma: pull the next element's first token and continue
  =/  n  (pull rest.q buf.q ln.q)
  %=  $
    acc      [ev acc]
    el-toks  ?~(tok.n ~ [u.tok.n rest.n])
    cbuf     buf.n
    cln      ln.n
  ==
::
::  +|  CONSTANT / Override Section
::
++  const-section
  ::  parse one CONSTANT/CONSTANTS section; kw is the keyword image, loc
  ::  its line (for CFG_GENERAL), toks head is the first token after it.
  ::  Returns the updated ast and the tokens left for the outer loop
  ::  (head = the break keyword, or ~).
  |=  [kw=@t loc=@ud toks=(list ctok) ast=cfg-ast]
  ^-  (each [ast=cfg-ast rest=(list ctok)] cfg-diag)
  |^  (line toks kw)
  ++  line
    |=  [toks=(list ctok) buf=@t]
    ^-  (each [ast=cfg-ast rest=(list ctok)] cfg-diag)
    ?~  toks
      [%& ast(raw (snoc raw.ast buf)) ~]
    ?:  (~(has in keywords) img.i.toks)
      [%& ast(raw (snoc raw.ast buf)) toks]
    ::  assignment line: lhs first token (no-buf), append "\n<lhs> "
    =/  lhs0  img.i.toks
    =/  ln0   line.i.toks
    =/  p  (pull t.toks (rap 3 ~[buf '\0a' lhs0 ' ']) ln0)
    ::  compound !-chain: lhs!id!id...
    =/  cc
      |-  ^-  [lhs=@t p=ptok]
      ?.  ?&(?=(^ tok.p) =(img.u.tok.p '!'))
        [lhs0 p]
      =/  q  (pull rest.p buf.p ln.p)
      =/  lhs1  (rap 3 ~[lhs0 '!' ?~(tok.q '' img.u.tok.q)])
      $(lhs0 lhs1, p (pull rest.q buf.q ln.q))
    (dispatch lhs.cc p.cc)
  ::  after lhs (+ ! chain): p.tok is <-, (, or =
  ++  dispatch
    |=  [lhs=@t p=ptok]
    ^-  (each [ast=cfg-ast rest=(list ctok)] cfg-diag)
    ?:  ?&(?=(^ tok.p) =(img.u.tok.p '<-'))
      (override lhs (pull rest.p buf.p ln.p))
    (assign lhs ~ p)
  ::  <- override (main module or module override <-[mod])
  ++  override
    |=  [lhs=@t p=ptok]
    ^-  (each [ast=cfg-ast rest=(list ctok)] cfg-diag)
    ?:  ?&(?=(^ tok.p) =(img.u.tok.p '['))
      ::  module override: <- [ mod ] rhs
      =/  m  (pull rest.p buf.p ln.p)
      ?~  tok.m  [%| (ed 5.005 ln.m '<-[')]
      =/  mod  img.u.tok.m
      =/  c  (pull rest.m buf.m ln.m)
      ?.  ?&(?=(^ tok.c) =(img.u.tok.c ']'))
        [%| (ed 5.006 ln.c ']')]
      =/  r  (pull rest.c buf.c ln.c)
      ?~  tok.r  [%| (ed 5.005 ln.r '<-[mod]')]
      =/  inner  (~(gut by mod-overrides.ast) mod *(map @t @t))
      =.  ast  ast(mod-overrides (~(put by mod-overrides.ast) mod (~(put by inner) lhs img.u.tok.r)))
      (line rest.r buf.r)
    ::  main override
    ?~  tok.p  [%| (ed 5.005 ln.p '<-')]
    =.  ast  ast(overrides (~(put by overrides.ast) lhs img.u.tok.p))
    (line rest.p buf.p)
  ::  = assignment, optionally with (args) and/or [mod]
  ++  assign
    |=  [lhs=@t args=(list cfg-value) p=ptok]
    ^-  (each [ast=cfg-ast rest=(list ctok)] cfg-diag)
    ?:  ?&(?=(^ tok.p) =(img.u.tok.p '('))
      (args-loop lhs args (pull rest.p buf.p ln.p))
    ?.  ?&(?=(^ tok.p) =(img.u.tok.p '='))
      [%| (ed 5.006 ln.p '= or <-')]
    =/  tv  (pull rest.p buf.p ln.p)
    ?:  ?&(?=(^ tok.tv) =(img.u.tok.tv '['))
      ::  module-specific constant: = [ mod ] value
      =/  m  (pull rest.tv buf.tv ln.tv)
      ?~  tok.m  [%| (ed 5.005 ln.m '=[')]
      =/  mod  img.u.tok.m
      =/  c  (pull rest.m buf.m ln.m)
      ?.  ?&(?=(^ tok.c) =(img.u.tok.c ']'))
        [%| (ed 5.006 ln.c ']')]
      =/  tval  (pull rest.c buf.c ln.c)
      =/  rv  (parse-value ?~(tok.tval ~ [u.tok.tval rest.tval]) buf.tval ln.tval)
      ?:  ?=(%| -.rv)  rv
      =/  cur=cfg-const  [lhs args v.p.rv]
      =/  ex  (~(gut by mod-constants.ast) mod *(list cfg-const))
      =.  ast  ast(mod-constants (~(put by mod-constants.ast) mod (snoc ex cur)))
      (line rest.p.rv buf.p.rv)
    ::  main constant
    =/  rv  (parse-value ?~(tok.tv ~ [u.tok.tv rest.tv]) buf.tv ln.tv)
    ?:  ?=(%| -.rv)  rv
    =.  ast  ast(constants (snoc constants.ast [lhs args v.p.rv]))
    (line rest.p.rv buf.p.rv)
  ::  operator-argument list: ( v , v , ... )
  ++  args-loop
    |=  [lhs=@t args=(list cfg-value) p=ptok]
    ^-  (each [ast=cfg-ast rest=(list ctok)] cfg-diag)
    =/  rv  (parse-value ?~(tok.p ~ [u.tok.p rest.p]) buf.p ln.p)
    ?:  ?=(%| -.rv)  rv
    =/  args1  (snoc args v.p.rv)
    =/  tn  (pull rest.p.rv buf.p.rv ln.p.rv)
    ?:  ?&(?=(^ tok.tn) =(img.u.tok.tn ','))
      (args-loop lhs args1 (pull rest.tn buf.tn ln.tn))
    ::  end of arg list: tn must be ')'
    ?.  ?&(?=(^ tok.tn) =(img.u.tok.tn ')'))
      [%| (ed 5.002 loc '')]
    (assign lhs args1 (pull rest.tn buf.tn ln.tn))
  --
::
::  +|  Main Line Grammar
::
++  parse-cfg
  |=  cfg=@t
  ^-  cfg-result
  =|  ast=cfg-ast
  =/  toks  (ctoks cfg)
  |-  ^-  cfg-result
  ?~  toks  [%& ast]
  =/  kw   img.i.toks
  =/  loc  line.i.toks
  =/  rest  t.toks
  ::  single-value keys: EOF -> 5003; already set -> 5004; else set + prime
  ?:  =(kw 'INIT')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  init.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(init `img.i.rest), toks t.rest)
  ?:  =(kw 'NEXT')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  next.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(next `img.i.rest), toks t.rest)
  ?:  =(kw 'SPECIFICATION')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  spec.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(spec `img.i.rest), toks t.rest)
  ?:  =(kw 'VIEW')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  view.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(view `img.i.rest), toks t.rest)
  ?:  =(kw 'SYMMETRY')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  symmetry.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(symmetry `img.i.rest), toks t.rest)
  ?:  =(kw 'ALIAS')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  alias.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(alias `img.i.rest), toks t.rest)
  ?:  =(kw '_PERIODIC')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  periodic.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(periodic `img.i.rest), toks t.rest)
  ?:  =(kw '_RL_REWARD')
    ?~  rest  [%| (ed 5.003 loc kw)]
    ?^  rlreward.ast  [%| (ed 5.004 loc kw)]
    $(ast ast(rlreward `img.i.rest), toks t.rest)
  ::  list keys
  ?:  ?|(=(kw 'INVARIANT') =(kw 'INVARIANTS'))
    =/  r  (take-list rest)
    $(ast ast(invariants (weld invariants.ast acc.r)), toks rest.r)
  ?:  ?|(=(kw 'PROPERTY') =(kw 'PROPERTIES'))
    =/  r  (take-list rest)
    $(ast ast(properties (weld properties.ast acc.r)), toks rest.r)
  ?:  ?|(=(kw 'CONSTRAINT') =(kw 'CONSTRAINTS'))
    =/  r  (take-list rest)
    $(ast ast(constraints (weld constraints.ast acc.r)), toks rest.r)
  ?:  ?|(=(kw 'ACTION_CONSTRAINT') =(kw 'ACTION_CONSTRAINTS'))
    =/  r  (take-list rest)
    $(ast ast(action-constraints (weld action-constraints.ast acc.r)), toks rest.r)
  ?:  ?|(=(kw 'POSTCONDITION') =(kw 'POSTCONDITIONS'))
    =/  r  (take-list rest)
    $(ast ast(postconditions (weld postconditions.ast acc.r)), toks rest.r)
  ?:  =(kw '_POSSIBLE')
    =/  r  (take-list rest)
    $(ast ast(possible (weld possible.ast acc.r)), toks rest.r)
  ::  CHECK_DEADLOCK
  ?:  =(kw 'CHECK_DEADLOCK')
    ?~  rest  [%| (ed 5.003 loc kw)]
    =/  v  i.rest
    ?:  =(img.v 'TRUE')
      ?.  ?=(%undef deadlock.ast)  [%| (ed 5.004 loc kw)]
      $(ast ast(deadlock %true), toks t.rest)
    ?:  =(img.v 'FALSE')
      ?.  ?=(%undef deadlock.ast)  [%| (ed 5.004 loc kw)]
      $(ast ast(deadlock %false), toks t.rest)
    [%| (ed 5.006 line.v 'TRUE or FALSE')]
  ::  CONSTANT / CONSTANTS
  ?:  ?|(=(kw 'CONSTANT') =(kw 'CONSTANTS'))
    =/  r  (const-section kw loc rest ast)
    ?:  ?=(%| -.r)  r
    $(ast ast.p.r, toks rest.p.r)
  ::  unknown keyword
  [%| (ed 5.006 loc 'a keyword')]
::
++  take-list
  ::  accumulate token images until the next token is a keyword or EOF
  |=  toks=(list ctok)
  ^-  [acc=(list @t) rest=(list ctok)]
  =|  acc=(list @t)
  |-  ^-  [acc=(list @t) rest=(list ctok)]
  ?~  toks  [(flop acc) ~]
  ?:  (~(has in keywords) img.i.toks)  [(flop acc) toks]
  $(acc [img.i.toks acc], toks t.toks)
::
::  +|  Rendering (ConfigDump projection)
::
++  render-value
  |=  v=cfg-value
  ^-  tape
  ?+  -.v  ~|(%cfg-value-unexpected !!)
    %int    (trip (num-cord (abs:si p.v)))    ::  cfg NUMBER_LITERALs are >=0
    %str    :(weld "\"" (trip p.v) "\"")
    %bool   ?:(p.v "TRUE" "FALSE")
    %model  (trip p.v)
    %set    :(weld (trip '{') (join ", " (turn p.v render-value)) (trip '}'))
  ==
::
++  render-line
  |=  c=cfg-const
  ^-  tape
  =/  base  (trip lhs.c)
  =/  withargs
    ?~  args.c  base
    :(weld base " ( " (join " , " (turn args.c render-value)) " )")
  :(weld withargs " = " (render-value val.c))
::
++  join
  |=  [sep=tape l=(list tape)]
  ^-  tape
  ?~  l  ~
  ?~  t.l  i.l
  :(weld i.l sep $(l t.l))
::
++  by-key
  |=  m=(map @t *)
  ^-  (list @t)
  (sort (turn ~(tap by m) head) cord-lte)
::
++  render
  |=  a=cfg-ast
  ^-  @t
  =|  o=tape
  =.  o  (weld o "CONFIG\0a")
  =.  o  (scalar-line o 'init' init.a)
  =.  o  (scalar-line o 'next' next.a)
  =.  o  (scalar-line o 'spec' spec.a)
  =.  o  (scalar-line o 'view' view.a)
  =.  o  (scalar-line o 'symmetry' symmetry.a)
  =.  o  (scalar-line o 'alias' alias.a)
  =.  o  (scalar-line o 'periodic' periodic.a)
  =.  o  (scalar-line o 'rlreward' rlreward.a)
  =.  o  :(weld o "deadlock " ?:(?=(%false deadlock.a) "false" "true") "\0a")
  =.  o  (list-lines o 'invariant' invariants.a)
  =.  o  (list-lines o 'property' properties.a)
  =.  o  (list-lines o 'constraint' constraints.a)
  =.  o  (list-lines o 'action-constraint' action-constraints.a)
  =.  o  (list-lines o 'postcondition' postconditions.a)
  =.  o  (list-lines o 'possible' possible.a)
  ::  constants (parse order)
  =.  o
    |-  ^-  tape
    ?~  constants.a  o
    $(o :(weld o "const " (render-line i.constants.a) "\0a"), constants.a t.constants.a)
  ::  main overrides, sorted by lhs
  =.  o
    =/  ks  (by-key overrides.a)
    |-  ^-  tape
    ?~  ks  o
    =/  r  (~(got by overrides.a) i.ks)
    $(o :(weld o "override " (trip i.ks) " <- " (trip r) "\0a"), ks t.ks)
  ::  module overrides, sorted by mod then lhs
  =.  o
    =/  ms  (by-key mod-overrides.a)
    |-  ^-  tape
    ?~  ms  o
    =/  inner  (~(got by mod-overrides.a) i.ms)
    =/  ls  (by-key inner)
    =/  chunk
      =|  c=tape
      |-  ^-  tape
      ?~  ls  c
      =/  r  (~(got by inner) i.ls)
      $(ls t.ls, c :(weld c "mod-override " (trip i.ms) " " (trip i.ls) " <- " (trip r) "\0a"))
    $(o (weld o chunk), ms t.ms)
  ::  module constants, sorted by mod (lines in parse order)
  =.  o
    =/  ms  (by-key mod-constants.a)
    |-  ^-  tape
    ?~  ms  o
    =/  cs  (~(got by mod-constants.a) i.ms)
    =/  chunk
      =|  c=tape
      |-  ^-  tape
      ?~  cs  c
      $(cs t.cs, c :(weld c "mod-const " (trip i.ms) " " (render-line i.cs) "\0a"))
    $(o (weld o chunk), ms t.ms)
  =.  o  (weld o "RAW\0a")
  =.  o
    |-  ^-  tape
    ?~  raw.a  o
    $(o :(weld o (trip i.raw.a) "\0a---\0a"), raw.a t.raw.a)
  (crip o)
::
++  scalar-line
  |=  [o=tape key=@t v=(unit @t)]
  ^-  tape
  ?~  v  o
  :(weld o (trip key) " " (trip u.v) "\0a")
::
++  list-lines
  |=  [o=tape key=@t l=(list @t)]
  ^-  tape
  ?~  l  o
  $(o :(weld o (trip key) " " (trip i.l) "\0a"), l t.l)
::
::  +|  Entrypoint
::
++  dump-cfg
  ::  render the ConfigDump projection (or CONFIG-ERROR) for a .cfg text
  |=  cfg=@t
  ^-  @t
  =/  r  (parse-cfg cfg)
  ?-  -.r
      %&
    (render p.r)
      %|
    =/  m  msg.p.r
    =/  tp  (trip m)
    =/  m2  ?:(&(?=(^ tp) =('\0a' (rear tp))) m (cat 3 m '\0a'))
    (cat 3 'CONFIG-ERROR\0a' m2)
  ==
--
