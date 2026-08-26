/-  *tla-lus
/+  *test
/=  action-mark  /mar/tla-lus/action
/=  update-mark  /mar/tla-lus/update
|%
  ::  Mark Round-Trips For All Public Nouns
  ::
  ::  Every action/update variant must survive grow -> grab unchanged;
  ::  malformed nouns must crash the grab clam (poke nack), never coerce
  ::  silently into a different value.
  ::
++  grab-action
  |=  raw=*
  ^-  action
  (noun:grab:~(. action-mark *action) raw)
::
++  grab-update
  |=  raw=*
  ^-  update
  (noun:grab:~(. update-mark *update) raw)
::
++  full-diag
  ^-  diagnostic
  :*  [%sany 4.802]
      %warning
      %lint
      'field name clash'
      `['LintRecordClash' [3 7] [3 9]]
      ~[['LintRecordClash' [2 1] [2 9]]]
  ==
::
++  clay-request
  ^-  request
  ::  `check-opts` is [translate view difftrace continue cfg mode]; the middle
  ::  three landed in R2.4.2/R2.4.3 and this literal never grew them
  :*  [%check [& | | | `'MC.cfg' | [%simulate 42 5 100 |]]]
      :*  %clay
          ~zod
          %specs
          da+~2026.7.12
          'DieHard'
          `/die-hard/txt
          ~[/lib]
      ==
      default-limits
      ::  `write` (R2.2): a terminal run's Clay write TARGET, not a boolean --
      ::  this literal was `&` when the field was `allow-write=?`
      `[%specs /out/dump]
      ~
  ==
::
++  default-limits
  ^-  limits
  ::  the trailing field is `max-set-size` (tlc2's `-maxSetSize` default,
  ::  R2.4.1). This literal went stale when that field landed and this shard
  ::  has not built since; found by R2.4.6, which is the first increment to
  ::  run `/tests/mar` again
  [1.000.000 64 100.000 1.000 ~m10 1.000.000 1.000.000]
::
++  inline-request
  ^-  request
  :*  [%translate [%wf & &]]
      [%inline 'Demo' (malt ~[['Demo' '====']]) `'INIT Init']
      default-limits
      ~  ~
  ==
::
++  actions
  ^-  (list action)
  :~  [%submit ~.j1 inline-request]
      [%submit ~.j2 clay-request]
      [%cancel ~.j1]
      [%delete-result ~.j1]
  ==
::
++  updates
  ^-  (list update)
  :~  [%ack ~.j1]
      [%rejected ~.j1 'duplicate active id']
      [%deleted ~.j1]
      [%job ~.j1 [%stage %explore]]
      [%job ~.j1 [%progress 3 13]]
      [%job ~.j1 [%diagnostic full-diag]]
      [%job ~.j1 [%result [%ok [100 80 0 12 [0 1 2 3]]]]]
      [%job ~.j1 [%result [%violated [%invariant 'Inv' %.n] [10 8 0 4 [0 1 1 2]]]]]
      [%job ~.j1 [%result [%limited %states [75 60 0 9 [0 1 1 1]]]]]
      [%job ~.j1 [%result [%cancelled ~]]]
      [%job ~.j1 [%result [%failed 'evaluation error']]]
  ==
::
++  test-action-round-trips
  %+  roll  actions
  |=  [a=action acc=tang]
  %+  weld  acc
  ;:  weld
    (expect-eq !>(a) !>(noun:grow:~(. action-mark a)))
    (expect-eq !>(a) !>((grab-action `*`a)))
  ==
::
++  test-update-round-trips
  %+  roll  updates
  |=  [u=update acc=tang]
  %+  weld  acc
  ;:  weld
    (expect-eq !>(u) !>(noun:grow:~(. update-mark u)))
    (expect-eq !>(u) !>((grab-update `*`u)))
  ==
::
++  test-action-malformed-tag
  (expect-fail |.((grab-action [%bogus ~.j1])))
::
++  test-action-malformed-payload
  ::  %submit with a bare atom where the request cell belongs
  (expect-fail |.((grab-action [%submit ~.j1 42])))
::
++  test-update-malformed-event
  (expect-fail |.((grab-update [%job ~.j1 [%nonsense 1]])))
::
++  test-update-malformed-result
  (expect-fail |.((grab-update [%job ~.j1 [%result [%sideways ~]]])))
--
