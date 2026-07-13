# Compatibility Notes

Intentional differences between `%tla-lus` and the pinned Java TLA+
toolchain (SANY / PlusCal / TLC). Each entry states the difference and why
it exists. Differential tests use normalized oracle output; anything listed
here is a deliberate, documented divergence rather than a latent bug.

## Release matrix

| Property | Value |
|---|---|
| Oracle pin (SANY/PlusCal/TLC) | `tlaplus@4ba7d8811` (MIT) |
| Example/fixture pins | `tlaplus-Examples@47b0e2cc`, `vscode-tlaplus@acc095d6` (MIT) |
| Agent state version | `%1` (migrates from `%0`; `lib/tla/migrate`) |
| Kelvin | `sys.kelvin` = `[%zuse 411 410 409 408]` |
| Release gate | `tools/release-gate.sh` (8 gates) + `-test /=tla-lus=/tests ~` |
| Differential integrity | `tools/validate.py --check` — all goldens reproduce byte-identically from the pin |

The desk contains **no** GUI, Toolbox, `tla2tex`, or Java code or
dependencies; the Java `tla2tools.jar` is used only to build the differential
goldens and is never shipped or called at runtime. The only vendored upstream
text is the MIT `StandardModules` (`lib/tla/stdmods.hoon`, with its provenance
header). Everything the release gate audits — pin, golden reproducibility,
no-GUI/no-Java, MIT provenance, kelvin, `%0→%1` migration, bounded fixture
sizes, and the desk manifest — is checked by `tools/release-gate.sh`.

## Unit 4 — Syntactic analyzer

- **Error-message text for rejected parses is not reproduced.** REJECT/ACCEPT
  verdicts match SANY exactly (all 261 corpus cases), and accepted trees match
  node-for-node, but the human-readable text of syntax-error messages is not
  yet byte-compatible. Diagnostic *codes* and source spans are preserved.

## Unit 5 — Module resolution

- Clay stores each module under its **lowercased** name, because Clay path
  segments cannot carry case. The case-sensitive declared-name check still
  runs in `resolve`, so a file/module-name mismatch is still detected.

## Unit 6 — Semantic graph construction

The differential oracle is a normalized semantic tree (`tools/oracle/SemDump.java`),
not raw `XMLExporter` XML. Two fields present in the XML are intentionally
omitted from the normalized form:

- **Volatile UIDs** — SANY assigns global sequential node IDs that depend on
  load order and the built-in operator table; they carry no semantic content
  and are excluded.
## Unit 7 — Level checking

Levels (0 constant / 1 state / 2 action / 3 temporal) are now computed and
emitted (`L<level>` on every node) and match SANY across the corpus,
including the cross-definition `spec` case. Two behaviors to note:

- **Unreferenced formal parameters keep level `-1`.** SANY never level-checks
  a formal parameter that the body does not use, so its level stays at the
  uninitialized sentinel `-1` (e.g. `b` in `Foo(a, b) == a`). This is
  reproduced exactly rather than normalized to 0.

Deferred to a later increment (tracked here):

- The full **level-constraint machinery** — level parameters,
  `SetOfLevelConstraints` / `SetOfArgLevelConstraints` for higher-order
  operator arguments, and iterative recursive level checks — is not yet
  ported. The direct level *value* is computed; the constraint checks that
  reject certain higher-order or cross-substitution misuses are not.
- **Level-error diagnostics** (prime inside prime, temporal nesting,
  wrong-level `.cfg` targets) are not emitted. As in unit 6, SANY recovers
  from these with partial trees rather than failing, so they need the
  semantic diagnostic channel.
- **`Linter.java`** (record-constructor field-name clash, with its
  suppression/elevation settings) is not yet ported.

## Unit 9 — Constant evaluation

Constant TLA+ expressions evaluate to canonical values matching the TLC REPL
(`tlc2.REPL`) across the corpus. One deliberate divergence:

- **String ordering.** TLC orders `StringValue`s by their internal
  `UniqueString` id — the order strings were first interned during the run —
  which is not lexicographic and not reproducible without replicating the
  interning table. Strings (and record fields, and string-set elements) are
  ordered **lexicographically** here. This agrees with the oracle on ordinary
  string sets (e.g. `{"a", "b"}`) but can differ on adversarial cases such as
  `{"bb", "a", "ab"}`.

Not yet ported (later unit-9 increments): `.cfg` config parsing (keywords,
constant/model-value assignments, `SPECIFICATION`/`INIT`/`NEXT`, invariants,
properties, constraints, symmetry), model values, the StandardModule Hoon
override contract beyond the operators exercised, fingerprints, and full
lazy/enumerable value semantics for large sets.

Deferred to a later unit-6 increment (tracked here, targeted well-formed
modules only for now):

- **Semantic error recovery.** For ill-formed input (undefined operator
  reference, duplicate top-level symbol, arity mismatch) SANY does *not* fail:
  it builds a partial `ModuleNode` with `nullODN` sentinel operators, keeps the
  first of a duplicated definition, and records the problem on a separate
  diagnostic channel. The current port targets well-formed modules and does not
  yet reproduce these partial trees or emit the semantic diagnostics.
- **EXCEPT** (`$Except` / `$Seq` index nesting), **INSTANCE / substitution**
  semantics (`$SubstIn`, `APSubstIn`), **N_SetOfRcds**, proof/theorem/assume
  expression bodies, and subexpression `!`-navigation are not yet translated
  into the semantic graph (they parse correctly at unit 4).
