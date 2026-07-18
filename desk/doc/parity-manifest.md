# Parity Manifest

Machine-checked parity ledger for `%tla-lus` (PORT-COMPLETION-PLAN-2 unit 0).
One row per included Java behavioral cluster (granularity matches the
`port-map.md` §4 inventory) and one row per public request option. Every row
carries a `status`; `tools/check-parity.py --check` fails if any status is
blank or not one of the closed set below, so nothing in scope stays
unclassified.

Status values:

- `parity` — Hoon behavior differentially matches the pinned Java oracle.
- `partial` — a first increment matches a narrow slice; named behavior is
  still missing (see rationale).
- `approved-difference` — a deliberate, documented divergence (see
  `compatibility.md`), tested as such.
- `replaced` — the Java mechanism is intentionally supplanted by a Hoon/Gall
  mechanism; no byte parity is meaningful.
- `absent` — in scope, not yet implemented.
- `excluded` — out of scope per the plan; rationale states why.
- `oracle-only` — goldens are captured from the pin but no Hoon comparator
  exists yet.

This is a scaffold ledger: the release gate is a scaffold gate until every
in-scope row is `parity`, `approved-difference`, `replaced`, or `excluded`
(no `partial`, `absent`, or `oracle-only`). Counts are cited from the
generated `evidence-counts.md`, never hand-written.

## Java source clusters

| id | java-owner | hoon-owner | oracle-test | status | unit | rationale |
|---|---|---|---|---|---|---|
| sany-pipeline | tla2sany.SANY + drivers | app/tla-lus, job.hoon | regen.sh baseline | replaced | 1,5-7 | CLI front-end becomes the Gall API; pipeline order preserved |
| lexer | parser.TLAplusParserTokenManager, SimpleCharStream | lib/tla/source, lib/tla/lexer | gen-lexer-tests (270) | parity | 3 | token kinds/images/spans/comment specials/TokenMgrError text match |
| parser-cst | parser.TLAplusParser, Operators/OperatorStack, SyntaxTreeNode | lib/tla/syntax, lib/tla/ast | gen-parser-tests (249) | parity | 4 | accept/reject verdicts + tree shape match; error text under parse-errors |
| parse-errors | parser.ParseError(s)/ParseException*/TokenMgrError, msgStack/expecting | lib/tla/syntax (perr/bpa/parse-typed) | gen-parse-err-tests (34) | partial | 2 | ***Parse Error*** blocks byte-match the corpus (Encountered/Was expecting/residual stack, OperatorStack + junction/label/\X/!.@ messages, TokenMgrError wrapper); ~100 expecting sites on unexercised productions and typed `at` spans remain |
| st-location | st.Location, TreeNode, ParseTree | lib/tla/source, lib/tla/ast | gen-lexer-tests | parity | 2-4 | span/location semantics reproduced |
| modanalyzer | modanalyzer.SpecObj, ParseUnit, ModuleContext | lib/tla/modules | gen-modres-tests (13) | parity | 5 | EXTENDS/INSTANCE BFS, dep order, cycles, missing, shadowing |
| semantic-graph | semantic.Generator + node classes, Context, SymbolTable, ModuleNode, Errors | lib/tla/semantic (typed IR + gen + render) | gen-sem-tests (31) | partial | 3,6 | typed IR with EXCEPT/@/SetOfRcds/RECURSIVE, error recovery (nullODN, dup keep-first, coded diagnostics, DIAGS, L-1 masking), INSTANCE/SubstIn incl. I!Op resolution and implicit substitutions, thmdef/assume/theorem + ASSUME/PROVE bodies with NEW symbols; BY/QED proof steps, !-nav, APSubstIn, wider projection remain |
| level-check | semantic.LevelNode, levelCheck methods | lib/tla/semantic | gen-sem-tests (19) | partial | 4,7 | level values match; constraint machinery + level diagnostics absent |
| linter | linter.Linter.lintRecords | lib/tla/lint | (none) | absent | 4,7 | record field-name-clash lint not ported |
| standard-modules | StandardModules/*.tla | lib/tla/stdmods | gen-stdmods (20) | parity | 5 | 20 modules vendored with MIT provenance |
| sany-output | output.SanyOutput, LogLevel | lib/tla/diagnostics | (none) | replaced | 2 | typed diagnostics replace the logging abstraction |
| sany-xml | xml.XMLExporter, sany.xsd | (oracle adapter) | AstDump/SemDump | excluded | 6 | oracle/test format only, not a runtime surface |
| sany-explorer | explorer.* | — | (none) | excluded | — | interactive debug aid |
| sany-utilities | utilities.* (Vector, ...) | (hoon stdlib) | (none) | excluded | — | Java containers replaced by Hoon stdlib |
| symbol-matcher | semantic.SymbolMatcher | — | (none) | excluded | — | editor completion helper |
| pcal-translate | pcal Tokenize/ParseAlgorithm/AST/PcalTranslate/PcalTLAGen/trans | lib/tla/pcal-* (planned) | gen-pcal-tests (2) | absent | 8 | only corpus goldens captured; translator not written |
| pcal-crc | pcal Validator/ValidationCallBack (CRC-32) | lib/tla/crc | (crc.hoon tests, 7) | parity | 8 | java.util.zip.CRC32 + Long.toHexString reproduced |
| pcal-reference | pcal.Translator/Test/PcalDebug | — | (none) | excluded | 8 | string-in/out API-shape reference only |
| tlc-driver | tlc2.TLC (arg parsing, run modes, exit codes) | lib/tla/job | gen-mc-tests (5) | partial | 13 | exhaustive/simulate modes partial; flags map to request mold |
| tlc-repl | tlc2.REPL, TLCRunner, TraceExplorationSpec | lib/tla/eval (repl as oracle) | gen-eval-tests (37) | excluded | 9 | REPL/TE-spec generation out of scope; used only as eval oracle |
| tlc-safety | tool.ModelChecker, AbstractChecker, Worker, TLCState*, TLCTrace | lib/tla/check | gen-mc-tests (5) | partial | 7,10 | tiny BFS slice; FP64/symmetry/constraints/coverage/checkpoints absent |
| tlc-resumable | tool.AbstractChecker resumable/checkpoint contract | lib/tla/job (kont kernel) | (job tests: every-boundary pause/resume) | partial | 1 | P2-1: budgeted per-event slicing with persisted BFS/scan/sim cursors; checkpoint-to-disk semantics and byte-format parity remain unit 9 |
| tlc-dfid | tool.DFIDModelChecker/DFIDWorker | — | (none) | excluded | 9 | DFID not in core target |
| tlc-eval | tool/impl.Tool, OpDefEvaluator, ContextEnumerator, ActionItemList* | lib/tla/eval, lib/tla/check | gen-eval-tests (37) | partial | 6 | CST evaluator on finite subset; semantic-node eval absent |
| tlc-config | tool/impl.ModelConfig, Spec, SpecProcessor | lib/tla/check (cfg reader) | gen-mc-tests (5) | partial | 5 | line-oriented INIT/NEXT/INVARIANT/PROPERTY only; full grammar absent |
| tlc-value | value + value/impl (Value hierarchy) | lib/tla/eval | gen-eval-tests (37) | partial | 6 | finite bool/int/str/set/seq/rec/fcn/intv; lazy/model/EXCEPT/FP absent |
| tlc-module | module.* (Java StandardModule overrides) | lib/tla/eval | gen-eval-tests (37) | partial | 6 | operators exercised inline; override registry contract absent |
| tlc-overrides | overrides.* (annotation binding) | (contract doc) | (none) | excluded | 6 | JVM reflection binding; no runtime equivalent in Gall |
| tlc-liveness | tool/liveness.* (Liveness, LN*, TBGraph*, LiveCheck, OrderOfSolution) | lib/tla/check | gen-mc-tests (5) | partial | 8,11 | no-fairness stutter lassos only; tableau/SCC/Buchi/WF/SF absent |
| tlc-fp | tool/fp.FP64/FPSet contract | lib/tla/check | (none) | absent | 10 | rendered-string state keys used; canonical FP64 not ported |
| tlc-fp-disk | tool/fp DiskFPSet/OffHeap/MultiFPSet/LongArray | — | (none) | excluded | — | performance-only disk layout |
| tlc-queue | tool/queue.IStateQueue, StateQueue/StateDeque | lib/tla/check | gen-mc-tests (5) | partial | 10 | in-memory BFS queue; Disk*Queue excluded |
| tlc-coverage | tool/coverage.* | lib/tla/check | (none) | absent | 10 | action/cost coverage counters not ported |
| tlc-output-ec | output.EC/MP (codes, -tool tagging) | lib/tla/diagnostics | gen-mc-tests (5) | partial | 2,10 | selected verdict/trace codes; full EC taxonomy + -tool tags absent |
| tlc-model-shapes | model.MCError/MCState/MCVariable/Assignment | sur/tla-lus | (none) | replaced | 2 | structured trace shapes recast as wire nouns |
| tlc-util-fp64 | util.FP64 | lib/tla/check | (none) | absent | 10 | fingerprint function not ported (see tlc-fp) |
| tlc-util-context | util.Context (binding chain) | lib/tla/eval | gen-eval-tests (37) | partial | 6 | evaluation binding chain partial with the CST evaluator |
| tlc-util-rng | util.RandomGenerator (simulation RNG) | lib/tla/check (og) | (sim property tests) | approved-difference | 9 | Hoon `og` RNG, not TLC's; exact seed-trace parity deferred |
| tlc-util-combinatorics | util.Combinatorics, BitVector, Vect | lib/tla/eval | gen-eval-tests (37) | partial | 9 | subset/enumeration helpers partial |
| tlc-uniquestring | util.UniqueString (interning order) | (hoon atoms) | gen-eval-tests (37) | approved-difference | 9 | lexicographic string order vs interning id (compatibility.md) |
| tlc-monolith | util.MonolithSpecExtractor | lib/tla/modules | (none) | absent | 5 | monolith multi-module file support not ported |
| tlc-constants | util.TLAConstants | lib/tla/* | (implicit) | partial | 3,5 | shared literals ported as needed |
| tlc-util-io | util disk/IO/concurrency (BufferedRandomAccessFile, StatePool, locks, IdThread) | — | (none) | excluded | — | JVM-specific; nouns + Gall replace |
| tlc-debug | debug.* (DAP debugger) | — | (none) | excluded | — | out of first target |
| tlc-pprint | pprint.* | lib/tla/eval (renderer) | gen-eval-tests (37) | replaced | 9 | value rendering reimplemented; Java pprint not ported |
| tlc-distributed | tool/distributed.* | — | (none) | excluded | — | distributed TLC out of scope |
| tlc-management | tool/management, util/statistics (JMX) | — | (none) | excluded | — | monitoring/telemetry out of scope |
| tla2tex | tla2tex.* | — | (none) | excluded | — | typesetting out of scope (plan) |
| formatter | formatter.* | — | (none) | excluded | — | not in first compatibility target |
| grammar | javacc/tla+.jj | doc/tla-bnf.md, lib/tla/syntax | gen-bnf-manifest (35) | parity | 3-4 | grammar is source of truth; 35 productions manifest drift-checked |

## Public request options

Every field of `sur/tla-lus.hoon`'s `request` mold. `status` is the support
level of the option in the live Gall pipeline (`lib/tla/job`), not merely its
presence in the wire type.

| id | java-owner | hoon-owner | oracle-test | status | unit | rationale |
|---|---|---|---|---|---|---|
| op-translate | pcal.trans | job.hoon validate | (job tests) | absent | 8 | typed rejection at submit naming unit 8; no stub artifact (P2-1) |
| op-analyze | tla2sany.SANY -s/-l/-lint | job.hoon %parse/%terminal | gen-parser-tests (249) | partial | 2-4 | syntax-only analyze runs the real parser per module; semantic/level/lint flags are typed-rejected at submit (P2-1) |
| op-check-exhaustive | tlc2.TLC (safety) | job.hoon kont kernel, check.hoon bfs-cursor | gen-mc-tests (5) | partial | 7,10 | inline+cfg, budget-sliced resumable BFS (P2-1); constraints/symmetry/FP64/coverage absent |
| op-check-simulate | tlc2.TLC -simulate | job.hoon %sim kont, check.hoon sim-cursor | (sim property tests + job tests) | partial | 9,12 | real seeded engine wired and budget-sliced (P2-1); TLC RNG/enumeration-order parity absent |
| check-opt-translate | tlc2 translate-before-check | job.hoon validate | (job tests) | absent | 8 | typed rejection at submit (P2-1); no stub translation |
| check-opt-cfg | tlc2.TLC -config | job.hoon cfg-audit + do-config | gen-mc-tests (5) + job tests | partial | 5 | strict key/value audit rejects unknown/duplicate keys by name (P2-1); full ModelConfig grammar absent; cfg source override typed-rejected |
| src-inline | (n/a) | job.hoon %inline | gen-mc-tests (5) | partial | 7,10 | inline bundles run the real parse->config->search pipeline; multi-module resolution not yet wired into %check |
| src-clay | util.FilenameToStream | mar/tla, job.hoon validate | (job tests) | absent | 10 | typed rejection at submit (P2-1); Clay resolver exists but Gall issues no reads |
| limit-max-source | (n/a) | job.hoon validate | (job tests) | parity | 2 | enforced at validate before work begins |
| limit-max-modules | (n/a) | job.hoon validate | (job tests) | parity | 2 | enforced at validate |
| limit-max-states | TLCGlobals | check.hoon bfs-step cap | (job tests) | parity | 1 | enforced as each state registers, inside the sliced search (P2-1) |
| limit-max-depth | TLCGlobals | check.hoon bfs-step maxd, sim depth | (job tests) | parity | 1 | enforced at registration depth and simulation walk depth (P2-1) |
| limit-max-time | TLCGlobals runtime | job.hoon step entry | (job tests) | parity | 1 | checked on entry to every slice against the submit time (P2-1) |
| limit-max-artifact | (n/a) | job.hoon finish-arts | (job tests) | parity | 2 | enforced before storing the report artifact |
| allow-write | (n/a) | (unused) | (none) | absent | 13 | Clay write-back not implemented; flag ignored |
