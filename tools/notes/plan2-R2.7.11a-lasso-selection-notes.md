# R2.7.11a — lasso selection: the rule is not a length rule

```text
Sub-unit: R2.7.11a
Row: tlc-live-lasso  (partial -> parity)
Hypothesis under test (R2.7.11's): "+scc-accepting may accept nodes the pin
  does not, so `longest` masks an ACCEPTANCE bug"
Result: DISPROVED, and the real rule fell out of disproving it.
```

## The acceptance hypothesis, disproved

`gh1389-counting` has two distinct states and the property `AtMost(4)`
("`x` becomes TRUE at most 4 times"). The pin's counter-example is 10 states,
`F,T,F,T,F,T,F,T,F,T`; the port's was 11, one trailing `F`.

The port's State-11 node is **genuinely accepting**. Its behaviour makes `x`
TRUE five times, exactly as the pin's does, so it violates `AtMost(4)` just as
soundly. There is no acceptance bug. Both candidates are correct witnesses and
only one of them is the witness tlc2 prints — this was always a SELECTION
question, and R2.7.11 was right about that much.

## What separates the two directions

`¬AtMost(4)` is a 5-deep nest of `<>`:

```text
<>(x /\ <>(~x /\ <>(x /\ <>(~x /\ <>(x /\ <>(~x /\ <>(x /\ <>(~x /\ <>x))))))))
```

Every conjunct is discharged by the time `x` is TRUE for the fifth time, at
State 10. Nothing is left to do, so the shortest discharging path IS the
answer, and the trailing `F` is dead weight.

`wf-absent-viol` is the other shape. `Live == <>(x = 3)` negates to
`[](x # 3)` — a `[]`, an obligation that survives into the limit. The witness
is a real lasso whose CYCLE does the work, and tlc2 reports the stutter its
DFS finishes first: the sink `x = 2`, `LOOP 3`, the DEEPEST one.

So:

| tf discharged by a finite prefix? | witness | pick |
|---|---|---|
| yes | pure reachability, no closer printed | **shortest** prefix |
| no | genuine lasso, cycle does the work | **longest** (deepest) prefix |

**The predicate already existed.** `+box-free-tf` is R2.7.5's "does a FINITE
PREFIX discharge everything?" — box-free `tf`, no promise carrying a `[]`,
every PEM condition-free (R2.7.6.0 widened it to the last clause). It is the
same predicate `+live-render` already uses to decide whether to print a closer
at all, which is the visible form of the same fact: a counter-example with no
closer is one whose length is decided by reachability.

That is why the two frozen cases and the three arms the shortest-probe broke
partition cleanly:

```text
box-free  (shortest):  live-after-inv, gh1389-counting     <- the two frozen
NOT box-free (longest): wf-absent-viol (lasso + message),
                        inv-prop-prop-runs                 <- the three broken
```

Each of the two heuristics fitted to one case was fitted to one SIDE.

## The change

`desk/lib/liveness.hoon`:

- `+box-free-tf` MOVED here from `lib/check`. `+lasso-of-product` needs it and
  liveness.hoon cannot depend on check.hoon. `has-box:tp` becomes `has-box`
  (`=, tp`). `+box-free-tf:check` is now a one-line forwarder so
  `job.hoon`'s `box-free-tf:check` call is untouched.
- `+lasso-of-product` binds `finite=(box-free-tf ~[o])` once per
  OrderOfSolution and the stutter-selection fold compares with `lth` when
  `finite`, `gth` otherwise. Two lines of behaviour.

`tools/gen-mc-tests.py`: `SKIPS` is now **empty**. Both entries were this
defect; the map and its printout stay for the next increment that needs them.

## Evidence

- `tests/lib/mc`: **85 arms, `ok=%.y`**, including the two newly-emitted
  `test-mc-live-after-inv` and `test-mc-gh1389-counting`.
- `liveness-lasso`, `liveness-message`, `liveness-verdict`,
  `liveness-product`, `liveness-accept`, `temporal`, `temporal-struct`,
  `tableau`: `ok=%.y`.
- `job`, `sim-live`, `trace`, `diagnostics`, `symmetry`, `tier2`,
  `tier2-sub`, `regprop`, `inv-constraints`, `cfg-runspec`: `ok=%.y`.

## The methodological point, since R2.7.11 got it backwards

R2.7.11 read `LiveWorker.printTrace`, saw the prefix come from
`dg.getPath(state, tidx)` over a disk-backed graph, and concluded the answer
was a function of TLC's traversal ORDER and therefore not locally computable.
That is true of the MECHANISM and false of the RESULT. The traversal order
decides which node the search stops at; what makes that node PREDICTABLE is
the obligation the tableau still carries. Reading the pin's implementation
said "unreproducible"; asking what the pin's ANSWER MEANS said "two lines".

Worth keeping next to the standing note that eight units in a row found their
own row's claim wrong: the row was right that the defect was in `+oos-lasso`'s
selection and wrong about the shape of the fix, and the previous unit was
right to refuse to fit a third heuristic.
