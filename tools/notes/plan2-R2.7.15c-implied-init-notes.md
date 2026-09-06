# R2.7.15c — the implied-init bin: three sites, and the head-of-list checklist

```text
Sub-unit: R2.7.15c
Row: tlc-safety-assume (partial -> parity)
Planned: route the IMPLIED INIT on `+run-check` and the job kernel, and fix
  the console's own head-of-list routing (the amendment).
Found: those three, plus a fourth site the same bin had been hiding -- a
  clean implied init short-circuited the WHOLE rest of the routing.
```

## The rule, and why it is not an invariant

tlc2 checks a level<=1 PROPERTY only while computing the INITIAL STATES
(`Tool.getImpliedInits`, `ModelChecker.doInit:1199`). Folding it into the
invariant vector would check it at every state and report violations at states
tlc2 never tests, so the check has to sit where `doInit` has it — per initial
state, after the INVARIANTs of that same state (EC 2107 before EC 2108, which
is `inv-prop-init`'s measurement, R2.3.4).

That shape is now one arm, `+first-bad-init`, shared by all three engines. It
answers `[%inv name st]`, `[%prop name st]` or `%|` for an evaluation error:

  * the CONSOLE renders both codes from it (`+init-viol-lines`);
  * `+run-check` and the JOB KERNEL act on the `%prop` half and leave `%inv`
    to their own search, which reaches the same initial state and reports it
    with the counters it actually accumulated;
  * `%|` is nobody's violation — every caller falls through and lets the
    engine raise it as the run's own typed failure, which is
    `+first-violated`'s rule. The retired `+implied-init-run` reported an
    evaluation error AS a violation, naming a property that had not been
    shown false.

## The four sites

**(1) `+run-check`** computed `iinits` and dropped it, completing `%ok`. It
now answers `[%property name %.y]` — the `initial` flag R2.7.1 added for
exactly EC 2108 — with ZERO statistics, because a run that aborts during
initial-state computation reports none. That is the same thing the console
prints, which is no counts at all.

**(2) The job kernel** likewise. It seals through `+finish-arts` with the
console's own lines as the `%report` artifact and the single offending state
as the `%trace`. The EC 2255 state-level warning rides `swarn`, the channel
R2.3.5's EC 2145 warning uses, and `+finish-arts` already prepends `swarn` to
the report — so the artifact is the console's output byte for byte, which is
what `test-implied-init-kernel-report-matches-console` asserts.

The check sits AFTER the `%dfid` and `%simulate` branches deliberately: DFID
checks its own implied inits state-major in `+dfid-cursor-init` (R2.5), and
reaching this from there would check them twice.

**(3) The console routed only the FIRST implied init.** `+check`'s branch was
`?^ iinits.c (implied-init-run c name.i.iinits.c body.i.iinits.c)` — the head
of the bin — and `+implied-init-run` took one name and emitted one EC 2255
warning. Measured at the pin (`prop-init-second`): with `PROPERTY InitOk`
(holds) followed by `PROPERTY InitBad` (fails), tlc2 warns about BOTH and
reports `InitBad`; the port warned once, checked once, and completed clean.

**That is the FIFTH instance of the head-of-list pattern, and the SECOND time
it survived a fix aimed at it** — R2.7.15b's defect (4) was the same thing one
layer down. It is a checklist item, not a lesson: after fixing a head-of-list
assumption, GREP THE WHOLE BIN for siblings before calling it done.

**(4) A clean implied init short-circuited the rest of the routing** — the one
this unit did not plan for, and the bin had been hiding it. `+implied-init-run`
ended `[warn (safety-run c | 0)]`, so a spec whose implied init HELD went
straight to a bare safety search: a box-state property, an implied action or a
temporal property declared beside it was never checked. Measured
(`prop-init-live`): `PROPERTY InitOk` (holds) with `PROPERTY Live` (`<>(x = 9)`
on a stuttering Next) — the pin reports `Temporal property Live was violated`,
the port completed `No error has been found.` The routing now falls THROUGH
into the same three-bin branch every other run uses, which is also how the
`-seed` that `safety-run c | 0` was discarding reaches the search.

## Evidence

Two `mc` cases added and pinned at the oracle, both of which fail against the
pre-unit port:

| case | shape | pin |
| --- | --- | --- |
| `prop-init-second` | two implied inits, the FAILING one declared second | two EC 2255 warnings, then `Property InitBad is violated by the initial state:` |
| `prop-init-live` | an implied init that HOLDS beside a temporal property that fails | one warning, then the liveness counter-example and the counts |

Four `tests/lib/inv-constraints` arms for `+run-check` (violated, declared
second, invariant-wins, holds-and-the-search-follows) and two
`tests/lib/job` arms for the kernel (the typed result + one-state trace, and
the report matching the console).

`+implied-init-run` is RETIRED; `+first-bad-init` and `+init-viol-lines`
replace it, and `+init-viol-lines` takes explicit arguments rather than an
`sctx` because the kernel calls it and never builds one.

**Ship runs**: `ok=%.y`, 0 FAILED, in two passes over ELEVEN shards --
`mc` (102 cases) / `job` / `inv-constraints` / `dfid` / `safety-gen` / `trace` /
`liveness-verdict` / `cfg-runspec`, then `liveness-lasso` /
`liveness-message` / `clay-load`. `gen-mc-tests.py`'s `SKIPS` stays EMPTY, and
regenerating the whole `mc` corpus moved no other golden. Ledger **133
terminal / 1 owed** (`tlc-eval-node`, R2.7.16); `check-portmap.py` coherent
after the quoted tally in `compatibility.md` was moved 2 -> 1.
