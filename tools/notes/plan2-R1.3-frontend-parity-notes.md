# R1.3 — Front-end parity (units 2-4) — notes

Plan: `~/FoxyLabs/tla-lus/R1.3-R1.5-plan.md`. Oracle pin unchanged:
`tlaplus@4ba7d8811`, `tlaplus-Examples@47b0e2cc`. Ledger rows:
`semantic-graph`, `level-constraints`, `parse-errors`, `tlc-output-ec`,
`tlc-constants`.

## R1.3.0 — kickoff (DOCS/ORACLE ONLY, 2026-08-05)

No ship change, no generator change, no `-test`, no census edit. Groups the
front-end divergence census by root cause, confirms each bucket maps to the
planned R1.3.1-R1.3.4 step, and captures the exact SANY diagnostics the front
end must reproduce for the three `java=reject` specs. Same pattern as
R1.5.0 / C1.0 / 7.0 / 8.0.

### 1. Census baseline — FROZEN

The census that R1.3.x flips is already committed and drift-guarded:
`desk/test-data/tier2/divergences.txt`, generated from
`tools/gen-tier2-tests.py` (`KNOWN_DIVERGENCES` curated + `SANY_BATCH_DIVERGENCES`
flat batch + `SUB_BATCH_DIVERGENCES` subdir batch). Verified reproducible with
`python3 tools/tier2.py --check` (no ship deploy).

Front-end rows, deduped to unique specs:

- `tier2.hoon`: **3 specs** — `CigaretteSmokers` (curated), `IllegalOperatorTest`
  (curated **and** flat batch — one spec, two rows), `BagsTest` (flat batch).
- `tier2-sub.hoon`: **32 specs** — `SUB_BATCH_DIVERGENCES`.
- No spec appears in both shards ⇒ **35 unique front-end divergent specs**
  (the plan's "~33" predates the last two R1.1.9 subdir additions —
  `EWD998/EWD998`, `suite/test219`/`test51`).

Direction: **31 are `java=accept / hoon=reject`** (a Hoon front-end *feature
gap* — SANY accepts, the WU3/WU4 pipeline wrongly rejects), and **only 3 are
`java=reject / hoon=accept`** (Hoon too lenient): `IllegalOperatorTest`,
`suite/etest16`, `suite/test214`.

### 2. Root-cause buckets → R1.3.x steps (CONFIRMED)

Grouped from the `divergences.txt` reason column; each bucket confirmed against
the spec source and (for rejects) the SANY diagnostic.

| bucket | step | specs | n |
|---|---|---|---|
| **LAMBDA not in WU3 graph** | R1.3.1 | `CigaretteSmokers`, `BagsTest`, `ModuleOverwrites/ModuleOverwrites`, `coverage/F,K,L`, `EWD840/Error02,Error03,MC02,MC02Sim`, `EWD998/EWD998`, `suite/test201` (LAMBDA *through* INSTANCE…WITH) | 12 |
| **Higher-order op-arg arity (deep 4271)** | R1.3.2 | `IllegalOperatorTest` (EC 4271), `suite/test30`, `suite/test999` | 3 |
| **INSTANCE…WITH substitution edges** | R1.3.3 | `gh1134/MultiUser`, `suite/test206,test216,test219,test219a,test51`, `suite/test203` (WITH over RECURSIVE), `examples/SingleLaneBridge/SingleLaneBridge` (RECURSIVE + HO) | 8 |
| **SANY semantic/level conformance edges** | R1.3.4 | `gh1134/SingleUser`, `suite/etest15`, `suite/etest16` (EC 4262), `suite/test16`, `suite/test214` (EC 4357), `suite/test42,test43,test52,test7,test9,test10,test23` | 12 |

Totals 12+3+8+12 = 35 = the whole front-end census. Deviations from the plan's
tables, resolved here:

- **`suite/test201`** — the plan tables it under R1.3.1 (LAMBDA) *and* mentions
  INSTANCE. It is LAMBDA reached through an INSTANCE…WITH; kept in R1.3.1
  (LAMBDA generation is the blocking gap; the INSTANCE edge is R1.3.3's already).
- **`suite/test203`** — INSTANCE…WITH over a RECURSIVE def; not tabled in the
  plan's R1.3.3 row but its census reason maps there. Assigned to **R1.3.3**.
- **`gh1134/SingleUser`** — the plan tables it under R1.3.3 next to
  `gh1134/MultiUser`; the census reason is `_CONF` (a plain conformance edge,
  not an INSTANCE substitution). Assigned to **R1.3.4** per its measured cause.
  (`MultiUser` stays R1.3.3 — its reason is `_INST`.)

### 3. Oracle capture — the SANY diagnostics R1.3.x must reproduce

Two golden shapes, both byte-reproducible from `SemDump A.tla` at the pin
(`java -cp <jar>:tools/oracle/build SemDump <spec>.tla`, run from the spec's dir):

**(a) 31 `java=accept` specs.** Golden = `ACCEPT` + the root module's semantic
tree (+ LEVELS). The front end already REJECTs; the fix makes it ACCEPT and
generate the same graph. No error text to match — the acceptance *is* the golden
(covered by the existing `semantic-graph` / `level-constraints` differential once
the spec parses).

**(b) 3 `java=reject` specs.** Golden = the exact SemDump `DIAGS` line(s). The
front end currently ACCEPTs (too lenient); the fix must REJECT with the same
error code, span, and (normalized first-line) message. Captured verbatim:

```
IllegalOperatorTest  (R1.3.2)
  D 4271 ERROR 3.8-3.11 Argument number 1 to operator 'D'
    (SANY EC 4271: arg operator's parameter profile mismatch — 'D' expects a
     0-parameter operator; the deep-4271 check R1.3.2 adds)

suite/etest16  (R1.3.4)
  D 4262 ERROR 5.27-5.27 Non-unique fields in constructor.
  D 4262 ERROR 7.27-7.27 Non-unique fields in constructor.
    (SANY EC 4262: duplicate record/constructor field names — a record-literal
     well-formedness check the Hoon generator is missing)

suite/test214  (R1.3.4)
  D 4357 ERROR 10.11-10.14 The only expression allowed as a fact in a HIDE is
    (SANY EC 4357: proof-step HIDE fact restriction — proof-body conformance)
```

(SemDump normalizes each SANY message to its first line; that first line is the
golden the Hoon comparator matches. These three EC/span/first-line triples are
the R1.3.2/R1.3.4 acceptance goldens.)

### 4. Confirmed front-end gaps (the fix sites)

- **LAMBDA (R1.3.1).** Parser already emits `n-lambda`
  (`desk/lib/syntax.hoon:2039`, via `lambda-expr` at `:2015`); `semantic.hoon`
  has **no** `n-lambda` arm (grep empty) — it is neither generated nor
  level-checked, so any spec passing `LAMBDA … : …` into an operator-argument
  position rejects. A LAMBDA is an inline operator definition flowing into an
  op-arg slot; generate it as a `%user-op` symbol with the bound idents as
  formal params, level = its body's level.
- **Higher-order arity (R1.3.2).** `sym` already carries `parg=(list @ud)` —
  the per-op argument parameter arities (`semantic.hoon:40,248`). The current
  4271 check compares the *count* only; the deep check compares the argument
  operator's own `parg` profile against the expected slot (EC 4271 as above).
- **INSTANCE…WITH (R1.3.3).** `semantic.hoon` has the substitution scaffolding
  (`:23`, `:382`) but not the operator/`\E`/SUBSET/higher-order-under-subst and
  temporal-under-instance edges the 8 specs exercise.
- **Conformance edges (R1.3.4).** Per-spec triage; two are Java-rejects the
  front end is too lenient on (`etest16` EC 4262, `test214` EC 4357), the rest
  are accepts the front end wrongly rejects.

### 5. How each R1.3.x step is verified (unchanged from the plan)

1. Hoon fix in `desk/lib/{semantic,syntax,...}.hoon`.
2. Delete the fixed entries from `KNOWN_DIVERGENCES` / `SANY_BATCH_DIVERGENCES`
   / `SUB_BATCH_DIVERGENCES` in `tools/gen-tier2-tests.py`.
3. `python3 tools/gen-tier2-tests.py` (regenerate shards + `divergences.txt`).
4. `python3 tools/tier2.py --check` (byte-reproducible) + ship-run
   `-test /=tla-lus=/tests/lib/tier2{,-sub} ~` → green.
5. Full suite `-test /=tla-lus=/tests ~` (no regression) + scaffold gate.
6. Named ledger row(s) → `parity`; update `compatibility.md` / `port-map.md`.

Recommended order per the plan: **R1.3.1 (LAMBDA, ~12 specs, highest leverage)
→ R1.3.2 → R1.3.3 → R1.3.4 → R1.3.5 (ledger residue) → R1.3.6 (close-out)**.
Ship-run gotchas (dojo send-keys `-l --`, `|commit` before `=x -build-file`,
scrollback-vs-stale) are in `[[tla-lus-dev-environment]]`.

---

# R1.3.1 — LAMBDA in the WU3 semantic graph

Sub-plan: `~/FoxyLabs/tla-lus/R1.3.1-plan.md`. Closes the 12-spec LAMBDA bucket.

## R1.3.1.0 — kickoff (DOCS/ORACLE ONLY, 2026-08-05)

No ship/generator/census change. Captures how SANY renders a LAMBDA op-arg,
confirms the representation approach, maps the multi-param shape, and lists the
byte-stability guard. `SemDump` at the pin (`java -cp <jar>:tools/oracle/build
SemDump <spec>.tla`, from the spec dir) is the golden source.

### 1. Oracle capture — how SANY projects a LAMBDA op-arg

A LAMBDA is an `OpArgNode` referencing a synthesized `OpDefNode` **named
`LAMBDA`**. `SemDump` projects it (SemDump.java:348) as a single summary line —
**the body is NOT rendered as a child**, and the LAMBDA gets **no `lvl <name>`
row** in the LEVELS section (it is anonymous):

```
oparg LAMBDA op=LAMBDA arity=<nparams> L<bodylevel> <span>
```

Frozen goldens (byte-reproducible from the pin):

| spec | line | arity | level | note |
|---|---|---|---|---|
| `CigaretteSmokers` | `oparg LAMBDA op=LAMBDA arity=1 L1 44.38-44.66` | 1 | **L1** | body reads `smokers` (a var) → state level |
| `BagsTest` | `oparg LAMBDA op=LAMBDA arity=1 L0 186.17-186.34` (×5) | 1 | L0 | body uses only its param → constant |
| `coverage/F` | `oparg LAMBDA op=LAMBDA arity=1 L0 8.31-8.45` | 1 | L0 | `LAMBDA s : s > 1` |
| `coverage/F` | `oparg LAMBDA op=LAMBDA arity=2 L0 8.48-8.78` | **2** | L0 | `LAMBDA odd, b : …` — multi-param, second LAMBDA in the same application |

`CigaretteSmokers` LEVELS confirms no LAMBDA row; its body's arg-level-params
fold into the **enclosing** def: `lvl stopSmoking L2 lp={…,smokers} …` and the
oparg carries `L1`.

### 2. Representation — approach (a) CONFIRMED, with a refinement

The Hoon dump renderer at **`semantic.hoon:4833`** already emits the exact
`oparg LAMBDA op=LAMBDA arity=N …` line for **any** `$OpArg`-shaped `%apply`
(`name.op == '$OpArg'`, `ubound` head = the name, `args` head = a `%lit %num`
arity). So generation only has to produce that shape with **name `LAMBDA`** —
**no new renderer, no new `sem` variant, no new LEVELS row, no mold change.**

Refinement over the plan's "synthetic `LAMBDA` op-def in the context": a LAMBDA
is **anonymous and non-unique** (`coverage/F` has two, `BagsTest` five, all named
`LAMBDA`). Registering a named `LAMBDA` symbol in the shared context would
**collide** across sibling LAMBDAs and could spuriously create a LEVELS row.
Instead **carry the LAMBDA's level data inline on the `$OpArg` node**:

- `sem-apply` (`semantic.hoon:977`) is reused unchanged. `args` head stays the
  arity `%lit %num` (what the renderer reads); **the generated LAMBDA body sem
  rides as the `args` tail element.** The `$OpArg` render arm reads only the head
  and returns `:_ ~` (never recurses into `args`), so the body stays invisible in
  the tree — exactly matching SANY's no-body projection.

### 3. Targets for the code increments

- **R1.3.1.1 (generation).** In `g-arg-list` (`semantic.hoon:1157`), before
  `oparg-of`/`g-x`, detect an `n-lambda` arg node; extract its bound idents
  (params) and body (from the `n-lambda` kids the parser flops in at
  `syntax.hoon:2039`); emit `%apply` with `op=['$OpArg' <kind>]`,
  `ubound=[['LAMBDA' | <lambda-span>]]`, `args=[<arity-lit> <body-sem>]`,
  `at=<lambda-span>`, `lvl=<body level>`. Body generated with the params in
  scope as `%formal-param` symbols. arity = param count (multi-param ⇒ 2+).
- **R1.3.1.2 (level).** Teach `oparg-def`/`oparg-param` (`:2609`/`:2960`) and
  node-eval's `resolve-oparg` (`node-eval.hoon:734…`) the `name=='LAMBDA'`
  convention: not context-resolvable — take the body level + arg-level-params
  from the inline `args`-tail body so they fold into the enclosing def's
  `lc`/`lp`/`nlp` (as `stopSmoking` shows). Leibniz/4272-4273 + arity vs the HO
  slot.
- **Watch:** verify `resolve-oparg` and any other `$OpArg` `args` consumer
  tolerate the 2-element `args` (arity + body); the semantic level readers use
  the head only, but node-eval must be checked in R1.3.1.1.

### 4. Byte-stability guard

`tests/lib/sem` has **73 goldens, none containing LAMBDA** (grep clean), so the
LAMBDA arm must leave every existing sem/level golden byte-identical — the
regression assertion for each increment. New LAMBDA sem goldens are added from
`SemDump` on the closed specs as they land.

## R1.3.1.1 — generation (SHIP-VERIFIED, 2026-08-05)

The higher-order operator-argument path is **`g-opappl`** (`semantic.hoon:1464`),
NOT `g-arg-list` — per argument position `i` it reads `expect = (at-or parg.u.s
i 0)` (the operator's own per-param arity from the `parg` field) and, when
`expect /= 0`, only builds an `$OpArg` if the arg is a bare operator reference
of matching arity (`ref-arity`); anything else → 4270/4271 + `nullODN`. A LAMBDA
took that error path (observed: `apply nullODN` in the arg slot + `D 4270 … in a
position an operator is required` + `D 4271`).

**Fix** (two helpers + one hook, all in the generator core):

- `+lam-arity` (`semantic.hoon`) — bound-ident count of an `n-lambda` (0 for
  non-LAMBDA).
- `+lambda-of` — detects `n-lambda`, extracts the param idents (`skim` the
  `%identifier` leaves) and body (`rear-node`), puts the params in scope with
  `add-params`, and emits the reserved `$OpArg` `%apply`: `op=['$OpArg'
  %user-op]`, `ubound=[['LAMBDA' | span]]`, `args=[[%lit %num <arity> span]]`,
  `lvl=(expr-level body c2)`, `at=<lambda span>`. Anonymous, non-unique → NOT
  registered in the context; the `$OpArg` render arm (`:4833`) reads only the
  arity head, so it prints exactly `oparg LAMBDA op=LAMBDA arity=N …`.
- **Hook in `g-opappl`** at the `expect /= 0` branch (`:1515`), before the
  `ref-arity`/`oparg-of` logic: `=/ la ?:(=(expect (lam-arity i.nl)) (lambda-of
  i.nl c) ~)  ?^ la $(…, out [u.la out])`. (`g-arg-list` also got the hook for
  non-`g-opappl` apply forms — harmless, not the failing path.)

**Verification.** New byte-exact differential `tests/lib/sem/lambda`
(`desk/test-data/sem/lambda/A.tla`: single-param `Apply(LAMBDA y : y = 1)` +
**multi-param** `Apply2(LAMBDA a, b : a = b)`, both constant-level so no level
work needed): `test-sem-lambda` **OK**, all 74 sem goldens `ok=%.y` — no
regression. Emits `oparg LAMBDA op=LAMBDA arity=1 …` and `arity=2 …`
byte-identical to `SemDump`.

**Real-spec confirmation.** The flat tier-2 SANY batch (`test-sany-batch`) now
reports its divergence set as `IllegalOperatorTest:hoon=accept` — **`BagsTest`
dropped out (reject → accept)**, `IllegalOperatorTest` correctly unchanged (its
4271 too-lenient case is R1.3.2). The arm `FAILED` only because the frozen
`SANY_BATCH_DIVERGENCES` still lists `BagsTest` (census flip = R1.3.1.5); no
spurious flips.

**Scope note.** Generation drives the SANY **accept/reject** verdict (what the
tier-2 SANY batch compares), so this one change closes the accept/reject for the
whole LAMBDA bucket, not just the two .1 probes — the census flip is still
deferred to R1.3.1.5. What remains for **R1.3.1.2** is the LEVELS byte-match on
non-constant LAMBDAs: level-check's `$OpArg` arm (`:2688-2698`) rewrites the
node level via `l-resolve 'LAMBDA'` → falls through to level 0, so a state-level
LAMBDA (CigaretteSmokers `arity=1 L1`) still renders `L0` and its arg-level-params
do not fold into the enclosing def. `.2` special-cases `name=='LAMBDA'` to keep
the body level + propagate arg-level-params, and teaches node-eval `resolve-oparg`.

## R1.3.1.2 — level-checking (SHIP-VERIFIED, 2026-08-05)

A LAMBDA is an inline `OpDefNode`, so its level data is exactly what **`+l-def`**
(`semantic.hoon:3604`, the `OpDefNode.levelCheck` port) computes from a
`sem-def`, and `OpArgNode.levelCheck` then **copies** the referenced operator's
`[lvl ok lp lc ac ap all]` (never `nlp`). Reused wholesale:

- **Generation (`+lambda-of`)** now also carries what level-check needs: the
  bound idents ride in `bound` (one `sem-bound`, the param `sbind`s, no range),
  and the generated body rides as the **`args` tail** (`args = [arity-lit
  body]`). Both are invisible to the `$OpArg` render arm (reads only the ubound
  name + arity head), so the `.1` tree goldens are unchanged.
- **Level (`+l-x` `$OpArg` arm, `:2741`)** — a new `nm == 'LAMBDA'` branch
  reconstructs the anonymous `sem-def` (`[%sdef 'LAMBDA' arity | lvl at params
  body '']` from `bound` + the `args` tail), runs `(l-def df e ~)`, and returns
  `s(lvl lvl.ol)` + `[lvl.ol ok.ol lp.ol lc.ol ac.ol ap.ol all.ol ~]` (nlp `~`,
  matching SANY). `l-def` already strips the LAMBDA's own params from `lp`/`lc`/
  `ac`/`ap` (its `pset` machinery), so only outer refs propagate — the enclosing
  def picks them up through the existing higher-order `l-apply-def` path with no
  further change. `l-def`'s `eo` (which would register `'LAMBDA'` in `ops`) is
  discarded, so sibling LAMBDAs (all named `LAMBDA`) never collide.

Node-eval **`resolve-oparg`** already tolerates the shape: it looks `'LAMBDA'`
up in `ops.e`, misses, returns `~` → no crash. Actually *evaluating* a
LAMBDA-parameterized operator (model-checking `BagOfAll(LAMBDA …)`) stays
deferred; no census spec model-checks a LAMBDA.

**Verification.** New `tests/lib/sem/lambdalvl` (`Apply(LAMBDA y : y = x)` over
`VARIABLE x`) pins the state-level case: `oparg LAMBDA … L1`, `apply Apply … L1`,
`Foo L1 lp={x} lc={x<=2}` — byte-identical to `SemDump`. `test-sem-lambdalvl`
**OK**; `test-sem-lambda` (constant L0) **stayed byte-identical** (`l-def` yields
L0 there); all 75 sem goldens `ok=%.y`, no regression. (The R1.3.1.1 "remaining
for R1.3.1.2" paragraph above is now closed by this section.)

**Bug caught in the loop:** first build `nest-fail`ed — I wrote the arm's return
as `:_ ds.ld :- s …` (a `[[s r] ds]` 2-tuple) instead of the arm's `[s r ds]`
3-tuple; fixed with `:*  s(…)  [lres]  ds.ld  ==`.

## R1.3.1.3 — multi-param, multi-LAMBDA, fixtures (SHIP-VERIFIED, 2026-08-05)

**No code change** — the .1 generation + .2 level mechanism already covers every
shape in this bucket; R1.3.1.3 is verification via direct byte-exact goldens.
`coverage/{F,K,L}` are self-contained (`EXTENDS Naturals`, which the sem harness
already resolves), so they go in verbatim (module renamed `F`/`K`/`L` → `A`,
span-preserving — same length):

- **`covf`** = `coverage/F`: two LAMBDAs in **one** application (`Op({…}, LAMBDA
  s : …, LAMBDA odd, b : …)`) — `arity=1` then **`arity=2`** — inside a
  set-comprehension user HO op.
- **`covk`** = `coverage/K`: LAMBDA to a user HO op `Foo(Op(_), S)` from inside a
  parameterized def `Bar(S)`, body `e \in Nat`.
- **`covl`** = `coverage/L`: LAMBDA to `ChooseOne(S, P(_))` (a `CHOOSE` HO op),
  constant body.
- **`lamseq`** (synthetic): `SelectSeq(<<1,2,3>>, LAMBDA e : e = 1)` — the
  **imported** (Sequences StandardModule) HO-op path, which the census's
  `ModuleOverwrites/ModuleOverwrites` and `EWD840/{Error02,Error03,MC02,MC02Sim}`
  all use (`SelectSeq(seq, LAMBDA …)` inside a `LET`/`ENABLED`). SANY resolves
  `SelectSeq` as `UserDefinedOpKind` with the operator param at position 1, so
  `g-opappl`'s `expect = (at-or parg 1 0) = 1` routes the LAMBDA to `lambda-of`.

`test-sem-{covf,covk,covl,lamseq}` all **OK**, all 79 sem goldens `ok=%.y`.
Both HO-op flavors (user-defined `covk`/`covf`/`covl`, imported `lamseq`) are
byte-proven, so the 5 non-coverage specs (same `SelectSeq`+LAMBDA path, only
wrapped in `LET`/`ENABLED` — context-independent for `g-opappl`) are covered;
their accept flip is confirmed corpus-wide at R1.3.1.5.

**Corpus confirmation (subdir SANY batch, `sany-verdict`).** arms 1-3 FAILED with
exactly the LAMBDA specs dropping from the frozen divergence set — proof they now
accept: `coverage/{F,K,L}` (sub-2), `suite/test201` (sub-3), `EWD840/{Error02,
Error03,MC02,MC02Sim}` + `ModuleOverwrites/ModuleOverwrites` (sub-1). Correctly
still divergent: `SingleLaneBridge`, `gh1134/*` (R1.3.3/.4), the `suite/*`
conformance specs (R1.3.4), and **`EWD998/EWD998`** (see R1.3.1.4). (An earlier
`ok=%.y` reading was stale scrollback; the clean re-run is `ok=%.n` with these
three arms failing.)

## R1.3.1.4 — LAMBDA in temporal; INSTANCE decision (SHIP-VERIFIED, 2026-08-05)

**No new code** — LAMBDA in temporal/action context already works; this step is
verification + a scope decision on the two named specs.

- **`suite/test201` (LAMBDA through `INSTANCE … WITH`) — CLOSED, no R1.3.3
  deferral.** The subdir batch shows it flips to accept: the substitution
  expression `A <- LAMBDA y : y^3` reaches the same generation path (a LAMBDA in
  an operator-argument/substitution position), so the `.1`/`.2` mechanism carries
  it. The plan's conditional deferral is therefore resolved as *keep in R1.3.1*.
- **LAMBDA in temporal/action level — verified.** New `tests/lib/sem/lamact`
  (`Next == Apply(LAMBDA y : y = x')`, primed var → action level): SANY renders
  `oparg LAMBDA … L2`, `Next L2 lc={x<=1}`; `test-sem-lamact` **OK** byte-exact,
  no new code (`l-def`/`l-x` compute the level-2 body). `EWD840/{MC02,MC02Sim}`
  (LAMBDA inside `ENABLED`) flipping in the batch is the real-spec witness.
- **`EWD998/EWD998` — residual reject is NOT a LAMBDA gap; deferred.** Dumping its
  closure (EWD998 + Utils) through `analyze-graph` gives **10 `%error` diags, all
  `TLCGetAndSet`** 4270/4271 at lines 188/190/202/204/206 — i.e. a **built-in
  operator (`+`, `\cup`) passed as an operator argument** (`TLCGetAndSet(0, +,
  …)`, `(4, \cup, …)`). The spec's actual LAMBDA arguments (lines 193/198,
  `LAMBDA o,v : Pairwise(o,v,+)` / `… v'[n] …`) raise **no** error — the LAMBDAs
  are handled. The blocker is higher-order **built-in**-operator arguments, which
  `g-opappl` routes only for user/imported ops (`ref-arity`/`oparg-of` are
  ctx-keyed, and a built-in like `+` is not a ctx entry). This is an R1.3.2-class
  (higher-order op-arg) gap, out of R1.3.1 scope; EWD998 stays in the census as a
  documented residual and closes when built-in-op-args are handled.
  - **Known limitation noted:** `+lambda-of` generates the body with `g-x` but
    does not thread the body's diagnostics, so an error *inside* a LAMBDA body
    (e.g. a built-in-op-arg) is currently swallowed — masking, not causing, the
    same gap. Threading body diags belongs with the built-in-op-arg fix (doing it
    alone would make a `Pairwise(o,v,+)`-in-LAMBDA body falsely reject while SANY
    accepts). Tracked with the EWD998 residual.

---

# R1.3.2 — Higher-order operator-argument edges

Sub-plan: `~/FoxyLabs/tla-lus/R1.3.2-plan.md`. Three HO-argument buckets.

## R1.3.2.0 — kickoff (DOCS/ORACLE ONLY, 2026-08-08)

No ship/generator/census change. Captures the SANY goldens and the exact Hoon
reject diagnostics for the three specs, confirms the buckets, freezes the
baseline. Same pattern as R1.3.1.0.

### Oracle + Hoon capture (measured)

**IllegalOperatorTest** (`D(Op(_)) == Op(42)` / `Foo == D(D)`) — Hoon too
lenient. SANY **rejects**:
```
D 4271 ERROR 3.8-3.11  Argument number 1 to operator 'D'
                       should be a 1-parameter operator.
```
Hoon `analyze-graph` errors: **`~`** (accepts — the bug). `D`'s parameter
`Op(_)` is 1-arity, so `D` is a second-order operator; SANY forbids passing it
where a first-order 1-param operator is required. The Hoon HO check in
`+g-opappl` (`semantic.hoon:1464`) compares the argument's **arity** only (both
`D` and the `Op(_)` slot are arity 1). **Fix (R1.3.2.1):** also require the
argument operator to be **first-order** — every entry of its `parg`
(`semantic.hoon:40`) must be 0 — else EC 4271 *"…should be a K-parameter
operator"* (K = the slot's expected arity).

**test30 / test999** (identical but for the module name) — Hoon too strict.
SANY **accepts**. Hoon `analyze-graph` errors (both, at `2 ++ (x+3)`, line 23):
```
D 4004 ERROR 23.17-23.18  Could not find declaration or definition of symbol '++'.
D 4004 ERROR 23.16-23.23  Couldn't resolve infix operator symbol `++'.
```
Only the **infix** operator constant `_++_` fails; the prefix HO constants
`P(_,_)`, `Plus(_,_)`, `PLen(_)` (declared the same way) resolve and apply
fine. **Fix (R1.3.2.2):** link an infix use `a ++ b` to a `CONSTANT _++_`
declaration (infix-operator-symbol resolution for HO constants).

**EWD998/EWD998** (the R1.3.1 residual, re-scoped here) — Hoon too strict. SANY
**accepts**. Hoon: 10× EC 4270/4271 on `TLCGetAndSet(0, +, …)` / `(4, \cup, …)`
— a **built-in** operator as an operator argument; `+oparg-of`/`+ref-arity`
(`semantic.hoon:1178`/`:1450`) are ctx-keyed and miss built-ins. **Fix
(R1.3.2.3):** resolve a built-in operator (arity from `builtins`) in an
operator-argument position so the `$OpArg` is generated.

### Buckets → steps

| bucket | direction | step | specs |
|---|---|---|---|
| deep-4271 (arg operator must be first-order) | add reject | R1.3.2.1 | `IllegalOperatorTest` |
| infix operator constant resolution (`CONSTANT _++_`) | stop rejecting | R1.3.2.2 | `suite/test30`, `suite/test999` |
| built-in operator as an op-arg | stop rejecting | R1.3.2.3 | `EWD998/EWD998` |

Baseline frozen: `divergences.txt` post-R1.3.1 (1 sany + 1 batch + 1 tlc-batch +
23 subdir); `tier2.py --check` byte-reproducible.

## R1.3.2.1 — deep-4271 (SHIP-VERIFIED, 2026-08-08)

`D(D)` was accepted because `g-opappl`'s HO branch checks the argument's arity
only (`D` and the `Op(_)` slot are both arity 1). SANY builds the `OpArgNode`
(the selector passes — `D` IS an arity-1 operator) but its **match** phase
rejects a **second-order** operator (one whose own parameter is an operator).

- **`+ref-first-order`** (`semantic.hoon`, beside `ref-arity`): `(unit ?)` —
  `&` iff every entry of the referenced operator's `parg` is 0 (first-order),
  `~` when the node is not a resolvable op ref.
- **`g-opappl` HO branch** restructured: on a matching-arity operator ref, build
  the `$OpArg` (selector), then — if `ref-first-order` is not `[~ %.y]` — keep
  the oparg in the tree **and** emit the match-phase `e2` (EC 4271, at the
  application span `span-of:ast n`): *"Argument number N to operator 'X' should
  be a K-parameter operator."* The non-matching-arity path (selector fail →
  `nullODN` + `e1` + `e2`) is unchanged.

Faithful to SANY: the `oparg D op=D arity=1` node **stays** in the tree, the sole
diagnostic is the match-phase 4271 at the app span (3.8-3.11), and everything
renders `L-1` (level-check skipped on the generation error). New sem golden
`illegalop` (`D(Op(_))==Op(42)` / `Foo==D(D)`): `test-sem-illegalop` **OK**
byte-exact, all 81 sem goldens `ok=%.y` (the `ho*`/`errarity` HO-arg cases
unaffected — first-order op-args build the oparg exactly as before). `sany-verdict`
now **rejects** `IllegalOperatorTest` (the `e2` `%error`), agreeing with Java;
census flip deferred to R1.3.2.4.

## R1.3.2.2 — infix operator constants (SHIP-VERIFIED, 2026-08-08)

`param-decl` (`syntax.hoon:~3210`) parses an operator-symbol constant as
`n-infixdecl` (`_op_`), `n-prefixdecl` (`op _`), or `n-postfixdecl` (`_ op`) —
NOT `n-identdecl` — but `+decl-syms` (`semantic.hoon:275`) only registered
`n-identdecl` kids, so `CONSTANT _++_` was dropped and `2 ++ 3` failed to
resolve (EC 4004). SANY registers it as a constant **named `++`** (arity 2,
`ConstantDeclKind`), exactly like the prefix HO constant `Plus(_,_)`.

**Fix:** `+decl-syms`'s `n-paramdeclaration` arm now also handles the three
operator-decl kinds. The operator symbol is a childless tok-node carrying the
text in its `image`, read with `+node-text` and `+resolve-syn` (matching what an
infix/prefix/postfix *use* resolves to via `op-of-genop`); it registers
`[%constant <arity> …]` — arity 2 for infix, 1 for prefix/postfix — at the decl
node's span, identical in shape to the `Plus(_,_)` identdecl case (so the level
machinery yields the same `lp`/`alc`).

New sem golden `infixconst` (`CONSTANT _++_, Plus(_,_)` / `Foo == 2 ++ 3` /
`Bar == Plus(2, 3)`): `test-sem-infixconst` **OK** byte-exact — `const ++
arity=2`, `apply ++ opkind=ConstantDeclKind`, `LEVELS … lp={++,Plus}
alc={(++,0)>=0,…}`. All 82 sem goldens `ok=%.y`. `test30`/`test999` (whose only
errors were the two `++` 4004s — R1.3.2.0) now accept; census flip at R1.3.2.4.
Prefix/postfix operator constants are handled by the same arm (no census spec
exercises them; not golden-tested).

HOON: `snag`/`i.ks` on a `?~`-narrowed list nest-fails (`mull-grow`, `have %~`);
use a non-narrowing `(lth (lent ks) n)` guard + `snag` on the plain list.

## R1.3.2.3 — built-in operator as an op-arg (SHIP-VERIFIED, 2026-08-08)

EWD998's `TLCGetAndSet(0, +, …)` / `(4, \cup, …)` rejected (4270/4271) because a
bare operator argument parses to a **Gen*Op wrapper** (`bare-op-node`,
`syntax.hoon:1343`: `%n-geninfixop`/`%n-genprefixop`/`%n-genpostfixop`/
`%n-gennonexpprefixop`) — NOT `%n-generalid` — so `ref-arity`/`oparg-of`/
`ref-first-order` returned `~` before any lookup. SANY renders `oparg + op=+
arity=2` and (synonym-resolved) `\cup` → `oparg \union op=\union arity=2`.

**Fix:** new shared **`+arg-op-info`** resolves the operator an argument node
names — a bare `n-generalid` (existing, with instance prefix) **or** a Gen*Op
wrapper (name via `+op-of-genop`, which synonym-resolves `\cup`→`\union`) — then
looks it up in the **context then `builtins`** (a built-in like `\union` isn't
in the context; `+` is, imported by `EXTENDS Integers`). `ref-arity`/`oparg-of`/
`ref-first-order` are now thin wrappers over it (built-ins have empty `parg` →
first-order, so they pass the R1.3.2.1 check). The `$OpArg` carries the resolved
op's `kind` (`%builtin` for `\union`, `%user-op` for imported `+`), so the
existing `l-x` `$OpArg` level arm resolves it via `l-resolve`.

New sem golden `bltopargs` (`Apply(a, Op(_,_), b) == Op(a,b)` / `Apply(1, +, 2)`
/ `Apply(1, \cup, 2)`): `test-sem-bltopargs` **OK** byte-exact — `oparg + op=+
arity=2`, `oparg \union op=\union arity=2`, `Foo`/`Bar` L0. All 83 sem goldens
`ok=%.y`. **`EWD998/EWD998` now accepts (0 errors)** — the last LAMBDA-bucket
spec, and the R1.3.1 residual, closed. Census flip at R1.3.2.4.

**R1.3.2.4 note:** the .3 built-in-op-arg fix also closed **`suite/test43`**
(`SortSeq(<<…>>, <)` / `(…, \leq)` / `(…, >)` — built-in comparison operators as
`SortSeq`'s operator argument), surfaced when its subdir arm flipped; removed
from `SUB_BATCH_DIVERGENCES` too (23→19, 276/295 agree). All 6 subdir arms +
the flat batch green; `tier2.py --check` byte-reproducible.

## R1.3.3.0 — kickoff (DOCS/ORACLE ONLY, 2026-08-08)

No ship change, no generator change, no `-test`, no census edit. `SemDump` the
INSTANCE bucket at the pin, confirm all four substitution edges map onto the
**existing** `sem-isub`/`$SubstIn`/`l-substin` scaffolding (no new IR shape), and
name the `sem` goldens that must stay byte-identical. Plan:
`~/FoxyLabs/tla-lus/R1.3.3-plan.md`. Same pattern as R1.3.2.0 / R1.3.1.0.

### 1. The 8 specs, regrouped to the four code edges

Reassignments from R1.3.0 §2 hold: `suite/test201` already closed by R1.3.1 (not
a deferral); `suite/test203` added here; `gh1134/SingleUser` is R1.3.4 (`_CONF`),
only `MultiUser` is R1.3.3. The eight: `gh1134/MultiUser`, `suite/{test206,
test216,test219,test219a,test51,test203}`, `examples/SingleLaneBridge/
SingleLaneBridge`.

| edge (increment) | specs | oracle shape |
|---|---|---|
| **.1 operator + param subst** | `test219`, `gh1134/MultiUser` | subst into a **HO instance member** (`I!SortSeq arity=3` with an operator param `Op`) + param subst `b <- n` |
| **.2 `\E`/SUBSET/HO under subst** | `test206`, `test219a` | operator subst as an **oparg** (`sub A5 <- oparg A5/LAMBDA arity=5`), HO instance param (`Inst2(A5(_,_,_,_,_))` → `Inst2!Foo arity=6`), `SUBSET`/`$UnboundedChoose`/`\EE` bodies |
| **.3 temporal under instance** | `test216`, `test51` | named-instance **temporal members** kept at L3 (`J!SpecC` = `[]`/`$SquareAct`/`<>`/`$WF`), constant subst `D <- 42/43` + temporal theorems; temporal operators as **op-args at L3** (`TempTest(oparg ~> arity=2 L3)`, `-+-> L3`, `\cdot L2`) |
| **.4 RECURSIVE under WITH** | `test203`, `SingleLaneBridge` | operator subst of a **RECURSIVE** op (`sub A <- oparg g op=g arity=1`, `g` mutually recursive via member `foo!h`); `RECURSIVE SeqFromSet(_)` + HO op-arg in a `WF_`/`~>` liveness spec |

### 2. Oracle captures (byte goldens, `SemDump A.tla` from the spec's dir at the pin)

All eight are **ACCEPT** (feature gap, not a reject-mismatch — no error text to
match; acceptance + the semantic tree is the golden). Representative fragments:

```
test219:   def I!SortSeq arity=3 local=n L0
             param Op arity=2 L0            (HO operator param)
             substin subs=1 L0
               sub C <- num 4 L0
               in  letin ... apply Op opkind=FormalParamKind   (Op used under subst)

test203:   def foo!h arity=1 local=n L0
             substin subs=2 L0
               sub A <- oparg g op=g arity=1 L0     (OPERATOR subst -> oparg)
               sub b <- apply n opkind=FormalParamKind
               in  apply A opkind=ConstantDeclKind ( apply b opkind=ConstantDeclKind )
           def g arity=1 ... apply foo!h opkind=UserDefinedOpKind   (RECURSIVE via member)

test219a:  def Inst2!Foo arity=6 local=n L0
             substin subs=1 L0
               sub A5 <- oparg A5 op=A5 arity=5 L0   (op subst as oparg, instance-prefixed COp!@!++)

test216:   def Thm2Def ... substin sub D <- num 42 in apply + (apply D ConstantDeclKind) ...
           def J!SpecC arity=0 L3  ... apply [] L3 ( apply $SquareAct L2 )   (temporal member kept L3)
           def Spec arity=0 L3  apply $WF L3

test51:    def TempTest arity=1 L0
             apply TempTest L3 ( oparg ~>   op=~>   arity=2 L3 )
             apply TempTest L3 ( oparg -+-> op=-+-> arity=2 L3 )
             apply TempTest L2 ( oparg \cdot op=\cdot arity=2 L2 )
```

### 3. Edges map onto the existing scaffolding — NO new IR shape

- `sem-isub = [param=@t pkind=symkind expr=(unit sem)]` (`semantic.hoon:1035`).
  `expr` is a `sem`, so it already holds **all four** subst kinds: `num`
  (constant), an `$OpArg`-encoded `%apply` (operator subst — the R1.3.2 `$OpArg`,
  reused), and an `apply` of a formal param (`b <- n`). `$SubstIn`/`$APSubstIn`
  reserved-`%apply` encoding (`:1018`,`:2114`,`:2268`) and `l-substin` level-check
  (`:2943`, raises the body level by the subst exprs') are already in place.
- **Proof the simple case already works:** `sem` goldens `lvlinsth`/`lvlinstm`/
  `lvlinstp` already carry `F <- Op` (operator subst) and pass. The R1.3.3 gaps
  are the *harder* subst positions, not the mold: (a) op subst of a RECURSIVE /
  instance-prefixed op (`.4`/`.2` generation on `unit-instance`/subst-args,
  `:1100`), (b) HO instance params and `SUBSET`/`\E`/`\EE` under the wrapper
  (`.2`), (c) **level preservation** of L2/L3 leaves across `$SubstIn` and
  temporal op-args at L2/L3 (`.3`, in `l-substin` + the R1.3.2 `arg-op-info`
  path, which must not flatten a temporal op-arg's level). Confirmed:
  **approach = extend generation + `l-substin`, no new `$%` member** (the
  zuse-408 mold-loop reason the reserved-`%apply` encoding exists still binds).

### 4. Byte-stability guard — sem goldens that must NOT move

The 11 existing INSTANCE/subst goldens (`desk/test-data/sem/`): `inst`, `instun`,
`instimp`, `instlcl`, `instrex`, `apsubst`, `lvlinst`, `lvlinstc`, `lvlinsth`,
`lvlinstm`, `lvlinstp`; plus the oparg goldens R1.3.3 shares the `$OpArg` path
with (`bltopargs`, `hoargm`, `ho273`, `hoparam`, `hoparm`, `horemap`, `houn`).
Each R1.3.3.x adds new focused goldens; these stay byte-identical.

### 5. Census baseline — FROZEN

`python3 tools/tier2.py --check` = `tier-2 differential integrity: OK`; the 8
R1.3.3 specs sit among the 276/295 subdir divergences (before R1.3.3.1).

## R1.3.3.1 — parametrized + nested instance edges (SHIP-VERIFIED, 2026-08-08)

Measured the real Hoon rejection (probe sem cases driven through `dump-sem`) for
the two `.1` targets; each exposed a **distinct** gap, both in `semantic.hoon`:

- **Gap A — parametrized-instance parameters.** `Inst(n) == INSTANCE B WITH c <- n,
  …`: SANY binds `n` in scope for the WITH expressions and **prepends** it to every
  imported def (`Inst!Op arity=1 param n`, `Inst!Two arity=2 param n,x`). Hoon lost
  `n` entirely → `4200 Unknown operator: n` on `c <- n`, and imported defs had the
  wrong arity. Fix: `+unit-instance` now returns the instance's own params
  (`lhs-params` of the module-def LHS); `+g-instance` adds them to the ctx used for
  the WITH exprs and **prepends** them (as `spar`) to each imported def with
  `arity += lent`; `+inst-syms` bumps the imported member arity/`parg`/`weights`
  by the param count so a reference like `SingleUserP!Init` resolves at arity 1.
- **Gap B — nested instance member application.** `M!Op(1)` where `M` is an instance
  inside the instanced module: `+g-opappl` used only the **last** identifier leaf
  (`Op`) as the operator name, dropping the `M!` prefix → `4200 Unknown operator:
  Op`. (The 0-ary path `+g-genid` already qualified via `+genid-prefix`.) Fix:
  `+g-opappl` builds the qualified name the same way. Small, but it is what
  `StateMachine!Init(UserIDs)` in `SingleUser` needs.
- **Level-constraint follow-up.** After Gap A, the MODULE line's `lc` gained a
  spurious `n<=2`: `+l-instance`'s `getSubLCSet` mapping added the substitution
  expression's level params, and a parametrized instance substitutes its own bound
  formal param `n`. Bound params are never module-level declarations, so SANY does
  not surface them there — `lcc`'s subst-mapping loop now skips `%formal-param`
  keys. (The def line's `lc` was already correct via `l-substin`.)

**Result:** `gh1134/MultiUser` **accepts** (`sany-verdict` %reject→%accept) — the
census target closes. The tier2-sub run then flagged **two more** now-agreeing
specs the same fixes closed early (they dropped out of the divergence list):
- **`gh1134/SingleUser`** — Gap B (`StateMachine!Init(UserIDs)`, a nested instance
  member through `EXTENDS Base`). Its R1.3.0 `_CONF`/R1.3.4 classification was
  **wrong**: the cause is the nested-member gap, identical to MultiUser's.
- **`suite/test203`** — Gap A (`foo(n) == INSTANCE test203a WITH A <- g, b <- n`
  is a **parametrized** instance; `n` in scope + prepended). An **R1.3.3.4** target
  (RECURSIVE-under-WITH) closed early by the parametrized-parameter fix; the
  RECURSIVE operator subst `A <- g` was already carried by the existing `$OpArg`
  substitution path.

Census: `SUB_BATCH_DIVERGENCES` 19→16 (**279/295 agree**). Two focused sem goldens
land byte-exact (single imported def each, to sidestep the orthogonal instance-def
**hash-order** divergence below): `instparm` (Gap A: `Inst(n)` prepends `n`,
`c <- n` resolves) and `instnest` (Gap B: `M!Op(1)`). All 85 sem goldens `ok=%.y`
(no regression from the shared `g-opappl`/`inst-syms` paths); the tier2-sub arms'
only diffs were these three specs dropping out (no false regression — nothing
newly diverged); `tier2.py --check` byte-reproducible.

**`suite/test219` — NOT closed, and NOT an INSTANCE-substitution gap.** With the
`.1` fix it still `sany-verdict` %reject, and `analyze-graph` returns `~` with
**0 semantic errors** — i.e. it fails at **parse/resolve**, not level/semantic. The
spec is dominated by labels (`lab(x,y,z) :: …`) and `!`-subexpression selectors
(`!:!++`, `!>>`, `!<<`, `!2!1`) — the unit-3 subexpression-navigation residue.
Reassigned to **R1.3.5** (`parse-errors` / `!`-nav); its census reason updated.

**Known orthogonal divergence (NOT introduced here, surfaced by probing).** SANY's
`ModuleNode.getOpDefs()` returns **instance-imported** defs in Java hashtable order
(`Alpha,Beta,Gamma` → `Beta,Gamma,Alpha`), not source/decl order; the root module's
own defs stay source-ordered. This only affects a **multi-def-instance sem golden**
(none existed before; the two new goldens are single-def by design) and never the
accept/reject verdict the census tests — so it does not block MultiUser. Left as a
documented `semantic-graph` residual (same class as the C1.7 interning-order
approved difference), to be settled in R1.3.6 if a multi-def-instance golden is
wanted (canonicalize both sides in `SemDump`/`dump-sem`).

## R1.3.3.2 — tuple-pattern quantifier binders (SHIP-VERIFIED, 2026-08-08)

Measured the two nominal `.2` targets (`test206`, `test219a`) and found the plan's
scope was **misdiagnosed**:

- **"\E/SUBSET/higher-order under substitution" already works.** A `psubsub` probe
  (`I == INSTANCE B WITH v <- x`, B = `Op == \E s \in SUBSET {1,2} : v \in s`) gives
  **0 Hoon errors** — `+g-instance` generates each imported body with the full
  generator, so quantifiers/`SUBSET` thread through `$SubstIn` unchanged. No gap.
- **The real gap is tuple-pattern binders** `<<y, z>> \in S`. Measured: `test206`
  fails at **parse** (`parse-fail %.y`, 0 sem errors — the `COp!@!++` subexpression
  selectors, R1.3.5); `test219a` **parses** with **3 sem errors** — `Unknown
  operator: y`, `Unknown operator: z` (the tuple binder `<<y, z>> \in {<<3,4>>}` on
  line 10) and `Unknown operator: Op!lab` (a label ref, R1.3.5).

**Fix.** `+qbound-vars` (bound-var collection for `\A`/`\E`, and via `+fcn-level`
for function definitions) only gathered bare identifier leaves; a tuple binder
parses to `%n-identifiertuple` (a node), so its idents were dropped. New
`+tuple-idents` pulls each identifier out (recursing for nested tuples); `+qbound-vars`
descends into `%n-identifiertuple` and binds each individually — exactly SANY, which
renders `bound y`/`bound z` (no tuple marker in the SemDump projection). One helper,
one arm; the fix covers both quantifier and function-def binders.

**Result.** New sem golden `tupbind` (`\E <<y,z>> \in S` + `\A x, <<y,z>> \in S`)
byte-exact; all 86 sem goldens `ok=%.y`. The tuple-binder fix **closed three census
specs — none of them the plan's nominal .2 targets**, all closed early because a
tuple binder was their *only* remaining gap:
- **`examples/SingleLaneBridge/SingleLaneBridge`** — `\A <<r,l>> \in CarsRight \X
  CarsLeft`. An **R1.3.3.4** target (RECURSIVE + HO op-arg); those were already
  carried by the R1.3.1 `$OpArg`/RECURSIVE paths, leaving the tuple binder.
- **`suite/etest15`**, **`suite/test10`** — tuple binders in **function**
  definitions (`[<<k,l>> \in Int \X Int |-> ..]`), R1.3.4 targets.

Census `SUB_BATCH_DIVERGENCES` 16→13 (**282/295 agree**); tier2-sub arms' only diffs
were these three dropping out (no false regression). `test219a` went 3→1 error (last
= `Op!lab` label ref) and `test206` stays parse-blocked — the two nominal .2 targets
are both **gated on R1.3.5** (`!`-nav), not on substitution; their census reasons
updated. `tier2.py --check` byte-reproducible.

## R1.3.3.3 — operator-symbol parameter in a definition (SHIP-VERIFIED, 2026-08-08)

Same shape as `.2`: the plan's nominal scope was misdiagnosed. Measured the two
`.3` targets:

- **"Temporal under instance" already works.** `test51` reaches `Foo1 == TempTest(-+->)`
  at L3; the temporal/user op-args resolve via the R1.3.2.3 `arg-op-info` path.
- **The real gap is an operator-symbol PARAMETER in a definition** `TempTest(_+_)`.
  Measured: `test51` **parses** with **3 sem errors** `4204 The operator TempTest
  requires 0 arguments` — Hoon computed TempTest's arity as **0**. `test216` fails at
  **parse** (`!`-subexpression selectors `Thm1!:`/`Thm1!<<`/`Thm1b!2!1` → R1.3.5).

**Root cause.** `+param-decl` parses a def's operator-symbol param `_+_` to the SAME
`n-infixdecl`/`n-prefixdecl`/`n-postfixdecl` node as a `CONSTANT _++_` (R1.3.2.2), but
`+count-params` (def arity) counted only `n-identdecl`/`n-paramdecl`, and `+lhs-params`
(param binding + `parg`) extracted only `n-identdecl` — so the operator param was
invisible: arity 0, `+` unbound.

**Fix.** New shared `+opsym-param` (operator name + arity from a fixity decl: infix 2,
prefix/postfix 1) now backs three callers — `+decl-syms` (refactored to it, no behaviour
change), `+count-params` (now counts the three fixity kinds), `+lhs-params` (binds e.g.
`+` at arity 2, so the body `1 + 2` resolves and `add-params` seeds the formal at the
right arity). **Second fix (the `used` flag):** the rendered param level `L0`/`L-1`
comes from `used.p = (subtree-names-has body <name>)`, which matched only `%identifier`
leaves; an operator in the body (`1 + 2`) is a **childless tok-node** whose text is in
the `image`. `+subtree-names-has` now resolves each node's image / leaf text through
`+resolve-syn`, so an operator-symbol param counts as used and renders `L0` like SANY.
(All 87 sem goldens pass — the broadened match is `resolve-syn`-guarded, no false hits.)

**Result.** New sem golden `infixparam` (`TempTest(_+_) == 1 + 2` / `Foo == TempTest(\cup)`:
`param + arity=2`, body `apply + FormalParamKind`, `oparg \union`) byte-exact. Census
**closed two** — again neither the plan's nominal target:
- **`suite/test51`** — `TempTest(_+_)` (the `.3` target, via the op-param + the already-
  working temporal op-args).
- **`suite/test42`** — `Foo(a, _--_) == a -- 0` (an operator-symbol param mixed with a
  normal one), an **R1.3.4** target closed early.

Census `SUB_BATCH_DIVERGENCES` 13→11 (**284/295 agree**); tier2-sub diffs were only these
two dropping out (no false regression). The nominal target `test216` stays parse-blocked
(`!`-nav → R1.3.5); its census reason updated. `tier2.py --check` byte-reproducible.

NOTE (golden gotcha): an `EXTENDS Integers` in the `infixparam` fixture makes `+` a
**multiply-defined** symbol (param vs the imported operator) — SANY then REJECTs (EC
4201). The fixture omits EXTENDS; the body `1 + 2` uses the param `+`, `\cup` is built-in.

## R1.3.3.4 — RECURSIVE-under-WITH + higher-order instance param (CLOSE-OUT, 2026-08-08)

**No code change.** Both named targets were already closed early:
- **`suite/test203`** (`foo(n) == INSTANCE test203a WITH A <- g, b <- n` over
  `RECURSIVE g(_)`) — closed by **R1.3.3.1** (parametrized-instance parameter `n`).
  The RECURSIVE operator subst `A <- g` was already carried by the existing `$OpArg`
  substitution path; the only gap was the parametrized param.
- **`examples/SingleLaneBridge/SingleLaneBridge`** (`RECURSIVE SeqFromSet(_)` + HO
  op-arg in a `WF_`/`~>` liveness spec) — closed by **R1.3.3.2** (tuple binder
  `\A <<r,l>> \in CarsRight \X CarsLeft`).

Both were only **accept**-verified through tier2-sub, so this step locks the two named
mechanisms with **byte-exact sem goldens**:
- **`recinst`** — RECURSIVE op through WITH + member access: `RECURSIVE g(_)` /
  `foo(n) == INSTANCE B WITH F <- g, c <- n` / `g(n) == .. foo(n)!Use` (B: `Use == F(c)`).
  Oracle+Hoon agree byte-exact: `def foo!Use arity=1 param n substin subs=2 [sub F <-
  oparg g op=g arity=1] [sub c <- n]`, and `def g` recursive.
- **`hoinst`** — higher-order instance parameter: `Inst(F(_,_)) == INSTANCE B`
  (B: `Use == F(1,2)`). `def Inst!Use arity=1 param F arity=2 substin subs=1
  [sub F <- oparg F op=F arity=2]` — the HO instance param `F(_,_)` is captured at
  arity 2 by `+lhs-params`/`+us-arity` (R1.3.3.1's `spar` path) and prepended by
  `+g-instance`; the implicit substitution of B's same-named `F(_,_)` renders the
  `$OpArg`.

All 89 sem goldens `ok=%.y`; no `semantic.hoon` change ⇒ no ship regression beyond the
two new goldens. No census change (both targets absent since .1/.2; 284/295 agree).
`tier2.py --check` byte-reproducible.

### R1.3.3 pattern summary (across .1–.4)

Every step's *planned* substitution/temporal mechanism was **measured to already work**;
the real gaps were orthogonal front-end features that the target specs happened to also
need: parametrized/nested instances (.1), tuple binders (.2), operator-symbol params (.3).
Cumulatively R1.3.3 closed **8** census specs — `gh1134/MultiUser`, `gh1134/SingleUser`,
`suite/test203`, `examples/SingleLaneBridge/SingleLaneBridge`, `suite/etest15`,
`suite/test10`, `suite/test51`, `suite/test42` — taking the subdir batch from 19→11
divergences (276→284 of 295 agree). The **remaining** nominal R1.3.3 targets
(`test206`, `test216`, `test219`, `test219a`) all converge on the **R1.3.5** feature:
labels + `!`-subexpression selectors (`Thm1!:`, `Op!lab`, `COp!@!++`, `!<<`/`!2!1`).

## R1.3.4 — semantic/level conformance edges (SHIP-VERIFIED, 2026-08-09)

Per-spec triage of the 7 conformance divergences remaining after R1.3.1-.3. Measured
each; the actual cause differed from its R1.3.0 `_CONF` label every time. **Five
closed, two reassigned to R1.3.5 (`test214`, `test52`):**

- **`etest16`** (too lenient → EC 4262): `[a |-> 1, b |-> 2, a |-> 1]` / `[a:{1},
  b:{2}, a:{1}]` — duplicate record field. `+g-rcd` now threads a `seen` set and
  emits `4262 Non-unique fields in constructor.` at the duplicate field-name span.
- **`test16` / `test7` / `test9`** (too strict): tuple binders `<<i,j>> \in S` in
  **subset-of** (`{<<y>> \in S : ..}`), **set-of-all** (`{e : <<k,l>> \in S}`), and
  **CHOOSE** (`CHOOSE <<i,j>> \in S : ..`). R1.3.3.2 fixed only the quantifier path
  (`+qbound-vars`); these use `+idents-before-colon` (g-choose/g-subsetof) — now
  descends into `%n-identifiertuple` too. (set-of-all already used qbound-vars.)
- **`test52`** — NOT closed, reassigned to R1.3.5. Its `BoxTest(-._) == -(x = 0)`
  is a **prefix operator parameter**: the decl `-._` lexes the `-.` token (param
  bound as `-.`), but a bare prefix `-` in an expression stays `-`, so the use fails
  (EC 4004). SANY canonicalizes prefix `-` to `-.`. A `+prefix-op` canonicalization
  (prefix `-`→`-.` in the `%n-prefixexpr` generation/level arms + `+subtree-names-
  has`) closed test52 — **but broke `tests/lib/arith`** (every negative-number case:
  `-7 \div 2`, `(-7) % 3`, Expt neg, intervals): the port deliberately names unary
  minus **`-`** (registered under Naturals) for the evaluator, while SANY uses `-.`.
  Renaming the graph node to `-.` breaks the stdops registry lookup. Reverted;
  reconciling the two names is cross-cutting (generator ↔ `stdops` registry) →
  **R1.3.5**. (This is the `-`/`-.` split the C1.2 unary-minus notes already flag.)
- **`test23`** (too strict, EC 4200 `Sum`): **LOCAL operator definitions** were
  never registered. `+finish-def` prepends the LOCAL leaf as a **direct kid** of the
  N_OperatorDefinition (ahead of the identlhs), so `+def-signature`/`+g-def`/`+def-
  level` — which took `i.kids` as the LHS — saw the LOCAL leaf, bailed, and dropped
  the def. New `+def-lhs` returns the first *node* kid; the `local` flag now reads
  `has-local` over the definition's own kids (the LOCAL leaf isn't inside identlhs).
- **`test214`** — NOT closed. Rejecting `HIDE bar, TRUE` (EC 4357) requires USE/HIDE
  proof-fact validation, which needs theorem-name scoping (a THEOREM name like `bar`
  is not in the module context today) + proof-step handling. That is the same
  **BY/QED proof-step** infrastructure R1.3.5 owns → **reassigned to R1.3.5**.

Census `SUB_BATCH_DIVERGENCES` 11→6 (**289/295 agree**); the 6 remaining
(`test52`/`test206`/`test214`/`test216`/`test219`/`test219a`) are ALL R1.3.5 —
`!`-subexpression selectors / labels (three), proof HIDE facts (`test214`), and the
unary-minus `-`/`-.` naming (`test52`). New sem goldens `rcddup`/`tupsub`/`localdef`.

**recinst golden WITHDRAWN.** The R1.3.3.4 `recinst` mechanism-lock golden began
failing during R1.3.4 triage on **byte-identical committed code** (semantic.hoon is
diff-empty between R1.3.3.4 and R1.3.3.5): its `lvl foo!Use ml=[2]` became `ml=[3]`
+ a spurious module `lc`. This is a pre-existing **non-determinism in the RECURSIVE-
operator-substituted-through-WITH level path** (a recursive fixpoint interacting with
`$SubstIn` level mapping), not an R1.3.4 change — proven by reproducing the failure
with all R1.3.4 edits stashed. The golden is removed rather than kept flaky; the
RECURSIVE-through-WITH *acceptance* stays covered by `test203` (census). Tracked as a
`semantic-graph`/`level-constraints` residual for R1.3.6/unit-4 follow-up. `hoinst`
(the deterministic HO-instance-param lock) is retained.

## R1.3.5 — ledger-residue closure (front-end)

Decomposition plan `~/FoxyLabs/tla-lus/R1.3.5-plan.md` (.0–.8). R1.3.5 is a *mix*:
6 census specs R1.3.3/.4 measured and reassigned here (real accept/reject tests)
plus five ledger rows tier-2 never surfaces (`semantic-graph`, `level-constraints`,
`parse-errors`, `tlc-output-ec`, `tlc-constants`).

### R1.3.5.0 — kickoff (SHIP-VERIFIED oracle measurement, DOCS/ORACLE ONLY, 2026-08-09)

No desk deploy, no ship `-test`, no `semantic.hoon` change (R1.3.x.0 pattern). Ran
`SemDump` at the pin on all 6 census specs (from the `suite/` dir, deps co-located)
+ raw `tla2sany.SANY` on the reject; scoped the two engine-side ledger rows against
`src/tlc2/output/EC.java`/`MP.java` and `src/util/TLAConstants.java`. **Census frozen
unchanged** (6 `SUB_BATCH_DIVERGENCES`, 289/295 agree).

**Baseline census (all `suite/`, java=accept unless noted):** `test52` (hoon=reject),
`test206` (hoon=reject), `test214` (hoon=accept — java REJECTS), `test216`
(hoon=reject), `test219` (hoon=reject), `test219a` (hoon=reject).

**Measured, per unit:**

- **`test52` → R1.3.5.1. Wider than the `-`/`-.` naming.** `SemDump` ACCEPT (230
  lines, 0 diags). SANY canonicalizes the prefix param and its definition to **`-.`**
  (`param -. arity=1 L0 9.9-9.11`; `apply -. opkind=FormalParamKind`; `def -. arity=1
  … 13.1-13.26`) — the `-`(port)/`-.`(SANY) split the C1.2 notes flag. **But the spec
  also passes eleven built-in prefix/postfix/special operators as op-args**, each
  rendered `oparg NAME op=NAME arity=1`: `[]`,`<>` (10.17/11.17, L3), `ENABLED`
  (44.17, L1), `UNCHANGED` (47.19, L2), `'` (48.15, L2), `-.`,`^+`,`^*`,`^#` (23–26,
  L0), `SUBSET`,`UNION`,`DOMAIN` (27–29, L0). R1.3.2.3's `+arg-op-info` resolved
  **infix** built-ins (`+`,`\cup`); .1 must extend it (or verify coverage) to prefix
  / postfix / special-form (`ENABLED`/`UNCHANGED`/`'`/`SUBSET`/`UNION`/`DOMAIN`) built-in
  op-args **and** reconcile `-`/`-.` without breaking the `stdops` registry (the R1.3.4
  revert cause: `tests/lib/arith` names unary minus `-`). Scope note added to plan .1.

- **`test206`,`test216`,`test219` → R1.3.5.2 (parse); `test219a` → R1.3.5.2/.3 (sem).**
  `SemDump` ACCEPT for all four in Java (206=1383 ln, 216=1169, 219=8149, 219a=740) —
  the port rejects at PARSE (206/216/219) or sem (219a `Op!lab`). Two sub-features:
  - **Label DEFINITIONS** render as tree nodes `label <name> L<lvl> <span>` wrapping the
    labeled expression: `id(a,b,…) :: expr`, `id :: expr`. E.g. `label lab L0
    11.23-15.65`, `label label2 L0 15.49-15.64`, `label lab3 L0 35.17-35.28`.
  - **Subexpression-selector REFERENCES** resolve by **inlining the selected
    subexpression as an `OpApplNode`**. `Bar == Op(Foo, 9)!lab(1,2,3)` →
    `def Bar arity=0 L0 40.1-40.28 / apply LAMBDA opkind=UserDefinedOpKind /
    oparg Foo op=Foo arity=1 / num 9 / num 1 / num 2 / num 3` — the label's params
    (x,y,z) and enclosing op's args (Foo,9) become the application. Full selector
    vocabulary observed across 206/216/219/219a: `!name`, `!123` (`!2!1`), `!<<`,
    `!>>`, `!:`, `!@` (`SOp1a!@`, `COp!@!++`), `!(args)` (`!(3)`, `!(2,2)`), `!lab(args)`
    (`!lab(1,2,3)`), `!op-symbol` (`!++`, `!:!++`), and chains
    (`Op(Foo,9)!lab(1,2,3)!:!++(9,4)`, `Inst!Bar4(1)!lab(2)!<<`), incl. **through
    INSTANCE** (`Inst!Foo`, `J!ThmC!1`, `Foo!Thm2!:`, `I!Thm3!2!2`) and on **theorems**
    (`Thm1!:`, `Thm1b!2!1`). Note test219a's `!`-nav is mostly commented; its live
    forms are `Op(Foo,9)!lab(1,2,3)` + `COp!@!++`. .2 = parse the selector/label grammar
    + `***Parse Error***` bytes (advances `parse-errors`); .3 = sem resolution/inlining
    (retire `Unknown operator: Op!lab`). Existing `c-labels-003.gold` shows only the
    "Removing label … would change expression parsing" reject exists today.

- **`test214` → R1.3.5.4. Oracle = exactly ONE error.** `SemDump` renders the graph
  (`thmdef bar`/`theorem name=bar`/`thmdef xx`/`assumeprove`/`prove`, all L-1) AND a
  single `DIAGS` line `D 4357 ERROR 10.11-10.14 The only expression allowed as a fact
  in a HIDE is ` — confirmed by raw `SANY` (`*** Errors: 1`, "…the name of a theorem,
  assumption, or step."). Only the `TRUE` in `HIDE bar, TRUE` (10.11-10.14) is flagged;
  the spec's three other `(*ERROR*)` annotations (`bar!1` L7, `USE TRUE` + `xx!1` L13)
  are **NOT** reported by the semantic phase. So .4 needs: THEOREM-name scoping
  (`bar`/`xx` reachable as facts), USE/HIDE statement handling, proof steps
  (`<1>2.`/`<1>3. QED`), and the HIDE-fact restriction reject EC 4357 at the bad-fact
  span. (`bar!1`/`xx!1` are `!`-nav on theorems — overlaps .2/.3, but are not the
  flagged error.)

- **`level-constraints` full differential + `recinst` non-determinism → R1.3.5.5.**
  Unchanged from the R1.3.4 note: the RECURSIVE-op-substituted-through-`WITH` level
  fixpoint is non-deterministic (`ml=[2]`↔`[3]` on byte-identical committed
  `semantic.hoon`); the `recinst` golden was withdrawn. .5 also owns `$APSubstIn`
  implicit-subst rendering, instance-def hash-order, wider `SemDump`/LEVELS projection,
  and the full re-level differential over the 92 `sem` goldens.

- **`parse-errors` residual → R1.3.5.6.** Manifest: ~100 `expecting` sites on
  unexercised productions + typed `at` spans; corpus is `gen-parse-err-tests` (34
  golds). .6 extends it (shares .2's new selector grammar).

- **`tlc-output-ec` + `tlc-constants` → R1.3.5.7.** `EC.java` = **256** codes;
  `MP.java` gates `-tool` tagging on `TLCGlobals.tool && tool` (6+ sites). Port today:
  `lib/diagnostics.hoon` is **ordering-only** (75 ln, `code-family` rank contract); the
  actual EC codes are inline in `semantic.hoon`. .7 = complete the EC/MP taxonomy +
  `-tool` tag format in `lib/diagnostics`, and port `util.TLAConstants` shared literals.

**Ordering confirmed:** `.1`,`.4`,`.5`,`.7` independent; `.3` needs `.2`; `.6` follows
`.2`. `.1` is the smallest self-contained closer. Ledger rows stay **partial** (flip is
the .8 close-out). Oracle scratch dumps in the session scratchpad `r1350/*.sem.txt`;
regenerable via `java -cp $JAR:tools/oracle/build SemDump <spec>.tla` from the `suite/` dir.

### R1.3.5.1 — prefix/postfix op-args + unary-minus `-`/`-.` (SHIP-VERIFIED, 2026-08-09)

**Measured the real gap first** (committed `dump-sem` probe vs `SemDump` on a minimal
`EXTENDS TLC`-free repro): the ONLY divergence was the prefix `-` USE. `BoxTest(-._) ==
-(x=0)` raised `D 4004 @ 4.17 "Couldn't resolve prefix operator symbol `-'"`. Everything
else the R1.3.5.0 census predicted as a gap **already worked** via R1.3.2.3: the prefix
param `-._` (named `-.`), the postfix def `^+`, and every built-in/user op-arg —
`oparg SUBSET`/`-.`/`^+`/`[]` all rendered correctly. So the scope collapsed to the
`-`/`-.` naming plus its registry reconciliation; no `+arg-op-info` extension needed.

**Root cause: generator and eval-registry were consistently *mis*-named `-`/Naturals.**
SANY names the prefix operator `-.` (its distinct prefix-form; infix `-` is subtraction);
the pin declares `-. a == 0 - a` in `Integers`. The port named it `-` in BOTH the graph
and the `stdops` registry key `[Naturals '-' 1]`, so they matched each other but not the
pin — canonicalizing only the graph (the R1.3.4 attempt) broke `tests/lib/arith`.

**Fix (surgical, both sides to the pin-exact name):**
- `semantic.hoon`: new `+canon-prefix-op` (prefix `-`→`-.`, else identity), applied at
  the `%n-prefixexpr` **generation** arm (`g-x`), the `%n-prefixexpr` **expr-level** arm,
  and in **`+subtree-names-has`**. KEY PARSE FACT (dumped the Hoon tree to find it): a
  prefix `-` parses as an **`n-infixop`** (image `-`) child under `n-prefixexpr` — NOT an
  `n-prefixop` — so it is only distinguishable from infix `-` by the *parent* kind; the
  `subtree-names-has` canon keys on `%n-prefixexpr` (via `op-of-genop` on kid 0), then
  recurses only the operand, so a `-._` parameter now reads as used → param level L0 and
  `alp={(-.,0,x)}` match.
- `stdops.hoon`: registry key `[Naturals '-' 1]` → `[Integers '-.' 1]` (the pin's own
  declaration; `binding-of` resolves the canonicalized `-.` to Integers → override).
- `gen-stdops-tests.py`: the unary-minus special-case in the anti-drift guard is now
  dead — `[Integers '-.' 1]` is directly a pin `required` operator (inventory row 28);
  comment updated (defensive fallback, no key uses it).
- `tests/lib/stdops.hoon`: `test-binding-unary-minus` probed `-`/1 → now `-.`/1
  (`Expr == -(1)`, EXTENDS Integers) = %override.

**Verified:** real **test52 ACCEPTS** (`sany-verdict` = %accept, committed probe). New
byte-exact golden `desk/test-data/sem/prefixop` (module A: prefix param `-._`, prefix/
postfix user defs, built-in `SUBSET`/`[]` + user `-.`/`^+` op-args) matches SemDump tree
+ LEVELS; `gen-sem-tests` 91→92, byte-reproducible (generate-twice-diff clean). Functional
subset `-test {stdops,arith,sem,node-eval,value}` = **ok=%.y** (no regression from the
generator or registry change). tier2-sub arms 3/4/6 OK; **sub-5 fails as the expected
test52 census-flip signal** (flip deferred to the R1.3.5.8 close-out per plan). Ledger
`semantic-graph`/`level-constraints` stay partial (flip at .8). No git commit yet.

**GOTCHAS this session:** (1) a double-quoted tape golden interpolates `{…}` → syntax
error; single-quote the cord (`{` is literal there). (2) The 2-min bash cap can't span a
full ship suite (tier2-sub arms ~300s each); use a `run_in_background` until-loop waiter.
(3) `tmux capture-pane -S -900` missed FAILED lines buried under huge tier2-sub output —
widen the scrollback or grep the whole buffer.

### R1.3.5.2 — `!`-subexpression selectors, parse layer (SHIP-VERIFIED, 2026-08-09)

**Scope collapsed after measurement.** R1.3.5.0 assumed the `!`-nav grammar was
missing; it is ~95% present — `general-id-full` (syntax.hoon) already builds the
idprefix-element chain (`ident!`, `ident(args)!`, `(args)!`, structops `!<<`/`!>>`/
`!:`/`!123`, final `!@`/operator/identifier) and `label-expr` produces `n-label` with
the `labelDoesNotChangeParse` check. Probed the CURRENT parser on the three specs:
- **`test216` already parses** — its divergence is *semantic* (belongs in R1.3.5.3),
  not parse; the R1.3.5.0 census reason ("parse") was imprecise.
- **`test206`/`test219`** failed on exactly two constructs, found by AstDump-ing the
  chains: (1) a trailing **`!(args)`** (`COp(1,2)!(3)`) = an `N_OpArgs` directly under
  `N_GeneralId`; (2) a mid-chain **operator-symbol selector with args** `!++(9,10)!`.

**Fix (three additions to `general-id-full`, all CST-byte-exact vs AstDump):**
1. trailing `!(args)` final segment → `[n-idprefix, n-opargs]` general-id.
2. mid-chain op-symbol element `!op!` / `!op(args)!` via new `+op-sym-tok`/`+op-sel-node`/
   `+op-sel-mid` (the last is a trailing-bang lookahead that distinguishes a mid-chain
   selector from a *final* operator like `!++(4,5)`, which stays an `n-opapplication`).
3. mid-chain **`@`** now emits `n-structop` (was `identifier`) to match SANY — a
   pre-existing CST inexactness surfaced while byte-checking `COp!@!++`.
KEY CST FACT (AstDump): a trailing `!ident(args)` / `!op(args)` is `n-opapplication(
general-id, opargs)` — `ident-expr` already wraps it — whereas a bang **immediately**
followed by `(args)` is a general-id child. So no "final trailing opargs" change was
needed (an early wrong hypothesis, corrected by dumping the enclosing node).

**Verified:** committed probe — `parse:syntax` on **test206/test216/test219 all parse
(`%parses`)**. New hand-written byte-exact CST test `tests/lib/syntax/subexpr-ext.hoon`
(4 arms: `!(args)`-final, `!op(args)!`-mid, `@`-structop, `!op(args)`-final-opappl) vs
AstDump — these forms are ABSENT from the pinned upstream corpus
(`subexpressions.txt` has only `op(a,b)!<<!>>!3!(x,y)!:!@`). No regression: full syntax
dir (all 30 corpus shards + subexpr-ext), sem (92 goldens), lexer = `ok=%.y`.

**Census unchanged (correct):** .2 is parse-only; test206/216/219 still reject at
*semantic* (label refs unresolved → R1.3.5.3), so they stay divergent and the tier2-sub
arms keep matching the census. Only test52 (R1.3.5.1) remains the expected sub-5 flip.
Ledger `parse-errors` advanced (selector forms now parse byte-exact). No git commit yet.

**GOTCHAS:** (1) `capture-pane` showed STALE identical `-test` output (same µs timings) —
always C-c + C-a C-k + clear-history and read a FRESH run. (2) misread an AstDump excerpt
by cutting the sed window above the enclosing `n-opapplication`; always dump from the
`def` line to see the wrapper. (3) split a multi-form byte-golden into per-def arms so a
mismatch isolates to one tiny def.

### R1.3.5.3.0 — kickoff (oracle measurement, DOCS/ORACLE ONLY, 2026-08-09)

No code, no desk deploy, no ship `-test`; census frozen (R1.3.x.0 pattern). Read SANY's
`Selector`/`genIdToSelector`/`selectorToNode` and `SemDump`ed one resolved case per
resolution mode. Scratch goldens in `r1350/{nav,nav2}.sem.txt` + `r1350/test206.sem.txt`,
regenerable via `java -cp $JAR:tools/oracle/build SemDump <spec>.tla`.

**Selector interface (the .3.2 increment boundary).** `genIdToSelector`
(`Generator.java:503`) walks `n-idprefix` elements + the final into a `Selector` =
parallel `ops`/`opNames`/`args`/`STN` arrays; each element's kind code (`:331-336`,
`:409-470`):

    NameSel=-1   identifier / operator-symbol / proof-step  (`!Foo`, `!lab`, `!++`)
    NullSel=-2   a `(...)` selector                          (`!(args)`)
    GGSel =-3    `>>`      LLSel=-4  `<<`      ColonSel=-5  `:`      AtSel=-6  `@`
    N>=0         a positional selector `!N`  (an N_StructOp whose child is a number)

`selectorToNode` (`:619-2041`, 1422 lines) is a two-phase state machine over that list:
**FollowingLabels** (peel leading `NameSel`s that match a `LabelNode` of the current
definition) → **FindingSubExpr** (navigate the operator's body per the codes above).

**Resolution mode → SemDump shape (MEASURED — the per-increment acceptance targets):**

| mode | selector | SemDump render | port reuse |
|---|---|---|---|
| label DEFINITION | `lab :: e` | `label <name> L<lvl> <span>` tree node | NEW node (see mold below) |
| label REFERENCE | `Op(Foo,9)!lab(1,2,3)` | `apply LAMBDA opkind=UserDefinedOpKind` + `oparg`/args | `$OpArg`/LAMBDA (R1.3.1/.2) |
| body `!:` / parametric `!(args)` | `Foo(5)!:`, `Def13!(42)!>>` | `apply LAMBDA opkind=UserDefinedOpKind` + args | LAMBDA |
| structural nav `!N`/`!<<`/`!>>` | `Def10!2`, `Def4!<<!<<` | `apply $Nop opkind=BuiltInKind` wrapping the **selected subexpr with its ORIGINAL spans** | `$Nop` builtin |
| argument selector `!@` | `OOp2(SOp1a!@,2,2)` | `oparg LAMBDA op=LAMBDA arity=N` | `$OpArg`/`resolve-oparg` |
| through-INSTANCE | `Inst!Foo(..)`, `Foo!Thm2!:` | `substin subs=N` wrapping the inlined node | `$SubstIn`/`l-substin` (R1.3.3) |

**KEY FEASIBILITY FINDING:** every inlining OUTPUT shape is already expressible with
existing port machinery — `$Nop` (navigation), `LAMBDA`/`$OpArg` (parametric/label/`!@`),
`$SubstIn` (through-instance). So .3 builds the **selector walk + resolver** (the missing
`selectorToNode`) and **one new node** (the label); it does NOT need new IR value shapes.
`$Nop` wraps a pure navigation selection and PRESERVES the source subexpression's spans
(the render points back to the original location, e.g. `A == Def10!2` → `apply $Nop /
num 2 L0 3.15-3.15`).

**LABEL MOLD DECISION (freeze):** encode the label with the **reserved-`%apply` trick**,
`%apply ['$Label' %builtin] lvl span [[name | span] ~] ~ [body]` — a `$Label`-special
render arm emits `label <name> L<lvl> <span>` (exactly as `$OpArg` renders `oparg`). This
reuses the existing recursive `%apply` union and **dodges the zuse-408 recursive-mold
loop** a new `+$ label` variant would trigger; it is the proven `$OpArg`/`$SubstIn`
pattern. (`.3.1` may revisit only if the label needs a field `%apply` can't carry.)

**Goldens to preserve:** all **92** `tests/lib/sem` goldens byte-identical (none contain
labels). **12 carry `substin`** (R1.3.3 INSTANCE subst) — `.3.5`'s through-INSTANCE
selector work extends the `$SubstIn` path and MUST leave those 12 unchanged (per-def
byte-diff after each `.3.5` edit).

**Census baseline (frozen, unchanged in .0):** `SUB_BATCH_DIVERGENCES` carries
`suite/test206`, `test216`, `test219`, `test219a` (all `hoon=reject`: they parse after
R1.3.5.2, reject at semantic) + the R1.3.5.1 `test52` deferral. `.3` flips the four
`!`-nav specs at `.3.6`.

**Increment map (from the modes above):** .3.1 label generation (`label` nodes appear) →
.3.2 selector infra + label-ref resolution (`FollowingLabels`) → .3.3 structural nav
(`$Nop`, `FindingSubExpr`) → .3.4 `!@`/op-symbol → .3.5 through-INSTANCE + on-theorem
(`substin`) → .3.6 levels + census flip. Plan `~/FoxyLabs/tla-lus/R1.3.5.3-plan.md`.

### R1.3.5.3.1 — label generation (SHIP-VERIFIED, build 570, 2026-08-09)

Labels were PARSED (`n-label`) but never generated — `g-x` had no `%n-label` arm, so a
labeled body silently dropped to `[~ ~]`. Now generated via the kickoff's reserved-`%apply`
`$Label` encoding (NO new recursive `+$` variant → dodges zuse-408):
- **`+g-label`** (semantic.hoon, by `builtin-apply`): from `n-label` = `[target :: body]`,
  emits `[%apply ['$Label' %builtin] (expr-level n) span [[name | span] ~] ~ [body-sem]]`;
  `+label-name` reads the label name off the target (a bare general-id `lab ::` or an
  application head `lab(x) ::`). `g-x` `%n-label` arm dispatches to it.
- **`expr-level` `%n-label` arm**: level = the labeled body's level (level-transparent),
  matching `label lab L0` where the body is L0.
- **`render-sem` `$Label` arm** (by the `$OpArg`/`$NewSymb` special-cases): emits
  `label <name> L<lvl> <span>` + the body child at `+(d)` — byte-identical to SANY's
  LabelNode projection. The `$Label` apply is otherwise level-transparent, so `l-x`
  traverses its single body arg with no change (LEVELS match).

Labels appear inside quantifier/CHOOSE/def-body positions (the body IS a label, or a
quantifier body is a label). NO resolution of label REFERENCES yet — `Op!lab` still
rejects (that is R1.3.5.3.2). VERIFIED: new byte-exact golden `desk/test-data/sem/label`
(`Op(p) == \A x \in {1,2} : lab(x) :: x + p` + `Simple == lab2 :: TRUE`) matches SemDump
tree + LEVELS; `gen-sem-tests` 92→93, byte-reproducible (regen diff = ONLY the new case,
so the 92 existing goldens are untouched). `-test {sem,node-eval,value,stdops,arith}` =
`ok=%.y` (no regression from the shared g-x/expr-level/render edits). Census unchanged
(the four `!`-nav specs still reject at semantic — label refs are .3.2). No git commit yet.
