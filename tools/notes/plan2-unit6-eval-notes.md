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

### zuse-408 mull-budget constraint (confirms the single-core architecture)

An external test core has a **very low mull budget for the recursive `value`
mold**: `(render:v (vin:v 42))` — one value construction — builds and passes
in a test file, but more than ~1-2 value-typed expressions in one core (e.g.
five render assertions, or a single two-value `equal:v` call) overflows with a
`nest-fail`/`recover: dig: over` flood. (An earlier note here claimed values
"cannot cross a core boundary at all"; that was wrong — it was stale-revision
noise plus tmux eating the leading `-` of `-test`, which must be sent with
`-l --`. A single value op crosses fine.) This is why the 37 eval tests only
pass `@t` and compare rendered **cords** — a value is never held in the test
core. Consequences (now settled):
- **Architecture: consolidate.** Production value/eval/action operations live
  in a **single core** (a monolith like today's eval.hoon), so values never
  cross a boundary and the mull budget is spent once at lib-compile time, not
  per test. The plan's separate value/enumerate/eval/action file split is not
  viable as independent cores; `value.hoon` is the seed of the one core, and
  6.2-6.9 grow it (or a `tlc/core.hoon`) rather than adding sibling cores.
- **Testing.** Drive the core through **scalar entrypoints** (text in /
  rendered cord or boolean out), exactly as `eval-text` does; keep at most a
  1-op value smoke test per file. Comprehensive value coverage rides the
  **differential EvalDump path** (values → text) once 6.5 wires the evaluator.
- value.hoon itself is verified correct by **direct dojo evaluation** (equal
  same-kind + cross-representation, render, compare) and a 1-op render smoke
  test (`tests/lib/tla/value`).

## 6.2 in progress — composite access (2026-07-21)

Growing value.hoon as the single core (the settled architecture). Landed
`apply` and `domain` + the `eval-err`/`vres` typed-failure shape:
- `apply [f x]`: `f[x]` for a function (domain point matched by `equal`), a
  tuple (1-based integer index), or a record (string field); out-of-domain /
  wrong-selector are typed `vres` failures.
- `domain f`: function domain as a normalized set, tuple domain as `1..n`,
  record fields as a string set.
Verified in dojo: `<<1,4,9>>[2]` → `4`; `[a|->1,b|->2].b` → `2`;
`DOMAIN (1:>10 @@ 5:>20)` → `{1, 5}`; `<<9>>[5]` → typed "applying a tuple
outside its domain: 5". Automated coverage is dojo + differential-at-6.5
(constructing an apply input exceeds the ~1-2-op test-core mull budget).

### 6.2 remaining landed 2026-07-21 — EXCEPT, model values, constructors

`ValueExcept`, model-value semantics, and dup-checked constructors added to
value.hoon; full ship suite `ok=%.y`, all dojo-verified.

- **EXCEPT** (`sel-step`/`except-select`/`except-put`, `sel-res` =
  `(each (unit value) eval-err)`). A selector path is a `(list value)` of
  already-evaluated selectors (fcn/record domain point or 1-based tuple
  index). `except-select` mirrors `Value.select` + `Tool.OPCODE_exc`'s three
  outcomes: `%|` hard failure (EXCEPT on a non-function, or wrong-typed
  selector — tuple non-int, record non-string — propagates); `[%& ~]` miss
  (a step out of domain → skip the whole clause, TLC warns
  `TLC_EXCEPT_APPLIED_TO_UNKNOWN_FIELD`); `[%& `old]` hit (`old` = the
  current value, the `@` binding). `except-put` rebuilds via structural
  `turn`/`snap` (tlc2 `takeExcept`), leaving unmatched steps unchanged and
  earlier values immutable; only ever reached on a hit. Clause folding +
  `@`/replacement evaluation are the 6.5 evaluator's job (fold source-order:
  select → if miss warn+skip, else bind `@`=old, eval rhs, `except-put`).
  Dojo: `[F EXCEPT ![2]=99]`→`<<1, 99, 3>>`; select `![2]`→`@`=2, `![9]`→miss;
  `[R EXCEPT !.b.c=42]`→`[a |-> 1, b |-> [c |-> 42]]`; `[T EXCEPT ![3]=30]`→
  `<<1, 2, 30>>`; multi `![1]=7,![3]=8`→`<<7, 2, 8>>`; EXCEPT on `5`→hard fail.
- **Model values** (`mv-type`/`val-eq`/`member`). Per tlc2 `ModelValue`: a
  name with `length>2 && char[1]=='_'` is TYPED (type = char[0]); else
  untyped (0). Structural `equal` stays total (same name = equal) so models
  sit in sets/domains freely; the typed-comparison FAILURES surface only at
  the semantic `=` (`val-eq`) and `\in` (`member`), both returning
  `(each ? eval-err)`. `val-eq`: two models compare by name when either is
  untyped or types match, else error (differently-typed); a typed model vs a
  non-model errors; otherwise `[%& (equal a b)]`. `member` folds `val-eq`
  over `set-elems` (typed model vs a non-model element → error), guarding
  non-set RHS. Dojo: `m0=m0`→T, untyped `a=b`→F, `a_1=b_2`→err, `a_1=3`→err,
  `m0 \in {a,b,c}`→F, `a \in {a,b}`→T. Config already yields `[%model name]`
  values (cfg-value); wiring constants into the eval context is 6.9.
- **Constructors** (`mk-rec`/`mk-fcn`, `find-dup-key`/`find-dup-dom`). Return
  a `vres`: a repeated record field name (tlc2 `RecordValue.normalize`
  `Assert.fail`) or a repeated function domain point (`FcnRcdValue.normalize`)
  is a typed failure, else the normalized value. Dojo: dup field / dup domain
  both error. Function-constructor domains from `[x \in S |-> …]` arrive
  pre-deduped (S is a normalized set), so dups only reach `mk-fcn` from
  explicit pair lists.

Message text is approximate (single-line, no embedded `\n`); exact
EC-coded/byte-faithful diagnostics are 6.8's job (like `apply`/`domain`).
Remaining 6.2 is closed; next is 6.3 enumeration or 6.5 evaluator wiring.

## 6.3 landed 2026-07-21 — resumable finite enumeration + lazy sets

USER DECISION (locked): lazy sets are a **separate `sexp` descriptor + `enum`
cursor, forced to eager `%set` only at value boundaries** — NOT extra members
of the `value` union (that growth is the zuse-408 recursive-mold hazard). A
key consequence: `sexp` operands are `value`s (a lazy operand is forced
first), so `sexp` is a **flat, non-recursive** `$%` and the cursor never
nests — zero mold risk. Molds compiled in isolation first (plan discipline)
before any logic. Full ship suite `ok=%.y`, all dojo-verified.

Added to value.hoon:
- **`sexp`** (flat union): `%set`/`%cup`/`%cap`/`%diff`/`%union`/`%prod`
  (=set-of-tuples, S1\X…\Xn)/`%fcns` ([D->R])/`%rcds` ([a:S,…])/`%subset`.
- **`ecur`** (flat, jam-safe WU1 continuation) — three shapes, non-recursive
  because every sub-enumeration is a finite value's element list:
  `%elems es i` (linear: set/interval/cup/cap/diff/union, element list
  precomputed in `enum`), `%odo dims ix mk dom ks done` (exponential:
  product/fcns/rcds — odometer, **rightmost dim fastest** = tlc2
  SetOfTuples/Fcns/Rcds), `%subset es k comb done` (tlc2 cardinality order).
- **`enum`** sexp→`(each ecur eval-err)`; **`enum-next`** cur→`[estep ecur]`
  (`estep`=`%item`/`%done`), one bounded element per step, cursor is the
  continuation; **`force`** sexp→`(each value eval-err)` drains + normalizes
  to a deduped `%set`, rejecting `>max-card`(1e6) / SUBSET arg `>20` as typed
  overflow (`cur-bound`: exact product/2^n, upper bound otherwise);
  **`enum-tapes`** = ordered render list (test witness, returns tapes so no
  value crosses a low-budget test core).
- **Lazy `set-member`/`set-empty`** — decided structurally on the descriptor,
  never materializing: verified `{7} \in SUBSET (1..25)`→T and
  `SUBSET (1..25)` non-empty with NO overflow (while `force` correctly
  rejects it). `set-empty` = one `enum-next` step.
- Helpers: `elemsof-e` (non-enumerable→typed err), `elemsof-all`, `memb`
  (structural), `odo-current`/`odo-advance`, `next-comb`/`subset-advance`,
  `zip-vp`/`zip-vf`/`odo-build`, `cap-mul`.

Dojo-verified ORDER vs TLC: `{1,2}\X{3,4}`→`<<1,3>>,<<1,4>>,<<2,3>>,<<2,4>>`;
`[1..2->{5,6}]`→`<<5,5>>,<<5,6>>,<<6,5>>,<<6,6>>`; `SUBSET{1,2,3}`→
`{},{1},{2},{3},{1,2},{1,3},{2,3},{1,2,3}`; `cup` keeps dups in order
`1,2,2,3` (force→`{1,2,3}`); `cap`/`diff`/`union`/`rcds` all match; empty
range→no fcns, empty domain→one `<<>>` fcn. Pause/resume: a mid-enumeration
cursor `=(c ;;(ecur (cue (jam c))))`→`%.y`, and `enum-next` is a pure gate of
it ⇒ save/load equivalence by construction.

DEFERRED to 6.4 (need the evaluator to test a predicate / map an expr): set
predicate `{x∈S:P}` and set-of-all `{e:x∈S}` cursors — thin filter/map layers
over an existing `ecur`, wired when the evaluator exists. Per-`next` WU1
budget accounting is wired at 6.9 integration (each `enum-next` = one bounded
step; the caller loops against the budget). Comprehensive coverage rides the
differential EvalDump path once 6.5 wires enumeration into expression eval.

## 6.4 landed 2026-07-21 — CHOOSE, binders, enumerable constructors, control

These evaluate expression BODIES (predicates, images, guards, branches),
which is the 6.5 semantic-node evaluator's job — so they are **gate-
parameterized combinators over the 6.3 cursor**: the 6.5 evaluator supplies
each gate as `|=(v (eval node ctx(x v)))` over a jam-safe (node, context)
pair, and the resumable state stays the 6.3 `ecur`. Tested now with Hoon
gates; full ship suite `ok=%.y`, all dojo-verified. Gate type aliases:
`vpred`/`vmap` (single-binder value→bool/value), `vthunk`/`bthunk` (deferred
value/bool branches), `cpred`/`cdom` (multi-binder predicate / prefix-
dependent domain).

Added to value.hoon:
- **Streaming primitives**: `stream-find` (first element satisfying p,
  short-circuit), `stream-collect` (fold keep/drop over the cursor).
- **Quantifiers** `ex-over`/`all-over` (single `sexp`, short-circuit on first
  witness/counterexample, typed error propagation). **`choose-over`** = CHOOSE
  x∈S:P — deterministic first satisfying element in TLC enumeration order
  (a pure fn of the cursor ⇒ stable across pause/resume), typed failure when
  none satisfies.
- **Enumerable constructors**, all streamed through the lazy `ecur` (never
  eagerly expand the source): `filter-over` (`{x∈S:P}`), `map-over`
  (`{e:x∈S}`, dedup-normalized), `fcn-over` (`[x∈S|->e]`). (`SUBSET`/`UNION`/
  record/tuple set constructors are the 6.3 `sexp`; `DOMAIN` is 6.2.)
- **Multi-binder context enumeration** `ctx-go` + `ex-ctx`/`all-ctx` over a
  `(list cdom)`: nested streamed cursors, each domain gate sees the prefix
  bound so far ⇒ **dependent bounds** (`\A x∈S, y∈T(x):P`). Short-circuit
  threads through. TUPLE DESTRUCTURING (`<<x,y>>∈S`) is transparent here — the
  enumeration yields the element; the 6.5 evaluator destructures it into
  x,y when building the eval-context from each tuple.
- **Control** with short-circuit error suppression (only the selected branch
  runs): `if-val` (non-bool guard = typed error), `case-val` (guards lazy in
  order, first-true body, else OTHER, else typed "no case"), `conj-list`
  (short-circuit on first FALSE), `disj-list` (on first TRUE).

Dojo-verified: `\A x∈1..3:x∈1..3`→T, `…:x∈{1,2}`→F; `\E x∈1..5:x=4`→T;
`CHOOSE x∈1..10:x=5`→5, no-match→typed err; `{x∈1..6:x∈{2,4,6}}`→{2,4,6};
`{{x}:x∈1..3}`→{{1},{2},{3}}; `[x∈1..3|->x]`→<<1,2,3>>; IF-true suppresses
else-error; CASE picks first-true guard's body (other bodies' errors
suppressed); conj/disj short-circuit and suppress later errors; multi-binder
`\E/\A x∈1..2,y∈1..2:x=y`→T/F; dependent `\E/\A x∈1..3,y∈1..x:x=y`→T/F.

DEFERRED: budget-exhaustion-immediately-before/after-a-match tests need WU1
budget threading through the cursor (6.9 integration; the combinators already
stream + short-circuit, so slicing wraps them via the `ecur`). Message text
approximate (6.8 owns exact bytes). The gates become node-backed and the
whole thing resumable when 6.5 fuses these with the semantic-node evaluator.

## 6.5 landed 2026-07-21 — semantic-node evaluator (retires CST eval)

New `desk/lib/tla/tlc/node-eval.hoon`: a dispatcher over the WU3 `sem` graph
producing values via the 6.1-6.4 core. Imports `v` (value) and `sm`
(semantic, for `sem` types + `generate`). All 37 REPL baseline cases pass
through it (`tests/lib/tla/node-eval.hoon`, adapted from the CST test), plus
14 probe cases (`tests/lib/tla/neval-probe.hoon`).

- **Context** = two maps, NOT a tagged union (unioning recursive `value` +
  `sem-def` risks the mold hang): `eenv=[vals=(map @t value) ops=(map @t
  sem-def) atv=(unit value) fuel=@ud]`. `vals` = constants/bound-vars/
  expression-params; `ops` = module/LET operator defs + op-valued params;
  `atv` = the EXCEPT `@`; `fuel` = recursion budget.
- **Dispatch** (`eval` over `-.n`): `%lit`/`%atref`/`%nullodn`/`%letin`/
  `%apply`. `eval-apply` routes by op kind: `%builtin`→`eval-builtin`,
  `%constant`/`%new-constant`→val lookup, `%user-op`/applied `%formal-param`→
  `eval-user`, bare `%formal-param`→val lookup, `%variable`→typed 6.6 stub.
- **Laziness kept**: `eval-domain` returns a lazy `sexp` for set-denoting
  positions (SUBSET/UNION/cup/cap/diff/times/setoffcns/setofrcds), used by
  `\in`/`\subseteq`/binders so an exponential domain is never forced; a set
  used as a plain value is `force`d.
- **Builtins**: =,/=,¬,∧,∨,⇒,≡,ConjList/DisjList (short-circuit),∈,∉,⊆,
  set ctors (forced), DOMAIN, FcnApply, Except (via except-select/@/put),
  SetEnumerate, Tuple, RcdConstructor/RcdSelect ($Pair/str-lit args),
  IfThenElse, Case (OTHER = nullodn guard), Bounded Forall/Exists/Choose,
  SubsetOf/SetOfAll/FcnConstructor (single binder), quantifiers multi-binder
  via `all-ctx`/`ex-ctx`.
- **Native table** (`native-set`): StandardModule `%user-op`s with no body —
  +,-,*,^,\div,%,<,>,\leq,\geq,..,\o,Len,Head,Tail,Append,Cardinality —
  supplied natively (family 4 proper deferred; unknown bodyless op = typed
  unsupported). `eval-user`: module def→bind params (unused expr param not
  evaluated = lazy arg; op-valued param→bind def)→eval body w/ fuel-1; else
  native; else unsupported.
- **`eval-text`** = the CST-retirement entrypoint (wrap `Expr == <txt>`
  EXTENDS Integers/Sequences/FiniteSets → generate → eval the def body →
  render). `eval-dbg` surfaces the typed error (debugging).

**Two WU3 generator gaps fixed in semantic.hoon** (were ungenerated → null):
- `%n-fcnconst` (`[x\in S|->e]` expression): new `g-fcnconst` emits
  `$FcnConstructor` (binders + body); reusing `g-fcn-body` was wrong — it
  reads the body's identifier as a function name and false-flags recursion.
  Body = last NODE kid (rear-of-all-kids grabs the `]` token).
- `%n-otherarm` (CASE `OTHER`): `g-case` skimmed only `%n-casearm`, dropping
  OTHER entirely; now includes it as a `$Pair` with a `%nullodn` guard (tlc2
  null first component), which `eval-case` recognizes as the default.

## 6.6 landed 2026-07-21 — states, prime, UNCHANGED

node-eval.hoon `eenv` gained `s0`/`s1` states + `primed`/`enabled` control
bits (the EvalControl subset). `+$ state (map @t value)` keyed by variable
identity (name); absence = unassigned = a typed read failure. All 8
state/prime/UNCHANGED cases green (`tests/lib/tla/neval-state.hoon`), full
suite unaffected.

- **Variable resolution** (`lookup-var`, wired into `eval-apply`'s
  `%variable` arm): from `s1` under a prime, else `s0`; an unassigned read is
  a typed failure (distinct message for the primed/successor vs current
  case).
- **Prime** (`'`, builtin arity-1 weight-0): evaluate the operand with
  `primed=&` — priming distributes to variable references (a constant/op is
  prime-invariant). Nested prime is a WU4 level error; an unassigned primed
  variable is a typed failure.
- **UNCHANGED e** (`eval-unchanged`): `e' = e` — `val-eq` of the successor
  (primed) and current evaluations; tuples/composites compare structurally.
- **Predicate entry points**: `eval-pred [root src nm s0 s1]` → `(each ?
  eval-err)` requiring a boolean — a constant predicate passes empty states,
  a state predicate only `s0`, a fully-assigned action predicate both.
  `base-env` builds the env for a module's defs under given states.
- `x' = e` needs no special casing at 6.6: `x'` already resolves from `s1`,
  so an equality is `bi-eq` of the primed LHS and the current RHS. Assignment
  vs filtering (partial successor solving) is WU6.7.

DEFERRED to 6.7: partial-successor action solving, ENABLED existential search
(the `enabled` bit is carried but unused). EvalDump still needs a STATE MODE
for differential fixtures (6.0 note); 6.6 is dojo/probe-verified with
hand-built states. Substitution-around-prime needs INSTANCE ($SubstIn, a 6.5
residue).

## 6.7 landed 2026-07-21 — action solving + ENABLED

node-eval.hoon gained the semantic-node action solver (`solve` + friends) —
the replacement for check.hoon's ad-hoc CST `gen`. All 6 cases green
(`tests/lib/tla/neval-action.hoon`); full suite unaffected. `eenv` gained
`vars=(set @t)` (declared VARIABLE names, from `vars-of`) so assignment is
decided by variable IDENTITY, never rendered names. `+$ sres = (each (list
state) eval-err)`.

- **`solve [n mode cur part e]`** mirrors tlc2 getInitStates/getNextStates +
  ActionItemList: `$ConjList`/`\land`→`solve-conj` (thread the partial state
  left-to-right), `$DisjList`/`\lor`→`solve-disj` (branch from the same
  partial), `$IfThenElse`→eval guard then the taken branch, `$BoundedExists`→
  `solve-exists` (branch over the domain in enumeration order via
  `drain-sexp`), `UNCHANGED`→`solve-unchanged` (assign each named var to its
  current value), `=` whose LHS is an ASSIGNABLE unbound state var
  (`assignable-sem`: unprimed var in %init / primed var in %next, declared,
  not yet in `part`)→ASSIGN, everything else→`solve-filter` (prune when
  false). `senv` builds the eval env: %init reads the partial under plain
  names (`s0=part`), %next reads `x` from `cur` and `x'` from the partial
  (`s0=cur, s1=part`).
- **Entry points**: `solve-init`/`solve-next [root src nm (cur)]` → `sres`,
  each checking every state assigns ALL vars (else typed incomplete-init/next
  failure — tlc2's incomplete-state error). `render-states` = stable
  `k=<v>,…` per state in stream order for differential comparison.
- **`ENABLED A`** (`eval-enabled`, wired into eval-builtin): solve A in %next
  from the current state, TRUE iff a COMPLETE successor exists (witness
  discarded). Conflicting assignment (`x'=x /\ x'=x+1`: second `=` filters
  since x' is bound → false) ⇒ no successor ⇒ FALSE.

Verified: Init→1 state; Next disjunction→2 successors in branch order; `\E
d\in1..2 /\ UNCHANGED y`→domain order; y'-unassigned action→incomplete
failure; ENABLED witness→T, conflicting→F.

DEFERRED: (1) wiring `solve` into check.hoon's BFS (replacing `gen`) + the
job continuation — an integration step that touches WU1's kernel, folded
into 6.9. (2) RESUMABILITY/budgeting the solver (persist action stack, domain
cursors, branch position) — the solver is currently eager/streaming; 6.9
owns the resumable wrapper. (3) ENABLED first-witness short-circuit (correct
but computes all successors then tests; fine for finite domains). (4) multi-
binder action `\E`. EvalDump STATE MODE still owed for oracle-differential
init/next fixtures.

## 6.8 landed 2026-07-25 — canonical FP64 input bytes + typed-error shape

value.hoon gained `fp-input : value -> (list @D)`, the exact byte stream tlc2
folds into FP64 (the INPUT contract; WU7 owns the hash). Reproduces
`Value.fingerPrint` Extend order from the pinned tree: a KIND tag byte then
components, `Extend(int)`=4 bytes LITTLE-ENDIAN, `Extend(byte/char)`=1 byte,
`Extend(String)`=chars; value NORMALIZED first. 13-case differential green
(`tests/lib/tla/neval-fp.hoon`); full suite unaffected.

- **Kind bytes** (tlc2 ValueConstants): BOOL 0, INT 1, STRING 3, SETENUM 5,
  FCNRCD 9, MODEL 22. **Cross-representation collapse** (the key insight):
  tlc2 fingerprints an INTERVAL as a SetEnum of its ints, and a TUPLE/RECORD
  as an FcnRcd (int-keyed 1..n / string-keyed) — so interval=set,
  tuple=function, record=function coincide byte-for-byte, exactly matching
  +equal's cross-rep equalities. `fp-enc` therefore encodes intv→SETENUM,
  seq→FCNRCD int keys, rec/fcn→FCNRCD (string/domain keys), all sorted by
  normalize. `int32-le` does 32-bit two's-complement LE (verified:
  `fp-input(-7)` = `[1 249 255 255 255]`).
- **Deviations documented**: (1) MODEL values — tlc2 folds the UniqueString
  interning id `tok` (UniqueString.fingerPrint = Extend(tok)), NOT
  reproducible = the deferred family-5 difference; we fold the model NAME
  instead (still injective over model values, not tlc2-byte-identical). (2)
  Non-ASCII strings — tlc2 folds UTF-16 low bytes + `length()` in chars; we
  fold UTF-8 bytes + byte count (identical for ASCII). STRINGS otherwise
  fingerprint by content (reproducible), only MODEL uses tok.
- **Hoon gotcha**: `turn`/`zing` over the recursive `value` mold fuse-loops
  the zuse-408 compiler — `fp-enc`'s list recursions are hand-rolled (`fp-set`
  + inline `|-`), never `turn`.
- `fp-of-text` (node-eval): fingerprint bytes of a constant expression, driven
  by text so no value crosses a low-budget test core.

Typed error taxonomy (task 4): node-eval defines the single `ev-diag` shape
`[code category msg at stack recoverable]` + `ec-category`
(undefined/type/non-enumerable/resource/incomplete/comparison/arithmetic/
no-case/choose-empty/except/unsupported/runtime) + `to-diag` lifter. Per-site
emission (replacing the bare `[code msg]` eval-err with real EC numbers +
spans + op stack) and the EvalDump error-fixture differential (task 5) are the
follow-on sweep — the shape/category contract is defined now.

Also fixed a small evaluator gap: unary minus `-7` (generated as `-` with one
arg) now negates in `eval-native`.

## Remaining subunits (dependency order)

6.1 value molds/primitives → 6.2 composites+EXCEPT+model / 6.3 enumeration →
6.4 CHOOSE+binders → 6.5 semantic-node evaluator (retire CST) → 6.6 states/
prime/UNCHANGED → 6.7 action solving+ENABLED → 6.8 FP64 input bytes + typed
errors → 6.9 integrate/bound/close. EvalDump needs a *state mode* (evaluate in
a TLCState) for 6.6/6.7 fixtures.
