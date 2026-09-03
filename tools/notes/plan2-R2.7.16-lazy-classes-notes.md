# R2.7.16 — the lazy set classes and the function class

```text
Sub-unit: R2.7.16
Row: tlc-eval-node (partial -> parity) -- the ledger's LAST owed row
Planned: make `+sexp-class` recursive on its operands, add the four binary
  set classes plus `%fcns`/`%rcds`, and add the function class to `+kind-of`.
Found: the plan's "one predicate" is right, but the OPERATORS DO NOT SHARE
  ONE RULE -- four different tests, plus an empty-operand case that returns
  an operand unchanged and never forces at all.
```

## One predicate, five different applications

tlc2's `Reducible` has exactly TWO implementors in the whole tree —
`IntervalValue` and `SetEnumValue` — and every representation-class decision
is that predicate applied to an operand. R2.7.13 measured that much. What it
did not measure, and what a single rule would have got wrong, is **where** the
predicate is applied:

| construction | eager (SetEnumValue) iff | else |
| --- | --- | --- |
| `S \cup T` | **BOTH** operands Reducible | `SetCupValue` |
| `S \cap T` | **EITHER** is | `SetCapValue` |
| `S \ T` | the **LEFT** is | `SetDiffValue` |
| `UNION S` | S is a **SetEnumValue OF SetEnumValues** | `UnionValue` |
| `{x \in S : P}` | S is Reducible | `SetPredValue` |
| `[d1, d2, … \|-> e]` | **EVERY** domain is Reducible | `FcnLambdaValue` |
| `SUBSET`, `\X`, `[D -> R]`, `[a: S]` | never — unconditional | own class |

Read off `Tool.java` and then **confirmed against the pin, per row**, because
three of them are surprising:

* **`\cup` needs both.** `Tool` forces through either operand, but
  `SetEnumValue.cup` and `IntervalValue.cup` both fall back to a `SetCupValue`
  unless the *other* side is Reducible too. `\cap` and `\` have no such
  fallback — their loops only need `member` on the other side — so one
  Reducible operand is enough for `\cap`, and for `\` it must be the left one.
* **UNION's test is strictly narrower than Reducible**: `instanceof
  SetEnumValue`, not `instanceof Reducible`. So `UNION {1..2, 3..4}`, whose
  elements are INTERVALS and therefore Reducible, is a `UnionValue` at the
  pin, while `UNION {{1, 2}, {3}}` is a `SetEnumValue`.
* **The function class is every domain, not the first** —
  `[i \in 1..2, j \in ((1..2) \X (1..2)) |-> i]` is a `FcnLambdaValue`. A
  `RECURSIVE` spec forces `isFcnRcd = false` outright and keeps winning ahead
  of the domain test, which is the case R1.4.5 already had.

## The empty operand, which is not a class rule at all

`SetEnumValue.cup` and `IntervalValue.cup` both open `if (size == 0) return
set;`. So `\cup` with an EMPTY Reducible operand returns **the other operand
itself** — no forcing, no new value, and the result keeps that operand's own
class. Measured: `{} \cup ((1..2) \X (1..2))` and `(1..0) \cup ((1..2) \X
(1..2))` are both `SetOfTuplesValue`, and so are the two with the operands
swapped.

That cannot be expressed as a class on a forced set, because the class could be
`IntervalValue` and no forced `%set` can carry that. It lives in `+force` as a
short-circuit, in `Tool`'s own order (arg1 tested first) — the one place in the
port where a lazy construction produces a value without forcing.

## Where the port changed

`lib/value.hoon`: new `+reducible` (the predicate, named once so the five
call sites cannot drift), `+empty-val`, `+union-eager`; `+sexp-class` rewritten
per the table; `+force` short-circuits the empty `\cup`.

`+filter-over` needed no change and is the reason the predicate has to be
spelled `%set-enum`: it already asked `?:(=(%set-enum base) %set-enum
%set-pred)` — the Reducible test in port terms — so fixing `+sexp-class` fixed
`{x \in S : P}` over a lazy base for free. `+sexp-class` answering `%set-enum`
now MEANS "Reducible", not merely "prints as SetEnumValue".

`lib/check.hoon`: `+kind-name` gains the six missing class names; `+kind-of`
takes the env and decides the function class through the new
`+fcn-doms-reducible`. No `vfcn` mold change — the class is read off the
EXPRESSION, the same shape the `$RecursiveFcnSpec` case already had, and the
domains are re-evaluated in the definition's own env (tlc2 evaluates every
domain in one context, so this is its rule and not an approximation). Only
`+project-defs` reaches this, so the re-evaluation is diagnostic-path cost.

**A Hoon trap, twice**: `+fcn-doms-reducible` first used `levy` over
`+flatten-bound`'s product and nest-failed `mull-grow` with two `sem`
identities in the same trace (`rng=#3` against `rng=^#3.#sem`). Widening the
list did not help; only an EXPLICIT loop did. Same cause as the `turn`-over-
`state` note in `+finish-bfs`: a wet gate over a binder carrying the recursive
`sem` mold.

## Checked, not assumed: the class does not reach state identity

Making more constructions carry a non-`%set-enum` class widens R2.7.2's blast
radius, so the question is whether two equal sets built differently can now
become two states. They cannot: `+equal-norm` compares set-likes by ELEMENTS
and never looks at `cls`, `+fp-enc`'s `%set` case encodes tag, length and
elements and never `cls`, and `+permute` normalizes the class away before
fingerprinting. Verified before the corpus was regenerated, because a
divergence here would move `distinct` counts rather than a printed word.

## Evidence

`ev-lazyclass` grew from 21 definitions to 34, one per branch of the table
above plus the empty-`\cup` cases, all pinned at the oracle. **`SKIPS` in
`gen-core-eval-tests.py` is now EMPTY** — the thirteen frozen entries
(`ev-tupbind/FcnT` plus `ev-lazyclass` ×12) all drop, which is this row's
stated acceptance, and every VALUE is unchanged.

**One reshape, and it is worth recording because it is NOT this row's
difference.** The first multi-binder probes (`[i \in 1..2, j \in {1, 2} |-> i +
j]`) came back with the right CLASS and the wrong pair ORDER — tlc2 prints a
multi-binder function first-index-fastest, the port prints it sorted by domain
point. That is the standing `tlc-value-order` approved difference `_ORDER`
already carries for `ev-multibind`'s `G`/`H`, arriving in a new case rather
than a new defect. Skipping the two would have lost the class assertion they
exist for, so instead the SECOND domain is a singleton (`{5}`, `SUBSET {}`),
which makes the two print orders coincide: `FMulti` (both Reducible ->
FcnRcdValue), `FMixed` (Reducible first, lazy second -> FcnLambdaValue, the
case that proves "every domain, not the first") and `FMixFst` (the mirror) all
compare in full.

Ship: `core-eval` `ok=%.y`, 0 FAILED, `test-lazyclass` and `test-tupbind` both
OK; `value`, `node-eval`, `eval`, `fp` and `stdops` green in the same pass.

`keepLazy` remains UNMEASURED and is recorded as such: tlc2 suppresses
`toFcnRcd()` under it, and whether any port path corresponds is not known
here. It cannot affect the projection this corpus compares, since
`+project-defs` evaluates a definition outside any search.
