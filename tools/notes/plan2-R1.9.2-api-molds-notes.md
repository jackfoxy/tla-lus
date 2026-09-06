# P2-R1.9.2 — mold-by-mold API examples

The row: *"Mold-by-mold API examples for the public wire (`sur/tla-lus.hoon`),
so each noun a consumer sees has a worked example."*

Right, and understated. `sur/tla-lus.hoon` defines **43** public molds.
`api.md` quoted **15** and worked an example for one flow. The other 28 — every
`diagnostic`, `trace-state`, `artifact`, `source-id`, `read-request` a consumer
receives — existed only in the Hoon.

## The consumer-visible bug

`api.md` documented the `%clay` source bundle as

```
[%clay =ship =desk cas=case root=path cfg=(unit path) roots=(list path)]
```

`root` is **`module-name`**, not `path`. That is the headline change of
`api-version` **2**, and `sur/tla-lus.hoon` says so in its own revision note —
*"2 = unit 10 — a %clay bundle's `root` is a module name (it was a path)"*. The
API doc was never updated, so it described version 1 while the agent shipped
version 2. A caller following the doc would send a path and get rejected.

Two more stale claims fixed alongside: agent state quoted as
`state-2 = [%2 jobs=(map req-id job-2)]` (it is `%3`/`job-3`), and a "Current
surface" paragraph saying Clay sources and semantic/level diagnostics "are
documented in `compatibility.md` as they land" — both landed in unit 10 and 4.8
respectively, and the ledger has been closed since R1.8.6.

## The mold reference

New section: all 43 molds in declaration order, grouped (identifiers/positions,
lexical/diagnostic, traces/artifacts, request, result/job), each with its shape
and a value a consumer would actually see. The values come from green test
assertions and the real molds, not from imagination — `[%ok [5 4 0 4 [0 1 1 1]]]`
is what `test-check-ok` asserts, `[%violated [%invariant 'PBad'] [3 3 0 3 [1 1 1
1]]]` what `test-live-violation` asserts, `default-limits:job-lib` is quoted as
the tuple `mar/tla-lus` actually carries.

Plus three reading notes that save a round trip: `%violated` is never collapsed
into `%failed` (a counterexample is a *successful* run that found something);
`run-stats` means different things per mode (in `%simulate`, `generated` is
transitions taken and `distinct`/`queued` stay 0); and `binding.val` is already
rendered text, matching what TLC prints.

## Writing it wrong first is the point

I drafted four of the shapes from memory and then checked them against
`sur/tla-lus.hoon`. Four were wrong:

| mold | drafted | actual |
|---|---|---|
| `trace-state` | `[num label bindings at]` | `[index action=(unit [name at]) bindings]` |
| `step-result` | `%more` / `%done` / `%await` | `%more` / **`%stop`** / `%await` |
| `job` | "id, request, stage, …" | no `id` field at all — the id is the map key |
| `source-id` | `[%inline name=@t]` | `[%inline name=source-name]` |

Every one would have been a new instance of exactly the defect this unit exists
to remove. They were caught by a throwaway field-name cross-check against the
sur bodies, which is worth stating plainly: *the reason the old `root=path` bug
survived is that nobody ever diffed the doc against the mold.*

## What keeps it true

`tools/check-portmap.py` check **(6)**: every `+$` in `sur/tla-lus.hoon` appears
in `api.md`. Verified to bite — renaming `out-degree` in the doc fails the gate
and names the mold. A noun a consumer can receive can no longer ship
undocumented.

It does not check that the *shape* stays right; that would mean parsing Hoon.
What it does guarantee is that a new mold cannot be added silently, which is the
failure mode that actually happened here — `%await` and the `root` change
arrived with api-version 2 and the doc did not move.
