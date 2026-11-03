/-  *tla-lus
/+  *test
/=  sp  /lib/source-path
|%
  ::  Tests For Clay Path Canonicalization (unit P2-10.2)
  ::
  ::  A source-ref exists only if lib/source-path built it, so these
  ::  cases are the whole surface a Clay read can be named through: a
  ::  pinned revision, a well-formed desk, canonical segments, and a path
  ::  under a declared search root. Every rejection names what offended.
  ::
++  roots  `(list path)`~[/src /vendor/tla]
::
++  ref
  |=  [cas=case pax=path]
  (read-ref:sp ~zod %spec cas roots pax)
::
++  txt
  |=  e=path-err:sp
  (err-text:sp e)
::
::  path literals cannot spell these segments, so they are built flat
++  esc-path     `path`~[%src `@ta`'..' %etc %tla]
++  dot-path     `path`~[%src `@ta`'.' %tla]
++  dollar-path  `path`~[%src `@ta`'$foo' %tla]
++  dotted-path  `path`~[%src `@ta`'spec.tla']
++  tbx-path     `path`~[%src `@ta`'puzzle.toolbox' %model-1 %mc %tla]
++  tbx-mark     `path`~[%src `@ta`'puzzle.toolbox' %mc `@ta`'t.la']
++  upper-path   `path`~[%src `@ta`'Spec' %tla]
++  empty-path   `path`~[%src `@ta`'' %tla]
++  esc-root     `path`~[%src `@ta`'..']
++  esc-cfg      `path`~[%src `@ta`'..' %secrets %txt]
::
::  +|  Accepted
::
::
++  test-ref-in-root
  %+  expect-eq
    !>([%& `source-ref`[~zod %spec ud+7 /src/spec/tla]])
  !>((ref ud+7 /src/spec/tla))
::
++  test-ref-nested-under-root
  ::  a search root may be a directory: anything below it is in scope
  %+  expect-eq
    !>([%& `source-ref`[~zod %spec ud+7 /vendor/tla/sub/spec/tla]])
  !>((ref ud+7 /vendor/tla/sub/spec/tla))
::
++  test-empty-root-is-the-desk
  ::  declaring `/` as a search root legitimately scopes the whole desk
  =/  r  (read-ref:sp ~zod %spec ud+7 `(list path)`~[~] /any/where/tla)
  (expect-eq !>(%.y) !>(?=(%& -.r)))
::
++  test-module-path-lowercases
  ::  util.FilenameToStream: the file is the lowercased module name
  ;:  weld
    (expect-eq !>([%& /src/diehard/tla]) !>((module-path:sp /src 'DieHard')))
    (expect-eq !>([%& /diehard/tla]) !>((module-path:sp / 'DieHard')))
    (expect-eq !>([%& %spec]) !>((module-seg:sp 'spec')))
  ==
::
++  test-bundle-accepted
  %+  expect-eq
    !>(~)
  !>((check-bundle:sp %spec 'DieHard' `/src/cfg/txt roots))
::
::  +|  Rejected: Escape And Malformed Segments
::
::
++  test-escape-segment
  ::  the segments that would mean traversal, named in the message
  ;:  weld
    (expect-eq !>([%| [%escape '..' esc-path]]) !>((ref ud+7 esc-path)))
    (expect-eq !>([%| [%escape '.' dot-path]]) !>((ref ud+7 dot-path)))
    %+  expect-eq
      !>('path segment \'..\' escapes its search root in /src/../etc/tla')
    !>((txt [%escape '..' esc-path]))
  ==
::
++  test-dollar-segment
  %+  expect-eq
    !>([%| [%bad-segment '$foo' 'reserved $ prefix' dollar-path]])
  !>((ref ud+7 dollar-path))
::
++  test-dotted-segment
  ::  a filesystem-style name smuggled into one knot
  %+  expect-eq
    !>([%| [%bad-segment 'spec.tla' 'dotted' dotted-path]])
  !>((ref ud+7 dotted-path))
::
::  R4.2r: a DIRECTORY may contain `.` (the Examples' Toolbox model
::  directories); a file's name or mark segment may not
++  test-dotted-directory-accepted
  %+  expect-eq
    !>([%& `source-ref`[~zod %spec ud+7 tbx-path]])
  !>((ref ud+7 tbx-path))
::
++  test-dotted-mark-refused
  %+  expect-eq
    !>([%| [%bad-segment 't.la' 'dotted' tbx-mark]])
  !>((ref ud+7 tbx-mark))
::
++  test-non-knot-segment
  ::  Clay segments are lowercase; an uppercase file name cannot exist
  %+  expect-eq
    !>([%| [%bad-segment 'Spec' 'not a Clay knot' upper-path]])
  !>((ref ud+7 upper-path))
::
++  test-empty-segment
  %+  expect-eq
    !>([%| [%bad-segment '' 'empty' empty-path]])
  !>((ref ud+7 empty-path))
::
::  +|  Rejected: Out Of Root, Unpinned, Malformed Names
::
::
++  test-out-of-root
  ;:  weld
    (expect-eq !>([%| [%out-of-root /etc/passwd]]) !>((ref ud+7 /etc/passwd)))
    ::  a prefix of a root is not under it
    (expect-eq !>([%| [%out-of-root /vendor]]) !>((ref ud+7 /vendor)))
    %+  expect-eq
      !>('path /etc/passwd is not under a declared search root')
    !>((txt [%out-of-root /etc/passwd]))
  ==
::
++  test-unpinned-case
  ::  a %da or %tas case is refused: the run pins one revision at submit
  ;:  weld
    (expect-eq !>([%| [%unpinned da+~2026.7.16]]) !>((ref da+~2026.7.16 /src/spec/tla)))
    (expect-eq !>([%| [%unpinned tas+%live]]) !>((ref tas+%live /src/spec/tla)))
    %+  expect-eq
      !>('the Clay revision was not pinned to a concrete number')
    !>((txt [%unpinned da+~2026.7.16]))
  ==
::
++  test-bad-desk
  ;:  weld
    %+  expect-eq
      !>([%| [%bad-desk %$]])
    !>((read-ref:sp ~zod %$ ud+7 roots /src/spec/tla))
    (expect-eq !>('invalid desk name \'\'') !>((txt [%bad-desk %$])))
  ==
::
++  test-bad-module-name
  ;:  weld
    (expect-eq !>([%| [%empty-name ~]]) !>((module-seg:sp '')))
    (expect-eq !>([%| [%bad-name 'a b']]) !>((module-seg:sp 'a b')))
    (expect-eq !>([%| [%bad-name '../etc']]) !>((module-path:sp /src '../etc')))
    (expect-eq !>('invalid module name \'a b\'') !>((txt [%bad-name 'a b'])))
  ==
::
::  +|  Rejected: Bundle Shape (at submit)
::
::
++  test-bundle-no-roots
  %+  expect-eq
    !>(`[%no-roots ~])
  !>((check-bundle:sp %spec 'spec' `/src/cfg/txt ~))
::
++  test-bundle-empty-root-name
  %+  expect-eq
    !>(`[%empty-name ~])
  !>((check-bundle:sp %spec '' `/src/cfg/txt roots))
::
++  test-bundle-escaping-search-root
  %+  expect-eq
    !>(`[%escape '..' esc-root])
  !>((check-bundle:sp %spec 'spec' `/src/cfg/txt ~[esc-root]))
::
++  test-bundle-config-out-of-root
  ::  the config is read like any other source, so it lives in the roots
  %+  expect-eq
    !>(`[%out-of-root /secrets/cfg/txt])
  !>((check-bundle:sp %spec 'spec' `/secrets/cfg/txt roots))
::
++  test-bundle-config-escapes
  %+  expect-eq
    !>(`[%escape '..' esc-cfg])
  !>((check-bundle:sp %spec 'spec' `esc-cfg roots))
--
