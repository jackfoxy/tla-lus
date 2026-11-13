::  R4.4 (clause 8), a ship-side dojo generator: the structural identity of
::  a %tla-ex module and its tlauc conversion. Copy it to the %tla-lus
::  mount's gen/ and run, for `specifications/Paxos/Voting.tla`,
::
::    +tla-lus!sem-identity 'Voting' /specifications/paxos
::
::  Both texts go through +dump-sem's pipeline (the SemDump projection of
::  the semantic graph, levels included), the ASCII original from <sdir>
::  and the conversion from /unicode/<sdir>, each with %tla-ex's library
::  roots after it, as the agent orders them. tlauc keeps every line but
::  changes a symbol's width, so every span's columns are elided before the
::  two dumps are compared; lines are kept. The verdicts are
::  +sany-verdict's rule (no %error from the semantic or level phase).
::  Prints one line: verdicts, line counts, identity, first difference.
::
/-  *tla-lus
/+  modules, semantic
:-  %say
|=  [[now=@da eny=@uvJ bek=beak] [root=@t sdir=path ~] ~]
:-  %noun
^-  @t
=/  bx=path  /(scot %p p.bek)/tla-ex/(scot %da now)
=/  span-cols
  %+  cook  |=([a=@ud * * * b=@ud * *] [a b])
  ;~(plug dem dot dem hep dem dot dem)
=/  elide
  ::  `3.16-3.20` becomes `3-3`; every other token stays
  |=  l=@t
  ^-  @t
  =/  t=tape  (trip l)
  =|  cur=tape
  =|  out=tape
  |-  ^-  @t
  ?:  |(?=(~ t) =(' ' i.t))
    =/  k=tape  (flop cur)
    =/  p  (rust k span-cols)
    =/  w=tape  ?~(p k "{(a-co:co -.u.p)}-{(a-co:co +.u.p)}")
    =.  out  (weld (flop w) out)
    ?~  t  (crip (flop out))
    $(t t.t, cur ~, out [' ' out])
  $(t t.t, cur [i.t cur])
=/  dump
  |=  dir=path
  ^-  [ok=? lines=wain]
  =/  roots=(list path)  ~[dir /apalache /community /tlapm]
  =/  res=resolver
    |=  name=@t
    ^-  (unit source-text)
    =/  f=@ta  (crip (cass (trip name)))
    =/  rs  roots
    |-  ^-  (unit source-text)
    ?~  rs  ~
    =/  p=path  :(weld bx i.rs /[f]/tla)
    ?.  .^(? %cu p)  $(rs t.rs)
    `[[%inline name] .^(@t %cx p)]
  =/  r  (resolve:modules root res ~)
  ?:  ?=(%| -.out.r)  [| ~['REJECT']]
  =/  g  p.out.r
  =/  ctxs  (analyze:semantic sem-order.g mods.g deps.g)
  =/  rt  (~(get by mods.g) root)
  ?~  rt  [| ~['REJECT']]
  =/  fc  (full-ctx:semantic tree.u.rt ctxs)
  =/  dv  (l-deps:semantic root sem-order.g ctxs mods.g)
  =/  lr
    %:  l-module-core:semantic
      (gen-module:semantic tree.u.rt fc ctxs mods.g)
      fc
      ctxs
      mods.g
      dv
    ==
  =/  err
    |=(ds=(list sdiag:semantic) (lien ds |=(d=sdiag:semantic =(%error sev.d))))
  :-  ?!(|((err sem.phase.lr) (err lvl.phase.lr)))
  %+  turn
    ;:(weld ['ACCEPT' ~] (render-module:semantic m.lr) ['LEVELS' lvls.lr])
  elide
=/  a  (dump sdir)
=/  u  (dump (weld /unicode sdir))
=/  verdict  |=(ok=? ?:(ok "accept" "reject"))
=/  diff=tape
  =/  x  lines.a
  =/  y  lines.u
  |-  ^-  tape
  ?~  x  ?~(y "" " only-u={(trip i.y)}")
  ?~  y  " only-a={(trip i.x)}"
  ?.  =(i.x i.y)  " a={(trip i.x)} | u={(trip i.y)}"
  $(x t.x, y t.y)
%-  crip
;:  weld
  "sem-identity {(trip root)}"
  " a={(verdict ok.a)} u={(verdict ok.u)}"
  " n={(a-co:co (lent lines.a))}/{(a-co:co (lent lines.u))}"
  " same={?:(=(lines.a lines.u) "y" "n")}"
  (scag 300 diff)
==
