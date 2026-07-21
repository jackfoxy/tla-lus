# PLAN-2 Unit 6 (core TLC values + evaluation, Phase B5) — oracle notes

Oracle pin: `tlaplus@4ba7d8811289fb8e95dac4d5e554c05216ba3100`.
Java owners: `tlc2.value.IValue`/`ValueConstants`/`tlc2.value.impl.Value` +
subclasses; `tlc2.tool.impl.Tool` (`eval`, `getInitStates`/`getNextStates`,
`enabled`), `OpDefEvaluator`, `ContextEnumerator`, `ActionItemList*`,
`EvalControl`, `tlc2.util.Context`; `tlc2.output.EC` evaluation codes.

## 6.0 oracle tool + corpus (done)

- `tools/oracle/EvalDump.java`: builds a `FastTool` (SANY analyze +
  `SpecProcessor` config, so config CONSTANT/model assignments are in scope),
  then for every **arity-0 definition originating in the root module** (sorted
  by name) evaluates its body via `tool.eval(def.getBody())` and prints a
  UID-free projection:
  `EVAL` then `<name> <value-class> <canonical-toString>`, or
  `<name> ! <ExceptionClass>: <message>` for a typed evaluation failure.
  Java identities / coverage / timing excluded; the value class simple name is
  the stable kind discriminator; values render via `Value.toString` (TLC's
  canonical rendering, as the REPL uses).
- `tools/gen-core-eval-tests.py` + `desk/test-data/eval-core/*` (9 cases,
  A.tla + A.txt staged to a tempdir A.cfg): oracle-only in `validate.py`,
  byte-stable. Families 1-3 covered: `ev-primitives`/`ev-composites` (values),
  `ev-lookup`/`ev-except`/`ev-model` (functions/records/EXCEPT/model values),
  `ev-sets`/`ev-binders` (enumeration + binders), `ev-errors` (typed failures),
  `ev-config` (config-driven constants).
- Ledger: the broad `tlc-eval`/`tlc-value` claims are replaced by a
  families-1-3 matrix (`tlc-eval-cst` baseline + `tlc-eval-node`,
  `tlc-value-primitive/composite/except/model`, `tlc-enum`, `tlc-binders`,
  `tlc-eval-state/action/error`, `tlc-value-order`), each with a named
  positive/negative fixture. `check-parity.py` clean.

## Key oracle facts (frozen)

- **Config integration works through FastTool.** `ev-config` (`CONSTANT N=5,
  K=3`) yields `Sum IntValue 8`, `Range IntervalValue 1..5`; `ev-model`
  (`MV = m0`, `MS = {a, b, c}`) yields `ModelValue`s and `Mem BoolValue FALSE`
  (m0 ∉ {a,b,c}). So constant/model assignments from WU5 config are the
  natural evaluation-context source (plan family 2/6.2/6.9).
- **Constant-only modules load cleanly**; a spec with a VARIABLE and no INIT
  fails FastTool at config (`SpecProcessor` 2231). So 6.0-6.4 value/eval
  fixtures are constant-only; state/prime/action fixtures (6.6/6.7) need INIT/
  NEXT and an EvalDump *state mode* (evaluate in a TLCState) — deferred there.
- **Canonical renderings captured**: empty interval → `{}`; escaped string →
  `"a\"b"`; DOMAIN of a `1..3` function → `IntervalValue 1..3`; record domain
  → `SetEnumValue {"a", "b"}`; `SUBSET {1,2}` → `SubsetValue {{}, {1}, {2},
  {1, 2}}` (a lazy `SubsetValue`, not eagerly a SetEnumValue); `UNION` and
  `\cup`/`\cap`/`\` → `SetEnumValue`.
- **EXCEPT** captured for function/tuple/record incl. nested `!.b.c`, `@`
  self-reference (`![2] = @ + 100`), and multi-clause (`![1]=7, ![3]=8`).
- **Typed failures** carry the real exception class + message: division by
  zero → `EvalException: The second argument of \div is 0.`; out-of-domain
  application → `TLCRuntimeException: In applying the function <<1,2,3>>, the
  first argument is: 9 which is not in its domain.`. A Java-override type error
  (e.g. `1 + "x"`) yields a message naming the Java method signature — a
  volatile detail to **normalize** when those land in the differential corpus
  (6.8 owns the typed-diagnostic shape and message normalization).

## Value subclass inventory (35 `value/impl/*Value` classes)

- **Required, families 1-3 (Phase B)**: `BoolValue`, `IntValue`,
  `StringValue`, `ModelValue`, `IntervalValue` (6.1 primitives); `TupleValue`,
  `RecordValue`, `FcnRcdValue`, `FcnLambdaValue`, `SetEnumValue` (6.1/6.2
  composites); the `ValueExcept` helper (6.2); the lazy/enumerable set family
  `SubsetValue`, `KSubsetValue`, `UnionValue`, `SetCupValue`, `SetCapValue`,
  `SetDiffValue`, `SetOfFcnsValue`, `SetOfRcdsValue`, `SetOfTuplesValue`,
  `SetOfFcnsOrRcdsValue`, `SetPredValue`, `EnumerableValue`, `UndefValue`
  (6.3/6.4).
- **Deferred family 4 (Phase C, StandardModule overrides / Java methods)**:
  `MethodValue`, `CallableValue`, `OpValue`, `OpRcdValue`, `OpLambdaValue`,
  `UserValue`, `EvaluatingValue`, `PriorityEvaluatingValue`,
  `LazySupplierValue`, `FunctionValue` (abstract base). A StandardModule
  operator reached without a native/core impl must return a typed unsupported
  result, never a value.
- **Deferred family 5**: string ordering by `UniqueString` interning id
  (`tlc-value-order` approved-difference; no dedicated class).
- **Excluded/internal**: `Value` (abstract base), `LazyValue` (evaluation
  wrapper — relevant to lazy operator args in 6.5, tracked there).

## Baseline (current state before B5)

- 37 CST/REPL constant-expression cases (`gen-eval-tests`,
  `tests/lib/tla/eval`) — kept unchanged as the Phase-B smoke suite
  (`tlc-eval-cst`).
- Approved difference: lexicographic string order vs TLC's UniqueString order
  (`tlc-value-order`).
- No semantic-node evaluator (production eval is CST via `eval-text`), no
  general resumable enumerator, no model-value/config integration in the Hoon
  evaluator (the CST evaluator takes bare expression text), incomplete action
  semantics (`check.hoon`'s ad-hoc CST solver).

## 6.1 landed — canonical value layer (2026-07-20)

`desk/lib/tla/tlc/value.hoon`: the canonical value interface the evaluator/
enumerator/fingerprint encoder build on. Molds **alias** eval.hoon's proven
mold (`+$ value value:ev`, tuples = the `%seq` member, a vpair's image field
is `r`) — a freshly-defined `$+`-recursive `$%` overflows the zuse-408 mold
compiler even in an isomorphic shape (`recover: dig: over`), the same fix
config.hoon uses. Implemented:
- `equal`: total, cross-representation (interval↔set, tuple↔function,
  record field-order independent, unnormalized↔normalized), recursive, never
  by rendered string. `set-elems`/`fcn-pairs` coerce; `rec-equal`/`fcn-equal`/
  `elems-equal` compare by mutual membership.
- `normalize`: idempotent, representation-preserving (sets sorted+deduped by
  equality, record fields sorted by key, function pairs sorted by domain;
  intervals/tuples keep their view).
- `vlth`: total private storage order (distinct from TLC comparison), with
  real record/function ordering (eval.hoon's had records/functions collapse
  to a single bucket).
- `compare`: the **partial** TLC `<` operator — integers only, a typed
  failure (`each @sd @t`) on incomparable values, never a convenient total order.
- `render`: matches `Value.toString` — plain-decimal ints (Hoon `scow %ud`
  would dot-group), `1..n` functions as tuples, all-string-domain functions as
  records, else the `(d :> v @@ …)` form, sorted record/set output, escaped
  strings. Verified in dojo against the EvalDump renderings.
- `type-name`, `vkind`, and value constructors (`vin`/`vni`/`vb`/`vs`/`vm`/
  `vintv-c`/`vset-c`/`vseq-c`/`vrec-c`/`vfcn-c`).

Verified correct by direct dojo evaluation (`equal` same-kind + cross-rep
interval=set, `render` int/set, `compare`) — all match.

### CRITICAL zuse-408 finding (blocks the usual test path; affects 6.2-6.9)

A `value` mold **cannot cross a core import boundary without a nest-fail**:
`(render:v (vin:v 42))` evaluates fine in dojo (after `=v -build-file`) but a
test file (`/= v /lib/tla/tlc/value` then the same call) fails to build with
`nest-fail` — the mull re-derives the recursive `$+` fixpoint and the two
structurally-identical instances do not nest. Every automated-test shape
tried failed (direct arms, grouped `;:(weld …)` arms, constructors moved into
value.hoon, an internal `+selftest` returning scalars — the last even broke
value.hoon's own compilation). This is why the 37 existing eval tests only
ever pass `@t` and compare rendered **cords** — a value never crosses a
boundary there. Implications:
- Automated coverage of value.hoon is via the **differential** path (EvalDump
  renders values to text = tape, which crosses cleanly) once 6.5 wires the
  semantic evaluator; unit-level assertions must compare rendered cords, not
  value molds.
- 6.2-6.9 architecture: value operations likely must stay **within one core**
  (a monolith like today's eval.hoon), or be exposed only through
  scalar-returning entrypoints (text in / rendered text or boolean out).
  Verify cross-core value passing before committing to the plan's separate
  value/enumerate/eval/action file split.

## Remaining subunits (dependency order)

6.1 value molds/primitives → 6.2 composites+EXCEPT+model / 6.3 enumeration →
6.4 CHOOSE+binders → 6.5 semantic-node evaluator (retire CST) → 6.6 states/
prime/UNCHANGED → 6.7 action solving+ENABLED → 6.8 FP64 input bytes + typed
errors → 6.9 integrate/bound/close. EvalDump needs a *state mode* (evaluate in
a TLCState) for 6.6/6.7 fixtures.
