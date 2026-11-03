# R4.2d: SYMMETRY with a temporal PROPERTY, and what it found (2026-10-13)

**Status: code done; regression running.**

The six Examples models with SYMMETRY and a PROPERTY: MCKVsnap (large),
Paxos/MCPaxos, Paxos/MCVoting, SimplifiedFastPaxos/FastPaxos, braf, and
PaxosHowToWinATuringAward/MCVoting. None of the failures was symmetry.

## A WRONG ANSWER: refinement through a same-name substitution

Paxos/MCVoting reported a liveness (implied-action) failure where tlc2
succeeds; so did the TuringAward copy. `PROPERTY ConsensusSpecBar` is
`C!Spec` with `C == INSTANCE Consensus`, whose implicit substitution is
`chosen <- chosen`, and Voting's `chosen` is a DEFINITION. The same failure
reproduces with no SYMMETRY.

Cause (`+bind-substs`): a state-level substitution was bound by name in
`psub` AND by its current-state value in `vals`. `+eval-user` answers a
zero-arity name from `vals` first (R4.2u's config value for a definition),
so the outer `chosen`, reached through the inner variable, read the
CURRENT value even under a prime: `chosen' # {}` was always false. A
renamed definition (`WITH chosen <- ch`) did not collide and was right.
Fix: a state-level substitution is bound by name only. mc
`inst-subst-samename` (pin golden). Both MCVoting models now agree.

## Generated counts: three solver differences

With the wrong answer fixed, MCVoting's distinct and depth matched but
`generated` did not (no SYMMETRY: 2,836 against 3,124). Measured shape by
shape against the pin (one variable, `x < 2 /\ ... /\ x' = x + 1`):

| shape | pin | port before |
|---|---|---|
| `x' = x + 1 /\ \E q \in {1,2,3} : q > 0` | 3 | 7 |
| `x' = x + 1 /\ (TRUE \/ TRUE)` | 3 | 5 |
| `(TRUE => \E a \in {1,2} : a > 0) /\ x' = x + 1` | 5 | 3 |
| `Ok2 /\ x' = x + 1`, `Ok2 == \E c \in {1,2} : c > 0` | 3 | 5 |

1. **All-assigned fast path.** Once every variable is assigned, tlc2
   evaluates the remaining conjuncts as booleans
   (`Tool.getNextStatesAllAssigned` under the default `TLCGlobals.warn`;
   `getInitStates`' `ps.allAssigned()` branch). `+solve-conj` now does the
   same (`+conj-bools`), never for a list's first conjunct (tlc2 solves
   `args[0]` directly). It is also DEPTH-first now, one partial state at a
   time, which is tlc2's `ActionItemList` order (and so its RNG and
   `TLCSet` order).
2. **`P => A` in action position** solves A when P holds, as OPCODE_implies
   does in both `getInitStates` and `getNextStates`; it was a filter.
3. **A precomputed arity-0 definition** (`cdefs`, or a value in `vals`) is
   a VALUE at the pin (`lookup` returns it), so it is a filter, not an
   expansion.

mc `gen-allassigned-exists`, `gen-allassigned-disj`, `gen-implies-enum`,
`gen-cdef-value` (pin goldens). Every other mc golden is unchanged.

After the three, MCVoting (no SYMMETRY) 3,124 / 599 / 11 and MCVoting
451 / 77 / 11: both equal the pin.

## The other four

- PaxosHowToWinATuringAward/MCVoting: limited at 600 s (3,846 of 6,752
  distinct), no wrong answer in that prefix. Perf, R4.3.
- SimplifiedFastPaxos/FastPaxos: limited at 600 s (1,265 of 25,617). R4.3.
- Paxos/MCPaxos: `unsupported StandardModule operator: Naturals!Nat/0`
  (R4.2m residue).
- braf: `Sequences!Seq/1` (R4.2m residue).
- MCKVsnap: large; not run.
