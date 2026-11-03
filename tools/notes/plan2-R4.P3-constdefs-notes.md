# R4.P3 — constant-definition precomputation (H4) (2026-10-10)

**Status: DONE.**

## tlc2 at the pin (`SpecProcessor.processConstantDefns`, read)

- Every arity-0 operator definition whose body's level bound is CONSTANT is
  evaluated ONCE at startup, and references read the value
  (`opDef.setToolObject`).
- The lookup goes through `lookup(opDef, …)`: an overridden operator (a
  Java override or a config `<-`) is not an `OpDefNode`, so it is skipped.
- Evaluation errors are SWALLOWED; the definition stays lazy, and any error
  surfaces where it is referenced.
- Modules that are instantiated with parameters are skipped. That is
  irrelevant to the value of a constant-level body.
- Measured: `R == RandomElement(1..1000)` with `Next == x' = R` gives **2
  distinct states** at seeds 1 and 2. R is drawn ONCE, at startup.

## Port (`lib/node-eval.hoon`)

- `eenv` gains `cdefs=(map @t [def=sem-def val=value])`. `+make-env` fills
  it through `+with-cdefs`, which evaluates every arity-0, level-0
  definition with a body that is not StandardModule, not overridden
  (`+lookup:so`) and not a `+node-op:so`. A crash (`mule`) or an
  evaluation error leaves the definition lazy.
- **Deliberately not as tlc2:** a definition whose evaluation changes the
  run state (an RNG draw, `TLCSet`) stays per-reference, so this unit
  changes no observable behaviour. The RandomElement case above is a
  PRE-EXISTING divergence (the port draws per reference), recorded as a new
  row (R4.2aa); matching it needs the pin's startup RNG order measured.
- `+eval-user` answers an arity-0 reference from `cdefs` when the cached
  `sem-def` IS the one in scope, so a LET of the same name is never
  answered from the cache.
- `~+` memoizes `+with-cdefs` per environment input, because `+env-of`
  rebuilds the env per expansion.
- `+base-env` (the REPL/eval path) does not precompute.

## Also: keyed membership (`lib/value.hoon`)

The cache exposed the next cost: `messages \subseteq Message` scanned the
240 cached records linearly per member.
- `+set-index` (`~+`-memoized) holds a set's element keys and whether any
  element is a TYPED model value, the only case in which `+val-eq` can fail.
- `+member` and `+memb` answer a set of more than 8 elements from it when
  neither side is a typed model value (exactly the scan's answer), and an
  integer in an interval by a range check.
- `+fcn-index` does the same for `+find-image` (first pair wins, as in the
  scan).

## Evidence

- **Paxos, cap 30, load average 1.5:** full config **143 s (R4.P0) →
  21.6 s**. Without `PaxosTypeOK`, 21.1 s. The invariant's cost went from
  123 s to about 0.5 s. What remains (about 0.18 s per generated state) is
  successor evaluation: a set filter `{x \in S : P}` in the actions,
  per-state interpreter work.
- **CoffeeCan100Beans:** reaches all 5,150 distinct states in 300 s (it
  never left `%config` before R4.P4). Its temporal PROPERTY phase is the
  remaining time, to measure at the R4.P close.
- Arm `tests/lib/neval-mc` `test-constant-defs-evaluated-once`: `C` and
  `D` (built from `C`) are cached with their values; state-level `V`,
  parameterized `P` and random `R` are not.
- 25 shards green after the change: mc, safety-gen, dfid, sim-diff,
  generate-diff, liveness-message, job, trace, stream, tlcmod, core-eval,
  perf (tier-3 work profiles), bags, neval-mc, neval-action, stdops-diff,
  clay-load, blackbox, app, fuzz, eval, cfg-val, strorder, value, tier2.
  (The keyed-membership change came after that run; neval-mc was re-run
  green, and the full set reruns at the R4.1 close.)
