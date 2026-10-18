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
