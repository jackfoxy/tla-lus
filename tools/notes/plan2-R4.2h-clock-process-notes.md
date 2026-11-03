# R4.2h: wall clock and process (2026-10-14)

**Status: done -- every surface refused by name.** R2.6.1's rule: a
reproducible run may not observe the wall clock or start a process.

| surface | where | outcome |
|---|---|---|
| `TLCGet("duration")` | SmokeEWD998 `StopAfter` | refused by name (R2.6.1, unchanged) |
| `TLCSet("exit", ..)` | SmokeEWD998 | refused by name (`tlc-module-tlc`, unchanged) |
| `TLC!JavaTime` | -- | excluded (unchanged) |
| `IOUtils!IOExec`, `IOEnvExec`, `IOExecTemplate`, `IOEnvExecTemplate` | SmokeEWD998_SC, SimTokenRing, EWD998_optsSC | NEW: refused by name ("it runs a process") |
| `IOUtils!IOSerialize`/`IODeserialize`/`Serialize`/`Deserialize`, `CSV!CSVWrite`/`CSVWriteRecord`/`CSVRead`/`CSVRecords` | SimTokenRing, SimKnuthYao | NEW: refused by name ("it writes/reads a file") |

Before this, the CommunityModules operators fell through to their dummy TLA+
bodies (`IOExec(c) == CHOOSE r \in [exitValue : Int, ...] : TRUE`), which
evaluates to an unbounded-CHOOSE error at best -- not a refusal that names the
operator. They are registry rows now (`+io-refused`; gen-stdops-tests
`COMMUNITY_OVERRIDES`; registry 42 -> 54).

## Corpus

Only SmokeEWD998 has a manifest model among these (`-simulate`, 100 traces).
It now passes its `TLCGet("config")` ASSUME (R4.2w) and then spends its
whole wall in the INITIAL-state solve: five `RandomSubset(10, ..)` draws make
about 90,000 candidates filtered by `Inv!P0`, all in one unsliced step (R4.3
perf). Past that, `StopAfter` would hit the `duration`/`exit` refusals.
SmokeEWD998_SC, SimKnuthYao, SimTokenRing have no manifest model.

## Tests

job `test-ioexec-refused`; stdops row count 54.
