# R1.3.8 — front-end follow-on: `\X` triage, then tuple-pattern binders

Parent: `R1-release-work-breakdown.md` R1.3.8. Oracle pin: `tlaplus@4ba7d8811`.
Both items surfaced in R1.4.7's close-out measurement; both sit under `semantic-graph`,
which carried `parity`. `\X` runs first: a crash and a silently vanishing definition
outrank an unsupported syntax form.

## (a) `$CartesianProd` — done

### One root cause, three symptoms

The parser has a dedicated node kind **`%n-times` (`N_Times`)** for `\X` / `\times`, and it
already flattens `A \X B \X C` into a single node (`syntax.hoon:569-572`) — exactly mirroring
SANY's **variadic** `$CartesianProd`. The semantic generator had **no `%n-times` case**, so
`+g-x` fell through and returned `[~ ~]`: the node was dropped from the graph **silently, with
no diagnostic at all**.

That single gap produced all three measured defects:

| symptom | mechanism |
|---|---|
| `P == (1..2) \X (1..2)` has no evaluable body and vanishes from the projection | the body *was* the dropped node |
| `{x \in (A \X B) : P}` → `a set filter expects one bounded variable` | the bound's range was dropped, so `+flatten-bound` skipped the group and the count came out 0, not 1 |
| `e \in (A \X B)` **crashes** the evaluator (uncaught bail) | `+bi-in` did `(snag 1 as)` on an argument list the drop had shortened |

Worth stating plainly: the failure mode was *silence*. `$CartesianProd` is registered in the
builtin table and `\X` resolves through `+resolve-syn` to `\times`, so every check that would
normally catch this passed — there was simply no branch for the node kind.

### Why nothing caught it

The **107-case sem corpus contained no `\X` case at all**. `semantic-graph` earned `parity`
without ever being measured against this operator, and the tier-2 census (295/295, empty) does
not cover it either. The coverage hole is the real finding; the fix is small.

### The fix

New `+g-times` and `+times-operands` in `lib/semantic`, plus the matching `+expr-level` case.
Operands are taken by **even position**, not by skimming for `%node`: an operator token can
itself be a wrapped node (`N_InfixOp`), which a skim would silently admit as an operand.

New sem case `desk/test-data/sem/cartprod` covers `\X`, `\times`, a flattened three-operand
chain, `\in` over a product, and a filter over a product. **Byte-exact against SANY; all 108
sem cases pass.**

### What the fix does not close

The three *functional* defects are gone. What remains is the **class column**:

| expression | pin | port |
|---|---|---|
| `A \X B` | `SetOfTuplesValue` | `SetEnumValue` |
| `{x \in (A \X B) : P}` | `SetPredValue` | `SetEnumValue` |
| `SUBSET S` | `SubsetValue` | `SetEnumValue` |

Elements and rendering agree exactly in every case. tlc2 has a class per lazy set form; the
port normalizes them all to one eager `%set`. And the class is **not** a property of the
operator — `{x \in 1..6 : P}` is a `SetEnumValue` at the pin while `{x \in (A \X B) : P}` is a
`SetPredValue`, i.e. it depends on whether the *base* set is itself lazy. Reproducing that
means modelling tlc2's lazy-value class hierarchy, which this port deliberately does not; its
enumeration *is* lazy (`sexp` / `ecur`), it is the representation class that is absent.

Filed as one approved difference, `_LAZYSET`, now covering `ev-sets/Sub` (which already carried
it separately), `ev-prod/P`, `ev-prod/R` and `ev-prodfilt/Card`.

## (b) tuple-pattern binders — done

Fixed in the order the measurement dictated: **oracle, then graph, then evaluator.** Doing the
oracle change alone would have reddened three existing goldens, so the first two land together.

### 1. Oracle

`SemDump` now prints SANY's `OpApplNode.isBdedQuantATuple` as a ` tup` suffix on each bound of a
destructuring group. Three goldens changed — `tupbind`, `tupsub`, and `labelrefarg`, the last a
tuple binder the corpus already had but nobody had noticed. `Bar` in `tupbind` is the useful
one: it mixes a plain and a tuple group (`\A x \in {1}, <<y, z>> \in {<<3,4>>}`) and the
projection now distinguishes them within a single quantifier.

### 2. Graph

`+$ sem-bound` gained `tuple=?`, set by new `+qbound-is-tuple`. There were **four** construction
sites, not the one the grep first suggested: `+g-qbound-groups`, `+g-choose`, `+g-subsetof`, and
the LAMBDA `$OpArg` in `+arg-lambda` (whose parameters are never destructuring). Each surfaced as
its own `nest-fail`, which is the type system doing its job — the mold change forced every
producer to state its answer.

### 3. Evaluator

The seam is `+flatten-bound`. It used to expand a group into one entry **per variable**, which is
exactly what erases the distinction. It now returns binder **groups** (`+$ bgroup`):

- `i, j \in S` → two groups, each ranging over the whole of S (unchanged behaviour)
- `<<i, j>> \in S` → **one** group carrying both names

New `+bind-group` binds one group to one domain element: a plain group binds its single name, a
tuple group destructures the element across its names. Because `+ctx-doms` and `+bind-vals` route
through it, **one change covers all six binder positions and the state-generation path**
(`+solve-exists`/`+solve-forall`), rather than six edits that could drift apart.

A tuple binder over a non-tuple element binds nothing, so the body fails on an unbound name
rather than silently seeing the whole element.

### Result

`ev-tupbind` verifies the values byte-exact: `\E` TRUE, `\A` FALSE, `CHOOSE` `<<1, 1>>`,
set-of-all `{2, 3, 4}`. What remains is the lazy-class column only, and it taught us one more
thing: **laziness propagates from the base set**. `[<<i, j>> \in (A \X B) |-> e]` is a
`FcnLambdaValue` at the pin while `[i \in 1..3 |-> e]` is a `FcnRcdValue` — the same constructor,
differing only in whether its domain was lazy. Filed with the other `_LAZYSET` skips.

### Ledger

`tlc-eval-node` → `approved-difference`, which makes **all seven R1.4 rows terminal**, so R1.3.8
closes R1.4 as planned. `semantic-graph` re-measured and stays `parity`. Owed rows 18 → **17**.
