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
