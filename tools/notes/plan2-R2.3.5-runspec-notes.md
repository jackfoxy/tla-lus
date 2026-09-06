# R2.3.5 — `cfg-runspec`'s three named non-ports

**All three landed. `cfg-runspec` → `parity`.** The unit also *found* a new
residue and re-opened `semantic-graph` for it, so the owed count is unchanged
at 12 — one row closed, one opened, which is the honest accounting.

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

## (c) INSTANCE substitution — ported

The first pass refused it, on the reasoning that peeling `$SubstIn` is trivial
(`+substin-parts` and `+rewrap-substin` both existed) but *evaluating* the
peeled body needs a renaming frame `node-eval` did not have. That reasoning was
right; the conclusion — that it was too big for this unit — was not, and one
measurement settled it.

**The measurement**: a fixture using INIT/NEXT keys through `I!InitI` /
`I!NextI`, which bypasses SPECIFICATION decomposition entirely and isolates the
evaluator. It failed with `unsupported builtin operator: $SubstIn:inner` —
meaning name resolution already worked and the *only* blocker was the missing
case. That is a much smaller thing than "a renaming frame touching four
subsystems."

What it took:

- `+bind-substs` makes the same split `+bind-psub` does, and for the same
  reason: a substitution onto a bare state variable (`v <- x`) is kept as a
  **node**, so the inner module's `v' = ...` is still an assignment to the
  outer `x`; a value substitution (`k <- 3`) is evaluated once into `vals`,
  where a CONSTANT reference reads from.
- `%variable` consults `psub`, exactly as `%formal-param` already did.
- `+deref-sem` chases a substituted variable, so the action solver sees the
  renaming. Bounded, because `x <- x` would otherwise spin.
- `+unchanged-vars` derefs, so `UNCHANGED v` under `v <- x` is `UNCHANGED x`.
- `+solve` descends into a substitution in action position, binding first —
  otherwise the inner `v' = ...` is evaluated as a boolean filter instead of
  solved as an assignment.
- `+decompose-spec` peels and carries a `subs` stack, re-wrapping every leaf
  (`+add-subs` = `Specs.addSubsts`), because leaves are evaluated later and
  must still carry the bindings.
- `+subst-var-name` translates subscript names through the substitutions, or
  the EC 2145 check from (a) warns spuriously on every instanced spec — caught
  by `spec-inst-flat`, which ran correctly but emitted a bogus warning.

## The residue this unit FOUND

An instanced member that references a **sibling** member of its own module
(`SpecI == InitI /\ [][NextI]_v`) resolves to nothing: the generated `$SubstIn`
body carries a bare `InitI`, while the root `defs` map holds instanced members
**qualified** (`I!InitI`). tlc2 has no such problem — `SpecI`'s body links
straight to `InitI`'s `OpDefNode`.

**This is not a substitution gap.** Substitution works: `inst-keys` and
`spec-inst-flat` both run byte-exact. It is instance *generation*, so it is
recorded on `semantic-graph`, which owns that, and refused by name in
`+decompose-spec` — dropping it produced `the SPECIFICATION has no initial
predicate`, true of nothing the caller wrote.

Worth noting why it went unseen: **no existing `test-data/sem/inst*` fixture
has an inner definition that references a sibling.** Five instance fixtures,
none exercising the shape.

## Evidence

`mc` gains `spec-sub`, `spec-lazy`, `spec-inst-flat` and `inst-keys`, all
byte-exact against the pin; `spec-decomp` gains
`test-lazy-parameter-inlining`, `test-instance-substitution-runs` and
`test-instance-sibling-reference-refused-by-name`.

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
