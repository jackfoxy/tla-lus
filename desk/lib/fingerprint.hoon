::  Canonical FP64 fingerprints + FPSet visited-set semantics (Work Unit 7.1).
::
::  Ports tlc2.util.FP64 (initialized at index 0, the `-fp 0` polynomial) and
::  the observable FPSet.put/contains contract over the Work Unit 6.8
::  `fp-input` byte stream.
::
::  FP64 is a CRC-64 over bytes: the fingerprint starts at IrredPoly and each
::  byte b advances it by
::    fp = (fp >>> 8) ^ ByteModTable_7[(b ^ fp) & 0xFF]
::  ByteModTable_7 is derived from IrredPoly once (FP64.Init). A state's
::  fingerprint extends FP64 over each variable's `fp-input` bytes in TLC's
::  canonical (declaration) variable order, matching TLCState.fingerPrint.
::
/=  vl  /lib/value
::
::  build the 256-entry ByteModTable_7 once, closed over by the exposed core.
::
=>
|%
++  irred-poly  0x9114.98ae.0e66.bad6           ::  FP64.Polys[0] (index 0)
++  one         0x8000.0000.0000.0000           ::  FP64.One (bit 63)
::  PowerTable[0..71]: t starts at One, t <- (t >>> 1) ^ (t.0 ? IrredPoly : 0)
++  power-table
  ^-  (list @ux)
  =|  out=(list @ux)
  =/  t=@ux  one
  |-  ^-  (list @ux)
  ?:  =(72 (lent out))  (flop out)
  =/  nt=@ux  (mix (rsh [0 1] t) ?:(=(1 (dis 0x1 t)) irred-poly 0x0))
  $(out [t out], t nt)
::  ByteModTable_7[j] = XOR over set bits k of j of PowerTable[71-k]
++  build-mod
  ^-  (map @ @ux)
  =/  pt=(list @ux)  (slag 64 power-table)         ::  PowerTable[64..71]
  =|  out=(map @ @ux)
  =/  j  0
  |-  ^-  (map @ @ux)
  ?:  =(256 j)  out
  =/  v=@ux  0x0
  =/  k  0
  =.  v
    |-  ^-  @ux
    ?:  =(8 k)  v
    ::  bit k of j selects PowerTable[71-k] = pt at list index 7-k
    =?  v  =(1 (dis 0x1 (rsh [0 k] j)))  (mix v (snag (sub 7 k) pt))
    $(k +(k))
  $(j +(j), out (~(put by out) j v))
--
::
=/  mod=(map @ @ux)  build-mod
::  R4.P5 (H6): the same table as one atom, entry j at 64-bit word j, read
::  with +cut (jetted) instead of a map lookup per byte
=/  tab=@
  %+  rep  6
  (turn (gulf 0 255) |=(j=@ (~(got by mod) j)))
::
|%
+$  fp      @ux                                  ::  a 64-bit fingerprint
+$  fp-set  (map fp @ud)                         ::  fp -> first-seen depth
::
++  fp-new  ^-(fp irred-poly)
::  advance a fingerprint by one byte
++  fp-byte
  |=  [f=fp b=@D]
  ^-  fp
  (mix (rsh [0 8] f) (cut 6 [(dis 0xff (mix b f)) 1] tab))
::  advance a fingerprint by a byte stream
++  fp-bytes
  |=  [f=fp bs=(list @D)]
  ^-  fp
  ?~  bs  f
  $(f (fp-byte f i.bs), bs t.bs)
::  the fingerprint of a single value (New then Extend over its fp-input)
++  fp-value
  |=  x=value:vl
  ^-  fp
  (fp-walk fp-new (normalize:vl x))
::
++  fp-walk
  ::  FP64 extended over a NORMALIZED value's fp-input bytes, folded in as
  ::  they are produced: no byte list and no nested +weld (R4.P5, H6).
  ::  (fp-walk f v) = (fp-bytes f (fp-enc:vl v)) byte for byte; the
  ::  differential arm in tests/lib/value checks it
  |=  [f=fp v=value:vl]
  ^-  fp
  ?-  -.v
      %bool   (fp-byte (fp-byte f k-bool:vl) ?:(p.v 't' 'f'))
      %int    (fp-i32 (fp-byte f k-int:vl) p.v)
      %str    (fp-str f p.v)
      %model
    =/  g  (fp-i32 (fp-byte f k-model:vl) (sun:si (met 3 p.v)))
    (fp-word g p.v (met 3 p.v))
  ::
      %intv
    =/  els  (expand-intv:vl lo.v hi.v)
    (fp-elems (fp-count f k-set:vl (lent els)) els)
  ::
      %set    (fp-elems (fp-count f k-set:vl (lent p.v)) p.v)
      %seq
    =/  g  (fp-count f k-fcn:vl (lent p.v))
    =/  i  1
    |-  ^-  fp
    ?~  p.v  g
    =.  g  (fp-i32 (fp-byte g k-int:vl) (sun:si i))
    $(p.v t.p.v, i +(i), g (fp-walk g i.p.v))
  ::
      %rec
    =/  g  (fp-count f k-fcn:vl (lent p.v))
    |-  ^-  fp
    ?~  p.v  g
    $(p.v t.p.v, g (fp-walk (fp-str g k.i.p.v) v.i.p.v))
  ::
      %fcn
    =/  g  (fp-count f k-fcn:vl (lent p.v))
    |-  ^-  fp
    ?~  p.v  g
    $(p.v t.p.v, g (fp-walk (fp-walk g d.i.p.v) r.i.p.v))
  ==
::
++  fp-count
  ::  a set or function header: kind tag, then the element count
  |=  [f=fp k=@D n=@ud]
  ^-  fp
  (fp-i32 (fp-byte f k) (sun:si n))
::
++  fp-i32
  ::  a Java int's four little-endian bytes, fed straight from its bits
  |=  [f=fp n=@sd]
  ^-  fp
  (fp-word f (i32:vl n) 4)
::
++  fp-word
  ::  feed the `n` low-order bytes of `u`, least significant first: one
  ::  loop in place of a gate call (and, for a string, a +rip) per byte
  |=  [f=fp u=@ n=@ud]
  ^-  fp
  ?:  =(0 n)  f
  %=  $
    f  (mix (rsh 3 f) (cut 6 [(dis 0xff (mix u f)) 1] tab))
    u  (rsh 3 u)
    n  (dec n)
  ==
::
++  fp-elems
  |=  [f=fp vs=(list value:vl)]
  ^-  fp
  ?~  vs  f
  $(vs t.vs, f (fp-walk f i.vs))
::
++  fp-str
  ::  a STRINGVALUE field: tag, length, chars
  |=  [f=fp s=@t]
  ^-  fp
  =/  g  (fp-i32 (fp-byte f k-str:vl) (sun:si (met 3 s)))
  (fp-word g s (met 3 s))
::  the fingerprint of a state: FP64 over each variable's value bytes in
::  TLC's canonical variable order (`order`). A missing binding contributes
::  no bytes; solve() only yields complete states, so this is defensive.
++  state-fp
  |=  [order=(list @t) st=(map @t value:vl)]
  ^-  fp
  =/  acc  fp-new
  |-  ^-  fp
  ?~  order  acc
  =/  v  (~(get by st) i.order)
  ?~  v  $(order t.order)
  $(order t.order, acc (fp-walk acc (normalize:vl u.v)))
::
::  Symmetry reduction (Work Unit 7.5): a state's fingerprint is taken over its
::  orbit representative — the lexicographically smallest state reachable by
::  applying every permutation in the symmetry group, matching
::  TLCStateMut.fingerPrint. A permutation renames model values.
::
++  permute
  ::  rename the model values of a value under `pm` (identity elsewhere); the
  ::  recursion is hand-rolled (a wet turn over the value mold fuse-loops)
  |=  [pm=(map @t @t) v=value:vl]
  ^-  value:vl
  ?-  -.v
    %bool   v
    %int    v
    %intv   v
    %str    v
    %model  [%model (~(gut by pm) p.v p.v)]
    %set    [%set %set-enum (permute-list pm p.v)]
    %seq    [%seq (permute-list pm p.v)]
    %rec    [%rec (permute-fields pm p.v)]
    %fcn    [%fcn (permute-pairs pm p.v)]
  ==
++  permute-list
  |=  [pm=(map @t @t) l=(list value:vl)]
  ^-  (list value:vl)
  ?~  l  ~
  [(permute pm i.l) $(l t.l)]
++  permute-fields
  |=  [pm=(map @t @t) l=(list [k=@t v=value:vl])]
  ^-  (list [k=@t v=value:vl])
  ?~  l  ~
  [[k.i.l (permute pm v.i.l)] $(l t.l)]
++  permute-pairs
  |=  [pm=(map @t @t) l=(list [d=value:vl r=value:vl])]
  ^-  (list [d=value:vl r=value:vl])
  ?~  l  ~
  [[(permute pm d.i.l) (permute pm r.i.l)] $(l t.l)]
::  the state permuted by `pm`, each value re-normalized (a model rename can
::  reorder a set or function)
++  permute-state
  |=  [pm=(map @t @t) order=(list @t) st=(map @t value:vl)]
  ^-  (map @t value:vl)
  =|  out=(map @t value:vl)
  |-  ^-  (map @t value:vl)
  ?~  order  out
  =/  v  (~(get by st) i.order)
  ?~  v  $(order t.order)
  $(order t.order, out (~(put by out) i.order (normalize:vl (permute pm u.v))))
::  strict lexicographic order over states, variables in declaration order
++  state-lth
  |=  [a=(map @t value:vl) b=(map @t value:vl) order=(list @t)]
  ^-  ?
  ?~  order  |
  =/  va  (~(get by a) i.order)
  =/  vb  (~(get by b) i.order)
  ?~  va  ?~(vb $(order t.order) &)
  ?~  vb  |
  ?:  (vlth:vl u.va u.vb)  &
  ?:  (vlth:vl u.vb u.va)  |
  $(order t.order)
::  the orbit representative: the lex-smallest permuted state (identity when
::  the symmetry group is empty)
++  canonicalize
  ::  the lex-smallest state in the orbit of `st` under the GROUP GENERATED by
  ::  the permutation set — reached by repeatedly taking the smallest image
  ::  under all perms until it stops shrinking (a fixpoint). tlc2 builds the
  ::  cross product of the symmetry sets (TLCStateMut.fingerPrint:
  ::  |perms| = |set 1|! * |set 2|! * …) and reduces in one pass; iterating the
  ::  smaller GENERATING set (e.g. `Permutations(P) \union Permutations(Q)`, a
  ::  non-group union) to a fixpoint yields the same representative without
  ::  materializing the product. A closed group (a single `Permutations(S)`)
  ::  fixes on the first pass, so the reduction is unchanged there.
  |=  [perms=(list (map @t @t)) order=(list @t) st=(map @t value:vl)]
  ^-  (map @t value:vl)
  ?~  perms  st
  |-  ^-  (map @t value:vl)
  =/  best=(map @t value:vl)  st
  =/  ps=(list (map @t @t))  perms
  =.  best
    |-  ^-  (map @t value:vl)
    ?~  ps  best
    =/  cand  (permute-state i.ps order st)
    =?  best  (state-lth cand best order)  cand
    $(ps t.ps)
  ?:  =(best st)  best
  $(st best)
::  the fingerprint of a state's orbit representative, plus the representative
::  itself (stored so the visited set and traces use it consistently)
++  orbit-fp
  |=  [perms=(list (map @t @t)) order=(list @t) st=(map @t value:vl)]
  ^-  [fp=fp canon=(map @t value:vl)]
  =/  canon  (canonicalize perms order st)
  [(state-fp order canon) canon]
::
++  view-fp
  ::  a state's identity under a VIEW: tlc2 fingerprints the VIEW's VALUE
  ::  rather than the state's bindings (`TLCStateMutExt.fingerPrint`, the
  ::  `viewMap != null` branch), and evaluates it on `minVals` -- the
  ::  SYMMETRY REPRESENTATIVE, not the raw state. `+orbit-fp` already returns
  ::  that representative as `canon`, so the two compose in the pin's order:
  ::  canonicalize first, then view (R2.3.1)
  |=  v=value:vl
  ^-  fp
  (fp-value v)
::
::  FPSet observable semantics (FPSet.put / FPSet.contains; memory model).
::
++  fs-empty  ^-(fp-set ~)
++  fs-has    |=([s=fp-set f=fp] (~(has by s) f))
++  fs-depth  |=([s=fp-set f=fp] (~(get by s) f))    ::  first-seen depth
++  fs-size   |=(s=fp-set ~(wyt by s))               ::  distinct count
::  first-seen insertion: `contains` then insert. A re-seen fingerprint keeps
::  its original depth; `added` is false iff it was already present.
++  fs-put
  |=  [s=fp-set f=fp d=@ud]
  ^-  [added=? fp-set]
  ?:  (~(has by s) f)  [| s]
  [& (~(put by s) f d)]
--
