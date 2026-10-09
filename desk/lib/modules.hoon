/-  *tla-lus
/=  ast      /lib/ast
/=  syn      /lib/syntax
/=  stdmods  /lib/stdmods
|%
  ::  Module Resolution And Standard-Module Loading
  ::
  ::  Port of tla2sany/modanalyzer (SpecObj) behavior at the pinned
  ::  commit: resolution of EXTENDS/INSTANCE references in SpecObj's
  ::  order (any unresolved extension before any instantiation) and
  ::  appearance order, inner modules registered from their outer file,
  ::  user modules shadowing the vendored StandardModules, SANY's
  ::  missing-module / circular-dependency / file-name-mismatch errors,
  ::  and a dependency-first order for semantic analysis. Parses are
  ::  cached by content hash so a stale tree can never cross source
  ::  revisions. +dump-modres renders the normalized `SANY -s`
  ::  differential format.
  ::
::  +|  Types
::
+$  node  syntax-node:ast
+$  mod-src  ?(%root %file %std %inner)
+$  loaded
  $:  name=@t
      src=mod-src
      hash=@
      tree=node
  ==
+$  mod-graph
  $:  order=(list @t)          ::  file parse order (SpecObj's, SANY-equal)
      mods=(map @t loaded)
      deps=(map @t (list @t))  ::  per file: referenced names, in order
      sem-order=(list @t)      ::  dependency-first order for unit 6
  ==
::  content-hash parse cache
+$  pcache  (map @ node)
::  resolution error, pre-structured for the dump renderer
+$  mres-err
  $%  [%missing what=@t in=@t]
      [%cycle path=(list @t)]
      [%mismatch file=@t module=@t]
      [%parse-fail file=@t]
  ==
::
::  +|  Reference Extraction
::
::
++  module-name-of
  ::  declared name from the N_Module tree
  |=  tree=node
  ^-  (unit @t)
  ?.  ?=(%node -.tree)  ~
  ?~  kids.tree  ~
  =/  begin  i.kids.tree
  ?.  ?=(%node -.begin)  ~
  ?~  kids.begin  ~
  ?~  t.kids.begin  ~
  =/  nm  i.t.kids.begin
  ?.  ?=(%leaf -.nm)  ~
  `text.token.nm
::
++  inner-modules
  ::  nested N_Module nodes anywhere below (transitively)
  |=  tree=node
  ^-  (list [name=@t tree=node])
  ?.  ?=(%node -.tree)  ~
  %-  zing
  %+  turn  kids.tree
  |=  k=node
  ^-  (list [name=@t =node])
  ?:  &(?=(%node -.k) =(%n-module kind.k))
    =/  nm  (module-name-of k)
    [[?~(nm '' u.nm) k] (inner-modules k)]
  (inner-modules k)
::
++  refs-of
  ::  EXTENDS and INSTANCE names in appearance order, deduplicated
  |=  tree=node
  ^-  (list @t)
  =/  raw
    |-  ^-  (list @t)
    ?.  ?=(%node -.tree)  ~
    ?:  =(%n-extends kind.tree)
      %+  murn  kids.tree
      |=  k=node
      ^-  (unit @t)
      ?.  ?=(%leaf -.k)  ~
      ?.  =(%identifier kind.token.k)  ~
      `text.token.k
    ?:  =(%n-nonlocalinstance kind.tree)
      ::  [instance name ...]: the module name is the second kid
      ?~  kids.tree  ~
      ?~  t.kids.tree  ~
      =/  nm  i.t.kids.tree
      ?.  ?=(%leaf -.nm)  ~
      [text.token.nm ~]
    %-  zing
    %+  turn  kids.tree
    |=(k=node ^$(tree k))
  ::  dedupe preserving first appearance
  =|  seen=(set @t)
  =|  out=(list @t)
  |-
  ?~  raw  (flop out)
  ?:  (~(has in seen) i.raw)  $(raw t.raw)
  $(raw t.raw, seen (~(put in seen) i.raw), out [i.raw out])
::
++  monolith-module
  ::  SANY's last resort for a module with no file of its own: the block in
  ::  the ROOT file from its `---- MODULE <name> ----` line through the next
  ::  `====` line, both markers included (MonolithSpecExtractor.module, which
  ::  ParseUnit calls once every resolver has missed). Both markers are
  ::  whole-line matches there (`String.matches`), so a header with anything
  ::  else on its line is not one
  |=  [text=@t name=@t]
  ^-  (unit @t)
  =/  ws  (mask " \09\0d")
  =/  head
    ;~  plug
      (stun [4 4.096] hep)
      (star ws)
      (jest 'MODULE')
      (plus ws)
      (jest name)
      (star ws)
      (stun [3 4.096] hep)
      (star (mask "\0d"))
    ==
  =/  lines=wain  (to-wain:format text)
  |-  ^-  (unit @t)
  ?~  lines  ~
  ?~  (rush i.lines head)  $(lines t.lines)
  ::  an unterminated block is still a block: Java stops at end of file
  =/  body=wain  ~[i.lines]
  =/  rest=wain  t.lines
  |-  ^-  (unit @t)
  ?~  rest  `(of-wain:format (flop body))
  ?:  =('====' (end [3 4] i.rest))
    `(of-wain:format (flop [i.rest body]))
  $(rest t.rest, body [i.rest body])
::
::  +|  Resolvers
::
::
++  inline-resolver
  ::  the inline source bundle as a resolver
  |=  modules=(map @t @t)
  ^-  resolver
  |=  name=module-name
  ^-  (unit source-text)
  =/  txt  (~(get by modules) name)
  ?~  txt  ~
  `[[%inline name] u.txt]
::
::  (a synchronous Clay resolver lived here until unit 10.7. It read
::  `<root>/<name>.tla` with `.^` inside whatever event called it, and no
::  stage ever invoked it. Clay sources are loaded asynchronously now —
::  lib/job's %modules stage names the files it needs and pauses — so a
::  library that reads Clay in-line is not just unused but wrong, and the
::  scaffold gate checks that none reappears.)
::
::  +|  Resolution
::
::
++  parse-cached
  ::  parse via the content-hash cache; a hash hit never crosses
  ::  revisions because the key is the text itself
  |=  [text=@t cache=pcache]
  ^-  [res=(each node @t) cache=pcache]
  =/  key  (shax text)
  =/  hit  (~(get by cache) key)
  ?^  hit  [[%& u.hit] cache]
  =/  pr  (parse:syn text)
  ?:  ?=(%| -.pr)  [pr cache]
  [pr (~(put by cache) key p.pr)]
::
++  own-refs
  ::  a module's OWN extendees and instancees, in appearance order, and its
  ::  direct inner modules -- not descending into those inner modules, since
  ::  SANY keeps each ModulePointer's relatives apart
  |=  tree=node
  ^-  [ext=(list @t) inst=(list @t) inner=(list @t)]
  =|  acc=[ext=(list @t) inst=(list @t) inner=(list @t)]
  =/  top=?  &
  |-  ^+  acc
  ?.  ?=(%node -.tree)  acc
  ?:  &(!top =(%n-module kind.tree))
    =/  nm  (module-name-of tree)
    acc(inner (snoc inner.acc ?~(nm '' u.nm)))
  ?:  =(%n-extends kind.tree)
    =/  ids=(list @t)
      %+  murn  kids.tree
      |=  k=node
      ^-  (unit @t)
      ?.  ?=(%leaf -.k)  ~
      ?.  =(%identifier kind.token.k)  ~
      `text.token.k
    acc(ext (weld ext.acc ids))
  ?:  =(%n-nonlocalinstance kind.tree)
    ::  [instance name ...]: the module name is the second kid
    ?.  ?=([* [%leaf *] *] kids.tree)  acc
    acc(inst (snoc inst.acc text.token.i.t.kids.tree))
  =/  ks  kids.tree
  |-  ^+  acc
  ?~  ks  acc
  $(ks t.ks, acc ^$(tree i.ks, top |))
::
++  find-next
  ::  SpecObj.findNextUnresolvedExtention / ...Instantiation: depth-first
  ::  from the root, a module's own unresolved names first, then its
  ::  resolved extendees, its resolved instancees and its inner modules,
  ::  each visited once. `ext` picks which kind of name is wanted
  |=  [root=@t mods=(map @t loaded) ext=?]
  ^-  (unit [name=@t from=@t])
  =|  seen=(set @t)
  =<  -
  |-  ^-  [(unit [name=@t from=@t]) (set @t)]
  ?:  (~(has in seen) root)  [~ seen]
  =.  seen  (~(put in seen) root)
  =/  ld  (~(get by mods) root)
  ?~  ld  [~ seen]
  =/  r  (own-refs tree.u.ld)
  =/  miss=(list @t)
    (skip ?:(ext ext.r inst.r) |=(n=@t (~(has by mods) n)))
  ?^  miss  [`[i.miss root] seen]
  =/  have  |=(n=@t (~(has by mods) n))
  =/  subs=(list @t)
    :(weld (skim ext.r have) (skim inst.r have) inner.r)
  |-  ^-  [(unit [name=@t from=@t]) (set @t)]
  ?~  subs  [~ seen]
  =/  got  ^$(root i.subs)
  ?^  -.got  got
  $(subs t.subs, seen +.got)
::
++  resolve
  ::  module resolution from the root in SANY's order (SpecObj's loop):
  ::  the next module loaded is any unresolved EXTENDS anywhere in the
  ::  tree before any unresolved INSTANCE. (Until R4.1c this was a plain
  ::  BFS, which agreed with SANY on every corpus case and parsed
  ::  `A EXTENDS B; INSTANCE C` with B extending a third module in the
  ::  wrong order.)
  |=  [root=@t res=resolver cache=pcache]
  ^-  [order=(list @t) out=(each mod-graph mres-err) cache=pcache]
  =|  order=(list @t)
  =|  mods=(map @t loaded)
  =|  deps=(map @t (list @t))
  =/  nxt=(unit [name=@t from=@t])  `[root '']
  |-  ^-  [(list @t) (each mod-graph mres-err) pcache]
  ?~  nxt
    ::  cycle check over file-level deps, then semantic order
    =/  cyc  (find-cycle root deps)
    ?^  cyc
      [(flop order) [%| [%cycle u.cyc]] cache]
    :+  (flop order)
      [%& [(flop order) mods deps (sem-order root deps)]]
    cache
  =/  name=@t  name.u.nxt
  =/  from=@t  from.u.nxt
  ::  user modules shadow the standard library
  =/  found=(unit [src=mod-src text=@t])
    =/  user  (res name)
    ?^  user  `[?:(=(name root) %root %file) text.u.user]
    =/  std  (~(get by standard-modules:stdmods) name)
    ?^  std  `[%std u.std]
    ::  last, a block in the root file itself (R4.1c, `tlc-monolith`)
    =/  rt  (res root)
    ?~  rt  ~
    =/  mono  (monolith-module text.u.rt name)
    ?~  mono  ~
    `[%file u.mono]
  ?~  found
    [(flop order) [%| [%missing name from]] cache]
  =.  order  [name order]
  =/  pc  (parse-cached text.u.found cache)
  =.  cache  cache.pc
  ?:  ?=(%| -.res.pc)
    [(flop order) [%| [%parse-fail name]] cache]
  =/  tree  p.res.pc
  ::  declared-name check (SANY file-name mismatch)
  =/  declared  (module-name-of tree)
  ?:  &(?=(^ declared) !=(u.declared name))
    [(flop order) [%| [%mismatch name u.declared]] cache]
  ::  register the file, its inner modules, and its references
  =/  inners  (inner-modules tree)
  =.  mods
    %-  ~(gas by mods)
    :-  [name `loaded`[name src.u.found (shax text.u.found) tree]]
    %+  turn  inners
    |=  [nm=@t tr=node]
    [nm `loaded`[nm %inner 0 tr]]
  =.  deps  (~(put by deps) name (refs-of tree))
  =/  e  (find-next root mods &)
  $(nxt ?^(e e (find-next root mods |)))
::
++  find-cycle
  ::  DFS over file-level deps; returns the first cycle path
  |=  [root=@t deps=(map @t (list @t))]
  ^-  (unit (list @t))
  =|  stack=(list @t)
  =|  done=(set @t)
  =/  helper
    |-  ^-  [(unit (list @t)) (set @t)]
    =*  cur  root
    ?:  (~(has in done) cur)  [~ done]
    =/  hit  (find ~[cur] (flop stack))
    ?^  hit
      ::  cycle: from first occurrence of cur through stack to cur
      =/  pre  (flop stack)
      [`(snoc (slag u.hit pre) cur) done]
    =/  kids  (~(gut by deps) cur ~)
    =.  stack  [cur stack]
    =/  r
      |-  ^-  [(unit (list @t)) (set @t)]
      ?~  kids  [~ done]
      =/  sub  ^$(root i.kids)
      ?^  -.sub  sub
      $(kids t.kids, done +.sub)
    ?^  -.r  r
    [~ (~(put in done) cur)]
  -.helper
::
++  sem-order
  ::  dependency-first (post-order DFS from the root)
  |=  [root=@t deps=(map @t (list @t))]
  ^-  (list @t)
  =|  seen=(set @t)
  =|  out=(list @t)
  =/  helper
    |-  ^-  [(list @t) (set @t)]
    ?:  (~(has in seen) root)  [out seen]
    =.  seen  (~(put in seen) root)
    =/  kids  (~(gut by deps) root ~)
    =/  r
      |-  ^-  [(list @t) (set @t)]
      ?~  kids  [out seen]
      =/  sub  ^$(root i.kids)
      $(kids t.kids, out -.sub, seen +.sub)
    [[root -.r] +.r]
  (flop -.helper)
::
::  +|  Differential Dump (normalized `SANY -s` output)
::
::
++  banner  '****** SANY2 Version 2.2 created 08 July 2020'
::
++  dump-modres
  |=  [root=@t modules=(map @t @t)]
  ^-  wain
  =/  r  (resolve root (inline-resolver modules) ~)
  %-  zing
  ^-  (list wain)
  :~  ~['' banner '']
    ::
      %+  turn  order.r
      |=  nm=@t
      (cat 3 'Parsing file ' (cat 3 nm '.tla'))
    ::
      ?:  ?=(%& -.out.r)  ~
      (render-err root p.out.r)
  ==
::
++  render-err
  ::  the doubled fatal-error block SANY prints
  |=  [root=@t err=mres-err]
  ^-  wain
  =/  loc=@t
    ?:  ?=(%missing -.err)  (cat 3 'In module ' in.err)
    'Unknown location'
  =/  msg=wain
    ?-  -.err
        %missing
      :_  ~
      %+  rap  3
      :~  'Cannot find source file for module '  what.err
          ' imported in module '  in.err  '.'
      ==
    ::
        %cycle
      :~  'Circular dependency among .tla files; dependency cycle is:'
          ''
          %+  rap  3
          :-  '  '
          %+  join  ' --> '
          `(list @t)`(turn path.err |=(n=@t (cat 3 n '.tla')))
      ==
    ::
        %mismatch
      :_  ~
      %+  rap  3
      :~  'File name \''  file.err  '\' does not match the name \''
          module.err  '\' of the top level module it contains.'
      ==
    ::
        %parse-fail
      ~['Could not parse module.']
    ==
  %-  zing
  ^-  (list wain)
  :~  :~  ''
          (cat 3 'Fatal errors while parsing TLA+ spec in file ' (cat 3 root '.tla'))
          ''
          loc
          ''
      ==
      msg
      ~['*** Errors: 1' '' loc '']
      msg
      ~['' '']
  ==
--
