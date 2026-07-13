# Port Map

Java-to-Hoon traceability for `%tla-lus`. Established by Work Unit 0
(pin, inventory, baseline). Every later unit updates its rows: source
classes, Hoon owner, implemented features, missing features, and tests.

## 1. Pinned Upstream Sources

All differential comparison runs against these exact commits. Never compare
against an unrecorded moving checkout.

| Repo | Local checkout | Remote | Pinned commit | Commit date | License |
|---|---|---|---|---|---|
| `tlaplus/tlaplus` | `/mnt/mars/gitrepos/tlaplus` | `git@github.com:jackfoxy/tlaplus.git` (fork of `tlaplus/tlaplus`) | `4ba7d8811289fb8e95dac4d5e554c05216ba3100` | 2026-05-26 | MIT (`LICENSE`) |
| `tlaplus/Examples` | `/mnt/mars/gitrepos/tlaplus-Examples` | `git@github.com:jackfoxy/tlaplus-Examples.git` | `47b0e2cc0268836b89f5ce451f38e5df5f1cf773` | 2026-05-24 | MIT (`LICENSE.md`) |
| `tlaplus/vscode-tlaplus` | `/mnt/mars/gitrepos/vscode-tlaplus` | `git@github.com:jackfoxy/vscode-tlaplus.git` | `acc095d6f8b075788bfbb4c09288c778757abaec` | 2026-05-08 | MIT (`LICENSE`) |

Checkout caveats recorded at pin time (2026-07-12):

- `tlaplus`: untracked `test-model/DieHard_TTrace_*.bin` artifacts from prior
  local runs; tracked tree clean. Oracle runs copy fixtures to a temp dir so
  the checkout is never polluted further.
- `tlaplus-Examples`: locally modified
  `specifications/TeachingConcurrency/Simple.cfg`. Do not use that spec as an
  oracle fixture until the checkout is restored.
- `vscode-tlaplus`: clean. Bundled `tools/tla2tools.jar` in that repo is NOT
  the oracle; only the jar built from the pinned `tlaplus` commit is.

Attribution: all three upstreams are MIT-licensed. Any translated code,
copied fixture, or vendored StandardModule in this desk must retain the
upstream copyright notice and a pointer to the pinned commit.

## 2. Java Oracle Build And Invocation Forms

Build (validated 2026-07-12 from the pinned commit, Ant + OpenJDK 11):

```bash
cd /mnt/mars/gitrepos/tlaplus/tlatools/org.lamport.tlatools
ant -f customBuild.xml info compile compile-test dist
# -> dist/tla2tools.jar (~4.3 MB)
```

Smoke check (must reproduce exactly under the pinned commit):

```bash
java -cp dist/tla2tools.jar tlc2.TLC -deadlock test-model/pcal/Bakery.tla
# -> 1183 states generated, 668 distinct states found, depth 41, no error
```

Entry points (one jar, several mains; `java -jar` aliases `tlc2.TLC`):

| Stage | Invocation form |
|---|---|
| SANY parse+semantic+level+lint | `java -cp tla2tools.jar tla2sany.SANY [-s] [-l] [-lint] [-error-codes] [-messagesAsErrors codes] [-suppressMessages codes] FILE...` |
| PlusCal translation | `java -cp tla2tools.jar pcal.trans [-nocfg] [-wf|-sf|-wfNext|-nof] [-termination] [-label] [-lineWidth n] FILE` (rewrites FILE in place; writes `FILE.cfg` unless `-nocfg`) |
| TLC model check | `java -cp tla2tools.jar tlc2.TLC [-config FILE.cfg] [-deadlock] [-workers 1] [-fp 0] [-seed N] [-metadir DIR] [-cleanup] [-lncheck final] [-tool] FILE` |
| TLC simulation | `java -cp tla2tools.jar tlc2.TLC -simulate num=N -depth D -seed S [-aril A] ... FILE` |
| XML AST export (oracle format only) | `java -cp tla2tools.jar tla2sany.xml.XMLExporter [-o] FILE` |

SANY exit codes with `-error-codes`: documented as `2` parse error and `4`
semantic/level error, but the pinned build observably exits `255` on fatal
lexical/parse errors (see `golden/lex-bad-string.txt`,
`golden/syntax-reject.txt`) and `4` on semantic/level errors. The Hoon port
matches the coded-diagnostic categories, not CLI exit integers.
TLC exit codes: `0` success, non-zero per `tlc2.output.EC` category
(e.g. `151` config error, observed in `golden/cfg-bad.txt`).

Determinism flags used for every TLC oracle run: `-workers 1 -fp 0`
(fixed fingerprint-function index) and, for simulation, explicit
`-seed`/`-aril`. `-tool` mode emits `@!@!@STARTMSG <EC-code>` tagged
messages; the tagged form is the long-term compatibility surface for
diagnostics (see the Toolbox inventory below), while unit-0 goldens use the
plain human-readable form.

Constraints inherited from the Java tools: TLC holds global static state and
cannot run twice in one JVM (one process per oracle run); SANY `parse()` is
process-safe but not thread-safe.

## 3. Differential-Output Normalization Rules

Implemented in `desk/test-data/oracle/regen.sh` (`normalize()`); every rule
here must stay in sync with that script. Comparison is on normalized text.

1. Line endings: CRLF -> LF; strip trailing whitespace; ensure final newline.
2. Absolute paths: the fixture temp dir and repo checkout prefixes are
   rewritten to `<WORK>/` and `<REPO>/`.
3. Timestamps: any `YYYY-MM-DD hh:mm:ss` -> `<DATETIME>`; `Finished in NNs
   at (...)` and trailing `... in NNs.` durations -> `<D>`.
3a. TLC's temp StandardModules extraction dir (`/tmp/tlc-<random>/`) ->
   `<TLCTMP>`; the TLC version banner embeds the jar build timestamp
   (`TLC2 Version 2026.07.12.HHMMSS (rev: ...)`) -> `TLC2 Version <BUILD>
   (rev: ...)`, keeping the rev hash as the oracle pin.
4. Rates and machine sizing: `... states generated (N s/min)`, `... and N
   cores`, heap/offheap MB figures -> `<N>` placeholders; drop the
   `Working set` / OS + JVM info lines.
5. Randomness: TLC runs pin `-fp 0 -workers 1`; the printed `with fp N and
   seed N` line is kept verbatim (deterministic under pinned flags). TLC's
   random simulation seed is always passed explicitly.
6. Progress lines: `Progress(N) at (...)` keeps N, normalizes the timestamp
   and rate fields. Checkpoint directory names (`states/YY-MM-DD-...`) ->
   `<METADIR>`.
7. Ordering: single worker + fixed fp make state counts and traces
   deterministic; no reordering is applied. If a future case emits
   set-ordered diagnostics, sort just that block and record it here.
8. The TLC/SANY version banners are kept verbatim; they pin the oracle
   version and change only when the pinned commit changes.
9. TLC trace-exploration artifacts (`*_TTrace_*.tla/.bin`) are excluded from
   golden output (generated in the temp dir and discarded).

## 4. Primary Inventory: `tlatools/org.lamport.tlatools/src`

Classification: `port` (behavior reimplemented in Hoon), `reference`
(consulted for contracts/oracle formats, not ported), `performance-only`
(port later only if profiling demands; semantics must not depend on it),
`excluded` (out of scope per PLAN.md).

Hoon owner names refer to the planned `lib/tla/*.hoon` split; "impl" is
empty at unit 0 and is updated per unit.

### 4.1 SANY (`tla2sany/`) — 105 classes

| Package (classes) | Class notes | Class | Hoon owner | Unit |
|---|---|---|---|---|
| `tla2sany` (1) + `drivers` (6) | `SANY.frontEndMain` pipeline order (syntax -> semantic -> level -> lint), `SanySettings`, `SanyExitCode`, `FrontEndException`/`SemanticException` | port (pipeline semantics; CLI surface itself becomes the Gall API) | `modules.hoon`, `diagnostics.hoon` | 5-7 |
| `parser` (16) | `TLAplusParser`/`TLAplusParserTokenManager` are generated from `javacc/tla+.jj` (grammar is the source of truth); `Operators`/`OperatorStack`/`Operator`/`OSelement` precedence engine; `SyntaxTreeNode`, `Token`, `SimpleCharStream` lexical states; `ParseError(s)`, `ParseException*`, `TokenMgrError`, `JunctionListContext` (conj/disj lists) | port | `lexer.hoon`, `syntax.hoon`, `ast.hoon` | 3-4 |
| `st` (6) | `Location` (spans), `TreeNode`/`ParseTree`, `SyntaxTreeConstants`, `ParseError(s)` interfaces | port | `source.hoon`, `ast.hoon` | 2-4 |
| `modanalyzer` (9) | `SpecObj` (root/extends/instance discovery, dep order, cycles), `ParseUnit(sTable)`, `ModuleContext/Pointer/Relationships/Relatives`, `SyntaxTreePrinter` (debug: reference) | port | `modules.hoon` | 5 |
| `semantic` (52) | `Generator` (AST->semantic graph), `Context`/`SymbolTable`/`ExternalModuleTable`, `ModuleNode` + all node kinds (`OpApplNode`, `OpDefNode`, `OpDeclNode`, `LetInNode`, `SubstInNode`/`APSubstInNode`/`Subst`, `InstanceNode`, `AssumeNode`/`TheoremNode`/`ThmOrAssumpDefNode`, proof nodes, `LabelNode`, ...), `BuiltInOperators`/`ASTConstants`, `LevelNode`/`LevelConstants`/`SetOf(Arg)LevelConstraints`/`ArgLevelParam` (level checking), `ErrorCode`/`Errors` (coded diagnostics), `StandardModules` (bundled-module list), `FrontEnd`, `SymbolMatcher` (reference: editor completion helper) | port (all but `SymbolMatcher`) | `semantic.hoon`, `levels.hoon`, `diagnostics.hoon` | 6-7 |
| `linter` (1) | `Linter.lintRecords`: `RECORD_CONSTRUCTOR_FIELD_NAME_CLASH` (4802, WARNING) with documented suppression heuristics | port | `lint.hoon` | 7 |
| `StandardModules/*.tla` | `Naturals`, `Integers`, `Reals`, `Sequences`, `FiniteSets`, `Bags`, `TLC`, `TLCExt`, `Randomization`, `Json`, `Toolbox`, `RealTime`, `_TLC*`/`_Json*` trace templates (reference: trace-spec generation) | port (vendored + Hoon overrides) | `stdlib.hoon` | 5, 9 |
| `output` (5) | `SanyOutput`/`LogLevel` abstractions | reference (subsumed by typed diagnostics) | `diagnostics.hoon` | 2 |
| `xml` (5) | `XMLExporter`, `sany.xsd` | reference (oracle format for semantic-tree diff, unit 6) | — | 6 |
| `explorer` (5) | interactive semantic-graph explorer, DOT dump | reference (debug aid) | — | — |
| `utilities` (5) | Java containers (`Vector` etc.) | excluded (Hoon stdlib replaces) | — | — |

### 4.2 PlusCal (`pcal/`) — 27 classes + `exception` (14)

| Class notes | Class | Hoon owner | Unit |
|---|---|---|---|
| `trans` (driver, options, `BEGIN/END TRANSLATION` replacement, checksums via `Validator`/`ValidationCallBack`), `ParseAlgorithm` + `Tokenize`/`PcalCharReader`/`PcalBuiltInSymbols` (C and P syntax), `AST` (PlusCal AST), `PcalSymTab`/`PcalFixIDs` (symbols, ID fixing), `PcalTranslate` (AST -> intermediate), `PCalTLAGenerator`/`PcalTLAGen` (TLA+ text generation), `TLAExpr`/`TLAToken` (expression fragments), `Region`/`PCalLocation`/`MappingObject`/`TLAtoPCalMapping` (source mapping), `PcalParams` (options incl. `-wf -sf -wfNext -nof -termination`), `exception/*` (error taxonomy) | port | `pcal-ast.hoon`, `pcal-parser.hoon`, `pcal-translate.hoon` | 8 |
| `PcalDebug`, `PcalResourceFileReader`, `Test`, `Translator` (string-in/string-out wrapper: API-shape reference), `OldPlusCal.tla`/`PlusCal*.tla` (in-tree specs) | reference | — | 8 |

### 4.3 TLC (`tlc2/`) — ~380 classes

| Package (classes) | Class notes | Class | Hoon owner | Unit |
|---|---|---|---|---|
| `tlc2` root (7) | `TLC` (arg parsing, run modes, exit codes), `TLCGlobals` | port (semantics; flags map to the Gall request mold) | `job.hoon`, `cfg.hoon` | 9-13 |
| | `REPL`, `REPLSpecWriter`, `TLCRunner`, `TraceExplorationSpec`, `TraceExpressionExplorerSpecWriter` | excluded (REPL/TE-spec generation out of first target) | — | — |
| `tool` (44) | `ModelChecker` (BFS safety), `AbstractChecker`, `Worker`/`IWorker` (single-worker parity), `Simulator`/`SimulationWorker`, `Action`, `TLCState*` (`TLCStateMut`, `StateVec`, `TLCStateInfo`, `TLCTrace`, `ConcurrentTLCTrace`), `EvalControl`/`EvalException`/`FingerprintException`/`WorkerException`, `BuiltInOPs`/`Specs`/`ToolGlobals`, functor interfaces | port | `state.hoon`, `safety.hoon`, `trace.hoon` | 10, 12 |
| | `DFIDModelChecker`/`DFIDWorker` | reference (DFID only if inventory later reclassifies as required core) | — | 12 |
| | `CheckImpl*`, `TraceApp`, `TLAPlusExecutor`, `RL*SimulationWorker` (RL experiments), `PossibleAction` | excluded | — | — |
| `tool/impl` (17) | `Tool` (expression/action evaluation core), `SpecProcessor`, `Spec`, `ModelConfig` (.cfg parser), `OpDefEvaluator`, `TLARegistry`/`TLAClass` (override binding contract), `ContextEnumerator`, `ActionItemList*` | port (`DebugTool`/`CallStackTool`: reference — debugger/error-callstack wrappers; `ParameterizedSpecObj`, `WorkerValue`: reference) | `eval.hoon`, `cfg.hoon` | 9 |
| `value` (15) + `value/impl` (46) | value interfaces + `Value` hierarchy: `BoolValue`, `IntValue`, `IntervalValue`, `StringValue`, `ModelValue`, `SetEnumValue`, `SubsetValue`, `SetOf{Fcns,Rcds,Tuples}Value`, `SetPredValue`, `SetCap/SetCup/SetDiff/UnionValue`, `FcnRcdValue`, `FcnLambdaValue`, `RecordValue`, `TupleValue`, `LazyValue`, `MVPerm(s)` (symmetry), `ValueEnumeration`, normalization/equality/fingerprint/`ValueExcept` semantics | port (`CallableValue`/`EvaluatingValue`/`MethodValue`/`PriorityEvaluatingValue` are JVM-reflection binding: reference — the *contract* they bind is ported via `tlc2/module`; `ValueInput/OutputStream` serialization: reference — Hoon nouns replace; `KSubsetValue`, `UserObj`/`UserValue`, `CounterExample`: reference) | `value.hoon` | 9 |
| `module` (19) | Java overrides for `Naturals`, `Integers`, `Sequences`, `FiniteSets`, `Bags`, `Strings`, `TLC`, `TLCExt`, `TLCGetSet`, `TransitiveClosure`, `Randomization`, `AnySet`, `TLCEval`; name/arity/behavior contract incl. `TLARegistry` infix mapping | port (contract + behavior) (`Json`, `_JsonTrace`, `_Possible`, `TLCBuiltInOverrides`: reference/excluded first target) | `stdlib.hoon` | 9 |
| `overrides` (4) | annotation machinery for user-provided Java overrides | reference (contract doc only; no JVM in Gall) | — | 9 |
| `tool/liveness` (44) | `Liveness` (property decomposition to `LiveExprNode` normal form: `LN*`), `TBGraph`/`TBGraphNode`/`TBPar*` (tableau), `OrderOfSolution`/`PossibleErrorModel`, `LiveCheck`/`ILiveCheck`/`LiveWorker` (SCC search), `DiskGraph`/`TableauDiskGraph`/`NodePtrTable` (behavioral graph store), `LiveCounterExampleException` (lasso traces) | port (memory-graph semantics; disk-backed layout itself performance-only; `LiveCheck1`, `AddAndCheckLiveCheck`, `BEGraph*`/`BTGraphNode` legacy, `Dot/Noop*StateWriter` debug: reference) | `liveness.hoon` | 11 |
| `tool/fp` (18) + `fp/dfid` (3) | `FPSet` contract (put/contains exactness) | port (contract only) — `DiskFPSet` family, `OffHeapDiskFPSet`, `MultiFPSet`, `LongArray(s)`: performance-only | `state.hoon` | 10, 12 |
| `tool/queue` (7) | `IStateQueue` BFS contract, `StateQueue`/`StateDeque` | port (contract; `Disk*Queue` performance-only) | `state.hoon` | 10 |
| `tool/coverage` (8) | action/cost coverage counters | reference (unit 10 emits basic counters; full cost model deferred) | `safety.hoon` | 10 |
| `output` (12) | `EC` (stable message codes), `MP` (message formats, `-tool` tagging), `ErrorTraceMessagePrinterRecorder` | port (codes/categories as typed diagnostics) — `AbstractSpecWriter`/`SpecTraceExpressionWriter`/`SpecWriterUtilities` reference (Toolbox model-writer shapes), streams excluded | `diagnostics.hoon` | 2, 9-12 |
| `model` (7) | `MCError`/`MCState`/`MCVariable`/`Assignment`/`TypedSet`/`Formula` (structured trace/model shapes shared with Toolbox) | reference (API-shape input to `sur/tla-lus.hoon`) | `sur/tla-lus.hoon` | 2 |
| `util` (47) | behavioral: `FP64` (fingerprint function), `Context` (evaluation binding chain), `Vect`/`SetOfStates`/`LongVec` (containers), `RandomGenerator` (simulation RNG — must match for seed parity), `BitVector`, `Combinatorics` | port (those five areas) | `eval.hoon`, `state.hoon`, `simulate.hoon` | 9-12 |
| | disk/IO/concurrency: `BufferedRandomAccessFile`, `StatePool*`, `Disk*Stack`, caches, locks, `IdThread`, statistics | performance-only or excluded (JVM-specific) | — | — |
| `util` top-level (27) | `UniqueString` (interning: reference — Hoon terms/atoms), `FilenameToStream`/resource locators (reference: shape for inline/Clay resolvers), `MonolithSpecExtractor` (port: monolith module support), `TLAConstants` (port: shared literals), `Assert`/`ToolIO` (reference), `MailSender`/`ExecutionStatisticsCollector`/`TLCRuntime`/`UsageGenerator` (excluded) | mixed as noted | `source.hoon`, `modules.hoon` | 3, 5 |
| `debug` (15) | DAP debugger | excluded (first target) | — | — |
| `pprint` (6) | pretty-printer for values | reference | — | — |
| `tool/distributed` (33 across subpkgs) | distributed TLC | excluded | — | — |
| `tool/management`, `util/statistics` (16) | JMX/monitoring | excluded | — | — |

### 4.4 Other top-level packages

| Package | Class | Note |
|---|---|---|
| `tla2tex` (26) | excluded | PLAN.md exclusion |
| `formatter` | excluded | not in first compatibility target |
| `model` (top-level) | reference | shared model shapes |
| `javacc/tla+.jj` | port (grammar source of truth) | unit 3-4; drives `doc/tla-bnf.md` |

### 4.5 Upstream test inventory (`test/`, `test-model/`)

~1300 test classes; 607 `.tla` fixtures under `test-model/`. Usage
classification (fixtures are `test-fixture` sources for differential runs;
Java test classes are `reference` for expected behavior — none are ported
as Java):

| Test tree (classes) | Use for |
|---|---|
| `test/tla2sany/corpus/*.txt` (syntax corpus: expressions, functions, except, conj/disj lists, fairness, proofs, ...) | unit 3-4 accept/reject + AST-shape parity |
| `test/tla2sany/parser` (10), `test/tla2sany/api` (9), `test/tla2sany/drivers` (4) | parser/API behavior reference |
| `test/tla2sany/semantic` (6) + `semantic/corpus` + `semantic/error_corpus` | unit 6-7 semantic/level diagnostics parity |
| `test/tla2sany/xml` (4) | XML-oracle comparison harness reference |
| `test/pcal` (96) + `test/pcal/parser/corpus` | unit 8 translation parity |
| `test/tlc2/tool` (260), `tool/suite` (107), `tool/liveness` (126 + 21 sim), `tool/simulation` (7), `tool/evalorder` (6), `tool/doinitfunctor` (6), `tool/checkpoint` (3) | units 9-12 verdict/trace/count parity |
| `test/tlc2/value/impl` (14), `test/tlc2/module` (8), `test/tlc2/util` (13) | unit 9 value/override property tests |
| `test/tlc2/debug` (17), `test/tlc2/tool/distributed` (14), `test/formatter` (30), `test/tlc2/tool/fp` (22, beyond contract) | excluded / performance-only |
| `test-model/` (607 specs incl. `pcal/`, `suite/`, DieHard, Euclid, Bakery, liveness models) | fixture pool for all tiers |
| `tlaplus-Examples/specifications/` | tier-2/3 matrix (unit 14) |

## 5. Secondary-Reference Inventory (Adapter Layers)

Sources for the boundary around the Java tools, never for TLA+ semantics.
Classification: `api-shape` (informs Gall nouns/API), `test-fixture`
(inputs/goldens reusable for compatibility), `ignore-ui`.

### 5.1 Toolbox (`tlaplus/toolbox/`)

| Item | Class |
|---|---|
| `org.lamport.tla.toolbox/spec/parser/` — `ModuleParserLauncher`, `ParseResult`, `ParserDependencyStorage`, `ParseResultBroadcaster`, `IParseConstants` | api-shape (parse-result + module-dependency tracking shapes) |
| `tool.tlc/model/` — `Model`, `ModelWriter`, `TLCSpec`, `TLCModelFactory`, `TraceExpressionModelWriter`, `ModelCoverage` | api-shape (generated `.tla`/`.cfg` model writing, checkpoint/coverage states) |
| `tool.tlc/output/` + `tool.tlc.ui/.../output/{source,data}` — `IProcessOutputSink`, tag-based incremental `EC` parsers, `TLCModelLaunchDataProvider`, `TLCState`/`TLCError`/`TLCVariableValue`, `StateSpaceInformationItem`, `ActionInformationItem`, `CoverageInformation` | api-shape (streamed `-tool` message model: progress, errors, stuttering, back-to-state, action locations, trace values) |
| `tool.tlc.ui.test/.../output/{source,data}` tests — `TagBasedTLCOutputIncrementalParserTest`, `TLCStateTest`, `TLCErrorTest`, `TLCVariableValueTest`, `CoverageInformationTest`, `Bug267*` | test-fixture (real nested/tagged TLC output, trace values, coverage) |
| PlusCal/TLA+ checksum-divergence validation before TLC (`Validator` use in spec editor plumbing) | api-shape (unit 8 divergence policy) |
| All other plugins: editors, views, wizards, prover UI, tla2tex UI, product/feature/p2 packaging, Oomph | ignore-ui |

### 5.2 VS Code (`vscode-tlaplus/`)

| Item | Class |
|---|---|
| `src/commands/` — `parseModule`, `checkModel`, `evaluateExpression`, `exportModule`, `modelResolver` (adjacent/custom `.cfg` resolution) | api-shape (headless orchestration: PlusCal -> SANY -> TLC phases, cancellation, module search paths) |
| `src/parsers/` — `sany.ts`, `tlc.ts`, `tlcCodes.ts`, `tlcValues.ts`, `traceParser.ts`, `pluscal.ts` | api-shape (structured run phases, warnings/errors, EC-code mapping, trace-value grammar) |
| `src/model/check.ts`, `coverage.ts`, `documentInfo.ts` | api-shape (result nouns checklist: status, statistics, coverage, traces) |
| `src/lm/` — `MCPServer.ts`, `SANYTool.ts`, `TLCTool.ts` | api-shape (bounded smoke/explore ops, workspace path validation) |
| `tests/suite/parsers/` + `tests/fixtures/parsers/` | test-fixture (SANY/TLC output corpora: multiline diagnostics, monolith modules, progress, stuttering, lasso back-edges) |
| `src/debugger`, `webview`, `panels`, `formatters`, `completions`, `symbols`, syntax highlighting, packaging, `main*.ts` | ignore-ui |
| PlusCal boundary-detection / C-syntax caveats in its docs | ignore-ui (explicitly NOT ported, per PLAN.md) |

## 6. Selected Oracle Cases (Unit-0 Baseline)

Tiny cases proving the oracle harness end to end; the golden outputs live in
`desk/test-data/oracle/golden/` and regenerate via
`desk/test-data/oracle/regen.sh` (normalization rules §3). Upstream-copied
fixtures note their origin in a `SOURCE` file per case.

| Case | Area | Fixture | Oracle command | Expected |
|---|---|---|---|---|
| `lex-bad-string` | lexing | hand-written: unterminated string | `SANY -error-codes` | lexical error, exit 2 |
| `syntax-accept` | grammar | hand-written: LET/EXCEPT/quantifiers/records | `SANY -error-codes` | parse+semantic ok |
| `syntax-reject` | grammar | hand-written: malformed EXCEPT | `SANY -error-codes` | parse error, exit 2 |
| `semantic-undef` | semantics | hand-written: undefined operator + arity error | `SANY -error-codes` | semantic errors, exit 4 |
| `semantic-instance` | semantics | hand-written 2-module INSTANCE + substitution | `SANY -error-codes` | ok, both modules |
| `level-prime` | levels | hand-written: double prime / action in invariant position | `SANY -error-codes` | level error, exit 4 |
| `lint-record-clash` | lint | hand-written: `bar == 23`, `R == [bar |-> 42]` | `SANY -error-codes` | warning 4802 |
| `pcal-evenodd` | PlusCal | `test-model/pcal/EvenOdd.tla` (copy) | `pcal.trans -nocfg`; golden = full rewritten `.tla` | translation matches |
| `cfg-bad` | config | hand-written spec + `.cfg` naming unknown invariant | `TLC -config` | config error category |
| `values-eval` | values | hand-written ASSUME/PrintT over sets/functions/records/intervals | `TLC` | printed canonical values |
| `safety-diehard` | safety | `test-model/DieHard.tla|.cfg` (copy) | `TLC -workers 1 -fp 0` | invariant violation, shortest trace |
| `deadlock-counter` | deadlock | hand-written bounded counter | `TLC -workers 1 -fp 0` | deadlock, trace |
| `liveness-lasso` | liveness | hand-written WF spec with violated `<>[]` property | `TLC -workers 1 -fp 0 -lncheck final` | liveness violation, lasso trace |
| `simulate-seeded` | simulation | same spec as `deadlock-counter` | `TLC -simulate num=3 -depth 8 -seed 1 -aril 0 -deadlock` | reproducible run |

Regeneration: `TLA_REPO=/mnt/mars/gitrepos/tlaplus desk/test-data/oracle/regen.sh`
(re-runs every case in a temp dir against the pinned jar and rewrites
`golden/`). `regen.sh --check` verifies goldens match without rewriting.

## 6a. Lexer Differential Harness (Unit 3)

- Oracle: `tools/oracle/TokenDump.java` (compile:
  `java -m jdk.compiler/com.sun.tools.javac.Main -cp <jar> -d build TokenDump.java`
  — this machine has no `javac` launcher). Dumps the raw
  `TLAplusParserTokenManager` stream: `T <kind> <spans> <image>` per
  token, `C` per comment special, `E <TokenMgrError message>` on lexical
  error; stops when module nesting returns to zero (SANY never lexes
  past the root `====`).
- Fixtures: `desk/test-data/lex/boundary/*.tla` (hand-written: tabs,
  CRLF, EOF in string/comment/eol-comment, bad escapes, no-pattern and
  live-prefix errors, nested comments, unicode spellings, proof-step
  lexemes, junction BAND/BOR, WF/SF cases, module-delimiter variants,
  pragma mode, pre-module skip) and `desk/test-data/lex/corpus/*`
  (every case extracted from `test/tla2sany/corpus/*.txt`).
- `tools/gen-lexer-tests.py` regenerates all goldens from the pinned jar
  and emits the Hoon test shards `desk/tests/lib/tla/lexer/*.hoon`
  (generated files; never hand-edit).
- Hoon side: `lib/tla/source.hoon` (UTF-8 codec — zuse `tuba`/`tufa`
  reject control chars — and the exact SimpleCharStream line/column
  model incl. tab-to-8 and CR/LF/CRLF), `lib/tla/lexer.hoon` (states,
  ~230-lexeme table, maximal munch with declaration-rank ties,
  identifier CASE0-N, junctions, proof lexemes, nested-comment special
  emission, TokenMgrError-format errors, `+dump` renderer).

## 7. Progress Log

| Unit | Status | Evidence |
|---|---|---|
| 0 pin/inventory/baseline | done 2026-07-12 | oracle rebuilt from pin; Bakery smoke reproduces 1183/668/41; 14 golden cases repeatable (`regen.sh --check` x2) |
| 1 headless desk scaffold | done 2026-07-12 | fake-ship install without GUI; 27/27 tests OK (`-test /=tla-lus=/tests ~`); live submit/progress/done via Behn slices; bad-mark nack, artifact scry, delete-result; state survived pier restart |
| 2 freeze shared types/diagnostics/job semantics | done 2026-07-12 | 51/51 tests OK; all action/update variants round-trip through marks, malformed nouns crash the grab clam; pure `step` engine pause/resume-identical (`test-pause-resume-identical`); limits terminate as `%limited`; `%0`->`%1` migration fixtures pass and live upgrade migrated running-agent state on the fake ship |
| 3 source handling + native TLA+ lexer | done 2026-07-13 | 270 differential cases green on fake ship: 21 hand-written boundary fixtures (tabs, CRLF, EOF-in-string/comment/eol-comment, bad escapes, live-prefix + no-pattern errors, nested comments, unicode spellings, proof lexemes, junction BAND/BOR, WF/SF cases, delimiter variants, pragma, pre-module skip) + all 249 syntax-corpus cases — token kinds, images, spans, comment specials, and byte-exact TokenMgrError messages match the pinned Java token manager |
| 4 syntactic analyzer + BNF | done 2026-07-13 | all 261 upstream syntax-corpus accept/reject cases green vs `AstDump.java` (SANY concrete tree: node kinds, spans, images, canonical step numbers) — full grammar: module frame/units, every definition LHS form, operator-stack expression engine (Operators/OperatorStack port incl. N_Times flattening, unary-minus mixfix, precedence-conflict rejection), junction lists with column discipline + `checkIndentation`, all `[`/`{` constructor families incl. `{x \in S}` recovery, quantifiers/CHOOSE/LAMBDA/fairness/labels (+`labelDoesNotChangeParse`), subexpression `!`-navigation, INSTANCE WITH, USE/HIDE/BY, complete proof syntax with level checking and a `belchDEF`-equivalent definition lookahead; `doc/tla-bnf.md` (35 traceable productions + mechanically generated precedence/synonym tables) drift-checked by generated `tests/lib/tla/bnf.hoon`. Deviations: error-message parity deferred (REJECT verdicts match; messages differ), documented for compatibility.md |

Unit-2 Hoon surface: `sur/tla-lus.hoon` freezes the public wire nouns —
spans/locs (SANY Location semantics), `token`, diagnostics (namespaced
`diag-code`, severity, `stage`, spans, related locs), traces/artifacts,
the full `request` (op + source-bundle + limits + write policy),
five-way terminal `result`, `job`, resumable `step-result`, actions and
updates. `lib/tla/job.hoon` is the stub engine (validate, per-op stage
plan, one stage per bounded step, limit enforcement);
`lib/tla/diagnostics.hoon` owns deterministic ordering;
`lib/tla/migrate.hoon` owns frozen `%0` molds + migration. Deviations:
the recursive syntax-tree mold is deferred to unit 4 — recursive `$%`
molds overflow the zuse-408 mold compiler without obelisk-style `$+`
annotations (`token` is frozen now; the tree shape lands with the
parser). Diagnostic/update surface for unit 1's `%cancelled`/`%done`
updates was replaced by `[%job id event]` before any external consumer
existed.
