# Plan-2 Unit 4 (levels/lint) — 4.0 Oracle Inventory and Frozen Baseline

Subunit 4.0 of `unit-4-plan.md`, executed 2026-07-18 against the pinned
oracle `tlaplus@4ba7d8811289fb8e95dac4d5e554c05216ba3100`.

## Frozen baseline

Pre-existing uncommitted increment (audited, preserved): level machinery in
`desk/lib/tla/semantic.hoon` (+1777 lines: `lres` constraint algebra,
`l-x`/`l-args`/`l-def`/`l-substin`/`l-inst`/`l-lint`, builtin max-level
tables), `SemDump.java` switched to full settings (semantic + levels +
lint, no PlusCal validation), and 16 fixture families
(`lvl*`, `lint*`, `recmut`).

- Regeneration is byte-identical (`gen-sem-tests.py` twice, `md5sum` over
  all goldens equal).
- 47-case pre-4.0 suite: **45/47 green**; `lvlqtb`, `lvltmp` red, both on
  one delta: unreferenced bound identifier `bound i L-1` (oracle) vs `L0`
  (Hoon). `lvltmp`'s five temporal diags 4310–4314 already match.
- Expanded 56-case suite (4.0 adds 9 fixtures): **48/56 green**. Red set
  and exact deltas below; each red is a subunit's named failing case.

## Two-phase gating (normative)

SANY runs level checking only when semantic generation produced no errors:
any semantic ERROR renders every levelCheck-derived level `-1`
(declaration levels survive). A **level** error does the opposite —
computed levels stay visible and only `D`-lines are added (all `lvl*`
goldens show real levels beside 4205/4206/43xx). The Hoon renderer's
blanket mask-to-`-1` is correct for phase one and must not fire for phase
two.

## SemDump 4.0 extensions

- `apsubstin` arm (was the `?APSubstInNode` fallback), mirroring `substin`.
- `LEVELS` section after `DIAGS`: one line per root-module def (+ module
  node, + thmdefs), reading the public `LevelNode` collection fields
  (no `levelChecked` assertions):
  `lvl <name> L<n> [ml=[..] w=[..]] [mml=[..] olc=[..]] [lp={..}] [lc={..}] [alc={..}] [alp={..}] [nlp={..}]`
  — max-levels and weights per argument; higher-order min-max levels and
  op-level conditions (`olc[i][j][k]`, k over param *i*'s arity — the
  allocation in `OpDefNode` line 1109 indexes by `params[i].getArity()`);
  level params, level constraints (`p<=n`), arg-level constraints
  (`(p,i)>=n`), arg-level params (`(op,i,param)`), non-Leibniz params.
  Every collection is sorted lexicographically because SANY's
  `HashSet`/`HashMap` iteration order is identity-hash volatile;
  `ParamAndPosition`/`ArgLevelParam` are package-private with UID-bearing
  `toString`s, so `tools/oracle/LevelProbe.java` (package
  `tla2sany.semantic`) renders them by name only.
- `gen-sem-tests.py` splits `LEVELS` into `golden-lvl.txt` per case:
  **oracle-only** (manifest row `level-constraints`) until the 4.1 Hoon
  constraint renderer exists. `golden.txt` and the generated test arms are
  unchanged in shape, so green cases stay green.

## Owner-to-fixture matrix

| Subunit | Java owner (pin) | Rule family | Green fixtures | Named failing oracle case |
|---|---|---|---|---|
| 4.1 | `SetOfLevelConstraints`, `SetOfArgLevelConstraints`, `ArgLevelParam`, `ParamAndPosition` | constraint set algebra + rendering | — (Hoon algebra live but unobserved) | every `golden-lvl.txt` (56, oracle-only; e.g. `lvlho`: `lvl H L2 ml=[3] w=[1] mml=[2] olc=[F] lc={x<=1} nlp={x}`) |
| 4.2 | `LevelNode`, first-order `OpApplNode`/`OpDefNode.levelCheck`, `BuiltInOperators` tables | bottom-up levels, arg-max 4205 | `constvar nullary nary infix quant letin ite casex spec lvlop` | `lvlqtb`/`lvltmp`: unreferenced bound identifier must stay `L-1`; `lvlcdot`: DIAGS text must backslash-escape (`\\cdot`) |
| 4.3 | `OpDefNode.levelCheckParams`: `maxLevels`/`weights`/`minMaxLevel`/`opLevelCond` | higher-order applications | `lvlho` (4272), `hoparam` | `hoparam`'s `golden-lvl.txt` (`mml=[0;] olc=[FT;]`) — projection parity; doubly-higher-order argLevelParam remapping has no fixture yet (4.3 must add one) |
| 4.4 | recursive-section fixpoint in `OpDefNode`, `$RecursiveFcnSpec` | recursion | `recmut recur lvlrec` (4290) `lvlsec` | `recfcn`: recursive function must carry `ubound f` self-binder + `$FcnApply` subtree; higher-order `RECURSIVE H(_(_))` is a parse REJECT (parser corpus owns it) |
| 4.5 | node-specific `levelCheck`: prime, `ENABLED`, `UNCHANGED`, temporal 4310–4315, fairness, `\cdot`, `ASSUME` 4206 | node rules | `lvlpri lvlena lvlunc lvlwf lvlwfp lvlcdot`(pos) `lvlasm lvltmp`(diags) | `lvltmp`/`lvlqtb` bound `L-1` (shared with 4.2); BY/QED proof-body rules blocked on unit-3 residue (no fixture possible yet) |
| 4.6 | `InstanceNode`/`SubstInNode`/`APSubstInNode.levelCheck`, `Subst.getSub*Set`, Leibniz | instances/substitution | `lvlinst lvlinstc` (4245, re-level) `instimp instun inst` | `lvlinsth`: operator substitution renders `oparg` not `apply`; `lvlinstm`: 4244+4246; `lvlinstp`: 4244+4247; `apsubst`: instanced theorem import (`apsubstin`) — unit-3 residue dependency |
| 4.7 | `Linter.lintRecords`; driver `filterVisibleMessages`/`reportMessages` | record lint + controls | `lintok lintrc lintx`(cross-module) `lintsd`(same-domain suppression) | driver-level suppression/elevation: no oracle path through SemDump (report-time, not `Errors`-channel) — evidence is Hoon `lint-options` unit tests (4.7) |
| 4.8 | Gall `%analyze` flags, `$kont` | integration | — | `%analyze` `level`/`lint` flags are typed-rejected today (job tests); wiring happens only after 4.2–4.7 |

Red set (8): `lvlqtb lvltmp lvlcdot recfcn lvlinsth lvlinstm lvlinstp
apsubst`. Everything else (48) green as of this baseline.

## 4.0 closing validation (2026-07-18)

- `python3 tools/gen-sem-tests.py` — 56 cases, TOTAL 56, regeneration
  byte-identical on a second run (md5 over all goldens).
- `python3 tools/validate.py --check` — clean: every generator reproduces
  from the pin; 719 compared cases + 2 oracle-only;
  `desk/doc/evidence-counts.md` regenerated (sem 31 → 56).
- `python3 tools/check-parity.py --check` — ledger well-formed, 70 rows,
  0 unclassified.
- Focused suite `-test /=tla-lus=/tests/lib/tla/sem ~` on tla-zod:
  48/56, red = exactly the 8 named cases.
- Full suite `-test /=tla-lus=/tests ~` on tla-zod: `ok=%.n` with the
  failure set exactly `{apsubst lvlcdot lvlinsth lvlinstm lvlinstp lvlqtb
  lvltmp recfcn}` — no regression in lexer/parser/parse-err/bnf/modres/
  eval/mc/job/agent/fuzz suites. The suite goes back to `ok=%.y` only
  when 4.2–4.6 land; that is deliberate (failing oracle cases first).

## Notes for later subunits

- `lvlinstm`/`lvlinstp` were built from `InstanceNode.levelCheck`
  (lines ~195–290): 4246 fires when the instanced module's
  arg-level-constraint minimum exceeds the substituted `OpDefNode`'s
  `getMaxLevel(j)`; 4247 via an `ArgLevelParam` between two module params
  (`D == F(c)`) whose substitutions conflict. Both also trip 4244
  (non-Leibniz `Op(a) == a' = x`).
- The lint suppression clauses (other component / other same-domain record
  built from declarations) are inside `lintRecords` itself and are
  Errors-channel visible — `lintsd` covers them. Only per-code
  suppression/elevation is driver-level.
- Do not grow the `$sem` or `$kont` `$%` unions for 4.x nodes (zuse-408
  mold-compiler hang); use the reserved-apply encoding.

## 4.1 Canonical constraint types and set algebra (done 2026-07-18)

The projection went from oracle-only to byte-compared: `dump-sem` now
appends the LEVELS section and `gen-sem-tests.py` compares tree + DIAGS
+ LEVELS as one wain per case. Focused suite 48/56; the red set is
exactly the 8 named 4.2–4.6 cases from the 4.0 matrix (no new reds).
Algebra unit suite `tests/lib/tla/lvl.hoon` 10/10.

What landed beyond the frozen 4.0 machinery:

- `lres`/`oplev` grew `all` (allParams), `nlp` (nonLeibnizParams), and
  `lbz` (isLeibnizArg; builtins = ArgWeights>0 with variadic index 0,
  user defs = param absent from body nlp, monotonic across recursive
  iterations). Non-Leibniz argument positions inject the operand's
  allParams (`OpApplNode.levelCheck` line 638); bound identifiers are
  removed from lp/all/nlp but NOT from the constraint sets.
- LetIn: SANY never fills a LetInNode's nonLeibnizParams (keep empty);
  lets contribute lc, alc, and occur-filtered alp (previously dropped).
- Bound identifiers key constraints by a span-derived owner
  (`+bound-key`, e.g. `b3.4`) standing in for SymbolNode identity —
  same-named binders keep distinct entries and the renderer keeps
  duplicates (`lc={x<=2,x<=2}` in setforms).
- `+l-deps`/`denv`: dependency-first level check of every loaded module,
  seeding definition oplevs (imported ops carry real constraint sets —
  the `n<=2` on everything EXTENDS-ing Naturals comes from a Naturals
  definition's own lc) and per-module `mlev` (constancy + module lc).
  `+l-inst` consumes it instead of re-checking the instanced module.
- `Subst.getSubLCSet` kind overrides in `+l-substin`: when the
  instanced module is non-constant, CONSTANT-keyed entries tighten to 0
  and VARIABLE-keyed to 1 before mapping through the substitution. The
  `$SubstIn` reserved apply's op name now carries the module
  (`'$SubstIn:B'`, `+substin-mod`; all matches are prefix-based).
- Module line: lp = the constant declarations; lc/alc/alp union own
  defs + EXTENDS-imported defs (`+extends-of`; INSTANCE-loaded modules'
  raw defs must NOT contribute — that distinction is invisible in the
  generation ctx, hence the tree walk) + assumes/theorems; alp filtered
  per def by `ArgLevelParam.occur(params)`; `ModuleNode.getLevel()`
  throws in SemDump, so the module always prints `L-1`.
- Masked (semantic-error) form: `lvl <name> L-1` with `ml=? w=?` /
  `mml=? olc=?` for arity>0 / higher-order defs — the oracle's getters
  throw when levelCheck never ran.
- Renderer order/format: entries render name-only, sorted
  byte-lexicographically (Java Collections.sort), `alc` as
  `(p,i)>=n`, `alp` as `(op,i,param)`, empty segments omitted; segment
  order lp lc alc alp nlp.

Deferred out of 4.1 (owned rows unchanged): the doubly-higher-order
call-site argLevelParam remapping and its opLevelCond non-Leibniz rule
(4.3), instance-node lc/alc/alp contributions to the module line and
4244/4246/4247 (4.6 — today only lvlinstm/lvlinstp would notice),
driver-level lint controls (4.7).

Subunit handoff:

```text
Subunit: 4.1
Java owner and entry method: SetOfLevelConstraints/SetOfArgLevelConstraints put+putAll, ArgLevelParam/ParamAndPosition, LevelNode collection fields; SemDump.lvlLine projection
Current Hoon owner: lib/tla/semantic.hoon (lc-*/ac-* algebra, lres/oplev/denv, l-deps, LEVELS renderer in l-module-core)
Smallest failing parity case: none for 4.1; next failing cases are lvlqtb/lvltmp (4.2)
New or changed nouns: lres/oplev += all/nlp/lbz; lenv += mlevs; denv; $SubstIn op name carries module
Diagnostic/result expected: no diagnostic changes; LEVELS section byte-equality
Focused validation result: sem 48/56 (reds = the 8 named 4.2-4.6 cases), lvl 10/10
Full validation result: -test /=tla-lus=/tests ~ on tla-zod: ok=%.n with exactly {apsubst lvlcdot lvlinsth lvlinstm lvlinstp lvlqtb lvltmp recfcn}; validate.py --check clean; check-parity.py --check clean (70 rows)
Pause/resume evidence, if applicable: n/a (no Gall wiring in 4.1)
Parity-manifest rows changed: level-constraints (oracle-only -> partial, compared evidence), level-substitution (note update)
Compatibility limitations removed or added: LEVELS projection now compared; Leibniz *tracking* ported (4244/4246/4247 diagnostics still absent); doubly-higher-order remapping noted for 4.3
Remaining dependencies: 4.2 next (bound-identifier L-1 sentinel, \cdot DIAGS escaping)
```

## 4.2 Bottom-up levels and basic operator constraints (done 2026-07-18)

Both named failing cases closed; suite 51/56, red set now exactly
`{apsubst lvlinsth lvlinstm lvlinstp recfcn}` (4.3–4.6 owners). The
bulk of 4.2's scope (bottom-up levels, builtin level/weight/max-level
tables, arity + 4205 argument-maximum checks, exact diagnostic
code/span/message/order) was already green at the 4.0 baseline and is
unchanged; what landed here:

- **Unreferenced bound identifiers keep SANY's uninitialized `L-1`**
  (`lvlqtb`, `lvltmp`): `sbind` gained a `used=?` flag (adding a record
  field inside the `$+` cycle is safe — `spar` precedent; only `$%`
  member growth hangs the zuse-408 mold compiler). `+l-apply-def` marks
  each `ubound`/`bound` binder used iff its span-derived key appears in
  the union of the arguments' `allParams` — exactly SANY, since a
  reference is what invokes `FormalParamNode.levelCheck` (weight-0
  positions still count), ranges are checked outside the binding scope,
  and inner shadowing is already excluded because inner nodes removed
  their own bound keys from `all`. The renderer prints binders with
  `(rlvl |(mask !used.b) 0)`, the same form as formal params.
- **D-line messages are escaped per SemDump `esc()`** (`lvlcdot`,
  `lvltmp`'s 4313): `+esc-msg` doubles backslashes and escapes
  \r/\t/\f after the first-line cut (`\cdot` → `\\cdot`, `\land` →
  `\\land`). Tree lines (`apply \cdot …`) stay raw — SemDump only
  escapes `str` values and DIAGS messages.

Subunit handoff:

```text
Subunit: 4.2
Java owner and entry method: LevelNode/FormalParamNode.levelCheck (uninitialized -1), first-order OpApplNode/OpDefNode.levelCheck, BuiltInOperators tables; SemDump.esc
Current Hoon owner: lib/tla/semantic.hoon (sbind used flag, l-apply-def usage marking, render-sem binder lines, esc-msg)
Smallest failing parity case: none for 4.2; next failing cases are hoparam's doubly-higher-order remapping fixture (4.3, to be added) and recfcn (4.4)
New or changed nouns: sbind += used=? (all construction sites default |; l-apply-def rewrites)
Diagnostic/result expected: bound/ubound L-1 vs L0 in the tree; backslash-escaped DIAGS text
Focused validation result: sem 51/56 (reds = apsubst lvlinsth lvlinstm lvlinstp recfcn), lvl 10/10 unchanged
Full validation result: -test /=tla-lus=/tests ~ on tla-zod: 785 OK, ok=%.n with exactly the 5 reds above; validate.py --check clean; check-parity.py --check clean
Pause/resume evidence, if applicable: n/a
Parity-manifest rows changed: level-basic (partial -> parity), level-node-rules (note: bound sentinel closed, BY/QED residue remains)
Compatibility limitations removed or added: removed the two closed bullets (bound-identifier L-1, DIAGS escaping)
Remaining dependencies: 4.3 (higher-order: add the doubly-higher-order argLevelParam remapping fixture), 4.4 (recfcn), 4.5 negative ASSUME fixtures, 4.6 instance ops
```
