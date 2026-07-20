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
| semantic-graph | semantic.Generator + node classes, Context, SymbolTable, ModuleNode, Errors | lib/tla/semantic (typed IR + gen + render) | gen-sem-tests (56) | partial | 3,6 | typed IR with EXCEPT/@/SetOfRcds/RECURSIVE, error recovery (nullODN, dup keep-first, coded diagnostics, DIAGS, L-1 masking), INSTANCE/SubstIn incl. I!Op resolution and implicit substitutions, thmdef/assume/theorem + ASSUME/PROVE bodies with NEW symbols; BY/QED proof steps, !-nav, APSubstIn, wider projection remain |
| level-constraints | semantic.SetOfLevelConstraints, SetOfArgLevelConstraints, ArgLevelParam, ParamAndPosition | lib/tla/semantic (lres, lc-*/ac-* algebra, LEVELS renderer) | gen-sem-tests (56, LEVELS section compared) + tests/lib/tla/lvl (10) | partial | 4 | 4.1 done: min/max-merge algebra unit-tested (empty/duplicate/conflicting/permuted merges); Hoon renders the sorted LEVELS projection (levels, ml/w, mml/olc, lp/lc/alc/alp/nlp with allParams and Leibniz-arg tracking, node-identity keys for same-named binders, EXTENDS-imported and dependency-seeded constraint sets, getSubLCSet kind overrides) byte-compared per case; the 8 sem reds are owned by the 4.2-4.6 rows |
| level-basic | semantic.LevelNode + first-order OpApplNode/OpDefNode levelCheck, BuiltInOperators level tables | lib/tla/semantic (l-x, l-args, l-def) | gen-sem-tests (56) | parity | 4 | 4.2 done: bottom-up levels, builtin level/weight/max tables, 4205 arg-max diags, unreferenced formal AND bound identifiers keep SANY's uninitialized L-1 (usage tracked through the arguments' allParams, shadowing-correct), DIAGS message text backslash-escaped per SemDump esc() |
| level-higher-order | OpDefNode levelCheckParams: maxLevels, weights, minMaxLevel, opLevelCond; OpApplNode call-site alp blocks; Generator/OpDefNode.match 4270/4271 | lib/tla/semantic (oparg-*, ref-arity, g-opappl, l-apply-def) | gen-sem-tests (lvlho, hoparam, ho273, hodbl, horemap, hoparm, houn, hoargm) | parity | 4 | 4.3 done: 4272/4273 rejection, oparg levels/weights, mml/olc projection, call-site argLevelParam remapping (op side to formal-parameter operator arguments, param side to operand level params), alp-driven lc (argDef max-level bound) and ac (operand-level lower bound), the doubly-higher-order non-Leibniz rule, unused/mixed/zero-arity params, and the 4270/4271 operator-argument arity mismatches (selector error before argument generation + match-phase 4271, argument becomes nullODN) |
| level-recursion | OpDefNode recursive-section fixpoint iteration, RecursiveFcnSpec | lib/tla/semantic (rec-seed, l-def, g-fcn-body, g-x %n-fcnappl) | gen-sem-tests (recmut, recur, recrev, recun, rechi, lvlrec, lvlsec, recfcn) | parity | 4 | 4.4 done: self/mutual recursion (both declaration orders), recursion through operator arguments, unused recursive arguments keep the seeded ml=2/w=1 floor, 4290 primed-arg diag, recursive functions ($RecursiveFcnSpec with the ubound self-binder, FormalParamKind self-references, $FcnApply). Convergence is structurally bounded: SANY's algorithm is a fixed two-pass fixpoint (check, raise to section maxima, recheck) with no unbounded iteration, mirrored exactly; higher-order RECURSIVE is a parse reject, covered by the parser corpus |
| level-node-rules | node-specific levelCheck: prime, ENABLED, UNCHANGED, temporal 4310-4315, fairness, \cdot, ASSUME 4206 | lib/tla/semantic (l-x per-op level conditions, ArgMaxLevels tables) | gen-sem-tests (lvlpri, lvlprin, lvlena, lvlunc, lvlencu, lvltmp, lvlwf, lvlwfp, lvlwfn, lvlcdot, lvlasm, lvlasmn, lvlqtb) | parity | 4 | 4.5 done: every node-specific rule routes through 4205 (ArgMaxLevels: nested prime, ENABLED/UNCHANGED at and above their bounds, WF/SF subscript and action operands), 4206 (ASSUME at levels 1, 2, and 3), or the temporal 4310-4315 family — boundary fixtures below/at/above each limit, codes/spans/messages/order byte-matched. BY/QED proof-step nodes are not generated at all (unit-3 residue owns them; their level rules follow when the nodes land); higher-order RECURSIVE and UNCHANGED-of-unparenthesized-prime are parse rejects owned by the parser corpus |
| level-substitution | InstanceNode/SubstInNode/APSubstInNode levelCheck, Subst.getSub*Set, constructSubst, Leibniz tracking | lib/tla/semantic (l-substin, l-inst, g-instance, ext-decls, build-ctx) | gen-sem-tests (lvlinst, lvlinstc, lvlinsth, lvlinstm, lvlinstp, apsubst, inst, instun, instimp, instlcl, instrex) + tests/lib/tla/lvl (validate-target) | parity | 4 | 4.6 done: 4244 (non-Leibniz operator substitution), 4245 (both constant-module and module-constraint forms), 4246 (arg-level constraint not met), 4247 (co-parameter level), the instance node's getSubLCSet level-constraint contribution to the module line, operator substitutions rendered as $OpArg, APSubstIn theorem/assumption import, constructSubst implicit-then-explicit substitution order, and the pure validate-target configuration gate; EXTENDS now imports only definitions from instanced modules (declarations no longer leak) and re-exports inherited declarations into the module dump |
| linter | linter.Linter.lintRecords + SANY filterVisibleMessages/reportMessages | lib/tla/semantic (l-lint, collect-records, built-from-decls, apply-lint-options, lint-warnings) | gen-sem-tests (lintok, lintrc, lintx, lintsd, lintnest, lintmf) + tests/lib/tla/lvl (lint-options) | parity | 4 | 4.7 done: 4802 code/span/message, no-collision, local/imported collision, nested-record and multi-field constructors, both built-from-declarations suppression clauses; the driver-level lint-options (per-code suppression, warning-to-error elevation preserving order, and the suppressed/as-errors overlap rejection) match SANY filterVisibleMessages/reportMessages, exercised by Hoon unit tests since they are report-time and invisible to the Errors channel |
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
| cfg-lex-parse | tool/impl.ModelConfig getNextToken/parse/parseValue, CFG_* 5001-5006 | lib/tla/config (ctoks, parse-cfg, parse-value, dump-cfg) | gen-cfg-tests (34) | parity | 5 | 5.1 done: full line grammar (all keyword sections, single-value/list/deadlock dispatch, keyword-boundary stop) + parseValue (int/string/bool/`{…}`set/model) + CFG diagnostics (5002 general/5003 missing-id/5004 twice/5005 expect-id/5006 expected-symbol) byte-match ConfigDump; cfg lexed via the WU3 lexer in %spec state (lex-cfg), TokenMgrError→EOF swallow, values reuse eval.hoon's value mold |
| cfg-constants | tool/impl.ModelConfig CONSTANT/override/modOverrides/modConstants/rawConstants | lib/tla/config (const-section) | gen-cfg-tests (34) | parity | 5 | 5.2 done: plain/operator-arg/module-specific assignments, main + module overrides (`<-`, `<-[mod]`), compound Bug44 `a!b!c` LHS, args-as-model-values, and byte-exact rawConstants buffers (keyword-seeded, `\n`+lhs then each token image+space) match ConfigDump |
| cfg-validate | tool/impl.SpecProcessor config-vs-graph TLC_CONFIG_* (2222-2281) | lib/tla/config (validate, planned 5.3b) | gen-cfg-val-tests (13) | oracle-only | 5 | 5.3a done: ConfigValidate oracle drives FastTool (SANY→SpecProcessor.processConfig, fail-fast, one diagnostic/file) capturing 2222 (unassigned constant), 2227 (both spec+init), 2228 (target takes an argument), 2229 (target not defined), 2231 (missing init), 2233 (init is a constant), 2272 (property is action-level); Hoon validator over the WU3 `sem-module` (defs/consts/vars) + WU4 `validate-target` not yet written |
| cfg-runspec | tool/impl.SpecProcessor mode selection + property/fairness gates, typed run-spec | lib/tla/config (planned 5.4) | gen-cfg-tests (5.4) | absent | 5 | SPEC xor INIT/NEXT (2227/2231/2232/2237), 2257/2259 property/fairness gates, run-spec assembly + mode selection |
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
| op-analyze | tla2sany.SANY -s/-l/-lint driver phases + filterVisibleMessages | job.hoon %parse/%semantic/%terminal, semantic.analyze-graph | gen-parser-tests (249) + tests/lib/tla/job (analyze pipeline) | parity | 2-4 | 4.8: syntax runs the real parser per module; the semantic/level/lint flags run the real Work Unit 3+4 pipeline via analyze-graph, with diagnostics split by phase and gated as SANY gates them (a semantic error suppresses level and lint; a level error suppresses lint); apply-lint-options threads the driver warning controls (default empty); the verdict fails on any parse/semantic/level error, single bounded slice, pause/resume identical |
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
