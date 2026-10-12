# R4.P6: visited set without states (H8): measured; R4.P6a done (2026-10-11)

**Status:** MEASURED, then split at the check-in (approved). **R4.P6a is
DONE** (below). R4.P6b is deferred to R4.P8's memory numbers.

## R4.P6a: done, smaller than proposed

No re-execution was needed. Within one expansion the port registers
successors in action order, and every stored state was generated FROM its
stored predecessor. So once the stored state is the ACTUAL one, walking
`seen` yields exactly the trace tlc2 rebuilds, with the same first match in
action order. `+register-in` changes in two places:
- `seen` stores `st`, not the representative `cst`;
- the invariant is checked on `st` (`isValid(inv, succState)`).

The identity is unchanged: the fingerprint is still the orbit
representative's, and a VIEW is still evaluated on it (`minVals`). Without a
symmetry group, `st` IS `cst`, so nothing else moves.

Evidence:
- new mc case `symmetry-trace` (the `SymTr` spec below; pin golden): the
  port now prints `x = b` and the `Next` label;
- mc 107/107 and symmetry 3/3;
- the full suite re-run (tracker).

R4.P6b (dropping states) would still need tlc2's re-execution, because
then nothing would be stored to walk.

## tlc2 at the pin (read)

- The queue holds full states. The FPSet holds fingerprints. The trace file
  holds `[fp, predecessor pointer]`.
- `TLCTrace.getTrace` rebuilds a counterexample forward from the initial
  fingerprint. `Tool.getState(fp)` regenerates the initial states and takes
  the FIRST whose fingerprint matches. `Tool.getState(fp, s)` runs every
  action in order on the rebuilt predecessor `s` and takes the first
  successor whose fingerprint matches; that action labels the step. The
  port's `+edge-action` already uses exactly that labelling rule.
- Fingerprints there include VIEW and SYMMETRY (`fingerPrint()`). So the
  rebuilt trace shows the ACTUAL successor reached from the actual
  predecessor, never an orbit representative.

## Finding: symmetry traces diverge today (correctness)

The port stores and expands the orbit REPRESENTATIVE and prints traces from
`seen`. Minimal case (`SymTr`: `P = {a, b}`, `SYMMETRY Permutations(P)`,
`Next` flips `x` between `a` and `b`, `Inv == n < 2`):

| | state 2 | labels |
|---|---|---|
| tlc2 | `x = b`, `n = 1` | `<Next line 6, …>` |
| port | `x = a`, `n = 1` | `<unknown action>` |

The counts agree (3 generated, 3 distinct). The trace's states and labels do
not. (The `x`/`n` order is the known R4.2t.) No golden had a symmetry
violation trace. This one should become one.

## Memory: what dropping states from `seen` buys

Jam size of the visited set after a BFS (scratch profiler; jam is a proxy
for loom use):

| model | distinct | `seen` | without states | states' share |
|---|---|---|---|---|
| grid (2 integers) | 20,001 | 491 KB | 349 KB | 29% |
| GameOfLife, N = 4 (16-cell function) | 65,536 | 1.95 MB | 0.86 MB | 56% |

At most about 2×, and the frontier keeps its states either way. No model
measured so far is memory-bound. The timed-out models are time-bound, and
GameOfLife's serf RSS was 264 MB at 30k states. R4.P8 (the runtime
envelope) is where memory is measured at 100k–1M states.

## Proposal for the check-in

- **R4.P6a (do next):** rebuild every trace the pin's way, by re-executing
  Init/Next along the fingerprint chain (first match in action order), and
  enqueue/expand the ACTUAL state rather than the representative. This
  fixes the symmetry trace (states and labels). It also makes the trace
  path independent of what `seen` stores, which is R4.P6b's precondition.
  Evidence: a `SymTr`-style golden from the pin, and every trace golden
  byte-identical.
- **R4.P6b (defer to R4.P8's numbers):** drop states from `seen`. The gain is
  at most 2× on the visited set. Liveness and graph exports need every
  state, so they keep a store. Do it only if R4.P8 shows memory binds.
