# R4.2t: state VARIABLE order, measured; the decision is the user's (2026-10-12)

## The pin's rule

tlc2 orders a state's variables by its `vars` array (`TLCStateMut.toString`
prints in that order; `TLCState.fingerPrint` folds in it). That array is
`Context.getVariableDecls()`, which walks the module's SANY `Context`, a
`java.util.Hashtable<Object, Pair>`, with `table.elements()`. So the order
is **Hashtable enumeration order**. Keys are `UniqueString`s whose
`hashCode` is `String.hashCode` (deterministic). The order still depends on:
- every symbol in that context, not only the variables: constants,
  definitions, and what EXTENDS brings in;
- their insertion order (a bucket's chain is newest-first);
- the table's capacity history (11, then 2n+1 rehashes at load 0.75, which
  reorders chains);
- enumeration runs from the last bucket down.

Measured on the pin (`-workers 1`):

| declared | printed |
|---|---|
| `VARIABLES zeta, alpha, mid, Qux, beta2, beta10` | `Qux, zeta, alpha, beta2, beta10, mid` |
| `VARIABLES mid, zeta, alpha` (+ one definition) | `zeta, alpha, mid` |
| `VARIABLES y, b, m` (R4.2l) | `b, m, y` |

The order is neither declaration nor alphabetical. The port uses
declaration order (root first, then EXTENDS).

## What it affects

1. **Trace binding order:** every printed state with two or more variables
   whose orders differ. tier 2 already sorts bindings for exactly this
   reason (`gen-tier2-tests.py`). The mc corpus never declares variables
   out of tlc2's order.
2. **FP64 byte order.** Identity does not change (any fixed order is a
   bijection), but three things that read fingerprint values do:
   - the per-state RNG reseed `fp ^ seed` for specs that draw;
   - the liveness graph's map order, hence which lasso is reported;
   - the symmetry representative's tie-breaks.
3. **The same mechanism is R4.2ac:** instance-imported definitions enter
   the instancer's context in Hashtable order (SemDump: `R!Next` before
   `R!vars`).

## Options

- **A. Port it.** Simulate SANY's module Context: the same symbols,
  inserted in the same order, in a Hashtable model (`String.hashCode`,
  capacity 11 / 2n+1 / 0.75 rehash, chain order, top-down enumeration).
  Then use that order for printing and for FP64.
  - Effort M–L. Getting every symbol and its insertion order exactly
    right is the risk; it also closes R4.2ac.
  - Every golden whose declaration order differs from tlc2's would start
    to agree; today none of the mc goldens does.
- **B. Approved difference.** Extend `tlc-value-order` /
  `tlc-uniquestring`: variable order is a Hashtable layout artifact of
  SANY's symbol table, as string order is an intern-table artifact.
  - Verdicts and counts are unaffected; traces differ only in binding
    order.
  - The draw/lasso/symmetry effects become documented consequences.
  - The Examples black-box comparison would normalize binding order, as
    tier 2 does.

**Recommendation: B now, A as a later row.** Option A's exactness depends on
reproducing SANY's whole context population, and nothing in R4's
acceptance (verdicts and counts) depends on it.
