# R4.1c: front-end residue named by R4.0b (in progress)

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

## 4. Still open in R4.1c

- **INSTANCE inside LET.** Affects `suite/test59`, `CyclicRedefineInstance`
  and `EWD998/EWD998_TTrace`. The parser already accepts `M == INSTANCE ...`
  in a LET, via `finish-def`. The gap is semantic generation: `g-letin`
  binds only operator signatures, never a scoped instance's `M!` members.
- ~~`sany/Github723`, a WRONG ACCEPT~~ **CLOSED.** The port now runs
  SANY's `checkSubstitutionForCorrectArity` (EC 4243) on an IMPLICIT
  substitution, located at the INSTANCE unit (pin: `line 3, col 1 to line 3,
  col 10`). New sem case: `subst-arity`. The EXPLICIT path (`WITH C <- F`) is
  different at the pin: `generateOpArg` reports `Expected arity 1 but found
  operator of arity 2.` first, then a 4243 located in `--TLA+ BUILTINS--`,
  and a value substituted for an operator constant draws `Arity 1 operator
  (not an expression) is expected...`. It is unmeasured against the port and
  is a residue of this row.
- **The 3 nested-only rejects** (`Github725b`, `Github725f`,
  `Github687spec`): cause unmeasured.
- **The monolith CONFIG half** (§1).
