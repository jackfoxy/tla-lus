# R2.7.15a — multi-PROPERTY routing: three fixed, two frozen

```text
Sub-unit: R2.7.15a
Row: tlc-safety-assume (stays `partial`)
Shipped: the routing itself -- every property binned on its own shape, on all
  three engines, with the safety-side bins running in ONE search.
Frozen: two implied-action defects, both PRE-EXISTING, one of them a FOURTH
  defect this unit's own corpus exposed.
```

## What shipped

**`+bin-properties`** — `SpecProcessor.processConfigProps`, over the whole
list: `[]P` box-state to the invariant vector, level<=1 to the implied inits,
`[][A]_v` to the implied actions, the rest to the liveness engine. Carried on
`sctx` as `binvs`/`iinits`/`iacts` beside R2.7.12's `props`, and used by
`+check`, `+run-check` and `job.hoon`'s `do-config` — the three engines that
each had their own head-of-list test.

**Implied actions became a per-transition check.** `bfs-opts.iacts`, evaluated
at the hook `acons` already uses — an action CONSTRAINT prunes the transition,
an implied action reports it. `+implied-action-run` and `+first-bad-step` are
retired; `+first-bad-action` (R2.5's, written for DFID) is now the predicate
for both engines.

**One search, both kinds.** A spec declaring a safety-side property and a
temporal one runs the safety pass first and, if it completes clean, the
liveness engine — `ModelChecker.doNext` returning on a violation, generalized.

**Precedence, and the attempt that got it backwards.** The first version ran
the implied-action check BEFORE `+register-in`. `inv-prop-action` caught it:
an INVARIANT and an implied action false on the same transition must name the
INVARIANT, and the counts must include the registered successor. Moving the
check after the invariant check fixed both at once — the order is tlc2's own,
and its DFID comment states it: *"the INVARIANTS first ... then the IMPLIED
ACTIONS on EVERY transition"*.

Green: `prop-box-viol`, `prop-box-last`, `prop-box-then-live`,
`prop-init-viol`, and the pre-existing `inv-prop-action`,
`implied-act-{pass,viol}`, `implied-init-{pass,viol}`. **`prop-box-viol` and
`prop-box-last` are the same two properties in opposite orders and now agree**
— the order-independence this row is about.

## What is frozen, and why both are pre-existing

**`prop-act-viol` — the queue count.** 1 where the pin says 0. `+register-in`
checks invariants BEFORE the enqueue (*"a violating state is counted but never
enqueued"*), and the new check sits after `+register-in` returns, so the
successor is already on the queue. The fix moves the check INSIDE
`+register-in`, between the invariant check and the enqueue, which needs
`prev` threaded in.

**`prop-act-ok` — a FOURTH defect, and it is latent in DFID too.** `[][A]_v`
is checked as `A` alone, not as the square action `A \/ UNCHANGED v`, so a
STUTTERING step reports a violation tlc2 permits. `+implied-action-inner`
returns `$SquareAct`'s first argument and drops the subscript; both the
retired `+first-bad-step` and DFID's `+first-bad-action` consumed it that way.

**No corpus case could show it**: every existing implied-action spec has a
next-state relation with no stuttering step. `prop-act-ok`'s `Next` has
`x' = x`, which is why the matrix found it. The fix carries the subscript
beside the body (`[name body sub]`) in both `bfs-opts.iacts` and
`dfid-opts.iacts`, and answers FALSE only when `A` fails AND the subscript
CHANGED.

That is the fifth instance this release of a rule that was right on a corpus
uniform in the deciding dimension.

## Also still owed

The job kernel routes no IMPLIED INIT. `iinits.bins` is computed and unused
there; the console's `+implied-init-run` owns that diagnostic and the kernel
never had it. Pre-existing, narrowed around rather than closed, and named at
the routing site.

## Evidence

**323 arms, `ok=%.y`, 0 FAILED** across `mc` (98 cases), `job`, `dfid`,
`safety-gen`, `inv-constraints`, `liveness-message`, `liveness-lasso`,
`trace`, `cfg-runspec`. Ledger unchanged at **132 terminal / 2 owed**.
