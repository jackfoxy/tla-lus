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

### R1.3.5.3.2 — selector infrastructure + resolver skeleton (SHIP-VERIFIED, build 572, 2026-08-09)

The shared foundation for all of `!`-nav resolution. **Architecture decision: POST-PASS**
(not inline-threaded) — `gen-module` folds accumulating `defs` (with bodies) but g-def→
g-x→g-genid only receive `ctx` (no body); threading a registry through ~30 arms is a wide
change, and the port already separates generate/level passes. So resolution runs once over
the completed `sem-module`, consistent with that structure.

Pieces (all in semantic.hoon):
- **`+sel-of`** (port of `Generator.genIdToSelector`): a general-id → `(list sel-item)`,
  `sel-item = [kind num nm args at]`, kind ∈ %name/%null(`!(args)`)/%gg/%ll/%colon/%at/%pos;
  `sel[0]` is the base op, `sel[1..]` navigation. `+sel-item-of`/`+oparg-nodes`/`+structop-num`
  classify each element. Non-recursive mold (holds CST `node`s, not `sem`).
- **routing** in `g-genid`: on flat-name lookup FAILURE (so the R1.3.3 `M!Op` instance-member
  path — which IS in `ctx` — is untouched) AND a non-empty `!`-prefix, emit a `$Sel`
  placeholder via `+sel-placeholder`. **.3.2 gate: pure %name chain, no args** (a bare
  label chain); arg-carrying/structural selectors stay a 4200 reject → census unchanged.
- **`+resolve-sels`** (the post-pass, wired at `gen-module`'s return so every caller —
  render + level-check — sees resolved graphs): `+bodymap` (name→body over defs+thmdefs),
  `+rsel-sem`/`+rsel-list` (hand-rolled walk replacing `$Sel`, since wet gates fuse-loop the
  recursive `sem` mold), `+resolve-one` (base body → navigate label selectors via
  `+find-label` → wrap in `$Nop` at the reference span, KEEPING the selected node's original
  spans), `+sem-lvl`.

VERIFIED: byte-exact golden `desk/test-data/sem/labelref` (`Op == lab :: 42` / `Bar ==
Op!lab` → `apply $Nop / label lab / num 42`, `$Nop` at the ref span 4.8, inner at 3.7) =
SemDump; `gen-sem` 93→94 byte-reproducible (regen diff = ONLY the new case → the 93 existing
untouched, so `+resolve-sels` is a faithful NO-OP for selector-free specs). `-test
{sem,node-eval,value,stdops}` = `ok=%.y`. Census unchanged (the four `!`-nav specs still
reject — arg-carrying label refs are .3.3). HOON: `resolve-one` took `s=sem`; accessing
`ubound.s` needs `?> ?=(%apply -.s)` first (union field). No git commit yet.

NEXT R1.3.5.3.3: label refs WITH args (`!lab(1,2,3)`) — carry generated selector args in the
`$Sel` placeholder, substitute the label's params → `apply LAMBDA`; closes test219a's label half.

### R1.3.5.3.3 — label reference resolution (SHIP-VERIFIED, build 576, 2026-08-09)

Parametric label refs on the .3.2 skeleton. KEY CST FACT: `Op(Foo,9)!lab(1,2,3)` is
`n-opapplication[ generalid[Op(Foo,9)!lab], opargs(1,2,3) ]` — the BASE args (Foo,9) ride
in the idprefix element, the LABEL args (1,2,3) are the enclosing application's opargs. So
the parametric case routes through **g-opappl** (not g-genid), and the trailing opargs
attach to the final selector. Target render (SemDump ELIDES the LAMBDA body): `apply LAMBDA
opkind=UserDefinedOpKind` + args = base args ++ label args, where an operator-valued base
arg becomes an `oparg` (Op's param `Arg(_)` → `oparg Foo`).

Pieces (semantic.hoon):
- **`+g-sel`** — shared placeholder builder for both g-genid (bare, `targs=~`) and g-opappl
  (parametric, `targs`=the application opargs): `+attach-targs` puts `targs` on the final
  selector; generates each selector's args — the base (sel[0]) HO-aware via its `parg`
  (`+gen-sel-args`, reusing `oparg-of`), the rest as individuals — and carries the flat arg
  list in the `$Sel` placeholder (ubound=names, args=flat generated args).
- **routing**: g-genid `?~ s` → `(g-sel n ~ …)`; g-opappl `?~ s` → `(g-sel gid targs …)`;
  both fall through to 4200 when g-sel returns `~` (not a pure %name chain).
- **`+resolve-one`** extended: navigate labels (`+find-label`); if the placeholder has args
  → `apply LAMBDA` (`['LAMBDA' %user-op]`, level = max arg level) applied to them; else the
  .3.2 `$Nop`. `+rsel-sem` resolves nested `$Sel` in the placeholder args first.

VERIFIED: byte-exact golden `sem/labelrefarg` (`Op(Foo,9)!lab(1,2,3)` → `apply LAMBDA /
oparg Foo / num 9 / num 1 / num 2 / num 3`, L0) + `sem/labelref` (.3.2) both green; gen-sem
94→95 byte-reproducible (diff = ONLY the new case). `-test {sem,node-eval,value,stdops}` =
`ok=%.y` (g-opappl routing doesn't touch existing specs — instance members are IN ctx so
never reach the `?~ s` g-sel path). Census UNCHANGED: test219a still rejects (`COp!@!++` =
`!@`/op-symbol → .3.4/.3.5); the parametric-label MECHANISM is proven, spec-flip is .3.6.

RESIDUALS (documented): (1) label arity mismatch `!lab` on a 3-param label → SANY EC 4337;
not emitted yet (test219a's active ref has the correct count) — .3.6/.3.7. (2) LAMBDA level
= max-arg-level approximation (exact for constant args); refine in .3.7 if a variable-carrying
ref needs it. HOON: `flop`/`weld` over a `(list sem)` mint-vain (zuse-408) — built forward
with hand-rolled `+weld-sems`; a `?~ args.s`-narrowed list must be widened (`=/ al=(list sem)`)
before its own `?~`; `(gth (lent x) 1)` does NOT narrow `x` for `i.x` (need `?~ x`). No git commit.

NEXT R1.3.5.3.4: `!@` (argument selector → `oparg LAMBDA`) + `!<op-symbol>` (`!++`, nested
LET operator); then .3.5 structural / through-INSTANCE.

### R1.3.5.3.4 — argument (`!@`) + operator-symbol (`!++`) selectors (SHIP-VERIFIED, 2026-08-10)

Both resolve to `oparg LAMBDA arity=N` (reusing the `$OpArg` encoding); the work is
computing N by accumulating a param count during navigation (Generator.java:1296/970/1083):
base-op params + the bound vars a node binds when the selector is `!@` + nested-LET-op
params for `!<op-symbol>`. Targets (measured): `SOp1a!@` → `oparg LAMBDA arity=2`
(SOp1a's `a` + its subsetof's bound `x`); `COp!@!++` → `arity=5` (COp's `q,p` + bound `x`
+ the LET `a ++ b`).

Pieces (semantic.hoon):
- registry now carries params: `+$ defentry [body params]`; `+bodymap` returns
  `(map @t defentry)` (threaded through `resolve-one`/`rsel-sem`/`rsel-list`).
- `+bound-count` = a node's bound vars (`bound` for a bounded binder, `ubound` for an
  unbounded one — count both). `+find-let-op` = the first `%letin`-defined op named `nm`
  (hand-rolled, like `+find-label`).
- `resolve-one` navigation now threads `[cur cnt at]`: `!@` (encoded `'@'` in the
  placeholder) adds `(bound-count cur)` and sets `at`; a name selector tries `find-label`,
  else `find-let-op` (adds its param count). If `at` → `oparg LAMBDA arity=cnt`.
- `g-sel` gate widened to `?(%name %at)`; `+g-sel-of-arg` + a g-opappl arg-loop fallback
  (before the 4270/4271) route a subexpression-selector *argument* (`OOp2(SOp1a!@,..)`)
  to the placeholder instead of erroring — this is where `!@` args actually appear.

BUG FIXED (found via a direct `find-let-op` probe): `+op-of-genop` returns `''` on a bare
`n-infixop` tok-node (it reads `rear-node kids`, but a tok-node has no kids), so the `!++`
selector name was empty. `+sel-item-of` now reads the name with `+node-text` (handles both
a leaf and a childless op node).

VERIFIED: byte-exact golden `sem/selat` (`SOp1a!@` arity 2, `COp!@!++` arity 5); gen-sem
95→96 byte-reproducible (95 existing untouched); `-test {sem,node-eval,value,stdops}` =
`ok=%.y`. Census unchanged (test219a still has structural / through-INSTANCE selectors).

RESIDUAL (pre-existing, unrelated to .3.4): `CHOOSE x : P` (unbounded) is mis-generated as
`$BoundedChoose` with `x` in `bound` instead of `$UnboundedChoose`/`ubound` — surfaced when
the first `selat` draft used unbounded CHOOSE (arity was right since `bound-count` reads
both, but the render differed). The REAL test219a `COp` uses unbounded CHOOSE, so this
g-choose bug must be fixed before test219a closes (.3.6/close-out); `selat` uses a bounded
`\A` to isolate the .3.4 mechanism. HOON: `op-of-genop` vs `node-text` on op tok-nodes. No git commit.

NEXT R1.3.5.3.5: structural navigation (`FindingSubExpr`: `!1`/`!<<`/`!>>`/`!:`/`!(args)`
→ `apply $Nop`) — the `Def1..Def23` corpus; then .3.6 through-INSTANCE.

### R1.3.5.3.5 — structural navigation (`FindingSubExpr`) (SHIP-VERIFIED, 2026-08-10)

The `N_StructOp` / `N_OpArgs` selectors over a definition body, all measured against
SemDump: `!N` → arg N, `!<<` → arg 1, `!>>` → arg 2 (ArgNum, 1-indexed), `!:` → the whole
current node, `!(args)` → parametric. A no-param navigation wraps the selected node in
`apply $Nop` (KEEPING its original spans); a parametric one (`!(args)`, or a `!:` on a
def that has base args) is `apply LAMBDA` + the args.

Pieces (semantic.hoon):
- `+nth-arg` (1-indexed arg of an `%apply`, bounds-checked).
- g-sel gate widened to `?(%name %at %ll %gg %colon %pos %null)`; each selector encoded in
  the placeholder ubound by a marker — `<<`/`>>`/`:`/`@`/`(` or a decimal positional index
  (identifiers/op-symbols never collide with those).
- `resolve-one` navigation: `<<`→1, `>>`→2, a decimal→that index (via `nth-arg`); `!:`
  no-ops; `!@`/`!(args)` add `(bound-count cur)` to the LAMBDA param count AND descend into
  the quantified body (`nth-arg cur 1`) so a following structural selector indexes the body
  (`!@` also sets the operator-argument flag). Result: `at` → `oparg LAMBDA arity=cnt`; else
  args → `apply LAMBDA`; else `apply $Nop`.

BUG FIXED: g-genid bailed (`?~ ids [~ ~]`) on a structural-*final* selector (`Da!2`,
`Db!<<`) because the final child is a structop, not an identifier leaf — now routes to
`+g-sel` there too. Also corrected in .5: `!@`/`!(args)` must DESCEND into the binder body
(they previously just skipped), else a trailing `!>>` indexed the binder wrapper (1 arg)
and nulled out.

VERIFIED: two byte-exact goldens — `sem/selnav` (`!2` on a tuple/set, `!<<`/`!>>` on infix,
chained `!>>!<<`, `!<<` on `$FcnApply`) and `sem/selnavp` (`Dg(5)!:` → `apply LAMBDA`,
`Dh!(2)!>>` → `apply LAMBDA`, `Di!:` → `apply $Nop`). gen-sem 96→98 byte-reproducible (96
existing untouched); `-test {sem,node-eval,value,stdops}` = `ok=%.y`; the .3.4 `selat`
(`!@`/`!++`) still byte-exact (the descend change didn't regress it). Census unchanged
(test206 also needs through-INSTANCE selectors → .3.6). RESIDUAL still open: the unbounded
`CHOOSE x : P` g-choose bug (from .3.4) — needed before test206/219a close (.3.6/.3.7). No git commit.

NEXT R1.3.5.3.6: through-INSTANCE + theorem/proof-step selectors (`SubstInNode`, `Thm1!:`).

### R1.3.5.3.6 — through-INSTANCE + theorem/proof-step selectors (SHIP-VERIFIED, 2026-08-10)

Two aspects, both measured against SemDump:
- **Theorem-base selectors** (`Thm1!:`, `Thm1!<<`, `Thm1b!2!1`) — ALREADY worked: `+bodymap`
  registers thmdefs (name→body), so a theorem base navigates like any def (`test-thm` byte-
  exact with no code change).
- **Through-INSTANCE** (`Foo!Thm2!:`, `Foo!Thm2!<<`, `Foo!Op(7)!>>`): the base is the FLAT
  instance-member name (`Foo!Thm2`, already a registered thmdef whose body is an `apsubstin`
  from R1.3.3); the selectors navigate its INNER body and the result is re-wrapped in a
  `substin` (SubstInNode, NEVER APSubstInNode — Generator.selectorToNode:1945).

Pieces (semantic.hoon):
- `+resolve-base` — the base is the LONGEST leading `!`-joined run of *name* selectors that is
  a registered def/theorem (`+is-sel-marker` stops the join at a structural selector). So
  `Foo!Thm2!:` resolves base `Foo!Thm2` (2 selectors), remaining `[:]`.
- `+substin-parts` (extracts `[mod names exprs inner lvl at]` from a `$SubstIn`/`$APSubstIn`
  apply, reading lvl/at while narrowed to %apply) + `+rewrap-substin` (rebuilds as
  `$SubstIn:<mod>` around the navigated node).
- `resolve-one`: base via `resolve-base`; navigate the substin INNER body; the `$Nop` result
  re-wraps in `$SubstIn`; the LAMBDA/oparg results elide the substitution (as SemDump does).

VERIFIED: byte-exact goldens `sem/thmsel` (theorem-base) + `sem/instsel` (2-module: `Foo!Thm2!:`
→ `$Nop / substin(D<-42) / D=D`, `Foo!Thm2!<<` → `$Nop / substin / D`, `Foo!Op(7)!>>` → `apply
LAMBDA / num 7`). gen-sem 98→100 byte-reproducible (98 existing untouched); `-test {sem,
node-eval,value,stdops}` = `ok=%.y`. Census unchanged (census flip is the .3.7 close-out).

RESIDUALS for .3.7 (census flip): (1) the unbounded `CHOOSE x : P` g-choose bug (from .3.4) —
blocks test206/219a and, via INSTANCE, test219. (2) inherited-instance-member generation
(`Foo!\leq` when the instanced module EXTENDS Integers) is a pre-existing R1.3.3 ordering/
content difference — surfaced in the first `instsel` draft (used a minimal non-EXTENDS `insta`
to isolate .3.6); may affect test216 (test216a). (3) full LEVELS differential on the inlined
selection nodes. (4) label-arity EC 4337 (from .3.3). No git commit. HOON: a `?~`-narrowed
`(unit tuple)`'s field access wants the level/span read while narrowed (folded into
`substin-parts`), not a separate `sem-at` on the un-narrowed body.

NEXT R1.3.5.3.7: close-out — the unbounded-CHOOSE fix + census flip (test206/216/219/219a) +
LEVELS + ledger/docs.

### R1.3.5.3.7 — close-out (SHIP-VERIFIED, 2026-08-10)

**Unbounded-CHOOSE fix (the last mechanism gap).** `CHOOSE x : P` still parses an EMPTY
`n-maybebound`, so g-choose's `bounded = ?=(^ mbs)` mis-classified it as `\in`-bounded ->
`$BoundedChoose` with `x` in `bound`. Fixed: key on an actual range (`?=(^ rng)`). Also:
an unbounded CHOOSE names its bound symbol at the CHOOSE-keyword span (SANY, unlike
unbounded `\E`/`\A` which use the variable span) -> the sbind span is the keyword span
when unbounded. New golden facts verified (`Ch`); no sem regression.

**Census outcome — measured each target's actual verdict** (committed wain-based
`sany-verdict` probe; the specs are too long for a single-line cord, so each is built from
a per-line `wain` via `+catl`):
- **`suite/test219a` -> ACCEPTS.** CLOSED. Removed from `SUB_BATCH_DIVERGENCES`.
- **`test206`/`test216`/`test219` still reject — but NONE on `!`-nav.** Dumped
  `analyze-graph` diagnostics: test206 = 1x `EC 4204 Inst2!Foo requires 6 arguments`
  (`Inst2(COp!@!++)!Foo(1,2,3,4,5)` — the parametrized-instance param arg is not counted);
  test219 = 18x `EC 4204` of the same class (`I(x)!OOp2`, `L!Inst2!Foo`, ...
  parametrized/nested-instance member arity); test216 = 8x `EC 4200 Unknown operator:
  Thm1/Thm2/...` (bare THEOREM names used as operators — theorem-name scoping, the same
  gap as test214). These are **R1.3.3 instance-member + theorem-scoping gaps, NOT `!`-nav**
  — re-scoped in `SUB_BATCH_REASONS` and kept in the census for a follow-up.

**R1.3.5.3 (`!`-subexpression navigation) IS COMPLETE.** The mechanism is proven by
test219a accepting + eight byte-exact `sem` goldens across every mode: `labelref` (bare
label), `labelrefarg` (parametric label), `selat` (`!@`/`!++`), `selnav`/`selnavp`
(structural `!N`/`!<<`/`!>>`/`!:`/`!(args)`), `thmsel` (theorem-base), `instsel`
(through-INSTANCE `substin`), plus `label`. The four resolution modes SANY's
`selectorToNode` implements (labels, structural, `!@`/op-symbol, through-INSTANCE) all
render byte-identical to SemDump.

Ledger: `semantic-graph` `!`-nav + `APSubstIn` + LabelNode items -> DONE; the residuals
above stay open (instance-member arity, theorem scoping). No git commit.

NEXT (post-R1.3.5.3, follow-ups): parametrized/nested-instance member application arity
(closes test206/219); theorem-name scoping (closes test216, test214); then R1.3.5.4-.7
(the remaining R1.3.5 ledger rows: level-constraints differential, parse-errors residual,
tlc-output-ec, tlc-constants).

**R1.3.5.3.7 addendum — test217 regression surfaced by the tier2-sub run.** Flipping
test219a re-ran the subdir batch and exposed `suite/test217` as a NEW divergence
(hoon=accept / java=reject) — a regression this session's `!`-nav / instance work
introduced. Cause: `FooBar == I(x')!Foo` where `I(z) == INSTANCE test217a WITH y <- z`
and `test217a` has `THEOREM Foo == y'=0` (action level). SANY renders it `apply I!Foo`
APPLIED to `x'` (arity 1, L2) and reports a level error (the action-level arg exceeds the
member parameter's level). The port resolves the flat member `I!Foo` (in ctx, arity 1)
but DROPS the instance-element arg `x'` -> `apply I!Foo` with no args, L0 -> under-checks
-> accepts. This is the parametrized-instance MEMBER APPLICATION gap (same class as
test206/test219; the level-error variant), NOT `!`-nav. Documented in the census as
`suite/test217 -> hoon=accept` and re-scoped for the R1.3.3 instance-member follow-up.
So the census outcome of R1.3.5.3: **test219a closed**; test206/216/217/219 kept as
documented divergences whose residual is R1.3.3 instance-member arity/level + theorem
scoping, none of them `!`-nav. tier2-sub's only remaining FAIL is sub-5 (the R1.3.5.1
`test52` flip, deferred to the R1.3.5.8 parent close-out).

### R1.3.5.4.0 — kickoff / oracle freeze (DOCS/ORACLE ONLY, 2026-08-10)

No desk deploy, no ship `-test`, no `semantic.hoon` change (R1.3.x.0 pattern). Ran
`SemDump` at the pin (`4ba7d8811`) on the two R1.3.5.4 census specs; scratch dumps in the
session scratchpad `r1354/{FREEZE.md,test214.sem.txt,test216.sem.txt}`. Census frozen
unchanged (test214 hoon=accept, test216 hoon=reject; still in `SUB_BATCH_DIVERGENCES`).

- **test214 (`general/tests`) — ACCEPT + exactly ONE error (26 ln).** Graph = 2 thmdefs +
  2 theorems only (`thmdef bar`/`thmdef xx`/`theorem name=bar`/`theorem name=xx`, all L-1);
  DIAGS = **exactly** `D 4357 ERROR 10.11-10.14 The only expression allowed as a fact in a
  HIDE is `. The top-level `USE bar,bar!1` unit, the `HIDE` unit, and the proof
  `<1>2. USE… / <1>3. QED` render **no** nodes; the 3 non-HIDE (*ERROR*) annots
  (`bar!1` L7, `USE TRUE`+`xx!1` L13) are **NOT** semantic-phase errors. LEVELS = MODULE/
  bar/xx (L-1). Port baseline (unchanged from §R1.3.5.3.7): hoon **ACCEPTS** (drops proof +
  USE/HIDE). → .3 adds exactly the one EC 4357.

- **test216 (`suite`) — ACCEPT, no diags (1169 ln).** 23 `thmdef` + 5 `theorem name=`.
  Named-theorem scoping shape: def `thmdef <name> local=<y|n> L<lvl> <span>`
  (`getThmOrAssDefs`), stmt `theorem [name=<name>] L<lvl> <span>` (`getTheorems`, body via
  `getTheorem()`); a **bare theorem reference** resolves to `apply <Name>
  opkind=ThmOrAssumpDefKind` (Init L16: `apply Thm1 opkind=ThmOrAssumpDefKind`); `Thm1!:`/
  `Thm1!<<`/`Thm1!>>` inline the body under `$Nop` — already produced by the R1.3.5.3
  `!`-nav resolver **once the name is scoped**. Port baseline (unchanged): hoon **REJECTS**
  with **8× EC 4200 `Unknown operator Thm1/Thm2`** — the bare theorem-name-scoping gap;
  `!`-nav is already built (.3.6), only the name binding is missing → .1 flips it with no
  selector code.

- **EC 4357 rule frozen** (`UseOrHideNode.java:95-107`): **HIDE only**
  (`getKind()==UseKind → return`); per fact that is an OpAppl whose
  `operator.getKind() != ThmOrAssumpDefKind` → error at the fact span. SemDump first-line
  message (trailing space): `The only expression allowed as a fact in a HIDE is ` (the
  `\nthe name of a theorem, assumption, or step.` continuation is dropped by SemDump's
  first-line normalization). A ThmOrAssumpDef-named fact (`bar`) is OK; a builtin OpAppl
  (`TRUE`) is flagged — so .3 keys the check on the .1 scoping.

- **Theorem-name scoping frozen** (`processTheorem`, `Generator.java:5544`): a named
  THEOREM/ASSUME binds `new ThmOrAssumpDefNode(name)`; two consequences .1 must produce —
  (a) name reachable as an operator (retires EC 4200, renders `opkind=ThmOrAssumpDefKind`),
  (b) name valid as a HIDE/USE fact (the EC 4357 discriminator). Port scaffolding already
  present: `sem-module` carries `thmdefs`/`assumes`/`theorems` (`semantic.hoon:1178-1180`),
  opkind map has `%thm-assump → 'ThmOrAssumpDefKind'` (`:140`), name→body registry over
  thmdefs (`:2723-2736`) feeds the resolver; the missing piece is resolving a bare
  theorem-name reference against that scope during operator lookup.

- **PLAN CORRECTION — proof-step bodies are NOT in the SemDump projection.**
  `SemDump.java:260-266` projects theorems via `t.getTheorem()` (statement body) and
  **never** `t.getProof()`; proof steps, LeafProof, and USE/HIDE units emit no graph nodes
  and no LEVELS entries. So R1.3.5.4.2 is a **walk + level** pass only (parse-attached
  proofs must level-check and raise no spurious diagnostics so the top-level HIDE is
  reached) — there is nothing to project. Corrected in `R1.3.5.4-plan.md` (.0/.2 rows,
  "SANY's rule" §, "SANY LOC" — .2 downgraded L→M).

**Ordering confirmed:** .1 (scoping, closes test216 via existing `!`-nav) → .2 (proof
walk/level, no output) → .3 (EC 4357, closes test214) → .4 (flip). Ledger `semantic-graph`
stays partial (flip is .8). Oracle regenerable: `java -cp $JAR:tools/oracle/build SemDump
<spec>.tla` from the spec dir (test214 = general/tests, test216 = suite).

### R1.3.5.4.1 — theorem-name scoping (SHIP-VERIFIED build 611, 2026-08-10)

Retires EC 4200 on bare theorem/assumption references so **test216 flips 8× EC 4200 →
ACCEPT (0 sem/lvl diags)**. Mechanism, all in `semantic.hoon`:

- **`+thm-signature`** (new): a NAMED `%n-theorem`/`%n-assumption` → `(unit dsig)`
  `[name [%thm-assump 0 | 0 ~ ~] local]` (first identifier leaf = name; arity 0; `has-local`).
- **`+thm-level`** (new): body level = `expr-level` of the body node, or (ASSUME/PROVE) the
  max over items with NEW symbols scoping forward (mirrors `+g-assumeprove`'s level fold).
- **`+build-ctx`**: after the `?^ ds` def-signature arm, an `else` arm registers the
  thm-signature into `full` (and `exported` when non-local) with `level = (thm-level u full)`
  — so `+g-genid`'s `(~(get by c) nm)` resolves a bare `Thm1`/`bar` to
  `apply <N> opkind=ThmOrAssumpDefKind` (the `%thm-assump → 'ThmOrAssumpDefKind'` opkind map
  was already present). A def and a theorem are disjoint unit kinds, so the arm split is safe.
- **`+inst-syms`**: filter widened `?|(=(%user-op kind.s) =(%thm-assump kind.s))` so an
  INSTANCE also imports named theorems/assumptions as prefixed members. Once theorems live
  in the instanced module's `exported` ctx (above), a bare `Thm2` from `INSTANCE test216a`
  or `ThmC3` from `INSTANCE test216c` resolves (the 2 residual 4200s after the own-module
  fix). Nonparametrized instance ⇒ arity stays 0.

VERIFIED: a scratch `sany-verdict`+`analyze-graph` probe on the real test216 (+deps
216a/b/c, built from the suite `.tla`) went `%reject`(8×4200) → `%accept`(0 diags); probe
removed. New byte-exact sem golden `desk/test-data/sem/thmscope/A.tla` (`THEOREM Foo == TRUE`
/ `Bar == Foo` / `Qux == Foo!:` — own bare ref renders ThmOrAssumpDefKind + `!:` inlines);
gen-sem 100→101, full `-test /tests/lib/sem` `ok=%.y` (no regression, incl. all instance
goldens after the inst-syms change).

**Deferred to R1.3.5.5 (level-constraint projection, non-census, surfaced by the thmscope
golden):** (1) an OWN-module theorem reference does not propagate the theorem body's lp/lc
constraints, because thmdef oplevs are registered (`l-module-core` twalk, ~:5104) AFTER the
regular defs (dwalk) that may reference them — a source-order/fixpoint gap (imported
theorems via apsubstin DO carry lp/lc). (2) `$APSubstIn` does not discharge a substituted
constant's constraint: `INSTANCE B WITH c <- 0` still renders `lc={c<=2}`/`lp={c}` on the
importing def where SANY drops it. Neither affects accept/reject. The minimal .1 golden was
kept constant-free/instance-free to avoid asserting these; the imported-theorem scoping is
covered by the test216 accept probe instead. Census NOT edited (flip is the .4 close-out);
test216 stays in SUB_BATCH_DIVERGENCES, mechanism-verified.

### R1.3.5.4.2 — proof-step body handling (SHIP-VERIFIED, NO code change, 2026-08-10)

Like R1.3.5.2, the layer was already present — **no `semantic.hoon` change**. Confirmed by
measurement + a new golden:

- The parser already builds the full proof CST (`proof-prod`/`use-hide-unit`/`step-prod`/
  `qed-step`, `syntax.hoon:2512+`): `n-proof`/`n-terminalproof`/`n-proofstep`/`n-qedstep`/
  `n-useorhide`.
- `+g-thm` takes the theorem BODY (first `%node` kid) and **drops** the trailing proof
  node; the theorem span is `(span-of:ast u)` = the whole unit, so it already INCLUDES the
  proof (oracle: `theorem name=Bar 5.1-8.11` spans through QED). `+gen-module`'s walk
  **skips** any unit that is not def/theorem/assumption/recursive/instance — so top-level
  `n-useorhide` units are silently dropped. Net: proofs + USE/HIDE emit no graph nodes, no
  LEVELS entries, no diagnostics — exactly SANY's SemDump non-projection (`SemDump.java:260`
  renders `getTheorem()` only, never `getProof()`).

VERIFIED: new byte-exact golden `desk/test-data/sem/pfthm/A.tla` (`THEOREM Foo == c=0 /
OBVIOUS`; `THEOREM Bar == c=1 / <1>1. c=1 OBVIOUS / <1>2. QED`; top-level `USE Foo` /
`HIDE Bar`) — port == oracle, both render body-only thmdef/theorem (span incl. proof),
ACCEPT 0 diags, own-theorem lp/lc correct (`lvl Foo L0 lp={c} lc={c<=2}`). gen-sem 101→102,
full `-test /tests/lib/sem` `ok=%.y`. test214 re-probed = `%accept, sem-diags=0` (the proof
step `<1>2. USE TRUE,bar,xx,xx!1` is never walked, so its 3 non-HIDE (*ERROR*)s stay
unflagged — matching the oracle). Probe removed.

Consequence for .3: the ONLY work to flip test214 is walking the TOP-LEVEL `n-useorhide`
units in `+gen-module` + the EC 4357 HIDE-fact check. The proof steps are irrelevant to the
4357 (USE facts are unchecked; proof-step facts are never reached). Census NOT edited.

### R1.3.5.4.3 — USE/HIDE fact validation, EC 4357 (SHIP-VERIFIED build 619, 2026-08-10)

**test214 flips hoon=accept → hoon=reject with EXACTLY one EC 4357 @ 10.11-10.14** — the
census target. Mechanism, all in `semantic.hoon`:

- **`+hide-facts`** (new): the fact nodes of a USE/HIDE unit = the `%node` kids ahead of the
  `%df` (DEF/DEFS) keyword leaf (facts precede the optional `DEF targets` list; comma/kw are
  leaves, skipped).
- **`+g-usehide`** (new): returns `(list sdiag)`, no graph node (SANY projects neither USE
  nor HIDE). Fires only when the first kid is the `HIDE` keyword leaf. Each fact is resolved
  via `+g-x`; if the result is an `%apply` whose `kind.op` ≠ `%thm-assump`, emit
  `derr 4.357 (span-of f) "The only expression allowed as a fact in a HIDE is "` (trailing
  space — SANY's first-line message; the `\nthe name of…` continuation is dropped by the
  first-line normalization both sides share). A ThmOrAssumpDef-named fact (`bar`, scoped by
  .1) passes; a builtin OpAppl (`TRUE`) is flagged; a non-`%apply` fact (a literal) is not
  flagged (SANY guards on `OpApplKind`). `g-x`'s own resolution diagnostics are threaded too
  (empty for test214's `bar`/`TRUE`). USE units are skipped (facts unchecked).
- **`+gen-module` walk**: new arm `?: (is-kind u %n-useorhide) $(us t.us, ds (weld ds
  (g-usehide u c)))` ahead of the def/function filter (the walk's `c` is the full-ctx, so
  `bar` resolves to `%thm-assump` from .1).

VERIFIED: probe on real test214 → `verdict=%reject sem-diags=1`, the single diag
`code=4.357 at=10.11-10.14 msg='The only expression allowed as a fact in a HIDE is '` —
byte-identical to the oracle `D 4357 ERROR 10.11-10.14 …`. The 3 non-HIDE (*ERROR*)s stay
unflagged (USE facts + proof-step USE are never checked). Probe removed. New byte-exact sem
golden `desk/test-data/sem/hidefact/A.tla` (`THEOREM Foo == TRUE` / `HIDE Foo, TRUE` → Foo
OK, TRUE → 4357; dump header `ACCEPT` + DIAGS, per `SemDump`). gen-sem 102→103, full
`-test /tests/lib/sem` `ok=%.y` no regression — pfthm's `HIDE Bar` (Bar a theorem) correctly
draws no 4357. Census NOT edited (flip is the .4 close-out); test214 stays hoon=accept in
`SUB_BATCH_DIVERGENCES`, mechanism-verified as reject.

### R1.3.5.4.4 — R1.3.5.4 close-out (census flip + ledger, 2026-08-10)

Census flip for the two R1.3.5.4 targets, plus a discovered pre-existing divergence.

- **Census:** removed `suite/test214` + `suite/test216` from `SUB_BATCH_DIVERGENCES`/
  `SUB_BATCH_REASONS` (`gen-tier2-tests.py`); `gen-tier2-tests.py` regenerated the shards;
  `tier2.py --check` byte-reproducible. Ship-run (full suite) **sub-4 OK** — test214 now
  rejects (EC 4357), test216 now accepts, both agree with the pinned Java.
- **Discovered pre-existing divergence — `suite/etest5`.** The .4 tier2-sub run surfaced
  `sub-3` failing on `suite/etest5` (`IF M!Init …`, a member of a NONEXISTENT module M):
  hoon **accepts** (0 diags), SANY **rejects** (`D 4200 Unknown operator: Init` at the
  selector span). **Proved PRE-EXISTING**: deploying `624cae35` (R1.3.5.3.7, before .4) and
  probing → still `%accept`. etest5 was never in the census (0 hits in the pre-.4
  divergences), so `sub-3` had been silently red since before .4; the §R1.3.5.3.7 "only
  sub-5 fails" note was unverified (no full tier2-sub run there). Root: `M!Init` isn't in
  ctx, falls to the selector resolver, and resolves to the local `Init` def ignoring the
  unknown instance prefix → under-rejects. NOT `!`-nav/proof, NOT introduced by .4 —
  **added to the census** (`suite/etest5 -> hoon=accept`) with an R1.3.6 pointer, so the
  census is truthful and `sub-3` is accounted for. Divergences 4→5 (290/295 agree).
- **Sole remaining tier2-sub failure: `sub-5` / `suite/test52`** — the R1.3.5.1 unary-minus
  fix flipped test52 to hoon=accept (== Java), but its census removal is one of the six
  entries the parent plan explicitly defers to **R1.3.5.8** (and R1.3.5.3-plan's verification
  section already notes "the full suite's ok=%.n will carry the R1.3.5.1 test52 sub-5 flip
  until the R1.3.5.8 census close-out"). So the full suite stays `ok=%.n` solely from this
  documented deferral; every other arm (incl. sub-3 etest5 now tracked, sub-4 test214/216)
  is green.
- **Ledger/docs:** `parity-manifest.md` `semantic-graph` residual advanced (theorem-name
  scoping + USE/HIDE EC 4357 + BY/QED proofs-walk-clean now listed done; EC 4204 instance-
  member arity + level-constraint propagation + hash-order + wider projection remain, still
  `partial`); `compatibility.md` R1.3.5 residue rewritten to the current four census specs
  (test52/206/217/219) + the etest5 discovery, noting R1.3.5.3 closed test219a and R1.3.5.4
  closed test214/test216. `tier2.py` description 289→290/295. port-map R1.3.5 row deferred
  to the R1.3.5 close-out (.8, which owns full census reconciliation incl. test52).

R1.3.5.4 COMPLETE: test214 (EC 4357 reject) + test216 (accept) closed and ship-verified;
mechanism = theorem-name scoping (.4.1) + proofs walk clean/no projection (.4.2) + USE/HIDE
fact validation (.4.3); no regression (etest5 pre-existing). Remaining R1.3.5 census
residue (test52/206/217/219/etest5) is R1.3.3-arity + unary-minus + nonexistent-module,
none owned by R1.3.5.4.

### R1.3.5.5.0 — kickoff / level-constraints measurement (DOCS/ORACLE ONLY, 2026-08-10)

R1.3.5.5 (`level-constraints` full differential) DECOMPOSED into
`~/FoxyLabs/tla-lus/R1.3.5.5-plan.md` (.0-.5). No census spec — it is the
`level-constraints` ledger `partial → parity` push. In every finding the GRAPH (node)
projection matches byte-exact; only the `LEVELS` section diverges.

- **recinst reproduced (the anchor).** Re-added `desk/test-data/sem/recinst`
  (`RECURSIVE g(_)` / `foo(n) == INSTANCE B WITH F <- g, c <- n` / `g(n) == foo(n)!Use`;
  B: `CONSTANT c`,`CONSTANT F(_)`,`Use == F(c)`), gen-sem, ship-tested → **FAILED on
  LEVELS only**: oracle `lvl foo!Use L0 ml=[2] w=[1]` + no module lc; port `ml=[3]` +
  spurious `lvl MODULE A L-1 lc={n<=2}`. The bound formal param `n` leaks into module
  scope and `foo!Use`'s arg max-level over-counts by one. Matches the withdrawn-golden
  symptom (`ml=[2]↔[3]`). Reverted recinst (back to 103 goldens) to keep the suite green;
  .5.1 restores it deterministically. Locus: `+rec-seed` (:4414) × `+l-substin`/getSubLCSet
  (:3664, :4687-4755) — the RECURSIVE `oparg g` substituted through WITH re-enters the
  level fixpoint, which is not order-invariant (a `~(tap by)` accumulator).
- **Own-theorem-ref lp/lc (from .4.1).** `THEOREM Foo == c=0` / `Bar == Foo` → oracle
  `lvl Bar lp={c} lc={c<=2}`, port empty. Cause: `+l-module-core` registers thmdef oplevs
  in the twalk (:5104) AFTER the dwalk defs that reference them → .5.2 pre-seeds them.
- **$APSubstIn substituted-constant discharge (from .4.1).** `INSTANCE B WITH c<-0` (B
  refs its own `c`) → SANY discharges `c`, port still renders `lc={c<=2}`/`lp={c}` on the
  importer → .5.3 extends the R1.3.3.1 formal-param-skip discharge to substituted keys.
- **Instance-def hash-order** (existing approved-difference, .5.4) + **wider LEVELS
  projection** (.5.4) + **full re-level differential** over the corpus (.5.5).

Reusable: the R1.3.3.1 `%formal-param` skip in getSubLCSet (:3458/:3549/:3600) — .1 and .3
extend the SAME discharge rule; the `lres`/`oplev` algebra + LEVELS renderer are correct
(values wrong, not rendering). Sub-plan order .1(anchor+discharge) → .3(reuses) → .2(indep)
→ .4/.5(projection+differential close-out). No code/census change this step.

### R1.3.5.5.1 — recinst RECURSIVE-op-through-WITH LEVELS (SHIP-VERIFIED, 2026-08-11)

The anchor. Two symptoms on recinst: `foo!Use ml=[3]` (oracle `[2]`) + spurious module
`lc={n<=2}`. Graph matched; LEVELS diverged. ROOT CAUSE (found by tracing `+l-def`'s
`lc.r.gb` for foo!Use = **empty**): the constraint comes from the operator argument `g`
(RECURSIVE, seeded `maxLevels=[2]`) substituted for B's `F` in `Use == F(c)`. The body
carries an argLevelParam `[F 0 c]`; `+l-substin`'s `ap2` **dropped** it (op is a subst
param) instead of turning it into a level constraint, and the module-scope value was
computed separately by `+l-instance` and leaked (missing formal-param skip).

- **Fix (a) — `+l-substin` `alp-lc`** (feeds the DEF's lc): for each body argLevelParam
  `[op i par]` whose `op` is a substituted param resolving (via `+oparg-def` on the
  substituting expr) to an operator DEFINITION, add `par' <= (mxl-of op.oplev i)` where
  `par'` = the substituting expr's `lp` for `par` (or `par` itself if unsubstituted).
  KEEPS formal params, so `foo!Use`'s param `n` gets `n<=2` → `+l-def` `maxl` = min(3,2) =
  2 → `ml=[2]`. Merged as `(lc-uni lc2 alp-lc)` in the returned lres.
- **Fix (b) — `+l-instance` argLevelParam `lcc`** (the module-scope instance-node
  constraints): added the R1.3.3.1 `?: =(%formal-param kind.i.qs) skip` (the constant/
  variable-param block already had it) → the bound param `n` no longer surfaces as module
  `lc={n<=2}`.

Deterministic: the constraint is read directly from `g`'s seeded oplev (`rec-seed`
maxLevels [2]), replacing the order-dependent accumulation that produced the withdrawn
golden's `ml=[2]↔[3]` flip. `snames` (adding instance members to the open RECURSIVE
section) was explored and REVERTED — it did not change the result (the fix is in the
constraint computation, and it introduced a graph diff), confirming the section-membership
theory was wrong.

VERIFIED: `desk/test-data/sem/recinst` restored byte-exact (`lvl {g,foo!Use,Bar} ml=[2]`,
no module lc); full `-test /tests/lib/sem` `ok=%.y`, 103→104, **no regression on any
instance golden** (instparm/instnest/instsel/hoinst/tupsub/...). **Golden uses a VARIANT**
(`foo == INSTANCE B WITH F<-g` non-parametrized; `Bar(x) == foo!Use(x)`): the original
mutual-recursion spec `g(n) == foo(n)!Use` has its LEVELS fixed too (measured `ml=[2]`), but
`foo(n)!Use` is exactly the **test217** instance-element-arg application the port drops
(graph diverges) — a pre-existing R1.3.3 gap, so the byte-exact golden avoids it. HOON: a
face immediately before `~(` parses `=~` as the tissig rune (`lc=~(tap...)` → syntax error);
`%Foo` with uppercase is not a valid `@tas`; cast list-typed `?~` results explicitly
(`=/ qs=(list lkey)`) or `t.qs` mint-`-find`s.

### R1.3.5.5.2 — own-theorem-reference lp/lc (SHIP-VERIFIED, 2026-08-11)

`THEOREM Foo == c=0` / `Bar == Foo` → oracle `lvl Bar lp={c} lc={c<=2}`; port rendered
`lvl Bar` empty because `+l-module-core` levels all defs (dwalk) before the theorem
definitions (twalk, ~:5181), so `Foo`'s oplev was absent when `Bar` (a def whose body is a
bare `apply Foo opkind=ThmOrAssumpDefKind`) was levelled — it inherited no constraints.

FIX: after the level env `e` is built and before the dwalk, a pre-seed pass folds each named
`thmdef` into `ops.e` — `(l-thm i.tl e)` then the same oplev construction the twalk uses
(`:* lvl ok 0 | ~ ~ ~ ~ ~  lp lc ac ap all nlp ~ ==`). A def in the dwalk now reads the
theorem's lp/lc; the twalk still runs afterwards and registers the FINAL oplevs (so a
theorem body that references a def is still computed correctly there — the pre-seed only
serves def→theorem inheritance, and for a constant/var-bodied theorem the two agree).

VERIFIED: new byte-exact golden `desk/test-data/sem/thmreflvl` (`lvl {MODULE,Bar,Foo}
lp={c} lc={c<=2}`); full `-test /tests/lib/sem` `ok=%.y`, 104→105, no regression on the
theorem goldens (thms/thmscope/thmsel/thmap) or the module-line constraint aggregation.
This is the item .4.1's `thmscope` golden was kept constant-free to avoid.

### R1.3.5.5.3 — $APSubstIn substituted-constant discharge (SHIP-VERIFIED, NO code change, 2026-08-11)

Fresh measurement: the substituted-constant discharge is ALREADY correct — the `.4.1`/`.5.0`
note (`INSTANCE B WITH c<-0` renders `lc={c<=2}`) did **not** reproduce. `+l-substin`'s `lc2`
maps each body constraint keyed by a substituted param to the substituting expression's level
params (`sub-r(si).lp`); `c <- 0` substitutes `c` with a `num` whose lp is empty, so the `c`
constraint drops. The `lc={c<=2}` seen at .4.1 was the **own-theorem-ref inheritance** bug
(`Baz == Thm`, Thm imported) fixed by **R1.3.5.5.2**'s pre-seed — `Baz` now inherits `Thm`'s
already-discharged oplev (empty), not a stale/undischarged one.

VERIFIED (all all-empty LEVELS, matching oracle): new goldens `desk/test-data/sem/apsubdis`
(theorem / `$APSubstIn`: `INSTANCE B WITH c<-0` over B `THEOREM Thm == c=1` / `Baz == Thm`) +
`subdis` (def / `$SubstIn`: B `Use == c=1` / `Baz == Use`); the full .4.1 spec (thmscope's
Foo/Bar/Qux + this instance) also passes (tested, then dropped as redundant with thmscope).
gen-sem 105→107, full `-test /tests/lib/sem` `ok=%.y`, no regression. No code change; the two
goldens lock the discharge for both substin kinds.

### R1.3.5.5.4 — instance-def hash-order + wider LEVELS projection (AUDIT, NO code change, 2026-08-11)

Both items resolve without code.

- **Instance-def hash-order** — reproduced: `INSTANCE B WITH k<-0` over B `Alpha..Epsilon`
  (all `== k`) → oracle def order `Delta,Epsilon,Beta,Gamma,Alpha` (Java `Hashtable`
  iteration by UniqueString identity) vs the port's source order. Recorded as an
  **approved-difference** (already documented at `compatibility.md:328-337`): cosmetic —
  affects only the ORDER of a multi-def instance's imported defs in a dump, never
  membership/arity/level/body/verdict. Canonicalizing would require partitioning
  `getOpDefs()` into own (source-order) vs imported (SubstIn-bodied) and sorting only the
  latter on BOTH sides (SANY interleaves them), high fiddliness for a cosmetic gain — so no
  multi-def-instance golden; single-def-instance goldens (instparm/instnest/instsel/...)
  stay byte-exact.
- **Wider LEVELS projection** — audited COMPLETE. `+lvl-line-def` emits every field
  `SemDump.java` does: `L<lvl>`, `ml=[]/w=[]` (arity>0), `mml=[]/olc=[]` (has-op-param), and
  `(lvl-segs lp lc ac ap nlp)` → `lp/lc/alc/alp/nlp`. Field coverage across the sem goldens:
  mml/olc ×21, alc ×5, alp ×4, nlp ×25, ml ×40, lp ×56, lc ×80 — every field exercised and
  byte-matched. No missing projection code, no new golden needed.

R1.3.5.5 residue after .1-.4: only the **full re-level differential** (.5.5, the close-out)
+ the ledger flip remain; the level-constraint VALUES (recinst RECURSIVE-through-WITH,
own-theorem-ref, substituted-constant discharge) are fixed, projection is complete, and the
one ordering divergence is a documented approved-difference.

### R1.3.5.5.5 — full re-level differential + close-out (SHIP-VERIFIED, 2026-08-11)

= UNIT R1.3.5.5 COMPLETE. The `level-constraints` ledger row flips **partial → parity**.

- **Differential:** the sem corpus (107 goldens) compares the full `LEVELS` section byte-for-
  byte against `SemDump`; all pass, so the re-level differential is clean. The `.1`-`.3`
  fixes (recinst RECURSIVE-through-WITH, own-theorem-ref pre-seed, substituted-constant
  discharge) and `.4` projection audit are all captured by dedicated goldens
  (`recinst`/`thmreflvl`/`apsubdis`/`subdis`).
- **No-regression:** full `-test /=tla-lus=/tests` → **OK 1515 / FAILED 1**; the one FAILED
  is `tier2-sub` sub-5 (`test52`, the R1.3.5.1 flip deferred to R1.3.5.8), NOT a level
  change. Every leveling-sensitive dir green — sem (135 arms), lvl (18), node-eval (37),
  value (1) — and tier2-sub sub-1/2/3/4/6 OK, so the `+l-substin` `alp-lc` / `+l-instance`
  formal-param skip / thmdef pre-seed did not flip any SANY accept/reject verdict across the
  295-spec subdir batch. `tier2.py --check` byte-reproducible (290/295, census untouched).
- **Ledger/docs:** `parity-manifest.md` `level-constraints` → **parity** (rationale records
  the three value fixes + complete projection; sole residual = the instance-def hash-order
  approved-difference); the `semantic-graph` residual updated (level-constraint items done,
  only EC 4204 instance-member arity `test206`/`test217`/`test219` remains, an R1.3.3
  follow-up). `compatibility.md` hash-order approved-difference already covers the ordering.

R1.3.5.5 done: RECURSIVE-op-through-WITH levels fixed + deterministic, own-theorem-ref lp/lc,
substituted-constant discharge, projection complete, differential clean, `level-constraints`
at parity. Remaining R1.3.5 units: `.6` parse-errors, `.7` tlc-output-ec/tlc-constants, `.8`
census close-out (incl. the deferred test52).

### R1.3.5.6.0 — parse-errors kickoff / differential (DOCS/ORACLE ONLY, 2026-08-11)

NOTE: "R1.3.5.5.6" in the request = R1.3.5.6 (the R1.3.5.5 sub-plan ended at .5). R1.3.5.6
(`parse-errors` residual) DECOMPOSED into `~/FoxyLabs/tla-lus/R1.3.5.6-plan.md` (.0-.5).

Differential: added 10 malformed `.tla` to `desk/test-data/parse-err/boundary/` targeting
unexercised productions, `gen-parse-err-tests`, ship-tested `(dump-err:syntax)` vs
`ParseErrDump`. **6/10 already byte-exact** (the port's `+perr`/`+bpa`/`+stack-tape` machinery
is broadly correct — e.g. `x == 1 +` matches exactly incl. the ExtendableExpr/Expression/
Definition/Module-body stack). The 4 divergent, in four classes:

1. **Missing `+bpa` stack entry** — `x == \A i`: SANY stack top-5 = `Quant Bound`/`Quantified
   form`/`Expression`/`Definition`/`Module body`; port omits `Quant Bound`, so the window
   shifts and shows a spurious trailing `Module definition`. → .6.1.
2. **`Encountered` grouping+span** — `INSTANCE` alone: `Was expecting` matches, but SANY
   `Encountered "INSTANCE ====" at line 2, column 1 and token "----"` (production-start token
   grouped, production span) vs port `Encountered "====" at line 3, column 1 and token
   "INSTANCE"` (raw next token, own span). → .6.2.
3. **Module-body routing** — `THEOREM` alone: SANY reports at module-body level (`Was
   expecting "LOCAL, INSTANCE, …"`, stack Module body/Module definition); port parses THEOREM
   as an expression start (ExtendableExpr/Expression) and emits no `Was expecting`. → .6.3.
4. **Grammar-level recovery point** — `f[x \in S] ==`: SANY expects `==== or more Module
   body` at `f`; port parses it as a def and fails later at `====`. → .6.4.

Reverted the 10 probe fixtures (suite back to 34 goldens green). The ~12 module-level
expecting strings (`+set-exp`/`body-expecting`) + the block renderer are correct; the work is
extending `+bpa` push sites, the encountered-assembly, and keyword-unit routing, then
exhaustive per-production fixture coverage (~100 sites). Sub-plan .1 stack / .2 encountered /
.3 routing / .4 long-tail+grammar / .5 ledger flip. STALE ledger note to fix in .5:
`parse-errors` row still says `test206/216/219 fail at parse` — R1.3.5.2/.3 closed the
`!`-nav parse layer; they now diverge at SEMANTIC (instance-member arity). No code/census
change this step.

### R1.3.5.6.1 — bpa stack-entry coverage: expression + declaration (SHIP-VERIFIED, 2026-08-11)

Audited SANY residual-stack production names (batch of ~45 malformed inputs through
`ParseErrDump`, `^…starting at` extracted) vs the port's `+bpa` set. Pushed the missing
EXPRESSION + DECLARATION production entries (each with pop-on-success or the enclosing
production's `stk0` reset; byte-exact vs `ParseErrDump`):

- **Quant Bound** — `+quant-bound2` (bounded, also feeds SetOfAll `{e : qb}`) AND
  `+unbound-quant` (SANY reports an unbounded `\A i` binder under the same QuantBound
  production; the port's `match-fcn-const` splits bounded/unbounded early, so BOTH paths push).
- **Field Value** / **Field Set** — `+record-fields`, per field at the field name, keyed on
  `sep` (`|->` → Field Value / rcd-constructor, `:` → Field Set / set-of-records).
- **Except Component** — `+except-spec`, per `![expr,..]`/`.field` selector; the enclosing
  Except Spec resets `stk` to `stk0` on success, so only the error path matters.
- **Parameter declaration** + **Constant declaration items** — `+constant-decl` (unit + each
  comma item) — plus the `+param-decl` set-exp `"Identifier, _ or prefix op"`.
- **variable declaration** — `+decl-list` (only when `kw=%variable`).

New boundary fixtures: c-forall-inc/c-setofall-inc/c-fieldval-inc/c-setofrcd-inc/c-except-{comp,
bang,comp2}/c-vardecl-inc/c-constdecl-inc. gen-parse-err 34→43; full `-test /tests/lib/parse-err`
`ok=%.y`, no regression. bpa/epa/set-exp mutate only `stk`/`exp` (read by `+perr` on error) —
successful-parse CST unchanged, so no parser/sem regression.

REMAINING audit names moved to **.6.3** (coupled to keyword-unit routing — whether the port
even enters them): `Instance`/`NonLocalInstance`/`Substitution` (instance) and `Theorem`/
`Proof`/`Step`/`UseOrHideOrBy` (proof/theorem). HOON: `bpa` returns `pst`, so pop via
`=?  s  cond  (epa s)` or `(epa s.p.er)` at the success return; `bpa` clears `exp`, so a
following `set-exp` (e.g. param-decl) must come AFTER the bpa push.

### R1.3.5.6.2 — Encountered grouping analysis, MERGED into .6.3 (2026-08-11)

Read SANY's exact algorithm (`ParseExceptionExtended.getShortMessage`, parser/):
```
maxSize = max length over e.expectedTokenSequences
echo = join " " of maxSize token images starting at e.currentToken.next
       (a kind==0 token renders as tokenImage[0] = "<EOF>")
position = e.currentToken.next .beginLine/.beginColumn
token    = e.currentToken.image           (the last successfully matched token)
```
Mapped to the port's `+encountered`: position = `(peek-pos s)` = currentToken.next ✓;
token = `last.s` image = currentToken.image ✓; echo = `n` token images from `rest.s` (head =
currentToken.next) ✓ START but the port fixes **n=1** at all 41 `+perr-enc` sites, while SANY
uses maxSize. So, given identical routing, the ONLY divergence is the echo COUNT.

Broad scan (18 malformed inputs): multi-token echoes appear for EXACTLY four inputs —
`INSTANCE`/`THEOREM`/`ASSUME`/`LOCAL` each immediately followed by `====` → `"KW ===="` @ 2.1,
token `"----"`, maxSize=2. All four are bare module-body keyword units where SANY did NOT
consume the keyword (currentToken = the header `----`, next = the keyword) — i.e. every
multi-token-echo case is ALSO a .6.3 keyword-unit ROUTING divergence (the port consumes the
keyword and fails later at `====`, position 3.1, echo 1). There is NO pure echo-count case
(maxSize>1 with correct routing). CONCLUSION: the maxSize echo is inseparable from the routing
fix → .6.2 MERGES into .6.3, which must (a) not consume the keyword (fail at module-body), then
(b) echo maxSize=2 at the module-body level (a per-`perr-enc`-site `n`). No standalone code.

### R1.3.5.6.3 — keyword-unit routing + Encountered echo + entered-unit stack (SHIP-VERIFIED, 2026-08-11)

**Routing (the core .6.2+.6.3 divergence).** New `+body-end-ahead` (the token after the
current keyword is `%end-module`/EOF): in `+body-unit`, a bare `THEOREM`/`ASSUME` at the body
end takes `[%| (perr-brk s 2)]` (fail the Unit choice at module-body, keyword UNCONSUMED,
maxSize=2 echo `"KW ===="`) instead of entering the unit; `INSTANCE` additionally requires a
`%identifier` next (so `INSTANCE +` also fails at body — matches SANY). LOCAL already did this
(`perr-brk s 2` at :3396). The `+perr-brk s 2` mechanism (maxSize=2, currentToken.next
position, currentToken.image token) was already present — the merged .6.2 echo needed no new
code, just routing to it. Fixtures c-{instance,theorem,assume,local}-bare + c-instance-plus,
byte-exact.

**Entered-unit stack productions** (push at entry, pop on success): `Theorem` (`+theorem-unit`,
both returns), `Instance` (`+instance-unit`), `NonLocalInstance` (`+noninst`, both returns),
`Substitution` (`+substitution`). Verified present in the expected stacks; c-thm-body-inc
(`THEOREM x`) byte-exact. 43→49 goldens; parse-err + syntax-CST green (routing change did not
regress successful parses — bpa/set-exp/routing-guard are error-path-only for VALID units,
which still route via the identifier/non-end-module lookahead).

**SURFACED, deferred to .6.4:** (1) a GENERAL **expression-entry** divergence — when a called
expression is EMPTY (first token can't start one, e.g. substitution RHS `<-` then `====`),
SANY sets `Was expecting "Expression or Op. Symbol"` and reports at the CALLER's level without
pushing `ExtendableExpr`/`Expression`; the port enters `+expression` (pushing them) and lacks
the expecting. This blocks the instance-sub fixtures even though their Substitution/
NonLocalInstance/Instance bpa entries are correct + already in the stack. Contrast `x == 1 +`
(expression STARTED, mid-expr failure) which matches — so the fix is guarding the empty-start
case at expression entry. (2) proof productions `Proof`/`Step`/`UseOrHideOrBy`.

### R1.3.5.6.4 — expression-entry (partial) + remaining long-tail (SHIP-VERIFIED, 2026-08-11)

**(a) Expression-entry divergence — resolved TARGETED, not global.** A global guard at
`+expression` entry (`?~ pk0 || %end-module → report at caller without pushing Expression/
ExtendableExpr`) REGRESSED the .6.1 field/except goldens + a corpus original: SANY
**context-dependently** enters the Expression production — a record Field Value / Except
Component RHS at `====` DOES push `ExtendableExpr`/`Expression` (their goldens have it), but a
Substitution RHS does NOT (reports at the Substitution level). So the guard must be per-caller.
Reverted the global guard; added it ONLY in `+substitution`: after `<-`, if the next token is
`%end-module`/EOF, `[%| (perr-enc (set-exp s 'Expression or Op. Symbol') 1)]` at the
Substitution level. Closes the instance-sub cases (their `Substitution`/`NonLocalInstance`/
`Instance` bpa entries from .6.3 were already correct): c-inst-sub-inc / c-inst-sub2-inc /
c-defnst-sub-inc byte-exact, 49→52 goldens, no regression.

**REMAINING (the .6-parse-errors long tail, not done):**
- (b) proof `+bpa` entries `Proof` (proof-prod @ the proof-start), `Step` (step-prod/qed-step
  @ each step), `UseOrHideOrBy` (use-hide-by @ BY/USE/HIDE) — measured stacks (`THEOREM x==1
  PROOF <1>1` → Step 2.22/Proof 2.16/Theorem 2.1; `... OBVIOUS BY` → UseOrHideOrBy 2.16/Proof
  2.16/Theorem 2.1); the proof-prod machinery is plv-wrapped with step-list/qed/terminal
  branches, so pushes+pops need care.
- (c) per-production recovery points (`f[x \in S] ==` — SANY expects `==== or more Module
  body` at `f`, the port parses it as a def and fails later).
- (d) EXHAUSTIVE sweep: a boundary fixture per remaining grammar production + fix straggler
  byte-diffs — this is the bulk of the ledger's "~100 expecting sites" and the gate for the
  .6.5 `parse-errors partial→parity` flip.

parse-errors ledger now covers: expression + declaration stack productions (.6.1),
keyword-unit routing + maxSize echo (.6.2/.6.3), instance stack + substitution-RHS (.6.3/.6.4a)
— still `partial` pending (b)/(c)/(d).

### R1.3.5.6.4 sub-plan decision — DECOMPOSED (broad differential, 2026-08-11)

Q: should R1.3.5.6.4 have a sub-plan? Ran a broad differential — 49 malformed inputs across
the grammar as boundary fixtures, gen-parse-err, ship-tested vs ParseErrDump: **13 diverge /
36 already byte-exact** (~27%). The 13, by area: `\E`/`LET` (expr/control-flow), `[a EXCEPT
!.b =`/`[a EXCEPT ![1]` (EXCEPT recovery), `WF_v`/`[][a]_`/`<><<a>>_` (temporal/fairness),
`LAMBDA`/`LAMBDA a`, `RECURSIVE`/`RECURSIVE f(` (module-level), `THEOREM a PROVE`/`USE`
(proof/theorem). So the remainder is a full grammar SWEEP: ~15-20 divergence fixes + ~40-60
fixtures + proof bpa + recovery-points — one repeated pattern (bpa/set-exp/routing, byte-match
ParseErrDump) at scale, a few trickier (LAMBDA/fairness/RECURSIVE/proof). Large + multi-area →
YES, sub-plan. Wrote `~/FoxyLabs/tla-lus/R1.3.5.6.4-plan.md` (.0 kickoff done; .1 expr/control-
flow, .2 collections+EXCEPT, .3 temporal/fairness/LAMBDA, .4 module-level+proof, .5 recovery-
points+exhaustive+close-out/ledger flip). Reverted the 49 probe fixtures (suite back to 52
goldens green). Also — RESUMED the tla-zod ship after a session-teardown kill (`tmux
new-session -d -s tla-zod -x 220 -y 50` + vere resume, ~20s, no pill; clean stop, no lock).

### R1.3.5.6.4.1 — expr/control-flow productions (SHIP-VERIFIED, 2026-08-14)

Added 8 boundary fixtures (`boundary/c-{exists,choose,letin,if,if-nothen,if-noelse,
case,case-arm}-inc.tla`; the last four dropping the `-inc`): `\E`/CHOOSE/LET/IF/CASE
incomplete forms. Regen 52→60 goldens. Ship differential vs ParseErrDump: **6 already
byte-exact** (choose/if-inc/if-nothen/if-noelse/case-inc/case-arm), **2 diverged** — exactly
the plan's predicted `\E` + `LET`.

**exists-inc (`x == \E`).** Port pushed a spurious `Quant Bound` at 3.1 and (frame-cap then
dropping the outermost) was MISSING `Module definition` at the bottom. SANY enters the
QuantBound production only once a bound variable actually starts — a bare `\A`/`\E` at end
pushes nothing. FIX in `+unbound-quant`: replaced the unconditional `bpa 'Quant Bound'` with a
`=?` guarded on the next token being `%identifier`. Removing the spurious frame drops stack
depth from 6→5, so the residual-stack cap now reveals `Module definition` — both the extra and
the missing line fixed by one change. (`\A i` / setofall still push Quant Bound at the ident
position — unchanged.)

**letin-inc (`x == LET`).** Port's LET definition-list frame was `Definition`; SANY names it
`Let Definitions`. FIX: `+op-or-fun-def` now takes an `lbl=@t` frame label; the LET caller
passes `'Let Definitions'`, the three module-level callers `'Definition'`.

Both byte-exact; parse-err 60/60 `ok=%.y`; `tests/lib/syntax` CST green (shared productions
`op-or-fun-def`/`unbound-quant` touched, error-path-only — no valid-parse regression). No
existing golden changed bytes. Renamed fixtures to the `.6.x` `c-*` convention, which revived
the stale orphan goldens `b-c-{choose,letin,if-noelse}-inc.gold`.

### R1.3.5.6.4.2 — collections + EXCEPT recovery (SHIP-VERIFIED, 2026-08-14)

8 boundary fixtures (`boundary/c-{fcnconstr-inc,fcnset-inc,tuple-inc,record-inc,setof-filter,
except-inc,except-eq,except-idx}.tla`): `[n \in S |->` / `[S ->` / `<<a` / `[a |-> 1` /
`{x \in S :` / `[a EXCEPT` / `[a EXCEPT !.b =` / `[a EXCEPT ![1]`. 60→68 goldens. Differential:
**6 already byte-exact** (all collections + bare EXCEPT), **2 diverged** = the plan's predicted
`!.b =` + `![1]`.

Both EXCEPT divergences shared one root cause plus one extra. `+except-spec` pushed the
`Except Component` frame at the TOP of every selector-loop iteration, including the terminal
iteration that turns out to be the `= or ,` decision point (≥1 component already parsed, next
tok not a selector) — so the port kept a spurious `Except Component` on the stack that SANY had
popped. But the FIRST component after `!` is mandatory (SANY pushes Except Component even for a
bare `!` at end — see c-except-bang / c-except-comp2, which have it with NO "Was expecting").
FIX: push `Except Component` via `=?` guarded on `|(first sel)` where `first = ?=([* ~] kids)`
(only the `!` leaf so far) and `sel` = next tok is `[`/`.`; NOT at the post-component decision
point. SECOND, `![1]` alone needs `Was expecting "= or ,"`: added `=? s &(!first !sel)
(set-exp s '= or ,')` right before the `= ` eat (error-path-only — a successful `=` / a deeper
value-expr failure clears it via the expression's own bpa, so except-eq stays expectation-less).

Both byte-exact; parse-err 68/68 `ok=%.y`; `tests/lib/syntax` CST green (except-spec is
error-path-only for valid EXCEPTs); no existing golden changed bytes. `c-*` naming revived the
orphan goldens `b-c-{except-inc,fcnconstr-inc}.gold`. NEXT: R1.3.5.6.4.3 (temporal/fairness +
LAMBDA + special ops).

### R1.3.5.6.4.3 — temporal/fairness + LAMBDA + special ops (SHIP-VERIFIED, 2026-08-14)

11 boundary fixtures: WF_v/SF_v, [][a]_/<><<a>>_, LAMBDA/LAMBDA a, ENABLED/UNCHANGED/DOMAIN/
SUBSET/`a \union`. 68→79 goldens. Differential: **5 already byte-exact** (all the prefix/infix
special ops -- their expression-entry was already correct), **6 diverged** = the plan's WF/SF +
box/diamond subscripts + LAMBDA×2. Three fixes:

- **box/diamond subscript** (`[][a]_` / `<><<a>>_`). Port was missing a `restricted form of
  expression` frame at the subscript position. `+subscript-expr` (both call sites: `]_`@arsb and
  `>>_`@arab) now pushes that frame at entry and restores stk0 on success (same save/restore as
  the fairness subject). One added frame; the `scag 5` cap then drops `Module body` -> byte-exact.
- **LAMBDA as def body** (`x == LAMBDA`). SANY rejects LAMBDA at the Definition RHS (`Was
  expecting "Expression or Instance"`, Encountered LAMBDA@2.6 token `==`, NO Expression frame) --
  LAMBDA is only an operator ARGUMENT, never a standalone expression. `+expr-start` keeps
  `%lambda` (args still parse), but `+finish-def`'s existing `.6.4a` guard gained an explicit
  `=(%lambda kind.u.pk)` disjunct so the def-body choice fails before entering Expression. Both
  lambda fixtures share one golden.
- **WF_/SF_ missing `(action)`** (`WF_v`). SANY aborts with a custom `Ill-structured fairness
  expression at line L, column C` (L,C = keyword pos), NO Encountered line, and the residual
  stack DROPS the caller's `Fairness Expression` frame. Surgical: only the `eat %lbr` failure
  (subject parsed OK, no `(`) emits this -- built via `perr` with `stk = t.stk.s` (drop the
  frame) + exp cleared + the custom tape from `wtok`'s span. A bad SUBJECT (`WF_3`, existing
  boundary/fairness.tla) still propagates the normal Encountered error WITH the frame -- verified
  unchanged.

Both/all byte-exact; parse-err 79/79 `ok=%.y`; `tests/lib/syntax` CST green; no existing golden
changed bytes (fairness.tla `WF_3` preserved). NEXT: R1.3.5.6.4.4 (module-level + proof/theorem).

### R1.3.5.6.4.4 — module-level + proof/theorem (SHIP-VERIFIED, 2026-08-14)

8 fixtures: RECURSIVE, EXTENDS, `THEOREM a PROVE`, `INSTANCE M WITH`, `THEOREM x==1 PROOF
<1>1`, `... OBVIOUS BY`, `... PROOF`, `THEOREM ASSUME x PROVE`. (USE/HIDE/`... BY` alone all
ACCEPT -- no error fixture.) 79→87 goldens. Differential: EXTENDS / THEOREM-PROVE /
INSTANCE-WITH already byte-exact (the last via .6.4a subst-RHS guard); **6 diverged** = the
plan's RECURSIVE + proof trio + ASSUME-PROVE. All were MISSING residual-stack frames (the
deferred proof bpa work); fixes push+pop the SANY production frames:

- **recursive-prod**: push `Recursive` at entry + `Constant declaration items` per item
  (mirrors const-decl's `Parameter declaration`/items), pop each via epa + `(epa s)` on success.
- **assume-prove**: push `Assume-Prove` (at the ASSUME, after the label branch), pop via stk0.
- **proof-prod**: push `Proof` at entry, single `(epa s)` on the sole success return.
- **step-prod**: push `Step` at entry (stk0 save), pop on all 3 success returns; NEW body guard
  in the assert-step arm -- no SUFFICES and a body token that starts neither AssumeProve nor an
  expression => `[%| (perr-enc (set-exp s 'proof step') 1)]` without entering Expression.
- **step-start**: `set-exp 'Step number'` at entry (the missing-step-number expectation).
- **use-hide-by**: push `UseOrHideOrBy` at entry (stk0 save), pop on both success returns.

`OBVIOUS BY` routes through proof-prod's k2=BY branch into use-hide-by, which rejects OBVIOUS
(not by/use/hide) -- now with Proof+UseOrHideOrBy frames. All frame pushes are error-path-only:
valid proofs/theorems restore stk0 on success (CST green, incl. proof specs).

**DEFERRED to .5**: `RECURSIVE f(` -- a genuine recovery-point (SANY multi-token echo `( ====`
@2.12, unwinds to just Module definition); belongs with the .5 recovery-point sweep, not a
frame fix. 

parse-err 87/87 `ok=%.y`; `tests/lib/syntax` CST green; no existing golden changed bytes.
NEXT: R1.3.5.6.4.5 (recovery-points incl. `RECURSIVE f(`/`f[x\in S]==` + exhaustive completion
+ parse-errors partial→parity close-out).

### R1.3.5.6.4.5 — recovery-points + exhaustive completion + close-out (SHIP-VERIFIED, 2026-08-14)

= UNIT R1.3.5.6 COMPLETE. parse-errors ledger `partial → PARITY`.

**Recovery-points → approved-difference (not fixed).** `f[x \in S] ==` / `g[..] ==` /
`RECURSIVE f(` / `x == f(` / `x == [a]_v v` / empty def `x ==`: SANY uses JavaCC syntactic
LOOKAHEAD to reject a whole module-body unit and unwind to `Was expecting "==== or more Module
body"` at an arbitrary recovery point (the module header). The port parses the unit greedily and
reports the PRECISE semantic failure point (empty RHS / incomplete param decl) — strictly more
useful; reproducing SANY's unwind needs full-unit backtracking to emit a worse message.
Documented in compatibility.md (Unit P2-2) + the parity-manifest row. Not added as goldens
(they'd fail the byte-exact suite by design).

**Exhaustive sweep.** Added 12 byte-exact fixtures for the remaining operator/module/collection
productions: `/\`/`=>`/`~`/`\cup`/`\X`/`..`/`=` operator edges, `f[` application, `a.` record
access, `CONSTANT x ,`, bare `AXIOM`, `{a \in}` set filter. One straggler: `x == f[` (empty
application index) — port entered Expression for the index; SANY reports at `Some [] Form`.
FIX: `+sbracket-args` guards the arg with `!(expr-start …)` → per-caller `perr-enc` without
entering Expression (.6.4a pattern). 87→99 goldens.

**Orphan cleanup.** Removed 4 dead committed goldens with no inputs: `b-c-{def-empty,fcndef-inc}`
(recovery-point approved-differences) + `b-c-{instance-noname,theorem-inc}` (exact dups of
c-instance-bare/c-theorem-bare). Revived `c-setof-bad` with an input.

**Close-out.** parity-manifest `parse-errors` row `partial → parity` (count 34→99), stale
`test206/216/219 fail at parse` clause corrected (they diverge at *semantic* EC 4204 since
R1.3.5.2/.3, tracked under semantic-graph; the correct ids are test206/**217**/219).
`check-parity.py --check` well-formed. Full `-test /=tla-lus=/tests`: `ok=%.n` with the SOLE
failure `test52` (R1.3.5.8-deferred, the .5.5 baseline — ZERO regression from .6.1–.5).
`tier2.py --check`: byte-reproducible (census untouched, exit 0). parse-err suite 99/99 green;
tests/lib/syntax CST green.

R1.3.5.6 DONE — clears the parse-errors residue. R1.3.5 remaining: R1.3.5.7 (tlc-output-ec +
tlc-constants), R1.3.5.8 (census close-out incl. the deferred test52).
