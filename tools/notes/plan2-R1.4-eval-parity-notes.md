# R1.4 — evaluation parity (unit 6 / 6.5) — measurement notes

Oracle pin: `tlaplus@4ba7d8811`. Plan: `~/FoxyLabs/tla-lus/R1.4-plan.md`.

## R1.4.0 — corpus partition (frozen)

Method: a scratch probe (`tests/lib/tev`, since removed) ran `+eval-module-def:node-eval`
over **every arity-0 definition** in the nine `desk/test-data/eval-core` cases and the result
was diffed against each case's `golden-eval.txt` (`EvalDump`, the same pin).

### Partition

| case | golden defs | evaluated | errored | notes |
|---|---|---|---|---|
| `ev-binders` | 7 | 7 | 0 | |
| `ev-composites` | 9 | 9 | 0 | |
| `ev-config` | 3 | 0 | 3 | `undefined identifier: N` — **harness**, not evaluator |
| `ev-errors` | 2 | 0 | 2 | goldens *are* errors; message text differs |
| `ev-except` | 9 | 9 | 0 | |
| `ev-lookup` | 9 | 9 | 0 | |
| `ev-model` | 3 | 0 | 3 | `undefined identifier: MV/MS` — **harness** |
| `ev-primitives` | 10 | 10 | 0 | |
| `ev-sets` | 9 | 9 | 0 | |
| **total** | **61** | **53** | **8** | |

**Of the 53 that evaluate, 52 render byte-identical to the oracle's `toString`.** The corpus
does not currently exercise a single one of the five unsupported sites the plan lists
(`$RecursiveFcnSpec`, multi-binder function constructor, operator-valued argument, action
`\E`/`\A` multi-binder, decimal literals) — those need **new** cases, they are not latent
failures in the existing ones.

### The one value divergence

| case/def | oracle | port |
|---|---|---|
| `ev-lookup/Dom` (`DOMAIN <<a,b,c>>`) | `IntervalValue` `1..3` | `set` `{1, 2, 3}` |

`DOMAIN` over a tuple: TLC returns a lazy `IntervalValue`; the port eagerly enumerates.
Observable in `toString`, so it is a real parity item — small, and R1.4.1's differential
will hold it.

### Value-class column

The oracle's first column is the Java class name; `+vkind:value` is the port's own ADT tag.
The raw mapping measured over the corpus is **not injective** —

```
BoolValue -> bool    FcnRcdValue -> fcn    IntValue -> int
IntervalValue -> intv (2) / set (1, the Dom divergence)
RecordValue -> rec   SetEnumValue -> set   SubsetValue -> set
StringValue -> str   TupleValue -> seq
```

**Superseded by R1.4.1**: `+kind-name:check` already maps the port's tags back to the
oracle's class names, so the column *is* compared. The non-injectivity shows up as exactly
one skipped definition (`ev-sets/Sub`, `SubsetValue` vs `SetEnumValue`) — see below.

### Harness gap found (drives R1.4.1's shape)

`+eval-module-def:node-eval` takes `(modname, sources, defname)` and **no config**, so the
two cases whose definitions read `.cfg` CONSTANTs (`ev-config`: `N = 5`, `K = 3`;
`ev-model`: `MV = m0`, `MS = {a, b, c}`) cannot be driven through it at all. 6 of the 61
goldens are behind it, so it must be *closed*, not skipped.

**Closed in R1.4.1 without new code**: `+project-defs:check` — written for the C1.8 stdops
differential — already builds `(make-env:ne defs (const-map cfg) (vars-of:ne mo))` and
already renders the oracle's projection via `+kind-name`. Both `ev-config` and `ev-model`
compare green through it.

### `ev-errors`: text, not capability

Both defs fail in the port for the same *reason* as in the oracle:

| def | oracle | port |
|---|---|---|
| `BadDom` | `TLCRuntimeException: In applying the function <<1, 2, 3>>, the first argument is: 9 which is not in its domain.` | `applying a function outside its domain: 9` |
| `DivZero` | `EvalException: The second argument of \div is 0.` | `The second argument of \div is 0.` |

`DivZero` differs only by the exception-class prefix; `BadDom` needs the value rendered into
the message. Both are **R1.4.5** (EC-classified evaluator diagnostics), not R1.4.2/.3.

## Scope decisions (with evidence)

### (a) the CST evaluator — **keep the file, delete the dead driver**

`lib/eval.hoon` is *not* only the CST evaluator: it owns the canonical `value` mold and
`vfield`/`vpair`, which `lib/value` (hence `lib/node-eval`) and `lib/config`
(`+$ cfg-value value:eval`, `config.hoon:29`) both depend on. The file stays.

Its `+eval` **CST driver** (`eval.hoon:622`, over `syntax-node`) is production-reachable
from exactly one place: `check.hoon`'s `+ev-bool`/`+ev-val` (`:72`/`:78`), which feed a
CST-based state generator — `+gen`, `+gen-conj`, `+gen-exists`, `+qb-parts`,
`+gen-unchanged`, `+filter`, `+combine`, `+assignable` (`check.hoon:63–237`). That block is
a **closed cycle**: every call to `+gen` originates inside it (`:111`–`:189`), nothing
outside `check.hoon` references any of its arms, and no test does. The live engine reaches
state generation through `node-eval` (`+init-states`/`+next-states`/`+pred-bool`).

→ **R1.4.4**: delete the dead block from `check.hoon` (~130 lines); `+eval` then becomes
test-only, exercised by its own `tlc2.REPL` differential (`tools/gen-eval-tests.py` →
`tests/lib/eval`). `tlc-eval-cst` is therefore **not** `replaced` — it is a narrower,
separately-verified constant-expression evaluator that the semantic-node rows supersede for
state generation only. `tlc-util-context`'s "binding chain partial with the CST evaluator"
residue is closed by the same deletion: after it, there is one binding chain, `+make-env`.

### (b) `RandomElement` — **R1.7's, confirmed, hand over**

`compatibility.md:1207` already files `Randomization` and `TLC!RandomElement` under
*Excluded surfaces*, "unit 9 owns TLC's RNG", and the port already gives the typed rejection
`unsupported StandardModule operator: TLC!RandomElement/1` with a test pinning it
(`tests/lib/stdops.hoon:100–105`). R1.4 absorbs nothing; `tlc-module-tlc`'s `RandomElement`
residue is R1.7's.

### (c) decimal / Real literals — **excluded, but owed a *typed* rejection**

`compatibility.md:1206` already lists `Reals` under *Excluded surfaces*, and no corpus case
uses a decimal literal. So the capability is **excluded**, not owed.

But excluded surfaces are excluded *as typed rejections*, and `node-eval:126` returns
`[%| 0 'decimal (Real) literals are unsupported.']` — **EC 0**, i.e. unclassified, unlike its
neighbour at `:122` which carries EC 2265. That inconsistency is R1.4.5's (classification and
wiring), not a new evaluator capability.

## R1.4.1 — the `EvalDump` comparator (done)

`tools/gen-core-eval-tests.py` gained the differential half: it emits
`desk/tests/lib/core-eval.hoon`, one arm per case, running every arity-0 definition through
`+project-defs:check` and comparing against the oracle's own projection line for line.
**58 compared definitions across the 9 cases, all green** (rev 722, `ok=%.y`).
`validate.py` flips the generator `oracle-only` → `pass`.

No new comparator machinery was needed — `+project-defs:check` already did the work
(constant environment from the `.cfg`, `+kind-name` for the oracle's class column,
`! EC<code> <message>` for typed failures, an explicit per-arm skip list). This is the same
shape `gen-stdops-tests.py` emits, so the two differentials read alike.

**One oracle change was required.** `EvalDump` printed `! <ExceptionClass>: <message>` with
no error code, while `+project-defs` emits `! EC<code> <message>` — every error line would
have mismatched. `EvalDump` now carries the `EC<code> ` prefix for an `EvalException`,
copied from `ModuleOpDump.ec` (which had it since C1.2); the generator then strips the Java
class name from both sides, since the class is a Java identity and the code is the
behaviour. `ev-errors/DivZero` is byte-exact at **EC 2179**. Only `golden-eval.txt` for
`ev-errors` changed under regeneration — the eight other goldens are byte-identical, so the
new projection is additive.

### The three skips, each with a named owner

| case/def | why | owner |
|---|---|---|
| `ev-lookup/Dom` | `DOMAIN` of a tuple stays a lazy `IntervalValue 1..3` in TLC; the port enumerates it | R1.4.5b |
| `ev-errors/BadDom` | the out-of-domain message does not render the function value | R1.4.5 |
| `ev-sets/Sub` | a forced top-level `SUBSET {1, 2}` prints as `SetEnumValue`: the port has no lazy-subset *representation class*. The enumeration itself is lazy (`ecur`, `sexp-subseteq`), and the rendering agrees | approved difference |

Anything not on that list must match, so a new divergence cannot appear silently.

### Ledger

- `tlc-enum` — `oracle-only` → **`approved-difference`** (the comparator it was waiting on
  now exists; the residual is the `SubsetValue` projection artifact, not lazy enumeration).
- `tlc-eval-error` — `oracle-only` → **`partial`**, residue narrowed to two named items for
  R1.4.5.
- `tlc-eval-node` — stays `partial`; the "differential is still oracle-only" half of its
  residue is gone, leaving exactly recursive functions, multi-binder constructors, and the
  `Dom` interval.

Owed rows: 24 → **23**.

## R1.4.1b — corpus extension (done)

R1.4.0 measured that the nine original cases reach **none** of the sites `lib/node-eval` names
as unsupported, so R1.4.2/.3 had nothing to verify against. Four cases now exist to reach
them, goldens captured at the pin:

| case | targets | oracle loads |
|---|---|---|
| `ev-recfcn` | `$RecursiveFcnSpec` — `Fact[n \in 0..5]`, a `SUBSET`-domain recursion, a boolean one | 7 defs |
| `ev-multibind` | multi-binder function constructor, multi-binder `\E`/`\A`, tuple-pattern `\E`, multi-binder set-of-all | 8 defs |
| `ev-oparg` | operator-valued arguments: an operator NAME, and LAMBDAs at arity 1 and 2 | 5 defs |
| `ev-subbag` | `Bags!SubBag` — the witness `tlc-module-body`'s residue names | 4 defs |

Corpus 9 → **13 cases**, 61 → **82 golden definitions**.

### What already works (measured, not assumed)

Three of the twenty-one new definitions were expected to fail and do not:

- `ev-multibind/ExMulti`, `ev-multibind/AllMulti` — **multi-binder `\E`/`\A` at constant level
  already evaluate.** The plan lists `:1250`/`:1275` as unsupported, but those are the *action*
  paths; the constant quantifier handles multiple bounds today.
- `ev-oparg/A1`, `A2` — **an operator NAME passed as an argument already evaluates**
  (`Apply(Inc, 5)` = 6, `Twice(Inc, 5)` = 7). The `:946`/`:1119` "unsupported operator-valued
  argument" site is reached only by a **LAMBDA**.
- `ev-subbag/B` — `SetToBag` evaluates; only `SubBag`'s own body is blocked.

### Two sites R1.4.0 did not name, surfaced here

1. **Set-of-all over multiple binders** — `{i * j : i \in 1..2, j \in 1..3}` gives
   `a set-of-all expects one bounded variable`. Not in the plan's five-site table.
2. **Tuple-pattern bounded quantifier at constant level** — `\E <<i, j>> \in (1..2) \X (1..2)`
   gives `unbounded quantifier is not enumerable`, which **misdescribes the input**: the
   quantifier is bounded. Both belong to R1.4.3.

### The LAMBDA finding changes R1.4.3's scope

`ev-oparg/A3`, `A4` and `Sel` fail because **LAMBDA is not in the WU3 semantic graph** — the
identical residue `stdops-diff` already carries as a skip on `Sel`/`SelNone`
(`tests/lib/stdops-diff.hoon:137`). This is unit-3 / front-end work, not evaluator work.
**R1.4.3 cannot close the operator-valued-argument site for LAMBDA arguments**; it can only
close the multi-binder ones. That is a dependency the plan did not record.

### Oracle facts worth keeping

- A recursive function evaluates to a **`FcnLambdaValue`**, a class no earlier case produced,
  rendered `(0 :> 1 @@ 1 :> 1 @@ 2 :> 2 @@ …)` — *not* as a tuple, because `Fact`'s domain is
  `0..5` and so does not start at 1. `+kind-name:check` has no `FcnLambdaValue` case yet.
- `Card`'s domain is `SUBSET (1..3)` and the oracle emits its points in **`SubsetValue`
  order** — `{}, {1}, {2}, {3}, {1,2}, {1,3}, {2,3}, {1,2,3}` — which R1.4.2 must reproduce.
- The multi-binder constructor's point order is **first index fastest**:
  `<<1,1>> :> 11 @@ <<2,1>> :> 21 @@ <<1,2>> :> 12 @@ <<2,2>> :> 22`. That is the iteration
  order R1.4.3 owes, and it is *not* the order `DOMAIN G` prints (`GDom` is a normalized
  `SetEnumValue`, sorted).
- `SubBag(B)` renders a mixed set — `{<<>>, <<1>>, (2 :> 1), <<1, 1>>}` — because a bag whose
  domain is `{2}` is not a tuple. `SubBag(EmptyBag)` is `{<<>>}`.

### Suite discipline

The twenty-one new definitions split 3 green / 18 skipped, each skip naming the increment that
removes it (R1.4.2: 10, R1.4.3: 6, unit-3 LAMBDA: 3 — the last with no R1.4 owner). Compared
definitions 58 → **63**. The shard stays green, and the skip list *is* the work list for
R1.4.2/.3.

## R1.4.2 — recursive functions (done)

`$RecursiveFcnSpec` now evaluates. Compared definitions 63 → **70**; shard green at rev 727.

### The plan's approach was wrong, and the pin says why

The plan said "bind the function's own name in the environment and evaluate under the existing
fuel bound", which implies solving points in domain order. Measured at the pin first:

| probe | oracle |
|---|---|
| `R1[n \in 1..3] == IF n = 1 THEN 1 ELSE n * R1[n-1]` | `FcnLambdaValue <<1, 2, 6>>` |
| `NR1 == [n \in 1..3 \|-> n]` | `FcnRcdValue <<1, 2, 3>>` |
| `R0[n \in 0..2] == n` | `FcnRcdValue (0 :> 0 @@ 1 :> 1 @@ 2 :> 2)` |
| `Fwd[n \in 1..3] == IF n = 3 THEN 0 ELSE Fwd[n+1] + 1` | `FcnLambdaValue <<2, 1, 0>>` |
| `Circ[n \in 1..2] == Circ[n] + 1` | `FcnLambdaValue [n \in 1..2 \|-> <expression line 7, col 21 to line 7, col 31 of module A>]` |

Three things follow:

1. **`Fwd` works.** TLC's `FcnLambdaValue` is lazy and forces a point only when applied, so a
   body may refer to *any* point, not only an earlier one. Domain-order iteration would be
   wrong. `+eval-recfcn` therefore **sweeps the domain to a fixpoint**: each unsolved point is
   retried with the self-binder bound to the points solved so far, and sweeping stops when a
   whole pass solves nothing new. That terminates on every well-founded definition regardless
   of recursion direction, and is bounded by |domain| sweeps.
2. **The value class is a property of the EXPRESSION, not the value.** `R1` and `NR1` have
   identical renderings (`<<1, 2, 6>>` vs `<<1, 2, 3>>`, both tuples) but different classes;
   `R0` shows the pairs-vs-tuple choice is about the *domain*, not the class. So the class
   cannot be read off a value, and adding a marker to `vfcn` would be a shape change to the
   mold `lib/config`'s `cfg-value` and the jammed state share. New `+kind-of:check` instead
   reads it off the semantic node: a `$RecursiveFcnSpec` body prints `FcnLambdaValue`.
3. **`Circ` does not error** — TLC returns the unforced lambda, printing the body's source
   span. The port has no unforced-value form; a stalled fixpoint reports its last failure.
   Recorded as a difference, not in the corpus.

### A latent crash this reached

`+need-sexp` asserted `?>(?=(%& -.s) p.s)` on the set-constructor path (`node-eval:343`), so a
set constructor whose operand failed to evaluate **crashed the evaluator** instead of returning
a typed failure. Unreachable before, because nothing evaluated an expression expected to fail
and then continued — a fixpoint sweep does exactly that (`s \ {CHOOSE y \in s : TRUE}` on an
unsolved point). The call site now propagates; `+need-sexp` is deleted (it had one caller).

### Results

`ev-recfcn` 6/7 byte-exact — `Fact`, `Even`, `F5`, `C3`, `E3`, and `Card`, whose domain is
`SUBSET (1..3)` and whose points come out in the oracle's `SubsetValue` order
(`{}, {1}, {2}, {3}, {1,2}, {1,3}, {2,3}, {1,2,3}`). `ev-subbag` 2/4 — `B` and, newly,
`Empty` (`SubBag(EmptyBag)`), which exercises the RSB recursion's base case over a domain of
*functions*.

Two skips remain, both already-owned rather than new:

| def | why | owner |
|---|---|---|
| `ev-recfcn/FDom` | `DOMAIN` of a recursive function is a lazy `IntervalValue 0..5` in TLC, enumerated here — **the same divergence as `ev-lookup/Dom`** | R1.4.5b |
| `ev-subbag/Subs`, `NSubs` | `SubBag`'s `LET Combine` builds `{[...] : f \in BagSet, i \in 1..B[x]}` — a **multi-binder set-of-all** | R1.4.3 |

That second one confirms `tlc-module-body`'s residue verbatim ("recursive functions **and
multi-binder set constructors**"): R1.4.2 supplied the first half, R1.4.3 owes the second.
Because the fixpoint reports the last failing point rather than the first, the surfaced message
is the out-of-domain one, not the set-of-all one — worth knowing when reading that skip.

## R1.4.3 — multi-binder constructors (done)

Compared definitions 70 → **75**; `core-eval` green (13/13).

New `+ctx-map` and `+ctx-fcn` in `lib/value` walk a binding context over several
prefix-dependent domains and collect *every* binding (the existing `+ctx-go` short-circuits on
the first match, which suits `\E`/`\A` but not a constructor). `+eval-setofall` and
`+eval-fcncon` take that path when there is more than one binder and keep the streaming
one-binder path otherwise, so a large single-binder domain is still never materialized.

**`SubBag` now evaluates fully.** `ev-subbag` is 4/4: R1.4.2 supplied the recursion, this
supplies the multi-binder set-of-all in its `LET Combine`. `tlc-module-body`'s residue —
"recursive functions and multi-binder set constructors" — is closed on both halves.

### Multi-binder function print order: approved difference

`G == [i \in 1..2, j \in 1..2 |-> i * 10 + j]` at the pin prints
`(<<1, 1>> :> 11 @@ <<2, 1>> :> 21 @@ <<1, 2>> :> 12 @@ <<2, 2>> :> 22)` — **construction
order, first index fastest**, which is *not* sorted: `DOMAIN G` prints
`{<<1, 1>>, <<1, 2>>, <<2, 1>>, <<2, 2>>}`. So tlc2 leaves a multi-binder `FcnRcdValue`
un-normalized when printing.

The port's `+normalize` sorts function pairs by domain point, and that ordering is load-bearing
— value equality and state fingerprints depend on it. Reproducing tlc2's print order would mean
either abandoning the normal form or carrying insertion order inside `vfcn`, a mold change to a
type `lib/config`'s `cfg-value` and the jammed state share. The pairs are identical and the
function is the same function: `GAt == G[1, 2]` is `12` and `GDom` agrees byte-for-byte, both
green. `G` and `H` are therefore skipped as an **approved difference** in the existing
`tlc-value-order` family, not as owed work.

### `ExTup` is a front-end gap, not evaluator work — and needs a mold change

`\E <<i, j>> \in (1..2) \X (1..2) : i = j` still fails, and R1.4.3 cannot fix it. Two findings:

1. `+qbound-vars` (`semantic.hoon:890`) flattens a tuple binder by descending
   `%n-identifiertuple` and binding each identifier individually, so **`<<i, j>> \in S` and
   `i, j \in S` produce the same `sem-bound`** — `vars=[i j]`, one `range`. Those mean different
   things: the first destructures one element of `S`, the second ranges each variable over the
   whole of `S`. `+$ sem-bound` is `[vars=(list sbind) range=(unit sem)]` and has **no way to
   record the difference**, so no evaluator change can distinguish them.
2. The observed message (`unbounded quantifier is not enumerable`) means the graph handed the
   evaluator an empty bound list, so the CST for this shape is not producing an
   `%n-quantbound` for `g-bound-quant` to pick up either.

Closing it needs a destructuring flag on `sem-bound`, generator support, and then evaluator
support — the `tupbind`/`tupsub` family from R1.3.3.2/R1.3.4, which handled tuple binders in
*definitions*, `$SubsetOf` and `$SetOfAll` but not in quantifiers. That is front-end work; it is
recorded against `semantic-graph` rather than absorbed here.

## Consequences for the plan

- **R1.4.1 grows a requirement**: the comparator must supply cfg CONSTANTs, not skip the two
  cases that need them (6 goldens).
- **R1.4.2 / R1.4.3 need new corpus cases.** The existing corpus does not reach any of the
  five unsupported sites, so `gen-core-eval-tests.py` must gain `$RecursiveFcnSpec`
  (`Bags!SubBag` is the named witness) and multi-binder constructor cases before those
  increments have anything to verify against.
- **R1.4.5 gains two concrete items** beyond div-by-zero/out-of-domain classification: the
  `BadDom` message must render the function value, and `node-eval:126` must carry a real EC.
- **R1.4.4 is now specified**: delete `check.hoon:63–237`, keep `lib/eval.hoon`.
- A new, small parity item: `DOMAIN` over a tuple should stay an interval.
