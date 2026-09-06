# R2.3.4 — INVARIANT and PROPERTY in one config

`op-check-exhaustive` → **parity**. `tlc-safety-invariant` keeps its `partial`
for R2.7.1 alone. Owed 13 → 12.

## R2.3.0's correction held

The plan said this was "a typed rejection at `%config`; tlc2 runs both, the
port must too" — implying only the kernel refused. R2.3.0 measured otherwise
and was right: **neither path could do the work.**

- the **liveness** branch built its graph with `~` for invariants — they were
  simply not checked;
- the **box-state** branch *substituted* the property for them
  (`~[[u.pp.c u.binner]]`), dropping the config's own.

So the unit was engine work, not a deletion. A unit that had started by
deleting the rejection would have shipped a confidently wrong answer: the
combination would have "run" while silently not checking the invariant.

## What the engine needed

Almost nothing new — `+bfs-step` already checks `invs` and stops at the first
violation. The work was **carrying the list** to the two places that dropped
it, and then handling the outcome that became reachable:

| path | before | after |
|---|---|---|
| console liveness (`+check`) | `~` for invs | `invs.c`, and `%inv` joins `%deadlock`/`%error` in the pre-emption set |
| console box-state | `~[[pp binner]]` | `(weld invs.c ~[[pp binner]])` |
| kernel liveness (`%live %build`) | `~` for invs | `invs`, and `%inv` routes to `+finish-bfs` instead of `'internal: unexpected graph outcome'` |
| kernel box-state | `~[[pp binner]]` | `(weld invs ~[[pp binner]])` |

The `%live` kont gained `nl` (the whole-Next label) because `+finish-bfs`
renders a safety trace and needs it.

## A safety violation pre-empts the temporal check

`ModelChecker.doNext` returns on the violation and `modelCheck` never reaches
the temporal pass. Measured at the pin: `INVARIANT Tight` + `PROPERTY Live`
prints the safety trace and counts and **no temporal verdict at all**. Same
precedence R1.6.6 established for deadlock.

## Three orderings, all measured rather than assumed

1. **Config invariants before a box-state property.**
   `processConfigInvariants()` fills `invVec` first; `processConfigProps`
   *appends* a `[]P` with state-level P to that same vector
   (`SpecProcessor.java:1552`). Pinned with `INVARIANT Tight` +
   `PROPERTY BoxTight`, **both false at the same state** — tlc2 names `Tight`.
   A test where only one is false proves nothing about order; this one does.

2. **Invariant before implied init, on an initial state.**
   `ModelChecker.doInit` is **state-major**: for each initial state it checks
   every invariant (EC 2107) and only then every implied init (EC 2108).
   `+implied-init-run` checked the property first and reached invariants later
   through `+safety-run`, so it named the property. Pinned with
   `INVARIANT FalseInv` + `PROPERTY FalseProp`, both false at `x = 0` — tlc2
   names `FalseInv`, and still prints the EC 2255 state-level warning first.

3. **Invariant vs implied action: the shorter behavior, ties to the invariant.**
   Both measured: `INVARIANT Zero` + `PROPERTY NoStep` both false on the
   *same* transition names `Zero`; `INVARIANT Tight` (false at x=2) with
   `NoStep` (false on the first step) names `NoStep`.

   **Residual, recorded rather than hidden**: at equal depth but different
   queue position tlc2's order is its BFS order, while `+first-bad-step` scans
   the fingerprint map, not the queue. This unit narrows that approximation —
   ties now resolve as tlc2 resolves them — without removing it.

## Two kernel/console divergences observed but NOT fixed here

Worth writing down, because they are invisible until a spec uses them and this
unit was the first to look at the kernel's liveness options closely:

- the kernel's liveness graph build passes `~` for **state and action
  constraints** and `~` for symmetry perms, where the console passes
  `cons.c`/`acons.c`/`perms.c`;
- it passes `|` for **deadlock**, where the console passes `ddl.c` — so
  R1.6.6's deadlock-pre-empts-liveness precedence does not hold on the kernel
  path.

Neither is R2.3.4's row, and neither is exercised by the current
kernel-vs-console tests (their liveness spec has no constraints and cannot
deadlock). Left for a unit that owns the kernel liveness options.

## Evidence

Seven new `mc` corpus cases, all byte-exact on the first run:
`inv-prop-inv-wins`, `inv-prop-prop-runs`, `inv-prop-box-order`,
`inv-prop-box-prop`, `inv-prop-both-ok`, `inv-prop-init`, `inv-prop-action`.
Plus seven job arms including two `+same-report` kernel≡console comparisons.

## Touched

`desk/lib/check.hoon` (liveness opts + pre-emption, box-state opts,
`+implied-init-run`, `+implied-action-run`), `desk/lib/job.hoon` (rejection
deleted, box-state + liveness opts, `%live` kont gains `nl`, `%inv` routed to
`+finish-bfs`), `desk/test-data/mc/inv-prop-*` + regenerated
`desk/tests/lib/mc.hoon`, `desk/tests/lib/job.hoon`,
`desk/doc/parity-manifest.md`, `desk/doc/compatibility.md`.
