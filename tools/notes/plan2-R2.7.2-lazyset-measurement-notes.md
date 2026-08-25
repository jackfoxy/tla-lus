# R2.7.2 — the lazy-set representation class: measurement

The row: *"One root cause behind both: a fully-forced `SUBSET {1,2}` prints as
`SetEnumValue`, and a filter over a lazy base set loses tlc2's lazy class. The
enumeration is already lazy; what is missing is the *representation*."*

That diagnosis is **correct**. What it does not say is that the obvious
implementation of it **does not compile**, and this note is the measurement of
what does.

## What is actually compared

`gen-core-eval-tests.py` runs `EvalDump`, which emits
`<name> <kind> <canonical-value>` where `kind` is the Java **value class**. Seven
entries carry a `_LAZYSET` skip:

```
Sub SubsetValue {{}, {1}, {2}, {1, 2}}     <- port says SetEnumValue
```

The elements and their rendering already agree exactly; **only the class column
differs**. The port's enumeration is genuinely lazy — `sexp`/`ecur` in
`lib/value` cover `%subset`, `%prod`, `%fcns`, `%rcds`, `%cup`, `%cap`, `%diff`,
`%union`, one-for-one with tlc2's lazy classes. But `sexp` is **not a `value`**:
it is forced to an eager `%set` the moment a lazy set has to become a value
element, be rendered, or be fingerprinted, and the class is lost at that
boundary.

So the fix is exactly what the row says: let the class survive into `value`.

## Four isolation probes, because `value` is a documented hazard

`lib/value`'s own header records why this is not a free change:

> Reuse the value mold already proven to compile under zuse-408 in `lib/eval`
> (**a freshly-defined `$+`-recursive `$%` overflows the mold compiler even in
> an isomorphic shape**) ... Lazy finite-set descriptors are subunit 6.3 and are
> added there behind isolation tests, **not grown into this union
> speculatively**.

Taking that at its word, the extension was probed in isolation
(`-build-file` on a scratch lib, which is where the memory records the bug
reproduces — dojo-typed molds do not show it) before any real code was touched:

| probe | shape | result |
|---|---|---|
| 1 | 10th arm `[%lazy p=lset]`, `lset` a second named recursive mold | **overflow**, `clay: %a build failed`, `[skipped 620.067 frames]` |
| 2 | 10th arm `[%lazy cls=@tas p=(list value)]` | **overflow**, `recover: dig: over` |
| 3 | 10th arm `[%lazy cls=@tas]` — no `value` inside | **compiles** |
| 4 | **no new arm** — `[%set cls=@tas p=(list value)]` | **compiles** |

Probe 3 against probe 2 is the decisive pair: the limit is **not arm count**, it
is **adding another cycle member** to the `value` recursion. Every arm that
carries a `value` back is a cycle, and the mold compiler's budget is already
spent by the nine that exist.

## The shape that works, and it is also the right one

**Probe 4 is the design.** Put the class on the existing `%set` arm rather than
adding a lazy arm:

```hoon
+$  vset  $+(vset $:(%set cls=@tas p=(list value)))
```

No new cycle member, so it compiles — and it is the more honest model anyway:
in tlc2 the class *is* a property of a set, and every lazy form ultimately
denotes one. `cls` records what the set was BUILT as (`%subset`, `%prod`,
`%fcns`, ... or an ordinary `%set-enum`), which is precisely the column
`EvalDump` compares, while `sexp`/`ecur` keep doing the lazy enumeration they
already do.

It also matches the two facts `_LAZYSET` records that a naive "make SUBSET
lazy" would get wrong:

- **The class is not a property of the operator.** `{x \in 1..6 : P}` is a
  `SetEnumValue` at the pin while `{x \in (A \X B) : P}` is a `SetPredValue`.
  With `cls` on the set, a filter simply propagates its base set's `cls` —
  which is what tlc2 does.
- **Laziness propagates.** `[<<i, j>> \in (A \X B) |-> e]` is a
  `FcnLambdaValue` while `[i \in 1..3 |-> e]` is a `FcnRcdValue` — same
  constructor, different base. Same propagation rule.

## What the build costs

`%set`'s arity changes, so every construction and every pattern-match moves:
**32 `[%set ` sites across 11 files**, plus 55 `%set` references in `desk/lib`
alone. Mechanical, but wide, and it touches `lib/eval` — the mold every other
library aliases.

Sequencing note: do it as a single arity change with `cls` defaulted to
`%set-enum` everywhere first (all shards green, no behavior change), and only
then set `cls` at the lazy construction sites and drop the seven `_LAZYSET`
skips. Two verifiable steps rather than one unverifiable one.

## The build

Done in the two steps the measurement recommended.

**Step 1 — arity change, class defaulted everywhere.** `vset` becomes
`$:(%set cls=@tas p=(list value))` and every construction site passes
`%set-enum`. 32 sites, of which two needed care and one was found only by the
compiler:

- **Two `[%set ...]` sites are SEXP constructions, not values** —
  `lib/value`'s `sexp` arm definition and `as-sexp` in `lib/node-eval`. A
  blanket rewrite corrupts them. The first pass got the `sexp` arm anyway,
  because the exclusion matched on a line that has leading whitespace; the
  compiler caught it (`[%set %set-enum s=#1]` in the expected mold).
- **Two TALL-FORM constructions** (`:-  %set`) that no `[%set ` grep finds.
  Found by the compiler, not by search.

14 shards green afterwards with no behavior change, which is the point of
doing it as its own step.

**Step 2 — set the class, drop the skips.** `+force` derives it from the
`sexp` shape via a new `+sexp-class`; `+normalize` PRESERVES it (reordering
elements does not change what a set was built as) while `+canonicalize`
deliberately flattens it, because a set's class is not part of its identity at
the pin. `+filter-over` derives its class from the BASE set.

### The class map is measured, and the first attempt was wrong

Mapping every `sexp` form to a lazy class made `A \cup B` report
`SetCupValue`. The corpus caught it immediately against the pin's
`SetEnumValue`. Across every `eval-core` golden the pin emits exactly three
non-enum set classes:

| class | count | form |
|---|---|---|
| `SubsetValue` | 1 | `SUBSET S` |
| `SetOfTuplesValue` | 3 | `A \X B` |
| `SetPredValue` | 2 | `{x \in <lazy base> : P}` |

and **nothing else** — so `\cup`, `\cap`, `\` and `UNION` are mapped eager.
`[D -> R]` and `[a: S]` are left at `%set-enum` and marked UNMEASURED in the
code rather than guessed: no golden covers them, and inventing a class there
would repeat exactly the `%cup` error.

The filter rule is the one the residue text always named and a naive port gets
backwards: `{x \in ((1..2) \X (1..2)) : TRUE}` is `SetPredValue` while
`{x \in 1..6 : P}` is `SetEnumValue`. **The class is read off the BASE, never
off the operator.**

## Status

**Both rows closed at parity**, owed 10 → 8. Six of the seven `_LAZYSET` skips
dropped; `gen-core-eval-tests` compares 113 definitions, up from 108.

The seventh is not this unit's: `ev-tupbind`'s `FcnT` is a FUNCTION class
(`FcnLambdaValue` vs `FcnRcdValue`), which needs the same treatment on `vfcn` —
another arm, another cycle, another measurement. Recorded on `tlc-eval-node`
rather than folded in.

20 shards green. The probe lived only on the dev pier and never entered the
repo.
