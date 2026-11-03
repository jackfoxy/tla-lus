# R4.2: evaluator scope fixes found by the error-row re-run (2026-10-13)

Re-running every census row whose latest result was an error (55 rows;
`census-rerun-errors.txt`, `census-rerun-rest.txt`) surfaced four evaluator
defects. Each is general, not specific to its model.

1. **Arguments evaluated in the env being extended** (`lib/node-eval`
   `+bind-params`, `+bind-substs`, `+bind-psub`; `lib/temporal`
   `+bind-formals`). Formals were bound one by one and each later argument
   evaluated after them, so `Attacks(Append(queens, c), i, Len(queens) + 1)`
   read `queens` as the formal the first argument had just bound. N-Queens
   failed "index 3 of tuple <<1, 1>>". Every argument and substitution is
   now evaluated in the CALLER's env, as tlc2 does
   (`getVal(expr, c, …)`).
   - Test: mc `args-caller-env` (pin golden). N-Queens N = 4 now equals the
     pin exactly (2,970 / 785, depth 16).
2. **LOCAL definitions of an extended module were never imported**
   (`lib/semantic` `+ext-defs`). `Functions` folds through `MapThenFoldSet`
   from its `LOCAL INSTANCE Folds`, Bitwise's `^^` through a LOCAL `Xor`;
   the bodies that name them resolved to nothing. They are imported after
   every exported definition, under names nothing else took.
3. **The override registry was keyed by the REFERENCE name**
   (`+eval-user` and siblings). A definition reached through an operator
   parameter (`MapThenFoldSet(op(_,_), …)` given `+`) was looked up as
   `Naturals!op`. The key is now the definition's own name (`+bnm` of
   `name.def`).
4. **btree exhausts the loom in one slice** and crashed the ship (not yet
   localized; `timed-out.json`, R4.2aj).

## Census effect (`census-rerun-errors.txt`, `census-rerun-rest.txt`)

- now agree: MCInternalMemory, MCWriteThroughCache, MCYoYoNoPruning,
  MCYoYoPruning, EWD840_json; N-Queens (console; the runner re-run is
  pending);
- match their expected safety failure: Hanoi_anim, Hanoi Model_1;
- **new divergences**: SDP_Attack_New_Solution_Spec (expected success) and
  SDP_Attack_Spec (expected safety failure) both report a liveness failure
  → R4.2ak.
