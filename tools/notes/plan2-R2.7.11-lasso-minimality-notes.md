# R2.7.11 — lasso minimality: measured, NOT closed

> Closed by **R2.7.11a** — see `plan2-R2.7.11a-lasso-selection-notes.md`.
> The acceptance hypothesis this file records was DISPROVED, and the
> traversal-order conclusion turned out to describe the MECHANISM, not the
> RESULT: the selection is keyed on `+box-free-tf`.

```text
Sub-unit: R2.7.11
Claim being measured: "the fix is LASSO MINIMALITY in `+oos-lasso`"
Measurement result: the defect is in `+oos-lasso`'s SELECTION, yes -- but it is
  NOT a length rule in either direction, and the plan's M/med sizing assumed a
  fix that does not exist. The row stays `partial`, with a sharper target.
```

## What the two frozen cases want

Both are the port's trace running ONE state past the pin's:

| case | pin ends | port ends |
|---|---|---|
| `live-after-inv` (R2.7.5) | State 3, where `[](x = 0 => [](x # 2))`'s promise is fulfilled | State 4 |
| `gh1389-counting` (R2.7.6.2) | State 10 — the 5th `x = TRUE`, where `AtMost(4)` is violated | State 11 |

## The probe, and why it failed

R2.7.5 chose "among the accepting stutter SCCs keep the one with the LONGEST
prefix", fitted to `wf-absent-viol` (*"stutters at the sink `x = 2`, LOOP 3"*).
The obvious alternative — keep the SHORTEST — was tried:

```text
longest  (today):  wf-absent-viol PASSES, the two frozen cases FAIL
shortest (probe):  the two frozen cases would pass, and
                   liveness-lasso/test-lasso-wf-absent-viol FAILS,
                   liveness-message/test-message-wf-absent-viol FAILS,
                   mc/test-mc-inv-prop-prop-runs FAILS
```

So **neither length rule is right**, and the probe is reverted. A heuristic
over prefix length cannot express what the pin does.

## What the pin actually does

`LiveWorker.printTrace(state, tidx, nodeTbl)` builds the prefix from
`this.dg.getPath(state, tidx)` — the path to the node **where its own search
found the violation**. That node comes from `checkComponent`'s DFS over the
disk-backed behaviour graph, so the reported prefix is a function of TLC's
TRAVERSAL ORDER, not of any property of the node the port can compute locally.

Matching it means reproducing that traversal order over the product graph.
That is a different unit from the one the plan sized, and it is the same shape
of problem as `tlc-live-product`'s approved difference (memory graph vs
disk-backed node layout) — which is worth noticing before starting, because
the layout IS the order.

## One hypothesis, marked as such

Worth testing first, because it would be cheaper and would explain both
directions: perhaps the port's `+scc-accepting` accepts nodes the pin does not,
so the extra state is not a selection artifact at all — "longest" would then be
masking an acceptance bug (picking a node that should not be accepting), and
"shortest" exposes it by picking a different wrong node. The check is to dump
the accepting set for `gh1389-counting` and ask whether the State-11 node is
genuinely accepting under `PossibleErrorModel`'s conditions.

**Not verified.** It is written down as the next step, not as a finding.

## State

Both cases stay frozen with their goldens; `wf-absent-viol`,
`inv-prop-prop-runs` and the rest of the liveness corpus are green on the
unchanged rule. `tlc-live-lasso` stays `partial`, and its residue is now
"reproduce `checkComponent`'s traversal order (or disprove the acceptance
hypothesis first)" rather than "fix lasso minimality".
