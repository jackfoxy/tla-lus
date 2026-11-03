# R4.P11: state-level definitions memoized per state (2026-10-12)

**Status: DONE (smaller gain than the reference count suggested; see
Measured).** Approved at the R4.P close (plan r14).

R4.P9 found GameOfLife's `sc[<<x, y>> \in (0..N+1) \X (0..N+1)] == …`
rebuilt in full at each of its 18 references per state. Of the two
candidates (per-state memo; lazy `FcnLambdaValue`-style function values),
the memo is local to `+eval-user`. Lazy function values would change the
value representation everywhere (equality, fingerprint, DOMAIN, rendering).

## Change (`lib/node-eval`)

- `+eval-user`: a module-level (`origin` set), STATE-level (`lvl` 1)
  arity-0 definition is evaluated through `+eval-sdef`.
- `+eval-sdef`: `+eval-rs` under `~+`. The key is the whole sample (body,
  environment, carrier), so a hit is exact. Evaluation is a pure function of
  those, whatever the body does: a draw or a `TLCSet` changes the carrier,
  and that changed carrier is part of what is memoized. No purity rule is
  needed.
- `+sdef-env` makes references hit. It cuts the environment to what the
  body can observe: the `vals`/`psub` bindings whose names occur in the body
  or in any body it reaches (`+reach-names`, transitive over `ops`, `~+`),
  so constants and INSTANCE substitutions read through a reached member are
  kept and the call site's other locals are dropped. `s1` is cleared unless
  the reference is primed or under ENABLED. A same-named call-site local
  only widens the key (a miss), never changes a result.
- Fuel stays in the key (decremented as before), so the recursion limit
  behaves exactly as before.

## Measured

GameOfLife N = 3 (512 distinct, 1,024 generated) through the console
checker (scratch generator). A/B by alternating builds; each rebuild clears
the persistent `~+` cache, and an N = 2 warm-up preceded each timed run. The
box was shared (load 2.6–5.2):

| build | run 1 | run 2 |
|---|---|---|
| A (before) | 212.4 s | 170.8 s |
| B (memo) | 139.7 s | 141.8 s |

So the gain is **×1.2–1.5**. The materialization was not most of the cost.
What remains is presumably `Sum`'s recursion: per state, 18 calls × 8 steps
of CHOOSE, set difference and function application. That is general
evaluator speed and is not profiled here.

A repeat run on the same build took 2 s: the persistent cache served the
whole run. Any timing taken after a warm run of the same model is
therefore invalid.

## Tests

- `tests/lib/neval-state` `test-sdef-memo`: value follows the state; a
  constant is reached through another definition; a call-site local is
  ignored, including one that shares the definition's binder name; a primed
  reference reads `s1`.
- Regression: 52 shards green on the final code (neval-state 9, mc 107,
  dfid 23, job 130, app 44, blackbox 40, sim-diff 82, generate-diff 30,
  liveness-* 58, mp 192, stdops, tlcmod, bags, seqs, arith, …).
