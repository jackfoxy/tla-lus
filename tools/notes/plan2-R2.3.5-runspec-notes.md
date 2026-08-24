# R2.3.5 — `cfg-runspec`'s three named non-ports

Two of three landed. `cfg-runspec` stays **`partial`** for the third, which is
now refused **by name** instead of by accident. Owed stays 12.

## Measured first

All three were pinned against tlc2 before a line of Hoon changed, and the port
run compared. That is what made the split obvious:

| case | port, before | diagnosis |
|---|---|---|
| `spec-sub` | verdict and counts **already correct**, warning absent | purely additive |
| `spec-lazy` | `Error: variable is unassigned in the current state: x` | decomposition gap |
| `spec-inst` | `Error: the SPECIFICATION has no next-state relation` | **evaluator** gap wearing a decomposition error's clothes |

## (a) Subscript-coverage warning — EC 2145

`[A]_v`'s subscript must mention every declared state variable or TLC's
analysis is unsound: a variable outside it is never compared, so a step that
changes it reads as stuttering. tlc2 **warns per uncovered variable and
proceeds** (`SpecProcessor.java:1327-1339`), which is what makes it a warning
worth having rather than a rejection — the run still produces a result, it is
just a result about a smaller relation than the author wrote.

`+subscript-vars` ports `SpecProcessor.SubscriptCollector`. The rule that
matters, and that a naive port would get wrong: a bare variable counts, a
**tuple** recurses into its members, a 0-ary user operator expands to its body,
and **every other built-in is IGNORED rather than descended into**. That is the
Java's own comment ("Variables that appear in other kinds of expressions are
ignored"), and it is why `<<x, y>>` covers both variables while `x + y` covers
neither.

Plumbing: the warnings ride on `sctx.swarn` (console) and `jobstate.swarn`
(kernel). **`jobstate`, not a kont** — every terminal path renders a report and
they share no continuation shape, so `+finish-arts` is the one place they all
meet. One field, one write, one read.

## (b) LazyValue parameter inlining — and the regression that shaped it

`MyInit(Init) /\ [][Next]_vars` (Github1244's shape). tlc2 calls `getOpContext`
on the parameterized operator and recurses into its body; when decomposition
reaches a formal parameter the lookup yields a `LazyValue` — a closure pairing
the argument expression with its call-site context — which it unwraps and keeps
decomposing.

**The first cut ported that directly** and was wrong. `+decompose-spec` carried
the context as a `psub` map (formal → argument) and inlined ANY parameterized
operator whose arity matched. `mc` and `spec-decomp` both went green on it.
**Tier 2 caught it**: `AssignmentInitNeg` regressed to
`Error: undefined identifier: var` — a spec that had been *passing* by falling
through to the level check and letting `node-eval`'s own operator application
bind the formals properly.

The reason is structural, and it is why the Java can do something the port
cannot: tlc2's `Action` carries the `Context`, so a formal left inside an
emitted leaf still resolves at evaluation time. **The port's leaves carry no
context.** Inlining a body that decomposition does not fully reach emits a node
with an unbound formal, and evaluation dies on it.

So the shipped rule is narrower and sound: inline exactly `Op(A)` where
`Op(i) == i` — the body IS the formal, so the apply simply *denotes* `A` and
decomposition continues on `A`, with no context to lose. That is Github1244's
shape. Every other parameterized operator is left to the evaluator, which
already handles it correctly. `psub` is gone; it bought nothing the narrow rule
does not.

**The lesson is about test scope, not about inlining.** The two shards that
cover this arm directly (`mc`, `spec-decomp`) both passed the broken version.
Only the real-spec batch saw it. A decomposition change is exactly the kind of
edit whose blast radius is wider than its unit tests.

## (c) INSTANCE substitution — refused by name, and why

Peeling `$SubstIn` is trivial: `+substin-parts` already returns
`[mod names exprs inner lvl at]`, and `+rewrap-substin` already re-wraps —
the port has both halves of `Specs.addSubsts`.

**The blocker is evaluation, not decomposition.** `lib/node-eval` has no
`$SubstIn` case. An inner module's `v` must resolve through `v <- x` to the
**outer state's** binding — a variable *renaming* frame on `eenv`, touching
variable reads, primed reads, assignability and UNCHANGED — not a value
binding. Constants substitute easily; variables do not. That is unit-6 engine
work.

So `+decompose-spec` now says exactly that, where before the conjunct fell
through to `the SPECIFICATION has no next-state relation` — a message true of
nothing the caller wrote. R2.1 doctrine applied to a *deferral*: refuse by
name, not by side effect.

`tests/lib/spec-decomp` asserts the rejection, so the non-support is **tested**
rather than merely documented. The `spec-inst` mc fixture was removed rather
than left red: a permanently failing corpus case trains people to ignore the
shard.

## Evidence

`mc` gains `spec-sub` and `spec-lazy` (byte-exact against the pin);
`spec-decomp` gains `test-lazy-parameter-inlining` and
`test-instance-substitution-refused-by-name`.

Two things worth keeping. The first cut of the warning used a wet
`turn`/`skip` and `fuse-loop`ed the zuse-408 compiler against
`+decompose-spec`'s own recursive product type — the same trap
`+render-outcome` already records for its initial-state branch; rewritten as an
explicit loop (`+subscript-warns`). And tier 2 is what caught the inlining
regression above, after the two shards covering the arm had gone green.

## Touched

`desk/lib/check.hoon` (`+decompose-spec` signature + `psub` + `$SubstIn`
rejection + EC 2145, new `+subscript-vars` / `+subscript-warns`,
`+resolve-targets`, `sctx.swarn`, `+check` prepend), `desk/lib/job.hoon`
(`jobstate.swarn`, `+finish-arts`, `+do-config`),
`desk/test-data/mc/spec-{sub,lazy}` + regenerated `desk/tests/lib/mc.hoon`,
`desk/tests/lib/spec-decomp.hoon`, `desk/doc/parity-manifest.md`.
