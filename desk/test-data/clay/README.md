# Clay fixtures harness (unit 10)

Multi-module TLA+ sources for the inline/Clay differential. Each case is a
directory of the files a `%clay` `source-bundle` would name:

```
<case>/spec.tla       root module (declared `MODULE spec`)
<case>/<name>.tla      referenced user modules, stored under the LOWERCASED
                       module name (`helper.tla`); the declared-name check in
                       lib/modules +resolve still validates the case-sensitive
                       requested name
<case>/cfg.txt         the .cfg body, as `.txt`. Written before the desk had
                       a `%cfg` mark (`mar/cfg.hoon`, R4.0e); `.cfg` now works
                       too, and the ModelConfig parser reads any non-.tla
                       extension identically
<case>/expect.txt      the differential expectation, keyed to the frozen
                       inline golden it must equal
```

## Cases

- `multi/` — root `spec` EXTENDS user module `helper` (two-module bundle);
  equals inline `test-multi-module-check` → `[%ok [5 4 0 4]]`.
- `single/` — one-module counter; the async loader requests one read and
  closes the graph → `[%ok [4 3 0 3]]` (measured in 10.1; the 10.0 draft
  said `[3 3 0 3]`, which undercounted the initial state).

## Serving over Clay (unit 10.1)

The agent reads sources through Clay cards, not `.^` in a stage. These files
are committed to the `%tla-lus` desk itself, so a fake ship can serve them to
the agent over `%warp`/`%writ` (`.tla` via the `%tla` mark, `cfg.txt` via
`%txt`). A live run:

```
:tla-lus &tla-lus-action [%submit ~.c1 [[%check [| ~ [%exhaustive & 0]]]
  [%clay our %tla-lus [%da now] 'spec'
    [~ /test-data/clay/multi/cfg/txt] ~[/test-data/clay/multi]]
  [1.000.000 64 100.000 1.000 ~m10 1.000.000] |]]
+tla-lus!tla-lus/status ~.c1
```

The automated differential is `tests/lib/clay-load.hoon`, which mirrors these
texts and plays the agent from an in-test file system: it runs the same
sources as (a) an inline bundle and (b) a `%clay` bundle and asserts equal
results, so the Clay path is covered without a live Clay.

## Rule

Clay must match inline, never the reverse. Never weaken an inline golden to
make a Clay run pass.
