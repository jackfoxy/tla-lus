# Work Unit 4 Plan: Complete Level Checking and Linting

## Objective

Complete SANY-compatible level checking and record-constructor linting on top
of the typed semantic graph from Work Unit 3. The result must preserve partial
semantic graphs after recoverable errors and match the pinned Java oracle for
levels, constraint sets, diagnostics, severity, source spans, suppression, and
ordering.

This plan is stand-alone. It refines Work Unit 4 (Phase B step B3) from
`PORT-COMPLETION-PLAN-2.md` and uses the pinned Java tree at
`4ba7d8811289fb8e95dac4d5e554c05216ba3100` as the behavioral oracle.

## Scope

In scope:

- Levels 0 (constant), 1 (state), 2 (action), and 3 (temporal).
- Level parameters and level constraints.
- Argument-level constraints and argument-level parameters.
- Operator argument maximum levels, weights, and level conditions.
- Recursive-definition fixpoint checking.
- Node-specific level rules, including prime, temporal operators, actions,
  quantifiers, `ENABLED`, `UNCHANGED`, fairness, instances, and substitutions.
- Level validation hooks needed by later TLC configuration processing.
- `Linter.java` record-constructor field-name checks and warning controls.
- SANY-compatible diagnostics and normalized differential evidence.

Out of scope:

- Building semantic nodes that belong to Work Unit 3.
- Parsing and applying `.cfg` files, which belongs to the TLC configuration
  unit. This unit provides typed level-query and validation interfaces for it.
- TLC expression evaluation or model checking.
- Java implementation structure, mutable collections, or global state.

## Preconditions

1. Work Unit 1's continuation and work-budget molds exist before level
   checking is connected to Gall.
2. Work Unit 3 supplies stable semantic identities, resolved operator
   applications, operator arguments, recursive sections, instances,
   substitutions, assumptions, theorems, and recoverable sentinel nodes.
   Known Work Unit 3 residue that this unit must not assume exists:
   `APSubstIn`, subexpression `!`-navigation, `BY`/`QED` proof steps, the
   IR-native `@`-context, and the wider `SemDump` projection. Instance
   operator levels currently use the documented
   `max(export-level, substitution-levels)` approximation that subunit 4.6
   removes.
3. The pinned `tla2tools.jar` and `tools/oracle/SemDump.java` build cleanly.
4. The working tree already carries a large uncommitted Work Unit 4 first
   increment: level/lint additions in `desk/lib/tla/semantic.hoon`, new cases
   in `desk/tests/lib/tla/sem.hoon`, a `SemDump` extension, and the
   `lvl*`/`lint*`/`recmut` fixture families under `desk/test-data/sem/`.
   Treat it as user work: audit and preserve it; do not replace or reformat
   it wholesale. Subunit 4.0 must first establish which of these fixtures
   already pass.

If a required Work Unit 3 node is absent, add a failing fixture and record the
dependency. Do not hide the gap with a guessed level or a successful fallback.

## Required Architecture

Prefer these component boundaries:

```text
desk/lib/tla/semantic/
  types.hoon       semantic and level-result molds
  constraints.hoon level and argument-level set operations
  levels.hoon      node checks and recursive fixpoint driver
  lint.hoon        record-constructor lint rules
  render.hoon      normalized oracle projection
```

This refines the `lib/tla/semantic/` layout in `PORT-COMPLETION-PLAN-2.md`
(adds `constraints.hoon`; `context`/`generate`/`substitute` remain Work Unit 3
owners). The current implementation is concentrated in
`desk/lib/tla/semantic.hoon`. Split only along tested boundaries and only when
the local import/mold compiler supports the split without changing behavior.
Do not make file movement a prerequisite for parity. Do not grow the
`$+`-recursive `$sem` union with new members: the zuse-408 mold compiler
hangs on that; encode new variants inside existing members as the `$SubstIn`
reserved-apply precedent does.

Required pure nouns:

- `level-param`: the symbol or operator parameter on which a level depends.
- `level-constraint`: parameter plus maximum permitted level.
- `arg-level-param`: operator parameter, argument position, and referenced
  level parameter.
- `arg-level-constraint`: operator parameter, argument position, and minimum
  required level.
- `level-data`: computed level plus all four constraint collections.
- `level-result`: partial graph, ordered diagnostics, and success/fatality.
- `lint-options`: warning suppression/elevation settings.

Use stable semantic identities as keys. Rendered names and rendered nodes are
not internal identity.

## Work Breakdown

### 4.0 Inventory the Oracle and Freeze the Baseline

Java owners:

- `LevelNode` and every node-specific `levelCheck` implementation.
- `SetOfLevelConstraints`, `SetOfArgLevelConstraints`, and `ArgLevelParam`.
- `OpDefNode`, `OpApplNode`, `SubstInNode`, `APSubstInNode`, and
  `InstanceNode` level behavior.
- `BuiltInOperators` level metadata.
- `Linter.java` and its call sites.
- SANY semantic tests and error-code/message owners.

Tasks:

1. Add a parity-ledger row for every included owner and rule family.
2. Extend `SemDump` only with stable fields needed to observe levels,
   constraints, diagnostics, and lint results; exclude volatile Java UIDs.
3. Classify existing `desk/test-data/sem` cases by rule family, starting from
   the already-present `lvl*`/`lint*`/`recmut` families.
4. Capture at least one smallest positive and one smallest negative fixture per
   family before changing Hoon behavior.
5. Run the current generated semantic suite and record the exact baseline,
   including which of the uncommitted level/lint cases already pass.
6. Record the oracle's two-phase gating as normative: SANY runs level
   checking only when semantic generation produced no errors, so any semantic
   error renders every level as `-1`; a level-check error instead leaves
   computed levels visible and adds `D`-line diagnostics. The current
   renderer's blanket mask-to-`-1` on any error must be refined to
   distinguish these phases.

Done when the owner-to-fixture matrix is complete and every later subunit has a
named failing oracle case.

### 4.1 Add Canonical Constraint Types and Set Algebra

Tasks:

1. Define the four constraint molds and `level-data` without Java-specific
   collection structure.
2. Implement deterministic insert, lookup, union, equality, and normalization.
3. Match Java merge direction exactly: level constraints retain the tighter
   maximum; argument-level constraints retain the stronger minimum.
4. Define stable ordering for rendering and diagnostics independently of Hoon
   map tree shape.
5. Add table-driven Hoon tests for empty, duplicate, conflicting, and
   differently ordered merges.

Done when set operations are pure, order-independent internally,
deterministically rendered, and differentially checked on small operator
definitions.

### 4.2 Port Bottom-Up Levels and Basic Operator Constraints

Tasks:

1. Compute levels and constraint data for declarations, literals, formal
   parameters, operator definitions, applications, `LET`, and bounded and
   unbounded quantifiers.
2. Port built-in operator level, argument-weight, argument-maximum, and level
   condition tables from the pinned Java source.
3. Preserve SANY's `-1` level for an unreferenced formal parameter.
4. Check ordinary operator application arity and argument maximum levels.
5. Emit the exact diagnostic code, span, message, and order on recoverable
   failures.

Done when first-order positive and negative cases match the normalized Java
projection, including complete constraint collections.

### 4.3 Port Higher-Order Operator Rules

Tasks:

1. Represent operator-valued formal parameters and operator arguments without
   collapsing them into ordinary expression arguments.
2. Compute and propagate argument-level parameters.
3. Enforce argument-level constraints at higher-order applications.
4. Cover zero-arity, mixed expression/operator parameters, nested
   higher-order applications, unused parameters, and arity mismatches.
5. Add adversarial fixtures in which direct numeric levels agree but Java
   rejects the expression because a constraint is violated.

Done when higher-order acceptance and rejection cannot be reproduced by the
old direct-level-only algorithm and still match SANY.

### 4.4 Port Recursive Fixpoint Checking

Tasks:

1. Initialize recursive operator signatures with SANY-compatible provisional
   data.
2. Iterate levels, weights, maximum levels, level parameters, and argument
   constraints using Java-equivalent convergence rules.
3. Cover self recursion, mutual recursion, higher-order recursion, recursive
   functions, and unused recursive arguments.
4. Detect non-convergence as a typed internal failure with context; never loop
   without a bound.
5. Verify that fixture order and definition order do not alter the fixed point
   except where SANY specifies ordering.

Done when all recursive fixtures match final levels, constraints, and
diagnostics, and the convergence bound is tested.

### 4.5 Port Node-Specific Level Rules

Implement in small, independently green slices:

1. Prime and nested-prime restrictions.
2. `ENABLED` and `UNCHANGED` operand restrictions.
3. Action composition and action subscript rules.
4. Temporal operators and temporal quantifier bounds.
5. `WF_`, `SF_`, and other fairness/action combinations.
6. Assumption, theorem, and proof-body level requirements. Existing `thm*`
   fixtures were deliberately kept constant-level because non-constant
   `ASSUME` is a SANY 4206 level error; add those negative fixtures here.

For each slice:

- Add the smallest failing Java fixture first.
- Add boundary cases at levels immediately below, at, and above the limit.
- Check diagnostic code, message, primary span, related spans, severity, and
  ordering.
- Confirm the partial graph remains usable after recoverable failure.

Done when every included semantic node kind has an explicit rule or a
parity-ledger rationale showing that the generic rule is authoritative.

### 4.6 Port Instance and Substitution Constraints

Tasks:

1. Re-level substituted operator bodies rather than approximating their level
   as `max(exported-level, substitution-levels)`.
2. Apply explicit and implicit `INSTANCE ... WITH` substitutions in declaration
   order.
3. Propagate constraints through `SubstIn` and `APSubstIn`.
4. Cover named, unnamed, local, imported, and re-exported instances.
5. Match illegal-substitution and wrong-level diagnostics, including spans in
   the correct origin module.
6. Expose a pure validation gate for later `.cfg` targets: required maximum
   level, resolved symbol, and structured diagnostic result.

Done when cross-module and higher-order substitution cases match SANY without
the existing max-level approximation.

### 4.7 Port Record-Constructor Linting

Tasks:

1. Port the record-field-name collision rule from `Linter.java`.
2. Match which declarations and definitions are visible at the record
   constructor's location.
3. Match warning code, text, field span, severity, and deterministic order.
4. Port suppression and warning-to-error behavior through explicit
   `lint-options`; do not use global state.
5. Cover no collision, local collision, imported collision, repeated fields,
   nested records, suppression, and elevation.

Done when lint fixtures match the Java result under every supported warning
mode and linting remains independently selectable by the analyze pipeline.

### 4.8 Integrate, Bound, Document, and Close

Tasks:

1. Make level checking and linting explicit pure pipeline stages consuming the
   Work Unit 3 graph.
2. If traversal can exceed one Gall event's work budget, provide versioned
   `init`/`step` cursors and pause/resume tests at every boundary. Any new
   cursor must fit the jammed `$kont` continuation without adding members to
   a `$+`-recursive `$%` union (zuse-408 mold-compiler hang); reuse or
   extend existing `$kont` members.
3. Wire `%analyze` level/lint flags only after the real stages exist. Until
   then, retain typed rejection rather than a plausible `%ok`.
4. Regenerate oracle fixtures and run the complete ship suite.
5. Update `desk/doc/parity-manifest.md`, `desk/doc/port-map.md`, and
   `desk/doc/compatibility.md`; remove only limitations proved closed.
6. Run a style review: lowercase hyphenated names, two-space indentation,
   explicit contracts, bounded lines, contextual crashes, and one major
   component per file where practical.

Done when the focused and full gates pass, analyze requests return the real
ordered diagnostics, and every Work Unit 4 ledger row is `parity` or a tested
`approved-difference`.

## Dependency Order

```text
4.0 -> 4.1 -> 4.2 -> 4.3 -> 4.4
                  \-> 4.5
4.3 + 4.4 + Work Unit 3 instances/APSubstIn -> 4.6
4.0 + Work Unit 3 record nodes             -> 4.7
4.5 + 4.6 + 4.7                            -> 4.8
```

`4.5` can proceed by rule family after `4.2`. `4.7` is independent of
recursive and substitution work. Keep each subunit reviewable and green before
starting the next dependent subunit.

## Test Matrix

| Family | Required evidence |
|---|---|
| Constraint algebra | Unit tests for merge, normalization, equality, and deterministic render |
| Basic levels | Literals, declarations, definitions, applications, `LET`, quantifiers |
| Higher order | Operator arguments, max levels, weights, arg-level parameters and violations |
| Recursion | Self, mutual, higher-order, function recursion, stable convergence |
| Node rules | Prime, actions, temporal nesting, `ENABLED`, `UNCHANGED`, fairness |
| Substitution | Explicit/implicit `WITH`, `SubstIn`, `APSubstIn`, origin spans |
| Config contract | Pure acceptance/rejection by target kind and required maximum level |
| Lint | Collision/non-collision, visibility, suppression, elevation, ordering |
| Recovery | Partial graph plus all ordered diagnostics after multiple recoverable errors |
| Integration | `%analyze` flags, work-budget behavior, pause/resume if cursorized |

Every differential case compares the stable fields that Java exposes. Do not
accept verdict-only comparisons.

## Validation

Run after every subunit:

```bash
python3 tools/gen-sem-tests.py
python3 tools/validate.py --check
python3 tools/check-parity.py --check
```

Before closing the unit, also run `tools/scaffold-gate.sh` (all nine gates).

Run the focused Hoon semantic suite on the project fake ship, followed by the
complete desk suite using the command documented in `desk/doc/testing.md`.
Record the exact command and result in the subunit handoff because the ship
name and pier location are environment-specific.

Before closing Work Unit 4, also verify:

1. Regeneration is byte-identical on a second run.
2. The pinned Java oracle, not a different checkout, produced every golden.
3. No generated Hoon test file was edited by hand.
4. No unsupported level or lint path returns `%ok`.
5. Existing lexer, parser, module-resolution, and semantic-graph tests remain
   green.

## Per-Subunit Handoff

```text
Subunit:
Java owner and entry method:
Current Hoon owner:
Smallest failing parity case:
New or changed nouns:
Diagnostic/result expected:
Focused validation result:
Full validation result:
Pause/resume evidence, if applicable:
Parity-manifest rows changed:
Compatibility limitations removed or added:
Remaining dependencies:
```

## Final Acceptance

Work Unit 4 is complete only when:

- Levels and all constraint collections match the pinned SANY oracle across
  the selected positive and negative corpus.
- Recursive and higher-order checks reach Java-equivalent results.
- Prime, action, temporal, fairness, instance, and substitution violations
  emit matching structured diagnostics in matching order.
- Record-constructor lint behavior, suppression, and elevation match Java.
- Recoverable errors return a partial typed graph; fatal errors are explicit.
- The later TLC configuration unit can validate targets through a typed pure
  interface.
- Focused tests, full desk tests, oracle regeneration, documentation checks,
  and style review pass with no unexplained fallback.
