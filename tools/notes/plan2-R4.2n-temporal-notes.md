# R4.2n: temporal formulas the port refused (2026-10-12)

**Status: DONE.** Of the 25 census-r2 rows refused with "TLC cannot handle
the temporal formula", plus HourClock2 and Barrier (R4.P7):
- 12 now agree with the manifest;
- 7 now run (every manifest state reached in 6 of them) and are limited by
  liveness-phase time at 300 s;
- 6 have moved to another row's cause;
- 4 large models were not run (left for R4.3).

## What the 25 were

Measured from the formulas themselves:
- **~19: a bounded quantifier in a temporal formula.** Mostly quantified
  fairness, `\A p \in S : WF_v(A(p))` (MultiCarElevator, Prisoners ×5,
  ReadersWriters, the allocator specs, InnerSequential/Serial, ACP_NB,
  KVsnap); also `\A n \in 1..12 : []<>(hr = n)` (LiveHourClock) and
  `[](\E s \in 1..N : …)` (bcastFolklore).
- **6: a property through an INSTANCE** (`P!Spec`, `INSTANCE M`):
  MCAlternatingBit, YoYo ×2, VoucherIssue, glowingRaccoon ×2, LockHS.

## Fixes

1. **Bounded quantifiers** (`lib/temporal` `+quant-of`):
   `Liveness.astToLiveAppl` OPCODE_bf/be.
   - The domain is enumerated with no state.
   - The body is translated per binding; the kids are conjoined (`\A`) or
     disjoined (`\E`). An empty domain gives TRUE / FALSE.
   - At or below action level the result becomes a leaf of the whole node.
   - Failures follow tlc2's `catch`: EC 2213 above action level (with the
     cause, for `\A`), else a leaf.
2. **INSTANCE substitutions in the converter** (`+substin-of`):
   SubstInKind. Each substitution binds lazily (`getVal(…, false)`): a value
   if it evaluates, else the expression, call-by-name.
3. **Leaf bindings.** `%act` and `%enabled` leaves carry `ctx`/`nsub` as
   `%state` already did. `actx` records the bindings the translation itself
   introduced: quantifier variables, substitutions, and an expanded
   operator's formals. Every leaf captures them, and `lib/liveness`
   `+leaf-env` applies them to every leaf kind.
4. **Leaf equality is span AND bindings.** tlc2 tags every leaf occurrence
   (`tagExpr`), so the per-element copies under a quantifier are distinct;
   comparing spans alone merged them.
5. **`processConfigProps` decomposition** (`lib/check` `+prop-parts`,
   `+rewrap`, `+bin-properties`).
   - A PROPERTY is split through `$SubstIn`, LET, zero-arity definitions,
     `/\` and `$Nop`, and each part is binned on its own. Each part is
     re-wrapped in the wrappers it was found under (`Specs.addSubsts`).
   - Part names follow tlc2: a definition's name; a conjunct's location
     (`conj.toString()`), in the defining module.
   - A `[]P` whose `P` is a bare operator name is reported under `P`
     (measured: `Invariant Inv is violated`).
   - EC 2255 warns per state-level PROPERTY definition, not per part
     (`+swarn-names`).
   - "Genuine temporal" (the SYMMETRY warning) is the temporal bin being
     non-empty.
6. **EC 2269** `Computed N initial states...` (`+init-progress`), printed
   for each power of two p with 2 <= p < n. The port never printed it, and
   no corpus case had three initial states before this unit.
7. **Parametrized action labels** (`+act-sig`): `<Inc(1) …>`,
   `<Op(1,"a") …>`, from the action operator's formals in its context, as
   `Action.getLocation` does. The port printed `<Inc …>`. Coverage labels
   keep no arguments, as at the pin.

## Defects found on the way (pre-existing, now reachable)

8. **Infinite recursion on `x <- x`** (`lib/node-eval` `+self-ref`). An
   unnamed `INSTANCE M` substitutes M's variables by name; chasing that
   call-by-name binding re-read itself forever. It exhausted the loom inside
   one job slice and **crashed the ship** (MCAlternatingBit, 2026-10-12).
   `+deref-sem` had the guard; the evaluator's lookups did not.
9. **State-dependent substitutions bound eagerly** (`+bind-substs`).
   `y <- x % 2` was evaluated to a value, so the inner `y'` found no `y` in
   the successor. It is now also bound lazily through `psub`, as tlc2's
   LazyValue. An inner CONSTANT still reads the value.
10. **Fairness on an action with a state-dependent argument was vacuous**
    (`+bind-psub`). The solver evaluated `Return(c, alloc[c])`'s argument
    with no current state; ENABLED read the failure as FALSE, so
    `WF_vars(Return(c, alloc[c]))` constrained nothing. SimpleAllocator
    reported three properties violated where tlc2 finds no error: a WRONG
    ANSWER. Arguments are now evaluated in the solving env (`+senv`).
11. **Nested-instance members** (`lib/semantic` `g-instance`).
    `stagesInstance!cleanInstance!primerDepleted` was never generated (only
    operator definitions were imported), and a member naming it referenced
    nothing. The instanced module's own instance units are now imported
    recursively, wrapped in the outer substitution and qualified as
    siblings.
12. **Actions inside a LET lost the LET** (`+get-actions-in`).
    `+get-actions` descended through a LET and dropped its definitions, so
    `x' = b` failed "undefined operator: b" (MultiCarElevator's
    `CallElevator`). Each extracted action is re-wrapped in its LET,
    labelled at the body's span (the pin's location).
13. **DNF products held nested conjunctions** (`+splice-conj`). tlc2's
    `LNConj.addConj` splices them; the port's distribution appended them
    whole, and `+classify` raised EC 2214 on `\A c : SF_v(A(c))`
    (MultiCarElevator, the allocator specs).

## Tests (mc corpus, all pin goldens; mc 107 → 120)

- `live-forall-wf`, `live-forall-wf-viol` (VARIES: the pin drew two
  different lassos in two runs), `live-forall-prop`, `live-forall-sf`,
  `live-wf-statearg`.
- `prop-conj-decomp`, `prop-conj-viol`, `prop-instance-refine`,
  `prop-instance-same-names`, `prop-box-named`.
- `act-label-params`, `let-action-trace`, `let-action-live`.

## Census (the R4.2n rows; `--wall 300`; rows in `census-r42n.txt`)

| model | now | manifest |
|---|---|---|
| Prisoners, Prisoner, PrisonerLightUnknown, PrisonerSolo, PrisonerSoloLightUnknown | success | agree (214, 16, 62, 2, 4) |
| LiveHourClock, HourClock2, Barrier, stages, MCAlternatingBit | success | agree (12, 12, 64, 83, 240) |
| SimpleAllocator | console: agree (no error, 1,633 / 400); job: limited 300 s in liveness | 400 |
| ElevatorLivenessMedium, AllocatorRefinement, SchedulingAllocator, VoucherIssue, ACP_NB_TLC | limited 300 s, every state reached | 4122, 1690, 1690, 4199, 4284 |
| AllocatorImplementation | limited 300 s, 4,645 of 17,701 | |
| LockHS | limited 300 s, 0 states | → R4.3 |
| ReadersWriters/MC | `undefined identifier: NumActors` (`.cfg` `<-` not applied) | → R4.2v |
| MCInnerSequential | `Seq` as a value | → R4.2m |
| MCYoYoNoPruning, MCYoYoPruning | SUBSET too large to enumerate | → R4.2i |
| product | `incomplete next state` (`UNCHANGED doubles`, a definition naming variables) | → R4.2p |
| MCKVsnap, ElevatorLivenessLarge, MCInnerSerial, bcastFolklore | not run (large) | → R4.3 |

## Residue (recorded, not fixed here)

- tlc2 also UNROLLS a `\A` over a constant set inside a PROPERTY, and
  inlines a parameterized instance's arguments (`processConfigProps`
  OPCODE_bf / `getOpContext`). Here such a property stays whole, and the
  converter expands the quantifier. The verdict is the same, but a
  `\A n : []P(n)` routes to the liveness engine rather than to per-element
  invariants.
- EC 2213's location names the ROOT module for a span in another module
  (`+loc-leaf:tp`). Seen on KVsnap, ReadersWriters and product.
- SANY warnings (e.g. "Multiple declarations") are not printed in the
  console check output.
- The liveness phase is slow on several Examples models (six of seven
  limited rows have every state); for R4.3.

Addendum: `prop-instance-nested` (two instance levels, all inner modules;
pin golden) pins fix 11 — mc 121. The nested members travel in
`g-instance`'s new `nds` field and reach evaluation through `imports`
(`+nested-defs`), so SemDump and the level check never see them; putting
them in the module's `defs` broke `sem` `test-sem-instnest`. `sem` 119.
