::  CRC-32 (IEEE 802.3), matching java.util.zip.CRC32 + Long.toHexString.
::
::  The PlusCal translator records two checksums in the BEGIN TRANSLATION
::  marker: chksum(pcal) over the parsed algorithm AST's toString() and
::  chksum(tla) over the generated TLA+ text. Both are
::  Long.toHexString(new CRC32().update(bytes).getValue()) -- a reflected
::  CRC-32 with polynomial 0xEDB8.8320, rendered as lowercase hex with no
::  leading zeros and no `0x` prefix (so the empty string yields "0").
|%
++  crc32
  ::  the CRC-32 of a cord's bytes as an unsigned 32-bit atom
  |=  t=@t
  ^-  @ux
  =/  crc=@ux  0xffff.ffff
  =.  crc
    %+  roll  (rip 3 t)
    |=  [b=@ux c=_crc]
    =.  c  (mix c b)
    =/  i  0
    |-  ^-  @ux
    ?:  =(8 i)  c
    =.  c  ?:(=(1 (dis c 1)) (mix (rsh 0 c) 0xedb8.8320) (rsh 0 c))
    $(i +(i))
  (mix crc 0xffff.ffff)
::
++  to-hex
  ::  lowercase hex with no leading zeros or prefix (Long.toHexString)
  |=  n=@
  ^-  @t
  ?:  =(0 n)  '0'
  =/  digs  "0123456789abcdef"
  =|  out=tape
  |-  ^-  @t
  ?:  =(0 n)  (crip out)
  $(n (rsh 2 n), out [(snag (dis n 0xf) digs) out])
::
++  checksum
  ::  the recorded checksum string for a cord (crc32 rendered as hex)
  |=  t=@t
  ^-  @t
  (to-hex (crc32 t))
--
