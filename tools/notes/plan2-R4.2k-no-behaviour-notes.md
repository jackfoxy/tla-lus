# R4.2k: constant-only models through the job kernel (2026-10-12)

**Status: DONE.** A config with NO behaviour spec (neither INIT/NEXT nor a
SPECIFICATION: a module of ASSUMEs, SimpleMath's shape) was refused by
`lib/job` with "no INIT in config", while the console path (R3.0a) checks
the assumptions and completes over zero initial states, as tlc2 does. That
was an entry-point divergence.

- `lib/job` `+do-config`/`+config-run`: both names absent → the console's
  `%nullodn` marker for Init and Next. A `%nullodn` Init (no behaviour, or a
  SPECIFICATION with no initial predicate) gives zero initial states rather
  than being solved.
- Arm `tests/lib/job` `test-no-behaviour-spec`: an ASSUMEs-only module
  completes `%ok` with 0/0/0/0; a false ASSUME is still
  `%violated [%assumption …]`. job 131.

Census of the 7 rows (`census-r42k.txt`): **SimpleMath success**. The other
six now reach their ASSUMEs and fail for other reasons:
- `Print`/`PrintT` → R4.2a (PrintValues, Stones);
- an ASSUME that names another assumption ("a theorem/assumption is not an
  evaluable value"; MisraReachability ×2) → R4.2ah;
- `undefined operator: Vertices` (BlockDagTest) and an enumeration limit
  (TransitiveClosure) → R4.2i.
