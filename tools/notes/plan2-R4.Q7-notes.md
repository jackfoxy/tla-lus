# R4.Q7 notes — %config cost: semantic generation, constant definitions (2026-10-27)

Plan `~/FoxyLabs/tla-lus/R4-perf-plan-r3.md`, unit Q7 (H18, "semantic
generation per job"). Target in plan r1: the community-closure `%config`
in 5 s or less. **Not reached:** EWD998ChanID 42 → 18 s.

## Measured (EWD998ChanID, 15 modules incl. the CommunityModules closure;
dojo stepper, ship-only `%bout`)

`%config` 42.3 s = semantic generation 22.6–24.6 s + `check-assumes`
14.3 s + the rest (< 1 s).

Generation, by part: `mod-opdefs` 5.9 s, `l-deps` 5.0 s, root `gen-module`
2.8 s, resolve 1.9 s, `ext-defs` 1.6 s, nested definitions 0.8 s, analyze
0.3 s.

## 1. Each module generated three or four times

The root, `+l-deps`, `+ext-defs`, `+nested-defs` and `+mod-opdefs` each
call `+gen-module` on the same module with the same inputs (its tree, its
`full-ctx`, `ctxs`, `mods`). `+gen-module` is now memoized (`~+`; exact
key). Generation 22.6 → ≈10 s (`l-deps` 5.3 s now holds each module's one
generation plus level checking; `mod-opdefs` 5.9 → 0.3 s, `ext-defs` 1.6 →
0.1 s).

## 2. Constant definitions re-evaluated per dependent

`check-assumes`' 14.3 s was the first `+make-env`, i.e. `+with-cdefs`
evaluating every constant definition: `RingOfNodes` (a CHOOSE over 5^5
functions, ≈5.6 s), then `nat2node` and `node2nat`, each re-running it
(5.9 s each). `+with-cdefs` walked the definitions in map order against the
bare environment, so a definition never saw the values already computed;
the `~+` entries made inside each `mule` do not outlive it.

Now the candidates (`+cdef-cand`) are evaluated dependencies first
(`+cdef-order`/`+cdef-visit`, over `+reach-names`), each with the values
already found in `cdefs`. The values are identical; a definition that fails
stays lazy, and its dependents with it. EWD998ChanID `%config` 29.7 →
18.3 s. Arm `test-cdefs-in-dependency-order` (pin 2/1/1).

## Remaining

- Semantic generation ≈10 s for the community closure: each module's one
  generation and level check, resolve 1.8 s. A cross-job cache would help
  only repeated runs of the same module set (the key is the whole loaded
  set), so it was not done.
- `RingOfNodes` itself, 5.6 s: the per-node evaluator cost (tlc2 evaluates
  it in milliseconds).

## Found: R4.2at (wrong accept)

The first version of the new arm put `C == B + 1` before `B` is defined.
The port ran it; SANY rejects it (`Unknown operator: `A'.`). Recorded as
R4.2at, beside R4.2ar (both under R4.5.1); no corpus spec has it.

## Gates and census

Regression 65/65 (`logs/q7-regress1.txt`); validate, scaffold-gate,
test-examples PASS. Census `logs/census-q7.txt` (16 rows) against
census-q8b: every count unchanged; **EWD998ChanID 46 → 28 s**, MCReachable
40 → 36 s, MCNanoLarge 73 → 64 s. Three rows read slower
(AsyncTerminationDetection 155 → 210 s, MCReachabilityTestAllGraphs
246 → 316 s, MC_sums_even 255 → 314 s); a same-session A/B
(`q7-ab.sh`, `logs/census-q7ab-*.txt`) shows noise: HEAD 209/324 s then
154/247 s, Q7 155/246 s twice -- the first run after a rebuild is slow.
