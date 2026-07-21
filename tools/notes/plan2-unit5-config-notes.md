# PLAN-2 Unit 5 (TLC config processing) — oracle notes

Oracle pin: `tlaplus@4ba7d8811289fb8e95dac4d5e554c05216ba3100`.
Java owners: `tlc2.tool.impl.ModelConfig` (parse), `tlc2.tool.impl.SpecProcessor`
(config-vs-graph validation), `tlc2.output.EC`/`MP` (CFG_* 5001-5006,
TLC_CONFIG_* 2222-2281), `util.TLAConstants.KeyWords`.

## 5.0 oracle tool + corpus (done)

- `tools/oracle/ConfigDump.java`: drives `ModelConfig.parse()` on a `.cfg`
  and prints a normalized, UID-free projection — a `CONFIG` section (single
  scalars, ordered list keys, constant assignments/overrides/module maps with
  map keys sorted, values via `IValue.toString()`) + a `RAW` section echoing
  `getRawConstants()` verbatim; or a `CONFIG-ERROR` section with the exact
  `ConfigFileException` message. **SpecProcessor validation + run-spec view are
  NOT yet emitted** — added to ConfigDump at 5.3/5.4 with a paired `A.tla`.
- `tools/gen-cfg-tests.py`: per case `desk/test-data/cfg/<case>/in.txt` →
  `golden.txt`. (Input uses the `.txt` extension, not `.cfg`: the desk has no
  `%cfg` Clay mark, so a `.cfg` file aborts `|commit` with `%no-cast-between
  %mime %cfg` — same reason the mc corpus uses `-cfg.txt`. ModelConfig only
  special-cases the `.tla` extension, so `.txt` parses identically.) Oracle-only (no Hoon comparator) until 5.1 lands
  `dump-cfg`; wired into `tools/validate.py` as `oracle-only`, prints
  `TOTAL 34`. Regeneration is byte-identical.
- Corpus: 23 positive + 11 negative fixtures, ≥1 smallest positive and
  smallest negative per grammar section / CFG diagnostic family.
- Ledger: `tlc-config` row split into `cfg-lex-parse`/`cfg-constants`
  (oracle-only) and `cfg-validate`/`cfg-runspec` (absent). `check-parity.py`
  clean (73 rows, 32 owed).

## Key oracle facts (frozen baseline)

1. **Lex state.** `ModelConfig.parse` builds `new TLAplusParserTokenManager(scs, 2)`
   where `2 == SPEC` lexstate. So the cfg is lexed in the *normal in-module*
   state: the WU3 Hoon lexer driven in `%spec` state already yields the right
   tokens (idents, numbers, strings, and single tokens `<-` `!` `[` `]` `(` `)`
   `,` `=` `{` `}`). No separate cfg lexer mode is needed — start in `%spec`,
   skip comment tokens (SPECIAL_TOKENs, absorbed by `getNextToken`).
2. **`getNextToken` swallow.** A `TokenMgrError` is caught and converted to a
   synthetic `kind==EOF` token — a lexical error inside the cfg silently ends
   the stream, it does not surface as a diagnostic.
3. **One diagnostic per file.** `parse()` throws `ConfigFileException` on the
   *first* malformed construct → at most one CFG_* diagnostic (fatal, not
   accumulated). Templates (`MP.java`, `CONFIG_FILE_ERROR` =
   `"TLC found an error in the configuration file at line %1%\n"`):
   - 5001 `CFG_ERROR_READING_FILE`: `TLC encountered the following error when trying to read the configuration file %1%:\n%2%`
   - 5002 `CFG_GENERAL`: just the `line %1%` prefix (no 2nd line) — broken arg list / missing `)`
   - 5003 `CFG_MISSING_ID`: `…\nThe keyword %2% was not followed by an identifier.`
   - 5004 `CFG_TWICE_KEYWORD`: `…\nThe keyword %2% appeared twice.`
   - 5005 `CFG_EXPECT_ID`: `…\nExpected an identifier after %2%.`
   - 5006 `CFG_EXPECTED_SYMBOL`: `…\nIt was expecting %2%, but did not find it.`
4. **Location.** `loc = scs.getBeginLine()` (1-based) captured at the keyword.
   Single-value/twice/missing-id errors use `loc` (the keyword's line);
   CONSTANT-machinery symbol errors and `a keyword`/`TRUE or FALSE` use the
   *current* `scs.getBeginLine()` after consuming tokens.
5. **Keyword spellings.** From `TLAConstants.KeyWords` + literals: `CONSTANT(S)`,
   `CONSTRAINT(S)`, `ACTION_CONSTRAINT(S)`, `INVARIANT(S)`, `INIT`, `NEXT`,
   `VIEW`, `SYMMETRY`, `SPECIFICATION`, `PROPERTY`/`PROPERTIES`, `ALIAS`,
   `POSTCONDITION(S)`, `CHECK_DEADLOCK`, and the residual **underscore**-prefixed
   `_PERIODIC`, `_RL_REWARD`, `_POSSIBLE` (the plan's "PERIODIC/RLReward/_Possible"
   are these). `configTbl` is seeded so `configTbl.get(image) != null` is the
   "is this a keyword?" test that terminates list-key accumulation.
6. **Single-value keys** (`INIT NEXT SPECIFICATION VIEW SYMMETRY ALIAS
   _PERIODIC _RL_REWARD`): consume exactly one token. EOF → 5003 `[loc, kw]`;
   `old.length()!=0` (already set) → 5004 `[loc, kw]`.
7. **List keys** (`INVARIANT(S) PROPERTY/PROPERTIES CONSTRAINT(S)
   ACTION_CONSTRAINT(S) POSTCONDITION(S) _POSSIBLE`): accumulate token images
   until the next token is itself a configTbl key (or EOF). No per-token
   validation at parse time.
8. **`CHECK_DEADLOCK`**: EOF → 5003 `[loc]`; `TRUE`/`FALSE` → boolean; else 5006
   `[scs.getBeginLine(), "TRUE or FALSE"]`; twice (`previous != "undef"`) → 5004.
   Default stored value is the string `"undef"`; `getCheckDeadlock()` maps
   non-Boolean → `true`.
9. **Unknown keyword** → 5006 `[scs.getBeginLine(), "a keyword"]`.
10. **CONSTANT machinery** (`CONSTANT`/`CONSTANTS`):
    - LHS = first token, extended by `!`-chains → compound `frob!bar!glitch`
      (Bug44). Then dispatch on the next token:
    - `<-` → override. Next `[` → **module override** (`modOverrides[mod][lhs]=rhs`):
      EOF after `[` → 5005 `"<-["`; non-`]` → 5006 `"]"`; EOF after `]` → 5005
      `"<-[mod]"`. Otherwise **main override** (`overrides[lhs]=rhs` +
      `overridesReverseMap[rhs]=lhs`): EOF → 5005 `"<-"`.
    - else optional `(` arg-list: each arg via `parseValue`, comma-separated;
      non-`)` terminator → 5002 general. Then `=` required, else 5006 `"= or <-"`.
      After `=`, `[` → **module-specific constant** (`modConstants[mod]` line
      `[lhs, value]`): EOF after `[` → 5005 `"=["`; non-`]` → 5006 `"]"`.
      Otherwise **main constant** (`constants` Vect line `[lhs, arg.., value]`).
    - Operator-arg args go through `parseValue` too → bare idents become
      **ModelValues** (e.g. `Op(a,b)=5` stores model values `a`,`b`).
11. **parseValue**: `NUMBER_LITERAL`→`IntValue`; `STRING_LITERAL`→`StringValue`
    (strip the surrounding quotes); `TRUE`/`FALSE`→`BoolValue`; `{`→`SetEnumValue`
    (recursive, comma-separated, `}` required else 5006 `"}"`); EOF → 5006
    `"a value"`; else `ModelValue.make(image)` (a bare model value).
12. **rawConstants** (byte-sensitive, read verbatim downstream by
    `getConstantsAsList`): one `StringBuffer` per `CONSTANT`/`CONSTANTS`
    occurrence, seeded with the keyword image; each assignment starts with
    `"\n"+lhsToken+" "`, and every subsequent token appends `image+" "`
    (trailing space per token, via the `getNextToken(tmgr, buf)` overload).
    ConfigDump's `RAW` section echoes these verbatim, delimited by `---`.

## Frozen baseline (to replace incrementally)

Current honest reader: `check.hoon` `cfg-value`/`cfg-tokens`/`sub-comments`
(whitespace split, `\*` comment strip, keyword→next-word lookup) +
`job.hoon` `cfg-known`/`cfg-audit`/`do-config` (strict audit: only
`INIT`/`NEXT`/`INVARIANT`/`PROPERTY` accepted, every other key typed-rejects
`%config`). `gen-mc-tests` (5) exercises it end-to-end. Keep the
typed-rejection posture until each real construct lands; no parsed-but-
unvalidated key may return `%ok`.

## 5.1 groundwork landed

- `lexer.hoon`: `lex` refactored to a thin wrapper over new `lex-in`
  `|=([text start=?(%default %pragma %spec)])`; new `lex-cfg` seeds `%spec`
  (depth=1/saw=&) so a `.cfg` is tokenized directly in lexstate SPEC with no
  `----` frame, exactly like `new TLAplusParserTokenManager(scs, 2)`. Additive
  and behavior-preserving for `%default` — full ship suite `ok=%.y` (rev 178).
  Comments lex as `%com` items (skip); a lexical `%err` item = the
  `TokenMgrError→EOF` swallow (truncate the token stream there).

## 5.1 + 5.2 landed (2026-07-20)

`lib/tla/config.hoon` ports ModelConfig.parse/parseValue + the CONSTANT
machinery; `dump-cfg` renders the ConfigDump projection. gen-cfg-tests emits
`desk/tests/lib/tla/cfg.hoon` (34/34 green), flipped to `pass`; full suite
`ok=%.y`. `cfg-lex-parse`+`cfg-constants` → parity.

- Tokens compared by IMAGE (as Java `tt.image.equals`); only NUMBER/STRING
  kinds are distinguished (for parseValue). Punctuation `<- ! [ ] ( ) , = { }`
  all lex as single tokens with those exact images in %spec state.
- **cfg-value reuses `value:eval`.** A freshly-defined `$+`-recursive `$%`
  `cfg-value` (5 members, isomorphic to eval's proven `value`) OVERFLOWED the
  zuse-408 mold compiler (thousands of `[24 42]`/`[29 15]` frames on the cycle,
  the "recover: dig: over" signature) — even the exact eval recipe. Aliasing
  the already-compiled `value:eval` (via `/= eval /lib/tla/eval`) avoids
  defining a second recursive mold. cfg produces `%int`(≥0)/`%str`/`%bool`/
  `%model`/`%set`; render-value is a `?+` over those five.
- HOON GOTCHAS hit: 4+-digit decimals need dot grouping (`5.003`); `:(cat 3 …)`
  is invalid (cat is ternary → `(rap 3 ~[…])`); double-quoted `"{"`/`"}"`
  interpolate (use `(trip '{')`); `\n` isn't an escape (`\0a`); `$?(a b c)`
  bunts to the LAST member (deadlock default `%undef` placed last); `roll`
  seeds acc at the bunt so it drops a threaded prefix (fold each render section
  from empty, then weld onto `o`).

## 5.3a landed — config-vs-graph validation oracle (2026-07-20)

- `tools/oracle/ConfigValidate.java`: drives `tlc2.tool.impl.FastTool`
  (concrete; `Tool` is abstract) = SANY parse → `SpecProcessor.processConfig`
  on a paired `<base>.tla`+`<base>.cfg`, catching `Assert.TLCRuntimeException`
  (`.errorCode`, `.getMessage()`) / `TLCDetailedRuntimeException` (adds a
  `SemanticNode` span). Prints `VALIDATE` then `ok`, or `<code> <span>` +
  message. Spec arg omits `.tla` (else "Module-Table lookup failure");
  config arg omits `.cfg` (getConfig appends it).
- `tools/gen-cfg-val-tests.py` + `desk/test-data/cfg-val/*` (13 cases,
  A.tla + in.txt): stages in.txt→A.cfg in a tempdir (no `%cfg` Clay mark),
  runs ConfigValidate, captures `golden-val.txt`. `oracle-only` in validate.py,
  byte-stable. `cfg-validate` row → oracle-only.

### Frozen oracle facts (validation)

- **processConfig is fail-fast**: the first `Assert.fail` throws → at most one
  TLC_CONFIG diagnostic per file (like ModelConfig). Java check order:
  processConstants (2222 unassigned constant) → processConfig →
  processConfigInvariants → spec-xor-init/next → properties. Single-issue
  fixtures pass regardless of order.
- **Spans**: the resolution codes (2222/2227/2228/2229/2231/2233) pass no
  `expr` → span `~`. The action-level 2272 **bakes the location into the
  message text** ("...at line L, col C to line L, col C of module M...") and
  also has span `~`.
- Captured messages (byte-exact): 2222 `The constant parameter %1% is not
  assigned a value by the configuration file.`; 2227 `The configuration file
  cannot specify both INIT/NEXT and SPECIFICATION fields.`; 2228 `TLC requires
  %1% not to take any argument, but one was given: %2%` (%1% = "initial
  predicate"/"next state action"/"invariant"); 2229 `The %1% %2% specified in
  the configuration file\nis not defined in the specification.`; 2231 `The
  configuration file did not specify the initial state predicate.`; 2233 `The
  %1% %2% cannot be a constant.`; 2272 the long action-level paragraph.
- Observations: INIT with no NEXT/SPEC is **ok** (2232 not easily triggered);
  an extra `CONSTANT D = 5` not declared in the spec is **ok** (2226 not
  triggered by a stray assignment); `INVARIANT x` where x is a VARIABLE →
  2229 "not defined" (a variable is not an OpDef).

## 5.3b landed — Hoon validate-config (2026-07-20)

`config.hoon` gained `validate-config [sem-module cfg-ast]` (fail-fast like
SpecProcessor.processConfig) + `dump-validate [root src cfg]` (generates the
graph via `generate:semantic`, parses the cfg, validates, renders the
ConfigValidate projection). gen-cfg-val-tests emits `cfg-val.hoon` (13/13
green), flipped to `pass`; full ship suite `ok=%.y`. `cfg-validate` → partial.

- Java lookup semantics (confirmed): `defns.get(name)` returns an OpDefNode
  for a definition, an OpDeclNode for a **constant** (so INIT-of-a-constant →
  2233, not 2229), and **null for a variable** (variables aren't in defns, so
  INVARIANT-of-a-variable → 2229 "not defined"). Port: `find-def` over
  `defs.m`, `is-const` over `consts.m`; a name in neither (variable or absent)
  is treated as null.
- Order (fail-fast): processConstants (2222) → invariants → spec-xor-init/next
  → properties → missing-init (2231) → missing-next (2232). `validate-config`
  chains the six checks with a left-biased `first` over `(unit cfg-vdiag)`.
- 2272: after a property resolves to an arity-0 def, dispatch on `sem-def.lvl`
  — `lvl==2` (action) → 2272 with the def's **body** span (`sem-span` of
  `sem-def.body`) rendered as Location.toString (`line L, col C to line L,
  col C of module M`); lvl 0/1/3 are fine.
- Approximation: a valid arity-0 SPECIFICATION establishes init+next (the deep
  `processConfigSpec` unfold — which also owns 2234/2235/2237 and substitution
  codes — is 5.3c residue).

### 5.3b Hoon port path (as implemented; kept for reference)

The WU3 `sem-module` (from `generate`/`analyze-graph`) exposes everything:
`consts=(list [name arity at])`, `vars=(list [name at])`,
`defs=(list sem-def)` (each `sem-def` has `name`/`arity`/`lvl`/`at`), and
`lchecked`. WU4 `validate-target [m nm maxlvl]` resolves a def/thmdef by name
and gates on level. Port `validate-config [sem-module cfg-ast]`:
- 2222: every `consts` name must be assigned by `constants.cfg-ast` (or a
  mod-const); else fail.
- 2227: `spec` set AND (`init` or `next`) set.
- 2231: no `spec` and no `init`.
- INIT/NEXT: name in `consts` → 2233; in `defs` arity>0 → 2228; not in
  `defs`/`consts`/`vars` → 2229 (msg role "initial predicate"/"next state
  action").
- INVARIANT: in `defs` arity 0 → ok; arity>0 → 2228; else → 2229 ("invariant").
- PROPERTY action-level (2272): resolve in `defs`, if `lvl`==2 emit the baked
  message using the def's `at` span rendered "line L, col C to line L, col C
  of module M". (validate-target with maxlvl for temporal handles the level
  gate; the 2272 message wording is config-specific.)
Then flip gen-cfg-val-tests to `pass` + emit `desk/tests/lib/tla/cfg-val.hoon`.
Deeper SPECIFICATION-form processConfigSpec unfolding, substitution codes
(2223/2224/2225/2281), and 2242 arity-inconsistent are 5.3c residue.

## 5.4 landed — typed run-spec + mode selection (2026-07-20)

`config.hoon` gained the `run-spec`/`run-mode` molds + `assemble-run-spec
[sem-module cfg-ast]` (validate then project) + `run-spec-of [root src cfg]`.
Mode = spec-form xor init/next-form; sections keep multiplicity+order;
`deadlock=!=(%false deadlock.cfg-ast)`. Hand-written unit tests
`tests/lib/tla/cfg-runspec.hoon` (6/6). The run-spec is an internal noun, so
it is unit-tested, not differential. 2257/2259/2237 (property/fairness gates,
trivial spec) are 5.3c/WU11 residue (need deep processConfigSpec).

## 5.5 landed — integration + close (2026-07-20)

`%config` now runs the real pipeline: `do-config` → `run-spec-of:config root
modules cfg` (generate the WU3 graph → parse-cfg → validate-config →
assemble-run-spec) in one bounded slice, driving the `%bfs`/`%live`/`%sim`
konts off the run-spec's names. Config diagnostics are typed TLC failures via
`config-fail` ( `[%tlc code]` diagnostic + `%failed` with the EC message).
The honest reader is deleted: `job.hoon` lost `cfg-audit`/`cfg-known`;
`check.hoon` lost `cfg-value`/`cfg-tokens`/`sto`/`fell`/`sub-comments`/
`skip-line`, and `check`/`simulate-spec`/`run-check`/`has-property` read names
via the new `cfg-names` / `parse-cfg`. Both libs import `lib/tla/config`
(no cycle). The `%inline` source carries the full `modules` map, so `%config`
generates the graph with no prior `%semantic` stage. Four config-honesty job
tests rewritten to faithful behavior (5006 / repeated-invariant-ok / 2231 /
2229). Full suite `ok=%.y`, validate --check clean, all 9 scaffold gates PASS.
The wire contract is untouched (run-spec stays internal).

## Unit-5 residue (5.3c, future)
- Deep `processConfigSpec` SPECIFICATION-form unfold (2234/2235/2237, subst).
- Substitution codes 2223/2224/2225/2281; 2242 arity-inconsistent.
- 2230 has-value message body; TLC_INVARIANT_VIOLATED_LEVEL.
- Property/fairness gates 2257/2259 (need fairness extraction, WU11).
- Multi-invariant / multi-property checking (engine takes the first today).
