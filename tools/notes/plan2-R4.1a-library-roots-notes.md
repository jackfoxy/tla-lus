# R4.1a: library modules on the search path (+ R4.2r, found on the way)

```text
Sub-unit: R4.1a (2026-10-10)
Status: DONE on the no-vendoring path; the parse census is PARTIAL (53/373)
Pending decisions: vendoring (below); approval of the full parse census
```

## Search roots, as the pin orders them

`%clay` requests from `tools/examples.py` carry the roots `<spec dir>`,
`apalache`, `community`, `tlapm` (CI's classpath order), all on the
`%tla-ex` desk. Nothing is vendored into `%tla-lus`: the library trees are
served only from the Examples desk. A name `tla2tools.jar`'s
StandardModules provide is not staged.

## Fixed: a StandardModule found AFTER the library roots

`SimpleFilenameToStream` at the pin tries the spec directory, then the
StandardModules, then each library root. The `%clay` loader (`lib/job`
`+load-drain`) tried the spec directory and then every root before the
StandardModules, so a library root carrying its own `FiniteSets.tla` or
`Bags.tla` (tlapm's do) shadowed the standard one.

**Port.** On a miss in the spec directory, a StandardModule name is
registered from `stdmods` before any library root is tried. A file in the
spec directory still wins (that is what SANY does too).

New arm: `tests/lib/clay-load` `test-clay-standard-module-before-library-roots`.

## R4.2r (early): `.toolbox` models were refused at submit

Census rows: 7 models whose spec lives under a `<Spec>.toolbox/` directory.
`lib/source-path` `+check-seg` refused every dotted segment, because a dot
is the mark separator in a Clay path's LAST segment only.

**Port.** `+check-seg` takes `dir=?`; a dot is legal in a directory segment
and still refused in a module name or mark. `+check-path` and the
read/write/config references compute directories through `+file-dirs` (all
but the last two segments).

New arms: `tests/lib/source-path` `test-dotted-directory-accepted`,
`test-dotted-mark-refused`.

## Parse census (`tools/examples.py --parse`)

`desk/test-data/blackbox/parse-census.txt`: **53 of 373 modules, 53
agree** (4 of them proof modules), about 24 minutes of the estimated 3
hours. The 6 `.toolbox` modules agree after the R4.2r fix. The rest of the
run needs the user's approval (multi-hour). It was stopped on 2026-10-10
(crash #7, see the tracker); the runner now stops gracefully on SIGTERM.

## Decision owed: vendoring

tlapm's library is BSD-2-Clause; Apalache is Apache-2.0 with a `NOTICE`.
- **No vendoring (current):** the trees are served from `%tla-ex` as search
  roots. No gate or NOTICE change; a user's own desk must carry the modules
  it uses (as with Java, where they come from the classpath).
- **Vendoring:** copy the pinned trees into `%tla-lus` as a built-in root;
  the scaffold gate's provenance clause and a NOTICE change.
