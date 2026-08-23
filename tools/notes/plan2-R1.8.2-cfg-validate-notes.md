# P2-R1.8.2 — `cfg-validate`'s last three residues

Closes `cfg-validate` and, with it, `check-opt-cfg` — which owned no residue of
its own, only these three through `lib/config`. Ledger 121 terminal / 4 owed →
**123 / 2**.

R1.8.0's audit had already confirmed the three were real and removed a fourth
that was not (a stale `levelParams` design constraint R1.8.1.3b had dissolved).
This unit measured each of the three against the pin before writing anything —
and the third one shrank when measured.

---

## 1. Per-module `mod!lhs <- rhs` substitutions

`SpecProcessor.java:711-770`. The missing piece was never the loop; it was the
input. The port's graph exposed the root module plus its `EXTENDS` imports, and
nothing could name a **non-root** module's own operator list.

`sem-module` now carries `modops` (`+mod-opdefs` in `lib/semantic`): every module
in the spec mapped to the names and arities its own `ModuleNode.getOpDefs()`
exposes — EXTENDS closure first (dependency-first, first definer winning, LOCALs
not exported), then the module's own definitions, whose LOCALs *are* in the module
and so are listed. One `gen-module` per module, then cheap per-module closure
assembly. The map's key set doubles as the `modSet` that TLC_NO_MODULES tests
against.

`+mod-subst`/`+one-module` then run the loop, and `+unknown-modules` the 2245
check, in the Java's position: after the root 2226 sweep, before
`processConstantDefns`.

It is **not** the root loop repeated. Three asymmetries are explicit in the Java:

| | root loop | per-module loop |
|---|---|---|
| 2223 self-reference test | against the root `overrides` | against **this module's** table (`mDefs.containsKey(rhs)`) |
| rhs resolution | root `defns` | still root `defns` — the Java comments it: *"The rhs comes from the root module"* |
| 2225 arity check | deferred to `processConstantDefns` for a declared constant | fires **here**, for every operator |

A substitution applies to the module's own definition, so nothing is written back
to the root table.

**Config syntax measured, not assumed.** The first corpus attempt wrote
`CONSTANT B!Op <- Repl` and every case came back 2226 from the *root* loop —
`ModelConfig.java:328` folds `a!b!c` into one flat lhs name. The per-module form
is `Op <-[B] Repl` (`ModelConfig.java:342-372`), which is what the corpus uses.

## 2. `OpRcdValue.toString()` in an EC 2230 body

`+render-oprcd`, from `OpRcdValue.java:247`: `{ ` then one `<arg, arg, val>`
record per config line, joined by `, `, then `}` with no space before it; an empty
record is `{ }`. `addLine` appends and never dedups, so the config's line order
*is* the rendering order. Verified against the pin: `F(1) = 2` with `F(3) = 4`
renders `{ <1, 2>, <3, 4>}`.

Two Hoon notes for whoever touches this next: `"{ "` is not a tape literal — `{`
opens interpolation, so the brace comes from a cord (`(trip '{ ')`); and the
`turn`/`zing`/`weld` composition that reads most naturally here would not nest
under `(list @t)` without casts on every leg, so the arm is a plain accumulator
loop instead.

## 3. EC 2281's addendum on a temporal body — the residue overstated it

The residue said tlc2 renders EC 2261 there "with its abbreviated expression
rendering". **It does not.** `SemanticNode.toString()` returns
`getLocation().toString()`; the human-readable image is behind the
`SemanticNode.showPlainFormulae` system property, which no default run sets. So
the message's second parameter is a **location** — which `+loc-str` had already
been producing for the EC 2280 case since R1.8.1.3b.

The whole residue was one message template and one walk result away. Confirmed
against the pin, `CONSTANT C <- T` with `T == [](x = 0)`:

```
The configuration file substitutes constant C with non-constant T - specifically: TLC encountered a temporal formula ([]A) when evaluating a predicate or action.
line 5, col 6 to line 5, col 14 of module A
```

`+nonconst-ref` now returns a typed `ncref` — `%ident` (2280) or `%temporal`
(2261). It stops at a temporal node **without descending into it**, because
`Tool.evalImpl` switches on a node's OPCODE before evaluating its arguments: `C <-
[]P` names the box, never P's contents. The eight labels are exactly what
`Tool.java:2808-2846` passes as the first parameter: `[]A`, `<>A`, `WF`, `SF`,
`\EE`, `\AA`, `a ~> b`, `a -+-> formula`.

---

## Corpus

`cfg-val` 27 → 35, all captured from the pin and all green on the first run:

| case | code |
|---|---|
| `val-mod-sub-ok` | ok — a valid per-module override |
| `val-mod-sub-rhs-after-lhs` | 2223 |
| `val-mod-sub-undefined` | 2224 |
| `val-mod-sub-nargs` | 2225 |
| `val-mod-sub-not-in-spec` | 2226 |
| `val-mod-unknown` | 2245 |
| `val-inv-oprcd` | 2230 with an operator-record body |
| `val-sub-temporal` | 2281 with the EC 2261 addendum |

`gen-cfg-val-tests.py` now stages **every** `*.tla` in a case directory into the
oracle's temp dir, not just `A.tla`; the Hoon side already globbed them.

Shards re-run green: `cfg-val` (35), `sem`, `cfg`, `cfg-runspec`, `mc`, `job`,
`spec-decomp`.

---

## Found on the way, NOT taken here

`job.hoon:1100` still typed-rejects a SPECIFICATION-form config in the **job
kernel** — `unsupported: SPECIFICATION form config (deep processConfigSpec, unit 5
residue)` — although R1.8.1 landed the decomposition and the console path
(`check:check`) runs it. This is the same family as R1.8.3's residue: the job
kernel's continuation does not carry SPECIFICATION-form state, which is also why
its sliced liveness report drops the 2257/2259 hint and passes `'Next'` for the
root action name. All three are one continuation-shape change and belong to
R1.8.3 together; folding them into this unit would have paid for that change
twice. No `cfg-validate` or `check-opt-cfg` residue text cites it — it is
`cfg-runspec`/kernel scope.
