/-  *tla-lus
|%
  ::  Source Handling: Characters With SANY Positions
  ::
  ::  Replicates JavaCC SimpleCharStream.UpdateLineColumn exactly
  ::  (tabSize 8): tabs advance to the next multiple of eight plus one,
  ::  CR/LF/CRLF all take columns on their own line and start the next
  ::  line at column 1. Positions are per code point, matching Java's
  ::  per-char columns for BMP input. CRLF is never rewritten, so
  ::  reported logical positions match SANY on either line ending.
  ::
::  +|  Types
::
::  one annotated code point
+$  ach  [c=@c l=@ud col=@ud]
::
::  +|  UTF-8 Codec
::
::  zuse's +tuba/+tufa reject control characters (tab crashes them);
::  these accept everything Java's reader accepts
::
++  codepoints
  |=  t=@t
  ^-  (list @c)
  =/  bytes  `(list @)`(rip 3 t)
  =|  acc=(list @c)
  |-
  ?~  bytes  (flop acc)
  =/  b  i.bytes
  ?:  (lth b 0x80)
    $(bytes t.bytes, acc [`@c`b acc])
  ?:  &((gte b 0xc0) (lte b 0xdf))
    ?~  t.bytes  (flop acc)
    =/  c  (add (lsh [0 6] (sub b 0xc0)) (dis i.t.bytes 0x3f))
    $(bytes t.t.bytes, acc [`@c`c acc])
  ?:  &((gte b 0xe0) (lte b 0xef))
    ?~  t.bytes  (flop acc)
    ?~  t.t.bytes  (flop acc)
    =/  c
      ;:  add
        (lsh [0 12] (sub b 0xe0))
        (lsh [0 6] (dis i.t.bytes 0x3f))
        (dis i.t.t.bytes 0x3f)
      ==
    $(bytes t.t.t.bytes, acc [`@c`c acc])
  ?:  &((gte b 0xf0) (lte b 0xf7))
    ?~  t.bytes  (flop acc)
    ?~  t.t.bytes  (flop acc)
    ?~  t.t.t.bytes  (flop acc)
    =/  c
      ;:  add
        (lsh [0 18] (sub b 0xf0))
        (lsh [0 12] (dis i.t.bytes 0x3f))
        (lsh [0 6] (dis i.t.t.bytes 0x3f))
        (dis i.t.t.t.bytes 0x3f)
      ==
    $(bytes t.t.t.t.bytes, acc [`@c`c acc])
  ::  invalid lead byte: pass through
  $(bytes t.bytes, acc [`@c`b acc])
::
++  utf8-tape
  |=  cs=(list @c)
  ^-  tape
  %-  zing
  %+  turn  cs
  |=  c=@c
  ^-  tape
  ?:  (lth c 0x80)  [`@tD`c ~]
  ?:  (lth c 0x800)
    :~  `@tD`(add 0xc0 (rsh [0 6] c))
        `@tD`(add 0x80 (dis c 0x3f))
    ==
  ?:  (lth c 0x1.0000)
    :~  `@tD`(add 0xe0 (rsh [0 12] c))
        `@tD`(add 0x80 (dis (rsh [0 6] c) 0x3f))
        `@tD`(add 0x80 (dis c 0x3f))
    ==
  :~  `@tD`(add 0xf0 (rsh [0 18] c))
      `@tD`(add 0x80 (dis (rsh [0 12] c) 0x3f))
      `@tD`(add 0x80 (dis (rsh [0 6] c) 0x3f))
      `@tD`(add 0x80 (dis c 0x3f))
  ==
::
::  +|  Annotation
::
::
++  annotate
  ::  Attach the SANY line/column to every code point
  |=  text=@t
  ^-  (list ach)
  =/  cs  (codepoints text)
  =|  acc=(list ach)
  =/  line=@ud  1
  =/  col=@ud   0
  =/  cr=?  |
  =/  lf=?  |
  |-
  ?~  cs  (flop acc)
  =/  c  i.cs
  =.  col  +(col)
  =^  moved  line
    ?:  lf
      [& +(line)]
    ?:  &(cr !=('\0a' `@c`c))
      [& +(line)]
    [| line]
  =?  col  moved  1
  =/  new-lf  &(cr =('\0a' `@c`c))
  =.  lf  |
  =.  cr  |
  =?  lf  |(new-lf =('\0a' `@c`c))  &
  =?  cr  =('\0d' `@c`c)  &
  =?  col  =('\09' `@c`c)
    (add (dec col) (sub 8 (mod (dec col) 8)))
  $(cs t.cs, acc [[c line col] acc])
::
::  +|  End-Of-File Position
::
::
++  eof-pos
  ::  Where JavaCC reports an EOF encountered after these chars
  |=  s=(list ach)
  ^-  [l=@ud c=@ud]
  =/  last  (rear-unit s)
  ?~  last  [1 1]
  ?:  ?|(=('\0a' `@c`c.u.last) =('\0d' `@c`c.u.last))
    [+(l.u.last) 0]
  [l.u.last +(col.u.last)]
::
++  rear-unit
  |=  s=(list ach)
  ^-  (unit ach)
  ?~  s  ~
  `(rear s)
--
