/-  *tla-lus
|%
  ::  Clay Source Paths (unit P2-10.2)
  ::
  ::  The only constructor of a $source-ref. Every path a job reads is
  ::  built here, so escape is impossible by construction rather than by
  ::  discipline: a segment that is empty, dotted, `$`-prefixed, or not a
  ::  Clay knot is a typed error naming the segment, and a candidate that
  ::  does not lie under a declared search root is refused outright.
  ::
  ::  Clay is not a POSIX filesystem — a `..` segment is a (malformed)
  ::  knot, not a traversal, and a read is already confined to one desk.
  ::  The guard is therefore defense in depth plus an honest diagnostic:
  ::  a malformed path is named, never silently missed.
  ::
  ::  The name-to-file mapping is util.FilenameToStream's: a module name
  ::  becomes the lowercased name plus the `.tla` extension, because Clay
  ::  path segments cannot carry case. The case-sensitive declared-name
  ::  check stays with the resolver (lib/job +load-drain).
  ::
  ::  The revision must already be pinned: +read-ref refuses a `%da` or
  ::  `%tas` case, so a mid-run commit cannot split a run's source set and
  ::  no read can block on an unsettled case.
  ::
::  +|  Types
::
+$  path-err
  $%  [%no-roots ~]
      [%empty-name ~]
      [%bad-name name=@t]
      [%bad-desk =desk]
      [%unpinned cas=case]
      ::  `.` or `..`: the segments that would mean escape
      [%escape seg=@ta at=path]
      [%bad-segment seg=@ta why=@t at=path]
      [%out-of-root at=path]
      ::  a write target that overlaps the run's own read roots: a run must
      ::  not be able to overwrite the sources it is checking (R2.2)
      [%write-over-source at=path]
  ==
::
::  +|  Rendering
::
::
++  err-text
  |=  e=path-err
  ^-  @t
  ?-    -.e
      %no-roots    'a %clay bundle needs at least one module-search root'
      %empty-name  'empty root module name'
      %bad-name
    (rap 3 ~['invalid module name \'' name.e '\''])
  ::
      %bad-desk
    (rap 3 ~['invalid desk name \'' desk.e '\''])
  ::
      %unpinned
    'the Clay revision was not pinned to a concrete number'
  ::
      %write-over-source
    %+  rap  3
    :~  'write target '  (spat at.e)
        ' overlaps a module-search root; a run may not write over its own sources'
    ==
  ::
      %escape
    %+  rap  3
    :~  'path segment \''  seg.e  '\' escapes its search root in '
        (spat at.e)
    ==
  ::
      %bad-segment
    %+  rap  3
    :~  'invalid path segment \''  seg.e  '\' ('  why.e  ') in '
        (spat at.e)
    ==
  ::
      %out-of-root
    (rap 3 ~['path ' (spat at.e) ' is not under a declared search root'])
  ==
::
::  +|  Segments
::
::
++  knot-char
  ::  the characters a Clay path segment may carry. `.` is excluded, so
  ::  a dotted segment (a filesystem-style path smuggled into one knot)
  ::  never reaches Clay; `$` likewise
  |=  c=@t
  ^-  ?
  ?|  &((gte c 'a') (lte c 'z'))
      &((gte c '0') (lte c '9'))
      =(c '-')
      =(c '~')
      =(c '_')
  ==
::
++  check-seg
  |=  [s=@ta at=path]
  ^-  (unit path-err)
  =/  t  (trip s)
  ?~  t  `[%bad-segment s 'empty' at]
  ?:  |(=('.' s) =('..' s))
    `[%escape s at]
  ?:  =('$' i.t)
    `[%bad-segment s 'reserved $ prefix' at]
  ?:  (lien `tape`t |=(c=@t =('.' c)))
    `[%bad-segment s 'dotted' at]
  ?.  (levy `tape`t knot-char)
    `[%bad-segment s 'not a Clay knot' at]
  ~
::
++  check-path
  ::  every segment of one path, reported against the whole path
  |=  pax=path
  ^-  (unit path-err)
  =/  at  pax
  |-  ^-  (unit path-err)
  ?~  pax  ~
  =/  e  (check-seg i.pax at)
  ?^  e  e
  $(pax t.pax)
::
++  check-desk
  |=  d=desk
  ^-  (unit path-err)
  =/  t  (trip d)
  ?~  t  `[%bad-desk d]
  ?.  (levy `tape`t knot-char)  `[%bad-desk d]
  ~
::
++  under-root
  ::  a candidate must lie under a declared search root; the empty root
  ::  (`/`) legitimately declares the desk itself
  |=  [roots=(list path) pax=path]
  ^-  ?
  |-  ^-  ?
  ?~  roots  |
  ?:  =(i.roots (scag (lent i.roots) `path`pax))  &
  $(roots t.roots)
::
::  +|  Module Names
::
::
++  name-char
  ::  a TLA+ module identifier: letters, digits, underscore
  |=  c=@t
  ^-  ?
  ?|  &((gte c 'a') (lte c 'z'))
      &((gte c 'A') (lte c 'Z'))
      &((gte c '0') (lte c '9'))
      =(c '_')
  ==
::
++  module-seg
  ::  util.FilenameToStream: module name -> lowercased file name
  |=  name=module-name
  ^-  (each @ta path-err)
  =/  t  (trip name)
  ?~  t  [%| [%empty-name ~]]
  ?.  (levy `tape`t name-char)  [%| [%bad-name name]]
  [%& `@ta`(crip (cass `tape`t))]
::
++  module-path
  ::  the candidate file for a module name under one search root
  |=  [rot=path name=module-name]
  ^-  (each path path-err)
  =/  seg  (module-seg name)
  ?:  ?=(%| -.seg)  [%| p.seg]
  [%& (weld rot `path`~[p.seg %tla])]
::
::  +|  Construction
::
::
++  read-ref
  ::  the only way to name a file for reading: a pinned revision, a
  ::  well-formed desk, canonical segments, and a path under the roots
  |=  [=ship =desk cas=case roots=(list path) pax=path]
  ^-  (each source-ref path-err)
  ?.  ?=(%ud -.cas)  [%| [%unpinned cas]]
  =/  de  (check-desk desk)
  ?^  de  [%| u.de]
  =/  pe  (check-path pax)
  ?^  pe  [%| u.pe]
  ?.  (under-root roots pax)  [%| [%out-of-root pax]]
  [%& [ship desk cas pax]]
::
++  write-ref
  ::  the only way to name a write destination. Deliberately NOT `+read-ref`
  ::  with a flag — the two differ in every rule that matters:
  ::
  ::    - a read needs a PINNED case so a mid-run commit cannot split the
  ::      source set; a write always lands at the head, so it carries no case
  ::      at all. A write to a past revision would be meaningless.
  ::    - a read must lie UNDER a declared search root; a write must lie
  ::      OUTSIDE every one of them, or a run could overwrite the very
  ::      sources it is checking — and then re-read them on a resumed slice.
  ::
  ::  Segment canonicalization is shared, because escape is escape.
  |=  [=desk roots=(list path) pax=path]
  ^-  (each write-target path-err)
  =/  de  (check-desk desk)
  ?^  de  [%| u.de]
  =/  pe  (check-path pax)
  ?^  pe  [%| u.pe]
  ::  overlap in EITHER direction is refused: a target under a read root
  ::  (`/spec` vs root `/`) and a read root under the target (`/out` root
  ::  `/out/sub`) both let a write reach a source
  ?:  (overlaps roots pax)  [%| [%write-over-source pax]]
  [%& [desk pax]]
::
++  overlaps
  ::  does `pax` share a prefix with any root, in either direction?
  |=  [roots=(list path) pax=path]
  ^-  ?
  |-  ^-  ?
  ?~  roots  |
  ?|  =(i.roots (scag (lent i.roots) `path`pax))
      =(pax (scag (lent pax) `path`i.roots))
      $(roots t.roots)
  ==
::
++  check-bundle
  ::  what a %clay bundle can be judged on before any read: the desk, the
  ::  root module name, at least one search root, every root's segments,
  ::  and a config path that is canonical and inside the roots
  |=  [=desk root=module-name cfg=(unit path) roots=(list path)]
  ^-  (unit path-err)
  =/  de  (check-desk desk)
  ?^  de  de
  =/  ms  (module-seg root)
  ?:  ?=(%| -.ms)  `p.ms
  ?~  roots  `[%no-roots ~]
  =/  re  (check-roots roots)
  ?^  re  re
  ?~  cfg  ~
  =/  ce  (check-path u.cfg)
  ?^  ce  ce
  ?.  (under-root roots u.cfg)  `[%out-of-root u.cfg]
  ~
::
++  check-roots
  |=  roots=(list path)
  ^-  (unit path-err)
  |-  ^-  (unit path-err)
  ?~  roots  ~
  =/  e  (check-path i.roots)
  ?^  e  e
  $(roots t.roots)
--
