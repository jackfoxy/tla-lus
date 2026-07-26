# Clay fixtures harness (unit 10)

Multi-module TLA+ sources for the inline/Clay differential. Each case is a
directory of the files a `%clay` `source-bundle` would name:

```
<case>/spec.tla       root module (declared `MODULE spec`)
<case>/<name>.tla      referenced user modules, stored under the LOWERCASED
                       module name (`helper.tla`); the declared-name check in
                       lib/modules +resolve still validates the case-sensitive
                       requested name
<case>/cfg.txt         the .cfg body, as `.txt` — the desk has no %cfg mark
                       (a *.cfg through Clay aborts |commit), so cfg is served
                       under a marked extension; the ModelConfig parser reads
                       any non-.tla extension identically
<case>/expect.txt      the differential expectation, keyed to the frozen
                       inline golden it must equal
```

## Cases

- `multi/` — root `spec` EXTENDS user module `helper` (two-module bundle);
  equals inline `test-multi-module-check` → `[%ok [5 4 0 4]]`.
- `single/` — one-module counter; the async loader requests one read and
  closes the graph → `[%ok [3 3 0 3]]`.

## Serving over Clay (unit 10.1+)

The agent reads sources through Clay cards, not `.^` in a stage. On the fake
ship these files are placed on a desk the agent can `%warp`/`%cx` read via the
`%tla` mark (present: `desk/mar/tla.hoon`). The cfg path resolves under a
non-`.tla` mark. The differential harness submits the same files as (a) an
inline bundle and (b) a `%clay` bundle and asserts equal results.

## Rule

Clay must match inline, never the reverse. Never weaken an inline golden to
make a Clay run pass.
