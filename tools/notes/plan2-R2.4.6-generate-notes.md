# R2.4.6 — `-generate`: probabilistic simulation

The row: *"`-generate` — probabilistic simulation. `-simulate` with
`Tool.probabilistic` set. A different successor-pick engine, not a flag; sized
accordingly. Also surfaces `stats=basic/full`, which needs only a toggle since
R1.7 built the table."* Sized M/med, grounded on `op-check-simulate` and
`tlc-util-rng`.

Measured first, per the standing rule. The measurement found **two live parity
defects in the port's `-simulate`**, one of which *blocks* `-generate`, and
corrected two of the row's own claims.

## 1. `-generate` is unreachable on the shapes you would first reach for

`-generate` sets `tlc2.tool.impl.Tool.probabilistic`, which guards five sites in
`Tool.java`: `OPCODE_dl`/`lor` (`:1200`), `OPCODE_be` (`:1223`), `OPCODE_case`
(`:1323`, throws), `OPCODE_se` (`:1393`) and `OPCODE_in` (`:1441`). Every one of
them is inside **`getNextStates`**.

But `Tool.getActions` runs *before* `getNextStates` ever sees the relation, and
it consumes exactly the two constructs you would test with first:

| spec | `-simulate` vs `-generate` |
|---|---|
| `Next == A \/ B` | **byte-identical** |
| `Next == \E n \in 1..5 : x' = (x + n) % 100` | **byte-identical** |
| `Next == /\ y' = y + 1 /\ \E n \in 1..5 : x' = …` | **differs** — 135 states generated vs 32, different trace |

A top-level `\/` is split into one action per disjunct (`getActions` OPCODE_dl),
and a top-level `\E` is **enumerated into one action per element**
(`getActionsAppl` OPCODE_be). Each resulting action is deterministic, so the
probabilistic branches are dead. The flag only bites when the nondeterminism sits
*below* the decomposition boundary — under a conjunction, or in an `x' \in S`
(which `getActions` never decomposes).

## 2. R1.5.12's approved difference is observable after all — and it is a defect

`+get-actions` kept **one** action for `\E i \in S : body` where tlc2 makes
**N**. R1.5.12 recorded that as harmless: *"One-vs-N is unobservable here: every
per-element action carries this same label, the successor stream is already
enumerated in element order by `+solve-exists`, and the coverage counts are a
documented approved difference."*

That reasoning is about *labels and coverage*. **In simulation the action COUNT
is arithmetic.** `SimulationWorker` draws `floor(nextDouble() * actions.length)`
to pick an action and `floor(nextDouble() * nextStates.size())` to pick a
successor. N actions of one successor each and one action of N successors consume
the *same number of draws* but feed them to *different divisors*, so the walks
diverge from the first step.

Measured, `Next == \E n \in 1..3 : x' = x + n`, `INVARIANT x < 20`,
`-simulate num=1 -workers 1 -depth 40`:

| seed | tlc2 | port (before) |
|---|---|---|
| 1 | `0 3 4 5 6 8 9 11 12 15 16 17 18 21` | `0 3 5 6 8 11 14 15 18 20` |
| 2 | `0 1 2 5 8 11 13 16 18 21` | `0 3 4 7 8 10 11 14 16 18 20` |
| 3 | `0 2 3 6 7 8 10 13 14 17 18 20` | `0 3 5 7 8 11 14 16 18 20` |

and `The number of states generated:` **14** vs **25**.

The corpus could not see it: `gen-sim-tests.py` has no `\E` case at all (its
`nondet` case is `x' \in S`, which tlc2 does not decompose either, so both sides
have one action — that case has always agreed).

**Fixed.** `+get-actions` now ports `getActionsAppl` OPCODE_be properly: it
evaluates the bound against the constant-only environment (tlc2 uses
`TLCState.Empty`) and recurses into `args[0]` once per element, carrying the
binding on the action. The action type grew a context — `+$ act
[name body ctx]` — and `+act-env` merges it when the action is solved.

The **fallback is tlc2's own**, which is what makes the change safe: TLC wraps
the enumeration in a `try` and, on an empty domain (`Enum.isDone()`) or any
throw — a state-dependent bound, a non-enumerable bound — emits exactly the one
whole-quantifier action this arm used to return unconditionally. So every spec
that worked before still decomposes the same way unless its bound is
constant-level and enumerable.

## 3. The violating step's generated states were dropped

Second defect, independent of the first, and visible on a case whose *trace* is
byte-exact: `/\ y' = y + 1 /\ \E n \in 1..5 : x' = (x + n) % 100`, seed 1 —
tlc2 reports **135** states generated, the port reported **131**.

`sim-nexts` returned `[%viol name st]` with no count, and `sim-step`'s `%viol`
branch never added one, so the whole violating action invocation vanished from
the total. tlc2 calls `collectPreSuccessor` in `addElement` **before** the
invariant check (`SimulationWorker.java:579`), so every successor generated up to
*and including* the violating one is counted. Fixed; `%viol` now carries `ngen`.

Also untested by construction: `gen-sim-stats-tests.py` says in its own docstring
that its corpus is "completing, non-deadlocking, **non-violating**" specs.

## 4. `stats=basic/full` is not a statistics toggle

The row: *"Also surfaces `stats=basic/full`, which needs only a toggle since R1.7
built the table."*

Measured. `stats=basic` / `stats=full` do not print anything. They write a
**Graphviz DOT action-flow graph** to `<RootName>_actions.dot` on the filesystem
(`Simulator.writeActionFlowGraph`), an action-to-action transition matrix whose
edge weights are `log10(log10(count+1))` rounded to two places, with unseen arcs
drawn dotted-green. `full` clusters the vertices by `Action.con` and keys the
matrix by action id; `basic` collapses actions sharing a `getDefinition()`
location first, so the two files differ in both structure and weights.

R1.7 built the *trace-length / states-generated* statistics. That is a different
artifact. `stats=` is a file-output side channel, and on this wire it would be an
artifact (or the R2.2 Clay write-back), not a toggle.

## 5. The rest of the probabilistic mechanism, measured

- **CASE aborts.** `-generate` on a `CASE` below the decomposition boundary
  throws `UnsupportedOperationException: Probabilistic evaluation of next-state
  relation not implemented for CASE yet.` — exit with `TLC threw an unexpected
  exception`, 1 state generated. A port must refuse, not silently pick a branch.
- **Two RNGs, and the obvious guess is wrong.** The `\/` branch draws from
  `TLCGlobals.simulator.getRNG()`, which returns **the worker's own `localRng`**
  when called on a `SimulationWorker` thread (`Simulator.java:896`) — the state
  the port already carries as `sim-cursor.s`. The `\E` / `\in` / `\subseteq`
  branches instead draw from `RandomEnumerableValues.get()`, a *separate*
  `java.util.Random` seeded with `-seed` (`TLC.java:1400`). So the port needs
  exactly one **new** RNG state, not two, and not on the path you would guess.
- **`Ordering.RANDOMIZED` is an LCG, not a shuffle.**
  `EnumerableValue.SubsetEnumerator` draws `random.nextInt(n)` for its seed and
  `RandomGenerator.nextPrime(random)` for its increment, then walks
  `index = (a*index + c) % m` rejecting `index >= n`, where `(m, a)` come from
  `computeOptimalMandA(n)` — bump `n` to at least 9, then to the first value that
  is not divisible by 4 and not squarefree, and set `a` = product of its distinct
  prime factors, plus 1. `lib/rng` has neither `nextInt(bound)` nor prime
  factorization.
- **`\in` and `\subseteq` double-count.** Their probabilistic branches have **no
  early return after the loop** (unlike `dl` and `be`), so when the randomized
  pass yields no surviving successor the deterministic enumeration runs again over
  the same elements — and `collectPreSuccessor` counts them twice. Measured on a
  spec whose CONSTRAINT drops every successor of the last state: `-generate`
  reports 8 states generated where the arithmetic without the fall-through gives
  6 (1 init + 3 walked + 2×2 at the deadlocked step).
- `-generate` is reproducible: same seed, same result across runs; different
  seeds differ.
- A `[]P` box-state PROPERTY runs under `-generate` (it goes down the invariant
  path), so the port's box-state route needs no separate treatment.

## 6. Sizing

The row said M. Measured, `-generate` proper is **not** M, and the reason is
structural rather than incidental: tlc2's `getNextStates` is **CPS** — a
`ActionItemList` continuation threaded through every opcode — and "return as soon
as a successor is accepted" is a property of that shape. The port's `+solve`
returns a *list* per node and threads a list of partial states through a
conjunction, which cannot stop early across conjuncts: `/\ x' \in S /\ y' \in T`
must stop at the first accepted `(s, t)` pair, and only a continuation can
express that. A faithful port therefore needs a second solver family in CPS form
(~12 arms mirroring `+solve`), the randomized enumerators above, the
`SubsetEnumerator` LCG, `nextInt(bound)`, prime factorization, a `%generate`
`check-mode` variant, and the CASE refusal.

Revised size: **L / med**. Sequenced after the two defects above, which are
`op-check-simulate` parity in their own right and which `-generate` would
otherwise bake in.

## 7. On the wire

`check-mode` gained `generate=?` on the `%simulate` variant rather than a
variant of its own. tlc2 spells it that way too — `-simulate` and `-generate`
both set `RunMode.SIMULATE`, and the flag is a system property, not a mode — so
every rule that keys on simulation (the stage plan, the `-difftrace` refusal, the
ALIAS refusal) applies unchanged to both, which a separate variant would have
made me restate three times.

**The CASE refusal needed a channel before the mode could ship.** tlc2 aborts on
a `CASE` in probabilistic position: exit 255, no model checking performed. An
engine that merely dropped the offending action would have reported a completed
simulation over whatever actions remain, where tlc2 produced no result at all.
So `sim-result` grew `err=(unit @t)`, `step-res` an `%err` arm that ABORTS the
run rather than retrying the next action, and `do-sim` checks it **before**
`viol`, mapping it to `%failed`. The partial statistics are deliberately not
reported as an `%ok`.

Evidence is a **matched pair through the job kernel** — one bundle, one seed, one
field different:

| | states generated | verdict |
|---|---|---|
| `generate=\|` | 43 | `[%invariant 'Inv']` |
| `generate=&` | 13 | `[%invariant 'Inv']` |

both tlc2's exact numbers at `num=1 -workers 1 -seed 1 -depth 20`. Same verdict
KIND, different arithmetic, so the field is proven to reach the engine rather
than be read and ignored. A second pair pins the refusal: the CASE spec is
`%failed` under `-generate` and reaches a `%violated` verdict under plain
`-simulate`, which makes the refusal a property of the probabilistic engine and
not of the spec.

## 8. A shard that had not built since R2.4.1

Running `/tests/mar` — which this unit touched because it carries a `check-mode`
literal — found it **failing to build**, and not because of anything R2.4.6 did.
Three literals in `desk/tests/mar/tla-lus.hoon` had gone stale as the wire grew
and nothing had rebuilt the file since:

- `limits` was missing `max-set-size` (R2.4.1)
- `request.write` was still the boolean `allow-write` (R2.2)
- `check-opts` was missing `view` / `difftrace` / `continue` (R2.4.2, R2.4.3)

A `FAILED /tests/mar/tla-lus/hoon (build)` is a FILE failure, not an arm failure,
so a shard-scoped run of any other path reports `ok=%.y` and says nothing about
it. The increments that added those fields each ran only their touched shards —
correct for their budget, and exactly the hole that lets a build break sit for
five units. Fixed here; `/tests/mar` is green again.

## Evidence

Ship shards, all `ok=%.y`: `sim-diff` (82, was 33), `generate-diff` (18, new),
`sim`, `sim-stats`, `sim-live`, `rng`, `mc`, `trace`, `spec-decomp`,
`inv-constraints`, `safety-gen`, `job`, `liveness-lasso`.

`tools/validate.py --check`: **tier-1 differential integrity OK — every golden
reproduces byte-identically from the pin**, including the two generators this
unit touched. `tools/check-parity.py`: 131 rows, 118 terminal, 13 owed.
`tools/check-portmap.py`: coherent.

A process note worth keeping: an intermediate run reported `DRIFT: sim-diff.hoon`
and it was **not** drift — two `validate.py` runs were in flight at once, racing
over the same generated files, so one took its `before` snapshot of a file the
other was mid-write. `validate.py` compares a snapshot taken at the START of its
own run against the regenerated tree, so a second concurrent run makes it lie.
Run it alone.
