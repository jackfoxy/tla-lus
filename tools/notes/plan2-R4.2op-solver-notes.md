# R4.2o + R4.2p: operator arguments and UNCHANGED in the solver (2026-10-12)

## R4.2o: `$OpArg` (operator-valued INSTANCE substitutions)

TwoPhase declares `CONSTANT XInit(_), XAct(_, _, _)` and is instanced by
MCTwoPhase, which defines both. The unnamed `INSTANCE TwoPhase`
substitutes them by operator arguments (`$OpArg`). Three gaps, all in
`lib/node-eval`:
- `+bind-substs` evaluated an `$OpArg` substitution as a value. It now
  binds the operator in `ops` (`+resolve-oparg`), as `+bind-psub` binds an
  operator parameter.
- `+solve` / `+psolve` expanded only `%user-op` applications, so
  `XInit(x)` was filtered as a boolean with `x` unassigned. A CONSTANT
  operator bound to an operator (this, or a config `F <- G`) now expands
  like a user operator.
- `+bind-psub` evaluated a PRIMED state-variable argument (`XAct(0, x,
  x')`), reading a successor that did not exist yet. It is bound by name,
  as tlc2 binds every argument lazily, so `xNext = xInit` assigns `x'`
  (`+assignable-sem` chases the binding).

Test: mc `inst-oparg` (pin golden).

## R4.2p: UNCHANGED of a definition / nested tuple

`+unchanged-vars` took a variable or ONE flat tuple of variables.
`UNCHANGED vars` with `vars == <<x, y>>`, `UNCHANGED <<cycle, doubles>>`
with `doubles` a definition, and nested tuples all named nothing. Those
variables went unassigned and the successor was "incomplete next state".
It is now recursive, as tlc2's `processUnchanged` is: variables, tuples at
any depth, zero-arity definitions (fuel-bounded), call-by-name and LET
chased.

Test: mc `unchanged-def` (pin golden). No corpus case had used UNCHANGED
on a definition before.

Also R4.2o: **`INSTANCE M` brings what M EXTENDS** (`lib/semantic`
`+nested-defs` → `imports`). TwoPhase EXTENDS Naturals and MCTwoPhase does
not, so `(p + 1) % 2` in the instanced body named no `%`. The instanced
modules' EXTENDS closure is imported under plain names; the root's own
EXTENDS still wins. Test: mc `inst-ext-closure`. mc 129 → 132.

## Census (`census-r42p.txt`)

| model | now | manifest |
|---|---|---|
| MCTwoPhase | **success** | agree (4) |
| product (glowingRaccoon) | **success** | agree (305) |
| bcastByzNoBcast | **success** | agree (45) |
| aba_asyn_byz, bcastByz, nbacg_guer01, EnvironmentController | run, limited 300 s | |
| cf1s_folklore | run, `limited states` (20,001) | |
