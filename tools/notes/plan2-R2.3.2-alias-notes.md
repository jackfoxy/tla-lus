# R2.3.2 — ALIAS: trace rendering through an alias

Closes the frozen tier-2 `Github746` census entry. `cfg-alias` → **parity**.

## What tlc2 does

`Tool.evalAlias` evaluates the ALIAS expression and calls `.toState()` on the
resulting record: **the record becomes the state**, and the ordinary state
printer renders it. So no renderer signature had to change shape — the alias is
applied *before* rendering, not threaded *through* it.

The alias is evaluated against **both** the current state and its successor
(`eval(getAliasSpec(), Context.Empty, current, successor, …)`), so a primed
reference resolves against the successor. Where there is no successor the state
is paired with **itself**, which is what makes `x' # x` print FALSE on the last
state of a trace and TRUE everywhere else — the property that proves the
pairing rather than merely matching values.

On an evaluation error tlc2 does not fail the run: it returns the original
state plus an `_ALIASEvalError` field carrying the message. Reproduced — a
trace that cannot render is still a trace.

## Two insertion points, not one

R2.3.0 measured `+state-pairs` as the single chokepoint. That held for the
numbered trace, and it is where `+render-trace` and `job.hoon`'s
`+trace-states` both apply the alias. **It missed a second one**: the
initial-state violation prints through the alias too and never goes through
`+render-trace` at all.

- EC 2107 (`TLC_INVARIANT_VIOLATED_INITIAL`), `ModelChecker.java:1187`:
  the message is built from `evalAlias(curState, curState)`.
- EC 2108 (`TLC_PROPERTY_VIOLATED_INITIAL`), `ModelChecker.java:1199`:
  identically, and that is the port's `+implied-init-run`.

Both render **inline** in `check.hoon`, which is why a chokepoint search over
`+state-pairs` did not surface them. `test-mc-alias-init` (a rename of
`Github746`) pins the EC 2107 case.

## Field ORDER had to come from the semantic node

tlc2 prints the record's **constructor** order (`v, doubled, moved`). The
port's `%rec` value **normalizes its field list at construction**
(`value.hoon:743`), so the evaluated record can only ever report alphabetical
order — the information is gone before `+alias-state` sees it. Java's
`RecordValue` normalizes lazily, so `toState()` still sees source order.

`+alias-state` now reads the order off the alias's own `$RcdConstructor` node
via `+rcd-pairs:semantic`, using the evaluated record for **values alone**, and
falls back to the normalized order when the node names no fields (an alias that
is not a bare constructor — one built by a conditional, or by an operator
call). The fallback is guarded on set-equality of the two name lists, so a
partial match can never silently drop or invent a binding.

## Where ALIAS is refused, and why that is not a regression

R1.8.6 refused ALIAS wholesale. R2.3.2 lifts that for every **safety** path —
plain invariants, deadlock, implied-init, implied-action, and `[]P` box-state —
and **narrows** rather than removes the refusal on the two paths whose trace
renderers take no alias:

- **temporal PROPERTY** (the lasso): `+live-report` renders its own prefix and
  cycle. tlc2 aliases them (`LiveWorker.java:876-972`); the port would print an
  unaliased trace, which is exactly the silent wrong trace the R1.8.6 rejection
  existed to prevent.
- **simulation mode**: same shape, `SimulationWorker.java:163`.

Both guards sit at their own branch, **not** at the config gate, because a
`[]P` box-state PROPERTY runs on the SAFETY path and *does* render the alias
correctly — a `?=(^ pp)` guard at the gate would over-refuse it. Same shape as
R2.3.1's VIEW refusal, one level more precise.

## The census entry, and what the projection could not see

R1.8.8 censused `Github746` as a tier-2 `tlc-batch` divergence when R1.8.6 made
the silent ignore a typed rejection. The safety batch now agrees **14/14** and
the entry is retired.

Worth keeping: the projection never saw the actual bug. `tlc_projection`
captures trace lines only after the two counter-example markers, and an
initial-state violation is announced by neither — so the spec agreed on
`[verdict, counts, depth]` while disagreeing on every state line beneath it.
The rejection is what made it visible.

## Left alone, deliberately

`gen-stream-tests`' own `+binds` (R1.1.R1). `StreamDump.java:45` strips the
`/\ ` prefix and that differential compares successor **order**, not console
rendering; an alias applied there would corrupt a projection with nothing to do
with traces.

## Touched

`desk/lib/check.hoon` (`+alias-state` field order, EC 2107 branch of
`+render-outcome`, EC 2108 branch of `+implied-init-run`, the liveness
refusal), `desk/lib/job.hoon` (blanket rejection → two narrow ones, `alb`
resolution, `al` on the `%bfs` kont, `+finish-bfs` → report + typed trace,
`+trace-states`), `desk/test-data/mc/alias-init/` + regenerated
`desk/tests/lib/mc.hoon`, `tools/gen-tier2-tests.py` + regenerated
`desk/tests/lib/tier2.hoon` / `desk/test-data/tier2/divergences.txt`,
`desk/doc/parity-manifest.md`, `desk/doc/testing.md`.
