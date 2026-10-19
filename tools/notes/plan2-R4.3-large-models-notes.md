# R4.3 large models (2026-10-17 ..)

Plan r14, row R4.3: smoke parity for the large models, then completion where
feasible. `models.json` holds 31 large models (the plan's 40 counts the
excluded ones too).

## Part 1: the rows that reached no state

Five large models reached 0 states in the R4.2 censuses. They fail under any
smoke budget, so they came first. Each was probed with
`tla-zod-tools/probe2.py` (stage changes with times), and the slow slice was
found with `tla-zod-tools/gen/zstep` (ship-only: steps a `%tla-ex` job slice
by slice in the dojo, answers its Clay reads by scry, `~>  %bout` per slice)
under `guarded.sh` (one C-c past an RSS cap).

| model | cause | fix | now |
|---|---|---|---|
| PaxosCommit | (none left) | the R4.2 fixes | 2,735 distinct in 90 s |
| ElevatorLivenessLarge | `+dnf-conj` distributed in O(rows²): every factor walked all 8,192 rows (10 SF conjuncts x 8 negated PROPERTY parts) per block | rows x factors cross product in the same odometer order (`+cross-rows`, `+cons-all`); `+add-to-group` conses (was a snoc per pem) | %config > 150 s → 3,052 distinct in 150 s |
| TestMCReachability | the %config slice EXHAUSTED THE LOOM (`bail: meme`; the agent event was rolled back, so the job sat at stage `parse` and later ended `limited time`). `+user-op` (lib/temporal) followed the unnamed INSTANCE's `done <- done` call-by-name binding back to `done` forever | `+self-ref:ne` guard, as node-eval's lookups have had since R4.2n | 4,732 distinct in 120 s |
| MultiPaxos_MC | `+with-cdefs` evaluated every constant definition eagerly, incl. the unused `NodeStates` (~3 x 10^9 records). tlc2's `processConstantDefns` caches such a value as a lazy SetOfRcdsValue | `+lazy-set`: a body tlc2 keeps lazy (SUBSET, `\X`, `[D -> R]`, `[a : S]`; `\cup`/`\cap`/`\`/UNION by their operands) is not cached; `+eval-sdef`'s `~+` memo now covers constant-level definitions with the states cut from the key | 1,125 distinct in 150 s |
| MCReachable | (the same cause as MultiPaxos_MC, plus slow) | — | SUCCESS 11/8/6 = pin, 320 s (tlc2: 100 s) |

Measured for the cdefs fix (console `check:ck`): an unused
`NS == [a : 1..3, b : [1..3 -> [c : 1..n]]]` cost 12 s at n = 12 (5,184
records) and 565 s at n = 40 (192,000); after it, 3 s. R4.P3's own case did
not regress: SimplifiedFastPaxos 199 distinct in 120 s (before: 901 in 911 s).

## R4.2ap (TestGraphs with its PROPERTIES): closed

The TestMCReachability fix removed TestGraphs' loom exhaustion too, and
exposed a WRONG ANSWER behind it: `Refinement == MCR!Spec` reported the
implied action `[][Next]_vars` (MCReachability line 144) violated at depth
5, where the pin succeeds (2,790 / 2,590 / 51).

Localized on graph 1 (pin: 26 / 24 / 14) by splitting `MCR!Explore` into
its conjuncts as separate implied-action properties (a probe copy under
`%tla-ex specifications/zprobe/tgr/`): only `T' = T \cup {<<s, t>> : t \in
succs}` failed. `MCR == INSTANCE MCReachability WITH T <- SeqToSet(T) \cup
{<<state, succ>> : succ \in successors}, successors <- LET ... IN ...`: the
`successors` inside T's substitution is TLCMC's variable, but the port read
the substitution in the instance body's env, where its sibling
`successors <- LET ...` was still bound. tlc2 resolves names by SANY node,
so the capture cannot happen there.

Fix: `eenv` gains `pout`, the scope each call-by-name INSTANCE substitution
was written in (`+clo-of`: the instancer's `psub`, `vals` and its own
closures, recorded by `+bind-substs` with the expression it belongs to).
`+outer-of` restores that scope when the binding is still that expression,
else drops the name as before. Two levels of molds (`clo`, `clo1`): a
recursive `clo` looped zuse-408's mold compiler (`/lib/node-eval/hoon` frame
flood in the `|commit`). `+sdef-env` cuts `pout` to the reached names, as it
cuts `vals`/`psub`, so R4.P11's memo keys stay small.

TestGraphs.cfg (graph 7, Termination + Live + Refinement): 2,790 / 2,590 /
51 = pin (419 s in the dojo stepper).

Not done: lib/temporal's `+substin-of` (liveness leaves) binds the same way
without closures; no corpus model is known to need it.

## Tests

job `test-live-instance-self-subst` (unnamed INSTANCE, `<>(d \/ x = 5)`;
pin 3/3/3) and `test-subst-reads-instancer-scope` (`I == INSTANCE M WITH a
<- x, b <- a`, `[][I!Step]_<<x, a>>`; pin 3/3/3; bites: with `+outer-of`'s
closure disabled the port reports `Prop` violated). job 150 green.
The DNF rewrite keeps tlc2's order; the liveness/tableau shards check it.

## Part 2: the smoke census (2026-10-18)

Decision (the user, 2026-10-18): **smoke-budget = 1,000 distinct states**
(option A): a large model passes clause 3 when it reaches 1,000 distinct, or
completes, with no error, refusal or `%limited` other than states. The runner
gained `--size small|large` (test-examples checks it). Census:
`tools/examples.py --run --size large --include-timed-out --budget 1000
--wall 900` → `tla-zod-tools/logs/census-r43-smoke.txt` (31 rows).

26/31 passed as run. Then:

| model | cause | fix | now |
|---|---|---|---|
| LeastCircularSubstringMedium, ElevatorSafetyLarge | `+bfs-step` checked the state bound only after EVERY initial state was registered (6,400 and 198,656 of them) | the bound is checked before each registration | `limited states` in 201 s / 99 s |
| MCEWD687a (838 at the wall) | `TreeWithRoot`'s `G!IsTreeWithRoot` (a LET INSTANCE of Graphs) evaluates `SimplePath(G)`, hence `SeqOf`, once per node with the same `G`: 3.4 s per call | `+eval-app`: an application of a module-level constant/state-level operator goes through `+eval-sdef`'s `~+` memo; `+sdef-env` drops from the key the names BOUND in the reach (`+bound-reach`: binders, LET definitions and their formals, reached operators' formals; the applied operator's own formals kept) and cuts the states to the reached variables when no call-by-name binding is kept | 0.84 s per call; 1,003 distinct in 417 s |
| CoffeeCan3000Beans (0 at the wall) | every one of its ~4.5 M states is initial; the init solve materialized `{c \in Can : ...}` in one slice | `ilim` (eenv): under a bound, an init `x \in {y \in S : P}` takes bound + 1 elements, streaming S (`+filter-lim`); `trunc` (rst) records a cut, and the kernel re-solves unbounded if the bounded set yields fewer distinct states than the bound | `limited states` 1,001 in 10.4 s |

**30/31.** Left: MCInnerSerial. tlc2 itself COMPLETES at 195 distinct
(6,181 generated) in 12 min 34 s, so a 1,000-state budget is unreachable and
the smoke needs completion. One state expansion costs 16.3 s here against
about 3.9 s at the pin (`UpdateOpOrder`: `opOrder' \in SUBSET(opId' \X
opId')` /\ `Serializable'`), about 53 min to complete. The `+bound-reach`
key change did not move it (the cost is the SUBSET enumeration itself).

Also measured: the %config floor for a spec that loads the community
closure (IOUtils/SequencesExt/Graphs...) is semantic generation, ~22 s
(TestGraphs, TestMCReachability, the zprobe modules).

A note on the measurement helpers: interrupts inside `mule` (every job
slice, and dojo generators) print no frames; `~>  %bout.[0 %label]` timers in
ship-only copies and the stepping generator (`gen/zstep`, now with a budget
argument: one slice = one state expansion at budget 1) were what localized
these.

Tests: job `test-limited-states-in-inits` (bound 10 over 51 initial states:
`limited states` at 11), `test-init-filter-bounded` (bound 5: 6 generated, 6
distinct, not the filter's 26), `test-init-filter-bound-resolved` (`x \in
{even} /\ x > 40` under bound 5: the bounded pass finds none, the re-solve
finds 5, success).

## Part 3: the loom rows carried from R4.2 (R4.2aj, R4.2al)

**R4.2al EWD998ChanID: SUCCESS 15 / 14 / 14 = pin (133 s).** The loom
blow-up was gone after part 1; behind it the run failed `Attempted to apply
function with integer domain to the non-integer argument n1` where the pin
succeeds. Localized by bisecting the config (only `EWD998ChanSpec`, and in it
the implied action `[][EWD998Chan!Next]_vars`) and a ship-only print at the
failing application. Three nested-INSTANCE scope bugs, each with a repro
against the pin:

1. `+bare-self`: EWD998Chan's nested `INSTANCE EWD998` substitutes `active <-
   active`, which names EWD998Chan's `active` (itself `Node2Nat(active)`). The
   self-reference guard read the root variable; a self-reference with a
   recorded closure is now read in that closure's scope.
2. `+in-force`: the port wraps every instance member in its own `WITH` and in
   each enclosing instance's, so a sibling call (`EWD998Chan!Next` calling
   `System`) re-bound the substitutions from INSIDE the instance; its closure
   was the instance's own scope and `Node2Nat` was applied twice. tlc2 binds
   them once. A binding already in force at any level of the scope chain
   (current, then one and two closures out) is kept. Checking only the
   innermost level broke TestGraphs (TestGraphs' outer `S <- S` re-applied
   inside TLCMC's `MCR` over `S <- SeqToSet(S)`: `Len` of a set), caught by
   the runner re-check.
3. `+reads-state` (PRE-EXISTING: the R4.2af build fails the same way): a
   `WITH` expression carries level 0 in the graph, so `x <- x * 2` and `y <-
   Dbl(x)` were judged constant and evaluated once, at the current state; an
   implied action through the instance then read the wrong value (`x`) or
   none (`y'`). Bound by name when it reaches a declared variable or a
   call-by-name binding (a superset, so a misjudgment only binds lazily).

lib/temporal's `+substin-of` now binds through `+bind-substs:ne` (same lazy
rule, plus operator-valued substitutions and closures), and the liveness
leaves (`le-act`/`le-state`/`le-enabled`) carry `pout`, as does `actx`
(`lo`). Tests: job `test-subst-state-expr-lazy`, `test-subst-state-op-lazy`,
`test-subst-sibling-member` (all pin 4/4/4; the last bites with `+in-force`
disabled, as does EWD998ChanID at 2 nodes).

**R4.2aj btree:** no loom exhaustion now (guarded dojo stepper, full config:
878 distinct after 8 slices of 3-22 s, RSS flat ~150 MB). Throughput-bound
(374,727 distinct; tlc2 15 s): it stays on `timed-out.json`, note updated.

`timed-out.json`: TestGraphs and EWD998ChanID removed (10 → 8 entries).
