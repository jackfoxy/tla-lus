# Unit 6C (Phase C, C1) — StandardModule overrides and string order

Working notes for `~/FoxyLabs/tla-lus/unit-6c-plan.md`. Oracle pin
`tlaplus@4ba7d8811289fb8e95dac4d5e554c05216ba3100`.

Subunit C1.0 is inventory, ledger split, and frozen baseline: docs, tools, and
fixtures only. No desk change, no ship `-test` change.

## 1. What the oracle actually does (mechanism)

`SpecProcessor.processConstantDefns` walks every module of the spec. For a
module `M` it loads class `tlc2.module.M` and, for each **public static**
method that carries no `@TLAPlusOperator`/`@Evaluation` annotation:

- the TLA+ identifier is `TLARegistry.mapName(javaMethodName)` — the mapping
  each module class registers in its static block (`Plus`→`+`, `DotDot`→`..`,
  `Concat`→`\o`, `BagCup`→`\oplus`, `Neg`→`-.`, …), so the registry key is a
  **TLA+ operator name**, never the Java name;
- the method is wrapped in a `MethodValue` and set as the tool object of the
  `OpDefNode` **whose name matches**. For a *built-in* module the arity is not
  re-checked (the method's own parameter count is authoritative); for a
  user-supplied Java override arity is checked and a mismatch is a warning
  (EC 2400) with the override dropped.

Annotated methods take a different path (`processModuleOverrides`):
`@TLAPlusOperator` binds by `(module, identifier)` from the annotation;
`@Evaluation` and `@TLAPlusCallable` bind an `EvaluatingValue`/`CallableValue`
to the definition's **body**, receive `(Tool, ExprOrOpArgNode[], Context,
TLCState, TLCState, int, CostModel)` — i.e. *unevaluated* arguments — and
carry a `minLevel`.

Consequences for the Hoon port, all reflected in the C1 plan:

1. The registry key is `(module, TLA+ identifier, arity)`. Bare-name dispatch
   (what `node-eval` does today) is wrong in principle even where it happens
   to give the right answer.
2. A Java method binds only if some module **declares** an operator of that
   name. Several do not (§3).
3. A declared operator with no Java method keeps its TLA+ body: the port must
   be able to evaluate a StandardModule definition, not only override it.

## 2. Oracle tooling added

`tools/oracle/ModuleOpDump.java`

| mode | output |
|---|---|
| `--inventory` | one row per public static method of the `tlc2.module` classes: class, built-in flag, mapped TLA+ name, arity, Java name, parameter/return types, annotation |
| `--declared <base>` | SANY-parses `<base>.tla` and lists `module\|operator\|arity\|public-or-local` for every module in the external module table — the operators a StandardModule really declares |
| `<base>` | `FastTool` over `<base>.tla`/`.cfg`; `BINDINGS` says what each imported definition resolved to (`override:MethodValue`, `body-override:…`, or `body`), `EVAL` prints kind + canonical value or `! EC<code> <Exception>: <message>` |

`Spec.toolId` is protected static and is read reflectively so body-level
(`Evaluation`) overrides are visible; if that ever fails the tool degrades to
`body` rather than lying.

`tools/gen-stdops-tests.py` joins `--inventory` with `--declared` (probing all
20 vendored StandardModules individually), attaches the `EC.*` constants
reachable from each Java method body (source scan of the pinned tree), applies
the classification rules, and writes `desk/test-data/stdops/inventory.txt`
plus `golden-ops.txt` per case. It exits nonzero if a `tlc2/module` class is
missing from the dump's list or if any operator surface is unclassified.
Wired into `validate.py` as `oracle-only` (no Hoon comparator until C1.1).

## 3. Inventory result — 131 operator surfaces

| class | required | body | deferred | excluded |
|---|---|---|---|---|
| Naturals | 12 | | | |
| Integers | 2 (`-.`, `Int`) | | | 12 |
| Sequences | 8 | | | 3 |
| FiniteSets | 2 | | | |
| Bags | 12 | 2 | | |
| TLC (+TLCGetSet, TLCEval) | 8 | | 4 | 2 |
| Randomization | | | 3 | 1 |
| TLCExt / Json / IOUtils / Toolbox / Reals / RealTime / `_*` | | | | 57 |
| AnySet / Strings / TransitiveClosure | | | | 3 |
| **total** | **44** | **2** | **7** | **78** |

Machine-derived facts worth keeping (each changed the plan's scope):

- **`Integers`' arithmetic is redundant.** `Integers.java` re-registers
  `+ - * \div % ^ < > \leq \geq .. Nat`, but `Integers.tla` declares only
  `-.` and `Int`; the arithmetic operators are declared in `Naturals`, so they
  bind through the `Naturals` class. This is the upstream `TODO Why does
  tlc2.module.Integers define identical mappings?` in `Naturals.java`. The
  port needs one arithmetic registry, keyed by `Naturals`.
- **Three `Sequences` methods are unreachable**: `Cons`, `SelectInSeq`,
  `Insert` have no declaration in `Sequences.tla`.
- **`Strings`, `AnySet`, `TransitiveClosure` have no StandardModule at all**
  (`STRING`/`ANY`/`Warshall`); nothing in a spec can reach them.
- **`Bags!SubBag` is declared but not overridden** — `BINDINGS` in
  `st-bags/golden-ops.txt` shows `Bags!SubBag/1` resolving to `body`. This is
  the fixture for C1.1's TLA+-body evaluation, which is blocked by the unit-7
  finding that `EXTENDS`-imported definitions are not reachable from the
  evaluation environment.
- `Bags!Sum` is `LOCAL` — declared, not exported, body-evaluated if reached.
- `Json!textSerialize` targets module `IOUtils`, which is not vendored.

## 4. Frozen baseline (what the port does today)

- `desk/lib/node-eval.hoon` `++native-set`: **17 bare operator names** —
  `+ - * ^ \div % < > \leq \geq .. \o Len Head Tail Append Cardinality` —
  dispatched by name in `++eval-native` with no module or arity qualification.
  Every other bodyless `UserDefinedOpKind` is a typed unsupported failure.
- Coverage against the inventory: Naturals 11/12 (no `Nat`), Integers 1/2
  (unary minus; no `Int`), Sequences 5/8 (no `SubSeq`, `SelectSeq`, `Seq`),
  FiniteSets 1/2 (no `IsFiniteSet`), Bags 0/14, TLC 0/12 in the evaluator
  (`Permutations` is recognized ad hoc by `check.hoon`'s `symmetry-perms`
  from the CST, not through any registry).
- Four confirmed semantic defects, now regression-covered by
  `st-arith-errors` and `st-integers`:

| defect | pin |
|---|---|
| `\div` computed as `abs/abs` | floor division: `q = n1/n2`, then `q--` when `q<0 && q*n2!=n1` (`(-7)\div 2 = -4`) |
| `%` computed as `abs%abs` | divisor must be **positive** (EC 2169, message names `"second" "%" "positive number"`), remainder non-negative (`(-7)%3 = 2`) |
| `^` computed over `abs` | `Expt` with EC 2178 overflow and EC 2180 for `0^0` |
| unbounded `si` integers | `IntValue` is 32-bit; `+ - * ^` raise EC 2178 `Overflow when computing <a><op><b>`; a literal ≥ 2^31 fails the **whole load** (`TLC can't handle a number this big`) |

- No StandardModule definition is ever evaluated from its vendored TLA+ body.
- Family 5: strings ordered lexicographically (`value.hoon`), model-value
  fingerprints fold the **name** instead of the `UniqueString` tok
  (6.8 deviation), symmetry orbits canonicalize by `vlth` instead of TLC's
  `compareTo` (7.5 residue).

## 5. Fixture corpus (`desk/test-data/stdops/`, 11 cases)

`st-naturals`, `st-integers`, `st-arith-errors`, `st-big-literal`,
`st-sequences`, `st-seq-errors`, `st-finitesets`, `st-bags`, `st-tlc`,
`st-tlc-errors`, `st-string-order`.

Error codes pinned by the goldens: 2132 (`Assert` false), 2169 (argument
error — `%` divisor, `SelectSeq` predicate, `SortSeq`, `@@`), 2176 (applying
to the wrong value), 2178 (overflow), 2179 (`\div` by zero), 2180 (`0^0`),
2181 (cardinality of a non-enumerable value), 2182 (`Append`/`\o` on a
non-sequence), 2183 (`SubSeq` bound not in the domain), 2184 (`Head`/`Tail` of
the empty sequence), 2266 (`an` argument error, e.g. `1 < "a"`), 2283 (one-
argument error, e.g. `Len({1,2})`).

Notable pinned behaviors:

- `Len("abc") = 3` — a string **is** a sequence to `Len`.
- `Seq(3)` returns a `UserValue` (`Seq(3)`) rather than failing; the failure
  comes later, at membership or enumeration.
- `IsFiniteSet(Nat) = FALSE`, but `Cardinality(Nat)` is EC 2181.
- A type mismatch that reaches the Java method surfaces as a
  `TLCRuntimeException` naming the **Java method signature**
  (`… tlc2.module.Integers.Plus(IntValue,IntValue) … Cannot cast
  StringValue to IntValue`) — the volatile message C1.6 must normalize.
- `TLC!Any` renders `UserValue ANY`; `TLC!JavaTime` returns wall-clock
  milliseconds and was **removed from the fixture** — a golden containing it
  is not reproducible. Both stay `excluded`.

### Family-5 baseline (`st-string-order`)

```
Adversarial SetEnumValue {"bb", "a", "ab"}     \* interning order, not lexicographic
Longer      SetEnumValue {"aa", "ab", "b", "z"}
Ch          StringValue "bb"                   \* CHOOSE picks the first interned
Dom         SetEnumValue {"bb", "a", "ab"}     \* record field order follows it too
Models      SetEnumValue {zz, aa, mm}
ChModel     ModelValue zz
Rec         RecordValue [bb |-> 1, a |-> 2, ab |-> 3]
```

Every one of these differs from what the port produces today. C1.7 measures
the interning order with `InternDump` and decides reproduce-vs-approve; these
goldens are the evidence either way.

## 6. Ledger changes (C1.0)

`tlc-module` → `tlc-module-{registry,naturals,integers,sequences,finitesets,
bags,tlc,body,lazy,excluded}`, each with its own fixture and status;
`tlc-overrides` `excluded` → `replaced` (a static Hoon registry replaces
reflection/classpath discovery; the observable annotation semantics ride on
`tlc-module-lazy`); `tlc-value-order` and `tlc-uniquestring` keep
`approved-difference` but now cite `st-string-order` and name C1.7 as the
decision point. `check-parity.py --check` clean.

## 7. Gotchas hit in C1.0

- A `|` inside a code span in a manifest cell breaks `check-parity.py`'s row
  split (it splits the raw markdown row); escape it out of the text entirely.
- `7 \div -2` is a **parse** error in TLA+; adversarial negative arguments
  must be parenthesized (`7 \div (-2)`).
- One bad definition can fail the whole module load (`2147483648`), taking
  every other case in that fixture with it — such cases need their own case
  directory (`st-big-literal`).
- `ToString(Assert)` (an operator as a value) does not parse; drop it rather
  than working around it.
- Fixture goldens must be checked for nondeterminism *before* committing:
  run the generator twice and diff the whole tree (`JavaTime` was caught this
  way).
