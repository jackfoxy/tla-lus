::  Differential test: Hoon CRC-32 vs java.util.zip.CRC32 + Long.toHexString.
::  Vectors computed from the pinned JDK; see tools/oracle/CrcVec.java.
/+  *test
/=  crc  /lib/tla/crc
|%
++  test-crc-empty
  (expect-eq !>('0') !>((checksum:crc '')))
::
++  test-crc-a
  (expect-eq !>('e8b7be43') !>((checksum:crc 'a')))
::
++  test-crc-abc
  (expect-eq !>('352441c2') !>((checksum:crc 'abc')))
::
++  test-crc-fox
  %+  expect-eq
    !>  '414fa339'
  !>  (checksum:crc 'The quick brown fox jumps over the lazy dog')
::
++  test-crc-algorithm
  (expect-eq !>('282d6727') !>((checksum:crc '--algorithm Counter')))
::
++  test-crc-newline
  (expect-eq !>('ab7d37d5') !>((checksum:crc 'hello\0aworld')))
::
++  test-crc-chksum
  (expect-eq !>('d9a79f05') !>((checksum:crc 'chksum(pcal)')))
--
