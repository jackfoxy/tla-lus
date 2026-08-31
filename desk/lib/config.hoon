/-  *tla-lus
/=  lex  /lib/lexer
/=  eval  /lib/eval
/=  sem-lib  /lib/semantic
/=  k  /lib/constants
/=  diag  /lib/diagnostics
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
  ::  the TLAConstants.KeyWords members route through /lib/constants (`k`);
  ::  the plurals and TLC-internal sections (not in TLAConstants) stay literal
  :~  constant:k  constants:k  'CONSTRAINT'  'CONSTRAINTS'
      action-constraint:k  'ACTION_CONSTRAINTS'
      invariant:k  'INVARIANTS'  init:k  next:k  view:k  symmetry:k
      specification:k  property:k  'PROPERTIES'  'ALIAS'
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
  ::  render a CFG_* (5002-5006) message body through the shared MP renderer
  ::  (+ec-body:diag) -- single source of truth with lib/diagnostics; byte-
  ::  identical to MP.getMessage0 (R1.3.5.7.3). `arg` is the keyword/symbol
  ::  (the %2% param; unused by 5002).
  |=  [code=@ud line=@ud arg=@t]
  ^-  @t
  (ec-body:diag code ~[(num-cord line) arg])
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
    [%& [%set %set-enum ~] rest.p buf.p ln.p]
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
    [%& [%set %set-enum (flop [ev acc])] rest.q buf.q ln.q]
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
::  +|  Config-vs-Graph Validation (SpecProcessor.processConfig)
::
::  Port of tlc2.tool.impl.SpecProcessor's config-processing methods over
::  the WU3 semantic graph (sem-module). Fail-fast, like the Java: the
::  first violation is the only diagnostic. Handles the constant-table and
::  substitution codes (2242, 2222, 2223/2224/2225/2226, 2281), the
::  resolution codes (2227/2228/2229/2230/2231/2232/2233), the invariant
::  level code (2146) and the property action-level code (2272), in
::  SpecProcessor's own order. Deep SPECIFICATION-form unfolding is
::  +decompose-spec's (lib/check, R1.8.1.1): here a valid arity-0
::  SPECIFICATION is treated as establishing init and next.
::
+$  cfg-vdiag  [code=@ud msg=@t]
::  one entry of the `defns` table SpecProcessor.processSpec builds before
::  processConfig runs. Every processConfig* method dispatches on exactly
::  this -- `instanceof OpDefNode` / `== null` / a value -- which is why
::  2229/2230/2233 cannot be read off the semantic graph alone: a config
::  `CONSTANT Inv = 42` REPLACES the operator Inv in the table, and a
::  declared CONSTANT that only an override will fill resolves to null
::  until the override loop runs. R1.8.1.3b
+$  dentry
  $%  [%def d=sem-def:sem-lib]
      [%val v=cfg-value]
      ::  an OpRcdValue: the `F(a) = v` operator-record lines, with the
      ::  arity the first line fixed (makeConstantTable)
      [%opr ary=@ud lines=(list cfg-const)]
      ::  a declared CONSTANT with no value yet (defns.get -> null)
      [%none ~]
  ==
::  the typed run specification (unit 5.4): the single hand-off every
::  checking mode consumes, superseding the old cfg-word lookups. Mode is
::  spec-form (SPECIFICATION) xor init/next-form.
+$  run-mode
  $%  [%spec name=@t]
      [%init-next init=(unit @t) next=(unit @t)]
  ==
+$  run-spec
  $:  mode=run-mode
      invariants=(list @t)
      properties=(list @t)
      constraints=(list @t)
      action-constraints=(list @t)
      constants=(list cfg-const)
      overrides=(map @t @t)
      mod-overrides=(map @t (map @t @t))
      mod-constants=(map @t (list cfg-const))
      symmetry=(unit @t)
      view=(unit @t)
      alias=(unit @t)
      ::  R2.7.7.3: the POSTCONDITION names. On the run-spec because the engine
      ::  now ACTS on them -- evaluated after exploration -- and the kernel has
      ::  no other hand-off from the config to the render
      postconditions=(list @t)
      ::  R2.7.7.4b: `_POSSIBLE`'s names, for the same reason
      possible=(list @t)
      deadlock=?                         ::  getCheckDeadlock: true unless FALSE
  ==
::
++  kw-handled
  ::  the `.cfg` keywords the engine ACTS on (R2.7.7.1). Together with
  ::  `+kw-refused` this must cover `+keywords` exactly -- `tests/lib/cfg`
  ::  asserts it, which is the drift guard `gen-stdops-tests.py` gives the
  ::  operator surfaces and R2.7.7.0 found this side lacked. A new keyword
  ::  lands in one list or the other; it cannot land in neither and be
  ::  silently accepted, which is what POSTCONDITION did for two releases
  ^-  (set @t)
  %-  silt
  ^-  (list @t)
  :~  constant:k  constants:k  'CONSTRAINT'  'CONSTRAINTS'
      action-constraint:k  'ACTION_CONSTRAINTS'
      invariant:k  'INVARIANTS'  init:k  next:k  view:k  symmetry:k
      specification:k  property:k  'PROPERTIES'  'ALIAS'  'CHECK_DEADLOCK'
      ::  R2.7.7.3 evaluates these after exploration
      'POSTCONDITION'  'POSTCONDITIONS'
      ::  R2.7.7.4b tracks this one at the constraint positions
      '_POSSIBLE'
  ==
::
++  kw-refused
  ::  parsed, and REFUSED BY NAME rather than ignored (R2.7.7.1). Each is a
  ::  capability tlc2 has and this engine does not yet:
  ::
  ::  (POSTCONDITION left this list at R2.7.7.3, which evaluates it.)
  ::  (_POSSIBLE left this list at R2.7.7.4b, which tracks it.)
  ::    _PERIODIC         evaluated INSIDE the search loop; false ends the run
  ::                      with EC.TLC_ASSUMPTION_FALSE         -- R2.7.7.5
  ::    _RL_REWARD        only consumed by RLSimulationWorker, behind a JVM
  ::                      system property -- the capability is out of scope,
  ::                      but accepting the keyword silently is not
  ^-  (set @t)
  (silt ~['_PERIODIC' '_RL_REWARD'])
::
++  unsupported-kw
  ::  the typed rejection for a `.cfg` keyword this engine parses but does not
  ::  act on: it NAMES the keyword and what it would take, and never lets the
  ::  run proceed. R2's invariant, applied to `.cfg` keywords rather than to
  ::  `request` fields (R2.1 swept only the latter, which is how these four
  ::  survived). Checked in declaration order; `~` when the config is clean
  |=  a=cfg-ast
  ^-  (unit @t)
  ?^  periodic.a
    :-  ~
    %^  rap  3  'unsupported: _PERIODIC '
    :~  u.periodic.a
        '; tlc2 evaluates it inside the search loop and ENDS the run when it '
        'is false, which no completed run here could report'
    ==
  ?^  rlreward.a
    :-  ~
    %^  rap  3  'unsupported: _RL_REWARD '
    :~  u.rlreward.a
        '; its only consumer is the reinforcement-learning simulation worker, '
        'which this engine does not have'
    ==
  ~
::
++  sem-span
  ::  the source span of an IR expression node (nullodn has none)
  |=  s=sem:sem-lib
  ^-  (unit span)
  ?-  -.s
    %apply    at.s
    %letin    at.s
    %lit      at.s
    %atref    at.s
    %nullodn  ~
  ==
::
++  loc-str
  ::  render a span as Location.toString: "line L, col C to line L, col C
  ::  of module M" (or "Unknown location")
  |=  [modname=@t sp=(unit span)]
  ^-  @t
  ?~  sp  'Unknown location'
  =/  s  u.sp
  %+  rap  3
  :~  'line '  (num-cord line.from.s)  ', col '  (num-cord col.from.s)
      ' to line '  (num-cord line.to.s)  ', col '  (num-cord col.to.s)
      ' of module '  modname
  ==
::
++  v-noarg
  |=  [role=@t nm=@t]
  ^-  @t
  (rap 3 ~['TLC requires ' role ' not to take any argument, but one was given: ' nm])
::
++  v-notdef
  |=  [role=@t nm=@t]
  ^-  @t
  (rap 3 ~['The ' role ' ' nm ' specified in the configuration file\0ais not defined in the specification.'])
::
++  msg-2272
  |=  [nm=@t modname=@t bsp=(unit span)]
  ^-  @t
  =/  l  (loc-str modname bsp)
  %+  rap  3
  :~  'The formula '  nm  ' at '  l  ' is an action-level formula (i.e., it contains no temporal operators). '
      'Only temporal-level (or state-level) formulas are allowed under PROPERTY or PROPERTIES. '
      'To check that action '  nm  ' holds in *every* step of the behavior, define a temporal property: '
      'Let A be the formula at '  l  '; rewrite A as [][A]_v, where v is a state function (typically '
      'the tuple of variables) (compare page 90 of Specifying Systems at '
      'https://lamport.azurewebsites.net/tla/book.html).'
  ==
::
++  v-noarg-bare
  ::  the ONE-parameter TLC_CONFIG_ID_REQUIRES_NO_ARG variant, which
  ::  SPECIFICATION and PROPERTY use (SpecProcessor.java:799/823) where
  ::  INVARIANT/INIT/NEXT pass a role and take the two-parameter one
  |=  nm=@t
  ^-  @t
  (rap 3 ~['TLC requires ' nm ' not to take any argument.'])
::
++  render-oprcd
  ::  OpRcdValue.toString (OpRcdValue.java:247): `{ ` then the lines in
  ::  addLine order, each `<a1, a2, val>` -- every argument followed by
  ::  `, `, then the value -- separated by `, `, then `}` with no space
  ::  before it. An empty record is `{ }`. addLine appends and never
  ::  dedups, so the config's line order IS the rendering order. R1.8.2
  |=  ls=(list cfg-const)
  ^-  @t
  =/  out=tape  (trip '{ ')
  =/  cs  ls
  =/  first=?  &
  |-  ^-  @t
  ?~  cs  (crip (weld out (trip '}')))
  =.  out  ?:(first out (weld out ", "))
  =.  out  (weld out "<")
  =.  out
    =/  as  args.i.cs
    |-  ^-  tape
    ?~  as  out
    $(as t.as, out :(weld out (render-value i.as) ", "))
  =.  out  :(weld out (render-value val.i.cs) ">")
  $(cs t.cs, first |)
::
++  msg-2230
  ::  TLC_CONFIG_ID_HAS_VALUE: the third parameter is the VALUE's
  ::  toString, which +render-value renders exactly for every shape
  ::  parseValue produces, and +render-oprcd for an operator record
  ::  (`F(a) = v`) -- the shape makeConstantTable builds. R1.8.2
  |=  [role=@t nm=@t e=dentry]
  ^-  @t
  =/  rv=@t
    ?:  ?=(%val -.e)  (crip (render-value v.e))
    ?:  ?=(%opr -.e)  (render-oprcd lines.e)
    '<value>'
  (rap 3 ~['The ' role ' of ' nm ' is equal to ' rv])
::
++  ck-action
  ::  INIT/NEXT (processConfigInitAndNext): unresolved -> 2229; resolved
  ::  to a value rather than an operator -> 2233; def arity>0 -> 2228
  |=  [dm=(map @t dentry) role=@t nm=@t]
  ^-  (unit cfg-vdiag)
  =/  e  (~(get by dm) nm)
  ?~  e  `[2.229 (v-notdef role nm)]
  ?:  ?=(%none -.u.e)  `[2.229 (v-notdef role nm)]
  ?.  ?=(%def -.u.e)
    `[2.233 (rap 3 ~['The ' role ' ' nm ' cannot be a constant.'])]
  ?:  (gth arity.d.u.e 0)  `[2.228 (v-noarg role nm)]
  ~
::
++  ck-snapshot-def
  ::  the name check for `_PERIODIC` / `_RL_REWARD` / `_POSSIBLE`
  ::  (R2.7.7.2). Same two rejections as `+ck-action` — 2229 when the name
  ::  resolves to nothing, 2228 when the definition takes arguments — and
  ::  deliberately NOT 2233.
  ::
  ::  `processRLReward`/`processPeriodic`/`processConfigPossible` look the name
  ::  up in SpecProcessor's SNAPSHOT rather than in `defns`, precisely because
  ::  "any constant expression in defns will have been evaluated into a Value"
  ::  — so a constant-valued definition stays an OpDefNode and is ACCEPTED.
  ::  Measured: `_RL_REWARD Konst` with `Konst == 1 = 1` runs to a normal
  ::  verdict at the pin, where an INIT/NEXT-style check calls it a constant.
  ::  `processRLReward` does carry a must-not-be-constant branch, and the
  ::  snapshot lookup makes it unreachable; its own TODO says the message
  ::  would be bogus anyway
  |=  [dm=(map @t dentry) role=@t nm=@t]
  ^-  (unit cfg-vdiag)
  =/  e  (~(get by dm) nm)
  ?~  e  `[2.229 (v-notdef role nm)]
  ?:  ?=(%none -.u.e)  `[2.229 (v-notdef role nm)]
  ?.  ?=(%def -.u.e)  ~
  ?:  (gth arity.d.u.e 0)  `[2.228 (v-noarg role nm)]
  ~
::
++  ck-keyword-names
  ::  the `.cfg` keywords whose NAMES the pin resolves at spec processing,
  ::  before a single state is computed (`SpecProcessor` lines 944-948, in
  ::  this order). Shared by both paths, because the console never calls
  ::  `+validate-config` at all and a caller there would otherwise see the
  ::  R2.7.7.1 refusal for a config the pin rejects with its own diagnostic.
  ::
  ::  POSTCONDITION is NOT here, and that is measured rather than an omission:
  ::  its names resolve in `Spec.getPostConditionSpecs`, which runs after
  ::  exploration — the pin prints the state counts FIRST and only then fails
  ::  (R2.7.7.0's `cfg-post-undef`). An early check could not reproduce that,
  ::  so it belongs with the evaluation in R2.7.7.3
  |=  [m=sem-module:sem-lib a=cfg-ast]
  ^-  (unit cfg-vdiag)
  =/  bd  (build-defns m a)
  ?:  ?=(%| -.bd)  ~
  =/  dm  p.bd
  ::  in `SpecProcessor`'s order: rlreward, periodic, then _POSSIBLE
  =/  rl  ?~(rlreward.a ~ (ck-snapshot-def dm 'rlreward' u.rlreward.a))
  ?^  rl  rl
  =/  pe  ?~(periodic.a ~ (ck-snapshot-def dm 'periodic' u.periodic.a))
  ?^  pe  pe
  =/  ps  possible.a
  |-  ^-  (unit cfg-vdiag)
  ?~  ps  ~
  =/  r  (ck-snapshot-def dm 'possible' i.ps)
  ?^  r  r
  ::  R2.7.7.4b: `_POSSIBLE` alone rejects a TEMPORAL-level predicate.
  ::  `processConfigPossible` guards `level >= TemporalLevel` with EC 2230 and
  ::  the message below, measured verbatim (tlaplus#827): `_Track` wraps the
  ::  predicate into a CONSTRAINT, which a temporal formula cannot be
  =/  de  (~(get by dm) i.ps)
  ?:  ?&(?=(^ de) ?=(%def -.u.de) (gth lvl.d.u.de 2))
    :-  ~
    :-  2.230
    %+  rap  3
    :~  'The possible of '  i.ps  ' is equal to a temporal formula; '
        'only state- and action-level predicates are supported'
    ==
  $(ps t.ps)
::
++  ck-formula
  ::  INVARIANT/PROPERTY/SPECIFICATION resolution: unresolved -> 2229;
  ::  def arity>0 -> 2228 (bare = the one-parameter message); a
  ::  config-assigned value -> 2230, EXCEPT the boolean TRUE, which tlc2
  ::  accepts (warning 2149 for an invariant, silently for a property).
  ::  Returns the resolved def for the caller's level dispatch, or ~ when
  ::  an accepted TRUE ends the story for that name.
  |=  [dm=(map @t dentry) role=@t bare=? nm=@t]
  ^-  (each (unit sem-def:sem-lib) cfg-vdiag)
  =/  e  (~(get by dm) nm)
  ?~  e  [%| 2.229 (v-notdef role nm)]
  ?:  ?=(%none -.u.e)  [%| 2.229 (v-notdef role nm)]
  ?:  ?=(%def -.u.e)
    ?.  (gth arity.d.u.e 0)  [%& `d.u.e]
    [%| 2.228 ?:(bare (v-noarg-bare nm) (v-noarg role nm))]
  ?.  ?=(%val -.u.e)  [%| 2.230 (msg-2230 role nm u.e)]
  ?.  ?=(%bool -.v.u.e)  [%| 2.230 (msg-2230 role nm u.e)]
  ?.  p.v.u.e  [%| 2.230 (msg-2230 role nm u.e)]
  [%& ~]
::
++  const-table
  ::  makeConstantTable (SpecProcessor.java:2361): a CONSTANT line with no
  ::  argument list stores its value directly (later lines overwrite);
  ::  argument lines accumulate into an operator record whose arity the
  ::  FIRST line fixes -- a later line of a different arity is EC 2242.
  ::  (tlc2 throws a raw ClassCastException, not a diagnostic, when the two
  ::  forms are mixed under one name; the port keeps the record form.)
  |=  cs=(list cfg-const)
  ^-  (each (map @t dentry) cfg-vdiag)
  =|  t=(map @t dentry)
  |-  ^-  (each (map @t dentry) cfg-vdiag)
  ?~  cs  [%& t]
  ?~  args.i.cs
    $(cs t.cs, t (~(put by t) lhs.i.cs [%val val.i.cs]))
  =/  ar  (lent args.i.cs)
  =/  ex  (~(get by t) lhs.i.cs)
  ?~  ex
    $(cs t.cs, t (~(put by t) lhs.i.cs [%opr ar ~[i.cs]]))
  ?.  ?=(%opr -.u.ex)
    $(cs t.cs, t (~(put by t) lhs.i.cs [%opr ar ~[i.cs]]))
  ?.  =(ary.u.ex ar)
    :+  %|  2.242
    %+  rap  3
    ~['The arity of the operator ' lhs.i.cs ' is inconsistent in the configuration file.']
  $(cs t.cs, t (~(put by t) lhs.i.cs [%opr ary.u.ex (snoc lines.u.ex i.cs)]))
::
++  msg-2223
  |=  nm=@t
  ^-  @t
  %+  rap  3
  :~  'In the configuration file, the identifier '  nm  ' appears\0a'
      'on the right-hand side of a <- after already appearing on the\0a'
      'left-hand side of one.'
  ==
::
++  msg-2224
  |=  [lhs=@t rhs=@t]
  ^-  @t
  %+  rap  3
  :~  'The configuration file substitutes for '  lhs
      ' with the undefined identifier '  rhs  '.'
  ==
::
++  msg-2225
  |=  [lhs=@t rhs=@t]
  ^-  @t
  %+  rap  3
  :~  'The configuration file substitutes for '  lhs
      ' with '  rhs  ' of different number of arguments.'
  ==
::
++  msg-2226
  |=  nm=@t
  ^-  @t
  %+  rap  3
  :~  'In the configuration file, the identifier '  nm
      ' does not appear in the specification.'
  ==
::
++  build-defns
  ::  SpecProcessor.processSpec's constant/override machinery, in its own
  ::  order, up to the point processConfig takes over: the constant table
  ::  (2242), the declared constants (2222), the module's operator
  ::  definitions, the `<-` substitutions (2223/2224/2225/2226), and
  ::  processConstantDefns' checks on a constant substituted by an operator
  ::  (2225/2281). Fail-fast throughout, like the Java. R1.8.1.3b
  ::
  ::  R1.8.2 added the per-module `mod!lhs <- rhs` half (+mod-subst):
  ::  the same 2223/2224/2225/2226 loop over each module's own
  ::  getOpDefs(), plus TLC_NO_MODULES (2245) for a config module name the
  ::  spec does not define. It reads `modops.m`, which the graph now
  ::  carries for every module.
  |=  [m=sem-module:sem-lib a=cfg-ast]
  ^-  (each (map @t dentry) cfg-vdiag)
  |^  go
  ::  ModuleNode.getOpDefs order: EXTENDS-imported definitions first, so
  ::  the module's own shadow an imported name
  ++  odefs  `(list sem-def:sem-lib)`(weld imports.m defs.m)
  ++  go
    ^-  (each (map @t dentry) cfg-vdiag)
    =/  ct  (const-table constants.a)
    ?:  ?=(%| -.ct)  [%| p.ct]
    =/  base=(map @t dentry)
      =|  acc=(map @t dentry)
      =/  dl  odefs
      |-  ^-  (map @t dentry)
      ?~  dl  acc
      $(dl t.dl, acc (~(put by acc) name.i.dl [%def i.dl]))
    ::  the declared CONSTANTs: assigned by the config, else covered by an
    ::  override (and still null in the table until it applies), else 2222
    =/  r1  (put-consts p.ct base)
    ?:  ?=(%| -.r1)  [%| p.r1]
    ::  a config value for a DEFINED operator replaces the definition
    =/  dm
      =/  acc  p.r1
      =/  dl  odefs
      |-  ^-  (map @t dentry)
      ?~  dl  acc
      =/  v  (~(get by p.ct) name.i.dl)
      $(dl t.dl, acc ?~(v acc (~(put by acc) name.i.dl u.v)))
    ::  the per-module constant tables are built (hence arity-checked) here
    =/  r2  (mod-tables ~(val by mod-constants.a))
    ?^  r2  [%| u.r2]
    =/  r3  (subst dm)
    ?:  ?=(%| -.r3)  [%| p.r3]
    =/  r4  unused-overrides
    ?^  r4  [%| u.r4]
    ::  the per-module override tables, then the module-name check --
    ::  SpecProcessor.java:711-770, in that order
    =/  r5  (mod-subst p.r3)
    ?^  r5  [%| u.r5]
    =/  r6  unknown-modules
    ?^  r6  [%| u.r6]
    =/  r7  (const-defns p.r3)
    ?^  r7  [%| u.r7]
    [%& p.r3]
  ::  2222, in declaration order
  ++  put-consts
    |=  [ct=(map @t dentry) acc=(map @t dentry)]
    ^-  (each (map @t dentry) cfg-vdiag)
    =/  cl  consts.m
    |-  ^-  (each (map @t dentry) cfg-vdiag)
    ?~  cl  [%& acc]
    =/  v  (~(get by ct) name.i.cl)
    ?:  ?&(?=(~ v) !(~(has by overrides.a) name.i.cl))
      :+  %|  2.222
      %+  rap  3
      ~['The constant parameter ' name.i.cl ' is not assigned a value by the configuration file.']
    $(cl t.cl, acc (~(put by acc) name.i.cl ?~(v [%none ~] u.v)))
  ::  initializeModConstants: only its arity check (2242) is observable
  ::  here, the tables themselves belong with the deferred module overrides
  ++  mod-tables
    |=  ls=(list (list cfg-const))
    ^-  (unit cfg-vdiag)
    ?~  ls  ~
    =/  r  (const-table i.ls)
    ?:  ?=(%| -.r)  `p.r
    $(ls t.ls)
  ::  the `<-` substitutions: declared constants first, then operator
  ::  definitions, each in the module's own order
  ++  subst
    |=  dm=(map @t dentry)
    ^-  (each (map @t dentry) cfg-vdiag)
    =/  ns
      %+  weld
        (turn consts.m |=([name=@t arity=@ud at=*] [nm=name ar=arity ic=&]))
      (turn odefs |=(d=sem-def:sem-lib [nm=name.d ar=arity.d ic=|]))
    =/  acc  dm
    |-  ^-  (each (map @t dentry) cfg-vdiag)
    ?~  ns  [%& acc]
    =/  rhs  (~(get by overrides.a) nm.i.ns)
    ?~  rhs  $(ns t.ns)
    ?:  (~(has by overrides.a) u.rhs)  [%| 2.223 (msg-2223 u.rhs)]
    =/  my  (~(get by acc) u.rhs)
    ?~  my  [%| 2.224 (msg-2224 nm.i.ns u.rhs)]
    ?:  ?=(%none -.u.my)  [%| 2.224 (msg-2224 nm.i.ns u.rhs)]
    ::  the declared-constant loop does NOT compare arities here; that
    ::  check waits for processConstantDefns (+const-defns)
    =/  bad=?
      ?:  ic.i.ns  |
      ?.  ?=(%def -.u.my)  |
      !=(ar.i.ns arity.d.u.my)
    ?:  bad  [%| 2.225 (msg-2225 nm.i.ns u.rhs)]
    $(ns t.ns, acc (~(put by acc) nm.i.ns u.my))
  ::  2226: an override whose left-hand side names nothing in the spec
  ++  unused-overrides
    ^-  (unit cfg-vdiag)
    =/  known=(set @t)
      %-  sy
      %+  weld  (turn consts.m |=([name=@t arity=@ud at=*] name))
      (turn odefs |=(d=sem-def:sem-lib name.d))
    =/  ks  (sort ~(tap in ~(key by overrides.a)) aor)
    |-  ^-  (unit cfg-vdiag)
    ?~  ks  ~
    ?:  (~(has in known) i.ks)  $(ks t.ks)
    `[2.226 (msg-2226 i.ks)]
  ::  the per-module `mod!lhs <- rhs` tables (SpecProcessor.java:711-760).
  ::  Structurally the root loop with three differences the Java makes
  ::  explicit: the 2223 self-reference test is against THIS MODULE'S table,
  ::  not the root's; the rhs is still resolved in the ROOT defns table
  ::  ("The rhs comes from the root module"); and the arity check (2225)
  ::  fires here for every operator, where the root loop defers a declared
  ::  constant's to processConstantDefns. A substitution applies to the
  ::  module's own definition, so nothing is written back to the root table.
  ::  Modules are visited in the graph's dependency-first order and each
  ::  module's operators in getOpDefs() order; the 2226 sweep over a
  ::  module's own keys is sorted, as the root sweep is -- both stand in
  ::  for a java.util.Hashtable enumeration (compatibility.md). R1.8.2
  ++  mod-subst
    |=  dm=(map @t dentry)
    ^-  (unit cfg-vdiag)
    =/  ms  (sort ~(tap in ~(key by mod-overrides.a)) aor)
    |-  ^-  (unit cfg-vdiag)
    ?~  ms  ~
    =/  ops  (~(get by modops.m) i.ms)
    ::  a module the spec does not define is 2245, checked after this loop
    ?~  ops  $(ms t.ms)
    =/  tbl  (~(gut by mod-overrides.a) i.ms ~)
    =/  r  (one-module tbl u.ops dm)
    ?^  r  r
    $(ms t.ms)
  ::  one module's table against its own operator list
  ++  one-module
    |=  [tbl=(map @t @t) ops=(list [name=@t arity=@ud]) dm=(map @t dentry)]
    ^-  (unit cfg-vdiag)
    =|  done=(set @t)
    =/  os  ops
    |-  ^-  (unit cfg-vdiag)
    ?^  os
      =/  rhs  (~(get by tbl) name.i.os)
      ?~  rhs  $(os t.os)
      ?:  (~(has by tbl) u.rhs)  `[2.223 (msg-2223 u.rhs)]
      =/  my  (~(get by dm) u.rhs)
      ?~  my  `[2.224 (msg-2224 name.i.os u.rhs)]
      ?:  ?=(%none -.u.my)  `[2.224 (msg-2224 name.i.os u.rhs)]
      ?:  ?&(?=(%def -.u.my) !=(arity.i.os arity.d.u.my))
        `[2.225 (msg-2225 name.i.os u.rhs)]
      $(os t.os, done (~(put in done) name.i.os))
    ::  2226 over this module's own keys
    =/  ks  (sort ~(tap in ~(key by tbl)) aor)
    |-  ^-  (unit cfg-vdiag)
    ?~  ks  ~
    ?:  (~(has in done) i.ks)  $(ks t.ks)
    `[2.226 (msg-2226 i.ks)]
  ::  TLC_NO_MODULES (2245): a config `MODULE M` naming no module of the
  ::  specification. Checked after every per-module table has been applied,
  ::  as the Java does (SpecProcessor.java:763-770)
  ++  unknown-modules
    ^-  (unit cfg-vdiag)
    =/  ms  (sort ~(tap in ~(key by mod-overrides.a)) aor)
    |-  ^-  (unit cfg-vdiag)
    ?~  ms  ~
    ?:  (~(has by modops.m) i.ms)  $(ms t.ms)
    :-  ~
    :-  2.245
    %+  rap  3
    :~  'In the configuration file, the module name '  i.ms
        ' is not a module in the specification.'
    ==
  ::  processConstantDefns: a declared CONSTANT substituted by an operator
  ::  must have that operator's arity (2225) and, at arity 0, must be
  ::  constant-level (2281). tlc2 reaches 2281 by EVALUATING the body and,
  ::  when that throws, checking the body's level bound; the port takes the
  ::  level first and then names the offending reference (+nonconst-ref)
  ++  const-defns
    |=  dm=(map @t dentry)
    ^-  (unit cfg-vdiag)
    =/  cl  consts.m
    |-  ^-  (unit cfg-vdiag)
    ?~  cl  ~
    =/  e  (~(get by dm) name.i.cl)
    ?~  e  $(cl t.cl)
    ?.  ?=(%def -.u.e)  $(cl t.cl)
    ?.  =(arity.d.u.e arity.i.cl)
      `[2.225 (msg-2225 name.i.cl name.d.u.e)]
    ?.  =(0 arity.d.u.e)  $(cl t.cl)
    ?:  =(0 lvl.d.u.e)  $(cl t.cl)
    `[2.281 (msg-2281 name.m name.i.cl d.u.e dm)]
  --
::
++  msg-2281
  ::  TLC_CONFIG_SUBSTITUTION_NON_CONSTANT. Its third parameter is the
  ::  message of the exception constant evaluation threw, prefixed with
  ::  " - specifically: " (empty only for an EvalException). Measured at the
  ::  pin, the throw is EC 2280 TLC_CONFIG_UNDEFINED_OR_NO_OPERATOR on the
  ::  first state variable the body reads, so the port names that reference
  ::  and its location.
  ::  A body that is non-constant because it is TEMPORAL throws EC 2261
  ::  (TLC_ENCOUNTERED_FORMULA_IN_PREDICATE, Tool.java:2808-2846) instead,
  ::  and its addendum carries that message. Measured at the pin: the
  ::  message's second parameter is `expr.toString()`, and
  ::  SemanticNode.toString returns `getLocation().toString()` unless the
  ::  `showPlainFormulae` system property is set -- so it is the LOCATION,
  ::  not an expression rendering, and +loc-str already produces it. R1.8.2
  |=  [modname=@t nm=@t d=sem-def:sem-lib dm=(map @t dentry)]
  ^-  @t
  =/  add=@t
    ?~  body.d  ''
    =/  r  (nonconst-ref u.body.d dm modname | (silt ~[name.d]))
    ?~  r  ''
    ?:  ?=(%temporal -.u.r)
      %+  rap  3
      :~  ' - specifically: TLC encountered a temporal formula ('  op.u.r
          ') when evaluating a predicate or action.\0a'
          (loc-str mod.u.r at.u.r)
      ==
    %+  rap  3
    :~  ' - specifically: In evaluation, the identifier '  name.u.r
        ' is either undefined or not an operator.\0a'
        (loc-str mod.u.r at.u.r)
    ==
  %+  rap  3
  :~  'The configuration file substitutes constant '  nm
      ' with non-constant '  name.d  add
  ==
::
::  what constant evaluation of a substituting body trips over first
+$  ncref
  $%  ::  a state-variable reference -> EC 2280 in the 2281 addendum
      [%ident name=@t mod=@t at=(unit span)]
      ::  a temporal operator -> EC 2261 there instead, `op` being the
      ::  label Tool.java passes as that message's first parameter
      [%temporal op=@t mod=@t at=(unit span)]
  ==
::
++  temporal-label
  ::  the eight OPCODEs Tool.evalImpl answers with
  ::  TLC_ENCOUNTERED_FORMULA_IN_PREDICATE, and the literal each passes as
  ::  the message's first parameter (Tool.java:2808-2846)
  |=  nm=@t
  ^-  (unit @t)
  (~(get by (malt temporal-labels)) nm)
::
++  temporal-labels
  ^-  (list [@t @t])
  :~  ['[]' '[]A']
      ['<>' '<>A']
      ['$WF' 'WF']
      ['$SF' 'SF']
      ['$TemporalExists' '\\EE']
      ['$TemporalForall' '\\AA']
      ['~>' 'a ~> b']
      ['-+->' 'a -+-> formula']
  ==
::
++  nonconst-ref
  ::  the first thing constant evaluation trips over, in evaluation
  ::  (pre-)order -- a bound range before the body it binds -- descending
  ::  into an applied user operator as tlc2's evaluator does. Two shapes
  ::  end the walk: a state-variable reference (EC 2280) and a temporal
  ::  operator (EC 2261). Tool.evalImpl switches on the node's OPCODE
  ::  BEFORE evaluating its arguments, so a temporal node fails without
  ::  descending -- `C <- []P` names the box, never P's contents.
  ::  Under ENABLED a PRIMED variable is assignable, so it is not the
  ::  failure; that asymmetry is measured against the pin.
  |=  $:  s=sem:sem-lib
          dm=(map @t dentry)
          mod=@t
          enabled=?
          seen=(set @t)
      ==
  ^-  (unit ncref)
  =|  primed=?
  |-  ^-  (unit ncref)
  ?:  ?=(%letin -.s)
    ?~(body.s ~ $(s u.body.s))
  ?.  ?=(%apply -.s)  ~
  =/  nm  name.op.s
  ?:  ?=(%variable kind.op.s)
    ?:  ?&(enabled primed)  ~
    `[%ident nm mod at.s]
  =/  tl  (temporal-label nm)
  ?^  tl  `[%temporal u.tl mod at.s]
  =/  en  |(enabled =('ENABLED' nm))
  =/  pr  |(primed =('\'' nm))
  =/  rs=(list sem:sem-lib)
    %+  murn  bound.s
    |=(b=sem-bound:sem-lib range.b)
  =/  kids=(list sem:sem-lib)  (weld rs args.s)
  =/  here
    |-  ^-  (unit ncref)
    ?~  kids  ~
    =/  r  ^$(s i.kids, enabled en, primed pr)
    ?^(r r $(kids t.kids))
  ?^  here  here
  ::  an applied user operator: evaluation enters its body
  ?:  (~(has in seen) nm)  ~
  =/  e  (~(get by dm) nm)
  ?~  e  ~
  ?.  ?=(%def -.u.e)  ~
  ?~  body.d.u.e  ~
  %=  $
    s        u.body.d.u.e
    mod      ?:(=('' origin.d.u.e) mod origin.d.u.e)
    enabled  en
    seen     (~(put in seen) nm)
  ==
::
++  validate-config
  ::  processConfig (SpecProcessor.java:777) over the `defns` table
  ::  +build-defns assembled, in the Java's order: invariants, then
  ::  SPECIFICATION xor INIT/NEXT, then properties, then the two
  ::  missing-predicate checks. Fail-fast: the first violation is the
  ::  only diagnostic, exactly as processConfig throws.
  |=  [m=sem-module:sem-lib a=cfg-ast]
  ^-  (each ~ cfg-vdiag)
  =/  modname  name.m
  =/  bd  (build-defns m a)
  ?:  ?=(%| -.bd)  [%| p.bd]
  =/  dm  p.bd
  |^  result
  ++  result
    ^-  (each ~ cfg-vdiag)
    =/  e
      ;:  first
        chk-invariants  chk-spec-init-next
        chk-properties  chk-missing-init  chk-missing-next
        chk-view
        ::  R2.7.7.2: LAST, matching `SpecProcessor`'s own order —
        ::  processConfig first, then the constraints, then rlreward,
        ::  periodic and _POSSIBLE (lines 944-948)
        (ck-keyword-names m a)
      ==
    ?~  e  [%& ~]
    [%| u.e]
  ::  first non-~ of a chain of checks
  ++  first
    |=  [a=(unit cfg-vdiag) b=(unit cfg-vdiag)]
    ^-  (unit cfg-vdiag)
    ?^(a a b)
  ::  invariants: resolution, then the state-predicate level check (2146)
  ++  chk-invariants
    ^-  (unit cfg-vdiag)
    =/  il  invariants.a
    |-  ^-  (unit cfg-vdiag)
    ?~  il  ~
    =/  r  (ck-formula dm 'invariant' | i.il)
    ?:  ?=(%| -.r)  `p.r
    =/  d  p.r
    ?~  d  $(il t.il)
    ?.  (gte lvl.u.d 2)  $(il t.il)
    `[2.146 (msg-2146 u.d)]
  ::  2146: an INVARIANT must be a state predicate. The two message
  ::  variants are selected by the definition's levelParams EMPTINESS, not
  ::  by its level (SpecProcessor.java:1021): `x' = x` keeps its parameter
  ::  and takes the LevelNode-bug note, while `UNCHANGED x` (also level 2)
  ::  has weight 0, empties them, and takes the plain sentence
  ++  msg-2146
    |=  d=sem-def:sem-lib
    ^-  @t
    =/  plain
      (rap 3 ~['The invariant ' name.d ' is not a state predicate (one with no primes or temporal operators).'])
    ?:  (~(gut by lpe.m) name.d &)  plain
    %+  rap  3
    :~  plain  '\0aNote that a bug can cause TLC to incorrectly report this error.\0a'
        'If you believe your TLA+ or PlusCal specification to be correct,\0a'
        'please check if this bug described in LevelNode.java starting at line 590ff affects you.'
    ==
  ::  SPECIFICATION xor INIT/NEXT, and their resolution
  ++  chk-spec-init-next
    ^-  (unit cfg-vdiag)
    ?^  spec.a
      ?:  |(?=(^ init.a) ?=(^ next.a))
        `[2.227 'The configuration file cannot specify both INIT/NEXT and SPECIFICATION fields.']
      =/  r  (ck-formula dm 'value' & u.spec.a)
      ?:  ?=(%| -.r)
        ::  the SPECIFICATION not-defined role is `name`, not `value`
        ?.  =(2.229 code.p.r)  `p.r
        `[2.229 (v-notdef 'name' u.spec.a)]
      ~
    ::  no SPECIFICATION: resolve INIT then NEXT
    =/  ei  ?~(init.a ~ (ck-action dm 'initial predicate' u.init.a))
    ?^  ei  ei
    ?~(next.a ~ (ck-action dm 'next state action' u.next.a))
  ::  properties: resolution + action-level (2272)
  ++  chk-properties
    ^-  (unit cfg-vdiag)
    =/  pl  properties.a
    |-  ^-  (unit cfg-vdiag)
    ?~  pl  ~
    =/  r  (ck-formula dm 'property' & i.pl)
    ?:  ?=(%| -.r)  `p.r
    =/  d  p.r
    ?~  d  $(pl t.pl)
    ?.  =(2 lvl.u.d)  $(pl t.pl)
    =/  bsp  ?~(body.u.d ~ (sem-span u.body.u.d))
    `[2.272 (msg-2272 i.pl modname bsp)]
  ::  2231: no init established while the model needs one
  ++  chk-missing-init
    ^-  (unit cfg-vdiag)
    =/  established  |(?=(^ init.a) ?=(^ spec.a))
    ?:  established  ~
    ?.  |(?=(^ vars.m) ?=(^ invariants.a) ?=(^ properties.a))  ~
    `[2.231 'The configuration file did not specify the initial state predicate.']
  ::  VIEW resolves in `Spec.getViewSpec` (Spec.java:243), which runs with the
  ::  rest of spec construction -- hence last here, after every processConfig
  ::  check. It takes the same three codes the INIT/NEXT resolution does (2229
  ::  not defined, 2233 a constant, 2228 takes an argument) with the role string
  ::  `view function`.
  ::  ALIAS is deliberately NOT checked here. `getAliasSpec` runs only when a
  ::  trace is printed, so an undefined ALIAS is `ok` at config time -- measured
  ::  against the pin (`val-alias-undef`), which is why that case asserts `ok`
  ::  and guards against "symmetric" over-validation. R1.8.6
  ++  chk-view
    ^-  (unit cfg-vdiag)
    ?~(view.a ~ (ck-action dm 'view function' u.view.a))
  ::  2232: no next established while invariants/actions need one
  ++  chk-missing-next
    ^-  (unit cfg-vdiag)
    =/  established  |(?=(^ next.a) ?=(^ spec.a))
    ?:  established  ~
    ?.  ?=(^ invariants.a)  ~
    `[2.232 'The configuration file did not specify the next state predicate.']
  --
::
++  dump-validate
  ::  render the ConfigValidate projection for a spec + .cfg text
  |=  [root=@t src=(map @t @t) cfg=@t]
  ^-  @t
  =/  mo  (generate:sem-lib root src)
  ?~  mo  'VALIDATE\0aTHROW NoModule\0a'
  =/  pr  (parse-cfg cfg)
  ?:  ?=(%| -.pr)
    (rap 3 ~['VALIDATE\0aCFGPARSE\0a' msg.p.pr '\0a'])
  =/  r  (validate-config u.mo p.pr)
  ?-  -.r
    %&  'VALIDATE\0aok\0a'
    %|  (rap 3 ~['VALIDATE\0a' (num-cord code.p.r) ' ~\0a' msg.p.r '\0a'])
  ==
::
::  +|  Run-Spec Assembly (unit 5.4)
::
++  assemble-run-spec
  ::  validate the config against the graph, then assemble the typed
  ::  run-spec (mode selection + validated sections). Rejections are the
  ::  same TLC_CONFIG diagnostics as validate-config. The property/
  ::  fairness gates (2257/2259) and trivial-spec (2237) ride in with the
  ::  deep processConfigSpec unfold (5.3c residue).
  |=  [m=sem-module:sem-lib a=cfg-ast]
  ^-  (each run-spec cfg-vdiag)
  =/  v  (validate-config m a)
  ?:  ?=(%| -.v)  v
  :-  %&
  ^-  run-spec
  :*  mode=?^(spec.a [%spec u.spec.a] [%init-next init.a next.a])
      invariants=invariants.a
      properties=properties.a
      constraints=constraints.a
      action-constraints=action-constraints.a
      constants=constants.a
      overrides=overrides.a
      mod-overrides=mod-overrides.a
      mod-constants=mod-constants.a
      symmetry=symmetry.a
      view=view.a
      alias=alias.a
      postconditions=postconditions.a
      possible=possible.a
      deadlock=!=(%false deadlock.a)
  ==
::
++  run-spec-of
  ::  convenience: from a root name + module sources + cfg text to the
  ::  typed run-spec (or the first config diagnostic)
  |=  [root=@t src=(map @t @t) cfg=@t]
  ^-  (each run-spec cfg-vdiag)
  =/  mo  (generate:sem-lib root src)
  ?~  mo  [%| 0 'internal: module generation failed']
  (run-spec-with u.mo cfg)
::
++  run-spec-with
  ::  the same, over a semantic graph the caller already generated, so a
  ::  pipeline that needs both does not build (and reparse) it twice
  |=  [mo=sem-module:sem-lib cfg=@t]
  ^-  (each run-spec cfg-vdiag)
  =/  pr  (parse-cfg cfg)
  ?:  ?=(%| -.pr)  [%| code.p.pr msg.p.pr]
  (assemble-run-spec mo p.pr)
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
