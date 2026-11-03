# R4.1c: front-end residue named by R4.0b

```text
Sub-unit: R4.1c (started early: R4.1 does not depend on the census)
Rows: tlc-monolith absent -> partial (MODULE half ported; CONFIG half owed)
      semantic-graph partial (INSTANCE inside LET; Github723 arity; 3 nested)
Found on the way: SANY's module LOAD ORDER, which the port had as a BFS.
```

## 1. Monolith modules: the MODULE half

**Pin behaviour.** The pin is `ParseUnit` → `MonolithSpecExtractor.module`,
reached only once every resolver has missed. It extracts from the **root**
file: from a line matching `-----*\s*MODULE\s+<name>\s*----*` through the next
line matching `====.*`, both markers included.

Both are whole-line matches (`String.matches`), measured with four new
`modres` cases:
- `monolith`: an EXTENDS plus an INSTANCE of trailing blocks;
- `monolith-chain`: one trailing block extends another;
- `monolith-shadow`: a real `B.tla` wins over a trailing `B`;
- `monolith-notwhole`: a header with a trailing comment is NOT a header, so
  the result is a missing-module error.

**Port.**
- `lib/modules` `+monolith-module` does the extraction. `+resolve` calls it
  after the user and standard lookups miss.
- The `%clay` loader (`lib/job` `+load-drain`) does the same. It feeds the
  extracted block back into its own inbox as if it had been read, so
  registration, the size limit, parsing and the name check are shared with a
  real file.
- New test: `tests/lib/clay-load` `test-clay-monolith-trailing-module`.

**Ship results.**
- Flat batch: 14 of the 15 trailing specs now agree.
- Subdir batch: `braf` and `cdot/ActionCompositionDistributive` agree.
- `CyclicRedefineInstance` and `EWD998/EWD998_TTrace` still reject. Their
  trailing modules now resolve; what remains is an INSTANCE inside LET, the
  same as `suite/test59`.

**Owed: the CONFIG half.** `MonolithSpecExtractor.config` reads a `----
CONFIG X ----` block from a `.tla` passed as the config. More than 10
test-model specs carry one. No Examples manifest model uses one. Either port
it or approve the difference; that decision is R4.1c's.

## 2. Found on the way: SANY's module-load order

`monolith`'s golden parsed `A, B, Naturals, C`; the port parsed `A, B, C,
Naturals`. The same happens with three separate files (`order-ext-first`),
so this is a pre-existing divergence. The 13-case corpus never had
`A EXTENDS B; INSTANCE C` with `B` extending a third module.

SpecObj's loop picks the next module as follows:
- any unresolved EXTENDS anywhere in the tree comes before any unresolved
  INSTANCE (`findNextUnresolvedExtention` || `...Instantiation`);
- within each search, depth-first from the root: a module's own unresolved
  names, then its resolved extendees, resolved instancees and inner modules.

`+resolve` now does exactly that (`+own-refs`, `+find-next`). Only the
`SANY -s` "Parsing file" order can observe it. `+sem-order` was already
dependency-first. `modres` passes 18/18.

The `%clay` loader still issues READS in BFS order. That is not observable:
it decides only which missing module is reported first when several are
missing, and `missing-two` agrees.

## 3. Golden normalizer fix

`gen-modres-tests.py` reduced `Parsing file B.tla (/path/A.tla)` to `A`. It
now takes the module before the parenthesis.

## 4. Closed 2026-10-10

### Nested inner module context (`Github725b`, `Github725f`, `Github687spec`)

**Cause, measured.** A nested `---- MODULE Inner ----` sees the parent's
context UP TO the point where the inner module appears: the parent's
EXTENDS, declarations and definitions before it (SANY generates the inner
module in the parent's symbol table). The port built every module's context
from its own EXTENDS only, so `Inner725b`'s `x < 3` had no `<`.

**Port (`lib/semantic`).**
- `+build-ctx-upto tree deps stop` builds a module's context and stops at the
  nested module named `stop`. `+build-ctx` is the `stop = ~` case.
- `+analyze` stores, for each `%inner` module, its parent's partial context
  under `+encl-key` (`+put-encl`); the inner module's imports start from it.

### INSTANCE inside LET (`suite/test59`, `CyclicRedefineInstance`, `EWD998/EWD998_TTrace`)

**Cause.** `g-letin` bound operator signatures only, never a scoped
instance's `M!` members, so `M!xplus1` was undefined.

**Port (`lib/semantic`).** Expression generators lack the module graph, so
the instance is HOISTED to module level, which is where the graph is:
- `+let-mod-defs` finds the `M == INSTANCE ...` defs inside a definition's
  LETs; `+let-scoped` pairs each with the LET-scope context (`+let-ctx`:
  the enclosing LET's definitions in scope, so a LET-local name can be
  substituted, e.g. `WITH N <- k`).
- `+let-insts` generates each with `+g-instance` under that context; the
  `M!` defs and theorems are hoisted, and their symbols (`+let-inst-syms`)
  are put into the context of the definition that contains the LET.
- Evaluation needs nothing new: the LET-local names a substitution uses are
  resolved through the dynamic LET scope.
- Hoon note: wet `turn`/`zing` over these molds inside the recursion is a
  `fuse-loop` compile error; the helpers hand-roll their loops.

### Explicit substitution arity (`WITH C <- F`), the `Github723` residue

Measured at the pin with SemDump (six new sem cases, all byte-exact on the ship):

| case | `WITH C <- …` for `CONSTANT C(_)` | pin DIAGS |
|---|---|---|
| `subst-explicit-ok` | `F(y)` | none |
| `subst-explicit-arity` | `F(x, y)` | 4271 `Expected arity 1 but found operator of arity 2.` at the RHS, then 4243 at 0.0-0.0 (`--TLA+ BUILTINS--`) |
| `subst-explicit-zarg` | `N` (arity 0) | 4271 `... of arity 0.`, then 4243 at 0.0-0.0 |
| `subst-explicit-expr` | `3` | 4004 `Arity 1 operator (not an expression) is expected`, then 4243 at 0.0-0.0 |
| `subst-explicit-appl` | `F(1)` | the same 4004 over the application's span |
| `subst-explicit-zero` | `F(y)` for `CONSTANT C` (arity 0) | 4204 `The operator F requires 1 arguments.` (generateExpression; no 4243) |

`generateSubst` → `generateOpArg` → `checkSubstitutionForCorrectArity`: on
an error `generateOpArg` returns `nullOpArg` (located in the builtins, arity
-2), so the 4243 always follows. The port (`+g-instance` `gsubs`) now does
the same and renders `oparg nullOpArg arity=-2 … 0.0-0.0`; a bare operator
name for an arity-0 constant is no longer an `$OpArg`.

### Found on the way: a bare operator reference (a WRONG ACCEPT)

`G == F` with `F(y) == y` is SANY's 4204 `The operator F requires 1
arguments.` at the reference; the port accepted it. `+g-genid` now reports
it and generates nullODN. An operator ARGUMENT never reaches `+g-genid`
(`+oparg-of` takes it first). New sem case `bare-op-ref`;
`subst-explicit-zero` is the same check inside a substitution.

The check exposed a latent gap in `+g-sel`: only the selector BASE's
arguments were generated against the operator's per-position arities, so
`Foo` in `L!Op(Foo, 9)!lab(1,2,3)` and `I(55)!Op(Foo, 9)!…` (`suite/test219`)
was generated as an expression (formerly a silent `apply Foo`, now the 4204).
`+g-sel` now looks up the qualified member through a leading `%name` chain
(`L!Op`, `I!Op`), and drops the parametrized instance's leading parameters
(`I(55)` fills them) from its `parg`.

### Renderer: the instancee's nodes under an error

Under a generation error SemDump masks the instancing root's levels to L-1,
but NOT the instancee's own nodes: an instanced def's parameters, the
substin body and the `instance` line keep their levels. The port masked
them too, which is why `subst-arity` was withheld. Fixed in the renderer
(`+inst-body`); `subst-arity` is un-withheld and passes.

### Evidence

- tier2 batch 162/162 and subdir batch 329/329 agree; `divergences.txt`
  has no `batch` or `subdir-batch` rows.
- New arms in `tests/lib/neval-mc`: `test-nested-inner-sees-parent` (verdict
  and successors through `S!Step`), `test-instance-inside-let` (verdict and
  successors, with a LET-local `k` substituted for a CONSTANT).
- Examples: `EWD687a` (with its CommunityModules) accepts.

## 5. Still open

- **The monolith CONFIG half** (§1): 10+ test-model specs, no Examples
  manifest model. A decision for the R4.1 close: port it, or approve the
  difference.
