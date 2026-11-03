# R4.Q5 notes — SUBSET assignment, MCInnerSerial (2026-10-24/25)

Target (plan r1/r2): MCInnerSerial completes = pin (195 distinct, 6,181
generated) within 5× tlc2's 12 min 34 s. **Not met.**

## Runs

| run | code | result |
|---|---|---|
| baseline (`logs/q5-innerserial-full.txt`) | Q4 | 149 distinct at 445 s, then one slice > 25 min; ended `limited time` after the king crash (below) |
| `logs/q5-innerserial-full2.txt` | Q5, ship-only `default-budget` 8 | 160 distinct at 551 s, then no progress to the 4,500 s wall: `limited time`, 160/772 |

Per expansion (dojo stepper, one expansion per slice): 4–23 s early, but
some states at depth 4–5 run for more than 20 minutes. tlc2's whole run is
12.5 min.

## Change: `+subset-sup`

`x' \in SUBSET T` directly followed by `A \subseteq x'` produces only the
subsets of T that contain A: A's members (as T holds them) with each subset
of the rest, in the full path's order (by size, then combination order,
which adding fixed members to every combination preserves). The second
conjunct is still evaluated. It does not apply if A or T cannot be evaluated
before x' is assigned, or if either draws.

A/B on `zprobe/q4/ss` (`x = 1..12`, one expansion over `SUBSET (1..16)`):
**30 ms vs 50 s** (stubbed), counts equal (17/17/2). Arms
`test-subset-assign-supersets` (pin 10/4/2) and `test-subset-assign-outside`
(pin 1/1/1).

In MCInnerSerial `opOrder` is empty or small in most states, so the
pruning rarely bites. The plain path costs ≈760 µs per candidate
(enumeration, normalization, the `\subseteq` check), and `Serializable'`
adds more.

## What is left (for the check-in)

- `totalOpOrder` filters all 65,536 subsets of `opId \X opId` with a
  triple `\A`. tlc2 enumerates it lazily per `\E R \in totalOpOrder` and
  stops at the first witness. The port memoizes the whole set per `opId'`.
- Hypothesis, not tested: `Serializable'` is a heavy state-level definition,
  memoized per successor (up to 65,536 entries per expansion). That may
  evict the `totalOpOrder` entry from the bounded `~+` cache, which would
  then be recomputed.
- The agent's slice is 256 expansions (`default-budget`). At several
  seconds per expansion one Gall event runs for tens of minutes, the
  class that preceded the 2026-10-19 and 2026-10-25 king crashes. An
  adaptive slice was deferred at r14.

## Incident (2026-10-25 00:21)

During the baseline, I SIGINTed the serf four times trying to stop the
25-minute slice. Behn re-fires the slice ahead of any cancel (documented in
`examples.Watchdog`), so the job could end only at its `max-time`. The king
then crashed (`loom: external fault`). The 23:47 snapshot was backed up
(`tla-zod-chk-backup-2026-10-24-2347`), and a normal restart (the user's
choice) replayed cleanly to event 143326. Rule: never interrupt a job by
hand; let `max-time` and the watchdog end it.

## Gates and census

Regression 65/65 (`logs/q5-regress1.txt`); validate, scaffold-gate,
test-examples PASS. Targeted census `logs/census-q5.txt` (census-q4's 16
rows): every count unchanged, times within noise of census-q4
(the pattern occurs in none of them).
