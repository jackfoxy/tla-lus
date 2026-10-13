# R4.2s: Moving_Cat_Puzzle wrong answer (2026-10-12)

**Status: DONE.** CatEvenBoxes and CatOddBoxes reported a liveness failure
(a stuttering counter-example to `Victory`) where tlc2 finds none. Cause:
`lib/liveness` `+enabled-eval` required a COMPLETE successor.
`WF_cat_box(Move_Cat)` asks `ENABLED <Move_Cat>_cat_box`; `Move_Cat` assigns
`cat_box` only, so no complete successor existed, ENABLED read FALSE, and
the fairness condition was vacuous.

tlc2's `Tool.enabled` returns as soon as the action's item list is
exhausted (`if (acts.isEmpty()) return s1`): a variable the action does
not mention is unconstrained. The port's expression-level ENABLED
(`+eval-enabled-rs`) already had no such check; only the liveness one did.

- Fix: drop the completeness requirement in `+enabled-eval`.
- Test: mc `live-enabled-partial` (pin golden; it holds). mc 133; every
  liveness shard green.
- Census: both models **success**, agreeing with the manifest (48, 30).

This is the second fairness defect R4.2 found that made a property look
violated: see R4.2n fix 10, the state-dependent action argument.
