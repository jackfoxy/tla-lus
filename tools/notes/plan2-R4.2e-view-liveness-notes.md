# R4.2e: VIEW with a temporal PROPERTY (2026-10-13)

**Status: code done; regression and gates still to run on the fresh pier.**

## Why the combination was refused

Before this change, `+config-run` and `+check` refused VIEW together with a
temporal PROPERTY (R2.3.1). The liveness module recomputed plain
`state-fp`s (`+succ-fps`, `+trace-graph`). It then looked them up in a graph
keyed by the search's identity: the orbit fingerprint, or the view's
fingerprint. Under a VIEW the two disagree.

## Fix: one identity key for the search and the liveness graph

- `eenv` gains `idk=[perms=(list (map @t @t)) view=(unit sem:sm)]`, set by
  `+with-idk:node-eval`. Every liveness env gets it: the `%live` check
  phase in `lib/job`, the five liveness sites in `lib/check`, the post-error
  liveness pass, and the find-lasso path.
- `+live-key:liveness`: canonicalize under the symmetry permutations, then
  fingerprint the VIEW's value. That is tlc2's order: the view is evaluated on
  `minVals`. A view that fails to evaluate falls back to the plain
  fingerprint, as the safety search does.
- `+succ-fps` and `+trace-graph` (which now takes the env) key states with
  `+live-key`.
- The VIEW refusals are removed from `lib/job` and `lib/check`.

## Tests

- mc `live-view` (pin golden): 5 generated, 4 distinct, and the property
  holds. mc 134 → 135.
- Green on the current build: mc 135, symmetry 3, liveness-verdict 14,
  liveness-lasso 10, liveness-product 17, liveness-accept 7,
  liveness-message 10, sim-live 10, job 131.

## Census (`--wall 300`)

| model | now | manifest |
|---|---|---|
| FiniteMonotonic/MCDistributedReplicatedLog | liveness failure (271 generated, 37 distinct) | liveness failure (agree; no counts in the manifest) |
| ewd998/EWD998ChanID | ship crash: loom exhausted before any state | → R4.2al; added to `timed-out.json` |

## R4.2al (new): EWD998ChanID exhausts the loom

This model was hidden behind the refusal. I localized it with probes on a
3-node copy (`specifications/zprobe/` in `%tla-ex`; the files survive in
`/mnt/mars/piers/tla-zod-corrupt-2026-10-13/tla-ex/specifications/zprobe/`):

- `q.tla`: constant definitions only (`RingOfNodes`, `nat2node`,
  `node2nat`). Success, 3.6 s.
- `q2.tla`: plus all the variables and `Init`. Success, 12.4 s.
- `ewd998chanid.tla` with only `SPECIFICATION Spec` (`pb.cfg`): 0 states
  in 120 s.
- `q3.tla`: `q2` plus `Node2Nat`, `MapSeq`, `EWD998ChanInbox` and
  `EWD998Chan == INSTANCE EWD998Chan WITH …`. Loom exhausted. This crash
  corrupted the pier's snapshot, and the user chose a fresh pier.

So the instance closure is the cause. EWD998Chan itself nests
`INSTANCE EWD998`, which nests `TD == INSTANCE AsyncTerminationDetection`,
with state-level substitutions at each level. The first crash's trace ends in
`+with-cdefs` (`node-eval.hoon` ~2742, the `mule`d `eval-rs`). The next step
is an RSS-guarded probe at the smallest size that shows the growth. Before
re-running the census, check the instance-wrapped definitions' `lvl` and
`+with-cdefs`'s candidate set.
