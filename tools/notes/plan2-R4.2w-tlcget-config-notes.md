# R4.2w: `TLCGet` keys in ASSUME (2026-10-14)

The four census rows split in two (R4.2w measurement, 2026-10-12):
- two read `TLCGet("-Dtlc2.tool.impl.Tool.cdot")`: done by R4.2g (the request's
  `props`; MCCRDT, MCReplicatedLog).
- two read `TLCGet("config")`: done here.

## The pin (measured with tla2tools.jar)

`AbstractChecker.createConfig` / the simulator's config record:

| run | record |
|---|---|
| exhaustive (`-seed 0 -fp 0`) | `[install, mode "bfs", deadlock, seed "0", fingerprint "-7992595565342442794", worker 1]` |
| `-dfid` | the same, mode "bfs" (seed: the unprinted random one) |
| `-simulate num=3` | `[install, mode "simulate", deadlock, seed, worker 1, traces 3, depth 100, aril "0", sched "random"]` |
| `-generate num=3 -depth 4` | as simulate, mode "generate", depth 4 |

`seed` and `fingerprint` are strings (`Long.toString`); `deadlock` is the
effective check (request toggle AND the cfg's CHECK_DEADLOCK).

## Port

`+run-config:job` builds the record from the request's run mode; the kernel
binds it as `$config` in the evaluation `vals`; `+eval-tlc-get` answers
`TLCGet("config")` from it. The console path has no record and keeps the
refusal by name. `install` names this engine (`"%tla-lus"`) where the pin has
its jar path: approved difference (`tlc-module-tlc`). DFID's seed is the
port's 0, where tlc2's is unprinted and random (the standing seed-default
difference).

## Corpus readers

DieHardest (`mode = "bfs" /\ worker = 1`), SmokeEWD998 (`mode \in
{"generate", "simulate"}`), SimKnuthYao, SimTokenRing and the EWD998 `_opts`
modules (`mode = "generate"`, `depth = -1` -- tlc2's unbounded `-depth`,
which this wire cannot express: those models are not in the manifest).

## Tests

job `test-tlcget-config-bfs`, `test-tlcget-config-generate`.
