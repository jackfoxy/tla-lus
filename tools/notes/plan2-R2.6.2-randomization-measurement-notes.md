# R2.6.2 — Randomization: measurement

The row says: *"RNG-dependent, so seed parity matters — `tlc-util-rng` is already
`parity` (`java.util.Random` reproduced), which is the hard part."*

**`tlc-util-rng` is not the hard part.** It is already done, and so is the second
piece nobody counted. What is left is a third thing the row does not mention,
and it is the same evaluator change R2.7.4 now owns.

## What is already in hand

| piece | status |
|---|---|
| `java.util.Random` (LCG, `nextInt`, `nextLong`, `nextDouble`, `nextPrime`) | `tlc-util-rng` **parity** (unit 9.1) |
| `EnumerableValue.SubsetEnumerator` LCG, `computeOptimalMandA`, prime factorization | **already ported** as `+subset-indices` / `+optimal-m-a` / `+prime-factors` in `lib/rng` — R2.4.6 built them for `-generate` |
| `util.FP64` at polynomial index 0 | `tlc-util-fp64` **parity** |

`Randomization.java` itself is thin argument checking; the work is in
`EnumerableValue.getRandomSubset` and `SubsetValue.getRandomSetOfSubsets`, and
the enumerator underneath both is the one R2.4.6 already reproduced byte-exactly.

## What the draw is actually keyed on — and it is not what the row assumes

`RandomEnumerableValues` keeps one RNG per worker and **reseeds it per
predecessor state** in BFS (`TLCStateRandom.initializedFor`):

```java
final long seed = state.fingerPrint() ^ randomSeed;
this.setSeed(seed);
```

During initial-state generation there is no predecessor, so the RNG keeps
`randomSeed` alone. Measured at the pin, `RandomElement(0..99)` in a next-state
relation:

| flags | picks |
|---|---|
| `-fp 0 -seed 7` | 77, 48, 20 |
| `-fp 0 -seed 7` (again) | 77, 48, 20 |
| `-fp 0 -seed 999999` | 51, 3, 55 |
| `-fp 5 -seed 7` | 19, 6, 8 |

So the draw is a function of **both** `-seed` and the **fingerprint polynomial**,
and it is stable per predecessor state within a run (the same predecessor draws
the same value every time it is evaluated).

Two corrections fall out:

1. **The row's "seed parity" framing is incomplete.** In BFS the seed of record
   is `fingerprint ^ seed`, so parity needs the port's FP64 to agree with tlc2's
   for the selected polynomial. It does — `lib/fingerprint` is pinned at index 0
   and `tlc-util-fp64` is `parity` — but that is a dependency the row never
   names, and it means the port reproduces `-fp 0` runs and no others.
2. **A near-miss worth recording.** `-fp 0 -seed 7` and `-fp 0 -seed 8` produced
   *identical* picks, which looked like proof that `-seed` was inert. It was a
   collision on `nextInt(100)` for those two seeds. Widening to `-seed 999999`
   disproved it. Two data points that agree are not a measurement.

## What is missing, and it is R2.7.4's change again

Within a single evaluation the RNG **advances** — the pin says so in as many
words, and designs for it:

> Do not re-initialize random for the same TLCState twice to produce two
> distinct values with high probability with a next-state such as:
> `Next == x' = RandomElement(0..2) /\ y' = RandomElement(0..2)`

Measured, `x'` and `y'` do draw different values in one action. So a faithful
port must carry RNG state **across draws inside one evaluation**. `eenv` is
read-only and `eres` is `(each value eval-err)`; there is no channel for it.
Every eval's RETURN type has to carry it.

**That is the third unit to land on the same surgery**, after R2.6.1's write half
and R2.7.4's cost model. All three are the same shape: an upward-accumulating
piece of run state that a read-only environment cannot express.

There is no honest partial. Seeding a fresh RNG per evaluation is exactly right
for a spec that draws once and **silently wrong** for one that draws twice — it
would return the first draw's value again. A plausible wrong answer is the one
outcome the doctrine rules out, and unlike a refusal it cannot be detected by a
caller.

## Recommendation

Sequence R2.6.2 **after** R2.7.4, or fold it in alongside R2.6.1's write half.
The evaluator change is the whole cost; once it exists, `RandomElement`,
`RandomSubset`, `RandomSetOfSubsets` and `TestRandomSetOfSubsets` are thin
wrappers over machinery that is already ported and already differentially
verified.

Until then the four surfaces stay `deferred` with this note as the reason —
which is a sharper reason than the one they carry now ("TLC RandomGenerator
parity is unit 9"), a condition unit 9 discharged long ago.

`util.Combinatorics` re-scoping is confirmed but not yet needed: it is reached
only through `SubsetValue`'s unranking path, which only
`RandomSetOfSubsets` calls — so R1.8.0's exclusion rationale still holds
mechanically, and the row opens exactly when `RandomSetOfSubsets` lands.
