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
/=  vl  /lib/tla/tlc/value
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
  (mix (rsh [0 8] f) (~(got by mod) (dis 0xff (mix b f))))
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
  (fp-bytes fp-new (fp-input:vl x))
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
  $(order t.order, acc (fp-bytes acc (fp-input:vl u.v)))
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
