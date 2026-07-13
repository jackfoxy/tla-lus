# Unit 8 — PlusCal Translation: pipeline design study

PlusCal translation is the largest single unit in the port. Unlike the
lexer/parser/semantic units, it has **no per-fixture partial credit**: a
fixture's golden is the whole rewritten `.tla` (plus `.cfg`), and it embeds two
CRC-32 checksums, so nothing passes until the entire pipeline is byte-exact.
This note maps the pipeline and records what has been verified so far.

## The oracle

`java -cp tla2tools.jar pcal.trans <file>.tla` rewrites `<file>.tla` **in place**,
inserting the generated TLA+ between `\* BEGIN TRANSLATION (...)` and
`\* END TRANSLATION`, and writes `<file>.cfg` (and a `.old` backup). The
differential test copies a fixture, runs `pcal.trans`, and captures the
rewritten `.tla` + `.cfg` as goldens. See `desk/test-data/pcal/<case>/` and
`tools/gen-pcal-tests.py`.

Java sources (pinned commit), in pipeline order:

| Stage | Java | Lines | Hoon owner (planned) |
|---|---|---|---|
| Tokenize algorithm + expressions | `pcal/Tokenize.java` | 1644 | `lib/tla/pcal/tokenize.hoon` |
| Parse to PlusCal AST | `pcal/ParseAlgorithm.java` | 4456 | `lib/tla/pcal/parse.hoon` |
| AST node types + `toString()` | `pcal/AST.java` | 1047 | `lib/tla/pcal/ast.hoon` |
| Symbol table | `pcal/PcalSymTab.java` | 727 | `lib/tla/pcal/symtab.hoon` |
| Fix identifiers | `pcal/PcalFixIDs.java` | 599 | folded into parse/translate |
| Explode labels / control flow | `pcal/PcalTranslate.java` | 1501 | `lib/tla/pcal/translate.hoon` |
| Generate TLA+ text | `pcal/PcalTLAGen.java` | 4392 | `lib/tla/pcal/tlagen.hoon` |
| Checksums, BEGIN/END, options | `pcal/trans.java`, `Validator.java` | 2021+ | `lib/tla/pcal/driver.hoon` |

## Checksums (VERIFIED)

`Validator.checksum(s)` = `Long.toHexString(new CRC32().update(s.getBytes()).getValue())`
— reflected CRC-32 (poly `0xEDB88320`), lowercase hex, no leading zeros, no
`0x` (so `""` → `"0"`). Ported and differential-tested in `lib/tla/crc.hoon`
(`tests/lib/tla/crc.hoon`, 7 vectors from `tools/oracle/CrcVec.java`).

- `chksum(tla)` = CRC-32 of the translation lines **strictly between** the
  BEGIN and END TRANSLATION lines, **concatenated with no separators**
  (`Validator.checksum(Vector<String>)` appends each line with no newline).
  VERIFIED on the `counter` fixture: extracting lines 11..34 of `golden.tla`,
  concatenating, CRC-32 → `256526f5`, matching the recorded marker exactly.
  So once `tlagen` emits the exact text, `crc32:crc` produces the right value.
- `chksum(pcal)` = CRC-32 of `ast.toString()` (for a non-fair algorithm; a
  fair one prepends the `FAIR` marker string). This needs the parser + the
  AST serialization below, so it is the gating milestone for the front end.

## AST `toString()` — the chksum(pcal) target

Each `AST$*` subclass serializes to a TLA+ record literal
`[type |-> "...", field |-> value, ...]` using `Indent`/`EndIndent`/`NewLine`
helpers that track a **running indentation column** (position-dependent). The
serialization is what `PlusCal.tla` treats the object as, so some fields are
deliberately omitted (e.g. `Uniprocess` omits `macros`). Reproducing
`chksum(pcal)` requires this indented form byte-exact — the indentation stack
and `lineCol()` source positions are part of the hashed bytes.

Node classes (AST.java): `Uniprocess`, `Multiprocess`, `Procedure`, `Process`,
`VarDecl`, `PVarDecl`, `LabeledStmt`, `While`, `Assign`, `SingleAssign`, `Lhs`,
`If`, `Either`, `With`, `When`, `PrintS`, `Assert`, `Skip`, `LabelIf`,
`LabelEither`, `Clause`, `Call`, `Return`, `CallReturn`, `CallGoto`, `Goto`,
`Macro`, `MacroCall`, `Definition`.

## Generated TLA+ shape (uniprocess, from `counter`)

`VARIABLES pc, <globals>` · `vars == << ... >>` · `Init == (* Global
variables *) /\ ...` (with `pc = "<first label>"`) · one action per label
(`Label == /\ pc = "Label" /\ ...`, control flow becoming `IF/THEN/ELSE` over
conjunction lists, each branch setting `pc'`) · `Terminating == pc = "Done"
/\ UNCHANGED vars` · `Next == <labels> \/ Terminating` · `Spec == Init /\
[][Next]_vars` · `Termination == <>(pc = "Done")`. The `.cfg` is
`SPECIFICATION Spec` + a comment. Options (`-nof`, `-wf`, `-sf`, `-wfNext`,
`-termination`) change the fairness conjuncts and whether `Termination` is
emitted.

## Decomposition / order of increments

1. **CRC-32 checksum primitive** — DONE (`lib/tla/crc.hoon`, tested).
2. Oracle harness + corpus + goldens — DONE (`gen-pcal-tests.py`, `counter`,
   `twovars`).
3. PlusCal AST molds (`ast.hoon`) + `toString()` serialization → match
   `chksum(pcal)` on the corpus (front-end milestone).
4. Tokenizer + parser producing that AST.
5. `translate` + `tlagen` → exact translation text → `chksum(tla)` + visible
   output; `.cfg` generation; BEGIN/END insertion; option flags.
6. Run both Java SANY and the Hoon SANY (units 4–7) over every generated
   `.tla` to confirm the output parses and levels-checks identically.

Steps 3–5 are each large; a fixture goes green only when its whole pipeline is
byte-exact, including the position-dependent AST indentation.
