# R4.2c / R4.2g: the run's environment and Java properties (2026-10-13)

**Status: code written; tests pending.** User decision 2026-10-13: two
request fields, both empty by default.

## Wire

`request` gains `env=(map @t @t)` and `props=(map @t @t)` after `promote`
(api.md). The kernel binds them as the records `$env` and `$props` in the
evaluation `vals` (`$`-names, which no source or config can spell); the
console path has neither.

## R4.2c: `IOUtils!IOEnv`

CommunityModules' `IOEnv` is the JVM's `System.getenv()` as a record. The
port answers the request's `env` instead (node-op keyed `[IOUtils IOEnv 0]`,
as tlc2 binds its override). The corpus reads it guarded (`"K" \in DOMAIN
IOEnv`, TestGraphs, EWD998ChanTrace), so the empty default reproduces CI.
`IOExec`/`IOEnvExec` stay refused by name (no process): R4.2h.

## R4.2g: `-D` properties and `\cdot`

- `TLCGet("-D<key>")` is the property, or the key string itself when unset
  (`System.getProperty(k, "-D" + k)`, TLCGetSet.java:485).
- `A \cdot B` with `tlc2.tool.impl.Tool.cdot` = `"true"`, else the pin's
  refusal text:
  - next-state (`+solve-cdot`, Tool.java:1487): the intermediate state starts
    as `s0.copyWith(s1)` (the current values of the variables the successor
    already assigned), A is solved into it, B from each result into the
    successor; the intermediate states count as generated (`rst.xgen`, added
    by `+bfs-step`), as `nss.incrementStatesGenerated` does.
  - predicate (Tool.java:2771): TRUE when some `s0 -A-> t` (from an EMPTY
    successor) has `t -B-> s1`.
- Not reproduced: tlc2 passes the enclosing continuation (`acts`) into BOTH
  halves; the port's solver continues after the composition once. Equal when
  the composition is the last conjunct, as in both corpus models.
- The runner sets the property for models tagged "action composition"
  (MCCRDT, MCReplicatedLog), as CI does.

## Tests

job `test-ioenv-from-request`, `test-tlcget-d-property`,
`test-cdot-with-property` (pin: `java -Dtlc2.tool.impl.Tool.cdot=true`, 58
generated / 30 distinct / depth 7), `test-cdot-refused-without-property`.
