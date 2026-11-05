# R4.5.1 — regenerate, re-derive, and the two carried wrong accepts (2026-11-04)

```text
Sub-unit: R4.5.1 (plan r16): regenerate every generator; re-derive every
          doc claim about Examples coverage; carries R4.2at and R4.2ar
```

## R4.2at — a forward reference was accepted

`C == A` before `A == 3`: SANY `Unknown operator: `A'.`; the port accepted
it. **Cause:** `+gen-module` generated every unit of a module in the
module's FULL context (`+full-ctx`), so any name defined anywhere in the
module resolved.

**Fix (`lib/semantic`):** `+unit-ctxs` pairs each unit with the context the
units before it built: `+ctx-base` (builtins, EXTENDS imports, an inner
module's enclosing context; factored out of `+build-ctx-upto`) plus what
each earlier unit brought in (`+unit-names`: declarations, RECURSIVE
placeholders, INSTANCE imports, definitions, named theorems), the first
unit to bring a name in keeping it. A function definition also sees its
own name (a recursive function); an operator only through RECURSIVE.
`+g-letin` now generates LET definitions in order the same way
(`LET a == b  b == 1` is SANY's `Unknown operator: `b'`), RECURSIVE inside
a LET kept.

SANY probes (all now sem cases with SemDump goldens): `fwd-def`,
`fwd-self` (`F == F`), `fwd-var` (a later VARIABLE), `fwd-thm`,
`fwd-inst` (`I!Mk` before `I == INSTANCE`), `fwd-inst-unnamed`,
`fwd-local`, and the accepted `fwd-fcn` (`f[x \in {1}] == f[x]`),
`fwd-recursive` (`RECURSIVE R(_)` then a use); LET: `mdef-letfwd`,
`mdef-letrec`, `mdef-letfcn`. Bite: generating every unit in the full
context again fails exactly the 7 reject cases.

## R4.2ar — "Multiply-defined symbol" (4201) did not exist

Recorded as "an inner module's bound variable redeclaring an earlier
VARIABLE". Measured wider: the port had **no** 4201 Multiply-defined check
at all. All of these were accepted where SANY rejects:

| case | SANY |
|---|---|
| `VARIABLE i` then `\E i \in {1} : TRUE` (also CHOOSE, `{i \in S : P}`, `[i \in S |-> e]`, nested `\E i : \E i`) | 4201 Multiply-defined at the binder |
| `VARIABLE i` then `P(i) == i`; `C == 1` then `P(C) == C`; a LAMBDA parameter | 4201 at the parameter |
| `VARIABLE i` then `LET i == 1 IN i` | 4201 already defined + 4201 Multiply-defined |
| `C == 1` then `LET C == 2 IN C` | 4201 already defined + 4801 warning |
| `EXTENDS Sequences` then `Len == 1` | 4201 already defined + 4201 Multiply-defined (arity) |
| `EXTENDS B` (`k == 1`) then `\E k \in {1}` | 4201 |
| `CONSTANT x` then `VARIABLE x` | 4201 Multiply-defined |
| an inner module's binder against the parent's earlier VARIABLE | 4201 (the original R4.2ar) |

and `CONSTANT k` twice / `VARIABLE x, x` are the 4801 warning only (the
port listed the second declaration too).

**Fix:** SANY's `SymbolTable.addSymbol` and the Generator's checks:

- `+redefs`: a bound identifier or formal/LAMBDA parameter whose name is
  visible (anything but a builtin, one bound earlier in the same group
  included) is 4201, in the Generator's order (a quantifier group's
  variables after its range, `processQuantBoundArgs`; parameters before
  the body).
- `+sym-clash` for a definition or declaration: another kind or arity is
  4201 Multiply-defined, the same kind and arity the 4801 warning. A
  definition gets the Generator's "Operator X already defined or
  declared." first (`Function name `f' ...` for a function), its body is
  still generated for its diagnostics, and the addSymbol verdict follows
  (`+g-def-clash`). The first definition is kept.
- A clashing name is not rebound (`+visible` in `+add-params`,
  `+add-idents`, `+g-letin`): its uses resolve to the visible symbol, as in
  SANY (`P(i) == i` with `VARIABLE i` dumps `apply i VariableDeclKind`).
- `+own-decls` keeps a name's first declaration of either kind.
- An inner module is generated inside its parent (`+put-encl` context),
  its diagnostics in place: SANY reports them as the parent's.

24 sem cases `mdef-*` (Java goldens). `mdef-inner` compares the DIAGS
lines only (new `DIAGS_ONLY` in `gen-sem-tests.py`): SemDump nests an
inner module's own section in the parent's dump, which the port's dump has
never rendered. Bite: `+visible` always false fails 21 arms.

**Message text.** SANY's 4201 Multiply-defined and 4801 messages name the
other symbol's location on a second line ("with the one at line 2, col 10
to line 2, col 10 of module A."). The port keeps the first line, as it
already did for 4801 (SemDump's projection keeps only the first line, so
the goldens agree). Recording the location needs a span on every context
entry; raised with the user.

## Gates, run 1 (2026-11-04 21:20): 13 wrong rejects

`tla-zod-tools/r451-gates.sh`: the 65 shards + `lib/unicode`, the ASCII
parse census through the agent (all 373 must still agree: a wrong REJECT
from either fix shows here), and the 16-row targeted census. Run 1
(`logs/*-r451-run1.txt`): parse census **360/373**, 2 shards red
(`mc inst-param-capture`, `perf enum`), TestGraphs `error`. Four causes,
each a place the port's context was wider than SANY's, harmless until the
new 4201 check:

1. **A quantifier's range saw its own variables.** `{Round(l2) : l2 \in
   {l2 \in S : P}}` (BlockDag, BlockDagTest, TLCSailfish1/2), `p \in {p \in
   [...] : ...}` (Einstein), YoYoAllGraphs. SANY generates the range, then
   binds the group (`processQuantBoundArgs`). Now: `+g-qbound-groups`
   generates each range in the outer context plus the earlier groups;
   bounded CHOOSE and `{x \in S : P}` in the outer context.
2. **An instanced module's definitions were generated in its full
   context** (`+g-instance`): `RM == CHOOSE RM : ...` saw itself, a LET
   `a + b == ...` saw a top-level `+` defined later (the Standard
   Integers/Naturals/Reals via ProtoReals), TestGraphs' `i`. Now the same
   `+unit-ctxs` as `+gen-module` (`+unit-def-ctx` adds a function's own
   name).
3. **`+extends-of` collected a nested module's EXTENDS**: JointActionMemory's
   inner `InnerMemoryComponent EXTENDS InternalMemory` put its `VARIABLE
   mem, ctl, buf` in the parent's scope, so the parent's `\EE mem` clashed
   (also RTMemory, RTWriteThroughCache). Now it stops at a nested module.
4. **`perf enum`'s fixture used `Card1` before defining it**: SANY rejects
   it (`Unknown operator: `Card1'`). Fixture fixed (definition moved up;
   the work profile is unchanged).

New sem cases for 1-3: `mdef-range`, `mdef-chooseself`, `mdef-inst-later`,
`mdef-inner-ext` (DIAGS only: no diagnostic may appear).

## Gates, run 2 (2026-11-04 23:59 → 11-05 01:57)

- ASCII parse census through the agent (`logs/parse-census-r451.txt`):
  **373/373 agree**, 2,862 s (median 5.6 s).
- 16-row targeted census (`logs/census-r451-run2.txt`): every row's counts
  = census-r44.
- Shards: 65/66; `lib/regprop` 2 red. Its arms `root-definition-shadows-an-
  override` and `same-name-different-arity-...` evaluated a root that
  EXTENDS Sequences and defines its own `Len` -- SANY rejects both ("Operator
  Len already defined or declared"; plus Multiply-defined at another
  arity). Rewritten on legal specs (the root extends Integers, not
  Sequences): the registry property, that a user `Len` is not Sequences',
  is what they test. `imported-definition-shadows-an-override` (`EXTENDS H,
  Sequences`, H defining `Len`) is legal in SANY (the 4801 warning) and
  stays.

## Found after run 2

- **A LET name was renamed to a sibling** inside an instanced member
  (`+qualify-siblings`): `Fx == LET Gx == k IN Gx` before a member
  `Gx == 2` evaluated the member. A LET's own names are now dropped from the
  sibling map inside it. Sem case `mdef-inst-later` (Java golden; bites).
  Reachable only through R4.2at's in-order scope (a LET name may equal a
  LATER member's).
- **An empty DIAGS-only golden** generated `:~` with nothing before `==`
  (a syntax error); `gen-sem-tests.py` emits `~`.
- **Dump difference, not fixed:** an INSTANCE of a module with no
  CONSTANT/VARIABLE renders the port's `substin subs=0` wrapper; SemDump has
  no SubstIn node there. No sem case covered it before (`mdef-inst-later`
  gives B a constant). Dump-only; recorded for the user.

## Final gates (on the engine with every fix above)

- Full suite (I ran it, the R4 rule; `logs/full-suite-r451.log`): 2,478
  OK, 2 FAILED, 2,221 s. Both in `lib/stdops`
  (`user-shadows-standard`, `user-shadow-binding`): the same invalid premise
  as regprop's (a root `Len` beside EXTENDS Sequences); rewritten the same
  way, `lib/stdops` 18/18.
- 16-row targeted census (`logs/census-r451.txt`): every row's counts =
  census-r44.
- Scaffold gate (with `validate.py --check`) PASS; `evidence-counts.md`
  regenerated (sem 122 → 159 cases).
- The clause 8 censuses ran on the R4.4 engine; the R4.5.1 scope changes
  apply to both variants alike, but they are not re-measured here.

## Docs re-derived

- `testing.md`: new §*Examples coverage at R4* (clause by clause, each with
  its census file); the R3 section kept as R4's baseline, marked
  superseded.
- `compatibility.md`: the `tlaplus-Examples` coverage row (was "Not
  established"); Unit 6 paragraphs *Scope, in order* and *Redefinition*.
- `README.md`: the Status paragraph (R4 re-opened three rows and closed
  them; 138 rows, none owed).
- Not touched: the skills pack (`foxy-skills`, a separate repo) still says
  134 rows / R3 ACCEPTED -- to the user.

## Decisions (the user, 2026-11-05) and what they did

1. The second line of 4201/4801 messages: approved difference,
   `sem-diag-location`.
2. `substin subs=0`: approved difference, `sem-substin-zero`. Sem case
   `inst-noparam` captures the pin's golden (arm withheld, reason printed);
   `tests/lib/sem-approved` asserts the port's side of both rows. Ledger
   140 rows, 0 owed, 15 approved differences.
3. The skills pack (`foxy-skills`) updated for R4. Found while doing it: its
   request mold and every recipe built a FIVE-field request; R4.2c/g made it
   seven (`env`, `props`), so a request built from the pack as written is
   rejected by the mark's clam. Fixed.
4. Clause 8 re-run on this engine (below).
5. The tier-3 fresh-boot leg (below).

## (4) Clause 8 on the R4.5.1 engine (2026-11-05 05:56–07:56)

`uc-census-r451.sh`; the R4.4 runs are kept as
`logs/{parse-census-unicode,unicode-identity-census}-r44.txt`.

| census | result | total | median | max |
|---|---|---|---|---|
| (a) `examples.py --parse --unicode` | **373/373 agree** | 2,902 s | 5.6 s | 71.7 s |
| (b) `tools/ship/sem-identity.py` | **373/373 accept/accept, identical** | 3,942 s | 7.5 s | 117.4 s |

Same result as on the R4.4 engine. `tests/lib/sem-approved` 2/2 and
`lib/sem` green on the ship.

## (5) The tier-3 fresh-boot leg (2026-11-05 07:58–08:20)

`tla-zod-tools/freshboot.sh`: 5 warm runs, then 5 × (`|exit`, wait for the
lock to clear, relaunch `.run --loom 33`, idle dojo + 60 s, one perf-shard
run); then the rebuild leg the criterion also needs (R2.8.1a's method: a
comment-only edit to `lib/value.hoon` on the ship copy, 5 runs, restored).
Medians in ms (`tools/tier3-noise.py --report`):

| workload | warm | fresh boot | rebuild | rebuild vs fresh |
|---|---|---|---|---|
| enum | 717.8 | 731.9 | 740.8 | +1.2% |
| eval | 726.2 | 723.7 | 708.6 | −2.1% |
| ex-coffeecan | 3163.9 | 3129.8 | 3156.9 | +0.9% |
| ex-gameoflife | 1857.8 | 1877.9 | 1859.7 | −1.0% |
| fp | 734.8 | 708.0 | 742.9 | +4.9% |
| live | 297.3 | 293.1 | 304.1 | +3.8% |
| queue | 1279.7 | 1291.4 | 1250.9 | −3.1% |
| **median-workload spread** | **±4.5%** | **±3.0%** | **±3.4%** | |

R2.8.1a's criterion (±15% run-to-run, ±25% across a rebuild) **passes on all
three legs**; R2's fresh-boot failure (15.6%) does not reproduce. Per-workload
spread is under 7% everywhere except `live` (fresh boot 20.7%: one 354 ms run
among 289–293 ms; queue's warm 17.8% likewise one run). So a tier-3 gate is
possible; making it one (clause 5, with what per-workload threshold) is the
user's decision at R4.5.2. Raw JSON: `logs/tier3-{warm,fresh,rebuild}-r451*.json`.

## Close

Final full suite on the finished R4.5.1 tree (`logs/full-suite-r451-final.log`):
**2,478 OK, 0 FAILED, `ok=%.y`**, 2,120 s. Scaffold gate (with `validate.py
--check`) PASS; `check-parity` 140 rows, 0 owed; `check-portmap` coherent.
