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

### Value-class column: approved difference

The oracle's first column is the Java class name; the port's `+vkind` is its own ADT tag.
The mapping measured over the corpus is **not injective** —

```
BoolValue -> bool    FcnRcdValue -> fcn    IntValue -> int
IntervalValue -> intv (2) / set (1, the Dom divergence)
RecordValue -> rec   SetEnumValue -> set   SubsetValue -> set
StringValue -> str   TupleValue -> seq
```

`SetEnumValue` and `SubsetValue` both land on `set` because the port has no lazy-subset
representation, and their `toString` agrees anyway. **R1.4.1 compares the rendered value
text only**; the class-name column is a Java representation detail and is recorded as an
approved difference. Nothing observable is lost — the `Dom` case proves a class difference
that *does* matter still shows up in the text.

### Harness gap found (drives R1.4.1's shape)

`+eval-module-def:node-eval` takes `(modname, sources, defname)` and **no config**, so the
two cases whose definitions read `.cfg` CONSTANTs (`ev-config`: `N = 5`, `K = 3`;
`ev-model`: `MV = m0`, `MS = {a, b, c}`) cannot be driven through it at all. This is the
same shape as the `StreamDump` CONSTANT skip (R1.5.10) — but here it must be *closed*, not
skipped, because 6 of the 61 goldens are behind it. R1.4.1's comparator must build the
constant environment from `A.txt` (the `+make-env:node-eval` `consts` slot already exists;
`run-check` already populates it at `check.hoon:1284`) rather than adding a skip rule.

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
